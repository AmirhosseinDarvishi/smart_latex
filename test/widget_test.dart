import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_latex/smart_latex.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders plain text without math', (tester) async {
    await tester.pumpWidget(_wrap(const SmartLatexText('hello world')));
    expect(find.text('hello world'), findsOneWidget);
  });

  testWidgets('renders mixed text and inline math', (tester) async {
    await tester.pumpWidget(
      _wrap(SmartLatexText(r'value $x^2$ here')),
    );
    // The surrounding text is present as a rich-text run.
    expect(find.byType(SmartLatexText), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders display math without throwing', (tester) async {
    await tester.pumpWidget(
      _wrap(const SmartMath(r'\frac{1}{2}', display: true)),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('hides trailing incomplete math while streaming',
      (tester) async {
    await tester.pumpWidget(
      _wrap(const SmartLatexText(
        r'computing $\frac{1}{',
        hideTrailingIncompleteMath: true,
      )),
    );
    // The incomplete "$\frac{1}{" tail should not appear as raw text.
    expect(find.textContaining(r'\frac'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('malformed formula renders without exception', (tester) async {
    await tester.pumpWidget(
      _wrap(SmartLatexText(
        r'$\frac{{\text{0}\text{٫}\text{5}}}{{\left(\text{1}\\right)}}$',
        textDirection: TextDirection.rtl,
      )),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
