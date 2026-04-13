---
description: Save and refresh durable memory for a finished feature
agent: memory-curator
subtask: true
---

Record durable project memory for the finished feature `$ARGUMENTS`.

Goal:
- Save the smallest useful long-term context for future sessions.
- Keep related memory aligned with the current truth of the codebase.
- Do not capture raw chat history or temporary implementation noise.

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
2. Read the existing memory files in `docs/ai-memory/`.
3. Use the current diff, changed files, deleted files, and the provided slug to identify related memory notes that may now be stale.
4. Read only the changed source files and affected memory notes needed to understand the durable outcome.
5. Normalize `$ARGUMENTS` to a kebab-case slug, or infer one from the finished work if missing.
6. Create or update `docs/ai-memory/features/<normalized-slug>.md`.
7. Rewrite or trim other affected memory notes when the current change invalidates stale details.
8. Update `docs/ai-memory/INDEX.md` so it lists only the active feature notes.
9. Update `docs/ai-memory/decisions.md` only for cross-feature decisions that still apply.
10. Update `docs/ai-memory/troubleshooting.md` only for reusable debugging knowledge that still applies.
11. Apply high-confidence rewrites and trims automatically.
12. If a note or entry should be removed from active memory, do not delete it yet unless the user explicitly approved that deletion in the current conversation. Instead, return a short `Deletion review` with item IDs, exact targets, and reasons.
13. If the user explicitly approved specific deletions in the current conversation, delete only those approved items and update `docs/ai-memory/INDEX.md` plus any broken references.
14. If there is no meaningful durable information yet, say so instead of inventing memory.
