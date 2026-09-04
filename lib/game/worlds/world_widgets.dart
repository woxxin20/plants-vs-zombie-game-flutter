/// Small shared building blocks for the five non-battle screens. Kept out of
/// `components/hud/` on purpose (that folder is owned by a sibling agent) —
/// these are menu-only widgets, never used inside a battle.
library;

import 'dart:math' as math;
import 'dart:ui' hide TextStyle;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show TextStyle;
import 'package:flame/effects.dart';
import 'package:flame/events.dart';

import '../../core/layout.dart';
import '../../core/tokens.dart';
import '../components/backdrop_layers.dart';

/// Expands a component's hit-test rect so every interactive element gets at
/// least an `S.minTouch` square hitbox, even when its drawn size is smaller
/// (e.g. a 32-tall chip or a 22-tall switch track) — the accessibility hard
/// rule every world in this folder must satisfy.
bool paddedContains(Vector2 size, Vector2 point) {
  final padX = math.max(0.0, (S.minTouch - size.x) / 2);
  final padY = math.max(0.0, (S.minTouch - size.y) / 2);
  final rect = Rect.fromLTWH(
    -padX,
    -padY,
    size.x + padX * 2,
    size.y + padY * 2,
  );
  return rect.contains(point.toOffset());
}

/// L0-L3 (or L0-L2) menu backdrop, shared by every non-battle screen so each
/// world file doesn't repeat the same three `add()` calls.
Future<void> addMenuBackdrop(
  Component to, {
  required Vector2 viewSize,
  required BattleLayout layout,
  bool ambient = true,
}) async {
  await to.add(BackdropLayer(viewSize: viewSize));
  await to.add(DustMoteLayer(viewSize: viewSize));
  if (ambient) await to.add(AmbientGlowLayer(layout: layout));
}

/// A tappable rounded-rect label. Every colour/radius/text-style comes from
/// `tokens.dart`, passed in by the caller so this stays a dumb shell.
///
/// Hitbox is padded up to `S.minTouch` on both axes even when the drawn
/// button is smaller (e.g. the 32-tall Daily chip), per the accessibility
/// hard rule.
class WorldButton extends PositionComponent with TapCallbacks {
  WorldButton({
    required Vector2 size,
    required this.label,
    required this.onPressed,
    this.background = C.primary,
    this.textColor = C.onPrimary,
    TextStyle? textStyle,
    double? radius,
    this.enabled = true,
    super.position,
    Anchor anchor = Anchor.topLeft,
    int priority = 0,
  }) : radius = radius ?? R.button,
       _textStyle = textStyle ?? T.h3,
       super(size: size, anchor: anchor, priority: priority);

  String label;
  VoidCallback onPressed;
  Color background;
  Color textColor;
  double radius;
  bool enabled;
  final TextStyle _textStyle;

  late final TextComponent _labelComponent;

  @override
  Future<void> onLoad() async {
    _labelComponent = TextComponent(
      text: label,
      textRenderer: TextPaint(style: _textStyle.copyWith(color: textColor)),
      anchor: Anchor.center,
      position: size / 2,
    );
    await add(_labelComponent);
  }

  void setLabel(String text) {
    label = text;
    _labelComponent.text = text;
  }

  static final _fill = Paint();

  @override
  void render(Canvas canvas) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size.toSize(),
      Radius.circular(radius),
    );
    canvas.drawRRect(rrect, _fill..color = background);
  }

  // Disabled buttons render dimmed (0.5, matching every "else 0.5 opacity"
  // case in the spec) and stop eating taps.
  @override
  void renderTree(Canvas canvas) {
    if (enabled) {
      super.renderTree(canvas);
      return;
    }
    canvas.saveLayer(null, Paint()..color = const Color(0x80000000));
    super.renderTree(canvas);
    canvas.restore();
  }

  @override
  bool containsLocalPoint(Vector2 point) =>
      enabled && paddedContains(size, point);

  @override
  void onTapDown(TapDownEvent event) {
    add(
      ScaleEffect.to(
        Vector2.all(0.96),
        EffectController(duration: D.secs(D.buttonPress)),
      ),
    );
  }

  @override
  void onTapUp(TapUpEvent event) {
    add(
      ScaleEffect.to(
        Vector2.all(1),
        EffectController(duration: D.secs(D.buttonPress)),
      ),
    );
    onPressed();
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    add(
      ScaleEffect.to(
        Vector2.all(1),
        EffectController(duration: D.secs(D.buttonPress)),
      ),
    );
  }
}

/// A static (non-interactive) rounded-rect label — coin counts, progress
/// badges, that sort of thing.
class WorldChip extends PositionComponent {
  WorldChip({
    required Vector2 size,
    required String label,
    this.background = C.surface2,
    Color textColor = C.textPrimary,
    TextStyle? textStyle,
    double? radius,
    super.position,
    Anchor anchor = Anchor.topLeft,
    int priority = 0,
  }) : radius = radius ?? R.chip,
       _label = label,
       _textStyle = (textStyle ?? T.bodySmall).copyWith(color: textColor),
       super(size: size, anchor: anchor, priority: priority);

  Color background;
  double radius;
  final String _label;
  final TextStyle _textStyle;
  TextComponent? _labelComponent;

  @override
  Future<void> onLoad() async {
    _labelComponent = TextComponent(
      text: _label,
      textRenderer: TextPaint(style: _textStyle),
      anchor: Anchor.center,
      position: size / 2,
    );
    await add(_labelComponent!);
  }

  set label(String text) => _labelComponent?.text = text;

  static final _fill = Paint();

  @override
  void render(Canvas canvas) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size.toSize(),
      Radius.circular(radius),
    );
    canvas.drawRRect(rrect, _fill..color = background);
  }
}
