---
description: Recall relevant project memory for a feature or topic
agent: memory-recall
subtask: true
---

Recall durable project memory for `$ARGUMENTS`.

Start from @docs/ai-memory/INDEX.md.

Tasks:
1. If `$ARGUMENTS` is empty, briefly summarize what project memory exists and what kinds of queries are supported.
2. Search `docs/ai-memory/**/*.md` for relevant feature names, file paths, modules, tags, decisions, and exact error strings related to `$ARGUMENTS`.
3. Read only the matching notes.
4. Return a concise synthesis with:
   - relevant behavior
   - important files
   - decisions or constraints
   - reusable errors and fixes
5. If nothing relevant exists yet, say that clearly.
6. Do not update memory.
