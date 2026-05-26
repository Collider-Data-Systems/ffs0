# ffs0 Repository Instructions

## Scope

Personal portable private workspace (`ffs0`). Runtime code lives in sibling repos (`moos-kernel`, `moos-router`). `moos-config` is legacy.

All three repos at `github.com/Collider-Data-Systems/*` since T=172.

## Running state

**Read `kb/superset/running-state.md` first.** Current T-day, active program, kernel state, personae seatings, key URNs.

Current T206 hp-laptop state: kernel `hp-laptop.primary` is live on `ontology_version=3.16.2`, `t_day=206`, with runtime readback at `log_len=1467`. Router `localhost:9000` is healthy with hp-laptop up and Z440 currently down over LAN. `session:sam.governance` remains the hp-laptop governance/projection lane; its current VS Code/Copilot occupant is `agent:vscode.hp-laptop.copilot`, not the legacy `agent:claude-code.hp-laptop` unless Claude Code is explicitly restored. Five T200+ sessions remain scoped-idle and have no occupants until reviewed seating: calendar-readback, project-bridge, S0-staging, application-surface-map, and Z440-rejoin. HP ProDesk has a local setup session proven at T193. The active working lane is the Keep/session/visual/Calendar/recommendation/atlas projection family. T195-T206 Keep/loose-thought ingest is intentionally postponed until Sam structures and approves the source notes; do not ingest raw Keep notes or emit HG rewrites from trace/readback work. WF07 `anchors/anchor` is now declared and runtime-loaded; the T206 catch-up applied 22 Calendar event nodes, 22 session pins, and 22 WF07 source anchors. (Sam's Keep notes recorded a future intent to eventually transition the Go runtime codebase to Rust).

VS Code is now an explicit agent surface. Treat pinned VS Code conversations, Copilot sessions, Claude Desktop, and Antigravity windows as S0 substrate that may need G-ingest later; do not assume chat UI state is durable HG truth until it is chunked or projected. Cloudflared may be locally running with metrics available while public tunnel egress to Cloudflare edge is degraded; distinguish tunnel/public endpoint failures from local kernel/router health.

For projection work, run the local pipeline before making claims about MVP status:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File dev\scripts\projections\run-session-pipeline.ps1
```

Outputs land under `tmp/projections/session_pipeline/`: session context pack, graph engineering reports, session-occasion DOT/SVG, temporal/calendar DOT/SVG, T189 recommendation DOT/SVG, Calendar time-fabric plan/report/write-result, recommendation HG plan/report, reconciliation report, surface context atlas JSON/Markdown, MVP gate, and `index.html` control surface. Latest T206 local pipeline readback after the visual-root sprint reports gate `pass`, 24 pass, 0 warn, 0 fail. Recommendation reconciliation is converged: grouped nodes 10/10, grouped safe relations 16/16, Calendar event nodes 22/22, Calendar session pins 22/22, Calendar WF07 anchors 22/22, deferred relations 0. The session-occasion lens now admits existing WF20 `promotes/promoted-from`, WF19 pins, and WF07 source anchors; Calendar time-fabric planning locks to the stored writer-result source URNs when present so widened visual context does not create new G-readback candidates. Cytoscape.js inspector tabs are present for session occasion, Calendar Time-Fabric, T189 recommendations, and Calendar scope. All four graph artifacts and DOT lenses include the current context agent `agent:vscode.hp-laptop.copilot`; the dashboard includes F/G Relation Insights and Graphview Stack Notes with F/G node roles, WF relation-family labels, top-degree nodes, and renderer/library tradeoffs.

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
