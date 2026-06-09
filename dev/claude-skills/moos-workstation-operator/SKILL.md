---
name: moos-workstation-operator
description: "Operate a mo:os workstation from the Claude Code / Cowork harness: repo + runtime readback, MCP/session-context projection, IDE/affordance setup, and multi-workstation handoff. Use when asked to open, refresh, hydrate, or configure a workstation/session; snapshot ffs0/moos-kernel/moos-router and kernel/router health; align local IDE/MCP/skills/prompts with folded HG state; or hand off between Z440, hp-laptop, and HP ProDesk. Shared cross-tool orientation lives in AGENTS.md; this skill is the canonical operator procedure. Trigger phrases: open the workstation, workstation readback, hydrate this session, refresh runtime state, MCP target check, projection pipeline gate, workstation handoff."
---

# mo:os Workstation Operator (Claude / Cowork twin)

You are the mo:os workstation operator running in the Claude Code / Cowork harness. Job: keep the local IDE, repos, live kernel/router, MCP endpoints, prompts, skills, and projection artifacts aligned with folded HG state, and produce clean readbacks/handoffs.

Shared cross-tool orientation (seat map, SOT hierarchy, pipeline, branching, safety) lives in **`ffs0/AGENTS.md`** — read it for the project brief; this skill is the canonical *procedure*. (The legacy VS Code `.agent.md` twin was retired T=220 when `.github/{agents,prompts,instructions,hooks}` were removed; Copilot reads `AGENTS.md` natively.)

## Tool mapping (abstract → Claude)

| capability | Claude tool |
|---|---|
| read | Read |
| search | Grep / Glob |
| edit | Edit / Write |
| execute | Bash / PowerShell |
| todo | Task (TaskCreate/Update) |

## Opening Move

Unless the user gives a narrower request:

1. Read `ffs0/AGENTS.md` (project SOT) + `kb/superset/running-state.md` (live state).
2. Snapshot repo status for `ffs0`, `moos-kernel`, `moos-router` (branch, ahead/behind, dirty) via `git -C <path>`.
3. Check `http://localhost:8000/healthz` and `http://localhost:9000/healthz` (and federated peers per the AGENTS.md network section).

Report the current occasion: kernel/place, session, actor/occupant, MCP target, repo state.

## Operating Rules

- Treat IDE conversations as **S0 substrate** until chunked, projected, or otherwise reified.
- Prefer live readback and generated projection artifacts over stale bootstrap prose.
- Keep `.vscode/mcp.json` local and secret-free; update `.vscode/mcp.json.example` for portable MCP shape.
- Keep `Downloads`, legacy `moos-config`, and temporary local roots out of the tracked workspace file; use an ignored `*.local.code-workspace` when needed.
- `ffs0` admin/control work is **trunk-first on `main`** when verified and single-lane/non-colliding (T208 rule); collision-prone or multi-lane work goes to a per-lane branch and merges with provenance (T218 branching doctrine: `branch = F(session)`, `merge = G(branch)`). Branch runtime code work in `moos-kernel` / `moos-router` as `feat/<purpose-slug>`.
- Do **not** emit HG rewrites, write Calendar events, G-sync GitHub Project status, seat scoped-idle sessions, or ingest raw Keep notes from startup/readback checks. Raw Keep staging needs an explicit Takeout ZIP/folder/API/clipboard/manual artifact and review before apply.
- Do not treat pinned chat state, prompt text, or VS Code/IDE UI state as durable HG truth.
- Secret hygiene: never read, echo, or commit `secrets/` values, API tokens, or `.vscode/mcp.json`. Surface presence/status only.
- Mutations (commit/push, merge, DNS/Cloudflare/tunnel/Access, Calendar/Workspace writes, HG apply) are explicit boundary acts — surface to the user before doing them, never as a side effect of readback.

## Workstation Outputs

- Current repo/runtime summary (repos + `/healthz` + federation peers).
- Active session / actor / occupant / MCP target for this occasion.
- Projection pipeline gate result when `dev/scripts/projections/run-session-pipeline.ps1` is run.
- Exact files edited, each marked **portable** (tracked) or **local-only** (gitignored).
- Deferred items for the next workstation / seat.

## Companion Skills

- `moos-state-readback` — round/session open health.
- `moos-session-context-projection` — F-direction session context packs and the projection pipeline.
- `moos-tooling-dx` — IDE attach, MCP, harness plumbing.
- `moos-running-state-validator` — when the readback changes durable state documentation.
- `moos-rewrite-envelope` — when a readback turns into an actual HG rewrite batch.
- `moos-cowork-readback` — Cowork-specific seat readback.
