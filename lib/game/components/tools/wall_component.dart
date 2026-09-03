/// Shade Block — spec §6 row 6. Blocks a lane, takes no attack itself.
library;

import 'dart:ui';

import '../../../core/tokens.dart';
import 'tool_component.dart';

class WallComponent extends ToolComponent {
  WallComponent({
    required super.def,
    required super.row,
    required super.col,
    required super.center,
  });

  // 2x2 bricks inside a 32x32 area (4..36), separated by an S.x1 mortar gap.
  static final Rect _mortar = Rect.fromLTWH(
    S.x1,
    S.x1,
    kToolGlyph - 2 * S.x1,
    kToolGlyph - 2 * S.x1,
  );
  static const double _brick = 10;
  static const double _b0 = S.x1 + S.x1; // mortar edge gap + inter-brick gap
  static const double _b1 = _b0 + _brick + S.x1;
  static final List<Rect> _bricks = [
    Rect.fromLTWH(_b0, _b0, _brick, _brick),
    Rect.fromLTWH(_b1, _b0, _brick, _brick),
    Rect.fromLTWH(_b0, _b1, _brick, _brick),
    Rect.fromLTWH(_b1, _b1, _brick, _brick),
  ];

  static final Paint _mortarPaint = Paint()..color = C.wallMortar;
  static final Paint _brickPaint = Paint()..color = C.wallBlock;

  @override
  void renderGlyph(Canvas canvas) {
    canvas.drawRect(_mortar, _mortarPaint);
    for (final b in _bricks) {
      canvas.drawRect(b, _brickPaint);
    }
  }
}
