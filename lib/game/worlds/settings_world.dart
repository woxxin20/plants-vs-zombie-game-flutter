/// Settings screen (spec §12) — Sound / Haptics toggles + destructive Reset.
library;

import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';

import '../../core/layout.dart';
import '../../core/save_store.dart';
import '../../core/tokens.dart';
import '../light_vs_shadow_game.dart';
import 'world_widgets.dart';

/// Seconds the Reset Progress row stays armed after the first tap.
const double kResetConfirmWindow = 3.0;

class SettingsWorld extends World with HasGameReference<LightVsShadowGame> {
  SettingsWorld({required this.onBack});

  final VoidCallback onBack;

  @override
  Future<void> onLoad() async {
    final viewSize = kBaselineSize.clone();
    await addMenuBackdrop(this, viewSize: viewSize, layout: game.layout);

    await add(
      WorldButton(
        size: Vector2(72, 36),
        label: 'BACK',
        onPressed: onBack,
        background: C.surface3,
        textColor: C.textPrimary,
        textStyle: T.bodySmall,
        position: Vector2(S.screenPad, S.screenPad),
      ),
    );
    await add(
      TextComponent(
        text: 'SETTINGS',
        textRenderer: TextPaint(style: T.h1),
        anchor: Anchor.centerLeft,
        position: Vector2(96, S.screenPad + 18),
      ),
    );

    const labelX = 96.0;
    final switchX = viewSize.x - 96 - 40;
    final save = SaveStore.I.state;

    var y = 110.0;
    await add(
      TextComponent(
        text: 'Sound',
        textRenderer: TextPaint(style: T.h2),
        anchor: Anchor.centerLeft,
        position: Vector2(labelX, y + 11),
      ),
    );
    await add(
      SwitchComponent(
        value: save.sound,
        onChanged: (v) {
          save.sound = v;
          SaveStore.I.flush();
        },
        position: Vector2(switchX, y),
      ),
    );

    y += 64;
    await add(
      TextComponent(
        text: 'Haptics',
        textRenderer: TextPaint(style: T.h2),
        anchor: Anchor.centerLeft,
        position: Vector2(labelX, y + 11),
      ),
    );
    await add(
      SwitchComponent(
        value: save.haptics,
        onChanged: (v) {
          save.haptics = v;
          SaveStore.I.flush();
        },
        position: Vector2(switchX, y),
      ),
    );

    y += 64;
    await add(_ResetRow(position: Vector2(labelX, y)));
  }
}

/// Hand-drawn toggle, per spec §12 — never a Material `Switch`. Track
/// 40x22 `R.chip`, thumb slides via a 150ms `MoveEffect`.
class SwitchComponent extends PositionComponent with TapCallbacks {
  SwitchComponent({
    required bool value,
    required this.onChanged,
    Vector2? position,
  }) : _value = value,
       super(size: const Vector2(40, 22), position: position);

  bool _value;
  final void Function(bool value) onChanged;

  static const _thumbD = 18.0;
  static const _pad = 2.0;

  late final _ThumbCircle _thumb;

  double get _onX => size.x - _thumbD - _pad;
  double get _offX => _pad;

  static final _track = Paint();
  static final _thumbPaint = Paint()..color = C.textPrimary;

  @override
  Future<void> onLoad() async {
    _thumb = _ThumbCircle()
      ..size = Vector2.all(_thumbD)
      ..position = Vector2(_value ? _onX : _offX, _pad);
    await add(_thumb);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size.toSize(),
        const Radius.circular(R.chip),
      ),
      _track..color = _value ? C.primary : C.surface3,
    );
  }

  @override
  bool containsLocalPoint(Vector2 point) => paddedContains(size, point);

  @override
  void onTapUp(TapUpEvent event) {
    _value = !_value;
    _thumb.add(
      MoveEffect.to(
        Vector2(_value ? _onX : _offX, _pad),
        EffectController(duration: 0.15),
      ),
    );
    onChanged(_value);
  }
}

/// Draws its own thumb circle since it never leaves the parent's paint set.
class _ThumbCircle extends PositionComponent {
  @override
  void render(Canvas canvas) => canvas.drawCircle(
    Offset(size.x / 2, size.y / 2),
    size.x / 2,
    SwitchComponent._thumbPaint,
  );
}

/// Destructive two-step confirm row (spec instructions): first tap arms it
/// for `kResetConfirmWindow` seconds, showing the confirm label in
/// `C.error`; a second tap inside that window performs the reset. Letting
/// the window lapse silently disarms it.
class _ResetRow extends PositionComponent with TapCallbacks {
  _ResetRow({required Vector2 position})
    : super(position: position, size: const Vector2(300, 40));

  bool _armed = false;
  double _remaining = 0;
  late final TextComponent _label;

  @override
  Future<void> onLoad() async {
    _label = TextComponent(
      text: 'Reset Progress',
      textRenderer: TextPaint(style: T.h2.copyWith(color: C.error)),
      anchor: Anchor.centerLeft,
      position: Vector2(0, 20),
    );
    await add(_label);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_armed) return;
    _remaining -= dt;
    if (_remaining <= 0) _disarm();
  }

  void _disarm() {
    _armed = false;
    _label.text = 'Reset Progress';
  }

  void _reset() {
    // Progress only: removeAds is a paid entitlement and must survive a
    // reset, and sound/haptics are device prefs, not progress.
    final save = SaveStore.I.state;
    save.coins = 0;
    for (var i = 0; i < save.stars.length; i++) {
      save.stars[i] = 0;
    }
    save.unlocked
      ..clear()
      ..addAll(const {'bulb', 'beam', 'wall'});
    save.maxUnlocked = 1;
    save.totalPlays = 0;
    save.traySlotBonus = 0;
    save.lastDailyClaimed = 0;
    SaveStore.I.flush();
    _disarm();
  }

  @override
  bool containsLocalPoint(Vector2 point) => paddedContains(size, point);

  @override
  void onTapUp(TapUpEvent event) {
    if (_armed) {
      _reset();
      return;
    }
    _armed = true;
    _remaining = kResetConfirmWindow;
    _label.text = 'Tap again to confirm';
  }
}
