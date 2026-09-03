/// Beam optics — spec §15, implemented as a PURE function over the board so it
/// is unit-testable without a running game (RULE: critical-path coverage).
///
/// Everything is expressed in tile coordinates. `row` is the lane (0..kRows-1),
/// `col` is the tile column (0..kCols-1). Shadows carry a fractional `col`
/// because they walk continuously between tiles.
library;

import 'models.dart';

/// What a beam segment looks like, so presentation can pick a colour without
/// this file knowing anything about `dart:ui`.
enum BeamKind {
  /// Beam Lamp — warm gold.
  light,

  /// Frost Lens — cyan, also applies the slow.
  frost,

  /// Prism output travelling right.
  prismRight,

  /// Prism output travelling up.
  prismUp,

  /// Prism output travelling down.
  prismDown;

  bool get isFrost => this == BeamKind.frost;
}

/// One resolved, renderable piece of beam. Coordinates are tile-space and may
/// be fractional (a segment can stop part-way at a shadow) or off-board by one
/// (a segment that runs off the edge).
class BeamSegment {
  const BeamSegment({
    required this.fromRow,
    required this.fromCol,
    required this.toRow,
    required this.toCol,
    required this.kind,
    required this.dmg,
  });

  final double fromRow;
  final double fromCol;
  final double toRow;
  final double toCol;
  final BeamKind kind;
  final double dmg;

  bool get isHorizontal => fromRow == toRow;

  @override
  String toString() =>
      'BeamSegment(($fromRow,$fromCol)->($toRow,$toCol) $kind dmg=$dmg)';
}

/// A shadow as the tracer sees it. Deliberately not the component.
class BeamTarget {
  const BeamTarget({
    required this.id,
    required this.lane,
    required this.col,
    required this.resistsBeam,
  });

  /// Stable identity so the caller can map a hit back to its component.
  final Object id;
  final int lane;

  /// Fractional column position, decreasing as the shadow walks left.
  final double col;

  /// Veil takes reduced beam damage until frost hits it (spec §7).
  final bool resistsBeam;
}

/// A damage application produced by one trace pass. `dmgPerSecond` still needs
/// multiplying by `dt` at the call site — the tracer is frame-rate agnostic.
class BeamHit {
  const BeamHit({
    required this.targetId,
    required this.dmgPerSecond,
    required this.applySlow,
  });

  final Object targetId;
  final double dmgPerSecond;

  /// True when a frost beam landed: caller sets `slowUntil = now + 2.0`.
  final bool applySlow;
}

/// The board as the tracer needs it: tool id per tile, or null when empty.
typedef ToolGrid = List<List<String?>>;

class TraceResult {
  const TraceResult(this.segments, this.hits);
  final List<BeamSegment> segments;
  final List<BeamHit> hits;
}

/// A beam in flight. Internal to the tracer.
class _Ray {
  const _Ray(this.row, this.col, this.dir, this.dmg, this.kind);
  final int row;
  final int col;
  final Dir dir;
  final double dmg;
  final BeamKind kind;
}

/// Traces every beam on the board and returns what to draw and what to damage.
///
/// [emitters] are the tiles that fire this frame — typically every `beam` and
/// `frost` tool whose 1.2s tick just elapsed. Each entry is `(row, col, kind,
/// dmg)`.
TraceResult traceAll({
  required ToolGrid grid,
  required List<BeamTarget> targets,
  required List<({int row, int col, BeamKind kind, double dmg})> emitters,
}) {
  final segments = <BeamSegment>[];
  final hits = <BeamHit>[];

  for (final e in emitters) {
    _trace(
      _Ray(e.row, e.col, Dir.right, e.dmg, e.kind),
      0,
      <String>{},
      grid,
      targets,
      segments,
      hits,
    );
  }
  return TraceResult(segments, hits);
}

void _trace(
  _Ray r,
  int depth,
  Set<String> visited,
  ToolGrid grid,
  List<BeamTarget> targets,
  List<BeamSegment> segments,
  List<BeamHit> hits,
) {
  // Spec §15: depth cap and visited-set are what stop a mirror pair from
  // looping forever. Both guards are load-bearing; do not remove either.
  if (depth > kBeamMaxDepth) return;
  final key = '${r.row},${r.col},${r.dir}';
  if (!visited.add(key)) return;

  final next = _findNextOccupied(grid, r.row, r.col, r.dir);
  final target = _findFirstTarget(targets, r.row, r.col, r.dir);

  final dNext = next == null
      ? double.infinity
      : _distance(r.row, r.col, next.row.toDouble(), next.col.toDouble());
  final dTarget = target == null
      ? double.infinity
      : _distance(r.row, r.col, target.lane.toDouble(), target.col);

  // 1. A shadow is closer than the next tool — the beam stops in it.
  if (target != null && dTarget < dNext) {
    final factor = (target.resistsBeam && !r.kind.isFrost)
        ? kFogDamageFactor
        : 1.0;
    hits.add(
      BeamHit(
        targetId: target.id,
        dmgPerSecond: r.dmg * factor,
        applySlow: r.kind.isFrost,
      ),
    );
    segments.add(
      BeamSegment(
        fromRow: r.row.toDouble(),
        fromCol: r.col.toDouble(),
        toRow: target.lane.toDouble(),
        toCol: target.col,
        kind: r.kind,
        dmg: r.dmg,
      ),
    );
    return;
  }

  // 2. Nothing in the way — run to the board edge.
  if (next == null) {
    final edge = _edgeInDir(r.row, r.col, r.dir);
    segments.add(
      BeamSegment(
        fromRow: r.row.toDouble(),
        fromCol: r.col.toDouble(),
        toRow: edge.row,
        toCol: edge.col,
        kind: r.kind,
        dmg: r.dmg,
      ),
    );
    return;
  }

  final toolId = grid[next.row][next.col]!;
  segments.add(
    BeamSegment(
      fromRow: r.row.toDouble(),
      fromCol: r.col.toDouble(),
      toRow: next.row.toDouble(),
      toCol: next.col.toDouble(),
      kind: r.kind,
      dmg: r.dmg,
    ),
  );

  // 3. Mirror: reflects 90 degrees, but only a beam arriving horizontally.
  if (toolId == 'mirror' && r.dir == Dir.right) {
    final Dir out;
    if (next.row == 0) {
      out = Dir.down;
    } else if (next.row == kRows - 1) {
      out = Dir.up;
    } else {
      out = depth.isEven ? Dir.down : Dir.up;
    }
    _trace(
      _Ray(next.row, next.col, out, r.dmg, r.kind),
      depth + 1,
      visited,
      grid,
      targets,
      segments,
      hits,
    );
    return;
  }

  // 4. Prism: splits into three lanes at 60% damage each.
  if (toolId == 'prism' && r.dir == Dir.right) {
    const outs = <(Dir, BeamKind)>[
      (Dir.right, BeamKind.prismRight),
      (Dir.up, BeamKind.prismUp),
      (Dir.down, BeamKind.prismDown),
    ];
    for (final (dir, kind) in outs) {
      _trace(
        _Ray(next.row, next.col, dir, r.dmg * kPrismDamageFactor, kind),
        depth + 1,
        visited,
        grid,
        targets,
        segments,
        hits,
      );
    }
    return;
  }

  // 5. Anything else (wall, bulb, another lamp) simply stops the beam.
}

({int row, int col})? _findNextOccupied(
  ToolGrid grid,
  int row,
  int col,
  Dir dir,
) {
  switch (dir) {
    case Dir.right:
      for (var c = col + 1; c < kCols; c++) {
        if (grid[row][c] != null) return (row: row, col: c);
      }
    case Dir.up:
      for (var r = row - 1; r >= 0; r--) {
        if (grid[r][col] != null) return (row: r, col: col);
      }
    case Dir.down:
      for (var r = row + 1; r < kRows; r++) {
        if (grid[r][col] != null) return (row: r, col: col);
      }
  }
  return null;
}

BeamTarget? _findFirstTarget(
  List<BeamTarget> targets,
  int row,
  int col,
  Dir dir,
) {
  BeamTarget? best;
  var bestDist = double.infinity;
  for (final t in targets) {
    final double d;
    switch (dir) {
      case Dir.right:
        if (t.lane != row || t.col <= col) continue;
        d = t.col - col;
      case Dir.up:
        if (t.lane >= row || (t.col - col).abs() > 0.5) continue;
        d = (row - t.lane).toDouble();
      case Dir.down:
        if (t.lane <= row || (t.col - col).abs() > 0.5) continue;
        d = (t.lane - row).toDouble();
    }
    if (d < bestDist) {
      bestDist = d;
      best = t;
    }
  }
  return best;
}

double _distance(int row, int col, double toRow, double toCol) =>
    ((toRow - row).abs() + (toCol - col).abs()).toDouble();

({double row, double col}) _edgeInDir(int row, int col, Dir dir) =>
    switch (dir) {
      Dir.right => (row: row.toDouble(), col: kCols.toDouble()),
      Dir.up => (row: -1.0, col: col.toDouble()),
      Dir.down => (row: kRows.toDouble(), col: col.toDouble()),
    };
