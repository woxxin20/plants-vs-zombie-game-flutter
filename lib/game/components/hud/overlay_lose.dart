/// Lose overlay — DS-075 / spec §12. Hint + Try Again / Map.
library;

import 'package:flame/components.dart';

import '../../../core/tokens.dart';
import 'button_component.dart';
import 'hud_paint.dart';
import 'overlay_base.dart';

class LoseOverlay extends OverlayDialog {
  LoseOverlay({
    required void Function() onTryAgain,
    required void Function() onMap,
  }) : super(
         cardSize: Vector2(420, 260),
         title: 'DEFEAT',
         titleColor: C.error,
         body: [
           HudLabel(
             'Try more Bulbs early!',
             style: T.body,
             color: C.textSecondary,
             anchor: Anchor.topCenter,
             position: Vector2(210, 64),
           ),
           ...overlayButtons(
             cardWidth: 420,
             top: 110,
             buttons: [
               (
                 label: 'TRY AGAIN',
                 style: GameButtonStyle.primary,
                 onPressed: onTryAgain,
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
}
