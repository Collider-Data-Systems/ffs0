---
mode: agent
description: T=166 workspace overhaul — Antigravity IDE verification
---

# T=166 Antigravity overhaul

The ffs0 workspace has been overhauled. Your job: verify everything works from AG's perspective, clean up stale context, and confirm you're operational for T=164 work.

## Steps

1. **Pull latest ffs0**
   ```
   cd C:\Users\maass\HPlaptop\ffs0 && git pull
   ```

2. **Read your instruction file**
   Read `ANTIGRAVITY.md` in the repo root. It now points to `kb/superset/running-state.md` — read that too.

3. **Verify kernel reachability**
   ```
   GET http://localhost:8000/healthz
   ```
   Expected: `{"status":"ok","log_len":298,"t_day":166}`

4. **Verify MCP**
   If your MCP is configured (check `.vscode/mcp.json`), test a tool call to the kernel.

5. **Clean your context**
   - If you have a `/brains/` folder or internal context, remove references to:
       - non-existent Codex context files
       - pre-archive foundation note paths
       - pre-v3.6 ontology metadata
   - Your single source of truth is now `kb/superset/running-state.md`

6. **Report back**
   Confirm:
   - ANTIGRAVITY.md reads clean
   - running-state.md loaded
   - Kernel reachable (yes/no)
   - MCP wired (yes/no)
   - Any stale references found and cleaned (list them)

Do not start new work. This is a verification-only task.
