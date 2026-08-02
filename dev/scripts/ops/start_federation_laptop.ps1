# start_federation_laptop.ps1
# Bring the hp-laptop local federation up (manual / reference).
# hp-laptop is a single-primary box — no menno/lola/moos twins (those live on Z440).
# One primary kernel (:8000 + MCP :8080) + one router (:9000).
#
# Idempotent: safe to run while already up (guards skip a live kernel/router).
# To pick up a topology change on a live router, no restart needed:
#   Invoke-RestMethod -Method Post http://localhost:9000/admin/topology/reload
# For a binary swap use redeploy_laptop_kernel.ps1.
#
# Router shape (T=251, ffs0#154): UNIFORM topology-file launch. The routing
# table (kernel shards, ws aliases, default rule, peers) comes from
# dev/config/moos-federation.topology.json (routers.hp-laptop entry), loaded at
# boot. --default is only the bootstrap fallback if the file fails to load.
# Requires the moos-router build with boot-load support (feat/topology-file-sot
# or later) — rebuild the binary before relaunching with this script. Router 5s
# timeout fallback makes peering an offline box non-fatal.
#
# Emit discipline: HG rewrites target THIS box's :8000 only — never cross-emit the
# laptop seats to Z440/ProDesk.

$ErrorActionPreference = "Stop"

# Normalize hostname so Test-MoosFederation.ps1 resolves this box as the laptop seat
$env:MOOS_LOCAL_HOST = 'hp-laptop'

# --- Paths ($env:USERPROFILE = C:\Users\maass) ----------------------------
$KernelExe    = "$env:USERPROFILE\HPlaptop\moos-kernel\moos-kernel.exe"
$RouterExe    = "$env:USERPROFILE\HPlaptop\moos-router\moos-router.exe"
$TopologyFile = "$env:USERPROFILE\HPlaptop\ffs0\dev\config\moos-federation.topology.json"
$Ontology     = "$env:USERPROFILE\HPlaptop\ffs0\kb\superset\ontology.json"
$Log          = "$env:USERPROFILE\HPlaptop\moos-kernel\moos.jsonl"  # sovereign log — NOT $env:TEMP (would start fresh)

$LocalKernel = "http://localhost:8000"

# Bearer auth (moos-kernel #60): pass the token file only when it is a real,
# non-empty leaf file - the kernel exits FATAL on a missing/empty/dir path
# (Copilot catch on #167), and unset means open+WARNING, so anything less than
# a usable token degrades to the pre-#60 posture instead of a dead boot.
$AuthTokenFile = "$env:USERPROFILE\HPlaptop\ffs0\secrets\moos-auth-token"
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

# --- Primary kernel (idempotent) ------------------------------------------
if (Get-Process -Name moos-kernel -ErrorAction SilentlyContinue) {
    Write-Host "Primary kernel already running — skipping." -ForegroundColor Gray
} else {
    Write-Host "Starting moos primary kernel (laptop)..." -ForegroundColor Cyan
    # --kernel-urn (moos-kernel#69 / A6): explicit self-identity for /healthz +
    # /log/integrity. The laptop fold holds several peers' kernel nodes, so the
    # kernel cannot derive "which one is me" from the fold alone; without the
    # flag it honestly omits the field rather than guessing. Identity only —
    # never an actor. Probed rather than assumed: Go's flag package FAILS FAST
    # on unknown flags, so passing this to a pre-#69 binary would kill the
    # kernel at boot (e.g. an autostart after reboot, before a redeploy) —
    # the same defensive shape as the auth-token check above.
    # Probe details (Copilot catches on #191): match the raw line ARRAY, not
    # Out-String — Out-String width-wraps long help text and a wrapped flag
    # name would false-negative; Go flag help always leads each flag with its
    # own line, and -match over an array tests per line. And a probe FAILURE
    # must be as visible as a probe miss — both degrade to flag-off, loudly.
    # ...and (t275 live catch): Go's --help EXITS 2 with usage on stderr; under
    # this script's $ErrorActionPreference='Stop', redirected native stderr
    # becomes throwing error records — the probe itself threw and skipped the
    # flag on a perfectly good binary. Relax EAP around the probe only, and
    # stringify the stream so it's lines, not error records.
    $KernelUrnArgs = ""
    $prevEAP = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $kernelHelp = (& $KernelExe --help 2>&1 | ForEach-Object { "$_" })
        # Copilot catch (#198): with EAP relaxed, a GENUINE failure (access
        # denied, bad image, missing dependency) would stringify into
        # $kernelHelp, match nothing, and fall into the benign "predates"
        # NOTE. Gate on exit code first: Go exits 0 or (for --help) 2; anything
        # else is a failed probe, not an old binary — warn, flag off.
        if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 2) {
            $firstLine = if ($kernelHelp) { @($kernelHelp)[0] } else { '<no output>' }
            Write-Host "WARNING: --kernel-urn probe failed (exit $LASTEXITCODE: $firstLine) - starting without the flag (kernel_urn omitted from reports)." -ForegroundColor Yellow
        } elseif ($kernelHelp -match 'kernel-urn') {
            $KernelUrnArgs = " --kernel-urn urn:moos:kernel:hp-laptop.primary"
        } else {
            Write-Host "NOTE: binary predates moos-kernel#69 - starting without --kernel-urn (kernel_urn omitted from reports until redeploy)." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "WARNING: --kernel-urn probe failed ($($_.Exception.Message)) - starting without the flag (kernel_urn omitted from reports)." -ForegroundColor Yellow
    } finally {
        $ErrorActionPreference = $prevEAP
    }
    Start-Process -FilePath $KernelExe `
        -ArgumentList "--ontology `"$Ontology`" --log `"$Log`" --listen :8000 --mcp-addr :8080 --seed --seed-user sam --seed-ws hp-laptop$KernelUrnArgs$AuthArgs" `
        -WindowStyle Hidden
    Start-Sleep -Seconds 2
}

try {
    $h = Invoke-RestMethod "$LocalKernel/healthz" -TimeoutSec 5
    Write-Host ("Primary kernel: {0} [ontology {1}, t_day {2}, log_len {3}]" -f $h.status, $h.ontology_version, $h.t_day, $h.log_len) -ForegroundColor Green
} catch {
    Write-Host "WARNING: kernel healthz failed — may still be starting. Check log: $Log" -ForegroundColor Yellow
}

# --- Router (idempotent; topology-file SOT) --------------------------------
$RouterArgs = @(
    '--listen', ':9000',
    '--default', $LocalKernel,
    '--topology-file', $TopologyFile,
    '--local-host', 'hp-laptop'
)

if (Get-Process -Name moos-router -ErrorAction SilentlyContinue) {
    Write-Host "Router already running — skipping (POST /admin/topology/reload to pick up topology changes)." -ForegroundColor Gray
} else {
    Write-Host "Starting moos router (laptop; topology from $TopologyFile)..." -ForegroundColor Cyan
    Start-Process -FilePath $RouterExe -ArgumentList $RouterArgs -WindowStyle Hidden
    Start-Sleep -Seconds 2
}

try {
    $r = Invoke-RestMethod "http://localhost:9000/healthz" -TimeoutSec 8
    Write-Host ("Router: {0} [fans in {1} kernel(s)]" -f $r.status, $r.kernels.Count) -ForegroundColor Green
    if ($r.kernels.Count -lt 6) {
        Write-Host "WARNING: fan-in below 6 — topology file may not have loaded (old binary?). Check GET http://localhost:9000/admin/topology" -ForegroundColor Yellow
    }
} catch {
    Write-Host "WARNING: router healthz failed — may still be starting." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Laptop federation up. Kernel :8000 | MCP http://localhost:8080/sse | Router :9000" -ForegroundColor Green
Write-Host "Secondaries (menno/lola/moos) are on Z440 — no action needed here." -ForegroundColor Gray
Write-Host "Verify full mesh: dev\scripts\ops\Test-MoosFederation.ps1 -Mode Doctor" -ForegroundColor Gray
