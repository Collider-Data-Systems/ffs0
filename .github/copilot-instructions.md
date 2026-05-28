# ffs0 Repository Instructions

## Scope

Personal portable private workspace (`ffs0`). Runtime code lives in sibling repos (`moos-kernel`, `moos-router`). `moos-config` is legacy.

All three repos at `github.com/Collider-Data-Systems/*` since T=172.

## Running state

**Read `kb/superset/running-state.md` first.** Current T-day, active program, kernel state, personae seatings, key URNs.

Current T208 state: hp-laptop primary `192.168.1.14:8000` is live on `ontology_version=3.16.2`, `t_day=208`, with runtime readback at `log_len=1467`. Z440 primary/twins `192.168.1.13:{8000,8001,8002,8003}` are live on `ontology_version=3.16.2`, `t_day=208`, with log lengths `449/13/11/16`. `session:sam.governance` remains the hp-laptop governance/projection lane with folded occupant `agent:vscode.hp-laptop.copilot`; Z440's current VS Code/Copilot lead is `agent:vscode.hp-z440.primary` occupying `session:sam.z440-vscode-projection-lead` on `kernel:hp-z440.primary`. This does not activate Wolfram/Claude Code, Steinberger, Karpathy, Moos/Antigravity, Cowork, or `user:sam` as an apply actor. Keep source acquisition now has a real Workspace DWD/API path: T190-T208 raw notes and attachment metadata are staged review-only with `apply_ready=false`; do not emit raw-note HG rewrites until Sam reviews and chunks approved source material. WF07 `anchors/anchor` is declared and runtime-loaded; the T206 catch-up applied 22 Calendar event nodes, 22 session pins, and 22 WF07 source anchors. Z440 router `localhost:9000` is healthy, listens on `::`, and is reachable locally via `192.168.1.13:9000`; the router executable's two Public inbound `Block` rules were disabled and explicit allow rule `MOOS Router Z440 LAN TCP 9000` was added for `LocalSubnet`, so hp-laptop should retest direct LAN `:9000`. Local `http://192.168.1.13:9000/state/nodes` still times out after 12 seconds, so projection reads should keep using hp-laptop router `192.168.1.14:9000` until the router fanout/read path is fixed. HP ProDesk remains offline/non-blocking. (Sam's Keep notes recorded a future intent to eventually transition the Go runtime codebase to Rust).

VS Code is now an explicit agent surface. Treat pinned VS Code conversations, Copilot sessions, Claude Desktop, and Antigravity windows as S0 substrate that may need G-ingest later; do not assume chat UI state is durable HG truth until it is chunked or projected. Cloudflared may be locally running with metrics available while public tunnel egress to Cloudflare edge is degraded; distinguish tunnel/public endpoint failures from local kernel/router health.

For projection work, run the local pipeline before making claims about MVP status:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File dev\scripts\projections\run-session-pipeline.ps1
```

Outputs land under `tmp/projections/session_pipeline/`: session context pack, graph engineering reports, session-occasion DOT/SVG, temporal/calendar DOT/SVG, T189 recommendation DOT/SVG, Calendar time-fabric plan/report/write-result, recommendation HG plan/report, reconciliation report, surface context atlas JSON/Markdown, MVP gate, and `index.html` control surface. Latest hp-laptop pipeline baseline reports gate `pass`, 24 pass, 0 warn, 0 fail. Latest Z440 lead pipeline, run through hp-laptop router `192.168.1.14:9000` with explicit `SessionUrn=urn:moos:session:sam.z440-vscode-projection-lead` and `ActorUrn=urn:moos:agent:vscode.hp-z440.primary`, reports gate `warn`, 23 pass, 1 warn, 0 fail; the warning is dry T189 recommendation reconciliation with 43 pending Calendar candidates and is not an apply queue. The applied Calendar reconciliation baseline remains converged: grouped nodes 10/10, grouped safe relations 16/16, Calendar event nodes 22/22, Calendar session pins 22/22, Calendar WF07 anchors 22/22, deferred relations 0. The session-occasion lens admits existing WF20 `promotes/promoted-from`, WF19 pins, and WF07 source anchors; Calendar time-fabric planning locks to stored writer-result source URNs and live folded Calendar observations. The Keep stager accepts Takeout ZIP/folder/manual/API-normalized JSON sources and remains review-only with `apply_ready=false`. Cytoscape.js inspector tabs are present for session occasion, Calendar Time-Fabric, T189 recommendations, and Calendar scope. The dashboard includes F/G Relation Insights and Graphview Stack Notes with F/G node roles, WF relation-family labels, top-degree nodes, and renderer/library tradeoffs.

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
