---
document: Product Requirements Document
authority: Product purpose, users, scope, requirements, non-goals, success
status: Draft
owner: "Solo developer (repo owner)"
last_updated: "2026-09-03"
---

# Product Requirements Document — LIGHT vs SHADOW — Prism Defense

This document defines **what** the product must accomplish and **why**. It is
the product North Star. It does not prescribe folder structure, packages, or
implementation details.

## 1. Product definition

**One-sentence product:**
For casual mobile puzzle-defense players who want a short, fully offline
strategy session, LIGHT vs SHADOW — Prism Defense delivers a PvZ-style
lane-defense loop built on a light-optics puzzle (bending beams with mirrors
and prisms instead of stacking shooters) across 20 hand-authored levels, with
zero login, zero backend, and zero required network connection.

**North Star outcome:**
A player opens the app, completes one satisfying 2-3 minute level in which
their placed tools visibly turn a threatened board into a stable "light net,"
and wants to immediately replay or advance — without ever hitting a login
wall, a loading spinner for remote data, or a broken offline state.

**Problem statement:**
Casual players who want a short, self-contained strategy/puzzle session are
underserved by two extremes: live-ops tower-defense games that demand
connectivity, accounts, and constant content drip, and shallow idle/match
games with no real placement depth. Nothing in the "PvZ-like, 2-3 minute
session, fully offline" niche pairs genuine spatial puzzle depth (light-path
routing, not just DPS math) with a small, finishable, no-backend content set
a solo developer can actually ship and maintain.

**Why now:**
Puzzle is roughly 53% of mobile ad revenue in 2026 and the Block sub-genre is
the #1 puzzle category (per spec §1); a cozy dark-lab/neon-glow visual style
plus satisfying glow/particle effects is well-suited to short vertical social
clips (TikTok/Reels), giving a no-budget solo project a realistic path to
organic discovery without any live-ops or backend investment.

## 2. Users and context

### Primary user — Casual mobile puzzle-defense player

- **Profile:** Plays mobile games in short bursts (commute, break, before
  bed). Has likely played PvZ-style defense games or block/match puzzle games
  (e.g. Block Blast-style "one more try" loops). Not necessarily a hardcore
  strategy gamer.
- **Job to be done:** When I have 2-3 minutes free, I want to play one
  complete, satisfying round of a strategy puzzle, so I can feel a small
  sense of mastery and progress without a big time or attention commitment.
- **Current behavior:** Plays PvZ-likes or block-puzzle games for the
  "one more try" loop, frequently interrupted by forced logins, remote
  content checks, or intrusive ad frequency.
- **Pain points:** Forced network/login screens before play; excessive ad
  interruption; rosters of 40+ units that require memorization; games that
  punish a short session with no clean stopping point.
- **Environment:** Android or iOS phone held landscape; touch input,
  single- or two-hand; may be fully offline (commute, flight); device tier
  varies down to low-end 720p Android; may use larger system text scale or
  be colorblind.
- **Success from their perspective:** Finishes a level in under 3 minutes,
  feels the light-net "click" into place, earns stars/coins, and can jump
  straight into the next level with zero loading friction.

### Secondary user — Optional

- **Profile:** A completionist/collector player motivated by unlocking every
  tool and 3-starring every level.
- **Job to be done:** When I finish the main content, I want to see clear
  progress (stars per level, unlocked tools) and retry cleanly, so I can
  chase full completion.
- **Needs that differ from the primary user:** Clear per-level star tracking
  and low-friction retry to re-earn a missed star; otherwise shares the
  primary user's environment and constraints.

### Explicitly not a target user

Multiplayer/competitive players (no PvP, no leaderboards — no backend to
support them); players expecting live-ops or seasonal content drops (this is
a static, fully offline 20-level package with no remote content pipeline);
players who need cross-device/cloud-synced progress (no login, no backend —
save is local to one device); players seeking deep idle/incremental
progression (the 20-level, 8-tool, 5-enemy content set is the entire v1
scope, not a starting slice of a larger meta-game).

## 3. Product principles

1. **Offline-first, zero backend:** Every decision defaults to what works
   with no network. Only ad-serving and IAP purchase/restore may touch the
   network, and their absence must never block core play.
2. **Puzzle over spam:** Placement is a light-path puzzle (mirror 90°
   reflection, prism 3-way split) — when choosing between a stat-power
   change and a geometry/positioning change, prefer geometry.
3. **Session under 3 minutes:** Every level's wave pacing and UI flow must
   fit a 2-3 minute complete round (per the 20-level par-time table in the
   spec, §9); anything that stretches a level past that gets re-paced or cut.
4. **Solo-buildable scope is the ceiling, not the floor:** 3 lanes x 7 tiles,
   8 tools, 5 shadow types, 20 levels are the full v1 content set. New
   content ideas go to a backlog for a future release, not this one.
5. **One More Try, zero punishment:** Losing must lead straight back into
   play (instant restart, one capped rewarded Glow boost per battle) — never
   into a paywall or a long recovery flow.

## 4. Scope boundaries

### In scope

| ID | Capability | User value | Release |
| --- | --- | --- | --- |
| `PRD-SC-001` | 3-lane x 7-tile battle grid with 8 placeable light tools (Bulb, Beam Lamp, Mirror, Prism, Frost Lens, Shade Block, Flash Bomb, Twin Bulb) | Core puzzle-defense gameplay loop | MVP |
| `PRD-SC-002` | 5 shadow enemy types with distinct behaviors (Shade, Helm Shade/Bucket armor, Leaper/Jumper leap, Veil/Fog resist, Colossus/Giant split) | Teach-then-test difficulty curve keeps sessions engaging | MVP |
| `PRD-SC-003` | 20 hand-authored JSON levels with a wave system, flag (huge) waves, and the 50% pacing rule | Full offline content set, no backend | MVP |
| `PRD-SC-004` | Stars (0-3) and coins reward loop with per-level best-score tracking, plus tool-unlock rewards | Visible progress and reason to replay | MVP |
| `PRD-SC-005` | Loadout screen: scout preview of incoming shadow types, pick 6 of up to 8 unlocked tools before battle | Pre-battle strategic decision layer | MVP |
| `PRD-SC-006` | Local persistence (Hive): stars, coins, unlocked tools, settings, survive a full app kill | Trustworthy offline continuity | MVP |
| `PRD-SC-007` | Pause/resume and app-lifecycle handling (background, rotate-away-from-landscape, back button) | Reliable behavior under normal phone interruptions | MVP |
| `PRD-SC-008` | Monetization: banner (Home/Map only), interstitial (capped 1 per 3 wins), 1 rewarded "+50 Glow" boost per battle, IAP Remove Ads ($2.99) | Solo-sustainable revenue with no backend/live-ops | MVP |
| `PRD-SC-009` | Settings: sound toggle, haptics toggle, reset progress | Player control over experience and data | MVP |
| `PRD-SC-010` | Landscape-only orientation lock (landscapeLeft + landscapeRight) | Matches the grid/HUD layout the whole game is built around | MVP |

### Out of scope — what this product will not do

This section is binding. An out-of-scope item requires an explicit PRD change
before implementation.

| ID | Not included | Reason | Revisit trigger |
| --- | --- | --- | --- |
| `PRD-NS-001` | Multiplayer, PvP, leaderboards | No backend exists or is planned; protects solo scope | A backend investment is separately justified by demonstrated demand |
| `PRD-NS-002` | Cloud save, cross-device sync, login/accounts | Hard constraint: no backend, no login | A publisher or platform requirement forces an account system |
| `PRD-NS-003` | Live-ops, seasonal events, remote config, server-driven content | Offline-first hard constraint; content is a static bundled package | Dedicated content-ops capacity becomes available (not currently planned) |
| `PRD-NS-004` | More than 8 tools, 5 shadow types, or 20 levels in v1 | Protects the solo 4-5 week build budget (spec §21/§25) | v1 ships and retention/demand data justifies a content-pack follow-up |
| `PRD-NS-005` | Portrait orientation support | The grid/HUD layout formula (spec §11) is landscape-only by design | Not planned to revisit |
| `PRD-NS-006` | Any network call other than ad SDK requests and IAP purchase/restore | Offline-first hard constraint | Not planned to revisit |
| `PRD-NS-007` | Subscriptions or any consumable IAP beyond the two defined store items (Tray Slot +2 for coins, Remove Ads for $2.99) | Spec limits the store to two SKUs (§20) | Monetization underperforms and a broader store is deliberately proposed |

### Assumptions

| ID | Assumption | Evidence | Risk if false | Validation date/method |
| --- | --- | --- | --- | --- |
| `PRD-A-001` | Players will tolerate 1 rewarded ad per battle plus an interstitial every 3 wins without abandoning the app | Unvalidated (design targets from spec §20) | Ad fatigue drives churn and bad reviews | Post-launch D1/D7 retention and review sentiment vs. this cadence |
| `PRD-A-002` | 20 levels at the documented difficulty curve (spec §9) provide enough content for a satisfying first-week experience | Unvalidated (spec estimate only) | Content runs out too fast; players churn after level 20 with nothing next | D7/D30 level-completion and re-open data post-launch |
| `PRD-A-003` | The optics mechanic (mirror 90° reflect, prism 3-way split) reads as clear and fun through in-level teaching alone (1 new tool per level, safe lane first, levels 1-4), with no separate tutorial screen | Unvalidated | New players don't understand beam bending and churn in levels 1-4 | Playtesting before wide release; watch level 1-4 abandon rate |
| `PRD-A-004` | Low-end 720p Android hardware can sustain 60 FPS and <50 draw calls/frame with the full parallax + particle stack (spec §14/§18) as specified | Unvalidated | Performance NFR (`PRD-NFR-001`) fails on real target hardware | Profile testing (`flutter run --profile`) on a low-end 720p device before release, per spec §24 |

## 5. Core user journeys

### Journey `UJ-01` — Pick a loadout, play a level, win

- **Actor:** Primary user
- **Trigger:** Taps a level card on the Level Map, or taps Play from Home.
- **Preconditions:** At least level 1 is unlocked (always true from first
  launch).
- **Happy path:**
  1. Player opens Loadout for the selected level; the Scout panel lists
     incoming shadow types and counts (e.g. "Bucket x2, Veil x1"); player
     picks exactly 6 of their unlocked tools, and Start Battle becomes
     enabled.
  2. Player places tools on the 3x7 grid as Glow accumulates from the
     starting stock, falling orbs, and any placed Bulbs; beams trace through
     Mirrors/Prisms and damage Shadows across scheduled waves.
  3. Player survives until all waves have spawned and no shadows remain —
     the Win dialog shows stars earned, coins awarded, and any tool unlock.
- **Alternative/edge paths:** Player runs short on tools and a shadow
  reaches a lane whose Sweep is already used, ending in Lose instead; player
  backgrounds the app mid-battle and the game auto-pauses; player spends the
  one rewarded Glow boost when the economy is tight (see `UJ-03`).
- **Failure recovery:** The Lose dialog offers an instant "Try Again"
  restart with no data loss — any stars/coins already banked from prior wins
  on other levels are untouched; the failed attempt itself grants nothing.
- **Completion signal:** Win dialog is shown and the save is updated
  (`stars[levelId-1]`, `coins`, `maxUnlocked` possibly incremented, a tool
  added to `unlocked` if the level grants one).
- **Mapped requirements:** `PRD-FR-001`, `PRD-FR-002`, `PRD-FR-003`,
  `PRD-FR-004`, `PRD-FR-005`, `PRD-FR-006`, `PRD-FR-007`, `PRD-FR-008`,
  `PRD-FR-009`, `PRD-FR-010`, `PRD-FR-011`, `PRD-FR-012`, `PRD-FR-014`,
  `PRD-FR-020`

### Journey `UJ-02` — Reopen the app after a full kill and pick up where they left off

- **Actor:** Returning primary user
- **Trigger:** Reopens the app after force-closing it (or a normal OS kill).
- **Preconditions:** Has played at least one prior session with a save
  written (or this is the very first launch).
- **Happy path:**
  1. App launches and the local Hive `save` box loads.
  2. Home/Map screens show stars, coins, and unlocked tools/levels exactly
     as left before the kill.
  3. Player continues immediately — no re-login, no remote fetch, no
     loading screen tied to a network call.
- **Alternative/edge paths:** First-ever launch has no existing save, so
  defaults apply (0 coins, all stars 0, only `bulb`/`beam`/`wall` unlocked,
  `maxUnlocked=1`).
- **Failure recovery:** Not applicable — the read is local and synchronous;
  there is no network failure path to recover from.
- **Completion signal:** Map/Home screens reflect state identical to before
  the app was killed.
- **Mapped requirements:** `PRD-FR-013`, `PRD-FR-019`

### Journey `UJ-03` — Use the one capped rewarded Glow boost mid-battle

- **Actor:** Primary user under economic pressure mid-battle.
- **Trigger:** Player taps the RightPanel "+50 GLOW" boost button.
- **Preconditions:** `usedBoost==false && !removeAds && rewardedLoaded`.
- **Happy path:**
  1. Player taps the boost button (shown enabled, not dimmed).
  2. A rewarded ad plays to completion.
  3. On the reward callback, Glow increases by 50, `usedBoost` becomes
     `true`, the button dims to 0.4 opacity for the rest of the battle, and
     a Glow-burst particle plays.
- **Alternative/edge paths:** `removeAds` is owned, or no rewarded ad is
  currently loaded — the button stays disabled/dimmed and nothing happens on
  tap; the boost is capped at 1 use regardless of any of these states.
- **Failure recovery:** If the ad fails to load, the player simply continues
  the battle without the boost; no progress or Glow is lost.
- **Completion signal:** Glow increases by exactly 50, exactly once, for
  that battle.
- **Mapped requirements:** `PRD-FR-002`, `PRD-FR-017`

## 6. Functional requirements

Requirements state observable behavior, not implementation. Use "must" for a
release requirement and give every requirement testable acceptance criteria.

### `PRD-FR-001` — Tool placement validation

- **Statement:** The product must validate every placement attempt against
  the ordered checks — battle is playing, tile is within the 3x7 grid, tile
  is empty, player has enough Glow, the tool's cooldown has elapsed, a Twin
  Bulb may only replace an existing Bulb — before creating a tool, and give
  clear, non-color-only feedback on the first failing check.
- **User/value:** Primary player; prevents wasted taps and keeps the Glow
  economy trustworthy.
- **Priority:** Must
- **Journey:** `UJ-01`
- **Preconditions:** `state==playing`; a tool is selected from the tray or
  being dragged.
- **Acceptance criteria:**
  - Given the player taps an already-occupied tile with a tool selected,
    when placement is attempted, then the tile shakes, a heavy haptic fires,
    an "Occupied" toast appears, and no Glow is deducted.
  - Given the player has less Glow than the tool's cost (e.g. 42 Glow vs. a
    Beam Lamp's cost of 100), when placement is attempted, then the cost
    number pulses red and no tool is placed.
  - Given the player tries to place a Twin Bulb (cost 125) on a tile that is
    not an existing Glow Bulb, when placement is attempted, then a "Need
    Bulb" toast shows and no replacement occurs.
  - Given all checks pass, when placement completes, then Glow is deducted
    by the tool's cost, the tool is created with its placement pop
    animation, and that tool's cooldown timer starts.
- **Data involved:** Tool id, cost, cooldown, grid row/col, current Glow,
  per-tool last-placed timestamp.
- **Dependencies:** `PRD-FR-002`
- **Excluded behavior:** No partial refund on a failed placement attempt.
  Removing an already-placed tool (long-press, no refund) is a separate
  interaction and is not governed by this requirement.

### `PRD-FR-002` — Glow economy

- **Statement:** The product must generate and let the player collect Glow
  from three sources — starting stock, timed falling orbs, and
  Bulb/Twin Bulb auto-generation — with an upper display cap.
- **User/value:** Primary player; Glow is the resource that gates every
  placement decision, so its pacing drives the whole strategy layer.
- **Priority:** Must
- **Journey:** `UJ-01`, `UJ-03`
- **Preconditions:** Battle is in progress.
- **Acceptance criteria:**
  - Given a battle starts, when the level loads, then Glow begins at the
    level's `startGlow` value (50 for most levels, 75 for Level 16).
  - Given fewer than 2 Glow orbs are currently on screen, when 8.0 seconds
    have passed since the last orb spawned, then a new falling orb worth +25
    spawns and can be collected by tapping within a 40px radius.
  - Given a placed Glow Bulb is alive, when 10.0 seconds pass since its last
    generation tick, then Glow increases automatically by +25 (or +50 for a
    Twin Bulb) with no tap required.
  - Given any Glow-adding event would push the total above 999, when that
    event fires, then Glow is clamped to 999.
- **Data involved:** `startGlow` (per level), orb value (25), orb spawn
  interval (8.0s), orb collect radius (40px), Bulb gen (+25/10s), Twin Bulb
  gen (+50/10s), cap (999).
- **Dependencies:** `PRD-FR-001`
- **Excluded behavior:** Glow never decreases except through a successful
  tool placement's cost; there is no interest or multiplier mechanic.

### `PRD-FR-003` — Beam optics: Mirror 90° reflection

- **Statement:** The product must reflect an incoming rightward beam 90° at
  a Mirror tile, with the outgoing direction determined by the mirror's row.
- **User/value:** Primary player; this is the core puzzle mechanic that
  redirects damage into otherwise-uncovered lanes.
- **Priority:** Must
- **Journey:** `UJ-01`
- **Preconditions:** A Mirror is placed and a beam reaches it traveling
  right.
- **Acceptance criteria:**
  - Given a Mirror is placed in row 0 (top lane), when a rightward beam
    reaches it, then the beam continues in the Down direction from the
    mirror's position.
  - Given a Mirror is placed in row 2 (bottom lane), when a rightward beam
    reaches it, then the beam continues Up.
  - Given a Mirror is placed in row 1 (middle lane), when a rightward beam
    reaches it, then the beam continues Down or Up depending on the current
    trace recursion depth (even depth → down, odd depth → up).
- **Data involved:** Mirror cost 50, cooldown 10s, HP 150; beam direction.
- **Dependencies:** `PRD-FR-005`
- **Excluded behavior:** A Mirror does not reflect a beam arriving from any
  direction other than right in v1.

### `PRD-FR-004` — Beam optics: Prism 3-way split

- **Statement:** The product must split an incoming rightward beam at a
  Prism tile into three simultaneous rays (continuing right, up, and down),
  each carrying 60% of the incoming beam's damage.
- **User/value:** Primary player; lets one Beam Lamp cover all three lanes
  from a single investment, at a damage cost.
- **Priority:** Must
- **Journey:** `UJ-01`
- **Preconditions:** A Prism is placed and a beam of damage D reaches it
  traveling right.
- **Acceptance criteria:**
  - Given a Prism receives a rightward beam of damage D, when the trace
    processes the prism, then three new rays are created — right (gold,
    `#FFD23F`), up (violet, `#AB47BC`), down (green, `#66BB6A`) — each
    carrying damage `D * 0.6`.
  - Given each split ray hits a different lane's shadow, when damage is
    applied, then each shadow independently takes its own 60%-damage tick.
- **Data involved:** Prism cost 150, cooldown 15s, HP 100, split factor 0.6.
- **Dependencies:** `PRD-FR-005`
- **Excluded behavior:** A Prism never increases total damage delivered to
  a single target above the source beam's own value; the 0.6x factor applies
  per split lane, not stacked.

### `PRD-FR-005` — Beam trace depth limit and loop prevention

- **Statement:** The product must cap beam trace recursion at depth 3 and
  prevent infinite loops between Mirrors/Prisms using a visited
  position-and-direction set.
- **User/value:** Primary player and the app itself; guarantees the game
  never hangs or crashes from a player-built mirror loop.
- **Priority:** Must
- **Journey:** `UJ-01`
- **Preconditions:** A beam trace is in progress.
- **Acceptance criteria:**
  - Given a beam trace recursion reaches a depth greater than 3, when the
    trace step runs, then it stops immediately with no further ray
    segments created.
  - Given two or more Mirrors are arranged to form a loop, when a beam is
    traced through them, then the visited set (keyed by position and
    direction) prevents the same ray segment from being processed twice,
    so no infinite loop or crash occurs.
  - Given a Mirror or Prism currently has no incoming beam, when the battle
    tick runs, then it sits idle with no trace call and no error.
- **Data involved:** Max depth 3; visited-set key of position + direction.
- **Dependencies:** `PRD-FR-003`, `PRD-FR-004`
- **Excluded behavior:** No UI warning is shown to the player when a
  depth-3 cutoff truncates a beam path; the truncation is silent by design.

### `PRD-FR-006` — Shadow movement, eating, and special behaviors

- **Statement:** The product must move each of the 5 shadow types toward
  the player's side at its defined speed, have it eat the tool blocking its
  lane, and execute its unique special behavior: Helm Shade (Bucket) has
  high HP that visibly cracks before death, Leaper (Jumper) leaps the first
  Shade Block it meets, Veil (Fog) resists 30% of beam damage until hit by a
  Frost Lens beam, Colossus (Giant) spawns one Basic shadow at 50% of its
  own max HP.
- **User/value:** Primary player; distinct enemy behaviors are what teach
  and test the tool set across the 20-level curve.
- **Priority:** Must
- **Journey:** `UJ-01`
- **Preconditions:** Shadow has spawned and is on the grid.
- **Acceptance criteria:**
  - Given a Shade (Basic, 100 HP, 12 px/s) has no tool blocking its lane,
    when its update tick runs, then it moves left at 12 px/s.
  - Given any shadow reaches a tool in its lane, when its update tick runs,
    then it stops walking and reduces the tool's HP by its eat rate per
    second (20/s for all types except Colossus/Giant at 40/s); if the
    tool's HP reaches 0, the tool is destroyed with a puff effect and the
    shadow resumes walking on the next frame.
  - Given a Leaper (120 HP, 14 px/s) has not yet jumped and comes within
    20px of a Shade Block, when its update tick runs, then it performs a
    48px arc leap (300ms) over the block instead of eating it, and will
    never jump again for the rest of that shadow's life.
  - Given a Veil (150 HP, 10 px/s) is hit by a non-Frost beam, when damage
    is applied, then only 70% of that beam's damage lands (30% resisted)
    until a Frost Lens beam hits it.
  - Given a Colossus (600 HP, 8 px/s) drops to 50% of its own max HP for the
    first time, when its update tick runs, then it spawns one Basic shadow
    at `x+40` in the same lane, exactly once per Colossus.
- **Data involved:** Per-shadow HP/speed/eat table (Shade 100/12/20, Helm
  Shade 250/12/20, Leaper 120/14/20, Veil 150/10/20, Colossus 600/8/40) and
  first-appearance level (1, 5, 8, 12, 16 respectively).
- **Dependencies:** `PRD-FR-003`, `PRD-FR-004`, `PRD-FR-007`
- **Excluded behavior:** Shadows never change lanes; only Leaper has a leap
  ability and only Colossus has a spawn ability — no other cross-type
  behavior sharing.

### `PRD-FR-007` — Wave system: scheduled spawns and flag waves

- **Statement:** The product must spawn each level's shadows according to
  its JSON-defined wave list (a delay in seconds from level start, and a
  lane per shadow), and mark any wave flagged `"flag": true` as a huge wave
  shown distinctly in the TopBar's flag row.
- **User/value:** Primary player; the wave rhythm is the core tension/relief
  cycle of the loop.
- **Priority:** Must
- **Journey:** `UJ-01`
- **Preconditions:** Battle is in progress; level JSON is loaded.
- **Acceptance criteria:**
  - Given a level's waves array (e.g. Level 1: wave 0 at delay 12s with one
    Shade in lane 1; wave 1, flagged, at delay 22s with 3 Shades), when
    battle time reaches each wave's delay and the 50% rule (`PRD-FR-008`)
    allows it, then that wave's shadows spawn at the grid's right edge in
    their assigned lanes.
  - Given a wave has `"flag": true`, when it becomes the upcoming wave, then
    the TopBar's flag row shows a highlighted/pulsing flag icon in place of
    a plain dot.
  - Given all of a level's waves have spawned, when the last remaining
    shadow dies or is swept, then the win condition (`PRD-FR-010`) becomes
    eligible.
- **Data involved:** `level.waves[].delay`, `.flag`, `.shadows[].id`,
  `.shadows[].lane`.
- **Dependencies:** `PRD-FR-006`, `PRD-FR-008`
- **Excluded behavior:** Wave order and content are fixed per level's JSON;
  there is no dynamic difficulty adjustment.

### `PRD-FR-008` — Wave pacing: the 50% rule

- **Statement:** The product must gate every wave after the first behind
  either "at least 50% of the previous wave's total starting HP has been
  depleted" or "20 seconds have passed since the previous wave started," in
  addition to that wave's own scheduled delay.
- **User/value:** Primary player; produces the "teach then test" pressure
  rhythm instead of a flat spawn timer or a spam wall.
- **Priority:** Must
- **Journey:** `UJ-01`
- **Preconditions:** At least one wave has already spawned.
- **Acceptance criteria:**
  - Given wave N-1 spawned shadows totaling HP `T`, when the combined
    current HP of surviving wave-(N-1) shadows drops below `T * 0.5`, then
    wave N becomes eligible to spawn once its own delay has also elapsed.
  - Given wave N-1's survivors still hold ≥50% combined HP, when 20.0
    seconds have elapsed since wave N-1 started, then wave N becomes
    eligible anyway.
  - Given wave 0 (the level's first wave), when battle time reaches its
    scheduled delay, then it spawns unconditionally with no prior-wave
    check.
- **Data involved:** 50% HP threshold; 20.0s timeout.
- **Dependencies:** `PRD-FR-007`
- **Excluded behavior:** The 50% rule never blocks a wave whose own delay
  has not yet been reached, even if the prior wave is already fully
  cleared.

### `PRD-FR-009` — Sweep (lawnmower)

- **Statement:** The product must give each of the 3 lanes exactly one
  single-use Sweep that auto-triggers when any shadow in that lane reaches
  `x <= 12`, killing every shadow currently in that lane and permanently
  consuming that lane's Sweep for the rest of the battle.
- **User/value:** Primary player; a last-resort safety net that also creates
  the risk/reward of "used vs. unused" lane vulnerability.
- **Priority:** Must
- **Journey:** `UJ-01`
- **Preconditions:** Battle in progress; the lane's Sweep has not yet been
  used.
- **Acceptance criteria:**
  - Given lane 1's Sweep has not been used, when a shadow in lane 1 reaches
    `x<=12`, then every shadow currently in lane 1 is removed, a 20-particle
    radial sweep burst plays, the lane's sweep stripe fades out, and that
    lane's Sweep becomes unavailable for the rest of the battle.
  - Given lane 1's Sweep has already been used, when another shadow in lane
    1 reaches `x<=0`, then no sweep triggers and the lose condition
    (`PRD-FR-011`) is checked instead.
- **Data involved:** Sweep trigger threshold `x<=12`; per-lane boolean
  availability (3 lanes); lose threshold `x<=0`.
- **Dependencies:** `PRD-FR-011`
- **Excluded behavior:** A used Sweep never regenerates or refills mid-
  battle — exactly one use per lane per battle.

### `PRD-FR-010` — Win condition

- **Statement:** The product must declare the battle won the instant all of
  a level's waves have spawned and no shadows remain alive on the grid.
- **User/value:** Primary player; a clear, immediate, unambiguous success
  signal.
- **Priority:** Must
- **Journey:** `UJ-01`
- **Preconditions:** Battle in progress.
- **Acceptance criteria:**
  - Given every wave in the level has spawned and no shadow remains alive,
    when the battle tick evaluates terminal state, then the game transitions
    to Won and shows the Win overlay, even if the level's par time has not
    elapsed.
  - Given the Won transition fires, when the win handler runs, then stars
    and coins are calculated and the save is updated (`PRD-FR-012`) before
    the overlay is fully visible.
- **Data involved:** Spawned-wave count vs. total wave count; live shadow
  count.
- **Dependencies:** `PRD-FR-007`, `PRD-FR-012`
- **Excluded behavior:** There is no time-based win condition (surviving
  until a clock expires); winning is purely wave-completion plus
  board-clear.

### `PRD-FR-011` — Lose condition

- **Statement:** The product must declare the battle lost immediately when
  any shadow reaches `x<=0` in a lane whose Sweep has already been used.
- **User/value:** Primary player; a clear, immediate failure signal tied
  directly to a resource the player controlled (their Sweep usage).
- **Priority:** Must
- **Journey:** `UJ-01`
- **Preconditions:** Battle in progress.
- **Acceptance criteria:**
  - Given a lane's Sweep has already been used and a shadow in that lane
    reaches `x<=0`, when the battle tick evaluates terminal state, then the
    game transitions to Lost, the camera shakes, and the Lose overlay shows
    with the hint "Try more Bulbs early!".
  - Given a shadow reaches `x<=0` in a lane whose Sweep is still available,
    when the battle tick evaluates, then the Sweep triggers instead
    (`PRD-FR-009`) and the battle does not end.
- **Data involved:** Per-lane Sweep availability; shadow `x` position.
- **Dependencies:** `PRD-FR-009`
- **Excluded behavior:** There is no partial health-pool loss condition —
  loss is binary and immediate on the defined trigger.

### `PRD-FR-012` — Stars and coins reward

- **Statement:** The product must calculate and award stars and coins on
  Win, and persist any improvement over the player's prior best for that
  level.
- **User/value:** Primary and secondary user; the visible reward for a
  completed session and the reason to replay for a better score.
- **Priority:** Must
- **Journey:** `UJ-01`
- **Preconditions:** Battle has just transitioned to Won.
- **Acceptance criteria:**
  - Given a level is won with a `newStars` value greater than the
    previously saved stars for that level, when the win handler runs, then
    `save.stars[levelId-1]` is updated to the new higher value and coins
    increase by `(newStars - old) * 10 + 20`.
  - Given a level is won with `newStars` not greater than the previous
    best, when the win handler runs, then `save.stars[levelId-1]` is
    unchanged and coins still increase by 10.
  - Given the just-won level equals the current `maxUnlocked`, when the win
    handler runs, then `save.maxUnlocked` increments by 1, unlocking the
    next level.
  - Given the level's `unlockReward` names a tool (e.g. `"mirror"` on the
    level 5-7 band), when the win handler runs for that level, then that
    tool id is added to `save.unlocked`.
- **Data involved:** `save.stars[20]`, `save.coins`, `save.maxUnlocked`,
  `save.unlocked`, `level.unlockReward`.
- **Dependencies:** `PRD-FR-010`, `PRD-FR-013`
- **Excluded behavior:** Stars and coins are never awarded on Lose; there is
  no partial-credit reward for an incomplete attempt.

### `PRD-FR-013` — Level unlock and progression persistence

- **Statement:** The product must gate level access by `save.maxUnlocked`
  and persist all progression fields (coins, stars, unlocked tools,
  `maxUnlocked`, total plays) to local storage so they survive a full app
  kill.
- **User/value:** Primary and secondary user; guarantees progress is never
  lost and levels unlock in a predictable sequence.
- **Priority:** Must
- **Journey:** `UJ-02`
- **Preconditions:** App has a save (or is launching for the first time).
- **Acceptance criteria:**
  - Given `save.maxUnlocked==5`, when the Level Map renders, then levels 1-5
    show as playable and levels 6-20 show as locked.
  - Given the app is fully force-killed and relaunched, when the Home/Map
    screen loads, then all previously saved stars, coins, unlocked tools,
    and `maxUnlocked` display identically to their state before the kill.
  - Given it is the player's first-ever launch (no existing save), when the
    app initializes, then defaults apply: `coins=0`, all `stars=0`,
    `unlocked={"bulb","beam","wall"}`, `maxUnlocked=1`, `removeAds=false`,
    `sound=true`, `haptics=true`.
- **Data involved:** Hive box `save` (typeId 0): `coins`, `stars[20]`,
  `unlocked`, `removeAds`, `sound`, `haptics`, `maxUnlocked`, `totalPlays`.
- **Dependencies:** None (foundational).
- **Excluded behavior:** No cloud sync or cross-device restore of this
  save; it is single-device local storage only.

### `PRD-FR-014` — Loadout: scout preview and 6-of-8 tool pick

- **Statement:** The product must show which shadow types are incoming for
  the selected level (Scout preview) and require picking exactly 6 of the
  player's unlocked tools before Start Battle is enabled.
- **User/value:** Primary player; turns tool selection into an informed
  pre-battle strategic decision.
- **Priority:** Must
- **Journey:** `UJ-01`
- **Preconditions:** A level has been selected from the Map.
- **Acceptance criteria:**
  - Given a level is selected, when the Loadout screen loads, then the
    Scout panel lists each distinct incoming shadow type with its count
    (e.g. "Bucket x2, Veil x1").
  - Given fewer than 6 tools are currently selected, when the player views
    the Start Battle button, then it is disabled (dimmed to ~0.5 opacity)
    and cannot start the battle.
  - Given exactly 6 tools are selected, when the player taps Start Battle,
    then the battle begins with only those 6 tools available in the
    in-battle tray.
- **Data involved:** `level.availableTools`/`save.unlocked` (eligible
  tools), current selection count, tray slot count (6).
- **Dependencies:** `PRD-FR-013`
- **Excluded behavior:** The player cannot proceed with more or fewer than
  6 tools selected; there is no mid-battle tray reconfiguration.

### `PRD-FR-015` — App lifecycle: pause on background, rotation, and back

- **Statement:** The product must pause all gameplay simulation the instant
  the app is backgrounded or the device rotates away from landscape, and
  intercept the back action during battle to open Pause instead of exiting.
- **User/value:** Primary player; prevents lost/unfair progress from normal
  phone interruptions (a call, a notification, a pocket rotation).
- **Priority:** Must
- **Journey:** `UJ-02`
- **Preconditions:** `state==playing`.
- **Acceptance criteria:**
  - Given a battle is in progress, when the app receives a backgrounded
    lifecycle event, then the game engine pauses (no component advances)
    and resumes exactly where it left off on foreground.
  - Given the device rotates away from landscape mid-battle, when the
    orientation change is detected, then the game pauses and a rotate-back
    prompt is shown until landscape is restored.
  - Given the player triggers the back action while `state==playing`, when
    it is intercepted, then the Pause overlay opens instead of exiting the
    app; if not playing (e.g. on the Map), back instead pops to the
    previous screen.
- **Data involved:** App lifecycle state; device orientation; current game
  state enum.
- **Dependencies:** None.
- **Excluded behavior:** Pausing does not autosave partial mid-battle
  progress — only a completed Win or Lose result is persisted
  (`PRD-FR-012`).

### `PRD-FR-016` — Ads: banner and interstitial

- **Statement:** The product must show a banner ad on Home/Map only (never
  during Battle) and an interstitial after every 3rd level win, both fully
  suppressed once Remove Ads is owned.
- **User/value:** Solo developer (monetization); primary player (ads never
  interrupt the actual battle screen).
- **Priority:** Must
- **Journey:** `UJ-01`
- **Preconditions:** `save.removeAds==false`.
- **Acceptance criteria:**
  - Given `save.removeAds==false` and the player is on Home or Map, when
    those screens render, then a bottom banner ad (50h) is shown; given the
    player enters Battle, no banner is shown.
  - Given `save.removeAds==false`, an interstitial is loaded, and the
    just-won level's id is divisible by 3, when the Win overlay has been
    visible for 500ms, then the interstitial shows.
  - Given `save.removeAds==true`, when any screen renders, then no banner
    or interstitial ever shows, regardless of level id or win count.
- **Data involved:** `save.removeAds`, `levelId`, interstitial-loaded flag.
- **Dependencies:** `PRD-FR-018`
- **Excluded behavior:** No interstitial ever shows on Lose; no ad of any
  kind shows during Battle itself.

### `PRD-FR-017` — Rewarded Glow boost, capped once per battle

- **Statement:** The product must offer exactly one rewarded-ad-gated "+50
  Glow" boost per battle via the RightPanel HUD button, disabled once used
  for the remainder of that battle.
- **User/value:** Primary player; a controlled comeback mechanic that does
  not let ads be spammed for repeated advantage.
- **Priority:** Must
- **Journey:** `UJ-03`
- **Preconditions:** `usedBoost==false && !removeAds && rewardedLoaded`.
- **Acceptance criteria:**
  - Given the preconditions hold, when the player taps the boost button,
    then a rewarded ad plays; on the reward callback, Glow increases by 50,
    `usedBoost` becomes `true`, and the button dims to 0.4 opacity for the
    rest of the battle.
  - Given `usedBoost==true`, when the player looks at the button, then it
    stays disabled for the remainder of the current battle regardless of
    further taps.
  - Given no rewarded ad is currently loaded, when the player taps the
    button, then nothing happens and no crash occurs; the button stays in
    its disabled/loading visual state.
- **Data involved:** `usedBoost` (per-battle flag, resets each new battle),
  rewarded-loaded flag, +50 Glow amount.
- **Dependencies:** `PRD-FR-002`
- **Excluded behavior:** The boost never grants more than 50 Glow or more
  than once per battle; it does not revive a lost battle — it is a
  mid-battle economy aid, not a continue.

### `PRD-FR-018` — IAP Remove Ads

- **Statement:** The product must offer a single non-consumable "Remove
  Ads" purchase ($2.99) that permanently disables banner and interstitial
  ads once purchased, with restore-purchase support.
- **User/value:** Primary player who prefers a one-time payment over ad
  interruptions; solo developer (monetization).
- **Priority:** Must
- **Journey:** `UJ-01`
- **Preconditions:** Player initiates the purchase from the Shop.
- **Acceptance criteria:**
  - Given the player buys `remove_ads`, when `purchaseStatus==purchased` is
    received, then `save.removeAds` is set `true` and persisted, and banner
    and interstitial ads stop appearing immediately with no app restart
    required.
  - Given a returning player on the same store account taps Restore
    Purchases, when the restore completes, then `save.removeAds=true` is
    re-applied if the entitlement exists.
  - Given `save.removeAds` is already `true`, when the Shop screen renders,
    then Remove Ads shows as owned/disabled rather than purchasable again.
- **Data involved:** `save.removeAds`; product id `remove_ads`; price $2.99
  (exact store price-tier mapping is an open decision, `PRD-Q-007`).
- **Dependencies:** `PRD-FR-016`
- **Excluded behavior:** No server-side receipt validation (per the
  no-backend constraint); no subscription tier; the rewarded Glow boost
  (`PRD-FR-017`) remains capped at 1/battle even after this purchase.

### `PRD-FR-019` — Settings: sound, haptics, reset progress

- **Statement:** The product must let the player independently toggle sound
  and haptics, and reset progression fields back to first-launch defaults,
  with each toggle taking effect immediately.
- **User/value:** Primary player; control over the experience and their own
  data.
- **Priority:** Must
- **Journey:** `UJ-02`
- **Preconditions:** Player is on the Settings screen.
- **Acceptance criteria:**
  - Given `save.sound==true`, when the player taps the Sound toggle, then
    `save.sound` flips to `false` and all subsequent audio playback is
    muted without leaving Settings.
  - Given `save.haptics==true`, when the player taps the Haptics toggle,
    then `save.haptics` flips to `false` and no further haptic feedback
    fires until re-enabled.
  - Given the player taps "Reset Progress" and confirms, when the reset
    executes, then `coins`, `stars[20]`, `unlocked`, and `maxUnlocked` are
    rewritten to first-launch defaults. Whether `removeAds`/`sound`/
    `haptics` are also reset is not specified by the source spec — see
    `PRD-Q-008`.
- **Data involved:** `save.sound`, `save.haptics`, reset action scope.
- **Dependencies:** `PRD-FR-013`
- **Excluded behavior:** Reset Progress requires no network or account
  re-verification; it is fully local.

### `PRD-FR-020` — Landscape orientation lock

- **Statement:** The product must lock the entire app to landscape
  orientation (landscapeLeft + landscapeRight) and correctly scale the
  layout across supported viewport sizes without clipping or overlap.
- **User/value:** Primary player; the whole grid/HUD layout is designed
  around a single orientation, so this keeps the experience coherent on any
  device.
- **Priority:** Must
- **Journey:** `UJ-01`
- **Preconditions:** App is running.
- **Acceptance criteria:**
  - Given the app launches on any supported device, when orientation is
    set, then only landscapeLeft and landscapeRight are permitted; portrait
    is never presented.
  - Given the baseline layout is authored at 812x375, when the actual
    device viewport differs (e.g. 1280x720), then the tile-size formula
    produces a correctly scaled, non-clipped, non-overlapping grid and HUD.
  - Given the OS attempts a portrait rotation mid-battle, when detected,
    then the pause-and-prompt behavior of `PRD-FR-015` applies rather than
    a portrait-scaled layout appearing.
- **Data involved:** Preferred orientations; baseline viewport 812x375;
  example scaled target 1280x720.
- **Dependencies:** `PRD-FR-015`
- **Excluded behavior:** No portrait-mode layout is ever designed or
  shipped.

### Requirement index

Status vocabulary (defined in [`prd-story.md`](./prd-story.md) §8):
`Proposed` written, not built · `Built` code exists, no test proves it ·
`Tested` covered by a test known to fail without the feature ·
`Verified` confirmed on real hardware · `Deferred` descoped for this release.

| ID | Title | Priority | Journey | Release | Status |
| --- | --- | --- | --- | --- | --- |
| `PRD-FR-001` | Tool placement validation | Must | `UJ-01` | MVP | Tested |
| `PRD-FR-002` | Glow economy | Must | `UJ-01`, `UJ-03` | MVP | Tested |
| `PRD-FR-003` | Beam optics: Mirror 90° reflection | Must | `UJ-01` | MVP | Tested |
| `PRD-FR-004` | Beam optics: Prism 3-way split | Must | `UJ-01` | MVP | Tested |
| `PRD-FR-005` | Beam trace depth limit and loop prevention | Must | `UJ-01` | MVP | Tested |
| `PRD-FR-006` | Shadow movement, eating, and special behaviors | Must | `UJ-01` | MVP | Tested |
| `PRD-FR-007` | Wave system: scheduled spawns and flag waves | Must | `UJ-01` | MVP | Tested |
| `PRD-FR-008` | Wave pacing: the 50% rule | Must | `UJ-01` | MVP | Tested |
| `PRD-FR-009` | Sweep (lawnmower) | Must | `UJ-01` | MVP | Tested |
| `PRD-FR-010` | Win condition | Must | `UJ-01` | MVP | Tested |
| `PRD-FR-011` | Lose condition | Must | `UJ-01` | MVP | Tested |
| `PRD-FR-012` | Stars and coins reward | Must | `UJ-01` | MVP | Tested |
| `PRD-FR-013` | Level unlock and progression persistence | Must | `UJ-02` | MVP | Tested |
| `PRD-FR-014` | Loadout: scout preview and 6-of-8 tool pick | Must | `UJ-01` | MVP | Tested |
| `PRD-FR-015` | App lifecycle: pause on background, rotation, and back | Must | `UJ-02` | MVP | Tested |
| `PRD-FR-016` | Ads: banner and interstitial | Must | `UJ-01` | MVP | Deferred |
| `PRD-FR-017` | Rewarded Glow boost, capped once per battle | Must | `UJ-03` | MVP | Deferred |
| `PRD-FR-018` | IAP Remove Ads | Must | `UJ-01` | MVP | Deferred |
| `PRD-FR-019` | Settings: sound, haptics, reset progress | Must | `UJ-02` | MVP | Tested |
| `PRD-FR-020` | Landscape orientation lock | Must | `UJ-01` | MVP | Verified |

The Status column tracks build/verification progress against the vocabulary
above; it is not the requirement's approval state. Every requirement listed
here is approved — a withdrawn one is marked `Deferred` and says so in its
own section. Phase and task sequencing stays in `implementation_plan.md`.

## 7. Non-functional requirements

Use measurable thresholds. "Fast," "secure," and "scalable" are not
sufficient.

| ID | Category | Requirement | Measurement / acceptance |
| --- | --- | --- | --- |
| `PRD-NFR-001` | Performance | Battle screen sustains 60 FPS on low-end 720p Android with fewer than 50 draw calls per frame | Profiled via `flutter run --profile` and Flame's built-in FPS counter component on a low-end 720p Android device, per spec §24 |
| `PRD-NFR-002` | Reliability | Local save (stars, coins, unlocked tools, settings) must survive a full app kill with zero data loss | Manual QA case: force-kill mid-progress, relaunch, verify identical state (spec §24 edge #14) |
| `PRD-NFR-003` | Security | No login/account exists; IAP purchases go through the platform store's IAP flow with no custom credential or token storage | Code review confirms no auth/token storage and no custom purchase-validation server |
| `PRD-NFR-004` | Privacy | No personal data is collected beyond what the ad SDK and platform IAP require for their own function; no custom analytics/telemetry endpoint exists | Code review confirms no custom telemetry code path; ad SDK consent flow present where the platform requires it |
| `PRD-NFR-005` | Accessibility | No status is conveyed by color alone (invalid/valid tile states pair color with shake/toast, HP bars pair color with bar width); every interactive component has a minimum 48x48 touch target; system text-scale factor is respected, not hard-clamped | Manual accessibility pass over every interactive component's hitbox size and every status indicator's non-color cue |
| `PRD-NFR-006` | Compatibility | Landscape-only (landscapeLeft + landscapeRight); Android and iOS as release targets; baseline layout 812x375 scales correctly up to at least 1280x720 | Manual test at baseline and at least one scaled resolution per platform |
| `PRD-NFR-007` | Localization | English only for v1; no RTL or multi-language support is planned | Not applicable for v1 — revisit if a localization requirement is added |
| `PRD-NFR-008` | Offline/network | 100% of gameplay functions with zero network connectivity; only ad-fill requests and IAP purchase/restore calls touch the network, and their absence must degrade gracefully (disabled/dimmed button, no crash) with no effect on core play | Manual QA: complete a full level in airplane mode with no crash and no blocked interaction outside the ad/IAP buttons themselves |

## 8. Data, privacy, and permissions

- **User data collected:** None personal. Only local gameplay save state
  (coins, stars, unlocked tools, settings, total plays) in a single local
  Hive box, per `PRD-FR-013`.
- **Sensitive data:** None.
- **Data not collected:** No account, email, or name; no location; no
  contacts; no custom analytics/telemetry beyond whatever the third-party
  ad SDK collects under its own policy.
- **Retention/deletion:** The save persists on-device until the app is
  uninstalled or the player uses Settings → Reset Progress, which clears
  the relevant fields back to first-launch defaults (`PRD-FR-019`). There is
  no server-side retention, since there is no server.
- **Sharing/processors:** Google Mobile Ads (ad serving) and the platform
  IAP store via `in_app_purchase` (purchase processing) are the only
  third-party processors touched, used solely for their stated function; no
  other data sharing occurs.
- **Device permissions:** Network access is required only for ad fill and
  IAP; if unavailable, ads simply fail to load and IAP is unavailable while
  the core game remains fully playable offline. No other device permission
  (camera, location, contacts, external storage) is requested.
- **Consent requirements:** Whatever consent flow the ad SDK's own policy
  requires on a given platform (e.g. an app-tracking or consent-management
  prompt) must be obtained before ad requests are made. The exact
  implementation of that flow is an open decision — see `PRD-Q-001`.
- **Age/geography constraints:** Not yet defined — flagged as an open
  decision, `PRD-Q-005`.

Technical controls and schemas belong in `architecture.md`; enforceable
coding constraints belong in `rules.md`.

## 9. Success and guardrail metrics

The game has no analytics/telemetry system in scope (per the offline-first,
no-backend hard constraint), so the metrics below can only be measured via
app-store console aggregates (installs, ratings, store-level retention),
not an in-app funnel. Whether to add lightweight, privacy-respecting
telemetry to close this gap is itself an open decision — see `PRD-Q-004`.

| ID | Metric | Definition | Baseline | Target | Window | Source |
| --- | --- | --- | --- | --- | --- | --- |
| `PRD-SM-001` | Early-session progression | Share of installs that reach `maxUnlocked>=2` (i.e., complete Level 1) | Unknown (pre-launch) | Not yet set — no baseline data exists | D1 | Store console aggregate retention/analytics (Play Console / App Store Connect) |
| `PRD-GM-001` | Store rating under the designed ad cadence | Average app-store rating, tracked against the fixed ad design (interstitial 1-per-3-wins, rewarded capped 1/battle, per `PRD-FR-016`/`PRD-FR-017`) | N/A (pre-launch) | Must not fall below 4.0 | Ongoing, rolling | Store console reviews/ratings |

Avoid vanity metrics. Every event required for measurement must map to an
approved requirement; analytics is not permission to collect unrelated data.

## 10. Business and operational constraints

- **Budget:** Not yet defined — solo developer, no stated dollar budget in
  the source spec.
- **Launch date/window:** No fixed calendar date is committed. The spec
  estimates a 4-5 week solo build (17-18 day phased build order, spec §25);
  see `PRD-Q-006`.
- **Platforms/channels:** Android (Google Play) and iOS (Apple App Store)
  are the primary distribution channels. Flutter/Flame technically also
  supports web/desktop builds, but store distribution focus is mobile.
- **Compliance/legal:** Standard Google Play / Apple App Store / AdMob
  policy compliance applies. No COPPA-specific or age-targeting design
  decision has been made yet — see `PRD-Q-005`; confirm with a qualified
  legal owner before submission if targeting a broad or kids-adjacent
  audience.
- **Operations/support:** Solo developer handles all support. No moderation
  is needed (no user-generated content, no multiplayer). No live incident
  response infrastructure exists or is needed (no backend to fail).
- **External dependencies:** Google Mobile Ads SDK (ad fill) and the
  platform's IAP store via `in_app_purchase` (purchase processing) are the
  only external systems the game touches.

## 11. Risks

| ID | Risk | Likelihood | Impact | Mitigation | Owner | Trigger |
| --- | --- | --- | --- | --- | --- | --- |
| `PRD-R-001` | Ad fatigue (interstitial + rewarded) drives churn | Med | Med | Caps are already designed in (`PRD-FR-016` 1-per-3-wins interstitial, `PRD-FR-017` 1-per-battle rewarded) | Solo developer | D1 retention drop or negative reviews mentioning ads |
| `PRD-R-002` | The beam-optics mechanic (mirror/prism bending) is not intuitive to new players | Med | High | Teach 1 new tool per level in levels 1-4, safe lane first, per the documented difficulty curve (spec §9) | Solo developer | High level 1-4 abandon rate observed in playtesting |
| `PRD-R-003` | Low-end 720p Android can't sustain 60 FPS / <50 draw calls with the full particle+parallax stack | Med | High | Pooling discipline (spec §18.3) and dedicated profiling pass in the build plan (spec §25 Phase 5) | Solo developer | Profiled FPS below 60 or draw calls above 50 on target device |
| `PRD-R-004` | Solo 4-5 week build estimate slips (Flame learning curve, per spec §"Why Flame") | Med | Med | Phased build order with hard phase gates (spec §25) | Solo developer | Any phase running meaningfully over its budgeted days |

## 12. Open decisions

| ID | Decision needed | Options | Owner | Due | Blocks |
| --- | --- | --- | --- | --- | --- |
| `PRD-Q-001` | Exact AdMob ad unit IDs (banner, interstitial, rewarded) and the exact consent-flow implementation (e.g. ATT/UMP) | Create/register units now vs. at Phase 5; consent flow per Google's current requirements at build time | Solo developer | Before Phase 5 ad integration (spec §25) | `PRD-FR-016`, `PRD-FR-017` |
| `PRD-Q-002` | App store bundle/package identifiers (Android `applicationId`, iOS bundle identifier) and store listing name reservation | Reserve now vs. at first submission | Solo developer | Before first store submission | Release |
| `PRD-Q-003` | Font licensing/attribution requirements for Orbitron, Inter, and JetBrains Mono as loaded via the Google Fonts package at runtime vs. bundled at build time | Runtime `google_fonts` package (network fetch on first use) vs. bundling font files in assets | Solo developer | Before release | Release, App Store review |
| `PRD-Q-004` | Whether to add any lightweight, privacy-respecting analytics/telemetry, since the offline-first/no-backend constraint currently leaves `PRD-SM-001` measurable only via app-store console aggregates | No telemetry (status quo) vs. minimal opt-in local-aggregate reporting | Solo developer | Before finalizing `PRD-SM-001` baseline/target | `PRD-SM-001` |
| `PRD-Q-005` | Age rating / COPPA-adjacent compliance posture for the store listing (no explicit minimum-age design decision made) | General audience vs. explicit "designed for kids"/mixed-audience declaration | Solo developer | Before store submission | Release, legal compliance |
| `PRD-Q-006` | Fixed launch date/window (spec gives only a build-time estimate, no calendar commitment) | Commit to a date once build begins vs. remain open-ended | Solo developer | Post-build-start | Planning only, no current blocker |
| `PRD-Q-007` | Exact IAP store price-tier mapping for Remove Ads across regions (spec states $2.99 USD) | Use each store's nearest local price tier to $2.99 vs. a manually curated regional price list | Solo developer | Before Shop implementation | `PRD-FR-018` |
| `PRD-Q-008` | Whether "Reset Progress" (Settings) also clears `removeAds`/`sound`/`haptics`, or only the progression fields (coins, stars, unlocked, maxUnlocked) — the source spec does not specify this | Reset progression fields only (proposed default, preserves a paid entitlement) vs. reset everything including settings and `removeAds` | Solo developer | Before implementing `PRD-FR-019` | `PRD-FR-019` |

An unresolved item that affects scope, security, cost, public API, or data is
a blocking decision, not an implementation assumption.

## 13. Release acceptance

The release is product-ready only when:

- [ ] Every MVP `Must` requirement has passing acceptance evidence.
- [ ] Every applicable non-functional threshold is met or has an explicitly accepted exception.
- [ ] No open critical/high product, security, privacy, or data-loss finding remains.
- [ ] The core journeys work for target users and supported environments.
- [ ] Analytics/measurement required by success metrics is validated without excess collection.
- [ ] Rollback, support, and ownership are defined.
- [ ] Out-of-scope behavior has not leaked into the release.

## 14. Change log

| Date | Changed IDs | Decision and reason | Approved by | Downstream docs updated |
| --- | --- | --- | --- | --- |
| 2026-09-03 | Initial | Filled in the PRD template from `LIGHT_vs_SHADOW_Prism_Defense_Flame_Spec.md` v2.0 — all `[REQUIRED: ...]` placeholders replaced with real, testable content per the spec's exact numbers | Solo developer (repo owner) | Architecture / rules / design / phases / plan (not yet authored) |
