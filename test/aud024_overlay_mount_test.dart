/// AUD-024 — Pause / Win / Lose overlays must MOUNT AND PAINT, not just queue.
///
/// Production called `game.pauseEngine()` and then `_showOverlay(...)`.
/// `viewport.add` only queues a child; the queue is flushed by `updateTree`,
/// which a paused engine never runs. On a device this froze the last battle
/// frame with no dialog and no way out — reproduced on SM-S711B across two
/// cold starts (c10, c11).
///
/// The whole suite missed it because `ph02_exit_gate_test.dart`'s
/// `_flushLifecycle` helper calls `resumeEngine()`, pumps, and re-pauses. That
/// resume is exactly the tick production never performs, so the helper mounted
/// the overlay on the test's behalf and the assertion passed against broken
/// code. **Nothing in this file may call `resumeEngine()`.** If a future edit
/// adds one, this file stops testing anything.
///
/// Negative control: restore any of the three `pauseEngine()` calls in
/// `battle_world.dart` (`_finishWon`, `_finishLost.onComplete`, `pause`) and
/// the matching test below fails on an empty `whereType<...Overlay>()`.
library;

import 'dart:io';

import 'package:flame/game.dart';
import 'package:flame_riverpod/flame_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

const _tray = <String>['bulb', 'beam', 'wall'];

ShadowComponent _spawnShadow(
  BattleWorld world, {
  required int lane,
  required double x,
}) {
  final s = ShadowComponent(
    def: Content.I.shadow('basic'),
    lane: lane,
    fromWave: 0,
    spawn: Vector2(x, world.layout.laneCenterY(lane)),
  );
  world.add(s);
  return s;
}

/// Pumps real frames. The engine is left RUNNING throughout — that is the
/// point of this file.
Future<void> _pump(WidgetTester tester, [int n = 5]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Future<({LightVsShadowGame game, BattleWorld world})> _mountBattle(
  WidgetTester tester,
) async {
  final game = LightVsShadowGame();
  await tester.pumpWidget(
    ProviderScope(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: kBaselineSize.x,
          height: kBaselineSize.y,
          child: RiverpodAwareGameWidget(
            game: game,
            key: GlobalKey<RiverpodAwareGameWidgetState<LightVsShadowGame>>(),
          ),
        ),
      ),
    ),
  );
  await _pump(tester);
  expect(game.isLoaded, isTrue);

  final world = BattleWorld(
    levelId: 1,
    tray: _tray,
    onWin: (_, _) {},
    onLose: () {},
  );
  game.swapWorld(world);
  await _pump(tester, 20);
  expect(world.isLoaded, isTrue);
  return (game: game, world: world);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final hiveDir = await Directory.systemTemp.createTemp('prism_aud024_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => hiveDir.path,
        );
    await SaveStore.open();
    await Content.load();
  });

  group('AUD-024 overlays mount without a test-side resume', () {
    testWidgets('pause() mounts PauseOverlay and leaves the engine running', (
      tester,
    ) async {
      final (:game, :world) = await _mountBattle(tester);
      expect(game.paused, isFalse);

      world.pause();
      await _pump(tester, 5);

      expect(world.state, GameState.paused);
      expect(
        game.camera.viewport.children.whereType<PauseOverlay>(),
        isNotEmpty,
        reason: 'overlay was queued but never flushed — engine is paused',
      );
      expect(
        game.paused,
        isFalse,
        reason: 'pause() must freeze the sim via state, not stop the renderer',
      );
    });

    testWidgets('a paused battle stops simulating even with the engine live', (
      tester,
    ) async {
      final (:game, :world) = await _mountBattle(tester);

      world.pause();
      await _pump(tester, 5);
      final before = world.time;
      await _pump(tester, 20);

      expect(
        world.time,
        before,
        reason: 'update must early-return on state != playing',
      );
      expect(game.paused, isFalse);
    });

    testWidgets('resume() dismisses the overlay and restarts the sim', (
      tester,
    ) async {
      final (:game, :world) = await _mountBattle(tester);

      world.pause();
      await _pump(tester, 5);
      expect(
        game.camera.viewport.children.whereType<PauseOverlay>(),
        isNotEmpty,
      );

      world.resume();
      await _pump(tester, 5);

      expect(world.state, GameState.playing);
      expect(game.camera.viewport.children.whereType<PauseOverlay>(), isEmpty);
      final before = world.time;
      await _pump(tester, 10);
      expect(world.time, greaterThan(before));
    });

    testWidgets('win mounts WinOverlay', (tester) async {
      final (:game, :world) = await _mountBattle(tester);

      // Forced position on purpose — reachability is battle_playthrough_test's
      // job. This asserts only that a won board produces a VISIBLE dialog.
      world.waveIndex = world.level.waves.length;
      world.time = 1;
      expect(world.shadows, isEmpty);
      await _pump(tester, 10);

      expect(world.state, GameState.won);
      expect(
        game.camera.viewport.children.whereType<WinOverlay>(),
        isNotEmpty,
        reason: 'VICTORY dialog never mounted — this is the device symptom',
      );
      expect(game.paused, isFalse);
    });

    testWidgets('lose mounts LoseOverlay after the shake', (tester) async {
      final (:game, :world) = await _mountBattle(tester);

      const lane = 0;
      world.sweepAvailable[lane] = false;
      world.grid.sweepAvailable[lane] = false;
      await _pump(tester, 5);

      final shadow = _spawnShadow(
        world,
        lane: lane,
        x: world.layout.origin.x - 1,
      );
      await _pump(tester, 5);
      expect(shadow.isMounted, isTrue);
      expect(world.state, GameState.lost);

      // The lose shake runs on camera.viewfinder, which keeps ticking because
      // the engine was never stopped. No resumeEngine() needed — that is the
      // fix under test.
      await _pump(tester, 60);

      expect(
        game.camera.viewport.children.whereType<LoseOverlay>(),
        isNotEmpty,
        reason: 'DEFEAT dialog never mounted after the shake completed',
      );
      expect(game.paused, isFalse);
    });
  });
}
