---
description: Sync durable project memory for recent changes
agent: memory-curator
subtask: true
---

Synchronize active project memory for recent changes and optional scope `$ARGUMENTS`.

Goal:
- Run the default durable-memory checkpoint for recent changes.
- Keep `docs/ai-memory/` aligned with the current truth of the repo without adding busywork.

Inputs:
- Optional scope or hint: `$ARGUMENTS`
- Git status:
!`git status --short`
- Changed files with status:
!`git diff --name-status`
!`git diff --cached --name-status`
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
1. If `docs/ai-memory/` does not exist, explain that project memory has not been bootstrapped yet and tell the user to run the bootstrap script from this kit before retrying.
2. Treat this as the default checkpoint after accepted work, refactors, renames, deletions, or cleanup.
3. Use the provided git context and optional scope to run the normal `memory-curator` workflow and choose the right operating mode.
4. If `$ARGUMENTS` gives a clear slug or scope, use it to sharpen note selection.
5. Keep pending removals in `Deletion review` unless they were explicitly approved in the current conversation.
6. Keep the result concise with:
   - `Mode`
   - `Updated notes`
   - `Deletion review`
   - `Gaps`
   - `Next step`
