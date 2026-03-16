---
description: Sync both repos — pull latest from origin, check status, show recent commits
---

# Git Sync (Both Repos)

// turbo-all

## Steps

1. Sync mo:os kernel repo:
```powershell
git -C ".\moos" pull origin main
git -C ".\moos" log --oneline -5
git -C ".\moos" status -s
```

2. Sync ffs0-factory-super repo:
```powershell
git -C ".\ffs0-factory-super" pull origin main
git -C ".\ffs0-factory-super" log --oneline -5
git -C ".\ffs0-factory-super" status -s
```

3. Report any uncommitted changes or divergence.
