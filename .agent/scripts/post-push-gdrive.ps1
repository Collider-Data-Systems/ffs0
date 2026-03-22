# post-push-gdrive.ps1 — Bundle git repos and copy to Google Drive after each push
# Requires: Google Drive for Desktop running with a mounted drive letter
# Configure GDRIVE_ROOT below to match your mount point (e.g., "G:\My Drive" or "G:\Mijn Drive")

param(
    [string]$GDriveRoot = "",
    [string]$Repo = "auto"
)

# --- Config ---
$backupFolder = "moos-git-bundles"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

# Auto-detect Google Drive mount
if (-not $GDriveRoot) {
    $candidates = @(
        "G:\My Drive", "G:\Mijn Drive",
        "H:\My Drive", "H:\Mijn Drive",
        "I:\My Drive", "I:\Mijn Drive"
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) {
            $GDriveRoot = $c
            break
        }
    }
}

if (-not $GDriveRoot -or -not (Test-Path $GDriveRoot)) {
    Write-Host "[post-push] ERROR: Google Drive mount not found. Start Google Drive for Desktop and mount a drive letter." -ForegroundColor Red
    Write-Host "[post-push] Then set GDRIVE_ROOT or pass -GDriveRoot 'G:\My Drive'" -ForegroundColor Yellow
    exit 1
}

# Create backup folder on Drive
$targetDir = Join-Path $GDriveRoot $backupFolder
if (-not (Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    Write-Host "[post-push] Created $targetDir"
}

# Determine which repo we're in
$gitRoot = git rev-parse --show-toplevel 2>$null
if (-not $gitRoot) {
    Write-Host "[post-push] ERROR: Not in a git repository" -ForegroundColor Red
    exit 1
}

$repoName = Split-Path $gitRoot -Leaf
$branch = git rev-parse --abbrev-ref HEAD
$shortHash = git rev-parse --short HEAD

# Create git bundle (full repo, all refs)
$bundleName = "${repoName}_${branch}_${shortHash}_${timestamp}.bundle"
$bundlePath = Join-Path $targetDir $bundleName

Write-Host "[post-push] Bundling $repoName ($branch @ $shortHash)..."
git bundle create $bundlePath --all 2>$null

if ($LASTEXITCODE -eq 0 -and (Test-Path $bundlePath)) {
    $size = [math]::Round((Get-Item $bundlePath).Length / 1MB, 2)
    Write-Host "[post-push] OK: $bundleName (${size} MB) -> Google Drive" -ForegroundColor Green

    # Keep only last 5 bundles per repo to avoid filling Drive
    $old = Get-ChildItem $targetDir -Filter "${repoName}_*.bundle" | Sort-Object LastWriteTime -Descending | Select-Object -Skip 5
    foreach ($f in $old) {
        Remove-Item $f.FullName -Force
        Write-Host "[post-push] Cleaned old bundle: $($f.Name)" -ForegroundColor DarkGray
    }
} else {
    Write-Host "[post-push] ERROR: Bundle creation failed" -ForegroundColor Red
    exit 1
}
