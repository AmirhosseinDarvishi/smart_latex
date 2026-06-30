## 2.0.2 - 2026-06-30

### Fixed
- Documentation and metadata polish for pub.dev analysis (CHANGELOG, doc
  comment formatting). No functional changes.

## 2.0.0 - 2026-06-28

### Breaking / major
- **Self-contained now.** The math engine (a layout-fixed copy of
  flutter_math_fork, Apache-2.0) is bundled inside the package. You no longer
  need to add `flutter_math_fork` yourself or apply any `dependency_overrides`
  — `flutter pub add smart_latex` is all that's required.
- The bundled engine fixes the upstream
  `RenderResetDimension does not meet its constraints` layout crash that
  affected `\sqrt` nested in `\frac` with `\left(...\right)` delimiters.

See `PATCHES.md` for the exact changes made to the bundled engine.

## 1.0.0 - 2026-06-27

Initial release.

### Widgets
- `SmartLatexText` — renders a string of mixed plain text and LaTeX. Supports
  inline (`$...$`, `\(...\)`) and display (`$$...$$`, `\[...\]`) math, RTL,
  selectable text, custom error builders, text scaling, and a
  `hideTrailingIncompleteMath` flag for streaming / animated text.
- `SmartMath` — renders a single LaTeX expression (no surrounding text).

### Sanitizer
- `sanitizeLatex()` repairs common malformed LaTeX:
  - Double-backslash before command names (`\\right` → `\right`).
  - `\sqt` typo → `\sqrt`.
  - Persian / Arabic digits (۰–۹, ٠–٩) → ASCII.
  - Persian decimal/thousands separators (`٫ ٬ ،`).
  - Single-character `\text{0}` wrappers → bare characters.
  - Unbalanced curly braces.
- `LatexSanitizeOptions` lets you enable/disable each rule individually.
