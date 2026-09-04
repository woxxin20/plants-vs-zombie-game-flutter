/// L4 — the 3x7 board. 21 independent `TileComponent` children rather than one
/// painted grid, so a single tile can shake, highlight or flash on its own
/// (spec §5).
library;

import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';

import '../../core/layout.dart';
import '../../core/tokens.dart';
import '../../data/models.dart';
import 'backdrop_layers.dart' show P;

/// What a tile should look like right now — drives the fill/border pair.
enum TileMood { idle, valid, invalid }

class GridComponent extends PositionComponent {
  GridComponent({required this.layout, required this.onTileTap})
    : super(priority: P.grid);

  final BattleLayout layout;
  final void Function(int row, int col) onTileTap;

  final List<List<TileComponent>> tiles = [];

  /// Sweeps still available, one per lane (spec §5). The battle world flips
  /// these; the grid only draws them.
  final List<bool> sweepAvailable = List<bool>.filled(kRows, true);

  @override
  Future<void> onLoad() async {
    for (var r = 0; r < kRows; r++) {
      final row = <TileComponent>[];
      for (var c = 0; c < kCols; c++) {
        final t = TileComponent(
          row: r,
          col: c,
          edge: layout.tile,
          onTap: () => onTileTap(r, c),
        )..position = layout.tileTopLeft(r, c);
        row.add(t);
        await add(t);
      }
      tiles.add(row);
    }
  }

  TileComponent tileAt(int row, int col) => tiles[row][col];

  static final _dividerPaint = Paint()
    ..color = C.laneDivider
    ..strokeWidth = 1;

  static final _sweepPaint = Paint()..color = C.sweepStripe;
  static final _sweepArrow = Paint()
    ..color = C.primary
    ..style = PaintingStyle.fill;

  @override
  void render(Canvas canvas) {
    final o = layout.origin;

    // Dashed lane dividers, 4 on / 4 off (spec §11).
    for (var r = 1; r < kRows; r++) {
      final y = o.y + r * (layout.tile + S.tileGap) - S.tileGap / 2;
      for (var x = o.x; x < o.x + layout.boardW; x += 8) {
        canvas.drawLine(Offset(x, y), Offset(x + 4, y), _dividerPaint);
      }
    }

    // Sweep stripe per lane, hidden once spent.
    for (var lane = 0; lane < kRows; lane++) {
      if (!sweepAvailable[lane]) continue;
      final y = o.y + lane * (layout.tile + S.tileGap);
      final rect = Rect.fromLTWH(
        layout.sweepStripeX,
        y,
        layout.sweepStripeW,
        layout.tile,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(R.hp)),
        _sweepPaint,
      );
      // Hand-drawn right-pointing triangle, never a Material icon.
      final cx = rect.center.dx;
      final cy = rect.center.dy;
      final path = Path()
        ..moveTo(cx - 3, cy - 6)
        ..lineTo(cx + 4, cy)
        ..lineTo(cx - 3, cy + 6)
        ..close();
      canvas.drawPath(path, _sweepArrow);
    }
  }
}

class TileComponent extends PositionComponent with TapCallbacks {
  TileComponent({
    required this.row,
    required this.col,
    required double edge,
    required this.onTap,
  }) : super(size: Vector2.all(edge));

  final int row;
  final int col;
  final void Function() onTap;

  TileMood mood = TileMood.idle;

  /// True while a tool occupies this tile — changes the fill only.
  bool occupied = false;

  bool _shaking = false;

  /// Spec §17 fail UI: 4px shake, 80ms, on an illegal placement.
  void shake() {
    if (_shaking) return;
    _shaking = true;
    add(
      MoveByEffect(
        Vector2(S.tileGap, 0),
        EffectController(duration: 0.08, alternate: true, repeatCount: 2),
        onComplete: () => _shaking = false,
      ),
    );
  }

  static final _fill = Paint();
  static final _border = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  (Color, Color) get _colors => switch (mood) {
    TileMood.valid => (C.successBg, C.successBorder),
    TileMood.invalid => (C.errorBg, C.errorBorder),
    TileMood.idle => (occupied ? C.surface2 : C.gridEmpty, C.gridBorder),
  };

  @override
  void render(Canvas canvas) {
    final (fill, border) = _colors;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size.toSize(),
      const Radius.circular(R.tile),
    );
    canvas.drawRRect(rrect, _fill..color = fill);
    canvas.drawRRect(rrect, _border..color = border);
  }

  @override
  void onTapUp(TapUpEvent event) => onTap();

  /// The tile itself is the drop target for a dragged tray slot.
  ShapeHitbox get hitbox => RectangleHitbox(size: size);
}
