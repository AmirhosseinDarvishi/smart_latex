/// Options controlling which corrections [sanitizeLatex] applies.
///
/// All corrections are enabled by default. Disable individual rules when you
/// know the input is already well-formed and want to skip the work, or when a
/// particular rule conflicts with your content.
class LatexSanitizeOptions {
  const LatexSanitizeOptions({
    this.fixDoubleBackslashCommands = true,
    this.fixCommonTypos = true,
    this.normalizeDigits = true,
    this.unwrapSingleCharText = true,
    this.balanceBraces = true,
  });

  /// Apply no corrections — returns the input unchanged.
  const LatexSanitizeOptions.none()
      : fixDoubleBackslashCommands = false,
        fixCommonTypos = false,
        normalizeDigits = false,
        unwrapSingleCharText = false,
        balanceBraces = false;

  /// Convert `\\command` (double backslash) into `\command`.
  ///
  /// A double backslash followed by letters is a malformed command — in real
  /// LaTeX `\\` is a line break and cannot be followed directly by a command
  /// name. This breaks pairs such as `\left( ... \\right)`.
  final bool fixDoubleBackslashCommands;

  /// Fix well-known command typos such as `\sqt` → `\sqrt`.
  final bool fixCommonTypos;

  /// Convert Persian/Arabic digits (۰–۹, ٠–٩) and separators (٫ ٬ ،) to ASCII.
  final bool normalizeDigits;

  /// Unwrap single digits and math punctuation from `\text{}`.
  ///
  /// Input like `\text{0}\text{.}\text{5}` becomes `0.5`. A `\text{}` wrapper
  /// around a single character forces text-mode sizing that frequently
  /// mismatches the surrounding math layout.
  final bool unwrapSingleCharText;

  /// Drop unmatched closing braces and append missing closing braces so the
  /// brace nesting is balanced.
  final bool balanceBraces;

  LatexSanitizeOptions copyWith({
    bool? fixDoubleBackslashCommands,
    bool? fixCommonTypos,
    bool? normalizeDigits,
    bool? unwrapSingleCharText,
    bool? balanceBraces,
  }) {
    return LatexSanitizeOptions(
      fixDoubleBackslashCommands:
          fixDoubleBackslashCommands ?? this.fixDoubleBackslashCommands,
      fixCommonTypos: fixCommonTypos ?? this.fixCommonTypos,
      normalizeDigits: normalizeDigits ?? this.normalizeDigits,
      unwrapSingleCharText: unwrapSingleCharText ?? this.unwrapSingleCharText,
      balanceBraces: balanceBraces ?? this.balanceBraces,
    );
  }
}

/// Maps Persian/Arabic digits and separators to their ASCII equivalents.
const Map<String, String> _digitMap = {
  '۰': '0', '۱': '1', '۲': '2', '۳': '3', '۴': '4',
  '۵': '5', '۶': '6', '۷': '7', '۸': '8', '۹': '9',
  '٠': '0', '١': '1', '٢': '2', '٣': '3', '٤': '4',
  '٥': '5', '٦': '6', '٧': '7', '٨': '8', '٩': '9',
  '٫': '.', '٬': ',', '،': ',',
};

/// Known single-token command typos and their corrections.
const Map<String, String> _typoMap = {
  r'\sqt': r'\sqrt',
};

final RegExp _doubleBackslashCommand = RegExp(r'\\\\([a-zA-Z]+)');
final RegExp _singleCharText = RegExp(r'\\text\{([\d.,+\-=*/;:!%])\}');

/// Cleans up a LaTeX string so it can be rendered reliably.
///
/// Corrects the most common defects found in machine- or model-generated
/// LaTeX: double-backslash commands, simple typos, Persian/Arabic numerals,
/// single-character `\text{}` wrappers, and unbalanced braces.
///
/// ```dart
/// sanitizeLatex(r'\frac{\text{1}}{\text{2}}'); // => r'\frac{1}{2}'
/// sanitizeLatex(r'\left(x\\right)');           // => r'\left(x\right)'
/// sanitizeLatex('۱٫۵');                         // => '1.5'
/// ```
String sanitizeLatex(
  String tex, {
  LatexSanitizeOptions options = const LatexSanitizeOptions(),
}) {
  var result = tex;

  if (options.fixDoubleBackslashCommands) {
    result = result.replaceAllMapped(
      _doubleBackslashCommand,
      (m) => '\\${m.group(1)!}',
    );
  }

  if (options.fixCommonTypos) {
    for (final entry in _typoMap.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
  }

  if (options.normalizeDigits) {
    for (final entry in _digitMap.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
  }

  if (options.unwrapSingleCharText) {
    result = result.replaceAllMapped(_singleCharText, (m) => m.group(1)!);
  }

  if (options.balanceBraces) {
    result = _balanceBraces(result);
  }

  return result;
}

String _balanceBraces(String input) {
  final buf = StringBuffer();
  var depth = 0;
  for (var i = 0; i < input.length; i++) {
    final ch = input[i];
    final escaped = i > 0 && input[i - 1] == '\\';
    if (ch == '{' && !escaped) {
      depth++;
    } else if (ch == '}' && !escaped) {
      if (depth == 0) continue; // drop stray closing brace
      depth--;
    }
    buf.write(ch);
  }
  for (var i = 0; i < depth; i++) {
    buf.write('}');
  }
  return buf.toString();
}
