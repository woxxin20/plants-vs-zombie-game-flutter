/// Shared low-level drawing helpers for the HUD layer.
///
/// `T.*` (lib/core/tokens.dart) is `package:flutter/painting.dart`'s
/// `TextStyle` (AUD-011) — the type Flame's own `TextPaint` expects too.
/// `HudLabel` still paints a raw `dart:ui.Paragraph` instead of a Flame
/// `TextComponent`/`TextPaint`, so it converts a `T.*` style to a
/// `dart:ui.TextStyle` via `TextStyle.getTextStyle()` before pushing it —
/// every HUD label still reads its typography and colour from tokens.dart
/// alone, nothing literal.
///
/// `paintSunburst`/`paintPennant`/`paintPauseBars`/`paintStar` are the
/// hand-drawn glyphs spec §10.5 requires in place of Material icons, shared
/// by every HUD component that needs one.
library;

import 'dart:math' as math;
import 'dart:ui' hide TextStyle;
import 'dart:ui' as ui show TextStyle;

import 'package:flame/components.dart';
import 'package:flame/effects.dart' show OpacityProvider;
import 'package:flutter/painting.dart' show TextStyle;

/// A single line of `T.*`-styled text, drawn as a raw `dart:ui.Paragraph`.
///
/// Implements [OpacityProvider] so a stock Flame `OpacityEffect` can target
/// it directly (used for the disabled-button dim and the toast fade).
class HudLabel extends PositionComponent implements OpacityProvider {
  HudLabel(
    String text, {
    required TextStyle style,
    Color? color,
    super.position,
    super.anchor,
  }) : _style = style,
       _color = color {
    this.text = text;
  }

  TextStyle _style;
  Color? _color;
  String _text = '';
  double _opacity = 1.0;
  late Paragraph _paragraph;

  String get text => _text;
  set text(String value) {
    _text = value;
    _rebuild();
  }

  set style(TextStyle value) {
    _style = value;
    _rebuild();
  }

  set color(Color? value) {
    _color = value;
    _rebuild();
  }

  @override
  double get opacity => _opacity;

  @override
  set opacity(double value) {
    _opacity = value;
    _rebuild();
  }

  void _rebuild() {
    final builder = ParagraphBuilder(ParagraphStyle())
      ..pushStyle(_style.getTextStyle());
    final c = _color;
    if (c != null) {
      builder.pushStyle(
        ui.TextStyle(color: c.withValues(alpha: c.a * _opacity)),
      );
    }
    builder.addText(_text);
    _paragraph = builder.build()
      ..layout(const ParagraphConstraints(width: double.infinity));
    size = Vector2(_paragraph.maxIntrinsicWidth, _paragraph.height);
  }

  @override
  void render(Canvas canvas) => canvas.drawParagraph(_paragraph, Offset.zero);
}

/// Hand-drawn ray-burst "glow" icon, `size` square, centred on [center].
void paintSunburst(Canvas canvas, Offset center, double size, Color color) {
  final r = size * 0.28;
  canvas.drawCircle(center, r, Paint()..color = color);
  final stroke = Paint()
    ..color = color
    ..strokeWidth = size * 0.12
    ..strokeCap = StrokeCap.round;
  const rays = 8;
  for (var i = 0; i < rays; i++) {
    final a = (i / rays) * 2 * math.pi;
    final dir = Offset(math.cos(a), math.sin(a));
    canvas.drawLine(
      center + dir * (r + size * 0.1),
      center + dir * (size * 0.5),
      stroke,
    );
  }
}

/// Hand-drawn flag pennant (flag-wave marker), `size` tall, centred on [center].
void paintPennant(Offset center, double size, Color color, Canvas canvas) {
  final top = center.translate(0, -size / 2);
  final bottom = center.translate(0, size / 2);
  canvas.drawLine(
    top,
    bottom,
    Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round,
  );
  final flag = Path()
    ..moveTo(top.dx, top.dy)
    ..lineTo(top.dx + size * 0.7, top.dy + size * 0.22)
    ..lineTo(top.dx, top.dy + size * 0.44)
    ..close();
  canvas.drawPath(flag, Paint()..color = color);
}

/// Hand-drawn two-bar pause glyph, `size` square, centred on [center].
void paintPauseBars(Canvas canvas, Offset center, double size, Color color) {
  final paint = Paint()..color = color;
  final barW = size * 0.22;
  final barH = size * 0.8;
  final gap = size * 0.2;
  for (final dx in [-(gap / 2 + barW / 2), gap / 2 + barW / 2]) {
    final rect = Rect.fromCenter(
      center: center.translate(dx, 0),
      width: barW,
      height: barH,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(barW / 3)),
      paint,
    );
  }
}

/// Hand-drawn 5-point star, `size` diameter, centred on [center].
void paintStar(
  Canvas canvas,
  Offset center,
  double size,
  Color color, {
  required bool filled,
}) {
  final outerR = size / 2;
  final innerR = size / 4.2;
  final path = Path();
  for (var i = 0; i < 10; i++) {
    final a = -math.pi / 2 + i * math.pi / 5;
    final r = i.isEven ? outerR : innerR;
    final pt = center + Offset(math.cos(a), math.sin(a)) * r;
    if (i == 0) {
      path.moveTo(pt.dx, pt.dy);
    } else {
      path.lineTo(pt.dx, pt.dy);
    }
  }
  path.close();
  canvas.drawPath(
    path,
    filled
        ? (Paint()..color = color)
        : (Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2),
  );
}
