<#
.SYNOPSIS
    Read-only security audit of one mo:os seat host (z440 / hp-laptop / hpprodesk).

.DESCRIPTION
    Written at t306 after Google Antigravity installed additional applications on the
    Z440 and hp-laptop seats. Antigravity is a Windsurf-derived agentic IDE: it can
    register MCP servers, drive a browser through an extension, and run background
    binaries under the user profile. Each of those is a new local principal on a box
    where the kernel's READ surface is unauthenticated by design.

    This script MUTATES NOTHING. It reports. Every remediation is Sam's hands.

    Checks (each emits PASS / WARN / FAIL / INFO):
      A  Antigravity / Gemini / Codeium install + config footprint
      B  MCP servers registered outside .vscode/mcp.json, and their filesystem roots
      C  Kernel + MCP + router listeners: bind address, owning process
      D  Kernel write-auth: is a bearer token actually configured on the running kernel
      E  Live probe: unauthenticated write must 401; read CORS is open by design
      F  Windows Firewall inbound rules for the moos ports and for agent binaries
      G  Autostart surface: Run keys, scheduled tasks, services under agent paths
      H  secrets/ exposure: ACL, and whether an agent workspace root contains it
      I  cloudflared ingress on this box
      J  Browser extensions + native messaging hosts belonging to agent vendors

.PARAMETER Json
    Emit the findings as JSON on stdout instead of the formatted table (for G-ingest).

.PARAMETER SkipProbe
    Skip check E (the live HTTP probe against the local kernel).

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File dev\scripts\ops\Test-SeatSecurity.ps1

.EXAMPLE
    ... -Json > tmp\seat-security-z440.json
#>
[CmdletBinding()]
param(
    [switch]$Json,
    [switch]$SkipProbe
)

$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'

$findings = New-Object System.Collections.ArrayList

function Add-Finding {
    param(
        [Parameter(Mandatory)][string]$Check,
        [Parameter(Mandatory)][ValidateSet('PASS', 'WARN', 'FAIL', 'INFO')][string]$Severity,
        [Parameter(Mandatory)][string]$Title,
        [string]$Detail = '',
        [string]$Remediation = ''
    )
    $null = $findings.Add([pscustomobject]@{
            check       = $Check
            severity    = $Severity
            title       = $Title
            detail      = $Detail
            remediation = $Remediation
        })
}

$hostName = $env:COMPUTERNAME
$userProfile = $env:USERPROFILE
# ops -> scripts -> dev -> <ffs0 root>
$repoRoot = (Resolve-Path (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) '..\..\..')).Path
$secretsDir = Join-Path $repoRoot 'secrets'
# The secret values in secrets/ are gitignored, so they exist only in the main clone; a linked
# worktree (ffs0.wt\<branch>) has secrets/ with the tracked examples only. From a linked worktree,
# audit the main clone's secrets/ (resolved through the shared git dir).
try {
    $gitDir = (& git -C $repoRoot rev-parse --path-format=absolute --git-dir 2>$null)
    $common = (& git -C $repoRoot rev-parse --path-format=absolute --git-common-dir 2>$null)
    if ($gitDir -and $common -and ($gitDir -ne $common)) {
        $mainSecrets = Join-Path (Split-Path -Parent $common) 'secrets'
        if (Test-Path -LiteralPath $mainSecrets) { $secretsDir = $mainSecrets }
    }
} catch {}

# moos ports per dev/config/moos-federation.topology.json
$moosPorts = @(8000, 8001, 8002, 8003, 8080, 9000, 9001, 9002, 9003)

# Vendor path fragments that mark an agent-IDE-installed artifact.
$agentPathMarkers = @('antigravity', '\.gemini', 'codeium', 'windsurf', 'cursor')

# ---------------------------------------------------------------- A · footprint
$agentRoots = @(
    (Join-Path $userProfile '.gemini\antigravity'),
    (Join-Path $userProfile '.antigravity'),
    (Join-Path $userProfile '.codeium'),
    (Join-Path $env:LOCALAPPDATA 'Programs\Antigravity'),
    (Join-Path $env:LOCALAPPDATA 'Antigravity'),
    (Join-Path $env:APPDATA 'Antigravity')
) | Where-Object { $_ -and (Test-Path $_) }

if ($agentRoots.Count -eq 0) {
    Add-Finding -Check 'A' -Severity 'PASS' -Title 'No Antigravity/Gemini/Codeium footprint on this host'
}
else {
    foreach ($r in $agentRoots) {
        $sz = 0
        try { $sz = (Get-ChildItem -LiteralPath $r -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum } catch {}
        Add-Finding -Check 'A' -Severity 'INFO' -Title 'Agent-IDE install root present' `
            -Detail ("{0}  ({1:N1} MB)" -f $r, ($sz / 1MB))
    }
}

# Running processes from those roots.
$agentProcs = @()
try {
    $agentProcs = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
        Where-Object {
            $p = $_.ExecutablePath
            $p -and ($agentPathMarkers | Where-Object { $p -match [regex]::Escape($_) })
        }
}
catch {}
foreach ($p in $agentProcs) {
    Add-Finding -Check 'A' -Severity 'INFO' -Title 'Agent-vendor process running' `
        -Detail ("pid {0}  {1}" -f $p.ProcessId, $p.ExecutablePath)
}

# ---------------------------------------------------------------- B · MCP servers
# Antigravity/Windsurf keep MCP registrations in mcp_config.json under the user profile.
$mcpConfigs = @()
foreach ($base in @((Join-Path $userProfile '.gemini'), (Join-Path $userProfile '.antigravity'), (Join-Path $userProfile '.codeium'), (Join-Path $env:APPDATA 'Antigravity'))) {
    if (Test-Path $base) {
        $mcpConfigs += Get-ChildItem -LiteralPath $base -Recurse -File -Filter 'mcp_config.json' -Force -ErrorAction SilentlyContinue
        $mcpConfigs += Get-ChildItem -LiteralPath $base -Recurse -File -Filter 'mcp.json' -Force -ErrorAction SilentlyContinue
    }
}

if ($mcpConfigs.Count -eq 0) {
    Add-Finding -Check 'B' -Severity 'PASS' -Title 'No agent-IDE MCP registration files found outside .vscode/'
}

# Antigravity keeps several copies of the same registry (antigravity\, antigravity-backup\,
# antigravity-ide\, config\, playground\*\.vscode\). Report each distinct server/root once and
# list every config that carries it, instead of one finding per copy.
$serverSeen = [ordered]@{}
$rootSeen = [ordered]@{}

foreach ($cfg in $mcpConfigs) {
    Add-Finding -Check 'B' -Severity 'INFO' -Title 'Agent-IDE MCP config' -Detail $cfg.FullName
    $parsed = $null
    try { $parsed = Get-Content -LiteralPath $cfg.FullName -Raw -ErrorAction Stop | ConvertFrom-Json } catch {
        Add-Finding -Check 'B' -Severity 'WARN' -Title 'MCP config unparseable' -Detail $cfg.FullName
        continue
    }
    $servers = $null
    foreach ($k in @('mcpServers', 'servers')) { if ($parsed.PSObject.Properties.Name -contains $k) { $servers = $parsed.$k } }
    if (-not $servers) { continue }

    foreach ($name in $servers.PSObject.Properties.Name) {
        $s = $servers.$name
        $cmd = @()
        if ($s.PSObject.Properties.Name -contains 'command') { $cmd += [string]$s.command }
        if ($s.PSObject.Properties.Name -contains 'args') { $cmd += @($s.args | ForEach-Object { [string]$_ }) }
        $line = ($cmd -join ' ')
        $url = if ($s.PSObject.Properties.Name -contains 'url') { [string]$s.url } else { '' }

        # A filesystem/shell/desktop MCP server is a general file-access grant.
        $isFileAccess = $line -match 'server-filesystem|filesystem|mcp-server-commands|shell|desktop-commander|iterm|terminal|git\b'
        $sev = if ($isFileAccess) { 'FAIL' } else { 'WARN' }
        $key = "$name|$line|$url"
        if (-not $serverSeen.Contains($key)) {
            $serverSeen[$key] = [pscustomobject]@{ Name = $name; Line = $line; Url = $url; Sev = $sev; Configs = [System.Collections.Generic.List[string]]::new() }
        }
        $serverSeen[$key].Configs.Add($cfg.FullName)

        # Roots the server was handed.
        foreach ($a in $cmd) {
            # Directories only: a server's own entry script (node ...\mcp-server.js) is not a root it was handed.
            if ($a -match '^[A-Za-z]:\\' -and (Test-Path -LiteralPath $a -PathType Container)) {
                $covers = $false
                try { $covers = $secretsDir.ToLower().StartsWith($a.ToLower()) -or $a.ToLower().Contains('secret') } catch {}
                $rkey = "$name|$a"
                if (-not $rootSeen.Contains($rkey)) {
                    $rootSeen[$rkey] = [pscustomobject]@{ Name = $name; Root = $a; Covers = $covers; Configs = [System.Collections.Generic.List[string]]::new() }
                }
                $rootSeen[$rkey].Configs.Add($cfg.FullName)
            }
        }
    }
}

foreach ($s in $serverSeen.Values) {
    Add-Finding -Check 'B' -Severity $s.Sev -Title ("MCP server '{0}' registered by an agent IDE" -f $s.Name) `
        -Detail (("cmd: {0}" -f $s.Line) + $(if ($s.Url) { "  url: $($s.Url)" } else { '' }) + ("  configs ({0}): {1}" -f $s.Configs.Count, ($s.Configs -join '; '))) `
        -Remediation 'Confirm this server is one you added. A filesystem/shell MCP server grants the IDE agent read+write over every path passed as a root — remove it or narrow its roots (in every config listed).'
}
foreach ($r in $rootSeen.Values) {
    Add-Finding -Check 'B' -Severity $(if ($r.Covers) { 'FAIL' } else { 'WARN' }) `
        -Title ("MCP server '{0}' granted filesystem root" -f $r.Name) `
        -Detail ("{0}  configs ({1}): {2}" -f $r.Root, $r.Configs.Count, ($r.Configs -join '; ')) `
        -Remediation $(if ($r.Covers) { 'This root reaches ffs0\secrets. Narrow it now.' } else { 'Verify the root is intended.' })
}

# ---------------------------------------------------------------- C · listeners
$conns = @()
try { $conns = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue } catch {}
if ($conns.Count -eq 0) {
    Add-Finding -Check 'C' -Severity 'INFO' -Title 'Get-NetTCPConnection unavailable; run `netstat -ano` manually'
}
foreach ($c in ($conns | Where-Object { $moosPorts -contains $_.LocalPort })) {
    $pname = ''
    try { $pname = (Get-Process -Id $c.OwningProcess -ErrorAction SilentlyContinue).Path } catch {}
    $public = ($c.LocalAddress -eq '0.0.0.0' -or $c.LocalAddress -eq '::')
    Add-Finding -Check 'C' -Severity $(if ($public) { 'WARN' } else { 'PASS' }) `
        -Title ("port {0} listening on {1}" -f $c.LocalPort, $c.LocalAddress) `
        -Detail ("pid {0}  {1}" -f $c.OwningProcess, $pname) `
        -Remediation $(if ($public) { 'Bound to every interface. Kernel READ endpoints are unauthenticated by design, so every host on the LAN and the tailnet can read the full fold. Bind loopback (--listen 127.0.0.1:8000 / --mcp-addr 127.0.0.1:8080) on any seat that is not a deliberate federation peer.' } else { '' })
}

# Any listener owned by an agent-vendor binary is a new inbound surface.
foreach ($c in $conns) {
    $ppath = ''
    try { $ppath = (Get-Process -Id $c.OwningProcess -ErrorAction SilentlyContinue).Path } catch {}
    if (-not $ppath) { continue }
    if ($agentPathMarkers | Where-Object { $ppath -match [regex]::Escape($_) }) {
        $public = ($c.LocalAddress -eq '0.0.0.0' -or $c.LocalAddress -eq '::')
        Add-Finding -Check 'C' -Severity $(if ($public) { 'FAIL' } else { 'INFO' }) `
            -Title ("agent-vendor binary listening on {0}:{1}" -f $c.LocalAddress, $c.LocalPort) `
            -Detail $ppath `
            -Remediation $(if ($public) { 'An agent IDE component is accepting connections from off-box. Firewall it or reconfigure it to loopback.' } else { '' })
    }
}

# ---------------------------------------------------------------- D · kernel write-auth
$kernelProcs = @()
try {
    # Exact name: moos-router.exe and moos-lsp.exe take no --auth-token-file (the router forwards the
    # caller's bearer; the LSP is a read client), so matching 'moos%' reported them as unauthenticated kernels.
    $kernelProcs = @(Get-CimInstance Win32_Process -Filter "Name = 'moos-kernel.exe'" -ErrorAction SilentlyContinue)
}
catch {}
if ($kernelProcs.Count -eq 0) {
    Add-Finding -Check 'D' -Severity 'INFO' -Title 'No moos kernel process found on this host'
}
foreach ($k in $kernelProcs) {
    $cl = [string]$k.CommandLine
    $hasTokenFlag = $cl -match '--auth-token-file'
    Add-Finding -Check 'D' -Severity $(if ($hasTokenFlag) { 'PASS' } else { 'FAIL' }) `
        -Title ("kernel pid {0} write-auth" -f $k.ProcessId) `
        -Detail $cl `
        -Remediation $(if ($hasTokenFlag) { '' } else { 'No --auth-token-file. If MOOS_AUTH_TOKEN is also unset the kernel accepts UNAUTHENTICATED POST /rewrites, /programs and /twin/ingest from anything that can reach the port — including any local process an agent IDE spawns. Set a token in ffs0\secrets\moos-auth-token and restart via start_federation_*.ps1.' })
}
$tokenFile = Join-Path $secretsDir 'moos-auth-token'
Add-Finding -Check 'D' -Severity $(if (Test-Path $tokenFile) { 'PASS' } else { 'WARN' }) `
    -Title 'bearer token file' -Detail $tokenFile

# ---------------------------------------------------------------- E · live probe
if (-not $SkipProbe) {
    foreach ($port in @(8000, 8001, 8002, 8003)) {
        $base = "http://127.0.0.1:$port"
        $health = $null
        try { $health = Invoke-WebRequest -Uri "$base/healthz" -TimeoutSec 3 -UseBasicParsing -ErrorAction Stop } catch {}
        if (-not $health) { continue }

        # Unauthenticated write MUST be refused.
        $code = 0
        try {
            $r = Invoke-WebRequest -Uri "$base/rewrites" -Method POST -Body '{}' -ContentType 'application/json' `
                -TimeoutSec 3 -UseBasicParsing -ErrorAction Stop
            $code = $r.StatusCode
        }
        catch { if ($_.Exception.Response) { $code = [int]$_.Exception.Response.StatusCode } }

        Add-Finding -Check 'E' -Severity $(if ($code -eq 401) { 'PASS' } else { 'FAIL' }) `
            -Title ("kernel :{0} unauthenticated POST /rewrites -> {1}" -f $port, $code) `
            -Detail 'expected 401' `
            -Remediation $(if ($code -eq 401) { '' } else { 'The write path is open. Any local process — an agent-IDE MCP server, a browser extension, a script — can append to the sovereign log. Configure the bearer token (check D).' })

        # Read surface: open by design, and CORS is *. Stated so it is not a surprise.
        $acao = ''
        try { $acao = [string]$health.Headers['Access-Control-Allow-Origin'] } catch {}
        if ($acao -eq '*') {
            Add-Finding -Check 'E' -Severity 'WARN' `
                -Title ("kernel :{0} read surface: unauthenticated + Access-Control-Allow-Origin: *" -f $port) `
                -Detail 'This is the shipped design (reads open for observability), not a misconfiguration.' `
                -Remediation 'Consequence worth naming at t306: ANY web page loaded in ANY browser on this box can fetch http://localhost:PORT/state and read the entire fold cross-origin. An agentic IDE that drives a browser widens exactly this. If that is not acceptable, the fix is upstream in moos-kernel (origin allowlist on reads) — see moos-kernel#68.'
        }
    }
}

# ---------------------------------------------------------------- F · firewall
$fwRules = @()
try { $fwRules = Get-NetFirewallRule -Direction Inbound -Enabled True -Action Allow -ErrorAction SilentlyContinue } catch {}
foreach ($rule in $fwRules) {
    $appPath = ''
    try { $appPath = (Get-NetFirewallApplicationFilter -AssociatedNetFirewallRule $rule -ErrorAction SilentlyContinue).Program } catch {}
    $ports = ''
    try { $ports = (Get-NetFirewallPortFilter -AssociatedNetFirewallRule $rule -ErrorAction SilentlyContinue).LocalPort -join ',' } catch {}

    if ($appPath -and ($agentPathMarkers | Where-Object { $appPath -match [regex]::Escape($_) })) {
        Add-Finding -Check 'F' -Severity 'FAIL' -Title 'inbound Allow rule for an agent-vendor binary' `
            -Detail ("{0}  ->  {1}" -f $rule.DisplayName, $appPath) `
            -Remediation 'An installer opened the firewall for an agent-IDE component. Remove it unless you added it deliberately.'
    }
    elseif ($ports -and ($moosPorts | Where-Object { $ports -split ',' -contains "$_" })) {
        Add-Finding -Check 'F' -Severity 'WARN' -Title 'inbound Allow rule covering a moos port' `
            -Detail ("{0}  ports {1}  program {2}" -f $rule.DisplayName, $ports, $appPath) `
            -Remediation 'Scope it to the Tailscale interface if it is meant for federation; delete it otherwise.'
    }
}
if ($fwRules.Count -eq 0) {
    Add-Finding -Check 'F' -Severity 'INFO' -Title 'Firewall rules not readable (needs an elevated shell)'
}

# ---------------------------------------------------------------- G · autostart
foreach ($key in @('HKCU:\Software\Microsoft\Windows\CurrentVersion\Run', 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run')) {
    if (-not (Test-Path $key)) { continue }
    $props = Get-ItemProperty -Path $key -ErrorAction SilentlyContinue
    foreach ($n in $props.PSObject.Properties.Name) {
        if ($n -in @('PSPath', 'PSParentPath', 'PSChildName', 'PSDrive', 'PSProvider')) { continue }
        $v = [string]$props.$n
        if ($agentPathMarkers | Where-Object { $v -match [regex]::Escape($_) }) {
            Add-Finding -Check 'G' -Severity 'WARN' -Title 'Run-key autostart for an agent-vendor binary' `
                -Detail ("{0}\{1} = {2}" -f $key, $n, $v) `
                -Remediation 'Confirm intended; an agent IDE that starts with the session is a standing local principal.'
        }
    }
}
try {
    foreach ($t in (Get-ScheduledTask -ErrorAction SilentlyContinue)) {
        $act = ($t.Actions | ForEach-Object { [string]$_.Execute }) -join ';'
        if ($act -and ($agentPathMarkers | Where-Object { $act -match [regex]::Escape($_) })) {
            Add-Finding -Check 'G' -Severity 'WARN' -Title 'scheduled task runs an agent-vendor binary' `
                -Detail ("{0}{1}  ->  {2}" -f $t.TaskPath, $t.TaskName, $act)
        }
    }
}
catch {}
try {
    foreach ($svc in (Get-CimInstance Win32_Service -ErrorAction SilentlyContinue)) {
        $pn = [string]$svc.PathName
        if ($pn -and ($agentPathMarkers | Where-Object { $pn -match [regex]::Escape($_) })) {
            Add-Finding -Check 'G' -Severity 'FAIL' -Title 'Windows SERVICE installed by an agent vendor' `
                -Detail ("{0}  [{1}]  {2}" -f $svc.Name, $svc.StartMode, $pn) `
                -Remediation 'A service runs outside your session and often as SYSTEM. Verify why an IDE needed one.'
        }
    }
}
catch {}

# ---------------------------------------------------------------- H · secrets exposure
if (Test-Path $secretsDir) {
    $acl = Get-Acl -LiteralPath $secretsDir -ErrorAction SilentlyContinue
    $broad = @()
    foreach ($ace in @($acl.Access)) {
        if (-not $ace) { continue }
        if ($ace.IdentityReference -match 'Everyone|BUILTIN\\Users|Authenticated Users|INTERACTIVE') {
            $broad += ("{0}={1}" -f $ace.IdentityReference, $ace.FileSystemRights)
        }
    }
    Add-Finding -Check 'H' -Severity $(if ($broad.Count) { 'WARN' } else { 'PASS' }) `
        -Title 'secrets/ ACL' -Detail ($secretsDir + '  ' + ($broad -join '; ')) `
        -Remediation $(if ($broad.Count) { 'Tighten to the owner. Note the harder truth: an agent IDE running AS Sam inherits Sam''s rights regardless of ACL — the real control is not granting a filesystem MCP server a root above the repo (check B).' } else { '' })

    Add-Finding -Check 'H' -Severity 'INFO' -Title 'secrets/ contents (names only, never values)' `
        -Detail ((Get-ChildItem -LiteralPath $secretsDir -File -Force -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name) -join ', ')
}

# ---------------------------------------------------------------- I · cloudflared
$cfProcs = Get-Process -Name 'cloudflared' -ErrorAction SilentlyContinue
if ($cfProcs) {
    foreach ($c in $cfProcs) {
        Add-Finding -Check 'I' -Severity 'INFO' -Title 'cloudflared running on this host' -Detail ("pid {0}  {1}" -f $c.Id, $c.Path)
    }
    $cfDir = Join-Path $userProfile '.cloudflared'
    if (Test-Path $cfDir) {
        $creds = (Get-ChildItem -LiteralPath $cfDir -File -Force -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name) -join ', '
        Add-Finding -Check 'I' -Severity 'WARN' -Title 'tunnel credentials on disk' -Detail ("{0}: {1}" -f $cfDir, $creds) `
            -Remediation 'A tunnel credential is a standing route from the internet to this box. Delete the credential of any dormant tunnel (t283 recorded `collider-studio`, 0 connectors, credential still present on Z440). Confirm every live ingress hostname has an Access policy.'
    }
}
else {
    Add-Finding -Check 'I' -Severity 'PASS' -Title 'no cloudflared process on this host'
}

# ---------------------------------------------------------------- J · browser surface
$extRoots = @(
    (Join-Path $env:LOCALAPPDATA 'Google\Chrome\User Data\Default\Extensions'),
    (Join-Path $env:LOCALAPPDATA 'Microsoft\Edge\User Data\Default\Extensions')
) | Where-Object { Test-Path $_ }
foreach ($er in $extRoots) {
    $count = (Get-ChildItem -LiteralPath $er -Directory -ErrorAction SilentlyContinue).Count
    Add-Finding -Check 'J' -Severity 'INFO' -Title 'browser extensions installed' -Detail ("{0}: {1} extension(s)" -f $er, $count) `
        -Remediation 'Antigravity installs a browser extension to drive Chrome. Any extension with host permissions for http://localhost/* can read the kernel fold (see E). Review chrome://extensions and remove what you did not install.'
}
foreach ($nm in @(
        (Join-Path $env:LOCALAPPDATA 'Google\Chrome\User Data\NativeMessagingHosts'),
        (Join-Path $userProfile 'AppData\Roaming\Mozilla\NativeMessagingHosts'))) {
    if (Test-Path $nm) {
        $hosts = (Get-ChildItem -LiteralPath $nm -File -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name) -join ', '
        if ($hosts) {
            Add-Finding -Check 'J' -Severity 'WARN' -Title 'native messaging hosts registered' -Detail ("{0}: {1}" -f $nm, $hosts) `
                -Remediation 'A native messaging host lets a browser extension execute a local binary. This is the bridge from a web page to the filesystem — review each one.'
        }
    }
}

# ---------------------------------------------------------------- report
if ($Json) {
    [pscustomobject]@{
        host      = $hostName
        scanned   = (Get-Date).ToString('o')
        repo_root = $repoRoot
        findings  = $findings
    } | ConvertTo-Json -Depth 6
    # Same exit contract as the console path: 1 when any check FAILs.
    if (@($findings | Where-Object { $_.severity -eq 'FAIL' }).Count -gt 0) { exit 1 }
    exit 0
}

Write-Host ''
Write-Host "mo:os seat security audit — $hostName — $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -ForegroundColor Cyan
Write-Host ('=' * 78) -ForegroundColor Cyan
Write-Host 'READ-ONLY. Nothing was changed. Every remediation below is a boundary act.' -ForegroundColor DarkGray
Write-Host ''

foreach ($sev in @('FAIL', 'WARN', 'PASS', 'INFO')) {
    $rows = $findings | Where-Object { $_.severity -eq $sev }
    if (-not $rows) { continue }
    $color = switch ($sev) { 'FAIL' { 'Red' } 'WARN' { 'Yellow' } 'PASS' { 'Green' } default { 'DarkGray' } }
    Write-Host "[$sev] ($($rows.Count))" -ForegroundColor $color
    foreach ($f in $rows) {
        Write-Host ("  {0} · {1}" -f $f.check, $f.title) -ForegroundColor $color
        if ($f.detail) { Write-Host ("      {0}" -f $f.detail) -ForegroundColor DarkGray }
        if ($f.remediation) { Write-Host ("      -> {0}" -f $f.remediation) -ForegroundColor DarkCyan }
    }
    Write-Host ''
}

$fails = ($findings | Where-Object { $_.severity -eq 'FAIL' }).Count
$warns = ($findings | Where-Object { $_.severity -eq 'WARN' }).Count
Write-Host ("summary: {0} FAIL · {1} WARN · {2} finding(s) total" -f $fails, $warns, $findings.Count) -ForegroundColor Cyan
if ($fails -gt 0) { exit 1 }
exit 0
