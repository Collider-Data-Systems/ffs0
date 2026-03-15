---
description: Boot the mo:os kernel with KB hydration and verify it's healthy
---

# Boot Kernel

> **Antigraviti IDE note:** When prompted "Run command?" click "Always run ↑" to avoid per-command approval.

Start the mo:os kernel with knowledge base hydration, verify health, and confirm SSE streaming.

> **Note:** The kernel no longer auto-starts on IDE open. Run this workflow manually when a session begins.

// turbo-all

> **Antigraviti IDE:** When prompted "Run command?", click **"Always run ↑"** (not just Run) on the first occurrence of each command type. It remembers per pattern for the session.

## Steps

1. Check if kernel is already running on port 8000:

```powershell
curl -s http://localhost:8000/healthz
```

If it returns `status: ok` — skip to step 5. Kernel is already up.

2. Clear any stale process on port 8080 (MCP bridge from a previous session):

```powershell
$proc = Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess
if ($proc) { Stop-Process -Id $proc -Force; Write-Host "Killed PID $proc on :8080" } else { Write-Host ":8080 is free" }
```

3. Clear any stale process on port 8000 (kernel from a previous session):

```powershell
$proc = Get-NetTCPConnection -LocalPort 8000 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess
if ($proc) { Stop-Process -Id $proc -Force; Write-Host "Killed PID $proc on :8000" } else { Write-Host ":8000 is free" }
```

4. Start the kernel (open a **new terminal tab** for this — it blocks):

```powershell
Set-Location D:\FFS0_Factory\moos\platform\kernel; go run ./cmd/moos --kb "D:\FFS0_Factory\.agent\knowledge_base" --hydrate
```

Wait for log line: `[transport] listening on :8000`

5. Verify kernel health:

```powershell
curl -s http://localhost:8000/healthz
```

Expected: `{"status":"ok","nodes":118,"wires":131,...}`

6. Verify Explorer UI serves:

```powershell
curl -s -o NUL -w "%{http_code}" http://localhost:8000/explorer
```

Expected: `200`

7. Verify SSE stream connects (2s timeout is fine):

```powershell
curl -s -m 2 http://localhost:8000/log/stream
```

Expected: `: connected`

8. Verify MCP bridge on :8080:

```powershell
curl -s -m 2 http://localhost:8080/sse
```

Expected: `: connected`

9. Report results. Kernel is ready for testing.
