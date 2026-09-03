/// Twin Bulb — spec §6 row 8. Gen +50/10s, only placeable on an existing Bulb.
library;

import 'dart:ui';

import '../../../core/tokens.dart';
import 'tool_component.dart';

class TwinBulbComponent extends ToolComponent {
  TwinBulbComponent({
    required super.def,
    required super.row,
    required super.col,
    required super.center,
  });

  static const Offset _left = Offset(15, 20);
  static const Offset _right = Offset(25, 20);
  static const double _radius = 8;

  // Brighter than the single Bulb: bloom is drawn once per circle so the
  // overlap doubles up, plus a wider blur radius.
  static final Paint _bloom = ToolComponent.bloom(
    C.primary,
    Elevation.tool.blur + S.x1,
  );
  static final Paint _fill = Paint()..color = C.primary;

  @override
  void renderGlyph(Canvas canvas) {
    canvas.drawCircle(_left, _radius + S.x1, _bloom);
    canvas.drawCircle(_right, _radius + S.x1, _bloom);
    canvas.drawCircle(_left, _radius, _fill);
    canvas.drawCircle(_right, _radius, _fill);
  }
}
