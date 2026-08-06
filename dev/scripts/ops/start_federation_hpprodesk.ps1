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

# Bearer auth (moos-kernel #60): pass the token file only when it is a real,
# non-empty leaf file - the kernel exits FATAL on a missing/empty/dir path
# (Copilot catch on #167), and unset means open+WARNING, so anything less than
# a usable token degrades to the pre-#60 posture instead of a dead boot.
$AuthTokenFile = "$Base\ffs0\secrets\moos-auth-token"
$AuthArgs = ""
$AuthTokenUsable = $false
if (Test-Path $AuthTokenFile -PathType Leaf) {
    try { $AuthTokenUsable = ([IO.File]::ReadAllText($AuthTokenFile).Trim().Length -gt 0) } catch {}
}
if ($AuthTokenUsable) {
    $AuthArgs = " --auth-token-file `"$AuthTokenFile`""
} else {
    Write-Host "WARNING: $AuthTokenFile missing or empty - kernel starts UNAUTHENTICATED (write routes open)." -ForegroundColor Yellow
}

# --- Redeploy leg (T=278, marker-gated) -----------------------------------
# ProDesk runs headless: the kernel is launched by the `moos-prodesk` task's
# S4U principal, and an unelevated interactive/harness shell CANNOT terminate
# that process (PROCESS_TERMINATE denied) or register new S4U tasks. It CAN,
# however, fire the existing task - so the swap rides THIS script, which runs
# in the task's own context. redeploy_hpprodesk_kernel.ps1 builds
# moos-kernel.new.exe, drops redeploy-request.flag, and fires the task; this
# leg performs stop -> backup -> swap, then falls through to normal bring-up.
# The marker is consumed unconditionally (no boot loops); progress goes to
# redeploy-result.txt because the task window is hidden.
$RedeployFlag   = "$Base\moos-kernel\redeploy-request.flag"
$RedeployNewExe = "$Base\moos-kernel\moos-kernel.new.exe"
$RedeployResult = "$Base\moos-kernel\redeploy-result.txt"
if (Test-Path $RedeployFlag) {
    $rlog = New-Object System.Collections.Generic.List[string]
    $rlog.Add("redeploy leg fired: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
    try {
        Remove-Item $RedeployFlag -Force
        if ((Test-Path $RedeployNewExe) -and ((Get-Item $RedeployNewExe).Length -gt 0)) {
            $running = Get-Process -Name moos-kernel -ErrorAction SilentlyContinue
            if ($running) {
                $rlog.Add("stopping kernel PID $($running.Id)")
                Stop-Process -Id $running.Id -Force
                Start-Sleep -Seconds 3
            }
            $rstamp = Get-Date -Format 'yyyyMMdd-HHmmss'
            if (Test-Path $KernelExe) {
                Move-Item $KernelExe "$KernelExe.bak-$rstamp" -Force
                $rlog.Add("backup: moos-kernel.exe.bak-$rstamp")
            }
            Move-Item $RedeployNewExe $KernelExe -Force
            $rlog.Add("swapped: new binary LastWriteTime $((Get-Item $KernelExe).LastWriteTime)")
        } else {
            $rlog.Add("SKIP: no usable moos-kernel.new.exe next to the flag - nothing swapped")
        }
    } catch {
        $rlog.Add("ERROR: $($_.Exception.Message)")
    }
    $rlog | Out-File $RedeployResult -Encoding utf8
}

# --- Kernel (idempotent: skip if already running) -------------------------
if (Get-Process -Name moos-kernel -ErrorAction SilentlyContinue) {
    Write-Host "Primary kernel already running - skipping." -ForegroundColor Gray
} else {
    Write-Host "Starting moos primary kernel (ProDesk)..." -ForegroundColor Cyan
    # --kernel-urn (moos-kernel#69 / A6): explicit self-identity for /healthz +
    # /log/integrity. Identity only - never an actor. Probed rather than
    # assumed: Go's flag package FAILS FAST on unknown flags, so passing this
    # to a pre-#69 binary would kill the kernel at boot (e.g. an autostart
    # after reboot, before a redeploy). Same probe as the laptop/Z440
    # launchers (#191/#197 + the t275 EAP catch + the #198 exit-code gate):
    # Go's --help EXITS 2 with usage on stderr; under $ErrorActionPreference
    # 'Stop', redirected native stderr becomes throwing error records - relax
    # EAP around the probe only and stringify the stream. Gate on exit code
    # first: 0 or 2 is a real answer; anything else is a failed probe, not an
    # old binary - warn, flag off.
    $KernelUrnArgs = ""
    $prevEAP = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $kernelHelp = (& $KernelExe --help 2>&1 | ForEach-Object { "$_" })
        if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 2) {
            $firstLine = if ($kernelHelp) { @($kernelHelp)[0] } else { '<no output>' }
            Write-Host "WARNING: --kernel-urn probe failed (exit ${LASTEXITCODE}: $firstLine) - starting without the flag (kernel_urn omitted from reports)." -ForegroundColor Yellow
        } elseif ($kernelHelp -match 'kernel-urn') {
            $KernelUrnArgs = " --kernel-urn urn:moos:kernel:hpprodesk.primary"
        } else {
            Write-Host "NOTE: binary predates moos-kernel#69 - starting without --kernel-urn (kernel_urn omitted from reports until redeploy)." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "WARNING: --kernel-urn probe failed ($($_.Exception.Message)) - starting without the flag (kernel_urn omitted from reports)." -ForegroundColor Yellow
    } finally {
        $ErrorActionPreference = $prevEAP
    }
    Start-Process -FilePath $KernelExe `
        -ArgumentList "--ontology `"$Ontology`" --log `"$Log`" --listen :8000 --mcp-addr :8080 --seed --seed-user sam --seed-ws hpprodesk$KernelUrnArgs$AuthArgs" `
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
