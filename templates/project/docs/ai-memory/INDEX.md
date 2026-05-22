# AI Memory Index

This directory stores compact, durable context for future OpenCode sessions.

It should describe the current truth of the repo. Historical context lives in Git.
Use it to supplement active specs, not replace them.

## How to use this memory

- If the repo uses OpenSpec or another spec workflow, read the active spec first for current scope, requirements, and status.
- Start here when a task depends on prior implementation context, durable constraints, recurring errors, or cross-session project knowledge.
- Commands: `/sync-memory [scope]`, `/recall-feature <query>`, `/remember-feature <slug>`, `/review-memory [scope]`.
- Search this directory by feature name, file path, module name, tag, or exact error text.
- Read only the matching notes.

## Shared notes

- `decisions.md` - cross-feature decisions and constraints
- `troubleshooting.md` - reusable errors, root causes, and fixes
- `features/README.md` - feature-note conventions

## Features

- None recorded yet.
