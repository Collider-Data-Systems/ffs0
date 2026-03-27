---
description: Full test cycle — git pull, health check, HTTP endpoints, go test, browser, report
---

# Full Test Cycle (Antigraviti CI/CD)

When a test plan arrives in testoff.md, run this complete cycle.

// turbo-all

## Steps

1. Pull latest code:
```powershell
git -C ".\moos" pull origin main
git -C ".\moos" log --oneline -3
```

2. Verify kernel health (boot if needed via `workflows/boot-kernel.md`):
```powershell
curl -s http://localhost:8000/healthz
```

3. **Phase A — HTTP endpoints** (per test plan in testoff.md):
```powershell
# Health
curl -s http://localhost:8000/healthz

# Saturation (Explorer 2.0)
curl -s http://localhost:8000/state/saturation

# State
$state = Invoke-RestMethod "http://localhost:8000/state"
Write-Host "Nodes:" $state.nodes.Count "Wires:" $state.wires.Count

# SSE
curl -s -m 2 http://localhost:8000/log/stream
```

4. **Phase B — Browser visual test** (UNLOCKED on HP laptop):
   - Navigate to `http://localhost:8000/explorer`
   - Verify 5 tabs: Nodes | Wires | Slice | Schema | History
   - Run visual checks per test plan in testoff.md
   - Take screenshots of any issues

5. **Phase E — Go regression**:
```powershell
Push-Location ".\moos\platform\kernel"; go test ./...; Pop-Location
```
Expected: all packages pass (11+ packages as of Task 033).

6. Prepend results to testoff.md (timestamp + table format).

7. Record results in graph — MUTATE your agent_session node payload with status and last_result. (cfg/instance/agents/antigraviti.json is identity-only; state lives in graph.)

**Report format:**
```
| Phase | Result | Detail |
|-------|--------|--------|
| A health | PASS | nodes:NNN wires:NNN |
| A saturation | PASS | data returned |
| B browser | PASS | 5 tabs, data populated |
| E go test | PASS | all packages green |
```
