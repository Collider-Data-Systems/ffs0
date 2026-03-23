# Triangle Watcher (graph-only) - Native Windows toast notifications for mo:os

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

function Get-GraphSignal {
    try {
        # Use /healthz for counts (fast, no lock contention)
        $health = Invoke-RestMethod "http://localhost:8000/healthz" -TimeoutSec 2 -ErrorAction Stop

        # Use /state/lens for PRG + session status (filtered, not full state)
        $prg = Invoke-RestMethod "http://localhost:8000/state/lens?kind=prg_task" -TimeoutSec 3 -ErrorAction Stop
        $sess = Invoke-RestMethod "http://localhost:8000/state/lens?kind=agent_session" -TimeoutSec 3 -ErrorAction Stop

        $prgStates = @(
            $prg.nodes.PSObject.Properties |
            Sort-Object Name |
            ForEach-Object {
                $status = $_.Value.payload.status
                if (-not $status) { $status = "unknown" }
                "{0}:{1}" -f $_.Name, $status
            }
        )

        $sessionStates = @(
            $sess.nodes.PSObject.Properties |
            Sort-Object Name |
            ForEach-Object {
                $status = $_.Value.payload.status
                if (-not $status) { $status = "unknown" }
                "{0}:{1}" -f $_.Name, $status
            }
        )

        $signature = "n={0}|w={1}|prg={2}|sess={3}" -f `
            $health.nodes, `
            $health.wires, `
            ($prgStates -join ","), `
            ($sessionStates -join ",")

        [PSCustomObject]@{
            Signature = $signature
            NodeCount = $health.nodes
            WireCount = $health.wires
            PRGCount  = $prgStates.Count
        }
    }
    catch {
        return $null
    }
}

function Invoke-GraphChanged {
    param (
        [object]$Signal
    )

    if (-not $Signal) { return }

    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] GRAPH update: nodes=$($Signal.NodeCount) wires=$($Signal.WireCount) prg=$($Signal.PRGCount)"
    Send-Toast -AgentName "GraphState" -Channel "kernel:/state" -Message "nodes=$($Signal.NodeCount) wires=$($Signal.WireCount) prg=$($Signal.PRGCount)"
}

# --- Main ---

Write-Host "Starting Triangle Watcher..."
Write-Host "Graph-only mode: polling /healthz + /state/lens (no full /state)"
Write-Host "Keep this terminal open in the background to receive Toast Notifications."
Write-Host "-------------------------------------------------------------------"

Initialize-ToastRuntime

$lastGraphSignature = $null
while ($true) {
    $signal = Get-GraphSignal
    if ($signal -and $signal.Signature -ne $lastGraphSignature) {
        if ($lastGraphSignature -ne $null) {
            Invoke-GraphChanged -Signal $signal
        }
        $lastGraphSignature = $signal.Signature
    }
    Start-Sleep -Seconds 5
}
