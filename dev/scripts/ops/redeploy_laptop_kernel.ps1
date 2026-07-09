# redeploy_laptop_kernel.ps1
# Rebuild the hp-laptop primary engine (kernel) from the current moos-kernel
# checkout and hot-swap it under the running process, preserving the sovereign log.
#
# WHEN TO USE: merged moos-kernel PRs whose behavior is BINARY-level need this to
# reach the laptop fold — e.g. the fail-closed §12.2 color gate (#51), CreatedAt
# determinism (#54), M6 event-governance (#56). Ontology-only bumps (e.g. 4.0.1->4.0.2,
# the F-b authority_scope reclassification #151) do NOT need a rebuild — a plain restart
# via start_federation_laptop.ps1 reloads ontology.json. This script is for BINARY parity;
# start_federation_laptop.ps1 is the pure bring-up.
#
# INVARIANTS honored:
#   - sovereign log preserved: --log points at moos.jsonl (restart replays it; zero loss).
#   - reversible: the pre-swap binary is kept as moos-kernel.exe.bak-<stamp>.
#   - verifies /healthz after: reports ontology_version + log_len, warns if log_len drifts.
#
# First proven T=250 (laptop 4.0.1->4.0.2 + Jul-7 permissive binary -> master 7a4981f;
# log preserved 1592/1592). Companion to start_federation_laptop.ps1 (bring-up only).

param(
  [switch]$SkipBuild,   # swap an already-present moos-kernel.new.exe instead of building
  [switch]$NoRestart    # build + swap only; leave the kernel down (manual restart later)
)

$ErrorActionPreference = 'Stop'
$KernelDir = "$env:USERPROFILE\HPlaptop\moos-kernel"
$Exe       = "$KernelDir\moos-kernel.exe"
$NewExe    = "$KernelDir\moos-kernel.new.exe"
$Launch    = "$env:USERPROFILE\HPlaptop\ffs0\dev\scripts\ops\start_federation_laptop.ps1"
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
catch { Write-Host "  (kernel not responding — first-time bring-up is fine)" -ForegroundColor Yellow; $pre = $null }

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
$p = Get-CimInstance Win32_Process -Filter "Name='moos-kernel.exe'" | Where-Object { $_.CommandLine -like '*--listen :8000*' }
if ($p) { Write-Host "  stopping PID $($p.ProcessId)"; Stop-Process -Id $p.ProcessId -Force; Start-Sleep -Seconds 3 } else { Write-Host "  none running on :8000" }

Write-Host "== backup + swap ==" -ForegroundColor Cyan
if (Test-Path $Exe) { Move-Item $Exe "$Exe.bak-$stamp" -Force; Write-Host "  backup: moos-kernel.exe.bak-$stamp" }
Move-Item $NewExe $Exe -Force
Write-Host "  live binary LastWriteTime: $((Get-Item $Exe).LastWriteTime)"

if ($NoRestart) { Write-Host "-NoRestart set: binary swapped, kernel left down. Run start_federation_laptop.ps1 to bring up." -ForegroundColor Yellow; return }

Write-Host "== relaunch (start_federation_laptop.ps1) ==" -ForegroundColor Cyan
& $Launch

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
if (-not $ok) { Write-Host "!! kernel did not answer /healthz within timeout — check $KernelDir\moos.jsonl" -ForegroundColor Red }
