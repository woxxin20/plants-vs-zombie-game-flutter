/// PH-02 exit-gate suite — `docs/phases.md` §6.
///
/// Controllable clock: set `BattleWorld.time` and call `update` directly;
/// never `Future.delayed`. Flame ticker never idles — pump fixed frames.
library;

import 'dart:io';

import 'package:flame/game.dart';
import 'package:flame_riverpod/flame_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism_defense/app.dart';
import 'package:prism_defense/core/layout.dart';
import 'package:prism_defense/core/save_store.dart';
import 'package:prism_defense/data/content.dart';
import 'package:prism_defense/data/models.dart';
import 'package:prism_defense/game/components/hud/overlay_lose.dart';
import 'package:prism_defense/game/components/hud/overlay_pause.dart';
import 'package:prism_defense/game/components/hud/overlay_win.dart';
import 'package:prism_defense/game/components/shadow_component.dart';
import 'package:prism_defense/game/light_vs_shadow_game.dart';
import 'package:prism_defense/game/worlds/battle_world.dart';

const _tray = <String>['bulb', 'beam', 'wall', 'mirror', 'frost', 'bomb'];

Future<void> _pumpFrames(WidgetTester tester, [int n = 5]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

/// Async `onLoad` + mount need the engine ticking; pump fixed frames then
/// re-pause so the test keeps the controllable clock.
Future<void> _flushLifecycle(
  WidgetTester tester,
  LightVsShadowGame game,
) async {
  game.resumeEngine();
  await _pumpFrames(tester, 5);
  game.pauseEngine();
}

Future<({LightVsShadowGame game, BattleWorld world})> _mountBattle(
  WidgetTester tester, {
  void Function(int, int)? onWin,
  void Function()? onLose,
}) async {
  final gameKey = GlobalKey<RiverpodAwareGameWidgetState<LightVsShadowGame>>();
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
  expect(game.isLoaded, isTrue);

  final world = BattleWorld(
    levelId: 1,
    tray: _tray,
    onWin: onWin ?? (_, _) {},
    onLose: onLose ?? () {},
  );

  game.swapWorld(world);
  await _pumpFrames(tester, 20);
  expect(world.isLoaded, isTrue);
  game.pauseEngine();

  return (game: game, world: world);
}

ShadowComponent _spawnShadow(
  BattleWorld world, {
  required int lane,
  required double x,
  String id = 'basic',
}) {
  final s = ShadowComponent(
    def: Content.I.shadow(id),
    lane: lane,
    fromWave: 0,
    spawn: Vector2(x, world.layout.laneCenterY(lane)),
  );
  world.add(s);
  return s;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    final hiveDir = await Directory.systemTemp.createTemp('prism_ph02_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => hiveDir.path,
        );

    await SaveStore.open();
    await Content.load();
  });

  group('PH-02 combat core (BattleWorld)', () {
    testWidgets('beam hits two shadows on the same tile (QA #9)', (
      tester,
    ) async {
      final (:game, :world) = await _mountBattle(tester);

      world.glow = 999;
      expect(world.tryPlace('beam', 1, 0), PlaceResult.ok);
      await _flushLifecycle(tester, game);

      final x = world.layout.tileCenter(1, 4).x;
      final a = _spawnShadow(world, lane: 1, x: x);
      final b = _spawnShadow(world, lane: 1, x: x + 2);
      await _flushLifecycle(tester, game);
      expect(a.isMounted, isTrue);

      final hpA = a.hp;
      final hpB = b.hp;
      world.update(0.5);

      expect(a.hp, lessThan(hpA));
      expect(b.hp, lessThan(hpB));
    });

    testWidgets(
      'sweep at x<=12 clears the lane and leaves it vulnerable (QA #12)',
      (tester) async {
        final (:game, :world) = await _mountBattle(tester);

        final lane = 1;
        expect(world.sweepAvailable[lane], isTrue);

        final triggerX = world.layout.origin.x + kSweepTriggerX - 1;
        final a = _spawnShadow(world, lane: lane, x: triggerX);
        final b = _spawnShadow(world, lane: lane, x: triggerX + 30);
        await _flushLifecycle(tester, game);
        expect(a.isMounted, isTrue);

        world.update(0.016);

        expect(world.sweepAvailable[lane], isFalse);
        expect(world.grid.sweepAvailable[lane], isFalse);
        expect(a.isDying, isTrue);
        expect(b.isDying, isTrue);
      },
    );

    testWidgets(
      'win overlay when all waves spawned and no shadows remain (QA #13)',
      (tester) async {
        final (:game, :world) = await _mountBattle(tester);

        world.waveIndex = world.level.waves.length;
        world.time = 1;
        expect(world.shadows, isEmpty);

        world.update(0.016);
        await _flushLifecycle(tester, game);

        expect(world.state, GameState.won);
        expect(
          game.camera.viewport.children.whereType<WinOverlay>(),
          isNotEmpty,
        );
      },
    );

    testWidgets(
      'lose overlay when shadow reaches x<=0 with no sweep (QA #12)',
      (tester) async {
        final (:game, :world) = await _mountBattle(tester);

        final lane = 0;
        world.sweepAvailable[lane] = false;
        world.grid.sweepAvailable[lane] = false;

        final shadow = _spawnShadow(
          world,
          lane: lane,
          x: world.layout.origin.x - 1,
        );
        await _flushLifecycle(tester, game);
        expect(shadow.isMounted, isTrue);

        world.update(0.016);
        expect(world.state, GameState.lost);

        // Drive the lose-shake effect to completion so the overlay mounts.
        game.resumeEngine();
        await _pumpFrames(tester, 30);
        game.pauseEngine();
        await _flushLifecycle(tester, game);

        expect(
          game.camera.viewport.children.whereType<LoseOverlay>(),
          isNotEmpty,
        );
      },
    );

    testWidgets('pause() mounts PauseOverlay and pauseEngine halts ticks', (
      tester,
    ) async {
      final (:game, :world) = await _mountBattle(tester);

      game.resumeEngine();
      expect(game.paused, isFalse);

      world.pause();
      await _flushLifecycle(tester, game);
      expect(world.state, GameState.paused);
      expect(game.paused, isTrue);
      expect(
        game.camera.viewport.children.whereType<PauseOverlay>(),
        isNotEmpty,
      );

      final before = world.time;
      await _pumpFrames(tester, 10);
      expect(world.time, before);
    });
  });

  group('PH-02 lifecycle (QA #10)', () {
    testWidgets('didChangeAppLifecycleState(paused) calls pauseEngine', (
      tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: PrismDefenseApp()));
      await _pumpFrames(tester, 10);

      final gameWidget = tester
          .widget<RiverpodAwareGameWidget<LightVsShadowGame>>(
            find.byType(RiverpodAwareGameWidget<LightVsShadowGame>),
          );
      final game = gameWidget.game!;
      expect(game.paused, isFalse);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await _pumpFrames(tester, 2);

      expect(game.paused, isTrue);
    });

    testWidgets('backgrounding pauses the BattleWorld itself (AUD-017)', (
      tester,
    ) async {
      // Regression for AUD-017. app.dart read `_game.world`, but swapWorld
      // sets `camera.world` and FlameGame.world stays the default World
      // forever -- so `world is BattleWorld` was always false and this half
      // of QA #10 was dead code. The sibling test above passes either way,
      // because pauseEngine() runs regardless; only the world's own state
      // distinguishes the fixed code from the broken code.
      //
      // PrismDefenseApp must be the pumped widget: it owns the
      // WidgetsBindingObserver that receives the lifecycle event.
      await tester.pumpWidget(const ProviderScope(child: PrismDefenseApp()));
      await _pumpFrames(tester, 10);

      final game = tester
          .widget<RiverpodAwareGameWidget<LightVsShadowGame>>(
            find.byType(RiverpodAwareGameWidget<LightVsShadowGame>),
          )
          .game!;

      final world = BattleWorld(
        levelId: 1,
        tray: _tray,
        onWin: (_, _) {},
        onLose: () {},
      );
      game.swapWorld(world);
      await _pumpFrames(tester, 20);
      expect(world.isLoaded, isTrue);

      // Precondition: without this, a world that was already paused would
      // make the assertion below prove nothing.
      expect(world.state, isNot(GameState.paused));

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await _pumpFrames(tester, 2);

      expect(
        world.state,
        GameState.paused,
        reason: 'BattleWorld.pause() must run, not just game.pauseEngine()',
      );
    });
  });
}
