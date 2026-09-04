/// Boot check for the app shell: `PrismDefenseApp` must build a WidgetsApp-only
/// tree, resolve the initial route, and mount `HomeWorld` on the single shared
/// game (ADR-003/ADR-006). If the shell or the router regresses, this fails
/// where `flutter analyze` cannot see it.
library;

import 'dart:io';

import 'package:flame_riverpod/flame_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism_defense/app.dart';
import 'package:prism_defense/core/save_store.dart';
import 'package:prism_defense/data/content.dart';
import 'package:prism_defense/game/light_vs_shadow_game.dart';
import 'package:prism_defense/game/worlds/home_world.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // hive_ce_flutter's initFlutter() asks path_provider for the docs dir;
    // there is no plugin host in a widget test, so answer it with a temp dir.
    // Left behind on purpose: Hive keeps the box file open, so the OS reaps it.
    final hiveDir = await Directory.systemTemp.createTemp('prism_defense_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => hiveDir.path,
        );

    await SaveStore.open();
    await Content.load();
  });

  testWidgets('boots into HomeWorld on the one shared game', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PrismDefenseApp()));

    // Flame's ticker never settles, so pump fixed frames instead of settling.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(find.byType(WidgetsApp), findsOneWidget);

    final widget = tester.widget<RiverpodAwareGameWidget<LightVsShadowGame>>(
      find.byType(RiverpodAwareGameWidget<LightVsShadowGame>),
    );
    expect(widget.game!.camera.world, isA<HomeWorld>());
  });
}
