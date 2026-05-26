[CmdletBinding()]
param(
    [ValidateSet('Check', 'Stage', 'ClipboardStage', 'ApiAuthListen', 'ApiFetch', 'Pipeline')]
    [string]$Mode = 'Stage',

    [string]$SourcePath = 'scratch\keep\t195-t206',
    [string]$OutDir = 'tmp\projections\session_pipeline\keep_t206',
    [string]$BaseUrl = 'http://localhost:8000',
    [string]$JuliaPath = '',
    [string]$CredentialsPath = 'secrets\google_keep_oauth_client.json',
    [string]$TokenPath = 'secrets\google_keep_token.json',
    [switch]$UseCalendarOAuthClient,
    [switch]$OpenBrowser,
    [switch]$SkipLiveState,
    [switch]$RunPipeline,
    [int]$TStart = 195,
    [int]$TEnd = 206,
    [bool]$IncludeUndated = $true
)

$ErrorActionPreference = 'Stop'

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..\..')
Set-Location $RepoRoot

if ($UseCalendarOAuthClient) {
    $CredentialsPath = 'secrets\google_calendar_oauth_client.json'
}

function Resolve-JuliaPath {
    param([string]$RequestedPath)

    if (-not [string]::IsNullOrWhiteSpace($RequestedPath)) {
        if (-not (Test-Path $RequestedPath)) { throw "Julia not found at $RequestedPath" }
        return (Resolve-Path $RequestedPath).Path
    }

    $defaultJulia = 'C:\Users\maass\AppData\Local\Programs\Julia-1.12.6\bin\julia.exe'
    if (Test-Path $defaultJulia) { return $defaultJulia }

    $command = Get-Command julia -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }

    throw 'Julia executable not found. Pass -JuliaPath <path-to-julia.exe>.'
}

$script:JuliaExe = Resolve-JuliaPath -RequestedPath $JuliaPath

function Invoke-JuliaScript {
    param(
        [Parameter(Mandatory)][string]$ScriptPath,
        [string[]]$Arguments = @()
    )

    & $script:JuliaExe $ScriptPath @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Julia script failed with exit code ${LASTEXITCODE}: $ScriptPath"
    }
}

function Invoke-HealthCheck {
    try {
        $health = Invoke-RestMethod -Uri ("$BaseUrl".TrimEnd('/') + '/healthz') -TimeoutSec 5
        [pscustomobject]@{
            Status = $health.status
            Ontology = $health.ontology_version
            TDay = $health.t_day
            LogLen = $health.log_len
        } | Format-List | Out-String | Write-Host
    }
    catch {
        Write-Warning "Could not read kernel health at ${BaseUrl}: $($_.Exception.Message)"
    }
}

function Get-MoosNode {
    param([Parameter(Mandatory)][string]$Urn)

    try {
        $path = 'state/nodes/' + [uri]::EscapeDataString($Urn)
        Invoke-RestMethod -Uri ("$BaseUrl".TrimEnd('/') + '/' + $path) -TimeoutSec 5
    }
    catch {
        $null
    }
}

function Get-MoosRelationsFrom {
    param([Parameter(Mandatory)][string]$Urn)

    try {
        $path = 'state/relations/src/' + [uri]::EscapeDataString($Urn)
        @(Invoke-RestMethod -Uri ("$BaseUrl".TrimEnd('/') + '/' + $path) -TimeoutSec 5)
    }
    catch {
        @()
    }
}

function Invoke-GraphAnchorCheck {
    $anchors = @(
        @{ Role = 'session'; Urn = 'urn:moos:session:sam.governance' },
        @{ Role = 'Keep channel'; Urn = 'urn:moos:channel:google.keep.sam' },
        @{ Role = 'T206 carrier program'; Urn = 'urn:moos:program:sam.t206.keep-api-mvp-delivery' },
        @{ Role = 'T206 status KI'; Urn = 'urn:moos:ki:gdrive.t206-keep-api-mvp-status' },
        @{ Role = 'Keep OAuth external_op'; Urn = 'urn:moos:external_op:sam.t206-google-keep-oauth-scope-approval' }
    )

    Write-Host 'Existing graph anchors:' -ForegroundColor Cyan
    $anchorRows = foreach ($anchor in $anchors) {
        $node = Get-MoosNode -Urn $anchor.Urn
        $status = if ($null -eq $node) { 'missing' } else { 'ok' }
        $type = if ($null -eq $node) { '' } else { [string]$node.type_id }
        [pscustomobject]@{ Role = $anchor.Role; Status = $status; Type = $type; Urn = $anchor.Urn }
    }
    $anchorRows | Format-Table -AutoSize | Out-String | Write-Host

    $sessionRelations = Get-MoosRelationsFrom -Urn 'urn:moos:session:sam.governance'
    $keepRelations = Get-MoosRelationsFrom -Urn 'urn:moos:channel:google.keep.sam'
    $programRelations = Get-MoosRelationsFrom -Urn 'urn:moos:program:sam.t206.keep-api-mvp-delivery'
    $relationSummary = [ordered]@{
        'WF19 governance pins/occupancy/purpose from session' = @($sessionRelations | Where-Object { $_.rewrite_category -eq 'WF19' }).Count
        'WF12 Keep channel evidence links' = @($keepRelations | Where-Object { $_.rewrite_category -eq 'WF12' }).Count
        'WF18 T206 program composition links' = @($programRelations | Where-Object { $_.rewrite_category -eq 'WF18' }).Count
        'WF21 T206 program causal links' = @($programRelations | Where-Object { $_.rewrite_category -eq 'WF21' }).Count
    }
    [pscustomobject]$relationSummary | Format-List | Out-String | Write-Host
}

function Invoke-ProjectionReadback {
    $sessionPackPath = 'tmp\projections\session_pipeline\session_context\current_session.json'
    $mvpGatePath = 'tmp\projections\session_pipeline\mvp\session_pipeline_gate.json'
    $t206GraphPath = 'tmp\projections\session_pipeline\graph_artifacts\t206_keep_mvp_engineering.json'

    Write-Host 'Projection readback:' -ForegroundColor Cyan
    if (Test-Path $sessionPackPath) {
        $sessionPack = Get-Content -Path $sessionPackPath -Raw | ConvertFrom-Json
        [pscustomobject]@{
            Artifact = $sessionPackPath
            Actor = $sessionPack.handoff.session_header.actor
            Session = $sessionPack.handoff.session_header.session_urn
            Runtime = $sessionPack.handoff.session_header.kernel_base_url
        } | Format-List | Out-String | Write-Host
    }
    else {
        Write-Warning "Missing session projection: $sessionPackPath"
    }

    if (Test-Path $mvpGatePath) {
        $gate = Get-Content -Path $mvpGatePath -Raw | ConvertFrom-Json
        [pscustomobject]@{
            Artifact = $mvpGatePath
            Overall = $gate.overall_status
            Pass = $gate.summary.pass
            Warn = $gate.summary.warn
            Fail = $gate.summary.fail
        } | Format-List | Out-String | Write-Host
    }

    if (Test-Path $t206GraphPath) {
        $graph = Get-Content -Path $t206GraphPath -Raw | ConvertFrom-Json
        [pscustomobject]@{
            Artifact = $t206GraphPath
            Nodes = $graph.node_count
            Relations = $graph.relation_count
        } | Format-List | Out-String | Write-Host
    }
}

function Invoke-KeepCheck {
    New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
    Invoke-JuliaScript -ScriptPath 'dev\scripts\google_keep_fetch.jl' -Arguments @(
        '--mode', 'check',
        '--credentials', $CredentialsPath,
        '--token', $TokenPath,
        '--out', (Join-Path $OutDir 'google_keep_credential_check.json')
    )
}

function Invoke-KeepStage {
    param([Parameter(Mandatory)][string]$StageSource)

    New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
    $includeUndatedText = if ($IncludeUndated) { 'true' } else { 'false' }
    $skipLiveText = if ($SkipLiveState) { 'true' } else { 'false' }
    Invoke-JuliaScript -ScriptPath 'dev\scripts\keep_t195_t206_ingest_stage.jl' -Arguments @(
        '--source', $StageSource,
        '--base-url', $BaseUrl,
        '--out', (Join-Path $OutDir 'keep_t195_t206_stage.json'),
        '--markdown-out', (Join-Path $OutDir 'keep_t195_t206_stage.md'),
        '--t-start', [string]$TStart,
        '--t-end', [string]$TEnd,
        '--include-undated', $includeUndatedText,
        '--skip-live-state', $skipLiveText
    )

    $stagePath = Join-Path $OutDir 'keep_t195_t206_stage.json'
    if (Test-Path $stagePath) {
        $stage = Get-Content -Path $stagePath -Raw | ConvertFrom-Json
        Write-Host "Stage selected $($stage.selected_note_count) / $($stage.notes_total) notes; apply_ready=$($stage.candidate_hg.apply_ready)" -ForegroundColor Cyan
    }
}

function Save-ClipboardKeepSource {
    if (-not (Get-Command Get-Clipboard -ErrorAction SilentlyContinue)) {
        throw 'Get-Clipboard is not available in this PowerShell host.'
    }

    $text = Get-Clipboard -Raw
    if ([string]::IsNullOrWhiteSpace($text)) {
        throw 'Clipboard is empty. Copy one or more Google Keep notes first, then rerun -Mode ClipboardStage.'
    }

    $manualDir = Join-Path $SourcePath 'manual'
    New-Item -ItemType Directory -Force -Path $manualDir | Out-Null
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $path = Join-Path $manualDir "keep-clipboard-$stamp.md"
    $header = @"
# Google Keep Clipboard Capture $stamp

Source: Google Keep web clipboard via harness-neutral ingest runner.
Review status: S0 source material until the stage report is approved.

"@
    Set-Content -Path $path -Value ($header + $text) -Encoding UTF8
    Write-Host "Captured clipboard source: $path" -ForegroundColor Cyan
    return $path
}

function Invoke-KeepApiFetch {
    New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
    $includeUndatedText = if ($IncludeUndated) { 'true' } else { 'false' }
    Invoke-JuliaScript -ScriptPath 'dev\scripts\google_keep_fetch.jl' -Arguments @(
        '--mode', 'fetch',
        '--credentials', $CredentialsPath,
        '--token', $TokenPath,
        '--out-dir', 'scratch\keep\t195-t206\api',
        '--out', (Join-Path $OutDir 'google_keep_fetch_result.json'),
        '--stage', 'true',
        '--stage-out', (Join-Path $OutDir 'keep_t195_t206_stage.json'),
        '--stage-markdown-out', (Join-Path $OutDir 'keep_t195_t206_stage.md'),
        '--base-url', $BaseUrl,
        '--t-start', [string]$TStart,
        '--t-end', [string]$TEnd,
        '--include-undated', $includeUndatedText
    )
}

function Invoke-KeepApiAuthListen {
    $openBrowserText = if ($OpenBrowser) { 'true' } else { 'false' }
    Invoke-JuliaScript -ScriptPath 'dev\scripts\google_keep_fetch.jl' -Arguments @(
        '--mode', 'auth-listen',
        '--credentials', $CredentialsPath,
        '--token', $TokenPath,
        '--open-browser', $openBrowserText
    )
}

function Invoke-SessionPipeline {
    powershell -NoProfile -ExecutionPolicy Bypass -File 'dev\scripts\projections\run-session-pipeline.ps1'
    if ($LASTEXITCODE -ne 0) {
        throw "Session pipeline failed with exit code $LASTEXITCODE"
    }
}

Write-Host "Keep ingest harness mode: $Mode" -ForegroundColor Cyan
Write-Host "Repo: $RepoRoot"
Write-Host "Julia: $script:JuliaExe"

switch ($Mode) {
    'Check' {
        Invoke-HealthCheck
        Invoke-GraphAnchorCheck
        Invoke-ProjectionReadback
        Invoke-KeepCheck
    }
    'Stage' {
        Invoke-KeepStage -StageSource $SourcePath
    }
    'ClipboardStage' {
        $capturedPath = Save-ClipboardKeepSource
        Invoke-KeepStage -StageSource $capturedPath
    }
    'ApiAuthListen' {
        Invoke-KeepApiAuthListen
    }
    'ApiFetch' {
        Invoke-KeepApiFetch
    }
    'Pipeline' {
        Invoke-SessionPipeline
    }
}

if ($RunPipeline -and $Mode -ne 'Pipeline') {
    Invoke-SessionPipeline
}

Write-Host 'Keep ingest harness completed.' -ForegroundColor Green