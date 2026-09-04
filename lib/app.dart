/// App shell — the composition root above the engine.
///
/// One long-lived [LightVsShadowGame] lives inside one
/// [RiverpodAwareGameWidget]; `go_router`'s shell keeps that widget mounted for
/// every route and each child route only swaps `camera.world` (`ADR-003`).
/// The root is [WidgetsApp] — never `MaterialApp` (`ADR-006`).
library;

import 'package:flame/components.dart' show World;
import 'package:flame_riverpod/flame_riverpod.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'core/save_store.dart';
import 'core/tokens.dart';
import 'data/models.dart' show GameState;
import 'data/rules.dart' show dailyLevelId;
import 'game/light_vs_shadow_game.dart';
import 'game/worlds/battle_world.dart';
import 'game/worlds/home_world.dart';
import 'game/worlds/loadout_world.dart';
import 'game/worlds/map_world.dart';
import 'game/worlds/settings_world.dart';
import 'game/worlds/shop_world.dart';

class PrismDefenseApp extends StatefulWidget {
  const PrismDefenseApp({super.key});

  @override
  State<PrismDefenseApp> createState() => _PrismDefenseAppState();
}

class _PrismDefenseAppState extends State<PrismDefenseApp>
    with WidgetsBindingObserver {
  final LightVsShadowGame _game = LightVsShadowGame();
  final GlobalKey<RiverpodAwareGameWidgetState<LightVsShadowGame>> _gameKey =
      GlobalKey();
  late final GoRouter _router = _buildRouter();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// QA checklist #10: backgrounding pauses the engine (and the battle sim).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _game.pauseEngine();
      final world = _game.world;
      if (world is BattleWorld) world.pause();
    } else if (state == AppLifecycleState.resumed) {
      final world = _game.world;
      // Battle stays paused behind the overlay until the player taps Resume.
      if (world is BattleWorld && world.state == GameState.paused) return;
      _game.resumeEngine();
    }
  }

  GoRouter _buildRouter() => GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/home'),
      ShellRoute(
        builder: (context, state, child) => Stack(
          children: [
            RiverpodAwareGameWidget(game: _game, key: _gameKey),
            child,
          ],
        ),
        routes: [
          _world(
            '/home',
            (context, state) => HomeWorld(
              onPlay: () =>
                  context.go('/loadout/${SaveStore.I.state.maxUnlocked}'),
              onMap: () => context.go('/map'),
              onSettings: () => context.go('/settings'),
              onDaily: () =>
                  context.go('/loadout/${dailyLevelId(DateTime.now())}'),
            ),
          ),
          _world(
            '/map',
            (context, state) => MapWorld(
              onSelect: (levelId) => context.go('/loadout/$levelId'),
              onBack: () => context.go('/home'),
            ),
          ),
          _world('/loadout/:levelId', (context, state) {
            final levelId = _levelId(state);
            return LoadoutWorld(
              levelId: levelId,
              onStart: (picked) =>
                  context.go('/battle/$levelId', extra: picked),
              onBack: () => context.go('/map'),
            );
          }),
          _world(
            '/battle/:levelId',
            (context, state) => BattleWorld(
              levelId: _levelId(state),
              // BattleWorld persists its own result; these are navigation only.
              tray: (state.extra as List<String>?) ?? const <String>[],
              onWin: (stars, coins) => context.go('/map'),
              onLose: () => context.go('/map'),
            ),
          ),
          _world(
            '/shop',
            (context, state) => ShopWorld(
              onRemoveAdsPressed: () {},
              onBack: () => context.go('/home'),
            ),
          ),
          _world(
            '/settings',
            (context, state) =>
                SettingsWorld(onBack: () => context.go('/home')),
          ),
        ],
      ),
    ],
  );

  /// A route whose only job is to put [build]'s world on the shared game.
  GoRoute _world(
    String path,
    World Function(BuildContext, GoRouterState) build,
  ) => GoRoute(
    path: path,
    builder: (context, state) => _WorldSwap(
      key: ValueKey(state.uri.toString()),
      game: _game,
      build: () => build(context, state),
    ),
  );

  static int _levelId(GoRouterState state) =>
      int.tryParse(state.pathParameters['levelId'] ?? '') ?? 1;

  @override
  Widget build(BuildContext context) => WidgetsApp.router(
    title: 'LIGHT vs SHADOW',
    color: C.bg,
    routerConfig: _router,
    builder: (context, child) => Directionality(
      textDirection: TextDirection.ltr,
      child: child ?? const SizedBox.shrink(),
    ),
  );
}

/// Zero-size route body: mounting it swaps the shared game's world.
///
/// The swap runs post-frame so the engine is never mutated mid-build, and the
/// world is built once per route (the [ValueKey] above forces a fresh state on
/// every navigation).
class _WorldSwap extends StatefulWidget {
  const _WorldSwap({super.key, required this.game, required this.build});

  final LightVsShadowGame game;
  final World Function() build;

  @override
  State<_WorldSwap> createState() => _WorldSwapState();
}

class _WorldSwapState extends State<_WorldSwap> {
  @override
  void initState() {
    super.initState();
    final world = widget.build();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.game.swapWorld(world);
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
