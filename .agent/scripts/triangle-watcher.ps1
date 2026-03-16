# Triangle Watcher - Native Windows Toast Notifications for the mo:os Agent Triangle

# Configuration
$WatchFolder = Resolve-Path ".\ffs0-factory-super\.agent\channels"
$Filter = "*.md"

Write-Host "Starting Triangle Watcher..."
Write-Host "Monitoring channels in: $($WatchFolder.Path)"
Write-Host "Keep this terminal open in the background to receive Toast Notifications."
Write-Host "-------------------------------------------------------------------"

# Load Windows Runtime for Toast Notifications
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null
[Windows.UI.Notifications.ToastNotification, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null

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
            <text id="2">$AgentName: $Message</text>
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

# Set up FileSystemWatcher
$Watcher = New-Object System.IO.FileSystemWatcher
$Watcher.Path = $WatchFolder.Path
$Watcher.Filter = $Filter
$Watcher.IncludeSubdirectories = $false
$Watcher.EnableRaisingEvents = $true

# Define the action when a file changes
$Action = {
    $path = $Event.SourceEventArgs.FullPath
    $name = $Event.SourceEventArgs.Name
    $changeType = $Event.SourceEventArgs.ChangeType
    
    # We only care about modifications
    if ($changeType -eq 'Changed') {
        # Read the top few lines to find the newest message
        try {
            # Give the agent a split second to finish writing
            Start-Sleep -Milliseconds 200
            $content = Get-Content -Path $path -TotalCount 10 -ErrorAction Stop
            
            # Look for lines formatted like "### [2026-03-16 19:15] ClaudeCode -> direction: message..."
            $latestMessage = $content | Where-Object { $_ -match "^### \[" } | Select-Object -First 1
            
            if ($latestMessage) {
                # Extract agent name and the actual message payload
                if ($latestMessage -match "\] (.*?) (?:->|→) (?:.*?): (.*)") {
                    $agent = $Matches[1]
                    $msg = $Matches[2]
                    
                    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Update in $name from $agent"
                    Send-Toast -AgentName $agent -Channel $name -Message $msg
                } else {
                    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Update in $name (Unparseable format)"
                    Send-Toast -AgentName "Unknown Agent" -Channel $name -Message "Wrote to channel."
                }
            }
        } catch {
            Write-Host "Error reading file $name: $_"
        }
    }
}

# Register the event
Register-ObjectEvent $Watcher "Changed" -Action $Action | Out-Null

# Keep the script running
while ($true) {
    Start-Sleep -Seconds 5
}
