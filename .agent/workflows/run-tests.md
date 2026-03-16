---
description: Run all Go tests in the mo:os kernel and report results
---

# Run Kernel Tests (HP Laptop)

// turbo-all

## Steps

1. Run the full test suite:
```powershell
Push-Location ".\moos\platform\kernel"; go test ./...; Pop-Location
```
Expected: `ok` for all 9 packages, 0 failures.

2. If any failures, run verbose on the failing package:
```powershell
Push-Location ".\moos\platform\kernel"; go test -v -run TestFailingName ./internal/package_name; Pop-Location
```

3. Report results: passing packages, failures, race conditions.

4. (Optional) Run with race detector:
```powershell
Push-Location ".\moos\platform\kernel"; go test -race ./...; Pop-Location
```
