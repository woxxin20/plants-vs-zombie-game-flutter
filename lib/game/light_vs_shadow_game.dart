/// The single persistent FlameGame. Screens are `World`s swapped onto the same
/// camera rather than separate games (spec §12/§13), so navigating Home → Map →
/// Battle never pays the engine re-init cost.
library;

import 'dart:ui';

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_riverpod/flame_riverpod.dart';

import '../core/layout.dart';
import '../core/tokens.dart';

class LightVsShadowGame extends FlameGame
    with HasCollisionDetection, RiverpodGameMixin {
  LightVsShadowGame({World? initialWorld}) : _pendingWorld = initialWorld;

  World? _pendingWorld;

  /// Recomputed on every resize; every component reads geometry from here
  /// instead of measuring the screen itself.
  late BattleLayout layout = BattleLayout(kBaselineSize.clone());

  @override
  Color backgroundColor() => C.bg;

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewfinder.visibleGameSize = kBaselineSize.clone();
    if (_pendingWorld case final w?) {
      swapWorld(w);
      _pendingWorld = null;
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // The camera keeps the 812x375 design box, so components can address the
    // baseline coordinate space and let Flame letterbox for real devices.
    layout = BattleLayout(kBaselineSize.clone());
  }

  /// Replaces the active screen. The previous world is removed outright so its
  /// particle generators stop ticking (spec §24 edge case 20).
  void swapWorld(World next) {
    final previous = world;
    camera.world = next;
    if (!next.isMounted) add(next);
    if (previous != next && previous.isMounted) {
      previous.removeFromParent();
    }
    // HUD is per-screen: each world adds what it needs to camera.viewport.
    camera.viewport.removeAll(camera.viewport.children.toList());
  }
}
