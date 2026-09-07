---
document: Project Phases and Milestone Gates
authority: Build sequence, milestone scope, entry/exit criteria, release gates
status: Draft
owner: "Solo developer (repo owner)"
last_updated: "2026-09-07"
---

# Phases — LIGHT vs SHADOW: Prism Defense

Phases describe **testable outcomes**, not weeks of activity. A phase is complete
only when its exit gate has objective evidence. Concrete coding tasks live in
`implementation_plan.md`.

Source of truth for phase content: `LIGHT_vs_SHADOW_Prism_Defense_Flame_Spec.md`
§25 (Build Order, Phase 0-6) and §24 (QA checklist, referenced from PH-06).
`PH-00` through `PH-06` map 1:1 onto spec §25 Phase 0-6. `PH-07` records the
governance/repo-repurposing work that already happened and is numbered last
per the "never renumber an ID" rule in `docs/GOVERNANCE.md`, even though it
chronologically precedes `PH-00`.

## 1. Status and gate policy

Allowed phase status: `Not started`, `In progress`, `Blocked`, `Gate review`,
`Complete`.

Rules:

- Only one phase should normally be `In progress`; explicitly justify overlap.
- Later discovery/spikes may run early, but later production scope does not begin
  until dependencies and gates are met.
- A calendar date does not complete a phase.
- Missing required tests, unresolved critical/high findings, unfilled relevant
  `[REQUIRED]` fields, or unapproved blocking decisions prevent completion.
- Deferring an exit criterion requires a documented exception, owner, risk,
  expiry, and task—not deletion of the criterion.
- Every exit gate item below is a real command or a directly observable
  behavior. None have been run yet except where PH-07 evidence says so.

## 2. Roadmap overview

| Phase | Outcome | Spec source | Depends on | Status | Exit review |
| --- | --- | --- | --- | --- | --- |
| `PH-07` | Repo repurposed from PvZ-widgets to Flame governance-kit + resolvable pubspec | Repo history, `docs/audit.md` AUD-001..AUD-008 | None | Complete | 2026-09-03, solo dev |
| `PH-00` | `FlameGame`/`CameraComponent` bootstrap renders inside `WidgetsApp`, landscape-locked, empty-scene 60fps baseline | Spec §25 Phase 0, §26 | `PH-07` | In progress — 4/6 gate items met at `397ce19`; the 2 render/device items are unrun and `TASK-012` is blocked on `ARCH-Q-003` | 2026-09-04, Claude (lead) |
| `PH-01` | Parallax backdrop + 21-tile grid + glow economy (bulb + falling orbs) + place/remove + Hive + HUD shell render | Spec §25 Phase 1, §4.2, §5, §13 | `PH-00` | Gate review — 6/7 met at `9cc0c49`, 1 partial (no red-pulse API) | 2026-09-04, Claude (lead) |
| `PH-02` | Shadow walk/eat + beam trace (mirror/prism) + collisions + HP bars + sweep + win/lose overlays, one full level playable | Spec §25 Phase 2, §7, §8, §15, §16 | `PH-01` | Gate review — automated behavior is green and HUD is confirmed on hardware, but `AUD-024` freezes Pause/Win/Lose before their overlays mount; on-device playthrough fails | 2026-09-07, GameDesigner (lead) |
| `PH-03` | All 20 levels JSON + Loadout pick-6-of-8 + Scout panel + cooldowns + every tool/shadow special behavior | Spec §25 Phase 3, §6, §7, §9 | `PH-02` | Gate review — 5/5 at `70f19e1`, data-driven against the JSON | 2026-09-04, Claude (lead) |
| `PH-04` | Full particle/effects inventory + sound/haptics + stars/coins/daily + Shop world + Settings world | Spec §25 Phase 4, §18, §19, §23 | `PH-03` | Gate review — **2/5** at c14. Audio assets ship and `loadAll` is wired, but no test or device run has observed a cue play; `TASK-037`/`TASK-039` are still `Not started`. c13's 5/5 claim was reverted | 2026-09-07, GameDesigner (lead) |
| `PH-05` | Ads (banner/interstitial/rewarded) + IAP remove-ads + multi-viewport + profiled 60fps | Spec §25 Phase 5, §20 | `PH-04` | Partially deferred — ads/IAP scoped out by the owner 2026-09-04 (exception recorded in §9); multi-viewport + 60fps remain in scope | 2026-09-04, Claude (lead) |
| `PH-06` | Final art-direction pass + signed APK/AAB + full §24 QA checklist passes | Spec §25 Phase 6, §4, §24 | `PH-05` | Not started | [Owner/date] |

Rename/reorder phases only by changing the authoritative spec first; this
table is a direct restatement of spec §25, not an independent decomposition.

## 3. `PH-07` — Governance bootstrap and repo repurposing (Complete)

**Outcome:** The repository stopped being a pure-Flutter-widgets Plants vs
Zombies clone and became a governance-kit-managed Flutter+Flame project
(`prism_defense`) with a resolvable dependency set and an empty `lib/`
skeleton, ready for `PH-00` to begin.

**Status:** Complete
**Owner:** Solo developer (repo owner)
**Depends on:** None
**Requirements:** N/A (infrastructure, not a PRD-FR)

### Scope (what actually happened)

- Deleted old `lib/`, `test/`, `assets/images`, `assets/sounds` from the
  working tree (recoverable only via `git log` — see `AUD-008`).
- Deployed the project-governance-kit to repo root: `docs/*.md`, `AGENTS.md`,
  `AGENT.md`, `CLAUDE.md`, `STATE.md`, `.ai/STATE-PROTOCOL.md`,
  `.ai/inbox/`, `.claude/settings.json`, `.claude/commands/wrap.md`.
- Rewrote `pubspec.yaml`: package `plants_vs_zombie` -> `prism_defense`,
  added Flame stack, set `uses-material-design: false`.
- Created empty folder skeleton: `lib/core`, `lib/game/worlds`,
  `lib/game/components/{tools,hud}`, `lib/game/particles`, `lib/state`,
  `lib/data`, `assets/{data,levels,audio}`.

### Exit gate (retroactive — already met)

- [x] `flutter pub get` exits 0 against the rewritten `pubspec.yaml`.
- [x] `flutter --version` confirms toolchain (3.47.0 stable) capable of
      resolving the pinned Flame/Riverpod/Hive/go_router stack.
- [x] `docs/*.md`, `AGENTS.md`, `AGENT.md`, `CLAUDE.md`, `STATE.md` exist at
      repo root (`ls` evidence).
- [x] Empty `lib/`/`assets/` skeleton exists at the paths listed above
      (`ls -R lib assets` evidence).
- [ ] Known divergences (a)-(f) recorded in `docs/audit.md` are triaged with
      owners and remediation tasks — **done in this pass**, see `AUD-001`
      through `AUD-006`.

**Evidence:** `docs/audit.md` §12 Test and build evidence row for
2026-09-03; `pubspec.yaml` diff; `docs/audit.md` `AUD-001`..`AUD-008`.

**Mapped tasks:** `TASK-001`..`TASK-006` (all Done).

## 4. `PH-00` — Flame engine bootstrap

**Outcome:** `FlameGame` root with `CameraComponent` (viewfinder + viewport
split) renders an empty `BattleWorld` inside a non-Material `WidgetsApp`
root; landscape lock is enforced; empty-scene 60fps baseline is confirmed.

### Scope

- `lib/main.dart`: lock orientation, `Hive.init`, `runApp` with `WidgetsApp`
  (not `MaterialApp`).
- `lib/core/theme.dart`: color/text tokens as plain Dart constants +
  `TextPaint` builders — no `ThemeData`.
- `lib/game/light_vs_shadow_game.dart`: `FlameGame` root,
  `camera.viewfinder`/`camera.viewport` split per spec §26 snippet.
- `lib/game/worlds/battle_world.dart`: empty `World` subclass, addable/loadable.
- Font sourcing/bundling groundwork for `theme.dart` (see `AUD-002`,
  `TASK-011`) — offline-first forbids runtime `GoogleFonts` fetch.
- Native app id / bundle id / display name retargeting away from
  `plants_vs_zombie` (`AUD-005`, `TASK-012`).

### Explicit non-goal

No grid, no tools, no shadows, no HUD content yet — only the render/camera
skeleton and the orientation/lifecycle shell.

### Exit gate

- [x] `flutter analyze` returns zero errors/warnings against `lib/`.
      Evidence: `No issues found!` at `397ce19`.
- [x] `flutter test` passes a widget test that pumps the app shell and asserts
      a game widget is present with no `MaterialApp`/`Scaffold` ancestor.
      Evidence: `test/app_boot_test.dart`, 35/35 at `397ce19`. **Drift, now
      corrected:** this gate was written against a class named
      `LightVsShadowApp`; the shell that exists is `PrismDefenseApp`
      (`lib/app.dart`), and the test asserts `WidgetsApp` plus `HomeWorld`
      mounted on the shared game via `game.camera.world`.
- [ ] App launches on an Android emulator or physical device locked to
      `landscapeLeft`/`landscapeRight` only (rotate device, no relayout —
      observed manually, logged in `docs/audit.md`). **Never run.**
- [ ] Flame's built-in FPS counter component shows a sustained ≥60fps on the
      empty `BattleWorld` for 30s (`flutter run --profile`, observed).
      **Never run.**
- [x] `grep -r "MaterialApp\|Scaffold\|Icons\." lib/` returns no matches.
      Evidence: 3 hits at `397ce19`, all inside doc comments that *name* the
      forbidden widgets in order to forbid them (`lib/app.dart:6`,
      `lib/main.dart:2`, `lib/game/components/tools/tool_component.dart:4`).
      Zero code matches. The gate's grep cannot tell comment from code; a
      reviewer must.
- [ ] Native app id / bundle id / display name no longer reference
      `plants_vs_zombie` in `android/app/build.gradle.kts` and
      `ios/Runner.xcodeproj`. **Still `com.example.plants_vs_zombie`
      (Android, `build.gradle.kts:8,19`) and `com.example.plantsVsZombie`
      (iOS)** — blocked on `ARCH-Q-003`, the human bundle-id decision
      (`AUD-005`, `TASK-012`).

**Mapped tasks:** `TASK-007`..`TASK-012`
**Evidence:** 4 of 6 met at `397ce19`. The two unmet render/device items need a
physical device or emulator; the sixth needs a human decision.

## 5. `PH-01` — Grid, glow economy, HUD shell

**Outcome:** The 21-tile battle grid, the glow economy (start glow, falling
`GlowOrbComponent`, `BulbComponent` generation), tool place/remove, Hive
persistence, and the screen-locked HUD shell (`TopBarComponent`,
`RightPanelComponent`) all work together in `BattleWorld`.

### Scope

- `lib/game/components/backdrop_layer.dart`, `dust_mote_layer.dart`,
  `ambient_glow_layer.dart` (L0-L3 parallax rig, motion-parallax not
  camera-scroll, per spec §14).
- `lib/game/components/grid_component.dart` + `tile_component.dart` (L4,
  21 tiles, `TapCallbacks`).
- `lib/game/components/tools/bulb_component.dart`,
  `glow_orb_component.dart`.
- `lib/game/components/hud/top_bar_component.dart`,
  `right_panel_component.dart`, `tray_slot_component.dart`,
  `toast_component.dart`.
- `lib/state/battle_notifier.dart` (`Notifier<BattleState>` bridged via
  `flame_riverpod`).
- `lib/core/hive.dart` (Save box init/read/write per spec §19 schema).
- `tryPlace` implementing placement checks #1-#5 of the 7-check table in
  spec §17 (checks #6-#7 depend on `twin`/`prism`, deferred to `PH-03`).

### Exit gate

All seven are covered by `test/ph01_exit_gate_test.dart` unless noted.
Verified by the lead at `9cc0c49`: `flutter analyze` clean, `flutter test` 42/42.

- [x] Tapping an empty tile with a selected tool places it, deducts glow, and
      plays the placement `ScaleEffect`.
- [x] Tapping an occupied tile shakes it and shows the "Occupied" toast with
      **no glow deduction** (QA checklist #1) — the no-deduction half is
      asserted explicitly, not implied.
- [~] Insufficient glow blocks placement (QA checklist #2). **Partial:** the
      block and the zero-deduction are asserted; the *red cost pulse* is not,
      because `TraySlotComponent` exposes no pulse API. Production code was
      deliberately not redesigned to make a test pass — closing this needs a
      real pulse API, tracked with `TASK-020`.
- [x] A `GlowOrbComponent` spawns on the falling-glow timer and is collectible
      by tap (controllable clock, no `Future.delayed`).
- [x] `BulbComponent` generates +25 glow every 10.0s **only while alive** — the
      dead-bulb case is asserted, not just the happy path.
- [x] The `save` box persists `coins`/`stars`/`unlocked` across a simulated
      restart, close and reopen (QA checklist #14).
- [x] `TopBarComponent` glow display updates reactively. **Drift:** this gate
      said "from `BattleNotifier`"; per `ADR-007` there is no notifier — the
      owning world writes the value and the bar diffs it in `update()`.

**Mapped tasks:** `TASK-013`..`TASK-022` (`TASK-021` dropped, `ADR-007`)
**Evidence:** `test/ph01_exit_gate_test.dart` at `9cc0c49`; analyze clean, 42/42, both re-run by the lead. 6 of 7 items fully met, 1 partial.

## 6. `PH-02` — Combat core: shadows, beams, sweep, win/lose

**Outcome:** `ShadowComponent` walk+eat behavior, beam trace through
mirror/prism via `BeamComponent`, `CollisionCallbacks` beam-hit detection,
HP bars, per-lane sweep, and win/lose HUD overlays work together so that one
full level (level 1) is playable start to finish without a crash.

### Scope

- `lib/game/components/shadow_component.dart` (walk, eat, bob, death
  dissolve into particles per §7).
- `lib/game/components/beam_component.dart` + beam trace algorithm (depth-3,
  visited-set loop prevention per spec §15, QA checklist #5-#7).
- `lib/game/components/tools/beam_lamp_component.dart`,
  `mirror_component.dart`, `prism_component.dart`.
- `lib/game/components/wave_manager_component.dart` implementing the 50%
  rule (`canSpawnNext()` per spec §8).
- Sweep behavior on `GridComponent`/lane (spec §5) triggering at `x<=12`.
- `lib/game/components/hud/overlay_win.dart`, `overlay_lose.dart`,
  `overlay_pause.dart`.
- `assets/levels/1.json` (first real level content, minimum needed to prove
  the slice).

### Exit gate

- [ ] Unit test on the beam-trace algorithm proves depth-3 cap and
      visited-set loop prevention (QA checklist #7) with a synthetic
      multi-mirror layout.
- [ ] Beam-hits-shadow collision reduces shadow HP and is observable via a
      component/widget test (QA checklist #9, two shadows same tile both
      take damage).
- [ ] Sweep triggers automatically when a shadow reaches `x<=12`, kills all
      shadows in that lane, and the lane becomes vulnerable afterward (test,
      covers QA checklist #12).
- [ ] Win overlay appears when all waves are spawned and no shadows remain,
      even if the level timer is still running (test, QA checklist #13).
- [ ] Lose overlay appears immediately when a shadow reaches `x<=0` with no
      sweep left for that lane (test, QA checklist #12).
- [ ] `assets/levels/1.json` is playable on-device from start to a win or
      loss with no unhandled exception (manual run, logged).
- [ ] `game.pauseEngine()` halts all component `update()` calls on
      `didChangeAppLifecycleState(paused)` (QA checklist #10, test or
      manual observation).

**Mapped tasks:** `TASK-023`..`TASK-032`, `TASK-046`
**Evidence:** 2026-09-07 c10 on SM-S711B: build/install/cold launch passed;
Home → Loadout → Battle, HUD, placement, Glow collection, and wave progression
worked. `AUD-024` blocks this gate because Pause/Win/Lose overlays do not mount.
Remediation: `TASK-046`.

## 7. `PH-03` — Full content: 20 levels, loadout, all tools/shadows

**Outcome:** All 20 level JSONs exist and load; Loadout world enforces
pick-6-of-8 with a Scout preview panel; every one of the 8 tools and 5
shadows (including Frost slow, Bomb 3x3, Twin-replaces-Bulb, Jumper leap,
Giant throw-Imp) behaves per spec §6/§7/§9.

### Scope

- `assets/levels/2.json`..`20.json` per spec §9 progression table.
- `lib/game/worlds/loadout_world.dart`, Scout panel, pick-6-of-8 enforcement.
- Remaining tool components: `frost_lens_component.dart`,
  `wall_component.dart`, `bomb_component.dart`, `twin_bulb_component.dart`.
- Remaining placement checks #6 (twin-must-target-bulb) and #7
  (max-prism-per-row) from spec §17.
- Cooldown UI (dark overlay + countdown number + circular progress).

### Exit gate

- [ ] All 20 `assets/levels/*.json` files parse against the schema in spec
      §22 (test iterates the directory).
- [ ] Loadout screen blocks starting a battle with fewer/more than 6 tools
      selected (test).
- [ ] Each tool's damage/cost/cooldown/HP matches spec §6 table exactly
      (data-driven test against `assets/tools.json`).
- [ ] Each shadow's HP/speed/eat/special matches spec §7 table exactly
      (data-driven test against `assets/shadows.json`).
- [ ] QA checklist #4 (Twin on non-bulb -> toast), #16 (Bomb on edge clamps
      3x3, no index error) pass.

**Mapped tasks:** `TASK-033`..`TASK-036` (coarse — expand at `PH-02` gate
review once `BeamComponent`/`ShadowComponent` shapes are proven).
**Evidence:** [Filled at gate review.]

## 8. `PH-04` — Juice: particles, effects, audio, stars/coins, shop, settings

**Outcome:** Full particle inventory (§18.1) and effects inventory (§18.2)
implemented with pooling (§18.3); all 8 sound files preloaded and triggered;
stars/coins calculation matches §19; Shop world and Settings world
(including custom `SwitchComponent`) are functional.

### Scope

- `lib/game/particles/particle_definitions.dart`, `effect_pool.dart`.
- `lib/core/audio.dart` (`FlameAudio` pool setup, `audioCache.loadAll`).
- `lib/game/worlds/shop_world.dart`, `settings_world.dart`.
- Stars/coins award logic on win, daily level id calculation.

### Exit gate

- [ ] All particles in §18.1 are implemented as `ParticleSystemComponent`
      and high-frequency ones (`SparkParticle`, `CollectParticle`) come from
      a pool, not `new` + `removeFromParent()` each trigger (code review).
      (c13 flipped this to met; reverted at c14 — `TASK-037` is still
      `Not started` and no code review was recorded.)
- [ ] All 8 sound files in `assets/audio/` are preloaded at boot via
      `FlameAudio.audioCache.loadAll` and play on their documented trigger.
      Files ship and `loadAll` is wired (c13), but **no test or device run has
      observed a cue play**: the test host has no audio plugin, so `_ready`
      stays false and the preload path is never exercised. Needs device evidence.
- [x] Stars/coins award on win matches the exact formula in spec §19 (unit
      test — `test/ph04_exit_gate_test.dart:72`, pre-dates c13).
- [x] Shop world purchase of "Tray Slot +2" and "Remove Ads" updates Hive
      state and disables the bought item (test — `ph04_exit_gate_test.dart:83`,
      pre-dates c13).
- [ ] Settings `SwitchComponent` toggling sound/haptics changes `FlameAudio`
      global volume and gates haptic calls. The test at
      `ph04_exit_gate_test.dart:130` asserts the boolean flags only;
      `setSoundEnabled` returns at `audio.dart:70` before touching volume
      whenever `_ready` is false, which is always true under `flutter test`.
      The "changes FlameAudio global volume" half is unverified.

**Mapped tasks:** `TASK-037`..`TASK-039` (coarse).
**Evidence:** `test/ph04_exit_gate_test.dart` passes 6/6; full suite 72/72; `flutter analyze` clean (re-run at c14). All 8 SFX plus `bgm.mp3` generated via `tool/generate_audio.py` into `assets/audio/` (375,607 bytes, within the 500KB budget). **Gate is 2/5, not 5/5**: c13 marked all five met, but only the shop and stars/coins items have real assertions, and both pre-date c13. The audio, particles and settings-volume items were flipped without new evidence and were reverted at c14. `AUD-018`'s code fix is correct but has no negative control — reopened as `Open — code fixed, unverified`.

## 9. `PH-05` — Monetization and cross-device polish

**Outcome:** Banner/interstitial/rewarded ads and IAP remove-ads work per
spec §20 frequency rules; the game runs correctly at both 812x375 and
1280x720; profiled 60fps holds on a low-end device target.

### Scope

- AdMob ad unit id creation (real ids, not test ids) — `AUD-006`,
  `TASK-040`.
- IAP product id (`remove_ads`) registration in store consoles —
  `AUD-006`, `TASK-041`.
- Banner composited outside `GameWidget`; interstitial 1/3-win cap;
  rewarded boost 1/battle cap.
- Multi-viewport verification (812x375, 1280x720).

### Exit gate

**Monetization deferred, 2026-09-04 (c7).** The repo owner scoped ads and IAP
out of the current push to concentrate on gameplay. Per §1, the criteria are
deferred with an exception record, not deleted:

| Field | Value |
| --- | --- |
| Deferred | The four ad/IAP criteria below (banner, interstitial, rewarded, IAP sandbox) |
| Owner | Repo owner |
| Risk | `google_mobile_ads` and `in_app_purchase` stay in `pubspec.yaml` and `lib/core/monetization.dart` stays compiled but unexercised, so it can rot silently. `PRD-FR-016`..`PRD-FR-018` remain `Must` in the PRD and are NOT withdrawn. |
| Expiry | Before any store submission — these gate `PH-06`, which cannot pass without them |
| Task | `TASK-040`..`TASK-041` move to Deferred; `AUD-006` stays open |

- [~] **DEFERRED** — Banner shows on Home/Map only, hidden when `removeAds==true`.
- [~] **DEFERRED** — Interstitial only after a win where `levelId % 3 == 0`, capped 1 per 3 wins.
- [~] **DEFERRED** — Rewarded boost button disables after first use per battle.
- [~] **DEFERRED** — IAP `remove_ads` purchase + `restorePurchases()` in a store sandbox.
- [ ] Layout holds with no overlap/clipping at both 812x375 and 1280x720
      (screenshot evidence both). **Still in scope — this is gameplay, not
      monetization, and it is automatable.**
- [ ] `flutter run --profile` sustains 60fps on a low-end Android 720p
      target with draw calls <50/frame. **Still in scope; needs a device.**

**Mapped tasks:** `TASK-040`..`TASK-041` deferred; `TASK-042`..`TASK-043` active.
**Evidence:** [Filled at gate review.]

## 10. `PH-06` — Final art pass and release build

**Outcome:** Visual QA against §4 art direction passes; signed release
builds succeed; the full §24 QA checklist (all 20 edge cases) passes.

### Scope

- Art-direction review: bloom consistency, color-temperature check, no
  stray Material-like flat fills anywhere (self-review against §4).
- `flutter build apk --release` and `flutter build appbundle --release`.
- Full run of the §24 QA checklist (20 rows).

### Exit gate

- [ ] Self-review against spec §4 art direction checklist recorded with no
      open items.
- [ ] `flutter build apk --release` exits 0.
- [ ] `flutter build appbundle --release` exits 0.
- [ ] All 20 rows of spec §24 QA checklist pass with evidence (linked from
      `docs/audit.md`), including #19 (no orphaned components leak after
      death/destroy effects) and #20 (World swap fully disposes previous
      World's components).

**Mapped tasks:** `TASK-044`..`TASK-045` (coarse).
**Evidence:** [Filled at gate review.]

## 11. Phase template

### `PH-##` — [Outcome title]

- **Outcome:** [Observable capability/state.]
- **Status:** [Allowed value.]
- **Owner:** Solo developer (repo owner)
- **Depends on:** `PH-__`
- **Requirements:** `PRD-FR-___`, `PRD-NFR-___`
- **In scope:** [Capabilities.]
- **Out of scope:** [Boundaries.]
- **Key risks/decisions:** [IDs.]
- **Tasks:** `TASK-___`
- **Entry criteria:** [Evidence required before start.]
- **Exit criteria:** [Binary/testable conditions.]
- **Verification:** [Commands/environments/manual protocol.]
- **Evidence:** [Filled during gate review.]
- **Deferred items:** [Owner + task + accepted risk.]

## 12. Phase change log

| Date | Phase | Scope/gate/status change | Reason | PRD/plan/audit links | Owner |
| --- | --- | --- | --- | --- | --- |
| 2026-09-03 | `PH-07` | Created, marked Complete | Governance kit deployed, repo repurposed to Flame stack, `flutter pub get` passing | `AUD-001`..`AUD-008`, `TASK-001`..`TASK-006` | Solo developer |
| 2026-09-03 | `PH-00`..`PH-06` | Created from spec §25 Phase 0-6, all Not started | First fill of governance templates against `LIGHT_vs_SHADOW_Prism_Defense_Flame_Spec.md` | Spec §25, §24 | Solo developer |
| 2026-09-04 | `PH-05` | Four ad/IAP exit criteria deferred with an exception record (§1 requires owner/risk/expiry/task, not deletion); multi-viewport and 60fps stay in scope | Repo owner scoped monetization out of the current push to concentrate on gameplay. `PRD-FR-016`..`018` are NOT withdrawn and `AUD-006` stays open — this is a sequencing decision, not a product change | `AUD-006`, `TASK-040`/`TASK-041` deferred | Repo owner (decision), Claude (lead) |
| 2026-09-04 | `PH-02`, `PH-03`, `PH-04` | Not started → Gate review / Gate review / Blocked, with commit evidence per phase | Delivered by Cursor under bounded assignment and verified by the lead re-running every command; `PH-04` cannot pass its audio item until assets exist | `AUD-017` (found in review, fixed `ed0c0f9`/`d39b6b0`), `AUD-018`; commits `f7d52fd`, `70f19e1`, `f545e79` | Claude (lead), implementation by Cursor |
| 2026-09-04 | `PH-00` | Status Not started → In progress; 4 of 6 exit-gate items ticked with commit evidence; gate wording corrected from `LightVsShadowApp` to the shell that exists, `PrismDefenseApp` | Reconciling the gate against the tree after `TASK-007`/`TASK-008` landed — the status had never been updated and the gate named a class that was never written | `AUD-011`..`AUD-014`, `TASK-007`, `TASK-008`, commits `733fb55`/`397ce19` | Claude (lead) |
