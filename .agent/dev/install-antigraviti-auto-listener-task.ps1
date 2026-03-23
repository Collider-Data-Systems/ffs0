param(
    [string]$TaskName = "FFS0_Antigraviti_AutoListen",
    [string]$ScriptPath = "C:\Users\HP\FFS0_HPlaptop\ffs0-factory-super\.agent\dev\antigraviti-auto-listen.ps1"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$pwsh = (Get-Command pwsh).Source
$taskCommand = '"{0}" -NoLogo -WindowStyle Hidden -File "{1}" -StartFromNow' -f $pwsh, $ScriptPath

$taskCreated = $false
try {
    $createOutput = schtasks /Create /F /SC ONLOGON /RL LIMITED /TN $TaskName /TR $taskCommand 2>&1
    $queryOutput = schtasks /Query /TN $TaskName 2>&1
    if ($LASTEXITCODE -eq 0) {
        $taskCreated = $true
        Write-Output "Created/updated logon task: $TaskName"
        schtasks /Run /TN $TaskName | Out-Null
        Write-Output "Started task now: $TaskName"
    }
    else {
        Write-Warning ($createOutput | Out-String)
        Write-Warning ($queryOutput | Out-String)
    }
}
catch {
    Write-Warning $_.Exception.Message
}

if (-not $taskCreated) {
    $startupDir = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Startup"
    $launcherPath = Join-Path $startupDir "FFS0-Antigraviti-AutoListen.cmd"
    $launcher = "@echo off`r`n`"$pwsh`" -NoLogo -WindowStyle Hidden -File `"$ScriptPath`" -StartFromNow`r`n"
    Set-Content -LiteralPath $launcherPath -Value $launcher -Encoding ASCII
    Write-Output "Scheduled task unavailable; installed Startup launcher: $launcherPath"

    Start-Process -FilePath $pwsh -ArgumentList @("-NoLogo", "-WindowStyle", "Hidden", "-File", $ScriptPath, "-StartFromNow") -WindowStyle Hidden
    Write-Output "Started listener via Startup fallback launcher (singleton guarded)"
}
