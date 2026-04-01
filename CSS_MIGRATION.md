# CSS Variable Migration Guide

This document describes an approach for migrating certain prop-drilled visual properties from inline
React/OverReact styles to CSS custom properties (CSS variables). It also lists candidates for this
migration and explains when the approach is safe versus when it risks introducing bugs.

## Background

scadnano follows a React/Redux architecture where the view is a pure function of props, and props are
drilled down from connected components. This is the correct default — it ensures React knows when to
re-render and prevents the class of bugs that React was designed to eliminate (stale views, forgotten
updates, inconsistent state).

However, some visual properties have characteristics that make them safe — and even beneficial — to
manage via CSS custom properties instead of React props:

1. **They are uniform**: the same value applies to every instance of a component sharing a CSS class.
2. **They are purely stylistic**: they affect only appearance (font-size, stroke-width, opacity), not
   layout decisions, conditional rendering, or business logic.
3. **They are already defined in CSS**: the CSS file already has rules for the relevant classes, and the
   inline style merely overrides or supplements what CSS could express.

## How the CSS Variable Approach Works

Instead of prop-drilling a value like `modification_font_size` from `AppUIState` through
`DesignMainStrands` → `DesignMainStrand` → `DesignMainStrandModifications` → `DesignMainStrandModification`
and finally applying it as `..fontSize = props.font_size`, we:

1. **Define a CSS variable** in the stylesheet with a fallback:
   ```css
   .modification-text {
       font-size: var(--modification-font-size, 12);
   }
   ```

2. **Set the variable on the document root** via middleware when the action is dispatched:
   ```dart
   document.documentElement?.style.setProperty('--modification-font-size', '$font_size');
   ```

3. **Set the initial value** in `app.dart`'s `start()` method (after `setup_view()`), reading from the
   persisted state:
   ```dart
   set_modification_font_size(store.state.ui_state.modification_font_size);
   ```

4. **Remove the inline style** from the React component and **remove the prop** from every intermediate
   component in the drilling chain.

The state field, action, reducer, menu item, and serializer registration all remain unchanged — only
the view-side plumbing changes.

## When This Is Safe

A CSS variable migration is safe when **all** of the following hold:

- **Uniform value**: Every element with the CSS class gets the same value. There is no per-instance
  variation. If strand A's domain name font size could differ from strand B's, this approach breaks.

- **No conditional rendering depends on the value**: The component does not use the value in `render()`
  to decide *what* to render (e.g., `if (font_size > 10) show_label()`). It only uses the value to
  set a style attribute. If the value influences control flow, it must remain a React prop so that
  React re-renders when it changes.

- **No derived layout calculations**: The component does not use the value to compute positions, sizes,
  or other attributes that feed into sibling components. For example, if a font-size were used to
  calculate the vertical offset of a label to avoid overlap, removing it from props would break that
  calculation.

- **The CSS class is stable**: The class name is reliably present on the element and won't be removed
  or changed by other code paths.

## When This Is NOT Safe

Do **not** use CSS variables when:

- **The value varies per instance**: e.g., each strand has its own color. Strand colors are
  data-driven, not uniform, so they must remain inline.

- **Render logic depends on the value**: e.g., `show_domain_names` is a boolean that controls whether
  name text elements are rendered at all. If this were a CSS variable controlling `display: none`, React
  would still render the component and its children (wasting work), and any side effects in
  `componentDidMount` would still fire. Keep booleans that control rendering as React props.

- **The value feeds into position/geometry calculations**: e.g., DNA sequence font sizes are computed
  dynamically based on insertion length and letter spacing. These calculations happen in Dart code during
  `render()`, so they cannot be replaced by CSS.

- **The component's identity or key depends on the value**: Changing a CSS variable doesn't trigger
  React's reconciliation, so if React needs to know about the change to update keys or diff correctly,
  it must be a prop.

## Advantages of the CSS Variable Approach

1. **No unnecessary re-renders**: Changing a CSS variable does not trigger React re-rendering of any
   component. Given scadnano's known performance sensitivity to OverReact re-renders (see
   CONTRIBUTING.md discussion of `identical()` vs `==`), this is significant. Changing a font-size
   prop currently causes every strand component to re-render even though only a CSS property changed.

2. **Eliminates prop drilling**: For `modification_font_size`, the prop passes through 4 intermediate
   components that don't use it. Removing this simplifies each component's props interface and reduces
   the surface area for bugs when refactoring.

3. **CSS handles cascading naturally**: The selected-state stroke-width
   (`calc(var(--strand-stroke-width) + 1)`) is expressed purely in CSS relative to the base value.
   With props, this relationship would need to be duplicated in Dart code.

4. **Consistent with CSS's purpose**: These are presentation-layer concerns. CSS variables are the
   standard mechanism for parameterizing presentation.

## Risks and Mitigations

- **Risk**: The view is no longer a pure function of React props for these properties. If a CSS
  variable is not set (e.g., middleware doesn't fire, or initialization is missed), the fallback value
  in `var(..., fallback)` is used. Always provide a sensible fallback matching the constant default.

- **Risk**: Debugging is harder — you can't inspect a component's props to see the current font-size.
  Instead, you'd inspect the computed CSS. Mitigation: the value is still in `AppUIState` and visible
  in Redux DevTools.

- **Risk**: If a future feature needs per-instance variation for a property that was migrated to CSS,
  the migration would need to be reversed. Mitigation: only migrate properties that are inherently
  uniform by design (not just currently uniform by coincidence).

## Candidates for Migration

### High priority (significant prop-drilling reduction)

These properties are drilled through 3–5 intermediate components that don't use the value:

| Property | CSS Variable | Default | CSS Classes | Drilling Depth |
|---|---|---|---|---|
| `modification_font_size` | `--modification-font-size` | 12.0 | `.modification-text` | 5 components |
| `strand_name_font_size` | `--strand-name-font-size` | 16.0 | `.strand-name` | 5 components |
| `strand_label_font_size` | `--strand-label-font-size` | 16.0 | `.strand-label` | 5 components |
| `domain_name_font_size` | `--domain-name-font-size` | 10.0 | `.domain-name`, `.loopout-name`, `.extension-name` | 5 components |
| `domain_label_font_size` | `--domain-label-font-size` | 10.0 | `.domain-label`, `.loopout-label`, `.extension-label` | 5 components |

### Medium priority (shorter drilling chains)

| Property | CSS Variable | Default | CSS Classes | Drilling Depth |
|---|---|---|---|---|
| `major_tick_offset_font_size` | `--major-tick-offset-font-size` | 12.0 | (needs new class) | 3 components |
| `major_tick_width_font_size` | `--major-tick-width-font-size` | 8.0 | (needs new class) | 3 components |

### Already migrated

| Property | CSS Variable | Default | CSS Classes |
|---|---|---|---|
| `stroke_width` | `--strand-stroke-width` | 5.0 | `.domain-line`, `.loopout-curve`, `.crossover-curve`, `.extension-line`, `.insertion-curve`, `.potential-segment`, `.potential-vertical-crossover-curve`, `.domain-line-moving` |
| `crossover_opacity` | `--crossover-opacity` | 0.5 | `.crossover-curve` |
| `crossover_opacity_same_helix` | `--crossover-opacity-same-helix` | 0.5 | `.crossover-curve-same-helix` |

### Not candidates

These should remain as React props or inline styles:

| Property | Reason |
|---|---|
| Strand/domain **colors** (`stroke`) | Per-instance, data-driven |
| `show_dna`, `show_modifications`, etc. | Booleans controlling whether components render at all |
| DNA sequence font sizes | Computed per-insertion/loopout based on length and letter spacing |
| Selection state classes | React must manage these for event handling to work correctly |
| Zoom-dependent stroke widths (selection box) | Computed dynamically from current zoom level |

## Steps to Migrate a Property

For each candidate, follow these steps:

1. **Add `font-size: var(--variable-name, default)` to the CSS class** in `scadnano-styles.css`.

2. **Add a setter function** in `lib/src/middleware/stroke_width.dart` (consider renaming this file
   to `css_variables.dart` if migrating multiple properties).

3. **Add middleware handling** for the existing action (e.g., `ModificationFontSizeSet`) in the same
   middleware function to call the setter.

4. **Add initialization** in `app.dart`'s `start()` method after `setup_view()`.

5. **Remove the inline style** (e.g., `..fontSize = props.font_size`) from the leaf component.

6. **Remove the prop** from every intermediate component in the drilling chain. This is the main
   payoff — simplifying the component interfaces.

7. **Test**: verify the value applies correctly on load, changes via the menu, and persists across
   page refreshes (via localStorage). Also verify that the SVG export includes the correct computed
   style (the `clone_and_apply_style_rec` function copies computed styles, so CSS variables should
   resolve correctly during export).
