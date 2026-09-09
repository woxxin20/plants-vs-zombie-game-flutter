/// TopBar HUD — spec §11: `812x48`, glow chip + wave flags + pause button.
/// Lives on `camera.viewport`, positioned in screen space.
library;

import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/animation.dart' show Curves;

import '../../../core/layout.dart';
import '../../../core/tokens.dart';
import '../../../data/models.dart';
import 'hud_paint.dart';

class TopBarComponent extends PositionComponent {
  TopBarComponent({
    Vector2? viewportSize,
    this.glow = 0,
    this.waveIndex = 0,
    this.waveCount = 1,
    Set<int>? flagWaves,
    required this.onPause,
  }) : flagWaves = flagWaves ?? <int>{},
       super(size: Vector2((viewportSize ?? kBaselineSize).x, S.topBarH));

  /// Current glow total — spec caps the display at `kGlowMax`.
  int glow;
  int waveIndex;
  int waveCount;

  /// 0-based indices of "huge" (flag) waves — spec §8.
  final Set<int> flagWaves;
  void Function() onPause;

  static const double _chipW = 110;
  static const double _iconSize = 16;

  late final Rect _chipRect;
  late final HudLabel _glowLabel;
  late final HudLabel _glowMaxLabel;
  late final HudLabel _waveLabel;
  late final _PauseButton _pauseButton;
  final List<_FlagDot> _flagDots = [];

  int _lastGlow = 0;
  int _lastWaveIndex = -1;
  int _lastWaveCount = -1;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size.x = size.x;
    if (isLoaded) {
      _pauseButton.position = Vector2(
        this.size.x - S.screenPad - S.minTouch,
        0,
      );
      _syncFlagRow();
    }
  }

  @override
  Future<void> onLoad() async {
    final chipY = (S.topBarH - S.x8) / 2;
    _chipRect = Rect.fromLTWH(S.screenPad, chipY, _chipW, S.x8);
    final chipCenterY = _chipRect.center.dy;

    add(
      _glowLabel = HudLabel(
        '$glow',
        style: T.number,
        color: C.primary,
        position: Vector2(
          _chipRect.left + S.x2 + _iconSize + S.x1,
          chipCenterY,
        ),
        anchor: Anchor.centerLeft,
      ),
    );
    add(
      _glowMaxLabel = HudLabel(
        '/$kGlowMax',
        style: T.label,
        position: Vector2(_glowLabel.x + _glowLabel.width + S.x1, chipCenterY),
        anchor: Anchor.centerLeft,
      ),
    );

    _waveLabel = HudLabel('WAVE ${waveIndex + 1}/$waveCount', style: T.label);
    add(_waveLabel);
    _pauseButton = _PauseButton(
      onPause: () => onPause(),
      position: Vector2(size.x - S.screenPad - S.minTouch, 0),
    );
    add(_pauseButton);

    _lastGlow = glow;
    _syncFlagRow();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (glow != _lastGlow) {
      _lastGlow = glow;
      _glowLabel.text = '$glow';
      _glowMaxLabel.position = Vector2(
        _glowLabel.x + _glowLabel.width + S.x1,
        _glowMaxLabel.y,
      );
    }
    if (waveIndex != _lastWaveIndex || waveCount != _lastWaveCount) {
      _lastWaveIndex = waveIndex;
      _lastWaveCount = waveCount;
      _waveLabel.text = 'WAVE ${waveIndex + 1}/$waveCount';
      _syncFlagRow();
    }
  }

  /// Rebuilds the centre flag-dot row — cheap and rare (once per wave).
  void _syncFlagRow() {
    for (final d in _flagDots) {
      d.removeFromParent();
    }
    _flagDots.clear();

    final dotsWidth = (2 * waveCount - 1) * S.x2;
    final centerY = size.y / 2;
    final total = dotsWidth + S.x2 + _waveLabel.width;
    final startX = (size.x - total) / 2;

    for (var i = 0; i < waveCount; i++) {
      final dot = _FlagDot(
        isFlag: flagWaves.contains(i),
        position: Vector2(startX + i * 2 * S.x2 + S.x2 / 2, centerY),
      )..anchor = Anchor.center;
      dot.setActive(i <= waveIndex);
      add(dot);
      _flagDots.add(dot);
    }
    _waveLabel
      ..position = Vector2(startX + dotsWidth + S.x2, centerY)
      ..anchor = Anchor.centerLeft;
  }

  static final _bg = Paint()..color = C.surface;
  static final _border = Paint()
    ..color = C.gridBorder
    ..strokeWidth = 1;
  static final _chipFill = Paint()..color = C.bg;
  static final _chipBorder = Paint()
    ..color = C.gridBorder
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  @override
  void render(Canvas canvas) {
    canvas.drawRect(Offset.zero & size.toSize(), _bg);
    canvas.drawLine(Offset(0, size.y), Offset(size.x, size.y), _border);

    final chip = RRect.fromRectAndRadius(
      _chipRect,
      const Radius.circular(R.chip),
    );
    canvas.drawRRect(chip, _chipFill);
    canvas.drawRRect(chip, _chipBorder);
    paintSunburst(
      canvas,
      Offset(_chipRect.left + S.x2 + _iconSize / 2, _chipRect.center.dy),
      _iconSize,
      C.primary,
    );
  }
}

/// One marker in the centre wave row — a dot, or a pennant for a flag wave.
class _FlagDot extends PositionComponent {
  _FlagDot({required this.isFlag, required Vector2 position})
    : super(position: position, size: Vector2.all(S.x2));

  final bool isFlag;
  bool active = false;

  void setActive(bool value) {
    active = value;
    if (!value) return;
    scale = Vector2.all(1);
    add(
      ScaleEffect.to(
        Vector2.all(1.2),
        EffectController(
          duration: D.secs(D.bob),
          curve: Curves.easeOut,
          alternate: true,
        ),
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    final color = active ? C.primary : C.textDisabled;
    final center = Offset(size.x / 2, size.y / 2);
    if (isFlag) {
      paintPennant(center, 14, color, canvas);
    } else {
      canvas.drawCircle(center, S.x1, Paint()..color = color);
    }
  }
}

/// Right-side pause toggle — 48x48, two hand-drawn bars.
class _PauseButton extends PositionComponent with TapCallbacks {
  _PauseButton({required this.onPause, required super.position})
    : super(size: Vector2.all(S.minTouch));

  final void Function() onPause;

  static final _bg = Paint()..color = C.surface2;

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size.toSize(),
        const Radius.circular(R.slot),
      ),
      _bg,
    );
    paintPauseBars(canvas, Offset(size.x / 2, size.y / 2), 20, C.textPrimary);
  }

  @override
  void onTapUp(TapUpEvent event) => onPause();
}
