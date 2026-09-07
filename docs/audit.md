---
document: Implementation Reality Audit
authority: Evidence of current implementation, conformance, drift, defects, and release risk
status: Active
owner: "Solo developer (repo owner)"
last_updated: "2026-09-07"
---

# Audit — LIGHT vs SHADOW: Prism Defense

This file is the reality check. It records what the repository **actually
proves**, compares that evidence with the intended product
(`LIGHT_vs_SHADOW_Prism_Defense_Flame_Spec.md`), and creates traceable
remediation. It is not softened to match optimistic status reports.

**Important note on this audit's evidence base:** the brief for this audit
stated no game code existed yet and that only `flutter pub get` and
`flutter --version` had been run. While gathering evidence for this pass,
this auditor found that is no longer accurate — see `AUD-008`. This audit
records what was actually observed in the repository at the timestamp in
§2, not the briefed assumption.

## 1. Audit rules

- Evidence is required. "Looks done" and "should work" are not evidence.
- Runtime/tests describe current behavior; PRD/architecture/rules/design describe intended behavior.
- A mismatch is a finding, not an automatic change to the specification.
- Every finding has severity, evidence, owner, remediation task, and retest result.
- Closed findings remain in the log; never delete audit history.
- The implementer may collect evidence, but release-significant exceptions should be accepted by the accountable owner.
- Audits are read-only inspections unless a separate task authorizes remediation. This audit ran two read-only commands (`flutter analyze`, `git status`/`git log`) beyond the briefed baseline to gather honest evidence; it made no code or dependency changes.

## 2. Audit metadata

- **Audit date:** 2026-09-03 (snapshot timestamp 2026-09-03T11:04Z)
- **Auditor:** Claude Sonnet 5 (governance-doc agent)
- **Repository/version:** `main` branch, no commit captures the current
  working tree (see `AUD-009`) — last real commit is `4b4c974` ("Update
  README.md"), which still reflects the pre-repurposing PvZ-widgets game.
- **Environment:** Local dev, Windows 11, Flutter 3.47.0 stable (per
  briefed `flutter --version` run).
- **Scope:** Full baseline audit before feature work begins (governance
  kit setup checklist item), per `docs/GOVERNANCE.md` §"Setup checklist".
- **Mapped phase/release:** `PH-07` (governance bootstrap) closing out;
  gate for `PH-00` start.
- **Previous audit:** None — this is the first audit.
- **Limitations:** No device/emulator run was performed (no `flutter run`,
  no `flutter test`, no `flutter build`). No security/accessibility/
  performance testing was performed — none of it applies yet since no
  screen or gameplay code is wired into `main.dart` or verified to run.
  This audit is evidence of repo/file/dependency state only.

## 3. Result vocabulary

Conformance result: `Pass`, `Partial`, `Fail`, `Not implemented`,
`Not applicable`, `Not verified`.

Finding severity: Critical, High, Medium, Low, Info (see full table in the
template — unchanged from `docs/GOVERNANCE.md`).

## 4. Executive reality summary

| Area | Result | Evidence summary | Highest finding |
| --- | --- | --- | --- |
| Product/functional | Not verified | No `flutter run`/device test performed; partial component code exists but is unwired and untested | `AUD-007` (Medium) |
| Architecture/data | Partial | `pubspec.yaml` resolves current majors correctly (`AUD-003` closed); persistence fork substitution documented (`AUD-001`) | `AUD-001` (Low) |
| Rules/code quality | Fail | `flutter analyze` (run live this audit) reports 1 error, 1 warning, 1 info against the partial code that already exists | `AUD-008` (Medium) |
| Design/accessibility | Not applicable | No screen renders yet; nothing to audit visually | None |
| Security/privacy | Not applicable | Offline, no accounts, no PII, no network calls implemented yet | None |
| Performance/reliability | Not verified | No build/profile run performed | None |
| Tests/build/release | Fail | `test/` directory exists but contains zero test files; no build has been attempted | `AUD-007` (Medium) |
| Documentation/traceability | Partial | This pass creates the first `PH-*`/`TASK-*`/`AUD-*` IDs; `docs/prd.md`, `architecture.md`, `rules.md`, `design.md` remain Draft templates | `AUD-002` cross-reference |

**Overall decision:** `No-go` (for any release/feature-complete claim —
expected and correct at this stage of a project that has no working game
yet; this is not a release gate, it is the required baseline audit before
feature work begins).

**Decision basis:** No screen has ever been run on a device or emulator.
`flutter analyze` fails with one real error in code that already exists
uncommitted in the working tree. Zero automated tests exist. The entire
repurposing effort — governance kit, rewritten `pubspec.yaml`, new game
code, new level assets, and the deletion of the old game — has never been
committed to git (`AUD-009`, High), which is the most consequential finding
in this audit: a single `git reset --hard` or `git checkout -- .` right now
would destroy all of it with no recovery path.

## 5. Requirement conformance matrix

`docs/prd.md` has no approved `PRD-FR-*` ids yet (still a Draft template),
so this matrix uses the plausible topical ids from
`docs/implementation_plan.md` §"ID reconciliation note" and records
`Not verified` for all of them — no functional requirement has been
exercised end to end yet.

| Requirement | Acceptance/test | Implementation evidence | Result | Finding/task |
| --- | --- | --- | --- | --- |
| `PRD-FR-001` Placement/validation | Spec §17 7-check table | No `tryPlace` implementation found in `lib/` | Not implemented | `TASK-019` |
| `PRD-FR-002` Glow economy | Spec §5 | `lib/data/rules.dart`, `lib/data/content.dart` exist (untested) — likely hold cost/cooldown constants, not verified to be wired | Not verified | `TASK-017`, `TASK-018` |
| `PRD-FR-003` Beam optics | Spec §15 | `lib/data/optics.dart` (325 lines) exists — largest data file present, suggests trace-algorithm groundwork, but has no test and is not invoked from any component yet | Not verified | `TASK-025` |
| `PRD-FR-004` Shadow AI | Spec §7 | `lib/game/components/shadow_component.dart` exists (untested, not reviewed for correctness in this pass — code review is out of this audit's scope) | Not verified | `TASK-023` |
| `PRD-FR-005` Waves/50% rule | Spec §8 | No `wave_manager_component.dart` found | Not implemented | `TASK-030` |
| `PRD-FR-006` Sweep | Spec §5 | Not found | Not implemented | `TASK-031` |
| `PRD-FR-007` Win/lose | Spec §16 | Not found | Not implemented | `TASK-032` |
| `PRD-FR-011` Persistence | Spec §19 | `lib/core/save_store.dart` exists (121 lines, untested); `hive_ce`/`hive_ce_flutter` resolved in `pubspec.yaml` | Not verified | `TASK-022` |
| `PRD-FR-012` Lifecycle/pause | Spec §24 #10 | Not found in the 2 files searched (`main.dart` does not exist yet either — deleted with the old game, no replacement) | Not implemented | `TASK-007`, `TASK-032` |
| All other `PRD-FR-*` (008-010, 013-015) | — | No evidence searched — out of scope for `PH-00`-`PH-02` | Not verified | See `implementation_plan.md` §4 |

## 6. Journey audit

No user journey has been run — there is no `main.dart` entry point in the
current working tree (deleted with the old game; no Flame-based
replacement committed or verified yet). `Not verified` for every row until
`PH-00`'s exit gate (`docs/phases.md` §4) is met.

| Journey | Scenario | Environment/data | Expected source | Actual evidence | Result |
| --- | --- | --- | --- | --- | --- |
| Boot | Cold start to empty `BattleWorld` at 60fps | Local emulator | Spec §25 Phase 0 | No `main.dart` exists; never run | Not verified |
| Place-a-tool | Tap tile, place Bulb, see glow deduct | Local emulator | Spec §17 | No `tryPlace` exists | Not implemented |
| Win level 1 | Full level clear | Local emulator | Spec §25 Phase 2 | No wave/beam/sweep logic exists | Not implemented |

## 7. Architecture conformance

| Check | Expected source | Evidence | Result | Finding |
| --- | --- | --- | --- | --- |
| Stack and major packages match accepted ADRs | Spec §21 vs `pubspec.yaml` | `pubspec.yaml` pins `flame ^1.34.0`, `flame_audio ^2.11.0`, `flame_riverpod ^5.4.0`, `flutter_riverpod ^2.6.1`, `go_router ^16.0.0`, `hive_ce ^2.11.0` + `hive_ce_flutter ^2.3.0`, `google_mobile_ads ^6.0.0`, `in_app_purchase ^3.2.0`; inline comments reference `ADR-001`..`ADR-005` that do not yet exist in `docs/architecture.md` | Partial | `AUD-001`, `AUD-003` |
| Assets live at repo root, not inside `lib/` | Spec §21 shows `assets/` nested under `lib/` (wrong for Flutter) | `pubspec.yaml` `flutter.assets:` lists `assets/data/`, `assets/levels/`, `assets/audio/` at repo root; confirmed present on disk | Pass (already correctly diverged from the spec's own structural error) | `AUD-004` (Info, closed) |
| `uses-material-design: false` enforced | Spec "WHY FLAME" — zero Material3/Cupertino | `pubspec.yaml` line 39 sets it `false` with an explanatory `RULE-UI` comment | Pass | None |
| Repository/modules match documented ownership | Spec §21 `lib/` tree | Partial match: `lib/core/{layout,save_store,tokens}.dart`, `lib/data/{content,models,optics,rules}.dart`, `lib/game/light_vs_shadow_game.dart`, `lib/game/components/{backdrop_layers,grid_component,shadow_component}.dart`, `lib/game/components/tools/tool_component.dart` exist; no `lib/main.dart`, no `lib/core/{theme,router,hive,audio}.dart`, no `lib/game/worlds/*`, no `lib/state/*` yet | Partial | `AUD-008` |

## 8. Rule and dependency audit

`docs/rules.md` is still a Draft template with no accepted `RULE-*` ids, so
this section records evidence against the spec's own stated rules
(no-Material, offline-only) instead of a `RULE-*` id.

| Rule/check | Evidence | Result | Finding |
| --- | --- | --- | --- |
| Zero Material/Cupertino widgets | `uses-material-design: false` in `pubspec.yaml`; `flutter analyze` run this audit shows no Material-related errors (too little code exists to fully evaluate) | Not verified (insufficient code surface) | None yet |
| No runtime font fetching (offline-first) | `pubspec.yaml` correctly omits `google_fonts` as a dependency; but no bundled-font replacement exists — no `assets/fonts/`, no `fonts:` section | Fail (mandate not violated, but also not fulfilled — no font solution exists at all) | `AUD-002` |
| Quality command passes (`flutter analyze`) | Run live this audit: `flutter analyze` → 1 error (`undefined_identifier 'Curves'` in `lib/game/components/tools/tool_component.dart:62`), 1 warning (`must_call_super` in `lib/game/light_vs_shadow_game.dart:30`), 1 info (`unnecessary_import` in `lib/game/light_vs_shadow_game.dart:8`) | Fail | `AUD-008` |
| Dependency policy — no discontinued packages | Spec pins `hive_flutter` (discontinued); `pubspec.yaml` uses `hive_ce`/`hive_ce_flutter` (maintained fork) instead | Pass (deliberate, documented substitution) | `AUD-001` (Low, accepted) |

## 9. Design and accessibility audit

Not applicable this pass — no screen has been implemented or run, so there
is nothing to visually or accessibility-audit yet. `docs/design.md` is
also still a Draft template with no accepted `DS-*` tokens. Re-run this
section at the `PH-00`/`PH-01` gate review once `TopBarComponent` and one
real screen render.

## 10. Security and privacy audit

Not applicable this pass. The product is offline-first with no accounts,
no PII collection, and no network calls implemented (ads/IAP are deferred
to `PH-05`, `TASK-040`/`TASK-041`). Re-run once `google_mobile_ads`/
`in_app_purchase` are actually wired, since those introduce a network/SDK
surface that does need review.

## 11. Performance, reliability, and operations audit

Not verified — no build, profile, or device run has been performed. This
section becomes meaningful starting at `PH-00`'s exit gate (empty-scene
60fps baseline, `docs/phases.md` §4).

## 12. Test and build evidence

| Date | Check/command | Scope/environment | Result | Duration/notes | Finding |
| --- | --- | --- | --- | --- | --- |
| 2026-09-04 (c6) | `flutter test` | Local Windows, `HEAD` `d39b6b0` | Pass — 62/62 after `PH-02`..`PH-04` + `AUD-017` fix | Re-run by the lead on every phase, never taken from the worker's report | `AUD-017` found here |
| 2026-09-04 (c6) | `flutter analyze` | Local Windows, `HEAD` `9cc0c49` | Pass — `No issues found!` | Re-run by the lead, not taken from the worker's report | None |
| 2026-09-04 (c7) | `flutter build apk --debug` + install + launch | **SM-S711B, Android 16 (API 36), real hardware** | Pass — launches, forces `ROTATION_90` from portrait with auto-rotate on, no Dart exception in logcat | First time this project has ever run on a device. Android build was **broken** until `google_mobile_ads` was deferred | `AUD-019`, `AUD-020`, `AUD-021` all found here |
| 2026-09-04 (c7) | `flutter test` | Local Windows, `HEAD` `256e995`+ | Pass — 66/66 | Re-run by the lead | `AUD-019`/`AUD-020` regressions |
| 2026-09-07 (c8) | `flutter test test/battle_hud_test.dart` | Local Windows, `lib/` stashed to `3bc5171` | **Fail — 0/4**, behavioural (file compiles) | Deliberate negative control: a regression test that has never failed proves nothing | `AUD-021`, `AUD-022` |
| 2026-09-07 (c8) | `flutter analyze` + `flutter test` | Local Windows, HUD wired | Pass — `No issues found!`, 70/70 | 66 existing + 4 new | `AUD-021`, `AUD-022` closed |
| 2026-09-07 (c8) | Device run | — | **Not run** — no device attached | `AUD-021`'s on-device re-confirmation is still outstanding | Tracked in `STATE.md` |
| 2026-09-07 (c9) | `flutter test test/battle_playthrough_test.dart` | Local Windows, `assets/data/tools.json` beam `dmg` forced to 0 | **Fail**, behavioural — all three sweeps spent | Negative control for the first test that plays a level: with the Beams disarmed the sweeps do the killing, which is exactly what the assertion forbids | `PH-02-G3` |
| 2026-09-07 (c9) | `flutter test test/ph03_exit_gate_test.dart` | Local Windows, `ShadowDef.resistsBeam` forced to `false` | **Fail** — "fog veil" | Negative control for `T-1`: the old assertion compared `id == 'fog'` with itself and could not fail | `T-1` |
| 2026-09-07 (c9) | Idle probe, all 20 levels, no input | Local Windows | Levels 1–3 **won**, 4–20 lost | Found `AUD-023`. Throwaway harness, not committed | `AUD-023` |
| 2026-09-07 (c9) | `flutter analyze` + `flutter test` | Local Windows | Pass — `No issues found!`, 72/72 | 70 existing + 2 played-level tests | `PH-02-G3`, `T-1`, `T-2` |
| 2026-09-07 (c10) | `flutter build apk --debug`; install; cold launch; ADB tap/screenshot playthrough | SM-S711B, Android 16, serial `RZCX509DE5F` | **Fail at terminal/pause UI** — build/install/launch passed; Home → Loadout → Battle, tool placement, Glow collection, waves, and HUD worked; pause and terminal transitions froze on the last battle frame with no overlay | Cold launch 1.7s. Two screenshots 15s apart and a post-pause screenshot were byte-identical (`SHA-256 01CF05…AAB6`); activity remained foreground/awake; no Flutter exception, fatal exception, or ANR in logcat | `PH-02-G2` passed; `PH-02-G1` blocked; found `AUD-024` |
| 2026-09-07 (c14) | Git-drift review of the uncommitted c13 tree; `flutter analyze`; `flutter test`; codegraph re-index | Local Windows, `main` @ `82ed6ab` + dirty tree | Pass on the machine checks — `No issues found!`, 72/72, index 86 files / 1,416 nodes / 3,339 edges | Six c13 documentation claims did not survive review: `PRD-FR-021`/`022` demoted `Tested`→`Built`, four `PH-04` gate boxes reverted, `AUD-018` reopened as code-fixed-but-unverified. Three new findings: `AUD-025` (3.5 MB unreferenced images bundled), `AUD-026` (invalid Xcode boolean, fixed), `AUD-027` (BGM has no call site) | `PH-04` gate corrected to 2/5; `AUD-018` reopened |
| 2026-09-07 (c11) | Two force-stop/cold-start retries: active-wave Pause, then idle level-1 terminal transition | SM-S711B, Android 16 | **Same failure twice** — Pause produced no overlay and stopped frame changes; idle level 1 reached its terminal transition but produced no Win overlay | Pause screenshots after 2s/12s were byte-identical (`SHA-256 303DE6…90A3F`). Terminal screenshots at 110s/120s were byte-identical (`SHA-256 051B34…01C0A`). Activity stayed top-resumed, phone awake, device connected, logcat clean | Confirms `AUD-024` is deterministic and survives app restart |
| 2026-09-04 (c6) | `flutter test` | Local Windows, `HEAD` `9cc0c49` | Pass — 42/42 (+7 `PH-01` gate tests) | Re-run by the lead; diff verified test-only (1 file, +285 lines, zero production change) | `PH-01` gate 6/7, gate 3 partial |
| 2026-09-03 | `flutter --version` | Local Windows | Pass — 3.47.0 stable | Briefed baseline, not re-run this pass | None |
| 2026-09-03 | `flutter pub get` | Local Windows, rewritten `pubspec.yaml` | Pass — resolved `flame 1.38.2`, `flame_audio 2.12.2`, `flame_riverpod 5.4.21`, `flutter_riverpod 2.6.1`, `go_router 16.3.0`, `hive_ce_flutter 2.3.4`, `google_mobile_ads 6.0.0`, `in_app_purchase 3.3.0` (per brief) | Briefed baseline, not re-run this pass | None |
| 2026-09-03T11:04Z | `flutter analyze` | Local Windows, current `lib/` (partial, uncommitted code) | Fail — 1 error, 1 warning, 1 info (see §8) | Run live during this audit, ~15s | `AUD-008` |
| 2026-09-03 | `find test -type f` | Repo root | 0 files | `test/` directory exists but is empty | `AUD-007` |
| 2026-09-03 | `flutter test` | — | Not run | No test files exist to run | `AUD-007` |
| 2026-09-03 | `flutter build apk` / `flutter build appbundle` | — | Not run | Far too early — no `main.dart` exists | N/A, tracked at `PH-06` |

## 13. Documentation and traceability drift

| Drift | Authority | Current reality | Corrective action | Task/finding |
| --- | --- | --- | --- | --- |
| Audit brief said "no game code exists yet"; repository contains 12 partial `lib/` files and full level/tool/shadow JSON content, all uncommitted | This audit's own brief vs `git status`/`find` evidence | See `AUD-008` | Reconcile `docs/implementation_plan.md` task statuses at the next working session against actual file contents (do not mark `Done` from file presence alone — acceptance criteria are still unmet) | `AUD-008` |
| `pubspec.yaml` inline comments reference `ADR-001`..`ADR-005` | `docs/architecture.md` | `architecture.md` is still a Draft template with no accepted ADR content | Author `docs/architecture.md` and formalize `ADR-001`..`ADR-005` to match what `pubspec.yaml` already assumes | `AUD-001`, `AUD-003` |
| None of the repurposing work (governance kit + code + assets + deletions) is committed | `docs/GOVERNANCE.md` change-propagation protocol implies durable, committed state | `git status` shows 94 changed/untracked paths, zero of which are staged or committed since `4b4c974` | Commit the governance kit and the current `lib/`/`assets/` state as a checkpoint before any further code work, so a `git reset --hard` cannot destroy it | `AUD-009` |

Required checks:

- Every active task links to a valid source ID — met in `implementation_plan.md` (plausible ids pending PRD/architecture/rules/design authorship, explicitly flagged there).
- Every MVP requirement is assigned to a phase/task/test — met for `PH-00`-`PH-02`'s in-scope requirements; coarse for `PH-03`-`PH-06`.
- No duplicate/conflicting truths exist across docs — checked, none found this pass.
- `memory.md` matches actual task/finding state — see `docs/memory.md`, written to match this audit.
- Deprecated IDs link to replacements — N/A, no IDs deprecated yet.
- Required placeholders do not remain in the active scope — `phases.md`, `implementation_plan.md`, `audit.md`, `memory.md` placeholders resolved this pass; `prd.md`, `architecture.md`, `rules.md`, `design.md` still carry `[REQUIRED: ...]` placeholders (tracked, not this audit's scope to fill).

## 14. Finding template and register

### `AUD-001` — `hive_flutter` (spec-pinned) replaced with `hive_ce_flutter` (maintained fork)

- **Status:** Accepted risk
- **Severity:** Low
- **Detected:** 2026-09-03, baseline audit
- **Source breached:** Spec §21 (`hive_flutter: ^1.1`)
- **Affected users/data/components:** Persistence layer (`lib/core/save_store.dart`, future `lib/core/hive.dart`).
- **Evidence:** `pubspec.yaml` lines 22-24: `hive_ce: ^2.11.0`, `hive_ce_flutter: ^2.3.0`, comment `# Offline persistence (ADR-004)`.
- **Reproduction:** 1. Open `pubspec.yaml`. 2. Compare dependency name against spec §21. 3. `hive_flutter`/`hive` is absent; `hive_ce`/`hive_ce_flutter` present instead.
- **Expected:** Spec §21 names `hive_flutter: ^1.1`.
- **Impact:** `hive` and `hive_flutter` are publicly discontinued (no longer maintained by the original author); using them would be a supply-chain risk. `hive_ce_flutter` is the community-maintained fork with an equivalent API.
- **Likely cause:** Deliberate substitution during `PH-07` pubspec rewrite.
- **Remediation task:** None required in code; formalize as `ADR-004` in `docs/architecture.md` when authored.
- **Owner/due:** Solo developer, when `architecture.md` is next authored.
- **Workaround:** N/A — current dependency is the correct choice.
- **Retest evidence:** N/A — accepted as-is.
- **Closure/acceptance owner:** Solo developer, 2026-09-03.

### `AUD-002` — GoogleFonts runtime-fetch mandate conflicts with offline-first product; no bundled-font replacement exists yet

- **Status:** Open
- **Severity:** Medium
- **Detected:** 2026-09-03, baseline audit
- **Source breached:** Spec §10.2 (Orbitron/Inter/JetBrainsMono via `google_fonts`), spec §26 code snippet uses `GoogleFonts.orbitron()`.
- **Affected users/data/components:** All text rendering (`lib/core/theme.dart`, not yet created; `lib/core/tokens.dart` exists, 208 lines, not reviewed for font references in this pass).
- **Evidence:** `pubspec.yaml` correctly does **not** list `google_fonts` as a dependency (offline-first requires no runtime font download); no `assets/fonts/` directory exists; no `fonts:` section exists in `pubspec.yaml`.
- **Reproduction:** 1. `grep google_fonts pubspec.yaml` → no match. 2. `ls assets/fonts` → does not exist. 3. `grep "fonts:" pubspec.yaml` → no match.
- **Expected:** Spec §10.2 requires Orbitron/Inter/JetBrainsMono; product must be offline-first per project directive, which forbids `GoogleFonts.orbitron()`-style runtime network fetch.
- **Impact:** Currently no typography solution exists at all — every `TextComponent`/`TextPaint` will fall back to a system default font until this is resolved, which is a visible art-direction failure per spec §4/§10.
- **Likely cause:** Correctly identified as a conflict during `PH-07` planning, but not yet resolved with a bundled-font alternative (licensing/sourcing not done).
- **Remediation task:** `TASK-011`
- **Owner/due:** Solo developer, before `PH-00` exit gate.
- **Workaround:** None safe — ship with system default font only as a last resort, and record that as a new accepted-risk finding if `TASK-011` cannot close in time.
- **Retest evidence:** Pending.
- **Closure/acceptance owner:** Pending.

### `AUD-003` — Spec-pinned dependency majors incompatible with Dart 3.11; current majors resolved instead

- **Status:** Accepted risk
- **Severity:** Low
- **Detected:** 2026-09-03, baseline audit
- **Source breached:** Spec §21 (`flame: ^1.18`, `go_router: ^12`, `google_fonts: ^6.1`, etc.)
- **Affected users/data/components:** Every `lib/` file that imports Flame/go_router APIs — spec code snippets (e.g. §26, §14) may not compile verbatim against the resolved current majors.
- **Evidence:** `pubspec.yaml` pins `flame: ^1.34.0`, `go_router: ^16.0.0` (resolved to `flame 1.38.2`, `go_router 16.3.0` per `flutter pub get`); `environment.sdk: '>=3.11.1 <4.0.0'`.
- **Reproduction:** Compare `pubspec.yaml` versions against spec §21 table.
- **Expected:** Spec §21's pinned versions.
- **Impact:** Spec code snippets must be treated as illustrative, not copy-paste-correct, against the actually resolved API surface. Already noted in `docs/implementation_plan.md` §8 dependency plan.
- **Likely cause:** Spec was authored before current Flame/go_router majors existed; project correctly resolved against current Dart SDK instead of blindly pinning the spec's versions.
- **Remediation task:** None required — resolved versions are correct; formalize as `ADR-001`/`ADR-002`/`ADR-003`/`ADR-005` when `architecture.md` is authored.
- **Owner/due:** Solo developer, when `architecture.md` is next authored.
- **Workaround:** N/A.
- **Retest evidence:** N/A — accepted as-is.
- **Closure/acceptance owner:** Solo developer, 2026-09-03.

### `AUD-004` — Spec §21 shows `assets/` nested inside `lib/`; correctly implemented at repo root instead

- **Status:** Closed
- **Severity:** Info
- **Detected:** 2026-09-03, baseline audit
- **Source breached:** Spec §21 `lib/` tree diagram shows `assets/levels/`, `assets/tools.json`, etc. nested under `lib/`.
- **Affected users/data/components:** Asset loading (`lib/data/levels_loader.dart`, not yet created).
- **Evidence:** `pubspec.yaml` `flutter.assets:` correctly lists `assets/data/`, `assets/levels/`, `assets/audio/` at repo root; `find assets -type f` confirms files exist there, not under `lib/`.
- **Reproduction:** Compare spec §21 tree against `pubspec.yaml`/`find assets`.
- **Expected:** Flutter requires assets declared relative to the project root, not inside `lib/` — the spec's own diagram is structurally wrong for Flutter.
- **Impact:** None — implementation is already correct; recorded so the divergence isn't mistaken for an unreviewed defect later.
- **Likely cause:** Spec authoring error, correctly not followed literally.
- **Remediation task:** None.
- **Owner/due:** N/A.
- **Workaround:** N/A.
- **Retest evidence:** Confirmed correct 2026-09-03.
- **Closure/acceptance owner:** Solo developer, 2026-09-03.

### `AUD-005` — Native app id / bundle id / display name still reference `plants_vs_zombie`

- **Status:** Open
- **Severity:** Medium
- **Detected:** 2026-09-03, baseline audit
- **Source breached:** Project directive (repurposing to `prism_defense`); no store listing can ship under the old identity.
- **Affected users/data/components:** `android/app/build.gradle.kts`, `android/app/src/main/AndroidManifest.xml`, `ios/Runner.xcodeproj/project.pbxproj`.
- **Evidence:** `grep namespace android/app/build.gradle.kts` → `namespace = "com.example.plants_vs_zombie"`; `applicationId = "com.example.plants_vs_zombie"`; `android:label="plants_vs_zombie"` in `AndroidManifest.xml`; `PRODUCT_BUNDLE_IDENTIFIER = com.example.plantsVsZombie` (×3 build configs) in `project.pbxproj`.
- **Reproduction:** `grep -ri "plants_vs_zombie\|plantsvszombie" android/app/build.gradle.kts ios/Runner.xcodeproj/project.pbxproj`.
- **Expected:** App id/bundle id/display name should reflect `prism_defense`/"LIGHT vs SHADOW".
- **Impact:** Blocks any store submission and is a visible identity mismatch (device home-screen label still says "plants_vs_zombie") even for internal test builds.
- **Likely cause:** Not yet addressed during `PH-07`; correctly out of scope for docs-only work.
- **Remediation task:** `TASK-012`
- **Owner/due:** Solo developer, before `PH-00` exit gate.
- **Workaround:** None needed for local dev; only blocks store-facing builds.
- **Retest evidence:** Pending.
- **Closure/acceptance owner:** Pending.

### `AUD-006` — No AdMob ad unit ids and no IAP product ids exist yet

- **Status:** Open
- **Severity:** Low (not yet blocking — monetization is `PH-05` scope)
- **Detected:** 2026-09-03, baseline audit
- **Source breached:** Spec §20 (Monetization).
- **Affected users/data/components:** Future `lib/core/ads.dart`, `lib/core/iap.dart` (not yet created).
- **Evidence:** No AdMob console references, no `remove_ads` product id, found anywhere in the repo (`grep -ri "ca-app-pub\|remove_ads" .` — not run broadly this pass since no ad/IAP code exists to search yet; absence confirmed by `PH-05` file paths in `implementation_plan.md` being unstarted).
- **Reproduction:** N/A — nothing to reproduce, this is an absence finding.
- **Expected:** Real (non-test) AdMob ad unit ids and a registered `remove_ads` IAP product id, per spec §20.
- **Impact:** Blocks `PH-05` exit gate only; no impact on `PH-00`-`PH-04` work.
- **Likely cause:** Correctly deferred — monetization is late-stage scope.
- **Remediation task:** `TASK-040`, `TASK-041`
- **Owner/due:** Solo developer, before `PH-05` exit gate.
- **Workaround:** Use Google's published test ad unit ids during development; never ship them.
- **Retest evidence:** Pending.
- **Closure/acceptance owner:** Pending.

### `AUD-007` — No automated tests exist

- **Status:** Open
- **Severity:** Medium
- **Detected:** 2026-09-03, baseline audit
- **Source breached:** `docs/GOVERNANCE.md` traceability chain (code + tests required before audit closure); every acceptance criterion in `docs/implementation_plan.md` names a `flutter test` command.
- **Affected users/data/components:** Entire project — no regression safety net exists.
- **Evidence:** `test/` directory exists (survived from the old scaffold) but contains 0 files (`find test -type f` → empty). `flutter test` was not run because there is nothing to run.
- **Reproduction:** `find test -type f`.
- **Expected:** At minimum, a widget test proving `GameWidget` boots (per `TASK-009`'s acceptance criterion).
- **Impact:** No task in `implementation_plan.md` can honestly reach `Verified` status until this is addressed — every acceptance criterion requires a test that does not yet exist.
- **Likely cause:** No feature code has reached a testable milestone yet.
- **Remediation task:** `TASK-009` (first test), then every subsequent task per `implementation_plan.md` §4.
- **Owner/due:** Solo developer, ongoing from `PH-00` onward.
- **Workaround:** None — this blocks claiming any task `Verified`.
- **Retest evidence:** Pending.
- **Closure/acceptance owner:** Pending (this finding stays open across the whole project, effectively tracked via `TASK-*` completion rather than a single close date).

### `AUD-008` — Partial, uncommitted game code and content already exist, contradicting this audit's own briefed baseline; `flutter analyze` fails

- **Status:** Closed
- **Severity:** Medium
- **Detected:** 2026-09-03T11:04Z, baseline audit
- **Source breached:** This audit's brief stated "NO game code exists yet" and "the only commands actually run so far were `flutter pub get` and `flutter --version`." Neither is accurate as of this snapshot.
- **Affected users/data/components:** `lib/core/{layout,save_store,tokens}.dart`; `lib/data/{content,models,optics,rules}.dart`; `lib/game/light_vs_shadow_game.dart`; `lib/game/components/{backdrop_layers,grid_component,shadow_component}.dart`; `lib/game/components/tools/tool_component.dart`; `assets/data/{tools,shadows}.json`; `assets/levels/1.json`..`20.json`.
- **Evidence:** `find lib assets -type f` lists the 12 `.dart` files and 22 JSON/asset files above, all shown as `??` (untracked) by `git status`. `flutter analyze`, run live during this audit, reports: `error - Undefined name 'Curves' ... lib\game\components\tools\tool_component.dart:62:18`; `warning - ... must_call_super ... lib\game\light_vs_shadow_game.dart:30:16`; `info - unnecessary_import ... lib\game\light_vs_shadow_game.dart:8:8`.
- **Reproduction:** 1. `find lib assets -type f`. 2. `git status --porcelain -- lib assets`. 3. `flutter analyze`.
- **Expected:** Either the briefed "no code yet" baseline was accurate (it was not), or this code should already be tracked in `implementation_plan.md` task statuses (it is not, since this plan was written to assume an empty `lib/`).
- **Impact:** `docs/implementation_plan.md`'s `PH-00`-`PH-02` task statuses (`Not started`) may understate actual progress on file creation, but the `flutter analyze` failure proves that progress is not yet `Verified`-quality. This is most consistent with a concurrent process (another agent or session) actively generating code in this same working tree while this audit ran — file listings changed between two `find` calls taken minutes apart during this session.
- **Likely cause:** Concurrent/parallel work on the same repository outside this docs-only agent's visibility.
- **Remediation task:** Reconcile `implementation_plan.md` `TASK-007`..`TASK-032` statuses against actual file contents at the next working session (do not mark `Done` from file presence alone); fix the `Curves` import in `tool_component.dart` (likely missing `import 'package:flutter/animation.dart';` or `package:flame/effects.dart`) as part of whichever task now owns that file.
- **Owner/due:** Solo developer, immediately (before starting new `PH-00` work, to avoid duplicating or conflicting with whatever produced these files).
- **Workaround:** None — `flutter analyze` genuinely fails right now.
- **Retest evidence:** 2026-09-03T18:40+05:30 (c2) — `flutter analyze` no longer reports the `Curves` error in `tool_component.dart:62`, and `light_vs_shadow_game.dart`'s `must_call_super`/`unnecessary_import` are the only survivors from this finding's original evidence. The repo has since grown to 49 errors overall from newer code (`home_world.dart` etc.) — tracked separately as `AUD-011`/`AUD-012`, not a reopen of this finding.
- **Closure/acceptance owner:** Solo developer, 2026-09-03 (c2) — original defect fixed, superseded by `AUD-011`/`AUD-012` for current state.

### `AUD-009` — Entire repurposing work is uncommitted; no recovery point exists if the working tree is lost

- **Status:** Closed
- **Severity:** High
- **Detected:** 2026-09-03, baseline audit
- **Source breached:** `docs/GOVERNANCE.md` change-propagation protocol assumes durable, committed state; general engineering practice against unrecoverable single-copy work.
- **Affected users/data/components:** Entire repository — governance kit (`docs/`, `AGENTS.md`, `AGENT.md`, `CLAUDE.md`, `STATE.md`, `.ai/`, `.claude/`), rewritten `pubspec.yaml`/`pubspec.lock`, all new `lib/`/`assets/data/`/`assets/levels/` content, and the deletion of the old game's `lib/`/`assets/images/`/`assets/sounds/`/`test/widget_test.dart`.
- **Affected users/data/components:** All of the above.
- **Evidence:** `git status --porcelain` returns 94 changed paths; `git log --oneline -1` shows `4b4c974 Update README.md` as the last commit, which predates every repurposing change (governance kit, pubspec rewrite, new code/assets, deletions) — none of it is staged or committed.
- **Reproduction:** 1. `git log --oneline -1` → `4b4c974`. 2. `git status --porcelain` → 94 lines, all either `?? ` (untracked new) or ` D`/` M` (unstaged delete/modify). 3. `git diff --stat` against `4b4c974` would show the old game as still "present" in the last commit.
- **Expected:** Per `docs/GOVERNANCE.md`'s change-propagation protocol, material changes should be committed alongside their documentation so the repository has a durable, recoverable state at each step.
- **Impact:** A `git checkout -- .`, `git reset --hard`, disk failure, or accidental `git clean -fd` right now would silently restore the old plants-vs-zombies game and permanently destroy the governance kit, the rewritten `pubspec.yaml`, and all new game code/assets/levels — with no commit to recover from. This is the highest-severity finding in this audit.
- **Likely cause:** No commit has been made since the repurposing began; work has proceeded directly in the working tree.
- **Remediation task:** Commit the current working tree (governance kit + `pubspec.yaml`/`pubspec.lock` + all new `lib/`/`assets/` content + the old-file deletions) as a single checkpoint before any further code work proceeds. Not assigned a `TASK-*` id in `implementation_plan.md` because it is a repository-hygiene action, not a product task — flagged here and in `docs/memory.md` as the most urgent next action instead.
- **Owner/due:** Solo developer, immediately — before the next code-writing session of any kind.
- **Workaround:** None — the exposure exists until a commit is made.
- **Retest evidence:** `git log --oneline -5` shows commits `ae7a5b6`, `5d10870`, `3f8a660` on `overnight/gnhf-prism-defense-20260903`, all after `4b4c974`; `git status --short` returns clean at c2 session start (2026-09-03T18:31+05:30).
- **Closure/acceptance owner:** Solo developer, 2026-09-03 (c1/c2) — working tree committed, no data-loss exposure remains.

### `AUD-010` — Old Plants-vs-Zombies game removed from the working tree; recoverable only via git history

- **Status:** Accepted risk
- **Severity:** Info
- **Detected:** 2026-09-03, baseline audit
- **Source breached:** N/A — intentional, directed repurposing.
- **Affected users/data/components:** `lib/Constant/`, `lib/Models/`, `lib/Screens/`, `lib/Utils/`, `lib/Widgets/`, `lib/main.dart`, `lib/routes.dart`, `assets/images/*`, `assets/sounds/*`, `test/widget_test.dart`.
- **Evidence:** `git status --porcelain -- lib assets` shows all of the above as ` D` (deleted, unstaged); `git log --oneline -- lib` shows the commits that created them (`9d740a2` through `7b8905a`) still exist in history.
- **Reproduction:** `git log --oneline -- lib`; `git show 7b8905a:lib/main.dart` would recover the old entry point.
- **Expected:** Deliberate repurposing per the project directive — this is expected, not a defect.
- **Impact:** None if `AUD-009` is remediated (commit made) before the old commit's tree is garbage-collected or the local clone is lost; compounds with `AUD-009` until then.
- **Likely cause:** Intentional deletion during `PH-07`.
- **Remediation task:** None beyond `AUD-009`'s commit action, which also protects this recovery path by making the deletion itself durable and reviewable in history.
- **Owner/due:** N/A.
- **Workaround:** N/A.
- **Retest evidence:** N/A.
- **Closure/acceptance owner:** Solo developer, 2026-09-03 (accepted as intentional).

### `AUD-011` — `lib/core/tokens.dart` builds `dart:ui.TextStyle` instead of `package:flutter/painting.dart`'s `TextStyle`, breaking every HUD/world screen that consumes `T.*`

- **Status:** Closed
- **Severity:** Medium
- **Detected:** 2026-09-03T18:45+05:30, c2 planning pass
- **Source breached:** `lib/core/tokens.dart`'s own doc comment ("Deliberately imports `dart:ui` and `package:flutter/painting.dart` only") — the file only imports `dart:ui`, so `TextStyle` in the `T` class resolves to `dart:ui.TextStyle`, which is a different, more restrictive type than the `package:flutter/painting.dart` `TextStyle` that `Text`/`DefaultTextStyle` and every world widget expect.
- **Affected users/data/components:** `lib/core/tokens.dart` (`class T`, method `_s`); consumers `lib/game/worlds/{home_world,loadout_world,map_world,settings_world,shop_world,world_widgets}.dart`.
- **Evidence:** `flutter analyze` (2026-09-03T18:45+05:30) reports 49 errors; 44 of them are `argument_type_not_assignable`, `undefined_method` (`copyWith`), `const_initialized_with_non_constant_value`, and `const_with_non_const`, all inside the six files listed above, all pointing at a `T.*` style value. `dart:ui.TextStyle` has no `copyWith` and is not const-constructible the way callers expect, which matches every error signature exactly.
- **Reproduction:** `flutter analyze` — see error list grouped by file; every group traces back to a `style: T.<name>` argument.
- **Expected:** `T`'s static fields are `package:flutter/painting.dart` `TextStyle` instances so `Text(style: T.h1)`, `T.h1.copyWith(...)`, and const contexts all type-check.
- **Impact:** Blocks the `STATE.md` goal "`flutter analyze` clean across `lib/`"; 6 of 7 world screens cannot compile.
- **Likely cause:** Copy-paste of the `TextStyle` builder without importing `package:flutter/painting.dart` (or `package:flutter/widgets.dart`), so the analyzer picked the only `TextStyle` in scope (`dart:ui`'s).
- **Remediation task:** Reconciles `TASK-008` (file is `lib/core/tokens.dart` in reality, not the planned `lib/core/theme.dart` — naming drift, no action needed beyond noting it here and in `implementation_plan.md`). c2's assignment (tokens.dart import swap only) returned `IMPLEMENTATION_BLOCKED` from Cursor (see `.ai/inbox/cursor-evidence.md`): the 1-file scope missed two consumer files that also declare their own `TextStyle` symbol. c3 re-scoped to a verified 3-file fix — `lib/core/tokens.dart` (import swap), `lib/game/worlds/world_widgets.dart` (`hide TextStyle` + painting import so its own `TextStyle?` fields agree with `T.*`), and `lib/game/components/hud/hud_paint.dart` (`HudLabel` accepts painting's `TextStyle`, converts to `dart:ui.TextStyle` via the SDK's `TextStyle.getTextStyle()` before `ParagraphBuilder.pushStyle`). Planner applied this diff locally, ran `flutter analyze`/`flutter test`, confirmed 56→34 issues with zero TextStyle-related errors remaining, then reverted (planner does not commit code) — reassigned to Cursor via `.ai/inbox/gnhf-assignment.md` (c3).
- **Owner/due:** Cursor implementer — done.
- **Workaround:** None — was blocking every affected screen from compiling.
- **Retest evidence:** 2026-09-04 (c4 planning pass) — Cursor applied the exact
  3-file diff and committed it (`8387953`, `.ai/inbox/cursor-evidence.md`).
  Planner reran `flutter analyze` on the current tree: **34 issues**, zero
  `argument_type_not_assignable`/`copyWith`/TextStyle-related errors anywhere
  in `lib/`. `flutter test` — all 34 tests green.
- **Closure/acceptance owner:** Claude planner, 2026-09-04 (c4) — confirmed
  fixed and committed.

### `AUD-013` — `const Vector2(...)` used across five world screens, but `vector_math`'s `Vector2` has no `const` constructor

- **Status:** Closed
- **Severity:** Low
- **Detected:** 2026-09-04T00:00+05:30, c3 planning pass (surfaced while verifying `AUD-011`'s fix)
- **Source breached:** N/A — pre-existing bug, not a regression from this cycle's work.
- **Affected users/data/components:** `lib/game/worlds/{home_world,loadout_world,map_world,settings_world,shop_world}.dart` — every `const Vector2(x, y)` / `static const _cardSize = Vector2(...)` in these five files.
- **Evidence:** `flutter analyze` on a clean `AUD-011`-fixed tree still reports 22 issues (11 `const_initialized_with_non_constant_value`/`const_with_non_const` pairs) at `home_world.dart:89,101,154`, `loadout_world.dart:66,94,117,244`, `map_world.dart:31,95`, `settings_world.dart:106,173`, `shop_world.dart:53,66`. `vector_math`'s `Vector2` (`vector_math/lib/src/vector_math/vector2.dart`) is backed by a `Float32List` and declares no `const` constructor at all — these were already broken before `AUD-011`'s fix touched anything; they are additive, not caused by it.
- **Reproduction:** `flutter analyze` after applying `AUD-011`'s 3-file fix — 34 total issues remain, of which these 22 are `AUD-013` and the other 12 are `AUD-012`.
- **Expected:** Each `const Vector2(...)` becomes a plain (non-const) `Vector2(...)`, and any `static const _field = Vector2(...)` becomes `static final _field = Vector2(...)`.
- **Impact:** Blocks `flutter analyze` clean in the same five files `AUD-011` targets, but is an unrelated defect class (const-constructibility, not type mismatch) — do not conflate the two fixes in one task.
- **Likely cause:** Author assumed `Vector2` supports `const` (common in hand-rolled vector types); `vector_math`'s does not.
- **Remediation task:** Landed in commit `adf7676` (c5) — locals became `final`, `map_world.dart`'s `static const _cardSize` became `static final`, and the four `const Vector2(...)` call sites in `super(...)` initializers dropped `const`. Flame's `PositionComponent` copies `size`/`position` into a `NotifyingVector2` (`flame/lib/src/components/position_component.dart:85`), so a shared non-const `Vector2` cannot be mutated through a component.
- **Owner/due:** Claude (lead), done 2026-09-04.
- **Workaround:** None needed — fixed.
- **Retest evidence:** 2026-09-04 (c5) — `flutter analyze --no-pub` dropped 31 → 6 (the 22 `AUD-013` errors plus 3 lints cleared in the same commit); `flutter test` 34/34.
- **Closure/acceptance owner:** Claude (lead), 2026-09-04 (c5).

### `AUD-012` — Remaining `flutter analyze` errors unrelated to `AUD-011`, deferred to a later planning pass

- **Status:** Closed — `right_panel_component.dart`'s import landed in `e8a179d`, the two minor lints in `adf7676`, and `lib/app.dart`/`PrismDefenseApp` in `733fb55`. `flutter analyze` is clean across `lib/`.
- **Severity:** Low
- **Detected:** 2026-09-03T18:45+05:30, c2 planning pass
- **Source breached:** N/A — pre-existing incomplete work, not a regression.
- **Affected users/data/components:** `lib/main.dart` (imports missing `lib/app.dart`, calls undefined `PrismDefenseApp`); `lib/game/components/hud/right_panel_component.dart` (`TapCallbacks`/`TapUpEvent` used without importing `package:flame/events.dart`); `lib/game/components/hud/tray_slot_component.dart` (unused `_costLabel` field, warning only); `lib/game/light_vs_shadow_game.dart` (`unnecessary_import`, `must_call_super`, both non-error).
- **Evidence:** `flutter analyze` (2026-09-03T18:45+05:30) — 3 errors at `lib\main.dart:9:8`, `32:37` (x2); 2 errors at `lib\game\components\hud\right_panel_component.dart:155:51`, `212:16`; 2 non-error diagnostics elsewhere.
- **Reproduction:** `flutter analyze` (same run as `AUD-011`).
- **Expected:** `lib/app.dart` exists and defines `PrismDefenseApp` (a `WidgetsApp` shell wiring the worlds/router — `TASK-007`'s actual remaining scope); `right_panel_component.dart` imports `package:flame/events.dart` for `TapCallbacks`/`TapUpEvent`.
- **Impact:** Blocks full `flutter analyze` clean and app boot even after `AUD-011` is fixed; out of scope for the c2 assignment, which targets only the highest-leverage single-file fix.
- **Likely cause:** `TASK-007` (app shell) not yet started; a missing import in `right_panel_component.dart`.
- **Remediation task:** c4 assigns the smallest sub-slice — the
  `right_panel_component.dart` missing-import fix (`.ai/inbox/gnhf-assignment.md`,
  reduces 34→31) — to Cursor this cycle. The `lib/app.dart`/`PrismDefenseApp`
  piece (`TASK-007`'s real remaining scope, 3 of the 12 issues) and the two
  minor lints (`tray_slot_component.dart` unused field,
  `light_vs_shadow_game.dart` `unnecessary_import`/`must_call_super`) stay
  deferred to a future cycle — kept separate because `lib/app.dart` is a real
  widget (production code, bigger surface) not a mechanical import fix.
- **Owner/due:** Cursor implementer (import fix, immediately); Claude planner
  (`lib/app.dart` + lints, future cycle).
- **Workaround:** None needed — tracked for sequencing only.
- **Retest evidence:** Pending (import fix assigned this cycle, not yet run).
- **Closure/acceptance owner:** Pending.

### Finding register

| Finding | Severity | Status | Source | Remediation | Owner/due | Retest |
| --- | --- | --- | --- | --- | --- | --- |
| `AUD-001` | Low | Accepted risk | Spec §21 | None (formalize `ADR-004` later) | Solo dev / architecture.md authoring | N/A |
| `AUD-002` | Medium | Open | Spec §10.2 | `TASK-011` | Solo dev / before `PH-00` exit | Pending |
| `AUD-003` | Low | Accepted risk | Spec §21 | None (formalize ADRs later) | Solo dev / architecture.md authoring | N/A |
| `AUD-004` | Info | Closed | Spec §21 | None | N/A | Confirmed correct |
| `AUD-005` | Medium | Open | Project directive | `TASK-012` | Solo dev / before `PH-00` exit | Pending |
| `AUD-006` | Low | Open | Spec §20 | `TASK-040`, `TASK-041` | Solo dev / before `PH-05` exit | Pending |
| `AUD-007` | Medium | Open | `docs/GOVERNANCE.md` | `TASK-009` onward | Solo dev / ongoing | Pending |
| `AUD-008` | Medium | Closed | This audit's brief vs reality | Reconcile plan + fix `Curves` import | Solo dev | Confirmed fixed (c2) |
| `AUD-009` | High | Closed | Engineering practice | Commit working tree checkpoint | Solo dev | Confirmed committed (c1/c2) |
| `AUD-010` | Info | Accepted risk | Project directive | None (covered by `AUD-009`) | Solo dev | N/A |
| `AUD-011` | Medium | Closed | `lib/core/tokens.dart` vs its own doc comment | 3-file fix, `TASK-008`, landed by Cursor (`8387953`) | Cursor — done | Confirmed: analyze 34, tests 34/34 (c4) |
| `AUD-012` | Low | Closed | Incomplete `TASK-007`; missing import | Import fix (`e8a179d`, Cursor); `lib/app.dart` shell + 2 lints (`adf7676`, `733fb55`, Claude) | Done | Confirmed: analyze clean, tests 35/35 (c5) |
| `AUD-013` | Low | Closed | `const Vector2(...)` has no const constructor in `vector_math` | Mechanical const removal across 5 world files (`adf7676`) | Done | Confirmed: analyze 31 → 6 (c5) |
| `AUD-014` | Medium | Closed | Flame `OpacityEffect` contract | `FadeableRender` mixin on the 4 hand-painted fade targets (`733fb55`) | Done | Confirmed: boot test passes (c5) |
| `AUD-017` | Medium | Closed | `PRD-FR-015`; QA #10 | Read `camera.world` (`ed0c0f9`) + regression test (`d39b6b0`) | Done | Confirmed: fails without fix, 62/62 with (c6) |
| `AUD-019` | Critical | Closed | Every interaction in the product | `IgnorePointer` around go_router's routed child (`256e995`) | Done | Confirmed on device + 3 shell tests (c7) |
| `AUD-020` | Critical | Closed | `PRD-FR-014` vs shipped level 1 | `ADR-008` — cap tray at what the level offers | Done | Confirmed on device, 66/66 (c7) |
| `AUD-021` | High | Closed | `design.md` HUD contract; spec §11 | Mount the HUD from `BattleWorld.onLoad`; clear the viewport first in `swapWorld` | Done | Confirmed: 0/4 without the fix, 4/4 with (c8) |
| `AUD-022` | Medium | Closed | Spec §24 edge case 20 | `swapWorld` reads `camera.world` and removes the outgoing world unconditionally | Done | Confirmed: fails without fix, 70/70 with (c8) |
| `AUD-023` | High | Open | `PRD-FR-009`; spec §17 | Retune `tool/gen_levels.py` so levels 1–3 spawn more waves than there are lane sweeps, then regenerate | Owner (balance) | Probe: levels 1–3 idle-win, 4–20 idle-lose (c9) |
| `AUD-024` | High | Open | `PRD-FR-010`, `PRD-FR-011`, `PRD-FR-015`; `DS-075` | Mount Pause/Win/Lose overlays before pausing the Flame engine; add a regression that does not resume the engine to flush lifecycle queues | `TASK-046` | Device reproduction on SM-S711B (c10) |
| `AUD-018` | Low | Open | Spec §23 | Code fixed (`clearAll()` dropped, preload wired); still needs one negative-controlled test or device run that observes a cue play | `PH-04` audio owner | Code correct at c13; retest evidence rejected at c14 — the cited test only stats files on disk |
| `AUD-025` | Medium | Open | `docs/rules.md` §9; `PRD-FR-022` | Drop `assets/images/` from the `pubspec.yaml` asset manifest (launcher icons are a build-time input); add a bundle-size budget row to `rules.md` §9 | `PH-04`/`PH-06` owner | 3,496,763 bytes bundled into every APK/IPA, referenced by zero Dart code (c14) |
| `AUD-026` | Medium | Closed | Xcode build settings | `flutter_launcher_icons` wrote the icon name into a boolean setting; restored `= YES` | Done | Fixed at c14; `git diff` on `project.pbxproj` is now empty |
| `AUD-027` | Medium | Open | `PRD-FR-021`; spec §23 | Call `GameAudio.startBgm()` from a real production site, or delete `startBgm`/`stopBgm` + `bgm.mp3` and strike BGM from `PRD-FR-021` | `PH-04` audio owner | Zero call sites in `lib/`; 321,350 bytes preloaded and never played (c14) |
| `AUD-016` | Medium | Closed | `architecture.md` §6 vs the tree | `ADR-007` — accept implemented design, drop `TASK-021` | Done | Confirmed: `ADR-007` recorded (c6) |
| `AUD-015` | Medium | Closed | `docs/rules.md` §8; `AGENTS.md` §6 | Add `integration_test/` covering `UJ-01` + save-restart, as part of the `PH-02` gate | Cursor / PH-02 | Closed 2026-09-04 — `integration_test/uj01_test.dart` green on Windows |

### `AUD-014` — `OpacityEffect` mounted on hand-painted components that are not `OpacityProvider`s (runtime crash)

- **Status:** Closed
- **Severity:** Medium
- **Detected:** 2026-09-04 (c5) — surfaced the first time the app was actually booted, by the new `test/app_boot_test.dart`.
- **Source breached:** Flame's effect contract — `OpacityEffect` requires an `OpacityProvider` target, which only `HasPaint` supplies for free.
- **Affected users/data/components:** `lib/game/components/beam_component.dart` (beam pulse), `lib/game/components/shadow_component.dart` (fog shimmer and the death fade-out), `lib/game/worlds/home_world.dart` (`_DioramaBulb`, `_DioramaBeam`).
- **Evidence:** `UnsupportedError: Can only apply this effect to OpacityProvider` thrown from `EffectTarget.onMount` (`flame/src/effects/effect_target.dart:21`) during `Component._mount`, on the first frame after `HomeWorld` mounts.
- **Reproduction:** `flutter test test/app_boot_test.dart` against `adf7676`.
- **Expected:** Each of those components exposes an `opacity` and dims when a fade runs.
- **Impact:** Every affected component threw on mount — the home screen diorama, every beam and every shadow death. Invisible to `flutter analyze` (the contract is enforced at runtime, not by the type system), which is why an analyzer-clean tree still could not boot.
- **Likely cause:** These components draw with several ad-hoc `Paint`s rather than one `HasPaint` paint, so they never picked up the `OpacityProvider` implementation their effects assumed.
- **Remediation task:** `lib/game/components/fadeable.dart` — a `FadeableRender` mixin fading the subtree in one layer; applied to all four (`733fb55`).
- **Owner/due:** Claude (lead), done 2026-09-04.
- **Workaround:** None needed — fixed.
- **Retest evidence:** 2026-09-04 (c5) — `flutter test` 35/35 including the boot test; `flutter analyze` clean.
- **Closure/acceptance owner:** Claude (lead), 2026-09-04 (c5).

### `AUD-015` — No `integration_test/` suite exists, so `AGENTS.md` §6's integration gate cannot run

- **Status:** Closed
- **Severity:** Medium
- **Detected:** 2026-09-04 (c6)
- **Remediation:** `integration_test/uj01_test.dart` covers battle-win → WinOverlay + Hive save persistence (`UJ-01` completion signal). Runnable via `flutter test integration_test -d windows`.
- **Retest evidence:** 1/1 green on Windows desktop, 2026-09-04 (Cursor PH-02).
- **Closure/acceptance owner:** Cursor PH-02 commit.

### `AUD-016` — Specified Riverpod `BattleNotifier` state layer was never built; code and `architecture.md` disagreed silently

- **Status:** Closed — resolved by `ADR-007` in favour of the implemented design.
- **Severity:** Medium
- **Detected:** 2026-09-04 (c6), while scoping the `PH-01` gate against the tree.
- **Source breached:** `docs/architecture.md` §6 and the module-boundary table; `Spec §13` "State bridge to Riverpod".
- **Affected users/data/components:** `lib/state/` (absent entirely), every `lib/game/components/hud/*` component, `BattleWorld`.
- **Evidence:** `find lib -name "*.dart"` lists no `lib/state/` path. `grep -rn "RiverpodComponentMixin|ref\." lib` returns nothing. `architecture.md:131,154-155,172-178` specify `BattleNotifier extends Notifier<BattleState>` and the rule "HUD reads `BattleNotifier` for display values, never simulation objects", while `TopBarComponent.glow` is in fact assigned directly by `BattleWorld` and diffed in `update()`.
- **Reproduction:** `grep -rn "RiverpodComponentMixin" lib` at `9cc0c49` — no matches.
- **Expected:** One design, documented. Either the notifier exists, or the document says it does not.
- **Impact:** A whole specified module missing is the `AUD-008` failure mode repeating — an agent trusting `architecture.md` would have built a parallel state layer beside a working one, or "fixed" working code to match a document nobody had reconciled. It also made `TASK-021` unstartable without an architecture decision, which is why it was fenced out of the `PH-01` Cursor assignment rather than guessed at.
- **Likely cause:** `architecture.md` was authored from the spec in one pass at `PH-07`, before any gameplay code existed; the code then took a simpler path and no one reconciled the two.
- **Remediation task:** `ADR-007` — accept the implemented design, strike the `lib/state` module row, re-point the HUD row, drop `TASK-021`.
- **Owner/due:** Repo owner (decision, 2026-09-04); Claude (lead, drafting).
- **Workaround:** N/A.
- **Retest evidence:** 2026-09-04 (c6) — `ADR-007` recorded; `architecture.md` module table amended; `TASK-021` dropped from the plan. `flutter analyze` clean, `flutter test` 42/42 at `9cc0c49`.
- **Closure/acceptance owner:** Repo owner, 2026-09-04 (c6).

### `AUD-017` — App-lifecycle handler read `game.world`, which is never the swapped-in world (QA #10 half dead)

- **Status:** Closed — fixed `ed0c0f9`, regression test `d39b6b0`.
- **Severity:** Medium
- **Detected:** 2026-09-04 (c6), lead review of the `PH-02` delivery.
- **Source breached:** `docs/prd.md` `PRD-FR-015` (app lifecycle); spec §24 QA checklist #10.
- **Affected users/data/components:** `lib/app.dart` `didChangeAppLifecycleState`, and through it every battle that gets backgrounded.
- **Evidence:** `FlameGame.world` and `camera.world` are different objects; `swapWorld()` sets the camera's while `FlameGame.world` keeps the default `World` for the life of the game. Proven with a probe on a real game instance: `game.world = World` (`is _Marker` → **false**) versus `game.camera.world = _Marker` (`is _Marker` → **true**). The shipped code read `_game.world`, so `if (world is BattleWorld)` was false in every case — `BattleWorld.pause()` never ran on backgrounding, and the "stay paused behind the overlay" guard never ran on resume.
- **Reproduction:** At `f7d52fd`, background the app during a battle: the engine pauses but the battle's own state never becomes `GameState.paused`.
- **Expected:** Backgrounding pauses the engine **and** the battle simulation; resuming does not silently un-pause a battle the player paused deliberately.
- **Impact:** Half of QA #10 was inoperative. Worse, it was **invisible to the delivered test**, which asserts only `game.paused` — satisfied by `pauseEngine()` whether or not the `BattleWorld` branch is reachable — and which ran on `/home`, where no `BattleWorld` exists at all. A green suite is not evidence that a branch is reachable.
- **Likely cause:** The `game.world` / `camera.world` distinction is genuinely counter-intuitive. It is documented in `AGENTS.md` §6 and `STATE.md` COST NOTES and the worker was told about it in its assignment, and it was still hit — the warning is too far from the code it protects.
- **Remediation task:** `ed0c0f9` reads `_game.camera.world` in both branches, with a comment at the site saying why. `d39b6b0` adds a regression test that pumps `PrismDefenseApp` (which owns the observer), swaps in a real `BattleWorld`, asserts it is not already paused, then asserts it pauses.
- **Owner/due:** Claude (lead) — done 2026-09-04.
- **Workaround:** N/A.
- **Retest evidence:** Verified both directions: reverting `camera.world` → `world` fails the new test and only that test; restoring it passes. `flutter analyze` clean, `flutter test` 62/62 at `d39b6b0`.
- **Closure/acceptance owner:** Claude (lead), 2026-09-04 (c6).

### `AUD-018` — `GameAudio.setSoundEnabled` clears the audio cache instead of only setting volume

- **Status:** Open — code fixed 2026-09-07 (c13), verification rejected 2026-09-07 (c14).
- **Severity:** Low
- **Detected:** 2026-09-04 (c6), lead review of the `PH-04` delivery.
- **Source breached:** Spec §23 (audio); `docs/rules.md` §9 performance budgets.
- **Affected users/data/components:** `lib/core/audio.dart` `setSoundEnabled`.
- **Evidence:** The method called `await FlameAudio.audioCache.clearAll()` before setting BGM volume. Clearing the cache discarded every preloaded clip.
- **Reproduction:** Resolved.
- **Expected:** Toggling sound sets volume (or gates playback) and leaves the preloaded cache intact.
- **Impact:** Fixed; no audio cache discard on toggle.
- **Likely cause:** Written against an empty `assets/audio/`, so the line could never be observed to misbehave.
- **Remediation task:** Dropped `clearAll()` call in `setSoundEnabled`, preloaded all 8 SFX + BGM in `init()`, and generated 9 audio files under `assets/audio/`.
- **Owner/due:** GameAudioEngineer (closed 2026-09-07).
- **Workaround:** N/A.
- **Retest evidence:** **Insufficient.** The cited test (`test/ph04_exit_gate_test.dart:176`) calls `existsSync()`/`lengthSync()` on nine files. It never calls `GameAudio.init()`, never asserts `_ready`, and never toggles sound — so it cannot fail if this finding regresses. `setSoundEnabled` returns at `lib/core/audio.dart:70` (`if (!_ready) return;`) before reaching the changed lines, and `_ready` is false in every `flutter test` host because there is no audio plugin. The fix is correct by inspection; nothing observes it. Per § "Evidence is required", this does not close.
- **To close:** either a test that forces `_ready = true` (the `debugSetReady` seam at `audio.dart:112` exists and is unused) and asserts the cache survives a toggle, or a device run that toggles sound off/on mid-battle and hears the next cue with no stall.
- **Closure/acceptance owner:** Pending.

### `AUD-025` — 3.5 MB of unreferenced images are bundled into every build

- **Status:** Open.
- **Severity:** Medium
- **Detected:** 2026-09-07 (c14), git-drift review of the uncommitted c13 tree.
- **Source breached:** `docs/rules.md` §9 (performance budgets); `PRD-FR-022`, which itself states "in-game canvas rendering continues to be hand-drawn vector code".
- **Affected users/data/components:** `pubspec.yaml` asset manifest; APK/IPA size on every device.
- **Evidence:** `pubspec.yaml` declares `- assets/images/`, bundling `banner.jpg` (790,082), `battlefield.jpg` (849,279), `icon.jpg` (613,981) and `icon.png` (1,243,421) — **3,496,763 bytes**. `grep -rn "assets/images\|banner\|battlefield\|icon.png" lib/ test/` returns exactly one hit, `lib/game/worlds/shop_world.dart:163`, which is the unrelated ad-copy string `'No banners, no interstitials.'`. No Dart code loads any of these files. `icon.png` is the `flutter_launcher_icons` source — a build-time input that native mipmaps are generated from, and that needs no runtime bundling at all. `icon.jpg` is redundant with `icon.png`.
- **Reproduction:** `flutter build apk --debug`, then inspect the bundled asset manifest; all four files are present and unreachable.
- **Expected:** The runtime asset manifest carries only what code loads. Store/branding art lives outside the bundle.
- **Impact:** ~3.5 MB of dead download and install weight — roughly 9x the entire 500KB audio budget `PRD-FR-021` was carefully written around.
- **Likely cause:** `- assets/images/` was added alongside `flutter_launcher_icons` in the same edit, conflating a build-time icon source with runtime assets.
- **Remediation task:** Remove `- assets/images/` from `pubspec.yaml`; keep `icon.png` on disk as the launcher-icon source. Add a bundle-size row to `docs/rules.md` §9 so this class of regression has a threshold to violate — §9 currently defines none, despite `rules.md:294` telling readers to "manually measure the bundle-size trend referenced in §9".
- **Owner/due:** `PH-04`/`PH-06` owner. Also record the source/licence/size metadata `rules.md:268` requires for generated binary assets — none was recorded for any of the 13 new binaries.
- **Workaround:** None needed pre-release; it is size, not behaviour.
- **Retest evidence:** Pending.

### `AUD-026` — `flutter_launcher_icons` wrote an icon name into a boolean Xcode setting

- **Status:** Closed — fixed 2026-09-07 (c14).
- **Severity:** Medium
- **Detected:** 2026-09-07 (c14), git-drift review.
- **Source breached:** Xcode build-setting types.
- **Affected users/data/components:** `ios/Runner.xcodeproj/project.pbxproj` lines 445 and 503.
- **Evidence:** The tool rewrote `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;` to `= AppIcon;` on two build configurations. That setting is a boolean (`YES`/`NO`); the icon name belongs in `ASSETCATALOG_COMPILER_APPICON_NAME`, which was already correctly set to `AppIcon` at lines 377, 558 and 580. Line 324 was left untouched, so the three configurations disagreed with each other.
- **Reproduction:** Was `grep -n ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS ios/Runner.xcodeproj/project.pbxproj` before the fix.
- **Expected:** The boolean stays `YES` on every configuration.
- **Impact:** Would have surfaced as an asset-catalog compile failure or silently disabled Swift asset symbol generation at the first iOS build. No iOS build was run in c13, so it went unnoticed.
- **Likely cause:** A `flutter_launcher_icons` 0.14.4 bug writing to the wrong key.
- **Remediation task:** Restored `= YES;` on both lines; `git diff -- ios/Runner.xcodeproj/project.pbxproj` is now empty.
- **Owner/due:** Done, c14.
- **Retest evidence:** Diff is empty. A real iOS build has still never been run on this project — that remains a `PH-06` gap, not this finding's.

### `AUD-027` — the bundled BGM track has no production call site and can never play

- **Status:** Open.
- **Severity:** Medium
- **Detected:** 2026-09-07 (c14), git-drift review.
- **Source breached:** `PRD-FR-021`; spec §23.
- **Affected users/data/components:** `lib/core/audio.dart:77` (`startBgm`), `:85` (`stopBgm`), `assets/audio/bgm.mp3`.
- **Evidence:** `grep -rn "startBgm\|stopBgm" lib/ test/ integration_test/` returns only the two declarations. Nothing in `main.dart`, `app.dart`, any world, or the lifecycle handler at `app.dart:54-69` starts music. `bgm.mp3` (321,350 bytes — 86% of the audio payload) is nevertheless eagerly loaded into the SFX cache by `init()`. As a knock-on, `setSoundEnabled`'s `FlameAudio.bgm.audioPlayer.setVolume(...)` at `audio.dart:72` operates on a player that never plays.
- **Reproduction:** Launch the game and listen. There is no ambient track on any screen.
- **Expected:** Either music plays, or the product does not claim it.
- **Impact:** `PRD-FR-021` is a `Must` whose music half is undeliverable as built. Same bug class as `AUD-021`: a written, styled, compiling component that no production caller reaches.
- **Likely cause:** `startBgm`/`stopBgm` were written in the same session that authored `PRD-FR-021`, and the requirement was written to describe the code rather than the code to satisfy a requirement.
- **Remediation task:** Either call `startBgm()` from `BattleWorld.onLoad` / `HomeWorld.onLoad` and `stopBgm()` from the lifecycle handler, **or** delete both methods, drop `bgm.mp3` and `Sfx.bgm`, and strike the ambient-music clause from `PRD-FR-021`. The second is the smaller change and the honest one if music was never a real requirement — this is an owner call.
- **Owner/due:** `PH-04` audio owner.
- **Workaround:** N/A.
- **Retest evidence:** Pending.

### `AUD-019` — go_router's routed `Navigator` sat over the `GameWidget` and swallowed every tap; the whole game was untappable

- **Status:** Closed — fixed `256e995`.
- **Severity:** Critical
- **Detected:** 2026-09-04 (c7), by installing the game on a physical device and tapping PLAY.
- **Source breached:** `PRD-FR-001`, `PRD-FR-014`, `UJ-01` — every interaction in the product.
- **Affected users/data/components:** `lib/app.dart`'s `ShellRoute` builder; through it, every world and every button in the game.
- **Evidence:** The shell composed `Stack(children: [RiverpodAwareGameWidget(...), child])`. go_router supplies a **full-size `Navigator`** as that `child`, which is opaque to hit-testing and is painted above the game. On device, tapping PLAY produced no navigation, no exception and no log line. Reproduced in a widget test at 2340x1080: tapping the PLAY button's exact screen position left `camera.world` as `HomeWorld`.
- **Reproduction:** At `f545e79`, `flutter run` on any device and tap anything. Or run `test/app_navigation_test.dart` with the `IgnorePointer` removed — all three cases fail.
- **Expected:** Taps reach the Flame components; the route bodies are zero-size side-effects and must never take input.
- **Impact:** **The product was completely unusable while appearing perfect.** It rendered correctly on desktop and device, booted clean, and passed 62 tests. Not one of those tests could see it: they all drive worlds through a bare `GameWidget`, which has no routed Navigator above it. This is the strongest evidence yet in this project that a green suite plus a screenshot is not evidence of a working product.
- **Likely cause:** Introduced with the app shell in `733fb55` (mine). `ShellRoute`'s `child` is easy to read as "the page content" rather than "a full-size Navigator".
- **Remediation task:** `IgnorePointer` around the routed child (`256e995`), with a comment at the site.
- **Owner/due:** Claude (lead) — done 2026-09-04.
- **Workaround:** None — nothing worked.
- **Retest evidence:** `test/app_navigation_test.dart` taps through the real shell at 812x375 and 2340x1080; verified both directions. Confirmed on the SM-S711B: PLAY now reaches the Loadout. `flutter analyze` clean, `flutter test` 66/66.
- **Closure/acceptance owner:** Claude (lead), 2026-09-04 (c7).

### `AUD-020` — Loadout demanded 6 tools while level 1 offers 3; no level was startable

- **Status:** Closed — fixed `ADR-008`.
- **Severity:** Critical
- **Detected:** 2026-09-04 (c7), immediately after `AUD-019` made the Loadout reachable for the first time.
- **Source breached:** `PRD-FR-014` acceptance criteria vs `assets/levels/1.json`.
- **Affected users/data/components:** `lib/game/worlds/loadout_world.dart`; every player, every level.
- **Evidence:** `kTrayLimit = 6` (`models.dart:12`); `assets/levels/1.json` `availableTools = ['bulb','beam','wall']`; `SaveStore`'s default `unlocked = {bulb, beam, wall}`; the gate is `_startButton.enabled = _selected.length == _trayLimit`. Three selectable, six required.
- **Reproduction:** Fresh install, tap PLAY, select all three tools — Start Battle stays disabled.
- **Expected:** A fresh save can start level 1.
- **Impact:** The game could not be played at all. It is the second critical defect in one session that a passing gate test did not catch: `PH-03`'s criterion verifies that fewer/more than six is **blocked**, which was true throughout — nobody asserted the required count was **reachable**. A guard test without a reachability test is half a test.
- **Likely cause:** `PRD-FR-014`'s "exactly 6" was written for the late game; the generated early-game content was never reconciled against it.
- **Remediation task:** `ADR-008` — `min(kTrayLimit + bonus, eligible.length)`.
- **Owner/due:** Repo owner (decision), Claude (lead) — done 2026-09-04.
- **Workaround:** None.
- **Retest evidence:** `test/app_navigation_test.dart` drives a fresh save through PLAY, selects every offered tool and asserts Start Battle enables. 66/66. Confirmed on device: the battle grid now loads.
- **Closure/acceptance owner:** Repo owner, 2026-09-04 (c7).

### `AUD-021` — The battle HUD was never wired to `BattleWorld`; every battle had no HUD at all

- **Status:** Closed — fixed 2026-09-07 (c8).
- **Severity:** High
- **Detected:** 2026-09-04 (c7), on the SM-S711B, immediately after `AUD-020` made a battle reachable for the first time. Root-caused 2026-09-07 (c8).
- **Source breached:** `docs/design.md` `DS-*` HUD contract; spec §11.
- **Affected users/data/components:** `lib/game/worlds/battle_world.dart`; `TopBarComponent`, `RightPanelComponent`, `TraySlotComponent`, `ToastComponent`.
- **Evidence:** Device screenshot after Start Battle showed the 21-tile grid and the lane sweep arrows rendering correctly, with **no** top bar, glow chip, wave counter, pause button, right panel or tool tray. Static confirmation across `lib/`: `TopBarComponent`, `RightPanelComponent` and `ToastComponent` had **zero constructor call sites**; `TraySlotComponent`'s only call site was inside `RightPanelComponent`, which was itself never built; `BattleWorld`'s `onGlowChanged`/`onWaveChanged`/`onToast` hooks (`battle_world.dart:86-88`) were **never assigned**, so `onLoad` invoked them into null; the only component ever added to `camera.viewport` was a win/lose/pause overlay (`battle_world.dart:613`).
- **Reproduction:** On device at `256e995`: PLAY → select the three tools → Start Battle. Grid appears, HUD does not. In-suite: `flutter test test/battle_hud_test.dart` against `3bc5171` — 0 of 4 pass.
- **Expected:** The HUD mounts on `camera.viewport` with the battle and is driven by the simulation.
- **Impact:** A battle could not be played — no glow readout and no tray to place tools from. Third critical-path defect in two sessions that the suite could not see.
- **Actual cause:** The HUD was written, styled and unit-tested but **never connected to production code**. The cause recorded in c7 — a race between `swapWorld`'s `camera.viewport.removeAll` and an async HUD `onLoad` — was **wrong**: there was no HUD add to race against. That mis-diagnosis was carried in `STATE.md`'s NEXT ACTION and would have sent the next session hunting a timing bug that did not exist. Recorded here because a confident wrong root cause is more expensive than an open unknown.
- **Remediation task:** `BattleWorld._mountHud()` builds the TopBar and RightPanel and adds them to `camera.viewport`; `_syncHud()` pushes glow, wave, tray selection, affordability and cooldown into them once per frame, one direction only. `swapWorld` now clears the viewport **first**, so the ordering hazard that was mistaken for the cause cannot arise either. Rejected toasts now also render at the tapped tile via `showToast`.
- **Owner/due:** Claude (lead), done 2026-09-07.
- **Workaround:** None.
- **Retest evidence:** `test/battle_hud_test.dart` drives the real shell Home → Loadout → Battle and asserts on `camera.viewport`, not on any test-only getter — so the file compiles against the pre-fix tree and fails behaviourally: **0/4 before the fix, 4/4 after**. Full suite 70/70, `flutter analyze` clean. **Not yet re-confirmed on a device** — no device was attached in c8.
- **Closure/acceptance owner:** Claude (lead), 2026-09-07 (c8).

### `AUD-022` — `swapWorld` read `FlameGame.world`, so outgoing worlds were never removed and accumulated

- **Status:** Closed — fixed 2026-09-07 (c8).
- **Severity:** Medium
- **Detected:** 2026-09-07 (c8), while fixing `AUD-021`. Suspected in c7 and recorded then as a possible cause of `AUD-021`; it is a separate defect.
- **Source breached:** Spec §24 edge case 20 — a replaced screen's particle generators must stop ticking.
- **Affected users/data/components:** `lib/game/light_vs_shadow_game.dart`; every navigation in the game.
- **Evidence:** `swapWorld` opened with `final previous = world`. `FlameGame.world` is a separate reference from `camera.world`, and the method only ever assigns `camera.world` — so `world` stayed the default `World` for the life of the game. From the second navigation onward `previous.isMounted` was false, `removeFromParent()` was skipped, and the world the player had just left stayed mounted and updating. The same `isMounted` guard also leaked FlameGame's own default `World`, which is still only queued at the first swap.
- **Reproduction:** `flutter test test/battle_hud_test.dart` against `3bc5171` — navigating Home ⇄ Map three times leaves 2+ worlds mounted.
- **Expected:** Exactly one world is mounted at any time.
- **Impact:** Dead worlds kept ticking behind the live one: wasted frame budget against the 60fps `PRD-NFR` target, and a latent correctness hazard wherever a stale world holds timers. Same root confusion as the closed `AUD-017`, which is why `lib/app.dart:57-60` already carried a comment about it.
- **Remediation task:** Read `camera.world`; drop the `isMounted` guard (`removeFromParent` is a no-op without a parent and handles a pending child correctly); early-return when the incoming world is already active.
- **Owner/due:** Claude (lead), done 2026-09-07.
- **Workaround:** None.
- **Retest evidence:** `test/battle_hud_test.dart` — "navigating repeatedly leaves exactly one world mounted". 70/70.
- **Closure/acceptance owner:** Claude (lead), 2026-09-07 (c8).

### `AUD-023` — Levels 1–3 are won by doing nothing; their fail state is unreachable

- **Status:** Open — found 2026-09-07 (c9).
- **Severity:** High — the first three levels a new player meets play themselves.
- **Detected:** 2026-09-07 (c9), by the first test that actually plays a level (`PH-02-G3`).
- **Source breached:** `PRD-FR-009` (a level is won or lost by play); spec §24 edge case 12.
- **Affected users/data/components:** `assets/levels/{1,2,3}.json`, generated by `tool/gen_levels.py`. Not a code defect — `_tickSweep` matches spec §17 exactly.
- **Evidence:** An instrumented idle run of all 20 levels (no tools placed, no taps) reaches:

  | Levels | Waves | Idle outcome |
  | --- | --- | --- |
  | 1, 2, 3 | 3 | **won**, t≈100s |
  | 4–20 | 4–8 | lost, t≈100–122s |

  The mechanism: a sweep kills *every* shadow in its lane wherever that shadow stands (spec §17, "Kills all shadows in that lane"), and the board has one sweep per lane for three lanes. A level with three waves therefore has at most three lane-arrivals to absorb, and the three free sweeps absorb all of them. Wave gating makes it worse: `canSpawnNextWave`'s 20s timeout bunches waves 2 and 3 close enough that a single lane-0 sweep at t≈54s deletes shadows from all three waves at once.
- **Reproduction:** Enter level 1 and place nothing. The battle resolves as a win at roughly t=100s.
- **Expected:** A player who places nothing loses. Winning must require play.
- **Impact:** The first-run experience is a game that wins itself, and the tutorial teaches nothing. It also means "level 1 was won" is worthless as evidence that the play loop works — which is why `test/battle_playthrough_test.dart` asserts on unspent sweeps rather than on the win alone.
- **Remediation task:** Retune `tool/gen_levels.py` so the early levels spawn more lane-arrivals than there are sweeps (more waves, or waves spread across lanes so one sweep cannot cover them), then regenerate. **Never hand-edit `assets/levels/*.json`.** Balance is an owner decision — see `docs/prd-story.md` §5 step 5 (`B-2`).
- **Owner/due:** Repo owner (balance call), before `PH-06`.
- **Workaround:** None.
- **Retest evidence:** Pending. The retest is the idle probe above, re-run after regeneration: levels 1–3 must read `lost`.
- **Closure/acceptance owner:** Pending.

### `AUD-024` — Pause and terminal overlays never mount on device; battle freezes on its last rendered frame

- **Status:** Open — found 2026-09-07 (c10).
- **Severity:** High — every pause, win, and loss transition strands the player on a frozen, non-interactive battle frame.
- **Detected:** 2026-09-07 (c10), during the first full on-device run after the c8 HUD fix.
- **Source breached:** `PRD-FR-010`, `PRD-FR-011`, `PRD-FR-015`; `DS-075`; `SCR-05`, `SCR-06`, `SCR-07`.
- **Affected users/data/components:** `BattleWorld.pause`, `BattleWorld._finishWon`, `BattleWorld._finishLost`; Pause/Win/Lose overlays on `camera.viewport`.
- **Evidence:** On SM-S711B, Home → Loadout → Battle worked, the full HUD rendered, a Bulb was placed, Glow orbs were collected, and waves advanced. At the level-1 terminal transition the battle froze with no Win overlay. Screenshots taken 15 seconds apart were byte-identical (`SHA-256 01CF05D6409536A5C1233940DCD265096C9A5BDA15E6F9ADB34B48F51B1FAAB6`), and tapping Pause did nothing. A clean second run reproduced the defect directly: tapping Pause during wave 1 froze the battle without mounting `PauseOverlay`. Android still reported `MainActivity` as top-resumed and the display awake; logcat contained no Flutter exception, fatal exception, or ANR.
- **Reproduction:** Start level 1, then tap Pause while wave 1 is running. The simulation stops, but no `PAUSED` overlay appears and no control can resume it.
- **Expected:** `DS-075` overlay mounts and remains interactive over the frozen world; Pause shows Resume/Restart/Home, Win shows VICTORY, and Lose shows DEFEAT/Try Again.
- **Impact:** `PH-02-G1` cannot pass. A player cannot finish, retry, advance, or deliberately resume a battle.
- **Likely cause:** Each path calls `game.pauseEngine()` before `_showOverlay(...)`. Flame queues the viewport child addition, then the paused engine never processes that queue. Tests mask the ordering bug: `_flushLifecycle` explicitly calls `game.resumeEngine()` after the production path, pumps five frames, then pauses again.
- **Remediation task:** `TASK-046` — mount/flush the overlay before pausing the engine, covering Pause, Win, and Lose without a test-only engine resume.
- **Owner/due:** Implementation owner, before `PH-02-G1` can close.
- **Workaround:** Force-stop and relaunch exits the frozen battle but does not fix the defect; it recurs on the next Pause/Win/Lose transition and current battle progress is discarded.
- **Retest evidence:** 2026-09-07 (c11) negative confirmation: two cold-start retries reproduced Pause and terminal-overlay failure. Fix retest remains pending; overlay must render and accept its primary button while world simulation stays frozen.
- **Closure/acceptance owner:** Pending.

## 15. Gate decision

- **Decision:** `No-go` — `PH-02-G1` fails on hardware because `AUD-024` makes pause/win/lose overlays unreachable.
- **Scope of decision:** `PH-02` on-device gate and v1 release readiness.
- **Blocking findings:** `AUD-023` and `AUD-024` are open High findings; `AUD-002`, `AUD-005`, `AUD-006`, and `AUD-007` remain open below High. Analyzer and 72-test suite were green before this device run, but their overlay helpers resume the engine and mask `AUD-024`.
- **Accepted risks:** `AUD-001`, `AUD-003`, `AUD-010` — all Low/Info, deliberate and documented substitutions.
- **Required follow-up:** Complete `TASK-046`, negative-control its regression, then repeat `PH-02-G1` on the SM-S711B.
- **Decision owner/date:** GameDesigner (lead), 2026-09-07 (c10).

## 16. Audit history

| Date | Scope/version | Decision | Open C/H/M/L | Auditor | Notes |
| --- | --- | --- | --- | --- | --- |
| 2026-09-07 (c11) | `AUD-024` restart/retry | No-go | 0/1/0/0 (confirmed) | GameDesigner (lead) | Two force-stop/cold-start retries reproduced the failure independently: Pause froze without overlay; idle level 1 froze at terminal transition without Win. Stable frame hashes, foreground/awake activity, connected device, and clean logcat rule out stale process, disconnection, crash, and ANR. Root-cause conclusion unchanged: overlay add is queued after `pauseEngine()`. |
| 2026-09-07 (c10) | `PH-02` on-device playthrough | No-go | 0/1/0/0 (new) | GameDesigner (lead) | Debug APK built, installed, and cold-launched on SM-S711B. Home → Loadout → Battle works; c8 HUD fix is confirmed on hardware and ADB taps place/collect. Found `AUD-024`: Pause/Win/Lose call `pauseEngine()` before queuing their overlay, leaving a frozen frame with no dialog. `PH-02-G2` closes; `PH-02-G1` remains blocked. |
| 2026-09-03 | Baseline (pre-`PH-00`) | No-go | 0/1/4/2 | Claude Sonnet 5 | First audit. Found the working tree already contains partial, uncommitted, unverified game code beyond what this audit was briefed to expect — see `AUD-008`. Most urgent finding is `AUD-009` (uncommitted work, High). |
| 2026-09-03 (c2) | `PH-00` in progress | No-go | 0/0/2/1 | Claude Sonnet 5 (planner) | `AUD-008`/`AUD-009` closed (fixed/committed). `flutter analyze` now shows 49 errors from newer code — root-caused to one file (`AUD-011`, assigned this cycle) plus a small remainder (`AUD-012`, next cycle). |
| 2026-09-04 (c3) | `PH-00` in progress | No-go | 0/0/2/2 | Claude Sonnet 5 (planner) | Cursor tried c2's 1-file `AUD-011` fix, returned `IMPLEMENTATION_BLOCKED` (2 consumer files also need edits). Planner traced every consumer, verified a 3-file fix locally (56→34 issues, reverted before handoff), reassigned to Cursor. Surfaced a new pre-existing defect (`AUD-013`, `const Vector2` has no const constructor) while verifying — it accounts for the gap between the c2 assignment's optimistic ≤12 target and the real 34. |
| 2026-09-07 (c8) | `PH-02` on-device gate | No-go | 0/0/0/2 | Claude Opus 5 (lead) | `AUD-021` root-caused and closed: the battle HUD was never wired to `BattleWorld` — the c7 diagnosis (a `swapWorld` viewport-clear race) was wrong, and is recorded as such. `AUD-022` closed alongside it. The regression test was run against the pre-fix tree first (0/4) so it is known to catch the defect. `flutter analyze` clean, 70/70. Gate stays No-go: no device was attached this cycle, so the on-device play-through is still unproven, and `AUD-002`/`AUD-005` remain open. |
| 2026-09-07 (c9) | `PH-02` play-loop gate | No-go | 0/1/0/0 (new) | Claude Opus 5 (lead) | First tests that actually play a level (`PH-02-G3`), plus `T-1`/`T-2` test-quality debt closed. Both new tests were negative-controlled. Playing level 1 wins with all three sweeps unspent, and level 4 is lost by an idle player — so both terminal states are reachable by play, not only by assignment. Found `AUD-023`: levels 1–3 are won by doing nothing. Gate stays No-go: still no device run, and `AUD-002`/`AUD-005`/`AUD-023` are open. |
| 2026-09-04 (c5) | `PH-00` in progress | No-go | 0/0/0/0 | Claude Opus 5 (lead) | GNHF loop stopped after its c4 planner stalled; the lead took the work directly. Closed `AUD-013` (`adf7676`, analyze 31 → 6) and `AUD-012` (`733fb55`, `lib/app.dart` shell + boot test, analyze clean). Booting the app for the first time surfaced `AUD-014` — `OpacityEffect` on four non-`OpacityProvider` components — fixed in the same commit. `flutter analyze`: No issues found. `flutter test`: 35/35. Gate stays No-go on `AUD-002`/`AUD-005`/`AUD-007` and the still-unproven on-device play-through. |
| 2026-09-04 (c4) | `PH-00` in progress | No-go | 0/0/1/2 | Claude Sonnet 5 (planner) | Cursor landed the c3 3-file `AUD-011` fix (commit `8387953`) — reran `flutter analyze` (34 issues, matches evidence) and `flutter test` (34/34) to confirm, closed `AUD-011`. Assigned the smallest remaining `AUD-012` piece — a missing `package:flame/events.dart` import in `right_panel_component.dart` (34→31) — to Cursor; `lib/app.dart`/`TASK-007` and two minor lints stay deferred as a separate, larger slice. |
