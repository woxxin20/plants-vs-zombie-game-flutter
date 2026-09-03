/// Beam Lamp — spec §6 row 2. Fires 20 dmg down its own lane every 1.2s.
library;

import 'dart:ui';

import '../../../core/tokens.dart';
import 'tool_component.dart';

class BeamLampComponent extends ToolComponent {
  BeamLampComponent({
    required super.def,
    required super.row,
    required super.col,
    required super.center,
  });

  static final RRect _body = RRect.fromRectAndRadius(
    const Rect.fromLTWH(6, 13, 12, 14),
    const Radius.circular(R.hp),
  );

  static final Path _cone = Path()
    ..moveTo(18, 14)
    ..lineTo(36, 20)
    ..lineTo(18, 26)
    ..close();

  static final Paint _bodyPaint = Paint()..color = C.textPrimary;
  static final Paint _conePaint = Paint()..color = C.beamCore;
  static final Paint _coneBloom = ToolComponent.bloom(
    C.beamCore,
    Elevation.tool.blur,
  );

  @override
  void renderGlyph(Canvas canvas) {
    canvas.drawPath(_cone, _coneBloom);
    canvas.drawPath(_cone, _conePaint);
    canvas.drawRRect(_body, _bodyPaint);
  }
}
