/// Falling collectible glow — spec §5. Spawns above the board, falls for 2s,
/// and is worth +25 when tapped inside a 40px radius.
library;

import 'dart:ui';

import 'package:flutter/animation.dart' show Curves;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';

import '../../core/tokens.dart';
import 'backdrop_layers.dart' show P;

/// Tap radius is deliberately larger than the drawn orb (spec §5: 40px), which
/// is also what keeps it above the 48px minimum touch target.
const double kGlowOrbTapRadius = 40.0;

class GlowOrbComponent extends PositionComponent with TapCallbacks {
  GlowOrbComponent({
    required Vector2 spawn,
    required this.fallTo,
    required this.onCollect,
  }) : super(
         position: spawn,
         size: Vector2.all(kGlowOrbTapRadius),
         anchor: Anchor.center,
         priority: P.entity,
       );

  final double fallTo;
  final void Function(GlowOrbComponent orb) onCollect;

  bool _collected = false;

  @override
  Future<void> onLoad() async {
    add(
      MoveToEffect(
        Vector2(position.x, fallTo),
        EffectController(duration: D.secs(D.glowFall), curve: Curves.easeIn),
      ),
    );
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (_collected) return;
    _collected = true;
    onCollect(this);
    removeFromParent();
  }

  static final _glow = Paint()
    ..color = C.beamGlow
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final _core = Paint()..color = C.primary;
  static final _ray = Paint()
    ..color = C.primary
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;

  @override
  void render(Canvas canvas) {
    final c = Offset(size.x / 2, size.y / 2);
    canvas.drawCircle(c, 14, _glow);
    canvas.drawCircle(c, 8, _core);
    // Hand-drawn 4-ray sunburst (spec §10.5) — no Material icon.
    for (final (dx, dy) in const [(0.0, -1.0), (1.0, 0.0), (0.0, 1.0), (-1.0, 0.0)]) {
      canvas.drawLine(
        c + Offset(dx * 11, dy * 11),
        c + Offset(dx * 15, dy * 15),
        _ray,
      );
    }
  }
}
