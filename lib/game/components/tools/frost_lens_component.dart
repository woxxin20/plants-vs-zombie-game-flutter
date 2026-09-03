/// Frost Lens — spec §6 row 5. 15 dmg + slows 50% for 2s.
library;

import 'dart:math' as math;
import 'dart:ui';

import '../../../core/tokens.dart';
import 'tool_component.dart';

class FrostLensComponent extends ToolComponent {
  FrostLensComponent({
    required super.def,
    required super.row,
    required super.col,
    required super.center,
  });

  static const double _armLen = 15;

  static final Paint _bg = Paint()..color = C.secondary.withValues(alpha: 0.2);
  static final Paint _arm = Paint()
    ..color = C.secondary
    ..style = PaintingStyle.stroke
    ..strokeWidth = R.hp
    ..strokeCap = StrokeCap.round;

  @override
  void renderGlyph(Canvas canvas) {
    const center = Offset(20, 20);
    canvas.drawCircle(center, _armLen + S.x1, _bg);
    for (var i = 0; i < 3; i++) {
      final a = i * math.pi / 3;
      final d = Offset(math.cos(a), math.sin(a)) * _armLen;
      canvas.drawLine(center - d, center + d, _arm);
    }
  }
}
