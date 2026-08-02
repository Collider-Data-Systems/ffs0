# sync-antigravity-config.ps1
# Syncs canonical skills ffs0/dev/claude-skills/* -> ffs0/.agents/skills/ AND $env:USERPROFILE\.gemini\antigravity\skills\

param(
    [switch]$CheckOnly
)

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..')).Path
$source = Join-Path $repoRoot 'dev\claude-skills'
$agentsSkillsTarget = Join-Path $repoRoot '.agents\skills'
$globalSkillsTarget = Join-Path $env:USERPROFILE '.gemini\antigravity\skills'
$agentsRulesTarget = Join-Path $repoRoot '.agents\rules'
$globalRulesTarget = Join-Path $env:USERPROFILE '.gemini\antigravity\rules'

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " Antigravity IDE Config & Skill Syncer" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# Ensure target directories exist
foreach ($dir in @($agentsSkillsTarget, $globalSkillsTarget, $agentsRulesTarget, $globalRulesTarget)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "Created target directory: $dir" -ForegroundColor Green
    }
}

$skills = Get-ChildItem -Path $source -Directory | Select-Object -ExpandProperty Name

Write-Host "Found $($skills.Count) canonical skills in $source" -ForegroundColor Yellow

foreach ($skill in $skills) {
    $srcPath = Join-Path $source $skill
    $agentsDest = Join-Path $agentsSkillsTarget $skill
    $globalDest = Join-Path $globalSkillsTarget $skill

    if ($CheckOnly) {
        Write-Host "Check: $skill" -ForegroundColor Gray
        continue
    }

    # Materialize to .agents/skills/
    if (Test-Path $agentsDest) { Remove-Item -Recurse -Force $agentsDest }
    Copy-Item -Recurse -Path $srcPath -Destination $agentsDest
    Write-Host "  -> Materialized to .agents/skills/$skill" -ForegroundColor Green

    # Materialize to global ~/.gemini/antigravity/skills/
    if (Test-Path $globalDest) { Remove-Item -Recurse -Force $globalDest }
    Copy-Item -Recurse -Path $srcPath -Destination $globalDest
    Write-Host "  -> Materialized to ~/.gemini/antigravity/skills/$skill" -ForegroundColor Green
}

# Sync rules
$rules = Get-ChildItem -Path $agentsRulesTarget -File -Filter '*.md'
foreach ($rule in $rules) {
    $globalRuleDest = Join-Path $globalRulesTarget $rule.Name
    Copy-Item -Force -Path $rule.FullName -Destination $globalRuleDest
    Write-Host "  -> Synced rule $($rule.Name) to ~/.gemini/antigravity/rules/" -ForegroundColor Green
}

Write-Host ""
Write-Host "✅ Antigravity IDE configuration and skill sync complete!" -ForegroundColor Cyan
