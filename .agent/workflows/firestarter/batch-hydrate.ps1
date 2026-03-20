# Firestarter: batch-hydrate.ps1
# Processes ALL skills through the Firestarter pipeline.
#
# Usage: .\batch-hydrate.ps1 [-SkillsRoot <path>] [-KernelUrl <url>]

param(
    [string]$SkillsRoot = ".agent\skills",
    [string]$KernelUrl = "http://localhost:8000",
    [string]$RootUrn = "urn:moos:kernel:wave-0"
)

$ErrorActionPreference = "Continue"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$HydrateScript = Join-Path $ScriptDir "hydrate-skill.ps1"

# Verify kernel is running
try {
    $Health = Invoke-RestMethod -Uri "$KernelUrl/healthz" -TimeoutSec 3
    Write-Host "[firestarter] Kernel healthy: $($Health.nodes) nodes, $($Health.wires) wires" -ForegroundColor Green
}
catch {
    Write-Host "[firestarter] ERROR: Kernel not reachable at $KernelUrl" -ForegroundColor Red
    Write-Host "  Start with: go run ./cmd/moos --kb ... --hydrate" -ForegroundColor Yellow
    exit 1
}

# Collect skill directories
$Skills = Get-ChildItem -Path $SkillsRoot -Directory | Sort-Object Name
$Total = $Skills.Count
$Ok = 0
$Skip = 0
$Fail = 0

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Firestarter Batch Hydration" -ForegroundColor Cyan
Write-Host " Skills: $Total" -ForegroundColor Cyan
Write-Host " Kernel: $KernelUrl" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

foreach ($Skill in $Skills) {
    $SkillMd = Join-Path $Skill.FullName "SKILL.md"
    if (-not (Test-Path $SkillMd)) {
        Write-Host "[firestarter] SKIP: $($Skill.Name) (no SKILL.md)" -ForegroundColor DarkGray
        $Skip++
        continue
    }

    & $HydrateScript -SkillDir $Skill.FullName -KernelUrl $KernelUrl -RootUrn $RootUrn

    if ($LASTEXITCODE -eq 0) {
        $Ok++
    }
    else {
        $Fail++
    }
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Firestarter Complete" -ForegroundColor Cyan
Write-Host "----------------------------------------"
Write-Host " Total:   $Total"
Write-Host " OK:      $Ok" -ForegroundColor Green
Write-Host " Skipped: $Skip" -ForegroundColor Yellow
Write-Host " Failed:  $Fail" -ForegroundColor $(if ($Fail -gt 0) { "Red" } else { "Green" })
Write-Host "========================================" -ForegroundColor Cyan

# Post-hydration: check kernel state
try {
    $Health = Invoke-RestMethod -Uri "$KernelUrl/healthz" -TimeoutSec 3
    Write-Host ""
    Write-Host " Kernel after: $($Health.nodes) nodes, $($Health.wires) wires" -ForegroundColor Green
}
catch {}
