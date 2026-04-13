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
Write-Host "  5. Run /review-memory [scope] after large refactors or removals"
