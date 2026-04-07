---
description: Recall relevant project memory for a feature or topic
agent: memory-recall
subtask: true
---

Recall durable project memory for `$ARGUMENTS`.

Tasks:
1. If `docs/ai-memory/` does not exist, explain that project memory has not been bootstrapped yet and tell the user to run the bootstrap script from this kit.
2. Start from `docs/ai-memory/INDEX.md`.
3. If `$ARGUMENTS` is empty, briefly summarize what project memory exists and what kinds of queries are supported.
4. Search `docs/ai-memory/**/*.md` for relevant feature names, file paths, modules, tags, decisions, and exact error strings related to `$ARGUMENTS`.
5. Read only the matching notes.
6. Return a concise synthesis with:
   - relevant behavior
   - important files
   - decisions or constraints
   - reusable errors and fixes
7. If nothing relevant exists yet, say that clearly.
8. Do not update memory.
