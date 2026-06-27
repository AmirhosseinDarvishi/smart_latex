# smart_latex

Robust LaTeX rendering for Flutter. Renders mixed text and math, repairs malformed input, and works cleanly inside custom-font and right-to-left layouts.

## Features

- Renders **inline** (`$...$`, `\(...\)`) and **display** (`$$...$$`, `\[...\]`) math.
- **Repairs malformed LaTeX** automatically:
  | Input problem | Fix applied |
  |---|---|
  | `\\right)` (double backslash) | `\\command` → `\command` |
  | `\sqt{x}` typo | → `\sqrt{x}` |
  | Persian / Arabic digits `۱٫۵` | → `1.5` |
  | `\text{0}\text{.}\text{5}` | → `0.5` |
  | Unmatched `{` or `}` | balanced automatically |
- **RTL-safe**: keeps KaTeX metrics isolated from the surrounding font/line-height so math renders correctly inside Persian/Arabic text and doesn't trigger `flutter_math_fork` layout assertions.
- `hideTrailingIncompleteMath` flag for streaming / typewriter animations.
- Selectable text, custom error builders, text scaling, and per-rule sanitizer options.

## Installation

```yaml
dependencies:
  smart_latex: ^1.0.0
```

## Usage

```dart
import 'package:smart_latex/smart_latex.dart';

// Inline math mixed with text
SmartLatexText(r'The answer is $\frac{1}{2}$.')

// RTL text with a formula
SmartLatexText(
  r'قضیه فیثاغورس: $a^2 + b^2 = c^2$',
  textDirection: TextDirection.rtl,
  style: const TextStyle(fontSize: 16, height: 1.8),
)

// A single expression
SmartMath(r'e^{i\pi} + 1 = 0', display: true)

// Streaming / animated text — hides an unclosed formula while it is typed
SmartLatexText(currentStreamedText, hideTrailingIncompleteMath: true)
```

### Sanitize without rendering

```dart
final clean = sanitizeLatex(r'\frac{{\text{0}\text{٫}\overline{\text{3}}}}{{1}}');
// → r'\frac{{0.\overline{3}}}{{1}}'
```

Pick which rules run:

```dart
sanitizeLatex(
  source,
  options: const LatexSanitizeOptions(
    normalizeDigits: false, // keep Persian digits
  ),
);
```

### Configuration

`SmartLatexText` parameters:

| Parameter | Default | Description |
|---|---|---|
| `style` | `null` | Base text style (merged over `DefaultTextStyle`). |
| `textDirection` | `ltr` | Text direction of the surrounding text. |
| `textAlign` | `start` | Alignment of the text. |
| `selectable` | `false` | Make plain-text runs selectable. |
| `sanitize` | `true` | Run `sanitizeLatex` on each math segment. |
| `sanitizeOptions` | all on | Which sanitizer rules to apply. |
| `hideTrailingIncompleteMath` | `false` | Hide an unclosed trailing `$`. |
| `scrollDisplayMath` | `true` | Horizontally scroll wide block equations. |
| `errorBuilder` | `null` | Custom widget when a formula fails to render. |
| `textScaler` | inherited | Scale factor for both text and math. |

### Using with gpt_markdown

`smart_latex` pairs well with full Markdown renderers. Provide a `latexBuilder`
that forwards only `fontSize`/`color` to the math renderer and sanitize the
input first:

```dart
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:smart_latex/smart_latex.dart';

GptMarkdown(
  source,
  useDollarSignsForLatex: true,
  latexWorkaround: sanitizeLatex,
  latexBuilder: (ctx, tex, style, inline) => Math.tex(
    sanitizeLatex(tex),
    mathStyle: inline ? MathStyle.text : MathStyle.display,
    textStyle: TextStyle(fontSize: style.fontSize, color: style.color),
    onErrorFallback: (_) => Text(tex, style: style),
  ),
)
```

## Note on `flutter_math_fork`

`flutter_math_fork` can throw a layout assertion
(`RenderResetDimension does not meet its constraints`) for some complex
formulas. `smart_latex` minimises this by never forwarding the font family or
line height to the renderer. If you still hit it with a specific expression,
the root cause is in `flutter_math_fork`'s layout code constraining child
sizes; see its issue tracker.

## License

MIT
