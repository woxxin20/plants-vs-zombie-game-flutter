/// RightPanel HUD — spec §11: `220` wide, full height under the TopBar.
/// Lives on `camera.viewport`, positioned in screen space.
library;

import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';

import '../../../core/layout.dart';
import '../../../core/tokens.dart';
import '../../../data/models.dart';
import 'hud_paint.dart';
import 'tray_slot_component.dart';

class RightPanelComponent extends PositionComponent {
  RightPanelComponent({
    required List<ToolDef> tools,
    required void Function(ToolDef) onSlotTap,
    this.waveProgress = 0,
    bool boostEnabled = true,
    required this.onBoost,
  }) : slots = [
         for (final t in tools) TraySlotComponent(def: t, onTap: () => onSlotTap(t)),
       ],
       _boostEnabled = boostEnabled,
       super(
         size: Vector2(S.rightPanelW, kBaselineSize.y - S.topBarH),
         position: Vector2(kBaselineSize.x - S.rightPanelW, S.topBarH),
       );

  /// Tray slots, up to `kTrayLimit` — exposed so the battle world can drive
  /// `selected`/`cooldownRemaining`/`affordable` per slot.
  final List<TraySlotComponent> slots;

  /// 0..1 fill of the wave-progress bar.
  double waveProgress;
  void Function() onBoost;

  bool _boostEnabled;
  bool get boostEnabled => _boostEnabled;
  set boostEnabled(bool value) {
    _boostEnabled = value;
    _boost.enabled = value;
  }

  static const _slotEdge = 64.0;
  static const _barW = 200.0;
  static const _barH = 6.0;

  late final _ProgressFill _fill;
  late final _BoostButton _boost;
  double _lastProgress = -1;

  @override
  Future<void> onLoad() async {
    add(HudLabel('TRAY - PICK 1', style: T.label, position: Vector2(S.cardPad, S.cardPad)));

    final gridW = 3 * _slotEdge + 2 * S.trayGap;
    final gridLeft = (size.x - gridW) / 2;
    final gridTop = S.cardPad + S.x4;
    for (var i = 0; i < slots.length; i++) {
      final col = i % 3;
      final row = i ~/ 3;
      slots[i].position = Vector2(
        gridLeft + col * (_slotEdge + S.trayGap),
        gridTop + row * (_slotEdge + S.trayGap),
      );
      add(slots[i]);
    }
    final gridBottom = gridTop + 2 * _slotEdge + S.trayGap;

    final barLeft = (size.x - _barW) / 2;
    final statsTop = gridBottom + S.x6;
    add(_TrackBg(position: Vector2(barLeft, statsTop), size: Vector2(_barW, _barH)));
    add(
      _fill = _ProgressFill(position: Vector2(barLeft, statsTop))
        ..width = _barW * waveProgress.clamp(0.0, 1.0),
    );
    _lastProgress = waveProgress;

    final legendTop = statsTop + _barH + S.x4;
    add(_HpLegendBar(position: Vector2(barLeft, legendTop), color: C.success, width: S.x12));
    add(
      _HpLegendBar(
        position: Vector2(barLeft + S.x12 + S.x2, legendTop),
        color: C.error,
        width: S.x12 / 2,
      ),
    );

    add(
      _boost = _BoostButton(
        onBoost: onBoost,
        position: Vector2((size.x - 200) / 2, size.y - S.cardPad - S.minTouch),
      )..enabled = _boostEnabled,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    final target = waveProgress.clamp(0.0, 1.0);
    if (target != _lastProgress) {
      _lastProgress = target;
      _fill.add(
        SizeEffect.to(Vector2(_barW * target, _barH), EffectController(duration: D.secs(D.hpLerp))),
      );
    }
  }

  static final _bg = Paint()..color = C.surface;

  @override
  void render(Canvas canvas) => canvas.drawRect(Offset.zero & size.toSize(), _bg);
}

class _TrackBg extends PositionComponent {
  _TrackBg({required super.position, required super.size});

  @override
  void render(Canvas canvas) => canvas.drawRRect(
    RRect.fromRectAndRadius(Offset.zero & size.toSize(), const Radius.circular(R.hp)),
    Paint()..color = C.gridEmpty,
  );
}

class _ProgressFill extends PositionComponent {
  _ProgressFill({required super.position}) : super(size: Vector2(0, RightPanelComponent._barH));

  @override
  void render(Canvas canvas) => canvas.drawRRect(
    RRect.fromRectAndRadius(Offset.zero & size.toSize(), const Radius.circular(R.hp)),
    Paint()..color = C.primary,
  );
}

/// A static two-bar legend for the HP colour scale (`C.hpFill`) — full
/// success-green vs. half error-red, not tied to any live tool.
class _HpLegendBar extends PositionComponent {
  _HpLegendBar({required super.position, required this.color, required double width})
    : super(size: Vector2(width, 4));

  final Color color;

  @override
  void render(Canvas canvas) => canvas.drawRRect(
    RRect.fromRectAndRadius(Offset.zero & size.toSize(), const Radius.circular(R.hp)),
    Paint()..color = color,
  );
}

/// Bottom rewarded-Boost button — spec §11/§20: `+50 GLOW`, 1-per-battle,
/// dimmed via a real `OpacityEffect` when spent/unavailable.
class _BoostButton extends PositionComponent with TapCallbacks, HasPaint {
  _BoostButton({required this.onBoost, required super.position}) : super(size: Vector2(200, 48));

  void Function() onBoost;

  bool _enabled = true;
  bool get enabled => _enabled;
  set enabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    add(OpacityEffect.to(value ? 1.0 : 0.4, EffectController(duration: D.secs(D.place))));
  }

  late final HudLabel _title;
  late final HudLabel _sub;

  @override
  Future<void> onLoad() async {
    add(
      _title = HudLabel(
        '+50 GLOW',
        style: T.h3,
        position: Vector2(S.x8, S.x4),
        anchor: Anchor.centerLeft,
      ),
    );
    add(
      _sub = HudLabel(
        'AD 1/1',
        style: T.label,
        position: Vector2(S.x8, size.y - S.x2),
        anchor: Anchor.centerLeft,
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _title.opacity = opacity;
    _sub.opacity = opacity;
  }

  static final _fillPaint = Paint();
  static final _borderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  @override
  void render(Canvas canvas) {
    final rrect = RRect.fromRectAndRadius(Offset.zero & size.toSize(), const Radius.circular(R.slot));
    canvas.drawRRect(rrect, _fillPaint..color = C.surface3.withValues(alpha: opacity));
    canvas.drawRRect(rrect, _borderPaint..color = C.gridBorder.withValues(alpha: opacity));
    paintSunburst(canvas, Offset(S.x8, size.y / 2), 16, C.primary.withValues(alpha: opacity));
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (!_enabled) return;
    onBoost();
  }
}
