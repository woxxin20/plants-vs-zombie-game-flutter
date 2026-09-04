/// Level Map screen (spec §12) — a 5x4 grid of level cards.
///
/// The spec wireframe gives cards as 110x90 with a 12px gap, four rows tall.
/// At the fixed 812x375 camera viewport (`kBaselineSize`) that literal grid
/// (598x396) is taller than the whole screen, so it's scaled down here to
/// 96x64 / gap 8 to actually fit above/below the header — same 5x4 layout,
/// same per-card content, just resized to the real viewport.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../../core/layout.dart';
import '../../core/save_store.dart';
import '../../core/tokens.dart';
import '../../data/content.dart' show kLevelCount;
import '../light_vs_shadow_game.dart';
import 'world_widgets.dart';

class MapWorld extends World with HasGameReference<LightVsShadowGame> {
  MapWorld({required this.onSelect, required this.onBack});

  final void Function(int levelId) onSelect;
  final VoidCallback onBack;

  static const _cols = 5;
  static const _rows = 4;
  static final _cardSize = Vector2(96, 64);
  static const _gap = S.x2;

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
        text: 'LEVELS',
        textRenderer: TextPaint(style: T.h1),
        anchor: Anchor.centerLeft,
        position: Vector2(96, S.screenPad + 18),
      ),
    );

    final save = SaveStore.I.state;
    await add(
      _CoinChip(
        coins: save.coins,
        position: Vector2(viewSize.x - S.screenPad, S.screenPad),
      ),
    );

    final gridW = _cols * _cardSize.x + (_cols - 1) * _gap;
    final gridH = _rows * _cardSize.y + (_rows - 1) * _gap;
    final origin = Vector2(
      (viewSize.x - gridW) / 2,
      S.screenPad +
          52 +
          (viewSize.y - S.screenPad - 52 - S.screenPad - gridH) / 2,
    );

    for (var r = 0; r < _rows; r++) {
      for (var c = 0; c < _cols; c++) {
        final id = r * _cols + c + 1;
        if (id > kLevelCount) continue;
        await add(
          _LevelCard(
            id: id,
            stars: save.starsFor(id),
            locked: id > save.maxUnlocked,
            onSelect: onSelect,
            position:
                origin +
                Vector2(c * (_cardSize.x + _gap), r * (_cardSize.y + _gap)),
          ),
        );
      }
    }
  }
}

class _CoinChip extends PositionComponent {
  _CoinChip({required this.coins, required Vector2 position})
    : super(
        size: Vector2(112, 32),
        position: position,
        anchor: Anchor.topRight,
      );

  final int coins;

  static final _bg = Paint()..color = C.surface2;
  static final _coin = Paint()..color = C.primary;

  @override
  Future<void> onLoad() async {
    await add(
      TextComponent(
        text: '$coins',
        textRenderer: TextPaint(style: T.number.copyWith(color: C.primary)),
        anchor: Anchor.centerLeft,
        position: Vector2(28, size.y / 2),
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size.toSize(),
        const Radius.circular(R.chip),
      ),
      _bg,
    );
    canvas.drawCircle(Offset(16, size.y / 2), 7, _coin);
  }
}

class _LevelCard extends PositionComponent with TapCallbacks {
  _LevelCard({
    required this.id,
    required this.stars,
    required this.locked,
    required this.onSelect,
    required Vector2 position,
  }) : super(size: MapWorld._cardSize.clone(), position: position);

  final int id;
  final int stars;
  final bool locked;
  final void Function(int levelId) onSelect;

  static final _fill = Paint()..color = C.surface2;
  static final _border = Paint()
    ..color = C.gridBorder
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final _starFill = Paint()..color = C.primary;
  static final _starEmpty = Paint()
    ..color = C.gridBorder
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  @override
  Future<void> onLoad() async {
    await add(
      TextComponent(
        text: '$id',
        textRenderer: TextPaint(style: T.h3),
        anchor: Anchor.topCenter,
        position: Vector2(size.x / 2, 8),
      ),
    );
  }

  @override
  void renderTree(Canvas canvas) {
    if (!locked) {
      super.renderTree(canvas);
      return;
    }
    canvas.saveLayer(null, Paint()..color = const Color(0x66000000));
    super.renderTree(canvas);
    canvas.restore();
  }

  @override
  void render(Canvas canvas) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size.toSize(),
      const Radius.circular(R.tile),
    );
    canvas.drawRRect(rrect, _fill);
    canvas.drawRRect(rrect, _border);

    const starR = 5.0;
    final starsY = size.y - 14;
    final startX = size.x / 2 - starR * 2.4;
    for (var i = 0; i < 3; i++) {
      final cx = startX + i * starR * 2.4;
      final path = _starPath(Offset(cx, starsY), starR);
      canvas.drawPath(path, i < stars ? _starFill : _starEmpty);
    }
  }

  @override
  bool containsLocalPoint(Vector2 point) =>
      !locked && (Offset.zero & size.toSize()).contains(point.toOffset());

  @override
  void onTapUp(TapUpEvent event) => onSelect(id);
}

Path _starPath(Offset center, double r) {
  final path = Path();
  const points = 5;
  const rotation = -math.pi / 2;
  for (var i = 0; i < points * 2; i++) {
    final radius = i.isEven ? r : r * 0.45;
    final angle = rotation + i * math.pi / points;
    final pt = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
    if (i == 0) {
      path.moveTo(pt.dx, pt.dy);
    } else {
      path.lineTo(pt.dx, pt.dy);
    }
  }
  path.close();
  return path;
}
