/// Pure data layer. Must not import flame or flutter widgets (RULE-FORBID).
/// Only `dart:` and plain Dart are allowed here so every rule in this file is
/// unit-testable without a game loop.
library;

// ---------------------------------------------------------------------------
// Board geometry — spec §5
// ---------------------------------------------------------------------------

const int kRows = 3;
const int kCols = 7;
const int kTrayLimit = 6;

/// Glow economy — spec §5.
const int kStartGlowDefault = 50;
const int kGlowMax = 999;
const double kGlowFallInterval = 8.0;
const int kGlowFallAmount = 25;
const int kGlowOrbsMax = 2;
const double kBulbGenInterval = 10.0;
const int kBulbGenAmount = 25;
const int kTwinGenAmount = 50;

/// Sweep (lawnmower) trigger — spec §5.
const double kSweepTriggerX = 12.0;

/// Beam optics — spec §15.
const int kBeamMaxDepth = 3;
const double kPrismDamageFactor = 0.6;
const double kFogDamageFactor = 0.7;
const double kFrostSlowFactor = 0.5;
const double kFrostSlowDuration = 2.0;
const double kBeamSegmentWidth = 12.0;

/// Wave pacing — spec §8.
const double kWaveHalfDeadFraction = 0.5;
const double kWaveTimeoutSeconds = 20.0;

/// Bomb — spec §6 / §17.
const int kBombDamage = 300;
const int kBombRadiusTiles = 1;

/// Optional placement limit — spec §17 check 7.
const int kMaxPrismPerRow = 2;

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum GameState { loading, ready, playing, paused, won, lost }

/// Beam travel direction. Beams only ever run right / up / down (spec §15).
enum Dir { right, up, down }

/// Why a placement was rejected. `ok` means it succeeded.
enum PlaceResult {
  ok,
  notPlaying,
  outOfBounds,
  occupied,
  notEnoughGlow,
  onCooldown,
  needBulb,
  maxPrism;

  /// User-facing toast text, or null when the failure is silently ignored
  /// (spec §17: checks 1 and 2 have no UI).
  String? get toast => switch (this) {
    PlaceResult.ok => null,
    PlaceResult.notPlaying => null,
    PlaceResult.outOfBounds => null,
    PlaceResult.occupied => 'Occupied',
    PlaceResult.notEnoughGlow => 'Not enough Glow',
    PlaceResult.onCooldown => 'Cooling down',
    PlaceResult.needBulb => 'Need Bulb',
    PlaceResult.maxPrism => 'Max Prism',
  };
}

// ---------------------------------------------------------------------------
// Tool definitions — assets/data/tools.json (spec §6, §22)
// ---------------------------------------------------------------------------

class ToolDef {
  const ToolDef({
    required this.id,
    required this.cost,
    required this.hp,
    required this.cooldown,
    required this.dmg,
  });

  final String id;
  final int cost;
  final int hp;

  /// Seconds before this tool can be placed again.
  final double cooldown;

  /// Damage per beam tick, 0 for non-emitters.
  final int dmg;

  factory ToolDef.fromJson(Map<String, dynamic> j) => ToolDef(
    id: j['id'] as String,
    cost: (j['cost'] as num).toInt(),
    hp: (j['hp'] as num).toInt(),
    cooldown: (j['cooldown'] as num).toDouble(),
    dmg: (j['dmg'] as num).toInt(),
  );

  /// A tool that occupies a tile and can be eaten. Bomb detonates instantly.
  bool get isPersistent => id != 'bomb';

  /// Generates glow on a timer.
  bool get isGenerator => id == 'bulb' || id == 'twin';

  /// Emits a beam down its own lane every tick.
  bool get isEmitter => id == 'beam' || id == 'frost';
}

// ---------------------------------------------------------------------------
// Shadow definitions — assets/data/shadows.json (spec §7, §22)
// ---------------------------------------------------------------------------

class ShadowDef {
  const ShadowDef({
    required this.id,
    required this.hp,
    required this.speed,
    required this.eat,
  });

  final String id;
  final int hp;

  /// Pixels per second, leftward.
  final double speed;

  /// Tool HP eaten per second.
  final double eat;

  factory ShadowDef.fromJson(Map<String, dynamic> j) => ShadowDef(
    id: j['id'] as String,
    hp: (j['hp'] as num).toInt(),
    speed: (j['speed'] as num).toDouble(),
    eat: (j['eat'] as num).toDouble(),
  );

  /// Veil takes 30% less beam damage until a frost beam hits it (spec §7).
  bool get resistsBeam => id == 'fog';

  /// Leaper hops the first wall it meets (spec §7).
  bool get jumpsWalls => id == 'jumper';

  /// Colossus spawns a Shade at 50% HP (spec §7).
  bool get throwsImp => id == 'giant';
}

// ---------------------------------------------------------------------------
// Levels — assets/levels/N.json (spec §8, §9, §22)
// ---------------------------------------------------------------------------

class WaveSpawn {
  const WaveSpawn({required this.id, required this.lane});
  final String id;
  final int lane;

  factory WaveSpawn.fromJson(Map<String, dynamic> j) =>
      WaveSpawn(id: j['id'] as String, lane: (j['lane'] as num).toInt());
}

class Wave {
  const Wave({
    required this.delay,
    required this.shadows,
    this.flag = false,
  });

  /// Seconds from level start before this wave is eligible to spawn.
  final double delay;
  final List<WaveSpawn> shadows;

  /// A "huge wave" — shows a flag in the TopBar.
  final bool flag;

  factory Wave.fromJson(Map<String, dynamic> j) => Wave(
    delay: (j['delay'] as num).toDouble(),
    flag: j['flag'] as bool? ?? false,
    shadows: (j['shadows'] as List)
        .map((s) => WaveSpawn.fromJson(s as Map<String, dynamic>))
        .toList(growable: false),
  );
}

class Level {
  const Level({
    required this.id,
    required this.name,
    required this.flags,
    required this.startGlow,
    required this.parTime,
    required this.availableTools,
    required this.waves,
    this.unlockReward,
  });

  final int id;
  final String name;

  /// Number of flag (huge) waves; drives the TopBar flag dots.
  final int flags;
  final int startGlow;

  /// Target completion time in seconds, used for the 3rd star.
  final double parTime;
  final List<String> availableTools;

  /// Tool id unlocked by finishing this level, or null.
  final String? unlockReward;
  final List<Wave> waves;

  factory Level.fromJson(Map<String, dynamic> j) => Level(
    id: (j['id'] as num).toInt(),
    name: j['name'] as String? ?? 'Level ${j['id']}',
    flags: (j['flags'] as num).toInt(),
    startGlow: (j['startGlow'] as num).toInt(),
    parTime: (j['parTime'] as num).toDouble(),
    availableTools: (j['availableTools'] as List).cast<String>(),
    unlockReward: j['unlockReward'] as String?,
    waves: (j['waves'] as List)
        .map((w) => Wave.fromJson(w as Map<String, dynamic>))
        .toList(growable: false),
  );

  /// Total shadows across every wave — used by the scout panel (spec §9).
  Map<String, int> get incoming {
    final counts = <String, int>{};
    for (final w in waves) {
      for (final s in w.shadows) {
        counts[s.id] = (counts[s.id] ?? 0) + 1;
      }
    }
    return counts;
  }
}
