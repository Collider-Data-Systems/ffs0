---
description: Quick Explorer smoke test — HTTP endpoints + browser visual verification
---

# Explorer Smoke Test (HP Laptop — Browser UNLOCKED)

// turbo-all

## Steps

1. Health check:
```powershell
curl -s http://localhost:8000/healthz
```
Expected: `nodes=119, wires=132, status=ok`

2. Lens endpoints:
```powershell
(Invoke-RestMethod "http://localhost:8000/state/lens?kind=agent_spec").nodes.PSObject.Properties.Count
```
Expected: 4 agent nodes

```powershell
(Invoke-RestMethod "http://localhost:8000/state/lens?kind=provider").nodes.PSObject.Properties.Count
```
Expected: 6 provider nodes

3. Scope endpoint:
```powershell
(Invoke-RestMethod "http://localhost:8000/state/scope/urn:moos:agent:antigraviti").nodes.PSObject.Properties.Count
```
Expected: 1 (self)

4. SSE stream:
```powershell
curl -s -m 2 http://localhost:8000/log/stream
```
Expected: `: connected`

5. **Browser visual test** (HP laptop can access localhost!):
   - Navigate to `http://localhost:8000/explorer` in browser
   - Verify 4 tabs: Objects, Morphisms, Ontology, Log
   - Verify filter strip: Kind, Stratum, Category, Scope, Search
   - Verify data is populated (119 nodes, 132 wires)
   - Take screenshot on any anomaly

6. Report results to testoff.md.
