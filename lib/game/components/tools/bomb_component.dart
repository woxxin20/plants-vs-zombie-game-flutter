/// Flash Bomb — spec §6 row 7. 300 dmg in a 3x3 area, instant, not persistent.
library;

import 'dart:ui';

import '../../../core/tokens.dart';
import 'tool_component.dart';

class BombComponent extends ToolComponent {
  BombComponent({
    required super.def,
    required super.row,
    required super.col,
    required super.center,
  });

  static const Offset _center = Offset(20, 22);
  static const double _radius = 10;

  static final Paint _bloom = ToolComponent.bloom(
    C.primary,
    Elevation.tool.blur,
  );
  static final Paint _fill = Paint()..color = C.primary;
  static final Paint _fuse = Paint()
    ..color = C.error
    ..style = PaintingStyle.stroke
    ..strokeWidth = R.hp
    ..strokeCap = StrokeCap.round;
  static final Paint _spark = Paint()..color = C.error;

  static final Path _fusePath = Path()
    ..moveTo(24, 13)
    ..quadraticBezierTo(30, 10, 28, 6);

  @override
  void renderGlyph(Canvas canvas) {
    canvas.drawCircle(_center, _radius + S.x1, _bloom);
    canvas.drawCircle(_center, _radius, _fill);
    canvas.drawPath(_fusePath, _fuse);
    canvas.drawCircle(const Offset(28, 6), R.hp, _spark);
  }
}
