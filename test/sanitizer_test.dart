import 'package:flutter_test/flutter_test.dart';
import 'package:smart_latex/smart_latex.dart';

void main() {
  group('sanitizeLatex', () {
    test('fixes double-backslash before command names', () {
      expect(
        sanitizeLatex(r'\left(1-2\sqrt{2}\\right)'),
        r'\left(1-2\sqrt{2}\right)',
      );
    });

    test('fixes \\sqt typo', () {
      expect(sanitizeLatex(r'\sqt{2}'), r'\sqrt{2}');
    });

    test('converts Persian digits to ASCII', () {
      expect(sanitizeLatex('۱۲۳'), '123');
      expect(sanitizeLatex('٤٥٦'), '456');
    });

    test('converts Persian decimal separator', () {
      expect(sanitizeLatex('۱٫۵'), '1.5');
    });

    test('unwraps single digits from \\text{}', () {
      expect(
        sanitizeLatex(r'\text{0}\text{.}\overline{\text{3}}'),
        r'0.\overline{3}',
      );
    });

    test('unwraps single punctuation from \\text{}', () {
      expect(sanitizeLatex(r'\text{+}'), '+');
      expect(sanitizeLatex(r'\text{=}'), '=');
    });

    test('keeps multi-character \\text{} intact', () {
      expect(sanitizeLatex(r'\text{abc}'), r'\text{abc}');
    });

    test('balances unmatched closing brace', () {
      expect(sanitizeLatex(r'\frac{1}{2}}'), r'\frac{1}{2}');
    });

    test('appends missing closing brace', () {
      expect(sanitizeLatex(r'\frac{1}{2'), r'\frac{1}{2}');
    });

    test('leaves an empty string untouched', () {
      expect(sanitizeLatex(''), '');
    });

    test('leaves a well-formed formula untouched', () {
      const ok = r'\frac{-b \pm \sqrt{b^2 - 4ac}}{2a}';
      expect(sanitizeLatex(ok), ok);
    });

    test('does not collapse a spaced \\\\ row break', () {
      // A genuine row break is followed by whitespace, so it is preserved.
      const matrix = r'\begin{matrix}a \\ b\end{matrix}';
      expect(sanitizeLatex(matrix), matrix);
    });

    test('documents that a tight \\\\letter row break is collapsed', () {
      // Known limitation: no space after `\\` looks like a malformed command.
      expect(
        sanitizeLatex(r'\begin{matrix}a\\b\end{matrix}'),
        r'\begin{matrix}a\b\end{matrix}',
      );
    });

    test('handles a full malformed formula', () {
      const input =
          r'\frac{{\text{0}\text{٫}\overline{\text{3}}-\text{0}\text{٫}\text{5}}}'
          r'{{\sqrt{{{\left(\text{1}-\text{2}\sqrt{{\text{2}}}\\right)}^{\text{2}}}}'
          r'-\sqrt{{\text{8}}}-\text{1}}}';
      final out = sanitizeLatex(input);
      expect(out.contains(r'\\right'), isFalse);
      expect(out.contains('٫'), isFalse);
      expect(out.contains(r'\text{0}'), isFalse);
      expect(out.contains(r'\right)'), isTrue);
    });
  });

  group('LatexSanitizeOptions', () {
    test('none() applies no changes', () {
      const input = r'\text{0}\\right ۱٫۵ }';
      expect(
        sanitizeLatex(input, options: const LatexSanitizeOptions.none()),
        input,
      );
    });

    test('can disable digit normalization only', () {
      final out = sanitizeLatex(
        r'\sqt ۱',
        options: const LatexSanitizeOptions(normalizeDigits: false),
      );
      expect(out.contains(r'\sqrt'), isTrue);
      expect(out.contains('۱'), isTrue);
    });

    test('can disable brace balancing only', () {
      final out = sanitizeLatex(
        r'{a',
        options: const LatexSanitizeOptions(balanceBraces: false),
      );
      expect(out, r'{a');
    });
  });
}
