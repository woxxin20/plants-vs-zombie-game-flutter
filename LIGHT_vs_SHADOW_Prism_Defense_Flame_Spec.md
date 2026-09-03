# LIGHT vs SHADOW — Prism Defense
## Complete Game Design & Technical Specification — FLAME ENGINE EDITION
### Landscape Only | 1 Developer | No Backend | Flutter + Flame | Offline First
---
**Version:** 2.0 (Flame Rebuild)
**Date:** 2026-09-03
**Platform:** Flutter + Flame (Android, iOS, Web, Desktop)
**Orientation:** LANDSCAPE ONLY (landscapeLeft + landscapeRight, immersiveSticky)
**Backend:** NONE — 100% Offline, Hive + Bundled JSON
**Engine:** Flame (`flame`, `flame_audio`, `flame_riverpod`) — full component architecture, no Material3, no Cupertino
**Target Session:** 2–3 min / level | 20 Levels | 4–5 Weeks Solo Build (Flame learning curve adds ~1 week vs pure-widget build)

---

## WHY FLAME (Read This First)

This is a full rebuild of the original pure-Flutter-widgets spec into a **Flame component architecture**. The reasoning, stated plainly so nobody re-litigates it mid-build:

- **Flame does not give you an art style.** No engine does. The neon-lab, dark-desk, light-optics look is 100% the responsibility of §9 (Art Direction) below — hand-drawn/custom-rendered assets, palette, lighting language. Flame is the *rendering and composition layer* that makes that art style easier to *stage* — camera, parallax, particles, effects — not the source of it.
- **What Flame earns its keep on:** `CameraComponent` + `World` for real parallax depth (desk background → dust motes → grid → foreground vignette), `ParticleSystemComponent` for pooled embers/sparks/glow trails, the `Effects` API for juice (scale/color/move sequences) instead of hand-rolled `AnimationController`s, and `CollisionCallbacks` for beam-hits-shadow detection.
- **Zero Material3 / Cupertino anywhere.** Every screen — Home, Map, Loadout, Battle, Shop, Settings, Pause, Win/Lose — is built as Flame components (or a custom Flutter widget tree with zero Material/Cupertino widgets — plain `Container`, `CustomPaint`, `GestureDetector`, no `MaterialApp`, no `Scaffold`, no `ElevatedButton` etc). App root uses `WidgetsApp` (not `MaterialApp`), and all screens render through Flame's `GameWidget` or fully custom Flutter widgets with hand-painted visuals.
- **Cost accepted:** +1 week solo build time for the component architecture, camera/parallax rig, and effects wiring versus the pure-widget version. Build plan (§21) reflects this.

---

## TABLE OF CONTENTS
1. [Executive Summary](#1-executive-summary)
2. [Design Pillars (PvZ Type Feeling)](#2-design-pillars)
3. [Core Loop & Win/Lose](#3-core-loop)
4. [Art Direction — Visual Language](#4-art-direction)
5. [Grid & Economy](#5-grid-economy)
6. [Tools — 8 Defenders Detailed](#6-tools)
7. [Shadows — 5 Enemies Detailed](#7-shadows)
8. [Wave System & 50% Rule](#8-wave-system)
9. [20 Levels Progression](#9-levels)
10. [UI Theme — Colors, Typography, Spacing](#10-ui-theme)
11. [Landscape Layout — Pixel Exact](#11-landscape-layout)
12. [All Screens — Flame Component Wireframes](#12-screens)
13. [Flame Architecture — Component Tree](#13-flame-architecture)
14. [Camera, World & Parallax Layers](#14-camera-parallax)
15. [Beam Optics Algorithm — Full Logic](#15-beam-logic)
16. [Battle Tick — Full Update Logic](#16-battle-tick)
17. [Placement Validation — All Conditions](#17-placement)
18. [Particles & Effects System](#18-particles-effects)
19. [Stars, Coins & Persistence](#19-persistence)
20. [Monetization — No Backend](#20-monetization)
21. [Tech Stack & Project Structure](#21-tech-stack)
22. [Data Models & JSON Schema](#22-data-models)
23. [Animations, Sound, Haptics](#23-animations)
24. [Edge Cases & QA Checklist](#24-qa)
25. [Build Order For AI — Phase Plan](#25-build-order)
26. [FlameGame Bootstrap Code Snippet](#26-bootstrap)
27. [AI Generation Prompt](#27-ai-prompt)

---

## 1. Executive Summary

**Premise:** Shadows creep from the right across a desk/notebook toward your Light Core on the left. Place Lamps, Mirrors, Prisms to bend light beams and push them back.

**Why This Type (Not PvZ Clone):** Keeps PvZ's addictive `chaos → stable net` satisfaction (`resource tension + lane-isolated battles + drip-feed unlocks`) but replaces shooting with **light optics**: Mirror reflects 90°, Prism splits 1 beam into 3 lanes. Placement = light-path puzzle, not spam.

**Solo Proof:** Uses proven solo patterns: 3 lanes x 7 tiles (not 5x9), 8 tools (not 48), 20 levels JSON, 100% offline (Quads pattern: deterministic daily via dayOfYear, Hive save). Flame component architecture so 1 dev can still ship in 4-5 weeks with real depth/juice. No physics server, no multiplayer, no login.

**Impact:** Cozy dark-lab + neon light ASMR is viral on TikTok/Reels (satisfying glow), puzzle = 53% of all mobile ad revenue 2026, Block sub-genre 10% (#1). Flame's parallax + particle layer pushes this from "satisfying" to "showreel-worthy" for organic social clips.

---

## 2. Design Pillars

1.  **Clear Situation:** 3 lanes visible at all times, each lane is an isolated battle. Player sees threat in 1 second.
2.  **Stable Rhythm:** 20s peace → waves → huge wave → 50% rule. Teaches then tests. Like PvZ.
3.  **Visible Growth:** From empty board to stable light net. Satisfaction is process, not just win.
4.  **Pleasantly Frustrating:** New shadow every 2 levels, introduced in safe lane first, then mixed.
5.  **One More Try:** Instant restart, 0 downtime, 1 rewarded revive per battle cap (Block Blast rule).
6.  **Real Environment, Not an App:** Parallax desk world, dust motes, bloom/glow, ambient particle life even at idle — the battlefield reads as a living diorama, never a settings screen.

---

## 3. Core Loop

**Loop Steps (repeats every 8-10s):**
1. Collect Glow (falling + Bulb generates)
2. Spend Glow to place tool on empty tile
3. Bulb generates more Glow (investment)
4. Lamp fires beam → Mirror/Prism bends → Shadows take damage/slow
5. Observe which lane is weak → place Wall/Boost
6. Save Flash Bomb for huge wave
7. Survive all flags → Win stars + coins → Unlock next level + tool

**Lose:** Shadow `x <= 0` AND `sweep[lane]==false` (already used)
**Win:** `allWavesSpawned==true && shadows.isEmpty`

---

## 4. Art Direction — Visual Language

This section exists because an engine choice does not create an art style — this does. Every asset, effect, and layer below must be followed for the game to read as a real environment rather than a UI screen with sprites on it.

### 4.1 World Concept
The battle takes place on a **dark wooden desk at night**, lit only by a single desk lamp off-frame and the glow of the player's tools. Think: study-desk diorama, blueprint-paper grid, tiny glowing machines. Not a flat colored background — a *place*.

### 4.2 Depth Layers (back to front, all via Flame `World` + `CameraComponent`, see §14)
| Layer | Content | Parallax Factor | Notes |
|---|---|---|---|
| L0 Backdrop | Near-black gradient vignette `#05070D → #0A0E1A`, soft radial glow center-left (implied lamp off-frame) | 0.0 (static) | `PositionComponent` behind camera, never scrolls |
| L1 Desk Texture | Subtle wood-grain / blueprint-grid texture, very low contrast, hand-painted noise, NOT a stock texture | 0.05 | Barely visible, gives "surface" feeling |
| L2 Dust Motes | 12-18 tiny circular particles `rgba(255,210,63,0.08-0.15)`, radius 1-3px, drifting slow random walk, looping | 0.15 | `ParticleSystemComponent`, infinite generator, always running even at menu/idle |
| L3 Ambient Glow Pools | 2-3 large soft blurred radial gradients near Bulbs/Lamps, breathing scale `1.0→1.08→1.0` 3s loop | 0.3 | Reinforces "this is a lit environment," not flat fill |
| L4 Grid & Tiles | The 3x7 battle grid itself | 1.0 (camera-locked) | See §11 |
| L5 Tools & Shadows | All placed tools, all enemies, beams | 1.0 | Gameplay layer |
| L6 Foreground Particles | Sparks, hit-bursts, sweep dust, collect trails | 1.0-1.1 | Slight over-parallax makes them "pop" in front |
| L7 Vignette Overlay | Dark radial vignette edges `rgba(0,0,0,0.35)` corners only | 0.0 (screen-space, camera HUD layer) | Focuses eye on grid center, hides screen edges |

### 4.3 Lighting Language
- **Bloom:** every light-emitting element (Bulb, Beam, Lamp core, Prism split) renders with a soft outer blur pass (`MaskFilter.blur` in the underlying `Paint`, or a duplicated lower-opacity larger-radius shape behind the sharp one) — never a flat-fill icon.
- **Color temperature tells story:** warm yellow/gold (`#FFD23F`) = player light, cold violet/magenta (`#E040FB`) = shadow threat, cyan (`#4FC3F7`) = frost/control. Never mix warm and cold on the same object.
- **Contrast:** background stays near-black (`#05070D`–`#141A2E` range) at all times so light sources visually pop. No mid-tone gray fills competing with glow.

### 4.4 Shadow Enemy Language
Shadows are not flat sprites — they are **living ink-blot silhouettes**: soft-edged (blurred alpha falloff, not hard vector edges), slightly wobbling/breathing idle animation even while walking (handled by `Effects` scale/skew loops), eyes are the only sharp, saturated element on them (draws focus, reads as "alive/watching"). Death = dissolve into 6-10 particles that fade+drift upward like smoke, never a simple pop.

### 4.5 Tool Language
Tools read as **small glowing machines**, not icons: visible construction lines (rivets, seams, a tiny glass/lens highlight), an idle "breathing" glow pulse even when not firing, and a distinct "power-up" animation on placement (scale+glow flash) so placing something always feels like activating a device, not stamping a sticker.

### 4.6 What This Explicitly Rules Out
- No `Icon(Icons.something)` Material icons anywhere in the game view.
- No flat solid-fill circles/squares with no gradient, glow, or texture standing in for final art.
- No screen that could be mistaken for a settings/forms page — even Shop and Settings get the desk/parallax treatment (lighter version — L0-L3 only, no gameplay layers).

---

## 5. Grid & Economy

**Grid:** 3 rows x 7 cols = 21 tiles. Tile is square, size calculated via formula (§11). Border 1px `#2A3560`, fill `#1A2340`, radius 8. Rendered as a `PositionComponent` (`GridComponent`) containing 21 `TileComponent` children — not a CustomPainter grid, so each tile can independently animate (hover-highlight, invalid-shake) via Flame `Effects`.

**Sweep (Lawnmower):** 1 per lane, left edge vertical stripe `12w rgba(255,210,63,0.15)` + arrow icon 12 (hand-drawn triangle, not Material icon). Auto triggers when shadow reaches `x <= 12`. Kills all shadows in that lane, plays sweep particle burst (`ParticleSystemComponent`, 20-particle radial), then stripe disappears via `OpacityEffect`. After used, lane is vulnerable.

**Glow Economy:**
*   Start Glow: `50`
*   Falling Glow: `+25` every `8.0s`, spawns as a `GlowOrbComponent` at `x = random(0, gridW)`, `y = -20` falls to `gridY 0..gridH` in 2s (`MoveEffect` with `Curves.easeIn`), tap radius `40px` to collect. Max 2 on screen.
*   Glow Bulb: Cost `50`, Cooldown `5s`, HP `100`, generates `+25` every `10.0s` auto (no tap). Must be ticked only if alive.
*   Twin Bulb: Cost `125`, Cooldown `15s`, HP `100`, generates `+50` every `10.0s`, can ONLY be placed ON existing Bulb (replaces it, refund 0).

**Economy Balance:** Bulb ROI `50 / 2.5 per sec = 20s`. With 2 bulbs early, pays by wave 2. Forces early decision: 2 bulbs = safe late, 0 bulbs = starve.

---

## 6. Tools — 8 Defenders

Each tool is a `PositionComponent` subclass (e.g. `BulbComponent extends PositionComponent with CollisionCallbacks`) rendering its own vector art in `render(Canvas)` — same hand-drawn shapes as the original spec, now living as Flame components so they get free access to `add(ScaleEffect...)`, `add(ParticleSystemComponent...)`, and `HasGameRef` for querying the battle world.

| ID | Name | Cost | Cooldown | HP | Damage / Effect | Lane Hit | Component Class | Visual 40x40 |
|---|---|---|---|---|---|---|---|---|
| `bulb` | Glow Bulb | 50 | 5s | 100 | Gen +25/10s | - | `BulbComponent` | Circle `#FFD23F` + 4 rays + glow blur 8, idle breathing pulse |
| `beam` | Beam Lamp | 100 | 5s | 100 | 20 dmg / 1.2s tick | Same lane | `BeamLampComponent` | Lamp rect `#E8EAF6` + cone `#FFD23F` |
| `mirror` | Mirror | 50 | 10s | 150 | Reflect 90° | Same + adj | `MirrorComponent` | Diamond `#B0BEC5` border `#78909C` + diagonal line 2px `#E8EAF6` |
| `prism` | Prism | 150 | 15s | 100 | Split 60% dmg to 3 lanes | 3 lanes | `PrismComponent` | Triangle gradient `#FF5252->#66BB6A->#29B6F6` |
| `frost` | Frost Lens | 125 | 12s | 100 | 15 dmg + slow 50% 2s | Same lane | `FrostLensComponent` | Snowflake `*` 6 arms `#4FC3F7` circle bg `rgba(79,195,247,0.2)` |
| `wall` | Shade Block | 50 | 8s | 400 | Block no attack | - | `WallComponent` | Brick 2x2 `#37474F` mortar `#263238` |
| `bomb` | Flash Bomb | 150 | 25s | - | 300 dmg 3x3 area instant | 3 lanes | `BombComponent` | Circle `#FFD23F` fuse `#EF5350` spark particle |
| `twin` | Twin Bulb | 125 | 15s | 100 | Gen +50/10s replaces bulb | - | `TwinBulbComponent` | Double circle overlapping |

**Placement Rules (§17) Must Pass All 7 Checks.**

**Tray Limit:** Player picks 6 of 8 before battle (Loadout screen). In battle tray shows 6 slots — rendered as a Flame `PositionComponent` row anchored to a HUD `CameraComponent.viewport`, not a Flutter `Row` widget, so it can sit inside the same render tree as everything else with zero Material dependency.

**Cooldown:** Dark overlay 75% + number `14 Inter #E8EAF6` countdown `4.2` (custom bitmap/vector font render via `TextComponent` with a `TextPaint` using `GoogleFonts.inter` — no Material `Text` widget) + circular progress 2px `#FFD23F` 360→0 drawn manually in `render()`.

**HP Bar:** Tool `32x4 radius2 bg rgba(0,0,0,0.4)` fill gradient `green #66BB6A >50% → yellow #FFD23F 25-50% → red #EF5350 <25%` width `hp%`. Implemented as a child `PositionComponent` whose width is driven by a `SizeEffect` / manual lerp over 200ms linear each time HP changes.

---

## 7. Shadows — 5 Enemies

Each shadow is a `PositionComponent` (e.g. `ShadowComponent`) with `CollisionCallbacks` for beam-hit detection via `RectangleHitbox`, so beam-vs-shadow intersection is Flame's collision system instead of manual rect math.

| ID | Name | HP | Speed | Eat/sec | Special | First Level | Component Visual 32x32 |
|---|---|---|---|---|---|---|---|
| `basic` | Shade | 100 | 12 px/s | 20 | - | 1 | Ink-blot circle `#2D1B4E` border2 `#4A2E7A` eyes `6x6 #E040FB` glow4, soft-edge blur per §4.4 |
| `bucket` | Helm Shade | 250 | 12 | 20 | Needs 2x bomb or 2 beams, before death shows crack | 5 | Same + bucket rect `#B0BEC5` on head |
| `jumper` | Leaper | 120 | 14 | 20 | Jumps over FIRST `wall` encountered (`MoveEffect` arc 12px 300ms) | 8 | Legs spring `#FFA726` |
| `fog` | Veil | 150 | 10 | 20 | Behind Veil, beam dmg -30% until Frost hits | 12 | Cloud puff `rgba(144,164,174,0.5)` blur, uses `OpacityEffect` shimmer |
| `giant` | Colossus | 600 | 8 | 40 | High HP, throws Imp at 50% HP (spawns basic at x+40) | 16 | Large 44x44, shadow larger, eye bigger 8 |

**Movement:** Handled in `ShadowComponent.update(dt)`: `x -= speed * dt`. Bob via a looping `MoveByEffect`/sine driver (`translateY sin(time*2.5)*2`), not a manual widget rebuild. Eating: if `toolAt(lane,colFromX(x)) != null && x <= tool.x+tileSize/2` then `tool.hp -= eat*dt` and `shadow.isEating=true` (pause walk, trigger an eating-animation `Effect` loop). Else walk.

**HP Bar:** `24x4 radius2` same gradient, above head offset `y-18`, child component.

**Spawn:** `x = gridRight + 32` offscreen, `y = rowCenter`. Spawned via `world.add(ShadowComponent(...))`. After spawn walk left.

**Death:** Dissolve into 6-10 smoke particles (`ParticleSystemComponent`, upward drift + fade), per §4.4 — never an instant `removeFromParent()` with no visual.

---

## 8. Wave System & 50% Rule

**Level JSON Wave:**
```json
"waves": [
  {"delay": 15, "shadows": [{"id":"basic","lane":0},{"id":"basic","lane":2}]},
  {"flag": true, "delay": 20, "shadows": [{"id":"bucket","lane":1},{"id":"basic","lane":1}]},
  {"flag": true, "delay": 25, "shadows": [{"id":"giant","lane":1}]}
]
```
*   `delay` = seconds from level start.
*   `flag` = huge wave (shows flag icon in TopBar).

**50% Rule Logic (lives in `BattleWorld.update(dt)` or a dedicated `WaveManagerComponent`):**
```dart
bool canSpawnNext() {
  if (waveIndex==0) return time >= waves[0].delay;
  Wave prev = waves[waveIndex-1];
  int totalHP = prev.shadows.fold(0,(s)=> s.hpMax);
  int aliveHP = shadows.where((s)=>s.fromWave==waveIndex-1).fold(0,(s)=>s.hp);
  bool halfDead = aliveHP < totalHP * 0.5;
  bool timeOut = time - lastWaveTime > 20.0;
  return time >= waves[waveIndex].delay && (halfDead || timeOut);
}
```
Ensures pressure rhythm, not spam.

**Flags UI:** TopBar center row `3 dots 8px` gap8: inactive `#4A5A6A`, active `#FFD23F` with pulse (`ScaleEffect` 1.2 400ms), upcoming flag wave has hand-drawn flag icon 14 `#FFD23F`. Rendered as a `PositionComponent` row inside the HUD camera viewport.

---

## 9. 20 Levels Progression

| Levels | Flags | New Mechanic | Unlock Reward | Par Time | Available Tools |
|---|---|---|---|---|---|
| 1-2 | 1 | Tutorial bulb+beam | - | 45s | bulb, beam, wall |
| 3-4 | 1 | Add wall need | - | 60s | +frost (preview) |
| 5-7 | 2 | Bucket 250HP | `mirror` | 75s | bulb,beam,wall,mirror |
| 8-11 | 2 | Jumper leaps wall | `frost` | 90s | +frost |
| 12-15 | 2-3 | Veil fog | `prism` + `bomb` | 110s | +prism,bomb |
| 16-18 | 3 | Giant 600HP | `twin` | 130s | all 8 |
| 19-20 | 3 | All mixed | - | 150s | all 8, hardest |

**Scout (Loadout):** Before battle show `INCOMING: Bucket x2, Veil x1` icons 24 (hand-drawn shadow silhouettes, not Material icons) + count JetMono 12. Player picks 6 from unlocked. Save to Hive.

**Difficulty Curve:** Early levels 1-4 teach 1 new tool every level, safe lane first. No fail possible if place 2 bulbs.

---

## 10. UI Theme — Complete Tokens

### 10.1 Colors
| Token | Hex | Usage |
|---|---|---|
| `bg` | `#0A0E1A` | Root background / L0 backdrop base |
| `surface` | `#141A2E` | TopBar, RightPanel |
| `surface2` | `#1E2642` | Card, Tile occupied |
| `surface3` | `#2A3560` | Border, Divider |
| `primary` | `#FFD23F` | Glow, Beam core, CTA, Selected |
| `primaryDark` | `#FFB300` | CTA pressed |
| `onPrimary` | `#1A1200` | Text on primary |
| `secondary` | `#4FC3F7` | Frost beam |
| `accentPrismG` | `Linear #FF5252→#FFD740→#66BB6A→#29B6F6→#AB47BC` | Prism |
| `success` | `#66BB6A` | Valid, Win |
| `successBg` | `#1B3A2E` | Valid tile fill |
| `successBorder` | `#2E7D5B` | Valid border |
| `error` | `#EF5350` | Invalid, Damage |
| `errorBg` | `#3A1A1A` | Invalid tile fill |
| `errorBorder` | `#7D2E2E` | Invalid border |
| `textPrimary` | `#E8EAF6` | Title, Body |
| `textSecondary` | `#90A4AE` | Sub, Hint |
| `textDisabled` | `#4A5A6A` | Disabled |
| `gridEmpty` | `#1A2340` | Empty tile |
| `gridBorder` | `#2A3560` | Tile border 1px |
| `shadowBody` | `#2D1B4E` | Enemy body |
| `shadowEye` | `#E040FB` | Eye glow |
| `beamCore` | `#FFD23F` | Beam 4px |
| `beamGlow` | `rgba(255,210,63,0.30)` | Outer 12px blur8 |
| `mirrorMetal` | `#B0BEC5` | Mirror |
| `wallBlock` | `#37474F` | Wall |
| `hpBg` | `rgba(0,0,0,0.40)` | HP bg |
| `scrim` | `rgba(10,14,26,0.80)` | Pause overlay |

Scaffold Gradient: `Linear 180deg #0A0E1A 0% → #141A2E 100%` — rendered as the L0 backdrop component, not a Flutter `Container` decoration.

### 10.2 Typography
All text rendered via Flame `TextComponent` + `TextPaint(style: TextStyle(...))` using `GoogleFonts` — never a Material `Text` widget inside the game view.

| Style | Font | Size | Weight | LH | LS | Use |
|---|---|---|---|---|---|---|
| display | Orbitron | 32 | 800 Black | 36 | 1.5 | Home Title |
| h1 | Orbitron | 24 | 700 Bold | 28 | 0.5 | Section header, Win |
| h2 | Inter | 18 | 700 Bold | 24 | 0 | Tool name |
| h3 | Inter | 14 | 600 Semi | 18 | 0 | Tray name |
| body | Inter | 14 | 400 | 20 | 0 | Desc |
| bodySmall | Inter | 12 | 400 | 16 | 0 | Hint |
| label | Inter | 10 | 600 | 12 | 0.8 | COST, WAVE |
| number | JetBrainsMono | 16 | 700 | 20 | 0 | Glow, Damage |
| numberLg | JetBrainsMono | 20 | 700 | 24 | 0 | TopBar Glow |

### 10.3 Spacing & Sizing (4px base)
`4,8,12,16,20,24,32,40,48` Screen padding 12 landscape (not 16). Card padding 12. Tile gap 4. Tray gap 10. TopBar 48, RightPanel 220w.

Radius: Card16, Button16, Tile8, Slot12, HP2, Chip20, Dialog20. All corner radii drawn manually via `RRect` in each component's `render()` — no `BorderRadius`/Material `Card`.

### 10.4 Elevation
Card `shadow rgba(0,0,0,0.40) blur16 y4` Button `rgba(255,210,63,0.30) blur12 y4` Tool `rgba(255,210,63,0.20) blur8 y2` Tiles flat. Implemented as a secondary lower-opacity shadow shape drawn behind the main shape in `render()`, or `Paint()..maskFilter = MaskFilter.blur(...)`.

### 10.5 Iconography
Everything hand-drawn as vector paths in a component's `render(Canvas)` — outline 2px stroke rounded caps, 24 base. No `Icon(Icons.*)` anywhere. Glow ray-burst, flag pennant, pause bars, tool glyphs (§6) — all custom `Path` draws.

---

## 11. Landscape Layout — Pixel Exact

**Baseline:** 812x375 (iPhone landscape) → scales to 1280x720 via formula. In Flame this drives the `CameraComponent.viewfinder` visible game size, computed once on `onGameResize`.

**Formula (AI Must Use):**
```dart
double topBarH = 48;
double pad = 12;
double rightW = 220;
double gridH = h - topBarH - pad*2; // 375-48-24=303
double gridW = w - rightW - pad*3; // 812-220-36=556
double tileH = (gridH - 2*4)/3;
double tileW = (gridW - 6*4)/7;
double tile = min(tileH, tileW); // square, ~72
```

**TopBar 812x48 (HUD `PositionComponent`, camera-viewport-anchored so it never scrolls with parallax):** `bg surface #141A2E borderBottom1 #2A3560`
*   Left Glow Chip `110x32 bg #0A0E1A radius16 border1 #2A3560` row `icon16 (hand-drawn sunburst) + number16 #FFD23F + "/200" 10 #90A4AE` padding `8`
*   Center Flags `row gap8` 3 dots `8` + label `WAVE 2/3 Inter10 #90A4AE`
*   Right Pause `48x48 bg surface2 radius12 icon20` (hand-drawn pause bars, tappable via Flame `TapCallbacks`)

**Grid Area:** `padding12` 3 rows, 7 cols, gap4, tiles `tile x tile` centered — this is `GridComponent` living in `World` at `1.0` parallax. Lane divider dashed `4,4 rgba(42,53,96,0.6)` horizontal, drawn in `GridComponent.render()`. Sweep stripe leftmost `12w rgba(255,210,63,0.15)` + arrow `10` if unused.

**Right Panel 220 (HUD `PositionComponent`, camera-viewport-anchored):**
*   Section1 Tray: title `TRAY - PICK 1 Inter10 #90A4AE` + grid `3x2 slots 64x64 gap10` (2 rows 3 cols fits 220) — each slot a `TraySlotComponent` with `TapCallbacks`
*   Section2 Stats: `Wave progress 200x6 bg #1A2340 radius3 fill #FFD23F width%` (driven by a `SizeEffect`), HP legend `row 2 bars 48x4`
*   Bottom Boost: `200x48 bg #2A3560 radius12 border1 #3A4A6A` row `icon16 #FFD23F + text "+50 GLOW" Inter12 700 + sub "AD 1/1" 9 #90A4AE` disabled `opacity0.4` via `OpacityEffect`

**Touch Target:** All interactive components min `48x48` hitbox (slot 64 ok, pause 48 ok), handled via Flame `TapCallbacks`/`DragCallbacks` mixins, not `GestureDetector`.

---

## 12. All Screens — Flame Component Wireframes

Every screen below is either (a) a distinct `FlameGame` / `World` loaded via `go_router`, or (b) a shared persistent `FlameGame` with swappable top-level `World`s (recommended — avoids re-init cost between Home→Map→Loadout→Battle). All use the L0-L3 desk/parallax backdrop from §4.2 (lighter weight outside Battle — no L4-L6 gameplay layers). Zero Material/Cupertino widgets in any of them.

**Home:** `World` with L0-L3 backdrop + dot pattern layer (`dot4 gap24 rgba(255,210,63,0.04)`, part of L1). Center row via two `PositionComponent` columns: Left `Title Orbitron32 (TextComponent) + sub12 #90A4AE "DEFEND THE LIGHT" + buttons column gap16: Play 220x56 primary, Map 200x48 secondary, Settings 200x48` (each button a `ButtonComponent extends PositionComponent with TapCallbacks`) Right `Preview card 280x160 surface2 radius16 showing a live mini 3x4 grid diorama — an actual tiny nested `World`/component tree animating idle beams, not a static image`. Bottom chips `Daily Ready 180x32 bg surface2 radius20 text12 + progress 3/20`.

**Level Map:** Header `h1 "LEVELS" + coin chip`. Grid `5 cols x4 rows cards 110x90 gap12`, each a `LevelCardComponent` with `TapCallbacks`, styled per §10.4.

**Loadout:** Landscape split via two `PositionComponent` panels: Left `Scout panel 340w bg surface2 radius16 padding12: "INCOMING" label + enemy icons24 (hand-drawn silhouettes) + count` + `Picked 6/6` Right `Tool grid 4x2 slots 76x96 gap12` Bottom bar `Start Battle 260x56 primary enabled only if 6 selected else disabled 0.5 opacity` Center divider `1px #2A3560`.

**Battle:** Full layered world per §4.2/§14 — this is the only screen using all L0-L7 layers.

**Pause Overlay:** Rendered as a HUD-layer `PositionComponent` group (not a Flutter dialog) so it composites over the paused `World` without pausing rendering — game `update()` is paused via `world.pauseEngine` logic, not the render tree. Full `scrim 0.80` rect. Center card `360x220 bg surface2 radius20 padding20 column gap16`: `PAUSED Orbitron18` + buttons `Resume primary 200x48, Restart secondary 200x48, Home text 200x48 #90A4AE`.

**Win Dialog:** Same HUD-overlay pattern. Card `420x260 bg surface2 radius20` -> `VICTORY Orbitron20 #66BB6A` + stars `3*28 gap12` each animated in via `ScaleEffect` stagger 120ms (`0->1.2->1 400ms backOut`) + `+20 coins chip bg #0A0E1A radius20 padding10x6` + a real `ParticleSystemComponent` confetti burst (12 particles fall 800ms) behind the card + buttons row gap12 `Replay 120x48 surface3` `Next 200x48 primary`.

**Lose:** Same but `DEFEAT #EF5350` + hint `Try more Bulbs early! Inter12 #90A4AE` + `Try Again primary`. World itself gets a `MoveEffect` shake (`translateX -4,4 x3 300ms`) before the overlay appears.

**Shop:** Left list `Tray Slot +2 (200 coins)` button-component, Right `Remove Ads $2.99` card `280x120 surface2`. Lightweight L0-L2 backdrop only. No server.

**Settings:** Row toggles `Sound, Haptics, Reset Progress` with a hand-drawn `SwitchComponent` (`#FFD23F` active track, animated thumb via `MoveEffect`) — not a Material `Switch`.

---

## 13. Flame Architecture — Component Tree

```
LightVsShadowGame extends FlameGame
  with HasCollisionDetection, KeyboardEvents
 ├─ World (swappable per screen via router)
 │   ├─ HomeWorld        (Home screen content)
 │   ├─ MapWorld         (Level Map content)
 │   ├─ LoadoutWorld     (Loadout content)
 │   ├─ BattleWorld      ← main gameplay, detailed below
 │   ├─ ShopWorld
 │   └─ SettingsWorld
 └─ CameraComponent
     ├─ viewfinder → follows/frames the active World
     └─ viewport   → HUD layer (TopBar, RightPanel, Tray, Dialogs)
                     stays fixed regardless of world/camera movement

BattleWorld extends World
 ├─ BackdropLayer (L0-L1)         — static gradient + desk texture
 ├─ DustMoteLayer (L2)            — ParticleSystemComponent, infinite generator
 ├─ AmbientGlowLayer (L3)         — breathing radial glows near active bulbs
 ├─ GridComponent (L4)
 │   └─ TileComponent x21         — TapCallbacks, hover/invalid Effects
 ├─ EntityLayer (L5)
 │   ├─ ToolComponent subclasses  — BulbComponent, BeamLampComponent,
 │   │                              MirrorComponent, PrismComponent,
 │   │                              FrostLensComponent, WallComponent,
 │   │                              BombComponent, TwinBulbComponent
 │   ├─ ShadowComponent x N       — with RectangleHitbox (CollisionCallbacks)
 │   ├─ BeamComponent x N         — drawn per active ray, recomputed on trace
 │   └─ GlowOrbComponent x ≤2     — falling collectible glow
 ├─ ForegroundParticleLayer (L6)  — sparks, hit-bursts, sweep dust, collect trails
 └─ WaveManagerComponent          — headless logic component, no visual;
                                    owns 50% rule, spawn timers, flag state

HUD (on CameraComponent.viewport, always screen-locked)
 ├─ TopBarComponent (Glow chip, Flags row, Pause button)
 ├─ RightPanelComponent (Tray, Stats, Boost button)
 └─ OverlayLayer (Pause / Win / Lose — added/removed on demand)
```

**State bridge to Riverpod:** `flame_riverpod`'s `RiverpodAwareGameMixin` on `LightVsShadowGame` lets components read/watch a `BattleNotifier extends Notifier<BattleState>` for cross-cutting state (glow count, wave index, save data) while gameplay simulation itself (positions, HP, collisions) lives natively in component `update(dt)` — avoids funneling every per-frame position change through Riverpod, which would be slow and unidiomatic.

---

## 14. Camera, World & Parallax Layers

```dart
class BattleWorld extends World with HasGameRef<LightVsShadowGame> {
  late final ParallaxComponent? backdropParallax; // or manual layered components, see below
  @override
  Future<void> onLoad() async {
    // Manual layered parallax (preferred over Flame's ParallaxComponent here
    // since layers need custom breathing/glow animation, not just scroll-offset).
    await addAll([
      BackdropLayer(),        // L0-L1, priority -30
      DustMoteLayer(),        // L2, priority -20, ParticleSystemComponent generator
      AmbientGlowLayer(),     // L3, priority -10
      GridComponent(),        // L4, priority 0
      // EntityLayer components added dynamically at priority 10+
      ForegroundParticleLayer(), // L6, priority 90
    ]);
  }
}
```

**CameraComponent setup (main game class):**
```dart
@override
Future<void> onLoad() async {
  camera.viewfinder.anchor = Anchor.topLeft;
  camera.viewfinder.visibleGameSize = Vector2(812, 375); // baseline, rescaled on resize
  world = BattleWorld();
  camera.world = world;
  // HUD lives on camera.viewport, unaffected by any world-space camera moves
  camera.viewport.add(TopBarComponent());
  camera.viewport.add(RightPanelComponent());
}
```

**Parallax factor application:** each backdrop layer's `render()` offsets its own draw position by `-camera.viewfinder.position * factor` (factors per §4.2 table) rather than using literal Flame `ParallaxComponent` scroll (which assumes a horizontally-scrolling camera). Since this game's camera is static during battle (fixed framing on the grid), the "parallax" here is expressed instead through: (a) depth-cued scale/opacity per layer, (b) independent idle-drift motion per layer (dust motes, breathing glows) at different speeds, so depth reads through *motion parallax* rather than camera-scroll parallax. This is the correct technique for a fixed-camera diorama and is what actually produces the "real environment" feeling requested.

**Screen shake (Lose state, big hits):** `camera.viewfinder.add(MoveByEffect(Vector2(4,0), EffectController(duration: 0.05, alternate: true, repeatCount: 6)))` applied to the viewfinder, not individual components — shakes the whole framed world at once.

---

## 15. Beam Optics Algorithm — Full Logic

**Ray:** `start Offset, dir Dir (right/up/down), dmg double, color Color, lane int` — represented as a lightweight data class, not a component itself; each resolved ray segment spawns/updates a `BeamComponent` for rendering.

**FindNextOccupied(start, dir):** Scan tiles in dir order via `GridComponent`'s tile map, return first with `tool != null`.

**Shadow hit-test:** Uses Flame's `CollisionCallbacks`/`RectangleHitbox` on each `ShadowComponent` intersected against a thin `RectangleHitbox` representing the current beam segment (width 12), rather than manual rect-intersection math — `onCollision` callback reports the hit back to the tracer.

**Trace Pseudocode (depth max3, loop prevent):**
```dart
void trace(Ray r, int depth, Set<String> visited) {
  if (depth>3) return;
  String key = "${r.start.dx},${r.start.dy},${r.dir}";
  if (visited.contains(key)) return; visited.add(key);
  Tile? next = findNextOccupied(r.start, r.dir);
  ShadowComponent? shadow = findFirstShadowInRay(r); // via hitbox intersection, not manual rect math
  double dNext = next!=null? dist(r.start,next.pos): double.infinity;
  double dShadow = shadow!=null? dist(r.start,shadow.pos): double.infinity;
  if (shadow!=null && dShadow < dNext) {
    shadow.hp -= r.dmg * dt * (shadow.id==fog?0.7:1.0);
    if (r.color == Color(0xFF4FC3F7)) shadow.slowUntil = time + 2.0;
    updateOrCreateBeamComponent(r.start, shadow.pos, r.color, r.dmg);
    world.add(SparkParticleComponent(shadow.pos)); // pooled ParticleSystemComponent
    return;
  }
  if (next==null) { updateOrCreateBeamComponent(r.start, edgeInDir(r.dir), r.color, r.dmg); return; }
  Tool t = next.tool;
  if (t.id == "mirror" && r.dir==Dir.right) {
    updateOrCreateBeamComponent(r.start, t.pos, r.color, r.dmg);
    Dir out;
    if (t.row==0) out=Dir.down;
    else if (t.row==2) out=Dir.up;
    else out = (depth%2==0? Dir.down: Dir.up);
    trace(Ray(t.pos, out, r.dmg, r.color, r.lane), depth+1, visited);
    return;
  }
  if (t.id == "prism" && r.dir==Dir.right) {
    updateOrCreateBeamComponent(r.start, t.pos, r.color, r.dmg);
    for (Dir d in [Dir.right, Dir.up, Dir.down]) {
      Color c = d==Dir.right? Color(0xFFFFD23F): d==Dir.up? Color(0xFFAB47BC): Color(0xFF66BB6A);
      trace(Ray(t.pos, d, r.dmg*0.6, c, r.lane), depth+1, visited);
    }
    return;
  }
  // wall/block etc just stops at tile, but beam lamp doesn't block
  updateOrCreateBeamComponent(r.start, t.pos, r.color, r.dmg);
}
```

**Visual:** `BeamComponent.render()` draws core `4px #FFD23F` + outer `12px rgba(0.3) blur8` (`MaskFilter.blur`) glow-first-then-core layering. Hit spark via a pooled `ParticleSystemComponent` (`6 dots 3px #FFD23F life180ms`) — pooling handled by Flame's particle system rather than manual list management.

**Performance:** `BeamComponent`s are reused/updated in place per active ray path rather than destroyed+recreated every frame; each implements `Component`'s built-in dirty-check so Flame only redraws changed beams. Target: keep total active `BeamComponent` count low (≤ 3 lanes × depth-3 max ≈ 9 concurrent segments).

---

## 16. Battle Tick — Full Update Logic dt 16ms

Core simulation lives in `BattleWorld.update(dt)` and/or a dedicated headless `WaveManagerComponent.update(dt)` — Flame calls `update(dt)` automatically every frame on every component in the tree, replacing the manual `Ticker` from the pure-widget version.

```dart
enum GameState { loading, ready, playing, paused, won, lost }
GameState state = loading;
double time=0, lastSun=0, lastWaveTime=0, lastGenCheck=0;
int glow=50, waveIndex=0, usedBoost=0;
List<bool> sweep=[true,true,true];
int selectedToolIndex=-1;

@override
void update(double dt) {
  super.update(dt); // propagates to all child components automatically
  if (state != playing) return;
  time += dt;
  // 1. Falling glow orb
  if (time - lastSun > 8.0 && glowOrbsOnScreen<2) {
    add(GlowOrbComponent(x: Random().nextDouble()*gridW)); lastSun=time;
  }
  // 2. Bulb gen — query components directly, no manual list bookkeeping needed
  for (var b in children.whereType<ToolComponent>().where((p)=>p.id=="bulb"||p.id=="twin")) {
    if (time - b.lastGen > 10.0) {
      glow = min(999, glow + (b.id=="twin"?50:25));
      b.lastGen=time;
      add(CollectParticleComponent(b.position));
    }
  }
  // 3. Wave (delegated to WaveManagerComponent.canSpawnNext(), §8)
  if (waveIndex < level.waves.length && waveManager.canSpawnNext()) {
    waveManager.spawnWave(level.waves[waveIndex]); lastWaveTime=time; waveIndex++;
  }
  // 4. Shadow movement/eating/special handled per-component in
  //    ShadowComponent.update(dt) — each shadow owns its own logic,
  //    Flame calls it automatically. World-level tick only aggregates
  //    terminal-state checks (steps 5-8 below).
  // 5. Sweep
  for (var s in List<ShadowComponent>.from(children.whereType<ShadowComponent>())) {
    if (s.x <= 12 && sweep[s.lane]) {
      sweep[s.lane]=false;
      children.whereType<ShadowComponent>().where((x)=>x.lane==s.lane).forEach((x)=>x.removeFromParent());
      add(SweepParticleComponent(s.lane));
      break;
    }
  }
  // 6. Beams re-traced (see §15) — only when placement/removal/death changes topology
  retraceAllBeamsIfDirty();
  // 7. Remove dead shadows (each ShadowComponent triggers its own death
  //    dissolve Effect + particle burst on hp<=0 inside its own update(),
  //    then calls removeFromParent() when the dissolve finishes)
  // 8. Terminal
  if (waveIndex >= level.waves.length && children.whereType<ShadowComponent>().isEmpty) {
    state=won; onWin();
  }
  if (children.whereType<ShadowComponent>().any((s)=> s.x<=0 && !sweep[s.lane])) {
    state=lost; onLose();
  }
}
```

**Per-shadow logic (now lives on the component itself, not a central loop):**
```dart
class ShadowComponent extends PositionComponent with CollisionCallbacks {
  @override
  void update(double dt) {
    super.update(dt);
    double speed = baseSpeed * (gameRef.battleWorld.time < slowUntil ? 0.5 : 1.0);
    ToolComponent? front = gameRef.battleWorld.toolAt(lane, colFromX(x));
    bool eating = front!=null && x <= front.x + tileSize/2;
    if (eating) {
      isEating=true;
      front!.hp -= eat * dt;
      if (front.hp<=0) { front.playDestroyEffectThenRemove(); }
    } else {
      isEating=false;
      if (id=="jumper" && !hasJumped && front!=null && front.id=="wall" && x - front.x < 20) {
        hasJumped=true;
        add(MoveByEffect(Vector2(-48,0), EffectController(duration:0.3, curve: Curves.easeOut)));
      } else {
        x -= speed * dt;
      }
    }
    if (id=="giant" && !hasThrown && hp < maxHp*0.5) {
      hasThrown=true;
      gameRef.battleWorld.add(ShadowComponent(id:"basic", lane:lane, x:x+40, hp:100, fromWave: fromWave));
    }
  }
}
```

---

## 17. Placement Validation — All Conditions Table

`tryPlace(toolId, row, col)` — invoked from `TileComponent`'s `onTapUp`/`onDragEnd` (Flame `TapCallbacks`/`DragCallbacks`), must check in order, first fail returns reason:

| # | Condition | Code | Fail UI |
|---|---|---|---|
| 1 | `state==playing` | if not playing return "Not playing" | ignore |
| 2 | `0<=row<3 && 0<=col<7` | bounds | ignore |
| 3 | `grid[row][col]==null` | occupied? | `tile.add(MoveByEffect shake 4px 80ms)`, haptic heavy, `ToastComponent "Occupied" 10px #EF5350 800ms` added to HUD viewport |
| 4 | `glow >= tool.cost` | | cost `TextComponent` pulse red `#EF5350` via `ColorEffect` 300ms |
| 5 | `now - lastPlaced[toolId] >= cooldown` | | show cooldown number on tray slot |
| 6 | `toolId=="twin" implies grid[row][col].id=="bulb"` before replacement logic | check `grid[row][col]?.id=="bulb"` | toast "Need Bulb" |
| 7 | `toolId=="prism" && countPrismInRow(row) >=2` optional limit | | toast "Max Prism" |

Success steps:
```dart
glow -= cost;
final tool = ToolComponentFactory.create(id, row, col, tile, pad, topBar); // returns e.g. BulbComponent
world.add(tool);
lastPlaced[toolId]=now;
selectedToolIndex=-1;
world.add(PlaceParticleComponent(tool.position)); // pooled ParticleSystemComponent
tool.add(ScaleEffect.to(Vector2.all(1.0), EffectController(duration:0.22, curve: Curves.elasticOut))
  ..onComplete = () {}); // "power-up" placement animation per §4.5
Haptic.mediumImpact();
FlameAudio.play('place.mp3');
checkAchievements();
```

**Input (all via Flame's `TapCallbacks`/`DragCallbacks` mixins on the relevant components, not `GestureDetector`):**
*   Tap tray slot -> `TraySlotComponent.onTapUp` selects (border `ColorEffect` to primary), tap again deselects.
*   Tap grid tile with selection -> `TileComponent.onTapUp` calls `tryPlace`.
*   Drag tray slot -> spawns a `GhostToolComponent` (40x40 opacity 0.6) that follows the drag position (`DragUpdateCallbacks`), on `onDragEnd` over a tile -> `tryPlace`.
*   LongPress placed tool 500ms (`onLongTapDown`) -> show shovel `IconComponent` (hand-drawn, 24, red) top-right -> tap to remove (no refund), tool plays `ScaleEffect.to(Vector2.zero(), duration:0.12)` + remove sound, then `removeFromParent()`.
*   Bomb: instant explode `300 dmg 3x3` radius `1 tile each direction` via `world.add(ExplosionParticleComponent(...))` full-screen-space flash, then `bombComponent.removeFromParent()` after `200ms`.

---

## 18. Particles & Effects System

This section is new versus the pure-widget spec — it's the concrete payoff of the Flame rebuild and must be implemented as described, not left generic.

### 18.1 Particle Inventory (all `ParticleSystemComponent`, pooled)
| Name | Trigger | Particle Count | Behavior | Life |
|---|---|---|---|---|
| `DustMoteParticle` | Always running (ambient, L2) | 12-18 | Slow random-walk drift, wrap at grid edges | Infinite loop |
| `PlaceParticle` | Tool placed | 6 | Burst outward 24px, fade | 120ms |
| `CollectParticle` | Glow orb / bulb tick collected | 8 | Burst + upward drift, gold | 200ms |
| `SparkParticle` | Beam hits shadow | 6 | Outward 24px, `#FFD23F` | 180ms |
| `SweepParticle` | Lane sweep triggers | 20 | Radial burst along lane, wide spread | 500ms |
| `DeathDissolveParticle` | Shadow dies | 6-10 | Upward drift + fade, smoke-colored (§4.4) | 400ms |
| `ExplosionParticle` | Flash Bomb detonates | 30 | Radial 3x3-tile-radius burst, `#FFD23F`→`#EF5350` | 400ms |
| `ConfettiParticle` | Win dialog | 12 | Fall from top, rotate, mixed palette colors | 800ms |
| `LeapDustParticle` | Jumper leaps wall | 4 | Small puff at takeoff + landing points | 200ms |

### 18.2 Effects Inventory (Flame `Effect` classes, replacing hand-rolled `AnimationController`s)
| Use | Effect | Params |
|---|---|---|
| Tool placement pop | `ScaleEffect.to` | `Vector2.all(1.0)` from 0, `elasticOut`, 220ms |
| Idle breathing glow (Bulb, ambient pools) | `ScaleEffect.to` (looping, `infinite: true, alternate: true`) | `1.0 → 1.08`, 3000ms |
| Beam pulse | `OpacityEffect.to` (looping) | `1.0 → 0.7 → 1.0`, 600ms |
| Shadow walk bob | Custom sine driver in `update()` (simplest for continuous sine, not a discrete Effect) | `translateY sin(time*2.5)*2` |
| HP bar width change | `SizeEffect.to` | width = hp%, 200ms linear |
| Tile invalid shake | `MoveByEffect` (alternate) | `±4px`, 80ms |
| Cost pulse red | `ColorEffect` | to `#EF5350`, 300ms, alternate |
| Win stars stagger | `ScaleEffect.to` chained via `SequenceEffect`, staggered `onComplete` per star | `0 → 1.2 → 1`, 400ms, `backOut`, 120ms stagger |
| Lose shake | `MoveByEffect` on `camera.viewfinder` | `±4px x3`, 300ms |
| Button press | `ScaleEffect.to` | `0.97`, 100ms, `easeOut` |
| Tray slot cooldown ring | Manual `render()` arc draw driven by a `TimerComponent`, not a pre-built Effect | 360°→0° |

### 18.3 Pooling Discipline
`ParticleSystemComponent` instances for high-frequency effects (`SparkParticle`, `CollectParticle`) should be drawn from a small reusable pool rather than freshly allocated every trigger, to keep the ≤50-draw-call/frame target (§24) on low-end Android. Implement a lightweight `EffectPool<T extends Component>` helper that recycles finished instances instead of calling `removeFromParent()` + `new` every time.

---

## 19. Persistence — Hive

**Box `save` single object (unchanged by the Flame rebuild — persistence is engine-agnostic):**
```dart
@HiveType(typeId:0) class Save extends HiveObject {
  @HiveField(0) int coins=0;
  @HiveField(1) List<int> stars=List.filled(20,0);
  @HiveField(2) Set<String> unlocked={"bulb","beam","wall"};
  @HiveField(3) bool removeAds=false;
  @HiveField(4) bool sound=true;
  @HiveField(5) bool haptics=true;
  @HiveField(6) int maxUnlocked=1;
  @HiveField(7) int totalPlays=0;
}
```

On win: `save.stars[levelId-1]=max(old,newStars)` `save.coins+= (newStars>old? (newStars-old)*10+20 :10)` `if levelId==maxUnlocked && won {maxUnlocked++}` `if reward=="mirror" unlocked.add("mirror")` Hive flush. Triggered from `BattleWorld.onWin()` reading/writing through the `BattleNotifier` (Riverpod), which Flame components access via `flame_riverpod`'s `RiverpodAwareGameMixin`/`RiverpodComponentMixin`.

Daily: `int dailyId = (DateTime.now().dayOfYear %20)+1` same for all offline. Home chip shows Daily. No server.

---

## 20. Monetization — No Backend

*   **Banner:** Home/Map only. Since these screens are Flame `World`s inside a `GameWidget`, the banner ad is composited as a normal Flutter widget *outside* the `GameWidget` (e.g. in a `Stack` in the root `WidgetsApp`/custom root widget) — `AdWidget` remains a legitimate Flutter widget use here since it's platform-rendered content, not part of the Flame render tree. Bottom 50h, hide if `removeAds`. Not shown during Battle.
*   **Interstitial:** After Win overlay `500ms` delay, if `!removeAds && levelId%3==0 && interstitialLoaded` show. Frequency cap 1/3 wins.
*   **Rewarded Boost:** RightPanel HUD button `+50 Glow` (a `ButtonComponent`, not a Flutter widget). Condition: `!usedBoost && !removeAds && rewardedLoaded` enabled else `OpacityEffect` to `0.4`. On Tap: `showRewardedAd() -> onRewarded: glow+=50; usedBoost=1; button disabled; world.add(GlowBurstParticleComponent())`. Cap 1 per battle (Block Blast rule).
*   **IAP Remove Ads:** `in_app_purchase` single `remove_ads $2.99` non-consumable. On `purchaseStatus==purchased` -> `save.removeAds=true` -> hide ads, no validation server needed. Restore via `restorePurchases()`.

**Store:** Shop screen (`ShopWorld`) lists: `Tray Slot +2 (200 coins)` component, disabled after bought, `Remove Ads $2.99` -> buy. No subscriptions.

---

## 21. Tech Stack & Project Structure

```yaml
dependencies:
  flame: ^1.18
  flame_audio: ^2.1
  flame_riverpod: ^0.2
  flutter_riverpod: ^2.4
  go_router: ^12
  hive_flutter: ^1.1
  google_mobile_ads: ^3.0
  in_app_purchase: ^3.1
  google_fonts: ^6.1
```

Note: `audioplayers` and `flutter_animate` from the pure-widget version are dropped — `flame_audio` (built on `audioplayers` internally) replaces direct `audioplayers` calls for pooled/spatial-friendly sound triggered from components, and Flame's own `Effects` API replaces `flutter_animate` entirely inside the game view (Flutter-side screens like a top-level router shell may still use plain Flutter animation primitives, but never `flutter_animate` or Material).

```
lib/
 main.dart                 // lock landscape, Hive.init, runApp with WidgetsApp root (NOT MaterialApp)
 core/
  theme.dart               // color/text tokens as plain Dart constants + TextPaint builders (no ThemeData/Material)
  router.dart              // go_router 7 routes, each hosting the shared GameWidget with a different World swapped in
  hive.dart                // init Box save
  audio.dart               // FlameAudio pool setup
 game/
  light_vs_shadow_game.dart   // FlameGame root, CameraComponent + HUD setup
  worlds/
   home_world.dart
   map_world.dart
   loadout_world.dart
   battle_world.dart          // main gameplay World, owns WaveManagerComponent
   shop_world.dart
   settings_world.dart
  components/
   backdrop_layer.dart        // L0-L1
   dust_mote_layer.dart       // L2
   ambient_glow_layer.dart    // L3
   grid_component.dart        // L4, + tile_component.dart
   tools/
    bulb_component.dart
    beam_lamp_component.dart
    mirror_component.dart
    prism_component.dart
    frost_lens_component.dart
    wall_component.dart
    bomb_component.dart
    twin_bulb_component.dart
   shadow_component.dart
   beam_component.dart
   glow_orb_component.dart
   wave_manager_component.dart
   hud/
    top_bar_component.dart
    right_panel_component.dart
    tray_slot_component.dart
    button_component.dart
    toast_component.dart
    overlay_pause.dart
    overlay_win.dart
    overlay_lose.dart
  particles/
   particle_definitions.dart   // §18.1 inventory as reusable factories
   effect_pool.dart            // §18.3 pooling helper
 state/
  battle_notifier.dart      // Notifier<BattleState>, bridged via flame_riverpod
 data/
  models.dart               // ToolDef, ShadowDef, Level, Wave
  levels_loader.dart         // load assets/levels/*.json
 assets/
  levels/1.json ...20.json
  tools.json
  shadows.json
  audio/place.mp3 ...
 assets/images/              // none needed MVP, all vector-drawn in component render()
```

**BattleNotifier:** `extends Notifier<BattleState>` holds save-relevant/cross-screen state (glow count for HUD display, wave index for TopBar, coins/stars). Per-frame simulation state (positions, HP, active beams) lives natively on the Flame components themselves — Riverpod is not used as the per-frame game loop, only as the bridge for state other widgets/screens need to observe.

---

## 22. Data Models & JSON Schema

Unchanged from the pure-widget version — JSON schema is engine-agnostic.

**assets/tools.json**
```json
[
  {"id":"bulb","cost":50,"hp":100,"cooldown":5,"dmg":0},
  {"id":"beam","cost":100,"hp":100,"cooldown":5,"dmg":20},
  {"id":"mirror","cost":50,"hp":150,"cooldown":10,"dmg":0},
  {"id":"prism","cost":150,"hp":100,"cooldown":15,"dmg":0},
  {"id":"frost","cost":125,"hp":100,"cooldown":12,"dmg":15},
  {"id":"wall","cost":50,"hp":400,"cooldown":8,"dmg":0},
  {"id":"bomb","cost":150,"hp":0,"cooldown":25,"dmg":300},
  {"id":"twin","cost":125,"hp":100,"cooldown":15,"dmg":0}
]
```

**assets/shadows.json**
```json
[
  {"id":"basic","hp":100,"speed":12,"eat":20},
  {"id":"bucket","hp":250,"speed":12,"eat":20},
  {"id":"jumper","hp":120,"speed":14,"eat":20},
  {"id":"fog","hp":150,"speed":10,"eat":20},
  {"id":"giant","hp":600,"speed":8,"eat":40}
]
```

**assets/levels/1.json Example Full**
```json
{
  "id": 1,
  "name": "First Light",
  "flags": 1,
  "startGlow": 50,
  "parTime": 45,
  "availableTools": ["bulb","beam","wall"],
  "unlockReward": null,
  "waves": [
    {"delay": 12, "shadows": [{"id":"basic","lane":1}]},
    {"flag": true, "delay": 22, "shadows": [{"id":"basic","lane":0},{"id":"basic","lane":1},{"id":"basic","lane":2}]}
  ]
}
```

**Level 16 Example Giant:**
```json
{
  "id": 16,
  "flags": 3,
  "startGlow": 75,
  "parTime": 130,
  "availableTools": ["bulb","beam","mirror","prism","frost","wall","bomb","twin"],
  "unlockReward": "twin",
  "waves": [
    {"delay": 10, "shadows": [{"id":"basic","lane":1},{"id":"bucket","lane":0}]},
    {"delay": 20, "shadows": [{"id":"jumper","lane":2},{"id":"fog","lane":1}]},
    {"flag": true, "delay": 35, "shadows": [{"id":"giant","lane":1},{"id":"bucket","lane":0},{"id":"bucket","lane":2}]},
    {"flag": true, "delay": 50, "shadows": [{"id":"giant","lane":0},{"id":"giant","lane":2}]}
  ]
}
```

---

## 23. Animations, Sound, Haptics

**Animations:** All via Flame `Effects` (§18.2), not `AnimationController`:
*   Place: `ScaleEffect 0->1 220ms elasticOut` + `PlaceParticle burst 120ms`
*   Shadow walk bob: sine driver in `update()`, `translateY 2px 400ms sine loop`
*   Beam pulse: `OpacityEffect 1.0->0.7->1.0 600ms loop`
*   Hit spark: `SparkParticle 6 particles 3px #FFD23F life180ms outward 24px`
*   Win stars: `ScaleEffect stagger 120ms 0->1.2->1 400ms backOut` + `ConfettiParticle 12 particles fall 800ms`
*   Lose shake: `MoveByEffect on camera.viewfinder -4,4 x3 300ms`
*   Button press: `ScaleEffect 0.97 100ms easeOut`

**Sound Files `assets/audio/` (played via `FlameAudio.play(...)`, preloaded via `FlameAudio.audioCache.loadAll([...])` at game boot):**
`place.mp3 120ms plop, collect.mp3 200ms sparkle, shoot.mp3 150ms zap, hit.mp3 100ms thud, explosion.mp3 400ms boom, win.mp3 800ms chime, lose.mp3 600ms buzz, sweep.mp3 500ms whoosh`

**Haptics (if haptics==true, triggered from component event handlers):**
`place->mediumImpact(), hit->lightImpact(), win->heavyImpact(), invalid->vibrate 50ms, sweep->heavyImpact()`

**Settings Toggle:** Custom `SwitchComponent` (`active #FFD23F`, §12) drives sound/haptics via `FlameAudio` global volume 0/1 and a `Haptic` gate.

---

## 24. Edge Cases & QA Checklist (AI Must Pass)

| # | Edge | Expected |
|---|---|---|
| 1 | Tap occupied tile | Shake + toast Occupied, no glow deduction |
| 2 | Insufficient glow | Cost text pulse red, no place |
| 3 | Cooldown active | Show number, no place |
| 4 | Twin on non-bulb | Toast Need Bulb |
| 5 | Mirror with no incoming beam | Idle, no crash, no trace |
| 6 | Prism with no beam | Idle |
| 7 | Multiple mirrors loops | visited set prevents infinite, max depth3 |
| 8 | Shadow eats at 0 hp | Tool removed with puff particle + destroy Effect, shadow resumes walk next frame |
| 9 | Two shadows same tile | Both take beam dmg (ray hits first via hitbox, second in same rect also dmg via area check) |
| 10 | App background pause | `didChangeAppLifecycleState paused -> game.pauseEngine()` (Flame's built-in pause, halts all component `update()` calls) |
| 11 | Back button landscape | Intercept pop: if playing -> pause else pop to map |
| 12 | No sweep left + shadow at x<=0 | Lose immediately |
| 13 | All waves spawned + shadows empty | Win, even if time still running |
| 14 | Hive after kill app | stars/coins still there |
| 15 | Rotate attempt | Show rotate icon component, `game.pauseEngine()` |
| 16 | Bomb on edge | 3x3 clamp to grid, no index error |
| 17 | Glow >999 | Clamp 999 |
| 18 | dt spike >32ms | Flame's own fixed/variable timestep handling clamps this; additionally clamp manually in `update(dt)` to avoid teleport |
| 19 | Component tree churn | Verify `removeFromParent()` is always called after death/destroy Effects complete — orphaned components silently leak and tank frame rate over a long session |
| 20 | World swap (Home→Map→Battle) | Confirm previous `World` and its components are fully disposed (no lingering `ParticleSystemComponent` generators still ticking off-screen) |

**Performance:** Preload JSON + all audio in loading state (`FlameAudio.audioCache.loadAll`). Pool beam/particle components per §15/§18.3. Rely on Flame's component-level dirty/visibility culling rather than a single `shouldRepaint` flag. Test on low-end Android 720p 60FPS via `flutter run --profile`, keep draw calls <50 per frame — monitor via Flame's built-in FPS counter component during dev.

---

## 25. Build Order For AI — Phase Plan (17-18 Days)

Flame architecture setup adds real time up front; budget for it rather than compressing it.

**Phase 0 Day1:** Flame project bootstrap — `FlameGame` root, `CameraComponent` (viewfinder + viewport split), empty `BattleWorld`, verify `GameWidget` renders inside a non-Material root (`WidgetsApp`), confirm landscape lock + 60fps empty-scene baseline.

**Phase 1 Day2-3:** Backdrop/parallax rig (L0-L3: `BackdropLayer`, `DustMoteLayer`, `AmbientGlowLayer`) + `GridComponent`/`TileComponent` (L4) + Glow economy (fall+bulb) + place/remove + Hive + `TopBarComponent`/`RightPanelComponent` HUD shell on `camera.viewport`.

**Phase 2 Day4-7:** `ShadowComponent` walk+eat + `CollisionCallbacks` beam-hit detection + Beam trace (mirror/prism) via `BeamComponent` + HP bars + Sweep + Win/Lose HUD overlays + confirm `update(dt)` propagation replaces manual Ticker correctly.

**Phase 3 Day8-11:** 20 levels JSON + Loadout world pick6 + Scout panel + Cooldowns + Frost slow + Bomb + Twin replace + Jumper leap (`MoveByEffect`) + Giant throw.

**Phase 4 Day12-14:** Full particle inventory (§18.1) + Effects inventory (§18.2) + `EffectPool` implementation + Sounds (`flame_audio`) + Haptics + Stars calc + Coins + Daily + Shop world + Settings world with custom `SwitchComponent`.

**Phase 5 Day15-16:** Ads (banner composited outside `GameWidget` + interstitial + rewarded 1 cap) + IAP Remove Ads + Polish Home/Map worlds (live mini-diorama preview per §12) + Test 812x375 & 1280x720 + Profile 60FPS with FPS counter component + fix any component-leak issues from QA #19-20.

**Phase 6 Day17-18:** Final art-direction pass against §4 (bloom consistency, color-temperature check, no stray Material-like flat fills anywhere) + Build APK/AAB.

**First Run Command:** `flutter create --platforms android,ios,web .` then add deps (§21), then scaffold `LightVsShadowGame`/`CameraComponent` before writing any screen content.

---

## 26. FlameGame Bootstrap Code Snippet For AI

```dart
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

// Color/text tokens as plain constants — no ThemeData, no Material.
class AppColors {
  static const bg = Color(0xFF0A0E1A);
  static const surface = Color(0xFF141A2E);
  static const primary = Color(0xFFFFD23F);
  static const error = Color(0xFFEF5350);
  static const textPrimary = Color(0xFFE8EAF6);
}

TextPaint titleTextPaint() => TextPaint(
  style: TextStyle(
    fontFamily: GoogleFonts.orbitron().fontFamily,
    fontSize: 32, fontWeight: FontWeight.w800,
    color: AppColors.textPrimary, letterSpacing: 1.5,
  ),
);

class LightVsShadowGame extends FlameGame with HasCollisionDetection {
  @override
  Color backgroundColor() => AppColors.bg;

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewfinder.visibleGameSize = Vector2(812, 375);
    world = BattleWorld(); // swap per-screen via router, see §21 structure
    camera.world = world;
    camera.viewport.addAll([
      TopBarComponent(),
      RightPanelComponent(),
    ]);
  }
}

// Root widget — WidgetsApp, NOT MaterialApp. No Material/Cupertino anywhere.
class LightVsShadowApp extends StatelessWidget {
  const LightVsShadowApp({super.key});
  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      color: AppColors.bg,
      builder: (context, _) => GameWidget(game: LightVsShadowGame()),
    );
  }
}
```

**System UI:**
```dart
SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
  statusBarColor: Color(0xFF0A0E1A), statusBarIconBrightness: Brightness.light,
  systemNavigationBarColor: Color(0xFF141A2E),
));
SystemChrome.setPreferredOrientations([
  DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight,
]);
```

---

## 27. AI Generation Prompt — Paste This

> Build a Flutter + Flame landscape-only game LIGHT vs SHADOW per this spec. Use exact hex, exact sizes, exact cooldowns/dmg/speed. No backend, Hive only. Full Flame component architecture: `FlameGame` root with `CameraComponent` (viewfinder for world, viewport for HUD), `World` per screen (Home/Map/Loadout/Battle/Shop/Settings), every tool/shadow/beam/particle as its own component class per §13. Zero Material3, zero Cupertino, zero `Icon(Icons.*)` anywhere — root widget is `WidgetsApp`, all visuals hand-drawn vector in each component's `render(Canvas)` per §4 Art Direction. Implement the L0-L7 parallax/depth layering (§14) using motion-parallax (independent per-layer idle drift/breathing), not camera-scroll parallax, since the battle camera is fixed. Use Flame `Effects` (§18.2) for all animation, `ParticleSystemComponent` (§18.1) for all particles, `CollisionCallbacks`/`RectangleHitbox` for beam-vs-shadow hits. Bridge cross-screen state (glow/coins/stars/save) through Riverpod via `flame_riverpod`; keep per-frame simulation native to component `update(dt)`. Implement placement 7 checks, beam trace depth3 with visited set, wave 50% rule, sweep per lane, stars logic, Hive save, ads composited outside GameWidget with 1 rewarded cap, IAP remove_ads $2.99. Landscape 812x375 formula tile = min(...). Start with Phase 0: FlameGame + CameraComponent bootstrap, verify empty-scene 60fps before adding any gameplay.

---

**Document Version:** 2.0 — Flame Engine Edition (supersedes the pure-Flutter-widgets v1.0 spec)
**Ready to give to any AI — it will generate without questions.**
**Next Steps:** 1) `flutter create` 2) Paste spec to Cursor/Claude 3) Run Phase 0 (Flame bootstrap) before Phase 1
