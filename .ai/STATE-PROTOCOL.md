# STATE.md Protocol v2 — Final Implementation Spec

Merged spec. Supersedes v1. Includes multi-agent (RUFLO) rules, memory-MCP
boundaries, and explicit session cycle open/close.

Hand this whole file to your coding agent and say:

> Read this spec and implement it in this repo exactly as written. Create
> STATE.md, create .ai/STATE-PROTOCOL.md, create .ai/inbox/, wire the hooks, add
> the /wrap command, update CLAUDE.md and AGENTS.md. Then fill STATE.md with the
> REAL current state of this project — read the git log, the working tree, the
> README, and query the codebase memory index. Invent nothing. If you cannot
> determine a field, write UNKNOWN and add it to NEEDS HUMAN.

Do one repo first. Use it three days. Then roll out.

---

## 1. The three state stores — do not blur these

You are running an indexer, an orchestrator, and a state file. They answer
different questions. If they overlap, you will stop trusting all three.

| Store | Answers | Owner | Lifetime |
|---|---|---|---|
| **codebase-memory-mcp / serena** | *What the code is.* Symbols, structure, where things live. | machine, regenerated | rebuilt on demand |
| **STATE.md** | *What I was doing and why. What to do next.* | lead agent, one writer | current cycle |
| **RUFLO queue / `.ai/inbox/`** | *What agents are doing right now.* | orchestrator | dies at cycle close |

**Hard rules:**

- STATE.md never contains code facts. Never a file inventory, never an
  architecture description, never a symbol list. That is what the index is for,
  and duplicating it is how STATE.md becomes 400 lines nobody reads.
- The memory MCP never contains NEXT ACTION. Volatile position stored in durable
  memory is how you get confidently sent to the wrong place next week.
- Only durable decisions cross from STATE.md into memory MCP (see §8).
- On conflict: STATE.md wins for **intent**, the index wins for **facts about
  code**, and if STATE.md contradicts the working tree, the working tree wins and
  STATE.md is stale — reconcile per §4.

---

## 2. Files this creates

```
<repo-root>/
├── STATE.md                     # agent-owned state (root, one per repo)
├── .ai/
│   ├── STATE-PROTOCOL.md        # canonical rules — source of truth
│   └── inbox/                   # worker scratch, consumed and emptied at cycle close
│       └── .gitkeep
├── CLAUDE.md                    # gets §9 block
├── AGENTS.md                    # gets §9 block
└── .claude/
    ├── settings.json            # SessionStart + SessionEnd hooks
    └── commands/
        └── wrap.md              # /wrap
```

**Location:** repo root. One per repo. In a monorepo, one per package that has
its own branch lifecycle — never more than three in a repo.

**Git:** commit STATE.md and `.ai/`. Gitignore `.ai/inbox/*` except `.gitkeep`.

**Worktrees:** each worktree carries its own STATE.md for its own branch, with
its own cycle numbering. On merge conflict, take the incoming branch's file
wholesale (`git checkout --theirs STATE.md`). Never hand-merge a snapshot.

---

## 3. STATE.md structure

Fixed headings. The agent must not add, remove, rename, or reorder sections.
**Hard cap 130 lines.** Over that, trim LOG then DECISIONS. If still over, the
file has started collecting code facts — delete them.

```markdown
# STATE — iap-restore-flutter

<!-- AGENT-OWNED. Whole-file rewrite only, never patched.
     Humans edit HUMAN NOTES only. Rules: .ai/STATE-PROTOCOL.md -->

CYCLE:   48 (open)
UPDATED: 2026-08-29T18:40+05:30
BY:      agent
BRANCH:  feat/iap-restore
COMMIT:  a3f9c21
STATUS:  BLOCKED

## NEXT ACTION
Run `flutter test test/iap/restore_test.dart`; fix the 2 failing cases in
lib/iap/iap_handler.dart:140 — restore returns null on sandbox accounts.

## PROJECT
Type:    Flutter (iOS + Android), StoreKit2 + Play Billing
Phase:   MVP
Success: paid restore survives reinstall on both stores; passes store review

## GOAL — this branch
Restore-purchase must work after app reinstall.
Done when:
- [ ] restore_test.dart passes (6/6)
- [ ] manual sandbox restore works on a fresh install, both platforms
- [ ] error copy reviewed

## BROKEN NOW
- Android restore silently no-ops when Play Billing returns an empty list.
  Reproduce: `flutter run --flavor dev` → Settings → Restore.

## DECISIONS / DO NOT TOUCH
- iap_handler.dart uses a manual retry loop, not the retry package — the package
  swallows StoreKit error codes we need for analytics.
- receipt_cache.json is intentionally unencrypted; it holds no PII.

## NEEDS HUMAN
- [ ] Refund-on-restore-failure, or log only? Blocks the error copy.

## COST NOTES
- Never let an agent read lib/generated/** — 40k tokens of nothing.
- Sonnet for UI work; Opus only for the billing state machine.
- Pipe `flutter pub get` output to a file; it floods context.

## HUMAN NOTES
(free text — agent copies this block through byte-for-byte)

## LOG
- 2026-08-29 | c48 | StoreKit2 restore wired, tests added, 2 failing
- 2026-08-28 | c47 | Branched from main, scoped restore flow
- 2026-08-26 | c46 | Closed receipt validation
```

### Field rules

| Field | Rule |
|---|---|
| `CYCLE` | Integer + `(open)` or `(closed)`. See §4. |
| `UPDATED` | ISO 8601 with offset. Always rewritten. |
| `BY` | `agent`, `human`, or `lead:<agent-name>` for RUFLO. |
| `BRANCH` / `COMMIT` | From `git branch --show-current` / `git rev-parse --short HEAD`. Never from memory. |
| `STATUS` | Exactly one of `GREEN` `NEEDS-REVIEW` `BLOCKED` `PARKED`. |
| `NEXT ACTION` | 1–3 lines, **exactly one action**. Must pass §6. |
| `PROJECT` | Write-once. Changes only when Phase changes. |
| `GOAL` | Rewritten only when the branch goal genuinely changes. Done-when boxes are testable or they don't belong. |
| `BROKEN NOW` | Must include a reproduction command. `- nothing` if clean. |
| `DECISIONS` | Max 8, each `<decision> — <reason>`. Reason mandatory. Mirrored to memory MCP (§8). |
| `NEEDS HUMAN` | Real blockers only. Not FYIs. |
| `COST NOTES` | Token traps, model preference, files that flood context. Append-only in practice; prune when wrong. |
| `HUMAN NOTES` | **Copied through verbatim. Never rewritten, summarised, or deleted.** |
| `LOG` | Newest first, max 5, one line each, tagged with cycle number. |

### STATUS semantics

- `GREEN` — open it and go. NEXT ACTION runs right now.
- `NEEDS-REVIEW` — agent finished; a human must read the diff before more work.
  NEXT ACTION must be `Review diff: <command>`.
- `BLOCKED` — needs a human decision. NEEDS HUMAN is non-empty.
- `PARKED` — deliberately frozen. NEXT ACTION is `Frozen <date>. To resume: <first step>.`

---

## 4. Cycle lifecycle — where the loop starts and finishes

A **cycle** is one unit of work with a defined open and close. This is what makes
a killed session detectable instead of mysterious.

### Open

Triggered by SessionStart. The agent:

1. Reads STATE.md (the hook injects it).
2. **Checks the cycle marker.**
   - `(closed)` → normal start. Increment cycle, mark `(open)`, emit the resume
     line, begin work.
   - `(open)` → **the previous cycle died.** Run reconciliation (below) before
     any other action. No code changes, no tool calls beyond inspection.
3. First output line, always, nothing before it:
   `Resuming <project> [<STATUS>] c<N> → <NEXT ACTION>`

### Reconciliation (orphaned cycle)

The previous session hit a token limit, crashed, or you closed the terminal.
The agent must, in this order:

1. `git log --oneline <COMMIT>..HEAD` — what got committed after the last write.
2. `git status --short` and `git diff --stat` — what is uncommitted.
3. Read `.ai/inbox/` if non-empty — worker notes from the dead cycle.
4. Reconstruct LAST DONE and BROKEN NOW from that evidence only. **Do not guess
   intent.** Anything unclear goes to NEEDS HUMAN.
5. Close the orphaned cycle, write the file, open the new cycle.
6. Report to the human in two lines: what died, what it recovered.

### Close

Triggered by `/wrap`, or by the agent finishing the assigned task. The agent
writes the full file with `CYCLE: <N> (closed)` and commits.

**A cycle that opens and never closes is a leak.** If your board (§11) shows a
project with an open cycle and a stale timestamp, that project ate a session and
gave nothing back.

---

## 5. Triggers

### READ (automatic, never writes)

- **R1 — Session start.** Hook injects the file. Cycle check runs. Resume line
  emitted.
- **R2 — Post-compact.** Same hook, `source: compact`. Agent silently re-anchors.
  No announcement, no cycle increment — a compact is not a new cycle.

### WRITE

| # | Trigger | Scope |
|---|---|---|
| W1 | A commit was just made | COMMIT, LOG, NEXT ACTION, UPDATED |
| W2 | Blocked / needs a decision | STATUS→BLOCKED, NEEDS HUMAN, BROKEN NOW, NEXT ACTION |
| W3 | Assigned task finished | STATUS→NEEDS-REVIEW, full rewrite, cycle closed |
| W4 | Human runs `/wrap` | Full rewrite, cycle closed |
| W5 | Context filling, or human says "wrap, context is high" | Full rewrite, cycle closed, then stop |
| W6 | Orphan reconciliation (§4) | Full rewrite, old cycle closed, new opened |

### Do NOT write when

- Only reads, greps, or index queries happened.
- Files changed but nothing committed and the task is still mid-flight —
  **except** W4/W5/W6, which always write and must record the mess in BROKEN NOW.
- Nothing material changed. Do not bump UPDATED to look busy; noise destroys the
  log's value.
- You are a subagent or a RUFLO worker. See §7.

---

## 6. NEXT ACTION validator

The agent runs this on itself before every write. Fails → rewrite. Fails twice →
ask the human.

**Must contain at least one of:** a file path with a line number, a runnable
shell command, or an exact symbol name.

**Rejected if built around:** `continue`, `work on`, `keep going`, `finish`,
`improve`, `polish`, `refactor the`, `look into`, `investigate`, `handle`,
`clean up`.

**Exactly one action.** If it contains " and then ", split and keep the first half.

**The test:** could someone who has never seen this project execute this line
without asking a question?

```
BAD   → Continue working on the IAP restore flow.
BAD   → Fix the failing tests and then deploy.
BAD   → 1. Fix tests  2. Update docs  3. Ship        ← three actions is zero actions
GOOD  → Run `flutter test test/iap/restore_test.dart`; the 2 failures are in
        lib/iap/iap_handler.dart:140.
GOOD  → Review diff: `git diff main..feat/iap-restore -- lib/iap/`
GOOD  → Frozen 2026-08-29. To resume: read GOAL, then `melos bootstrap`.
```

---

## 7. Write procedure and multi-agent rules

### Single-writer rule

**Exactly one writer per cycle.** In a RUFLO or subagent setup that is the lead
/ orchestrator, never a worker.

- Workers write to `.ai/inbox/<agent>-<timestamp>.md` — append-only, free-form,
  three lines max: what I did, what broke, what I'd do next.
- The lead consumes every inbox file at cycle close, folds the content into
  STATE.md, then **empties the inbox**.
- A worker that writes to STATE.md is a bug. Say so in CLAUDE.md.

### Write procedure (atomic)

1. Read current STATE.md. **Extract HUMAN NOTES verbatim into memory.**
2. Run the git commands for BRANCH and COMMIT. Never recall them.
3. Read and drain `.ai/inbox/` if present.
4. Compose the entire new file in memory, HUMAN NOTES pasted back unchanged.
5. Run the §6 validator on NEXT ACTION.
6. Trim: LOG to 5, DECISIONS to 8, file to 130 lines.
7. **Write the whole file in one Write.** Never Edit, never patch, never append.
   A half-written STATE.md is a corrupt STATE.md.
8. Mirror decisions to memory MCP per §8.
9. Commit STATE.md alone: `chore(state): c<N> <STATUS> — <first 8 words of NEXT ACTION>`

---

## 8. Memory MCP contract

At cycle close, the lead agent writes **one** memory entry per project:

- **Key:** `project:<repo-name>:decisions`
- **Value:** the current DECISIONS / DO NOT TOUCH list, verbatim.
- **Overwrite, never append.** The list in STATE.md is the truth.

Nothing else crosses. Specifically:

- **Never** store NEXT ACTION, STATUS, BROKEN NOW, or the LOG. Volatile.
- **Never** store code structure — that is the index's job and duplicating it
  means two answers to one question.
- **Never** store HUMAN NOTES.

At session start, an agent may read `project:<repo>:decisions` **only** if
STATE.md is missing or unreadable. Otherwise the file is authoritative.

Why decisions specifically: they are the one thing that must survive across
worktrees, across tools (Cursor won't read your Claude Code session), and across
weeks. A worker in a fresh worktree needs to know not to swap that retry loop.

---

## 9. Blocks for CLAUDE.md and AGENTS.md

Canonical rules live in `.ai/STATE-PROTOCOL.md` (sections 3–8 of this file).

**Append to CLAUDE.md:**

```markdown
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
```

**Append to AGENTS.md** — same block, but replace the `@.ai/STATE-PROTOCOL.md`
import with `Full rules are in .ai/STATE-PROTOCOL.md — read it before your first
STATE.md write this session.` Codex and Cursor do not resolve Claude Code imports.

If the two ever disagree, `.ai/STATE-PROTOCOL.md` wins.

---

## 10. Hooks — `.claude/settings.json`

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "f=\"$CLAUDE_PROJECT_DIR/STATE.md\"; if [ -f \"$f\" ]; then echo '=== STATE.md ==='; cat \"$f\"; if grep -q '^CYCLE:.*(open)' \"$f\"; then echo ''; echo '!! ORPHANED CYCLE — the previous session did not close. Run reconciliation (.ai/STATE-PROTOCOL.md section 4) BEFORE any other work.'; fi; n=$(ls -1 \"$CLAUDE_PROJECT_DIR/.ai/inbox\" 2>/dev/null | grep -v gitkeep | wc -l); [ \"$n\" -gt 0 ] && echo \"!! $n unconsumed worker note(s) in .ai/inbox/\"; else echo 'NO STATE.md. Create one from .ai/STATE-PROTOCOL.md before this session ends.'; fi"
          }
        ]
      }
    ],
    "SessionEnd": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "f=\"$CLAUDE_PROJECT_DIR/STATE.md\"; [ -f \"$f\" ] || exit 0; grep -q '^CYCLE:.*(open)' \"$f\" && echo 'WARNING: cycle left OPEN. Next session will run reconciliation.' >&2; exit 0"
          }
        ]
      }
    ]
  }
}
```

SessionStart stdout is injected into the model's context, which is what makes
resume free — you type nothing. It fires on `startup`, `resume`, `clear`, and
`compact`; the compact case is what recovers you after a context wipe.

SessionEnd cannot block termination, only warn.

PreCompact fires before compaction but its stdout is **not** injected as context
the way SessionStart's is, so it can warn you but cannot instruct the agent.
Recovery runs through the SessionStart `compact` path instead.

---

## 11. Commands

### `/wrap` — `.claude/commands/wrap.md`

```markdown
---
description: Close the cycle — write STATE.md so tomorrow is a five-minute start
---

End this session cleanly. Start no new work.

1. Drain .ai/inbox/ — fold any worker notes into STATE.md, then empty it.
2. Uncommitted changes: either commit them with a clear message, or record
   exactly what is uncommitted and why in BROKEN NOW.
3. Rewrite STATE.md per .ai/STATE-PROTOCOL.md §7 — whole-file write, HUMAN NOTES
   verbatim, LOG trimmed to 5, cycle marked (closed).
4. Run the §6 validator on NEXT ACTION. Read it back to me and state whether it
   names a file path or a runnable command. If it does not, rewrite it.
5. Set STATUS honestly. If you finished something I have not looked at, that is
   NEEDS-REVIEW, not GREEN.
6. Mirror DECISIONS to memory MCP per §8.
7. Commit STATE.md alone. Print the final NEXT ACTION line. Stop.
```

### Board script — `~/bin/board`

Answers "which project today" in two seconds. `chmod +x`, run every morning.

```bash
#!/usr/bin/env bash
ROOT="${1:-$HOME/dev}"
printf '%-16s %-6s %-13s %s\n' PROJECT CYCLE STATUS "NEXT ACTION"
printf '%.0s─' {1..104}; echo
for d in "$ROOT"/*/; do
  f="$d/STATE.md"; [ -f "$f" ] || continue
  cyc=$(grep -m1 '^CYCLE:'  "$f" | sed 's/CYCLE:[[:space:]]*//')
  st=$(grep  -m1 '^STATUS:' "$f" | sed 's/STATUS:[[:space:]]*//')
  nx=$(awk '/^## NEXT ACTION/{getline; getline; print; exit}' "$f")
  mark=""; case "$cyc" in *open*) mark="!" ;; esac
  printf '%-16s %-6s %-13s %s\n' "$(basename "$d")$mark" "$cyc" "$st" "${nx:0:52}"
done
```

```
PROJECT          CYCLE    STATUS        NEXT ACTION
────────────────────────────────────────────────────────────────────────────
flutter-app!     48(open) BLOCKED       Decide refund-on-restore-failure; see NE
swift-app        22(clos) NEEDS-REVIEW  Review diff: git diff main..feat/widgets
dashboard        9(clos)  PARKED        Frozen 2026-08-20. To resume: pnpm i
iap-handler      31(clos) GREEN         Run pnpm test src/webhook.test.ts
```

The `!` is a project that ate a session and closed nothing. Fix those first.

---

## 12. Weekly ritual (10 minutes, Friday)

1. Run `board`.
2. Any `!` — open it, force a reconciliation, close the cycle.
3. Any `NEEDS-REVIEW` older than three days — review it or demote it to PARKED.
   An unreviewed branch is not progress.
4. Re-pick next week's active projects. Two maximum. Everything else PARKED with
   an honest resume line.
5. Prune COST NOTES that turned out wrong.

Do not skip step 4. Five active projects is what created this problem.

---

## 13. Rollout

1. One repo. Three days. Fix what irritates you.
2. Then the rest, one per day.
3. Frozen projects: `STATUS: PARKED`, real GOAL, real resume line, cycle closed,
   commit, close the window.

The failure mode to watch is a vague NEXT ACTION. Every morning you still open a
project and feel lost, the fix is in §6 — not in another tool.
