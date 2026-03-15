---
description: Quick smoke test for Explorer UI — hit key endpoints for health and data
---

# Explorer Smoke Test

Verify the Explorer UI and core kernel endpoints are responding correctly. Quick sanity check before running the full phased test plan.

// turbo-all

## Steps

1. Health check:
```powershell
curl -s http://localhost:8000/healthz
```
Expected: `{"status":"ok","nodes":118,"wires":131,...}`

2. Explorer HTML loads:
```powershell
curl -s -o NUL -w "%{http_code}" http://localhost:8000/explorer
```
Expected: `200`

3. State endpoint returns graph data:
```powershell
$r = Invoke-RestMethod "http://localhost:8000/state"; Write-Host "nodes:" $r.nodes.PSObject.Properties.Count "wires:" $r.wires.PSObject.Properties.Count
```
Expected: nodes ~118, wires ~131.

4. Lens endpoint — no filter (returns full graph):
```powershell
$r = Invoke-RestMethod "http://localhost:8000/state/lens"; Write-Host "lens nodes:" $r.nodes.PSObject.Properties.Count
```
Expected: ~118 nodes.

5. Lens endpoint — kind filter:
```powershell
$r = Invoke-RestMethod "http://localhost:8000/state/lens?kind=provider"; Write-Host "provider nodes:" $r.nodes.PSObject.Properties.Count
```
Expected: subset of nodes where type_id == "provider".

6. Lens endpoint — stratum filter:
```powershell
$r = Invoke-RestMethod "http://localhost:8000/state/lens?stratum=S1"; Write-Host "S1 nodes:" $r.nodes.PSObject.Properties.Count
```
Expected: ~51 nodes (urn:moos:cat:* ontology nodes).

7. Lens POST — body filter:
```powershell
Invoke-RestMethod -Method POST -Uri "http://localhost:8000/state/lens" -ContentType "application/json" -Body '{"rules":[{"kind":["agent_spec"]}]}'
```
Expected: exactly 3 nodes (claude-code, vscode-ai, antigraviti).

8. Log endpoint:
```powershell
Invoke-RestMethod "http://localhost:8000/log?limit=5"
```
Expected: array of 5 morphism entries.

9. Registry endpoint:
```powershell
$r = Invoke-RestMethod "http://localhost:8000/semantics/registry"; Write-Host "registry types:" $r.PSObject.Properties.Count
```
Expected: 21 type specs.

10. SSE stream (2-second timeout):
```powershell
curl -s -m 2 http://localhost:8000/log/stream
```
Expected: `: connected` line.

11. MCP bridge:
```powershell
curl -s -m 2 http://localhost:8080/sse
```
Expected: `: connected`

12. Report: list each step as PASS/FAIL with actual counts. If any fail, note the HTTP status code and response body.
