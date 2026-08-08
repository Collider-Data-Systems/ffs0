# redeploy_hpprodesk_router.ps1
# Rebuild the HP ProDesk router from the current moos-router checkout and
# hot-swap it under the running process. Twin of redeploy_hpprodesk_kernel.ps1
# (T=278); router variant landed T=280 for the lane-C engine-stamp roll
# (moos-router#12: kernel_urn fan-in stamp).
#
# WHEN TO USE: merged moos-router PRs whose behavior is BINARY-level. Topology
# changes do NOT need this - the router hot-reloads the file via
# POST /admin/topology/reload, and a plain restart through
# start_federation_hpprodesk.ps1 also re-reads it at boot.
#
# INVARIANTS:
#   - stateless swap: the router keeps no sovereign state; nothing to preserve.
#   - reversible: the pre-swap binary is kept as moos-router.exe.bak-<stamp>.
#   - verifies /healthz after: fan-in count + kernel_urn stamp coverage.
#
# S4U note (same class the kernel script measured T=278): the router usually
# runs under the `moos-prodesk` task's S4U principal - a direct stop from an
# unelevated shell is denied. On denial this script drops
# router-redeploy-request.flag and fires the task; the launcher's router leg
# (T=280) performs stop -> backup -> swap in the task's own context and
# reports via router-redeploy-result.txt.

param(
  [switch]$SkipBuild    # swap an already-present moos-router.new.exe instead of building
)

$ErrorActionPreference = 'Stop'
$RouterDir = "$env:USERPROFILE\CDS\moos-router"
$Exe       = "$RouterDir\moos-router.exe"
$NewExe    = "$RouterDir\moos-router.new.exe"
$Launch    = "$env:USERPROFILE\CDS\ffs0\dev\scripts\ops\start_federation_hpprodesk.ps1"
$stamp     = Get-Date -Format 'yyyyMMdd-HHmmss'

function Resolve-Go {
  $g = Get-Command go -ErrorAction SilentlyContinue
  if ($g) { return $g.Source }
  $fallback = 'C:\Program Files\Go\bin\go.exe'
  if (Test-Path $fallback) { return $fallback }
  throw "go toolchain not found on PATH or at $fallback"
}

Write-Host "== pre-swap ==" -ForegroundColor Cyan
try { $pre = Invoke-RestMethod http://localhost:9000/healthz -TimeoutSec 8; Write-Host "  status=$($pre.status) fan-in=$($pre.kernels.Count)" }
catch { Write-Host "  (router not responding - first-time bring-up is fine)" -ForegroundColor Yellow; $pre = $null }

if (-not $SkipBuild) {
  $go = Resolve-Go
  Write-Host "== go build ./cmd/router ($go) ==" -ForegroundColor Cyan
  Push-Location $RouterDir
  try { & $go build -o moos-router.new.exe ./cmd/router; if ($LASTEXITCODE -ne 0) { throw "go build failed (exit $LASTEXITCODE)" } }
  finally { Pop-Location }
  Write-Host "  built moos-router.new.exe"
}
if (-not (Test-Path $NewExe)) { throw "no moos-router.new.exe to swap (build skipped and none present)" }

Write-Host "== stop running :9000 router ==" -ForegroundColor Cyan
# S4U-launched processes hide CommandLine from unelevated CIM; ProDesk runs a
# single router, so match by name and fall back loudly if that assumption breaks.
$p = @(Get-Process -Name moos-router -ErrorAction SilentlyContinue)
if ($p.Count -gt 1) { throw "expected at most one moos-router.exe on ProDesk, found $($p.Count) - resolve manually" }
$stopped = $true
if ($p) {
  try { Write-Host "  stopping PID $($p[0].Id)"; Stop-Process -Id $p[0].Id -Force -ErrorAction Stop; Start-Sleep -Seconds 3 }
  catch {
    $stopped = $false
    Write-Host "  direct stop denied ($($_.Exception.Message.Trim())) - routing swap through the moos-prodesk task" -ForegroundColor Yellow
  }
} else { Write-Host "  none running" }

if (-not $stopped) {
  $flag   = "$RouterDir\router-redeploy-request.flag"
  $result = "$RouterDir\router-redeploy-result.txt"
  if (Test-Path $result) { Remove-Item $result -Force }
  # Wait for any running task instance first: the task is MultipleInstances =
  # IgnoreNew, so Start-ScheduledTask against a Running instance is SILENTLY
  # dropped and the armed flag would sit until the next boot (T=280 review).
  $idleDeadline = (Get-Date).AddSeconds(60)
  while (((Get-ScheduledTask -TaskName 'moos-prodesk').State -eq 'Running') -and ((Get-Date) -lt $idleDeadline)) { Start-Sleep -Seconds 1 }
  if ((Get-ScheduledTask -TaskName 'moos-prodesk').State -eq 'Running') {
    throw "moos-prodesk task still Running after 60s - fire would be silently ignored (IgnoreNew); retry later"
  }
  "requested $stamp" | Out-File $flag -Encoding utf8
  Start-ScheduledTask -TaskName 'moos-prodesk'
  Write-Host "== task fired; waiting for the router redeploy leg ==" -ForegroundColor Cyan
  for ($i = 0; $i -lt 15; $i++) {
    Start-Sleep -Seconds 2
    if ((Test-Path $result) -and -not (Test-Path $flag)) { break }
  }
  if (Test-Path $result) { Get-Content $result | ForEach-Object { "  $_" } }
  else {
    # Do NOT fall through to verify: the old, never-stopped router would
    # answer healthz and green-light a deploy that never happened.
    if (Test-Path $flag) { Remove-Item $flag -Force; Write-Host "  flag disarmed (would fire a surprise swap at next boot)" -ForegroundColor Yellow }
    throw "no router-redeploy-result.txt after 30s - the task-routed swap did not report; inspect the task and $RouterDir"
  }
} else {
  Write-Host "== backup + swap ==" -ForegroundColor Cyan
  if (Test-Path $Exe) { Move-Item $Exe "$Exe.bak-$stamp" -Force; Write-Host "  backup: moos-router.exe.bak-$stamp" }
  Move-Item $NewExe $Exe -Force
  Write-Host "  live binary LastWriteTime: $((Get-Item $Exe).LastWriteTime)"

  Write-Host "== relaunch (start_federation_hpprodesk.ps1) ==" -ForegroundColor Cyan
  & $Launch
}

Write-Host "== verify /healthz ==" -ForegroundColor Cyan
$ok = $false
for ($i = 0; $i -lt 12; $i++) {
  Start-Sleep -Seconds 2
  try {
    $post = Invoke-RestMethod http://localhost:9000/healthz -TimeoutSec 8
    $stamped = @($post.kernels | Where-Object { $_.kernel_urn }).Count
    Write-Host "  status=$($post.status) fan-in=$($post.kernels.Count) kernel_urn-stamped rows=$stamped/$($post.kernels.Count)" -ForegroundColor Green
    $ok = $true; break
  } catch { Write-Host "  waiting... ($i)" }
}
if (-not $ok) { throw "router did not answer /healthz within timeout - check the task and $RouterDir" }
# On this fleet every kernel self-identifies (A6 landed fleet-wide), so zero
# stamped rows after a swap means the running binary is NOT the stamped build.
if ($stamped -eq 0) { throw "0 fan-in rows carry kernel_urn - the running router is not the lane-C stamped build" }
