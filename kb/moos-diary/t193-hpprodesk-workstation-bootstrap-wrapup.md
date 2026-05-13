# T193 HP ProDesk Workstation Bootstrap Wrapup

**T-day:** T=193
**Date:** 2026-05-13
**Kernel/session:** `hp-laptop.primary` / `session:sam.governance` as the coordinating lane; `hpprodesk.primary` / `session:sam.hpprodesk-setup` as the planned third-workstation lane
**Runtime readback:** HP ProDesk local primary now reports `/healthz` green from the `hpprodesk` seed log; no HP ProDesk HG rewrites have been applied yet
**Lane:** HP ProDesk workstation bring-up, topology correction, prompt handoff, and ffs0 trunk policy

## Executive Status

The recent T193 period turned the loose "HP Pro is in reach" idea into a concrete HP ProDesk bootstrap packet. The new workstation is now named consistently as `hpprodesk`, with planned kernel `urn:moos:kernel:hpprodesk.primary`, setup session `urn:moos:session:sam.hpprodesk-setup`, purpose `urn:moos:purpose:sam.hpprodesk-workstation-bootstrap`, and VS Code agent `urn:moos:agent:vscode.hpprodesk.primary`.

The practical result is that the HP ProDesk-side VS Code/Copilot can now pull `ffs0/main`, read the shared bootstrap prompt, and continue from a topology file that already knows the current LAN facts: HP ProDesk at `172.29.0.32`, hp-laptop at `172.29.0.38`, and Z440 kept in consideration as the historical/offline workstation at `192.168.1.11`.

## HP ProDesk Local Readback Projection

This section is a projection/readback packet, not a new source of truth. The source of truth for runtime state remains the sovereign JSONL logs plus live `/healthz` readback; this diary records what the HP ProDesk VS Code session observed so the next agent can hydrate without replaying the whole terminal transcript.

Current HP ProDesk readback:

- Hostname: `DESKTOP-3FC7C3F`, normalized by `Test-MoosFederation.ps1` to `hpprodesk`.
- Windows user: `desktop-3fc7c3f\geurt`.
- IPv4: `172.29.0.32/26` on `Ethernet`.
- Local repo parent: `C:\Users\Geurt\CDS`.
- `ffs0`: `main@6647d47` (`docs: fix HP ProDesk seed identity`).
- `moos-kernel`: `master@b5935e0`.
- `moos-router`: `master@18212eb`.
- Go toolchain: `go1.26.3 windows/amd64`.
- `moos-kernel` tests/build: `go test ./...` passed and `moos-kernel.exe` rebuilt locally.
- Local kernel command used the corrected identity: `--seed --seed-user sam --seed-ws hpprodesk`.
- Local `/healthz`: `status=ok`, `ontology_version=3.16.1`, `t_day=193`, `log_len=5`.
- Active `moos.jsonl` contains `workstation:hpprodesk` and `kernel:hpprodesk.primary`; the earlier bad `hp-laptop` seed log was preserved as `moos.hp-laptop-seed-misfire.20260513-161015.jsonl`.
- Hp-laptop is reachable at `172.29.0.38`: kernel `:8000` reports `status=ok`, `ontology_version=3.16.1`, `t_day=193`, `log_len=1160`; router `:9000` reports `status=ok` and marks Z440 `192.168.1.11` down.

No branch was created for this update because the repo policy makes verified `ffs0` admin/readback packets direct-to-main work. No `moos-kernel` or `moos-router` source code changed, and no HG rewrites were applied.

## What Landed

The first bootstrap packet added the dry workstation inventory generator, test, and prompt. The later concrete-identity packet updated the shared config and handoff surface once the HP ProDesk reported back.

Recent `ffs0/main` commits in this arc:

- `8136b8a tools: add T193 HP Pro bootstrap packet`
- `aa4b18e docs: make ffs0 trunk-first admin repo`
- `6f46e80 chore: make ffs0 workspace portable`
- `0725b48 config: add HP ProDesk topology`
- `1904859 docs: wrap T193 HP ProDesk bootstrap`
- `6647d47 docs: fix HP ProDesk seed identity`

Files now carrying the HP ProDesk handoff:

- `dev/config/moos-federation.topology.json` includes `hpprodesk.primary`, router peer data, MCP server `moos-hpprodesk-primary`, and persona key `hpprodesk-vscode`.
- `dev/config/session-affordance-map.json` includes the `hpprodesk-vscode-bootstrap` session affordance entry.
- `dev/scripts/ops/Test-MoosFederation.ps1` recognizes `hpprodesk-vscode` and normalizes `DESKTOP-3FC7C3F` to `hpprodesk`.
- `.github/prompts/hppro-vscode-t193-bootstrap.prompt.md` remains the compatibility filename, but its contents now describe HP ProDesk, `$env:USERPROFILE\CDS`, and the concrete `hpprodesk` URNs.
- `dev/scripts/t193_workstation_inventory.jl` and its test now default to `hpprodesk` rather than the old `hppro` placeholder.

## Running-State Versus Diary Rule

This closeout follows the rule Sam clarified during the session: `running-state.md` is the hot hydration card, while `kb/moos-diary/` is the slower readable session packet.

Running-state should carry the mixed session/agent facts a fresh IDE must not miss: current hosts, kernels, sessions, actors, branches, commits, warnings, and next gate. It should not become the full narrative.

The diary wrapup carries the story: why the topology changed, how the workstation identity settled, what was validated, and what remains deliberately deferred. For normal verified `ffs0` admin packets, both travel together on `ffs0/main` rather than on a long-lived feature branch.

## Explicitly Not Done

- No HG rewrite batch was applied for HP ProDesk yet. The workstation, kernel, setup session, purpose, and occupant links remain planned until HP ProDesk proves local kernel health and Sam approves the batch.
- No secrets were copied through chat or committed. `.vscode/mcp.json` and `secrets/` remain local-only surfaces.
- No `moos-kernel` or `moos-router` code changed.
- Z440 was not treated as replaced. It remains the second historical workstation and should be reconciled when it is physically reachable again.
- No new `ffs0` branch was created for this closeout. `ffs0/main` is the correct target for verified private admin/control state.

## Validation

Validation for the `0725b48` config packet:

- `dev/config/*.json` parsed successfully.
- `dev/scripts/ops/Test-MoosFederation.ps1` parsed successfully with the PowerShell parser.
- `dev/scripts/tests/test_t193_workstation_inventory.jl` passed `18/18`.
- `git diff --check` passed.
- `ffs0` was clean and up to date with `origin/main` before this diary/running-state follow-up.

Post-wrapup HP ProDesk readback caught one concrete prompt bug: the kernel start example still used plain `--seed`, which would have defaulted `--seed-ws` to `hp-laptop`. The prompt now explicitly passes `--seed-user sam` and `--seed-ws hpprodesk`.

Validation for the HP ProDesk-side local readback:

- `ffs0` was reconciled to `main@6647d47`; the only prior local prompt edit was restored because the same fix was upstream.
- `moos-kernel` tests passed and `moos-kernel.exe` rebuilt locally.
- The local primary kernel started with `--seed-ws hpprodesk`, replayed 5 rewrites, and returned `/healthz` green.
- Active `moos.jsonl` was checked for bad `workstation:hp-laptop` / `kernel:hp-laptop` seed refs.
- Hp-laptop `172.29.0.38:8000` and router `172.29.0.38:9000` returned healthy readbacks.

Follow-up projection check confirmed hp-laptop's session pipeline is current enough to use as the HP ProDesk routine template: local runner result remains `warn`, 18 pass, 2 warn, 0 fail, with the known warnings on visual lens root coverage and T189 recommendation reconciliation. The HP ProDesk bootstrap prompt now includes the same state-readback and projection routine, and `run-session-pipeline.ps1` can recognize `session:sam.hpprodesk-setup` / `agent:vscode.hpprodesk.primary` once the reviewed HG setup batch exists.

## Next Moves

- Prepare a reviewed `moos-rewrite-envelope` batch for the HP ProDesk workstation/kernel/session/purpose/occupant topology.
- After Sam approves the batch, apply it to the intended receiving kernel and re-run persona/topology verification.
- Keep HP ProDesk to one primary kernel until the setup session is represented in HG and restart-stable.
- When back at the Z440, run the federation doctor and reconcile all three workstations together.
