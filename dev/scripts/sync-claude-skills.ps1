# sync-claude-skills.ps1
# Sync ffs0/dev/claude-skills/* → $env:USERPROFILE\.claude\skills\
# Cowork/Claude Desktop reads from USERPROFILE\.claude\skills — canonical copies live in ffs0
# for git sync between Z440 and hp-laptop. This script pushes the repo copies into place.
#
# Usage (Z440 or hp-laptop):
#   pwsh D:\HPZ440\ffs0\dev\scripts\sync-claude-skills.ps1
#   (then fully quit + restart Claude Desktop for the Customizations panel to pick them up)

$ErrorActionPreference = 'Stop'

$source = Join-Path $PSScriptRoot '..\claude-skills' | Resolve-Path
$target = Join-Path $env:USERPROFILE '.claude\skills'

if (-not (Test-Path $target)) {
    New-Item -ItemType Directory -Path $target -Force | Out-Null
    Write-Host "Created $target"
}

Write-Host "Source: $source"
Write-Host "Target: $target"
Write-Host ""

$skills = Get-ChildItem -Path $source -Directory
foreach ($skill in $skills) {
    $dest = Join-Path $target $skill.Name
    if (Test-Path $dest) {
        Write-Host "Updating: $($skill.Name)"
        Remove-Item -Recurse -Force $dest
    } else {
        Write-Host "Installing: $($skill.Name)"
    }
    Copy-Item -Recurse -Path $skill.FullName -Destination $dest
}

Write-Host ""
Write-Host "Installed skills:"
Get-ChildItem -Path $target -Directory | Where-Object { $_.Name -like 'moos-*' } | ForEach-Object {
    $skillMd = Join-Path $_.FullName 'SKILL.md'
    if (Test-Path $skillMd) {
        Write-Host "  $($_.Name) (OK)"
    } else {
        Write-Host "  $($_.Name) (WARN: no SKILL.md)"
    }
}

Write-Host ""
Write-Host "Next: fully quit Claude Desktop (tray -> Quit) and restart. Skills appear in Customizations panel on next launch."
