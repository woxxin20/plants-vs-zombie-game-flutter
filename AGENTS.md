# Agent Operating Contract

This is the canonical instruction file for every AI or human coding agent in
this repository. `AGENT.md` and `CLAUDE.md` are compatibility entry points and
must defer to this file.

## 1. Mission

Build the product defined in `docs/prd.md`, using the system defined in
`docs/architecture.md`, within the constraints of `docs/rules.md`, following the
experience contract in `docs/design.md`, and in the order defined by
`docs/phases.md` and `docs/implementation_plan.md`.

Do not expand the product, invent requirements, or treat an existing bug or
implementation accident as intended behavior.

## 2. Required reading order

Before material work, read:

1. `docs/memory.md` — current state and handoff.
2. `docs/prd.md` — product scope and acceptance.
3. `docs/architecture.md` — system boundaries and decisions.
4. `docs/rules.md` — hard constraints.
5. `docs/design.md` — UI/UX contract when the task affects experience.
6. `docs/phases.md` — milestone context.
7. `docs/implementation_plan.md` — current task order.
8. `docs/audit.md` — relevant open findings and evidence.

For a tiny, isolated task, read the relevant sections rather than every line,
but never skip `memory.md`, the task's governing source, or applicable rules.

## 3. Authority and conflicts

- Current explicit user instructions govern the requested change.
- Each `/docs` file is authoritative only for the domain assigned in
  `README.md`.
- Runtime and tests are authoritative for what currently happens; the PRD is
  authoritative for what should happen.
- If implementation and specification differ, record drift in `docs/audit.md`.
- If two authoritative documents truly conflict, stop before making a
  high-impact assumption. Record the conflict and ask for a decision.
- Never resolve a conflict by silently editing multiple documents to match the
  implementation.

## 4. Readiness gate

Do not start production implementation when a relevant field still contains
`[REQUIRED: ...]`, an unresolved blocking question, or an unapproved
architecture decision. You may perform discovery, create a spike, or propose
options, but label that work non-production.

Before coding, identify:

- Requirement IDs: `PRD-FR-*` / `PRD-NFR-*`.
- Phase ID: `PH-*`.
- Task ID: `TASK-*`.
- Applicable `ADR-*`, `RULE-*`, and `DS-*` IDs.
- Acceptance criteria and verification command.

If no task exists, add one to `docs/implementation_plan.md` before substantial
implementation.

## 5. Implementation behavior

- Prefer the smallest coherent change that fully satisfies the traced acceptance criteria.
- Follow dependency direction and module boundaries from `docs/architecture.md`.
- Use only dependencies allowed by `docs/rules.md`.
- Reuse design tokens and shared components from `docs/design.md`; do not add one-off visual values without documenting an exception.
- Preserve existing user work and unrelated changes.
- Do not hide errors, disable tests, weaken types, or remove validation to make checks pass.
- Do not add speculative abstractions, features, analytics, tracking, or permissions.
- Treat security, privacy, accessibility, migrations, and destructive operations as explicit design concerns.
- When uncertainty is reversible and low-risk, make a documented assumption. When it changes scope, public API, data shape, security, cost, or architecture, request a decision.

## 6. Verification contract

Replace these placeholders before implementation begins:

| Check | Command | Required when |
| --- | --- | --- |
| Format | `[REQUIRED: format command]` | Source files change |
| Static analysis / lint | `[REQUIRED: lint command]` | Source or config changes |
| Type check | `[REQUIRED: type-check command or N/A]` | Typed source changes |
| Unit tests | `[REQUIRED: unit-test command]` | Logic changes |
| Integration tests | `[REQUIRED: integration-test command]` | Boundaries, APIs, database, or critical flows change |
| UI / golden / visual tests | `[REQUIRED: UI verification command or N/A]` | User-facing UI changes |
| Build | `[REQUIRED: build command]` | Before a release or when build configuration changes |

Run the narrowest relevant checks during development and all applicable gates
before declaring completion. If a required check cannot run, state exactly why,
record it in `docs/audit.md`, and do not describe the work as fully verified.

## 7. Documentation synchronization

Update documents in the same change as the code:

- `docs/implementation_plan.md`: task status and evidence.
- `docs/audit.md`: discovered or resolved drift, failures, and verification.
- `docs/memory.md`: concise current state, next action, blockers, and session log.
- The authoritative PRD, architecture, rules, or design file only when its truth changed.
- `docs/phases.md` only when phase scope, gate, or status changed.

Do not copy a requirement into several files. Reference its stable ID and link
to its authoritative definition.

## 8. Completion definition

A task is complete only when:

- Its acceptance criteria are met.
- Required tests/checks pass, with evidence recorded.
- Error, empty, loading, permission, offline, and edge states relevant to the task are handled.
- Security, accessibility, and responsive requirements are satisfied where applicable.
- Documentation and traceability are synchronized.
- No new unresolved high-severity audit finding was introduced.
- The next session can continue from `docs/memory.md` without reconstructing context.

## 9. Prohibited actions

- Do not implement an out-of-scope item from `docs/prd.md`.
- Do not change framework, state management, database, API style, navigation, or core dependencies without an approved `ADR-*`.
- Do not introduce packages forbidden by `docs/rules.md`.
- Do not store secrets, credentials, private keys, or real personal data in source or docs.
- Do not make destructive schema/data changes without a migration, rollback, backup strategy, and explicit authorization.
- Do not mark tasks, phases, bugs, or findings complete without objective evidence.
- Do not rewrite `memory.md` into a fictional success narrative; keep blockers and failures visible.
- Do not create agent-specific rules that conflict with this contract.

## 10. Agent handoff format

At the end of a working session, update `docs/memory.md` and report:

1. Outcome.
2. Files materially changed.
3. Requirement/task IDs addressed.
4. Checks run and their results.
5. Known limitations or open audit findings.
6. Exact recommended next action.

## 11. Session state (mandatory)

STATE.md at repo root is the single source of truth for what to do next.
Full rules are in .ai/STATE-PROTOCOL.md — read it before your first STATE.md
write this session.

- Read STATE.md first, before any other action. Open with
  `Resuming <project> [<STATUS>] c<N> → <NEXT ACTION>`. Nothing before it.
- If CYCLE is marked (open) at session start, the last session died. Run
  reconciliation (protocol §4) before touching anything else.
- Write STATE.md after a commit, when blocked, when the task is done, and on
  /wrap. Not otherwise. Do not bump the timestamp for nothing.
- NEXT ACTION: exactly one action, naming a file path or a runnable command.
  Never "continue X". Never a numbered list.
- Rewrite the whole file in one Write. Never patch it.
- HUMAN NOTES is copied through byte-for-byte.
- Only the lead session writes STATE.md. Subagents and workers write to
  .ai/inbox/ instead.
- STATE.md holds intent, not code facts. For code structure, query the codebase
  index — do not describe the codebase in STATE.md.
- Never end a turn with work half-done and STATE.md unupdated.

If AGENTS.md and .ai/STATE-PROTOCOL.md ever disagree, .ai/STATE-PROTOCOL.md
wins.

