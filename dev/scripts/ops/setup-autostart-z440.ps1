#Requires -RunAsAdministrator
# Setup all autostart tasks for Z440 (hp user)
# Run once after initial setup or when tasks need updating.

$ErrorActionPreference = 'Stop'

$trigger   = New-ScheduledTaskTrigger -AtLogOn -User 'desktop-42d00rd\hp'
$principal = New-ScheduledTaskPrincipal -UserId 'desktop-42d00rd\hp' -LogonType Interactive
$settings  = New-ScheduledTaskSettingsSet -ExecutionTimeLimit 0 -MultipleInstances IgnoreNew

# Helper to upsert a task
function Set-AutostartTask {
    param($Name, $Exe, $Args)
    $action = if ($Args) {
        New-ScheduledTaskAction -Execute $Exe -Argument $Args
    } else {
        New-ScheduledTaskAction -Execute $Exe
    }
    Unregister-ScheduledTask -TaskName $Name -Confirm:$false -ErrorAction SilentlyContinue
    Register-ScheduledTask -TaskName $Name -TaskPath '\' -Action $action -Trigger $trigger -Principal $principal -Settings $settings | Out-Null
    Write-Host "  OK  $Name"
}

Write-Host "Registering autostart tasks for Z440..."

# 1. Federation (kernels + router)
Set-AutostartTask 'moos-kernel-autostart' 'powershell.exe' '-ExecutionPolicy Bypass -WindowStyle Hidden -File D:\HPZ440\start_federation.ps1'

# 2. Windows 11 session desktops (apps + per-desktop mo:os session map)
Set-AutostartTask 'moos-session-desktops-autostart' 'powershell.exe' '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File D:\HPZ440\ffs0\dev\scripts\ops\Start-Z440SessionDesktops.ps1'

# Retire the older one-app-per-task launchers. The session desktop launcher owns app startup now.
foreach ($legacyTask in @('antigravity-autostart', 'vscode-autostart', 'chrome-autostart', 'claude-autostart')) {
    Unregister-ScheduledTask -TaskName $legacyTask -Confirm:$false -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "Done. Verify with: Get-ScheduledTask | Where-Object TaskName -match 'autostart' | ft TaskName,State"
