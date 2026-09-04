---
document: Active Project Memory and Handoff
authority: Short-lived current state, recent work, blockers, bugs, and next action
status: Active
owner: "Solo developer (repo owner)"
last_updated: "2026-09-04 00:30 +05:30"
---

# Memory — LIGHT vs SHADOW: Prism Defense

> Current cycle, `NEXT ACTION`, `BROKEN NOW`, and open/closed status live in
> [`STATE.md`](../STATE.md) at repo root — agent-owned, whole-file rewrite per
> [`.ai/STATE-PROTOCOL.md`](../.ai/STATE-PROTOCOL.md). This file keeps only
> durable handoff narrative that STATE.md's 130-line cap and 5-entry log have
> no room for. `AUD-009` (uncommitted work), the original `AUD-008`
> (`Curves` error), and `AUD-011` (tokens.dart `TextStyle`) are now closed —
> the repo is committed, that bug is fixed and confirmed (`flutter analyze`
> 34, `flutter test` 34/34). Current blocker is `AUD-012` (below).

This is the project's **working memory**, not a specification. It answers:
"Where are we now, what changed, what is blocked, and what should happen next?"

If this file conflicts with a product/architecture/rule/design source, the
authoritative source remains unchanged and the mismatch must be recorded in
`audit.md`.

## 1. Maintenance rules

- Update this file at the end of every material work session.
- Keep it concise and factual; target no more than 200 lines.
- Keep only the most recent 10 session entries.
- Move durable product truth to `prd.md`, technical decisions to an ADR,
  constraints to `rules.md`, and visual truth to `design.md`.
- Keep the current task state in `implementation_plan.md`; summarize it here.
- Keep evidence/findings in `audit.md`; reference finding IDs here.
- Never store secrets, credentials, personal data, full logs, or long pasted chat.
- Do not erase unresolved bugs/blockers to make the project appear clean.

## 2. Current snapshot

- **Product:** LIGHT vs SHADOW — Prism Defense, an offline landscape
  lane-defense game built on Flutter + Flame. See
  `LIGHT_vs_SHADOW_Prism_Defense_Flame_Spec.md` for full design (product
  truth belongs to `docs/prd.md` once authored, not here).
- **Current phase:** `PH-07` (governance bootstrap) — Complete. `PH-00`
  (Flame engine bootstrap) — In progress; `flutter analyze` is clean and the
  app shell boots under test, but no level has been played on a device yet.
- **Current objective:** Get a `flutter analyze`-clean, test-covered
  `FlameGame` bootstrap running landscape-locked at 60fps (`PH-00` exit
  gate, `docs/phases.md` §4), then proceed to `PH-01`/`PH-02`.
- **Active task:** Run the app on a real device / emulator and play one
  level start to win/lose. That is the last unchecked `GOAL` box in
  `STATE.md`, and nothing in the test suite proves it.
- **Last verified version:** Working tree is committed; `HEAD` is `733fb55`
  on `overnight/gnhf-prism-defense-20260903`. `AUD-009`, `AUD-011`,
  `AUD-012`, `AUD-013` and `AUD-014` are all closed.
- **Overall health:** On track for `PH-00`. `flutter analyze` is clean (56 →
  34 → 31 → 6 → 0 across c3-c5) and `flutter test` is 35/35. The one lesson
  from c5: an analyzer-clean tree still could not boot — `AUD-014` was a
  runtime-only contract breach that only appeared once the app was actually
  started. Prefer a boot/integration test over another analyzer pass for the
  next class of defect. Also do not assume `implementation_plan.md`'s
  per-task `Not started` labels reflect reality — reconcile against actual
  files before starting a task (see `AUD-008`'s original lesson).

## 3. What is implemented and verified

| Outcome | Requirement/task | Evidence | Verified date |
| --- | --- | --- | --- |
| Governance kit deployed at repo root | `TASK-001` | `ls docs AGENTS.md AGENT.md CLAUDE.md STATE.md` | 2026-09-03 |
| `pubspec.yaml` rewritten to `prism_defense` + Flame stack, resolves | `TASK-003`, `TASK-005` | `flutter pub get` exit 0 | 2026-09-03 |
| Empty `lib/`/`assets/` skeleton folders exist | `TASK-004` | `find lib assets -type d` | 2026-09-03 |
| Known spec divergences (a)-(f) triaged as audit findings | `TASK-006` | `docs/audit.md` `AUD-001`..`AUD-006` | 2026-09-03 |

Nothing beyond this is "verified" — the partial `lib/` code found during
this audit (`AUD-008`) exists but has not passed `flutter analyze` cleanly
and has zero test coverage, so it is explicitly **not** listed as
implemented/verified here.

## 4. In progress

| Task | Current state | Remaining work | Owner | Next check |
| --- | --- | --- | --- | --- |
| `TASK-009`..`TASK-012` (`PH-00`) | `TASK-007` (app shell) and `TASK-008` (tokens) are done and committed; `flutter analyze` is clean and `flutter test` is 35/35, including a boot test that mounts `HomeWorld` on the shared game | Play one level through on a device (rotation + win/lose + save survives a restart); bundle the fonts (`TASK-011`, blocked on `AUD-002`); retarget the native ids (`TASK-012`, `AUD-005`) | Solo developer | A level plays start to win/lose on a device |

## 5. Exact next actions

The single next action lives in `STATE.md` → `NEXT ACTION`: run
`flutter run -d <device>` from the overnight worktree and play level 1 from
Home through Loadout to a win or a loss. Everything downstream of that
(`TASK-011` fonts, `TASK-012` native ids) is blocked on human decisions
listed under `NEEDS HUMAN`.

## 6. Blockers and decisions needed

| ID | Blocker/decision | Impact | Owner | Next action/due | Blocks |
| --- | --- | --- | --- | --- | --- |
| `AUD-002` | No offline font solution exists (spec mandates GoogleFonts, product forbids runtime fetch) | Blocks `PH-00` exit gate; all text currently has no defined typeface | Solo developer | Source/license Orbitron, Inter, JetBrainsMono TTFs and bundle them (`TASK-011`) | `PH-00` exit gate |
| `AUD-005` | Native app id/bundle id/display name still say `plants_vs_zombie` | Blocks any store-facing build; visible identity mismatch even in dev | Solo developer | Retarget Android `applicationId`/`namespace`/label and iOS `PRODUCT_BUNDLE_IDENTIFIER` (`TASK-012`) | `PH-00` exit gate |

`AUD-009` (uncommitted work) and the original `AUD-008` (`Curves` error) are
closed — see `docs/audit.md` for retest evidence.

## 7. Known bugs and open findings

`audit.md` owns evidence and severity. This is only the active working view.

| Finding | User/system effect | Workaround | Fix task | Status |
| --- | --- | --- | --- | --- |
| `AUD-011` | `flutter analyze` failed (44 errors) across 6 world screens | N/A — fixed | `TASK-008` — landed by Cursor (`8387953`), confirmed c4 | Closed |
| `AUD-012` | `flutter analyze` failed (12 issues); app could not boot (`lib/app.dart` missing) | N/A — fixed | Import (`e8a179d`), lints (`adf7676`), `lib/app.dart` shell (`733fb55`) | Closed |
| `AUD-013` | `flutter analyze` failed (22 errors) — `const Vector2(...)` across 5 world screens | N/A — fixed | `adf7676` | Closed |
| `AUD-014` | Every beam, shadow death and home-diorama fade threw `Can only apply this effect to OpacityProvider` on mount | N/A — fixed | `FadeableRender` mixin, `733fb55` | Closed |
| `AUD-002` | No bundled typeface; text falls back to system default | Ship with system font as a last resort if unresolved | `TASK-011` | Open |
| `AUD-005` | App id/label still `plants_vs_zombie` | None needed for local dev only | `TASK-012` | Open |
| `AUD-006` | No AdMob/IAP ids yet | Use Google test ad unit ids in dev, never ship them | `TASK-040`, `TASK-041` | Open, deferred to `PH-05` |
| `AUD-001`, `AUD-003`, `AUD-010`, `AUD-004` | None — deliberate/correct divergences | N/A | N/A | Accepted risk / Closed |
| `AUD-007` (original "zero tests") | superseded — `test/{optics,rules,particle_pool}_test.dart` exist, 34 tests green | N/A | N/A | Closed |
| `AUD-008` (original `Curves` error), `AUD-009` (uncommitted work) | superseded/resolved — see `docs/audit.md` for retest evidence | N/A | N/A | Closed |

## 8. Recent decisions and assumptions

| Date | Decision/assumption | Authority | Effect on current work |
| --- | --- | --- | --- |
| 2026-09-03 | `PRD-FR-001`..`PRD-FR-015` are plausible placeholder ids by topic, pending real `docs/prd.md` authorship | `docs/implementation_plan.md` §"ID reconciliation note" | Every task's requirement link may need a one-pass renumber once `prd.md` is approved — do not treat these as final |
| 2026-09-03 | `ADR-001`..`ADR-005` referenced in `pubspec.yaml` comments do not yet exist in `docs/architecture.md` | `docs/audit.md` `AUD-001`, `AUD-003` | `architecture.md` authorship should formalize these ids to match what the dependency file already assumes, not invent new ones |
| 2026-09-03 | Governance bootstrap phase numbered `PH-07` (last), not `PH-00`, per the "never renumber" rule, even though it chronologically precedes the spec's Phase 0-6 | `docs/phases.md` §"header note" | `PH-00`..`PH-06` map 1:1 onto spec §25 Phase 0-6; do not confuse `PH-07`'s number with its execution order |

## 9. Environment and operational notes

- **Active branch/worktree:** `overnight/gnhf-prism-defense-20260903`, in the
  sibling worktree `../plants-vs-zombie-game-flutter-gnhf-overnight`. `main`
  still holds the WIP repurpose commit `ae7a5b6`; nothing has been merged.
- **Runtime/tool versions:** Flutter 3.47.0 stable; Dart SDK constraint
  `>=3.11.1 <4.0.0` (`pubspec.yaml`). Full dependency list is
  `pubspec.yaml`'s job, not repeated here.
- **Required local setup:** See `AGENTS.md` for exact commands once it is
  populated with real ones; `flutter pub get` is currently the only proven
  setup step.
- **Test data/mocks:** `test/app_boot_test.dart` mocks the
  `plugins.flutter.io/path_provider` channel with a temp dir so
  `hive_ce_flutter`'s `initFlutter()` works headless. Note that a widget test
  runs in fake-async: real I/O (`Content.load()`, `SaveStore.open()`) must
  happen in `setUpAll`, never inside `testWidgets`, or the test hangs until
  the 10-minute timeout. Flame's ticker never idles, so pump fixed frames —
  `pumpAndSettle` will time out.
- **External service status:** N/A — no ads/IAP/network wired yet.
- **Uncommitted/user-owned changes:** None — the overnight worktree is clean
  at `733fb55`. `.ai/inbox/` is drained. Do not run any destructive git
  command against `main`, which still carries the WIP repurpose commit.

## 10. Last verification

| Date/time | Check | Result | Scope/environment | Audit link |
| --- | --- | --- | --- | --- |
| 2026-09-04 (c5) | `flutter analyze` | No issues found | Local Windows, `HEAD` `733fb55` | `AUD-011`..`AUD-014` all closed |
| 2026-09-04 (c5) | `flutter test` | 35/35 pass | Local Windows | `AUD-014` (found by the new boot test) |
| 2026-09-04 (c5) | Play a level on a device | Not run | — | The remaining `PH-00` gap |
| 2026-09-04 (c4) | `flutter analyze` | 34 issues (down from 56) | Local Windows, `HEAD` `8387953` | `AUD-011` (closed), `AUD-012`/`AUD-013` (open) |
| 2026-09-04 (c4) | `flutter test` | 34/34 pass | Local Windows | — |
| 2026-09-03T11:04Z | `flutter analyze` | Fail — 1 error, 1 warning, 1 info | Local Windows, current `lib/` | `AUD-008` |
| 2026-09-03 | `flutter pub get` | Pass | Local Windows | §12 test/build evidence |

## 11. Recent session log

Cycle-by-cycle history lives in `STATE.md` → `LOG`. This section is for
narrative handoff needing more than one line.

### 2026-09-04 10:30 +05:30 — c5: GNHF stopped, analyzer cleared, app shell written

The overnight GNHF loop had stalled: its supervisor was alive but the c4
`claude-planner` wrapper had printed `max iterations reached (3)` and was
idling on an animated TUI. On the user's instruction the lead stopped the
four exact GNHF PIDs (supervisor, wrapper, node CLI, keep-awake child — never
a tree kill, other unrelated agents were running on the machine) and took the
work directly.

Three things landed:

1. `adf7676` — `AUD-013`: `Vector2` has no const constructor, so `const` was
   removed across the five world screens (locals to `final`,
   `map_world.dart`'s `static const _cardSize` to `static final`). Sharing one
   `Vector2` is safe because Flame copies `size`/`position` into a
   `NotifyingVector2`. Also cleared the last three lints. 31 → 6 issues.
2. `733fb55` — `TASK-007`: `lib/app.dart`, the shell `main.dart` had always
   imported but which never existed. `WidgetsApp.router` (`ADR-006`) over a
   `go_router` `ShellRoute` that keeps one `RiverpodAwareGameWidget` mounted
   while each route swaps `camera.world` (`ADR-003`). Route bodies are
   zero-size widgets that swap post-frame so the engine is never mutated
   mid-build. Analyzer clean.
3. The same commit fixed `AUD-014`, which the new `test/app_boot_test.dart`
   caught on its first run: `OpacityEffect` needs an `OpacityProvider`, and
   four hand-painted components (beam, shadow, two home-diorama pieces) are
   not one, so every fade threw on mount. A `FadeableRender` mixin fades the
   subtree in one layer instead.

Worth carrying forward: `flutter analyze` said nothing about `AUD-014`. The
first genuine boot found it in one run. The next defect class is likelier to
come from running the game than from another static pass.

Note on `FlameGame`: `game.world` is a separate field from `camera.world`.
`swapWorld` sets the camera's, so assertions must read `game.camera.world`.

### 2026-09-04 00:30 +05:30 — c4 planning: confirmed TASK-008 landed, assigned the smallest AUD-012 sub-slice

- **Request/goal:** Act as the `claude-planner` role for this cycle.
  STATE.md's CYCLE marker was still `2 (open)` at session start (orphaned —
  the c3 Cursor implementation cycle never closed it), so reconciliation ran
  first: `git log`/`git status`/`.ai/inbox/` review, per protocol §4.
- **Findings:** Reconciliation showed four commits landed after STATE.md's
  recorded `3f8a660`, the last being `8387953` — Cursor's `TASK-008` 3-file
  `TextStyle` fix (`.ai/inbox/cursor-evidence.md`, `IMPLEMENTATION_READY`).
  Reran `flutter analyze` (34 issues, matches evidence) and `flutter test`
  (34/34) to confirm before trusting the claim. Closed `AUD-011`. Of the
  remaining 34, picked the single smallest unfinished piece:
  `right_panel_component.dart` uses `TapCallbacks`/`TapUpEvent` without
  importing `package:flame/events.dart` (confirmed by grep — all 10 other
  `TapCallbacks` consumers in the repo import it; this file is the sole
  outlier) — a 1-line fix closing 3 of `AUD-012`'s 12 issues (34→31).
- **Changed:** `docs/audit.md` (closed `AUD-011`, updated `AUD-012` with the
  sub-slice scope, updated register/gate decision/history),
  `docs/implementation_plan.md` (`TASK-008` marked Done, plan-change-log
  entry), `docs/memory.md` (this file), `STATE.md`, `.ai/inbox/gnhf-assignment.md`
  (rewritten — new Cursor handoff), `.ai/inbox/cursor-evidence.md` (emptied,
  consumed into the docs above per protocol §7).
- **IDs:** `AUD-011` closed; `TASK-008` Done; `AUD-012` sub-slice assigned,
  parent still Open.
- **Verified:** `flutter analyze` (34, evidence for closing `AUD-011`),
  `flutter test` (34/34), `git log 3f8a660..HEAD`/`git status` (clean, 4
  commits recovered), grep across `lib/` confirming the import gap is
  file-scoped.
- **Not verified:** No code was changed this pass (planner role does not
  implement); the new import fix is unverified until Cursor lands it.
- **Next:** Cursor implements the `right_panel_component.dart` import fix
  per `.ai/inbox/gnhf-assignment.md`; next planning cycle picks up
  `lib/app.dart`/`TASK-007` (rest of `AUD-012`) or `AUD-013`.

### 2026-09-03 18:50 +05:30 — c2 planning: root-caused the analyze failure, assigned TASK-008 to Cursor

- **Request/goal:** Act as the `claude-planner` role (`.ai/overnight/claude-planner.md`)
  for this cycle: read the governing docs, pick exactly one smallest
  unfinished `TASK-*` slice, write `.ai/inbox/gnhf-assignment.md` for Cursor,
  and sync `STATE.md`/`implementation_plan.md`/`audit.md`/`memory.md`.
- **Findings:** `AUD-009` (uncommitted work) and the original `AUD-008`
  (`Curves` error) are both resolved — the working tree is committed and
  `flutter analyze` no longer shows that specific error. However,
  `flutter analyze` now shows 56 issues (49 errors) from code written since
  then. 44 of those errors trace to one root cause: `lib/core/tokens.dart`
  only imports `dart:ui`, so `class T`'s `TextStyle` fields are
  `dart:ui.TextStyle` (no `copyWith`, stricter const rules) instead of
  `package:flutter/painting.dart`'s — breaking every `lib/game/worlds/*.dart`
  screen that consumes them. Logged as `AUD-011`. The remaining 5 errors
  (missing `lib/app.dart`, a missing Flame import in
  `right_panel_component.dart`) are unrelated and logged as `AUD-012` for a
  future cycle.
- **Changed:** `docs/audit.md` (closed `AUD-008`/`AUD-009`, added
  `AUD-011`/`AUD-012`, updated register and gate decision), 
  `docs/implementation_plan.md` (`TASK-008` corrected to the real filename
  and marked In progress), `docs/memory.md` (this file), `STATE.md`,
  `.ai/inbox/gnhf-assignment.md` (new — the Cursor handoff).
- **IDs:** `TASK-008`; `AUD-008`, `AUD-009` closed; `AUD-011`, `AUD-012` opened.
- **Verified:** `flutter analyze` (56 issues, 49 errors — evidence for the
  finding), `flutter test` (34 tests, all pass), `git log`/`git status`
  (working tree clean, `HEAD` `3f8a660`).
- **Not verified:** No code was changed this pass (planner role does not
  implement); the fix itself is unverified until Cursor lands it.
- **Next:** Cursor implements `TASK-008` per `.ai/inbox/gnhf-assignment.md`;
  Codex reviews; next planning cycle picks up `AUD-012`/`TASK-007`.

### 2026-09-03 11:10 UTC — Filled `phases.md`, `implementation_plan.md`, `audit.md`, `memory.md`

- **Request/goal:** Fill the four governance templates
  (`phases.md`, `implementation_plan.md`, `audit.md`, `memory.md`) against
  `LIGHT_vs_SHADOW_Prism_Defense_Flame_Spec.md` §25/§24, establishing the
  first `PH-*`/`TASK-*`/`AUD-*` ids for this project. Docs-only — no code,
  no `STATE.md`, no other files touched.
- **Changed:** `docs/phases.md`, `docs/implementation_plan.md`,
  `docs/audit.md`, `docs/memory.md` (this file).
- **IDs:** `PH-00`..`PH-07`; `TASK-001`..`TASK-045`; `AUD-001`..`AUD-010`.
- **Verified:** `flutter pub get` (pass, per brief), `flutter analyze` (fail
  — run live this session, see `AUD-008`), `find`/`git status` evidence for
  every audit finding.
- **Not verified / failed:** No `flutter test` (no tests exist), no device
  run, no build. `flutter analyze` explicitly failed (1 error).
- **New findings/risks:** `AUD-008` (uncommitted partial game code
  contradicts this task's own briefed baseline — likely concurrent agent
  activity in this repo), `AUD-009` (High — entire repurposing work
  uncommitted, real data-loss exposure).
- **Next:** Commit a checkpoint of the current working tree (`AUD-009`),
  then reconcile `implementation_plan.md` `TASK-007`+ against the
  already-existing partial `lib/` files (`AUD-008`) before writing any new
  code, then fix the `Curves` import error and get `flutter analyze` clean
  as the first concrete step of `PH-00`.

## 12. Handoff checklist

- [x] Active phase/task and status are accurate.
- [x] Implemented claims have evidence.
- [x] Failed/unrun checks are visible.
- [x] Blockers and findings link to owners/tasks.
- [x] The exact next action is unambiguous (§5, and restated in §11).
- [ ] Durable decisions were promoted to their authoritative documents —
      **not done**: `ADR-001`..`ADR-005` and `PRD-FR-*` ids remain
      placeholders in `architecture.md`/`prd.md`, which are still Drafts.
- [x] Plan, audit, and memory agree (all written in this same pass).
- [x] Old session entries were archived if the size limit was exceeded — N/A,
      this is the first entry.

## 13. Archive pointer

Older session notes: N/A — this is the first `memory.md` entry.
