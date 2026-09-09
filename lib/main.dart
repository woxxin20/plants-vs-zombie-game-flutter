/// Entry point. Landscape lock, immersive sticky, Hive open, content preload,
/// then the app shell. Root is `WidgetsApp` — never `MaterialApp` (ADR-006).
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/audio.dart';
import 'core/save_store.dart';
import 'data/content.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF0A0E1A),
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF141A2E),
    ),
  );

  await SaveStore.open();
  await Content.load();
  await GameAudio.init();
  // AUD-027: one ambient loop for the whole app. Started once here rather than
  // per-world, so navigating Home -> Map -> Battle does not restart the track.
  await GameAudio.startBgm();

  runApp(const ProviderScope(child: PrismDefenseApp()));
}
