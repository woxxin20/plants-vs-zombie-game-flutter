/// Win overlay — DS-075 / spec §12. Shows stars + coins, then Map / Next.
library;

import 'package:flame/components.dart';

import '../../../core/tokens.dart';
import 'button_component.dart';
import 'hud_paint.dart';
import 'overlay_base.dart';

class WinOverlay extends OverlayDialog {
  WinOverlay({
    required this.stars,
    required this.coins,
    required void Function() onMap,
    required void Function() onNext,
  }) : super(
         cardSize: Vector2(420, 260),
         title: 'VICTORY',
         titleColor: C.success,
         body: [
           HudLabel(
             '$stars STAR${stars == 1 ? '' : 'S'}  ·  +$coins COINS',
             style: T.h3,
             color: C.textPrimary,
             anchor: Anchor.topCenter,
             position: Vector2(210, 64),
           ),
           ...overlayButtons(
             cardWidth: 420,
             top: 110,
             buttons: [
               (
                 label: 'NEXT',
                 style: GameButtonStyle.primary,
                 onPressed: onNext,
               ),
               (
                 label: 'MAP',
                 style: GameButtonStyle.secondary,
                 onPressed: onMap,
               ),
             ],
           ),
         ],
       );

  final int stars;
  final int coins;
}
