/// Shop screen (spec §12, §20) — Tray Slot purchase + Remove Ads card.
library;

import 'dart:ui';

import 'package:flame/components.dart';

import '../../core/layout.dart';
import '../../core/save_store.dart';
import '../../core/tokens.dart';
import '../light_vs_shadow_game.dart';
import 'world_widgets.dart';

/// Coin price of the +2 tray slot upgrade (spec §20). No token category
/// covers in-game prices, so it lives here next to its only use.
const int kTraySlotPrice = 200;

class ShopWorld extends World with HasGameReference<LightVsShadowGame> {
  ShopWorld({required this.onRemoveAdsPressed, required this.onBack});

  final VoidCallback onRemoveAdsPressed;
  final VoidCallback onBack;

  late final WorldButton _traySlotButton;

  @override
  Future<void> onLoad() async {
    final viewSize = kBaselineSize.clone();
    // Shop is L0-L2 only — no ambient glow (spec §12).
    await addMenuBackdrop(
      this,
      viewSize: viewSize,
      layout: game.layout,
      ambient: false,
    );

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
        text: 'SHOP',
        textRenderer: TextPaint(style: T.h1),
        anchor: Anchor.centerLeft,
        position: Vector2(96, S.screenPad + 18),
      ),
    );

    // --- left: tray slot purchase ---------------------------------------
    final btnSize = Vector2(320, 56);
    _traySlotButton = WorldButton(
      size: btnSize.clone(),
      label: _traySlotLabel,
      onPressed: _buyTraySlot,
      background: C.primary,
      textColor: C.onPrimary,
      enabled: _traySlotAvailable,
      position: Vector2(S.screenPad + S.x4, 150),
    );
    await add(_traySlotButton);

    // --- right: remove ads card ------------------------------------------
    final cardSize = Vector2(280, 120);
    final cardPos = Vector2(viewSize.x - cardSize.x - S.screenPad - S.x4, 110);
    await add(
      _RemoveAdsCard(
        size: cardSize,
        position: cardPos,
        onPressed: onRemoveAdsPressed,
      ),
    );
  }

  bool get _traySlotAvailable =>
      SaveStore.I.state.traySlotBonus == 0 &&
      SaveStore.I.state.coins >= kTraySlotPrice;

  String get _traySlotLabel => SaveStore.I.state.traySlotBonus > 0
      ? 'TRAY SLOT +2 — OWNED'
      : 'TRAY SLOT +2 ($kTraySlotPrice COINS)';

  void _buyTraySlot() {
    final save = SaveStore.I.state;
    if (save.traySlotBonus > 0 || save.coins < kTraySlotPrice) return;
    save.coins -= kTraySlotPrice;
    save.traySlotBonus = 2;
    SaveStore.I.flush();
    _traySlotButton
      ..enabled = _traySlotAvailable
      ..setLabel(_traySlotLabel);
  }
}

class _RemoveAdsCard extends PositionComponent {
  _RemoveAdsCard({
    required Vector2 size,
    required Vector2 position,
    required VoidCallback onPressed,
  }) : _onPressed = onPressed,
       super(size: size, position: position);

  final VoidCallback _onPressed;

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
    final owned = SaveStore.I.state.removeAds;
    await add(
      TextComponent(
        text: 'Remove Ads \$2.99',
        textRenderer: TextPaint(style: T.h2),
        position: Vector2(S.cardPad, S.cardPad),
      ),
    );
    await add(
      TextComponent(
        text: 'No banners, no interstitials.',
        textRenderer: TextPaint(
          style: T.bodySmall.copyWith(color: C.textSecondary),
        ),
        position: Vector2(S.cardPad, S.cardPad + 26),
      ),
    );
    await add(
      WorldButton(
        size: Vector2(size.x - S.cardPad * 2, 36),
        label: owned ? 'ADS REMOVED' : 'REMOVE ADS',
        onPressed: _onPressed,
        background: C.primary,
        textColor: C.onPrimary,
        enabled: !owned,
        textStyle: T.bodySmall,
        position: Vector2(S.cardPad, size.y - S.cardPad - 36),
      ),
    );
  }
}
