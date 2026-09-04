/// Reusable HUD button — spec §12 (Home/Pause/Win/Lose button rows) and
/// §18.2 (press pop).
library;

import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/animation.dart' show Curves;

import '../../../core/tokens.dart';
import 'hud_paint.dart';

enum GameButtonStyle { primary, secondary, text }

/// A tappable HUD button: an `R.button` RRect body with a centred label.
/// Used by every overlay (Resume/Restart/Home, Replay/Next, Try Again) and
/// by the RightPanel Boost button.
class GameButton extends PositionComponent with TapCallbacks {
  GameButton({
    required this.label,
    required Vector2 size,
    this.style = GameButtonStyle.primary,
    bool enabled = true,
    required this.onPressed,
    super.position,
    super.anchor,
  }) : _enabled = enabled,
       super(
         size: Vector2(
           math.max(size.x, S.minTouch),
           math.max(size.y, S.minTouch),
         ),
       );

  final String label;
  final GameButtonStyle style;
  final void Function() onPressed;

  bool _enabled;
  bool get enabled => _enabled;
  set enabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    _label.opacity = _enabled ? 1.0 : 0.4;
  }

  late final HudLabel _label;

  Color get _labelColor => switch (style) {
    GameButtonStyle.primary => C.onPrimary,
    GameButtonStyle.secondary => C.textPrimary,
    GameButtonStyle.text => C.textSecondary,
  };

  @override
  Future<void> onLoad() async {
    add(
      _label = HudLabel(
        label,
        style: T.h3,
        color: _labelColor,
        anchor: Anchor.center,
        position: size / 2,
      )..opacity = _enabled ? 1.0 : 0.4,
    );
  }

  static final _shadowPaint = Paint()
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, Elevation.button.blur);
  static final _fillPaint = Paint();

  @override
  void render(Canvas canvas) {
    final alpha = _enabled ? 1.0 : 0.4;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size.toSize(),
      const Radius.circular(R.button),
    );
    if (style == GameButtonStyle.primary) {
      canvas.save();
      canvas.translate(0, Elevation.button.dy);
      canvas.drawRRect(
        rrect,
        _shadowPaint
          ..color = Elevation.button.color.withValues(
            alpha: Elevation.button.color.a * alpha,
          ),
      );
      canvas.restore();
    }
    if (style != GameButtonStyle.text) {
      final bg = style == GameButtonStyle.primary ? C.primary : C.surface3;
      canvas.drawRRect(rrect, _fillPaint..color = bg.withValues(alpha: alpha));
    }
  }

  /// Spec §18.2 button press: scale to 0.97 and back, easeOut, 100ms — then
  /// fire [onPressed]. Disabled buttons ignore taps entirely.
  @override
  void onTapUp(TapUpEvent event) {
    if (!_enabled) return;
    add(
      ScaleEffect.to(
        Vector2.all(0.97),
        EffectController(
          duration: D.secs(D.buttonPress),
          curve: Curves.easeOut,
          alternate: true,
        ),
        onComplete: onPressed,
      ),
    );
  }
}
