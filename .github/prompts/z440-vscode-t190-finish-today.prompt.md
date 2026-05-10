---
mode: agent
description: "Use when: handing T190 mo:os projection/admin parity finish work to VS Code on the Z440."
---

# T190 Z440 VS Code Finish-Today Handoff

You are VS Code on the Z440. Rehydrate from current repo state and live endpoints, not stale IDE memory.

## First Screen

1. Read `kb/superset/running-state.md` first.
2. Check repo state before changing anything:
   ```powershell
   git -C D:\HPZ440\ffs0 status --short --branch
   git -C D:\HPZ440\moos-kernel status --short --branch
   git -C D:\HPZ440\moos-router-feat-type-map-routing status --short --branch
   ```
3. If `D:\HPZ440\ffs0` has local WIP, preserve it. Do not reset or force checkout. Create or keep a work branch before editing shared files:
   ```powershell
   git -C D:\HPZ440\ffs0 switch -c z440/t190-projection-finish
   ```
   If the branch already exists or you are already on a suitable branch, stay there. Pull/rebase only after inspecting the dirty files.
4. Pull the latest shared ffs0 state once local WIP is protected. The hp-laptop closeout includes the Z440 admin parity apply record and this prompt.

## Live Checks

Run the federation checks from the Z440 side:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File D:\HPZ440\ffs0\dev\scripts\ops\Test-MoosFederation.ps1 -Mode Doctor
powershell -NoProfile -ExecutionPolicy Bypass -File D:\HPZ440\ffs0\dev\scripts\ops\Test-MoosFederation.ps1 -Mode VerifyPersona -Persona z440-vscode-lead
Invoke-RestMethod http://localhost:8000/healthz | ConvertTo-Json -Depth 8
Invoke-RestMethod http://localhost:9000/healthz | ConvertTo-Json -Depth 8
Invoke-RestMethod https://api.my-tiny-data-collider.nl/healthz | ConvertTo-Json -Depth 8
Invoke-RestMethod https://kernel.my-tiny-data-collider.nl/healthz | ConvertTo-Json -Depth 8
```

Expected current shape:

- Z440 primary is `ontology_version=3.16.1`, `t_day=190`, `log_len >= 449`.
- `z440-vscode-lead` persona preflight passes.
- Both routers resolve `session:sam.governance` and `session:sam.z440-vscode-projection-lead`.
- Cloudflare public health returns HTTP 200.

Confirm these four Z440 primary relations are present before doing more HG work:

- `group:sam --owns/owned-by--> session:sam.z440-vscode-projection-lead`
- `group:sam --owns/owned-by--> purpose:sam.z440-vscode-projection-lead-operations`
- `group:sam --owns/owned-by--> program:sam.t190.z440-vscode-projection-lead-transition`
- `session:sam.z440-vscode-projection-lead --pins-urn/pinned-by-session--> group:sam`

The applied payload record is `dev/scripts/ops/t190-z440-admin-parity-review.program.json`. It has already been applied once from hp-laptop; do not replay it unless relation absence has been freshly checked and Sam explicitly approves.

## Finish Work

1. Run the projection pipeline locally:
   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File D:\HPZ440\ffs0\dev\scripts\projections\run-session-pipeline.ps1
   ```
2. Use Julia/Graphviz on Z440 as already installed. If packages are missing, install only the minimum needed for the existing pipeline.
3. Bring Z440 WIP in `dev/scripts/projections/run-session-pipeline.ps1` and `ffs0.code-workspace` to a clean, reviewable state, preserving hp-laptop compatibility.
4. Final gate should be `warn` or better with zero `fail`. Record pass/warn/fail counts and the dashboard path under `tmp/projections/session_pipeline/index.html`.
5. Project #4 row identity is separate from HG rewrites. Current hp-laptop repair raised `HG URN` coverage to 31/57. Do not G-sync board status until identity coverage is reliable. You may inspect remaining rows; only populate `HG URN` fields when exactly one resolvable `urn:moos:*` identity is unambiguous.

## Branch Rules

- `ffs0` is shared across hp-laptop and Z440. Use a branch for Z440 edits to shared scripts, workspace files, docs, prompts, or running-state.
- `moos-router` is already on `feat/type-map-routing`; keep router changes on that branch unless Sam says otherwise.
- `moos-kernel` stays on `master` for readback only. Create a focused branch before any runtime code change.
- Never commit `secrets/`, `.vscode/mcp.json`, generated binaries, or ignored `tmp/` outputs.

## Closeout

Before calling it done:

1. Update `kb/superset/running-state.md` with the Z440 projection result and any remaining warnings.
2. Commit only intentional files with a focused message.
3. Push the branch, or push `main` only if Sam explicitly chose a direct shared-state commit.
4. Report back with: branch/commit, Doctor result, persona result, pipeline gate result, Project #4 identity coverage, and any deferred items.

Finish this today; keep the changes small and operational.
