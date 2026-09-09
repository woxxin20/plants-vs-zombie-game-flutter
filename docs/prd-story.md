# PRD Story — LIGHT vs SHADOW: Prism Defense

**One document, the whole arc: idea → code → tests → review → playable → shipped.**

Status: Active · Owner: repo owner · Last verified 2026-09-09 (c15) against `main` @ `7a48bed` + working tree

---

## 0. What this document is, and is not

This is the **narrative spine**. It sequences the work, states honestly where the
game actually stands, and defines what "finished" means. It is the one file to
open when the question is *"where are we, really?"*

It **does not own any truth of its own**. Every claim here belongs to a canonical
owner, and on conflict that owner wins:

| Claim you want to check | Real owner |
| --- | --- |
| What the product must do | [`docs/prd.md`](./prd.md) (`PRD-FR-*`, `PRD-NFR-*`) |
| Milestones and exit gates | [`docs/phases.md`](./phases.md) (`PH-*`) |
| Findings and verification evidence | [`docs/audit.md`](./audit.md) (`AUD-*`) |
| Architecture decisions | [`docs/architecture.md`](./architecture.md) (`ADR-*`) |
| What to do next, right now | [`STATE.md`](../STATE.md) |
| What the code *is* | the codegraph index |

If this file and one of those disagree, **that owner is right and this file is
stale** — fix it here and record the drift in `docs/audit.md`.

This document deliberately replaces nothing. In particular, the `flame-harness`
`docs/harness/` stack was **not** bootstrapped (owner decision, `STATE.md` →
DECISIONS): one governance tree, not two.

---

## 1. The idea

An offline landscape lane-defense game. A 21-tile grid, three lanes. You spend
**Glow** to place light tools; **Mirrors** bend the beam 90°, **Prisms** split it
three ways; **Shadows** walk the lanes and eat your tools. Twenty levels, stars
for speed, no backend, no account, airplane-mode clean.

Source material: `LIGHT_vs_SHADOW_Prism_Defense_Flame_Spec.md` — input to the
PRD, never the requirement itself.

The repository began as a Plants-vs-Zombies Flutter widget demo. It was
repurposed, not extended; the old widget game is gone (history before `ae7a5b6`).

---

## 2. The story so far

| Cycle | What actually happened |
| --- | --- |
| c1–c2 | Governance kit deployed, 8 docs filled, `pubspec.yaml` retargeted to Flame, old `lib/` removed, pure rules written and unit-tested. |
| c3–c4 | Analyzer dug out of a 56-issue hole across three cycles. `AUD-011` (missing Flame events import) closed. |
| c5 | GNHF agent loop had stalled; lead took the work directly. Wrote `lib/app.dart` — the app had **no shell and could not boot at all** until then. Booting it for the first time immediately surfaced `AUD-014` (`OpacityEffect` on four non-`OpacityProvider` components). |
| c6 | `AGENTS.md` §6 filled, README rewritten as the doc-ownership map, `ADR-007` dropped the Riverpod state layer that was never built. Cursor delivered PH-01..PH-04 under bounded assignments; review found `AUD-017` (`game.world` ≠ `camera.world`). |
| c7 | **First device run in the project's history** (SM-S711B). The Android build had been broken the whole time — `google_mobile_ads 6.0.0` calls `configurations.all`, removed in Gradle 9.3.1. Deferring ads/IAP unblocked it. Two criticals found within ten minutes: `AUD-019` (routed Navigator swallowed **every** tap — the game was entirely untappable) and `AUD-020` (loadout demanded 6 tools, level 1 offers 3 — **no level was startable**). |
| c8 | `AUD-021` root-caused: the battle HUD was **written and never wired** — `TopBarComponent`, `RightPanelComponent` and `ToastComponent` had zero call sites in `lib/`. The c7 diagnosis (a `swapWorld` viewport-clear race) was **wrong** and is recorded as wrong. Fixed, plus `AUD-022` (worlds accumulated). 70/70. |
| c9 | First tests that play levels without forcing terminal state. Level 1 wins through placed Beams; level 4 loses idle. Found `AUD-023`: levels 1–3 win themselves. 72/72. |
| c10 | Debug APK built, installed, and entered battle on SM-S711B. c8 HUD fix confirmed. Found `AUD-024`: Pause/Win/Lose pause Flame before their overlay mounts, freezing an input-dead battle frame. |
| c11 | Two app restarts reproduced `AUD-024`: Pause froze without a dialog, then an idle level 1 froze at terminal transition without VICTORY. Stable frame hashes and clean logcat make the result conclusive. |

---

## 3. Where the game actually is

Two numbers, because they are very different:

- **Build-up (code written): ~85%**
- **Test-1 (verified working): ~40%**

| Dimension | % | Evidence |
| --- | --- | --- |
| Code written | 90 | 8 tools, all shadow types, optics, waves, economy, 20 level JSONs, 6 worlds, full HUD |
| Verified by tests | 75 | 72 tests, `flutter analyze` clean. A level is now played to a win, and to a loss, with no forced state (c9) |
| Verified on hardware | 25 | Home → Loadout → Battle, tool placement, Glow collection, waves, and HUD confirmed on SM-S711B; terminal/pause overlays fail (`AUD-024`) |
| **A level played start → win/lose** | **50** | **In the suite, yes (c9). Hardware reached the terminal transition in c10, but no overlay mounted; human end-to-end play still fails.** |
| Ship-ready | 10 | No audio, no bundled font, wrong app id, no keystore |

### Phase gates

| Phase | % | State |
| --- | --- | --- |
| `PH-07` governance bootstrap | 100 | Complete |
| `PH-00` engine bootstrap | 70 | 4/6 — device + fps items unrun |
| `PH-01` grid, glow economy, HUD shell | 85 | 6/7 |
| `PH-02` combat core | 85 | 6/7 — played to both outcomes in-suite; hardware reaches battle but `AUD-024` blocks pause/win/lose UI |
| `PH-03` full content | 100 | 5/5, data-driven against the JSON |
| `PH-04` juice | 80 | 2/5 — assets ship, but no cue has been observed playing; `TASK-037`/`TASK-039` not started |
| `PH-05` monetization + polish | 20 | Ads/IAP descoped by owner; 60fps never profiled |
| `PH-06` release | 0 | Not started |

---

## 4. The distinction that matters: written vs verified

This project's single most expensive lesson, stated plainly:

> **A clean analyzer, 70 passing tests and a correct-looking screenshot did not
> mean the product worked.** Five times. Twice catastrophically.

| Defect | What a green suite said | What was true |
| --- | --- | --- |
| `AUD-014` | 34/34 pass | App crashed on the first frame after mount |
| `AUD-019` | 62/62 pass | **Every tap in the game was swallowed. Nothing was clickable.** |
| `AUD-020` | 62/62 pass | **No level could be started from a fresh save.** |
| `AUD-021` | 66/66 pass | Battle had no HUD; no tray, so nothing could be placed |
| `AUD-024` | 72/72 pass | Pause/Win/Lose froze the battle before their overlays mounted |

Three test-design faults let these through, and all are still worth guarding:

1. **A guard without a reachability check is half a test.** `PH-03` asserted
   "≠6 tools is blocked" — true the entire time — while 6 was unreachable.
2. **A component tested in isolation never asks whether anything mounts it.**
   `test/ph01_exit_gate_test.dart:247` builds a bare `FlameGame`, adds a
   `TopBarComponent` by hand, and therefore could never see `AUD-021`.
3. **A test helper must not repair the production transition it checks.**
   `_flushLifecycle` resumes the engine after Pause/Win/Lose, letting queued
   overlays mount. Real gameplay never performs that resume, exposing `AUD-024`.

Rules adopted from this, now standing:

- A regression test that has never failed proves nothing. Stash `lib/` to the
  pre-fix commit, confirm the new test **fails behaviourally**, then restore.
- Assert through the production surface (`camera.viewport`), never through a
  getter added for the test — otherwise the negative control only proves the
  test does not compile.
- Trust the device over the suite.

### Known-weak coverage, named

Win and lose are asserted by **forcing** the terminal condition:

```dart
world.waveIndex = world.level.waves.length;   // forced, not played
world.update(0.016);
expect(world.state, GameState.won);
```

`test/ph02_exit_gate_test.dart` and `integration_test/uj01_test.dart` both do
this. **No test plays the game.** None spawns a wave, walks a shadow, kills it
with a beam and wins because the simulation got there. Terminal states are
covered; the loop that reaches them is not. Closing that gap is `PH-02-G3`
below, and it is the highest-value test left to write.

Three tautological assertions also remain at `test/ph03_exit_gate_test.dart:167-169`
— they restate `models.dart:150,153,156` verbatim and cannot fail.

---

## 5. The road to finish

In order. Each step names its exit criterion. Nothing below is optional for v1.

### Step 1 — Prove it runs (`PH-02` gate, blocks everything)

| ID | Work | Exit criterion |
| --- | --- | --- |
| `PH-02-G1` | Device playthrough — **blocked by `AUD-024`** | On the SM-S711B: PLAY → START BATTLE → HUD renders → place a tool → a shadow dies → reach win **or** lose. One human, one level, end to end. c10 reached the terminal transition, then froze with no overlay. |
| `PH-02-G2` | ✅ **Done (c10)** — confirm the c8 HUD fix on hardware | Glow chip, wave counter, pause button, tray, health bars, and rewarded-glow control rendered on SM-S711B; tool selection/placement and Glow collection responded to ADB taps |
| `PH-02-G3` | ✅ **Done (c9)** — `test/battle_playthrough_test.dart` | Plays level 1 to a win with every lane sweep unspent, and lets level 4 run to a loss. Negative-controlled: fails when Beam damage is zeroed |
| `PH-02-G4` | Fix `AUD-024` | Pause/Win/Lose overlays mount before the engine stops, remain interactive, and pass a regression that never resumes the engine to flush them |

Until `PH-02-G1` passes, the honest answer to "does the game work?" is
**unknown**, regardless of the test count. `PH-02-G3` narrowed it: the
simulation can be played to both terminal states. It says nothing about whether
a finger on glass can do the same.

### Step 2 — Close the test-quality debt

| ID | Work | Exit criterion |
| --- | --- | --- |
| `T-1` | ✅ **Done (c9)** | The three shadow specials are now literals in the spec §7 table. Negative-controlled: forcing `resistsBeam` to `false` now fails |
| `T-2` | ✅ **Done (c9)** | Swept every negative assertion in `test/`. Loadout, shop and rules already had positive pairs; the forced win/loss in `ph02_exit_gate_test.dart:167` did not, and now points at its reachability pair |

### Step 3 — Make it a game, not a simulation (`PH-04`)

| ID | Work | Exit criterion | Blocked on |
| --- | --- | --- | --- |
| `A-1` | 8 audio files into `assets/audio/` | Place/collect/shoot/hit/explosion/win/lose/sweep all audible | Done c13 — files generated by `tool/generate_audio.py`. "Audible" is still unproven: no test host has the audio plugin |
| `A-2` | Close `AUD-018` | `GameAudio.setSoundEnabled` no longer calls `audioCache.clearAll()` | Code done c13; `AUD-018` reopened at c14 pending a negative-controlled test or device run |
| `A-3` | Resolve `AUD-027` | `startBgm()` has a production call site, or BGM is struck from `PRD-FR-021` | Done c15 — owner chose to wire it; started from `main.dart`, lifecycle-aware |
| `F-1` | Bundle a licensed font | Text renders in the design typeface, not the OS default; closes `AUD-002` | **Human** (licensing) |

### Step 4 — Identity and performance (`PH-05`)

| ID | Work | Exit criterion | Blocked on |
| --- | --- | --- | --- |
| `ID-1` | Bundle id + app label | Home screen no longer reads `plants_vs_zombie`; closes `AUD-005` | **Human** |
| `P-1` | Profile 60fps | `flutter run --profile` on low-end 720p Android sustains 60fps, <50 draw calls (`PRD-NFR-001`) | — |
| `V-1` | Multi-viewport check | Correct at 812x375 baseline through 1280x720+ (`PRD-NFR-006`) | — |

### Step 5 — Balance and feel

Not yet started, and not yet possible: nobody has played the game, so nobody
knows whether 20 levels are fun, whether the Glow curve works, or whether the
difficulty ramp is sane. **This step cannot begin before `PH-02-G1`** — except `B-0`, which c9 found
without a device and which is a content bug, not a taste call.

| ID | Work | Exit criterion |
| --- | --- | --- |
| `B-0` | Fix `AUD-023` — levels 1–3 are won by doing nothing | An idle run of levels 1–3 ends `lost`. Found c9: one sweep per lane clears an entire lane, and a 3-wave level never presents more than three lane-arrivals |
| `B-1` | Play all 20 levels | Each is completable; note which are trivial or impossible |
| `B-2` | Retune `tool/gen_levels.py` and regenerate | Difficulty ramps monotonically. Regenerate — never hand-edit `assets/levels/*.json` |

### Step 6 — Release (`PH-06`)

| ID | Work | Exit criterion | Blocked on |
| --- | --- | --- | --- |
| `R-1` | Art-direction pass | `docs/design.md` `DS-*` honoured on device | — |
| `R-2` | Signed APK/AAB | Release build installs from a signed artifact | **Human** (keystore) |
| `R-3` | Spec §24 QA checklist | All items pass on hardware | `R-2` |

### Deferred, by owner decision (2026-09-04)

`PRD-FR-016` (banner/interstitial), `PRD-FR-017` (rewarded boost),
`PRD-FR-018` (IAP remove-ads). `google_mobile_ads` and `in_app_purchase` are
commented out in `pubspec.yaml:27,31` because 6.0.0 broke the entire Android
build against Gradle 9.3.1. `lib/core/monetization.dart` is deleted and
recoverable from git. The rewarded-boost **button and payout logic exist and
work** (`BattleWorld.grantBoost`) — only the ad behind it is absent.

These three requirements still read `Must` in `docs/prd.md`. That is live drift:
either the PRD withdraws them for v1, or v1 does not ship without them. **Owner
decision required** — see §7.

---

## 6. Definition of Done — v1

v1 ships when every line is true. Not before.

- [ ] A human plays level 1 start to win **and** start to lose, on hardware
- [ ] All 20 levels are completable, verified by playing them
- [x] A test plays a level to a win without forcing state (c9)
- [ ] `flutter analyze` clean, `flutter test` green, `flutter test integration_test` green
- [ ] 60fps sustained on low-end 720p Android, profiled (`PRD-NFR-001`)
- [ ] Save survives a force-kill with zero loss (`PRD-NFR-002`)
- [ ] All 8 audio cues audible; sound and haptics toggles work
- [ ] Bundled licensed font renders throughout
- [ ] App identity is the game's own, on both platforms
- [ ] Layout correct from 812x375 to 1280x720+
- [ ] Signed release artifact installs and runs
- [ ] Spec §24 QA checklist passes on hardware
- [ ] Zero open Critical or High `AUD-*`
- [ ] Every `PRD-FR-*` is `Verified` or explicitly withdrawn for v1

---

## 7. Open decisions — owner only

| # | Question | Blocks |
| --- | --- | --- |
| 1 | Do `PRD-FR-016/017/018` (ads, IAP) stay `Must` for v1, or are they withdrawn to v1.1? | The release-acceptance list, and whether `PH-05` can ever close |
| 2 | Bundle id + app label (`ARCH-Q-003`) | `ID-1`, and every store artifact |
| 3 | ~~Does BGM stay in scope?~~ Answered 2026-09-09: keep and wire it. `AUD-027` closed | — |
| 4 | Font licensing (`ARCH-Q-001`) | `F-1`, `AUD-002` |
| 5 | Keystore / signing identity | `PH-06`, `R-2` |

---

## 8. Requirement status legend

`docs/prd.md`'s requirement index previously showed **every** requirement as
`Proposed`, which tracked nothing. It now uses:

| Value | Meaning |
| --- | --- |
| `Proposed` | Written, not yet built |
| `Built` | Code exists; no test proves it |
| `Tested` | Covered by an automated test that is known to fail without the feature |
| `Verified` | Confirmed on real hardware by a human |
| `Deferred` | Descoped for this release by owner decision |

Current tally across the 20 functional requirements: **1 `Verified`**
(`PRD-FR-020`, landscape lock — observed forcing `ROTATION_90` on the SM-S711B
in c7), **14 `Tested`**, **2 `Built`** (`PRD-FR-006` shadow specials, whose only
assertions are the tautologies noted in §4; `PRD-FR-009` sweep, whose trigger is
never driven), **3 `Deferred`**.

So: one requirement out of twenty has ever been confirmed by a human on real
hardware, and it is the one about screen rotation. That is the honest state, and
it is the single fact this whole document exists to make unavoidable.

## 9. Change log

| Date | Change |
| --- | --- |
| 2026-09-07 (c8) | Created. Consolidates the arc c1→c8, the verified-vs-written scorecard, and the ordered path to v1. |
| 2026-09-07 (c9) | `PH-02-G3`, `T-1`, `T-2` closed. Scorecard moved test-1 30% → 40%. New `AUD-023` (levels 1–3 win themselves) entered as `B-0`. `PRD-FR-006` and `PRD-FR-009` promoted `Built` → `Tested`. |
| 2026-09-07 (c10) | `PH-02-G2` closed on SM-S711B. `PH-02-G1` reached the terminal transition but failed: Pause/Win/Lose overlays never mount after `pauseEngine()`. Added `AUD-024`, `PH-02-G4`, and `TASK-046`. No `PRD-FR-*` status promoted because the end-to-end hardware journey remains broken. |
| 2026-09-07 (c11) | Restart/retry confirmed `AUD-024` is deterministic, not stale device/app state. Pause and terminal transitions failed after independent cold starts. No `PRD-FR-*` status changed; `TASK-046` remains the next implementation action. |
