---
document: Product Design System and Experience Contract
authority: Visual identity, interaction behavior, tokens, responsive behavior, accessibility
status: Active
owner: "Solo developer (repo owner)"
last_updated: "2026-09-03"
---

# Design — LIGHT vs SHADOW — Prism Defense

This document defines how the product should **look, feel, communicate, and
respond**. It converts product principles into implementation-ready design
rules. Product capability belongs in `prd.md`; technical structure belongs in
`architecture.md`. Source spec: `LIGHT_vs_SHADOW_Prism_Defense_Flame_Spec.md`
("the game spec") — every number below is transcribed from it, not invented.

## 1. Creative North Star

**Design concept:** Neon-lab light optics diorama — a dark study-desk world
where you build tiny glowing machines to bend light and push back living
ink-shadows.

**Experience statement:**
Shadows creep from the right across a desk/notebook toward the player's Light
Core on the left. The player places Lamps, Mirrors, and Prisms to bend light
beams and push the shadows back. The design helps the player *read* a
light-path puzzle at a glance (3 isolated lanes, one glance = one threat
picture) and *feel* every placement as switching on a small real machine —
glow pulse, construction lines, a power-up flash — never as stamping a flat
icon onto a grid. The battlefield is a living diorama (dust motes drifting,
glow pools breathing, shadows wobbling even at idle) that keeps reading as a
real lit place through every screen, not just Battle.

**Three adjectives:** Cozy / Precise / Luminous

**The product should feel like:** A satisfying ASMR maker's desk at 1am —
small glowing machines built by hand, warm light pushing back the dark, in
tight 2-3 minute sessions (game spec §1, §3).

**The product must never feel like:** A generic flat-color mobile puzzle
template, a settings/forms page rendered with sprites on top, or a spammy
tower-defense clone with no optics logic (game spec §4.6).

## 2. Design principles

### `DS-001` — Clear Situation

- **Meaning:** The player must be able to assess threat in the time it takes
  to look at the screen once.
- **Do:** Keep all 3 lanes visible at all times; each lane is a fully
  isolated battle (a shadow in lane 0 never affects lane 1's beams).
- **Do not:** Hide lane state behind a scroll, a tab, or a zoomed-out view.
- **Product source:** Game spec §2, Pillar 1 ("Clear Situation").
- **Verification:** Manual review — a fresh player can name the weakest lane
  within 1 second of looking at the Battle screen.

### `DS-002` — Stable Rhythm

- **Meaning:** Peace, waves, huge wave, and the 50% rule teach the player and
  then test them, on a predictable cadence.
- **Do:** Run the 20s-peace → waves → flagged huge-wave rhythm exactly as
  encoded in `WaveManagerComponent.canSpawnNext()` (game spec §8).
- **Do not:** Spawn waves off a fixed timer alone, or let a huge wave surprise
  the player with no flag indicator in the TopBar.
- **Product source:** Game spec §2, Pillar 2; §8.
- **Verification:** Unit test on `canSpawnNext()` (rules.md §8, item 3).

### `DS-003` — Visible Growth

- **Meaning:** The satisfaction is watching an empty board become a stable
  light net, not only the win screen at the end.
- **Do:** Give every placed tool a breathing idle glow and a visible HP bar
  so the player's built network reads as alive throughout the level.
- **Do not:** Let a tool sit visually inert once placed.
- **Product source:** Game spec §2, Pillar 3; §4.5.
- **Verification:** Visual review against §12 (Motion and feedback) idle-glow
  entries.

### `DS-004` — Pleasantly Frustrating

- **Meaning:** New shadow types are introduced one at a time, in a safe lane
  first, per the level progression table.
- **Do:** Follow the exact per-level-band tool/enemy introduction order in
  §9 Navigation and IA / the level progression table below.
- **Do not:** Introduce two new shadow types in the same level, or introduce
  one in a lane the player cannot yet defend.
- **Product source:** Game spec §2, Pillar 4; §9 (20 Levels Progression).
- **Verification:** Level-JSON review against the progression table before
  each level ships.

### `DS-005` — One More Try

- **Meaning:** Losing must cost as little time as possible.
- **Do:** Instant restart, 0 loading downtime, exactly one rewarded revive
  (Boost) per battle.
- **Do not:** Force a trip back to the Map or an ad before a retry.
- **Product source:** Game spec §2, Pillar 5; §20 (Monetization).
- **Verification:** Manual timing — Lose → Try Again → playing again in under
  1 second of transition time.

### `DS-006` — Real Environment, Not an App

- **Meaning:** Every screen, not just Battle, reads as a lit physical desk,
  never a settings screen.
- **Do:** Apply the L0-L3 backdrop/parallax layers (§4 of the game spec) to
  every screen, including the lightweight Shop/Settings variant.
- **Do not:** Ship a flat solid-color background, a `Icon(Icons.*)`, or any
  screen that could be mistaken for a plain form.
- **Product source:** Game spec §2, Pillar 6; §4.6.
- **Verification:** Visual QA gate item (§16) checked per screen before ship.

## 3. Audience and usage environment

- **Primary user:** Casual mobile puzzle/tower-defense players who want a
  2-3 minute satisfying session, often one-handed, often during a break.
- **Typical context:** Landscape phone/tablet, short bursts, frequently
  offline (commute, airplane mode) — the game must be fully playable with no
  network at all.
- **Likely constraints:** Small touch targets are a real risk on phone-size
  landscape screens (screen height only ~375-420 logical px); attention spans
  are short (par times start at 45s).
- **Primary device/input:** Touch, landscape orientation only.
- **Content density:** Medium — a 3x7 battle grid plus a 220px HUD panel is
  the densest screen; Home/Map/Shop/Settings are low density.

## 4. References and anti-references

| Type | Product/system | Exact element to learn from | What not to copy |
| --- | --- | --- | --- |
| Reference | Plants vs. Zombies | Lane-isolated pressure, drip-feed unlocks, "chaos → stable net" satisfaction loop | Its shooting-based combat (this game uses light optics, not projectiles) |
| Reference | Block Blast | Solo-friendly content scope (small tool/enemy roster, no server), 1-rewarded-ad-per-session cap | Its match-3 board mechanic (not applicable) |
| Anti-reference | Generic flat-fill mobile puzzle templates | The failure mode to avoid: solid-color icons with no glow, gradient, or texture standing in for final art (game spec §4.6) | N/A |
| Anti-reference | Any screen resembling a Material settings/forms page | The failure mode to avoid: this game never uses `Icon(Icons.*)`, `Card`, or flat list rows even for Shop/Settings | N/A |

References are directional, not permission to clone protected assets or create
an inconsistent collage.

## 5. Brand and color system

All tokens below are transcribed verbatim from the game spec §10.1. This
project targets one intentional dark theme; there is no separate light theme
(the "Light" column is not applicable — dark is the only design, per §4 Art
Direction: background must stay near-black so light sources visually pop).

### Color tokens

| DS ID | Token | Hex / Value | Usage |
| --- | --- | --- | --- |
| `DS-007` | `color.bg` | `#0A0E1A` | Root background / L0 backdrop base |
| `DS-008` | `color.surface` | `#141A2E` | TopBar, RightPanel |
| `DS-009` | `color.surface2` | `#1E2642` | Card, Tile occupied |
| `DS-010` | `color.surface3` | `#2A3560` | Border, Divider |
| `DS-011` | `color.primary` | `#FFD23F` | Glow, Beam core, CTA, Selected |
| `DS-012` | `color.primaryDark` | `#FFB300` | CTA pressed |
| `DS-013` | `color.onPrimary` | `#1A1200` | Text on primary |
| `DS-014` | `color.secondary` | `#4FC3F7` | Frost beam |
| `DS-015` | `color.accentPrismG` | Linear gradient `#FF5252 → #FFD740 → #66BB6A → #29B6F6 → #AB47BC` | Prism |
| `DS-016` | `color.success` | `#66BB6A` | Valid, Win |
| `DS-017` | `color.successBg` | `#1B3A2E` | Valid tile fill |
| `DS-018` | `color.successBorder` | `#2E7D5B` | Valid border |
| `DS-019` | `color.error` | `#EF5350` | Invalid, Damage |
| `DS-020` | `color.errorBg` | `#3A1A1A` | Invalid tile fill |
| `DS-021` | `color.errorBorder` | `#7D2E2E` | Invalid border |
| `DS-022` | `color.textPrimary` | `#E8EAF6` | Title, Body |
| `DS-023` | `color.textSecondary` | `#90A4AE` | Sub, Hint |
| `DS-024` | `color.textDisabled` | `#4A5A6A` | Disabled |
| `DS-025` | `color.gridEmpty` | `#1A2340` | Empty tile |
| `DS-026` | `color.gridBorder` | `#2A3560` | Tile border, 1px |
| `DS-027` | `color.shadowBody` | `#2D1B4E` | Enemy body |
| `DS-028` | `color.shadowEye` | `#E040FB` | Eye glow |
| `DS-029` | `color.beamCore` | `#FFD23F` | Beam core stroke, 4px |
| `DS-030` | `color.beamGlow` | `rgba(255,210,63,0.30)` | Beam outer glow, 12px, blur 8 |
| `DS-031` | `color.mirrorMetal` | `#B0BEC5` | Mirror |
| `DS-032` | `color.wallBlock` | `#37474F` | Wall |
| `DS-033` | `color.hpBg` | `rgba(0,0,0,0.40)` | HP bar background |
| `DS-034` | `color.scrim` | `rgba(10,14,26,0.80)` | Pause overlay |
| `DS-035` | `color.scaffoldGradient` | Linear `180deg`, `#0A0E1A` 0% → `#141A2E` 100% | L0 backdrop component background — rendered by the backdrop component's own paint, never a Flutter `Container` decoration |

Rules:

- Components consume the `DS-*` token constant, never a raw hex literal
  (`RULE-FORBID-003`).
- Status never relies on color alone: invalid placement pairs `DS-019`/`020`/
  `021` with a shake `Effect` and an "Occupied"/"Need Bulb"/"Max Prism" toast
  text; HP bars pair color with proportional bar *width* (a numeric signal),
  not color alone; the lane sweep stripe communicates "used" by *disappearing*
  (an `OpacityEffect`), not by changing color alone.
- Every `color.text*`/`color.surface*` pair used for essential text meets
  WCAG 2.2 AA contrast (see §14) — the near-black backgrounds (`DS-007`/
  `008`/`009`) against `DS-022`/`023` are high-contrast by construction.
- This is a single dark-theme product; a light theme is explicitly out of
  scope. Contrast against the warm/cold glow accents (`DS-011`, `DS-014`,
  `DS-015`, `DS-028`) is verified against `DS-007` (near-black) specifically,
  since those accents render on the near-black backdrop, never on `surface2`.

## 6. Typography

All text is rendered via Flame `TextComponent` + `TextPaint(style: TextStyle(...))`
using the locally bundled font files listed in `rules.md` §2 — never a
Material `Text` widget inside the game view.

| DS ID | Style | Font | Size | Line height | Weight | Tracking | Use |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `DS-036` | `type.display` | Orbitron | 32 | 36 | 800 (Black) | 1.5 | Home Title |
| `DS-037` | `type.h1` | Orbitron | 24 | 28 | 700 (Bold) | 0.5 | Section header, Win |
| `DS-038` | `type.h2` | Inter | 18 | 24 | 700 (Bold) | 0 | Tool name |
| `DS-039` | `type.h3` | Inter | 14 | 18 | 600 (Semi) | 0 | Tray name |
| `DS-040` | `type.body` | Inter | 14 | 20 | 400 | 0 | Description |
| `DS-041` | `type.bodySmall` | Inter | 12 | 16 | 400 | 0 | Hint |
| `DS-042` | `type.label` | Inter | 10 | 12 | 600 | 0.8 | COST, WAVE labels |
| `DS-043` | `type.number` | JetBrains Mono | 16 | 20 | 700 | 0 | Glow amount, Damage |
| `DS-044` | `type.numberLg` | JetBrains Mono | 20 | 24 | 700 | 0 | TopBar Glow total |

- Text scaling: honor the OS text-scale factor up to **1.3x**. Read
  `MediaQuery.textScaler` once at boot (and on Settings change), clamp it to
  `[1.0, 1.3]`, and multiply every `TextPaint` `fontSize` token by the clamped
  value when constructing it. Fixed-size HUD containers (tray slot 64x64,
  glow chip 110x32, cost chip) MUST reflow their internal padding or truncate
  with an ellipsis rather than let text overflow their bounds at 1.3x.
- Exactly 3 font families are used project-wide: Orbitron, Inter, JetBrains
  Mono. No fourth family may be added without a `design.md` change first.
- No token here may render at an opacity/contrast low enough to read as a
  placeholder for essential information (`color.textDisabled`, `DS-024`, is
  reserved for genuinely disabled controls only).

## 7. Spacing, shape, elevation, and icons

### Spacing scale

Base unit: **4 px/dp**.

| DS ID | Token | Value | Typical use |
| --- | --- | --- | --- |
| `DS-045` | `space.1` | 4px | Tile gap, tight inline gap |
| `DS-046` | `space.2` | 8px | Related items, chip padding |
| `DS-047` | `space.3` | 12px | Screen padding (landscape), card padding, control padding |
| `DS-048` | `space.4` | 16px | Component gap, dialog padding |
| `DS-049` | `space.5` | 20px | Dialog card padding |
| `DS-050` | `space.6` | 24px | Section inset |
| `DS-051` | `space.7` | 32px | Major separation |
| `DS-052` | `space.8` | 40px | Large control sizing reference |
| `DS-053` | `space.9` | 48px | TopBar height, major separation, min touch target |

Named layout constants that reuse the scale above: screen padding = `space.3`
(12px, not the generic 16px — landscape is tighter); tile gap = `space.1`
(4px); tray gap = `space.5`-adjacent at 10px (see note below — this one value
is a spec-defined exception, not on the 4px scale, kept as `space.trayGap:
10px` since the game spec fixes it explicitly, game spec §11); TopBar height
= `space.9` (48px); RightPanel width = 220px (see §8 layout formula).

### Shape / elevation

| DS ID | Token | Value | Use |
| --- | --- | --- | --- |
| `DS-054` | `radius.card` | 16px | Cards/surfaces |
| `DS-055` | `radius.button` | 16px | Buttons |
| `DS-056` | `radius.tile` | 8px | Grid tiles |
| `DS-057` | `radius.slot` | 12px | Tray slots |
| `DS-058` | `radius.hp` | 2px | HP bars |
| `DS-059` | `radius.chip` | 20px | Chips |
| `DS-060` | `radius.dialog` | 20px | Dialogs/sheets |
| `DS-061` | `elevation.card` | shadow `rgba(0,0,0,0.40)` blur 16, y-offset 4 | Subtle raised surface (cards) |
| `DS-062` | `elevation.button` | shadow `rgba(255,210,63,0.30)` blur 12, y-offset 4 | Overlay/floating control (primary buttons) |
| `DS-063` | `elevation.tool` | shadow `rgba(255,210,63,0.20)` blur 8, y-offset 2 | Placed tool components |
| `DS-064` | `elevation.tile` | flat — no shadow | Grid tiles |

All corner radii are drawn manually via `RRect` in each component's
`render()` — no `BorderRadius`/Material `Card`. Elevation is implemented as a
secondary lower-opacity shadow shape drawn behind the main shape, or via
`Paint()..maskFilter = MaskFilter.blur(...)`.

### Iconography

- `DS-065` — **Iconography rule.** Every icon is hand-drawn as vector `Path`
  draws in a component's `render(Canvas)`: 24px base size, 2px stroke, rounded
  caps. Examples: glow ray-burst, flag pennant, pause bars, sweep arrow, tool
  glyphs (game spec §6). `Icon(Icons.*)` MUST NOT appear anywhere
  (`RULE-FORBID-001`).
- Icons support an adjacent text label whenever their meaning is not
  universal (e.g., the sweep arrow is paired with the lane stripe, not shown
  alone).
- Decorative icons (e.g., the L1 dot-pattern texture) are excluded from any
  accessibility semantics tree — they carry no meaning.
- Emoji and mixed icon families are **forbidden** — every icon in this
  product is the same hand-drawn vector style; no emoji, no third-party icon
  font.

## 8. Layout and responsive behavior

This product supports exactly **one layout mode: Landscape Fixed.** Portrait
is not supported at all (`RULE-FORBID-004`); there is no Compact/Medium/
Expanded breakpoint ladder because the game locks `landscapeLeft` +
`landscapeRight` at boot and stays there.

| Mode | Width | Columns/content max | Gutters | Navigation pattern |
| --- | --- | --- | --- | --- |
| `DS-066` Landscape Fixed (only supported mode) | Any landscape logical width, baseline 812x375, scales up (e.g. 1280x720 tablet) via the formula below | Grid: 3 rows x 7 cols. RightPanel: fixed 220px. No secondary columns. | Screen padding 12px (`space.3`), tile gap 4px (`space.1`), tray gap 10px | Full-screen `World` swap via `go_router`; no bottom nav bar, no rail, no drawer |
| Compact / Medium / Expanded | N/A | N/A | N/A | Out of scope — see `RULE-FORBID-004` |

### Landscape layout formula (exact, from game spec §11)

```dart
double topBarH = 48;
double pad = 12;
double rightW = 220;
double gridH = h - topBarH - pad*2; // 375-48-24=303
double gridW = w - rightW - pad*3;  // 812-220-36=556
double tileH = (gridH - 2*4)/3;
double tileW = (gridW - 6*4)/7;
double tile = min(tileH, tileW);    // square tile size
```

Computed at the 812x375 baseline: `gridH = 303`, `gridW = 556`,
`tileH = (303-8)/3 ≈ 98.3`, `tileW = (556-24)/7 = 76`, so
`tile = min(98.3, 76) = 76px`. (The game spec's own inline comment says
"~72" as a rough approximation next to this formula — 76 is the exact output
of the formula as written and is the authoritative value; see the
contradiction note in this task's final report.) This is computed once per
`onGameResize` and drives `CameraComponent.viewfinder.visibleGameSize`.

### TopBar — 812x48 (HUD, camera-viewport-anchored, never scrolls)

Background `color.surface` (`DS-008`), 1px bottom border `color.surface3`
(`DS-010`).

- **Left — Glow Chip:** `110x32`, bg `color.bg` (`DS-007`), radius 16
  (`DS-059` chip), 1px border `color.surface3`. Row: hand-drawn sunburst
  icon 16px + number `type.numberLg` (`DS-044`) `color.primary` (`DS-011`) +
  `"/200"` at `type.label`-scale 10px `color.textSecondary` (`DS-023`).
  Padding 8px (`DS-046`).
- **Center — Flags row:** 3 dots, 8px each, 8px gap. Inactive =
  `color.textDisabled` (`DS-024`); active = `color.primary` (`DS-011`) with
  a `ScaleEffect` pulse to 1.2 over 400ms. Upcoming flag wave shows a
  hand-drawn 14px flag icon in `color.primary`. Label `"WAVE 2/3"` at Inter
  10px `color.textSecondary`.
- **Right — Pause:** `48x48`, bg `color.surface2` (`DS-009`), radius 12
  (matches `radius.slot`, `DS-057`), 20px hand-drawn pause-bars icon,
  tappable via Flame `TapCallbacks`.

### Grid area

Padding 12px (`space.3`). 3 rows x 7 cols, 4px gap (`space.1`), tiles
`tile x tile` (76px at baseline) centered — rendered by `GridComponent` at
1.0 parallax (L4). Lane divider: dashed `4,4` `rgba(42,53,96,0.6)`
horizontal line, drawn in `GridComponent.render()`. Sweep stripe: leftmost
12px-wide vertical stripe, `rgba(255,210,63,0.15)`, plus a 10px hand-drawn
arrow icon, shown only while that lane's sweep is unused.

### Right Panel — 220px wide (HUD, camera-viewport-anchored)

- **Section 1 — Tray:** title `"TRAY - PICK 1"` at Inter 10px
  `color.textSecondary`; grid of slots `3 cols x 2 rows`, each slot `64x64`,
  10px gap (fits the 220px width). Each slot is a `TraySlotComponent` with
  `TapCallbacks`.
- **Section 2 — Stats:** wave progress bar `200x6`, bg `color.gridEmpty`
  (`DS-025`), radius 3, fill `color.primary` (`DS-011`) at `width%` (driven
  by a `SizeEffect`). HP legend: a row of 2 bars, `48x4` each.
- **Bottom — Boost button:** `200x48`, bg `color.surface3` (`DS-010`),
  radius 12, 1px border `#3A4A6A`. Row: 16px icon `color.primary` + text
  `"+50 GLOW"` Inter 12px 700 + sub-label `"AD 1/1"` at 9px
  `color.textSecondary`. Disabled state drops opacity to 0.4 via an
  `OpacityEffect`.

### Touch and pointer targets

Every interactive component has a minimum **48x48px** hitbox (tray slot at
64px and pause at 48px both already clear this). Implemented via Flame
`TapCallbacks`/`DragCallbacks` mixins on the component itself, never
`GestureDetector`. Horizontal scrolling is never used anywhere in this
product — every screen fits the fixed landscape frame without scrolling.

## 9. Navigation and information architecture

- **Primary destinations:** Home (`SCR-01`), Level Map (`SCR-02`), Loadout
  (`SCR-03`), Battle (`SCR-04`), Shop (`SCR-08`), Settings (`SCR-09`).
- **Hierarchy:** Flat, depth 1 from Home. Home → {Map, Settings}; Map →
  Loadout → Battle; Map → Shop. No screen is nested more than one level below
  Home except the Battle overlays (Pause/Win/Lose), which are depth-2
  HUD-layer overlays on top of Battle, not separate routes.
- **Back behavior:** While `state==playing` in Battle, the platform back
  button/gesture triggers Pause, not navigation (edge case #11, rules.md
  §8.1). Everywhere else, back pops to the previous route in the `go_router`
  stack (typically Map).
- **Deep links:** 7 route entries — `/` (redirect to `/home`), `/home`,
  `/map`, `/loadout/:levelId`, `/battle/:levelId`, `/shop`, `/settings`. All
  routes host the same shared `GameWidget`; only the top-level `World` swaps.
  No route requires authentication (there is none).
- **Current location:** Each screen's own header/title (`type.h1`/`display`)
  names the screen; the TopBar's Wave/Flags row additionally orients the
  player inside Battle specifically.
- **Unsaved work:** Battle progress is never partially saved — a level either
  completes (win, persisted) or is abandoned (no persistence, no
  confirmation dialog needed since restarting is free per `DS-005`).

| Journey | Entry | Steps/screens | Success destination | Recovery path |
| --- | --- | --- | --- | --- |
| `UJ-01` Play a level | Home → Play, or Map → level card | Home/Map → Loadout (pick 6 tools) → Battle → Win/Lose overlay | Win overlay → Next (advances to next level's Loadout) or Map | Lose overlay → Try Again (same Loadout) or Map |
| `UJ-02` Browse and buy | Map → Shop chip, or Home | Shop → buy Tray Slot / Remove Ads | Purchase confirmed, item shown as owned | Cancel returns to Map with no charge |
| `UJ-03` Adjust settings | Home → Settings | Settings → toggle Sound/Haptics/Reset | Toggle takes effect immediately | Back returns to Home, no confirmation needed for toggles |
| `UJ-04` Pause mid-battle | Battle → Pause button or back gesture | Battle → Pause overlay → Resume/Restart/Home | Resume returns to the exact paused frame | Restart resets the current level from `startGlow` |

## 10. Component contract

### `DS-067` — ButtonComponent

- **Purpose:** Every primary/secondary/text call-to-action (Play, Map,
  Settings, Start Battle, Resume, Restart, Home, Replay, Next, Try Again).
- **Do not use for:** Tool selection (use `TraySlotComponent`, `DS-074`) or
  toggles (use `SwitchComponent`, `DS-068`).
- **Variants:** Primary (`color.primary` fill, `color.onPrimary` text,
  `elevation.button` `DS-062`), Secondary (`color.surface3` fill,
  `color.textPrimary` text, no elevation), Text (no fill, `color.textSecondary`
  text).
- **Anatomy:** Background `RRect` (`radius.button` `DS-055`) + centered
  `type.h2`/`h3` label.
- **States:** Default / pressed (`ScaleEffect.to(0.97, 100ms, easeOut)`) /
  disabled (`opacity 0.5`, no tap response).
- **Content rules:** Label is an action verb describing the outcome (e.g.
  "Start Battle", not "Submit"); single line, no wrap.
- **Responsive behavior:** Fixed pixel sizes per screen (e.g. Play 220x56,
  Map/Settings 200x48) — Landscape Fixed is the only mode, so no reflow rule
  is needed.
- **Accessibility:** Minimum 48px tall hitbox on every variant; exposes a
  semantic label matching its visible text for screen readers.
- **Tokens:** `DS-011`/`012`/`013`/`010`/`022`/`023`, `DS-055`, `DS-062`.
- **Implementation primitive:** Flame `PositionComponent` with
  `TapCallbacks`.
- **Test evidence:** Widget/component test asserting hitbox ≥48x48 and tap
  callback firing; visual review against §16.

### `DS-068` — SwitchComponent

- **Purpose:** Boolean settings (Sound, Haptics) on the Settings screen.
- **Do not use for:** Anything with more than two states.
- **Variants:** On / off only.
- **Anatomy:** Track (rounded rect) + thumb (circle), thumb position driven
  by a `MoveEffect`.
- **States:** On (`color.primary` `DS-011` active track) / off
  (`color.surface3` `DS-010` track) / disabled (0.4 opacity, Reset Progress
  during an active reset action).
- **Content rules:** Always paired with an adjacent text label — never used
  standalone.
- **Responsive behavior:** Fixed size, single layout mode.
- **Accessibility:** ≥48x48 hitbox around the visible track; state is
  announced by adjacent label text changing/persisting, not by color alone.
- **Tokens:** `DS-011`, `DS-010`.
- **Implementation primitive:** `PositionComponent` with `TapCallbacks`.
- **Test evidence:** Toggle test asserting the bound settings value flips.

### `DS-069` — ToastComponent

- **Purpose:** Transient placement-failure feedback ("Occupied", "Need
  Bulb", "Max Prism").
- **Do not use for:** Persistent errors or anything requiring user action.
- **Variants:** Single variant, error-tinted text.
- **Anatomy:** `type.bodySmall`-scale (10px) text in `color.error` (`DS-019`),
  added to the HUD viewport, auto-removed after 800ms.
- **States:** Appear (fade/slide in) → hold → auto-dismiss.
- **Content rules:** 1-3 words, states the specific reason the placement
  failed (never a generic "Error").
- **Responsive behavior:** Anchored near the grid, fixed layout.
- **Accessibility:** Never the sole signal of failure — always accompanies
  a tile shake (`RULE-UI-006`).
- **Tokens:** `DS-019`, `DS-041`.
- **Implementation primitive:** `TextComponent` + `TextPaint`, added/removed
  from `camera.viewport`.
- **Test evidence:** Unit test on `tryPlace()` failure paths asserting the
  correct toast reason is dispatched (rules.md §8, item 2).

### `DS-070` — LoadingStateComponent

- **Purpose:** Shown while JSON levels/tools/shadows and audio preload at
  boot (game spec §24 Performance).
- **Do not use for:** Anything after boot — there is no other async loading
  path (no network).
- **Variants:** Single variant.
- **Anatomy:** Centered `type.h2` "LOADING..." label + a manually drawn
  progress arc (reuses the cooldown-ring drawing technique from
  `DS-074`/§12).
- **States:** Loading → complete (fades into Home).
- **Content rules:** No percentage number required (load is near-instant with
  bundled assets); a simple looping arc is sufficient.
- **Responsive behavior:** Fixed layout mode.
- **Accessibility:** Not focus-trapping; screen reader announces "Loading".
- **Tokens:** `DS-011`, `DS-037`.
- **Implementation primitive:** `World`-level loading gate before `Home`
  routes become reachable.
- **Test evidence:** Manual QA — cold boot never shows an unstyled blank
  frame.

### `DS-071` — LevelCardComponent

- **Purpose:** One card per level on the Level Map (`SCR-02`).
- **Do not use for:** Tool selection (`DS-074`).
- **Variants:** Locked / unlocked-unplayed / unlocked-starred (1-3 stars).
- **Anatomy:** `110x90` card (`radius.card` `DS-054`, `elevation.card`
  `DS-061`), level number (`type.h2`), 0-3 star glyphs, lock icon overlay
  when locked.
- **States:** Default / pressed (`ScaleEffect` 0.97) / locked (dimmed,
  `opacity` reduced, tap disabled).
- **Content rules:** Level number always visible even when locked (locked
  state hides content behind the number, not the number itself).
- **Responsive behavior:** Grid `5 cols x 4 rows`, 12px gap, fixed layout.
- **Accessibility:** ≥48x48 hitbox (card exceeds this already); locked state
  communicated by icon + reduced opacity, never opacity alone.
- **Tokens:** `DS-054`, `DS-061`, `DS-011` (stars), `DS-024` (locked).
- **Implementation primitive:** `PositionComponent` with `TapCallbacks`.
- **Test evidence:** Tap-on-locked-card test asserting no navigation occurs.

### `DS-072` — TopBarComponent

- **Purpose:** Persistent Battle HUD header (Glow chip, Flags, Pause).
- **Do not use for:** Non-Battle screens (Home/Map/etc. use their own
  simpler headers).
- **Variants:** Single variant; see §8 TopBar spec for exact anatomy.
- **Anatomy:** See §8.
- **States:** Static except the animated flag-pulse and live glow number.
- **Content rules:** Glow number is always the authoritative live value
  (never stale between frames).
- **Responsive behavior:** Camera-viewport-anchored; never scrolls or
  reflows.
- **Accessibility:** Pause button ≥48x48; glow chip is read-only (no tap
  target needed).
- **Tokens:** `DS-008`, `DS-010`, `DS-011`, `DS-023`, `DS-009`, `DS-053`.
- **Implementation primitive:** `PositionComponent` added to
  `camera.viewport`.
- **Test evidence:** Manual QA — glow number matches `BattleState.glow`
  every frame.

### `DS-073` — RightPanelComponent

- **Purpose:** Battle HUD side panel (Tray, Stats, Boost).
- **Do not use for:** Non-Battle screens.
- **Variants:** Single variant; see §8 Right Panel spec.
- **Anatomy:** See §8.
- **States:** Boost button disabled state (0.4 opacity) after use or with no
  ad available.
- **Content rules:** Tray always shows exactly the 6 tools picked in
  Loadout, in picked order.
- **Responsive behavior:** Camera-viewport-anchored, fixed 220px width.
- **Accessibility:** Every slot/button inside meets 48x48 independently.
- **Tokens:** `DS-008`, `DS-025`, `DS-011`, `DS-010`.
- **Implementation primitive:** `PositionComponent` added to
  `camera.viewport`.
- **Test evidence:** Manual QA against §8.

### `DS-074` — TraySlotComponent

- **Purpose:** One selectable tool slot in the Battle tray (up to 6) and the
  Loadout tool grid (up to 8).
- **Do not use for:** Anything other than tool selection.
- **Variants:** Available / selected (border `ColorEffect` to `color.primary`)
  / on-cooldown (dark overlay 75% + countdown number `DS-043` + a manually
  drawn circular progress arc, 2px stroke `color.primary`, sweeping 360°→0°) /
  disabled (not picked for this loadout).
- **Anatomy:** `64x64` (Battle tray) or `76x96` (Loadout grid) slot, tool
  glyph, cost label (`DS-042`), cooldown ring overlay when active.
- **States:** Default / selected / cooldown / disabled.
- **Content rules:** Cost is always shown even while on cooldown.
- **Responsive behavior:** Fixed grid (`3x2` Battle tray gap 10px, `4x2`
  Loadout grid gap 12px).
- **Accessibility:** 64px/76px hitbox both exceed the 48px minimum; cooldown
  state is communicated by the numeric countdown, not the dark overlay alone.
- **Tokens:** `DS-011`, `DS-009`, `DS-057`, `DS-042`, `DS-043`.
- **Implementation primitive:** `PositionComponent` with `TapCallbacks` /
  `DragCallbacks`.
- **Test evidence:** Unit test on cooldown-gating in `tryPlace()` (rules.md
  §8, item 2).

### `DS-075` — OverlayDialogComponent (Pause / Win / Lose)

- **Purpose:** Modal HUD-layer overlays that composite over a paused
  `World` without stopping rendering (`world`'s `update()` pauses via engine
  pause logic, not the render tree).
- **Do not use for:** Any non-modal HUD element.
- **Variants:** Pause (`360x220`), Win (`420x260`), Lose (same as Win, red
  accent).
- **Anatomy:** Full-screen `color.scrim` (`DS-034`, 0.80 opacity) rect behind
  a centered card (`radius.dialog` `DS-060`, `color.surface2` `DS-009`,
  padding 20px `DS-049`), title (`type.h1`/`Orbitron`), body content per
  variant (buttons for Pause; stars + coins + confetti for Win; hint text +
  retry for Lose), button row.
- **States:** Enter (fade/scale in) → held → exit (dismissed by a button
  tap).
- **Content rules:** Win: `"VICTORY"` in `color.success` (`DS-016`). Lose:
  `"DEFEAT"` in `color.error` (`DS-019`) plus the hint `"Try more Bulbs
  early!"` (`DS-041`). Pause: `"PAUSED"`.
- **Responsive behavior:** Centered, fixed size, single layout mode.
- **Accessibility:** All buttons inside meet 48px height; the scrim traps
  taps from reaching the paused world underneath.
- **Tokens:** `DS-034`, `DS-060`, `DS-009`, `DS-049`, `DS-037`, `DS-016`,
  `DS-019`.
- **Implementation primitive:** `PositionComponent` group added/removed from
  the HUD `OverlayLayer` on demand (not a Flutter dialog).
- **Test evidence:** State-machine test asserting `state` transitions to
  `won`/`lost`/`paused` show the correct overlay variant.

### `DS-076` — GridComponent / TileComponent

- **Purpose:** The 3x7 battle grid and its 21 individually tappable tiles.
- **Do not use for:** Any non-Battle grid-like layout (Loadout's tool grid
  uses `DS-074` instead).
- **Variants:** Tile: empty / occupied / valid-highlight (`color.successBg`
  `DS-017`/`color.successBorder` `DS-018`) / invalid-highlight
  (`color.errorBg` `DS-020`/`color.errorBorder` `DS-021`).
- **Anatomy:** 21 `TileComponent` children of one `GridComponent`, each
  `tile x tile` (76px baseline), border 1px `color.gridBorder` (`DS-026`),
  fill `color.gridEmpty` (`DS-025`), radius 8 (`DS-056`).
- **States:** Default / hover-highlight / invalid-shake (`MoveByEffect`
  ±4px, 80ms, alternate).
- **Content rules:** N/A (no text).
- **Responsive behavior:** Tile size is computed by the §8 formula on every
  `onGameResize`.
- **Accessibility:** Each tile individually exceeds 48x48 at every supported
  size (baseline 76px).
- **Tokens:** `DS-025`, `DS-026`, `DS-056`, `DS-017`, `DS-018`, `DS-020`,
  `DS-021`.
- **Implementation primitive:** `PositionComponent` with `TapCallbacks`/
  `DragCallbacks` per tile.
- **Test evidence:** Unit test on `tryPlace()` bounds/occupied checks
  (rules.md §8, item 2).

### `DS-077` — ToolComponent (base class, 8 tools)

- **Purpose:** Every placed defender (Bulb, Beam Lamp, Mirror, Prism, Frost
  Lens, Wall, Bomb, Twin Bulb).
- **Do not use for:** Shadows (`DS-078`) or beams (`DS-080`).
- **Variants:** 8 concrete subclasses per the game spec §6 table (exact
  cost/cooldown/HP/damage per tool — see that table, transcribed unchanged
  since it is a gameplay-balance fact owned by the game spec, not a design
  token).
- **Anatomy:** 40x40 hand-drawn vector body (visible construction lines,
  rivets, seams, a lens highlight) + a child HP bar (`32x4`, `radius.hp`
  `DS-058`, bg `color.hpBg` `DS-033`, fill green `>50%` `color.success`
  `DS-016` → yellow `25-50%` `color.primary` `DS-011` → red `<25%`
  `color.error` `DS-019`) + a placement power-up flash.
- **States:** Idle-breathing (`ScaleEffect` loop 1.0→1.08, 3000ms) / firing /
  damaged (HP bar shrinks via `SizeEffect`, 200ms linear) / destroyed
  (dissolve, not an instant pop).
- **Content rules:** N/A (no text on the tool itself; cost/name shown only
  on its tray slot).
- **Responsive behavior:** Scales with `tile` size from §8.
- **Accessibility:** Placement/removal only via the grid tile's own tap
  target, not the tool body directly.
- **Tokens:** `DS-011`, `DS-016`, `DS-019`, `DS-033`, `DS-058`, `DS-063`.
- **Implementation primitive:** `PositionComponent` subclass with
  `CollisionCallbacks` where relevant (e.g. beam-emitting tools).
- **Test evidence:** Placement/cooldown/HP unit tests (rules.md §8, items
  1-2).

### `DS-078` — ShadowComponent (base class, 5 enemies)

- **Purpose:** Every enemy (Shade, Helm Shade, Leaper, Veil, Colossus).
- **Do not use for:** Tools (`DS-077`).
- **Variants:** 5 concrete subclasses per the game spec §7 table (exact
  HP/speed/eat rate/special per enemy — gameplay-balance fact owned by the
  game spec).
- **Anatomy:** Soft-edged ink-blot silhouette (blurred alpha falloff, not a
  hard vector edge) + sharp saturated eyes (`color.shadowEye` `DS-028`) + a
  child HP bar (`24x4`, offset `y-18`, same gradient rule as `DS-077`).
- **States:** Walking (sine-driven bob) / eating (paused walk, eating-loop
  `Effect`) / slowed (Frost hit, 50% speed for 2s) / dying (dissolve into
  6-10 smoke particles, upward drift + fade, never an instant
  `removeFromParent()` with no visual).
- **Content rules:** N/A.
- **Responsive behavior:** Scales with `tile` size; base 32x32 (44x44 for
  Colossus).
- **Accessibility:** Not directly interactive (no tap target — shadows are
  never tapped by the player).
- **Tokens:** `DS-027`, `DS-028`, `DS-033`, `DS-016`, `DS-011`, `DS-019`.
- **Implementation primitive:** `PositionComponent` with `CollisionCallbacks`
  + `RectangleHitbox`.
- **Test evidence:** Beam-hit and death-particle unit/behavior tests
  (rules.md §8, item 1).

### `DS-079` — BeamComponent

- **Purpose:** Renders each active traced light-ray segment (game spec §15).
- **Do not use for:** Anything not produced by the beam trace algorithm.
- **Variants:** Warm (`color.beamCore` `DS-029`, player light), cold
  (`color.secondary` `DS-014`, frost), prism-split (per-branch color per
  game spec §15 trace pseudocode).
- **Anatomy:** Core stroke 4px + outer glow 12px `rgba(...,0.30)` blur 8,
  glow layer drawn first, core drawn on top.
- **States:** Active (`OpacityEffect` pulse loop 1.0→0.7→1.0, 600ms) / idle
  (not rendered when no beam resolves).
- **Content rules:** N/A.
- **Responsive behavior:** Recomputed only when placement/removal/death
  changes grid topology (not every frame) — see `retraceAllBeamsIfDirty()`.
- **Accessibility:** N/A (non-interactive visual).
- **Tokens:** `DS-029`, `DS-030`, `DS-014`.
- **Implementation primitive:** `PositionComponent`, reused/updated in place
  per active ray rather than destroyed and recreated every frame.
- **Test evidence:** Beam trace unit tests (rules.md §8, item 1).

### `DS-080` — GlowOrbComponent

- **Purpose:** Falling collectible glow, spawned every 8.0s (max 2 on
  screen).
- **Do not use for:** Bulb-generated glow (that is a silent counter
  increment, no on-screen orb).
- **Variants:** Single variant.
- **Anatomy:** Small glowing circle, falls from `y=-20` to grid `y` over 2s
  (`MoveEffect`, `easeIn`).
- **States:** Falling → collected (tap radius 40px, triggers
  `CollectParticle`) → removed. Uncollected orbs simply reach the grid and
  stop being interactive after the fall (they do not vanish uncollected —
  see accessibility note).
- **Content rules:** N/A.
- **Responsive behavior:** `x = random(0, gridW)` at spawn.
- **Accessibility:** 40px tap radius exceeds the 48px *diameter* minimum
  only marginally at 80px total — treat 40px radius as the accepted
  exception for a fast-moving collectible, not a static control.
- **Tokens:** `DS-011`.
- **Implementation primitive:** `PositionComponent` with `TapCallbacks`.
- **Test evidence:** Manual QA — max-2-on-screen cap holds under rapid
  spawns.

### `DS-081` — GlowChipComponent

- **Purpose:** TopBar left glow-total display. See §8 TopBar spec for full
  anatomy.
- **Do not use for:** Any other numeric display.
- **Variants:** Single variant.
- **Anatomy:** See §8.
- **States:** Live value only (read-only, no interaction states).
- **Content rules:** Clamped to 999 max (game spec §24 edge case #17).
- **Responsive behavior:** Fixed 110x32, camera-viewport-anchored.
- **Accessibility:** Read-only, no tap target required.
- **Tokens:** `DS-007`, `DS-059`, `DS-010`, `DS-044`, `DS-011`, `DS-023`.
- **Implementation primitive:** `PositionComponent` on `camera.viewport`.
- **Test evidence:** Unit test asserting glow display clamps at 999.

### `DS-082` — FlagsRowComponent

- **Purpose:** TopBar center wave/flag indicator. See §8 TopBar spec.
- **Do not use for:** Any other progress indicator.
- **Variants:** Single variant, 3-dot row.
- **Anatomy:** See §8.
- **States:** Inactive dot / active dot (pulsing) / upcoming-flag dot (flag
  icon).
- **Content rules:** `"WAVE X/Y"` label always matches `waveIndex`/total.
- **Responsive behavior:** Fixed, camera-viewport-anchored.
- **Accessibility:** Read-only.
- **Tokens:** `DS-024`, `DS-011`, `DS-023`.
- **Implementation primitive:** `PositionComponent` on `camera.viewport`.
- **Test evidence:** Manual QA against `waveIndex` state.

### `DS-083` — SweepStripeComponent

- **Purpose:** Per-lane "lawnmower" indicator on the grid's left edge.
- **Do not use for:** Anything else.
- **Variants:** Unused (visible stripe + arrow) / used (removed via
  `OpacityEffect`).
- **Anatomy:** 12px-wide vertical stripe `rgba(255,210,63,0.15)` + 10px
  hand-drawn arrow.
- **States:** Idle → triggered (auto, when a shadow reaches `x<=12`) →
  removed.
- **Content rules:** N/A.
- **Responsive behavior:** Height matches lane height.
- **Accessibility:** Presence/absence itself is the status signal (not
  color alone), satisfying `RULE-UI-006`.
- **Tokens:** `DS-011`.
- **Implementation primitive:** `PositionComponent`, child of
  `GridComponent`.
- **Test evidence:** Sweep-trigger unit test (rules.md §8, item 3 area /
  edge case #12).

### `DS-084` — BoostButtonComponent

- **Purpose:** RightPanel rewarded-ad "+50 Glow" button. See §8 spec.
- **Do not use for:** Any other ad surface.
- **Variants:** Enabled / disabled (`opacity 0.4` via `OpacityEffect`).
- **Anatomy:** See §8.
- **States:** Enabled → tapped (shows rewarded ad) → consumed (disabled for
  the rest of the battle, cap 1 per battle).
- **Content rules:** Sub-label always shows the remaining count, e.g.
  `"AD 1/1"` before use, and reflects `"AD 0/1"`-equivalent (disabled state)
  after.
- **Responsive behavior:** Fixed `200x48`.
- **Accessibility:** ≥48px tall; disabled state communicated by opacity
  *and* the sub-label count, not opacity alone.
- **Tokens:** `DS-010`, `DS-011`.
- **Implementation primitive:** `PositionComponent` with `TapCallbacks`,
  child of `RightPanelComponent`.
- **Test evidence:** Manual QA — cannot be tapped twice in one battle.

Minimum inventory note: this product has no text-input fields anywhere (no
forms), so the template's "input" category is **N/A** — every control here
is a tap target, a toggle, or a read-only display.

## 11. Screen template

### Home — `SCR-01`

- **Purpose / journey:** `UJ-01`, `UJ-03`; entry point for every session.
- **Entry conditions:** App boot, after `DS-070` loading completes.
- **Primary action:** Play (large primary button).
- **Information hierarchy:** Title → tagline → Play/Map/Settings buttons →
  live mini-diorama preview → Daily chip.
- **Components:** `DS-067` (buttons), `DS-006`-style L0-L3 backdrop, a live
  nested mini `World` (3x4 grid diorama with idle animated beams — not a
  static image, per game spec §12).
- **States:** Loading (`DS-070`) / content (only meaningful state — Home has
  no empty/error/offline variant since it needs no data).
- **Responsive behavior:** Single Landscape Fixed layout.
- **Accessibility:** Title announced as the screen heading; all 3 buttons
  meet 48px height.
- **Analytics:** None (no analytics SDK in this offline product).
- **Exit/recovery:** N/A — Home has no failure state to recover from.

### Level Map — `SCR-02`

- **Purpose / journey:** `UJ-01`.
- **Entry conditions:** From Home → Map, or back-navigation from Loadout.
- **Primary action:** Tap an unlocked level card.
- **Information hierarchy:** Header (`"LEVELS"` + coin chip) → 5x4 level
  card grid (`DS-071`).
- **Components:** `DS-071`.
- **States:** Content only (levels are bundled JSON, always available
  offline — no loading/error/offline state needed here beyond the shared
  boot-time `DS-070`).
- **Responsive behavior:** Single layout mode.
- **Accessibility:** Locked cards are excluded from tap handling but remain
  visible/announced as locked.
- **Analytics:** None.
- **Exit/recovery:** Back returns to Home.

### Loadout — `SCR-03`

- **Purpose / journey:** `UJ-01`.
- **Entry conditions:** From Map, level card tapped.
- **Primary action:** Start Battle (enabled only once exactly 6 tools are
  picked).
- **Information hierarchy:** Left Scout panel (`"INCOMING"` enemy preview) →
  Right tool grid (`DS-074`, up to 8, pick 6) → bottom Start Battle button.
- **Components:** `DS-074`, `DS-067` (Start Battle).
- **States:** Content / validation (Start Battle stays disabled at 0.5
  opacity until exactly 6 are selected — this *is* the validation-error
  state for this screen).
- **Responsive behavior:** Two fixed panels (`340w` Scout / remainder tool
  grid), 1px divider `color.surface3`, single layout mode.
- **Accessibility:** Picked-count `"Picked 6/6"` label is the non-color
  signal that Start Battle is ready.
- **Analytics:** None.
- **Exit/recovery:** Back returns to Map with no picks saved (Loadout picks
  are per-attempt, not persisted).

### Battle — `SCR-04`

- **Purpose / journey:** `UJ-01`, `UJ-04`; the core gameplay screen.
- **Entry conditions:** Start Battle tapped in Loadout with 6 tools picked.
- **Primary action:** Place a tool on a valid tile (no single primary
  action dominates — this is the sustained-play screen).
- **Information hierarchy:** TopBar (`DS-072`) → Grid (`DS-076`) with
  tools/shadows/beams (`DS-077`/`078`/`079`) → RightPanel (`DS-073`).
- **Components:** `DS-072`, `DS-073`, `DS-074`, `DS-076`, `DS-077`,
  `DS-078`, `DS-079`, `DS-080`, `DS-083`, `DS-084`.
- **States:** playing / paused (`DS-075` Pause variant) / won (`DS-075` Win
  variant) / lost (`DS-075` Lose variant, preceded by a `MoveByEffect`
  camera-viewfinder shake, ±4px x3, 300ms).
- **Responsive behavior:** Full §8 layout formula applies here specifically
  (it is the only screen using the grid).
- **Accessibility:** Every placement is reachable via a single tap-select →
  tap-place sequence (no drag is required to complete the core loop, though
  drag is also supported).
- **Analytics:** None.
- **Exit/recovery:** Pause → Home returns to Map without saving mid-battle
  progress (nothing to lose — restarting is free per `DS-005`). Lose → Try
  Again restarts the same level instantly.

### Pause Overlay — `SCR-05`

- **Purpose / journey:** `UJ-04`.
- **Entry conditions:** Pause button tapped, or back gesture while playing.
- **Primary action:** Resume.
- **Information hierarchy:** `"PAUSED"` title → Resume (primary) → Restart
  (secondary) → Home (text).
- **Components:** `DS-075` (Pause variant), `DS-067`.
- **States:** Shown/hidden only (world underneath is frozen, not
  re-rendered with new state while this overlay is up).
- **Responsive behavior:** Centered `360x220` card, single layout mode.
- **Accessibility:** Focus/first tap target is Resume; scrim blocks taps to
  the frozen world beneath.
- **Analytics:** None.
- **Exit/recovery:** Resume unfreezes at the exact paused frame; Restart
  resets `glow`/`waveIndex`/grid to the level's `startGlow` state; Home exits
  to Map.

### Win Dialog — `SCR-06`

- **Purpose / journey:** `UJ-01` success path.
- **Entry conditions:** `state==won` (all waves spawned, no shadows remain).
- **Primary action:** Next (advances to the following level's Loadout).
- **Information hierarchy:** `"VICTORY"` (`color.success`) → 3 stars
  (staggered `ScaleEffect` 120ms apart, `0→1.2→1`, 400ms `backOut`) → coins
  chip (`"+20 coins"` or the computed delta) → Replay/Next buttons, with a
  `ConfettiParticle` burst (12 particles, 800ms fall) behind the card.
- **Components:** `DS-075` (Win variant), `DS-067`.
- **States:** Entry animation → settled/interactive.
- **Responsive behavior:** Centered `420x260` card, single layout mode.
- **Accessibility:** Star count is also stated numerically (not stars-only)
  so it is not color/shape alone conveying the score.
- **Analytics:** None.
- **Exit/recovery:** Replay restarts the same level; Next advances.

### Lose Overlay — `SCR-07`

- **Purpose / journey:** `UJ-01` failure path.
- **Entry conditions:** `state==lost` (a shadow reached `x<=0` in a
  swept-out lane).
- **Primary action:** Try Again.
- **Information hierarchy:** `"DEFEAT"` (`color.error`) → hint text
  `"Try more Bulbs early!"` → Try Again (primary).
- **Components:** `DS-075` (Lose variant), `DS-067`.
- **States:** Entry (after camera shake) → settled/interactive.
- **Responsive behavior:** Same card frame as Win, single layout mode.
- **Accessibility:** Hint text is concrete/actionable, not a vague "You
  lost".
- **Analytics:** None.
- **Exit/recovery:** Try Again restarts the same level immediately (0
  downtime, `DS-005`).

### Shop — `SCR-08`

- **Purpose / journey:** `UJ-02`.
- **Entry conditions:** From Map or Home.
- **Primary action:** Buy (Tray Slot +2, or Remove Ads).
- **Information hierarchy:** Left list (Tray Slot +2, 200 coins) → Right
  card (Remove Ads, $2.99, `280x120` `color.surface2`).
- **Components:** `DS-067` (buy buttons).
- **States:** Content / owned (button becomes disabled once purchased,
  labeled "Owned" rather than just grayed out).
- **Responsive behavior:** Lightweight L0-L2 backdrop only (no gameplay
  layers), single layout mode.
- **Accessibility:** "Owned" state communicated by label text change, not
  opacity alone.
- **Analytics:** None.
- **Exit/recovery:** Back returns to Map/Home; a failed/cancelled IAP simply
  leaves the button in its pre-purchase state, no error dialog needed beyond
  the platform's own purchase-flow UI.

### Settings — `SCR-09`

- **Purpose / journey:** `UJ-03`.
- **Entry conditions:** From Home.
- **Primary action:** None singular — a settings list of independent
  toggles/actions.
- **Information hierarchy:** Sound toggle → Haptics toggle → Reset Progress
  action.
- **Components:** `DS-068` (Sound, Haptics), `DS-067` (Reset Progress, as a
  destructive text/secondary button).
- **States:** Content only; Reset Progress shows a confirmation step
  (destructive action, per rules.md §7) before it clears Hive data.
- **Responsive behavior:** Lightweight L0-L2 backdrop only, single layout
  mode.
- **Accessibility:** Reset Progress names the exact consequence in its
  confirmation copy ("This clears all stars, coins, and unlocks — this
  cannot be undone").
- **Analytics:** None.
- **Exit/recovery:** Back returns to Home; confirmation dialog's Cancel
  leaves all data untouched.

## 12. Motion and feedback

All motion is implemented via Flame `Effect` classes (`RULE-FORBID-002`) —
never a hand-rolled `AnimationController` inside the game view.

| Token | Duration/easing | Use | Reduced-motion behavior |
| --- | --- | --- | --- |
| `motion.fast` | 80-220ms, mostly `easeOut`/`elasticOut` | Micro feedback: button press (100ms), tool placement pop (220ms `elasticOut`), tile invalid shake (80ms), cost pulse red (300ms) | **Replace:** snap instantly to the end state (no scale/shake animation), but keep the accompanying particle burst/toast since those carry information, not just polish |
| `motion.standard` | 200-600ms | State/layout change: HP bar width change (200ms linear), beam pulse loop (600ms), flag pulse (400ms) | **Replace:** HP bar snaps to new width instantly; looping pulses (beam, flag, idle breathing) are suppressed and rendered at a fixed mid-value instead of animating |
| `motion.emphasis` | 300-800ms | Rare transitions: win stars stagger (400ms `backOut`, 120ms stagger), confetti (800ms fall), lose camera shake (300ms) | **Remove:** camera-viewfinder shake is disabled entirely; stars and confetti fade in together with no stagger and no motion, coins/score are still fully legible immediately |

- Motion explains continuity, causality, or status (a shake means "invalid",
  a pulse means "this is the active flag wave"); it is not decoration by
  default.
- No essential content or action depends on animation completing — e.g. the
  win screen's stars/coins values are correct and readable even if reduced
  motion skips their entrance animation.
- Reduced motion is read once from `MediaQuery.of(context).disableAnimations`
  (or the platform accessibility "reduce motion" setting) at boot and on
  Settings change, stored as a single boolean flag read by every component
  that adds a looping or emphasis-tier `Effect`.
- Haptics/audio require purpose, user control (the Settings toggles,
  `DS-068`), and a platform-appropriate fallback (silently no-op if the
  platform lacks haptics).
- Loading feedback (`DS-070`) begins immediately at boot, before any asset
  finishes loading — there is no scenario in this offline product where a
  load exceeds a couple of seconds, so no cancel affordance is needed.

### 12.1 Full animation timing table (game spec §18.2, §23)

| Use | Effect | Params |
| --- | --- | --- |
| Tool placement pop | `ScaleEffect.to` | `Vector2.all(1.0)` from 0, `elasticOut`, 220ms |
| Idle breathing glow (Bulb, ambient glow pools) | `ScaleEffect.to` (looping, `infinite: true, alternate: true`) | `1.0 → 1.08`, 3000ms |
| Beam pulse | `OpacityEffect.to` (looping) | `1.0 → 0.7 → 1.0`, 600ms |
| Shadow walk bob | Custom sine driver in `update()` | `translateY sin(time*2.5)*2` |
| HP bar width change | `SizeEffect.to` | width = hp%, 200ms linear |
| Tile invalid shake | `MoveByEffect` (alternate) | `±4px`, 80ms |
| Cost pulse red | `ColorEffect` | to `#EF5350`, 300ms, alternate |
| Win stars stagger | `ScaleEffect.to` chained via `SequenceEffect`, staggered `onComplete` per star | `0 → 1.2 → 1`, 400ms, `backOut`, 120ms stagger |
| Lose shake | `MoveByEffect` on `camera.viewfinder` | `±4px x3`, 300ms |
| Button press | `ScaleEffect.to` | `0.97`, 100ms, `easeOut` |
| Tray slot cooldown ring | Manual `render()` arc draw driven by a `TimerComponent` | 360° → 0° |

### 12.2 Particle inventory (game spec §18.1 — all `ParticleSystemComponent`, pooled)

| Name | Trigger | Particle count | Behavior | Life |
| --- | --- | --- | --- | --- |
| `DustMoteParticle` | Always running (ambient, L2) | 12-18 | Slow random-walk drift, wraps at grid edges | Infinite loop |
| `PlaceParticle` | Tool placed | 6 | Burst outward 24px, fade | 120ms |
| `CollectParticle` | Glow orb / bulb tick collected | 8 | Burst + upward drift, gold | 200ms |
| `SparkParticle` | Beam hits shadow | 6 | Outward 24px, `#FFD23F` | 180ms |
| `SweepParticle` | Lane sweep triggers | 20 | Radial burst along lane, wide spread | 500ms |
| `DeathDissolveParticle` | Shadow dies | 6-10 | Upward drift + fade, smoke-colored per §4.4 | 400ms |
| `ExplosionParticle` | Flash Bomb detonates | 30 | Radial 3x3-tile burst, `#FFD23F` → `#EF5350` | 400ms |
| `ConfettiParticle` | Win dialog | 12 | Fall from top, rotate, mixed palette | 800ms |
| `LeapDustParticle` | Jumper leaps a wall | 4 | Small puff at takeoff + landing points | 200ms |

Pooling discipline: high-frequency particles (`SparkParticle`,
`CollectParticle`) MUST be drawn from a small reusable `EffectPool<T>` rather
than freshly allocated per trigger, to hold the <50-draw-call/frame budget
(rules.md §9) on low-end Android.

### 12.3 Sound files (`assets/audio/`, played via `FlameAudio.play(...)`, preloaded via `FlameAudio.audioCache.loadAll([...])` at boot)

| File | Duration | Character |
| --- | --- | --- |
| `place.mp3` | 120ms | Plop |
| `collect.mp3` | 200ms | Sparkle |
| `shoot.mp3` | 150ms | Zap |
| `hit.mp3` | 100ms | Thud |
| `explosion.mp3` | 400ms | Boom |
| `win.mp3` | 800ms | Chime |
| `lose.mp3` | 600ms | Buzz |
| `sweep.mp3` | 500ms | Whoosh |

### 12.4 Haptic mapping (only fires if the Haptics setting, `DS-068`, is on)

| Trigger | Haptic |
| --- | --- |
| Tool placed | `mediumImpact()` |
| Beam hits shadow | `lightImpact()` |
| Win | `heavyImpact()` |
| Invalid placement | `vibrate(50ms)` |
| Lane sweep triggers | `heavyImpact()` |

## 13. Content and voice

- **Voice:** Terse, confident, action-oriented — short toast/hint strings,
  no filler ("Occupied", "Need Bulb", "Try more Bulbs early!").
- **Reading level/technical depth:** Casual mobile-game reading level; no
  jargon beyond the game's own tool/enemy names.
- **Buttons:** Action verbs describing outcome — "Play", "Start Battle",
  "Resume", "Restart", "Replay", "Next", "Try Again" — never a generic
  "Submit"/"OK".
- **Errors/toasts:** State the exact reason placement failed and nothing
  else — `"Occupied"`, `"Need Bulb"`, `"Max Prism"` (game spec §17). No
  stack traces or internal state are ever shown to the player.
- **Empty states:** Not applicable — every screen's data is bundled and
  always present offline; the closest analogue (Shop item already owned)
  uses an "Owned" label rather than an empty-state message.
- **Dates/numbers/names:** Coins/glow/HP are always plain integers, no
  locale-specific formatting needed (no thousands separators — values are
  capped at 999 for glow, small integers elsewhere).
- **Destructive actions:** "Reset Progress" (Settings) names the exact
  consequence and requires explicit confirmation before it clears the Hive
  `Save` box (rules.md §7).

## 14. Accessibility baseline

- **Standard/target:** WCAG 2.2 AA, applied to a hand-rendered Flame Canvas
  (no native semantics tree exists for most gameplay elements, so contrast
  and target-size rules are enforced by design review rather than an
  automated a11y scanner for the Battle screen specifically).
- **Color contrast:** 4.5:1 minimum for body/label text against its
  background token, 3:1 minimum for large text (≥18px, e.g. `type.h1`/
  `display`) and essential icons/status shapes. `color.textPrimary`
  (`DS-022`, `#E8EAF6`) and `color.textSecondary` (`DS-023`, `#90A4AE`)
  against `color.bg`/`surface`/`surface2` (`DS-007`/`008`/`009`, all
  near-black) clear this by a wide margin by construction; any new
  text/background pairing MUST be checked against this same 4.5:1/3:1 bar
  before it ships.
- **Text scaling/zoom:** Support OS text scale up to **1.3x** (§6);
  fixed-size HUD containers reflow padding or ellipsis rather than clip.
- **Input alternatives:** Touch is the only supported input (no keyboard/
  controller path is in scope for MVP); every tap target meets the 48x48
  minimum (§8) via `TapCallbacks`/`DragCallbacks`.
- **Focus order and visible focus:** Not applicable in the traditional
  sense (no keyboard focus ring in a touch-only Canvas game); the "current
  location" signal is the screen title/TopBar state instead (§9).
- **Dynamic announcements:** Placement failures always pair a toast
  (`DS-069`) with a shake — never a silent color change alone
  (`RULE-UI-006`). Win/Lose state changes are paired with both a visual
  overlay and audio/haptic cue (§12.3, §12.4), not visuals alone.
- **Images/media:** No raster images ship in MVP — every visual is
  hand-drawn vector in `render(Canvas)` (game spec §21), so there is no
  alt-text surface; decorative particle/backdrop layers are marked
  non-semantic.
- **Motion/flashing:** Reduced-motion behavior is defined per motion tier in
  §12; no effect in this product flashes faster than 3 times per second
  (the fastest repeating effect, the beam pulse, cycles at 600ms — well
  under the photosensitive-seizure threshold).
- **Cognitive accessibility:** Plain, consistent language across all
  toasts/dialogs (§13); Pause is always one tap away during Battle; no
  session-ending timeout exists — a paused game stays paused indefinitely.

## 15. Asset policy

- **Source/ownership/license:** No raster images ship in MVP — every visual
  (tools, shadows, icons, backgrounds) is hand-drawn vector `Path`/`Canvas`
  code inside each component's `render()` (game spec §21, `assets/images/`
  is empty by design). Font files (Orbitron, Inter, JetBrains Mono) are
  open-source (SIL Open Font License) and MUST be bundled locally under
  `assets/fonts/` with their license file retained (rules.md §2).
- **Required formats, dimensions, compression, dark-mode variants,
  naming:** Audio: `.mp3`, mono, durations exactly as listed in §12.3, named
  by trigger (`place.mp3`, `collect.mp3`, etc.) under `assets/audio/`. Level/
  tool/shadow data: `.json` under `assets/levels/` and `assets/`, schema per
  the game spec §22. No dark-mode variants are needed — this product has one
  intentional dark theme only (§5).
- **Raster/vector selection:** Vector (`Canvas` draws) for every visual
  asset — matches the runtime-performance need to redraw/recolor without
  shipping per-state image variants, and matches the "hand-drawn machine,
  not a sticker" art direction (game spec §4.5).
- Do not ship placeholders, watermarked assets, or unlicensed brand marks.
- **Asset size budgets:** Audio files stay under 500KB total (they're all
  ≤800ms clips); JSON level data stays under 5KB per level file; font files
  follow their upstream OFL package sizes as-is (no custom subsetting
  planned for MVP).

## 16. Design QA gate

- [ ] Screen matches its mapped journey (§9 `UJ-*`) and screen template
      (§11).
- [ ] Only approved `DS-*` tokens/components are used — no arbitrary hex,
      px, or duration literals (`RULE-UI-001`, `RULE-FORBID-003`).
- [ ] All states and recovery paths listed in §11 are present.
- [ ] Landscape Fixed layout, safe-area, and 1.3x text-scale behavior pass
      (§8, §6).
- [ ] Contrast, target size (≥48x48), and reduced-motion behavior pass
      (§14, §12).
- [ ] Content is final and matches the voice/copy rules in §13 — no
      placeholder data remains.
- [ ] Visual regression/golden evidence is updated intentionally.
- [ ] Deviations are recorded in `audit.md`; material design changes update
      this file first.

## 17. Change log

| Date | DS IDs/section | Reason | PRD/task links | Owner |
| --- | --- | --- | --- | --- |
| 2026-09-03 | `DS-001`..`DS-084`, full document | Initial design contract filled in from the Flame game spec (§4, §10, §11, §12, §18, §23); zero `[REQUIRED: ...]` placeholders remain | Game spec §2-§23 | Solo developer (repo owner) |
