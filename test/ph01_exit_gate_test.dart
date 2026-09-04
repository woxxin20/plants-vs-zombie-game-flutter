/// PH-01 exit-gate suite — `docs/phases.md` §5.
///
/// Exercises the mutation half of placement/economy/HUD against production
/// code that already exists. Controllable clock: set `BattleWorld.time` and
/// call `update` directly; never `Future.delayed`.
library;

import 'dart:io';
import 'dart:ui';

import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_riverpod/flame_riverpod.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:prism_defense/core/layout.dart';
import 'package:prism_defense/core/save_store.dart';
import 'package:prism_defense/data/content.dart';
import 'package:prism_defense/data/models.dart';
import 'package:prism_defense/game/components/glow_orb_component.dart';
import 'package:prism_defense/game/components/hud/hud_paint.dart';
import 'package:prism_defense/game/components/hud/top_bar_component.dart';
import 'package:prism_defense/game/components/tools/bulb_component.dart';
import 'package:prism_defense/game/light_vs_shadow_game.dart';
import 'package:prism_defense/game/worlds/battle_world.dart';

const _tray = <String>['bulb', 'beam', 'wall', 'mirror', 'frost', 'bomb'];

Future<void> _pumpFrames(WidgetTester tester, [int n = 5]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

/// Mounts a playing `BattleWorld` on the shared game and freezes the ticker
/// so the test owns the clock via `world.time` + `world.update`.
Future<({LightVsShadowGame game, BattleWorld world, List<String> toasts})>
_mountBattle(WidgetTester tester) async {
  final gameKey = GlobalKey<RiverpodAwareGameWidgetState<LightVsShadowGame>>();
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
  expect(game.isLoaded, isTrue);

  final world = BattleWorld(
    levelId: 1,
    tray: _tray,
    onWin: (_, _) {},
    onLose: () {},
  )..onToast = toasts.add;

  game.swapWorld(world);
  // Fake-async: drive loads with fixed pumps, never bare await on loaded.
  await _pumpFrames(tester, 20);
  expect(world.isLoaded, isTrue);
  expect(world.grid.isLoaded, isTrue);
  game.pauseEngine();

  expect(world.state, GameState.playing);
  return (game: game, world: world, toasts: toasts);
}

/// Mounted `add()`s are enqueued; flush without advancing the battle clock.
void _flushLifecycle(LightVsShadowGame game) => game.updateTree(0);

TapUpEvent _tapUp(FlameGame game, Offset at) => TapUpEvent(
  1,
  game,
  TapUpDetails(
    kind: PointerDeviceKind.touch,
    globalPosition: at,
    localPosition: at,
  ),
);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    final hiveDir = await Directory.systemTemp.createTemp('prism_ph01_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => hiveDir.path,
        );

    await SaveStore.open();
    await Content.load();
  });

  group('PH-01 placement + economy (BattleWorld)', () {
    testWidgets('empty tile with tool selected places it and deducts glow', (
      tester,
    ) async {
      final (:game, :world, toasts: _) = await _mountBattle(tester);
      final start = world.glow;
      final cost = Content.I.tool('bulb').cost;
      expect(start, greaterThanOrEqualTo(cost));

      world.selectedTool = 'bulb';
      final result = world.tryPlace('bulb', 1, 2);

      expect(result, PlaceResult.ok);
      expect(world.glow, start - cost);
      expect(world.toolAt(1, 2), isA<BulbComponent>());
      expect(world.grid.tileAt(1, 2).occupied, isTrue);
      expect(world.selectedTool, isNull);
      // Placement pop (ScaleEffect) is attached in ToolComponent.onLoad.
      expect(world.toolAt(1, 2)!.children.whereType<ScaleEffect>(), isNotEmpty);
      expect(game.isLoaded, isTrue);
    });

    testWidgets('occupied tile shakes, toasts Occupied, deducts no glow', (
      tester,
    ) async {
      final (:game, :world, :toasts) = await _mountBattle(tester);
      world.selectedTool = 'bulb';
      expect(world.tryPlace('bulb', 0, 0), PlaceResult.ok);
      final glowAfterFirst = world.glow;

      world.selectedTool = 'wall';
      final result = world.tryPlace('wall', 0, 0);
      _flushLifecycle(game);

      expect(result, PlaceResult.occupied);
      expect(world.glow, glowAfterFirst);
      expect(toasts, contains('Occupied'));
      expect(
        world.grid.tileAt(0, 0).children.whereType<MoveByEffect>(),
        isNotEmpty,
      );
      expect(game.isLoaded, isTrue);
    });

    testWidgets('insufficient glow blocks placement and deducts nothing', (
      tester,
    ) async {
      // Gate item also requires "cost text pulses red". TraySlotComponent
      // has no cost ColorEffect / pulse API today (design.md Cost pulse
      // red) — that half cannot be asserted without production changes.
      // See .ai/inbox/cursor-evidence-ph01.md.
      final (:game, :world, :toasts) = await _mountBattle(tester);
      world.glow = 0;
      world.selectedTool = 'bulb';

      final result = world.tryPlace('bulb', 1, 1);

      expect(result, PlaceResult.notEnoughGlow);
      expect(world.glow, 0);
      expect(world.toolAt(1, 1), isNull);
      expect(toasts, contains('Not enough Glow'));
      expect(game.isLoaded, isTrue);
    });

    testWidgets(
      'GlowOrbComponent spawns on falling-glow timer and is collectible by tap',
      (tester) async {
        final (:game, :world, toasts: _) = await _mountBattle(tester);
        expect(world.children.whereType<GlowOrbComponent>(), isEmpty);

        // Controllable clock: jump past kGlowFallInterval, then one tick.
        // GlowOrb.onLoad is `async` (microtask); pumps flush load+mount.
        world.time = kGlowFallInterval;
        world.update(1 / 30);
        game.resumeEngine();
        await _pumpFrames(tester, 5);
        game.pauseEngine();

        final orbs = world.descendants().whereType<GlowOrbComponent>().toList();
        expect(orbs, hasLength(1));

        final before = world.glow;
        final orb = orbs.single;
        orb.onTapUp(
          _tapUp(game, Offset(orb.absoluteCenter.x, orb.absoluteCenter.y)),
        );
        await _pumpFrames(tester, 2);

        expect(world.glow, before + kGlowFallAmount);
        expect(orb.isRemoving || !orb.isMounted, isTrue);
      },
    );

    testWidgets(
      'BulbComponent generates +25 glow every 10.0s only while alive',
      (tester) async {
        final (:game, :world, toasts: _) = await _mountBattle(tester);
        world.selectedTool = 'bulb';
        expect(world.tryPlace('bulb', 2, 3), PlaceResult.ok);
        final bulb = world.toolAt(2, 3)!;
        expect(bulb, isA<BulbComponent>());

        final afterPlace = world.glow;
        world.time = bulb.lastGen + kBulbGenInterval + 0.01;
        world.update(1 / 30);
        expect(world.glow, afterPlace + kBulbGenAmount);

        // Kill the bulb in place — still on the board until remove, but
        // `_tickGenerators` skips `!t.isAlive`.
        final afterGen = world.glow;
        bulb.takeDamage(bulb.hp);
        expect(bulb.isAlive, isFalse);
        world.time = bulb.lastGen + kBulbGenInterval + 0.01;
        world.update(1 / 30);
        expect(world.glow, afterGen);
        expect(game.isLoaded, isTrue);
      },
    );
  });

  group('PH-01 Hive save round-trip', () {
    test('save box round-trips coins/stars/unlocked across restart', () async {
      final store = await SaveStore.open();
      store.state.coins = 4242;
      store.state.stars[0] = 3;
      store.state.unlocked.add('prism');
      await store.flush();

      // Simulated app kill: close the box, then reopen (reads disk again).
      await Hive.box('save').close();
      final again = await SaveStore.open();

      expect(again.state.coins, 4242);
      expect(again.state.stars[0], 3);
      expect(again.state.unlocked, contains('prism'));
    });
  });

  group('PH-01 TopBar glow display', () {
    testWidgets('TopBarComponent glow display updates reactively', (
      tester,
    ) async {
      // phases.md names BattleNotifier; that bridge is out of scope for
      // this assignment. TopBar itself updates when `glow` changes — assert
      // that reactive path (what production wires today via onGlowChanged).
      final game = FlameGame();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: kBaselineSize.x,
            height: kBaselineSize.y,
            child: GameWidget(game: game),
          ),
        ),
      );
      await _pumpFrames(tester);

      final bar = TopBarComponent(glow: 50, waveCount: 3, onPause: () {});
      game.world.add(bar);
      await _pumpFrames(tester, 10);
      expect(bar.isLoaded, isTrue);

      HudLabel glowLabel() => bar.children.whereType<HudLabel>().first;

      expect(glowLabel().text, '50');

      bar.glow = 175;
      bar.update(0);
      expect(glowLabel().text, '175');

      bar.glow = 0;
      bar.update(0);
      expect(glowLabel().text, '0');
    });
  });
}
