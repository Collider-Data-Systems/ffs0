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
            ActorUrn = "urn:moos:agent:vscode.hp-laptop.copilot"
            HarnessKind = "VS Code/Copilot"
            HarnessAgentUrn = "urn:moos:agent:vscode.hp-laptop.copilot"
            HarnessEvidence = "VS Code GitHub Copilot chat surface; Claude Code is not assumed to be running."
            Focus = "session context projection for VS Code, agents, harnesses, and graph visualization"
        },
        [pscustomobject]@{
            SessionUrn = "urn:moos:session:sam.z440-vscode-projection-lead"
            ActorUrn = "urn:moos:agent:vscode.hp-z440.primary"
            HarnessKind = "VS Code/Copilot"
            HarnessAgentUrn = "urn:moos:agent:vscode.hp-z440.primary"
            HarnessEvidence = "Z440 VS Code/Copilot projection lead surface."
            Focus = "Z440 VS Code projection lead parity, federated readback, Julia pipeline, dashboard gate review, and Project #4 HG URN repair"
        },
        [pscustomobject]@{
            SessionUrn = "urn:moos:session:sam.hpprodesk-setup"
            ActorUrn = "urn:moos:agent:vscode.hpprodesk.primary"
            HarnessKind = "VS Code/Copilot"
            HarnessAgentUrn = "urn:moos:agent:vscode.hpprodesk.primary"
            HarnessEvidence = "HP ProDesk VS Code/Copilot setup surface."
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

$actorWasProvided = -not [string]::IsNullOrWhiteSpace($ActorUrn)
$resolvedContext = Resolve-SessionContext -Url $BaseUrl
if ([string]::IsNullOrWhiteSpace($SessionUrn)) { $SessionUrn = $resolvedContext.SessionUrn }
if ([string]::IsNullOrWhiteSpace($ActorUrn)) { $ActorUrn = $resolvedContext.ActorUrn }
if ([string]::IsNullOrWhiteSpace($Focus)) { $Focus = $resolvedContext.Focus }
$HarnessKind = if ($resolvedContext.PSObject.Properties['HarnessKind']) { [string]$resolvedContext.HarnessKind } else { '' }
$HarnessAgentUrn = if ($actorWasProvided) { $ActorUrn } elseif ($resolvedContext.PSObject.Properties['HarnessAgentUrn']) { [string]$resolvedContext.HarnessAgentUrn } else { $ActorUrn }
$HarnessEvidence = if ($resolvedContext.PSObject.Properties['HarnessEvidence']) { [string]$resolvedContext.HarnessEvidence } else { '' }

$ProjectionBaseUrl = $BaseUrl
if ($SessionUrn -eq "urn:moos:session:sam.z440-vscode-projection-lead" -and $BaseUrl.TrimEnd('/') -eq "http://localhost:8000" -and (Test-MoosHealth -Url "http://localhost:9000")) {
    $ProjectionBaseUrl = "http://localhost:9000"
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")
$oldPreset = $env:MOOS_PROJECTION_PRESET
$oldBaseUrl = $env:MOOS_BASE_URL
$oldOut = $env:MOOS_PROJECTION_OUT
$oldContextAgents = $env:MOOS_PROJECTION_CONTEXT_AGENT_URNS

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
    Write-Host "Harness: $HarnessKind / $HarnessAgentUrn"
    Write-Host "Julia: $Julia"

    Invoke-Step "Session context projection" {
        & $Julia "dev\scripts\session_context_projection.jl" `
            "--base-url" $ProjectionBaseUrl `
            "--session-urn" $SessionUrn `
            "--actor-urn" $ActorUrn `
            "--harness-kind" $HarnessKind `
            "--harness-agent-urn" $HarnessAgentUrn `
            "--harness-evidence" $HarnessEvidence `
            "--focus" $Focus
    }
    Invoke-Step "Graph artifact projection" { & $Julia "dev\scripts\graph_artifact_projection.jl" "--base-url" $ProjectionBaseUrl "--context-agent-urns" $ActorUrn }
    Invoke-Step "Temporal calendar graph artifact projection" {
        & $Julia "dev\scripts\graph_artifact_projection.jl" `
            "--base-url" $ProjectionBaseUrl `
            "--root-urn" "urn:moos:program:sam.t200plus.temporal-projection-fabric" `
            "--root-urns" "urn:moos:session:sam.governance;urn:moos:channel:google.calendar.sam;urn:moos:program:sam.t200plus.temporal-projection-fabric;urn:moos:program:sam.t200plus.google-calendar-projection-contract;urn:moos:program:sam.t200plus.google-calendar-projection-planner;urn:moos:program:sam.t200plus.google-calendar-oauth-writer;urn:moos:derivation:guido.t200plus-google-calendar-write-result" `
            "--radius" "2" `
            "--wfs" "WF18,WF19,WF21" `
            "--ports" "causes,caused-by,composes,composed-by,has-purpose,purpose-of-session,pinned-by-session,pins-urn" `
            "--types" "calendar_event,channel,clock,derivation,program,purpose,session,view_filter" `
            "--match" "calendar|temporal|time|clock|t200|google|governance|projection|writer|oauth|time-fabric|purpose" `
            "--context-agent-urns" $ActorUrn `
            "--out-base" "tmp/projections/session_pipeline/graph_artifacts/temporal_calendar_engineering"
    }
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
            "--context-agent-urns" $ActorUrn `
            "--out-base" "tmp/projections/session_pipeline/graph_artifacts/t189_recommendation_engineering"
    }
    Invoke-Step "Calendar scope graph artifact projection" {
        & $Julia "dev\scripts\graph_artifact_projection.jl" `
            "--base-url" $ProjectionBaseUrl `
            "--root-urn" "urn:moos:program:sam.t200plus.temporal-projection-fabric" `
            "--root-urns" "urn:moos:session:sam.governance;urn:moos:channel:google.calendar.sam;urn:moos:program:sam.t200plus.temporal-projection-fabric;urn:moos:program:sam.t200plus.google-calendar-projection-contract;urn:moos:program:sam.t200plus.google-calendar-projection-planner;urn:moos:program:sam.t200plus.google-calendar-oauth-writer;urn:moos:derivation:guido.t200plus-google-calendar-write-result;urn:moos:derivation:guido.t189-calendar-event-g-ingest-decision;urn:moos:program:sam.t189.calendar-event-g-ingest-shape;urn:moos:purpose:sam.t189-t200plus-time-fabric-convergence;urn:moos:view_filter:sam.t189-time-fabric-session-lens" `
            "--radius" "3" `
            "--wfs" "WF01,WF07,WF18,WF19,WF21" `
            "--ports" "*" `
            "--types" "calendar_event,channel,claim,clock,derivation,external_op,group,knowledge_item,program,purpose,session,tool_call,view_filter" `
            "--match" "calendar|temporal|time|clock|t189|t200|google|governance|session|event|projection|writer|oauth|time-fabric|surface|recommendation|convergence" `
                "--context-agent-urns" $ActorUrn `
            "--out-base" "tmp/projections/session_pipeline/graph_artifacts/calendar_scope_engineering"
    }

            $env:MOOS_PROJECTION_CONTEXT_AGENT_URNS = $ActorUrn
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

    $env:MOOS_PROJECTION_PRESET = "calendar-scope"
    $env:MOOS_PROJECTION_OUT = "tmp/projections/session_pipeline/visual/calendar_scope_frame"
    Invoke-Step "Calendar scope visual projection" { & $Julia "dev\scripts\export_t200plus_projection.jl" }

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
    Invoke-Step "Calendar time-fabric projection" {
        & $Julia "dev\scripts\calendar_time_fabric_projection.jl" `
            "--anchor-t" ([string]$anchorTValue) `
            "--scope-artifact" "tmp/projections/session_pipeline/graph_artifacts/calendar_scope_engineering.json" `
            "--write-result-path" "tmp/projections/session_pipeline/calendar/calendar_time_fabric_write_result.json" `
            "--lock-written-sources" "true"
    }

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
    if ($null -eq $oldContextAgents) {
        Remove-Item Env:MOOS_PROJECTION_CONTEXT_AGENT_URNS -ErrorAction SilentlyContinue
    } else {
        $env:MOOS_PROJECTION_CONTEXT_AGENT_URNS = $oldContextAgents
    }
    Pop-Location
}
