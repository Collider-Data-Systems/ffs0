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
    Invoke-Step "T189 recommendation graph artifact projection" {
        & $Julia "dev\scripts\graph_artifact_projection.jl" `
            "--base-url" $BaseUrl `
            "--root-urn" "urn:moos:purpose:sam.t189-t200plus-time-fabric-convergence" `
            "--root-urns" "urn:moos:session:sam.governance;urn:moos:purpose:sam.t189-t200plus-time-fabric-convergence;urn:moos:derivation:guido.t189-calendar-event-g-ingest-decision;urn:moos:view_filter:sam.t189-time-fabric-session-lens;urn:moos:group:my-tiny-data-collider" `
            "--radius" "2" `
            "--wfs" "WF01,WF18,WF19,WF21" `
            "--ports" "causes,caused-by,composes,composed-by,filtered-by,filters-session,owns,owned-by,pinned-by-session,pins-urn" `
            "--types" "derivation,group,program,purpose,session,view_filter" `
            "--match" "t189|t200|calendar|github|cytoscape|my-tiny-data-collider|convergence|governance|application" `
            "--out-base" "tmp/projections/session_pipeline/graph_artifacts/t189_recommendation_engineering"
    }

    $env:MOOS_PROJECTION_PRESET = "session-occasion"
    $env:MOOS_BASE_URL = $BaseUrl
    $env:MOOS_PROJECTION_OUT = "tmp/projections/session_pipeline/visual/session_occasion_frame"
    Invoke-Step "Session occasion visual projection" { & $Julia "dev\scripts\export_t200plus_projection.jl" }

    $env:MOOS_PROJECTION_PRESET = "temporal-calendar"
    $env:MOOS_PROJECTION_OUT = "tmp/projections/session_pipeline/visual/temporal_calendar_frame"
    Invoke-Step "Temporal calendar visual projection" { & $Julia "dev\scripts\export_t200plus_projection.jl" }

    $env:MOOS_PROJECTION_PRESET = "t189-recommendations"
    $env:MOOS_PROJECTION_OUT = "tmp/projections/session_pipeline/visual/t189_recommendation_frame"
    Invoke-Step "T189 recommendation visual projection" { & $Julia "dev\scripts\export_t200plus_projection.jl" }

    $health = Invoke-RestMethod -Uri "$BaseUrl/healthz" -TimeoutSec 5
    Invoke-Step "Calendar time-fabric projection" { & $Julia "dev\scripts\calendar_time_fabric_projection.jl" "--anchor-t" ([string]$health.t_day) }

    Invoke-Step "T189/T200 recommendation HG projection" { & $Julia "dev\scripts\t189_t200_recommendation_projection.jl" }

    Invoke-Step "T189 recommendation reconciliation" { & $Julia "dev\scripts\t189_recommendation_reconciliation.jl" "--base-url" $BaseUrl }

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
