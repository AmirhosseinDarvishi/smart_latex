/// Sanitizes LaTeX strings produced by AI language models before passing them
/// to a renderer such as flutter_math_fork.
///
/// AI models commonly make the following mistakes that this function corrects:
///  - `\\right` / `\\left` written as double-backslash instead of single
///  - `\sqt` instead of `\sqrt`
///  - Persian / Arabic digits (۰–۹, ٠–٩) and the decimal separator (٫)
///  - Wrapping every single digit or punctuation mark in `\text{}`
///  - Unbalanced curly braces
String sanitizeLatex(String tex) {
  var result = tex;

  // 1. Fix double-backslash before known LaTeX command names (AI typo).
  //    \\right → \right, \\left → \left, \\frac → \frac, etc.
  result = result.replaceAllMapped(
    RegExp(r'\\\\([a-zA-Z]+)'),
    (m) => '\\${m.group(1)!}',
  );

  // 2. Fix common command typos.
  result = result.replaceAll(r'\sqt', r'\sqrt');

  // 3. Normalise Persian/Arabic digits and decimal separators to ASCII.
  const _persianDigits = {
    '۰': '0', '۱': '1', '۲': '2', '۳': '3', '۴': '4',
    '۵': '5', '۶': '6', '۷': '7', '۸': '8', '۹': '9',
    '٠': '0', '١': '1', '٢': '2', '٣': '3', '٤': '4',
    '٥': '5', '٦': '6', '٧': '7', '٨': '8', '٩': '9',
    '٫': '.', '٬': ',', '،': ',',
  };
  for (final entry in _persianDigits.entries) {
    result = result.replaceAll(entry.key, entry.value);
  }

  // 4. Unwrap single digits and common math punctuation from \text{}.
  //    AI models write \text{0}\text{.}\overline{\text{3}} instead of
  //    0.\overline{3}. The \text{} wrapper around a single digit causes
  //    flutter_math_fork to try to use text-mode sizing, which often
  //    mismatches the minimum-height constraints of the surrounding layout.
  result = result.replaceAllMapped(
    RegExp(r'\\text\{([\d\.,\+\-=\*\/;:!%])\}'),
    (m) => m.group(1)!,
  );

  // 5. Balance curly braces.
  //    Extra closing braces are dropped; missing closing braces are appended.
  final buf = StringBuffer();
  var depth = 0;
  for (var i = 0; i < result.length; i++) {
    final ch = result[i];
    final isEscaped = i > 0 && result[i - 1] == '\\';
    if (ch == '{' && !isEscaped) {
      depth++;
    } else if (ch == '}' && !isEscaped) {
      if (depth == 0) continue;
      depth--;
    }
    buf.write(ch);
  }
  for (var i = 0; i < depth; i++) {
    buf.write('}');
  }

  return buf.toString();
}
