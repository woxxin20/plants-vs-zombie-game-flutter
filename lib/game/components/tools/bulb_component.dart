/// Glow Bulb — spec §6 row 1. Generates +25 glow every 10s.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';

import '../../../core/tokens.dart';
import 'tool_component.dart';

class BulbComponent extends ToolComponent {
  BulbComponent({
    required super.def,
    required super.row,
    required super.col,
    required super.center,
  });

  static const double _radius = 9;
  static const double _rayInner = _radius + S.x1;
  static const double _rayOuter = _radius + S.x2;

  static final Paint _bloom = ToolComponent.bloom(C.primary, Elevation.tool.blur);
  static final Paint _fill = Paint()..color = C.primary;
  static final Paint _ray = Paint()
    ..color = C.primary
    ..style = PaintingStyle.stroke
    ..strokeWidth = R.hp
    ..strokeCap = StrokeCap.round;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Idle breathing pulse — spec §4.5 / §18.2.
    add(
      ScaleEffect.to(
        Vector2.all(1.08),
        EffectController(
          duration: D.secs(D.breathe),
          alternate: true,
          infinite: true,
        ),
      ),
    );
  }

  @override
  void renderGlyph(Canvas canvas) {
    const center = Offset(20, 20);
    canvas.drawCircle(center, _radius + S.x1, _bloom);
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2;
      canvas.drawLine(
        center + Offset(math.cos(a), math.sin(a)) * _rayInner,
        center + Offset(math.cos(a), math.sin(a)) * _rayOuter,
        _ray,
      );
    }
    canvas.drawCircle(center, _radius, _fill);
  }
}
