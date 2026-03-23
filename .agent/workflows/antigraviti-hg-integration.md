---
description: Integrate Antigraviti IDE with PRG-targeted HG delegations and listener updates
---

# Antigraviti HG Integration

// turbo-all

## Goal

Use graph-native delegation messages so Antigraviti can pick up PRG-specific work from HG without manual chat wakeups.

## Preconditions

1. Kernel is healthy:
```powershell
Invoke-RestMethod http://localhost:8000/healthz
```

2. Auto-listener is running:
```powershell
Get-CimInstance Win32_Process |
  Where-Object { $_.Name -match 'pwsh|powershell' -and $_.CommandLine -match 'antigraviti-auto-listen.ps1' } |
  Select-Object ProcessId,CommandLine
```

## PRG-Targeted Delegation

Send delegation directly to the PRG you want AG to operate on:

```powershell
pwsh -File .\ffs0-factory-super\.agent\dev\delegate-antigraviti.ps1 \
  -PrgUrn "urn:moos:prg:040-the-bridge" \
  -Text "AG: run retroactive Google Drive mapping for PRG040 and checkpoint results." \
  -Tags "delegation,antigraviti,prg040,gdrive,right-adjoint,save-hg"
```

Expected behavior:
1. A `channel_message` is added in S2.
2. Message is linked to target PRG via `out -> in`.
3. AG listener auto-ACKs and links ACK back to source.

## Watch for ACK

```powershell
Get-Content .\moos\platform\kernel\data\morphism-log.jsonl -Tail 120 |
  Select-String "antigraviti-auto-ack|prg040|delegate-antigraviti"
```

## Optional Calendar Projection Check

```powershell
try {
  Invoke-RestMethod http://localhost:8000/functor/calendar | ConvertTo-Json -Depth 4
} catch {
  "FUN06 projection endpoint unavailable"
}
```

## Notes

- This is pull+push hybrid today: AG uses SSE-first with polling backfill.
- When MCP notifications are fully wired, this workflow remains valid but becomes lower-latency.

## Antigravity IDE Capabilities (unique to this IDE)

### Browser Verification
Antigravity can launch an embedded Chrome browser to verify the Explorer UI:
```
Use browser_subagent to navigate to http://127.0.0.1:8000/explorer
- Verify node/wire counts match /healthz
- Click through all 5 tabs: Nodes, Wires, Slice, Schema, History
- Screenshot anomalies and embed in artifacts
- Record browser sessions as .webp for audit trail
```

### MCP CloudRun
Antigravity has native access to Google Cloud Run MCP tools:
- `mcp_cloudrun_list_projects` — list GCP projects
- `mcp_cloudrun_deploy_local_folder` — deploy kernel or UI to Cloud Run
- Use for staging deployments when PRGs reach gate milestones

### HG Checkpoint (run after every significant action)
```powershell
$h = Invoke-RestMethod http://localhost:8000/healthz
$ts = Get-Date -Format "yyyyMMddHHmmss"
$body = @{
  type = "ADD"
  actor = "urn:moos:agent:antigraviti"
  add = @{
    urn = "urn:moos:message:${ts}-antigraviti-checkpoint"
    type_id = "channel_message"
    stratum = "S2"
    payload = @{
      sender = "Antigraviti"
      type = "checkpoint"
      text = "HG checkpoint: nodes=$($h.nodes) wires=$($h.wires) depth=$($h.log_depth)"
      tags = @("checkpoint","antigraviti")
    }
  }
} | ConvertTo-Json -Depth 10
Invoke-RestMethod http://localhost:8000/morphisms -Method Post -ContentType "application/json" -Body $body
```
