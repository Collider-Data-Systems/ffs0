# AGENTS.md — mo:os project (ffs0)

> **Authored projection SOT for tools.** Cross-tool brief read natively by Copilot, Cursor, Codex, Gemini/Antigravity. Claude reads it via `CLAUDE.md` `@import`.
> **Status: Phase-1 draft (T=219), branch `cowork-z440/config-overhaul-agents-sot`, under team review on ffs0#58.** Owners place follow-ups; do not treat as final until merged.

## SOT hierarchy (read this first)
```
HG folded state · ontology.json · live /healthz readback   → SEMANTIC SOT (truth; state is derived from the log)
THIS FILE  (ffs0/AGENTS.md, + local root AGENTS.md)         → authored PROJECTION SOT for tools (a hand-written F-image, until generated)
CLAUDE.md ×2 · .github/copilot-instructions.md · .agent/    → thin mirrors / tool-deltas only
```
A Markdown file is **never** the final truth. HG is. This file is the best current F-projection of the project brief until `moos-config-projection` (Phase 4) generates it. **Live runtime truth: `kb/superset/running-state.md` (read it first for round-to-round state).**

## The rule (non-negotiable)
Four rewrites only: **ADD · LINK · MUTATE · UNLINK**. **Log is truth. State is derived.** Nodes don't call things; relations don't carry messages; side effects only at actuator leaves via channels.
Nomenclature — use: node · relation · rewrite · property · operad · port · rewrite_category WF01..WF21 · `_urn`/`_urns`. Never: edge · wire · field · mutation · schema · association · binding · `_ref`. *(Full do/never table in `ffs0/CLAUDE.md`.)*

## Conversations are S0 (the F⊣G pipeline)
IDE/agent conversations are **S0 substrate** — the raw rewriting layer that emits work, NOT data/code/doctrine. Reification path:
```
S0 conversation → chunker (moos-workspace-ingest) → knowledge_item → pinned to workspace (G-ingest, F⊣G adjunction)
  → programs/tasks delegate to tools/sub-agents/personae → F projects back out to Calendar/Git/social/network/IDE surfaces
```
F (project): `run-session-pipeline.ps1` + skill `moos-session-context-projection`. G (ingest): skills `moos-workspace-ingest` (text) / `moos-multimodal-ingest` (binary). Endgame: keep everything in HG + jsonl in memory; these `.md` files are a temporary crutch that Phase 4 makes *generated*.

## Seats — agent × workspace × instance × surface  ⟨projection-ready: Phase-4 moos-config-projection pilot⟩
> The F-image of `channel`+`agent` nodes — lowest F⊣G unit defect, highest duplication payoff → first artifact `moos-config-projection` will generate. **4.0 aliases shown; URNs stay canonical (see Gate).**

| Persona (=Φ(purpose), D3) | Agent (principal) | Workspace ⟵`session` (D2) | Instance ⟵`kernel` (D6) | Surface / IDE-instance (D7) | MCP |
|---|---|---|---|---|---|
| Wolfram | `claude-code.hp-z440` | `sam.kernel-proper` | `hp-z440.primary` :8000 | Claude Code pane · Z440 | :8080 |
| Steinberger | `vscode.hp-z440.menno` | `sam.steinberger-seat` | `hp-z440.menno` :8001 *(emits :8000 pre-§M9)* | VS Code · Z440 | :8080 *(opens-on :9001)* |
| Karpathy | `vscode.hp-z440.lola` | `sam.karpathy-seat` | `hp-z440.lola` :8002 *(emits :8000 pre-§M9)* | VS Code · Z440 | :8080 *(opens-on :9002)* |
| Moos / AG-Z440 | `antigravity.hp-z440` | `sam.moos-diary` | `hp-z440.primary` :8000 | Antigravity · Z440 | :8080 |
| Cowork-Z440 | `claude-cowork.hp-z440` | `sam.z440-cowork-workspace` | `hp-z440.primary` :8000 | Claude Code/Cowork pane · Z440 | :8080 |
| Z440 VS Code lead | `vscode.hp-z440.primary` | `sam.z440-vscode-projection-lead` *(+ `sam.z440-primary-vscode-setup`)* | `hp-z440.primary` :8000 | VS Code/Copilot pane · Z440 | :8080 |
| Guido (governance) | `vscode.hp-laptop.copilot` | `sam.governance` | `hp-laptop.primary` :8000 | VS Code/Copilot · laptop | :8080 |
| Cowork-laptop | `claude-cowork.hp-laptop` | `sam.laptop-cowork-workspace` | `hp-laptop.primary` :8000 | Claude Code · laptop | :8080 |
| AG-laptop | `antigravity.hp-laptop` | `sam.laptop-moos-diary` | `hp-laptop.primary` :8000 | Antigravity · laptop | :8080 |
| HP ProDesk | `vscode.hpprodesk.primary` | `sam.hpprodesk-setup` | `hpprodesk.primary` :8000 | VS Code · ProDesk | :8080 *(offline/non-blocking)* |

All URN prefixes are `urn:moos:<type>:<short>`. Emit discipline: Z440 personae emit to `hp-z440.primary` :8000 / MCP :8080 until §M9 twin-sync; multi-workspace agents (Wolfram, Cowork) set `session_urn` explicitly (`session_urn` stays the canonical key per the Gate). Twins (`menno`/`lola`) carry `opens-on` topology intent (HTTP :8001/:8002, MCP :9001/:9002), not state replication. `sam.mvp-delivery` (hp-z440.primary) is a **dormant, occupant-less lane** (`has-occupant` UNLINKed T=219) — intentionally omitted from the active table.

## Network / federation (T=219, Tailscale mesh)
Z440 (`desktop-42d00rd`) `100.82.243.13` (Tailscale) / `192.168.1.15` (LAN). hp-laptop (`lap-sam`) `100.106.220.58` (Tailscale) / `192.168.1.10` (LAN). Federation router fans in cross-box over Tailscale (DHCP-drift retired). Kernels `:8000` (+Z440 twins `:8001-8003`), MCP `:8080` (Z440 twins' opens-on MCP `:9001/:9002/:9003`), router `:9000`. Live detail → `dev/config/moos-federation.topology.json`.

## Relational spine (4.0 vocabulary; alias-first)
```
user/group  —WF02 delegates-to→  agent          (authority/delegation)
workspace(session)  —WF19 has-occupant→  agent   (liveness/occupancy)
workspace(session)  —WF19 opens-on→  instance(kernel)   (topology intent)
agent  —presents-as→  persona (= Φ(purpose))     (D4; presentation, NOT authority)
surface  —realizes→  channel / workspace          (D8; observed-first, S0 substrate)
```
A user/group **delegates** an agent; an agent **occupies** a workspace; an agent **may present-as** a persona derived from purpose; IDE/harness panes/windows/tabs are **S0 surfaces** that project and evidence the workspace — never authority principals, never durable truth until G-ingested.

## 4.0 vocabulary (manifold paradigm) — ALIAS-FIRST, GATED
First mention dual-names: `workspace (session)`, `instance (kernel)`; thereafter the 4.0 term where context is clear.
**GATE: this is prose only. URNs, runtime type IDs, and relation semantics stay `session`/`kernel`/etc. until the reviewed 4.0 (ontology bump) / 4.0.x (hard URN rewrite) gates. This file authorizes no ontology or URN change.**

| Δ | Change | Status |
|---|---|---|
| D1 | `manifold` — new top category (application/domain grouping; colimit of branch-episodes) | ✅ Sam-ratified |
| D2 | `session` → `workspace` (alias-first) | ✅ Sam-ratified |
| D3 | `persona = Φ(purpose)` as a `derivation`, not authority | ✅ Sam-ratified |
| D4 | `presents-as` (agent↔persona relation) | endorsed (#57); implied by D3 |
| D5 | `channel.kind` expansion (infra: domain/dns-zone/cloudflare-*/registrar; surface: workstation-surface/virtual-desktop/window/tab-group/browser-tab/harness-pane) | endorsed (T216 draft) |
| D6 | `kernel` → `instance` (`instance := fold(log)`); alias in 4.0, hard ~59-site URN rewrite gated to 4.0.x | ✅ Sam-ratified |
| D7 | workstation surface layer — S0 projection substrate (desktops/windows/panes/tabs), observed-not-authored | endorsed (#57) |
| D8 | `realizes / realized-by` (surface↔channel/workspace), observed-first | endorsed (#57) |

`my-tiny-data-collider` is the worked example manifold (4 domains + Cloudflare/Workspace/GitHub/tunnel surfaces). 4.0 is developed **parallel** to current code; **current code = living spec to 4.0.**

## Skills (capabilities; model-invoked by description) — `dev/claude-skills/` (synced to `~/.claude/skills/`)
Authoring/ops: `moos-rewrite-envelope` · `moos-state-readback` · `moos-round-close` · `moos-running-state-validator` · `moos-cross-persona-audit` · `moos-workstation-operator`.
Projection/ingest: `moos-session-context-projection` (F) · `moos-workspace-ingest` (G text) · `moos-multimodal-ingest` (G binary) · `moos-github-project-bridge`.
Seat lanes: `moos-categorical-research` (Karpathy) · `moos-tooling-dx` (Steinberger) · `moos-cowork-readback` (Cowork).
Detail lives in each `SKILL.md` — do not restate here.

## Repos & branching
- `ffs0` (this repo) = private control/research workspace + KB. `moos-kernel` (Go runtime), `moos-router` (federation). `moos-config` = LEGACY, do not use. All at `github.com/Collider-Data-Systems/*`.
- **Trunk-first on `main`** for verified single-lane/non-colliding work (T208). **Branch + merge-with-provenance** for collision-prone multi-lane work (T218: `branch=F(session)`, `merge=G(branch)`; trailer `authored-by: <agent-urn> / <session-urn> / <purpose-slug>`). Runtime code branches `feat/<purpose-slug>` in `moos-kernel`/`moos-router`.

## Safety / boundaries
Never commit `secrets/` values, API tokens, or `.vscode/mcp.json`. Mutations (commit/push, merge, DNS/Cloudflare/tunnel/Access, Calendar/Workspace writes, HG apply) are explicit boundary acts — surface before doing, never as a side effect of readback. Do not emit HG rewrites, seat scoped-idle workspaces, or apply raw Keep notes from readback. IDE/UI/pinned-chat state is not durable HG truth.

## Tool-mirror map (this file is the source)
- `CLAUDE.md` (ffs0 + root) — `@import` this + Claude-specific deltas only.
- `.github/copilot-instructions.md` — thin mirror + Copilot-specific skill/prompt routing.
- `.agent/` (Antigravity, Phase 3, path TBD via live readback) — AG surface mechanics only.
Mirrors carry a header: source · manual/generated · source-commit · "don't edit except emergency de-rot." Duplication-trim of mirror bodies is a Phase-2 follow-up after this text stabilizes (do not gut bodies before the mirror proves readable).

---
*Phase-1 draft, Cowork-Z440. Review on ffs0#58.*
authored-by: agent:claude-cowork.hp-z440 / session:sam.z440-cowork-workspace / config-overhaul
