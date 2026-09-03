/// Mirror — spec §6 row 3. Reflects a beam 90 degrees.
library;

import 'dart:ui';

import '../../../core/tokens.dart';
import 'tool_component.dart';

class MirrorComponent extends ToolComponent {
  MirrorComponent({
    required super.def,
    required super.row,
    required super.col,
    required super.center,
  });

  static final Path _diamond = Path()
    ..moveTo(20, 7)
    ..lineTo(33, 20)
    ..lineTo(20, 33)
    ..lineTo(7, 20)
    ..close();

  static final Paint _fill = Paint()..color = C.mirrorMetal;
  static final Paint _border = Paint()
    ..color = C.mirrorEdge
    ..style = PaintingStyle.stroke
    ..strokeWidth = R.hp;
  static final Paint _highlight = Paint()
    ..color = C.textPrimary
    ..style = PaintingStyle.stroke
    ..strokeWidth = R.hp
    ..strokeCap = StrokeCap.round;

  @override
  void renderGlyph(Canvas canvas) {
    canvas.drawPath(_diamond, _fill);
    canvas.drawPath(_diamond, _border);
    canvas.drawLine(const Offset(14, 14), const Offset(26, 26), _highlight);
  }
}
