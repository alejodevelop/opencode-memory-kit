# OpenCode Memory Kit

Reusable memory workflow for OpenCode projects.

This repo gives you two things:

- global OpenCode commands and agents for durable memory
- a lightweight bootstrap you can apply to any new repo

The goal is simple:

- keep long-term project context inside each project repo
- keep global OpenCode setup small and reusable
- avoid saturating model context with old session noise

## What gets installed globally

- `/remember-feature <slug>`
- `/recall-feature <query>`
- `/review-memory <scope>`
- `memory-curator` subagent
- `memory-recall` subagent

These are reusable across projects.

## What gets created per project

- `AGENTS.md`
- `docs/ai-memory/INDEX.md`
- `docs/ai-memory/decisions.md`
- `docs/ai-memory/troubleshooting.md`
- `docs/ai-memory/features/README.md`

This is the durable memory that lives in the project and should be committed to Git.

## Repo layout

```text
agents/                  Global OpenCode agents
commands/                Global OpenCode commands
templates/project/       Files copied into each target repo
scripts/                 Install and bootstrap scripts
```

## Recommended setup

Use the default OpenCode directories. Do not override `OPENCODE_CONFIG_DIR` for normal usage.

## Quick Start

1. Install the kit once.
2. Bootstrap each new repo once.
3. Use `/remember-feature`, `/recall-feature`, and `/review-memory` during normal work.

PowerShell install:

```powershell
powershell -ExecutionPolicy Bypass -Command "iwr https://raw.githubusercontent.com/alejodevelop/opencode-memory-kit/main/install.ps1 -UseBasicParsing | iex"
```

Bootstrap the current repo:

```powershell
powershell -ExecutionPolicy Bypass -File "$HOME\.config\opencode\opencode-memory-kit\scripts\bootstrap-project.ps1" -Target .
```

Typical usage:

```text
/remember-feature auth-flow
/recall-feature auth
/review-memory auth
```

That is the core flow. Use `/review-memory` after large refactors, removals, or cleanup passes.

### One-command install from a public repo

No clone is required.

PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -Command "iwr https://raw.githubusercontent.com/alejodevelop/opencode-memory-kit/main/install.ps1 -UseBasicParsing | iex"
```

Unix shell:

```bash
curl -fsSL https://raw.githubusercontent.com/alejodevelop/opencode-memory-kit/main/install.sh | sh
```

This installs into the default OpenCode locations:

- `~/.config/opencode/agents/`
- `~/.config/opencode/commands/`
- `~/.config/opencode/opencode-memory-kit/`

You can rerun the same command later to update the installed kit.

## Bootstrap a new repo

After you create a new frontend or backend repo, seed the local memory files.

PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File "$HOME\.config\opencode\opencode-memory-kit\scripts\bootstrap-project.ps1" -Target .
```

Unix shell:

```bash
sh "$HOME/.config/opencode/opencode-memory-kit/scripts/bootstrap-project.sh" .
```

### Existing `AGENTS.md`

If the target repo already has an `AGENTS.md`, the bootstrap script does not replace it.

Instead, it appends a marked memory block:

- `<!-- opencode-memory-kit:start -->`
- `<!-- opencode-memory-kit:end -->`

This avoids clobbering existing project rules.

## Daily workflow inside a project

1. Bootstrap the repo once.
2. Work normally with `plan` and `build`.
3. When a feature is accepted, run `/remember-feature <slug>`.
4. In later sessions, run `/recall-feature <query>`.
5. After large refactors, removals, or cleanup passes, run `/review-memory [scope]`.

Examples:

```text
/remember-feature auth-flow
/remember-feature billing-webhook
/recall-feature auth
/recall-feature "TypeError fetch failed"
/review-memory auth
/review-memory "remove legacy billing"
```

## Memory lifecycle

- `docs/ai-memory/` is the active memory tree for the current truth of the repo.
- `/remember-feature` auto-refreshes related notes when the latest change makes older details stale.
- `/review-memory` is the broader cleanup pass for refactors, removals, and accumulated drift.
- High-confidence rewrites and trims can be applied automatically.
- Deletions require a brief review before anything is removed from the active memory tree.
- Git history is the archive for old context; obsolete notes should not stay in `docs/ai-memory/`.

## Design choices

- Global commands and agents are reusable.
- Project memory stays local to each repo.
- Memory is lazy-loaded through `AGENTS.md` and `docs/ai-memory/INDEX.md`.
- The stored notes are short, searchable, and Git-tracked.
- The active memory tree stays focused on current truth, while Git preserves history.

## Notes

- `docs/ai-memory/` is intentionally not injected into OpenCode global instructions.
- If you run `/remember-feature`, `/recall-feature`, or `/review-memory` in a repo that has not been bootstrapped yet, the command will tell you what is missing.
- Use `--force` with the bootstrap scripts only when you want to overwrite existing template files under `docs/ai-memory/`.

## Advanced usage

### Install from a local clone

If you are developing this kit locally, you can still install it from the checked-out repo.

PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-global.ps1
```

Unix shell:

```bash
sh ./scripts/install-global.sh
```

### Use `OPENCODE_CONFIG_DIR`

This is useful for development and testing the kit itself, but it is not the recommended day-to-day setup.
