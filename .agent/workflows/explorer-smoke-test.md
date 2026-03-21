---
description: Explorer 2.0 smoke test — HTTP endpoints + browser visual verification
---

# Explorer 2.0 Smoke Test (HP Laptop — Browser UNLOCKED)

// turbo-all

## Steps

1. Health check:
```powershell
curl -s http://localhost:8000/healthz
```
Expected: `status:ok` with current node/wire counts (check against last known state).

2. Saturation endpoint:
```powershell
curl -s http://localhost:8000/state/saturation
```
Expected: JSON with port saturation data.

3. State endpoint:
```powershell
$state = Invoke-RestMethod "http://localhost:8000/state"
Write-Host "Nodes:" $state.nodes.Count "Wires:" $state.wires.Count
```

4. SSE stream:
```powershell
curl -s -m 2 http://localhost:8000/log/stream
```
Expected: `: connected`

5. **Browser visual test** (HP laptop can access localhost):
   - Navigate to `http://localhost:8000/explorer`
   - Verify **5 tabs**: Nodes | Wires | Slice | Schema | History
   - Verify **pipeline bar** top: S0→S4 segments with counts, clickable filters
   - Verify **Nodes tab**: groups by type, expandable rows, port saturation badges (N/M)
   - Verify **Schema tab**: 28 type cards with port signatures
   - Verify **Slice tab**: URN input field + coslice/slice sections
   - Verify **History tab**: live SSE morphism log
   - Verify data is populated (current graph state)
   - Take screenshot on any anomaly

6. Post results to testoff.md.
