import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_latex/smart_latex.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('SmartLatexText delimiter parsing', () {
    testWidgets('renders \\[ ... \\] display math without leaking raw markers',
        (tester) async {
      await tester.pumpWidget(_wrap(const SmartLatexText(r'\[x^2 + 1\]')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // The raw display markers must be consumed, not shown as text.
      expect(find.textContaining(r'\['), findsNothing);
      expect(find.textContaining(r'\]'), findsNothing);
    });

    testWidgets(r'renders $$ ... $$ display math without leaking raw markers',
        (tester) async {
      await tester.pumpWidget(_wrap(const SmartLatexText(r'$$a+b$$')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.textContaining(r'$$'), findsNothing);
    });

    testWidgets('treats an escaped \\\$ as literal text, not a delimiter',
        (tester) async {
      await tester.pumpWidget(_wrap(const SmartLatexText(r'price is \$5 today')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // No math segment opened, so the surrounding text is intact.
      expect(find.textContaining(r'\$5'), findsOneWidget);
    });

    testWidgets('keeps surrounding text around inline math', (tester) async {
      await tester.pumpWidget(
        _wrap(const SmartLatexText(r'before $x$ after')),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(SmartLatexText), findsOneWidget);
    });

    testWidgets('display math produces a multi-block column', (tester) async {
      await tester.pumpWidget(
        _wrap(const SmartLatexText(r'intro $$x^2$$ outro')),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // Plain text before/after a display block forces block layout.
      expect(find.textContaining('intro'), findsOneWidget);
      expect(find.textContaining('outro'), findsOneWidget);
    });

    testWidgets('empty math body is rendered as literal text', (tester) async {
      await tester.pumpWidget(_wrap(const SmartLatexText(r'empty $$ here')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('unterminated math is shown raw when not hiding',
        (tester) async {
      await tester.pumpWidget(_wrap(const SmartLatexText(r'tail $x^2')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.textContaining(r'$x^2'), findsOneWidget);
    });
  });
}
