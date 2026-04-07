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
1. If `docs/ai-memory/` does not exist, explain that project memory has not been bootstrapped yet and tell the user to run the bootstrap script from this kit before retrying.
2. Read the existing memory files in `docs/ai-memory/`.
3. Read only the changed source files needed to understand the durable outcome.
4. Normalize `$ARGUMENTS` to a kebab-case slug, or infer one from the finished work if missing.
5. Create or update `docs/ai-memory/features/<normalized-slug>.md`.
6. Update `docs/ai-memory/INDEX.md`.
7. Update `docs/ai-memory/decisions.md` only for cross-feature decisions.
8. Update `docs/ai-memory/troubleshooting.md` only for reusable debugging knowledge.
9. If there is no meaningful durable information yet, say so instead of inventing memory.
