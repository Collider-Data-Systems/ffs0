# start_federation_hpprodesk.ps1
# Run this on the HP ProDesk after every restart to bring the local federation up.
# ProDesk is its own single-seat box (session:sam.hpprodesk-setup): one primary
# kernel + one router. No menno/lola/moos twins here (those live on Z440).
#
# Persists the T=226 rejoin invocation (ffs0#62/#63/#64) so a reboot keeps the
# full 3-way mesh. Router shape = FULL 3-WAY PEER (Sam's #64 call): ProDesk peers
# out to hp-laptop + Z440, matching routers.hpprodesk.peers in
# dev/config/moos-federation.topology.json. The 5s router timeout fallback makes
# peering to an offline box non-fatal (it fast-fails), so this is safe to run
# even before the always-on boxes restart.
#
# Emit discipline: HG rewrites target THIS box's :8000 only — never cross-emit
# the ProDesk seat to laptop/Z440.

$ErrorActionPreference = "Stop"

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

# --- Kernel ---------------------------------------------------------------
Write-Host "Starting moos primary kernel (ProDesk)..." -ForegroundColor Cyan
Start-Process -FilePath $KernelExe `
    -ArgumentList "--ontology `"$Ontology`" --log `"$Log`" --listen :8000 --mcp-addr :8080 --seed --seed-user sam --seed-ws hpprodesk" `
    -WindowStyle Normal

Start-Sleep -Seconds 2
try {
    $h = Invoke-RestMethod "$LocalKernel/healthz" -TimeoutSec 5
    $msg = "Primary kernel: {0} [ontology {1}, t_day {2}, log_len {3}]" -f $h.status, $h.ontology_version, $h.t_day, $h.log_len
    Write-Host $msg -ForegroundColor Green
} catch {
    Write-Host "WARNING: kernel healthz failed — may still be starting. Check log: $Log" -ForegroundColor Yellow
}

# --- Router (full 3-way peer) ---------------------------------------------
Write-Host "Starting moos router (ProDesk, peers: hp-laptop + Z440)..." -ForegroundColor Cyan
$RouterArgs = "--listen :9000 --shard $Shard --default $LocalKernel --peer $PeerLaptop --peer $PeerZ440"
Start-Process -FilePath $RouterExe -ArgumentList $RouterArgs -WindowStyle Normal

Start-Sleep -Seconds 2
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
