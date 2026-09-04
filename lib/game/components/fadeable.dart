/// Opacity for hand-painted components.
///
/// Flame's `OpacityEffect` needs an [OpacityProvider], and it only gets one for
/// free from `HasPaint` — a component that draws itself with several ad-hoc
/// `Paint`s (beams, shadows, the home diorama) has no single paint to dim, so
/// mounting a fade on one throws
/// `Unsupported operation: Can only apply this effect to OpacityProvider`.
/// This fades the whole subtree in one layer instead.
library;

import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart' show OpacityProvider;

// ponytail: saveLayer with null bounds, because renderTree runs before the
// component's own transform so local bounds would be in the wrong space. Only
// pays when opacity < 1. If a screen ever fades hundreds of these at once,
// switch that component to HasPaint and dim its paint directly.
mixin FadeableRender on PositionComponent implements OpacityProvider {
  double _opacity = 1.0;

  @override
  double get opacity => _opacity;

  @override
  set opacity(double value) => _opacity = value;

  @override
  void renderTree(Canvas canvas) {
    if (_opacity >= 1.0) {
      super.renderTree(canvas);
      return;
    }
    canvas.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, _opacity));
    super.renderTree(canvas);
    canvas.restore();
  }
}
