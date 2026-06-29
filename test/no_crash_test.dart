import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_latex/smart_latex.dart';

Widget _wrap(Widget c) => MaterialApp(home: Scaffold(body: Center(child: c)));

void main() {
  testWidgets('vendored engine renders the sqrt-in-frac formula without crash',
      (tester) async {
    await tester.pumpWidget(_wrap(const SmartLatexText(
      r'$\frac{{\text{0}\text{٫}\overline{\text{3}}-\text{0}\text{٫}\text{5}}}'
      r'{{\sqrt{{{\left(\text{1}-\text{2}\sqrt{{\text{2}}}\\right)}^{\text{2}}}}'
      r'-\sqrt{{\text{8}}}-\text{1}}}$',
      textDirection: TextDirection.rtl,
    )));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('plain sqrt with delimiters renders without crash',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const SmartMath(r'\sqrt{\left(1-2\sqrt{2}\right)^{2}}', display: true),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
