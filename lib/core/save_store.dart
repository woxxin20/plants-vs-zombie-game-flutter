/// Local persistence — spec §19. One Hive box, one plain map. No adapters and
/// no codegen: the save is eight scalar fields, and a generated TypeAdapter
/// would be more machinery than the thing it stores.
///
/// ADR-004: `hive_ce_flutter` replaces the spec's `hive_flutter`; the original
/// hive package is discontinued and hive_ce is the maintained fork with the
/// same API.
library;

import 'package:hive_ce_flutter/hive_flutter.dart';

import '../data/content.dart' show kLevelCount;

const _boxName = 'save';

class SaveState {
  SaveState({
    this.coins = 0,
    List<int>? stars,
    Set<String>? unlocked,
    this.removeAds = false,
    this.sound = true,
    this.haptics = true,
    this.maxUnlocked = 1,
    this.totalPlays = 0,
    this.traySlotBonus = 0,
    this.lastDailyClaimed = 0,
  }) : stars = stars ?? List<int>.filled(kLevelCount, 0),
       unlocked = unlocked ?? {'bulb', 'beam', 'wall'};

  int coins;

  /// Best star count per level, index = levelId - 1.
  final List<int> stars;

  /// Tool ids the player may bring into a loadout.
  final Set<String> unlocked;

  bool removeAds;
  bool sound;
  bool haptics;

  /// Highest level the player may enter.
  int maxUnlocked;
  int totalPlays;

  /// Extra tray slots bought in the shop (spec §20).
  int traySlotBonus;

  /// Day-of-year of the last claimed daily, 0 = never.
  int lastDailyClaimed;

  Map<String, dynamic> toMap() => {
    'coins': coins,
    'stars': stars,
    'unlocked': unlocked.toList(),
    'removeAds': removeAds,
    'sound': sound,
    'haptics': haptics,
    'maxUnlocked': maxUnlocked,
    'totalPlays': totalPlays,
    'traySlotBonus': traySlotBonus,
    'lastDailyClaimed': lastDailyClaimed,
  };

  factory SaveState.fromMap(Map<dynamic, dynamic> m) {
    final rawStars = (m['stars'] as List?)?.cast<num>() ?? const <num>[];
    final stars = List<int>.filled(kLevelCount, 0);
    for (var i = 0; i < rawStars.length && i < kLevelCount; i++) {
      stars[i] = rawStars[i].toInt();
    }
    return SaveState(
      coins: (m['coins'] as num?)?.toInt() ?? 0,
      stars: stars,
      unlocked:
          (m['unlocked'] as List?)?.cast<String>().toSet() ??
          {'bulb', 'beam', 'wall'},
      removeAds: m['removeAds'] as bool? ?? false,
      sound: m['sound'] as bool? ?? true,
      haptics: m['haptics'] as bool? ?? true,
      maxUnlocked: (m['maxUnlocked'] as num?)?.toInt() ?? 1,
      totalPlays: (m['totalPlays'] as num?)?.toInt() ?? 0,
      traySlotBonus: (m['traySlotBonus'] as num?)?.toInt() ?? 0,
      lastDailyClaimed: (m['lastDailyClaimed'] as num?)?.toInt() ?? 0,
    );
  }

  int starsFor(int levelId) =>
      (levelId >= 1 && levelId <= kLevelCount) ? stars[levelId - 1] : 0;

  int get totalStars => stars.fold(0, (a, b) => a + b);
}

/// Thin wrapper so nothing else in the app touches Hive directly.
class SaveStore {
  SaveStore._(this._box, this.state);

  final Box<dynamic> _box;
  final SaveState state;

  static SaveStore? _instance;
  static SaveStore get I =>
      _instance ?? (throw StateError('SaveStore.open() not awaited'));

  static Future<SaveStore> open() async {
    await Hive.initFlutter();
    final box = await Hive.openBox<dynamic>(_boxName);
    final raw = box.get('state');
    final state = raw is Map ? SaveState.fromMap(raw) : SaveState();
    return _instance = SaveStore._(box, state);
  }

  /// Writes the whole save. Called on win, on purchase and on settings change —
  /// never per frame.
  Future<void> flush() => _box.put('state', state.toMap());

  /// Test seam.
  static void debugSet(SaveStore s) => _instance = s;
}
