---
description: Save durable memory for a finished feature
agent: memory-curator
subtask: true
---

Record durable project memory for the finished feature `$ARGUMENTS`.

Goal:
- Save the smallest useful long-term context for future sessions.
- Do not capture raw chat history or temporary implementation noise.

Inputs:
- Feature slug: `$ARGUMENTS`
- Git status:
!`git status --short`
- Changed files:
!`git diff --name-only`
!`git diff --cached --name-only`
- Diff summary:
!`git diff --stat`
!`git diff --cached --stat`
- Recent commits:
!`git log --oneline -5`

Tasks:
1. Read the existing memory files in `docs/ai-memory/`.
2. Read only the changed source files needed to understand the durable outcome.
3. Normalize `$ARGUMENTS` to a kebab-case slug, or infer one from the finished work if missing.
4. Create or update `docs/ai-memory/features/<normalized-slug>.md`.
5. Update `docs/ai-memory/INDEX.md`.
6. Update `docs/ai-memory/decisions.md` only for cross-feature decisions.
7. Update `docs/ai-memory/troubleshooting.md` only for reusable debugging knowledge.
8. If there is no meaningful durable information yet, say so instead of inventing memory.
