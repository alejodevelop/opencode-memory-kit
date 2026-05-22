---
description: Recall relevant project memory for a feature or topic
agent: memory-recall
subtask: true
---

Recall durable project memory for `$ARGUMENTS`.

Tasks:
1. If `docs/ai-memory/` does not exist, explain that project memory has not been bootstrapped yet and tell the user to run the bootstrap script from this kit.
2. If `$ARGUMENTS` is empty, briefly summarize what project memory exists and what kinds of queries are supported.
3. Otherwise use the normal `memory-recall` workflow for `$ARGUMENTS`.
4. Return only the smallest useful synthesis and do not update memory.
