/// Battle HUD reachability — AUD-021 — and world lifetime — AUD-022.
///
/// The HUD components were written, styled and unit-tested, and never once
/// constructed by production code: `TopBarComponent`, `RightPanelComponent`
/// and `ToastComponent` had zero call sites in `lib/`. A battle therefore
/// rendered its grid and lane sweeps but carried no glow chip, no wave
/// counter, no pause button and no tool tray, so it could not be played at
/// all — while `flutter analyze` stayed clean and 66 tests stayed green.
///
/// PH-01's gate test did assert the TopBar updates reactively, but it built a
/// bare `FlameGame` and added the bar by hand. That is exactly the shape of
/// test that cannot see this defect: it verifies the component in isolation
/// and never asks whether anything mounts it. These tests drive the real
/// shell to a real battle and assert on `camera.viewport`.
library;

import 'dart:io';

import 'package:flame/components.dart';
import 'package:flame_riverpod/flame_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism_defense/app.dart';
import 'package:prism_defense/core/save_store.dart';
import 'package:prism_defense/data/content.dart';
import 'package:prism_defense/data/models.dart' show PlaceResult;
import 'package:prism_defense/game/components/hud/right_panel_component.dart';
import 'package:prism_defense/game/components/hud/top_bar_component.dart';
import 'package:prism_defense/game/light_vs_shadow_game.dart';
import 'package:prism_defense/game/worlds/battle_world.dart';
import 'package:prism_defense/game/worlds/home_world.dart';
import 'package:prism_defense/game/worlds/loadout_world.dart';
import 'package:prism_defense/game/worlds/world_widgets.dart';

const Size _screen = Size(2340, 1080);

Future<void> _pump(WidgetTester t, [int n = 30]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 16));
  }
}

LightVsShadowGame _game(WidgetTester tester) => tester
    .widget<RiverpodAwareGameWidget<LightVsShadowGame>>(
      find.byType(RiverpodAwareGameWidget<LightVsShadowGame>),
    )
    .game!;

/// Taps a named button in the live world, converting world -> screen through
/// the camera scale, exactly as a real finger would land.
Future<LightVsShadowGame> _tap(WidgetTester tester, String label) async {
  final game = _game(tester);
  final button = game.camera.world!.children
      .whereType<WorldButton>()
      .firstWhere((b) => b.label == label);
  final centre = button.absolutePosition + button.size / 2;
  final scale = _screen.width / 812.0;
  await tester.tapAt(Offset(centre.x * scale, centre.y * scale));
  await _pump(tester);
  return game;
}

/// The HUD as the player meets it: read off `camera.viewport`, never off a
/// getter added to the world for the test's convenience.
T _hud<T extends Component>(LightVsShadowGame game) =>
    game.camera.viewport.children.whereType<T>().single;

/// Home -> Loadout -> pick every offered tool -> Battle.
Future<LightVsShadowGame> _enterBattle(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: PrismDefenseApp()));
  await _pump(tester);
  expect(_game(tester).camera.world, isA<HomeWorld>());

  var game = await _tap(tester, 'PLAY');
  final loadout = game.camera.world;
  expect(loadout, isA<LoadoutWorld>());
  (loadout! as LoadoutWorld).debugSelectAll();
  await _pump(tester, 5);

  game = await _tap(tester, 'START BATTLE');
  expect(
    game.camera.world,
    isA<BattleWorld>(),
    reason: 'START BATTLE must reach the battle',
  );
  return game;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('prism_hud_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => dir.path,
        );
    await SaveStore.open();
    await Content.load();
  });

  group('AUD-021 a battle actually has a HUD', () {
    testWidgets('TopBar and RightPanel are mounted on the viewport', (
      tester,
    ) async {
      tester.view.physicalSize = _screen;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final game = await _enterBattle(tester);
      final viewport = game.camera.viewport.children;

      expect(
        viewport.whereType<TopBarComponent>(),
        hasLength(1),
        reason:
            'no TopBar on the viewport means no glow chip, no wave counter '
            'and no pause button — the battle cannot be played',
      );
      expect(
        viewport.whereType<RightPanelComponent>(),
        hasLength(1),
        reason:
            'no RightPanel means no tool tray, so nothing can ever be placed',
      );
    });

    testWidgets('the tray holds the tools the player actually picked', (
      tester,
    ) async {
      tester.view.physicalSize = _screen;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final game = await _enterBattle(tester);
      final battle = game.camera.world! as BattleWorld;
      final panel = _hud<RightPanelComponent>(game);

      expect(
        panel.slots.map((s) => s.def.id).toList(),
        battle.tray,
        reason: 'the tray must show the loadout selection, in order',
      );
      expect(
        battle.tray,
        isNotEmpty,
        reason: 'a battle entered through the loadout carries tools',
      );
    });

    testWidgets('the HUD is driven by the simulation, not just mounted', (
      tester,
    ) async {
      tester.view.physicalSize = _screen;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final game = await _enterBattle(tester);
      final battle = game.camera.world! as BattleWorld;
      final bar = _hud<TopBarComponent>(game);

      expect(
        bar.glow,
        battle.glow,
        reason: 'the chip must show the real glow total',
      );
      expect(bar.waveCount, battle.level.waves.length);

      // Spend glow through the real placement path and confirm the HUD follows.
      final before = battle.glow;
      final tool = battle.tray.first;
      battle.selectedTool = tool;
      expect(battle.tryPlace(tool, 0, 0), PlaceResult.ok);
      await _pump(tester, 3);

      expect(
        battle.glow,
        lessThan(before),
        reason: 'placing a tool costs glow',
      );
      expect(
        bar.glow,
        battle.glow,
        reason:
            'the TopBar must track glow after a placement; if this fails the '
            'HUD is mounted but nothing is pushing state into it',
      );

      final slot = _hud<RightPanelComponent>(
        game,
      ).slots.firstWhere((s) => s.def.id == tool);
      expect(
        slot.cooldownRemaining,
        greaterThan(0),
        reason: 'the slot just used must show its cooldown',
      );
    });
  });

  group('AUD-022 worlds do not accumulate', () {
    testWidgets('navigating repeatedly leaves exactly one world mounted', (
      tester,
    ) async {
      tester.view.physicalSize = _screen;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const ProviderScope(child: PrismDefenseApp()));
      await _pump(tester);

      // swapWorld read FlameGame.world, which stays the default World forever,
      // so from the second navigation on the outgoing world was never removed
      // and kept ticking behind the new one.
      for (var i = 0; i < 3; i++) {
        await _tap(tester, 'MAP');
        await _tap(tester, 'BACK');
      }

      final game = _game(tester);
      expect(
        game.children.whereType<World>(),
        hasLength(1),
        reason:
            'each swap must remove the outgoing world; more than one means '
            'dead worlds are still mounted and still updating',
      );
    });
  });
}
