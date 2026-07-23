<#
Builds a local, timestamped view of the Z440 desktop placement manifest.

The generated files are an S0 projection cache. They describe where HG-backed
and reference surfaces should appear, but they are not graph identity or truth.
#>

param(
    [string]$ConfigPath = '',
    [string]$OutputPath = '',
    [switch]$DryRun,
    [switch]$SkipHealthProbe
)

$ErrorActionPreference = 'Stop'

$script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$script:HostRoot = Split-Path $script:RepoRoot -Parent

if ([string]::IsNullOrWhiteSpace($ConfigPath)) {
    $ConfigPath = Join-Path $script:RepoRoot 'dev\config\z440-session-desktops.json'
}

function Expand-MoosCacheToken {
    param([Parameter(Mandatory)][string]$Value)

    $expanded = [Environment]::ExpandEnvironmentVariables($Value)
    $expanded = $expanded.Replace('${ffs0}', $script:RepoRoot)
    $expanded = $expanded.Replace('${hpz440}', $script:HostRoot)
    return $expanded
}

function ConvertTo-HtmlText {
    param($Value)

    if ($null -eq $Value) { return '' }
    return [System.Net.WebUtility]::HtmlEncode([string]$Value)
}

function ConvertTo-CachePageName {
    param([Parameter(Mandatory)][string]$Key)

    return (($Key.ToLowerInvariant() -replace '[^a-z0-9-]+', '-') -replace '^-|-$', '') + '.html'
}

function Get-HealthSnapshot {
    param($Desktop)

    if ($SkipHealthProbe -or -not $Desktop.engine -or -not $Desktop.engine.health_url) {
        return [pscustomobject]@{ status = 'not-probed'; detail = '' }
    }

    try {
        $health = Invoke-RestMethod -Uri ([string]$Desktop.engine.health_url) -TimeoutSec 2
        $detailParts = @()
        if ($health.ontology_version) { $detailParts += "ontology $($health.ontology_version)" }
        if ($null -ne $health.log_len) { $detailParts += "log $($health.log_len)" }
        if ($null -ne $health.max_log_seq) { $detailParts += "seq $($health.max_log_seq)" }
        return [pscustomobject]@{
            status = if ($health.status) { [string]$health.status } else { 'reachable' }
            detail = $detailParts -join ' / '
        }
    }
    catch {
        return [pscustomobject]@{ status = 'offline'; detail = $_.Exception.Message }
    }
}

function Get-SharedStyles {
    return @'
:root {
  color-scheme: light;
  --ink: #171817;
  --muted: #656961;
  --paper: #f7f5ef;
  --line: #c9c7be;
  --green: #276749;
  --blue: #2457a7;
  --red: #a23a2a;
  --yellow: #d6a719;
  --panel: rgba(255, 255, 255, 0.9);
}
* { box-sizing: border-box; }
body {
  margin: 0;
  color: var(--ink);
  background-color: var(--paper);
  background-image: linear-gradient(#ddd9ce 1px, transparent 1px), linear-gradient(90deg, #ddd9ce 1px, transparent 1px);
  background-size: 24px 24px;
  font-family: Bahnschrift, "Aptos Display", sans-serif;
  letter-spacing: 0;
}
main { width: min(1440px, calc(100% - 32px)); margin: 0 auto; padding: 28px 0 48px; }
header { border-top: 8px solid var(--ink); border-bottom: 1px solid var(--ink); padding: 18px 0 16px; }
h1 { margin: 0; font-size: clamp(1.8rem, 4vw, 3.6rem); line-height: 0.98; font-weight: 800; overflow-wrap: anywhere; }
h2 { margin: 0 0 10px; font-size: 1.15rem; }
p { margin: 6px 0; line-height: 1.45; }
a { color: var(--blue); text-decoration-thickness: 1px; text-underline-offset: 3px; }
code, .mono { font-family: "Cascadia Code", Consolas, monospace; font-size: 0.86em; overflow-wrap: anywhere; }
.meta { display: flex; flex-wrap: wrap; gap: 8px 18px; margin-top: 14px; color: var(--muted); }
.meta > * { min-width: 0; overflow-wrap: anywhere; }
.status { display: inline-flex; align-items: center; gap: 7px; font-weight: 700; }
.status::before { content: ""; width: 10px; height: 10px; background: var(--yellow); border: 1px solid var(--ink); }
.status.ok::before, .status.reachable::before { background: var(--green); }
.status.offline::before { background: var(--red); }
.desktop-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(270px, 1fr)); gap: 12px; margin-top: 20px; }
.desktop-card { min-height: 190px; padding: 16px; background: var(--panel); border: 1px solid var(--ink); border-radius: 4px; }
.desktop-card .number { color: var(--red); font: 800 0.82rem "Cascadia Code", monospace; }
.desktop-card .name { margin: 8px 0 12px; font-size: 1.05rem; overflow-wrap: anywhere; }
.desktop-card .intent { color: var(--muted); }
.monitor-strip { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 10px; margin-top: 20px; }
.monitor { min-height: 260px; background: var(--panel); border: 2px solid var(--ink); border-radius: 4px; padding: 12px; }
.monitor-id { display: flex; justify-content: space-between; border-bottom: 1px solid var(--line); padding-bottom: 8px; margin-bottom: 10px; }
.surface { padding: 8px 0; border-bottom: 1px solid var(--line); }
.surface:last-child { border-bottom: 0; }
.surface-kind { color: var(--green); font: 700 0.76rem "Cascadia Code", monospace; text-transform: uppercase; }
.tabs { margin: 8px 0 0; padding-left: 18px; }
.tabs li { margin: 5px 0; overflow-wrap: anywhere; }
.back { display: inline-block; margin-bottom: 14px; font-weight: 700; }
@media (max-width: 900px) {
  .monitor-strip { grid-template-columns: 1fr 1fr; }
}
@media (max-width: 560px) {
  main { width: min(100% - 20px, 1440px); padding-top: 12px; }
  .monitor-strip { grid-template-columns: 1fr; }
  .monitor { min-height: 0; }
}
'@
}

function New-CacheDocument {
    param(
        [Parameter(Mandatory)][string]$Title,
        [Parameter(Mandatory)][string]$Body
    )

    $safeTitle = ConvertTo-HtmlText $Title
    $styles = Get-SharedStyles
    return @"
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>$safeTitle</title>
  <style>$styles</style>
</head>
<body>
<main>
$Body
</main>
</body>
</html>
"@
}

if (-not (Test-Path $ConfigPath)) {
    throw "Config not found: $ConfigPath"
}

$config = Get-Content -Raw -Path $ConfigPath | ConvertFrom-Json
if ([int]$config.schema_version -lt 2) {
    throw 'Surface cache generation requires z440-session-desktops schema_version 2 or later.'
}

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Expand-MoosCacheToken ([string]$config.cache.output_directory)
}

$desktops = @($config.desktops | Sort-Object index)
$pageRows = foreach ($desktop in $desktops) {
    [pscustomobject]@{
        desktop = $desktop
        page = ConvertTo-CachePageName ([string]$desktop.surface_key)
        health = Get-HealthSnapshot -Desktop $desktop
    }
}

if ($DryRun) {
    Write-Host "DRY surface cache: $OutputPath"
    foreach ($row in $pageRows) {
        Write-Host "  DRY $($row.page) <- Desktop $($row.desktop.index) $($row.desktop.name)"
    }
    Write-Host '  DRY index.html'
    return
}

New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
$generatedAt = (Get-Date).ToUniversalTime().ToString('o')

foreach ($row in $pageRows) {
    $desktop = $row.desktop
    $healthClass = ([string]$row.health.status).ToLowerInvariant() -replace '[^a-z]+', '-'
    $anchorText = if ($desktop.anchor_urn) { ConvertTo-HtmlText $desktop.anchor_urn } else { 'reference-only surface' }
    $engineText = if ($desktop.engine -and $desktop.engine.urn) { ConvertTo-HtmlText $desktop.engine.urn } else { 'no local engine binding' }
    $desktopName = ConvertTo-HtmlText $desktop.name
    $intent = ConvertTo-HtmlText $desktop.intent
    $healthStatus = ConvertTo-HtmlText $row.health.status
    $healthDetail = ConvertTo-HtmlText $row.health.detail

    $monitorBuilder = [System.Text.StringBuilder]::new()
    [void]$monitorBuilder.AppendLine('<section class="monitor-strip" aria-label="Four monitor placement">')
    foreach ($monitor in @($config.monitors | Sort-Object slot)) {
        $slot = [int]$monitor.slot
        [void]$monitorBuilder.AppendLine('<article class="monitor">')
        [void]$monitorBuilder.AppendLine(('<div class="monitor-id"><strong>Monitor {0}</strong><span>{1}</span></div>' -f $slot, (ConvertTo-HtmlText $monitor.label)))
        $surfaces = @($desktop.windows | Where-Object { [int]$_.monitor_slot -eq $slot })
        if ($surfaces.Count -eq 0) {
            [void]$monitorBuilder.AppendLine('<p class="mono">unassigned</p>')
        }
        foreach ($surface in $surfaces) {
            [void]$monitorBuilder.AppendLine('<div class="surface">')
            [void]$monitorBuilder.AppendLine(('<div class="surface-kind">{0}</div>' -f (ConvertTo-HtmlText $surface.kind)))
            [void]$monitorBuilder.AppendLine(('<h2>{0}</h2>' -f (ConvertTo-HtmlText $surface.label)))
            if ($surface.urls) {
                [void]$monitorBuilder.AppendLine('<ul class="tabs">')
                foreach ($url in @($surface.urls)) {
                    $expandedUrl = Expand-MoosCacheToken ([string]$url)
                    $safeUrl = ConvertTo-HtmlText $expandedUrl
                    [void]$monitorBuilder.AppendLine(('<li><a href="{0}">{0}</a></li>' -f $safeUrl))
                }
                [void]$monitorBuilder.AppendLine('</ul>')
            }
            elseif ($surface.exe) {
                [void]$monitorBuilder.AppendLine(('<p class="mono">{0}</p>' -f (ConvertTo-HtmlText (Expand-MoosCacheToken ([string]$surface.exe)))))
            }
            [void]$monitorBuilder.AppendLine('</div>')
        }
        [void]$monitorBuilder.AppendLine('</article>')
    }
    [void]$monitorBuilder.AppendLine('</section>')

    $body = @"
<a class="back" href="index.html">All desktops</a>
<header>
  <div class="mono">Desktop $($desktop.index) / $([System.Net.WebUtility]::HtmlEncode([string]$desktop.surface_kind))</div>
  <h1>$desktopName</h1>
  <p>$intent</p>
  <div class="meta">
    <span class="status $healthClass">$healthStatus $healthDetail</span>
    <span class="mono">$anchorText</span>
    <span class="mono">$engineText</span>
  </div>
</header>
$($monitorBuilder.ToString())
"@
    $document = New-CacheDocument -Title "mo:os surface cache - $($desktop.surface_key)" -Body $body
    Set-Content -Path (Join-Path $OutputPath $row.page) -Value $document -Encoding utf8
}

$cardBuilder = [System.Text.StringBuilder]::new()
[void]$cardBuilder.AppendLine('<section class="desktop-grid" aria-label="Desktop placement cache">')
foreach ($row in $pageRows) {
    $desktop = $row.desktop
    $healthClass = ([string]$row.health.status).ToLowerInvariant() -replace '[^a-z]+', '-'
    [void]$cardBuilder.AppendLine('<article class="desktop-card">')
    [void]$cardBuilder.AppendLine(('<div class="number">DESKTOP {0:00} / {1}</div>' -f [int]$desktop.index, (ConvertTo-HtmlText $desktop.surface_kind)))
    [void]$cardBuilder.AppendLine(('<h2 class="name"><a href="{0}">{1}</a></h2>' -f $row.page, (ConvertTo-HtmlText $desktop.name)))
    [void]$cardBuilder.AppendLine(('<p class="intent">{0}</p>' -f (ConvertTo-HtmlText $desktop.intent)))
    [void]$cardBuilder.AppendLine(('<p class="status {0}">{1}</p>' -f $healthClass, (ConvertTo-HtmlText $row.health.status)))
    [void]$cardBuilder.AppendLine(('<p class="mono">{0}</p>' -f (ConvertTo-HtmlText $desktop.desktop_id)))
    [void]$cardBuilder.AppendLine('</article>')
}
[void]$cardBuilder.AppendLine('</section>')

$indexBody = @"
<header>
  <div class="mono">hp-z440 / local projection cache</div>
  <h1>Z440 surface placement</h1>
  <p>Four monitors across 14 virtual desktops, generated from the tracked placement manifest.</p>
  <div class="meta">
    <span class="mono">generated $generatedAt</span>
    <span class="mono">HG remains the semantic source of truth</span>
  </div>
</header>
$($cardBuilder.ToString())
"@
$indexDocument = New-CacheDocument -Title 'mo:os Z440 surface placement cache' -Body $indexBody
Set-Content -Path (Join-Path $OutputPath 'index.html') -Value $indexDocument -Encoding utf8

$cacheMetadata = [ordered]@{
    schema_version = 1
    generated_at = $generatedAt
    source_config = (Resolve-Path $ConfigPath).Path
    status = 'projection-cache'
    desktop_count = $desktops.Count
    monitor_count = @($config.monitors).Count
    pages = @($pageRows | ForEach-Object {
        [ordered]@{
            index = [int]$_.desktop.index
            desktop_id = [string]$_.desktop.desktop_id
            name = [string]$_.desktop.name
            surface_key = [string]$_.desktop.surface_key
            anchor_urn = $_.desktop.anchor_urn
            page = [string]$_.page
            health_status = [string]$_.health.status
        }
    })
}
$cacheMetadata | ConvertTo-Json -Depth 6 | Set-Content -Path (Join-Path $OutputPath 'surface-cache.json') -Encoding utf8

Write-Host "Surface cache: $OutputPath"
Write-Host "  HTML: $(Join-Path $OutputPath 'index.html')"
Write-Host "  JSON: $(Join-Path $OutputPath 'surface-cache.json')"