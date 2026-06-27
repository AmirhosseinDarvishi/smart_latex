import 'package:flutter/material.dart';
import 'package:smart_latex/smart_latex.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'smart_latex example',
      theme: ThemeData(useMaterial3: true),
      home: const _HomePage(),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    final bodyStyle = Theme.of(context).textTheme.bodyLarge!.copyWith(
          height: 1.8,
        );

    final items = <Widget>[
      // Inline math mixed with text.
      SmartLatexText(
        r'The quadratic formula is $x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}$.',
        style: bodyStyle,
      ),

      // Display (block) math via SmartMath.
      const SmartMath(r'e^{i\pi} + 1 = 0', display: true),

      // Display math via $$...$$ inside SmartLatexText.
      SmartLatexText(
        r'$$\int_0^\infty e^{-x^2}\,dx = \frac{\sqrt{\pi}}{2}$$',
        style: bodyStyle,
      ),

      // Malformed input: Persian digits + double backslash + \text wrappers.
      SmartLatexText(
        r'حاصل عبارت $\frac{{\text{0}\text{٫}\overline{\text{3}}-\text{0}\text{٫}\text{5}}}'
        r'{{\sqrt{{{\left(\text{1}-\text{2}\sqrt{{\text{2}}}\\right)}^{\text{2}}}}-\sqrt{{\text{8}}}-\text{1}}}$ کدام است؟',
        textDirection: TextDirection.rtl,
        style: bodyStyle,
      ),

      // RTL text with a small inline formula.
      SmartLatexText(
        r'قضیه فیثاغورس: $a^2 + b^2 = c^2$',
        textDirection: TextDirection.rtl,
        style: bodyStyle,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('smart_latex')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 32),
        itemBuilder: (_, i) => items[i],
      ),
    );
  }
}
