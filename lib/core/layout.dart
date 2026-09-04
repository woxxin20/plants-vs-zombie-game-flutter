/// Landscape layout maths — spec §11. Computed once per resize and read by the
/// grid, the HUD and every component that needs to convert between tile and
/// world coordinates.
library;

import 'dart:math' as math;

import 'package:flame/components.dart';

import '../data/models.dart';
import 'tokens.dart';

/// Design baseline the visible game size is pinned to (spec §11).
final Vector2 kBaselineSize = Vector2(812, 375);

class BattleLayout {
  BattleLayout(this.size)
    : tile = _tileFor(size),
      gridW = size.x - S.rightPanelW - S.screenPad * 3,
      gridH = size.y - S.topBarH - S.screenPad * 2;

  final Vector2 size;

  /// Square tile edge, the min of the row- and column-derived sizes (~72).
  final double tile;

  final double gridW;
  final double gridH;

  static double _tileFor(Vector2 size) {
    final gridH = size.y - S.topBarH - S.screenPad * 2;
    final gridW = size.x - S.rightPanelW - S.screenPad * 3;
    final tileH = (gridH - (kRows - 1) * S.tileGap) / kRows;
    final tileW = (gridW - (kCols - 1) * S.tileGap) / kCols;
    return math.min(tileH, tileW);
  }

  /// Total pixel size of the 3x7 board including gaps.
  double get boardW => kCols * tile + (kCols - 1) * S.tileGap;
  double get boardH => kRows * tile + (kRows - 1) * S.tileGap;

  /// Board origin in world space — centred inside the area left of the panel.
  Vector2 get origin => Vector2(
    S.screenPad + (gridW - boardW) / 2,
    S.topBarH + S.screenPad + (gridH - boardH) / 2,
  );

  /// Top-left corner of a tile in world space.
  Vector2 tileTopLeft(int row, int col) => Vector2(
    origin.x + col * (tile + S.tileGap),
    origin.y + row * (tile + S.tileGap),
  );

  /// Centre of a tile in world space.
  Vector2 tileCenter(int row, int col) =>
      tileTopLeft(row, col) + Vector2.all(tile / 2);

  /// Vertical centre of a lane.
  double laneCenterY(int lane) =>
      origin.y + lane * (tile + S.tileGap) + tile / 2;

  /// World x where a shadow spawns: one tool-width past the right board edge.
  double get spawnX => origin.x + boardW + 32;

  /// Fractional column of a world x — what the beam tracer and the eating
  /// check both need. Can go negative (past the Light Core) or above kCols.
  double colFromX(double x) => (x - origin.x) / (tile + S.tileGap);

  /// Integer column under a world x, or null when off the board.
  int? tileColFromX(double x) {
    final c = colFromX(x).floor();
    return (c < 0 || c >= kCols) ? null : c;
  }

  /// Lane under a world y, or null when off the board.
  int? laneFromY(double y) {
    final r = ((y - origin.y) / (tile + S.tileGap)).floor();
    return (r < 0 || r >= kRows) ? null : r;
  }

  /// The sweep stripe, one per lane, hugging the left board edge (spec §5).
  double get sweepStripeW => 12.0;
  double get sweepStripeX => origin.x - sweepStripeW - S.tileGap;
}
