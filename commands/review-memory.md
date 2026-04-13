---
description: Review and prune stale project memory
agent: memory-curator
subtask: true
---

Review the active project memory for `$ARGUMENTS`.

Goal:
- Find stale memory caused by refactors, removals, or drift.
- Automatically rewrite or trim notes that can be safely refreshed.
- Require a brief user review before deleting active memory.

Inputs:
- Review scope: `$ARGUMENTS`
- Git status:
!`git status --short`
- Changed files:
!`git diff --name-only`
!`git diff --cached --name-only`
- Deleted files:
!`git diff --name-only --diff-filter=D`
!`git diff --cached --name-only --diff-filter=D`
- Diff summary:
!`git diff --stat`
!`git diff --cached --stat`
- Recent commits:
!`git log --oneline -10`

Tasks:
1. If `docs/ai-memory/` does not exist, explain that project memory has not been bootstrapped yet and tell the user to run the bootstrap script from this kit.
2. Treat `$ARGUMENTS` as an optional scope. If it is empty, review the memory touched by recent changes first, then expand only if needed.
3. Read `docs/ai-memory/INDEX.md`, `docs/ai-memory/decisions.md`, `docs/ai-memory/troubleshooting.md`, and only the relevant feature notes.
4. Scan the notes that match the scope, changed files, deleted files, referenced modules, slugs, or likely stale signals.
5. Classify each candidate as `keep`, `rewrite`, `trim`, or `delete`.
6. Apply high-confidence rewrites and trims immediately.
7. Update `docs/ai-memory/INDEX.md` whenever active feature notes change.
8. If delete candidates exist and the user has not explicitly approved them in the current conversation, return a brief `Deletion review` with item IDs, exact targets, reasons, and recommended deletes.
9. If the user explicitly approved specific item IDs or exact targets in the current conversation, delete only those approved items and update `docs/ai-memory/INDEX.md` plus any cross-references.
10. Keep the report concise: automatic updates first, pending deletion review second, gaps last.
