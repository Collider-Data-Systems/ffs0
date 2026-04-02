---
description: Pulls latest changes for the workspace to maintain local/cloud sync.
---

# Sync Workspace

This workflow automatically pulls the latest changes for your `ffs0` workspace and handles git fetches, ensuring you're up to date across workstations. 

```bash
// turbo-all
Write-Host "Syncing ffs0 repository..."
git fetch -p
git pull --rebase
Write-Host "Workspace synchronized!"
```
