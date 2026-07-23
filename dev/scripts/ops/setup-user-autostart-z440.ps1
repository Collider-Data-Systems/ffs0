<#
Registers the Z440 surface projection for the current user without elevation.

The administrator-owned legacy app tasks are reported but not changed here.
Run setup-autostart-z440.ps1 from an elevated PowerShell 7 terminal later to
replace those tasks and converge on the canonical scheduled-task setup.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$Remove
)

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$hostRoot = Split-Path $repoRoot -Parent
$pwsh = (Get-Command pwsh.exe -ErrorAction Stop).Source
$surfaceScript = Join-Path $repoRoot 'dev\scripts\ops\Start-Z440SessionDesktops.ps1'
$runKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$valueName = 'moos-session-desktops-autostart'
$command = '"{0}" -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "{1}" -StartupGraceSeconds 20' -f $pwsh, $surfaceScript

if ($Remove) {
    if ($PSCmdlet.ShouldProcess("$runKey\$valueName", 'Remove current-user logon startup')) {
        Remove-ItemProperty -Path $runKey -Name $valueName -ErrorAction SilentlyContinue
    }
    Write-Host "Removed current-user startup value: $valueName"
    return
}

if ($PSCmdlet.ShouldProcess("$runKey\$valueName", 'Register current-user logon startup')) {
    New-Item -Path $runKey -Force | Out-Null
    Set-ItemProperty -Path $runKey -Name $valueName -Value $command
}

$startupFolder = [Environment]::GetFolderPath('Startup')
$archiveFolder = Join-Path $hostRoot 'tmp\startup-disabled-t264'
foreach ($legacyFile in @('moos-full-federation.bat', 'moos-kernel.bat', 'moos-router.bat')) {
    $source = Join-Path $startupFolder $legacyFile
    if (Test-Path $source) {
        if ($PSCmdlet.ShouldProcess($source, "Archive under $archiveFolder")) {
            New-Item -ItemType Directory -Path $archiveFolder -Force | Out-Null
            Move-Item -Path $source -Destination (Join-Path $archiveFolder $legacyFile) -Force
        }
    }
}

Write-Host "Current-user startup: $command"
Write-Host "Legacy Startup batches: $archiveFolder"

$legacyTasks = Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
    $_.TaskName -in @('antigravity-autostart', 'vscode-autostart', 'chrome-autostart', 'claude-autostart')
}
if ($legacyTasks) {
    Write-Warning 'Administrator-owned legacy app tasks remain. Run setup-autostart-z440.ps1 elevated to retire them.'
}