---
description: Sync durable project memory for recent changes
agent: memory-curator
subtask: true
---

Synchronize active project memory for recent changes and optional scope `$ARGUMENTS`.

Goal:
- Use one default memory checkpoint after accepted work when durable repo truth changed, plus after refactors or cleanup.
- Decide whether the current change needs a focused feature update, a broader stale-memory review, or no durable memory update.
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
2. Treat this command as the default memory checkpoint after accepted work when durable repo truth changed, and after refactors, renames, or cleanup.
3. If the repo uses OpenSpec or another spec workflow, use the active or just-archived spec as context when helpful, but do not duplicate requirements, task lists, acceptance criteria, execution notes, or current status in memory.
4. Determine one mode before editing:
   - `feature-update` - a cohesive feature or iteration changed durable behavior and should create or refresh one main feature note.
   - `drift-review` - refactors, renames, deletions, cleanup, or broader cross-note staleness are likely and the active memory tree should be reviewed.
   - `no-memory-needed` - the change does not alter durable repo truth enough to justify memory edits.
5. Prefer `drift-review` when deleted files, renamed files, large refactors, or multi-area changes appear in the diff.
6. Prefer `no-memory-needed` when changes are limited to formatting, comments, snapshot churn, docs, tests that do not change durable behavior, local-only config, or memory notes that already match current truth.
7. If `$ARGUMENTS` gives a clear slug or scope, use it to sharpen the mode decision and note selection.
8. If the mode is `no-memory-needed`, do not edit files. Return a concise reason and say whether a later accepted behavior change should use `/sync-memory`, `/remember-feature`, or `/review-memory`.
9. If the mode is `feature-update`, follow the finished-feature workflow: normalize or infer a kebab-case slug, update the durable feature note, refresh related notes, and update shared memory only when reusable cross-feature context changed.
10. If the mode is `drift-review`, follow the stale-memory review workflow across notes touched by the changed files, deleted files, referenced modules, and likely stale signals.
11. Apply high-confidence rewrites and trims automatically.
12. Never delete active memory unless the user explicitly approved that deletion in the current conversation. Otherwise return a brief `Deletion review`.
13. Keep the result concise with:
   - `Mode`
   - `Updated notes`
   - `Deletion review`
   - `Gaps`
   - `Next step`
