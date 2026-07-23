# Registers the canonical Z440 engine and Windows-surface startup tasks.

[CmdletBinding()]
param(
    [switch]$NoElevation
)

$ErrorActionPreference = 'Stop'

function Test-IsAdministrator {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [System.Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdministrator)) {
    if ($NoElevation) {
        throw 'Administrator privileges are required. Rerun without -NoElevation to accept the Windows elevation prompt.'
    }

    $pwshPath = (Get-Command pwsh.exe -ErrorAction Stop).Source
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    Write-Host 'Requesting Administrator approval for Z440 scheduled-task setup...'
    try {
        $elevated = Start-Process -FilePath $pwshPath -ArgumentList $arguments -Verb RunAs -Wait -PassThru
        exit $elevated.ExitCode
    }
    catch {
        throw "Administrator approval is required to update the scheduled tasks: $($_.Exception.Message)"
    }
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$pwsh = (Get-Command pwsh.exe -ErrorAction Stop).Source
$userId = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $userId
$principal = New-ScheduledTaskPrincipal -UserId $userId -LogonType Interactive
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit 0 -MultipleInstances IgnoreNew -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)

# Helper to upsert a task
function Set-AutostartTask {
    param($Name, $Exe, $ActionArguments)
    $action = if ($ActionArguments) {
        New-ScheduledTaskAction -Execute $Exe -Argument $ActionArguments
    } else {
        New-ScheduledTaskAction -Execute $Exe
    }
    Unregister-ScheduledTask -TaskName $Name -Confirm:$false -ErrorAction SilentlyContinue
    Register-ScheduledTask -TaskName $Name -TaskPath '\' -Action $action -Trigger $trigger -Principal $principal -Settings $settings | Out-Null
    $registeredAction = @(Get-ScheduledTask -TaskName $Name -ErrorAction Stop).Actions | Select-Object -First 1
    if ($registeredAction.Execute -ne $Exe -or $registeredAction.Arguments -ne $ActionArguments) {
        throw "Scheduled task '$Name' did not retain its expected action."
    }
    Write-Host "  OK  $Name"
}

Write-Host "Registering autostart tasks for Z440..."

# 1. Federation (kernels + router)
$federationScript = Join-Path $repoRoot 'dev\scripts\ops\start_federation_z440.ps1'
Set-AutostartTask 'moos-kernel-autostart' $pwsh "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$federationScript`""

# 2. Windows 11 surface projection (desktops + windows + browser tabs)
$surfaceScript = Join-Path $repoRoot 'dev\scripts\ops\Start-Z440SessionDesktops.ps1'
Set-AutostartTask 'moos-session-desktops-autostart' $pwsh "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$surfaceScript`" -StartupGraceSeconds 20"

# Retire the older one-app-per-task launchers. The session desktop launcher owns app startup now.
foreach ($legacyTask in @('antigravity-autostart', 'vscode-autostart', 'chrome-autostart', 'claude-autostart')) {
    Unregister-ScheduledTask -TaskName $legacyTask -Confirm:$false -ErrorAction SilentlyContinue
}

# Archive the April-era Startup-folder batches. They duplicate the tracked federation task
# and contain stale topology flags, but remain available for forensic comparison.
$startupFolder = [Environment]::GetFolderPath('Startup')
$archiveFolder = Join-Path (Split-Path $repoRoot -Parent) 'tmp\startup-disabled-t264'
foreach ($legacyFile in @('moos-full-federation.bat', 'moos-kernel.bat', 'moos-router.bat')) {
    $source = Join-Path $startupFolder $legacyFile
    if (Test-Path $source) {
        New-Item -ItemType Directory -Path $archiveFolder -Force | Out-Null
        Move-Item -Path $source -Destination (Join-Path $archiveFolder $legacyFile) -Force
        Write-Host "  ARCHIVE  $legacyFile"
    }
}

Write-Host ""
Write-Host "Done. Verify with: Get-ScheduledTask | Where-Object TaskName -match 'autostart' | ft TaskName,State"
