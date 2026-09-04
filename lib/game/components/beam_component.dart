/// Renders one resolved beam segment (spec §15 Visual).
///
/// Segments are reused in place rather than recreated each frame: the battle
/// world keeps a small list and only grows it when the trace produces more
/// segments than it currently holds (target: <= 9 concurrent, spec §15).
library;

import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';

import '../../core/layout.dart';
import '../../core/tokens.dart';
import '../../data/optics.dart';
import 'backdrop_layers.dart' show P;
import 'fadeable.dart';

class BeamComponent extends PositionComponent with FadeableRender {
  BeamComponent() : super(priority: P.beam);

  Offset _from = Offset.zero;
  Offset _to = Offset.zero;
  Color _color = C.beamCore;
  bool _visible = false;

  @override
  Future<void> onLoad() async {
    // Spec §18.2: 1.0 -> 0.7 -> 1.0 over 600ms, looping.
    add(
      OpacityEffect.to(
        0.7,
        EffectController(
          duration: D.secs(D.beamPulse) / 2,
          alternate: true,
          infinite: true,
        ),
      ),
    );
  }

  static Color colorFor(BeamKind kind) => switch (kind) {
    BeamKind.light => C.beamCore,
    BeamKind.frost => C.secondary,
    BeamKind.prismRight => C.primary,
    BeamKind.prismUp => const Color(0xFFAB47BC),
    BeamKind.prismDown => C.success,
  };

  /// Points this segment at a new path. Cheap — no allocation, no remount.
  void setSegment(BeamSegment s, BattleLayout layout) {
    final from =
        layout.origin +
        Vector2(
          s.fromCol * (layout.tile + S.tileGap) + layout.tile / 2,
          s.fromRow * (layout.tile + S.tileGap) + layout.tile / 2,
        );
    final to =
        layout.origin +
        Vector2(
          s.toCol * (layout.tile + S.tileGap) + layout.tile / 2,
          s.toRow * (layout.tile + S.tileGap) + layout.tile / 2,
        );
    _from = Offset(from.x, from.y);
    _to = Offset(to.x, to.y);
    _color = colorFor(s.kind);
    _visible = true;
  }

  void hide() => _visible = false;

  final _glow = Paint()
    ..strokeWidth = 12
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

  final _core = Paint()
    ..strokeWidth = 4
    ..strokeCap = StrokeCap.round;

  @override
  void render(Canvas canvas) {
    if (!_visible) return;
    // Glow first, then the sharp core on top — the layering that makes it read
    // as light rather than a coloured rectangle (spec §4.3).
    canvas.drawLine(_from, _to, _glow..color = C.beamGlow);
    canvas.drawLine(_from, _to, _core..color = _color);
  }
}
