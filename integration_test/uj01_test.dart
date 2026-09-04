/// Integration coverage for `UJ-01` (play a level → win) and the
/// save-survives path called out by `AUD-015`.
///
/// Runs via `flutter test integration_test -d windows` (or an emulator).
/// On-device playthrough of `assets/levels/1.json` remains human-blocked.
library;

import 'dart:io';

import 'package:flame_riverpod/flame_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:prism_defense/core/layout.dart';
import 'package:prism_defense/core/save_store.dart';
import 'package:prism_defense/data/content.dart';
import 'package:prism_defense/data/models.dart';
import 'package:prism_defense/game/components/hud/overlay_win.dart';
import 'package:prism_defense/game/light_vs_shadow_game.dart';
import 'package:prism_defense/game/worlds/battle_world.dart';

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
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final hiveDir = await Directory.systemTemp.createTemp('prism_uj01_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => hiveDir.path,
        );
    await SaveStore.open();
    await Content.load();
  });

  testWidgets('UJ-01: battle win shows overlay and persists save', (
    tester,
  ) async {
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

    const tray = <String>['bulb', 'beam', 'wall', 'mirror', 'frost', 'bomb'];
    final coinsBefore = SaveStore.I.state.coins;

    final world = BattleWorld(
      levelId: 1,
      tray: tray,
      onWin: (_, _) {},
      onLose: () {},
    );
    game.swapWorld(world);
    await _pumpFrames(tester, 20);
    game.pauseEngine();

    world.waveIndex = world.level.waves.length;
    world.update(0.016);
    await _flushLifecycle(tester, game);

    expect(world.state, GameState.won);
    expect(
      game.camera.viewport.children.whereType<WinOverlay>(),
      isNotEmpty,
    );
    expect(SaveStore.I.state.coins, greaterThan(coinsBefore));
    expect(SaveStore.I.state.starsFor(1), greaterThan(0));
    expect(SaveStore.I.state.totalPlays, greaterThan(0));
  });
}
