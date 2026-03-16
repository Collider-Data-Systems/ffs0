---
description: Full CI/CD test cycle — git pull, health, HTTP endpoints, go test, browser, report
---

# Full Test Cycle (Antigravity CI/CD)

When a test plan arrives in testoff.md, run this complete cycle.

// turbo-all

## Steps

1. Pull latest code:
```powershell
git -C ".\moos" pull origin main
git -C ".\moos" log --oneline -3
```

2. Verify kernel health (boot if needed via `/boot-kernel`):
```powershell
curl -s http://localhost:8000/healthz
```

3. **Phase A — HTTP endpoints** (per test plan in testoff.md):
```powershell
# Health
curl -s http://localhost:8000/healthz

# Lens
(Invoke-RestMethod "http://localhost:8000/state/lens?kind=agent_spec").nodes.PSObject.Properties.Count

# Scope
(Invoke-RestMethod "http://localhost:8000/state/scope/urn:moos:agent:antigraviti").nodes.PSObject.Properties.Count
```

4. **Phase B — Browser visual test** (UNLOCKED on HP laptop):
   - Navigate to `http://localhost:8000/explorer`
   - Run visual checks per test plan
   - Take screenshots of any issues

5. **Phase E — Go regression**:
```powershell
Push-Location ".\moos\platform\kernel"; go test ./...; Pop-Location
```

6. Prepend results to testoff.md (timestamp + table format).

7. Update `antigraviti.json` — status, phases_completed, last_result.

**Report format:**
```
| Phase | Result | Detail |
|-------|--------|--------|
| A1 health | PASS | nodes:119 wires:132 |
| B browser | PASS | 4 tabs, data populated |
| E go test | PASS | 9 packages green |
```
