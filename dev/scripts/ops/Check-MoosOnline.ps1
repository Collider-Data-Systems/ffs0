# Check-MoosOnline.ps1 - one-shot "are we online?" check for HP ProDesk.
# Run after logging back in (the moos-prodesk task starts the federation at logon).
# Baseline: kernel/router log_len>=29, ontology 3.16.2, t_day 227.
#   powershell -ExecutionPolicy Bypass -File $env:USERPROFILE\CDS\ffs0\dev\scripts\ops\Check-MoosOnline.ps1

$ok = $true
function Line($name, $good, $detail) {
    $tag = if ($good) { 'OK  ' } else { 'FAIL' }
    $color = if ($good) { 'Green' } else { 'Red' }
    Write-Host ("  {0}  {1,-22} {2}" -f $tag, $name, $detail) -ForegroundColor $color
    if (-not $good) { $script:ok = $false }
}

Write-Host "=== HP ProDesk online check ===" -ForegroundColor Cyan

# Tailscale (service - up independent of login)
$ip = (& tailscale ip -4 2>$null | Select-Object -First 1)
Line 'tailscale' ($ip -eq '100.87.28.95') "ip=$ip"

# Autostart task fired? (processes present)
$k = Get-Process moos-kernel -ErrorAction SilentlyContinue
$r = Get-Process moos-router -ErrorAction SilentlyContinue
Line 'kernel process' ($null -ne $k) ($(if ($k) { "pid $($k.Id)" } else { 'not running - did you log in? task moos-prodesk runs at logon' }))
Line 'router process' ($null -ne $r) ($(if ($r) { "pid $($r.Id)" } else { 'not running' }))

# Local kernel health + log persistence
try {
    $h = Invoke-RestMethod http://localhost:8000/healthz -TimeoutSec 6
    Line 'kernel :8000' ($h.status -eq 'ok') ("status=$($h.status) ontology=$($h.ontology_version) t_day=$($h.t_day) log_len=$($h.log_len)")
    Line 'HG log persisted' ([int]$h.log_len -ge 29) ("log_len=$($h.log_len) (baseline 29 - lower means the sovereign log reset)")
} catch { Line 'kernel :8000' $false $_.Exception.Message }

# Local router health
try {
    $rr = Invoke-RestMethod http://localhost:9000/healthz -TimeoutSec 8
    Line 'router :9000' ($rr.status -eq 'ok') ("fans in $($rr.kernels.Count) kernel(s)")
} catch { Line 'router :9000' $false $_.Exception.Message }

# Peers reachable over Tailscale (informational - depends on THEM being up)
foreach ($p in @(@{n='hp-laptop'; ip='100.106.220.58'}, @{n='Z440'; ip='100.82.243.13'})) {
    try { $ph = Invoke-RestMethod "http://$($p.ip):8000/healthz" -TimeoutSec 4; Write-Host ("  peer $($p.n) ($($p.ip)): kernel $($ph.status)") -ForegroundColor Gray }
    catch { Write-Host ("  peer $($p.n) ($($p.ip)): unreachable (may be offline)") -ForegroundColor DarkGray }
}

Write-Host ""
if ($ok) { Write-Host "RESULT: ONLINE - ProDesk federation survived the reboot." -ForegroundColor Green }
else     { Write-Host "RESULT: NOT FULLY ONLINE - if processes are missing, confirm you logged in (logon-triggered task); else run dev\scripts\ops\start_federation_hpprodesk.ps1" -ForegroundColor Yellow }
