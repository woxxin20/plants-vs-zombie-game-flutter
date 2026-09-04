/// Home screen (spec §12) — title, nav buttons, a live mini-diorama preview
/// and the daily chip.
library;

import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';

import '../../core/layout.dart';
import '../../core/save_store.dart';
import '../../core/tokens.dart';
import '../../data/content.dart' show kLevelCount;
import '../light_vs_shadow_game.dart';
import 'world_widgets.dart';
import '../components/fadeable.dart';

class HomeWorld extends World with HasGameReference<LightVsShadowGame> {
  HomeWorld({
    required this.onPlay,
    required this.onMap,
    required this.onSettings,
    required this.onDaily,
  });

  final VoidCallback onPlay;
  final VoidCallback onMap;
  final VoidCallback onSettings;
  final VoidCallback onDaily;

  @override
  Future<void> onLoad() async {
    final viewSize = kBaselineSize.clone();
    await addMenuBackdrop(this, viewSize: viewSize, layout: game.layout);

    // --- left column: title, sub, nav buttons ---------------------------
    const leftX = 64.0;
    await add(
      TextComponent(
        text: 'LIGHT vs SHADOW',
        textRenderer: TextPaint(style: T.display),
        position: Vector2(leftX, 40),
      ),
    );
    await add(
      TextComponent(
        text: 'DEFEND THE LIGHT',
        textRenderer: TextPaint(
          style: T.bodySmall.copyWith(color: C.textSecondary),
        ),
        position: Vector2(leftX, 88),
      ),
    );

    var y = 136.0;
    await add(
      WorldButton(
        size: Vector2(220, 56),
        label: 'PLAY',
        onPressed: onPlay,
        background: C.primary,
        textColor: C.onPrimary,
        position: Vector2(leftX, y),
      ),
    );
    y += 56 + S.x4;
    await add(
      WorldButton(
        size: Vector2(200, 48),
        label: 'MAP',
        onPressed: onMap,
        background: C.surface3,
        textColor: C.textPrimary,
        position: Vector2(leftX, y),
      ),
    );
    y += 48 + S.x4;
    await add(
      WorldButton(
        size: Vector2(200, 48),
        label: 'SETTINGS',
        onPressed: onSettings,
        background: C.surface3,
        textColor: C.textPrimary,
        position: Vector2(leftX, y),
      ),
    );

    // --- right column: preview card + daily chip -------------------------
    final cardSize = Vector2(280, 160);
    final cardX = viewSize.x - cardSize.x - leftX;
    const cardY = 40.0;
    await add(
      _PreviewCard(size: cardSize.clone(), position: Vector2(cardX, cardY)),
    );

    final save = SaveStore.I.state;
    final today = DateTime.now();
    final dayOfYear = today.difference(DateTime(today.year)).inDays + 1;
    final claimedToday = save.lastDailyClaimed == dayOfYear;

    final chipSize = Vector2(180, 32);
    final chipX = cardX + (cardSize.x - chipSize.x) / 2;
    final chipY = cardY + cardSize.y + S.x4;
    await add(
      WorldButton(
        size: chipSize.clone(),
        label: claimedToday ? 'DAILY CLAIMED' : 'DAILY READY',
        onPressed: onDaily,
        background: C.surface2,
        textColor: claimedToday ? C.textSecondary : C.primary,
        radius: R.chip,
        textStyle: T.bodySmall,
        position: Vector2(chipX, chipY),
      ),
    );

    final completed = save.stars.where((s) => s > 0).length;
    await add(
      TextComponent(
        text: '$completed/$kLevelCount',
        textRenderer: TextPaint(
          style: T.bodySmall.copyWith(color: C.textSecondary),
        ),
        anchor: Anchor.topCenter,
        position: Vector2(chipX + chipSize.x / 2, chipY + chipSize.y + S.x2),
      ),
    );
  }
}

/// The 280x160 card + its live mini diorama — an actual animated component
/// tree (grid tiles + a pulsing beam), not a static image.
class _PreviewCard extends PositionComponent {
  _PreviewCard({required Vector2 size, required Vector2 position})
    : super(size: size, position: position);

  static final _fill = Paint()..color = C.surface2;

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size.toSize(),
        const Radius.circular(R.card),
      ),
      _fill,
    );
  }

  @override
  Future<void> onLoad() async {
    const rows = 3;
    const cols = 4;
    final tile = Vector2(44, 24);
    const gap = S.x1;
    final gridW = cols * tile.x + (cols - 1) * gap;
    final gridH = rows * tile.y + (rows - 1) * gap;
    final origin = Vector2(
      (size.x - gridW) / 2,
      (size.y - gridH) / 2,
    );

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        await add(
          _DioramaTile(
            size: tile.clone(),
            position: origin + Vector2(c * (tile.x + gap), r * (tile.y + gap)),
          ),
        );
      }
    }

    // A bulb on the middle-left tile, feeding a beam across the row.
    final bulbCenter = origin + Vector2(tile.x / 2, tile.y * 1.5 + gap);
    await add(_DioramaBulb(position: bulbCenter));
    await add(
      _DioramaBeam(
        position: Vector2(bulbCenter.x + tile.x / 2, bulbCenter.y - 3),
        length: gridW - tile.x,
      ),
    );
  }
}

class _DioramaTile extends PositionComponent {
  _DioramaTile({required super.size, required super.position});

  static final _fill = Paint()..color = C.gridEmpty;
  static final _border = Paint()
    ..color = C.gridBorder
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  @override
  void render(Canvas canvas) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size.toSize(),
      const Radius.circular(R.tile / 2),
    );
    canvas.drawRRect(rrect, _fill);
    canvas.drawRRect(rrect, _border);
  }
}

class _DioramaBulb extends PositionComponent with FadeableRender {
  _DioramaBulb({required Vector2 position})
    : super(position: position, size: Vector2.all(14), anchor: Anchor.center);

  static final _glow = Paint()
    ..color = C.beamGlow
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final _core = Paint()..color = C.primary;

  @override
  Future<void> onLoad() async {
    add(
      OpacityEffect.to(
        0.5,
        EffectController(
          duration: D.secs(D.beamPulse),
          alternate: true,
          infinite: true,
        ),
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    final c = Offset(size.x / 2, size.y / 2);
    canvas.drawCircle(c, size.x / 2 + 3, _glow);
    canvas.drawCircle(c, size.x / 2, _core);
  }
}

class _DioramaBeam extends PositionComponent with FadeableRender {
  _DioramaBeam({required Vector2 position, required this.length})
    : super(position: position, size: Vector2(1, 6), anchor: Anchor.centerLeft);

  final double length;

  static final _paint = Paint()..color = C.beamCore;

  @override
  Future<void> onLoad() async {
    add(
      OpacityEffect.to(
        0.25,
        EffectController(
          duration: D.secs(D.beamPulse),
          alternate: true,
          infinite: true,
        ),
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, length, size.y),
        const Radius.circular(R.hp),
      ),
      _paint,
    );
  }
}
