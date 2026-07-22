# start_federation_z440.ps1
# Bring the Z440 local federation up: primary kernel (:8000 + MCP :8080),
# three twins (menno :8001/:9001, lola :8002/:9002, moos :8003/:9003), and
# the router (:9000).
#
# Persistence: intended autostart single source of truth for Z440 — re-point
# the `moos-kernel-autostart` scheduled task at THIS tracked script (same move
# as ProDesk's T=227 repoint; until then the untracked D:\HPZ440\start_federation.ps1
# copy remains the live autostart target).
#
# Router shape (T=251, ffs0#154): UNIFORM topology-file launch. The routing
# table (kernel shards, ws aliases, default rule, peers) comes from
# dev/config/moos-federation.topology.json, loaded at boot and hot-reloadable
# via POST http://localhost:9000/admin/topology/reload. --default is only the
# bootstrap fallback if the file fails to load. Requires the moos-router build
# with boot-load support (feat/topology-file-sot or later) — rebuild the binary
# before relaunching with this script.
#
# NOT idempotent: kills anything on the federation ports first (full restart).

$ErrorActionPreference = 'Stop'

# Normalize hostname so Test-MoosFederation.ps1 resolves this box as the Z440 seat
$env:MOOS_LOCAL_HOST = 'hp-z440'

# --- Paths ------------------------------------------------------------------
$KernelExe    = 'D:\HPZ440\moos-kernel\moos-kernel.exe'
$RouterExe    = 'D:\HPZ440\moos-router\moos-router.exe'   # canonical repo path (legacy feat-worktree copy removed T=247)
$TopologyFile = 'D:\HPZ440\ffs0\dev\config\moos-federation.topology.json'
$Ontology     = 'D:\HPZ440\ffs0\kb\superset\ontology.json'
$LocalKernel  = 'http://localhost:8000'

# Bearer auth (moos-kernel #60): pass the token file only when it is a real,
# non-empty leaf file - the kernel exits FATAL on a missing/empty/dir path
# (Copilot catch on #167), and unset means open+WARNING, so anything less than
# a usable token degrades to the pre-#60 posture instead of a dead boot.
$AuthTokenFile = 'D:\HPZ440\ffs0\secrets\moos-auth-token'
$AuthArgs = @()
$AuthTokenUsable = $false
if (Test-Path $AuthTokenFile -PathType Leaf) {
    try { $AuthTokenUsable = ([IO.File]::ReadAllText($AuthTokenFile).Trim().Length -gt 0) } catch {}
}
if ($AuthTokenUsable) {
    $AuthArgs = @('--auth-token-file', $AuthTokenFile)
} else {
    Write-Host "WARNING: $AuthTokenFile missing or empty - kernels start UNAUTHENTICATED (write routes open)." -ForegroundColor Yellow
}

# Gemini LLM proxy (moos-kernel #58 egress + #63 scope-split): enabled on the
# PRIMARY kernel only. The scope-split bearer rides the same non-empty-leaf
# guard as the write token; without it /llm/* is gated by the write token
# alone (and with neither token the proxy would be open - warned above).
$LLMTokenFile = 'D:\HPZ440\ffs0\secrets\moos-llm-token'
$LLMArgs = @('--enable-llm-proxy')
$LLMTokenUsable = $false
if (Test-Path $LLMTokenFile -PathType Leaf) {
    try { $LLMTokenUsable = ([IO.File]::ReadAllText($LLMTokenFile).Trim().Length -gt 0) } catch {}
}
if ($LLMTokenUsable) {
    $LLMArgs += @('--llm-token-file', $LLMTokenFile)
} else {
    Write-Host "WARNING: $LLMTokenFile missing or empty - /llm/* gated by the write token only." -ForegroundColor Yellow
}

# --- Full restart: clear the federation ports -------------------------------
$ports = @(8000, 8080, 8001, 9001, 8002, 9002, 8003, 9003, 9000)
$owners = Get-NetTCPConnection -State Listen -LocalPort $ports -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty OwningProcess -Unique
foreach ($p in $owners) {
    if ($p -and $p -ne $PID) {
        Stop-Process -Id $p -Force -ErrorAction SilentlyContinue
    }
}

Start-Sleep -Seconds 1

# --- 1. Primary kernel — :8000 / MCP :8080 -----------------------------------
Write-Host "Starting primary kernel (:8000)..."
Start-Process -FilePath $KernelExe -ArgumentList (@('--ontology',$Ontology,'--log','D:\HPZ440\moos-kernel\moos.jsonl','--listen',':8000','--mcp-addr',':8080','--seed','--seed-user','sam','--seed-ws','hp-z440') + $AuthArgs + $LLMArgs) -WorkingDirectory 'D:\HPZ440\moos-kernel' -WindowStyle Minimized

Start-Sleep -Seconds 3

# --- 2. Twin kernels ----------------------------------------------------------
Write-Host "Starting twin kernels (:8001-8003)..."
Start-Process -FilePath $KernelExe -ArgumentList (@('--ontology',$Ontology,'--log','D:\HPZ440\kernels\menno\moos.jsonl','--listen',':8001','--mcp-addr',':9001') + $AuthArgs) -WindowStyle Minimized
Start-Process -FilePath $KernelExe -ArgumentList (@('--ontology',$Ontology,'--log','D:\HPZ440\kernels\lola\moos.jsonl','--listen',':8002','--mcp-addr',':9002') + $AuthArgs) -WindowStyle Minimized
Start-Process -FilePath $KernelExe -ArgumentList (@('--ontology',$Ontology,'--log','D:\HPZ440\kernels\moos\moos.jsonl','--listen',':8003','--mcp-addr',':9003') + $AuthArgs) -WindowStyle Minimized

Start-Sleep -Seconds 3

# --- 3. Router — :9000 (topology-file SOT) ------------------------------------
Write-Host "Starting router (:9000, topology from $TopologyFile)..."
Start-Process -FilePath $RouterExe -ArgumentList `
    '--listen',':9000',`
    '--default',$LocalKernel,`
    '--topology-file',$TopologyFile,`
    '--local-host','hp-z440' `
    -WorkingDirectory (Split-Path $RouterExe -Parent) -WindowStyle Minimized

Start-Sleep -Seconds 2

try {
    $r = Invoke-RestMethod 'http://localhost:9000/healthz' -TimeoutSec 8
    Write-Host ("Router: {0} [fans in {1} kernel(s)]" -f $r.status, $r.kernels.Count) -ForegroundColor Green
    if ($r.kernels.Count -lt 6) {
        Write-Host "WARNING: fan-in below 6 — topology file may not have loaded (old binary?). Check GET http://localhost:9000/admin/topology" -ForegroundColor Yellow
    }
} catch {
    Write-Host "WARNING: router healthz failed — may still be starting." -ForegroundColor Yellow
}

Write-Host "Federation started. Kernels: :8000-8003  MCP: :8080,:9001-9003  Router: :9000"
Write-Host "Verify full mesh: dev\scripts\ops\Test-MoosFederation.ps1 -Mode Doctor" -ForegroundColor Gray
