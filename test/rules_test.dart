/// Placement (§17), wave pacing (§8), terminal state (§16) and scoring (§19).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:prism_defense/data/models.dart';
import 'package:prism_defense/data/rules.dart';

const bulb = ToolDef(id: 'bulb', cost: 50, hp: 100, cooldown: 5, dmg: 0);
const twin = ToolDef(id: 'twin', cost: 125, hp: 100, cooldown: 15, dmg: 0);
const prism = ToolDef(id: 'prism', cost: 150, hp: 100, cooldown: 15, dmg: 0);

List<List<String?>> emptyGrid() =>
    List.generate(kRows, (_) => List<String?>.filled(kCols, null));

PlaceResult place(
  ToolDef tool, {
  GameState state = GameState.playing,
  int row = 1,
  int col = 1,
  int glow = 999,
  double now = 100,
  Map<String, double>? lastPlaced,
  List<List<String?>>? grid,
}) => validatePlacement(
  state: state,
  row: row,
  col: col,
  tool: tool,
  glow: glow,
  now: now,
  lastPlaced: lastPlaced ?? {},
  grid: grid ?? emptyGrid(),
);

void main() {
  group('placement', () {
    test('a legal placement succeeds', () {
      expect(place(bulb), PlaceResult.ok);
    });

    test('rejects when not playing', () {
      expect(place(bulb, state: GameState.paused), PlaceResult.notPlaying);
    });

    test('rejects out of bounds', () {
      expect(place(bulb, row: -1), PlaceResult.outOfBounds);
      expect(place(bulb, col: kCols), PlaceResult.outOfBounds);
    });

    test('rejects an occupied tile', () {
      final g = emptyGrid()..[1][1] = 'wall';
      expect(place(bulb, grid: g), PlaceResult.occupied);
    });

    test('rejects when glow is short by one', () {
      expect(place(bulb, glow: 49), PlaceResult.notEnoughGlow);
      expect(place(bulb, glow: 50), PlaceResult.ok);
    });

    test('rejects while the tool is cooling down', () {
      expect(
        place(bulb, now: 103, lastPlaced: {'bulb': 100}),
        PlaceResult.onCooldown,
      );
      expect(place(bulb, now: 105, lastPlaced: {'bulb': 100}), PlaceResult.ok);
    });

    test('Twin Bulb needs a Bulb under it and replaces it', () {
      expect(place(twin), PlaceResult.needBulb);

      final onWall = emptyGrid()..[1][1] = 'wall';
      expect(place(twin, grid: onWall), PlaceResult.needBulb);

      final onBulb = emptyGrid()..[1][1] = 'bulb';
      expect(place(twin, grid: onBulb), PlaceResult.ok);
    });

    test('a row holds at most two prisms', () {
      final g = emptyGrid()
        ..[1][2] = 'prism'
        ..[1][4] = 'prism';
      expect(place(prism, grid: g), PlaceResult.maxPrism);

      final one = emptyGrid()..[1][2] = 'prism';
      expect(place(prism, grid: one), PlaceResult.ok);
    });

    test('checks run in spec order — cooldown loses to occupancy', () {
      final g = emptyGrid()..[1][1] = 'wall';
      expect(
        place(bulb, grid: g, now: 101, lastPlaced: {'bulb': 100}, glow: 0),
        PlaceResult.occupied,
      );
    });
  });

  group('bomb footprint', () {
    test('covers 3x3 in the middle of the board', () {
      expect(bombFootprint(1, 3), hasLength(9));
    });

    test('clamps at a corner without throwing', () {
      expect(bombFootprint(0, 0), hasLength(4));
      expect(bombFootprint(kRows - 1, kCols - 1), hasLength(4));
    });
  });

  group('wave pacing (50% rule)', () {
    final waves = [
      const Wave(delay: 10, shadows: []),
      const Wave(delay: 20, shadows: []),
    ];

    bool ready({
      required int index,
      required double time,
      double lastWaveTime = 0,
      int total = 100,
      int alive = 100,
    }) => canSpawnNextWave(
      waveIndex: index,
      waves: waves,
      time: time,
      lastWaveTime: lastWaveTime,
      previousWaveTotalHp: total,
      previousWaveAliveHp: alive,
    );

    test('the first wave only waits for its delay', () {
      expect(ready(index: 0, time: 9.9), isFalse);
      expect(ready(index: 0, time: 10), isTrue);
    });

    test('a later wave waits for its delay even when the lane is clear', () {
      expect(ready(index: 1, time: 19, alive: 0), isFalse);
    });

    test('a later wave spawns once half the previous wave HP is gone', () {
      // lastWaveTime is recent, so the 20s timeout cannot be what lets it
      // through — this isolates the half-dead branch.
      expect(ready(index: 1, time: 21, lastWaveTime: 20, alive: 60), isFalse);
      expect(ready(index: 1, time: 21, lastWaveTime: 20, alive: 40), isTrue);
    });

    test('a stalled player still gets the wave after 20s', () {
      expect(ready(index: 1, time: 21, lastWaveTime: 10, alive: 100), isFalse);
      expect(ready(index: 1, time: 31, lastWaveTime: 10, alive: 100), isTrue);
    });

    test('past the last wave nothing spawns', () {
      expect(ready(index: 2, time: 999), isFalse);
    });
  });

  group('terminal state', () {
    test('wins only when every wave spawned and the board is clear', () {
      expect(hasWon(waveIndex: 3, waveCount: 3, shadowsAlive: 0), isTrue);
      expect(hasWon(waveIndex: 3, waveCount: 3, shadowsAlive: 1), isFalse);
      expect(hasWon(waveIndex: 2, waveCount: 3, shadowsAlive: 0), isFalse);
    });

    test('loses only when the lane sweep is already spent', () {
      const atCore = [(x: 0.0, lane: 1)];
      expect(
        hasLost(shadows: atCore, sweepAvailable: [true, true, true]),
        isFalse,
      );
      expect(
        hasLost(shadows: atCore, sweepAvailable: [true, false, true]),
        isTrue,
      );
    });
  });

  group('scoring', () {
    test('three stars needs par time and an unused sweep in every lane', () {
      expect(
        starsFor(elapsed: 40, parTime: 45, sweepAvailable: [true, true, true]),
        3,
      );
      expect(
        starsFor(elapsed: 40, parTime: 45, sweepAvailable: [true, false, true]),
        2,
      );
      expect(
        starsFor(elapsed: 60, parTime: 45, sweepAvailable: [true, true, true]),
        2,
      );
      expect(
        starsFor(elapsed: 60, parTime: 45, sweepAvailable: [false, true, true]),
        1,
      );
    });

    test('coins reward improvement, and a replay still pays something', () {
      expect(coinsFor(previousStars: 0, newStars: 3), 50);
      expect(coinsFor(previousStars: 2, newStars: 3), 30);
      expect(coinsFor(previousStars: 3, newStars: 3), 10);
      expect(coinsFor(previousStars: 3, newStars: 1), 10);
    });

    test('glow clamps at 999 and never goes negative', () {
      expect(clampGlow(1200), kGlowMax);
      expect(clampGlow(-5), 0);
      expect(clampGlow(300), 300);
    });

    test('the daily level is deterministic and inside 1..20', () {
      for (var d = 0; d < 366; d++) {
        final id = dailyLevelId(DateTime(2026).add(Duration(days: d)));
        expect(id, inInclusiveRange(1, 20));
      }
      expect(
        dailyLevelId(DateTime(2026, 3, 14)),
        dailyLevelId(DateTime(2026, 3, 14)),
      );
    });
  });
}
