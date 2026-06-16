[CmdletBinding()]
<#
.SYNOPSIS
    Trigger the hp-laptop + Z440 GitHub-issue watcher seats from the ProDesk box.

.DESCRIPTION
    From this ProDesk box (session:sam.hpprodesk-setup), wake the always-on seats so
    they read a coordination issue + linked PRs. Runs dev/scripts/ops/Watch-GitHubIssue.ps1
    on each peer over Tailscale SSH.

    Per-seat pre-flight:
      - online check (peer kernel :8000 /healthz reachable)
      - remote-exec check (tailscale ssh probe)
    If a peer has no remote-exec channel (Tailscale SSH not enabled / no OpenSSH server),
    it is reported UNREACHABLE with the exact command to run locally on that box.

    NOTE: Watch-GitHubIssue.ps1 is a GitHub poller + canned auto-ack for the VS Code/Copilot
    seats. It surfaces new comments and (with -AutoReply) posts a scripted ack. It does NOT
    launch a live Claude. A reasoning read+reply still needs Claude Code / the VS Code seat
    opened at that box.

    Remote exec requires, on each peer, EITHER `tailscale up --ssh` (+ tailnet ACL allowing
    ProDesk -> peer ssh) OR a running OpenSSH server. Until then peers report UNREACHABLE and
    you run the printed fallback locally.

.EXAMPLE
    .\Trigger-PeerWatchers.ps1 -Issue 64 -LastSeenId 4719756641
    # Surface the #64 coordination note onward on both seats (read-only, no ack).

.EXAMPLE
    .\Trigger-PeerWatchers.ps1 -Issue 64 -LastSeenId 4719756641 -AutoReply -Target z440
    # Z440 only; post its scripted governance ack.

.EXAMPLE
    .\Trigger-PeerWatchers.ps1 -DryRun
    # Print the remote/local commands without contacting anything.
#>
param(
    [int]$Issue = 64,
    [long]$LastSeenId = -1,
    [switch]$AutoReply,
    [switch]$Watch,
    [ValidateSet('hp-laptop', 'z440', 'all')]
    [string]$Target = 'all',
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Peer table. Ffs0 paths are evaluated REMOTELY (kept literal here so $env:USERPROFILE
# expands on the peer, not on ProDesk). Tailscale IPs are permanent for this tailnet.
$Peers = @(
    [pscustomobject]@{ Key = 'hp-laptop'; TsHost = 'lap-sam';         Ip = '100.106.220.58'; Profile = 'hp-laptop-governance'; Ffs0 = '$env:USERPROFILE\HPLaptop\ffs0' }
    [pscustomobject]@{ Key = 'z440';      TsHost = 'desktop-42d00rd'; Ip = '100.82.243.13';  Profile = 'z440-vscode-lead';     Ffs0 = 'D:\HPZ440\ffs0' }
)

function Get-ArgsTail {
    $tail = ''
    if ($LastSeenId -ge 0) { $tail += " -LastSeenId $LastSeenId" }
    if ($AutoReply)        { $tail += ' -AutoReply' }
    if ($Watch)            { $tail += ' -Watch' }
    return $tail
}

function Get-RemoteCommand {
    param([Parameter(Mandatory)]$Peer, [Parameter(Mandatory)][string]$ArgsTail)
    # Double-quote the path so $env:USERPROFILE expands on the peer. git pull is best-effort.
    return ('Set-Location "' + $Peer.Ffs0 + '"; ' +
            'git pull --ff-only; ' +
            '.\dev\scripts\ops\Watch-GitHubIssue.ps1 -Issue ' + $Issue +
            ' -Profile ' + $Peer.Profile + $ArgsTail)
}

function Get-LocalFallback {
    param([Parameter(Mandatory)]$Peer, [Parameter(Mandatory)][string]$ArgsTail)
    return ('cd "' + $Peer.Ffs0 + '"; git pull --ff-only; ' +
            '.\dev\scripts\ops\Watch-GitHubIssue.ps1 -Issue ' + $Issue +
            ' -Profile ' + $Peer.Profile + $ArgsTail)
}

function Test-PeerSsh {
    # tailscale ssh exits 0 even when the dial fails, so detect failure from the text.
    param([Parameter(Mandatory)]$Peer)
    # Native stderr via 2>&1 would throw under -EA Stop (PS 5.1 NativeCommandError); localize.
    $ErrorActionPreference = 'Continue'
    $out = (& tailscale ssh -- $Peer.TsHost hostname 2>&1 | Out-String).Trim()
    $failMarkers = '502|Connection closed by UNKNOWN|Dial\(|refused|timed? *out|mislukt|not enabled'
    if ($out -match $failMarkers) {
        $firstLine = ($out -split "`r?`n" | Where-Object { $_ } | Select-Object -First 1)
        return [pscustomobject]@{ Ok = $false; Detail = $firstLine }
    }
    return [pscustomobject]@{ Ok = $true; Detail = $out }
}

$argsTail = Get-ArgsTail
$selected = if ($Target -eq 'all') { $Peers } else { $Peers | Where-Object { $_.Key -eq $Target } }

$summary = New-Object System.Collections.Generic.List[object]

foreach ($p in $selected) {
    Write-Host ""
    Write-Host "=== $($p.Key)  ($($p.Ip) / $($p.TsHost))  profile=$($p.Profile) ===" -ForegroundColor Cyan

    $online = $false
    try { $online = (Test-NetConnection -ComputerName $p.Ip -Port 8000 -WarningAction SilentlyContinue).TcpTestSucceeded } catch { $online = $false }
    Write-Host ("  online (kernel :8000): {0}" -f $online)

    $remote = Get-RemoteCommand -Peer $p -ArgsTail $argsTail
    $local  = Get-LocalFallback -Peer $p -ArgsTail $argsTail

    if ($DryRun) {
        Write-Host "  [dry-run] remote: $remote" -ForegroundColor DarkGray
        Write-Host "  [dry-run] local : $local"  -ForegroundColor DarkGray
        $summary.Add([pscustomobject]@{ Seat = $p.Key; Result = 'dry-run'; Detail = '' })
        continue
    }

    $ssh = Test-PeerSsh -Peer $p
    if (-not $ssh.Ok) {
        Write-Host "  RESULT: UNREACHABLE (no remote exec)" -ForegroundColor Yellow
        Write-Host "    reason: $($ssh.Detail)"
        Write-Host "    enable once: 'tailscale up --ssh' on $($p.Key) (+ tailnet ACL), or start an OpenSSH server."
        Write-Host "    run locally on $($p.Key):"
        Write-Host "      $local" -ForegroundColor Gray
        $summary.Add([pscustomobject]@{ Seat = $p.Key; Result = 'UNREACHABLE'; Detail = $ssh.Detail })
        continue
    }

    Write-Host "  SSH ok ($($ssh.Detail)) - triggering watcher..." -ForegroundColor Green
    $enc = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($remote))
    & {
        $ErrorActionPreference = 'Continue'  # native stderr via 2>&1 must not throw under -EA Stop
        & tailscale ssh -- $p.TsHost powershell -NoProfile -ExecutionPolicy Bypass -EncodedCommand $enc 2>&1 |
            ForEach-Object { Write-Host "    $_" }
    }
    Write-Host "  RESULT: TRIGGERED" -ForegroundColor Green
    $summary.Add([pscustomobject]@{ Seat = $p.Key; Result = 'TRIGGERED'; Detail = '' })
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
$summary | ForEach-Object { Write-Host ("  {0,-10} {1} {2}" -f $_.Seat, $_.Result, $_.Detail) }
