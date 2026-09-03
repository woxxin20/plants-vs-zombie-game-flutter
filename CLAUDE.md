# Claude Project Entry Point

The repository uses one shared operating contract for all coding agents.

1. Read and follow [`AGENTS.md`](./AGENTS.md).
2. Begin with the current handoff in [`docs/memory.md`](./docs/memory.md).
3. Use [`README.md`](./README.md) to resolve which document owns each kind of truth.

Do not duplicate or override project policies in this file. Claude-specific
workflow notes may be added only when they are tool mechanics, not product,
architecture, design, or implementation rules. If any note conflicts with
`AGENTS.md`, `AGENTS.md` is authoritative.

## Session state (mandatory)

STATE.md at repo root is the single source of truth for what to do next.
Full rules: @.ai/STATE-PROTOCOL.md

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

