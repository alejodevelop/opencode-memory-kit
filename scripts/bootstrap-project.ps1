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

function New-FullAgentsContent {
    param(
        [string]$ManagedBlockPath
    )

    $managedBlock = [System.IO.File]::ReadAllText($ManagedBlockPath)
    return "# Project Instructions`n`n$managedBlock"
}

function Test-FileContentEqual {
    param(
        [string]$LeftPath,
        [string]$RightPath
    )

    if (-not (Test-Path $LeftPath) -or -not (Test-Path $RightPath)) {
        return $false
    }

    return (Get-FileHash -LiteralPath $LeftPath).Hash -eq (Get-FileHash -LiteralPath $RightPath).Hash
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
$managedAgentsTemplate = Join-Path $templateRoot "AGENTS.memory.md"

if (-not (Test-Path -Path $Target -PathType Container)) {
    throw "Target directory does not exist: $Target"
}

$resolvedTarget = (Resolve-Path $Target).Path
$targetAgents = Join-Path $resolvedTarget "AGENTS.md"

if (Test-Path $targetAgents) {
    Sync-ManagedAgentsBlock -Path $targetAgents -ManagedBlockPath $managedAgentsTemplate -StartMarker $startMarker -EndMarker $endMarker
}
else {
    Write-Utf8NoBomFile -Path $targetAgents -Content (New-FullAgentsContent -ManagedBlockPath $managedAgentsTemplate)
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

    elseif ($exists -and (Test-FileContentEqual -LeftPath $sourcePath -RightPath $destination)) {
        Write-Host "Already up to date $relativePath"
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
