---
description: Sync the moos repo — pull latest, check status, show recent commits
---

# Git Sync

Pull the latest changes from the moos repository, check for uncommitted changes, and show recent history.

// turbo-all

## Steps

1. Pull latest from main:
```powershell
Set-Location D:\FFS0_Factory\moos; git pull origin main
```

2. Show current status (uncommitted/staged files):
```powershell
Set-Location D:\FFS0_Factory\moos; git status -s
```

3. Show last 10 commits:
```powershell
Set-Location D:\FFS0_Factory\moos; git log --oneline -10
```

4. Report: pulled changes (if any), uncommitted files (if any), latest commit hash.
