/// Depth layers L0-L3 — spec §4.2 and §14.
///
/// The battle camera is fixed, so depth is expressed through *motion* parallax
/// (each layer drifts/breathes at its own speed) rather than camera-scroll
/// parallax. That is the technique §14 calls for; do not swap it for
/// `ParallaxComponent`.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../core/layout.dart';
import '../../core/tokens.dart';

/// Render priorities, so layer order is declared once instead of guessed at
/// each `add()` site.
abstract final class P {
  static const backdrop = -30;
  static const dust = -20;
  static const ambientGlow = -10;
  static const grid = 0;
  static const entity = 10;
  static const beam = 20;
  static const foregroundParticles = 90;
  static const vignette = 95;
}

/// L0 + L1: the near-black gradient, the off-frame lamp pool and a low-contrast
/// blueprint grain. Static — never scrolls.
class BackdropLayer extends PositionComponent {
  BackdropLayer({required this.viewSize})
    : super(priority: P.backdrop, size: viewSize);

  final Vector2 viewSize;

  late final Paint _gradient = Paint()
    ..shader = Gradient.linear(Offset.zero, Offset(0, viewSize.y), const [
      C.backdropTop,
      C.backdropBottom,
    ]);

  // Implied desk lamp off-frame, centre-left (spec §4.1).
  late final Paint _lampPool = Paint()
    ..shader = Gradient.radial(
      Offset(viewSize.x * 0.28, viewSize.y * 0.42),
      viewSize.x * 0.55,
      const [Color(0x14FFD23F), Color(0x00FFD23F)],
    );

  late final List<Offset> _dots = _buildDots();

  List<Offset> _buildDots() {
    // L1 blueprint dot grid: dot 4px, gap 24, rgba(255,210,63,0.04).
    final out = <Offset>[];
    for (var y = 12.0; y < viewSize.y; y += 24) {
      for (var x = 12.0; x < viewSize.x; x += 24) {
        out.add(Offset(x, y));
      }
    }
    return out;
  }

  static final _dotPaint = Paint()..color = const Color(0x0AFFD23F);

  @override
  void render(Canvas canvas) {
    final rect = Offset.zero & viewSize.toSize();
    canvas.drawRect(rect, _gradient);
    canvas.drawRect(rect, _lampPool);
    canvas.drawPoints(PointMode.points, _dots, _dotPaint..strokeWidth = 2);
  }
}

/// L2: 12-18 dust motes on a slow random walk. Always running, including on
/// menu screens — the room is alive even when the game is not.
class DustMoteLayer extends Component {
  DustMoteLayer({required this.viewSize, this.count = 16, math.Random? random})
    : _rng = random ?? math.Random(7),
      super(priority: P.dust);

  final Vector2 viewSize;
  final int count;
  final math.Random _rng;

  final List<_Mote> _motes = [];

  @override
  Future<void> onLoad() async {
    for (var i = 0; i < count; i++) {
      _motes.add(
        _Mote(
          pos: Offset(
            _rng.nextDouble() * viewSize.x,
            _rng.nextDouble() * viewSize.y,
          ),
          radius: 1 + _rng.nextDouble() * 2,
          alpha: 0.08 + _rng.nextDouble() * 0.07,
          drift: Offset(
            (_rng.nextDouble() - 0.5) * 6,
            (_rng.nextDouble() - 0.5) * 4,
          ),
          phase: _rng.nextDouble() * math.pi * 2,
        ),
      );
    }
  }

  double _t = 0;

  @override
  void update(double dt) {
    _t += dt;
    for (final m in _motes) {
      m.pos += m.drift * dt;
      // Gentle sine wander on top of the linear drift.
      m.pos = Offset(m.pos.dx + math.sin(_t * 0.4 + m.phase) * 0.15, m.pos.dy);
      // Wrap rather than respawn, so the count never changes.
      if (m.pos.dx < -4) m.pos = Offset(viewSize.x + 4, m.pos.dy);
      if (m.pos.dx > viewSize.x + 4) m.pos = Offset(-4, m.pos.dy);
      if (m.pos.dy < -4) m.pos = Offset(m.pos.dx, viewSize.y + 4);
      if (m.pos.dy > viewSize.y + 4) m.pos = Offset(m.pos.dx, -4);
    }
  }

  final _paint = Paint();

  @override
  void render(Canvas canvas) {
    for (final m in _motes) {
      canvas.drawCircle(
        m.pos,
        m.radius,
        _paint..color = C.primary.withValues(alpha: m.alpha),
      );
    }
  }
}

class _Mote {
  _Mote({
    required this.pos,
    required this.radius,
    required this.alpha,
    required this.drift,
    required this.phase,
  });
  Offset pos;
  final double radius;
  final double alpha;
  final Offset drift;
  final double phase;
}

/// L3: soft breathing glow pools that sit under light-emitting tools, so the
/// board reads as a lit surface rather than a flat fill (spec §4.2, §4.3).
class AmbientGlowLayer extends Component {
  AmbientGlowLayer({required this.layout}) : super(priority: P.ambientGlow);

  final BattleLayout layout;

  /// World-space centres of the current light sources. The battle world
  /// rewrites this whenever a generator or lamp is placed or destroyed.
  final List<Vector2> sources = [];

  double _t = 0;

  @override
  void update(double dt) => _t += dt;

  @override
  void render(Canvas canvas) {
    // 1.0 -> 1.08 -> 1.0 over 3s (spec §18.2 breathing).
    final breathe =
        1.0 +
        0.08 * (0.5 + 0.5 * math.sin(_t * 2 * math.pi / D.secs(D.breathe)));
    for (final s in sources) {
      final radius = layout.tile * 1.6 * breathe;
      canvas.drawCircle(
        Offset(s.x, s.y),
        radius,
        Paint()
          ..shader = Gradient.radial(Offset(s.x, s.y), radius, const [
            Color(0x1FFFD23F),
            Color(0x00FFD23F),
          ]),
      );
    }
  }
}

/// L7: screen-space vignette. Lives on the camera viewport, not the world, so
/// it never moves with a shake.
class VignetteLayer extends PositionComponent {
  VignetteLayer({required this.viewSize})
    : super(priority: P.vignette, size: viewSize);

  final Vector2 viewSize;

  late final Paint _paint = Paint()
    ..shader = Gradient.radial(
      Offset(viewSize.x / 2, viewSize.y / 2),
      viewSize.length * 0.5,
      const [Color(0x00000000), Color(0x59000000)],
      const [0.55, 1.0],
    );

  @override
  void render(Canvas canvas) =>
      canvas.drawRect(Offset.zero & viewSize.toSize(), _paint);
}
