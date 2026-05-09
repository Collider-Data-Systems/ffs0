param(
    [string]$BaseUrl = "http://localhost:8000",
    [string]$Julia = $env:JULIA_EXE
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($Julia)) {
    $localJulia = "C:\Users\maass\AppData\Local\Programs\Julia-1.12.6\bin\julia.exe"
    if (Test-Path $localJulia) {
        $Julia = $localJulia
    } else {
        $Julia = "julia"
    }
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")
$oldPreset = $env:MOOS_PROJECTION_PRESET
$oldBaseUrl = $env:MOOS_BASE_URL
$oldOut = $env:MOOS_PROJECTION_OUT

function Invoke-Step {
    param(
        [string]$Name,
        [scriptblock]$Command
    )
    Write-Host "==> $Name"
    & $Command
    if ($LASTEXITCODE -ne 0) {
        throw "$Name failed with exit code $LASTEXITCODE"
    }
}

Push-Location $repoRoot
try {
    Invoke-Step "Session context projection" { & $Julia "dev\scripts\session_context_projection.jl" "--base-url" $BaseUrl }
    Invoke-Step "Graph artifact projection" { & $Julia "dev\scripts\graph_artifact_projection.jl" "--base-url" $BaseUrl }

    $env:MOOS_PROJECTION_PRESET = "session-occasion"
    $env:MOOS_BASE_URL = $BaseUrl
    Invoke-Step "Session occasion visual projection" { & $Julia "dev\scripts\export_t200plus_projection.jl" }

    $env:MOOS_PROJECTION_PRESET = "temporal-calendar"
    $env:MOOS_PROJECTION_OUT = "tmp/projections/session_pipeline/visual/temporal_calendar_frame"
    Invoke-Step "Temporal calendar visual projection" { & $Julia "dev\scripts\export_t200plus_projection.jl" }

    $health = Invoke-RestMethod -Uri "$BaseUrl/healthz" -TimeoutSec 5
    Invoke-Step "Calendar time-fabric projection" { & $Julia "dev\scripts\calendar_time_fabric_projection.jl" "--anchor-t" ([string]$health.t_day) }

    Invoke-Step "T189/T200 recommendation HG projection" { & $Julia "dev\scripts\t189_t200_recommendation_projection.jl" }

    Invoke-Step "Session pipeline MVP gate" { & $Julia "dev\scripts\session_pipeline_mvp_gate.jl" "--base-url" $BaseUrl }

    Write-Host ""
    Write-Host "Dashboard: tmp\projections\session_pipeline\index.html"
} finally {
    $env:MOOS_PROJECTION_PRESET = $oldPreset
    $env:MOOS_BASE_URL = $oldBaseUrl
    if ($null -eq $oldOut) {
        Remove-Item Env:MOOS_PROJECTION_OUT -ErrorAction SilentlyContinue
    } else {
        $env:MOOS_PROJECTION_OUT = $oldOut
    }
    Pop-Location
}
