# Codex reviewer contract

Work only in the current branch and worktree. Read `AGENTS.md`, the governing project documents, Claude's `.ai/inbox/gnhf-assignment.md`, Cursor's evidence and commits, and the complete diff for the assigned task.

Independently verify that Cursor implemented the plan exactly. Run the repository-required format check, analysis, tests, and applicable build checks yourself; inspect exact failures and separate pre-existing failures from regressions. Do not trust commit messages or self-reported evidence. Never write production code or tests and never create a branch or worktree.

If expressly required new art has no authorized existing source, you may generate images/sprites/spritesheets and commit only those assets plus provenance. Otherwise generate no art.

Write `.ai/inbox/codex-review.json` with `verdict` (`PASS` or `FAIL`), commands/results, commits reviewed, and findings. Every finding must include severity, file/symbol, observed behavior, expected behavior, and reproduction. Emit `REVIEW_PASS` only with objective evidence; otherwise emit `REVIEW_FAIL` so Claude/Cursor can repair it.
