# redeploy_hpprodesk_kernel.ps1
# Rebuild the HP ProDesk primary engine (kernel) from the current moos-kernel
# checkout and hot-swap it under the running process, preserving the sovereign log.
#
# WHEN TO USE: merged moos-kernel PRs whose behavior is BINARY-level need this to
# reach the ProDesk fold — e.g. A18 perf pair (#70), A6 log-integrity (#69).
# Ontology-only bumps do NOT need a rebuild — a plain restart via
# start_federation_hpprodesk.ps1 reloads ontology.json. This script is for BINARY
# parity; start_federation_hpprodesk.ps1 is the pure bring-up.
#
# INVARIANTS honored (same as redeploy_laptop_kernel.ps1, first proven T=250):
#   - sovereign log preserved: --log points at moos.hpprodesk.jsonl (restart
#     replays it; zero loss). Take a log copy before running for belt+braces.
#   - reversible: the pre-swap binary is kept as moos-kernel.exe.bak-<stamp>.
#   - verifies /healthz after: reports ontology_version + log_len, warns if
#     log_len drifts (ProDesk baseline: 29, cf. Check-MoosOnline.ps1).
#
# First used T=278 (ProDesk-boot bundle: 4.0.4/26fbf0f build -> 4.0.5/afe140c,
# picking up A18 + A6 + the launcher's probed --kernel-urn).

param(
  [switch]$SkipBuild,   # swap an already-present moos-kernel.new.exe instead of building
  [switch]$NoRestart    # build + swap only; leave the kernel down (manual restart later)
)

$ErrorActionPreference = 'Stop'
$KernelDir = "$env:USERPROFILE\CDS\moos-kernel"
$Exe       = "$KernelDir\moos-kernel.exe"
$NewExe    = "$KernelDir\moos-kernel.new.exe"
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
try { $pre = Invoke-RestMethod http://localhost:8000/healthz -TimeoutSec 5; Write-Host "  ontology=$($pre.ontology_version) log_len=$($pre.log_len) status=$($pre.status)" }
catch { Write-Host "  (kernel not responding - first-time bring-up is fine)" -ForegroundColor Yellow; $pre = $null }

if (-not $SkipBuild) {
  $go = Resolve-Go
  Write-Host "== go build ./cmd/moos ($go) ==" -ForegroundColor Cyan
  Push-Location $KernelDir
  try { & $go build -o moos-kernel.new.exe ./cmd/moos; if ($LASTEXITCODE -ne 0) { throw "go build failed (exit $LASTEXITCODE)" } }
  finally { Pop-Location }
  Write-Host "  built moos-kernel.new.exe"
}
if (-not (Test-Path $NewExe)) { throw "no moos-kernel.new.exe to swap (build skipped and none present)" }

Write-Host "== stop running :8000 kernel ==" -ForegroundColor Cyan
# S4U-launched processes hide CommandLine from unelevated CIM; ProDesk runs a
# single kernel, so match by name and fall back loudly if that assumption breaks.
$p = @(Get-Process -Name moos-kernel -ErrorAction SilentlyContinue)
if ($p.Count -gt 1) { throw "expected at most one moos-kernel.exe on ProDesk, found $($p.Count) - resolve manually" }
$stopped = $true
if ($p) {
  try { Write-Host "  stopping PID $($p[0].Id)"; Stop-Process -Id $p[0].Id -Force -ErrorAction Stop; Start-Sleep -Seconds 3 }
  catch {
    # The kernel usually runs under the `moos-prodesk` task's S4U principal;
    # an unelevated shell gets PROCESS_TERMINATE denied. Route the whole
    # stop -> backup -> swap through the task itself: the launcher's
    # marker-gated redeploy leg (T=278) runs in the task's own context.
    $stopped = $false
    Write-Host "  direct stop denied ($($_.Exception.Message.Trim())) - routing swap through the moos-prodesk task" -ForegroundColor Yellow
  }
} else { Write-Host "  none running" }

if (-not $stopped) {
  if ($NoRestart) { throw "-NoRestart is incompatible with the task-routed swap (the task always relaunches)" }
  $flag   = "$KernelDir\redeploy-request.flag"
  $result = "$KernelDir\redeploy-result.txt"
  if (Test-Path $result) { Remove-Item $result -Force }
  "requested $stamp" | Out-File $flag -Encoding utf8
  Start-ScheduledTask -TaskName 'moos-prodesk'
  Write-Host "== task fired; waiting for the redeploy leg ==" -ForegroundColor Cyan
  for ($i = 0; $i -lt 15; $i++) {
    Start-Sleep -Seconds 2
    if ((Test-Path $result) -and -not (Test-Path $flag)) { break }
  }
  if (Test-Path $result) { Get-Content $result | ForEach-Object { "  $_" } }
  else { Write-Host "!! no redeploy-result.txt after 30s - inspect the task and $KernelDir manually" -ForegroundColor Red }
} else {
  Write-Host "== backup + swap ==" -ForegroundColor Cyan
  if (Test-Path $Exe) { Move-Item $Exe "$Exe.bak-$stamp" -Force; Write-Host "  backup: moos-kernel.exe.bak-$stamp" }
  Move-Item $NewExe $Exe -Force
  Write-Host "  live binary LastWriteTime: $((Get-Item $Exe).LastWriteTime)"

  if ($NoRestart) { Write-Host "-NoRestart set: binary swapped, kernel left down. Run start_federation_hpprodesk.ps1 to bring up." -ForegroundColor Yellow; return }

  Write-Host "== relaunch (start_federation_hpprodesk.ps1) ==" -ForegroundColor Cyan
  & $Launch
}

Write-Host "== verify /healthz ==" -ForegroundColor Cyan
$ok = $false
for ($i = 0; $i -lt 12; $i++) {
  Start-Sleep -Seconds 2
  try {
    $post = Invoke-RestMethod http://localhost:8000/healthz -TimeoutSec 5
    Write-Host "  ontology=$($post.ontology_version) log_len=$($post.log_len) status=$($post.status)" -ForegroundColor Green
    if ($pre -and ($post.log_len -ne $pre.log_len)) { Write-Host "  WARN: log_len changed $($pre.log_len) -> $($post.log_len) (expected preserved)" -ForegroundColor Yellow }
    $ok = $true; break
  } catch { Write-Host "  waiting... ($i)" }
}
if (-not $ok) { Write-Host "!! kernel did not answer /healthz within timeout - check $KernelDir\moos.hpprodesk.jsonl" -ForegroundColor Red }
