param(
    [string]$ConfigDir = (Join-Path $HOME ".config\opencode"),
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$archiveUrl = if ($env:OPENCODE_MEMORY_KIT_ARCHIVE_URL) { $env:OPENCODE_MEMORY_KIT_ARCHIVE_URL } else { "https://github.com/alejodevelop/opencode-memory-kit/archive/refs/heads/main.zip" }
$sourceDir = $env:OPENCODE_MEMORY_KIT_SOURCE_DIR
$tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("opencode-memory-kit-" + [Guid]::NewGuid().ToString("N"))
$archivePath = Join-Path $tempDir "opencode-memory-kit.zip"
$extractDir = Join-Path $tempDir "extract"

try {
    if ($sourceDir) {
        $repoDir = Get-Item -LiteralPath $sourceDir
    }
    else {
        New-Item -ItemType Directory -Force -Path $extractDir | Out-Null

        Write-Host "Downloading OpenCode memory kit..."
        Invoke-WebRequest -UseBasicParsing -Uri $archiveUrl -OutFile $archivePath
        Expand-Archive -Path $archivePath -DestinationPath $extractDir -Force

        $repoDir = Get-ChildItem -Directory $extractDir | Select-Object -First 1
        if (-not $repoDir) {
            throw "Could not locate extracted kit contents."
        }
    }

    $installScript = Join-Path $repoDir.FullName "scripts\install-global.ps1"
    if (-not (Test-Path $installScript)) {
        throw "Could not locate install-global.ps1 in the downloaded kit."
    }

    & $installScript -ConfigDir $ConfigDir -Force:$Force
}
finally {
    if (Test-Path $tempDir) {
        Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
    }
}
