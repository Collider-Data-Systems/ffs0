# sync-claude-skills.ps1
# Sync ffs0/dev/claude-skills/* -> $env:USERPROFILE\.claude\skills\
# Cowork/Claude Desktop/Claude Code read from USERPROFILE\.claude\skills - canonical copies live in ffs0.
#
# T=262 harness diet: per-seat materialization. With -Seat, only that seat's mount list
# (from dev/config/session-affordance-map.json, plus moos-seat-hydration which every seat gets)
# is installed; moos-* dirs in the target that are NOT in the selected set are PRUNED.
# Without -Seat, all repo skills are synced (fleet default) and retired moos-* dirs are pruned.
#
# Usage:
#   pwsh dev\scripts\sync-claude-skills.ps1                      # all skills + prune retired
#   pwsh dev\scripts\sync-claude-skills.ps1 -Seat hpprodesk-vscode-bootstrap
#   (then fully quit + restart the Claude app for the panel to pick them up)

param(
    [string]$Seat = ''
)

$ErrorActionPreference = 'Stop'

$source = Join-Path $PSScriptRoot '..\claude-skills' | Resolve-Path
$target = Join-Path $env:USERPROFILE '.claude\skills'
$mapPath = Join-Path $PSScriptRoot '..\config\session-affordance-map.json'

if (-not (Test-Path $target)) {
    New-Item -ItemType Directory -Path $target -Force | Out-Null
    Write-Host "Created $target"
}

$repoSkills = Get-ChildItem -Path $source -Directory | Select-Object -ExpandProperty Name

# Resolve the desired skill set
$wanted = $repoSkills
if ($Seat -ne '') {
    $map = Get-Content $mapPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $row = $map.sessions | Where-Object { $_.key -eq $Seat }
    if ($null -eq $row) {
        Write-Host "Seat '$Seat' not found in session-affordance-map.json. Known keys:" -ForegroundColor Red
        $map.sessions | ForEach-Object { Write-Host "  $($_.key)" }
        exit 1
    }
    $wanted = @($row.skills) + 'moos-seat-hydration' | Select-Object -Unique
    $missing = $wanted | Where-Object { $_ -notin $repoSkills }
    foreach ($m in $missing) { Write-Host "WARN: seat lists '$m' but repo has no such skill dir" -ForegroundColor Yellow }
    $wanted = $wanted | Where-Object { $_ -in $repoSkills }
    Write-Host "Seat '$Seat' -> materializing $($wanted.Count) skill(s): $($wanted -join ', ')"
}

# Install/update wanted skills
foreach ($name in $wanted) {
    $dest = Join-Path $target $name
    if (Test-Path $dest) {
        Write-Host "Updating: $name"
        Remove-Item -Recurse -Force $dest
    } else {
        Write-Host "Installing: $name"
    }
    Copy-Item -Recurse -Path (Join-Path $source $name) -Destination $dest
}

# Prune moos-* dirs not in the selected set (covers retired skills and de-mounted seat skills)
Get-ChildItem -Path $target -Directory | Where-Object { $_.Name -like 'moos-*' -and $_.Name -notin $wanted } | ForEach-Object {
    Write-Host "Pruning: $($_.Name)" -ForegroundColor Yellow
    Remove-Item -Recurse -Force $_.FullName
}

Write-Host ""
Write-Host "Installed moos skills:"
Get-ChildItem -Path $target -Directory | Where-Object { $_.Name -like 'moos-*' } | ForEach-Object {
    $skillMd = Join-Path $_.FullName 'SKILL.md'
    if (Test-Path $skillMd) { Write-Host "  $($_.Name) (OK)" } else { Write-Host "  $($_.Name) (WARN: no SKILL.md)" }
}

Write-Host ""
Write-Host "Next: fully quit the Claude app (tray -> Quit) and restart for skills to reload."
