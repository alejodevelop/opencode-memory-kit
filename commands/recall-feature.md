---
description: Recall relevant project memory for a feature or topic
agent: memory-recall
subtask: true
---

Recall durable project memory for `$ARGUMENTS`.

Tasks:
1. If `docs/ai-memory/` does not exist, explain that project memory has not been bootstrapped yet and tell the user to run the bootstrap script from this kit.
2. If the repo uses OpenSpec or another spec workflow and `$ARGUMENTS` asks about current requirements, scope, task status, or acceptance criteria, say that the active spec should be checked first and use memory only as durable implementation context.
3. Start from `docs/ai-memory/INDEX.md`.
4. If `$ARGUMENTS` is empty, briefly summarize what project memory exists and what kinds of queries are supported.
5. Treat `docs/ai-memory/` as the active memory tree for the current truth of the repo.
6. Search `docs/ai-memory/**/*.md` for relevant feature names, file paths, modules, tags, decisions, and exact error strings related to `$ARGUMENTS`.
7. Read only the matching notes.
8. Return a concise synthesis with:
   - relevant behavior
   - important files
   - durable constraints or cross-feature decisions
   - reusable errors and fixes
9. If nothing relevant exists yet, say that clearly.
10. Do not update memory.
