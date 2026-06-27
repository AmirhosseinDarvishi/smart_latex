## 1.0.0

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

### Stability
- Only `fontSize` and `color` are forwarded to the math renderer; font family
  and line height are dropped so KaTeX metrics stay consistent and the
  `flutter_math_fork` layout assertions don't fire inside custom-font / RTL
  layouts.
