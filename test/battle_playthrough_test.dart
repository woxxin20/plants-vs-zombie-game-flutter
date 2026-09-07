/// PH-02-G3 — a test that actually plays a level.
///
/// Every other win/lose test in this suite reaches the terminal state by
/// *forcing* it (`world.waveIndex = world.level.waves.length`, then pumping a
/// frame). That proves `hasWon` fires when handed a won position; it proves
/// nothing about whether the position is reachable by playing. Level 1 could be
/// unwinnable and the whole suite would stay green — which is exactly the shape
/// of blindness that hid `AUD-020` and `AUD-021`.
///
/// This test starts at the real Home screen, walks the real shell into a real
/// battle, and then plays: it collects falling glow by tapping it, spends that
/// glow through the same placement path a finger drives, and lets the clock run
/// at the engine's own capped step until the sim declares a result. Nothing is
/// assigned into the world. The only assertion is that a competent player wins.
library;

import 'dart:io';

import 'package:flame_riverpod/flame_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism_defense/app.dart';
import 'package:prism_defense/core/save_store.dart';
import 'package:prism_defense/data/content.dart';
import 'package:prism_defense/data/models.dart'
    show GameState, PlaceResult, kRows;
import 'package:prism_defense/game/components/glow_orb_component.dart';
import 'package:prism_defense/game/light_vs_shadow_game.dart';
import 'package:prism_defense/game/worlds/battle_world.dart';
import 'package:prism_defense/game/worlds/home_world.dart';
import 'package:prism_defense/game/worlds/loadout_world.dart';
import 'package:prism_defense/game/worlds/world_widgets.dart';

const Size _screen = Size(2340, 1080);

/// World -> screen. The camera keeps the 812-wide design box and letterboxes,
/// so a world x maps to a physical x by this one scale factor.
const double _scale = 2340 / 812.0;

/// The engine clamps its own step to 1/30, so pumping faster than 33ms buys no
/// sim time. One pump therefore advances the battle by exactly 1/30 s.
const Duration _frame = Duration(milliseconds: 33);

LightVsShadowGame _game(WidgetTester t) => t
    .widget<RiverpodAwareGameWidget<LightVsShadowGame>>(
      find.byType(RiverpodAwareGameWidget<LightVsShadowGame>),
    )
    .game!;

Future<void> _pump(WidgetTester t, [int n = 30]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(_frame);
  }
}

Future<LightVsShadowGame> _tap(WidgetTester t, String label) async {
  final game = _game(t);
  final button = game.camera.world!.children
      .whereType<WorldButton>()
      .firstWhere((b) => b.label == label);
  final centre = button.absolutePosition + button.size / 2;
  await t.tapAt(Offset(centre.x * _scale, centre.y * _scale));
  await _pump(t);
  return game;
}

Future<BattleWorld> _enterBattle(WidgetTester t) async {
  await t.pumpWidget(const ProviderScope(child: PrismDefenseApp()));
  await _pump(t);
  expect(_game(t).camera.world, isA<HomeWorld>());

  var game = await _tap(t, 'PLAY');
  (game.camera.world! as LoadoutWorld).debugSelectAll();
  await _pump(t, 5);

  game = await _tap(t, 'START BATTLE');
  return game.camera.world! as BattleWorld;
}

/// Taps every orb currently falling. This is the only glow income a player gets
/// besides generators, and it only exists if the orb is genuinely tappable —
/// so collecting through a real tap also proves the collectible is reachable.
Future<void> _collectOrbs(WidgetTester t, BattleWorld battle) async {
  final orbs = battle.children.whereType<GlowOrbComponent>().toList();
  for (final orb in orbs) {
    final centre = orb.absolutePosition;
    await t.tapAt(Offset(centre.x * _scale, centre.y * _scale));
  }
}

/// A deliberately dumb but legal strategy: hold one Bulb per lane for income,
/// and one Beam per lane for damage, always in the two leftmost columns so
/// nothing is placed under a shadow. Returns true if it spent anything.
bool _spend(BattleWorld battle) {
  bool place(String id, int row, int col) {
    if (battle.toolAt(row, col) != null) return false;
    battle.selectedTool = id;
    return battle.tryPlace(id, row, col) == PlaceResult.ok;
  }

  for (var lane = 0; lane < kRows; lane++) {
    if (place('beam', lane, 1)) return true;
  }
  for (var lane = 0; lane < kRows; lane++) {
    if (place('bulb', lane, 0)) return true;
  }
  return false;
}

/// Mounts a battle on the live game directly. Used only where the shell cannot
/// reach the level (the map gates on save progress); the simulation itself is
/// untouched — nothing is assigned into the world.
Future<BattleWorld> _battle(WidgetTester t, int levelId) async {
  await t.pumpWidget(const ProviderScope(child: PrismDefenseApp()));
  await _pump(t, 5);
  final battle = BattleWorld(
    levelId: levelId,
    tray: const ['bulb', 'beam', 'wall'],
    onWin: (_, _) {},
    onLose: () {},
  );
  _game(t).swapWorld(battle);
  await _pump(t, 5);
  return battle;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('prism_play_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => dir.path,
        );
    await SaveStore.open();
    await Content.load();
  });

  testWidgets('level 1 is winnable by playing it — no forced state', (t) async {
    t.view.physicalSize = _screen;
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    final battle = await _enterBattle(t);
    expect(battle.state, GameState.playing);
    expect(battle.level.id, 1, reason: 'the first level is the one under test');

    // Generous: level 1 pars at 45s. If a played win needs four times par,
    // the level is not winnable in any sense the player would recognise.
    const limit = 180.0;
    var guard = 0;
    while (battle.state == GameState.playing && battle.time < limit) {
      _spend(battle);
      await _pump(t, 15); // half a second of real sim
      await _collectOrbs(t, battle);
      guard++;
      expect(guard, lessThan(2000), reason: 'sim clock is not advancing');
    }

    expect(
      battle.state,
      GameState.won,
      reason:
          'a player who places a Beam and a Bulb in every lane, and collects '
          'the glow that falls, must be able to win the first level. Reached '
          '${battle.state.name} at t=${battle.time.toStringAsFixed(1)}s with '
          'wave ${battle.waveIndex}/${battle.level.waves.length} and '
          '${battle.shadows.length} shadows alive',
    );
    // The load-bearing assertion. Level 1 is won even by an idle player
    // (`AUD-023`), so "won" alone proves nothing about the play loop — but an
    // idle win burns all three lane sweeps, because a sweep is what killed
    // every shadow. A win with the sweeps still intact can only mean the tools
    // the test placed did the damage: glow was earned, spent, and converted
    // into kills through the real simulation.
    expect(
      battle.sweepAvailable,
      everyElement(isTrue),
      reason:
          'the placed Beams must kill the shadows before they reach the core; '
          'a spent sweep means the tools did nothing and the lane saved itself',
    );
    expect(
      SaveStore.I.state.starsFor(1),
      greaterThanOrEqualTo(2),
      reason:
          'a leak-free win scores at least 2 (spec §19). This strategy is '
          'deliberately dumb and finishes over the 45s par, so 3 is not '
          'claimed here — only that the win was really scored and saved',
    );
  });

  testWidgets('the fail state is reachable by playing — level 4, no input', (
    t,
  ) async {
    t.view.physicalSize = _screen;
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    // Level 4 rather than level 1 on purpose: levels 1-3 ship only three waves,
    // and one sweep per lane clears an entire lane whatever the shadows'
    // positions (spec §17), so those three levels cannot be lost at all and
    // are won by leaving the phone on the table. That is `AUD-023`, a level-data
    // defect, not a rules defect — asserting it here would lock the bug in, so
    // this test proves the fail state is reachable on the first level where the
    // waves outnumber the sweeps.
    final battle = await _battle(t, 4);

    const limit = 240.0;
    while (battle.state == GameState.playing && battle.time < limit) {
      await _pump(t, 30);
    }

    expect(
      battle.state,
      GameState.lost,
      reason:
          'with nothing placed, shadows must outlast the lane sweeps and reach '
          'the Light Core. Reached ${battle.state.name} at '
          't=${battle.time.toStringAsFixed(1)}s',
    );
  });
}
