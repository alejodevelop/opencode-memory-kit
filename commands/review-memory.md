---
description: Review and prune stale project memory
agent: memory-curator
subtask: true
---

Review the active project memory for `$ARGUMENTS`.

Goal:
- Run a focused stale-memory review for refactors, removals, or drift.
- Refresh or trim stale notes while keeping deletions review-only until approved.

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
2. Treat this as a focused `drift-review` using `$ARGUMENTS`, recent changes, deleted files, and related notes.
3. Refresh or trim what is clearly stale across the affected notes and shared memory files.
4. Keep pending removals in `Deletion review` unless they were explicitly approved in the current conversation.
5. Keep the report concise: automatic updates first, pending deletion review second, gaps last.
