# Bundled math engine

`lib/src/math/` is a vendored copy of
[flutter_math_fork](https://pub.dev/packages/flutter_math_fork) (Apache-2.0),
included so that `smart_latex` is fully self-contained and needs no extra math
package or `dependency_overrides`.

The original license is kept at `LICENSE-flutter_math_fork`.

## Changes relative to upstream (v0.7.4)

A layout bug in upstream causes a debug assertion
(`RenderResetDimension does not meet its constraints`) for some formulas — most
visibly `\sqrt` nested inside `\frac` with `\left(...\right)` delimiters. The
affected `performLayout()` methods set their size without clamping it to the
incoming constraints.

Fix applied: clamp the computed size to the constraints in these files under
`lib/src/math/src/render/layout/`:

- `reset_dimension.dart`
- `min_dimension.dart`
- `line.dart`
- `custom_layout.dart`
- `eqn_array.dart`
- `vlist.dart`

Each change is the same shape:

```dart
// before
size = _computeLayout(constraints, dry: false);
// after
size = constraints.constrain(_computeLayout(constraints, dry: false));
```

Other edits: the in-code font-family prefix was changed from
`packages/flutter_math_fork/` to `packages/smart_latex/`, and the library
directive renamed to `smart_latex.math`.
