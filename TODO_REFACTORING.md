# Future Refactoring Notes

## Remove svg_position from Helix

Helix has a field `svg_position` representing where to place it in the SVG view. This is view-layer
information that doesn't belong in the state class (unlike `GridPosition` and `Position3D` which are
actual design state saved to .sc files).

**What to do:** Remove `svg_position` from `Helix`. Every view component accessing `Helix.svg_position`
needs to receive the position as a separate prop. The pure function `helices_assign_svg` in util.dart
already computes these positions, and `app_state.dart` has a memoized getter
`helix_idx_to_svg_position_map` that could be the source.

This is a large refactoring touching many view files.
