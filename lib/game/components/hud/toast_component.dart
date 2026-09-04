/// Placement-rejection toast — spec §17 (e.g. "Not enough Glow", "On
/// cooldown") shown next to the tile that was tapped.
library;

import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';

import '../../../core/tokens.dart';
import 'hud_paint.dart';

/// A short red message that holds, then fades and removes itself.
///
/// Lifetime is `D.toast` end to end. There's no dedicated "toast fade"
/// duration token, so the fade itself borrows `D.place` (nearest quick-
/// transition token) and is carved out of the tail of `D.toast`, holding
/// fully opaque for the remainder.
class ToastComponent extends PositionComponent {
  ToastComponent({required String message, required Vector2 at})
    : _message = message,
      super(position: at, anchor: Anchor.center);

  final String _message;
  late final HudLabel _label;

  @override
  Future<void> onLoad() async {
    add(
      _label = HudLabel(
        _message,
        style: T.label,
        color: C.error,
        anchor: Anchor.center,
      ),
    );
    final fade = D.secs(D.place);
    final hold = math.max(D.secs(D.toast) - fade, 0.0);
    add(
      OpacityEffect.to(
        0,
        EffectController(duration: fade, startDelay: hold),
        target: _label,
        onComplete: removeFromParent,
      ),
    );
  }
}

/// Utility for firing a one-off toast without holding a reference to it.
void showToast(Component parent, String message, Vector2 at) {
  parent.add(ToastComponent(message: message, at: at));
}
