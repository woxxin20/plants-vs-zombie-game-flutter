/// The single persistent FlameGame. Screens are `World`s swapped onto the same
/// camera rather than separate games (spec §12/§13), so navigating Home → Map →
/// Battle never pays the engine re-init cost.
library;

import 'dart:ui';

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
    await super.onLoad();
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
  ///
  /// HUD is per-screen: a world mounts its own onto `camera.viewport` from its
  /// `onLoad`. That runs *after* this method returns, so the viewport is
  /// cleared here first — clearing it last deleted the incoming world's HUD
  /// the moment it arrived, which is what left every battle with no HUD at all
  /// (`AUD-021`).
  void swapWorld(World next) {
    // `camera.world`, NOT `FlameGame.world`. This method only ever assigns the
    // camera's, so `world` stays the default World for the life of the game;
    // reading it here made `previous.isMounted` false from the second swap on,
    // leaving every outgoing world mounted and ticking (`AUD-022`). Same root
    // confusion as `AUD-017`.
    final previous = camera.world;
    if (identical(previous, next)) return;

    camera.viewport.removeAll(camera.viewport.children.toList());
    camera.world = next;
    if (!next.isMounted) add(next);
    // No `isMounted` guard: the very first swap happens while FlameGame's own
    // default World is still only queued, so testing for it left that empty
    // world a child of the game forever. `removeFromParent` is a no-op when
    // there is no parent, and handles a still-pending child correctly.
    previous?.removeFromParent();
  }
}
