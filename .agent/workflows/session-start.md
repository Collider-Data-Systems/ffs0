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

6. Start auto delegation listener (background):

```powershell
Start-Process pwsh -ArgumentList '-NoLogo','-File','.\ffs0-factory-super\.agent\dev\antigraviti-auto-listen.ps1' -WindowStyle Hidden
```

Expected log behavior: listener auto-ACKs delegation messages tagged `delegation` + `antigraviti`.

6a. Verify listener is running:

```powershell
Get-CimInstance Win32_Process | Where-Object { $_.Name -match 'pwsh|powershell' -and $_.CommandLine -match 'antigraviti-auto-listen.ps1' } | Select-Object ProcessId,CommandLine
```

6b. One-time persistence (run once per machine):

```powershell
pwsh -File .\ffs0-factory-super\.agent\dev\install-antigraviti-auto-listener-task.ps1
```

6c. No-chat delegation signal (graph-native):

```powershell
# Emit a channel_message via /morphisms (delegate/policy tags) from any script/IDE.
# Listener picks it up from HG log automatically; no chat trigger needed.
```

6d. PRG-targeted delegation contract:

```powershell
pwsh -File .\ffs0-factory-super\.agent\dev\delegate-antigraviti.ps1 `
	-PrgUrn "urn:moos:prg:040-the-bridge" `
	-Text "AG: process PRG040 updates and checkpoint outcomes to HG." `
	-Tags "delegation,antigraviti,prg040,save-hg"
```

Use this for any PRG-specific assignment so routing is explicit in HG.

7. Save session checkpoint to HG:

```powershell
$s = Invoke-RestMethod http://localhost:8000/healthz
"status={0} nodes={1} wires={2} log_depth={3}" -f $s.status,$s.nodes,$s.wires,$s.log_depth
```

8. Calendar projection check (if FUN06 is active):

```powershell
try { Invoke-RestMethod http://localhost:8000/functor/calendar | ConvertTo-Json -Depth 4 } catch { "calendar projection endpoint not active yet" }
```

9. Update your state file to `active` with current timestamp.

10. If no new direction in testoff.md: post `"No new direction. Status: standby."` and stop.

11. If a test plan is active: proceed per the instructions in testoff.md.
