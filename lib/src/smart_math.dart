import 'package:flutter/material.dart';

import 'math/flutter_math.dart';
import 'sanitizer.dart';

/// Renders a single LaTeX math expression (no surrounding plain text).
///
/// Use this when the whole string is one formula. For mixed text + math use
/// `SmartLatexText` instead.
///
/// The input is cleaned with [sanitizeLatex] (unless [sanitize] is `false`)
/// and only the font size and color of [style] are forwarded to the renderer
/// to keep KaTeX metrics independent of the surrounding theme.
class SmartMath extends StatelessWidget {
  const SmartMath(
    this.expression, {
    super.key,
    this.style,
    this.display = false,
    this.sanitize = true,
    this.sanitizeOptions = const LatexSanitizeOptions(),
    this.scrollable = true,
    this.textScaler,
    this.errorBuilder,
  });

  /// The LaTeX expression, without delimiters (no surrounding `$`).
  final String expression;

  /// Base style. Only `fontSize` and `color` are used by the renderer.
  final TextStyle? style;

  /// Render in display style (larger, centered) instead of inline style.
  final bool display;

  /// Whether to run [sanitizeLatex] on [expression].
  final bool sanitize;

  /// Options for [sanitizeLatex] when [sanitize] is `true`.
  final LatexSanitizeOptions sanitizeOptions;

  /// Wrap in a horizontal scroll view so wide expressions don't overflow.
  final bool scrollable;

  /// Scale factor applied to the rendered math. Defaults to the ambient
  /// [MediaQuery] text scaler.
  final TextScaler? textScaler;

  /// Builds the fallback widget when rendering fails. Receives the sanitized
  /// expression. Defaults to showing it as plain selectable text.
  final Widget Function(BuildContext context, String expression)? errorBuilder;

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style.merge(style);
    final scaler = textScaler ?? MediaQuery.textScalerOf(context);
    final content =
        sanitize ? sanitizeLatex(expression, options: sanitizeOptions) : expression;

    final math = Math.tex(
      content,
      mathStyle: display ? MathStyle.display : MathStyle.text,
      textScaleFactor: scaler.scale(1),
      textStyle: TextStyle(fontSize: base.fontSize, color: base.color),
      onErrorFallback: (_) =>
          errorBuilder?.call(context, content) ??
          SelectableText(content, style: base),
    );

    final wrapped = Directionality(
      textDirection: TextDirection.ltr,
      child: UnconstrainedBox(child: math),
    );

    if (!scrollable) return wrapped;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: wrapped,
    );
  }
}
