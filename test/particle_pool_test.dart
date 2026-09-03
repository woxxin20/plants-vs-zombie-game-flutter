import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prism_defense/game/particles/effect_pool.dart';

/// A fake particle system with a fixed lifespan, never mounted to any game —
/// `ParticlePool` only needs `Component.add` (synchronous when the parent
/// isn't mounted) and `Particle.shouldRemove`, so no real game loop is
/// needed to drive this.
ParticleSystemComponent _fakeSystem({double lifespan = 999}) =>
    ParticleSystemComponent(
      particle: CircleParticle(paint: Paint(), lifespan: lifespan),
    );

void main() {
  test(
    'ParticlePool stops emitting past maxLive and resumes once systems finish',
    () {
      final parent = Component();
      final pool = ParticlePool(parent, maxLive: 2);

      final shortLived = _fakeSystem(lifespan: 0.01);
      pool.emit(() => shortLived);
      pool.emit(_fakeSystem);
      expect(pool.liveCount, 2);
      expect(parent.children.length, 2);

      // At capacity: a spam of extra hits is dropped, not queued.
      pool.emit(_fakeSystem);
      pool.emit(_fakeSystem);
      expect(pool.liveCount, 2);
      expect(parent.children.length, 2);

      // Finish the short-lived system (one big dt tick past its lifespan).
      // ParticleSystemComponent's own update() removes it on schedule.
      shortLived.update(1);
      expect(shortLived.particle!.shouldRemove, isTrue);
      expect(parent.children.contains(shortLived), isFalse);

      // The pool resumes: the next emit prunes the finished tracking entry
      // and accepts the new system, without exceeding the cap.
      pool.emit(_fakeSystem);
      expect(pool.liveCount, 2);
      expect(parent.children.length, 2);
    },
  );
}
