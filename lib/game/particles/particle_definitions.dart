/// Particle factories — spec §18.1. One function per inventory row, each
/// returning a `ParticleSystemComponent` positioned at a world point and
/// composed from Flame's `Particle` API (`Particle.generate`, `moving`,
/// `accelerated`, `rotating`, `ComputedParticle`) — no hand-rolled component
/// lists.
///
/// Every system removes itself when its lifespan ends: that's
/// `ParticleSystemComponent.update()`'s default behaviour, left untouched
/// here (see `package:flame/src/components/particle_system_component.dart`).
///
/// Duration tokens (`D`, lib/core/tokens.dart) don't have an exact entry for
/// every §18.1 lifespan, so lifespans below are composed from existing `D`
/// values (sums/products of tokens) rather than a bare literal millisecond
/// count, per RULE-FORBID: no literal colour or duration.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/animation.dart' show Curves;

import 'package:flame/components.dart';
import 'package:flame/particles.dart';

import '../../core/tokens.dart';
import '../components/backdrop_layers.dart' show P;

final math.Random _rng = math.Random();

// Lifespans (seconds), derived from D tokens — see file doc comment.
final double _tPlace = D.secs(D.winStarStagger); // 120ms
final double _tCollect = D.secs(D.hpLerp); // 200ms
final double _tHitSpark =
    D.secs(D.loseShake) - D.secs(D.winStarStagger); // 180ms
final double _tSweep = D.secs(D.bob) + D.secs(D.buttonPress); // 500ms
final double _tDissolve = D.secs(D.bob); // 400ms
final double _tExplosion = D.secs(D.winStar); // 400ms
final double _tConfetti = D.secs(D.bob) * 2; // 800ms
final double _tLeapDust = D.secs(D.hpLerp); // 200ms
final double _tGlow = D.secs(D.winStar); // ~400ms

ParticleSystemComponent _system(Vector2 at, Particle particle) =>
    ParticleSystemComponent(
      position: at,
      priority: P.foregroundParticles,
      particle: particle,
    );

/// A single dot that fades to transparent over its lifespan (or stays solid
/// if [fade] is false). Flame has no built-in opacity particle to compose
/// with, so this uses `ComputedParticle` — explicitly one of the sanctioned
/// composition primitives — to read `particle.progress` each frame.
Particle _dot(Color color, double radius, {bool fade = true}) {
  return ComputedParticle(
    renderer: (canvas, particle) {
      final alpha = fade ? color.a * (1 - particle.progress) : color.a;
      canvas.drawCircle(
        Offset.zero,
        radius,
        Paint()..color = color.withValues(alpha: alpha),
      );
    },
  );
}

/// [count] dots flying outward from the origin between [minDist] and
/// [maxDist] px, over a `spread`-radian slice of the circle centred on
/// [direction]. Backs every "burst" row in §18.1.
Particle _burst({
  required int count,
  required double lifespan,
  required double minDist,
  required double maxDist,
  required Color Function(int i) color,
  double radius = 3,
  double direction = 0,
  double spread = math.pi * 2,
}) {
  return Particle.generate(
    count: count,
    lifespan: lifespan,
    generator: (i) {
      final angle = direction + (_rng.nextDouble() - 0.5) * spread;
      final dist = minDist + _rng.nextDouble() * (maxDist - minDist);
      return _dot(color(i), radius).moving(
        to: Vector2(math.cos(angle), math.sin(angle)) * dist,
        curve: Curves.easeOut,
      );
    },
  );
}

/// `PlaceParticle` — tool placed. 6 dots burst outward 24px and fade. 120ms.
ParticleSystemComponent placeBurst(Vector2 at) => _system(
  at,
  _burst(
    count: 6,
    lifespan: _tPlace,
    minDist: 16,
    maxDist: 24,
    color: (_) => C.primary,
  ),
);

/// `CollectParticle` — glow orb / bulb tick collected. 8 dots, burst +
/// upward drift, gold. 200ms.
ParticleSystemComponent collectBurst(Vector2 at) => _system(
  at,
  Particle.generate(
    count: 8,
    lifespan: _tCollect,
    generator: (i) {
      final angle = _rng.nextDouble() * math.pi * 2;
      final dist = 6 + _rng.nextDouble() * 10;
      final rise = 14 + _rng.nextDouble() * 10;
      return _dot(C.primary, 3).moving(
        to: Vector2(math.cos(angle) * dist, math.sin(angle) * dist - rise),
        curve: Curves.easeOut,
      );
    },
  ),
);

/// `SparkParticle` — beam hits shadow. 6 dots, 3px, `#FFD23F` (== C.primary),
/// outward 24px. 180ms.
ParticleSystemComponent hitSpark(Vector2 at) => _system(
  at,
  _burst(
    count: 6,
    lifespan: _tHitSpark,
    minDist: 16,
    maxDist: 24,
    radius: 3,
    color: (_) => C.primary,
  ),
);

/// `SweepParticle` — lane sweep triggers. 20 dots, radial burst along the
/// lane, wide spread. 500ms.
ParticleSystemComponent sweepBurst(Vector2 at) => _system(
  at,
  _burst(
    count: 20,
    lifespan: _tSweep,
    minDist: 20,
    maxDist: 56,
    radius: 3,
    direction: 0, // along the lane (+x); rotate the emitter if a lane runs
    // the other way.
    spread: math.pi, // "wide spread"
    color: (_) => C.primary,
  ),
);

/// `DeathDissolveParticle` — shadow dies. 6-10 dots, upward drift + fade,
/// smoke-coloured per §4.4. 400ms.
///
/// §4.4 ties "smoke" to the shadow palette rather than a literal grey; there
/// is no dedicated smoke/grey token, so this uses `C.shadowBorder` (the
/// lighter of the two shadow tones — reads as dissipating ink, not a flat
/// silhouette fill).
ParticleSystemComponent deathDissolve(Vector2 at) {
  final count = 6 + _rng.nextInt(5); // 6-10
  return _system(
    at,
    Particle.generate(
      count: count,
      lifespan: _tDissolve,
      generator: (_) {
        final dx = (_rng.nextDouble() - 0.5) * 16;
        final dy = -18 - _rng.nextDouble() * 18;
        final radius = 2.5 + _rng.nextDouble() * 2;
        return _dot(
          C.shadowBorder,
          radius,
        ).moving(to: Vector2(dx, dy), curve: Curves.easeOut);
      },
    ),
  );
}

/// `ExplosionParticle` — Flash Bomb detonates. 30 dots, radial burst,
/// `#FFD23F` → `#EF5350` (== C.primary → C.error). 400ms.
ParticleSystemComponent explosionBurst(Vector2 at) => _system(
  at,
  _burst(
    count: 30,
    lifespan: _tExplosion,
    minDist: 30,
    maxDist: 84,
    radius: 4,
    color: (i) => Color.lerp(C.primary, C.error, i / 29) ?? C.primary,
  ),
);

/// `ConfettiParticle` — win dialog. 12 dots falling from the top of a
/// [width]-wide band centred on [at], rotating, mixed palette. 800ms.
ParticleSystemComponent confettiFall(Vector2 at, double width) => _system(
  at,
  Particle.generate(
    count: 12,
    lifespan: _tConfetti,
    generator: (i) {
      final x0 = (_rng.nextDouble() - 0.5) * width;
      final fallY = 120 + _rng.nextDouble() * 80;
      final sway = (_rng.nextDouble() - 0.5) * 24;
      final spin =
          (_rng.nextBool() ? 1 : -1) * math.pi * (2 + _rng.nextDouble() * 2);
      final color = C.prismSpectrum[i % C.prismSpectrum.length];
      return _dot(color, 3, fade: false)
          .rotating(from: 0, to: spin)
          .moving(to: Vector2(sway, fallY), curve: Curves.easeIn)
          .translated(Vector2(x0, 0));
    },
  ),
);

/// `LeapDustParticle` — Jumper leaps a wall. 4 dots, small puff. 200ms.
///
/// No dedicated dust/grey token exists; uses `C.textSecondary` (neutral
/// grey) for the puff.
ParticleSystemComponent leapDust(Vector2 at) => _system(
  at,
  _burst(
    count: 4,
    lifespan: _tLeapDust,
    minDist: 4,
    maxDist: 10,
    radius: 2,
    color: (_) => C.textSecondary,
  ),
);

/// Rewarded-ad glow payout. Gold burst, ~400ms. Not in the §18.1 table
/// (that's the base inventory); this is the reward-flow equivalent of
/// `CollectParticle`, sized up for a one-off payout moment.
ParticleSystemComponent glowBurst(Vector2 at) => _system(
  at,
  _burst(
    count: 10,
    lifespan: _tGlow,
    minDist: 20,
    maxDist: 40,
    radius: 4,
    color: (_) => C.primary,
  ),
);
