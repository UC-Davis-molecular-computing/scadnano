# Migrating off `dart:html` / `dart:svg` / `dart:js` (issue #1029)

**Status: the migration itself is blocked upstream (verified 2026-08-03) and is not starting. The
no-regret prep work in §6 is proceeding independently — the first item landed 2026-08-04. This
document records why we are blocked, what was verified, and what to do when that changes.**

Related: [issue #1029](https://github.com/UC-Davis-molecular-computing/scadnano/issues/1029),
[Workiva/over_react#981](https://github.com/Workiva/over_react/issues/981),
[Workiva/react-dart#391](https://github.com/Workiva/react-dart/issues/391).

---

## 1. Why we are blocked

`dart:html`, `dart:svg`, and `dart:js` are deprecated in favour of `package:web` + `dart:js_interop`.
scadnano cannot migrate because OverReact has not, and OverReact's public API is typed in `dart:html`.

Upstream state (checked 2026-08-03 against the pub.dev API and package sources):

| Package | Latest | Published | `dart:html` in `lib/` | `package:web` / `dart:js_interop` | discontinued `js` |
|---|---|---|---|---|---|
| `over_react` | 5.7.0 | 2026-07-06 | 14 files | **0** | `js: ^0.6.1+1` |
| `react` (react-dart) | 7.3.2 | 2026-03-12 | 7 files | **0** | `js: ^0.6.3` |
| `over_react_test` | 3.0.4 | 2026-02-27 | 5 files | **0** | `js: ^0.6.1+1` |
| `dnd` | 2.0.1 | **2021-10-07** | 1 file | **0** | — |
| `w_common` | 4.0.0 | 2026-03-03 | 2 files | **0** | `js: ^0.6.3` |
| `w_flux` | 3.0.3 | 2026-03-03 | 3 files | **0** | via `react` |
| `platform_detect` | 2.1.6 | 2026-02-22 | 3 files | **0** | — |
| `http` | 1.6.0 | — | 1 file | **migrated** | — |

There is no over_react 6.x, no prerelease, and no branch or PR in `Workiva/over_react` or
`Workiva/react-dart` mentioning `package:web`, `js_interop`, or `wasm`. Neither carries pub.dev's
`is:wasm-ready` tag. Recent Workiva work is dart2js *size optimisation* — the opposite direction.

Maintainer `greglittlefield-wf` on over_react#981 (2025-07-10):

> We do have plans to migrate to `package:web` and the new `dart:js_interop` JS interop eventually,
> but unfortunately there's not a timeline for that.
>
> For now, I would recommend continuing to use `dart:html` in code that interacts with over_react
> APIs that use those DOM types.

That thread has been silent since 2025-07-11.

**Two blockers are independent of OverReact:**

- **`dnd` 2.0.1** — last published 2021-10-07, effectively unmaintained. `dart:html`-only, and it
  pins [lib/src/view/design.dart](lib/src/view/design.dart) via `Draggable(view_svg)` whose callbacks
  do `draggable_event.originalEvent as MouseEvent`. This one is fully within our control (fork or
  replace) and will need solving regardless of what Workiva does.
- **The `package:js` interop layer** — [react_bootstrap.dart](lib/src/view/react_bootstrap.dart),
  [react_color.dart](lib/src/view/react_color.dart), [react_dnd.dart](lib/src/view/react_dnd.dart),
  [strand_color_picker.dart](lib/src/view/strand_color_picker.dart), `axis_arrows_*.dart`.
  `package:js` and `dart:js_interop` do not mix freely.

---

## 2. The maintainer's suggested cast — it probably *does* work, but it doesn't help

Greg suggested bridging at the boundary:

```dart
import 'dart:html' as html;
import 'package:web/web.dart' as web;
import 'over_react/react_dom' as react_dom;

void mount(web.Element webElement) =>
    react_dom.render(/*...*/, webElement as html.Element);
```

Our reply on the issue was that the packages are "totally incompatible". **That conclusion was based
on the wrong evidence.** The error quoted in the issue body —

```
The argument type 'Element (…web-1.1.1…)' can't be assigned to the parameter type
'Element (…html_dart2js.dart)'.   [argument_type_not_assignable]
```

— comes from passing a `web.Element` with **no cast at all**. It is exactly the error the explicit
`as` exists to silence, so it does not test Greg's suggestion.

### Why the cast should succeed on the JS backends

Verified against the local Dart 3.11.1 SDK (`C:/tools/dart-sdk`):

```
package:web        extension type Element._(JSObject _)         web-1.1.1/lib/src/dom/dom.dart:3047
dart:js_interop    extension type JSObject._(JSObjectRepType _) lib/js_interop/js_interop.dart:188
                   typedef JSObjectRepType = interceptors.JSObject
                                             lib/_internal/js_shared/lib/js_types.dart:21
dart:_interceptors class JavaScriptObject extends Interceptor implements JSObject
                                             lib/_internal/js_runtime/lib/interceptors.dart:444
dart:html          Element extends Node extends EventTarget extends JavaScriptObject
                                             lib/html/dart2js/html_dart2js.dart:13063, 23794, 16256
```

`web.Element` erases to `interceptors.JSObject`, which `html.Element` transitively implements — so
the cast is a genuine downcast over the *same underlying JS object*, lowering to a real interceptor
check (`$isElement`). It is not a no-op: a non-DOM JS object will still throw.

The SDK states this directly (`lib/js_interop/js_interop.dart:84-90`):

> These classes implicitly all erase to the internal interceptor `JavaScriptObject`, so they can be
> freely casted to and from other [staticInterop] types, `dart:html` types, and `JSObject` from
> `dart:js_interop`.

The reverse direction has a documented constructor, `JSObject.fromInteropObject`
(`js_interop.dart:189-197`), *"Accepts, for example, the types created using `package:js` or
`dart:html`."* Nothing lints the cast either — `invalid_runtime_check_with_js_interop_types`
deliberately exempts `dart:html`, and it isn't enabled in our `analysis_options.yaml` anyway.

**Unverified:** nobody has publicly reported running this line — the snippet appears in exactly one
place on the internet (our issue), and there's no sign Greg ran it. The above is a derivation from
SDK source, not an observation. See §5 for the experiment that would settle it.

### Why it still doesn't unblock an incremental migration

1. **Wasm — never.** `dart:html`/`dart:svg` don't exist on dart2wasm (`typedef JSObjectRepType =
   js.JSValue` there, and `dart:html` isn't in `libraries.json`). One importing library fails the
   whole build. Wasm is the headline reason to migrate, so a JS-backend-only bridge earns *zero*
   partial credit.
2. **Our browser tests are a live hazard.** [dart-lang/web#240](https://github.com/dart-lang/web/issues/240)
   is an observed failure of exactly this cast family (`type 'EventTarget' is not a subtype of type
   'JSObject?'`), root-caused to `package:test`'s browser bootstrap not running dart2js's interceptor
   setup. Our whole suite runs under `dart run build_runner test` in Chrome, so a bridge could pass
   `webdev build` and fail the suite.
3. **It only fixes one direction.** OverReact hands `dart:html` types *back*:
   `SyntheticEvent.nativeEvent`, `Ref<DivElement>`, `findDomNode`, `DomProps` callbacks.
4. **The guarantee is emergent, not contractual.**
   [dart-lang/sdk#56531](https://github.com/dart-lang/sdk/issues/56531) treats this as implementation
   details leaking, something the team intends to remove; on dart2js it holds only while the `@Native`
   class is retained.

---

## 3. The official guides never contemplate our situation

The [official migration guide](https://dart.dev/interop/js-interop/package-web) (15.5 KB, read in
full) contains **zero** occurrences of "incremental", "gradual", "partial", "staged", or "coexist".
It prescribes a single atomic per-library import swap, offers **no** conversion API between the two
type families, and explicitly rules out `implements`-based adapters:

> If you have a mocking class that `implements` a `dart:html` class, it can't be used to implement a
> `package:web` type. Instead, prefer mocking the JS object itself.

and on type identity:

> When used with a `dart:html` object, `is` and `as` verify that the object is the JS type within the
> `@Native` annotation. In contrast, all `package:web` types are reified to `JSObject`. This means a
> runtime type test will result in different behavior between `dart:html` and `package:web` types.

`dart fix` covers **type renames only**, and only *after* you have swapped the import and broken the
file. There is no codemod — Workiva's own `over_react_codemod` has nothing for `package:web`.

For contrast, null safety — the Dart team's other ecosystem-wide migration — shipped with first-class
mixed-mode support and a `dart migrate` tool. `package:web` shipped with neither. The silence is
meaningful: there is no supported staged path.

> ⚠️ Search engines misattribute null safety's "migrate the leaves of the dependency graph first"
> advice to the `package:web` guide. It is **not** from that guide.

---

## 4. Removal timeline — runway, but the clock restarted

- `dart:html` is `@Deprecated('Use package:web and dart:js_interop instead.')` since Dart 3.7, with
  *"scheduled for removal in late 2025"* in its docs (`html_dart2js.dart:13`). **That date passed;
  it survived 3.7 → 3.12.**
- [dart-lang/sdk#59716](https://github.com/dart-lang/sdk/issues/59716) (umbrella deprecation issue) is
  now **closed**.
- [dart-lang/sdk#63919](https://github.com/dart-lang/sdk/issues/63919), opened **2026-07-30** by
  mkustermann (Dart compiler lead): *"we can start moving towards it's deletion"* — proposes an
  `--allow-legacy-html` opt-in flag as step one.

No committed removal version, and a flag is not deletion. But after ~8 months of drift the direction
is active again. **That flag landing is our real deadline signal.**

---

## 5. When to revisit

The single trigger is **OverReact publishing a release that drops `dart:html`** — which would also
drop its `js` dependency and raise its `analyzer` ceiling, since all three move together. Cheap check:

```sh
curl -s https://pub.dev/api/packages/over_react/versions/$(curl -s https://pub.dev/api/packages/over_react \
  | tr ',' '\n' | grep -oE '"version":"[^"]*"' | head -1 | cut -d'"' -f4) \
  | tr ',' '\n' | grep -oE '"(analyzer|js)":"[^"]*"'
```

While that prints `"analyzer":">=5.13.0 <11.0.0"` and `"js":"^0.6.1+1"`, we are blocked. (This is also
why the `analyzer` pin in [pubspec.yaml](pubspec.yaml) is capped — see the comment there.)

### Optional: settle the cast question empirically (~15 min)

Worth doing at some point because it is genuinely new public information — nobody has reported it.
Throwaway program, not committed:

```dart
import 'dart:html' as html;
import 'package:web/web.dart' as web;

void main() {
  final web.Element? e = web.document.querySelector('#probe');
  final html.Element h = e as html.Element;           // the claim under test
  print('cast ok: ${h.tagName}');
  print('reverse: ${(h as Object) as web.Element}');  // JSObject.fromInteropObject direction
}
```

Run it three ways — they can disagree:

| How | Why |
|---|---|
| `dart run webdev serve` (DDC) | what we develop against |
| `webdev build` / `dart compile js` (dart2js) | what we ship |
| inside a `dart run build_runner test` browser test | **most likely to fail**, per dart-lang/web#240 |

Then reply on over_react#981 with the result. Our question there ("Do you have a link describing
that?") was never answered. Include the correction that the error in the issue body was
`argument_type_not_assignable` from an *uncast* call, and ask whether he means "use `package:web` in
leaf code and bridge at the boundary" (actionable) or "this unblocks incremental migration" (it can't,
until OverReact's API surface changes).

---

## 6. No-regret prep work (safe to do any time, independent of upstream)

Current inventory of `dart:html` importers, excluding generated `.g.dart` (updated 2026-08-04):

| Category | Files | Movable today? |
|---|---|---|
| ~~Dead / near-dead imports~~ | ~~14~~ | **DONE 2026-08-04** |
| `window.alert` / `confirm` only | 15 | Yes — one small shim |
| Independent I/O (localStorage, file save/load, HTTP, clipboard, CSS, iframe, global key listeners) | ~13 | Yes in principle |
| **Pinned by OverReact** (`SyntheticEvent.nativeEvent`, `Ref<DivElement>`, `react_dom.render`, `e.target`) | **~25** | **No** |

Totals now: **57** files import `dart:html` (down from 71), 6 `dart:svg`, 3 `dart:js`, 10
`package:js/js.dart`; **0** use `package:web`. The remaining items shrink the eventual migration
further and are wins on their own terms:

1. ~~**Delete the 14 dead `dart:html` imports.**~~ **Done 2026-08-04** — but only 9 were actually
   dead. `dart analyze` rejected the other 5, because **`dart:html` re-exports `Point` and `Rectangle`
   from `dart:math`** (`html_dart2js.dart:77`: `export 'dart:math' show Rectangle, Point;`). Those
   five — `design_main_dna_sequences`, `design_main_slice_bar`, `design_main_strands`,
   `design_main_strands_moving`, `design_main_unpaired_insertion_deletions` — were reaching
   `dart:math`'s `Point` through `dart:html`, and were repointed at `import 'dart:math';` (or
   `Math.Point` in `design_main_slice_bar.dart`, which already imports `dart:math as Math`).

   > ⚠️ **Audit trap for the remaining work.** A grep for `dart:html` *identifiers* undercounts,
   > because `dart:html` re-exports symbols that don't look like DOM types at all:
   > ```
   > export 'dart:math'               show Rectangle, Point;   // :77
   > export 'dart:html_common'        show promiseToFuture;    // :76
   > export 'dart:_internal'          show HttpStatus;         // :75
   > export 'dart:_native_typed_data' show SharedArrayBuffer;  // :49
   > ```
   > Always confirm with `dart analyze`, not grep. Removing an import is self-verifying — an
   > undefined name is an error — so this is cheap to check and expensive to assume.
2. **Add an `alert`/`confirm` shim** and route the 15 files that use `dart:html` for nothing else
   through it — e.g. [assign_dna.dart](lib/src/middleware/assign_dna.dart),
   [helix_remove.dart](lib/src/middleware/helix_remove.dart),
   [menu_side.dart](lib/src/view/menu_side.dart). **Reuse the existing precedent:**
   [clipboard.dart](scadnano_state_actions/lib/src/state/clipboard.dart) already defines
   `abstract class Clipboard` with `BrowserClipboard` / `CLIClipboard`, swapped at a single global in
   [system_clipboard.dart:22](lib/src/middleware/system_clipboard.dart#L22).
3. **Inline the ~15 `KeyCode` constants** into
   [constants.dart](scadnano_state_actions/lib/src/constants.dart) and
   [edit_mode.dart](scadnano_state_actions/lib/src/state/edit_mode.dart), which import `dart:html`
   *only* for those.
4. **Move `HttpRequest` to `package:http`** in
   [util_state.dart:288-291](scadnano_state_actions/lib/src/util_state.dart#L288). The app already
   uses `package:http` elsewhere, so this removes DOM from the state package entirely — no
   `package:web` involved.
5. **Split [util.dart](lib/src/util.dart)** (754 lines, imported by 64 files) into a DOM/JS half and a
   pure-geometry half. It is the natural chokepoint by import count but not currently a clean seam: it
   is `@JS() library util;`, mixes `dart:html` + `dart:js` + `dart:svg` + `package:js`, and reaches
   into global app state. Splitting it would immediately make the ~30 files that import it for
   non-DOM reasons DOM-free. Highest leverage, highest effort.

**Explicitly do NOT do now:** introduce `package:web` into view code, write a general bridge/adapter
layer, or anything premised on Wasm. All three get deleted when OverReact migrates.

### The hard cases, for whenever the migration does happen

Named so they aren't a surprise. These query React-rendered DOM and re-measure it:

- [util.dart](lib/src/util.dart) — `createSvgPoint()`, `getScreenCtm().inverse()`, `getBBox()`,
  `svg_to_png_data` (called *from JS* via `allowInterop`)
- [view/design.dart](lib/src/view/design.dart) (1120 lines) — holds `SvgSvgElement`s, renders React
  into them, attaches raw listeners, **and** installs `package:dnd` `Draggable` on them
- [middleware/export_svg.dart](lib/src/middleware/export_svg.dart) — clones by id, must `append` to
  the document to measure (`getBBox()` needs it in the DOM), then removes
- [middleware/selections_intersect_box_compute.dart](lib/src/middleware/selections_intersect_box_compute.dart)
  — needs *both* `getBBox()` and `getBoundingClientRect()`; see the explanatory comment block there
- The `componentDidMount` → `querySelector('#own-id')` → `addEventListener('contextmenu')` pattern,
  repeated across ~10 view files, which casts `Event` → `MouseEvent`

### Reference material

`origin/1029-move-from-to-newer-js-and-web-libraries` holds an abandoned 2025 attempt (2 commits, 91
files, 242 commits behind `dev`). **It does not compile** — it calls `Element.html`,
`NodeTreeSanitizer`, `setInnerHtml`, and constructs `package:web` extension types directly
(`HTMLPreElement()`, `SVGFilterElement()`), none of which exist; its pubspec added `js_interop: any`,
which resolves to the abandoned pub.dev package `js_interop 0.0.1` rather than the SDK library. Do not
rebase it. It is still useful via `git show` as a cheat-sheet of the mechanical `dart:html` →
`package:web` mapping *and* of the constructs that do not port cleanly (`Element.html`,
`NodeTreeSanitizer`, `setInnerHtml`, element construction, `..attributes = {}`, `Rectangle<num>` vs
`DOMRect`, `querySelectorAll` returning `NodeList`).

The branch `1029-move-to-newer-js-and-web-libraries` is empty (identical to `dev`) — it is the
placeholder to start fresh in when the time comes.
