# start_federation_laptop.ps1
# Bring the hp-laptop local federation up (manual / reference).
# hp-laptop is a single-primary box — no menno/lola/moos twins (those live on Z440).
# One primary kernel (:8000 + MCP :8080) + one router (:9000).
#
# Idempotent: safe to run while already up (guards skip a live kernel/router).
# To pick up a shard/peer change, stop the router first
#   Stop-Process -Name moos-router
# then re-run this script. For a binary swap use redeploy_laptop_kernel.ps1.
#
# Router shape (T=251): full fan-in shard list + 2-way peer (Z440 + ProDesk),
# matching routers.hp-laptop in dev/config/moos-federation.topology.json. The ProDesk
# leg (shard + peer) was added T=251 when the 6th box rejoined the mesh — before that
# the laptop router fanned in 5/6 (ProDesk invisible from this box). Router 5s timeout
# fallback makes sharding/peering an offline box non-fatal.
#
# Emit discipline: HG rewrites target THIS box's :8000 only — never cross-emit the
# laptop seats to Z440/ProDesk.

$ErrorActionPreference = "Stop"

# Normalize hostname so Test-MoosFederation.ps1 resolves this box as the laptop seat
$env:MOOS_LOCAL_HOST = 'hp-laptop'

# --- Paths ($env:USERPROFILE = C:\Users\maass) ----------------------------
$KernelExe   = "$env:USERPROFILE\HPlaptop\moos-kernel\moos-kernel.exe"
$RouterExe   = "$env:USERPROFILE\HPlaptop\moos-router\moos-router.exe"
$Ontology    = "$env:USERPROFILE\HPlaptop\ffs0\kb\superset\ontology.json"
$Log         = "$env:USERPROFILE\HPlaptop\moos-kernel\moos.jsonl"  # sovereign log — NOT $env:TEMP (would start fresh)

$LocalKernel = "http://localhost:8000"

# --- Primary kernel (idempotent) ------------------------------------------
if (Get-Process -Name moos-kernel -ErrorAction SilentlyContinue) {
    Write-Host "Primary kernel already running — skipping." -ForegroundColor Gray
} else {
    Write-Host "Starting moos primary kernel (laptop)..." -ForegroundColor Cyan
    Start-Process -FilePath $KernelExe `
        -ArgumentList "--ontology `"$Ontology`" --log `"$Log`" --listen :8000 --mcp-addr :8080 --seed --seed-user sam --seed-ws hp-laptop" `
        -WindowStyle Hidden
    Start-Sleep -Seconds 2
}

try {
    $h = Invoke-RestMethod "$LocalKernel/healthz" -TimeoutSec 5
    Write-Host ("Primary kernel: {0} [ontology {1}, t_day {2}, log_len {3}]" -f $h.status, $h.ontology_version, $h.t_day, $h.log_len) -ForegroundColor Green
} catch {
    Write-Host "WARNING: kernel healthz failed — may still be starting. Check log: $Log" -ForegroundColor Yellow
}

# --- Router (idempotent; full shard list + 2-way peer) --------------------
# Tailscale IPs are permanent for this tailnet (dev/config/moos-federation.topology.json).
# Shard set preserves the pre-T251 list verbatim and appends the ProDesk kernel shard.
$RouterArgs = @(
    "--listen :9000"
    "--shard urn:moos:ws:hp-laptop=$LocalKernel"
    "--shard urn:moos:ws:hp-z440=http://100.82.243.13:8000"
    "--shard urn:moos:kernel:hp-z440.primary=http://100.82.243.13:8000"
    "--shard urn:moos:kernel:hp-z440.menno=http://100.82.243.13:8001"
    "--shard urn:moos:kernel:hp-z440.lola=http://100.82.243.13:8002"
    "--shard urn:moos:kernel:hp-z440.moos=http://100.82.243.13:8003"
    "--shard urn:moos:kernel:hpprodesk.primary=http://100.87.28.95:8000"
    "--peer http://100.82.243.13:9000"
    "--peer http://100.87.28.95:9000"
    "--default $LocalKernel"
) -join " "

if (Get-Process -Name moos-router -ErrorAction SilentlyContinue) {
    Write-Host "Router already running — skipping (stop it first to pick up shard/peer changes)." -ForegroundColor Gray
} else {
    Write-Host "Starting moos router (laptop; shards: laptop + Z440x4 + ProDesk; peers: Z440 + ProDesk)..." -ForegroundColor Cyan
    Start-Process -FilePath $RouterExe -ArgumentList $RouterArgs -WindowStyle Hidden
    Start-Sleep -Seconds 2
}

try {
    $r = Invoke-RestMethod "http://localhost:9000/healthz" -TimeoutSec 8
    Write-Host ("Router: {0} [fans in {1} kernel(s)]" -f $r.status, $r.kernels.Count) -ForegroundColor Green
} catch {
    Write-Host "WARNING: router healthz failed — may still be starting." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Laptop federation up. Kernel :8000 | MCP http://localhost:8080/sse | Router :9000" -ForegroundColor Green
Write-Host "Secondaries (menno/lola/moos) are on Z440 — no action needed here." -ForegroundColor Gray
Write-Host "Verify full mesh: dev\scripts\ops\Test-MoosFederation.ps1 -Mode Doctor" -ForegroundColor Gray
