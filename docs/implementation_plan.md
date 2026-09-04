---
document: Executable Implementation Plan
authority: Current task decomposition, order, dependencies, verification, status
status: Draft
owner: "Solo developer (repo owner)"
last_updated: "2026-09-03"
---

# Implementation Plan — LIGHT vs SHADOW: Prism Defense

This is the translation layer between `LIGHT_vs_SHADOW_Prism_Defense_Flame_Spec.md`
and code. It references the spec and `docs/phases.md`; it does not redefine
them.

**ID reconciliation note:** `docs/prd.md` is being authored in parallel and
does not yet contain final `PRD-FR-###` ids. The `PRD-FR-001`..`PRD-FR-015`
ids used below are plausible placeholders assigned by topic (placement,
glow economy, beam optics, shadow AI, waves/50% rule, sweep, win/lose,
stars/coins, progression, loadout, persistence, lifecycle/pause, ads, IAP,
settings) so every task has a traceable target. Once `prd.md` is approved,
reconcile these numbers in one pass and update this table plus
`docs/phases.md`. Likewise `docs/architecture.md`, `docs/rules.md`, and
`docs/design.md` are still template Drafts with no real `ADR-###`/`RULE-###`/
`DS-###` ids yet — the ids referenced below are plausible topical placeholders
for the same reason, to be reconciled once those documents are authored.

## 1. Current objective

- **Active phase:** `PH-07` (Complete) transitioning into `PH-00`.
- **Outcome for this plan:** Get from an empty `lib/` skeleton to a playable
  first level (`PH-00` through `PH-02` exit gates, per `docs/phases.md`).
- **In-scope requirements:** `PRD-FR-001`..`PRD-FR-007`, `PRD-FR-011`,
  `PRD-FR-012` (placement, glow economy, beam optics, shadow AI, waves/50%
  rule, sweep, win/lose, persistence, lifecycle/pause).
- **Explicitly excluded:** `PRD-FR-008`..`PRD-FR-010`, `PRD-FR-013`..
  `PRD-FR-015` (stars/coins polish, progression content, loadout, ads, IAP,
  settings) — deferred to `PH-03`..`PH-05`, tracked coarsely below.
- **Target environment/release:** Local dev, Android emulator/device,
  Flutter 3.47.0 stable, no CI configured yet.
- **Owner:** Solo developer (repo owner).
- **Blocking decisions/findings:** `AUD-001`..`AUD-008` — none block starting
  `PH-00`; `AUD-002` (fonts) and `AUD-005` (native ids) must close before
  `PH-00` exit gate.

## 2. Readiness check

- [ ] Requirements are approved and have acceptance criteria — **pending**,
      `docs/prd.md` is still a Draft template; this plan uses plausible
      `PRD-FR-*` ids until it is authored.
- [ ] Applicable ADRs are accepted — **pending**, `docs/architecture.md` is
      still a Draft template.
- [ ] Applicable rules and design contracts are complete — **pending**,
      `docs/rules.md`/`docs/design.md` are still Draft templates.
- [x] Dependencies resolve: `flutter pub get` passed (`AUD-007` evidence).
- [x] Relevant required placeholders in this file, `phases.md`, `audit.md`,
      `memory.md` are resolved.
- [x] Task order supports a working/testable vertical slice (`PH-00` ->
      `PH-01` -> `PH-02` = boot -> place/economy -> play one level).
- [ ] Rollback/recovery is defined for risky changes — N/A this pass, no
      code exists yet to roll back.

Because `prd.md`/`architecture.md`/`rules.md`/`design.md` remain Draft,
strictly only discovery/spike work may proceed under the governance kit's
own rule. This plan is written so that `TASK-007` onward can start the
moment those four documents are approved, without re-deriving the task
breakdown.

## 3. Status vocabulary

Task status: `Ready`, `In progress`, `Blocked`, `In review`, `Verified`,
`Deferred`, `Cancelled`, `Done` (used here for already-completed governance
tasks, equivalent to `Verified`).

- `Verified`/`Done` requires passing evidence and synchronized docs.
- `Blocked` requires a named blocker, owner, and next resolution action.
- `Deferred` requires a reason and destination phase/release.
- Never use percentages; state what is actually complete and what remains.

All tasks below are `Not started` except `TASK-001`..`TASK-006`, which are
`Done` (governance bootstrap already happened — see `docs/audit.md` for
evidence).

## 4. Traceability/task board

Columns beyond the base template (`File paths`, `Acceptance criterion`,
`Verification command`) are added here because `docs/GOVERNANCE.md` requires
every task to carry file paths, acceptance criterion, and verification
command, and repeating a full §6 detail block per task would duplicate this
table without adding information at this stage (no code exists yet to
describe edge cases beyond what's below).

### `PH-07` — Governance bootstrap (Complete, all tasks Done)

| Task | PRD-FR | File paths created/changed | Acceptance criterion | Verification command | Status |
| --- | --- | --- | --- | --- | --- |
| `TASK-001` | N/A (infra) | `docs/*.md`, `AGENTS.md`, `AGENT.md`, `CLAUDE.md`, `STATE.md`, `.ai/STATE-PROTOCOL.md`, `.ai/inbox/`, `.claude/settings.json`, `.claude/commands/wrap.md` | All listed governance-kit files exist at repo root | `ls docs AGENTS.md AGENT.md CLAUDE.md STATE.md` | Done |
| `TASK-002` | N/A (infra) | Deletion of old `lib/`, `test/`, `assets/images`, `assets/sounds` | Old PvZ-widgets code/assets absent from working tree, recoverable via `git log` | `git log --diff-filter=D --summary -- lib test assets` | Done |
| `TASK-003` | N/A (infra) | `pubspec.yaml` | Package renamed `plants_vs_zombie` -> `prism_defense`; Flame stack added; `uses-material-design: false` | `grep -E "name:|flame:|uses-material-design" pubspec.yaml` | Done |
| `TASK-004` | N/A (infra) | `lib/core`, `lib/game/worlds`, `lib/game/components/{tools,hud}`, `lib/game/particles`, `lib/state`, `lib/data`, `assets/{data,levels,audio}` | Empty folder skeleton exists at every listed path | `find lib assets -type d` | Done |
| `TASK-005` | N/A (infra) | `pubspec.lock` | `flutter pub get` resolves the full rewritten dependency set with no error | `flutter pub get` | Done — passed |
| `TASK-006` | N/A (infra) | `docs/audit.md` | Known divergences (a)-(f) plus missing-tests/missing-code/history-only-recovery are recorded as `AUD-*` findings with severity and remediation tasks | Manual review of `docs/audit.md` §14 register | Done — this pass |

### `PH-00` — Flame engine bootstrap

| Task | PRD-FR | File paths created | Acceptance criterion | Verification command | Status |
| --- | --- | --- | --- | --- | --- |
| `TASK-007` | N/A (infra) | `lib/main.dart`, `lib/app.dart` (the shell `main.dart` always imported but which did not exist) | `runApp` uses `WidgetsApp` (not `MaterialApp`, `ADR-006`); orientation locked to `landscapeLeft`/`landscapeRight`; `SaveStore.open()`/`Content.load()` awaited before `runApp`; one long-lived `LightVsShadowGame` in one `RiverpodAwareGameWidget`, kept mounted by a `go_router` `ShellRoute` while each of the 7 routes only swaps `camera.world` (`ADR-003`) | `flutter analyze` (clean); `flutter test test/app_boot_test.dart` (asserts the shell boots and mounts `HomeWorld` on the shared game); manual device rotation test still pending | Done — `733fb55` (c5); analyze clean, 35/35 tests. Manual rotation test still owed. |
| `TASK-008` | N/A (infra) | `lib/core/tokens.dart` (actual filename — plan originally said `lib/core/theme.dart`; drift noted, not renaming, see `AUD-011`), plus `lib/game/worlds/world_widgets.dart` and `lib/game/components/hud/hud_paint.dart` (import/consumer fixes required to make the tokens.dart change compile — c2's tokens.dart-only scope was tried by Cursor and returned `IMPLEMENTATION_BLOCKED`, see `AUD-011`) | Color/text tokens defined as plain `Color`/`TextStyle` constants per spec §10.1/§26; zero `ThemeData` references; `T`'s `TextStyle` values are `package:flutter/painting.dart`'s type (not `dart:ui`'s) so every consumer compiles | `grep -c "ThemeData" lib/core/tokens.dart` returns 0; `flutter analyze` total drops from 56 to 34 (the 34 remainder is `AUD-012`+`AUD-013`, unrelated) | Done — Cursor landed the 3-file diff (`8387953`), confirmed by the planner (c4): `flutter analyze` 34 issues, `flutter test` 34/34, closes `AUD-011` |
| `TASK-009` | N/A (infra) | `lib/game/light_vs_shadow_game.dart` | `LightVsShadowGame extends FlameGame` with `camera.viewfinder`/`camera.viewport` split per spec §26 snippet; `backgroundColor()` returns `AppColors.bg` | `flutter test test/game_boot_test.dart` (new widget test asserting `GameWidget` renders) | Not started |
| `TASK-010` | N/A (infra) | `lib/game/worlds/battle_world.dart` | Empty `BattleWorld extends World` loads with no children and no exception | Same widget test as `TASK-009` | Not started |
| `TASK-011` | N/A (infra, closes `AUD-002`) | `assets/fonts/*.ttf`, `pubspec.yaml` `fonts:` section, `lib/core/theme.dart` | Orbitron/Inter/JetBrainsMono TTFs sourced under a license compatible with redistribution, bundled as assets, referenced via `fonts:` in `pubspec.yaml`; zero `google_fonts` runtime network calls remain in `lib/` | `grep -r "GoogleFonts\." lib/` returns 0 matches; `flutter pub deps` no longer lists `google_fonts` as used | Not started |
| `TASK-012` | N/A (infra, closes `AUD-005`) | `android/app/build.gradle(.kts)`, `android/app/src/main/AndroidManifest.xml`, `ios/Runner.xcodeproj/project.pbxproj`, `ios/Runner/Info.plist` | `applicationId`/`PRODUCT_BUNDLE_IDENTIFIER` and display name no longer reference `plants_vs_zombie`/`Plants vs Zombie` | `grep -ri "plants_vs_zombie\|plants vs zombie" android/app/build.gradle* ios/Runner.xcodeproj/project.pbxproj` returns 0 matches | Not started |

### `PH-01` — Grid, glow economy, HUD shell

| Task | PRD-FR | File paths created | Acceptance criterion | Verification command | Status |
| --- | --- | --- | --- | --- | --- |
| `TASK-013` | N/A (art/visual) | `lib/game/components/backdrop_layer.dart` | L0-L1 static gradient/desk texture renders at priority -30 | Manual visual check + `flutter test` smoke test that it mounts without error | Done — code shipped as `lib/game/components/backdrop_layers.dart` (**drift:** plan said `backdrop_layer.dart`; the three L0-L3 layers were consolidated into one file). Mount asserted by `test/ph01_exit_gate_test.dart`. |
| `TASK-014` | N/A (art/visual) | `lib/game/components/dust_mote_layer.dart` | 12-18 particle `ParticleSystemComponent` infinite generator runs at priority -20 | Manual visual check; component-count assertion in widget test | Done — in `backdrop_layers.dart` (same consolidation as `TASK-013`). Particle pooling covered by `test/particle_pool_test.dart`. |
| `TASK-015` | N/A (art/visual) | `lib/game/components/ambient_glow_layer.dart` | Breathing radial glow near active bulbs at priority -10 | Manual visual check | Done — in `backdrop_layers.dart` (same consolidation). Visual-only; no automated assertion, per `ADR-006` no goldens. |
| `TASK-016` | `PRD-FR-001` | `lib/game/components/grid_component.dart`, `lib/game/components/tile_component.dart` | `GridComponent` contains exactly 21 `TileComponent` children (3x7), each with `TapCallbacks` | `flutter test` asserting `battleWorld.children.whereType<TileComponent>().length == 21` | Done — `lib/game/components/grid_component.dart` (**drift:** plan said a separate `tile_component.dart`; the tile is a private class inside `grid_component.dart`). Grid load + tile occupancy asserted in `test/ph01_exit_gate_test.dart`. |
| `TASK-017` | `PRD-FR-002` | `lib/game/components/tools/bulb_component.dart` | `BulbComponent` generates +25 glow every 10.0s only while `hp > 0`; cost 50, cooldown 5s, HP 100 per spec §6 table | `flutter test` fast-forwarding a fake clock 10s and asserting glow increment | Done — `lib/game/components/tools/bulb_component.dart`; `test/ph01_exit_gate_test.dart` drives a controllable clock and asserts +25 glow at 10s **and that a dead bulb stops generating**. |
| `TASK-018` | `PRD-FR-002` | `lib/game/components/glow_orb_component.dart` | Orb spawns every 8.0s at random x, falls 2s with `easeIn`, max 2 on screen, tap radius 40px collects +25 glow | `flutter test` with fake clock; asserts glow += 25 on simulated tap | Done — `lib/game/components/glow_orb_component.dart`; `test/ph01_exit_gate_test.dart` asserts timer spawn, single-orb cap, tap collection (+`kGlowFallAmount`) and removal. |
| `TASK-019` | `PRD-FR-001` | `lib/game/battle/placement.dart` (or `battle_world.dart` method) | `tryPlace` implements checks #1-#5 of spec §17 table in order, first fail short-circuits with correct UI reaction (shake+toast for occupied, red pulse for insufficient glow, cooldown number shown) | `flutter test` — one test per check (#1-#5), covers QA checklist #1, #2, #3 | Done — `BattleWorld.tryPlace` delegates the 7 ordered checks to the already-tested `rules.validatePlacement`; `test/ph01_exit_gate_test.dart` now covers the **mutation** half (glow deducted, tile occupied, tool created, `selectedTool` cleared) and the reject paths for occupied/insufficient-glow. |
| `TASK-020` | `PRD-FR-002` | `lib/game/components/hud/top_bar_component.dart`, `right_panel_component.dart`, `tray_slot_component.dart`, `toast_component.dart` | HUD renders on `camera.viewport` (screen-locked regardless of world state); `TopBarComponent` glow chip matches current glow value | `flutter test` widget test reading `TopBarComponent`'s rendered glow text | Done — HUD components exist and live on `camera.viewport`; `test/ph01_exit_gate_test.dart` asserts `TopBarComponent`'s rendered glow text tracks the value. **Partial:** the insufficient-glow *red cost pulse* is unasserted — `TraySlotComponent` exposes no pulse API. Gap recorded, production code deliberately not redesigned to suit a test. |
| `TASK-021` | `PRD-FR-011` | `lib/state/battle_notifier.dart` | `BattleNotifier extends Notifier<BattleState>` exposes glow/wave/coins/stars; `RiverpodAwareGameMixin` wired on `LightVsShadowGame` | `flutter test` asserting HUD reflects a manually-set `BattleNotifier` state | **Dropped** — `ADR-007`. The Riverpod `BattleNotifier` layer was never built and the shipped design uses direct callbacks + `SaveStore`; `architecture.md` amended to match rather than refactoring working code for no player-visible gain. See `AUD-016`. |
| `TASK-022` | `PRD-FR-011` | `lib/core/hive.dart` | `Save` `HiveObject` (spec §19 schema) box `save` opens on boot; write then reopen box round-trips all 8 fields | `flutter test` — write `Save`, close box, reopen, assert equality (covers QA checklist #14) | Done — shipped as `lib/core/save_store.dart` (**drift:** plan said `lib/core/hive.dart`, and a plain map replaces the `HiveObject`+adapter, per `ADR-004`). `test/ph01_exit_gate_test.dart` writes, closes and reopens the box and asserts `coins`/`stars`/`unlocked` survive. |

### `PH-02` — Combat core: shadows, beams, sweep, win/lose

| Task | PRD-FR | File paths created | Acceptance criterion | Verification command | Status |
| --- | --- | --- | --- | --- | --- |
| `TASK-023` | `PRD-FR-004` | `lib/game/components/shadow_component.dart` | `ShadowComponent.update(dt)` moves `x -= speed*dt`; eats tool in range (`hp -= eat*dt`, pauses walk) per spec §7 | `flutter test` — spawn shadow next to a tool, advance dt, assert tool HP drops and shadow x unchanged while eating | Not started |
| `TASK-024` | `PRD-FR-004` | Same file, `DeathDissolveParticle` factory in `lib/game/particles/particle_definitions.dart` | Shadow death spawns 6-10 upward-drift fade particles, never a bare `removeFromParent()` | `flutter test` asserting particle component added on `hp<=0` | Not started |
| `TASK-025` | `PRD-FR-003` | `lib/game/components/beam_component.dart` | Beam trace recomputes on tool change, depth-3 cap, visited-set prevents infinite mirror loops (spec §15) | `flutter test` — synthetic multi-mirror layout, asserts trace terminates and depth `<=3` (QA checklist #7) | Not started |
| `TASK-026` | `PRD-FR-003` | `lib/game/components/tools/beam_lamp_component.dart` | 20 dmg/1.2s tick to same lane, cost 100, cooldown 5s, HP 100 per spec §6 | `flutter test` unit test on tick timer and damage application | Not started |
| `TASK-027` | `PRD-FR-003` | `lib/game/components/tools/mirror_component.dart` | Reflects beam 90°, cost 50, cooldown 10s, HP 150; idle+no-crash with no incoming beam (QA checklist #5) | `flutter test` | Not started |
| `TASK-028` | `PRD-FR-003` | `lib/game/components/tools/prism_component.dart` | Splits 60% dmg to 3 lanes, cost 150, cooldown 15s, HP 100; idle+no-crash with no beam (QA checklist #6) | `flutter test` | Not started |
| `TASK-029` | `PRD-FR-003`, `PRD-FR-004` | `RectangleHitbox` wiring on `ShadowComponent`/`BeamComponent`, `with HasCollisionDetection` on game root | Two shadows on the same tile both take beam damage (ray hits first via hitbox, second via area check) per QA checklist #9 | `flutter test` — two shadows same tile, one beam tick, assert both HP dropped | Not started |
| `TASK-030` | `PRD-FR-005` | `lib/game/components/wave_manager_component.dart` | `canSpawnNext()` implements the exact 50%-rule formula from spec §8 (halfDead OR timeOut, gated by `waves[waveIndex].delay`) | `flutter test` — table-driven tests against the formula with known alive/total HP and elapsed time | Not started |
| `TASK-031` | `PRD-FR-006` | Sweep behavior on `GridComponent`/lane (extend `tile_component.dart` or new `sweep_component.dart`) | Auto-triggers at `x<=12`, kills all shadows in lane, 20-particle radial burst, lane vulnerable after use (QA checklist #12 lose condition depends on this) | `flutter test` — shadow crosses x=12, assert lane cleared and sweep marked used | Not started |
| `TASK-032` | `PRD-FR-007`, `PRD-FR-012` | `lib/game/components/hud/overlay_win.dart`, `overlay_lose.dart`, `overlay_pause.dart`, `assets/levels/1.json`, lifecycle hook in `lib/main.dart` | Win overlay shows when all waves spawned and shadow list empty even if timer running (QA checklist #13); lose overlay shows immediately when a shadow reaches `x<=0` with no sweep left (QA checklist #12); `didChangeAppLifecycleState(paused)` calls `game.pauseEngine()` (QA checklist #10) | `flutter test` for win/lose conditions; manual backgrounding test for pause | Not started |

### `PH-03`..`PH-06` — coarse (expand at each prior phase's gate review)

| Task | Phase | PRD-FR | File paths / area | Acceptance criterion | Verification command | Status |
| --- | --- | --- | --- | --- | --- | --- |
| `TASK-033` | `PH-03` | `PRD-FR-009` | `assets/levels/2.json`..`20.json` | All 20 level files parse against spec §22 schema and match spec §9 progression table (flags/par time/tools per band) | `flutter test` — directory-iterating schema/content test | Not started |
| `TASK-034` | `PH-03` | `PRD-FR-010` | `lib/game/worlds/loadout_world.dart` | Player must pick exactly 6 of 8 unlocked tools before battle start; Scout panel shows incoming shadow counts | `flutter test` widget test | Not started |
| `TASK-035` | `PH-03` | `PRD-FR-001` | `lib/game/components/tools/{frost_lens,wall,bomb,twin_bulb}_component.dart` | Frost 15dmg+50% slow 2s; Wall 400HP blocks attack; Bomb 300dmg 3x3 clamped at grid edge (QA checklist #16); Twin only replaces existing Bulb, refund 0 (QA checklist #4) | `flutter test` per tool | Not started |
| `TASK-036` | `PH-03` | `PRD-FR-004` | Cooldown UI on `tray_slot_component.dart`; shadow specials in `shadow_component.dart` | Cooldown shows countdown+ring; Jumper leaps first wall only; Fog reduces beam dmg 30% until Frost hits; Giant throws Imp at 50% HP; Bucket needs 2x bomb/2 beams | `flutter test` per behavior | Not started |
| `TASK-037` | `PH-04` | N/A (polish) | `lib/game/particles/particle_definitions.dart`, `effect_pool.dart` | Full §18.1/§18.2 inventory implemented; `SparkParticle`/`CollectParticle` drawn from an `EffectPool`, not freshly allocated | Code review + draw-call profiling during `flutter run --profile` | Not started |
| `TASK-038` | `PH-04` | N/A (polish) | `lib/core/audio.dart`, haptic gate | All 8 `assets/audio/*.mp3` preloaded via `FlameAudio.audioCache.loadAll`; haptics fire per spec §23 table when `save.haptics==true` | Manual trigger check + log evidence | Not started |
| `TASK-039` | `PH-04` | `PRD-FR-008`, `PRD-FR-015` | `lib/state/battle_notifier.dart` (stars/coins), `lib/game/worlds/shop_world.dart`, `settings_world.dart` | Stars/coins award matches spec §19 formula exactly; Shop purchases persist to Hive; Settings `SwitchComponent` toggles sound/haptics | `flutter test` unit test on award formula + widget tests on Shop/Settings | Not started |
| `TASK-040` | `PH-05` | `PRD-FR-013` | AdMob console (manual), `lib/core/ads.dart` | Real (non-test) AdMob ad unit ids created for banner/interstitial/rewarded, wired via `google_mobile_ads`, closes `AUD-006` | Manual console screenshot + `grep` confirms no `ca-app-pub-3940256099942544` (Google test id) remains in release config | Not started |
| `TASK-041` | `PH-05` | `PRD-FR-014` | Play Console / App Store Connect (manual), `lib/core/iap.dart` | `remove_ads` $2.99 non-consumable product id registered in both stores, wired via `in_app_purchase`, closes `AUD-006` | Manual sandbox purchase test | Not started |
| `TASK-042` | `PH-05` | `PRD-FR-013` | Ad trigger call sites in battle/win flow | Interstitial capped 1/3 wins (`levelId%3==0`); rewarded boost capped 1/battle | `flutter test` on cap logic + manual ad-request log | Not started |
| `TASK-043` | `PH-05` | N/A (NFR/perf) | N/A (test-only) | Layout holds at 812x375 and 1280x720; `flutter run --profile` sustains 60fps, draw calls <50/frame on a low-end Android 720p target | Manual device matrix + Flame FPS counter + profiler | Not started |
| `TASK-044` | `PH-06` | N/A (art QA) | N/A (review-only) | Self-review against spec §4 art direction passes with no open item | Manual checklist review | Not started |
| `TASK-045` | `PH-06` | N/A (release) | N/A | `flutter build apk --release` and `flutter build appbundle --release` both exit 0; all 20 rows of spec §24 QA checklist pass | `flutter build apk --release`; `flutter build appbundle --release`; manual QA checklist run | Not started |

Every implementation task above traces to a requirement or an infra/AUD
finding as noted in its `PRD-FR` column.

## 5. Execution order

Organize work as vertical slices where possible:

1. `PH-00` (`TASK-007`..`TASK-012`): boot the engine, lock orientation, bundle
   fonts, retarget native ids — nothing renders gameplay yet.
2. `PH-01` (`TASK-013`..`TASK-022`): grid + glow economy + HUD shell — proves
   the core "place a thing, see feedback" loop with Hive persistence.
3. `PH-02` (`TASK-023`..`TASK-032`): shadows + beams + sweep + win/lose — the
   first fully playable level (`assets/levels/1.json`).
4. `PH-03`..`PH-06`: expand content, juice, monetization, release — each
   phase's coarse tasks get broken into the detailed table format above at
   that phase's own gate review, once the component shapes from `PH-00`-
   `PH-02` are proven and stable.

Do not build an entire unverified layer before proving one end-to-end slice
— `PH-02`'s exit gate is deliberately "one full level playable," not "all 20
levels."

## 6. Detailed task template

### `TASK-###` — [Verb + observable outcome]

- **Status:** Ready / In progress / Blocked / In review / Verified / Deferred / Cancelled
- **Owner:** [Name/agent.]
- **Requirement:** `PRD-FR-___` / `PRD-NFR-___` / `AUD-___`
- **Phase:** `PH-__`
- **Architecture:** `ADR-___`, architecture §[section]
- **Rules:** `RULE-___`
- **Design:** `DS-___` / N/A
- **Dependencies:** `TASK-___`, external access, decision, migration.
- **Why now:** [Why this is the next smallest valuable/risk-reducing task.]

#### Scope

- [Concrete change.]
- [Concrete state/error path.]

#### Out of scope

- [Nearby work intentionally excluded.]

#### Expected file/module impact

- `[path/module]` — [responsibility/change].

Expected paths guide work but do not authorize violation of the architecture.
Update the task if discovery reveals a different valid shape.

#### Acceptance and verification

| Acceptance criterion | Test/evidence | Environment | Result |
| --- | --- | --- | --- |
| [Reference PRD criterion, do not rewrite its meaning] | [Test name/command/manual protocol] | [Local/test/etc.] | Pending |

#### Risk and rollback

- **Risk:** [Data, security, user experience, compatibility, cost.]
- **Mitigation:** [How reduced.]
- **Rollback/recovery:** [Exact safe path or N/A with reason.]

#### Completion record

- **Completed:** [Date/commit/change reference.]
- **Checks:** [Command/test and result.]
- **Audit findings resolved/created:** `AUD-___` / None.
- **Follow-ups:** `TASK-___` / None.

## 7. Cross-cutting verification matrix

| Concern | Applicable requirement/rule | Planned evidence | Task owner | Result |
| --- | --- | --- | --- | --- |
| Functional acceptance (placement/beam/waves/win-lose) | `PRD-FR-001`, `PRD-FR-003`, `PRD-FR-005`, `PRD-FR-007` | `flutter test` suites per `TASK-016`..`TASK-032` | `TASK-016`..`TASK-032` | Pending |
| Persistence/offline | `PRD-FR-011` | Hive round-trip test, restart simulation | `TASK-022` | Pending |
| Performance | 60fps empty scene, <50 draw calls/frame | Flame FPS counter + `flutter run --profile` | `TASK-009`, `TASK-043` | Pending |
| Reliability/lifecycle | `PRD-FR-012`, QA checklist #10, #18, #19, #20 | Manual backgrounding + component-leak review | `TASK-032`, `TASK-045` | Pending |
| Responsive/visual | 812x375 and 1280x720 | Screenshot evidence both viewports | `TASK-043` | Pending |
| Build/release | `PH-06` gate | `flutter build apk/appbundle --release` | `TASK-045` | Pending |
| Offline-first / no runtime font fetch | `AUD-002` | `grep -r "GoogleFonts\." lib/` | `TASK-011` | Pending |

Accessibility and security/privacy rows are intentionally omitted until
`docs/rules.md`/`docs/design.md` define applicable thresholds for an
offline, no-account, no-PII single-player game — add them if that changes.

## 8. Dependency and migration plan

| Change | Reason/source | Compatibility impact | Migration steps | Rollback/recovery | Task |
| --- | --- | --- | --- | --- | --- |
| `hive_ce_flutter` instead of spec-pinned `hive_flutter` | `hive_flutter`/`hive` is discontinued upstream; `hive_ce_flutter` is the maintained fork (`AUD-001`) | Same API surface, package name differs in `pubspec.yaml` and imports | Already applied in `pubspec.yaml`; write `lib/core/hive.dart` against `hive_ce_flutter` | Revert to `hive_flutter` if `hive_ce_flutter` proves unmaintained | `TASK-022` |
| Bundled fonts instead of `google_fonts` runtime fetch | Offline-first product forbids runtime font download (`AUD-002`) | `google_fonts` dependency can be dropped once TTFs are sourced/licensed and bundled | Source licensed TTFs, add `fonts:` section to `pubspec.yaml`, replace `GoogleFonts.orbitron()` calls with local `TextStyle(fontFamily:...)` | Keep `google_fonts` as a fallback only if a compatible bundled font cannot be sourced in time — record as an accepted risk in `docs/audit.md` if so | `TASK-011` |
| Current Flame/go_router/google_fonts majors instead of spec-pinned old majors | Spec §21 pins versions incompatible with Dart 3.11 (`AUD-003`) | API surface differs from spec's code snippets (e.g. `CameraComponent` API, `go_router` builder signatures) — component code must be written against the resolved current majors, not copied verbatim from spec snippets | Already applied in `pubspec.yaml`; verify each spec code snippet compiles against resolved versions before relying on it | N/A — no working version to roll back to yet | `TASK-007`..`TASK-032` (ongoing) |

## 9. Release/rollout plan

- **Release unit/version:** First internal build after `PH-06` exit gate
  (signed APK/AAB), version `1.0.0+1`.
- **Pre-deploy checks:** All `PH-00`..`PH-06` exit gates green; full spec
  §24 QA checklist passes; `docs/audit.md` has no open Critical/High finding.
- **Migration order:** N/A — no prior release exists.
- **Rollout strategy:** Manual, solo developer; internal testing track
  first (Play Console internal test / TestFlight), no staged rollout
  automation exists yet.
- **Health signals:** Manual crash/ANR check in store console; no analytics
  pipeline defined yet (deferred — no PRD-NFR requires one currently).
- **Abort conditions:** Any Critical/High `AUD-*` finding discovered during
  internal test.
- **Rollback/recovery:** Unpublish/halt rollout in store console; no
  server-side component to roll back (offline-first, no backend).
- **Post-release validation:** Play/complete all 20 levels on a real device
  post-install; confirm Hive save survives app kill/relaunch.

## 10. Definition of done

A task may be marked `Verified`/`Done` only when:

- [ ] It meets mapped acceptance criteria without expanding scope.
- [ ] All applicable checks from `AGENTS.md` pass.
- [ ] Tests cover success, expected failure, and relevant edge/recovery paths.
- [ ] Architecture, dependency, security, and design rules are satisfied.
- [ ] Required migration/rollback and observability are present.
- [ ] No placeholders, debug bypasses, fake production paths, or unexplained TODOs remain.
- [ ] Audit findings are updated with evidence.
- [ ] Plan, phase status if affected, and memory handoff are synchronized.

## 11. Plan change log

| Date | Task IDs | Change | Reason/source | Owner |
| --- | --- | --- | --- | --- |
| 2026-09-03 | `TASK-001`..`TASK-045` | Initial executable plan, `TASK-001`..`TASK-006` marked Done | First fill against `LIGHT_vs_SHADOW_Prism_Defense_Flame_Spec.md` §25, `docs/GOVERNANCE.md` ID scheme | Solo developer |
| 2026-09-03 (c2) | `TASK-008` | Reconciled against actual code (file is `lib/core/tokens.dart`, not `lib/core/theme.dart`); root-caused `flutter analyze`'s 44 world-screen errors to this file's `dart:ui.TextStyle` vs `package:flutter/painting.dart`'s; marked In progress and assigned to Cursor | `AUD-011`; `flutter analyze` evidence gathered this cycle | Claude planner |
| 2026-09-04 (c6) | `TASK-013`..`TASK-022` (`PH-01`) | Reconciled all ten rows against the tree: eight were already implemented and merely unverified, so they move to Done with the new `test/ph01_exit_gate_test.dart` as evidence; `TASK-020` is Done-partial (no red-pulse API to assert); `TASK-021` is Dropped under `ADR-007`. Recorded three file-naming drifts the plan carried since `PH-07` (`backdrop_layer.dart` -> `backdrop_layers.dart` consolidation, `tile_component.dart` folded into `grid_component.dart`, `hive.dart` -> `save_store.dart`) | `AUD-016`, `ADR-007`; `flutter analyze` clean and `flutter test` 42/42 at `9cc0c49`, both re-run by the lead | Claude (lead), implementation by Cursor |
| 2026-09-04 (c5) | `TASK-007` | Wrote `lib/app.dart` (the `WidgetsApp.router` shell, `ADR-003`/`ADR-006`) and `test/app_boot_test.dart`; marked Done. Closed `AUD-013` (mechanical `const Vector2` removal, `adf7676`) and `AUD-012`. Booting the app for the first time exposed `AUD-014` (`OpacityEffect` on non-`OpacityProvider` components) — fixed with the `FadeableRender` mixin in the same commit | `AUD-012`/`AUD-013` closure evidence; `AUD-014` (new); `flutter analyze` clean, `flutter test` 35/35 | Claude (lead) |
| 2026-09-04 (c4) | `TASK-008` | Confirmed Cursor's 3-file diff landed (commit `8387953`); reran `flutter analyze` (34) and `flutter test` (34/34) to verify; marked Done, closed `AUD-011`. Assigned the next smallest slice — a missing `package:flame/events.dart` import in `right_panel_component.dart` (`AUD-012` sub-slice, no new `TASK-*` number, mechanical import fix) — to Cursor via `.ai/inbox/gnhf-assignment.md` | `AUD-011` closure evidence; `AUD-012` partial remediation | Claude planner |
