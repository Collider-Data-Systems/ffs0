---
description: Run all Go tests in the mo:os kernel and report results
---

# Run Kernel Tests

> **Antigraviti IDE note:** When prompted "Run command?" click "Always run ↑" to avoid per-command approval.

Execute the full test suite for the mo:os kernel. All packages must pass with 0 failures.

// turbo-all

> **Antigraviti IDE:** Click **"Always run ↑"** on the first `go test` prompt. Use PowerShell `Set-Location` not bash `cd`.

## Steps

1. Run the full test suite:

```powershell
Set-Location D:\FFS0_Factory\moos\platform\kernel; go test ./...
```

Expected: `ok` for all packages, 0 failures.

2. If any failures, run the failing package with verbose output:

```powershell
Set-Location D:\FFS0_Factory\moos\platform\kernel; go test -v -run TestFailingName ./internal/package_name
```

3. Report results: list passing packages, any failures, and whether race conditions exist.

4. (Optional) Run with race detector:

```powershell
Set-Location D:\FFS0_Factory\moos\platform\kernel; go test -race ./...
```
