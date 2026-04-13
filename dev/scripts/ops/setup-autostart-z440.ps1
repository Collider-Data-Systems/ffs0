#Requires -RunAsAdministrator
# Setup all autostart tasks for Z440 (hp user)
# Run once after initial setup or when tasks need updating.

$ErrorActionPreference = 'Stop'

$trigger   = New-ScheduledTaskTrigger -AtLogOn -User 'hp-z440\hp'
$principal = New-ScheduledTaskPrincipal -UserId 'hp-z440\hp' -LogonType Interactive
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

# 2. Antigravity
Set-AutostartTask 'antigravity-autostart' 'C:\Users\hp\AppData\Local\Programs\antigravity\Antigravity.exe' '"D:\HPZ440\ffs0\ffs0.code-workspace"'

# 3. VS Code
Set-AutostartTask 'vscode-autostart' 'C:\Users\hp\AppData\Local\Programs\Microsoft VS Code\Code.exe' '"D:\HPZ440\ffs0\ffs0.code-workspace"'

# 4. Chrome
Set-AutostartTask 'chrome-autostart' 'C:\Program Files\Google\Chrome\Application\chrome.exe' $null

# 5. Claude (Store app via explorer)
Set-AutostartTask 'claude-autostart' 'C:\Windows\explorer.exe' 'shell:AppsFolder\Claude_pzs8sxrjxfjjc!Claude'

Write-Host ""
Write-Host "Done. Verify with: Get-ScheduledTask | Where-Object TaskName -match 'autostart' | ft TaskName,State"
