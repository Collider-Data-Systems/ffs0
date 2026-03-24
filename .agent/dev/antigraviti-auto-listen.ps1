param(
    [string]$KernelBaseUrl = "http://localhost:8000",
    [string]$AgentUrn = "urn:moos:agent:antigraviti",
    [string]$AssignedTo = "antigraviti",
    [string]$SessionUrn = "urn:moos:session:20260322-antigraviti",
    [int]$PollSeconds = 2,
    [string]$StateFile = "",
    [string]$LogFile = "",
    [switch]$StartFromNow,
    [switch]$DisableSSE,
    [string]$MutexName = "Local\FFS0_Antigraviti_AutoListen"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$createdNew = $false
$mutex = New-Object System.Threading.Mutex($true, $MutexName, [ref]$createdNew)
if (-not $createdNew) {
    Write-Output "[AG-AutoListen] another listener instance is already running; exiting."
    exit 0
}

$scriptDir = Split-Path -Parent $PSCommandPath
if ([string]::IsNullOrWhiteSpace($StateFile)) {
    $StateFile = Join-Path $scriptDir ".antigraviti-auto-listener-state.json"
}
elseif (-not [System.IO.Path]::IsPathRooted($StateFile)) {
    $StateFile = Join-Path $scriptDir $StateFile
}

if ([string]::IsNullOrWhiteSpace($LogFile)) {
    $LogFile = Join-Path $scriptDir "antigraviti-auto-listen.log"
}
elseif (-not [System.IO.Path]::IsPathRooted($LogFile)) {
    $LogFile = Join-Path $scriptDir $LogFile
}

function Initialize-ToastRuntime {
    try {
        [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
        [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null
        [Windows.UI.Notifications.ToastNotification, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
    }
    catch {
        # Silent fail if running under strict pwsh without WinRT bridging
    }
}

function Send-Toast {
    param (
        [string]$AgentName,
        [string]$Channel,
        [string]$Message
    )

    # Check if WinRT types are available before attempting to Toast
    $xmlType = [type]::GetType("Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType=WindowsRuntime", $false)
    if ($null -eq $xmlType) {
        Write-Log -Message "Skipping toast (WinRT XML type not found)"
        return
    }

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

    try {
        $XmlDocument = [Windows.Data.Xml.Dom.XmlDocument]::new()
        $XmlDocument.LoadXml($XmlString)
        $Toast = [Windows.UI.Notifications.ToastNotification]::new($XmlDocument)
        $notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($AppId)
        $notifier.Show($Toast)
    }
    catch {
        Write-Log -Level "WARN" -Message "Failed to show toast: $($_.Exception.Message)"
    }
}


function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARN")]
        [string]$Level = "INFO"
    )

    $line = "{0} [{1}] {2}" -f (Get-Date).ToUniversalTime().ToString("o"), $Level, $Message
    Add-Content -LiteralPath $LogFile -Value $line -Encoding UTF8
    if ($Level -eq "WARN") {
        Write-Warning $line
    }
    else {
        Write-Output $line
    }
}

function Default-After {
    if ($StartFromNow) {
        return (Get-Date).ToUniversalTime().AddSeconds(-15).ToString("o")
    }
    return (Get-Date).ToUniversalTime().AddMinutes(-5).ToString("o")
}

function Normalize-AfterTimestamp {
    param([object]$Value)

    if ($null -eq $Value) {
        return Default-After
    }
    if ($Value -is [datetime]) {
        return ([datetime]$Value).ToUniversalTime().ToString("o")
    }

    $text = [string]$Value
    if ([string]::IsNullOrWhiteSpace($text)) {
        return Default-After
    }

    try {
        $dt = [datetime]::Parse($text, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::RoundtripKind)
        return $dt.ToUniversalTime().ToString("o")
    }
    catch {
        return Default-After
    }
}

function Read-ListenerState {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return [pscustomobject]@{
            last_after = Default-After
            processed  = @()
        }
    }

    try {
        $loaded = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
        return [pscustomobject]@{
            last_after = Normalize-AfterTimestamp -Value $loaded.last_after
            processed  = @($loaded.processed)
        }
    }
    catch {
        return [pscustomobject]@{
            last_after = Default-After
            processed  = @()
        }
    }
}

function Write-ListenerState {
    param(
        [string]$Path,
        [object]$State
    )

    $dir = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $State | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Post-Morphism {
    param(
        [string]$BaseUrl,
        [object]$Body
    )

    $json = $Body | ConvertTo-Json -Depth 12
    Invoke-RestMethod "$BaseUrl/morphisms" -Method Post -ContentType "application/json" -Body $json | Out-Null
}

function Save-State {
    param(
        [string]$Path,
        [object]$State,
        [System.Collections.Generic.HashSet[string]]$Processed
    )

    $State.processed = @($Processed)
    Write-ListenerState -Path $Path -State $State
}

function Get-ErrorDetail {
    param([object]$Err)
    if ($null -ne $Err.ErrorDetails -and -not [string]::IsNullOrWhiteSpace($Err.ErrorDetails.Message)) {
        return [string]$Err.ErrorDetails.Message
    }
    return [string]$Err.Exception.Message
}

function Get-Node {
    param([string]$Urn)
    return Invoke-RestMethod "$KernelBaseUrl/state/nodes/$Urn"
}

function Matches-Assignee {
    param(
        [object]$TaskPayload,
        [string]$Expected
    )

    if ($null -eq $TaskPayload -or [string]::IsNullOrWhiteSpace($Expected)) {
        return $false
    }

    $assigned = ""
    if ($TaskPayload.PSObject.Properties.Name -contains "assigned_to" -and $null -ne $TaskPayload.assigned_to) {
        $assigned = [string]$TaskPayload.assigned_to
    }
    if ([string]::IsNullOrWhiteSpace($assigned)) {
        return $false
    }

    if ($assigned.Equals($Expected, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }
    return $assigned.ToLowerInvariant().Contains($Expected.ToLowerInvariant())
}

function Get-DelegationTaskNodes {
    $lens = Invoke-RestMethod "$KernelBaseUrl/state/lens?kind=delegation_task"
    if ($null -eq $lens -or $null -eq $lens.nodes) {
        return @()
    }
    return @($lens.nodes.PSObject.Properties.Value)
}

function Copy-Payload {
    param([object]$Payload)

    $copy = @{}
    if ($null -eq $Payload) {
        return $copy
    }
    foreach ($p in $Payload.PSObject.Properties) {
        $copy[$p.Name] = $p.Value
    }
    return $copy
}

function Set-DelegationTaskStatus {
    param(
        [string]$TaskUrn,
        [string]$Status,
        [hashtable]$Extra
    )

    $task = Get-Node -Urn $TaskUrn
    if ($null -eq $task) {
        throw "task not found: $TaskUrn"
    }

    $payload = Copy-Payload -Payload $task.payload
    $payload.status = $Status
    foreach ($k in $Extra.Keys) {
        $payload[$k] = $Extra[$k]
    }

    $mut = @{
        type = "MUTATE"
        actor = $AgentUrn
        mutate = @{
            urn = $TaskUrn
            expected_version = [int]$task.version
            payload = $payload
        }
    }
    Post-Morphism -BaseUrl $KernelBaseUrl -Body $mut
}

function Process-DelegationTask {
    param(
        [object]$Task,
        [System.Collections.Generic.HashSet[string]]$Processed
    )

    $taskUrn = [string]$Task.urn
    if ([string]::IsNullOrWhiteSpace($taskUrn) -or $Processed.Contains($taskUrn)) {
        return
    }

    $payload = $Task.payload
    $status = ""
    if ($payload.PSObject.Properties.Name -contains "status" -and $null -ne $payload.status) {
        $status = [string]$payload.status
    }
    if (-not $status.Equals("pending", [System.StringComparison]::OrdinalIgnoreCase)) {
        return
    }
    if (-not (Matches-Assignee -TaskPayload $payload -Expected $AssignedTo)) {
        return
    }

    try {
        $now = (Get-Date).ToUniversalTime().ToString("o")
        Set-DelegationTaskStatus -TaskUrn $taskUrn -Status "in_progress" -Extra @{ started_at = $now }

        $msgStamp = (Get-Date).ToUniversalTime().ToString("yyyyMMddHHmmssfff")
        $suffix = Get-Random -Minimum 1000 -Maximum 9999
        $ackUrn = "urn:moos:message:${msgStamp}-${suffix}-antigraviti-auto-ack"
        $title = "delegation task"
        if ($payload.PSObject.Properties.Name -contains "title" -and $null -ne $payload.title) {
            $title = [string]$payload.title
        }
        $ackText = "Auto-processed delegation_task $taskUrn ($title). Status moved pending -> in_progress -> completed."

        Send-Toast -AgentName "Antigraviti" -Channel "DelegationTask" -Message "Picked $taskUrn"

        $addAck = @{
            type = "ADD"
            actor = $AgentUrn
            add = @{
                urn = $ackUrn
                type_id = "channel_message"
                stratum = "S2"
                payload = @{
                    sender = "Antigraviti"
                    type = "ack"
                    tags = @("delegation_task", "ack", "antigraviti", "auto-listener")
                    text = $ackText
                }
            }
        }
        Post-Morphism -BaseUrl $KernelBaseUrl -Body $addAck

        $linkTaskToSession = @{
            type = "LINK"
            actor = $AgentUrn
            link = @{
                source_urn = $taskUrn
                source_port = "out"
                target_urn = $SessionUrn
                target_port = "receives"
            }
        }
        Post-Morphism -BaseUrl $KernelBaseUrl -Body $linkTaskToSession

        $linkAckToTask = @{
            type = "LINK"
            actor = $AgentUrn
            link = @{
                source_urn = $ackUrn
                source_port = "out"
                target_urn = $taskUrn
                target_port = "in"
            }
        }
        Post-Morphism -BaseUrl $KernelBaseUrl -Body $linkAckToTask

        $done = (Get-Date).ToUniversalTime().ToString("o")
        Set-DelegationTaskStatus -TaskUrn $taskUrn -Status "completed" -Extra @{ completed_at = $done }

        [void]$Processed.Add($taskUrn)
        Write-Log -Message ("completed delegation_task: {0}" -f $taskUrn)
    }
    catch {
        $detail = Get-ErrorDetail -Err $_
        Write-Log -Level "WARN" -Message ("failed delegation_task processing {0}: {1}" -f $taskUrn, $detail)
    }
}

function Run-DelegationTaskPoll {
    param([System.Collections.Generic.HashSet[string]]$Processed)

    $tasks = Get-DelegationTaskNodes
    foreach ($task in $tasks) {
        Process-DelegationTask -Task $task -Processed $Processed
    }
}

$state = Read-ListenerState -Path $StateFile
$processed = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($urn in @($state.processed)) {
    if ($null -ne $urn) { [void]$processed.Add([string]$urn) }
}

Initialize-ToastRuntime
Write-Log -Message ("started. session={0} assignee={1} poll={2}s" -f $SessionUrn, $AssignedTo, $PollSeconds)

try {
    while ($true) {
        try {
            Run-DelegationTaskPoll -Processed $processed
            Save-State -Path $StateFile -State $state -Processed $processed
            Start-Sleep -Seconds $PollSeconds
        }
        catch {
            $detail = Get-ErrorDetail -Err $_
            Write-Log -Level "WARN" -Message ("loop failure: {0}" -f $detail)
            Save-State -Path $StateFile -State $state -Processed $processed
            Start-Sleep -Seconds $PollSeconds
        }
    }
}
finally {
    if ($null -ne $mutex) {
        $mutex.ReleaseMutex() | Out-Null
        $mutex.Dispose()
    }
}
