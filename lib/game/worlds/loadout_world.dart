/// Loadout screen (spec §9, §12) — Scout panel + tool tray picker.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../../core/layout.dart';
import '../../core/save_store.dart';
import '../../core/tokens.dart';
import '../../data/content.dart';
import '../../data/models.dart';
import '../light_vs_shadow_game.dart';
import 'world_widgets.dart';

/// Display names for the scout list — the JSON only has ids (spec §9/§22).
const _shadowNames = <String, String>{
  'basic': 'Shade',
  'bucket': 'Helm Shade',
  'jumper': 'Leaper',
  'fog': 'Veil',
  'giant': 'Colossus',
};

class LoadoutWorld extends World with HasGameReference<LightVsShadowGame> {
  LoadoutWorld({
    required this.levelId,
    required this.onStart,
    required this.onBack,
  });

  final int levelId;
  final void Function(List<String> picked) onStart;
  final VoidCallback onBack;

  final Set<String> _selected = {};
  final List<_ToolSlot> _slots = [];
  late final WorldButton _startButton;
  late final TextComponent _pickedLabel;
  late final int _trayLimit;

  @override
  Future<void> onLoad() async {
    final viewSize = kBaselineSize.clone();
    await addMenuBackdrop(this, viewSize: viewSize, layout: game.layout);

    final level = Content.I.level(levelId);
    final save = SaveStore.I.state;
    _trayLimit = kTrayLimit + save.traySlotBonus;

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

    // --- Scout panel -------------------------------------------------
    final panelSize = Vector2(340, 351);
    final panelPos = Vector2(S.screenPad, S.screenPad);
    await add(_ScoutPanel(size: panelSize, position: panelPos, level: level));

    // --- centre divider -----------------------------------------------
    final dividerX = panelPos.x + panelSize.x + S.screenPad;
    await add(
      _Divider(
        position: Vector2(dividerX, S.screenPad),
        height: viewSize.y - S.screenPad * 2,
      ),
    );

    // --- tool grid ------------------------------------------------------
    final rightX = dividerX + 1 + S.screenPad;
    final rightW = viewSize.x - rightX - S.screenPad;

    _pickedLabel = TextComponent(
      text: 'PICKED 0/$_trayLimit',
      textRenderer: TextPaint(style: T.h3),
      position: Vector2(rightX, S.screenPad),
    );
    await add(_pickedLabel);

    final unlockedTools = level.availableTools
        .where(save.unlocked.contains)
        .toList(growable: false);

    final slotSize = Vector2(76, 96);
    const cols = 4;
    const gap = S.x3;
    final gridW = cols * slotSize.x + (cols - 1) * gap;
    final gridOrigin = Vector2(
      rightX + (rightW - gridW) / 2,
      60,
    );

    for (var i = 0; i < unlockedTools.length; i++) {
      final tool = Content.I.tool(unlockedTools[i]);
      final row = i ~/ cols;
      final col = i % cols;
      final slot = _ToolSlot(
        tool: tool,
        position: gridOrigin + Vector2(col * (slotSize.x + gap), row * (slotSize.y + gap)),
        onTap: _toggle,
      );
      _slots.add(slot);
      await add(slot);
    }

    // --- start battle button --------------------------------------------
    final startSize = Vector2(260, 56);
    _startButton = WorldButton(
      size: startSize.clone(),
      label: 'START BATTLE',
      onPressed: () => onStart(_selected.toList(growable: false)),
      background: C.primary,
      textColor: C.onPrimary,
      enabled: false,
      position: Vector2(
        rightX + (rightW - startSize.x) / 2,
        viewSize.y - S.screenPad - startSize.y,
      ),
    );
    await add(_startButton);
  }

  void _toggle(String toolId) {
    if (_selected.contains(toolId)) {
      _selected.remove(toolId);
    } else {
      if (_selected.length >= _trayLimit) return;
      _selected.add(toolId);
    }
    for (final slot in _slots) {
      slot.selected = _selected.contains(slot.tool.id);
    }
    _pickedLabel.text = 'PICKED ${_selected.length}/$_trayLimit';
    _startButton.enabled = _selected.length == _trayLimit;
  }
}

class _Divider extends PositionComponent {
  _Divider({required Vector2 position, required double height})
    : super(position: position, size: Vector2(1, height));

  static final _paint = Paint()..color = C.gridBorder;

  @override
  void render(Canvas canvas) =>
      canvas.drawRect(Offset.zero & size.toSize(), _paint);
}

class _ScoutPanel extends PositionComponent {
  _ScoutPanel({
    required Vector2 size,
    required Vector2 position,
    required this.level,
  }) : super(size: size, position: position);

  final Level level;

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
    final pad = S.cardPad;
    await add(
      TextComponent(
        text: 'INCOMING',
        textRenderer: TextPaint(style: T.label),
        position: Vector2(pad, pad),
      ),
    );

    var y = pad + 24.0;
    for (final entry in level.incoming.entries) {
      await add(_ShadowIcon(position: Vector2(pad, y)));
      await add(
        TextComponent(
          text: _shadowNames[entry.key] ?? entry.key,
          textRenderer: TextPaint(style: T.body),
          anchor: Anchor.centerLeft,
          position: Vector2(pad + 32, y + 12),
        ),
      );
      await add(
        TextComponent(
          text: 'x${entry.value}',
          textRenderer: TextPaint(style: T.number),
          anchor: Anchor.centerRight,
          position: Vector2(size.x - pad, y + 12),
        ),
      );
      y += 32;
    }
  }
}

/// Generic 24px hand-drawn shadow silhouette (spec §9) — differentiated by
/// the name label next to it rather than per-species art.
class _ShadowIcon extends PositionComponent {
  _ShadowIcon({required Vector2 position})
    : super(position: position, size: Vector2.all(24));

  static final _body = Paint()..color = C.shadowBody;
  static final _border = Paint()
    ..color = C.shadowBorder
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  static final _eye = Paint()..color = C.shadowEye;

  @override
  void render(Canvas canvas) {
    final c = Offset(size.x / 2, size.y / 2);
    canvas.drawCircle(c, size.x / 2 - 1, _body);
    canvas.drawCircle(c, size.x / 2 - 1, _border);
    canvas.drawCircle(Offset(c.dx - 4, c.dy - 1), 1.6, _eye);
    canvas.drawCircle(Offset(c.dx + 4, c.dy - 1), 1.6, _eye);
  }
}

class _ToolSlot extends PositionComponent with TapCallbacks {
  _ToolSlot({
    required this.tool,
    required Vector2 position,
    required this.onTap,
  }) : super(position: position, size: Vector2(76, 96));

  final ToolDef tool;
  final void Function(String toolId) onTap;

  bool selected = false;

  static final _border = Paint()..style = PaintingStyle.stroke..strokeWidth = 2;
  static final _fill = Paint();

  @override
  Future<void> onLoad() async {
    await add(
      TextComponent(
        text: tool.id[0].toUpperCase() + tool.id.substring(1),
        textRenderer: TextPaint(style: T.bodySmall),
        anchor: Anchor.topCenter,
        position: Vector2(size.x / 2, 62),
      ),
    );
    await add(
      TextComponent(
        text: '${tool.cost}',
        textRenderer: TextPaint(style: T.label),
        anchor: Anchor.topCenter,
        position: Vector2(size.x / 2, 78),
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size.toSize(),
      const Radius.circular(R.slot),
    );
    canvas.drawRRect(rrect, _fill..color = selected ? C.surface3 : C.surface2);
    canvas.drawRRect(
      rrect,
      _border..color = selected ? C.primary : C.gridBorder,
    );
    _drawGlyph(canvas, Offset(size.x / 2, 32));
  }

  void _drawGlyph(Canvas canvas, Offset c) {
    switch (tool.id) {
      case 'bulb':
        canvas.drawCircle(c, 14, Paint()..color = C.beamGlow);
        canvas.drawCircle(c, 9, Paint()..color = C.primary);
      case 'beam':
        canvas.drawRect(
          Rect.fromCenter(center: c, width: 16, height: 8),
          Paint()..color = C.textPrimary,
        );
        canvas.drawPath(
          Path()
            ..moveTo(c.dx + 8, c.dy - 6)
            ..lineTo(c.dx + 20, c.dy)
            ..lineTo(c.dx + 8, c.dy + 6)
            ..close(),
          Paint()..color = C.primary,
        );
      case 'mirror':
        canvas.drawPath(
          Path()
            ..moveTo(c.dx, c.dy - 12)
            ..lineTo(c.dx + 12, c.dy)
            ..lineTo(c.dx, c.dy + 12)
            ..lineTo(c.dx - 12, c.dy)
            ..close(),
          Paint()..color = C.mirrorMetal,
        );
      case 'prism':
        final colors = C.prismSpectrum;
        canvas.drawPath(
          Path()
            ..moveTo(c.dx, c.dy - 12)
            ..lineTo(c.dx + 12, c.dy + 10)
            ..lineTo(c.dx - 12, c.dy + 10)
            ..close(),
          Paint()
            ..shader = Gradient.linear(
              Offset(c.dx - 12, c.dy),
              Offset(c.dx + 12, c.dy),
              colors,
            ),
        );
      case 'frost':
        final p = Paint()
          ..color = C.secondary
          ..strokeWidth = 2;
        for (var i = 0; i < 6; i++) {
          final a = i * math.pi / 3;
          canvas.drawLine(
            c,
            Offset(c.dx + 12 * math.cos(a), c.dy + 12 * math.sin(a)),
            p,
          );
        }
      case 'wall':
        final p = Paint()..color = C.wallBlock;
        canvas.drawRect(Rect.fromCenter(center: c, width: 20, height: 20), p);
        canvas.drawLine(
          Offset(c.dx - 10, c.dy),
          Offset(c.dx + 10, c.dy),
          Paint()
            ..color = C.wallMortar
            ..strokeWidth = 2,
        );
      case 'bomb':
        canvas.drawCircle(c, 10, Paint()..color = C.primary);
        canvas.drawLine(
          Offset(c.dx + 6, c.dy - 8),
          Offset(c.dx + 12, c.dy - 16),
          Paint()
            ..color = C.error
            ..strokeWidth = 2,
        );
      case 'twin':
        canvas.drawCircle(
          Offset(c.dx - 5, c.dy),
          8,
          Paint()..color = C.primary.withValues(alpha: 0.8),
        );
        canvas.drawCircle(
          Offset(c.dx + 5, c.dy),
          8,
          Paint()..color = C.primary.withValues(alpha: 0.8),
        );
      default:
        canvas.drawCircle(c, 10, Paint()..color = C.textDisabled);
    }
  }

  @override
  void onTapUp(TapUpEvent event) => onTap(tool.id);
}
