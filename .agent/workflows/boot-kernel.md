---
description: Boot the mo:os kernel on HP laptop with KB hydration and verify health
---

# Boot Kernel (HP Laptop)

// turbo-all

## Steps

1. Check if kernel is already running:
```powershell
curl -s http://localhost:8000/healthz
```
If it returns `status: ok` — skip to step 5.

2. Clear stale process on port 8080 (MCP bridge):
```powershell
$p = Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess; if ($p) { Stop-Process -Id $p -Force; Write-Host "Killed $p on :8080" } else { Write-Host ":8080 free" }
```

3. Clear stale process on port 8000 (kernel HTTP):
```powershell
$p = Get-NetTCPConnection -LocalPort 8000 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess; if ($p) { Stop-Process -Id $p -Force; Write-Host "Killed $p on :8000" } else { Write-Host ":8000 free" }
```

4. Start the kernel in a dedicated PowerShell window (it blocks — keep the window open):
```powershell
# moos/ is a sibling of ffs0-factory-super/, both under FFS0_HPlaptop/
Push-Location "$env:USERPROFILE\FFS0_HPlaptop\moos\platform\kernel"
.\moos.exe --kb "$env:USERPROFILE\FFS0_HPlaptop\ffs0-factory-super\.agent\kb" --hydrate
Pop-Location
```
Or with go run (slower, recompiles):
```powershell
Push-Location "$env:USERPROFILE\FFS0_HPlaptop\moos\platform\kernel"
go run ./cmd/moos --kb "$env:USERPROFILE\FFS0_HPlaptop\ffs0-factory-super\.agent\kb" --hydrate
Pop-Location
```
Wait for: `[transport] listening on :8000`

5. Verify kernel health:
```powershell
curl -s http://localhost:8000/healthz
```

6. Verify Explorer UI:
```powershell
curl -s -o NUL -w "%{http_code}" http://localhost:8000/explorer
```
Expected: `200`

7. Verify SSE stream:
```powershell
curl -s -m 2 http://localhost:8000/log/stream
```

8. Verify MCP bridge:
```powershell
curl -s -m 2 http://localhost:8080/sse
```

9. Kernel is ready for testing.
