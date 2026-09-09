/// Design tokens — the ONLY source of colour, spacing, radius and type in this
/// project. See docs/design.md (DS-*) and RULE-UI-001: components must never
/// hard-code a literal colour, gap, radius or duration.
///
/// Deliberately imports `dart:ui` and `package:flutter/painting.dart` only —
/// never material.dart / cupertino.dart (RULE-FORBID-001).
library;

import 'package:flutter/painting.dart';

// ---------------------------------------------------------------------------
// Colours — spec §10.1
// ---------------------------------------------------------------------------

abstract final class C {
  static const bg = Color(0xFF0A0E1A);
  static const surface = Color(0xFF141A2E);
  static const surface2 = Color(0xFF1E2642);
  static const surface3 = Color(0xFF2A3560);

  static const primary = Color(0xFFFFD23F);
  static const primaryDark = Color(0xFFFFB300);
  static const onPrimary = Color(0xFF1A1200);
  static const secondary = Color(0xFF4FC3F7);

  /// Prism split gradient, left→right.
  static const prismSpectrum = <Color>[
    Color(0xFFFF5252),
    Color(0xFFFFD740),
    Color(0xFF66BB6A),
    Color(0xFF29B6F6),
    Color(0xFFAB47BC),
  ];

  static const success = Color(0xFF66BB6A);
  static const successBg = Color(0xFF1B3A2E);
  static const successBorder = Color(0xFF2E7D5B);

  static const error = Color(0xFFEF5350);
  static const errorBg = Color(0xFF3A1A1A);
  static const errorBorder = Color(0xFF7D2E2E);

  static const textPrimary = Color(0xFFE8EAF6);
  static const textSecondary = Color(0xFF90A4AE);
  static const textDisabled = Color(0xFF4A5A6A);

  static const gridEmpty = Color(0xFF1A2340);
  static const gridBorder = Color(0xFF2A3560);

  static const shadowBody = Color(0xFF2D1B4E);
  static const shadowBorder = Color(0xFF4A2E7A);
  static const shadowEye = Color(0xFFE040FB);

  static const beamCore = Color(0xFFFFD23F);
  static const beamGlow = Color(0x4DFFD23F); // rgba(255,210,63,0.30)

  static const mirrorMetal = Color(0xFFB0BEC5);
  static const mirrorEdge = Color(0xFF78909C);
  static const wallBlock = Color(0xFF37474F);
  static const wallMortar = Color(0xFF263238);

  static const hpBg = Color(0x66000000); // rgba(0,0,0,0.40)
  static const scrim = Color(0xCC0A0E1A); // rgba(10,14,26,0.80)

  static const sweepStripe = Color(0x26FFD23F); // rgba(255,210,63,0.15)
  static const laneDivider = Color(0x992A3560); // rgba(42,53,96,0.6)

  /// Backdrop gradient, 180deg.
  static const backdropTop = Color(0xFF0A0E1A);
  static const backdropBottom = Color(0xFF141A2E);

  /// HP bar fill by remaining fraction — spec §6 HP Bar.
  static Color hpFill(double fraction) {
    if (fraction > 0.5) return success;
    if (fraction >= 0.25) return primary;
    return error;
  }
}

// ---------------------------------------------------------------------------
// Spacing / sizing — spec §10.3, 4px base
// ---------------------------------------------------------------------------

abstract final class S {
  static const x1 = 4.0;
  static const x2 = 8.0;
  static const x3 = 12.0;
  static const x4 = 16.0;
  static const x5 = 20.0;
  static const x6 = 24.0;
  static const x8 = 32.0;
  static const x10 = 40.0;
  static const x12 = 48.0;

  /// Landscape screen padding is 12, not 16.
  static const screenPad = 12.0;
  static const cardPad = 12.0;
  static const tileGap = 4.0;
  static const trayGap = 10.0;

  static const topBarH = 48.0;
  static const rightPanelW = 220.0;

  /// Minimum interactive hitbox on every axis (DS accessibility contract).
  static const minTouch = 48.0;
}

abstract final class R {
  static const card = 16.0;
  static const button = 16.0;
  static const tile = 8.0;
  static const slot = 12.0;
  static const hp = 2.0;
  static const chip = 20.0;
  static const dialog = 20.0;
}

// ---------------------------------------------------------------------------
// Elevation — spec §10.4. Drawn as a blurred copy behind the shape.
// ---------------------------------------------------------------------------

class Elevation {
  const Elevation(this.color, this.blur, this.dy);
  final Color color;
  final double blur;
  final double dy;

  static const card = Elevation(Color(0x66000000), 16, 4);
  static const button = Elevation(Color(0x4DFFD23F), 12, 4);
  static const tool = Elevation(Color(0x33FFD23F), 8, 2);
}

// ---------------------------------------------------------------------------
// Typography — spec §10.2
//
// ADR-005: the spec names Orbitron / Inter / JetBrainsMono via GoogleFonts, but
// the product is offline-first (PRD-NFR: playable in airplane mode), so runtime
// font fetching is forbidden. The three families are now BUNDLED as variable
// TTFs under assets/fonts/ (SIL OFL 1.1, licence text alongside) and declared in
// pubspec.yaml, so `F.bundled` is true and these names resolve. Do not add the
// google_fonts package. Closes ARCH-Q-001 / AUD-002.
// ---------------------------------------------------------------------------

abstract final class F {
  static const display = 'Orbitron';
  static const heading = 'Orbitron';
  static const ui = 'Inter';
  static const mono = 'JetBrainsMono';

  /// True since 2026-09-09: assets/fonts/ ships all three families.
  static const bundled = true;

  static String? family(String name) => bundled ? name : null;
}

abstract final class T {
  static TextStyle _s(
    String fam,
    double size,
    FontWeight weight,
    double lineHeight,
    double letterSpacing, {
    Color color = C.textPrimary,
  }) => TextStyle(
    fontFamily: F.family(fam),
    fontSize: size,
    fontWeight: weight,
    height: lineHeight / size,
    letterSpacing: letterSpacing,
    color: color,
  );

  static final display = _s(F.display, 32, FontWeight.w800, 36, 1.5);
  static final h1 = _s(F.heading, 24, FontWeight.w700, 28, 0.5);
  static final h2 = _s(F.ui, 18, FontWeight.w700, 24, 0);
  static final h3 = _s(F.ui, 14, FontWeight.w600, 18, 0);
  static final body = _s(F.ui, 14, FontWeight.w400, 20, 0);
  static final bodySmall = _s(F.ui, 12, FontWeight.w400, 16, 0);
  static final label = _s(
    F.ui,
    10,
    FontWeight.w600,
    12,
    0.8,
    color: C.textSecondary,
  );
  static final number = _s(F.mono, 16, FontWeight.w700, 20, 0);
  static final numberLg = _s(F.mono, 20, FontWeight.w700, 24, 0);
}

// ---------------------------------------------------------------------------
// Motion — spec §23. Durations live here so RULE-UI-001 holds for timings too.
// ---------------------------------------------------------------------------

abstract final class D {
  static const place = Duration(milliseconds: 220);
  static const buttonPress = Duration(milliseconds: 100);
  static const beamPulse = Duration(milliseconds: 600);

  /// Idle breathing cycle shared by bulbs and the ambient glow pools.
  static const breathe = Duration(seconds: 3);
  static const hpLerp = Duration(milliseconds: 200);
  static const bob = Duration(milliseconds: 400);
  static const winStar = Duration(milliseconds: 400);
  static const winStarStagger = Duration(milliseconds: 120);
  static const loseShake = Duration(milliseconds: 300);
  static const glowFall = Duration(seconds: 2);
  static const toast = Duration(milliseconds: 1400);

  static double secs(Duration d) => d.inMicroseconds / 1e6;
}
