/// Pause overlay — DS-075 / spec §12. Resume / Restart / Home.
library;

import 'package:flame/components.dart';

import '../../../core/tokens.dart';
import 'button_component.dart';
import 'overlay_base.dart';

class PauseOverlay extends OverlayDialog {
  PauseOverlay({
    required void Function() onResume,
    required void Function() onRestart,
    required void Function() onHome,
  }) : super(
         cardSize: Vector2(360, 220),
         title: 'PAUSED',
         titleColor: C.textPrimary,
         body: overlayButtons(
           cardWidth: 360,
           top: 56,
           buttons: [
             (
               label: 'RESUME',
               style: GameButtonStyle.primary,
               onPressed: onResume,
             ),
             (
               label: 'RESTART',
               style: GameButtonStyle.secondary,
               onPressed: onRestart,
             ),
             (label: 'HOME', style: GameButtonStyle.text, onPressed: onHome),
           ],
         ),
       );
}
