---
mode: agent
description: T=166 workspace overhaul — VSCode Codex verification
---

# T=166 VSCode overhaul

The ffs0 workspace has been overhauled. Your job: verify the new stored prompts work, confirm context files load, and report readiness.

## Steps

1. **Pull latest ffs0**
   ```
   cd C:\Users\maass\HPlaptop\ffs0 && git pull
   ```

2. **Read context file**
   Read `.github/copilot-instructions.md` — it now points to `kb/superset/running-state.md`.
   Read `running-state.md` too.

3. **Test the stored prompt**
   Use the stored prompt `.github/prompts/running-start-t164.prompt.md`:
   - Does it auto-discover in the prompt picker?
   - Run it: does it read running-state.md and give a 3-line orientation?

4. **Verify kernel reachability**
   ```
   curl http://localhost:8000/healthz
   ```
   Expected: `{"status":"ok","log_len":298,"t_day":166}`

5. **Clean stale references**
   If any stored prompts or workflows reference:
   - `codex-unified.md` → does not exist
   - `foundation-t158.md` → archived at `dev/reference/research-archive/`
   - Ontology v3.5 / WF01-WF18 → stale (now v3.6, WF01-WF19)
   
   Update or remove them.

6. **Report back**
   Confirm:
   - copilot-instructions.md loads cleanly
   - running-start prompt discoverable and functional
   - Kernel reachable (yes/no)
   - Stale references found and cleaned (list)
   - Any VSCode-specific stored prompt improvements to suggest

Do not start new work. Verification only.
