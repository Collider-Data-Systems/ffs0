param(
    [string]$BaseUrl = "http://localhost:8000",
    [string]$Julia = $env:JULIA_EXE,
    [string]$SessionUrn = "",
    [string]$ActorUrn = "",
    [string]$Focus = "",
    [int]$AnchorT = 0
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($Julia)) {
    $juliaCandidates = @(
        "C:\Users\Geurt\AppData\Local\Programs\Julia-1.12.6\bin\julia.exe",
        "C:\Users\hp\AppData\Local\Programs\Julia-1.12.6\bin\julia.exe",
        "C:\Users\maass\AppData\Local\Programs\Julia-1.12.6\bin\julia.exe",
        "julia"
    )
    foreach ($candidate in $juliaCandidates) {
        if ((Test-Path $candidate) -or (Get-Command $candidate -ErrorAction SilentlyContinue)) {
            $Julia = $candidate
            break
        }
    }
}

function Test-MoosNodeExists {
    param(
        [Parameter(Mandatory)][string]$Url,
        [Parameter(Mandatory)][string]$Urn
    )
    try {
        $nodePath = $Url.TrimEnd('/') + '/state/nodes/' + [uri]::EscapeDataString($Urn)
        Invoke-RestMethod -Uri $nodePath -TimeoutSec 5 | Out-Null
        return $true
    } catch {
        return $false
    }
}

function Test-MoosHealth {
    param([Parameter(Mandatory)][string]$Url)
    try {
        Invoke-RestMethod -Uri ($Url.TrimEnd('/') + '/healthz') -TimeoutSec 5 | Out-Null
        return $true
    } catch {
        return $false
    }
}

function Resolve-SessionContext {
    param([Parameter(Mandatory)][string]$Url)

    $contexts = @(
        [pscustomobject]@{
            SessionUrn = "urn:moos:session:sam.governance"
            ActorUrn = "urn:moos:agent:claude-code.hp-laptop"
            Focus = "session context projection for VS Code, agents, harnesses, and graph visualization"
        },
        [pscustomobject]@{
            SessionUrn = "urn:moos:session:sam.z440-vscode-projection-lead"
            ActorUrn = "urn:moos:agent:vscode.hp-z440.primary"
            Focus = "Z440 VS Code projection lead parity, federated readback, Julia pipeline, dashboard gate review, and Project #4 HG URN repair"
        },
        [pscustomobject]@{
            SessionUrn = "urn:moos:session:sam.hpprodesk-setup"
            ActorUrn = "urn:moos:agent:vscode.hpprodesk.primary"
            Focus = "HP ProDesk workstation bootstrap, session wiring readback, projection pipeline, and router peer readiness"
        }
    )

    foreach ($context in $contexts) {
        if (Test-MoosNodeExists -Url $Url -Urn $context.SessionUrn) {
            return $context
        }
    }

    return $contexts[0]
}

$resolvedContext = Resolve-SessionContext -Url $BaseUrl
if ([string]::IsNullOrWhiteSpace($SessionUrn)) { $SessionUrn = $resolvedContext.SessionUrn }
if ([string]::IsNullOrWhiteSpace($ActorUrn)) { $ActorUrn = $resolvedContext.ActorUrn }
if ([string]::IsNullOrWhiteSpace($Focus)) { $Focus = $resolvedContext.Focus }

$ProjectionBaseUrl = $BaseUrl
if ($SessionUrn -eq "urn:moos:session:sam.z440-vscode-projection-lead" -and $BaseUrl.TrimEnd('/') -eq "http://localhost:8000" -and (Test-MoosHealth -Url "http://localhost:9000")) {
    $ProjectionBaseUrl = "http://localhost:9000"
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
    Write-Host "Base URL: $BaseUrl"
    Write-Host "Projection read URL: $ProjectionBaseUrl"
    Write-Host "Session: $SessionUrn"
    Write-Host "Actor: $ActorUrn"
    Write-Host "Julia: $Julia"

    Invoke-Step "Session context projection" {
        & $Julia "dev\scripts\session_context_projection.jl" `
            "--base-url" $ProjectionBaseUrl `
            "--session-urn" $SessionUrn `
            "--actor-urn" $ActorUrn `
            "--focus" $Focus
    }
    Invoke-Step "Graph artifact projection" { & $Julia "dev\scripts\graph_artifact_projection.jl" "--base-url" $ProjectionBaseUrl }
    Invoke-Step "T189 recommendation graph artifact projection" {
        & $Julia "dev\scripts\graph_artifact_projection.jl" `
            "--base-url" $ProjectionBaseUrl `
            "--root-urn" "urn:moos:purpose:sam.t189-t200plus-time-fabric-convergence" `
            "--root-urns" "urn:moos:session:sam.governance;urn:moos:purpose:sam.t189-t200plus-time-fabric-convergence;urn:moos:derivation:guido.t189-calendar-event-g-ingest-decision;urn:moos:view_filter:sam.t189-time-fabric-session-lens;urn:moos:group:my-tiny-data-collider" `
            "--radius" "2" `
            "--wfs" "WF01,WF18,WF19,WF21" `
            "--ports" "causes,caused-by,composes,composed-by,filtered-by,filters-session,owns,owned-by,pinned-by-session,pins-urn" `
            "--types" "calendar_event,derivation,group,program,purpose,session,view_filter" `
            "--match" "t189|t200|calendar|github|cytoscape|my-tiny-data-collider|convergence|governance|application" `
            "--out-base" "tmp/projections/session_pipeline/graph_artifacts/t189_recommendation_engineering"
    }

    $env:MOOS_PROJECTION_PRESET = "session-occasion"
    $env:MOOS_BASE_URL = $ProjectionBaseUrl
    $env:MOOS_PROJECTION_OUT = "tmp/projections/session_pipeline/visual/session_occasion_frame"
    Invoke-Step "Session occasion visual projection" { & $Julia "dev\scripts\export_t200plus_projection.jl" }

    $env:MOOS_PROJECTION_PRESET = "temporal-calendar"
    $env:MOOS_PROJECTION_OUT = "tmp/projections/session_pipeline/visual/temporal_calendar_frame"
    Invoke-Step "Temporal calendar visual projection" { & $Julia "dev\scripts\export_t200plus_projection.jl" }

    $env:MOOS_PROJECTION_PRESET = "t189-recommendations"
    $env:MOOS_PROJECTION_OUT = "tmp/projections/session_pipeline/visual/t189_recommendation_frame"
    Invoke-Step "T189 recommendation visual projection" { & $Julia "dev\scripts\export_t200plus_projection.jl" }

    $anchorTValue = $AnchorT
    if ($anchorTValue -le 0) {
        $health = Invoke-RestMethod -Uri "$ProjectionBaseUrl/healthz" -TimeoutSec 5
        if ($null -ne $health.t_day) {
            $anchorTValue = [int]$health.t_day
        } else {
            $localHealth = Invoke-RestMethod -Uri "http://localhost:8000/healthz" -TimeoutSec 5
            $anchorTValue = [int]$localHealth.t_day
        }
    }
    Invoke-Step "Calendar time-fabric projection" { & $Julia "dev\scripts\calendar_time_fabric_projection.jl" "--anchor-t" ([string]$anchorTValue) }

    Invoke-Step "T189/T200 recommendation HG projection" { & $Julia "dev\scripts\t189_t200_recommendation_projection.jl" }

    Invoke-Step "T189 recommendation reconciliation" { & $Julia "dev\scripts\t189_recommendation_reconciliation.jl" "--base-url" $ProjectionBaseUrl }

    Invoke-Step "Session pipeline MVP gate" {
        & $Julia "dev\scripts\session_pipeline_mvp_gate.jl" `
            "--base-url" $ProjectionBaseUrl `
            "--session-urn" $SessionUrn `
            "--actor-urn" $ActorUrn
    }

    Invoke-Step "Surface context atlas" { & $Julia "dev\scripts\surface_context_atlas.jl" "--base-url" $ProjectionBaseUrl }

    Invoke-Step "Session pipeline MVP gate with atlas" {
        & $Julia "dev\scripts\session_pipeline_mvp_gate.jl" `
            "--base-url" $ProjectionBaseUrl `
            "--session-urn" $SessionUrn `
            "--actor-urn" $ActorUrn
    }

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
