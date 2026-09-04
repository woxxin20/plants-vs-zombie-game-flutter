/// Audio + haptics gate — spec §23 / PH-04.
///
/// `assets/audio/` is currently empty (human-blocked). Trigger points call
/// [play] / [haptic], which stay inert until files exist. Settings toggles
/// drive [setSoundEnabled] (FlameAudio master volume 0/1) and [setHapticsEnabled].
library;

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';

import 'save_store.dart';

/// The eight documented cue names from spec §23. Kept as constants so call
/// sites never invent a filename the preload list does not know about.
abstract final class Sfx {
  static const place = 'place.mp3';
  static const collect = 'collect.mp3';
  static const shoot = 'shoot.mp3';
  static const hit = 'hit.mp3';
  static const explosion = 'explosion.mp3';
  static const win = 'win.mp3';
  static const lose = 'lose.mp3';
  static const sweep = 'sweep.mp3';

  static const all = <String>[
    place,
    collect,
    shoot,
    hit,
    explosion,
    win,
    lose,
    sweep,
  ];
}

abstract final class GameAudio {
  static bool _sound = true;
  static bool _haptics = true;
  static bool _ready = false;

  static bool get soundEnabled => _sound;
  static bool get hapticsEnabled => _haptics;

  /// Call once at boot after [SaveStore.open]. Preload is best-effort: when
  /// `assets/audio/` is empty the load is skipped and [play] stays a no-op.
  static Future<void> init() async {
    _sound = SaveStore.I.state.sound;
    _haptics = SaveStore.I.state.haptics;
    // No files shipped yet — do not call loadAll (it throws on missing assets)
    // and do not touch FlameAudio.bgm (needs a plugin host).
    _ready = false;
  }

  /// Settings Switch: volume 1 when on, 0 when off.
  ///
  /// Volume is applied to FlameAudio only after a successful [init] preload
  /// (`_ready`). In tests / missing-plugin hosts we only flip the gate flag.
  static Future<void> setSoundEnabled(bool enabled) async {
    _sound = enabled;
    if (!_ready) return;
    try {
      await FlameAudio.audioCache.clearAll();
      // Master gate: callers check [_sound] before play; when ready, also
      // zero the BGM bus so any ambient track respects the toggle.
      FlameAudio.bgm.audioPlayer.setVolume(enabled ? 1.0 : 0.0);
    } catch (_) {}
  }

  static void setHapticsEnabled(bool enabled) => _haptics = enabled;

  /// Play a one-shot. No-op when sound is off or assets are missing.
  static Future<void> play(String file) async {
    if (!_sound || !_ready) return;
    try {
      await FlameAudio.play(file);
    } catch (_) {
      // Missing asset or plugin host — stay silent.
    }
  }

  /// Light impact when haptics are on; no-op otherwise.
  static Future<void> haptic() async {
    if (!_haptics) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Test seam: mark the bus as "ready" without loading files.
  static void debugSetReady(bool ready) => _ready = ready;
}
