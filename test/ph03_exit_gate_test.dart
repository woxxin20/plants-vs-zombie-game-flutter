/// PH-03 exit-gate suite — `docs/phases.md` §7.
///
/// Data-driven checks read `assets/data/*.json` and `assets/levels/*.json`
/// directly — never hand-transcribed constants that can drift from the files.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flame_riverpod/flame_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism_defense/core/layout.dart';
import 'package:prism_defense/core/save_store.dart';
import 'package:prism_defense/data/content.dart';
import 'package:prism_defense/data/models.dart';
import 'package:prism_defense/data/rules.dart';
import 'package:prism_defense/game/light_vs_shadow_game.dart';
import 'package:prism_defense/game/worlds/battle_world.dart';
import 'package:prism_defense/game/worlds/loadout_world.dart';

/// Spec §6 table — expected values the JSON must match exactly.
const _specTools = <String, ({int cost, double cooldown, int hp, int dmg})>{
  'bulb': (cost: 50, cooldown: 5, hp: 100, dmg: 0),
  'beam': (cost: 100, cooldown: 5, hp: 100, dmg: 20),
  'mirror': (cost: 50, cooldown: 10, hp: 150, dmg: 0),
  'prism': (cost: 150, cooldown: 15, hp: 100, dmg: 0),
  'frost': (cost: 125, cooldown: 12, hp: 100, dmg: 15),
  'wall': (cost: 50, cooldown: 8, hp: 400, dmg: 0),
  'bomb': (cost: 150, cooldown: 25, hp: 0, dmg: 300),
  'twin': (cost: 125, cooldown: 15, hp: 100, dmg: 0),
};

/// Spec §7 table — HP/speed/eat, plus the three specials transcribed from the
/// spec as literal booleans. They are literals on purpose: `ShadowDef`'s
/// specials are id-derived (`id == 'fog'`), so asserting them against the same
/// `id == 'fog'` expression compares an expression with itself and passes no
/// matter what the production code says (`T-1`).
const _specShadows =
    <String, ({int hp, double speed, double eat, bool resists, bool jumps, bool imp})>{
      'basic': (hp: 100, speed: 12, eat: 20, resists: false, jumps: false, imp: false),
      'bucket': (hp: 250, speed: 12, eat: 20, resists: false, jumps: false, imp: false),
      'jumper': (hp: 120, speed: 14, eat: 20, resists: false, jumps: true, imp: false),
      'fog': (hp: 150, speed: 10, eat: 20, resists: true, jumps: false, imp: false),
      'giant': (hp: 600, speed: 8, eat: 40, resists: false, jumps: false, imp: true),
    };

Future<void> _pumpFrames(WidgetTester tester, [int n = 5]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Future<void> _flushLifecycle(
  WidgetTester tester,
  LightVsShadowGame game,
) async {
  game.resumeEngine();
  await _pumpFrames(tester, 5);
  game.pauseEngine();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final hiveDir = await Directory.systemTemp.createTemp('prism_ph03_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => hiveDir.path,
        );
    await SaveStore.open();
    await Content.load();
  });

  group('PH-03 levels schema (§22)', () {
    test('all 20 assets/levels/*.json parse against Level.fromJson', () {
      final dir = Directory('assets/levels');
      expect(dir.existsSync(), isTrue);

      final files =
          dir
              .listSync()
              .whereType<File>()
              .where((f) => f.path.endsWith('.json'))
              .toList()
            ..sort((a, b) => a.path.compareTo(b.path));

      expect(files, hasLength(kLevelCount));

      for (final file in files) {
        final raw = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        final level = Level.fromJson(raw);

        expect(level.id, inInclusiveRange(1, kLevelCount), reason: file.path);
        expect(level.name, isNotEmpty);
        expect(level.flags, greaterThanOrEqualTo(0));
        expect(level.startGlow, greaterThan(0));
        expect(level.parTime, greaterThan(0));
        expect(level.availableTools, isNotEmpty);
        expect(level.waves, isNotEmpty);
        for (final wave in level.waves) {
          expect(wave.delay, greaterThanOrEqualTo(0));
          expect(wave.shadows, isNotEmpty);
          for (final s in wave.shadows) {
            expect(s.lane, inInclusiveRange(0, kRows - 1));
            expect(_specShadows.containsKey(s.id), isTrue, reason: s.id);
          }
        }
      }
    });
  });

  group('PH-03 tools.json vs spec §6', () {
    test('each tool cost/cooldown/HP/dmg matches the table exactly', () {
      final raw =
          jsonDecode(File('assets/data/tools.json').readAsStringSync()) as List;
      expect(raw, hasLength(_specTools.length));

      for (final entry in raw) {
        final m = entry as Map<String, dynamic>;
        final id = m['id'] as String;
        final expected = _specTools[id];
        expect(expected, isNotNull, reason: 'unknown tool $id');
        expect(m['cost'], expected!.cost, reason: '$id cost');
        expect(
          (m['cooldown'] as num).toDouble(),
          expected.cooldown,
          reason: '$id cooldown',
        );
        expect(m['hp'], expected.hp, reason: '$id hp');
        expect(m['dmg'], expected.dmg, reason: '$id dmg');

        // Content loader agrees with the file.
        final loaded = Content.I.tool(id);
        expect(loaded.cost, expected.cost);
        expect(loaded.cooldown, expected.cooldown);
        expect(loaded.hp, expected.hp);
        expect(loaded.dmg, expected.dmg);
      }
    });
  });

  group('PH-03 shadows.json vs spec §7', () {
    test('each shadow HP/speed/eat/special matches the table exactly', () {
      final raw =
          jsonDecode(File('assets/data/shadows.json').readAsStringSync())
              as List;
      expect(raw, hasLength(_specShadows.length));

      for (final entry in raw) {
        final m = entry as Map<String, dynamic>;
        final id = m['id'] as String;
        final expected = _specShadows[id];
        expect(expected, isNotNull, reason: 'unknown shadow $id');
        expect(m['hp'], expected!.hp, reason: '$id hp');
        expect(
          (m['speed'] as num).toDouble(),
          expected.speed,
          reason: '$id speed',
        );
        expect((m['eat'] as num).toDouble(), expected.eat, reason: '$id eat');

        final loaded = Content.I.shadow(id);
        expect(loaded.hp, expected.hp);
        expect(loaded.speed, expected.speed);
        expect(loaded.eat, expected.eat);

        // Specials are id-derived (no JSON field) — assert against the spec
        // table's literals, never against the getter's own expression.
        expect(loaded.resistsBeam, expected.resists, reason: '$id veil');
        expect(loaded.jumpsWalls, expected.jumps, reason: '$id leaper');
        expect(loaded.throwsImp, expected.imp, reason: '$id colossus');
      }
    });
  });

  group('PH-03 loadout pick-6', () {
    testWidgets('Start Battle stays disabled until exactly 6 tools selected', (
      tester,
    ) async {
      SaveStore.I.state.unlocked.addAll(_specTools.keys);
      SaveStore.I.state.maxUnlocked = 16;

      final gameKey =
          GlobalKey<RiverpodAwareGameWidgetState<LightVsShadowGame>>();
      final game = LightVsShadowGame();
      List<String>? started;

      await tester.pumpWidget(
        ProviderScope(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(
              width: kBaselineSize.x,
              height: kBaselineSize.y,
              child: RiverpodAwareGameWidget(game: game, key: gameKey),
            ),
          ),
        ),
      );
      await _pumpFrames(tester);

      final loadout = LoadoutWorld(
        levelId: 16,
        onStart: (picked) => started = List<String>.from(picked),
        onBack: () {},
      );
      game.swapWorld(loadout);
      await _pumpFrames(tester, 20);
      game.pauseEngine();

      expect(loadout.debugCanStart, isFalse);
      loadout.debugPressStart();
      expect(started, isNull);

      final ids = Content.I
          .level(16)
          .availableTools
          .where(SaveStore.I.state.unlocked.contains)
          .take(6)
          .toList();
      expect(ids, hasLength(6));
      for (final id in ids) {
        loadout.debugToggle(id);
      }
      expect(loadout.debugCanStart, isTrue);

      loadout.debugPressStart();
      expect(started, isNotNull);
      expect(started, hasLength(kTrayLimit));

      // Deselect one — Start disables; a 7th pick is refused.
      loadout.debugToggle(ids.first);
      expect(loadout.debugCanStart, isFalse);
      started = null;
      loadout.debugPressStart();
      expect(started, isNull);

      loadout.debugToggle(ids.first); // back to 6
      loadout.debugToggle('twin'); // 7th — refused
      expect(loadout.debugCanStart, isTrue); // still exactly 6
    });
  });

  group('PH-03 QA #4 / #16 (BattleWorld)', () {
    testWidgets('Twin on non-bulb toasts Need Bulb (QA #4)', (tester) async {
      final gameKey =
          GlobalKey<RiverpodAwareGameWidgetState<LightVsShadowGame>>();
      final game = LightVsShadowGame();
      final toasts = <String>[];

      await tester.pumpWidget(
        ProviderScope(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(
              width: kBaselineSize.x,
              height: kBaselineSize.y,
              child: RiverpodAwareGameWidget(game: game, key: gameKey),
            ),
          ),
        ),
      );
      await _pumpFrames(tester);

      final world = BattleWorld(
        levelId: 16,
        tray: _specTools.keys.take(6).toList(),
        onWin: (_, _) {},
        onLose: () {},
      )..onToast = toasts.add;
      game.swapWorld(world);
      await _pumpFrames(tester, 20);
      game.pauseEngine();

      world.glow = 999;
      // Empty tile — not a bulb.
      expect(world.tryPlace('twin', 1, 2), PlaceResult.needBulb);
      expect(toasts, contains('Need Bulb'));

      // Wall is also not a bulb.
      expect(world.tryPlace('wall', 1, 2), PlaceResult.ok);
      await _flushLifecycle(tester, game);
      expect(world.tryPlace('twin', 1, 2), PlaceResult.needBulb);
    });

    testWidgets('Bomb on edge clamps 3x3 with no index error (QA #16)', (
      tester,
    ) async {
      // Pure footprint already covered in rules_test; assert BattleWorld
      // detonates a corner bomb without throwing.
      expect(bombFootprint(0, 0), hasLength(4));
      expect(() => bombFootprint(0, 0), returnsNormally);
      expect(() => bombFootprint(kRows - 1, kCols - 1), returnsNormally);

      final gameKey =
          GlobalKey<RiverpodAwareGameWidgetState<LightVsShadowGame>>();
      final game = LightVsShadowGame();

      await tester.pumpWidget(
        ProviderScope(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(
              width: kBaselineSize.x,
              height: kBaselineSize.y,
              child: RiverpodAwareGameWidget(game: game, key: gameKey),
            ),
          ),
        ),
      );
      await _pumpFrames(tester);

      final world = BattleWorld(
        levelId: 16,
        tray: ['bulb', 'beam', 'wall', 'mirror', 'frost', 'bomb'],
        onWin: (_, _) {},
        onLose: () {},
      );
      game.swapWorld(world);
      await _pumpFrames(tester, 20);
      game.pauseEngine();

      world.glow = 999;
      expect(() => world.tryPlace('bomb', 0, 0), returnsNormally);
      expect(world.toolAt(0, 0), isNull); // bomb is not persistent
    });
  });
}
