/// The five enemies (spec §7). One class, behaviour switched by `ShadowDef`,
/// because the differences are four flags and a size — eight subclasses would
/// be more files than logic.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/animation.dart' show Curves;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';

import '../../core/tokens.dart';
import '../../data/models.dart';
import 'backdrop_layers.dart' show P;
import 'fadeable.dart';

class ShadowComponent extends PositionComponent
    with CollisionCallbacks, FadeableRender {
  ShadowComponent({
    required this.def,
    required this.lane,
    required this.fromWave,
    required Vector2 spawn,
  }) : hp = def.hp.toDouble(),
       maxHp = def.hp.toDouble(),
       super(
         position: spawn,
         size: Vector2.all(def.id == 'giant' ? 44 : 32),
         anchor: Anchor.center,
         priority: P.entity,
       );

  final ShadowDef def;
  final int lane;

  /// Index of the wave this shadow belongs to — the 50% rule needs it.
  final int fromWave;

  double hp;
  final double maxHp;

  /// Battle time until which this shadow moves at half speed (frost).
  double slowUntil = 0;

  /// True while chewing a tool; the shadow stops walking.
  bool isEating = false;

  /// Leaper hops the first wall only (spec §7).
  bool hasJumped = false;

  /// Colossus throws one Shade at 50% HP (spec §7).
  bool hasThrown = false;

  bool _dying = false;
  bool get isDying => _dying;

  double _bobPhase = 0;

  String get id => def.id;
  double get hpFraction => (hp / maxHp).clamp(0.0, 1.0);

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox(collisionType: CollisionType.passive));
    _bobPhase = position.x % (math.pi * 2);
    if (def.id == 'fog') {
      // Veil shimmers rather than sitting flat (spec §7).
      add(
        OpacityEffect.to(
          0.6,
          EffectController(
            duration: 1.2,
            alternate: true,
            infinite: true,
          ),
        ),
      );
    }
  }

  /// Applies beam damage. Returns true when this hit killed it.
  bool takeBeamDamage(double amount, {required bool slow, required double now}) {
    if (_dying) return false;
    hp -= amount;
    if (slow) slowUntil = now + kFrostSlowDuration;
    return hp <= 0;
  }

  double speedAt(double now) =>
      def.speed * (now < slowUntil ? kFrostSlowFactor : 1.0);

  /// Starts the dissolve and schedules removal. Idempotent.
  void die({required void Function(Vector2 at) onDissolve}) {
    if (_dying) return;
    _dying = true;
    onDissolve(position.clone());
    add(
      OpacityEffect.fadeOut(
        EffectController(duration: 0.4),
        onComplete: removeFromParent,
      ),
    );
  }

  /// Leaps 48px left over a wall (spec §7 / §16).
  void leapWall({required void Function(Vector2 at) onDust}) {
    if (hasJumped) return;
    hasJumped = true;
    onDust(position.clone());
    add(
      MoveByEffect(
        Vector2(-48, 0),
        EffectController(duration: 0.3, curve: Curves.easeOut),
        onComplete: () => onDust(position.clone()),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _bobPhase += dt;
  }

  /// Walk bob: sin(time*2.5)*2 px, applied at render so it never desyncs the
  /// simulation position the beam tracer reads (spec §18.2).
  double get _bobY => _dying ? 0 : math.sin(_bobPhase * 2.5) * 2;

  static final _bodyPaint = Paint()..color = C.shadowBody;
  static final _borderPaint = Paint()
    ..color = C.shadowBorder
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final _softEdge = Paint()
    ..color = C.shadowBody
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final _eyePaint = Paint()..color = C.shadowEye;
  static final _eyeGlow = Paint()
    ..color = C.shadowEye
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final _hpBg = Paint()..color = C.hpBg;
  static final _hpFill = Paint();

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(0, _bobY);

    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = size.x / 2 - 2;

    // Soft-edged ink blot, per §4.4 — never a hard-edged flat circle.
    canvas.drawCircle(Offset(cx, cy), r + 2, _softEdge);
    canvas.drawCircle(Offset(cx, cy), r, _bodyPaint);
    canvas.drawCircle(Offset(cx, cy), r, _borderPaint);

    switch (def.id) {
      case 'bucket':
        // Helmet plate across the top of the head.
        final rect = Rect.fromLTWH(cx - r * 0.8, cy - r * 0.95, r * 1.6, r * 0.6);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(3)),
          Paint()..color = C.mirrorMetal,
        );
      case 'jumper':
        // Spring legs.
        final legPaint = Paint()
          ..color = const Color(0xFFFFA726)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;
        for (final dx in [-6.0, 6.0]) {
          final p = Path()..moveTo(cx + dx, cy + r * 0.7);
          for (var i = 0; i < 3; i++) {
            p.lineTo(cx + dx + (i.isEven ? 3 : -3), cy + r * 0.7 + 3 + i * 3);
          }
          canvas.drawPath(p, legPaint);
        }
      case 'fog':
        // Veil puff sitting over the body.
        canvas.drawCircle(
          Offset(cx, cy),
          r * 1.15,
          Paint()
            ..color = const Color(0x8090A4AE)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      default:
        break;
    }

    // Eyes — the one part that glows, so the threat reads instantly.
    final eyeR = def.id == 'giant' ? 4.0 : 3.0;
    for (final dx in [-eyeR * 1.6, eyeR * 1.6]) {
      canvas.drawCircle(Offset(cx + dx, cy - 2), eyeR + 2, _eyeGlow);
      canvas.drawCircle(Offset(cx + dx, cy - 2), eyeR, _eyePaint);
    }

    // HP bar, 24x4, 18px above the head.
    if (hpFraction < 1) {
      const w = 24.0;
      const h = 4.0;
      final left = cx - w / 2;
      const top = -18.0; // above the head, in local coords
      final bg = Rect.fromLTWH(left, top, w, h);
      canvas.drawRRect(
        RRect.fromRectAndRadius(bg, const Radius.circular(R.hp)),
        _hpBg,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, w * hpFraction, h),
          const Radius.circular(R.hp),
        ),
        _hpFill..color = C.hpFill(hpFraction),
      );
    }

    canvas.restore();
  }
}
