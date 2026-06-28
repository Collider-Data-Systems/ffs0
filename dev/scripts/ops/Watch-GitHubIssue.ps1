[CmdletBinding()]
param(
    [string]$Repo = "Collider-Data-Systems/ffs0",
    [int]$Issue = 54,
    [int]$IntervalSeconds = 180,
    [ValidateSet('hp-laptop-governance', 'z440-vscode-lead')]
    [string]$Profile = 'hp-laptop-governance',
    [string]$SessionUrn = '',
    [string]$ActorUrn = '',
    [string]$WatcherLabel = '',
    [switch]$Watch,
    [switch]$AutoReply,
    [switch]$CloudflaredReadback,
    [switch]$ReplyToAllZ440,
    [long]$LastSeenId = -1,
    [string]$StatePath = "",
    [string]$Marker = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-WatcherProfileDefaults {
    param([Parameter(Mandatory)][string]$Name)

    switch ($Name) {
        'hp-laptop-governance' {
            return [pscustomobject]@{
                Marker = '[hp-laptop-auto-ack]'
                WatcherLabel = 'hp-laptop governance watcher'
                SessionUrn = 'urn:moos:session:sam.governance'
                ActorUrn = 'urn:moos:agent:vscode.hp-laptop.copilot'
            }
        }
        'z440-vscode-lead' {
            return [pscustomobject]@{
                Marker = '[z440-vscode-auto-ack]'
                WatcherLabel = 'Z440 VS Code lead watcher'
                SessionUrn = 'urn:moos:session:sam.z440-vscode-projection-lead'
                ActorUrn = 'urn:moos:agent:vscode.hp-z440.primary'
            }
        }
    }

    throw "Unknown watcher profile: $Name"
}

$profileDefaults = Get-WatcherProfileDefaults -Name $Profile
if ([string]::IsNullOrWhiteSpace($Marker)) { $Marker = [string]$profileDefaults.Marker }
if ([string]::IsNullOrWhiteSpace($WatcherLabel)) { $WatcherLabel = [string]$profileDefaults.WatcherLabel }
if ([string]::IsNullOrWhiteSpace($SessionUrn)) { $SessionUrn = [string]$profileDefaults.SessionUrn }
if ([string]::IsNullOrWhiteSpace($ActorUrn)) { $ActorUrn = [string]$profileDefaults.ActorUrn }

function Get-DefaultStatePath {
    param(
        [Parameter(Mandatory)][string]$RepoName,
        [Parameter(Mandatory)][int]$IssueNumber,
        [Parameter(Mandatory)][string]$ProfileName
    )

    $safeRepo = $RepoName -replace '[^A-Za-z0-9_.-]', '_'
    $safeProfile = $ProfileName -replace '[^A-Za-z0-9_.-]', '_'
    $stateDir = Join-Path (Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) "tmp") "issue-watch"
    New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
    return (Join-Path $stateDir "$safeRepo-$IssueNumber-$safeProfile.json")
}

function Invoke-GhJson {
    param(
        [Parameter(Mandatory)][string[]]$Arguments
    )

    $output = & gh @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "gh command failed: gh $($Arguments -join ' ')"
    }
    # Join captured stdout lines directly. Do NOT pipe through Out-String:
    # in Windows PowerShell 5.1 Out-String width-wraps the long single-line
    # JSON, corrupting it so ConvertFrom-Json silently returns a truncated set.
    return (@($output) -join "`n")
}

function Get-IssueComments {
    param(
        [Parameter(Mandatory)][string]$RepoName,
        [Parameter(Mandatory)][int]$IssueNumber
    )

    # Listing payload deliberately omits comment bodies. Windows PowerShell 5.1
    # ConvertFrom-Json silently collapses a large (~100KB+) array-with-bodies to
    # a single element, breaking detection. Bodies are fetched lazily per new
    # comment via Get-CommentBody.
    $json = Invoke-GhJson -Arguments @(
        "issue", "view", "$IssueNumber",
        "--repo", $RepoName,
        "--json", "comments",
        "--jq", ".comments | map({node_id:.id, created_at:.createdAt, html_url:.url, user:.author.login})"
    )
    $comments = @($json | ConvertFrom-Json)
    $normalized = foreach ($comment in $comments) {
        $numericId = 0L
        $commentUrl = [string]$comment.html_url
        $match = [regex]::Match($commentUrl, 'issuecomment-(\d+)')
        if ($match.Success) {
            $numericId = [long]$match.Groups[1].Value
        } else {
            Write-Host "Skipping comment without issuecomment numeric URL id: $commentUrl" -ForegroundColor Yellow
            continue
        }

        [pscustomobject]@{
            id = $numericId
            node_id = $comment.node_id
            created_at = $comment.created_at
            html_url = $comment.html_url
            user = $comment.user
        }
    }
    return @($normalized | Sort-Object id)
}

function Get-CommentBody {
    param(
        [Parameter(Mandatory)][string]$RepoName,
        [Parameter(Mandatory)][long]$CommentId
    )

    try {
        $body = Invoke-GhJson -Arguments @(
            "api", "repos/$RepoName/issues/comments/$CommentId", "--jq", ".body"
        )
        return [string]$body
    } catch {
        Write-Host "Could not fetch body for comment ${CommentId}: $($_.Exception.Message)" -ForegroundColor Yellow
        return ""
    }
}

function Read-LastSeenId {
    param(
        [Parameter(Mandatory)][string]$Path,
        [long]$ExplicitLastSeenId,
        [Parameter(Mandatory)][string]$RepoName,
        [Parameter(Mandatory)][int]$IssueNumber
    )

    if ($ExplicitLastSeenId -ge 0) { return $ExplicitLastSeenId }

    if (Test-Path $Path) {
        try {
            $state = Get-Content -Path $Path -Raw | ConvertFrom-Json
            if ($null -ne $state.last_seen_id) { return [long]$state.last_seen_id }
        } catch {
            Write-Host "State file could not be read; starting from issue tail: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }

    $apiPath = "repos/$RepoName/issues/$IssueNumber/comments?per_page=100"
    $latestId = Invoke-GhJson -Arguments @("api", $apiPath, "--jq", ".[-1].id")
    if ([string]::IsNullOrWhiteSpace($latestId)) { return 0 }
    return [long]$latestId.Trim()
}

function Write-LastSeenId {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][long]$SeenId
    )

    $parent = Split-Path -Parent $Path
    if (-not [string]::IsNullOrWhiteSpace($parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    $state = [pscustomobject]@{
        repo = $script:Repo
        issue = $script:Issue
        profile = $script:Profile
        watcher_label = $script:WatcherLabel
        session_urn = $script:SessionUrn
        actor_urn = $script:ActorUrn
        marker = $script:Marker
        last_seen_id = $SeenId
        updated_at = (Get-Date).ToUniversalTime().ToString("o")
    }
    $state | ConvertTo-Json -Depth 4 | Set-Content -Path $Path -Encoding UTF8
}

function Test-AutoReplyRelevant {
    param(
        [Parameter(Mandatory)][string]$Body,
        [switch]$ReplyToAnyZ440
    )

    if ([string]::IsNullOrWhiteSpace($Body)) { return $false }
    $autoReplyMarkers = @(
        $script:Marker,
        'Auto-ack from Z440 VS Code lead',
        'hp-laptop governance auto watcher',
        'Z440 VS Code lead watcher',
        '[hp-laptop-auto-ack]',
        '[z440-vscode-auto-ack]'
    )
    foreach ($autoReplyMarker in $autoReplyMarkers) {
        if (-not [string]::IsNullOrWhiteSpace($autoReplyMarker) -and $Body -match [regex]::Escape($autoReplyMarker)) {
            return $false
        }
    }

    switch ($script:Profile) {
        'hp-laptop-governance' {
            $isZ440Side = $Body -match '(Antigravity-Z440|Cowork-Z440|Z440 VS Code lead|agent:vscode\.hp-z440|agent:antigravity\.hp-z440|agent:claude-cowork\.hp-z440|session:sam\.z440|kernel:hp-z440)'
            if (-not $isZ440Side) { return $false }
            if ($ReplyToAnyZ440) { return $true }

            $asksOrHandoff = $Body -match '(hp-laptop governance action needed|hp-laptop governance|governance request|request to hp-laptop|Guido|open item|action needed|guidance|blocked|question|handoff|please reply|please post|requested redacted|config request)'
            return $asksOrHandoff
        }
        'z440-vscode-lead' {
            if ($ReplyToAnyZ440) {
                return ($Body -match '(hp-laptop governance|Cowork-Z440|Antigravity-Z440|agent:vscode\.hp-laptop|agent:claude-cowork\.hp-z440|agent:antigravity\.hp-z440|session:sam\.governance|Z440)')
            }

            return ($Body -match '(Z440 action needed|Z440 VS Code lead action needed|request to Z440|request for Z440|handoff to Z440|please have Z440|please reply from Z440|pls.*Z440|agent:vscode\.hp-z440\.primary|session:sam\.z440-vscode-projection-lead)')
        }
    }

    return $false
}

function Test-NeedsCloudflaredReadback {
    param([Parameter(Mandatory)][string]$Body)

    if ($script:Profile -ne 'hp-laptop-governance') { return $false }

    return ($Body -match '(moos-hp|cloudflared|\.cloudflared|ingress|apex/www|502|tunnel)' -and
            $Body -match '(hp-laptop|governance|redacted|config|readback|origin)')
}

function Get-RedactedCloudflaredIngress {
    $configPath = Join-Path $HOME ".cloudflared\config.yml"
    if (-not (Test-Path $configPath)) {
        return [pscustomobject]@{
            ConfigExists = $false
            IngressText = "<config not found>"
            Services = @()
        }
    }

    $lines = Get-Content -Path $configPath
    $ingressLines = New-Object System.Collections.Generic.List[string]
    $services = New-Object System.Collections.Generic.List[string]
    $inIngress = $false

    foreach ($line in $lines) {
        if ($line -match '^\s*tunnel\s*:') { continue }
        if ($line -match '^\s*credentials-file\s*:') { continue }
        if ($line -match '^\s*ingress\s*:') {
            $inIngress = $true
            $ingressLines.Add("ingress:")
            continue
        }
        if (-not $inIngress) { continue }
        if (($line -match '^\S') -and ($line -notmatch '^\s*#') -and ($line -notmatch '^\s*-')) { break }

        $redacted = $line -replace '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}', '<uuid-redacted>'
        $ingressLines.Add($redacted)

        if ($line -match 'service:\s*(\S+)') {
            [void]$services.Add($Matches[1])
        }
    }

    return [pscustomobject]@{
        ConfigExists = $true
        IngressText = ($ingressLines -join "`n")
        Services = @($services | Sort-Object -Unique)
    }
}

function Invoke-LocalOriginTest {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Uri,
        [hashtable]$Headers = @{}
    )

    try {
        $response = Invoke-WebRequest -Uri $Uri -UseBasicParsing -TimeoutSec 8 -MaximumRedirection 0 -Headers $Headers
        return [pscustomobject]@{
            Name = $Name
            Uri = $Uri
            Status = "$([int]$response.StatusCode)"
            Detail = "$($response.Headers['content-type'])"
        }
    } catch {
        $response = $_.Exception.Response
        if ($null -ne $response) {
            return [pscustomobject]@{
                Name = $Name
                Uri = $Uri
                Status = "$([int]$response.StatusCode)"
                Detail = $_.Exception.Message
            }
        }
        return [pscustomobject]@{
            Name = $Name
            Uri = $Uri
            Status = "error"
            Detail = $_.Exception.Message
        }
    }
}

function Get-CloudflaredReadbackMarkdown {
    $ingress = Get-RedactedCloudflaredIngress
    $tests = @(
        Invoke-LocalOriginTest -Name "apex origin / plain" -Uri "http://localhost:9000/",
        Invoke-LocalOriginTest -Name "apex origin / host-header" -Uri "http://localhost:9000/" -Headers @{ Host = "my-tiny-data-collider.nl" },
        Invoke-LocalOriginTest -Name "www origin / host-header" -Uri "http://localhost:9000/" -Headers @{ Host = "www.my-tiny-data-collider.nl" },
        Invoke-LocalOriginTest -Name "router health" -Uri "http://localhost:9000/healthz",
        Invoke-LocalOriginTest -Name "kernel mcp root" -Uri "http://localhost:8080/"
    )

    $process = Get-Process cloudflared -ErrorAction SilentlyContinue | Select-Object -First 1
    $metricsLines = @()
    try {
        $metrics = (Invoke-WebRequest http://localhost:20241/metrics -UseBasicParsing -TimeoutSec 5).Content
        $metricsLines = @($metrics -split "`n" | Select-String -Pattern 'cloudflared_tunnel_ha_connections|cloudflared_tunnel_total_requests|cloudflared_tunnel_concurrent_requests' | ForEach-Object { $_.Line.Trim() })
    } catch {
        $metricsLines = @("metrics unavailable: $($_.Exception.Message)")
    }

    $tableRows = $tests | ForEach-Object { "| ``$($_.Name)`` | ``$($_.Uri)`` | $($_.Status) | $($_.Detail) |" }
    $processLine = if ($null -ne $process) {
        "cloudflared process: $($process.Path), PID $($process.Id), started $($process.StartTime)"
    } else {
        "cloudflared process: not running"
    }

@"
### Redacted hp-laptop `moos-hp` ingress readback

`tunnel:` and `credentials-file:` are intentionally omitted/redacted. Current `ingress:` block:

```yaml
$($ingress.IngressText)
```

### Local origin tests

| Test | URI | Status | Detail |
|---|---|---:|---|
$($tableRows -join "`n")

### Connector health

```text
$processLine
$($metricsLines -join "`n")
```

Governance read: if apex/www map to `http://localhost:9000/` and that root returns `502` while `/healthz` is `200`, the connector is alive and the apex/www failure is an ingress/origin-shape issue rather than a missing ingress rule. Keep DNS/Cloudflare/tunnel edits gated on explicit Sam approval.
"@
}

function New-AutoReplyBody {
    param(
        [Parameter(Mandatory)]$Comment,
        [switch]$IncludeCloudflaredReadback
    )

    $body = ""
    if ($IncludeCloudflaredReadback -and (Test-NeedsCloudflaredReadback -Body $Comment.body)) {
        $body = Get-CloudflaredReadbackMarkdown
    } elseif ($script:Profile -eq 'z440-vscode-lead') {
        $body = @"
I saw this #$($script:Issue) comment while the Z440 VS Code lead watcher is running in this VS Code IDE/conversation. Conservative boundary held: no HG rewrites, no Keep/Calendar/Project sync, no DNS/Cloudflare/tunnel changes, no secret handling, no repo edits, and no manual log mirroring from this watcher.

Default Z440 stance until the live agent writes a reviewed reply:

- Watching as `$script:SessionUrn` / `$script:ActorUrn`.
- Prefer live federation/read-surface checks before claims.
- Keep domain/tunnel/4.0/channel moves as draft or source-evidence plans unless Sam explicitly authorizes an apply/change.
- If a concrete Z440 response is needed, keep the phrase `Z440 action needed` or `request to Z440` in #$($script:Issue) and this session will handle it when active.
"@
    } else {
        $body = @"
I saw this Z440-side governance request while the hp-laptop watcher is running. Conservative boundary held: no HG rewrites, no Keep/Calendar/Project sync, no DNS/Cloudflare/tunnel changes, no secret handling, and no manual log mirroring from this watcher.

Default guidance until Sam wakes hp-laptop governance for a full reviewed reply:

- Use `ffs0/main` at or after `c3f6e47` for the latest hp-laptop projection baseline.
- Prefer live federation/read-surface checks; do not copy `moos.jsonl` between machines.
- Keep domain/tunnel/4.0/channel moves as draft or source-evidence plans unless Sam explicitly authorizes an apply/change.
- If a concrete hp-laptop action is needed, keep the phrase `hp-laptop governance action needed` in #$($script:Issue) and this session will handle it when active.
"@
    }

@"
$script:Marker

Auto-reply from $script:WatcherLabel for $($Comment.html_url) (`$comment_id=$($Comment.id)`).

$body

- $script:WatcherLabel, T=216
"@
}

function Invoke-IssuePoll {
    $comments = Get-IssueComments -RepoName $script:Repo -IssueNumber $script:Issue
    $newComments = @($comments | Where-Object { [long]$_.id -gt $script:LastSeenId } | Sort-Object id)

    if ($newComments.Count -eq 0) {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] no new #$script:Issue comments since id $script:LastSeenId"
        return
    }

    foreach ($comment in $newComments) {
        $body = Get-CommentBody -RepoName $script:Repo -CommentId ([long]$comment.id)
        $comment | Add-Member -NotePropertyName body -NotePropertyValue $body -Force
        $preview = (($body -replace "`r", '') -split "`n" | Select-Object -First 6) -join ' / '
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] new #$script:Issue comment id $($comment.id): $($comment.html_url)"
        Write-Host "preview: $preview"

        if ($script:AutoReply -and (Test-AutoReplyRelevant -Body $body -ReplyToAnyZ440:$script:ReplyToAllZ440)) {
            $replyBody = New-AutoReplyBody -Comment $comment -IncludeCloudflaredReadback:$script:CloudflaredReadback
            $null = Invoke-GhJson -Arguments @("issue", "comment", "$script:Issue", "--repo", $script:Repo, "--body", $replyBody)
            Write-Host "auto-reply posted for comment id $($comment.id)"
        } elseif ($script:AutoReply) {
            Write-Host "no auto-reply: comment did not match request rules or was an auto-ack"
        }

        if ([long]$comment.id -gt $script:LastSeenId) {
            $script:LastSeenId = [long]$comment.id
            Write-LastSeenId -Path $script:StatePath -SeenId $script:LastSeenId
        }
    }

    Write-Host "Updated last seen id: $script:LastSeenId"
}

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw "GitHub CLI 'gh' was not found on PATH."
}

if ([string]::IsNullOrWhiteSpace($StatePath)) {
    $StatePath = Get-DefaultStatePath -RepoName $Repo -IssueNumber $Issue -ProfileName $Profile
}

$LastSeenId = Read-LastSeenId -Path $StatePath -ExplicitLastSeenId $LastSeenId -RepoName $Repo -IssueNumber $Issue
Write-LastSeenId -Path $StatePath -SeenId $LastSeenId

Write-Host "Watching $Repo#$Issue. State: $StatePath"
Write-Host "Profile: $Profile; Watcher: $WatcherLabel"
Write-Host "Session: $SessionUrn"
Write-Host "Actor: $ActorUrn"
Write-Host "Marker: $Marker"
Write-Host "Last seen comment id: $LastSeenId"
Write-Host "AutoReply: $AutoReply; CloudflaredReadback: $CloudflaredReadback; ReplyToAllZ440: $ReplyToAllZ440"

Invoke-IssuePoll

if (-not $Watch) { return }

Write-Host "Polling every $IntervalSeconds seconds. Stop this terminal to stop the watcher."
while ($true) {
    Start-Sleep -Seconds $IntervalSeconds
    try {
        Invoke-IssuePoll
    } catch {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] poll error: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}