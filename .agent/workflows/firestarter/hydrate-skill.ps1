# Firestarter: hydrate-skill.ps1
# Classifies a single skill and POSTs it to the running kernel.
# Auto-detects: tries ADD first, falls back to MUTATE (enrich) if node exists.
#
# Usage: .\hydrate-skill.ps1 <skill-dir-path> [-KernelUrl <url>] [-RootUrn <urn>]

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$SkillDir,

    [string]$KernelUrl = "http://localhost:8000",
    [string]$RootUrn = "urn:moos:kernel:wave-0",
    [string]$LogFile = ""
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ClassifyScript = Join-Path $ScriptDir "classify-skill.py"
if (-not $LogFile) { $LogFile = Join-Path $ScriptDir "log.jsonl" }

$SkillDir = Resolve-Path $SkillDir -ErrorAction Stop
$SkillName = Split-Path $SkillDir -Leaf

Write-Host "[firestarter] Processing: $SkillName" -ForegroundColor Cyan

# Try ADD first
$ProgramJson = python $ClassifyScript $SkillDir --root-urn $RootUrn --mode add 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "[firestarter] CLASSIFY FAILED: $SkillName" -ForegroundColor Red
    exit 1
}

$TmpFile = [System.IO.Path]::GetTempFileName()
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($TmpFile, ($ProgramJson -join "`n"), $utf8NoBom)

try {
    $Response = curl.exe -s -X POST "$KernelUrl/programs" -H "Content-Type: application/json" -d "@$TmpFile" 2>&1
    $Parsed = $Response | ConvertFrom-Json -ErrorAction SilentlyContinue

    if ($Parsed.error -and $Parsed.error -match "already exists") {
        # Node exists — fall back to MUTATE (enrich)
        Write-Host "[firestarter] Node exists, enriching: $SkillName" -ForegroundColor Yellow

        # Get current version from kernel
        $NodeResp = curl.exe -s "$KernelUrl/state/nodes/urn:moos:tool:$SkillName" 2>&1
        $NodeData = $NodeResp | ConvertFrom-Json -ErrorAction SilentlyContinue
        $Version = if ($NodeData.version) { $NodeData.version } else { 1 }

        $EnrichJson = python $ClassifyScript $SkillDir --root-urn $RootUrn --mode enrich --version $Version 2>&1
        [System.IO.File]::WriteAllText($TmpFile, ($EnrichJson -join "`n"), $utf8NoBom)

        $Response2 = curl.exe -s -X POST "$KernelUrl/programs" -H "Content-Type: application/json" -d "@$TmpFile" 2>&1
        $Parsed2 = $Response2 | ConvertFrom-Json -ErrorAction SilentlyContinue

        if ($Parsed2.error) {
            Write-Host "[firestarter] ENRICH FAIL: $SkillName - $($Parsed2.error)" -ForegroundColor Red
            $Status = "enrich_fail"
        }
        else {
            Write-Host "[firestarter] ENRICHED: $SkillName (v$Version -> v$($Version+1))" -ForegroundColor Green
            $Status = "enriched"
        }
    }
    elseif ($Parsed.error) {
        Write-Host "[firestarter] FAIL: $SkillName - $($Parsed.error)" -ForegroundColor Red
        $Status = "error"
    }
    else {
        Write-Host "[firestarter] ADDED: $SkillName (new node)" -ForegroundColor Green
        $Status = "added"
    }

    # Log
    $LogEntry = @{
        timestamp = (Get-Date -Format "o")
        skill = $SkillName
        status = $Status
    } | ConvertTo-Json -Compress
    Add-Content -Path $LogFile -Value $LogEntry -Encoding UTF8
}
finally {
    Remove-Item $TmpFile -ErrorAction SilentlyContinue
}
