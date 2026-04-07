param(
    [string]$ConfigDir = (Join-Path $HOME ".config\opencode"),
    [switch]$Force
)

$ErrorActionPreference = "Stop"

function Write-Utf8NoBomFile {
    param(
        [string]$Path,
        [string]$Content
    )

    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $encoding)
}

function Install-Asset {
    param(
        [string]$RelativePath,
        [string]$Content
    )

    $destination = Join-Path $ConfigDir $RelativePath
    $destinationDir = Split-Path -Parent $destination

    if ($destinationDir -and -not (Test-Path $destinationDir)) {
        New-Item -ItemType Directory -Force -Path $destinationDir | Out-Null
    }

    $exists = Test-Path $destination
    if ($exists -and -not $Force) {
        Write-Host "Skipped $RelativePath"
        return
    }

    Write-Utf8NoBomFile -Path $destination -Content $Content
    if ($exists) {
        Write-Host "Updated $RelativePath"
    }
    else {
        Write-Host "Created $RelativePath"
    }
}

$assets = @(
    @{
        Path = "agents\memory-curator.md"
        Content = @'
---
description: Curates durable project memory after a feature is finished
mode: subagent
permission:
  bash:
    "*": deny
  webfetch: deny
---

You maintain compact, durable project memory under `docs/ai-memory/`.

Your job is to convert completed work into reusable context without bloating future prompts.

Workflow:
1. Read `docs/ai-memory/INDEX.md`, `docs/ai-memory/decisions.md`, `docs/ai-memory/troubleshooting.md`, and `docs/ai-memory/features/README.md`.
2. Use the command-provided feature slug and git summary as the primary source of scope.
3. Normalize the slug to kebab-case, or infer one from the finished work if needed.
4. Read only the changed project files needed to understand the durable outcome.
5. Create or update `docs/ai-memory/features/<slug>.md`.
6. Update `docs/ai-memory/INDEX.md` so the feature list stays current.
7. Update shared notes only when the information will matter outside this single feature.

Capture only durable information:
- implemented behavior or constraints
- file paths, modules, or entry points future work must know
- decisions and tradeoffs that future sessions should preserve
- exact error messages, root causes, and fixes when reusable

Avoid:
- raw chat transcripts
- temporary TODOs or abandoned ideas
- verbose diff narration
- temporary commands or tool output
- duplicate notes

File conventions:
- keep notes concise and searchable
- use short bullet lists
- prefer exact file paths in backticks
- use exact error strings in backticks
- use kebab-case filenames for feature notes
- update existing sections instead of appending near-duplicates

Feature note template:

# <Feature Title>

## Summary
- What now exists and why it matters.

## Files
- `path/to/file` - why it matters.

## Decisions
- Durable decision and rationale.

## Errors and fixes
- Symptom: `exact error or signal`
- Root cause: ...
- Fix: ...

## Follow-ups
- Only if a real, durable constraint remains.

If the prompt does not provide a clean slug, infer one. If the durable intent is still ambiguous after reading the relevant files, ask one short clarifying question.
'@
    },
    @{
        Path = "agents\memory-recall.md"
        Content = @'
---
description: Recalls relevant durable project memory for a task or feature
mode: subagent
permission:
  edit: deny
  bash:
    "*": deny
  webfetch: deny
---

You search `docs/ai-memory/` and return only the durable context relevant to the caller's query.

Workflow:
1. Start with `docs/ai-memory/INDEX.md`.
2. Use `grep` on `docs/ai-memory/**/*.md` for the query terms, feature names, file paths, modules, tags, and exact error strings.
3. Read only the matching notes.
4. Synthesize the smallest useful answer for the caller.

Output:
- `Matches` - the memory notes that were relevant.
- `Relevant context` - implemented behavior or project knowledge that matters now.
- `Files` - exact file paths when the memory references them.
- `Decisions` - durable constraints or tradeoffs to preserve.
- `Troubleshooting` - exact recurring errors and fixes when relevant.
- `Gaps` - clearly state if the memory does not answer something.

Rules:
- If there are no relevant matches, say so clearly.
- Do not restate full notes when a short synthesis is enough.
- Prefer exact file paths and exact error strings in backticks.
- Do not modify any files.
'@
    },
    @{
        Path = "commands\remember-feature.md"
        Content = @'
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
'@
    },
    @{
        Path = "commands\recall-feature.md"
        Content = @'
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
'@
    },
    @{
        Path = "opencode-memory-kit\scripts\bootstrap-project.ps1"
        Content = @'
param(
    [string]$Target = ".",
    [switch]$Force
)

$ErrorActionPreference = "Stop"

function Write-Utf8NoBomFile {
    param(
        [string]$Path,
        [string]$Content
    )

    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $encoding)
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir
$templateRoot = Join-Path $repoRoot "templates\project"
$docsTemplateRoot = Join-Path $templateRoot "docs"
$fullAgentsTemplate = Join-Path $templateRoot "AGENTS.md"
$appendAgentsTemplate = Join-Path $templateRoot "AGENTS.memory.md"
$marker = "opencode-memory-kit:start"

if (-not (Test-Path -Path $Target -PathType Container)) {
    throw "Target directory does not exist: $Target"
}

$resolvedTarget = (Resolve-Path $Target).Path
$targetAgents = Join-Path $resolvedTarget "AGENTS.md"

if (Test-Path $targetAgents) {
    $current = [System.IO.File]::ReadAllText($targetAgents)
    if ($current.Contains($marker)) {
        Write-Host "Skipped AGENTS.md (memory workflow already present)"
    }
    else {
        $appendBlock = [System.IO.File]::ReadAllText($appendAgentsTemplate)
        $separator = if ($current.EndsWith("`n")) { "`r`n" } else { "`r`n`r`n" }
        Write-Utf8NoBomFile -Path $targetAgents -Content ($current + $separator + $appendBlock)
        Write-Host "Updated AGENTS.md (appended memory workflow block)"
    }
}
else {
    Copy-Item $fullAgentsTemplate $targetAgents
    Write-Host "Created AGENTS.md"
}

Get-ChildItem -File -Recurse $docsTemplateRoot | ForEach-Object {
    $sourcePath = $_.FullName
    $relativePath = $sourcePath.Substring($templateRoot.Length + 1)
    $destination = Join-Path $resolvedTarget $relativePath
    $destinationDir = Split-Path -Parent $destination

    if ($destinationDir -and -not (Test-Path $destinationDir)) {
        New-Item -ItemType Directory -Force -Path $destinationDir | Out-Null
    }

    $exists = Test-Path $destination
    if ($exists -and -not $Force) {
        Write-Host "Skipped $relativePath"
    }
    else {
        Copy-Item $sourcePath $destination -Force
        if ($exists) {
            Write-Host "Updated $relativePath"
        }
        else {
            Write-Host "Created $relativePath"
        }
    }
}

Write-Host ""
Write-Host "Project memory workflow is ready in $resolvedTarget"
Write-Host "Next steps:"
Write-Host "  1. Open the project in OpenCode"
Write-Host "  2. Build as usual"
Write-Host "  3. Run /remember-feature <slug> when a feature is accepted"
Write-Host "  4. Run /recall-feature <query> in future sessions"
'@
    },
    @{
        Path = "opencode-memory-kit\scripts\bootstrap-project.sh"
        Content = @'
#!/usr/bin/env sh
set -eu

target="."
force="0"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --force)
      force="1"
      ;;
    -h|--help)
      printf '%s\n' "Usage: sh scripts/bootstrap-project.sh [target-dir] [--force]"
      exit 0
      ;;
    *)
      target="$1"
      ;;
  esac
  shift
done

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(dirname "$script_dir")
template_root="$repo_root/templates/project"
docs_template_root="$template_root/docs"
full_agents_template="$template_root/AGENTS.md"
append_agents_template="$template_root/AGENTS.memory.md"
marker="opencode-memory-kit:start"

if [ ! -d "$target" ]; then
  printf '%s\n' "Target directory does not exist: $target" >&2
  exit 1
fi

target=$(CDPATH= cd -- "$target" && pwd)
target_agents="$target/AGENTS.md"

if [ -f "$target_agents" ]; then
  if grep -q "$marker" "$target_agents"; then
    printf '%s\n' "Skipped AGENTS.md (memory workflow already present)"
  else
    printf '\n\n' >> "$target_agents"
    cat "$append_agents_template" >> "$target_agents"
    printf '%s\n' "Updated AGENTS.md (appended memory workflow block)"
  fi
else
  cp "$full_agents_template" "$target_agents"
  printf '%s\n' "Created AGENTS.md"
fi

find "$docs_template_root" -type f | sort | while IFS= read -r source_path; do
  relative_path=${source_path#"$template_root/"}
  destination="$target/$relative_path"
  destination_dir=$(dirname "$destination")

  mkdir -p "$destination_dir"

  if [ -f "$destination" ] && [ "$force" != "1" ]; then
    printf '%s\n' "Skipped $relative_path"
    continue
  fi

  if [ -f "$destination" ]; then
    cp "$source_path" "$destination"
    printf '%s\n' "Updated $relative_path"
  else
    cp "$source_path" "$destination"
    printf '%s\n' "Created $relative_path"
  fi
done

printf '\n'
printf '%s\n' "Project memory workflow is ready in $target"
printf '%s\n' "Next steps:"
printf '%s\n' "  1. Open the project in OpenCode"
printf '%s\n' "  2. Build as usual"
printf '%s\n' "  3. Run /remember-feature <slug> when a feature is accepted"
printf '%s\n' "  4. Run /recall-feature <query> in future sessions"
'@
    },
    @{
        Path = "opencode-memory-kit\templates\project\AGENTS.md"
        Content = @'
# Project Instructions

<!-- opencode-memory-kit:start -->
## Project Memory Workflow

This project uses a durable AI memory layer stored in `docs/ai-memory/`.

### Persistent Memory

- Use `docs/ai-memory/INDEX.md` as the entry point.
- For explicit manual lookup, use `/recall-feature <query>`.
- Memory is intentionally lazy-loaded. Do not read every file in `docs/ai-memory/` by default.
- When a task mentions existing functionality, prior decisions, regressions, previous bugs, or continuing work from a past session:
  1. Read `docs/ai-memory/INDEX.md`.
  2. Use `grep` on `docs/ai-memory/**/*.md` for relevant feature names, file paths, tags, and error strings.
  3. Read only the matching notes.
- Prefer `docs/ai-memory/features/*.md` for feature-specific implementation context.
- Prefer `docs/ai-memory/decisions.md` for durable cross-feature decisions and constraints.
- Prefer `docs/ai-memory/troubleshooting.md` for recurring errors, exact messages, root causes, and fixes.

### Updating Memory

- After a feature is implemented, iterated on, and accepted, persist durable context with `/remember-feature <kebab-case-slug>`.
- The memory update should capture only long-lived project knowledge:
  - relevant behavior now implemented
  - important files or modules touched
  - decisions that future work must respect
  - reusable debugging knowledge
- Do not store raw conversation logs, temporary speculation, or large diff narration.

### Memory Quality Bar

- Keep notes concise and searchable.
- Include exact file paths and exact error strings when useful.
- Update existing notes in place instead of creating duplicates.
<!-- opencode-memory-kit:end -->
'@
    },
    @{
        Path = "opencode-memory-kit\templates\project\AGENTS.memory.md"
        Content = @'
<!-- opencode-memory-kit:start -->
## Project Memory Workflow

This project uses a durable AI memory layer stored in `docs/ai-memory/`.

### Persistent Memory

- Use `docs/ai-memory/INDEX.md` as the entry point.
- For explicit manual lookup, use `/recall-feature <query>`.
- Memory is intentionally lazy-loaded. Do not read every file in `docs/ai-memory/` by default.
- When a task mentions existing functionality, prior decisions, regressions, previous bugs, or continuing work from a past session:
  1. Read `docs/ai-memory/INDEX.md`.
  2. Use `grep` on `docs/ai-memory/**/*.md` for relevant feature names, file paths, tags, and error strings.
  3. Read only the matching notes.
- Prefer `docs/ai-memory/features/*.md` for feature-specific implementation context.
- Prefer `docs/ai-memory/decisions.md` for durable cross-feature decisions and constraints.
- Prefer `docs/ai-memory/troubleshooting.md` for recurring errors, exact messages, root causes, and fixes.

### Updating Memory

- After a feature is implemented, iterated on, and accepted, persist durable context with `/remember-feature <kebab-case-slug>`.
- The memory update should capture only long-lived project knowledge:
  - relevant behavior now implemented
  - important files or modules touched
  - decisions that future work must respect
  - reusable debugging knowledge
- Do not store raw conversation logs, temporary speculation, or large diff narration.

### Memory Quality Bar

- Keep notes concise and searchable.
- Include exact file paths and exact error strings when useful.
- Update existing notes in place instead of creating duplicates.
<!-- opencode-memory-kit:end -->
'@
    },
    @{
        Path = "opencode-memory-kit\templates\project\docs\ai-memory\INDEX.md"
        Content = @'
# AI Memory Index

This directory stores compact, durable context for future OpenCode sessions.

## How to use this memory

- Start here when a task depends on prior project work.
- For manual lookup in OpenCode, run `/recall-feature <query>`.
- Search this directory by feature name, file path, module name, tag, or exact error text.
- Read only the matching notes.

## Shared notes

- `decisions.md` - cross-feature decisions and constraints
- `troubleshooting.md` - reusable errors, root causes, and fixes
- `features/README.md` - feature-note conventions

## Features

- None recorded yet.
'@
    },
    @{
        Path = "opencode-memory-kit\templates\project\docs\ai-memory\decisions.md"
        Content = @'
# Decisions

Cross-feature decisions and constraints that future work should preserve.

## How to add entries

- Add only decisions that affect more than one future task or module.
- Prefer one short subsection per decision.
- Link affected files when possible.

## Entries

- None recorded yet.
'@
    },
    @{
        Path = "opencode-memory-kit\templates\project\docs\ai-memory\troubleshooting.md"
        Content = @'
# Troubleshooting

Reusable debugging knowledge for this project.

## How to add entries

- Record only issues that are likely to recur.
- Prefer exact symptoms in backticks.
- Include root cause and fix.

## Entries

- None recorded yet.
'@
    },
    @{
        Path = "opencode-memory-kit\templates\project\docs\ai-memory\features\README.md"
        Content = @'
# Feature Notes

Create one file per accepted feature using a kebab-case slug.

## When to create a feature note

- The feature changed durable project behavior.
- Future work will benefit from remembering touched files, constraints, or fixes.

## Recommended structure

- `# <Feature Title>`
- `## Summary`
- `## Files`
- `## Decisions`
- `## Errors and fixes`
- `## Follow-ups`

Record durable knowledge only. Avoid raw diff summaries and transient chat context.
'@
    }
)

foreach ($asset in $assets) {
    Install-Asset -RelativePath $asset.Path -Content $asset.Content
}

$bootstrapPath = Join-Path $ConfigDir "opencode-memory-kit\scripts\bootstrap-project.ps1"

Write-Host ""
Write-Host "OpenCode memory kit installed under $ConfigDir"
Write-Host "Installed into default OpenCode locations:"
Write-Host "  - agents/"
Write-Host "  - commands/"
Write-Host "  - opencode-memory-kit/"
Write-Host ""
Write-Host "Bootstrap a new repo with:"
Write-Host ('  powershell -ExecutionPolicy Bypass -File "{0}" -Target .' -f $bootstrapPath)
