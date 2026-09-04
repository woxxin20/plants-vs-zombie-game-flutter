/// Beam optics — the load-bearing rules from spec §15. If any of these break,
/// mirrors loop forever or prisms deal the wrong damage, and neither shows up
/// as a crash.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:prism_defense/data/models.dart';
import 'package:prism_defense/data/optics.dart';

ToolGrid emptyGrid() =>
    List.generate(kRows, (_) => List<String?>.filled(kCols, null));

BeamTarget target(Object id, int lane, double col, {bool fog = false}) =>
    BeamTarget(id: id, lane: lane, col: col, resistsBeam: fog);

({int row, int col, BeamKind kind, double dmg}) lamp(int row, int col) =>
    (row: row, col: col, kind: BeamKind.light, dmg: 20);

void main() {
  test(
    'a lamp with an empty lane draws one segment to the edge and hits nothing',
    () {
      final r = traceAll(
        grid: emptyGrid(),
        targets: const [],
        emitters: [lamp(1, 0)],
      );

      expect(r.hits, isEmpty);
      expect(r.segments, hasLength(1));
      expect(r.segments.single.toCol, kCols.toDouble());
      expect(r.segments.single.fromRow, 1);
    },
  );

  test('a shadow in the lane takes the full damage and stops the beam', () {
    final r = traceAll(
      grid: emptyGrid(),
      targets: [target('s', 1, 4)],
      emitters: [lamp(1, 0)],
    );

    expect(r.hits, hasLength(1));
    expect(r.hits.single.targetId, 's');
    expect(r.hits.single.dmgPerSecond, 20);
    expect(r.hits.single.applySlow, isFalse);
    expect(r.segments.single.toCol, 4);
  });

  test('the nearest shadow is hit, not the far one', () {
    final r = traceAll(
      grid: emptyGrid(),
      targets: [target('far', 1, 6), target('near', 1, 2)],
      emitters: [lamp(1, 0)],
    );

    expect(r.hits.single.targetId, 'near');
  });

  test('Veil takes 30% less beam damage but full frost damage', () {
    final light = traceAll(
      grid: emptyGrid(),
      targets: [target('v', 1, 3, fog: true)],
      emitters: [lamp(1, 0)],
    );
    expect(
      light.hits.single.dmgPerSecond,
      closeTo(20 * kFogDamageFactor, 1e-9),
    );

    final frost = traceAll(
      grid: emptyGrid(),
      targets: [target('v', 1, 3, fog: true)],
      emitters: [(row: 1, col: 0, kind: BeamKind.frost, dmg: 15)],
    );
    expect(frost.hits.single.dmgPerSecond, 15);
    expect(frost.hits.single.applySlow, isTrue);
  });

  test('a tool between the lamp and the shadow blocks the beam', () {
    final g = emptyGrid()..[1][3] = 'wall';
    final r = traceAll(
      grid: g,
      targets: [target('s', 1, 5)],
      emitters: [lamp(1, 0)],
    );

    expect(r.hits, isEmpty);
    expect(r.segments.single.toCol, 3);
  });

  group('mirror', () {
    test('in the top lane reflects downward', () {
      final g = emptyGrid()..[0][3] = 'mirror';
      final r = traceAll(
        grid: g,
        targets: [target('s', 2, 3)],
        emitters: [lamp(0, 0)],
      );

      expect(r.hits.single.targetId, 's');
      // Segment 1: lamp -> mirror. Segment 2: mirror -> shadow, going down.
      expect(r.segments, hasLength(2));
      expect(r.segments[1].fromRow, 0);
      expect(r.segments[1].toRow, 2);
    });

    test('in the bottom lane reflects upward', () {
      final g = emptyGrid()..[2][3] = 'mirror';
      final r = traceAll(
        grid: g,
        targets: [target('s', 0, 3)],
        emitters: [lamp(2, 0)],
      );

      expect(r.hits.single.targetId, 's');
      expect(r.segments[1].toRow, 0);
    });

    test('two facing mirrors terminate instead of looping forever', () {
      final g = emptyGrid()
        ..[0][2] = 'mirror'
        ..[2][2] = 'mirror';

      // If the visited-set or the depth cap regressed, this call never returns.
      final r = traceAll(grid: g, targets: const [], emitters: [lamp(0, 0)]);

      expect(r.segments.length, lessThanOrEqualTo(kBeamMaxDepth + 2));
    });

    test('depth-3 cap stops a multi-prism chain (QA #7)', () {
      // Four prisms in a row: the rightward child of the 4th would be depth 4
      // and must be rejected, so a shadow past the chain is never hit.
      final g = emptyGrid()
        ..[1][1] = 'prism'
        ..[1][2] = 'prism'
        ..[1][3] = 'prism'
        ..[1][4] = 'prism';

      final r = traceAll(
        grid: g,
        targets: [target('far', 1, 6)],
        emitters: [lamp(1, 0)],
      );

      expect(r.hits.where((h) => h.targetId == 'far'), isEmpty);
      // Termination proof: call returned and stayed within a bounded segment count.
      expect(r.segments.length, lessThanOrEqualTo(20));
    });
  });

  group('prism', () {
    test('splits into three lanes at 60% damage', () {
      final g = emptyGrid()..[1][3] = 'prism';
      final r = traceAll(
        grid: g,
        targets: [
          target('up', 0, 3),
          target('mid', 1, 5),
          target('down', 2, 3),
        ],
        emitters: [lamp(1, 0)],
      );

      expect(r.hits, hasLength(3));
      for (final h in r.hits) {
        expect(h.dmgPerSecond, closeTo(20 * kPrismDamageFactor, 1e-9));
      }
      expect(r.hits.map((h) => h.targetId).toSet(), {'up', 'mid', 'down'});
    });

    test('with nothing around it still terminates', () {
      final g = emptyGrid()..[1][3] = 'prism';
      final r = traceAll(grid: g, targets: const [], emitters: [lamp(1, 0)]);
      expect(r.hits, isEmpty);
      expect(r.segments, isNotEmpty);
    });
  });

  test('a mirror with no incoming beam produces nothing at all', () {
    final g = emptyGrid()..[1][3] = 'mirror';
    final r = traceAll(grid: g, targets: const [], emitters: const []);
    expect(r.segments, isEmpty);
    expect(r.hits, isEmpty);
  });
}
