# start_federation_laptop.ps1
# Run this on hp-laptop after every restart to bring the local kernel up.
# Secondaries (menno/lola/moos) live on Z440 — no secondary kernels on laptop.

$ErrorActionPreference = "Stop"

$KernelExe   = "$env:USERPROFILE\HPLaptop\moos-kernel\moos-kernel.exe"
$Ontology    = "$env:USERPROFILE\HPLaptop\ffs0\kb\superset\ontology.json"
$Log         = "$env:USERPROFILE\HPLaptop\moos-kernel\moos.jsonl"  # sovereign log — NOT $env:TEMP (would start fresh)

Write-Host "Starting moos primary kernel (laptop)..." -ForegroundColor Cyan

Start-Process -FilePath $KernelExe `
    -ArgumentList "--ontology `"$Ontology`" --log `"$Log`" --listen :8000 --mcp-addr :8080 --seed --seed-user sam --seed-ws hp-laptop" `
    -WindowStyle Normal

Start-Sleep -Seconds 2

try {
    $h = Invoke-RestMethod http://localhost:8000/healthz -TimeoutSec 5
    Write-Host "Primary kernel: $($h.status)" -ForegroundColor Green
} catch {
    Write-Host "WARNING: healthz check failed — kernel may still be starting. Check log: $Log" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Laptop kernel up. MCP: http://localhost:8080/sse" -ForegroundColor Green
Write-Host "Secondaries (menno/lola/moos) are on Z440 (192.168.1.15) — no action needed." -ForegroundColor Gray
Write-Host ""
Write-Host "VS Code: refresh MCP servers in Chat Customizations." -ForegroundColor Cyan
