/// Pooling discipline for particle systems — spec §18.3. Caps concurrent
/// particle systems so a spam of hits can't blow the ≤50-draw-call/frame
/// budget (§24).
library;

import 'package:flame/components.dart';

/// A counter and a list, not a framework: caps how many particle systems
/// [emit] has added and are still running, dropping the request once
/// [maxLive] is reached rather than exceeding the draw-call budget.
///
/// ponytail: liveness is pruned lazily — each [emit] call first drops
/// tracked systems whose particle has already finished, rather than
/// subscribing to Flame's async removal lifecycle (`Component.removed`,
/// which only resolves once the system is actually mounted in a running
/// game — awkward to unit test and unnecessary here). A finished system
/// still self-removes from the render tree on schedule either way (that's
/// `ParticleSystemComponent`'s own job, untouched); the only ceiling is that
/// its pool slot isn't freed until the *next* `emit` call. Upgrade to
/// `system.removed.then(...)` eager decrement if a real gap between "finished"
/// and "next emit" ever starves emitters in practice.
class ParticlePool {
  ParticlePool(this.parent, {this.maxLive = 24});

  final Component parent;
  final int maxLive;

  final List<ParticleSystemComponent> _live = [];

  /// How many systems this pool currently believes are alive.
  int get liveCount => _live.length;

  /// Builds and adds a particle system, unless [maxLive] concurrent systems
  /// are already alive — in which case the request is dropped.
  void emit(ParticleSystemComponent Function() build) {
    _live.removeWhere((s) => s.particle?.shouldRemove ?? true);
    if (_live.length >= maxLive) return;
    final system = build();
    _live.add(system);
    parent.add(system);
  }
}
