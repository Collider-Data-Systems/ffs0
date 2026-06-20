<#
.SYNOPSIS
    Mirror Google Keep notes from BOTH a personal and a Workspace account into one
    folder, then sync that folder to Google Drive — so every device (Android Drive
    app, Claude Desktop's Drive MCP, the ffs0 session) can read them.

.DESCRIPTION
    Two halves land Markdown/JSON into a single mirror root:
      personal  -> dev/scripts/keep_personal_fetch.py   (gkeepapi, master token)
      workspace -> dev/scripts/ops/Invoke-KeepIngestHarness.ps1 (official Keep API)
    Then `rclone copy <root> <remote>` pushes it to Drive. Run on Z440 (always at
    home) on a schedule; the other boxes and Android just read the Drive folder.

    Secret-free: the personal master token is read from secrets/keep_personal.env
    (gitignored); Workspace creds use the existing harness' secrets paths.

.EXAMPLE
    pwsh -File dev/scripts/ops/Invoke-KeepDriveMirror.ps1 -DriveRemote gdrive:keep-mirror
.EXAMPLE
    pwsh -File dev/scripts/ops/Invoke-KeepDriveMirror.ps1 -SkipWorkspace -SkipUpload  # personal-only, no push
#>
[CmdletBinding()]
param(
    [string]$OutRoot = 'scratch\keep\mirror',
    [string]$EnvFile = 'secrets\keep_personal.env',
    [string]$PythonPath = 'python',
    [ValidateSet('ApiDelegatedKeylessFetch', 'ApiDelegatedFetch', 'ApiFetch')]
    [string]$WorkspaceMode = 'ApiDelegatedKeylessFetch',
    [string]$DriveRemote = 'gdrive:keep-mirror',
    [switch]$SkipPersonal,
    [switch]$SkipWorkspace,
    [switch]$SkipUpload
)

$ErrorActionPreference = 'Stop'
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..\..')
Set-Location $repoRoot

function Write-Step($msg) { Write-Host "[keep-mirror] $msg" -ForegroundColor Cyan }

$personalOut = Join-Path $OutRoot 'personal'
$workspaceOut = Join-Path $OutRoot 'workspace'
New-Item -ItemType Directory -Force -Path $personalOut, $workspaceOut | Out-Null

# --- personal account (gkeepapi) -------------------------------------------
if (-not $SkipPersonal) {
    if (-not (Test-Path $EnvFile)) {
        throw "Personal env file '$EnvFile' not found. Copy secrets\keep_personal.env.example and fill it (KEEP_EMAIL, KEEP_MASTER_TOKEN)."
    }
    Write-Step "loading $EnvFile and fetching personal Keep notes"
    Get-Content $EnvFile | ForEach-Object {
        $line = $_.Trim()
        if ($line -and -not $line.StartsWith('#') -and $line.Contains('=')) {
            $k, $v = $line.Split('=', 2)
            Set-Item -Path "Env:$($k.Trim())" -Value $v.Trim()
        }
    }
    & $PythonPath 'dev\scripts\keep_personal_fetch.py' '--out' $personalOut
    if ($LASTEXITCODE -ne 0) { throw "personal fetch failed (exit $LASTEXITCODE)" }
}
else { Write-Step 'skipping personal account' }

# --- workspace account (official Keep API, existing harness) ---------------
if (-not $SkipWorkspace) {
    Write-Step "fetching Workspace Keep notes via $WorkspaceMode"
    & pwsh -NoProfile -File 'dev\scripts\ops\Invoke-KeepIngestHarness.ps1' `
        -Mode $WorkspaceMode -ApiOutDir $workspaceOut -SkipLiveState
    if ($LASTEXITCODE -ne 0) { Write-Warning "workspace fetch returned exit $LASTEXITCODE (continuing)" }
}
else { Write-Step 'skipping workspace account' }

# --- push the unified mirror to Drive --------------------------------------
if (-not $SkipUpload) {
    if (-not (Get-Command rclone -ErrorAction SilentlyContinue)) {
        throw "rclone not found. Install it and configure a 'gdrive' remote (rclone config), or re-run with -SkipUpload."
    }
    Write-Step "rclone copy $OutRoot -> $DriveRemote"
    rclone copy $OutRoot $DriveRemote --progress
    if ($LASTEXITCODE -ne 0) { throw "rclone upload failed (exit $LASTEXITCODE)" }
}
else { Write-Step 'skipping Drive upload' }

Write-Step "done. mirror at $OutRoot (personal Markdown + workspace notes)."
