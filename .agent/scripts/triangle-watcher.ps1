# Triangle Watcher - Native Windows Toast Notifications for the mo:os Agent Triangle

function Initialize-ToastRuntime {
    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
    [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null
    [Windows.UI.Notifications.ToastNotification, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
}

function Send-Toast {
    param (
        [string]$AgentName,
        [string]$Channel,
        [string]$Message
    )

    $AppId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'

    $XmlString = @"
<toast>
    <visual>
        <binding template="ToastText02">
            <text id="1">mo:os Triangle - $Channel</text>
            <text id="2">${AgentName}: $Message</text>
        </binding>
    </visual>
    <audio src="ms-winsoundevent:Notification.Default"/>
</toast>
"@

    $XmlDocument = [Windows.Data.Xml.Dom.XmlDocument]::new()
    $XmlDocument.LoadXml($XmlString)

    $Toast = [Windows.UI.Notifications.ToastNotification]::new($XmlDocument)
    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($AppId).Show($Toast)
}

function Invoke-ChannelChanged {
    param (
        [string]$FilePath,
        [string]$FileName
    )

    Start-Sleep -Milliseconds 200
    $content = Get-Content -Path $FilePath -TotalCount 10 -ErrorAction Stop
    $latestMessage = $content | Where-Object { $_ -match "^### \[" } | Select-Object -First 1

    if ($latestMessage) {
        if ($latestMessage -match "\] (.*?) (?:->|→) (?:.*?): (.*)") {
            $agent = $Matches[1]
            $msg = $Matches[2]
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Update in $FileName from $agent"
            Send-Toast -AgentName $agent -Channel $FileName -Message $msg
        } else {
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Update in $FileName (Unparseable format)"
            Send-Toast -AgentName "Unknown Agent" -Channel $FileName -Message "Wrote to channel."
        }
    }
}

function Invoke-ChannelAction {
    param (
        [string]$FilePath,
        [string]$FileName
    )

    # Execution is only allowed for ClaudeCode direction messages in testoff.
    if ($FileName -ine "testoff.md") { return }

    Start-Sleep -Milliseconds 200
    $content = Get-Content -Path $FilePath -TotalCount 15 -ErrorAction Stop
    $topMessage = $content | Where-Object { $_ -match "^### \[" } | Select-Object -First 1

    if (-not $topMessage) { return }

    if ($topMessage -match "^### \[.*\]\s+(.*?)\s+(?:->|→)\s*([a-zA-Z-]+)\s*:") {
        $agent = $Matches[1]
        $messageType = $Matches[2]

        if ($agent -ieq "ClaudeCode" -and $messageType -ieq "direction") {
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] AUTO-TRIGGER: direction detected in testoff.md"
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Executing go test + health check..."

            # Pull latest repo state before test cycle.
            git -C ".\moos" pull origin main 2>&1 | ForEach-Object { Write-Host "  $_" }

            Push-Location ".\moos\platform\kernel"
            try {
                $testResult = go test ./... 2>&1
                $testResult | ForEach-Object { Write-Host "  $_" }
            } finally {
                Pop-Location
            }

            try {
                $health = Invoke-RestMethod "http://localhost:8000/healthz" -ErrorAction Stop
                Write-Host "  healthz: status=$($health.status) nodes=$($health.nodes) wires=$($health.wires)"
            } catch {
                Write-Host "  healthz: kernel not running (start manually)"
            }

            Send-Toast -AgentName "AutoTrigger" -Channel "testoff.md" -Message "Test cycle complete - check terminal output"
        }
    }
}

function Start-ChannelWatcher {
    param (
        [string]$WatchFolder,
        [string]$Filter = "*.md"
    )

    $Watcher = New-Object System.IO.FileSystemWatcher
    $Watcher.Path = $WatchFolder
    $Watcher.Filter = $Filter
    $Watcher.IncludeSubdirectories = $false
    $Watcher.EnableRaisingEvents = $true

    $Action = {
        $path = $Event.SourceEventArgs.FullPath
        $name = $Event.SourceEventArgs.Name
        $changeType = $Event.SourceEventArgs.ChangeType
        if ($changeType -eq 'Changed') {
            try {
                Invoke-ChannelChanged -FilePath $path -FileName $name
                Invoke-ChannelAction -FilePath $path -FileName $name
            } catch {
                Write-Host "Error reading file ${name}: $_"
            }
        }
    }

    Register-ObjectEvent $Watcher "Changed" -Action $Action | Out-Null
    return $Watcher
}

# --- Main ---

$WatchFolder = Resolve-Path ".\ffs0-factory-super\.agent\channels"

Write-Host "Starting Triangle Watcher..."
Write-Host "Monitoring channels in: $($WatchFolder.Path)"
Write-Host "Keep this terminal open in the background to receive Toast Notifications."
Write-Host "-------------------------------------------------------------------"

Initialize-ToastRuntime
Start-ChannelWatcher -WatchFolder $WatchFolder.Path | Out-Null

while ($true) {
    Start-Sleep -Seconds 5
}
