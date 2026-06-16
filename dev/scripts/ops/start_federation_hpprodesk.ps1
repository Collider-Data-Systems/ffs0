# start_federation_hpprodesk.ps1
# Bring the HP ProDesk local federation up (manual / reference).
# ProDesk is its own single-seat box (session:sam.hpprodesk-setup): one primary
# kernel + one router. No menno/lola/moos twins here (those live on Z440).
#
# Persistence note: reboot persistence is ALREADY provided by the local
# `moos-prodesk` scheduled task (logon trigger) -> C:\Users\Geurt\CDS\start-moos.ps1,
# which is kept LOCAL + untracked per the fleet convention for machine startup
# scripts (cf. Z440 D:\HPZ440\start_federation.ps1, hp-laptop's Startup .bat).
# THIS tracked script is the reviewable parity mirror of that invocation plus
# healthz readback + idempotent guards, for manual bring-up and reference. It is
# NOT what the scheduled task runs; keep the two in sync if either changes.
#
# Router shape = FULL 3-WAY PEER (Sam's #64 call): ProDesk peers out to hp-laptop
# + Z440, matching routers.hpprodesk.peers in dev/config/moos-federation.topology.json.
# The 5s router timeout fallback makes peering to an offline box non-fatal.
#
# Emit discipline: HG rewrites target THIS box's :8000 only — never cross-emit
# the ProDesk seat to laptop/Z440.

$ErrorActionPreference = "Stop"

# Normalize hostname so Test-MoosFederation.ps1 resolves this box as the ProDesk seat
$env:MOOS_LOCAL_HOST = 'hpprodesk'

# --- Paths (ProDesk: $env:USERPROFILE = C:\Users\Geurt) -------------------
$Base        = "$env:USERPROFILE\CDS"
$KernelExe   = "$Base\moos-kernel\moos-kernel.exe"
$RouterExe   = "$Base\moos-router\moos-router.exe"
$Ontology    = "$Base\ffs0\kb\superset\ontology.json"
$Log         = "$Base\moos-kernel\moos.hpprodesk.jsonl"  # sovereign log — NOT $env:TEMP (would start fresh)

# --- Peers (Tailscale IPs are permanent for this tailnet) -----------------
$PeerLaptop  = "http://100.106.220.58:9000"   # hp-laptop (lap-sam)
$PeerZ440    = "http://100.82.243.13:9000"     # Z440 (desktop-42d00rd)
$LocalKernel = "http://localhost:8000"
$Shard       = "urn:moos:kernel:hpprodesk.primary=$LocalKernel"

# --- Kernel (idempotent: skip if already running) -------------------------
if (Get-Process -Name moos-kernel -ErrorAction SilentlyContinue) {
    Write-Host "Primary kernel already running — skipping." -ForegroundColor Gray
} else {
    Write-Host "Starting moos primary kernel (ProDesk)..." -ForegroundColor Cyan
    Start-Process -FilePath $KernelExe `
        -ArgumentList "--ontology `"$Ontology`" --log `"$Log`" --listen :8000 --mcp-addr :8080 --seed --seed-user sam --seed-ws hpprodesk" `
        -WindowStyle Normal
    Start-Sleep -Seconds 2
}

try {
    $h = Invoke-RestMethod "$LocalKernel/healthz" -TimeoutSec 5
    $msg = "Primary kernel: {0} [ontology {1}, t_day {2}, log_len {3}]" -f $h.status, $h.ontology_version, $h.t_day, $h.log_len
    Write-Host $msg -ForegroundColor Green
} catch {
    Write-Host "WARNING: kernel healthz failed — may still be starting. Check log: $Log" -ForegroundColor Yellow
}

# --- Router (full 3-way peer; idempotent) ---------------------------------
if (Get-Process -Name moos-router -ErrorAction SilentlyContinue) {
    Write-Host "Router already running — skipping." -ForegroundColor Gray
} else {
    Write-Host "Starting moos router (ProDesk, peers: hp-laptop + Z440)..." -ForegroundColor Cyan
    $RouterArgs = "--listen :9000 --shard $Shard --default $LocalKernel --peer $PeerLaptop --peer $PeerZ440"
    Start-Process -FilePath $RouterExe -ArgumentList $RouterArgs -WindowStyle Normal
    Start-Sleep -Seconds 2
}

try {
    $r = Invoke-RestMethod "http://localhost:9000/healthz" -TimeoutSec 8
    $msg = "Router: {0} [fans in {1} kernel(s) now; peers resolve once hp-laptop/Z440 routers restart]" -f $r.status, $r.kernels.Count
    Write-Host $msg -ForegroundColor Green
} catch {
    Write-Host "WARNING: router healthz failed — may still be starting." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "ProDesk federation up. Kernel :8000 | MCP http://localhost:8080/sse | Router :9000" -ForegroundColor Green
Write-Host "Verify the full mesh after Z440 + hp-laptop routers restart:" -ForegroundColor Gray
Write-Host "  dev\scripts\ops\Test-MoosFederation.ps1 -Mode Doctor" -ForegroundColor Gray
