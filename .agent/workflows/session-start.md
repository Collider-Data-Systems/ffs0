---
description: Antigraviti session start checklist — read state, verify kernel, check test channel
---

# Session Start (Antigraviti Agent)

Start-of-session procedure for the Antigraviti testing agent. Read context, verify kernel, update state.

// turbo-all

> **Approval gate:** On the FIRST occurrence of each command type (`curl`, `Invoke-RestMethod`, `Set-Location`, `go test`, `git`), click **"Always run ↑"** (not just "Run"). This authorizes the pattern for the entire session. There is no global auto-approve — you must do this once per command type.

## Steps

1. Read your agent state file:
```
.agent/configs/agents/antigraviti.json
```
Confirm `status` field. If `paused`, do not proceed without direction.

2. Read the test channel for latest directions (top 60 lines only — newest is always there):
```
.agent/knowledge_base/testoff.md
```
Note the latest `test-plan` or `direction` message and which phase is active.

3. Pull latest code:
```powershell
Set-Location D:\FFS0_Factory\moos; git pull origin main; git log --oneline -5
```

4. Check kernel is running:
```powershell
curl -s http://localhost:8000/healthz
```
Expected: `{"status":"ok","nodes":118,"wires":131,...}`
If not running → run workflow `/boot-kernel` first. Do NOT proceed to testing without `status: ok`.

5. Verify lens endpoint is live (v0.2 feature):
```powershell
$r = Invoke-RestMethod "http://localhost:8000/state/lens?kind=agent_spec"; Write-Host "agent nodes:" $r.nodes.PSObject.Properties.Count
```
Expected: 3 agent nodes (claude-code, vscode-ai, antigraviti).

6. Update your state file to `active` with current timestamp:
```json
{
  "agent_urn": "urn:moos:agent:antigraviti",
  "status": "active",
  "role": "testing",
  "session_start": "<current ISO timestamp>"
}
```

7. If no new direction in testoff.md: prepend `"No new direction. Status: standby."` to testoff.md and stop.

8. If a test plan is active: proceed with the phased test plan per the OPERATING MANUAL in testoff.md.
