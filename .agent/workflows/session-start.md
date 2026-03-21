---
description: Start an Antigraviti testing session — read state, verify kernel, check test channel
---

# Session Start (Antigraviti — HP Laptop)

// turbo-all

## Steps

1. Read your agent state file:
```powershell
Get-Content ".\ffs0-factory-super\.agent\cfg\agents\antigraviti.json"
```
Confirm `status` field. If `paused`, do not proceed without direction.

2. Read the test channel for latest direction (top 60 lines — newest is always first):
```powershell
Get-Content ".\ffs0-factory-super\.agent\channels\testoff.md" -TotalCount 60
```

3. Pull latest code:
```powershell
git -C ".\moos" pull origin main; git -C ".\moos" log --oneline -5
```

4. Check kernel is running:
```powershell
curl -s http://localhost:8000/healthz
```
Expected: `{"status":"ok","nodes":NNN,"wires":NNN,...}`
If not running → use `workflows/boot-kernel.md` first.

5. Verify saturation endpoint (Explorer 2.0):
```powershell
curl -s http://localhost:8000/state/saturation | ConvertFrom-Json | Select-Object -First 5
```

6. Update your state file to `active` with current timestamp.

7. If no new direction in testoff.md: post `"No new direction. Status: standby."` and stop.

8. If a test plan is active: proceed per the instructions in testoff.md.
