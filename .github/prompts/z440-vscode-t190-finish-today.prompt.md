---
mode: agent
description: "Use when: handing T190 mo:os projection/admin parity finish work to VS Code on the Z440."
---

# T190 Z440 VS Code Finish-Today Handoff

You are VS Code on the Z440. Rehydrate from current repo state and live endpoints, not stale IDE memory.

This is a session-centered finish pass. Treat the IDE conversation as S0 substrate; the durable object is the session occasion: purpose, occupant, host kernel, scope pins, and safe operations at the current log prefix.

## First Screen

1. Read `kb/superset/running-state.md` first.
2. Read `kb/moos-diary/README.md`, `kb/moos-diary/t190-z440-vscode-lead-handoff-wrapup.md`, and `kb/moos-diary/t190-session-branch-and-closeout-policy.md`. The diary folder now groups 3-5 running-state sprints into readable session wrap-ups for all agents/personae.
3. Check repo state before changing anything:
   ```powershell
   git -C D:\HPZ440\ffs0 status --short --branch
   git -C D:\HPZ440\moos-kernel status --short --branch
   git -C D:\HPZ440\moos-router-feat-type-map-routing status --short --branch
   ```
4. If `D:\HPZ440\ffs0` has local WIP, preserve it. Do not reset or force checkout. Create or keep a work branch before editing shared files:
   ```powershell
   git -C D:\HPZ440\ffs0 switch -c z440/t190-projection-finish
   ```
   If the branch already exists or you are already on a suitable branch, stay there. Pull/rebase only after inspecting the dirty files.
5. Pull the latest shared ffs0 state once local WIP is protected. The hp-laptop closeout includes the Z440 admin parity apply record, diary report, folder README, and this prompt.

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

## Session And Identity Model

Work from these distinctions:

- `user` is the human principal. Today that is `user:sam`; do not add Menno, Lola, or other IRL people as kernel `user` principals without an explicit identity/personhood design.
- `agent` is an AI delegate or harness surface: Claude Code, VS Code, Antigravity, Cowork, service drivers, or future IDE delegates.
- `session` is the scoped occasion that carries work. It evaluates purpose, occupant, host kernel, scope pins, and authority path.
- `group` is ownership or collective scope, such as `group:sam`, application groups, or later family/domain groups.
- `channel` is the right first shape for external accounts and surfaces: Gmail accounts, GitHub/Git accounts, Calendar, Drive, Tasks, VCS, websites, DNS, dashboards, and local filesystems.

Sam may add four more Gmail accounts and more Git accounts. Treat that as account-as-channel first, not account-as-user. Proposed future shape: `channel:google.gmail.<slug>`, `channel:github.<account-or-org>`, and `channel:vcs.<account-or-repo>`, owned by `group:sam` or `user:sam`, with ingested artifacts linked through WF12 and projected surfaces keyed by `HG URN`.

Do not G-sync Project #4 status or emit account/person rewrites until row identity and authority semantics are reliable.

## Finish Work

1. Run the projection pipeline locally:
   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File D:\HPZ440\ffs0\dev\scripts\projections\run-session-pipeline.ps1
   ```
2. Use Julia/Graphviz on Z440 as already installed. If packages are missing, install only the minimum needed for the existing pipeline.
3. Bring Z440 WIP in `dev/scripts/projections/run-session-pipeline.ps1` and `ffs0.code-workspace` to a clean, reviewable state, preserving hp-laptop compatibility.
4. Final gate should be `warn` or better with zero `fail`. Record pass/warn/fail counts and the dashboard path under `tmp/projections/session_pipeline/index.html`.
5. Project #4 row identity is separate from HG rewrites. Current hp-laptop repair raised `HG URN` coverage to 31/57. Do not G-sync board status until identity coverage is reliable. You may inspect remaining rows; only populate `HG URN` fields when exactly one resolvable `urn:moos:*` identity is unambiguous.
6. Add or update a session-centered diary wrap-up if your finish pass covers more than one sprint, touches external surfaces, or changes what another agent should assume next.

## Branch Rules

- `ffs0/main` is the coordination trunk for verified state packets. Running-state and moos-diary closeouts should land together there when the packet is small, verified, and needed by other sessions immediately.
- Use a branch for Z440 WIP, projection scripts, workspace files, large docs, identity/account proposals, or anything that cannot be verified in one sitting.
- `moos-router` is already on `feat/type-map-routing`; keep router changes on that branch unless Sam says otherwise.
- `moos-kernel` stays on `master` for readback only. Create a focused branch before any runtime code change.
- Never commit `secrets/`, `.vscode/mcp.json`, generated binaries, or ignored `tmp/` outputs.

## Closeout

Before calling it done:

1. Update `kb/superset/running-state.md` with the Z440 projection result and any remaining warnings.
2. Update `kb/moos-diary/` with a session-centered wrap-up if the result changes the handoff picture.
3. Commit only intentional files with a focused message.
4. Push `ffs0/main` for a verified coordination packet; push your branch for WIP or implementation work.
5. Report back with: branch/commit, Doctor result, persona result, pipeline gate result, Project #4 identity coverage, and any deferred items.

Finish this today; keep the changes small and operational.
