/// The battle — spec §16 is the tick, §15 the optics, §17 the placement rules.
///
/// The pure rules live in lib/data/rules.dart and lib/data/optics.dart and are
/// unit-tested there. This class owns the component tree, the timers and the
/// wiring; it deliberately contains no rule it could have imported.
library;

import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';

import '../../core/audio.dart';
import '../../core/layout.dart';
import '../../core/save_store.dart';
import '../../core/tokens.dart';
import '../../data/content.dart';
import '../../data/models.dart';
import '../../data/optics.dart';
import '../../data/rules.dart' as rules;
import '../components/backdrop_layers.dart';
import '../components/beam_component.dart';
import '../components/glow_orb_component.dart';
import '../components/grid_component.dart';
import '../components/shadow_component.dart';
import '../components/tools/tool_component.dart';
import '../components/tools/tool_factory.dart';
import '../light_vs_shadow_game.dart';
import '../particles/effect_pool.dart';
import '../particles/particle_definitions.dart' as fx;
import '../components/hud/overlay_lose.dart';
import '../components/hud/overlay_pause.dart';
import '../components/hud/overlay_win.dart';

/// How often a Beam Lamp / Frost Lens fires (spec §6: "20 dmg / 1.2s tick").
const double kEmitterInterval = 1.2;

class BattleWorld extends World with HasGameReference<LightVsShadowGame> {
  BattleWorld({
    required this.levelId,
    required this.tray,
    required this.onWin,
    required this.onLose,
  });

  final int levelId;

  /// The six tools the player brought (spec §6 Tray Limit).
  final List<String> tray;

  final void Function(int stars, int coins) onWin;
  final void Function() onLose;

  late final Level level = Content.I.level(levelId);
  late final BattleLayout layout = game.layout;

  // --- simulation state (spec §16) ---------------------------------------
  GameState state = GameState.loading;
  double time = 0;
  double _lastGlowFall = 0;
  double _lastWaveTime = 0;
  int glow = 0;
  int waveIndex = 0;
  bool usedBoost = false;
  final List<bool> sweepAvailable = List<bool>.filled(kRows, true);
  final Map<String, double> lastPlaced = {};

  /// Selected tray tool id, or null when nothing is armed.
  String? selectedTool;

  /// Board occupancy, mirrored from the component tree so the tracer and the
  /// validator get a plain grid without walking children every frame.
  final List<List<ToolComponent?>> _tools = List.generate(
    kRows,
    (_) => List<ToolComponent?>.filled(kCols, null),
  );

  late final GridComponent grid;
  late final AmbientGlowLayer _glowLayer;
  final List<BeamComponent> _beams = [];

  /// Total HP each wave spawned with, for the 50% rule.
  final List<int> _waveTotalHp = [];

  // --- callbacks the HUD layer binds to ----------------------------------
  void Function(int glow)? onGlowChanged;
  void Function(int waveIndex, int waveCount)? onWaveChanged;
  void Function(String message)? onToast;

  /// Capped particle budget — spec §18.3 / §24 (<= 50 draw calls per frame).
  late final ParticlePool _fx = ParticlePool(this);

  @override
  Future<void> onLoad() async {
    final view = kBaselineSize.clone();
    grid = GridComponent(layout: layout, onTileTap: _onTileTap);
    _glowLayer = AmbientGlowLayer(layout: layout);

    await addAll([
      BackdropLayer(viewSize: view),
      DustMoteLayer(viewSize: view),
      _glowLayer,
      grid,
    ]);

    glow = level.startGlow;
    onGlowChanged?.call(glow);
    onWaveChanged?.call(0, level.waves.length);
    state = GameState.playing;
  }

  // -----------------------------------------------------------------------
  // Queries
  // -----------------------------------------------------------------------

  Iterable<ShadowComponent> get shadows =>
      children.whereType<ShadowComponent>().where((s) => !s.isDying);

  ToolComponent? toolAt(int row, int col) =>
      (row < 0 || row >= kRows || col < 0 || col >= kCols)
      ? null
      : _tools[row][col];

  List<List<String?>> get _toolIdGrid => [
    for (final row in _tools) [for (final t in row) t?.id],
  ];

  // -----------------------------------------------------------------------
  // Placement — spec §17
  // -----------------------------------------------------------------------

  void _onTileTap(int row, int col) {
    final id = selectedTool;
    if (id == null) return;
    tryPlace(id, row, col);
  }

  /// Attempts a placement and applies every side effect on success.
  /// Returns the reason so tests can assert without inspecting the tree.
  PlaceResult tryPlace(String toolId, int row, int col) {
    final def = Content.I.tool(toolId);
    final result = rules.validatePlacement(
      state: state,
      row: row,
      col: col,
      tool: def,
      glow: glow,
      now: time,
      lastPlaced: lastPlaced,
      grid: _toolIdGrid,
    );

    if (result != PlaceResult.ok) {
      _rejectPlacement(result, row, col);
      return result;
    }

    _setGlow(glow - def.cost);
    lastPlaced[toolId] = time;
    selectedTool = null;

    final center = layout.tileCenter(row, col);

    if (toolId == 'bomb') {
      _detonateBomb(row, col);
      return result;
    }

    // Twin Bulb replaces the Bulb under it, no refund (spec §5).
    if (toolId == 'twin') {
      _tools[row][col]?.removeFromParent();
      _tools[row][col] = null;
    }

    final tool = createTool(def: def, row: row, col: col, center: center)
      ..lastGen = time
      ..lastFire = time;
    _tools[row][col] = tool;
    grid.tileAt(row, col).occupied = true;
    add(tool);

    _fx.emit(() => fx.placeBurst(center));
    GameAudio.play(Sfx.place);
    GameAudio.haptic();
    _refreshGlowPools();
    return result;
  }

  void _rejectPlacement(PlaceResult result, int row, int col) {
    if (result == PlaceResult.occupied ||
        result == PlaceResult.needBulb ||
        result == PlaceResult.maxPrism) {
      if (row >= 0 && row < kRows && col >= 0 && col < kCols) {
        grid.tileAt(row, col).shake();
      }
    }
    if (result.toast case final msg?) onToast?.call(msg);
  }

  /// Flash Bomb: 300 damage over its own tile plus one in every direction,
  /// clamped to the board, then the bomb itself is gone (spec §17).
  void _detonateBomb(int row, int col) {
    final center = layout.tileCenter(row, col);
    final footprint = rules.bombFootprint(row, col);
    _fx.emit(() => fx.explosionBurst(center));
    GameAudio.play(Sfx.explosion);

    for (final s in shadows.toList()) {
      final c = layout.tileColFromX(s.position.x);
      if (c == null) continue;
      if (!footprint.any((f) => f.row == s.lane && f.col == c)) continue;
      if (s.takeBeamDamage(kBombDamage.toDouble(), slow: false, now: time)) {
        _killShadow(s);
      }
    }
  }

  /// Long-press removal, no refund (spec §17 Input).
  void removeToolAt(int row, int col) {
    final tool = _tools[row][col];
    if (tool == null) return;
    _tools[row][col] = null;
    grid.tileAt(row, col).occupied = false;
    tool.destroyAndRemove();
    _refreshGlowPools();
  }

  // -----------------------------------------------------------------------
  // Economy
  // -----------------------------------------------------------------------

  void _setGlow(int next) {
    glow = rules.clampGlow(next);
    onGlowChanged?.call(glow);
  }

  /// Rewarded-ad payout, capped at one per battle (spec §20).
  bool grantBoost() {
    if (usedBoost) return false;
    usedBoost = true;
    _setGlow(glow + 50);
    return true;
  }

  void _refreshGlowPools() {
    _glowLayer.sources
      ..clear()
      ..addAll([
        for (final row in _tools)
          for (final t in row)
            if (t != null && (t.def.isGenerator || t.def.isEmitter))
              t.position.clone(),
      ]);
  }

  int get _orbsOnScreen => children.whereType<GlowOrbComponent>().length;

  // -----------------------------------------------------------------------
  // Tick — spec §16
  // -----------------------------------------------------------------------

  @override
  void update(double dt) {
    // Spec §24 edge case 18: a dt spike must not teleport anything.
    final step = math.min(dt, 1 / 30);
    super.update(step);
    if (state != GameState.playing) return;
    time += step;

    _tickFallingGlow();
    _tickGenerators();
    _tickWaves();
    _tickShadows(step);
    _tickSweep();
    _tickBeams(step);
    _tickTerminal();
  }

  void _tickFallingGlow() {
    if (time - _lastGlowFall <= kGlowFallInterval) return;
    if (_orbsOnScreen >= kGlowOrbsMax) return;
    _lastGlowFall = time;
    final x = layout.origin.x + math.Random().nextDouble() * layout.boardW;
    add(
      GlowOrbComponent(
        spawn: Vector2(x, layout.origin.y - 20),
        fallTo: layout.origin.y + math.Random().nextDouble() * layout.boardH,
        onCollect: (orb) {
          _setGlow(glow + kGlowFallAmount);
          _fx.emit(() => fx.collectBurst(orb.position.clone()));
          GameAudio.play(Sfx.collect);
        },
      ),
    );
  }

  void _tickGenerators() {
    for (final row in _tools) {
      for (final t in row) {
        if (t == null || !t.def.isGenerator || !t.isAlive) continue;
        if (time - t.lastGen <= kBulbGenInterval) continue;
        t.lastGen = time;
        _setGlow(glow + (t.id == 'twin' ? kTwinGenAmount : kBulbGenAmount));
        _fx.emit(() => fx.collectBurst(t.position.clone()));
      }
    }
  }

  void _tickWaves() {
    if (waveIndex >= level.waves.length) return;

    final prevTotal = waveIndex == 0 ? 0 : _waveTotalHp[waveIndex - 1];
    final prevAlive = waveIndex == 0
        ? 0
        : shadows
              .where((s) => s.fromWave == waveIndex - 1)
              .fold<int>(0, (sum, s) => sum + s.hp.ceil());

    final ready = rules.canSpawnNextWave(
      waveIndex: waveIndex,
      waves: level.waves,
      time: time,
      lastWaveTime: _lastWaveTime,
      previousWaveTotalHp: prevTotal,
      previousWaveAliveHp: prevAlive,
    );
    if (!ready) return;

    _spawnWave(level.waves[waveIndex]);
    _lastWaveTime = time;
    waveIndex++;
    onWaveChanged?.call(waveIndex, level.waves.length);
  }

  void _spawnWave(Wave wave) {
    var totalHp = 0;
    for (final spawn in wave.shadows) {
      final def = Content.I.shadow(spawn.id);
      totalHp += def.hp;
      add(
        ShadowComponent(
          def: def,
          lane: spawn.lane,
          fromWave: waveIndex,
          spawn: Vector2(layout.spawnX, layout.laneCenterY(spawn.lane)),
        ),
      );
    }
    _waveTotalHp.add(totalHp);
  }

  /// Movement, eating and the two per-type specials. Kept here rather than in
  /// ShadowComponent.update so the shadow never has to reach back into the
  /// world for the board — one direction of dependency, not two.
  void _tickShadows(double dt) {
    for (final s in shadows.toList()) {
      final col = layout.tileColFromX(s.position.x);
      final front = col == null ? null : toolAt(s.lane, col);

      final isEating =
          front != null &&
          front.def.isPersistent &&
          front.isAlive &&
          s.position.x <= front.position.x + layout.tile / 2;

      if (isEating) {
        s.isEating = true;
        front.takeDamage(s.def.eat * dt);
        if (!front.isAlive) {
          _tools[front.row][front.col] = null;
          grid.tileAt(front.row, front.col).occupied = false;
          front.destroyAndRemove();
          _refreshGlowPools();
        }
      } else {
        s.isEating = false;
        final blockedByWall =
            front != null && front.id == 'wall' && front.isAlive;
        if (s.def.jumpsWalls &&
            !s.hasJumped &&
            blockedByWall &&
            (s.position.x - front.position.x).abs() < 20) {
          s.leapWall(onDust: (at) => _fx.emit(() => fx.leapDust(at)));
        } else {
          s.position.x -= s.speedAt(time) * dt;
        }
      }

      // Colossus throws one Shade at half health.
      if (s.def.throwsImp && !s.hasThrown && s.hp < s.maxHp * 0.5) {
        s.hasThrown = true;
        add(
          ShadowComponent(
            def: Content.I.shadow('basic'),
            lane: s.lane,
            fromWave: s.fromWave,
            spawn: Vector2(s.position.x + 40, layout.laneCenterY(s.lane)),
          ),
        );
      }
    }
  }

  void _tickSweep() {
    for (final s in shadows) {
      if (s.position.x > layout.origin.x + kSweepTriggerX) continue;
      if (!sweepAvailable[s.lane]) continue;
      final lane = s.lane;
      sweepAvailable[lane] = false;
      grid.sweepAvailable[lane] = false;
      _fx.emit(
        () => fx.sweepBurst(Vector2(layout.origin.x, layout.laneCenterY(lane))),
      );
      GameAudio.play(Sfx.sweep);
      for (final victim in shadows.where((x) => x.lane == lane).toList()) {
        _killShadow(victim);
      }
      break;
    }
  }

  void _tickBeams(double dt) {
    // Emitters fire on their own 1.2s cadence; between ticks the drawn beam
    // stays put, which is why the trace only reruns when it must.
    final emitters = <({int row, int col, BeamKind kind, double dmg})>[];
    var fired = false;
    for (final row in _tools) {
      for (final t in row) {
        if (t == null || !t.def.isEmitter || !t.isAlive) continue;
        if (time - t.lastFire >= kEmitterInterval) {
          t.lastFire = time;
          fired = true;
        }
        emitters.add((
          row: t.row,
          col: t.col,
          kind: t.id == 'frost' ? BeamKind.frost : BeamKind.light,
          dmg: t.def.dmg.toDouble(),
        ));
      }
    }

    if (emitters.isEmpty) {
      for (final b in _beams) {
        b.hide();
      }
      return;
    }

    final targets = [
      for (final s in shadows)
        BeamTarget(
          id: s,
          lane: s.lane,
          col: layout.colFromX(s.position.x),
          resistsBeam: s.def.resistsBeam,
        ),
    ];

    final result = traceAll(
      grid: _toolIdGrid,
      targets: targets,
      emitters: emitters,
    );

    // Damage is continuous while a beam rests on a shadow; the 1.2s tick only
    // gates the *sound and spark*, so the numbers in §6 read as dps.
    // QA #9: the ray hits the first shadow; co-located shadows in the same
    // tile rect also take damage via this area check.
    final damaged = <ShadowComponent>{};
    for (final hit in result.hits) {
      final primary = hit.targetId as ShadowComponent;
      final primaryCol = layout.colFromX(primary.position.x);
      for (final s in shadows) {
        if (s.lane != primary.lane) continue;
        if ((layout.colFromX(s.position.x) - primaryCol).abs() > 0.5) continue;
        if (!damaged.add(s)) continue;
        if (s.takeBeamDamage(
          hit.dmgPerSecond * dt,
          slow: hit.applySlow,
          now: time,
        )) {
          _killShadow(s);
        } else if (fired) {
          _fx.emit(() => fx.hitSpark(s.position.clone()));
          GameAudio.play(Sfx.hit);
        }
      }
    }

    if (fired) GameAudio.play(Sfx.shoot);
    _renderSegments(result.segments);
  }

  void _renderSegments(List<BeamSegment> segments) {
    while (_beams.length < segments.length) {
      final b = BeamComponent();
      _beams.add(b);
      add(b);
    }
    for (var i = 0; i < _beams.length; i++) {
      if (i < segments.length) {
        _beams[i].setSegment(segments[i], layout);
      } else {
        _beams[i].hide();
      }
    }
  }

  void _killShadow(ShadowComponent s) =>
      s.die(onDissolve: (at) => _fx.emit(() => fx.deathDissolve(at)));

  void _tickTerminal() {
    if (rules.hasWon(
      waveIndex: waveIndex,
      waveCount: level.waves.length,
      shadowsAlive: shadows.length,
    )) {
      _finishWon();
      return;
    }
    if (rules.hasLost(
      shadows: [
        for (final s in shadows)
          (x: s.position.x - layout.origin.x, lane: s.lane),
      ],
      sweepAvailable: sweepAvailable,
    )) {
      _finishLost();
    }
  }

  void _finishWon() {
    state = GameState.won;
    final save = SaveStore.I.state;
    final previous = save.starsFor(levelId);
    final stars = rules.starsFor(
      elapsed: time,
      parTime: level.parTime,
      sweepAvailable: sweepAvailable,
    );
    final coins = rules.coinsFor(previousStars: previous, newStars: stars);

    save.stars[levelId - 1] = math.max(previous, stars);
    save.coins += coins;
    save.totalPlays += 1;
    if (levelId == save.maxUnlocked && levelId < kLevelCount) {
      save.maxUnlocked = levelId + 1;
    }
    if (level.unlockReward case final reward?) save.unlocked.add(reward);
    SaveStore.I.flush();

    GameAudio.play(Sfx.win);
    _fx.emit(() => fx.confettiFall(Vector2(kBaselineSize.x / 2, 20), 420));
    game.pauseEngine();
    _showOverlay(
      WinOverlay(
        stars: stars,
        coins: coins,
        onMap: () => onWin(stars, coins),
        onNext: () => onWin(stars, coins),
      ),
    );
  }

  void _finishLost() {
    state = GameState.lost;
    SaveStore.I.state.totalPlays += 1;
    SaveStore.I.flush();
    GameAudio.play(Sfx.lose);
    // Spec §12: the world shakes before the overlay lands.
    game.camera.viewfinder.add(
      MoveByEffect(
        Vector2(4, 0),
        EffectController(
          duration: D.secs(D.loseShake) / 6,
          alternate: true,
          repeatCount: 3,
        ),
        onComplete: () {
          game.pauseEngine();
          _showOverlay(LoseOverlay(onTryAgain: onLose, onMap: onLose));
        },
      ),
    );
  }

  /// Spec §24 edge cases 10/11/15: lifecycle and rotation pause the sim without
  /// tearing the tree down. Also mounts the Pause overlay (DS-075).
  void pause({bool showOverlay = true}) {
    if (state != GameState.playing) return;
    state = GameState.paused;
    game.pauseEngine();
    if (showOverlay) {
      _showOverlay(
        PauseOverlay(onResume: resume, onRestart: onLose, onHome: onLose),
      );
    }
  }

  void resume() {
    if (state != GameState.paused) return;
    _dismissOverlay();
    state = GameState.playing;
    game.resumeEngine();
  }

  Component? _activeOverlay;

  void _showOverlay(Component overlay) {
    _dismissOverlay();
    _activeOverlay = overlay;
    game.camera.viewport.add(overlay);
  }

  void _dismissOverlay() {
    _activeOverlay?.removeFromParent();
    _activeOverlay = null;
  }
}
