/// RightPanel tray slot — spec §11 (`64x64`, 3x2 grid) and §17 (placement
/// validation feeds `affordable`/`onCooldown` back here).
library;

import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';

import '../../../core/tokens.dart';
import '../../../data/models.dart';
import 'hud_paint.dart';

/// One pickable tool in the tray. Draws the tool's identity as a simple
/// coloured shape only — never imports the tool components themselves.
class TraySlotComponent extends PositionComponent with TapCallbacks, HasPaint<String> {
  TraySlotComponent({
    required this.def,
    bool selected = false,
    this.cooldownRemaining = 0,
    this.cooldownTotal = 0,
    this.affordable = true,
    required this.onTap,
    super.position,
  }) : _selected = selected,
       super(size: Vector2.all(64));

  final ToolDef def;
  double cooldownRemaining;
  double cooldownTotal;
  bool affordable;
  void Function() onTap;

  static const _borderId = 'border';

  bool _selected;
  bool get selected => _selected;
  set selected(bool value) {
    if (_selected == value) return;
    _selected = value;
    getPaint(_borderId).colorFilter = null;
    if (value) {
      add(ColorEffect(C.primary, EffectController(duration: D.secs(D.place)), paintId: _borderId));
    }
  }

  late final HudLabel _cooldownLabel;

  @override
  Future<void> onLoad() async {
    setPaint(
      _borderId,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = C.gridBorder,
    );
    add(
      HudLabel(
        '${def.cost}',
        style: T.label,
        anchor: Anchor.topRight,
        position: Vector2(size.x - S.x1, S.x1),
      ),
    );
    add(_cooldownLabel = HudLabel('', style: T.h3, anchor: Anchor.center, position: size / 2));
  }

  bool get _onCooldown => cooldownRemaining > 0 && cooldownTotal > 0;

  @override
  void update(double dt) {
    super.update(dt);
    final text = _onCooldown ? cooldownRemaining.ceil().toString() : '';
    if (_cooldownLabel.text != text) _cooldownLabel.text = text;
  }

  /// A flat colour standing in for the tool's identity, sourced only from
  /// `C.*` — nothing here imports `lib/game/components/tools/*`.
  Color get _glyphColor => switch (def.id) {
    'bulb' || 'twin' => C.primary,
    'beam' => C.beamCore,
    'frost' => C.secondary,
    'mirror' => C.mirrorMetal,
    'wall' => C.wallBlock,
    'prism' => C.prismSpectrum[2],
    'bomb' => C.error,
    _ => C.textPrimary,
  };

  static final _fill = Paint();
  static final _scrim = Paint()..color = C.scrim;
  static final _glyph = Paint();
  static final _arc = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round
    ..color = C.primary;

  @override
  void render(Canvas canvas) {
    final rrect = RRect.fromRectAndRadius(Offset.zero & size.toSize(), const Radius.circular(R.slot));
    final disabled = !affordable || _onCooldown;
    final alpha = disabled ? 0.4 : 1.0;

    canvas.drawRRect(rrect, _fill..color = C.surface2.withValues(alpha: alpha));
    canvas.drawRRect(rrect, getPaint(_borderId));
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2 - S.x1),
      12,
      _glyph..color = _glyphColor.withValues(alpha: alpha),
    );

    if (_onCooldown) {
      canvas.drawRRect(rrect, _scrim);
      final arcRect = Rect.fromCircle(center: Offset(size.x / 2, size.y / 2), radius: size.x / 2 - S.x2);
      final sweep = 2 * math.pi * (cooldownRemaining / cooldownTotal).clamp(0.0, 1.0);
      canvas.drawArc(arcRect, -math.pi / 2, sweep, false, _arc);
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (!affordable || _onCooldown) return;
    onTap();
  }
}
