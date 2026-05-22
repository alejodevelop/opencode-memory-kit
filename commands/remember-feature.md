---
description: Save and refresh durable memory for a finished feature
agent: memory-curator
subtask: true
---

Record durable project memory for the finished feature `$ARGUMENTS`.

Goal:
- Force a focused durable-memory refresh for one feature or implementation area.
- Save only the durable implementation context that should survive beyond the current spec or session.

Inputs:
- Feature slug or scope: `$ARGUMENTS`
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
!`git log --oneline -5`

Tasks:
1. If `docs/ai-memory/` does not exist, explain that project memory has not been bootstrapped yet and tell the user to run the bootstrap script from this kit before retrying.
2. Treat this as a focused `feature-update` using the current diff, changed files, deleted files, and `$ARGUMENTS`.
3. Normalize `$ARGUMENTS` to a kebab-case slug, or infer one from the finished work if missing.
4. Refresh the main feature note and any directly affected shared notes that still carry reusable context.
5. Keep pending removals in `Deletion review` unless they were explicitly approved in the current conversation.
6. If there is no meaningful durable information yet, say so instead of inventing memory.
