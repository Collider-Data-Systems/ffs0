---
description: Start an Antigraviti testing session — firestarter-based, graph-native delegation
---

// turbo-all

# Session Start (Antigraviti — HP Laptop)

## Steps

1. Read your agent config:

```powershell
Get-Content ".\ffs0-factory-super\.agent\cfg\instance\agents\antigraviti.json"
```

Confirm `status` field. If `paused`, do not proceed without direction.

2. Check kernel is running:

```powershell
curl -s http://localhost:8000/healthz
```

Expected: `{"status":"ok","nodes":NNN,"wires":NNN,...}`
If not running → use `workflows/boot-kernel.md` first.

3. Query pending delegation tasks assigned to AG:

```powershell
$lens = Invoke-RestMethod "http://localhost:8000/state/lens?kind=delegation_task"
$tasks = @($lens.nodes.PSObject.Properties.Value) |
  Where-Object {
    $_.payload.assigned_to -match "antigraviti" -and $_.payload.status -eq "pending"
  } |
  Sort-Object updated_at
$tasks | Select-Object urn,@{n='title';e={$_.payload.title}}
```

4. Start firestarter SSE listener (reactive, replaces polling):

```powershell
Start-Process pwsh -ArgumentList '-NoLogo','-File','.\ffs0-factory-super\.agent\dev\antigraviti-auto-listen.ps1' -WindowStyle Hidden
```

The listener watches `/log/stream` for `firestarter-trigger` SSE events targeting AG.
When triggered: picks up pending delegation_tasks, executes, MUTATEs status→completed.

5. Verify listener is running:

```powershell
Get-CimInstance Win32_Process | Where-Object { $_.Name -match 'pwsh|powershell' -and $_.CommandLine -match 'antigraviti-auto-listen.ps1' } | Select-Object ProcessId,CommandLine
```

6. Save session checkpoint:

```powershell
$s = Invoke-RestMethod http://localhost:8000/healthz
"status={0} nodes={1} wires={2} log_depth={3}" -f $s.status,$s.nodes,$s.wires,$s.log_depth
```

7. Update your agent config to `active` with current timestamp.

8. If no pending tasks and no firestarter trigger: run proactive testing suite per `workflows/antigraviti.md` (Proactive Testing section).
