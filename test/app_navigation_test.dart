/// Navigation reachability — AUD-019.
///
/// The app shell puts the shared `GameWidget` and go_router's routed `child`
/// in one `Stack`. go_router hands a FULL-SIZE `Navigator` as that child, so
/// without `IgnorePointer` it sits on top of the game and swallows every
/// pointer event — making the entire game untappable while still rendering
/// perfectly. Nothing else in the suite catches that: the worlds' buttons all
/// fire correctly when driven through a bare `GameWidget`.
library;

import 'dart:io';

import 'package:flame_riverpod/flame_riverpod.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism_defense/app.dart';
import 'package:prism_defense/core/save_store.dart';
import 'package:prism_defense/data/content.dart';
import 'package:prism_defense/game/light_vs_shadow_game.dart';
import 'package:prism_defense/game/worlds/home_world.dart';
import 'package:prism_defense/game/worlds/loadout_world.dart';
import 'package:prism_defense/game/worlds/map_world.dart';
import 'package:prism_defense/game/worlds/settings_world.dart';
import 'package:prism_defense/game/worlds/world_widgets.dart';

Future<void> _pump(WidgetTester t, [int n = 30]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('prism_nav_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => dir.path,
        );
    await SaveStore.open();
    await Content.load();
  });

  /// Taps a named button in the live world, converting world -> screen through
  /// the camera scale, exactly as a real finger would land.
  Future<LightVsShadowGame> tapWorldButton(
    WidgetTester tester,
    String label, {
    required double screenW,
    required double screenH,
  }) async {
    final game = tester
        .widget<RiverpodAwareGameWidget<LightVsShadowGame>>(
          find.byType(RiverpodAwareGameWidget<LightVsShadowGame>),
        )
        .game!;
    final button = game.camera.world!.children
        .whereType<WorldButton>()
        .firstWhere((b) => b.label == label);
    final centre = button.absolutePosition + button.size / 2;
    final scale = screenW / 812.0;
    await tester.tapAt(Offset(centre.x * scale, centre.y * scale));
    await _pump(tester);
    return game;
  }

  group('AUD-019 the game is actually tappable through the shell', () {
    for (final size in [const Size(812, 375), const Size(2340, 1080)]) {
      testWidgets('PLAY reaches the Loadout at ${size.width.toInt()}x'
          '${size.height.toInt()}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(const ProviderScope(child: PrismDefenseApp()));
        await _pump(tester);

        final game = tester
            .widget<RiverpodAwareGameWidget<LightVsShadowGame>>(
              find.byType(RiverpodAwareGameWidget<LightVsShadowGame>),
            )
            .game!;
        expect(
          game.camera.world,
          isA<HomeWorld>(),
          reason: 'home should mount first',
        );

        await tapWorldButton(
          tester,
          'PLAY',
          screenW: size.width,
          screenH: size.height,
        );

        expect(
          game.camera.world,
          isA<LoadoutWorld>(),
          reason:
              'tapping PLAY must navigate; if this fails the routed '
              'Navigator is swallowing pointer events again',
        );
      });
    }

    testWidgets('a fresh save can actually reach a battle (AUD-020)', (
      tester,
    ) async {
      // The Loadout demanded exactly kTrayLimit (6) tools while level 1 offers
      // only 3, so Start Battle could never enable and NO level was playable
      // from a fresh save. PH-03's gate test passed throughout, because it
      // verifies that the wrong counts are blocked -- not that the right count
      // is reachable. Assert reachability, not just the guard.
      tester.view.physicalSize = const Size(2340, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const ProviderScope(child: PrismDefenseApp()));
      await _pump(tester);

      final game = await tapWorldButton(
        tester,
        'PLAY',
        screenW: 2340,
        screenH: 1080,
      );
      final loadout = game.camera.world;
      expect(loadout, isA<LoadoutWorld>());

      final slots = (loadout as LoadoutWorld).debugSlotCount;
      expect(
        slots,
        greaterThan(0),
        reason: 'level 1 must offer at least one tool',
      );

      (loadout).debugSelectAll();
      await _pump(tester, 5);

      expect(
        loadout.debugCanStart,
        isTrue,
        reason:
            'picking every offered tool must enable Start Battle; if this '
            'fails the tray demands more tools than the level provides and '
            'the game is unplayable',
      );
    });

    testWidgets('MAP and SETTINGS are reachable too', (tester) async {
      tester.view.physicalSize = const Size(2340, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const ProviderScope(child: PrismDefenseApp()));
      await _pump(tester);

      var game = await tapWorldButton(
        tester,
        'MAP',
        screenW: 2340,
        screenH: 1080,
      );
      expect(game.camera.world, isA<MapWorld>());

      // Back to home, then into Settings.
      game = await tapWorldButton(tester, 'BACK', screenW: 2340, screenH: 1080);
      expect(game.camera.world, isA<HomeWorld>());

      game = await tapWorldButton(
        tester,
        'SETTINGS',
        screenW: 2340,
        screenH: 1080,
      );
      expect(game.camera.world, isA<SettingsWorld>());
    });
  });
}
