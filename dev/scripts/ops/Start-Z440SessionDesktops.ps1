<#
Ensures the Z440 Windows 11 surface projection described by the tracked manifest.

Virtual desktops, windows, coordinates, and tabs are an S0 cache. Durable HG
anchors remain truth; this script only rebuilds a useful local realization.
#>

param(
    [string]$ConfigPath = '',
    [switch]$DryRun,
    [switch]$Desktop1Only,
    [switch]$ForceLaunch,
    [switch]$RepositionExisting,
    [switch]$SkipCache,
    [int]$StartupGraceSeconds = 0,
    [int]$HealthWaitSeconds = 45,
    [int]$LaunchDelaySeconds = 1,
    [int]$WindowWaitSeconds = 20
)

$ErrorActionPreference = 'Stop'

$script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$script:HostRoot = Split-Path $script:RepoRoot -Parent
$script:Config = $null
$script:CacheOutput = $null
$script:LaunchStats = [ordered]@{
    launched = 0
    existing = 0
    failed = 0
}

if ([string]::IsNullOrWhiteSpace($ConfigPath)) {
    $ConfigPath = Join-Path $script:RepoRoot 'dev\config\z440-session-desktops.json'
}

Add-Type -AssemblyName System.Windows.Forms

if (-not ('MoosWindowApi' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;

public static class MoosWindowApi
{
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [StructLayout(LayoutKind.Sequential)]
    public struct RECT
    {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }

    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc callback, IntPtr extraData);

    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int maxCount);

    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);

    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);

    [DllImport("user32.dll")]
    public static extern bool ShowWindowAsync(IntPtr hWnd, int command);

    [DllImport("user32.dll")]
    public static extern bool SetWindowPos(
        IntPtr hWnd,
        IntPtr hWndInsertAfter,
        int x,
        int y,
        int width,
        int height,
        uint flags
    );
}
'@
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

function ConvertTo-MoosFileUri {
    param([Parameter(Mandatory)][string]$Path)

    return 'file:///' + (($Path -replace '\\', '/') -replace '^/+', '')
}

function Test-CommandOrPath {
    param([Parameter(Mandatory)][string]$Exe)

    if ($Exe -match '^[A-Za-z]:\\|^\\\\|%|\$\{') {
        return Test-Path (Expand-MoosPathToken $Exe)
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
        }
        catch {
            Start-Sleep -Seconds 2
        }
    }

    Write-Warning "Timed out waiting for $Url"
    return $false
}

function Get-VirtualDesktopCommands {
    Import-Module VirtualDesktop -ErrorAction SilentlyContinue -DisableNameChecking | Out-Null

    $required = @(
        'Get-CurrentDesktop',
        'Get-Desktop',
        'Get-DesktopCount',
        'Get-DesktopName',
        'Move-Window',
        'New-Desktop',
        'Set-DesktopName',
        'Switch-Desktop',
        'Test-Window'
    )

    $resolved = @{}
    foreach ($name in $required) {
        $command = Get-Command $name -Module VirtualDesktop -ErrorAction SilentlyContinue
        if (-not $command) { return $null }
        $resolved[$name] = $command
    }

    return [pscustomobject]@{
        GetCurrentDesktop = $resolved['Get-CurrentDesktop']
        GetDesktop = $resolved['Get-Desktop']
        GetDesktopCount = $resolved['Get-DesktopCount']
        GetDesktopName = $resolved['Get-DesktopName']
        MoveWindow = $resolved['Move-Window']
        NewDesktop = $resolved['New-Desktop']
        SetDesktopName = $resolved['Set-DesktopName']
        SwitchDesktop = $resolved['Switch-Desktop']
        TestWindow = $resolved['Test-Window']
    }
}

function Get-MoosDesktopCount {
    param([Parameter(Mandatory)]$Commands)

    return [int](& $Commands.GetDesktopCount)
}

function Set-MoosDesktopCount {
    param(
        [Parameter(Mandatory)]$Commands,
        [Parameter(Mandatory)][int]$Count
    )

    $current = Get-MoosDesktopCount -Commands $Commands
    while ($current -lt $Count) {
        if ($DryRun) {
            Write-Host "  DRY New virtual desktop $($current + 1)"
        }
        else {
            & $Commands.NewDesktop | Out-Null
        }
        $current++
    }
}

function Get-MoosRegistryDesktopMap {
    $key = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VirtualDesktops'
    $properties = Get-ItemProperty -Path $key -ErrorAction Stop
    $bytes = [byte[]]$properties.VirtualDesktopIDs
    $rows = @()

    for ($offset = 0; $offset + 15 -lt $bytes.Length; $offset += 16) {
        $chunk = [byte[]]$bytes[$offset..($offset + 15)]
        $rows += [pscustomobject]@{
            index = ($offset / 16) + 1
            desktop_id = ([guid]::new($chunk)).ToString().ToLowerInvariant()
        }
    }

    return $rows
}

function Resolve-MoosDesktop {
    param(
        [Parameter(Mandatory)]$Commands,
        [Parameter(Mandatory)]$DesktopSpec
    )

    $expectedId = ([guid][string]$DesktopSpec.desktop_id).ToString().ToLowerInvariant()
    $row = Get-MoosRegistryDesktopMap | Where-Object { $_.desktop_id -eq $expectedId } | Select-Object -First 1
    if (-not $row) {
        Write-Warning "Desktop GUID $expectedId ($($DesktopSpec.name)) is not present; refusing index-only placement."
        return $null
    }

    if ([int]$row.index -ne [int]$DesktopSpec.index) {
        Write-Host "  MAP Desktop $($DesktopSpec.index) -> live index $($row.index) by GUID"
    }

    return & $Commands.GetDesktop ([int]$row.index - 1)
}

function Set-MoosDesktopName {
    param(
        [Parameter(Mandatory)]$Commands,
        [Parameter(Mandatory)]$DesktopObject,
        [Parameter(Mandatory)]$DesktopSpec
    )

    $currentName = [string](& $Commands.GetDesktopName -Desktop $DesktopObject)
    $desiredName = [string]$DesktopSpec.name
    if ($currentName -eq $desiredName) { return }

    if ($DryRun) {
        Write-Host "  DRY Rename '$currentName' -> '$desiredName'"
    }
    else {
        & $Commands.SetDesktopName -Desktop $DesktopObject -Name $desiredName | Out-Null
        Write-Host "  NAME $desiredName"
    }
}

function Switch-MoosDesktop {
    param(
        [Parameter(Mandatory)]$Commands,
        [Parameter(Mandatory)]$DesktopObject,
        [Parameter(Mandatory)][int]$Index
    )

    if ($DryRun) {
        Write-Host "  DRY Switch to Windows desktop $Index"
        return
    }

    & $Commands.SwitchDesktop -Desktop $DesktopObject -NoAnimation | Out-Null
    Start-Sleep -Milliseconds 350
}

function Get-MoosTopLevelWindows {
    $windows = [System.Collections.Generic.List[object]]::new()
    $callback = [MoosWindowApi+EnumWindowsProc]{
        param($handle, $unused)

        if ([MoosWindowApi]::IsWindowVisible($handle)) {
            $text = [System.Text.StringBuilder]::new(1024)
            [void][MoosWindowApi]::GetWindowText($handle, $text, $text.Capacity)
            $title = $text.ToString()
            if ($title) {
                [uint32]$ownerPid = 0
                [void][MoosWindowApi]::GetWindowThreadProcessId($handle, [ref]$ownerPid)
                $process = Get-Process -Id $ownerPid -ErrorAction SilentlyContinue
                if ($process) {
                    $rect = New-Object MoosWindowApi+RECT
                    [void][MoosWindowApi]::GetWindowRect($handle, [ref]$rect)
                    $windows.Add([pscustomobject]@{
                        handle = $handle
                        handle_value = $handle.ToInt64()
                        process = [string]$process.ProcessName
                        title = $title
                        x = $rect.Left
                        y = $rect.Top
                        width = $rect.Right - $rect.Left
                        height = $rect.Bottom - $rect.Top
                    })
                }
            }
        }
        return $true
    }

    [void][MoosWindowApi]::EnumWindows($callback, [IntPtr]::Zero)
    return @($windows)
}

function Get-MoosSurfaceLaunchSpec {
    param(
        [Parameter(Mandatory)]$Surface,
        [Parameter(Mandatory)]$DesktopSpec
    )

    if ([string]$Surface.kind -eq 'browser') {
        $arguments = @(
            ('--profile-directory="{0}"' -f [string]$script:Config.browser.profile_directory),
            '--new-window'
        )

        $cacheTitle = ''
        if ($Surface.include_cache -eq $true) {
            $surfaceKey = ([string]$DesktopSpec.surface_key).ToLowerInvariant() -replace '[^a-z0-9-]+', '-'
            $arguments += ConvertTo-MoosFileUri (Join-Path $script:CacheOutput ($surfaceKey + '.html'))
            $cacheTitle = 'mo:os surface cache - ' + [regex]::Escape($surfaceKey)
        }

        foreach ($url in @($Surface.urls)) {
            $arguments += Expand-MoosPathToken ([string]$url)
        }

        return [pscustomobject]@{
            exe = Expand-MoosPathToken ([string]$script:Config.browser.exe)
            arguments = $arguments
            working_directory = $script:RepoRoot
            process = [string]$script:Config.browser.process_name
            title_regex = $cacheTitle
        }
    }

    $arguments = @()
    foreach ($argument in @($Surface.args)) {
        $arguments += Expand-MoosPathToken ([string]$argument)
    }

    $exe = Expand-MoosPathToken ([string]$Surface.exe)
    $processName = if ($Surface.match -and $Surface.match.process) {
        [string]$Surface.match.process
    }
    else {
        [System.IO.Path]::GetFileNameWithoutExtension($exe)
    }

    return [pscustomobject]@{
        exe = $exe
        arguments = $arguments
        working_directory = if ($Surface.working_directory) { Expand-MoosPathToken ([string]$Surface.working_directory) } else { $null }
        process = $processName
        title_regex = if ($Surface.match -and $Surface.match.title_regex) { [string]$Surface.match.title_regex } else { '' }
    }
}

function Get-MoosMatchingWindows {
    param([Parameter(Mandatory)]$LaunchSpec)

    return @(Get-MoosTopLevelWindows | Where-Object {
        $_.process -ieq $LaunchSpec.process -and
        ([string]::IsNullOrWhiteSpace($LaunchSpec.title_regex) -or $_.title -match $LaunchSpec.title_regex)
    })
}

function Test-MoosWindowOnDesktop {
    param(
        $Commands,
        $DesktopObject,
        [Parameter(Mandatory)][IntPtr]$Handle
    )

    if (-not $Commands -or -not $DesktopObject) { return $true }
    try {
        return [bool](& $Commands.TestWindow -Desktop $DesktopObject -Hwnd $Handle)
    }
    catch {
        return $false
    }
}

function Get-MoosMonitorWorkingArea {
    param([Parameter(Mandatory)][int]$Slot)

    $monitorSpec = $script:Config.monitors | Where-Object { [int]$_.slot -eq $Slot } | Select-Object -First 1
    $screens = @([System.Windows.Forms.Screen]::AllScreens)
    $screen = $null
    if ($monitorSpec -and $monitorSpec.observed_device) {
        $screen = $screens | Where-Object { $_.DeviceName -eq [string]$monitorSpec.observed_device } | Select-Object -First 1
    }
    if (-not $screen) {
        $screen = $screens | Sort-Object { $_.Bounds.X } | Select-Object -Index ($Slot - 1)
    }
    if (-not $screen) {
        throw "Monitor slot $Slot is not available."
    }
    return $screen.WorkingArea
}

function Set-MoosWindowPlacement {
    param(
        [Parameter(Mandatory)][IntPtr]$Handle,
        [Parameter(Mandatory)][int]$MonitorSlot
    )

    if ($DryRun) {
        Write-Host "  DRY Place window on monitor $MonitorSlot"
        return
    }

    $area = Get-MoosMonitorWorkingArea -Slot $MonitorSlot
    [void][MoosWindowApi]::ShowWindowAsync($Handle, 9)
    $flags = [uint32](0x0004 -bor 0x0010 -bor 0x0040)
    $placed = [MoosWindowApi]::SetWindowPos(
        $Handle,
        [IntPtr]::Zero,
        $area.X,
        $area.Y,
        $area.Width,
        $area.Height,
        $flags
    )
    if (-not $placed) {
        Write-Warning "Could not place window handle $($Handle.ToInt64()) on monitor $MonitorSlot."
    }
}

function Start-MoosSurfaceWindow {
    param(
        [Parameter(Mandatory)]$Surface,
        [Parameter(Mandatory)]$DesktopSpec,
        $DesktopObject,
        $DesktopCommands
    )

    $launchSpec = Get-MoosSurfaceLaunchSpec -Surface $Surface -DesktopSpec $DesktopSpec
    if (-not (Test-CommandOrPath -Exe $launchSpec.exe)) {
        Write-Warning "Skipping $($Surface.label): executable not found ($($launchSpec.exe))"
        $script:LaunchStats.failed++
        return
    }

    $matching = @(Get-MoosMatchingWindows -LaunchSpec $launchSpec)
    $existing = @($matching | Where-Object {
        Test-MoosWindowOnDesktop -Commands $DesktopCommands -DesktopObject $DesktopObject -Handle $_.handle
    })

    if ($existing.Count -gt 0 -and -not $ForceLaunch) {
        Write-Host "  KEEP $($Surface.label)"
        if ($RepositionExisting) {
            Set-MoosWindowPlacement -Handle $existing[0].handle -MonitorSlot ([int]$Surface.monitor_slot)
        }
        $script:LaunchStats.existing++
        return
    }

    $argumentText = $launchSpec.arguments -join ' '
    if ($DryRun) {
        Write-Host "  DRY LAUNCH monitor $($Surface.monitor_slot): $($Surface.label) -> $($launchSpec.exe) $argumentText"
        $script:LaunchStats.launched++
        return
    }

    $beforeHandles = @($matching | ForEach-Object { $_.handle_value })
    $startParams = @{ FilePath = $launchSpec.exe }
    if ($launchSpec.arguments.Count -gt 0) { $startParams.ArgumentList = $launchSpec.arguments }
    if ($launchSpec.working_directory -and (Test-Path $launchSpec.working_directory)) {
        $startParams.WorkingDirectory = $launchSpec.working_directory
    }

    Write-Host "  OPEN monitor $($Surface.monitor_slot): $($Surface.label)"
    Start-Process @startParams | Out-Null

    $deadline = (Get-Date).AddSeconds($WindowWaitSeconds)
    $window = $null
    while ((Get-Date) -lt $deadline -and -not $window) {
        Start-Sleep -Milliseconds 300
        $candidates = @(Get-MoosMatchingWindows -LaunchSpec $launchSpec | Where-Object {
            $_.handle_value -notin $beforeHandles
        })
        if ($candidates.Count -gt 0) { $window = $candidates[0] }
    }

    if (-not $window) {
        $targetCandidates = @(Get-MoosMatchingWindows -LaunchSpec $launchSpec | Where-Object {
            Test-MoosWindowOnDesktop -Commands $DesktopCommands -DesktopObject $DesktopObject -Handle $_.handle
        })
        if ($targetCandidates.Count -gt 0) { $window = $targetCandidates[0] }
    }

    if (-not $window) {
        Write-Warning "Window did not appear within $WindowWaitSeconds seconds: $($Surface.label)"
        $script:LaunchStats.failed++
        return
    }

    if ($DesktopCommands -and $DesktopObject -and -not (Test-MoosWindowOnDesktop -Commands $DesktopCommands -DesktopObject $DesktopObject -Handle $window.handle)) {
        & $DesktopCommands.MoveWindow -Desktop $DesktopObject -Hwnd $window.handle | Out-Null
        Start-Sleep -Milliseconds 250
    }

    Set-MoosWindowPlacement -Handle $window.handle -MonitorSlot ([int]$Surface.monitor_slot)
    $script:LaunchStats.launched++
    Start-Sleep -Seconds $LaunchDelaySeconds
}

if (-not (Test-Path $ConfigPath)) {
    throw "Config not found: $ConfigPath"
}

$script:Config = Get-Content -Raw -Path $ConfigPath | ConvertFrom-Json
if ([int]$script:Config.schema_version -lt 2) {
    throw 'Start-Z440SessionDesktops requires z440-session-desktops schema_version 2 or later.'
}

$script:CacheOutput = Expand-MoosPathToken ([string]$script:Config.cache.output_directory)
$desktops = @($script:Config.desktops | Sort-Object index)
$startupDesktops = @($desktops | Where-Object { $_.startup -eq $true })
if ($Desktop1Only) {
    $startupDesktops = @($desktops | Where-Object { [int]$_.index -eq 1 })
}

Write-Host 'Z440 mo:os Windows surface startup'
Write-Host "Config: $ConfigPath"
Write-Host "Repo:   $script:RepoRoot"

if (-not $DryRun -and $StartupGraceSeconds -gt 0) {
    Write-Host "Waiting $StartupGraceSeconds seconds for the interactive desktop to settle..."
    Start-Sleep -Seconds $StartupGraceSeconds
}

if (-not $DryRun) {
    Write-Host 'Waiting for local federation health...'
    [void](Wait-MoosEndpoint -Url 'http://localhost:8000/healthz' -TimeoutSeconds $HealthWaitSeconds)
    [void](Wait-MoosEndpoint -Url 'http://localhost:9000/healthz' -TimeoutSeconds 10)
}

if (-not $SkipCache) {
    $cacheScript = Join-Path $PSScriptRoot 'New-Z440SurfaceCache.ps1'
    if ($DryRun) {
        & $cacheScript -ConfigPath $ConfigPath -DryRun -SkipHealthProbe
    }
    else {
        & $cacheScript -ConfigPath $ConfigPath
    }
}

$desktopCommands = Get-VirtualDesktopCommands
$originalDesktop = $null
if ($desktopCommands) {
    $maxDesktop = [int](($startupDesktops | Measure-Object -Property index -Maximum).Maximum)
    Set-MoosDesktopCount -Commands $desktopCommands -Count $maxDesktop
    $originalDesktop = & $desktopCommands.GetCurrentDesktop
}
else {
    Write-Warning 'VirtualDesktop 1.5.11+ is not installed. Launching Desktop 1 only without desktop placement.'
    $startupDesktops = @($startupDesktops | Where-Object { [int]$_.index -eq 1 })
}

try {
    foreach ($desktopSpec in $startupDesktops) {
        Write-Host ''
        Write-Host "Desktop $($desktopSpec.index): $($desktopSpec.name)"
        Write-Host "  Anchor: $($desktopSpec.anchor_urn)"

        $desktopObject = $null
        if ($desktopCommands) {
            $desktopObject = Resolve-MoosDesktop -Commands $desktopCommands -DesktopSpec $desktopSpec
            if (-not $desktopObject) { continue }
            Set-MoosDesktopName -Commands $desktopCommands -DesktopObject $desktopObject -DesktopSpec $desktopSpec
            Switch-MoosDesktop -Commands $desktopCommands -DesktopObject $desktopObject -Index ([int]$desktopSpec.index)
        }

        foreach ($surface in @($desktopSpec.windows)) {
            Start-MoosSurfaceWindow -Surface $surface -DesktopSpec $desktopSpec -DesktopObject $desktopObject -DesktopCommands $desktopCommands
        }
    }
}
finally {
    if ($desktopCommands -and $originalDesktop) {
        if ($DryRun) {
            Write-Host ''
            Write-Host 'DRY Restore original Windows desktop'
        }
        else {
            & $desktopCommands.SwitchDesktop -Desktop $originalDesktop -NoAnimation | Out-Null
        }
    }
}

Write-Host ''
Write-Host "Done. launched=$($script:LaunchStats.launched) existing=$($script:LaunchStats.existing) failed=$($script:LaunchStats.failed)"
Write-Host "Cache: $script:CacheOutput"