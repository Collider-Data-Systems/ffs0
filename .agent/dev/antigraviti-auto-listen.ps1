param(
    [string]$KernelBaseUrl = "http://localhost:8000",
    [string]$AgentUrn = "urn:moos:agent:antigraviti",
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

    try {
        $Toast = [Windows.UI.Notifications.ToastNotification]::new($XmlDocument)
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($AppId).Show($Toast)
    }
    catch {
        # Silent fail if notifications disabled
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

function Is-DelegationPayload {
    param([object]$Payload)

    if ($null -eq $Payload) { return $false }

    $tags = @()
    if ($Payload.PSObject.Properties.Name -contains "tags") { $tags = @($Payload.tags) }
    $tagSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($tag in $tags) {
        if ($null -ne $tag) { [void]$tagSet.Add([string]$tag) }
    }

    $text = ""
    if ($Payload.PSObject.Properties.Name -contains "text" -and $null -ne $Payload.text) { $text = [string]$Payload.text }
    $type = ""
    if ($Payload.PSObject.Properties.Name -contains "type" -and $null -ne $Payload.type) { $type = [string]$Payload.type }
    $sender = ""
    if ($Payload.PSObject.Properties.Name -contains "sender" -and $null -ne $Payload.sender) { $sender = [string]$Payload.sender }

    $targetsAntigraviti = $tagSet.Contains("antigraviti") -or $text.ToLowerInvariant().Contains("antigraviti")
    $looksLikeInstruction = $tagSet.Contains("delegation") -or ($type -imatch "delegate|instruction|policy|request") -or $text.ToLowerInvariant().Contains("delegat") -or $text.ToLowerInvariant().Contains("listen")
    $isSelfAck = ($type -ieq "ack") -or $sender.ToLowerInvariant().Contains("antigraviti")

    return $targetsAntigraviti -and $looksLikeInstruction -and (-not $isSelfAck)
}

function Get-DelegationUrnFromEntry {
    param([object]$Entry)

    if ($null -eq $Entry.envelope) { return $null }
    $env = $Entry.envelope

    if ($env.type -eq "ADD" -and $null -ne $env.add -and $env.add.type_id -eq "channel_message") {
        if (Is-DelegationPayload -Payload $env.add.payload) {
            return [string]$env.add.urn
        }
    }

    if ($env.type -eq "LINK" -and $null -ne $env.link) {
        $link = $env.link
        $looksLikeSessionOwnsMessage = ($link.source_urn -eq $SessionUrn -and $link.source_port -eq "owns" -and $link.target_port -eq "child")
        if ($looksLikeSessionOwnsMessage) {
            try {
                $node = Get-Node -Urn ([string]$link.target_urn)
                if ($node.type_id -eq "channel_message" -and (Is-DelegationPayload -Payload $node.payload)) {
                    return [string]$node.urn
                }
            }
            catch {
                return $null
            }
        }
    }

    return $null
}

function Process-Entry {
    param(
        [object]$Entry,
        [ref]$State,
        [System.Collections.Generic.HashSet[string]]$Processed
    )

    if ($null -eq $Entry) {
        return
    }

    if ($null -ne $Entry.issued_at) {
        $State.Value.last_after = Normalize-AfterTimestamp -Value $Entry.issued_at
    }

    $sourceUrn = Get-DelegationUrnFromEntry -Entry $Entry
    if ([string]::IsNullOrWhiteSpace($sourceUrn) -or $Processed.Contains($sourceUrn)) {
        return
    }

    try {
        $now = (Get-Date).ToUniversalTime().ToString("yyyyMMddHHmmssfff")
        $suffix = Get-Random -Minimum 1000 -Maximum 9999
        $ackUrn = "urn:moos:message:${now}-${suffix}-antigraviti-auto-ack"
        
        $calStatus = "checking"
        try {
            $calTest = Invoke-RestMethod "$KernelBaseUrl/functor/calendar" -TimeoutSec 2 -ErrorAction Stop
            $calStatus = "FUN06 responds ok"
        }
        catch {
            $calStatus = "unavailable or error"
        }

        $ackText = "Auto-picked delegation from $sourceUrn. Listening active for PRG000/FUN06 signals. Calendar check: $calStatus."

        Send-Toast -AgentName "Antigraviti" -Channel "Delegation" -Message "Delegation $sourceUrn received. Calendar $calStatus."


        $addAck = @{
            type  = "ADD"
            actor = $AgentUrn
            add   = @{
                urn     = $ackUrn
                type_id = "channel_message"
                stratum = "S2"
                payload = @{
                    sender = "Antigraviti"
                    type   = "ack"
                    tags   = @("delegation", "ack", "antigraviti", "auto-listener", "save-hg", "calendar-project")
                    text   = $ackText
                }
            }
        }
        Post-Morphism -BaseUrl $KernelBaseUrl -Body $addAck

        $linkAckToSource = @{
            type  = "LINK"
            actor = $AgentUrn
            link  = @{
                source_urn  = $ackUrn
                source_port = "out"
                target_urn  = $sourceUrn
                target_port = "in"
            }
        }
        Post-Morphism -BaseUrl $KernelBaseUrl -Body $linkAckToSource

        $linkSessionOwnsAck = @{
            type  = "LINK"
            actor = $AgentUrn
            link  = @{
                source_urn  = $SessionUrn
                source_port = "owns"
                target_urn  = $ackUrn
                target_port = "child"
            }
        }
        Post-Morphism -BaseUrl $KernelBaseUrl -Body $linkSessionOwnsAck

        [void]$Processed.Add($sourceUrn)
        Write-Log -Message ("acked delegation: {0} -> {1}" -f $sourceUrn, $ackUrn)
    }
    catch {
        $detail = Get-ErrorDetail -Err $_
        Write-Log -Level "WARN" -Message ("failed to ack {0}: {1}" -f $sourceUrn, $detail)
    }
}

function Run-BackfillPoll {
    param(
        [ref]$State,
        [System.Collections.Generic.HashSet[string]]$Processed
    )

    $encodedAfter = [uri]::EscapeDataString([string]$State.Value.last_after)
    $url = "$KernelBaseUrl/log?after=$encodedAfter&limit=300"
    $entries = Invoke-RestMethod $url
    if ($null -eq $entries) {
        $entries = @()
    }
    foreach ($entry in @($entries)) {
        Process-Entry -Entry $entry -State ([ref]$State.Value) -Processed $Processed
    }
}

function Run-SSELoop {
    param(
        [ref]$State,
        [System.Collections.Generic.HashSet[string]]$Processed
    )

    $client = [System.Net.Http.HttpClient]::new()
    $client.Timeout = [System.Threading.Timeout]::InfiniteTimeSpan
    try {
        $stream = $client.GetStreamAsync("$KernelBaseUrl/log/stream").GetAwaiter().GetResult()
        $reader = New-Object System.IO.StreamReader($stream)
        $eventData = ""
        Write-Log -Message "SSE connected: /log/stream"

        while (-not $reader.EndOfStream) {
            $line = $reader.ReadLine()
            if ($null -eq $line) {
                continue
            }

            if ($line.StartsWith(":")) {
                continue
            }

            if ($line.StartsWith("data:")) {
                $chunk = $line.Substring(5).TrimStart()
                if ($eventData.Length -gt 0) {
                    $eventData += "`n"
                }
                $eventData += $chunk
                continue
            }

            if ([string]::IsNullOrWhiteSpace($line)) {
                if (-not [string]::IsNullOrWhiteSpace($eventData)) {
                    try {
                        $entry = $eventData | ConvertFrom-Json
                        Process-Entry -Entry $entry -State ([ref]$State.Value) -Processed $Processed
                    }
                    catch {
                        $detail = Get-ErrorDetail -Err $_
                        Write-Log -Level "WARN" -Message ("SSE parse failure: {0}" -f $detail)
                    }
                    $eventData = ""
                }
            }
        }
    }
    finally {
        $client.Dispose()
    }
}

$state = Read-ListenerState -Path $StateFile
$processed = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($urn in @($state.processed)) {
    if ($null -ne $urn) { [void]$processed.Add([string]$urn) }
}

Initialize-ToastRuntime
Write-Log -Message ("started. session={0} poll={1}s after={2}" -f $SessionUrn, $PollSeconds, $state.last_after)

try {
    while ($true) {
        try {
            Run-BackfillPoll -State ([ref]$state) -Processed $processed
            Save-State -Path $StateFile -State $state -Processed $processed

            if (-not $DisableSSE) {
                try {
                    Run-SSELoop -State ([ref]$state) -Processed $processed
                }
                catch {
                    $detail = Get-ErrorDetail -Err $_
                    Write-Log -Level "WARN" -Message ("SSE disconnected; fallback to polling: {0}" -f $detail)
                }
            }
            else {
                Start-Sleep -Seconds $PollSeconds
            }

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
