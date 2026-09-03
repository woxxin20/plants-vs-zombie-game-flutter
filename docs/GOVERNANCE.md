# Project Governance Kit

This kit turns project documentation into an operating system for humans and AI
agents. Each fact has one authoritative home. Other documents reference that
fact by ID or link instead of copying it.

> Start here: complete `docs/prd.md`, `docs/architecture.md`, `docs/rules.md`,
> and `docs/design.md` before asking an agent to build production features.
> Required placeholders are written as `[REQUIRED: ...]`. The project is not
> implementation-ready while any relevant required placeholder remains.

## File map

| File | Authoritative for | Must not become |
| --- | --- | --- |
| `docs/prd.md` | Product purpose, users, scope, non-goals, requirements, success | A technical design or task list |
| `docs/architecture.md` | System boundaries, stack, data, interfaces, dependency direction | A product wish list |
| `docs/rules.md` | Non-negotiable implementation constraints and package policies | A progress diary |
| `docs/design.md` | Visual language, tokens, components, behavior, accessibility | A gallery of vague inspiration |
| `docs/phases.md` | Milestones, sequence, entry/exit gates | A line-by-line coding plan |
| `docs/implementation_plan.md` | Current executable tasks and verification steps | A second PRD |
| `docs/audit.md` | Evidence of what exists, what fails, and where reality diverges | A backlog without proof |
| `docs/memory.md` | Short-lived project state, handoff context, bugs, and recent work | Permanent product or architecture truth |
| `AGENTS.md` | Canonical instructions every coding agent must follow | Project requirements duplicated from `/docs` |
| `AGENT.md` | Compatibility redirect for tools expecting the singular filename | An independent instruction set |
| `CLAUDE.md` | Claude-compatible entry point into the same operating contract | A competing rulebook |

## Domain authority, not one giant precedence list

When documents disagree, use the source that owns the disputed domain:

| Question | Authority |
| --- | --- |
| What are we building, for whom, and why? | `docs/prd.md` |
| Is a capability in or out of scope? | `docs/prd.md` |
| How is the system divided and how does data move? | `docs/architecture.md` |
| Which tools, patterns, or packages are allowed? | `docs/rules.md` |
| How must the product look and behave? | `docs/design.md` |
| What milestone comes next? | `docs/phases.md` |
| What is the next concrete task? | `docs/implementation_plan.md` |
| What is actually implemented or broken today? | `docs/audit.md` plus test/runtime evidence |
| What does the next session need to know? | `docs/memory.md` |
| How must an AI agent operate? | `AGENTS.md` |

Runtime evidence beats documentation when reporting the current state, but it
does not silently redefine the intended product. A mismatch is recorded in
`docs/audit.md`, then resolved by changing either the implementation or the
correct authoritative document.

## The hive-mind wiring

Every material item receives a stable ID:

| Item | ID format | Example |
| --- | --- | --- |
| Functional requirement | `PRD-FR-###` | `PRD-FR-001` |
| Non-functional requirement | `PRD-NFR-###` | `PRD-NFR-002` |
| Success metric | `PRD-SM-###` | `PRD-SM-001` |
| Architecture decision | `ADR-###` | `ADR-004` |
| Rule | `RULE-###` | `RULE-012` |
| Design rule or component | `DS-###` | `DS-008` |
| Phase | `PH-##` | `PH-03` |
| Implementation task | `TASK-###` | `TASK-017` |
| Audit finding | `AUD-###` | `AUD-006` |

Never renumber an ID after it has been referenced. Mark removed items as
`Deprecated` and explain the replacement.

The normal chain is:

```text
PRD requirement
  -> architecture decision + design rule + implementation rule
  -> phase
  -> executable task
  -> code + tests
  -> audit evidence
  -> memory handoff
```

Each task in `docs/implementation_plan.md` must link to at least one PRD
requirement, a phase, the relevant architecture/rule/design IDs, and a test or
other verification method. This creates end-to-end traceability without
duplicating the underlying specification.

## Change propagation protocol

Apply changes in this order and in the same pull request or change set:

1. Change the authoritative document first.
2. Record the reason and affected IDs in that document's change log.
3. Update all downstream references, tasks, tests, and phase gates.
4. Implement the change.
5. Run the required checks.
6. Update `docs/audit.md` with evidence and unresolved drift.
7. Update `docs/memory.md` with the concise handoff state.

Common propagation paths:

| Change | Required propagation |
| --- | --- |
| Product scope changes | PRD -> architecture/design/rules if affected -> phases -> plan -> tests -> audit -> memory |
| Technical approach changes | Architecture/ADR -> rules if enforceable -> plan -> code/tests -> audit -> memory |
| Visual behavior changes | Design -> plan -> UI/tests -> audit -> memory |
| A rule changes | Rules -> affected plan tasks/code/tests -> audit -> memory |
| A bug is discovered | Audit + memory -> implementation task -> fix/test -> close audit finding -> memory |
| Work is completed | Plan status + evidence -> phase status if gate passed -> audit -> memory |

## Standard working loop

1. **Orient:** read `AGENTS.md` and the current summary in `docs/memory.md`.
2. **Trace:** identify the requirement, architecture, rule, design, and phase IDs.
3. **Plan:** add or refine tasks in `docs/implementation_plan.md`.
4. **Build:** make the smallest coherent implementation change.
5. **Verify:** run targeted tests, then the project-level quality gates.
6. **Reconcile:** update the plan, audit, and memory; never claim completion
   without evidence.

## Setup checklist

- [ ] Replace every relevant `[REQUIRED: ...]` placeholder.
- [ ] Delete example rows that do not apply.
- [ ] Select one stack and one package policy in `docs/rules.md`.
- [ ] Define exact commands in `AGENTS.md`.
- [ ] Give every requirement, rule, decision, phase, task, and finding a stable ID.
- [ ] Add the first end-to-end traceability row to the implementation plan.
- [ ] Run the first audit before feature work begins.
- [ ] Keep `AGENT.md` and `CLAUDE.md` as thin redirects; do not copy policies into them.

