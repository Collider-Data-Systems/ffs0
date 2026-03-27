---
description: Antigraviti IDE-specific capabilities for graph integration
---

# Antigraviti IDE Capabilities

// turbo-all

## Browser Verification

Antigraviti can launch an embedded Chrome browser to verify the Explorer UI:

```
Use browser_subagent to navigate to http://127.0.0.1:8000/explorer
- Verify node/wire counts match /healthz
- Click through all 5 tabs: Nodes, Wires, Slice, Schema, History
- Screenshot anomalies and embed in artifacts
```

## MCP CloudRun

Antigraviti has native access to Google Cloud Run MCP tools:
- `mcp_cloudrun_list_projects` — list GCP projects
- `mcp_cloudrun_deploy_local_folder` — deploy kernel or UI to Cloud Run
- Use for staging deployments when PRGs reach gate milestones

## Graph Checkpoint

Run after every significant action to record system state:

```powershell
$h = Invoke-RestMethod http://localhost:8000/healthz
$ts = Get-Date -Format "yyyyMMddHHmmss"
$body = @{
  type = "ADD"; actor = "urn:moos:agent:antigraviti"
  add = @{
    urn = "urn:moos:message:${ts}-ag-checkpoint"
    type_id = "channel_message"; stratum = "S2"
    payload = @{
      sender = "Antigraviti"; type = "checkpoint"
      text = "Checkpoint: nodes=$($h.nodes) wires=$($h.wires) log=$($h.log_depth)"
      tags = @("checkpoint","antigraviti")
    }
  }
} | ConvertTo-Json -Depth 10
Invoke-RestMethod http://localhost:8000/morphisms -Method Post -ContentType "application/json" -Body $body
```
