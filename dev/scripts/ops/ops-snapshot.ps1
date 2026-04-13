param(
    [string]$RootPath = (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))),
    [string]$RemoteRouterUrl = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "=== $Title ===" -ForegroundColor Cyan
}

function Test-HasProperty {
    param([object]$Object, [string]$Name)
    if ($null -eq $Object) { return $false }
    return $Object.PSObject.Properties.Match($Name).Count -gt 0
}

function Get-RepoSummary {
    param([string]$Repo, [string]$Path)

    if (-not (Test-Path $Path)) {
        return [pscustomobject]@{ Repo = $Repo; Branch = "missing"; Commit = "-"; Dirty = -1 }
    }

    $statusLines = @()
    try { $statusLines = @(git -C $Path status --short --branch 2>$null) } catch {}

    $lineCount  = @($statusLines).Count
    $header     = if ($lineCount -gt 0) { $statusLines[0] } else { "status unavailable" }
    $dirtyCount = if ($lineCount -gt 1) { $lineCount - 1 } else { 0 }
    $commit     = "-"
    try { $commit = git -C $Path rev-parse --short HEAD 2>$null } catch {}

    return [pscustomobject]@{ Repo = $Repo; Branch = $header; Commit = $commit; Dirty = $dirtyCount }
}

function Get-Health {
    param([string]$Service, [string]$Url)
    try {
        $resp   = Invoke-RestMethod -Uri $Url -Method Get -TimeoutSec 3
        $status = if (Test-HasProperty $resp "status") { "$($resp.status)" } else { "unknown" }
        $logLen = "-"
        if (Test-HasProperty $resp "log_len") {
            $logLen = "$($resp.log_len)"
        } elseif (Test-HasProperty $resp "kernels") {
            $local = $resp.kernels | Where-Object { $_.url -eq "http://localhost:8000" } | Select-Object -First 1
            if ($null -ne $local -and $null -ne $local.log_len) { $logLen = "$($local.log_len)" }
        }
        return [pscustomobject]@{ Service = $Service; Url = $Url; Status = $status; LogLen = $logLen }
    } catch {
        return [pscustomobject]@{ Service = $Service; Url = $Url; Status = "down"; LogLen = "-" }
    }
}

Write-Section "MO:OS OPS SNAPSHOT"
Write-Host ("Time: {0}" -f (Get-Date).ToString("yyyy-MM-dd HH:mm:ss"))
Write-Host ("RootPath: {0}" -f $RootPath)

Write-Section "Repositories"
@(
    @{ Repo = "ffs0";        Path = (Join-Path $RootPath "ffs0") },
    @{ Repo = "moos-kernel"; Path = (Join-Path $RootPath "moos-kernel") },
    @{ Repo = "moos-router"; Path = (Join-Path $RootPath "moos-router") }
) | ForEach-Object { Get-RepoSummary -Repo $_.Repo -Path $_.Path } | Format-Table -AutoSize

Write-Section "Local Services"
$kernel = Get-Health -Service "kernel" -Url "http://localhost:8000/healthz"
$router = Get-Health -Service "router" -Url "http://localhost:9000/healthz"
@($kernel, $router) | Format-Table -AutoSize

if ($RemoteRouterUrl) {
    Write-Section "Remote Router"
    Get-Health -Service "remote-router" -Url $RemoteRouterUrl | Format-Table -AutoSize
}

Write-Section "Autostart Files"
$startupDir = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Startup"
$kernelBat  = Join-Path $startupDir "moos-kernel.bat"
$routerBat  = Join-Path $startupDir "moos-router.bat"
@(
    [pscustomobject]@{ File = $kernelBat; Exists = (Test-Path $kernelBat) },
    [pscustomobject]@{ File = $routerBat; Exists = (Test-Path $routerBat) }
) | Format-Table Exists, File -AutoSize

Write-Section "Verdict"
$issue = $false
if ($kernel.Status -ne "ok")              { Write-Host "Kernel health is not ok."       -ForegroundColor Yellow; $issue = $true }
if ($router.Status -ne "ok")              { Write-Host "Router health is not ok."       -ForegroundColor Yellow; $issue = $true }
if (-not (Test-Path $kernelBat) -or
    -not (Test-Path $routerBat))          { Write-Host "Missing Startup batch file(s)." -ForegroundColor Yellow; $issue = $true }

if ($issue) { Write-Host "Action needed." -ForegroundColor Yellow; exit 1 }
Write-Host "Ready: local multi-repo and kernel/router stack looks healthy." -ForegroundColor Green
