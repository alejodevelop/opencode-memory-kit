# AI Memory Index

This directory stores compact, durable context for future OpenCode sessions.

It should describe the current truth of the repo. Historical context lives in Git.
It complements active specs instead of replacing them.

## How to use this memory

- If the repo uses OpenSpec or another spec workflow, read the active spec first for current scope, requirements, and status.
- Start here when a task depends on prior implementation context, durable constraints, recurring errors, or cross-session project knowledge.
- For default upkeep in OpenCode, run `/sync-memory [scope]`.
- If the repo uses OpenSpec or another spec workflow, run `/sync-memory [scope]` after each spec archive for accepted work, or say explicitly that no durable memory update is needed.
- For manual lookup in OpenCode, run `/recall-feature <query>`.
- To force a focused feature refresh, run `/remember-feature <slug>`.
- For forced cleanup after refactors or removals, run `/review-memory [scope]`.
- Search this directory by feature name, file path, module name, tag, or exact error text.
- Read only the matching notes.
- Rewrite or trim stale notes in place, and review deletions before removing obsolete notes from the active tree.

## Shared notes

- `decisions.md` - cross-feature decisions and constraints
- `troubleshooting.md` - reusable errors, root causes, and fixes
- `features/README.md` - feature-note conventions

## Features

- None recorded yet.
