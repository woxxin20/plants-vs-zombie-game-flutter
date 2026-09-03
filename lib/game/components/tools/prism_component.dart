/// Prism — spec §6 row 4. Splits a beam 60% dmg across 3 lanes.
library;

import 'dart:ui';

import '../../../core/tokens.dart';
import 'tool_component.dart';

class PrismComponent extends ToolComponent {
  PrismComponent({
    required super.def,
    required super.row,
    required super.col,
    required super.center,
  });

  static final Path _triangle = Path()
    ..moveTo(20, 7)
    ..lineTo(33, 33)
    ..lineTo(7, 33)
    ..close();

  static final Paint _fill = Paint()
    ..shader = Gradient.linear(
      const Offset(7, 20),
      const Offset(33, 20),
      C.prismSpectrum,
    );

  @override
  void renderGlyph(Canvas canvas) => canvas.drawPath(_triangle, _fill);
}
