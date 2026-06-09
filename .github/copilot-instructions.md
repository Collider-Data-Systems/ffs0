# ffs0 Repository Instructions

> **Mirror of `ffs0/AGENTS.md`** (the project SOT) · manual · source: `ffs0/AGENTS.md` · don't edit except emergency de-rot. Canonical cross-tool orientation lives in `AGENTS.md`; this file holds Copilot-specific skill/prompt routing + the current running-state pointer. *(Phase 1, branch `cowork-z440/config-overhaul-agents-sot`: header added; duplication-trim is a Phase-2 follow-up after ffs0#58 review.)*

## Scope

Personal portable private workspace (`ffs0`). Runtime code lives in sibling repos (`moos-kernel`, `moos-router`). `moos-config` is legacy.

All three repos at `github.com/Collider-Data-Systems/*` since T=172.

## Running state

**Read `kb/superset/running-state.md` first.** Current T-day, active program, kernel state, personae seatings, key URNs.

Current T=219 state: **Tailscale mesh live** across both boxes — Z440 (`desktop-42d00rd`) `100.82.243.13` (Tailscale, permanent) / `192.168.1.15` (LAN); hp-laptop (`lap-sam`) `100.106.220.58` (Tailscale) / `192.168.1.10` (LAN). Both kernels on `ontology_version=3.16.2`, `t_day=219`: Z440 primary `localhost:8000` (log_len 449) + twins `:8001-8003`; hp-laptop primary (log_len 1471). Federation is **bidirectional and green** — the Z440 router (`localhost:9000` / Tailscale `100.82.243.13:9000`) fans in hp-laptop via Tailscale, and WF16 cross-box peer cascade is verified both directions (DHCP-drift brittleness retired). `session:sam.governance` remains the hp-laptop governance lane (occupant `agent:vscode.hp-laptop.copilot`); Z440's VS Code/Copilot lead is `agent:vscode.hp-z440.primary` on `session:sam.z440-vscode-projection-lead`. This does not activate Wolfram, Steinberger, Karpathy, Moos/Antigravity, Cowork, or `user:sam` as an apply actor. Keep source acquisition is staged review-only (`apply_ready=false`); no raw-note HG rewrites until Sam reviews and chunks approved material. **4.0 manifold paradigm (T=219):** D1/D2/D3/D6 (manifold · session→workspace · persona=Φ(purpose) · kernel→instance) **Sam-ratified**; D4/D5/D7/D8 (presents-as · channel.kind · surface layer · realizes) **team-endorsed**. Alias-first prose only — no ontology/URN change authorized; ontology bump pending, developed parallel to current code. Canonical delta table: `ffs0/AGENTS.md`. HP ProDesk offline/non-blocking.

VS Code is now an explicit agent surface. Treat pinned VS Code conversations, Copilot sessions, Claude Desktop, and Antigravity windows as S0 substrate that may need G-ingest later; do not assume chat UI state is durable HG truth until it is chunked or projected. Cloudflared may be locally running with metrics available while public tunnel egress to Cloudflare edge is degraded; distinguish tunnel/public endpoint failures from local kernel/router health.

For projection work, run the local pipeline before making claims about MVP status:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File dev\scripts\projections\run-session-pipeline.ps1
```

Outputs land under `tmp/projections/session_pipeline/`: session context pack, graph engineering reports, session-occasion DOT/SVG, temporal/calendar DOT/SVG, T189 recommendation DOT/SVG, Calendar time-fabric plan/report/write-result, recommendation HG plan/report, reconciliation report, surface context atlas JSON/Markdown, MVP gate, and `index.html` control surface. Latest hp-laptop pipeline baseline reports gate `pass`, 24 pass, 0 warn, 0 fail. Latest Z440 lead pipeline runs against the **local Z440 router** `localhost:9000` with explicit `SessionUrn=urn:moos:session:sam.z440-vscode-projection-lead` and `ActorUrn=urn:moos:agent:vscode.hp-z440.primary` (the prior `.14`-router workaround is retired since the T=219 IP/Tailscale fix), reports gate `warn`, 23 pass, 1 warn, 0 fail; the warning is dry T189 recommendation reconciliation with 43 pending Calendar candidates and is not an apply queue. The applied Calendar reconciliation baseline remains converged: grouped nodes 10/10, grouped safe relations 16/16, Calendar event nodes 22/22, Calendar session pins 22/22, Calendar WF07 anchors 22/22, deferred relations 0. The session-occasion lens admits existing WF20 `promotes/promoted-from`, WF19 pins, and WF07 source anchors; Calendar time-fabric planning locks to stored writer-result source URNs and live folded Calendar observations. The Keep stager accepts Takeout ZIP/folder/manual/API-normalized JSON sources and remains review-only with `apply_ready=false`. Cytoscape.js inspector tabs are present for session occasion, Calendar Time-Fabric, T189 recommendations, and Calendar scope. The dashboard includes F/G Relation Insights and Graphview Stack Notes with F/G node roles, WF relation-family labels, top-degree nodes, and renderer/library tradeoffs.

Kernel/application split: `moos-kernel` is the OS-facing runtime function program; `moos-router` is federation routing; application domains such as `my-tiny-data-collider` are HG groups/program families that run through the kernels and may project to websites, DNS, Calendar, GitHub, Workspace, and servers. Keep those entities/codebases separate.

Round-level context from prior rounds lives under `dev/reference/research-archive/` — retrieve explicitly when needed. `kb/research/` is reserved for live doctrine only (T=173 pivot).

## Working style

Small, safe, focused edits. Preserve folder structure unless change is requested.

Avoid process-heavy documents unless explicitly requested. `.md` accumulation is consciously ended as of T=173 — conversations reify into HG as `knowledge_item` nodes via the chunker skill, not new scratch files under `kb/research/`.

## Domain knowledge

Invoke `moos-session-context-projection` for session context packs, IDE/harness projection, local MVP gate checks, or graph visualization/analysis of newly added HG nodes.
Invoke `moos-categorical-research` for categorical/HDC/mathematical reasoning (Karpathy lane).
Invoke `moos-rewrite-envelope` for envelope authoring (post-§M11 actor discipline: agent-default, kernel-for-ontology-governed, never user:sam in Apply path).
Invoke `moos-tooling-dx` for VS Code, Claude Desktop, Antigravity, MCP, task-runner, prompt, skill, and workstation attach work.
The full skill set (13) lives in `dev/claude-skills/` (synced to `~/.claude/skills/`): also `moos-workstation-operator`, `moos-state-readback`, `moos-round-close`, `moos-cowork-readback`, `moos-workspace-ingest`, `moos-running-state-validator`, `moos-cross-persona-audit`, `moos-github-project-bridge`, `moos-multimodal-ingest`.

## Safety

Never commit secret values. `secrets/` is local-first. Destructive actions are explicit.
