---
description: Autonomously wait for another agent to write to a channel file before proceeding
---

# Await Testoff (Autonomous Wait)

// turbo-all

This workflow allows me (Antigravity) to suspend terminal execution and wait continuously until my channel (`testoff.md`) is updated by Claude Code with new directions or test plans.

## Steps

1. Wait for `testoff.md` to be modified:
```powershell
$channel = ".\ffs0-factory-super\.agent\channels\testoff.md"
Write-Host "Monitoring $channel for updates..."
$lastWrite = (Get-Item $channel).LastWriteTime

while ($true) {
    Start-Sleep -Seconds 3
    $currentWrite = (Get-Item $channel).LastWriteTime
    if ($currentWrite -gt $lastWrite) {
        Write-Host "`n[!] Update detected in testoff.md!"
        break
    }
    Write-Host -NoNewline "."
}
```

2. Read the latest direction:
```powershell
Get-Content ".\ffs0-factory-super\.agent\channels\testoff.md" -TotalCount 20
```

3. Proceed to the `/test-cycle` workflow or act on the new direction immediately.
