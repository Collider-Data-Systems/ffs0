# start_federation_hpprodesk.ps1
# Bring the HP ProDesk local federation up (manual / reference).
# ProDesk is its own single-seat box (session:sam.hpprodesk-setup): one primary
# kernel + one router. No menno/lola/moos twins here (those live on Z440).
#
# Persistence: this IS the autostart single source of truth - the `moos-prodesk`
# scheduled task (logon trigger) runs THIS tracked script (repointed T=227 from
# the former local C:\Users\Geurt\CDS\start-moos.ps1, now superseded). Kernel and
# router launch hidden (no console); use Watch-Moos.ps1 / Check-MoosOnline.ps1 to
# observe. Idempotent guards make it safe to run manually while already up.
#
# Router shape (T=251, ffs0#154): UNIFORM topology-file launch. The routing
# table (kernel shards, default rule, FULL 3-WAY PEER per Sam's #64 call) comes
# from dev/config/moos-federation.topology.json (routers.hpprodesk entry),
# loaded at boot; hot-reload via POST http://localhost:9000/admin/topology/reload.
# --default is only the bootstrap fallback if the file fails to load. Requires
# the moos-router build with boot-load support (feat/topology-file-sot or
# later) — rebuild the binary before relaunching with this script. The 5s
# router timeout fallback makes peering to an offline box non-fatal.
#
# Emit discipline: HG rewrites target THIS box's :8000 only - never cross-emit
# the ProDesk seat to laptop/Z440.

$ErrorActionPreference = "Stop"

# Normalize hostname so Test-MoosFederation.ps1 resolves this box as the ProDesk seat
$env:MOOS_LOCAL_HOST = 'hpprodesk'

# --- Paths (ProDesk: $env:USERPROFILE = C:\Users\Geurt) -------------------
$Base         = "$env:USERPROFILE\CDS"
$KernelExe    = "$Base\moos-kernel\moos-kernel.exe"
$RouterExe    = "$Base\moos-router\moos-router.exe"
$TopologyFile = "$Base\ffs0\dev\config\moos-federation.topology.json"
$Ontology     = "$Base\ffs0\kb\superset\ontology.json"
$Log          = "$Base\moos-kernel\moos.hpprodesk.jsonl"  # sovereign log - NOT $env:TEMP (would start fresh)

$LocalKernel = "http://localhost:8000"

# --- Kernel (idempotent: skip if already running) -------------------------
if (Get-Process -Name moos-kernel -ErrorAction SilentlyContinue) {
    Write-Host "Primary kernel already running - skipping." -ForegroundColor Gray
} else {
    Write-Host "Starting moos primary kernel (ProDesk)..." -ForegroundColor Cyan
    Start-Process -FilePath $KernelExe `
        -ArgumentList "--ontology `"$Ontology`" --log `"$Log`" --listen :8000 --mcp-addr :8080 --seed --seed-user sam --seed-ws hpprodesk" `
        -WindowStyle Hidden
    Start-Sleep -Seconds 2
}

try {
    $h = Invoke-RestMethod "$LocalKernel/healthz" -TimeoutSec 5
    $msg = "Primary kernel: {0} [ontology {1}, t_day {2}, log_len {3}]" -f $h.status, $h.ontology_version, $h.t_day, $h.log_len
    Write-Host $msg -ForegroundColor Green
} catch {
    Write-Host "WARNING: kernel healthz failed - may still be starting. Check log: $Log" -ForegroundColor Yellow
}

# --- Router (idempotent; topology-file SOT) --------------------------------
if (Get-Process -Name moos-router -ErrorAction SilentlyContinue) {
    Write-Host "Router already running - skipping (POST /admin/topology/reload to pick up topology changes)." -ForegroundColor Gray
} else {
    Write-Host "Starting moos router (ProDesk; topology from $TopologyFile)..." -ForegroundColor Cyan
    $RouterArgs = @(
        '--listen', ':9000',
        '--default', $LocalKernel,
        '--topology-file', $TopologyFile,
        '--local-host', 'hpprodesk'
    )
    Start-Process -FilePath $RouterExe -ArgumentList $RouterArgs -WindowStyle Hidden
    Start-Sleep -Seconds 2
}

try {
    $r = Invoke-RestMethod "http://localhost:9000/healthz" -TimeoutSec 8
    $msg = "Router: {0} [fans in {1} kernel(s)]" -f $r.status, $r.kernels.Count
    Write-Host $msg -ForegroundColor Green
    if ($r.kernels.Count -lt 6) {
        Write-Host "WARNING: fan-in below 6 - topology file may not have loaded (old binary?). Check GET http://localhost:9000/admin/topology" -ForegroundColor Yellow
    }
} catch {
    Write-Host "WARNING: router healthz failed - may still be starting." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "ProDesk federation up. Kernel :8000 | MCP http://localhost:8080/sse | Router :9000" -ForegroundColor Green
Write-Host "Verify the full mesh after Z440 + hp-laptop routers restart:" -ForegroundColor Gray
Write-Host "  dev\scripts\ops\Test-MoosFederation.ps1 -Mode Doctor" -ForegroundColor Gray
