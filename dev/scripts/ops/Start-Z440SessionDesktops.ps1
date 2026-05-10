<#
Starts the Z440 human workspace as a Windows 11 projection of mo:os sessions.

Windows 11 virtual desktops are an OS/user-interface surface, not HG truth. The
manifest in dev/config/z440-session-desktops.json maps Desktop N to durable
session URNs and the apps that make that session useful.

Without an optional VirtualDesktop PowerShell module, this script intentionally
launches only Desktop 1 so a login task does not dump every session window onto
one desktop. Install a compatible VirtualDesktop module later to let the same
manifest create/switch desktops before launching Desktop 2+ apps.
#>

param(
    [string]$ConfigPath = '',
    [switch]$DryRun,
    [switch]$Desktop1Only,
    [int]$HealthWaitSeconds = 45,
    [int]$LaunchDelaySeconds = 2
)

$ErrorActionPreference = 'Stop'

$script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$script:HostRoot = Split-Path $script:RepoRoot -Parent

if ([string]::IsNullOrWhiteSpace($ConfigPath)) {
    $ConfigPath = Join-Path $script:RepoRoot 'dev\config\z440-session-desktops.json'
}

function Expand-MoosPathToken {
    param([Parameter(Mandatory)][string]$Value)

    $expanded = [Environment]::ExpandEnvironmentVariables($Value)
    $expanded = $expanded.Replace('${ffs0}', $script:RepoRoot)
    $expanded = $expanded.Replace('${hpz440}', $script:HostRoot)
    $expanded = $expanded.Replace('${ffs0_forward}', ($script:RepoRoot -replace '\\', '/'))
    $expanded = $expanded.Replace('${hpz440_forward}', ($script:HostRoot -replace '\\', '/'))
    return $expanded
}

function Test-CommandOrPath {
    param([Parameter(Mandatory)][string]$Exe)

    if ($Exe -match '^[A-Za-z]:\\|^\\\\|%|\$\{') {
        $expanded = Expand-MoosPathToken $Exe
        return (Test-Path $expanded)
    }

    return [bool](Get-Command $Exe -ErrorAction SilentlyContinue)
}

function Wait-MoosEndpoint {
    param(
        [Parameter(Mandatory)][string]$Url,
        [Parameter(Mandatory)][int]$TimeoutSeconds
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        try {
            $health = Invoke-RestMethod -Uri $Url -TimeoutSec 3
            if ($health.status -eq 'ok') {
                Write-Host "  OK  $Url"
                return $true
            }
        } catch {
            Start-Sleep -Seconds 2
        }
    }

    Write-Warning "Timed out waiting for $Url"
    return $false
}

function Get-VirtualDesktopCommands {
    Import-Module VirtualDesktop -ErrorAction SilentlyContinue | Out-Null
    $newDesktop = Get-Command New-Desktop -ErrorAction SilentlyContinue
    $switchDesktop = Get-Command Switch-Desktop -ErrorAction SilentlyContinue
    if (-not $newDesktop -or -not $switchDesktop) {
        return $null
    }

    [pscustomobject]@{
        NewDesktop = $newDesktop
        SwitchDesktop = $switchDesktop
        GetDesktopList = Get-Command Get-DesktopList -ErrorAction SilentlyContinue
        GetDesktop = Get-Command Get-Desktop -ErrorAction SilentlyContinue
    }
}

function Get-DesktopCount {
    param($Commands)

    if ($Commands.GetDesktopList) {
        return @(& $Commands.GetDesktopList).Count
    }
    if ($Commands.GetDesktop) {
        return @(& $Commands.GetDesktop).Count
    }
    return 0
}

function Set-DesktopCount {
    param(
        [Parameter(Mandatory)]$Commands,
        [Parameter(Mandatory)][int]$Count
    )

    $current = Get-DesktopCount -Commands $Commands
    while ($current -lt $Count) {
        if ($DryRun) {
            Write-Host "  DRY New virtual desktop $($current + 1)"
        } else {
            & $Commands.NewDesktop | Out-Null
        }
        $current++
    }
}

function Switch-MoosDesktop {
    param(
        [Parameter(Mandatory)]$Commands,
        [Parameter(Mandatory)][int]$Index
    )

    $zeroBasedIndex = $Index - 1
    if ($DryRun) {
        Write-Host "  DRY Switch to Windows desktop $Index"
        return $true
    }

    try {
        & $Commands.SwitchDesktop -Desktop $zeroBasedIndex | Out-Null
        Start-Sleep -Milliseconds 500
        return $true
    } catch {
        try {
            & $Commands.SwitchDesktop $zeroBasedIndex | Out-Null
            Start-Sleep -Milliseconds 500
            return $true
        } catch {
            Write-Warning "VirtualDesktop module is present, but Switch-Desktop did not accept index $Index. Launching only desktop 1 is safer."
            return $false
        }
    }
}

function Start-MoosApp {
    param(
        [Parameter(Mandatory)]$App,
        [Parameter(Mandatory)]$Desktop
    )

    $exe = Expand-MoosPathToken ([string]$App.exe)
    $appArguments = @()
    if ($App.args) {
        foreach ($arg in @($App.args)) {
            $appArguments += (Expand-MoosPathToken ([string]$arg))
        }
    }

    $workingDirectory = $null
    if ($App.working_directory) {
        $workingDirectory = Expand-MoosPathToken ([string]$App.working_directory)
    }

    if (-not (Test-CommandOrPath -Exe ([string]$App.exe))) {
        Write-Warning "Skipping $($App.label): executable not found ($exe)"
        return
    }

    $argText = ($appArguments -join ' ')
    if ($DryRun) {
        Write-Host "  DRY Desktop $($Desktop.index): $($App.label) -> $exe $argText"
        return
    }

    $startParams = @{ FilePath = $exe }
    if ($appArguments.Count -gt 0) { $startParams.ArgumentList = $appArguments }
    if ($workingDirectory -and (Test-Path $workingDirectory)) { $startParams.WorkingDirectory = $workingDirectory }

    Write-Host "  APP Desktop $($Desktop.index): $($App.label)"
    Start-Process @startParams | Out-Null
    Start-Sleep -Seconds $LaunchDelaySeconds
}

if (-not (Test-Path $ConfigPath)) {
    throw "Config not found: $ConfigPath"
}

$config = Get-Content -Raw -Path $ConfigPath | ConvertFrom-Json
$desktops = @($config.desktops | Sort-Object index)
$startupDesktops = @($desktops | Where-Object { $_.startup -eq $true })
if ($Desktop1Only) {
    $startupDesktops = @($desktops | Where-Object { $_.index -eq 1 })
}

Write-Host "Z440 mo:os Windows session desktop startup"
Write-Host "Config: $ConfigPath"
Write-Host "Repo:   $script:RepoRoot"

Write-Host "Waiting for local federation health..."
[void](Wait-MoosEndpoint -Url 'http://localhost:8000/healthz' -TimeoutSeconds $HealthWaitSeconds)
[void](Wait-MoosEndpoint -Url 'http://localhost:9000/healthz' -TimeoutSeconds 10)

$desktopCommands = Get-VirtualDesktopCommands
if ($desktopCommands) {
    $maxDesktop = ($startupDesktops | Measure-Object -Property index -Maximum).Maximum
    Set-DesktopCount -Commands $desktopCommands -Count $maxDesktop
} else {
    Write-Warning "VirtualDesktop PowerShell module is not installed. Launching Desktop 1 startup apps only; desktop 2+ remains a session map."
    $startupDesktops = @($startupDesktops | Where-Object { $_.index -eq 1 })
}

foreach ($desktop in $startupDesktops) {
    Write-Host ""
    Write-Host "Desktop $($desktop.index): $($desktop.name)"
    Write-Host "  Session: $($desktop.session_urn)"

    if ($desktopCommands) {
        $switched = Switch-MoosDesktop -Commands $desktopCommands -Index ([int]$desktop.index)
        if (-not $switched -and [int]$desktop.index -ne 1) { continue }
    }

    foreach ($app in @($desktop.apps)) {
        Start-MoosApp -App $app -Desktop $desktop
    }
}

Write-Host ""
Write-Host "Done. Use Win+Tab to rename/reorder Windows desktops to match dev/config/z440-session-desktops.json."