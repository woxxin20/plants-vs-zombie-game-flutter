/// Base class for the eight defenders (spec §6).
///
/// Every concrete tool draws itself with vector paths in `render()` — there are
/// no sprites and no `Icon(Icons.*)` anywhere (RULE-FORBID / spec §10.5).
library;

import 'dart:ui';

import 'package:flutter/animation.dart' show Curves;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';

import '../../../core/tokens.dart';
import '../../../data/models.dart';
import '../backdrop_layers.dart' show P;

/// Drawn glyph size inside a tile, per spec §6 ("Visual 40x40").
const double kToolGlyph = 40.0;

abstract class ToolComponent extends PositionComponent {
  ToolComponent({
    required this.def,
    required this.row,
    required this.col,
    required Vector2 center,
  }) : hp = def.hp.toDouble(),
       maxHp = def.hp.toDouble(),
       super(
         position: center,
         size: Vector2.all(kToolGlyph),
         anchor: Anchor.center,
         priority: P.entity,
       );

  final ToolDef def;
  final int row;
  final int col;

  double hp;
  final double maxHp;

  /// Battle time of the last glow tick, for generators.
  double lastGen = 0;

  /// Battle time of the last beam tick, for emitters.
  double lastFire = 0;

  String get id => def.id;

  bool get isAlive => hp > 0 || !def.isPersistent;

  double get hpFraction => maxHp <= 0 ? 1 : (hp / maxHp).clamp(0.0, 1.0);

  @override
  Future<void> onLoad() async {
    // Spec §18.2: placement pop, 0 -> 1, elasticOut, 220ms.
    scale = Vector2.zero();
    add(
      ScaleEffect.to(
        Vector2.all(1),
        EffectController(duration: D.secs(D.place), curve: Curves.elasticOut),
      ),
    );
  }

  /// Damage from a shadow eating this tool.
  void takeDamage(double amount) {
    hp = (hp - amount).clamp(0, maxHp);
  }

  /// Death: shrink out, then leave the tree. Spec §24 edge case 19 — the
  /// component must actually be removed, never left orphaned and ticking.
  void destroyAndRemove() {
    add(
      ScaleEffect.to(
        Vector2.zero(),
        EffectController(duration: 0.12),
        onComplete: removeFromParent,
      ),
    );
  }

  /// Vector art for this tool, drawn centred in a `kToolGlyph` box.
  void renderGlyph(Canvas canvas);

  @override
  void render(Canvas canvas) {
    renderGlyph(canvas);
    if (def.isPersistent && hpFraction < 1) _renderHpBar(canvas);
  }

  static final _hpBg = Paint()..color = C.hpBg;
  static final _hpFill = Paint();

  void _renderHpBar(Canvas canvas) {
    // 32x4, radius 2, sitting just under the glyph (spec §6 HP Bar).
    const w = 32.0;
    const h = 4.0;
    final left = (size.x - w) / 2;
    final top = size.y - h;
    final bg = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, w, h),
      const Radius.circular(R.hp),
    );
    canvas.drawRRect(bg, _hpBg);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, w * hpFraction, h),
        const Radius.circular(R.hp),
      ),
      _hpFill..color = C.hpFill(hpFraction),
    );
  }

  /// Shared helper: a blurred copy of a shape behind the sharp one, which is
  /// how every light-emitting element gets its bloom (spec §4.3).
  static Paint bloom(Color color, double blur) => Paint()
    ..color = color
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
}
