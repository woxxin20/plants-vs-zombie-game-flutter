/// Pure gameplay rules: placement validation (§17), wave pacing (§8),
/// win/lose (§16) and scoring (§19). No Flame, no Flutter — all unit-testable.
library;

import 'dart:math' as math;

import 'models.dart';

// ---------------------------------------------------------------------------
// Placement — spec §17. Checks run in order; the first failure is returned.
// ---------------------------------------------------------------------------

PlaceResult validatePlacement({
  required GameState state,
  required int row,
  required int col,
  required ToolDef tool,
  required int glow,
  required double now,
  required Map<String, double> lastPlaced,
  required List<List<String?>> grid,
}) {
  if (state != GameState.playing) return PlaceResult.notPlaying;
  if (row < 0 || row >= kRows || col < 0 || col >= kCols) {
    return PlaceResult.outOfBounds;
  }

  final occupant = grid[row][col];

  // Twin Bulb is the one tool that legally lands on an occupied tile, and only
  // on a Bulb, which it replaces (spec §5). Its own occupancy check therefore
  // runs instead of the generic one, not after it.
  if (tool.id == 'twin') {
    if (occupant != 'bulb') return PlaceResult.needBulb;
  } else if (occupant != null) {
    return PlaceResult.occupied;
  }

  if (glow < tool.cost) return PlaceResult.notEnoughGlow;
  final last = lastPlaced[tool.id];
  if (last != null && now - last < tool.cooldown) return PlaceResult.onCooldown;

  if (tool.id == 'prism' &&
      grid[row].where((t) => t == 'prism').length >= kMaxPrismPerRow) {
    return PlaceResult.maxPrism;
  }

  return PlaceResult.ok;
}

/// Tiles a Flash Bomb damages: its own tile plus one in every direction,
/// clamped to the board (spec §24 edge case 16 — no index error on the rim).
List<({int row, int col})> bombFootprint(int row, int col) {
  final out = <({int row, int col})>[];
  for (var r = row - kBombRadiusTiles; r <= row + kBombRadiusTiles; r++) {
    for (var c = col - kBombRadiusTiles; c <= col + kBombRadiusTiles; c++) {
      if (r < 0 || r >= kRows || c < 0 || c >= kCols) continue;
      out.add((row: r, col: c));
    }
  }
  return out;
}

// ---------------------------------------------------------------------------
// Wave pacing — spec §8, the "50% rule".
// ---------------------------------------------------------------------------

/// Whether the next wave may spawn.
///
/// The first wave only waits for its own delay. Every later wave additionally
/// waits until half the previous wave's HP is gone, OR 20s have passed since
/// the last spawn — so a stalled player still gets pressure, and a fast player
/// is not spammed.
bool canSpawnNextWave({
  required int waveIndex,
  required List<Wave> waves,
  required double time,
  required double lastWaveTime,
  required int previousWaveTotalHp,
  required int previousWaveAliveHp,
}) {
  if (waveIndex >= waves.length) return false;
  if (time < waves[waveIndex].delay) return false;
  if (waveIndex == 0) return true;

  final halfDead =
      previousWaveAliveHp < previousWaveTotalHp * kWaveHalfDeadFraction;
  final timedOut = time - lastWaveTime > kWaveTimeoutSeconds;
  return halfDead || timedOut;
}

// ---------------------------------------------------------------------------
// Terminal state — spec §16 steps 8.
// ---------------------------------------------------------------------------

/// Won when every wave has spawned and no shadow is left standing.
bool hasWon({
  required int waveIndex,
  required int waveCount,
  required int shadowsAlive,
}) => waveIndex >= waveCount && shadowsAlive == 0;

/// Lost when a shadow reaches the Light Core in a lane whose sweep is spent.
bool hasLost({
  required Iterable<({double x, int lane})> shadows,
  required List<bool> sweepAvailable,
}) => shadows.any((s) => s.x <= 0 && !sweepAvailable[s.lane]);

// ---------------------------------------------------------------------------
// Scoring — spec §19 stores stars/coins but does not define the star formula.
//
// ASSUMPTION (documented, reversible — see docs/prd.md open decisions):
//   1 star  win at all
//   2 stars win and finish within par time
//   3 stars win within par time AND with every sweep still unused
// Rationale: the two levers the player actually controls are speed and whether
// their light net ever leaked. Change the thresholds here only, never inline.
// ---------------------------------------------------------------------------

int starsFor({
  required double elapsed,
  required double parTime,
  required List<bool> sweepAvailable,
}) {
  final inPar = elapsed <= parTime;
  final noLeak = sweepAvailable.every((s) => s);
  if (inPar && noLeak) return 3;
  if (inPar || noLeak) return 2;
  return 1;
}

/// Coins awarded for a win — spec §19: a fresh best pays the delta plus a
/// bonus, a repeat clear pays a flat 10.
int coinsFor({required int previousStars, required int newStars}) =>
    newStars > previousStars ? (newStars - previousStars) * 10 + 20 : 10;

/// Deterministic offline daily level: same for every device, no server.
/// Spec §19 uses day-of-year modulo the level count.
int dailyLevelId(DateTime now, {int levelCount = 20}) {
  final dayOfYear = now.difference(DateTime(now.year)).inDays + 1;
  return (dayOfYear % levelCount) + 1;
}

/// Glow is clamped at 999 (spec §24 edge case 17).
int clampGlow(int glow) => math.min(kGlowMax, math.max(0, glow));
