# ffs0 Repository Instructions

## Scope

Personal portable private workspace (`ffs0`). Runtime code lives in sibling repos (`moos-kernel`, `moos-router`). `moos-config` is legacy.

All three repos at `github.com/Collider-Data-Systems/*` since T=172.

## Running state

**Read `kb/superset/running-state.md` first.** Current T-day, active program, kernel state, personae seatings, key URNs.

Current T194 hp-laptop state: kernel `hp-laptop.primary` is live on `ontology_version=3.16.1`, `t_day=194`, with the latest occupancy correction moving readback to `log_len=1192`. Router `localhost:9000` is healthy with hp-laptop up and Z440 currently down over LAN. `session:sam.governance` remains the hp-laptop governance/projection lane; its current VS Code/Copilot occupant is `agent:vscode.hp-laptop.copilot`, not the legacy `agent:claude-code.hp-laptop` unless Claude Code is explicitly restored. HP ProDesk has a local setup session proven at T193. The active working lane is the Keep/session/visual/Calendar/recommendation/atlas projection family; latest report is `kb/moos-diary/t194-vscode-agents-calendar-scope-and-session-staging-wrapup.md`.

VS Code is now an explicit agent surface. Treat pinned VS Code conversations, Copilot sessions, Claude Desktop, and Antigravity windows as S0 substrate that may need G-ingest later; do not assume chat UI state is durable HG truth until it is chunked or projected. On this hp-laptop window, Sam currently has two pinned VS Code conversations in the `ffs0` workspace: T193 and T186.

For projection work, run the local pipeline before making claims about MVP status:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File dev\scripts\projections\run-session-pipeline.ps1
```

Outputs land under `tmp/projections/session_pipeline/`: session context pack, graph engineering reports, session-occasion DOT/SVG, temporal/calendar DOT/SVG, T189 recommendation DOT/SVG, Calendar time-fabric plan/report/write-result, recommendation HG plan/report, reconciliation report, surface context atlas JSON/Markdown, MVP gate, and `index.html` control surface. Current expected gate is `warn` with 22 pass, 2 warn, 0 fail after the T194 agent-neighborhood/F-G insight rerun; remaining warnings are visual lens root coverage and T189 recommendation reconciliation. Cytoscape.js inspector tabs are present for session occasion, Calendar Time-Fabric, T189 recommendations, and Calendar scope. All four graph artifacts and DOT lenses include the current context agent `agent:vscode.hp-laptop.copilot`; the dashboard includes F/G Relation Insights and Graphview Stack Notes with F/G node roles, WF relation-family labels, top-degree nodes, and renderer/library tradeoffs.

Kernel/application split: `moos-kernel` is the OS-facing runtime function program; `moos-router` is federation routing; application domains such as `my-tiny-data-collider` are HG groups/program families that run through the kernels and may project to websites, DNS, Calendar, GitHub, Workspace, and servers. Keep those entities/codebases separate.

Round-level context from prior rounds lives under `dev/reference/research-archive/` — retrieve explicitly when needed. `kb/research/` is reserved for live doctrine only (T=173 pivot).

## Working style

Small, safe, focused edits. Preserve folder structure unless change is requested.

Avoid process-heavy documents unless explicitly requested. `.md` accumulation is consciously ended as of T=173 — conversations reify into HG as `knowledge_item` nodes via the chunker skill, not new scratch files under `kb/research/`.

## Domain knowledge

Invoke `moos-session-context-projection` for session context packs, IDE/harness projection, local MVP gate checks, or graph visualization/analysis of newly added HG nodes.
Invoke the `moos-domain-expert` skill for categorical/mathematical reasoning.
Invoke `moos-rewrite-envelope` for envelope authoring (post-§M11 actor discipline: agent-default, kernel-for-ontology-governed, never user:sam in Apply path).
Invoke `moos-tooling-dx` for VS Code, Claude Desktop, Antigravity, MCP, task-runner, prompt, skill, and workstation attach work.

## Safety

Never commit secret values. `secrets/` is local-first. Destructive actions are explicit.
