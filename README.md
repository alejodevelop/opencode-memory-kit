# OpenCode Memory Kit

Reusable durable-memory workflow for OpenCode projects.

This kit gives you two things:

- global OpenCode commands and agents for durable memory
- a lightweight bootstrap that installs per-project memory scaffolding

Goals:

- keep long-term project context inside each repo
- keep global OpenCode setup small and reusable
- avoid saturating model context with old session noise
- keep the main thread thin by leaning on OpenCode's built-in `explore` and `general` subagents

## What gets installed

Global commands and agents:

- `/sync-memory [scope]`
- `/remember-feature <slug>`
- `/recall-feature <query>`
- `/review-memory <scope>`
- `memory-curator`
- `memory-recall`

Project bootstrap files:

- `AGENTS.md`
- `docs/ai-memory/INDEX.md`
- `docs/ai-memory/decisions.md`
- `docs/ai-memory/troubleshooting.md`
- `docs/ai-memory/features/README.md`

`/sync-memory` is the default checkpoint. It decides between a focused feature update, a broader drift review, or no durable memory update.

## Quick start

Recommended setup: use the default OpenCode directories. Do not override `OPENCODE_CONFIG_DIR` for normal usage.

Install once from the public repo:

PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -Command "iwr https://raw.githubusercontent.com/alejodevelop/opencode-memory-kit/main/install.ps1 -UseBasicParsing | iex"
```

Unix shell:

```bash
curl -fsSL https://raw.githubusercontent.com/alejodevelop/opencode-memory-kit/main/install.sh | sh
```

Bootstrap each repo:

PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File "$HOME\.config\opencode\opencode-memory-kit\scripts\bootstrap-project.ps1" -Target .
```

Unix shell:

```bash
sh "$HOME/.config/opencode/opencode-memory-kit/scripts/bootstrap-project.sh" .
```

If the repo already has `AGENTS.md`, bootstrap only refreshes or appends the managed block between:

- `<!-- opencode-memory-kit:start -->`
- `<!-- opencode-memory-kit:end -->`

That preserves existing project-specific rules outside the managed block.

## Daily use

1. Work normally with `plan` and `build`.
2. Let OpenCode use `explore` for broad reading and `general` for multi-step execution.
3. After accepted work when durable repo truth changed, run `/sync-memory [scope]`.
4. In later sessions, run `/recall-feature <query>`.
5. Use `/remember-feature <slug>` to force a focused feature-note refresh.
6. Use `/review-memory [scope]` after broad refactors, removals, or cleanup.

If the repo uses OpenSpec or another spec workflow, the active spec remains the source of truth for requirements, planning, task tracking, and acceptance criteria. After each spec archive for accepted work, run `/sync-memory [scope]` or say explicitly that no durable memory update is needed.

Typical commands:

```text
/sync-memory auth-flow
/sync-memory
/remember-feature billing-webhook
/recall-feature auth
/recall-feature "TypeError fetch failed"
/review-memory "remove legacy billing"
```

## Upgrade

Update the installed kit:

PowerShell:

```powershell
$script = (iwr "https://raw.githubusercontent.com/alejodevelop/opencode-memory-kit/main/install.ps1" -UseBasicParsing).Content
& ([scriptblock]::Create($script)) -Force
```

Unix shell:

```bash
curl -fsSL https://raw.githubusercontent.com/alejodevelop/opencode-memory-kit/main/install.sh | sh -s -- --force
```

Then rerun bootstrap inside the repo:

PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File "$HOME\.config\opencode\opencode-memory-kit\scripts\bootstrap-project.ps1" -Target .
```

Unix shell:

```bash
sh "$HOME/.config/opencode/opencode-memory-kit/scripts/bootstrap-project.sh" .
```

Safe rerun behavior:

- refreshes the managed block in `AGENTS.md`
- creates missing scaffold files under `docs/ai-memory/`
- preserves existing saved notes and feature memory files
- uses `-Force` or `--force` only for the global kit reinstall step
- does not overwrite project memory unless you explicitly use `--force`

## Repo layout

```text
agents/                  Global OpenCode agents
commands/                Global OpenCode commands
templates/project/       Files copied into each target repo
scripts/                 Install and bootstrap scripts
```

## Advanced usage

Install from a local clone while developing the kit:

PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-global.ps1
```

Unix shell:

```bash
sh ./scripts/install-global.sh
```

`OPENCODE_CONFIG_DIR` is useful for development and testing, but it is not the recommended day-to-day setup.
