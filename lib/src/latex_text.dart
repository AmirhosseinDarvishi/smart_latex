import 'package:flutter/material.dart';

import 'math/flutter_math.dart';
import 'sanitizer.dart';

/// Builds the fallback widget shown when a LaTeX segment fails to render.
///
/// [raw] is the original delimited source (including the `$`/`\(` markers),
/// [content] is the sanitized math body, and [style] is the effective text
/// style for that segment.
typedef LatexErrorBuilder = Widget Function(
  BuildContext context,
  String raw,
  String content,
  TextStyle style,
);

/// A widget that renders a string containing a mix of plain text and LaTeX
/// mathematics, with automatic clean-up of malformed LaTeX.
///
/// Recognised delimiters:
///
/// | Delimiter      | Mode    |
/// |----------------|---------|
/// | `$ ... $`      | inline  |
/// | `\( ... \)`    | inline  |
/// | `$$ ... $$`    | display |
/// | `\[ ... \]`    | display |
///
/// Each math segment is passed through [sanitizeLatex] (unless [sanitize] is
/// `false`) before being handed to `flutter_math_fork`, so malformed input is
/// corrected automatically.
///
/// Only the font size and color of [style] are forwarded to the math renderer;
/// font family, line height and letter spacing are intentionally dropped
/// because they corrupt KaTeX's internal metrics and can trigger layout
/// assertion errors — this is what makes the widget safe to use inside RTL /
/// custom-font layouts.
class SmartLatexText extends StatelessWidget {
  const SmartLatexText(
    this.text, {
    super.key,
    this.style,
    this.textAlign = TextAlign.start,
    this.textDirection = TextDirection.ltr,
    this.softWrap = true,
    this.maxLines,
    this.overflow = TextOverflow.clip,
    this.textScaler,
    this.hideTrailingIncompleteMath = false,
    this.selectable = false,
    this.sanitize = true,
    this.sanitizeOptions = const LatexSanitizeOptions(),
    this.errorBuilder,
    this.scrollDisplayMath = true,
  });

  /// The source string. May contain plain text, inline math and display math.
  final String text;

  /// Base text style. Merges over `DefaultTextStyle`.
  final TextStyle? style;

  /// How the plain-text runs are horizontally aligned. Defaults to
  /// [TextAlign.start].
  final TextAlign textAlign;

  /// Direction of the surrounding text. Math segments are always laid out
  /// left-to-right regardless of this value. Defaults to [TextDirection.ltr].
  final TextDirection textDirection;

  /// Whether the text should break at soft line breaks. Defaults to `true`.
  final bool softWrap;

  /// Optional cap on the number of lines for the inline text runs.
  final int? maxLines;

  /// How visual overflow of the inline text is handled. Defaults to
  /// [TextOverflow.clip].
  final TextOverflow overflow;

  /// Scale factor applied to both the text and the math. Defaults to the
  /// ambient [MediaQuery] text scaler.
  final TextScaler? textScaler;

  /// Hide an unclosed trailing math delimiter instead of showing it as raw
  /// text. Useful while streaming or animating text character by character.
  final bool hideTrailingIncompleteMath;

  /// Make the rendered text selectable. Note: math segments are never
  /// selectable; only the plain-text runs are.
  final bool selectable;

  /// Whether to run [sanitizeLatex] on each math segment. Disable if your
  /// input is already known-good LaTeX.
  final bool sanitize;

  /// Options forwarded to [sanitizeLatex] when [sanitize] is `true`.
  final LatexSanitizeOptions sanitizeOptions;

  /// Builds the fallback shown when a math segment cannot be rendered.
  /// Defaults to showing the raw source as plain text.
  final LatexErrorBuilder? errorBuilder;

  /// Wrap display math in a horizontal scroll view so wide equations don't
  /// overflow. Set to `false` to let them clip / shrink instead.
  final bool scrollDisplayMath;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = DefaultTextStyle.of(context).style.merge(style);
    final scaler = textScaler ?? MediaQuery.textScalerOf(context);
    final segments = _LatexParser.parse(
      text,
      hideTrailingIncompleteMath: hideTrailingIncompleteMath,
      sanitize: sanitize,
      sanitizeOptions: sanitizeOptions,
    );
    final hasMath = segments.any((s) => s.isMath);

    if (!hasMath) {
      final plain = segments.map((s) => s.raw).join();
      if (selectable) {
        return SelectableText(
          plain,
          style: effectiveStyle,
          textAlign: textAlign,
          textDirection: textDirection,
          maxLines: maxLines,
          textScaler: scaler,
        );
      }
      return Text(
        plain,
        style: effectiveStyle,
        textAlign: textAlign,
        textDirection: textDirection,
        softWrap: softWrap,
        maxLines: maxLines,
        overflow: overflow,
        textScaler: scaler,
      );
    }

    final blocks = _buildBlocks(context, segments, effectiveStyle, scaler);
    if (blocks.length == 1) return blocks.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: blocks,
    );
  }

  // Only fontSize and color reach the math renderer. See class docs.
  TextStyle _mathStyle(TextStyle s) =>
      TextStyle(fontSize: s.fontSize, color: s.color);

  List<Widget> _buildBlocks(
    BuildContext context,
    List<_Segment> segs,
    TextStyle style,
    TextScaler scaler,
  ) {
    final blocks = <Widget>[];
    final inline = <_Segment>[];

    void flush() {
      if (inline.isEmpty) return;
      blocks.add(_buildInline(context, List.of(inline), style, scaler));
      inline.clear();
    }

    for (final seg in segs) {
      if (seg.isDisplayMath) {
        flush();
        blocks.add(_buildDisplay(context, seg, style, scaler));
      } else {
        inline.add(seg);
      }
    }
    flush();
    return blocks;
  }

  Widget _buildInline(
    BuildContext context,
    List<_Segment> segs,
    TextStyle style,
    TextScaler scaler,
  ) {
    final mathStyle = _mathStyle(style);
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          for (final seg in segs)
            if (seg.isMath)
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  // UnconstrainedBox removes the minimum-height constraint that
                  // Text.rich imposes on WidgetSpan children; without it, a
                  // small glyph (e.g. a bare parenthesis) can violate
                  // flutter_math_fork's internal size assertions.
                  child: UnconstrainedBox(
                    child: Math.tex(
                      seg.content,
                      mathStyle: MathStyle.text,
                      textScaleFactor: scaler.scale(1),
                      textStyle: mathStyle,
                      onErrorFallback: (_) =>
                          _fallback(context, seg, style),
                    ),
                  ),
                ),
              )
            else
              TextSpan(text: seg.raw),
        ],
      ),
      textAlign: textAlign,
      textDirection: textDirection,
      softWrap: softWrap,
      maxLines: maxLines,
      overflow: overflow,
      textScaler: scaler,
    );
  }

  Widget _buildDisplay(
    BuildContext context,
    _Segment seg,
    TextStyle style,
    TextScaler scaler,
  ) {
    final math = Math.tex(
      seg.content,
      mathStyle: MathStyle.display,
      textScaleFactor: scaler.scale(1),
      textStyle: _mathStyle(style),
      onErrorFallback: (_) => _fallback(context, seg, style),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: Alignment.center,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: scrollDisplayMath
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: math,
                )
              : math,
        ),
      ),
    );
  }

  Widget _fallback(BuildContext context, _Segment seg, TextStyle style) {
    if (errorBuilder != null) {
      return errorBuilder!(context, seg.raw, seg.content, style);
    }
    return Text(
      seg.raw,
      textAlign: textAlign,
      textDirection: textDirection,
      style: style,
    );
  }
}

// ---------------------------------------------------------------------------
// Internal parser
// ---------------------------------------------------------------------------

class _Segment {
  const _Segment.text(this.raw)
      : content = raw,
        isMath = false,
        isDisplayMath = false;

  const _Segment.math({
    required this.raw,
    required this.content,
    required this.isDisplayMath,
  }) : isMath = true;

  final String raw;
  final String content;
  final bool isMath;
  final bool isDisplayMath;
}

class _Delim {
  const _Delim({
    required this.start,
    required this.open,
    required this.close,
    required this.isDisplay,
  });

  final int start;
  final String open;
  final String close;
  final bool isDisplay;

  int get contentStart => start + open.length;
}

class _LatexParser {
  static List<_Segment> parse(
    String src, {
    required bool hideTrailingIncompleteMath,
    required bool sanitize,
    required LatexSanitizeOptions sanitizeOptions,
  }) {
    final out = <_Segment>[];
    var cursor = 0;

    while (cursor < src.length) {
      final delim = _next(src, cursor);
      if (delim == null) {
        _addText(out, src.substring(cursor));
        break;
      }

      final closeAt = _findClose(src, delim.contentStart, delim.close);
      if (closeAt == -1) {
        if (delim.start > cursor) {
          _addText(out, src.substring(cursor, delim.start));
        }
        if (!hideTrailingIncompleteMath) {
          _addText(out, src.substring(delim.start));
        }
        break;
      }

      if (delim.start > cursor) {
        _addText(out, src.substring(cursor, delim.start));
      }

      final end = closeAt + delim.close.length;
      final raw = src.substring(delim.start, end);
      final body = src.substring(delim.contentStart, closeAt).trim();

      if (body.isEmpty) {
        _addText(out, raw);
      } else {
        out.add(_Segment.math(
          raw: raw,
          content: sanitize
              ? sanitizeLatex(body, options: sanitizeOptions)
              : body,
          isDisplayMath: delim.isDisplay,
        ));
      }
      cursor = end;
    }
    return out;
  }

  static void _addText(List<_Segment> out, String t) {
    if (t.isNotEmpty) out.add(_Segment.text(t));
  }

  static _Delim? _next(String src, int from) {
    for (var i = from; i < src.length; i++) {
      // Order matters: longer / more specific delimiters first.
      if (src.startsWith(r'$$', i) && !_escaped(src, i)) {
        return _Delim(start: i, open: r'$$', close: r'$$', isDisplay: true);
      }
      if (src.startsWith(r'\\[', i)) {
        return _Delim(start: i, open: r'\\[', close: r'\\]', isDisplay: true);
      }
      if (src.startsWith(r'\[', i)) {
        return _Delim(start: i, open: r'\[', close: r'\]', isDisplay: true);
      }
      if (src.startsWith(r'\\(', i)) {
        return _Delim(start: i, open: r'\\(', close: r'\\)', isDisplay: false);
      }
      if (src.startsWith(r'\(', i)) {
        return _Delim(start: i, open: r'\(', close: r'\)', isDisplay: false);
      }
      if (src.codeUnitAt(i) == 36 /* $ */ && !_escaped(src, i)) {
        return _Delim(start: i, open: r'$', close: r'$', isDisplay: false);
      }
    }
    return null;
  }

  static int _findClose(String src, int from, String close) {
    for (var i = from; i <= src.length - close.length; i++) {
      if (!src.startsWith(close, i)) continue;
      if (close.contains(r'$') && _escaped(src, i)) continue;
      return i;
    }
    return -1;
  }

  static bool _escaped(String src, int idx) {
    var slashes = 0;
    for (var i = idx - 1; i >= 0 && src.codeUnitAt(i) == 92; i--) {
      slashes++;
    }
    return slashes.isOdd;
  }
}
