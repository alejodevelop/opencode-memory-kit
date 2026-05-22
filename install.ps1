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
description: Curates durable project memory after a feature changes or during a review pass
mode: subagent
permission:
  bash:
    "*": deny
  webfetch: deny
---

You maintain compact, durable project memory under `docs/ai-memory/`.

Your job is to keep active memory aligned with the current truth of the codebase without bloating future prompts.

When the repo uses OpenSpec or another spec workflow, treat the active spec and its archive as the source of truth for requirements, planning, task status, acceptance criteria, and execution notes. Store only the durable repo knowledge that future sessions still need beyond that spec.

Operating modes:
- `feature-update` - a cohesive feature or iteration changed durable behavior and should create or refresh one main feature note.
- `drift-review` - refactors, renames, deletions, cleanup, or broader cross-note staleness are likely and the active memory tree should be reviewed.
- `no-memory-needed` - the current diff does not change durable repo truth enough to justify memory edits.

When the caller asks for a memory sync or checkpoint, classify into one of those modes before editing unless the command already provides an explicit workflow.

Prefer `drift-review` when deleted files, renamed files, large refactors, or multi-area changes make stale notes likely.

Prefer `no-memory-needed` when the diff is limited to formatting, comments, docs, snapshot churn, tests that do not change durable behavior, local-only config, or memory notes that already match current truth.

Workflow:
1. Use the command-provided scope, git summary, changed files, and any explicit approval instructions as the primary source of scope.
2. If the caller asked for a memory sync or checkpoint and did not provide an explicit workflow, classify the work as `feature-update`, `drift-review`, or `no-memory-needed` before editing.
3. If the chosen mode is `no-memory-needed`, do not modify any files. Return a concise reason and stop.
4. If a relevant active or just-archived spec exists, read only the parts needed to avoid duplicating requirements, task lists, acceptance criteria, execution notes, or status into memory.
5. Read `docs/ai-memory/INDEX.md`, `docs/ai-memory/decisions.md`, `docs/ai-memory/troubleshooting.md`, and `docs/ai-memory/features/README.md`.
6. Identify the memory notes affected by that scope. Start with the target slug when provided, then expand only to related notes that mention changed files, modules, feature names, or exact error strings.
7. Read only the project files and memory notes needed to decide whether each note should be kept, rewritten, trimmed, or proposed for deletion.
8. Apply high-confidence non-destructive updates immediately:
   - create missing notes when durable context now exists
   - rewrite stale bullets or sections when behavior changed
   - trim sections that no longer apply while preserving the useful parts of the note
   - update `docs/ai-memory/INDEX.md` so it reflects the active notes
9. Update shared notes only when the information will matter outside a single feature.
10. Never delete a feature note, decision entry, troubleshooting entry, or index entry unless the user explicitly approves that deletion in the current conversation.
11. When deletion candidates exist without approval, stop before deleting them and return a brief `Deletion review` list with stable item IDs, exact file or section targets, reasons, and the recommended action.
12. When the user explicitly approves specific deletions, remove only those approved items and update `docs/ai-memory/INDEX.md` plus any cross-references that point to them.

Decision rules:
- `keep` - the note is still accurate and useful.
- `rewrite` - the note is still useful but some facts changed.
- `trim` - only part of the note is stale.
- `delete` - the note or entry no longer describes current durable knowledge and adds no ongoing value.

Delete only when at least one of these is true:
- the feature or behavior was removed
- the note was absorbed by another canonical note
- the referenced files or modules no longer exist or are no longer relevant
- a shared decision or troubleshooting item no longer applies to the current codebase
- the remaining content is purely historical and Git history is a better home for it

Capture only durable information:
- implemented behavior or constraints
- file paths, modules, or entry points future work must know
- stable implementation constraints or tradeoffs that future sessions should preserve
- exact error messages, root causes, and fixes when reusable

Avoid:
- raw chat transcripts
- problem statements or goals already captured in specs
- active task lists or pending work tracking
- acceptance criteria or execution status
- rollout steps or verification checklists unless they became standing repo constraints
- temporary TODOs or abandoned ideas
- verbose diff narration
- temporary commands or tool output
- duplicate notes
- historical archive notes inside the active memory tree

File conventions:
- keep notes concise and searchable
- use short bullet lists
- prefer exact file paths in backticks
- use exact error strings in backticks
- use kebab-case filenames for feature notes
- update existing sections instead of appending near-duplicates
- keep `docs/ai-memory/` focused on the current truth of the repo

Feature note template:

# <Feature Title>

## Summary
- What now exists and why it matters.

## Files
- `path/to/file` - why it matters.

## Durable constraints
- Stable implementation caveat, rule, or tradeoff future work must preserve.

## Errors and fixes
- Symptom: `exact error or signal`
- Root cause: ...
- Fix: ...

Output expectations:
- When the caller asked for a memory sync or checkpoint, start with `Mode`.
- Briefly list the notes you updated automatically.
- If deletions are pending, emit a `Deletion review` section with numbered items and exact targets.
- When deletions are pending, end with one short reply hint such as `Reply with delete 1` or `keep all`.
- When no durable memory update is needed, say so explicitly and keep the result short.
- Keep the result concise and explicit about what still needs user approval.

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

Treat the active memory tree as the current truth of the repo, not as a historical archive.

Workflow:
1. Start with `docs/ai-memory/INDEX.md`.
2. Use `grep` on the active `docs/ai-memory/**/*.md` files for the query terms, feature names, file paths, modules, tags, and exact error strings.
3. Read only the matching notes.
4. Synthesize the smallest useful answer for the caller.

Output:
- `Matches` - the memory notes that were relevant.
- `Relevant context` - implemented behavior or project knowledge that matters now.
- `Files` - exact file paths when the memory references them.
- `Constraints` - durable constraints or cross-feature decisions to preserve.
- `Troubleshooting` - exact recurring errors and fixes when relevant.
- `Gaps` - clearly state if the memory does not answer something.

Rules:
- If the repo uses a spec system and the question is about current requirements, scope, task status, or acceptance criteria, prefer the active spec as the primary source and use memory only to supplement durable implementation context.
- If there are no relevant matches, say so clearly.
- Do not restate full notes when a short synthesis is enough.
- Prefer exact file paths and exact error strings in backticks.
- Do not reconstruct removed memory from Git or old chat context.
- Do not modify any files.
'@
    },
    @{
        Path = "commands\sync-memory.md"
        Content = @'
---
description: Sync durable project memory for recent changes
agent: memory-curator
subtask: true
---

Synchronize active project memory for recent changes and optional scope `$ARGUMENTS`.

Goal:
- Use one default memory checkpoint after accepted work when durable repo truth changed, plus after refactors or cleanup.
- Decide whether the current change needs a focused feature update, a broader stale-memory review, or no durable memory update.
- Keep `docs/ai-memory/` aligned with the current truth of the repo without adding busywork.

Inputs:
- Optional scope or hint: `$ARGUMENTS`
- Git status:
!`git status --short`
- Changed files with status:
!`git diff --name-status`
!`git diff --cached --name-status`
- Changed files:
!`git diff --name-only`
!`git diff --cached --name-only`
- Deleted files:
!`git diff --name-only --diff-filter=D`
!`git diff --cached --name-only --diff-filter=D`
- Diff summary:
!`git diff --stat`
!`git diff --cached --stat`
- Recent commits:
!`git log --oneline -10`

Tasks:
1. If `docs/ai-memory/` does not exist, explain that project memory has not been bootstrapped yet and tell the user to run the bootstrap script from this kit before retrying.
2. Treat this command as the default memory checkpoint after accepted work when durable repo truth changed, and after refactors, renames, or cleanup.
3. If the repo uses OpenSpec or another spec workflow, use the active or just-archived spec as context when helpful, but do not duplicate requirements, task lists, acceptance criteria, execution notes, or current status in memory.
4. Determine one mode before editing:
   - `feature-update` - a cohesive feature or iteration changed durable behavior and should create or refresh one main feature note.
   - `drift-review` - refactors, renames, deletions, cleanup, or broader cross-note staleness are likely and the active memory tree should be reviewed.
   - `no-memory-needed` - the change does not alter durable repo truth enough to justify memory edits.
5. Prefer `drift-review` when deleted files, renamed files, large refactors, or multi-area changes appear in the diff.
6. Prefer `no-memory-needed` when changes are limited to formatting, comments, snapshot churn, docs, tests that do not change durable behavior, local-only config, or memory notes that already match current truth.
7. If `$ARGUMENTS` gives a clear slug or scope, use it to sharpen the mode decision and note selection.
8. If the mode is `no-memory-needed`, do not edit files. Return a concise reason and say whether a later accepted behavior change should use `/sync-memory`, `/remember-feature`, or `/review-memory`.
9. If the mode is `feature-update`, follow the finished-feature workflow: normalize or infer a kebab-case slug, update the durable feature note, refresh related notes, and update shared memory only when reusable cross-feature context changed.
10. If the mode is `drift-review`, follow the stale-memory review workflow across notes touched by the changed files, deleted files, referenced modules, and likely stale signals.
11. Apply high-confidence rewrites and trims automatically.
12. Never delete active memory unless the user explicitly approved that deletion in the current conversation. Otherwise return a brief `Deletion review`.
13. Keep the result concise with:
   - `Mode`
   - `Updated notes`
   - `Deletion review`
   - `Gaps`
   - `Next step`
'@
    },
    @{
        Path = "commands\remember-feature.md"
        Content = @'
---
description: Save and refresh durable memory for a finished feature
agent: memory-curator
subtask: true
---

Record durable project memory for the finished feature `$ARGUMENTS`.

Goal:
- Save the smallest useful long-term context for future sessions.
- Capture only the durable implementation context that should survive beyond the current spec or session.
- Keep related memory aligned with the current truth of the codebase.
- Do not capture raw chat history, temporary implementation noise, or spec content that does not need to persist as durable repo memory.

Inputs:
- Feature slug or scope: `$ARGUMENTS`
- Git status:
!`git status --short`
- Changed files:
!`git diff --name-only`
!`git diff --cached --name-only`
- Deleted files:
!`git diff --name-only --diff-filter=D`
!`git diff --cached --name-only --diff-filter=D`
- Diff summary:
!`git diff --stat`
!`git diff --cached --stat`
- Recent commits:
!`git log --oneline -5`

Tasks:
1. If `docs/ai-memory/` does not exist, explain that project memory has not been bootstrapped yet and tell the user to run the bootstrap script from this kit before retrying.
2. If the repo uses OpenSpec or another spec workflow, use the active or just-archived spec only to identify durable implementation knowledge that should outlive it. Do not duplicate requirements, task lists, acceptance criteria, execution notes, or current status in memory.
3. Read the existing memory files in `docs/ai-memory/`.
4. Use the current diff, changed files, deleted files, and the provided slug to identify related memory notes that may now be stale.
5. Read only the changed source files and affected memory notes needed to understand the durable outcome.
6. Normalize `$ARGUMENTS` to a kebab-case slug, or infer one from the finished work if missing.
7. Create or update `docs/ai-memory/features/<normalized-slug>.md`.
8. Rewrite or trim other affected memory notes when the current change invalidates stale details.
9. Update `docs/ai-memory/INDEX.md` so it lists only the active feature notes.
10. Update `docs/ai-memory/decisions.md` only for cross-feature decisions that still apply.
11. Update `docs/ai-memory/troubleshooting.md` only for reusable debugging knowledge that still applies.
12. Apply high-confidence rewrites and trims automatically.
13. If a note or entry should be removed from active memory, do not delete it yet unless the user explicitly approved that deletion in the current conversation. Instead, return a short `Deletion review` with item IDs, exact targets, and reasons.
14. If the user explicitly approved specific deletions in the current conversation, delete only those approved items and update `docs/ai-memory/INDEX.md` plus any broken references.
15. If there is no meaningful durable information yet, say so instead of inventing memory.
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
'@
    },
    @{
        Path = "commands\review-memory.md"
        Content = @'
---
description: Review and prune stale project memory
agent: memory-curator
subtask: true
---

Review the active project memory for `$ARGUMENTS`.

Goal:
- Find stale memory caused by refactors, removals, or drift.
- Automatically rewrite or trim notes that can be safely refreshed.
- Keep active memory focused on durable repo knowledge rather than spec-owned planning or status details.
- Require a brief user review before deleting active memory.

Inputs:
- Review scope: `$ARGUMENTS`
- Git status:
!`git status --short`
- Changed files:
!`git diff --name-only`
!`git diff --cached --name-only`
- Deleted files:
!`git diff --name-only --diff-filter=D`
!`git diff --cached --name-only --diff-filter=D`
- Diff summary:
!`git diff --stat`
!`git diff --cached --stat`
- Recent commits:
!`git log --oneline -10`

Tasks:
1. If `docs/ai-memory/` does not exist, explain that project memory has not been bootstrapped yet and tell the user to run the bootstrap script from this kit.
2. If the repo uses OpenSpec or another spec workflow, keep planning notes, task tracking, acceptance criteria, execution logs, and current status in the spec system instead of `docs/ai-memory/`.
3. Treat `$ARGUMENTS` as an optional scope. If it is empty, review the memory touched by recent changes first, then expand only if needed.
4. Read `docs/ai-memory/INDEX.md`, `docs/ai-memory/decisions.md`, `docs/ai-memory/troubleshooting.md`, and only the relevant feature notes.
5. Scan the notes that match the scope, changed files, deleted files, referenced modules, slugs, or likely stale signals.
6. Classify each candidate as `keep`, `rewrite`, `trim`, or `delete`.
7. Apply high-confidence rewrites and trims immediately.
8. Update `docs/ai-memory/INDEX.md` whenever active feature notes change.
9. If delete candidates exist and the user has not explicitly approved them in the current conversation, return a brief `Deletion review` with item IDs, exact targets, reasons, and recommended deletes.
10. If the user explicitly approved specific item IDs or exact targets in the current conversation, delete only those approved items and update `docs/ai-memory/INDEX.md` plus any cross-references.
11. Keep the report concise: automatic updates first, pending deletion review second, gaps last.
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
$startMarker = "<!-- opencode-memory-kit:start -->"
$endMarker = "<!-- opencode-memory-kit:end -->"

function Write-Utf8NoBomFile {
    param(
        [string]$Path,
        [string]$Content
    )

    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $encoding)
}

function Get-NewlineStyle {
    param(
        [string]$Content
    )

    if ($Content.Contains("`r`n")) {
        return "`r`n"
    }

    return "`n"
}

function Convert-Newlines {
    param(
        [string]$Content,
        [string]$Newline
    )

    return (($Content -replace "`r`n", "`n") -replace "`n", $Newline)
}

function Sync-ManagedAgentsBlock {
    param(
        [string]$Path,
        [string]$ManagedBlockPath,
        [string]$StartMarker,
        [string]$EndMarker
    )

    $current = [System.IO.File]::ReadAllText($Path)
    $managedBlock = [System.IO.File]::ReadAllText($ManagedBlockPath)
    $startCount = [regex]::Matches($current, [regex]::Escape($StartMarker)).Count
    $endCount = [regex]::Matches($current, [regex]::Escape($EndMarker)).Count
    $newline = Get-NewlineStyle -Content $current
    $managedBlock = Convert-Newlines -Content $managedBlock -Newline $newline

    if ($startCount -eq 0 -and $endCount -eq 0) {
        if ([string]::IsNullOrWhiteSpace($current)) {
            $updated = $managedBlock
        }
        elseif ($current.EndsWith($newline)) {
            $updated = $current + $newline + $managedBlock
        }
        else {
            $updated = $current + $newline + $newline + $managedBlock
        }

        Write-Utf8NoBomFile -Path $Path -Content $updated
        Write-Host "Updated AGENTS.md (appended memory workflow block)"
        return
    }

    if ($startCount -ne 1 -or $endCount -ne 1) {
        throw "Invalid AGENTS.md markers in $Path. Expected exactly one managed block or none."
    }

    $startIndex = $current.IndexOf($StartMarker, [System.StringComparison]::Ordinal)
    $endIndex = $current.IndexOf($EndMarker, [System.StringComparison]::Ordinal)

    if ($startIndex -gt $endIndex) {
        throw "Invalid AGENTS.md markers in $Path. Fix the marker order manually."
    }

    $suffixStart = $endIndex + $EndMarker.Length
    $updated = $current.Substring(0, $startIndex) + $managedBlock + $current.Substring($suffixStart)

    if ($updated -eq $current) {
        Write-Host "AGENTS.md already up to date"
        return
    }

    Write-Utf8NoBomFile -Path $Path -Content $updated
    Write-Host "Updated AGENTS.md (refreshed managed memory workflow block)"
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir
$templateRoot = Join-Path $repoRoot "templates\project"
$docsTemplateRoot = Join-Path $templateRoot "docs"
$fullAgentsTemplate = Join-Path $templateRoot "AGENTS.md"
$appendAgentsTemplate = Join-Path $templateRoot "AGENTS.memory.md"

if (-not (Test-Path -Path $Target -PathType Container)) {
    throw "Target directory does not exist: $Target"
}

$resolvedTarget = (Resolve-Path $Target).Path
$targetAgents = Join-Path $resolvedTarget "AGENTS.md"

if (Test-Path $targetAgents) {
    Sync-ManagedAgentsBlock -Path $targetAgents -ManagedBlockPath $appendAgentsTemplate -StartMarker $startMarker -EndMarker $endMarker
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
Write-Host "  2. Work as usual with plan and build"
Write-Host "  3. Let OpenCode delegate broad reading to explore and multi-step execution to general"
Write-Host "  4. Run /sync-memory [scope] after accepted work when durable repo truth changed"
Write-Host "  5. If the repo uses OpenSpec or another spec workflow, run /sync-memory [scope] after each spec archive for accepted work or say no durable memory update is needed"
Write-Host "  6. Run /recall-feature <query> in future sessions"
Write-Host "  7. Use /remember-feature <slug> to force a focused feature-note refresh"
Write-Host "  8. Use /review-memory [scope] to force a broader stale-memory review"
Write-Host "You can rerun this same bootstrap command later to refresh managed AGENTS.md instructions."
Write-Host "Saved notes under docs/ai-memory/ stay intact unless you use --force."
'@
    },
    @{
        Path = "opencode-memory-kit\scripts\bootstrap-project.sh"
        Content = @'
#!/usr/bin/env sh
set -eu

target="."
force="0"
start_marker="<!-- opencode-memory-kit:start -->"
end_marker="<!-- opencode-memory-kit:end -->"

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

sync_agents_file() {
  file_path="$1"
  use_crlf="0"
  cr=$(printf '\r')

  if grep -q "$cr" "$file_path"; then
    use_crlf="1"
  fi

  start_count=$(grep -F -c "$start_marker" "$file_path" || true)
  end_count=$(grep -F -c "$end_marker" "$file_path" || true)

  if [ "$start_count" -eq 0 ] && [ "$end_count" -eq 0 ]; then
    sync_mode="append"
  elif [ "$start_count" -eq 1 ] && [ "$end_count" -eq 1 ]; then
    start_line=$(awk -v marker="$start_marker" 'index($0, marker) { print NR; exit }' "$file_path")
    end_line=$(awk -v marker="$end_marker" 'index($0, marker) { print NR; exit }' "$file_path")

    if [ "$start_line" -ge "$end_line" ]; then
      printf '%s\n' "Invalid AGENTS.md markers in $file_path. Fix the marker order manually." >&2
      exit 1
    fi

    sync_mode="replace"
  else
    printf '%s\n' "Invalid AGENTS.md markers in $file_path. Expected exactly one managed block or none." >&2
    exit 1
  fi

  tmp_file=$(mktemp)

  if [ "$sync_mode" = "replace" ]; then
    awk -v use_crlf="$use_crlf" -v start="$start_marker" -v end="$end_marker" -v replacement="$append_agents_template" '
      BEGIN {
        ORS = (use_crlf == "1") ? "\r\n" : "\n"
      }

      function print_replacement(   line) {
        while ((getline line < replacement) > 0) {
          sub(/\r$/, "", line)
          print line
        }
        close(replacement)
      }

      {
        sub(/\r$/, "", $0)

        if (!in_block && index($0, start)) {
          print_replacement()
          in_block = 1
          next
        }

        if (in_block) {
          if (index($0, end)) {
            in_block = 0
          }
          next
        }

        print $0
      }
    ' "$file_path" > "$tmp_file"
  else
    awk -v use_crlf="$use_crlf" -v replacement="$append_agents_template" '
      BEGIN {
        ORS = (use_crlf == "1") ? "\r\n" : "\n"
      }

      function print_replacement(   line) {
        while ((getline line < replacement) > 0) {
          sub(/\r$/, "", line)
          print line
        }
        close(replacement)
      }

      {
        sub(/\r$/, "", $0)
        print $0
      }

      END {
        if (NR > 0) {
          print ""
        }
        print_replacement()
      }
    ' "$file_path" > "$tmp_file"
  fi

  if cmp -s "$file_path" "$tmp_file"; then
    rm -f "$tmp_file"
    printf '%s\n' "AGENTS.md already up to date"
    return
  fi

  mv "$tmp_file" "$file_path"

  if [ "$sync_mode" = "replace" ]; then
    printf '%s\n' "Updated AGENTS.md (refreshed managed memory workflow block)"
  else
    printf '%s\n' "Updated AGENTS.md (appended memory workflow block)"
  fi
}

if [ ! -d "$target" ]; then
  printf '%s\n' "Target directory does not exist: $target" >&2
  exit 1
fi

target=$(CDPATH= cd -- "$target" && pwd)
target_agents="$target/AGENTS.md"

if [ -f "$target_agents" ]; then
  sync_agents_file "$target_agents"
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
printf '%s\n' "  2. Work as usual with plan and build"
printf '%s\n' "  3. Let OpenCode delegate broad reading to explore and multi-step execution to general"
printf '%s\n' "  4. Run /sync-memory [scope] after accepted work when durable repo truth changed"
printf '%s\n' "  5. If the repo uses OpenSpec or another spec workflow, run /sync-memory [scope] after each spec archive for accepted work or say no durable memory update is needed"
printf '%s\n' "  6. Run /recall-feature <query> in future sessions"
printf '%s\n' "  7. Use /remember-feature <slug> to force a focused feature-note refresh"
printf '%s\n' "  8. Use /review-memory [scope] to force a broader stale-memory review"
printf '%s\n' "You can rerun this same bootstrap command later to refresh managed AGENTS.md instructions."
printf '%s\n' "Saved notes under docs/ai-memory/ stay intact unless you use --force."
'@
    },
    @{
        Path = "opencode-memory-kit\templates\project\AGENTS.md"
        Content = @'
# Project Instructions

<!-- opencode-memory-kit:start -->
## Thin Main Thread

Use OpenCode's built-in `plan` and `build` agents as the main conversation thread.

- If the repo uses OpenSpec or another spec workflow, let the active spec drive current scope, sequencing, and completion criteria. Use the guidance here to keep execution compact, not to replace the spec.
- Keep the main thread thin: clarify the goal, choose the next move, delegate broader work, and return with a short synthesis.
- Prefer the built-in `explore` subagent for codebase search, reading 4+ files, understanding architecture, tracing behavior, or comparing options.
- Prefer the built-in `general` subagent for multi-step execution, multi-file changes, tests, builds, and non-trivial bash.
- Keep work inline only when it is small and obvious: 1-3 quick reads, one narrow answer, or a mechanical single-file tweak.
- When delegating, ask for a compact handoff instead of a full transcript.
- Use a soft handoff rubric for subagent replies and omit sections that do not apply:
  - `Findings` or `Outcome`
  - `Files`
  - `Risks` or `Blockers`
  - `Verification`
  - `Next step`
- Keep subagent returns brief: about 5-8 bullets, no long logs, and no narration of every tool call.

## Project Memory Workflow

This project uses a durable AI memory layer stored in `docs/ai-memory/`.

### Persistent Memory

- Durable memory is for the repo's long-lived truth, not for temporary task handoffs.
- Use `docs/ai-memory/INDEX.md` as the entry point.
- For the default maintenance checkpoint, use `/sync-memory [scope]`.
- For explicit manual lookup, use `/recall-feature <query>`.
- Memory is intentionally lazy-loaded. Do not read every file in `docs/ai-memory/` by default.
- If the repo uses OpenSpec or another spec workflow, read the active spec first for current requirements, scope, and status. Use memory only to supplement durable implementation context.
- When a task mentions existing functionality, prior decisions, regressions, previous bugs, or continuing work from a past session:
  1. Read `docs/ai-memory/INDEX.md`.
  2. Use `grep` on `docs/ai-memory/**/*.md` for relevant feature names, file paths, tags, and error strings.
  3. Read only the matching notes.
- Prefer `docs/ai-memory/features/*.md` for feature-specific implementation context.
- Prefer `docs/ai-memory/decisions.md` for durable cross-feature decisions and constraints.
- Prefer `docs/ai-memory/troubleshooting.md` for recurring errors, exact messages, root causes, and fixes.
- If previous work matters for a delegated task, look up the relevant memory first and pass only the useful summary or exact note paths to the subagent.
- `explore` may read memory when prior work, decisions, regressions, or recurring bugs are central to the task.
- `general` should prefer caller-provided memory summaries or exact note paths over broad memory searches.

### Updating Memory

- Use `/sync-memory [scope]` as the default memory checkpoint after accepted changes when durable repo truth changed, and after refactors, renames, or deletions.
- If the repo uses OpenSpec or another spec workflow, after each spec archive for accepted work, run `/sync-memory [scope]` or say explicitly that no durable memory update is needed.
- Use `/remember-feature <kebab-case-slug>` when you want to force a focused feature-note refresh.
- Use `/review-memory [scope]` when you want to force a broader stale-memory review.
- When accepted work finishes, either run `/sync-memory [scope]` or say explicitly that no durable memory update is needed.
- `docs/ai-memory/` should represent the current truth of the repo, not a historical archive.
- Only write durable memory when work is accepted or a real cleanup pass is happening.
- If the change is docs-only, formatting-only, or otherwise non-durable, say that no durable memory update is needed instead of forcing a note.
- `/sync-memory`, `/remember-feature`, and `/review-memory` may automatically rewrite or trim stale notes when confidence is high.
- Deletions from the active memory tree require a brief review before removal.
- The memory update should capture only long-lived project knowledge:
  - relevant behavior now implemented
  - important files or modules touched
  - stable implementation constraints or tradeoffs future work must respect
  - reusable debugging knowledge
- Do not store raw conversation logs, temporary speculation, large diff narration, subagent handoff notes, problem statements, goals, non-goals, task lists, acceptance criteria, rollout plans, or current status when those already belong to the spec system.

### Memory Quality Bar

- Keep notes concise and searchable.
- Include exact file paths and exact error strings when useful.
- Update existing notes in place instead of creating duplicates.
- Remove obsolete sections once they stop being true.
- Use Git history for old context instead of keeping dead notes under `docs/ai-memory/`.
<!-- opencode-memory-kit:end -->
'@
    },
    @{
        Path = "opencode-memory-kit\templates\project\AGENTS.memory.md"
        Content = @'
<!-- opencode-memory-kit:start -->
## Thin Main Thread

Use OpenCode's built-in `plan` and `build` agents as the main conversation thread.

- If the repo uses OpenSpec or another spec workflow, let the active spec drive current scope, sequencing, and completion criteria. Use the guidance here to keep execution compact, not to replace the spec.
- Keep the main thread thin: clarify the goal, choose the next move, delegate broader work, and return with a short synthesis.
- Prefer the built-in `explore` subagent for codebase search, reading 4+ files, understanding architecture, tracing behavior, or comparing options.
- Prefer the built-in `general` subagent for multi-step execution, multi-file changes, tests, builds, and non-trivial bash.
- Keep work inline only when it is small and obvious: 1-3 quick reads, one narrow answer, or a mechanical single-file tweak.
- When delegating, ask for a compact handoff instead of a full transcript.
- Use a soft handoff rubric for subagent replies and omit sections that do not apply:
  - `Findings` or `Outcome`
  - `Files`
  - `Risks` or `Blockers`
  - `Verification`
  - `Next step`
- Keep subagent returns brief: about 5-8 bullets, no long logs, and no narration of every tool call.

## Project Memory Workflow

This project uses a durable AI memory layer stored in `docs/ai-memory/`.

### Persistent Memory

- Durable memory is for the repo's long-lived truth, not for temporary task handoffs.
- Use `docs/ai-memory/INDEX.md` as the entry point.
- For the default maintenance checkpoint, use `/sync-memory [scope]`.
- For explicit manual lookup, use `/recall-feature <query>`.
- Memory is intentionally lazy-loaded. Do not read every file in `docs/ai-memory/` by default.
- If the repo uses OpenSpec or another spec workflow, read the active spec first for current requirements, scope, and status. Use memory only to supplement durable implementation context.
- When a task mentions existing functionality, prior decisions, regressions, previous bugs, or continuing work from a past session:
  1. Read `docs/ai-memory/INDEX.md`.
  2. Use `grep` on `docs/ai-memory/**/*.md` for relevant feature names, file paths, tags, and error strings.
  3. Read only the matching notes.
- Prefer `docs/ai-memory/features/*.md` for feature-specific implementation context.
- Prefer `docs/ai-memory/decisions.md` for durable cross-feature decisions and constraints.
- Prefer `docs/ai-memory/troubleshooting.md` for recurring errors, exact messages, root causes, and fixes.
- If previous work matters for a delegated task, look up the relevant memory first and pass only the useful summary or exact note paths to the subagent.
- `explore` may read memory when prior work, decisions, regressions, or recurring bugs are central to the task.
- `general` should prefer caller-provided memory summaries or exact note paths over broad memory searches.

### Updating Memory

- Use `/sync-memory [scope]` as the default memory checkpoint after accepted changes when durable repo truth changed, and after refactors, renames, or deletions.
- If the repo uses OpenSpec or another spec workflow, after each spec archive for accepted work, run `/sync-memory [scope]` or say explicitly that no durable memory update is needed.
- Use `/remember-feature <kebab-case-slug>` when you want to force a focused feature-note refresh.
- Use `/review-memory [scope]` when you want to force a broader stale-memory review.
- When accepted work finishes, either run `/sync-memory [scope]` or say explicitly that no durable memory update is needed.
- `docs/ai-memory/` should represent the current truth of the repo, not a historical archive.
- Only write durable memory when work is accepted or a real cleanup pass is happening.
- If the change is docs-only, formatting-only, or otherwise non-durable, say that no durable memory update is needed instead of forcing a note.
- `/sync-memory`, `/remember-feature`, and `/review-memory` may automatically rewrite or trim stale notes when confidence is high.
- Deletions from the active memory tree require a brief review before removal.
- The memory update should capture only long-lived project knowledge:
  - relevant behavior now implemented
  - important files or modules touched
  - stable implementation constraints or tradeoffs future work must respect
  - reusable debugging knowledge
- Do not store raw conversation logs, temporary speculation, large diff narration, subagent handoff notes, problem statements, goals, non-goals, task lists, acceptance criteria, rollout plans, or current status when those already belong to the spec system.

### Memory Quality Bar

- Keep notes concise and searchable.
- Include exact file paths and exact error strings when useful.
- Update existing notes in place instead of creating duplicates.
- Remove obsolete sections once they stop being true.
- Use Git history for old context instead of keeping dead notes under `docs/ai-memory/`.
<!-- opencode-memory-kit:end -->
'@
    },
    @{
        Path = "opencode-memory-kit\templates\project\docs\ai-memory\INDEX.md"
        Content = @'
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
'@
    },
    @{
        Path = "opencode-memory-kit\templates\project\docs\ai-memory\decisions.md"
        Content = @'
# Decisions

Stable repo-level constraints and cross-feature implementation decisions that future work should preserve when they must outlive the current spec.

## How to add entries

- Add only decisions that affect more than one future task or module.
- If a decision belongs only to the active spec or will stop mattering after that spec is archived, keep it there instead of duplicating it here.
- Prefer one short subsection per decision.
- Prefer concise durable constraints over long rationale.
- Link affected files when possible.
- Record only decisions that remain relevant after the current spec is archived.
- Rewrite or remove entries when the decision no longer constrains the current codebase.
- Do not keep superseded decisions here just for history; Git already preserves that context.

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
- Rewrite or remove entries when the symptom, root cause, or fix no longer matches the current codebase.
- Do not keep solved-once historical notes that no longer help future debugging.

## Entries

- None recorded yet.
'@
    },
    @{
        Path = "opencode-memory-kit\templates\project\docs\ai-memory\features\README.md"
        Content = @'
# Feature Notes

Create one file per accepted feature or durable implementation area using a kebab-case slug.

## When to create a feature note

- The feature changed durable project behavior.
- Future work will benefit from remembering touched files, constraints, or fixes.

## Lifecycle

- Treat each feature note as a durable memory supplement for the current implementation state of that feature, not as the source of truth for active planning or delivery status.
- Rewrite the note in place when behavior changes.
- Trim sections that became stale while keeping the useful parts.
- Delete the file when the feature is removed, absorbed, or no longer carries durable value.
- Do not archive obsolete feature notes under `docs/ai-memory/`; rely on Git history instead.
- Deletions require a brief review before removal.

## Recommended structure

- `# <Feature Title>`
- `## Summary`
- `## Files`
- `## Durable constraints`
- `## Errors and fixes`

Record durable knowledge only. Avoid raw diff summaries, transient chat context, active task lists, acceptance criteria, rollout plans, and status tracking already covered by specs.
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
Write-Host "Commands now available: /sync-memory, /remember-feature, /recall-feature, and /review-memory"
Write-Host "Default memory checkpoint: /sync-memory [scope]"
Write-Host "Bootstrap or refresh a repo with:"
Write-Host ('  powershell -ExecutionPolicy Bypass -File "{0}" -Target .' -f $bootstrapPath)
Write-Host "Rerun the same bootstrap command later to refresh managed instructions without overwriting saved memory notes."
