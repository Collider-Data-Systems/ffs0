# Watch-Moos.ps1 - live monitor for the HP ProDesk mo:os kernel + router.
# The kernel/router run hidden (no console of their own); this is a read-only
# view. CLOSING THIS WINDOW DOES NOT STOP THEM. Ctrl+C to stop watching.
#   powershell -ExecutionPolicy Bypass -File $env:USERPROFILE\CDS\ffs0\dev\scripts\ops\Watch-Moos.ps1
# ProDesk-specific (sovereign log, kernel/router on :8000/:9000). Auto-opened at
# logon via a Startup shortcut (T=227).
param(
    [int]$IntervalSeconds = 5,
    [int]$LogLines = 8
)
$ErrorActionPreference = 'Continue'
$KernelLog = "$env:USERPROFILE\CDS\moos-kernel\moos.hpprodesk.jsonl"

function Show-Once {
    Clear-Host
    Write-Host ("=== mo:os ProDesk monitor ===  {0}  (refresh {1}s) ===" -f (Get-Date -Format 'HH:mm:ss'), $IntervalSeconds) -ForegroundColor Cyan

    $k = Get-Process moos-kernel -ErrorAction SilentlyContinue
    $r = Get-Process moos-router -ErrorAction SilentlyContinue
    $kp = if ($k) { "pid {0}, {1} MB" -f $k.Id, [math]::Round($k.WorkingSet/1MB) } else { 'NOT RUNNING' }
    $rp = if ($r) { "pid {0}, {1} MB" -f $r.Id, [math]::Round($r.WorkingSet/1MB) } else { 'NOT RUNNING' }
    Write-Host ("  kernel proc : {0}" -f $kp)
    Write-Host ("  router proc : {0}" -f $rp)

    try {
        $h = Invoke-RestMethod http://localhost:8000/healthz -TimeoutSec 4
        Write-Host ("  kernel :8000: {0}  ontology {1}  t_day {2}  log_len {3}" -f $h.status, $h.ontology_version, $h.t_day, $h.log_len) -ForegroundColor Green
    } catch { Write-Host "  kernel :8000: DOWN" -ForegroundColor Red }

    try {
        $rr = Invoke-RestMethod http://localhost:9000/healthz -TimeoutSec 6
        Write-Host ("  router :9000: {0}  fans in {1} kernel(s)" -f $rr.status, $rr.kernels.Count) -ForegroundColor Green
        foreach ($kn in $rr.kernels) { Write-Host ("      - {0}  {1}  log_len={2}" -f $kn.url, $kn.status, $kn.log_len) -ForegroundColor DarkGray }
    } catch { Write-Host "  router :9000: DOWN" -ForegroundColor Red }

    Write-Host ("  --- kernel HG log tail (last {0}) ---" -f $LogLines) -ForegroundColor Gray
    try {
        $tail = Get-Content $KernelLog -Tail $LogLines -ErrorAction Stop
        foreach ($ln in $tail) {
            try {
                $o = $ln | ConvertFrom-Json
                $e = $o.envelope
                $id = $e.node_urn; if (-not $id) { $id = $e.relation_urn }
                $t = $e.type_id;   if (-not $t)  { $t = $e.rewrite_category }
                Write-Host ("    {0,3}  {1,-6} {2,-14} {3}" -f $o.log_seq, $e.rewrite_type, $t, $id)
            } catch { Write-Host "    (unparsed) $ln" -ForegroundColor DarkGray }
        }
    } catch { Write-Host ("    (log unavailable: {0})" -f $_.Exception.Message) -ForegroundColor DarkGray }

    Write-Host ""
    Write-Host "Closing this window does NOT stop the kernel/router. Ctrl+C to stop watching." -ForegroundColor DarkYellow
}

while ($true) {
    Show-Once
    Start-Sleep -Seconds $IntervalSeconds
}
