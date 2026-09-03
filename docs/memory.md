---
document: Active Project Memory and Handoff
authority: Short-lived current state, recent work, blockers, bugs, and next action
status: Active
owner: "Solo developer (repo owner)"
last_updated: "2026-09-03 11:10 UTC"
---

# Memory — LIGHT vs SHADOW: Prism Defense

> Current cycle, `NEXT ACTION`, `BROKEN NOW`, and open/closed status now live
> in [`STATE.md`](../STATE.md) at repo root — agent-owned, whole-file rewrite
> per [`.ai/STATE-PROTOCOL.md`](../.ai/STATE-PROTOCOL.md). This file keeps
> only durable handoff narrative that STATE.md's 130-line cap and 5-entry log
> have no room for. **This pass did not edit STATE.md** (out of scope for the
> agent that wrote this file); STATE.md still shows its 2026-08-29 snapshot
> and should be refreshed next session to reflect `AUD-009`.

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
  (Flame engine bootstrap) — Not started, next up.
- **Current objective:** Get a `flutter analyze`-clean, test-covered empty
  `FlameGame` bootstrap running landscape-locked at 60fps (`PH-00` exit
  gate, `docs/phases.md` §4), then proceed to `PH-01`/`PH-02`.
- **Active task:** None formally started; `TASK-007`..`TASK-012` (`PH-00`)
  are `Ready` to pick up per `docs/implementation_plan.md`.
- **Last verified version:** No commit reflects current state — see
  `AUD-009`. Last actual commit is `4b4c974` ("Update README.md"), which
  still shows the *old* pre-repurposing Plants-vs-Zombies game.
- **Overall health:** At risk — not from missing features (expected at this
  stage) but from `AUD-009`: 94 changed paths across the entire repo
  (governance kit, rewritten `pubspec.yaml`, new game code/assets, old-game
  deletions) are uncommitted. See §6 below — this is the most urgent item.

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
| `TASK-007`..`TASK-012` (`PH-00`) | Some target files already exist in the working tree (`lib/game/light_vs_shadow_game.dart`, `lib/core/tokens.dart`, `lib/core/layout.dart`, etc. — see `AUD-008`) but are unreviewed, uncommitted, and `flutter analyze` fails against them | Commit a checkpoint first (`AUD-009`); reconcile which `TASK-*` each existing file actually satisfies; fix the `Curves` undefined-identifier error in `lib/game/components/tools/tool_component.dart:62`; add the first `flutter test` (`TASK-009`'s acceptance criterion) | Solo developer | `flutter analyze` returns 0 errors; first widget test passes |

## 5. Exact next actions

The single next action lives in `STATE.md` → `NEXT ACTION`. STATE.md was
**not** updated by this pass and still shows a stale 2026-08-29 snapshot
("run `git init`" — git already exists and has 7 commits, so that specific
instruction is obsolete). The next session should rewrite `STATE.md`'s
`NEXT ACTION` to: **commit the current working tree as a checkpoint
(`AUD-009`), then start `TASK-007`.**

## 6. Blockers and decisions needed

| ID | Blocker/decision | Impact | Owner | Next action/due | Blocks |
| --- | --- | --- | --- | --- | --- |
| `AUD-009` | Entire repurposing work (governance kit + pubspec + new code/assets + old-game deletion) is uncommitted; 94 changed paths, last commit `4b4c974` predates all of it | A `git reset --hard`/`checkout -- .`/disk loss right now destroys everything with no recovery | Solo developer | Commit a checkpoint immediately, before any further code work | Effectively blocks safely starting `TASK-007` |
| `AUD-008` | Partial `lib/` game code already exists (source unclear — possibly concurrent agent activity during this audit), untested, `flutter analyze` fails with 1 error | `PH-00`/`PH-01`/`PH-02` task statuses in `implementation_plan.md` may not reflect actual file-level progress | Solo developer | Reconcile task statuses against actual file contents next session; do not mark tasks `Done` from file presence alone | `TASK-007`..`TASK-032` status accuracy |
| `AUD-002` | No offline font solution exists (spec mandates GoogleFonts, product forbids runtime fetch) | Blocks `PH-00` exit gate; all text currently has no defined typeface | Solo developer | Source/license Orbitron, Inter, JetBrainsMono TTFs and bundle them (`TASK-011`) | `PH-00` exit gate |
| `AUD-005` | Native app id/bundle id/display name still say `plants_vs_zombie` | Blocks any store-facing build; visible identity mismatch even in dev | Solo developer | Retarget Android `applicationId`/`namespace`/label and iOS `PRODUCT_BUNDLE_IDENTIFIER` (`TASK-012`) | `PH-00` exit gate |

## 7. Known bugs and open findings

`audit.md` owns evidence and severity. This is only the active working view.

| Finding | User/system effect | Workaround | Fix task | Status |
| --- | --- | --- | --- | --- |
| `AUD-009` | Total data-loss exposure on any destructive git operation | Avoid `git reset --hard`/`checkout -- .`/`clean -fd` until committed | Commit checkpoint (no `TASK-*` id — repo hygiene action) | Open |
| `AUD-008` | `flutter analyze` fails (1 error) on existing `lib/` code | Avoid relying on `tool_component.dart` until fixed | Reconcile + fix `Curves` import | Open |
| `AUD-002` | No bundled typeface; text falls back to system default | Ship with system font as a last resort if unresolved | `TASK-011` | Open |
| `AUD-005` | App id/label still `plants_vs_zombie` | None needed for local dev only | `TASK-012` | Open |
| `AUD-007` | Zero automated tests | None — cannot claim any task `Verified` yet | `TASK-009` onward | Open |
| `AUD-006` | No AdMob/IAP ids yet | Use Google test ad unit ids in dev, never ship them | `TASK-040`, `TASK-041` | Open, deferred to `PH-05` |
| `AUD-001`, `AUD-003`, `AUD-010`, `AUD-004` | None — deliberate/correct divergences | N/A | N/A | Accepted risk / Closed |

## 8. Recent decisions and assumptions

| Date | Decision/assumption | Authority | Effect on current work |
| --- | --- | --- | --- |
| 2026-09-03 | `PRD-FR-001`..`PRD-FR-015` are plausible placeholder ids by topic, pending real `docs/prd.md` authorship | `docs/implementation_plan.md` §"ID reconciliation note" | Every task's requirement link may need a one-pass renumber once `prd.md` is approved — do not treat these as final |
| 2026-09-03 | `ADR-001`..`ADR-005` referenced in `pubspec.yaml` comments do not yet exist in `docs/architecture.md` | `docs/audit.md` `AUD-001`, `AUD-003` | `architecture.md` authorship should formalize these ids to match what the dependency file already assumes, not invent new ones |
| 2026-09-03 | Governance bootstrap phase numbered `PH-07` (last), not `PH-00`, per the "never renumber" rule, even though it chronologically precedes the spec's Phase 0-6 | `docs/phases.md` §"header note" | `PH-00`..`PH-06` map 1:1 onto spec §25 Phase 0-6; do not confuse `PH-07`'s number with its execution order |

## 9. Environment and operational notes

- **Active branch/worktree:** `main` (per repo git status at session start).
- **Runtime/tool versions:** Flutter 3.47.0 stable; Dart SDK constraint
  `>=3.11.1 <4.0.0` (`pubspec.yaml`). Full dependency list is
  `pubspec.yaml`'s job, not repeated here.
- **Required local setup:** See `AGENTS.md` for exact commands once it is
  populated with real ones; `flutter pub get` is currently the only proven
  setup step.
- **Test data/mocks:** None yet — no tests exist (`AUD-007`).
- **External service status:** N/A — no ads/IAP/network wired yet.
- **Uncommitted/user-owned changes:** Effectively the entire working tree —
  see `AUD-009`. Do not run any destructive git command against this repo
  without committing first.

## 10. Last verification

| Date/time | Check | Result | Scope/environment | Audit link |
| --- | --- | --- | --- | --- |
| 2026-09-03T11:04Z | `flutter analyze` | Fail — 1 error, 1 warning, 1 info | Local Windows, current `lib/` | `AUD-008` |
| 2026-09-03 | `flutter pub get` | Pass | Local Windows | §12 test/build evidence |
| 2026-09-03 | `find test -type f` | 0 files | Local | `AUD-007` |

This session (docs-only pass) did not run `flutter test` or `flutter build`
— neither is meaningful yet (`AUD-007`: no tests exist; no `main.dart`
entry point exists to build from).

## 11. Recent session log

Cycle-by-cycle history lives in `STATE.md` → `LOG` (not updated this pass —
see the note in §5). This section is for narrative handoff needing more
than one line.

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
