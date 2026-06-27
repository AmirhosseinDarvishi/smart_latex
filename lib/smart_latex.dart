/// Robust LaTeX rendering for Flutter.
///
/// Renders strings that mix plain text and LaTeX, automatically repairing
/// malformed input (double-backslash commands, Persian/Arabic numerals,
/// single-character `\text{}` wrappers, unbalanced braces) and keeping KaTeX
/// metrics isolated from custom fonts and RTL layouts.
///
/// ```dart
/// import 'package:smart_latex/smart_latex.dart';
///
/// SmartLatexText(r'The answer is $\frac{1}{2}$.');
/// SmartMath(r'e^{i\pi} + 1 = 0', display: true);
/// final clean = sanitizeLatex(r'\left(x\\right)'); // r'\left(x\right)'
/// ```
library smart_latex;

export 'src/latex_text.dart' show SmartLatexText, LatexErrorBuilder;
export 'src/smart_math.dart' show SmartMath;
export 'src/sanitizer.dart' show sanitizeLatex, LatexSanitizeOptions;
