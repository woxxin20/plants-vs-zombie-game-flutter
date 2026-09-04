/// PH-04 exit-gate suite — juice code-half (`docs/phases.md` §8).
///
/// Audio asset preload is human-blocked (`assets/audio/` empty); triggers are
/// wired but inert. Stars/coins §19 already covered in `rules_test.dart`.
library;

import 'dart:io';

import 'package:flame_riverpod/flame_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism_defense/core/audio.dart';
import 'package:prism_defense/core/layout.dart';
import 'package:prism_defense/core/save_store.dart';
import 'package:prism_defense/data/content.dart';
import 'package:prism_defense/data/rules.dart';
import 'package:prism_defense/game/light_vs_shadow_game.dart';
import 'package:prism_defense/game/particles/effect_pool.dart';
import 'package:prism_defense/game/particles/particle_definitions.dart' as fx;
import 'package:prism_defense/game/worlds/settings_world.dart';
import 'package:prism_defense/game/worlds/shop_world.dart';
import 'package:flame/components.dart';

Future<void> _pumpFrames(WidgetTester tester, [int n = 5]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final hiveDir = await Directory.systemTemp.createTemp('prism_ph04_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => hiveDir.path,
        );
    await SaveStore.open();
    await Content.load();
    await GameAudio.init();
  });

  group('PH-04 particles §18.1', () {
    test('inventory factories return ParticleSystemComponents', () {
      final at = Vector2.zero();
      expect(fx.placeBurst(at), isA<ParticleSystemComponent>());
      expect(fx.collectBurst(at), isA<ParticleSystemComponent>());
      expect(fx.hitSpark(at), isA<ParticleSystemComponent>());
      expect(fx.sweepBurst(at), isA<ParticleSystemComponent>());
      expect(fx.deathDissolve(at), isA<ParticleSystemComponent>());
      expect(fx.explosionBurst(at), isA<ParticleSystemComponent>());
      expect(fx.confettiFall(at, 100), isA<ParticleSystemComponent>());
      expect(fx.leapDust(at), isA<ParticleSystemComponent>());
    });

    test('Spark/Collect go through ParticlePool, not uncapped add', () {
      final parent = Component();
      final pool = ParticlePool(parent, maxLive: 2);
      pool.emit(() => fx.hitSpark(Vector2.zero()));
      pool.emit(() => fx.collectBurst(Vector2.zero()));
      expect(pool.liveCount, 2);
      // Cap drops further high-frequency spam.
      pool.emit(() => fx.hitSpark(Vector2.zero()));
      expect(pool.liveCount, 2);
    });
  });

  group('PH-04 stars/coins §19', () {
    test('award formula matches spec (also in rules_test)', () {
      expect(
        starsFor(elapsed: 40, parTime: 45, sweepAvailable: [true, true, true]),
        3,
      );
      expect(coinsFor(previousStars: 0, newStars: 3), 50);
      expect(coinsFor(previousStars: 3, newStars: 3), 10);
    });
  });

  group('PH-04 shop', () {
    testWidgets('Tray Slot +2 and Remove Ads update save and disable', (
      tester,
    ) async {
      SaveStore.I.state.coins = 500;
      SaveStore.I.state.traySlotBonus = 0;
      SaveStore.I.state.removeAds = false;

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
                key:
                    GlobalKey<
                      RiverpodAwareGameWidgetState<LightVsShadowGame>
                    >(),
              ),
            ),
          ),
        ),
      );
      await _pumpFrames(tester);

      final shop = ShopWorld(onRemoveAdsPressed: () {}, onBack: () {});
      game.swapWorld(shop);
      await _pumpFrames(tester, 20);
      game.pauseEngine();

      expect(shop.debugTraySlotEnabled, isTrue);
      shop.debugBuyTraySlot();
      expect(SaveStore.I.state.traySlotBonus, 2);
      expect(SaveStore.I.state.coins, 300);
      expect(shop.debugTraySlotEnabled, isFalse);

      expect(shop.debugRemoveAdsEnabled, isTrue);
      shop.debugBuyRemoveAds();
      expect(SaveStore.I.state.removeAds, isTrue);
      expect(shop.debugRemoveAdsEnabled, isFalse);
    });
  });

  group('PH-04 settings switches', () {
    testWidgets('Sound/Haptics switches gate GameAudio', (tester) async {
      SaveStore.I.state.sound = true;
      SaveStore.I.state.haptics = true;
      await GameAudio.setSoundEnabled(true);
      GameAudio.setHapticsEnabled(true);

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
                key:
                    GlobalKey<
                      RiverpodAwareGameWidgetState<LightVsShadowGame>
                    >(),
              ),
            ),
          ),
        ),
      );
      await _pumpFrames(tester);

      final settings = SettingsWorld(onBack: () {});
      game.swapWorld(settings);
      await _pumpFrames(tester, 20);
      game.pauseEngine();

      final switches = settings.children.whereType<SwitchComponent>().toList();
      expect(switches, hasLength(2));

      switches[0].debugSet(false); // Sound
      expect(SaveStore.I.state.sound, isFalse);
      expect(GameAudio.soundEnabled, isFalse);

      switches[1].debugSet(false); // Haptics
      expect(SaveStore.I.state.haptics, isFalse);
      expect(GameAudio.hapticsEnabled, isFalse);
    });
  });

  group('PH-04 audio assets (blocked)', () {
    test('assets/audio is empty — preload gated, Sfx list documented', () {
      final dir = Directory('assets/audio');
      final mp3 = dir.existsSync()
          ? dir
                .listSync()
                .whereType<File>()
                .where((f) => f.path.endsWith('.mp3'))
                .toList()
          : <File>[];
      expect(mp3, isEmpty, reason: 'human-blocked: no audio files shipped');
      expect(Sfx.all, hasLength(8));
    });
  });
}
