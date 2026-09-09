/// Shared scrim + card shell for Pause / Win / Lose overlays (DS-075).
///
/// Lives on `camera.viewport` so it composites over a paused world without
/// tearing the sim tree down.
library;

import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/animation.dart' show Curves;

import '../../../core/tokens.dart';
import '../fadeable.dart';
import 'button_component.dart';
import 'hud_paint.dart';

/// Full-screen tap trap + centered dialog card.
class OverlayDialog extends PositionComponent
    with TapCallbacks, FadeableRender {
  OverlayDialog({
    Vector2? viewportSize,
    required this.cardSize,
    required this.title,
    required this.titleColor,
    required List<Component> body,
  }) : _body = body,
       super(
         size: viewportSize ?? kBaselineView,
         position: Vector2.zero(),
         priority: 1000,
       );

  static final Vector2 kBaselineView = Vector2(812, 375);

  final Vector2 cardSize;
  final String title;
  final Color titleColor;
  final List<Component> _body;

  late final _Scrim _scrim;
  late final _Card _card;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
    if (isLoaded) {
      _scrim.size = size.clone();
      _card.position = (size - cardSize) / 2;
    }
  }

  @override
  Future<void> onLoad() async {
    add(_scrim = _Scrim(size: size.clone()));

    final cardPos = (size - cardSize) / 2;
    _card = _Card(size: cardSize.clone(), position: cardPos);
    await add(_card);

    _card.add(
      HudLabel(
        title,
        style: T.h1,
        color: titleColor,
        anchor: Anchor.topCenter,
        position: Vector2(cardSize.x / 2, S.x5),
      ),
    );
    for (final child in _body) {
      _card.add(child);
    }

    opacity = 0;
    scale = Vector2.all(0.96);
    add(OpacityEffect.to(1, EffectController(duration: D.secs(D.place))));
    add(
      ScaleEffect.to(
        Vector2.all(1),
        EffectController(duration: D.secs(D.place), curve: Curves.easeOut),
      ),
    );
  }

  @override
  bool containsLocalPoint(Vector2 point) => true;

  @override
  void onTapUp(TapUpEvent event) {}
}

class _Scrim extends PositionComponent {
  _Scrim({required super.size});

  static final _paint = Paint()..color = C.scrim;

  @override
  void render(Canvas canvas) {
    canvas.drawRect(Offset.zero & size.toSize(), _paint);
  }
}

class _Card extends PositionComponent {
  _Card({required super.size, required super.position});

  static final _fill = Paint()..color = C.surface2;

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size.toSize(),
        const Radius.circular(R.dialog),
      ),
      _fill,
    );
  }
}

/// Convenience factory for a standard overlay button column.
List<Component> overlayButtons({
  required double cardWidth,
  required double top,
  required List<
    ({String label, GameButtonStyle style, void Function() onPressed})
  >
  buttons,
}) {
  const btnH = 48.0;
  const btnW = 200.0;
  const gap = 12.0;
  final out = <Component>[];
  var y = top;
  for (final b in buttons) {
    out.add(
      GameButton(
        label: b.label,
        size: Vector2(btnW, btnH),
        style: b.style,
        onPressed: b.onPressed,
        anchor: Anchor.topCenter,
        position: Vector2(cardWidth / 2, y),
      ),
    );
    y += btnH + gap;
  }
  return out;
}
