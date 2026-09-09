import 'dart:math' as math;

import 'package:flame_riverpod/flame_riverpod.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism_defense/data/content.dart';
import 'package:prism_defense/game/components/hud/right_panel_component.dart';
import 'package:prism_defense/game/components/hud/top_bar_component.dart';
import 'package:prism_defense/game/light_vs_shadow_game.dart';
import 'package:prism_defense/game/worlds/battle_world.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Content.load();
  });

  Future<void> pumpFrames(WidgetTester tester, [int n = 5]) async {
    for (var i = 0; i < n; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  Future<void> runViewportTest(
    WidgetTester tester, {
    required Size physicalSize,
    required double dpr,
  }) async {
    tester.view.physicalSize = physicalSize;
    tester.view.devicePixelRatio = dpr;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final game = LightVsShadowGame();
    final gameKey =
        GlobalKey<RiverpodAwareGameWidgetState<LightVsShadowGame>>();

    await tester.pumpWidget(
      ProviderScope(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: RiverpodAwareGameWidget(game: game, key: gameKey),
        ),
      ),
    );
    await pumpFrames(tester, 5);

    final world = BattleWorld(
      levelId: 1,
      tray: const ['bulb', 'beam', 'wall'],
      onWin: (_, _) {},
      onLose: () {},
    );

    game.swapWorld(world);
    await pumpFrames(tester, 20);

    expect(world.isLoaded, isTrue);
    expect(world.grid.isLoaded, isTrue);

    final topBar = game.camera.viewport.children
        .whereType<TopBarComponent>()
        .first;
    final panel = game.camera.viewport.children
        .whereType<RightPanelComponent>()
        .first;
    final viewportSize = game.camera.viewport.size;

    // TopBar spans full viewport width
    expect(topBar.size.x, equals(viewportSize.x));

    // RightPanel pins to the right edge of viewport
    expect(panel.position.x, equals(viewportSize.x - 220));
    expect(panel.size.x, equals(220));
    expect(panel.size.y, equals(viewportSize.y - 48));

    final panelLeft = panel.position.x;
    final panelRight = panel.position.x + panel.size.x;

    // Check all 3 rows of column 7 (col = 6)
    for (var r = 0; r < 3; r++) {
      final tile = world.grid.tileAt(r, 6);
      final tileTopLeft = game.camera.localToGlobal(tile.absolutePosition);
      final tileBottomRight = game.camera.localToGlobal(
        tile.absolutePosition + tile.size,
      );
      final tileCenter = game.camera.localToGlobal(tile.absoluteCenter);

      final overlapLeft = math.max(tileTopLeft.x, panelLeft);
      final overlapRight = math.min(tileBottomRight.x, panelRight);
      final overlapW = math.max(0.0, overlapRight - overlapLeft);

      // TASK-047 verification: ZERO overlap across all viewports!
      expect(
        overlapW,
        equals(0.0),
        reason: 'TASK-047: Row $r Col 6 must have zero overlap with RightPanel',
      );

      // Verify tile center tap works cleanly
      world.glow = 100;
      world.lastPlaced.clear();
      world.selectedTool = 'bulb';
      await tester.tapAt(Offset(tileCenter.x, tileCenter.y));
      await pumpFrames(tester, 5);

      final placedAtCenter = world.toolAt(r, 6) != null;
      expect(
        placedAtCenter,
        isTrue,
        reason: 'Tile($r, 6) must be tappable at center',
      );

      // Clean up tile for next test
      world.removeToolAt(r, 6);

      // Verify right edge of tile is also completely free and tappable
      final rightEdgeTap = Offset(tileBottomRight.x - 5, tileCenter.y);
      world.glow = 100;
      world.lastPlaced.clear();
      world.selectedTool = 'bulb';
      await tester.tapAt(rightEdgeTap);
      await pumpFrames(tester, 5);

      final placedAtRightEdge = world.toolAt(r, 6) != null;
      expect(
        placedAtRightEdge,
        isTrue,
        reason: 'Tile($r, 6) must be tappable at right edge (no occlusion)',
      );
      world.removeToolAt(r, 6);
    }
  }

  testWidgets(
    'TASK-047 / AUD-028: Wider viewport (2424x1080, DPR 2.625, aspect 2.244)',
    (tester) async {
      await runViewportTest(
        tester,
        physicalSize: const Size(2424, 1080),
        dpr: 2.625,
      );
    },
  );

  testWidgets(
    'TASK-047 / AUD-028: Baseline viewport (812x375, DPR 1.0, aspect 2.165)',
    (tester) async {
      await runViewportTest(
        tester,
        physicalSize: const Size(812, 375),
        dpr: 1.0,
      );
    },
  );

  testWidgets(
    'TASK-047 / AUD-028: Narrower viewport (1920x1080, DPR 2.4, aspect 1.778)',
    (tester) async {
      await runViewportTest(
        tester,
        physicalSize: const Size(1920, 1080),
        dpr: 2.4,
      );
    },
  );
}
