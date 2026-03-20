# Task 029 — Triangle Auto-Trigger

**Date:** 2026-03-16
**Status:** VERIFIED (2026-03-16 23:25)
**Assigned:** VS Code AI (implement) → Antigraviti (verify)
**Priority:** high
**Deps:** 028 (complete)
**Commits:** `fc483f9`, `ff3d633`
**Verification:** Antigraviti confirmed auto-trigger fires on watcher boot, go test 9/9 green, toast notifications working

---

## Goal

Upgrade `triangle-watcher.ps1` so Antigraviti's test cycle fires automatically when Claude Code posts a `direction` to `testoff.md`. Eliminates manual await-testoff polling and manual test-cycle invocation.

## Current State

- `triangle-watcher.ps1` detects channel file changes → sends Toast notification → stops there
- `await-testoff.md` is a separate polling loop Antigraviti runs manually
- `test-cycle.md` is a separate workflow Antigraviti runs manually after reading direction

Three manual steps. Target: zero.

## Changes Required

### 1. Add `Invoke-ChannelAction` to `triangle-watcher.ps1`

After `Invoke-ChannelChanged` sends the Toast, parse the top message type. If `testoff.md` changed and type is `direction`, auto-invoke the test-cycle workflow.

```powershell
function Invoke-ChannelAction {
    param (
        [string]$FilePath,
        [string]$FileName
    )

    if ($FileName -ne "testoff.md") { return }

    $content = Get-Content -Path $FilePath -TotalCount 15 -ErrorAction Stop
    $topMessage = $content | Where-Object { $_ -match "^### \[" } | Select-Object -First 1

    if ($topMessage -match "ClaudeCode.*→.*direction") {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] AUTO-TRIGGER: direction detected in testoff.md"
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Executing test-cycle..."

        # Pull latest
        git -C ".\moos" pull origin main 2>&1 | ForEach-Object { Write-Host "  $_" }

        # Run go test
        Push-Location ".\moos\platform\kernel"
        $testResult = go test ./... 2>&1
        $testResult | ForEach-Object { Write-Host "  $_" }
        Pop-Location

        # Health check
        try {
            $health = Invoke-RestMethod "http://localhost:8000/healthz" -ErrorAction Stop
            Write-Host "  healthz: nodes=$($health.nodes) wires=$($health.wires)"
        } catch {
            Write-Host "  healthz: kernel not running (start manually)"
        }

        Send-Toast -AgentName "AutoTrigger" -Channel "testoff.md" -Message "Test cycle complete — check results"
    }
}
```

### 2. Wire into `$Action` scriptblock

In `Start-ChannelWatcher`, after `Invoke-ChannelChanged`, call `Invoke-ChannelAction`:

```powershell
$Action = {
    ...
    if ($changeType -eq 'Changed') {
        try {
            Invoke-ChannelChanged -FilePath $path -FileName $name
            Invoke-ChannelAction -FilePath $path -FileName $name
        } catch { ... }
    }
}
```

### 3. `await-testoff.md` becomes deprecated

Keep file but add deprecation note: "Superseded by triangle-watcher.ps1 auto-trigger (Task 029)."

## Test Plan (Antigraviti verifies)

1. Start `triangle-watcher.ps1` in background terminal
2. Have Claude Code post a test direction to `testoff.md`
3. Verify: Toast fires AND `go test` runs automatically
4. Verify: health check runs if kernel is up
5. Verify: non-direction messages (test-result, question) do NOT trigger test cycle

## Acceptance

- Direction in testoff.md → auto `go test` + health check within 5s
- Non-direction messages → Toast only, no auto-execution
- `await-testoff.md` marked deprecated
