# AGENTS.md — mo:os project (ffs0)

> **Authored projection SOT for tools.** Cross-tool brief read natively by Copilot, Cursor, Codex, Gemini/Antigravity. Claude reads it via `CLAUDE.md` `@import`.
> **Status: Phases 1–4 COMPLETE (#58 closed T=244+).** Phase-1 approved on ffs0#58 (PR #59); Phase-2 mirror trim + `.claude/rules/` live; Phase-3 Antigravity canary proven; Phase-4 `moos-config-projection` generates the seat table below (`--mode check` = blocking drift gate at round-close step 0).

## SOT hierarchy (read this first)
```
HG folded state · ontology.json · live /healthz readback   → SEMANTIC SOT (truth; state is derived from the log)
THIS FILE  (`AGENTS.md`, repo root; the local fleet `AGENTS.md` is one level up, outside the repo)  → authored PROJECTION SOT for tools (an F-image; the seat table is machine-generated, the prose is authored)
CLAUDE.md ×2 · .github/copilot-instructions.md · ANTIGRAVITY.md · .claude/rules/    → thin mirrors / tool-deltas only
```
A Markdown file is **never** the final truth. HG is. This file is the best current F-projection of the project brief; `moos-config-projection` (Phase 4, landed) already generates the seat table — the remaining prose is authored. **Live runtime truth: `kb/superset/running-state.md` (read it first for round-to-round state).**

## The rule (non-negotiable)
Four rewrites only: **ADD · LINK · MUTATE · UNLINK**. **Log is truth. State is derived.** Nodes don't call things; relations don't carry messages; side effects only at actuator leaves via channels.
Nomenclature — use: node · relation · rewrite · property · operad · port · rewrite_category WF01..WF21 · `_urn`/`_urns`. Never: edge · wire · field · mutation · schema · association · binding · `_ref` · (for interaction nodes) transition/event/message. *(Authoritative vocabulary do/never block: `kb/superset/ontology.json`.)*

## Conversations are S0 (the F⊣G pipeline)
IDE/agent conversations are **S0 substrate** — the raw rewriting layer that emits work, NOT data/code/doctrine. Reification path:
```
S0 conversation → chunker (moos-workspace-ingest) → knowledge_item → pinned to workspace (G-ingest, F⊣G adjunction)
  → programs/tasks delegate to tools/sub-agents/personae → F projects back out to Calendar/Git/social/network/IDE surfaces
```
F (project): `run-session-pipeline.ps1` + skill `moos-session-context-projection`. G (ingest): skills `moos-workspace-ingest` (text, WF12 provides-kb) / `moos-multimodal-ingest` (binary). Endgame: keep everything in HG + jsonl in memory; these `.md` files are a temporary crutch being made *generated* piecewise (Phase 4 landed for the seat table; prose is next).

## Design-doc discipline (`dev/design/**`)
Relation-first, rewrite-first. No OOP framing (no objects-with-payload, no static UML associations). Distinguish **operad** (admissible grammar / valid composition) from **instance** (realized topology + rewrite log). All state change is ADD/LINK/MUTATE/UNLINK — nothing else. Relations are topology (LINK results); rewrite_categories WF01–WF21 are op-families — don't conflate. Properties are typed/governed, never free-form payloads, never duplicate topology. Output: concise conclusions; **mark conjectures as conjectures** (don't assert unproven categorical claims as settled); open questions as 1–2 bullets. Authoritative refs: `running-state.md` + `ontology.json`.

## Seats — agent × workspace × engine × surface  ⟨GENERATED — Phase-4 moos-config-projection, landed⟩
> The F-image of `channel`+`agent` nodes — the first Phase-4 generated artifact: `config_projection.py --mode write` folds it from router fan-in `/state` has-occupant relations + seat-display config; `--mode check` is the blocking drift gate at round-close step 0. Never hand-edit the fenced region. **4.0 aliases shown; URNs stay canonical (see Gate). If this table and live `/healthz`+HG readback disagree, the readback wins — re-read, don't force the table (it is an authored projection, not operational truth).**

<!-- BEGIN GENERATED: moos-config-projection seat-table v1 (source: HG /state has-occupant via router fan-in; persona/surface/mcp = seat-display config; do not hand-edit — regenerate with --mode write) -->
| Persona (=Φ(purpose), D3·config) | Agent (HG principal) | Workspace ⟵`session` (HG·D2) | Engine ⟵`kernel` (HG opens-on·D6) | Surface / IDE-instance (D7·config) | MCP (config) |
|---|---|---|---|---|---|
| Wolfram | `claude-code.hp-z440` | `sam.kernel-proper` | `hp-z440.primary` :8000 | Claude Code · Z440 (desktop 2) · `moos-kernel` | moos-primary |
| Moos / AG-Z440 | `antigravity.hp-z440` | `sam.moos-diary` | `hp-z440.primary` :8000 | Antigravity · Z440 (desktop 5) · `ffs0.code-workspace` | moos-primary |
| Zappa | `claude-cowork.hp-z440` | `sam.z440-cowork-workspace` | `hp-z440.primary` :8000 | Claude Code / Cowork pane · Z440 · `ffs0.code-workspace` | moos-primary |
| Z440 VS Code lead | `vscode.hp-z440.primary` | `sam.z440-primary-vscode-setup` | `hp-z440.primary` :8000 | VS Code/Copilot pane · Z440 · `ffs0.code-workspace` | moos-primary |
| Z440 VS Code lead | `vscode.hp-z440.primary` | `sam.z440-vscode-projection-lead` | `hp-z440.primary` :8000 | VS Code/Copilot pane · Z440 · `ffs0.code-workspace` | moos-primary |
| Steinberger | `vscode.hp-z440.menno` | `sam.steinberger-seat` | `hp-z440.menno` :8001 *(emits `hp-z440.primary` pre-§M9)* | VS Code · Z440 (desktop 3) · `moos-router` | moos-primary *(opens-on `moos-menno`)* |
| Karpathy | `vscode.hp-z440.lola` | `sam.karpathy-seat` | `hp-z440.lola` :8002 *(emits `hp-z440.primary` pre-§M9)* | VS Code · Z440 (desktop 4) · `ffs0.code-workspace` | moos-primary *(opens-on `moos-lola`)* |
| John Lydon (governance) | `claude-cowork.hp-laptop` | `sam.governance` | `hp-laptop.primary` :8000 | Claude Desktop / Cowork · hp-laptop · `ffs0.code-workspace` | moos-hp-laptop-primary |
| John Lydon (governance) | `claude-cowork.hp-laptop` | `sam.laptop-cowork-workspace` | `hp-laptop.primary` :8000 | Claude Desktop / Cowork · hp-laptop · `ffs0.code-workspace` | moos-hp-laptop-primary |
| AG-laptop | `antigravity.hp-laptop` | `sam.laptop-moos-diary` | `hp-laptop.primary` :8000 | Antigravity · hp-laptop · `ffs0.code-workspace` | moos-hp-laptop-primary |
| Guido (laptop VS Code lead) | `vscode.hp-laptop.copilot` | `sam.laptop-vscode-lead` | `hp-laptop.primary` :8000 | VS Code / Copilot · hp-laptop · `ffs0.code-workspace` | moos-hp-laptop-primary |
| HP ProDesk | `vscode.hpprodesk.primary` | `sam.hpprodesk-setup` | `hpprodesk.primary` :8000 | VS Code · ProDesk · `ffs0.code-workspace` | moos-hpprodesk-primary |
<!-- END GENERATED: moos-config-projection seat-table -->

All URN prefixes are `urn:moos:<type>:<short>`. Emit discipline: Z440 personae emit to `hp-z440.primary` :8000 / MCP :8080 until §M9 twin-sync; multi-workspace agents (Wolfram `claude-code.hp-z440`, Zappa `claude-cowork.hp-z440`, John Lydon `claude-cowork.hp-laptop` — governance + curation since the T247 split) set `session_urn` explicitly (`session_urn` stays the canonical key per the Gate). Twins (`menno`/`lola`) carry `opens-on` topology intent (HTTP :8001/:8002, MCP :9001/:9002), not state replication. `sam.mvp-delivery` (hp-z440.primary) is a **dormant, occupant-less lane** (`has-occupant` UNLINKed T=219) — intentionally omitted from the active table.

## Network / federation (T=219 Tailscale mesh · T=226 ProDesk rejoin)
Z440 (`desktop-42d00rd`) `100.82.243.13` (Tailscale) / `192.168.1.15` (LAN). hp-laptop (`lap-sam`) `100.106.220.58` (Tailscale) / `192.168.1.10` (LAN). HP ProDesk (`desktop-3fc7c3f`) `100.87.28.95` (Tailscale; mostly powered off — expect Doctor-mode drift flags while down). Federation router fans in cross-box over Tailscale (DHCP-drift retired). Kernels `:8000` (+Z440 twins `:8001-8003`), MCP `:8080` (Z440 twins' opens-on MCP `:9001/:9002/:9003`), router `:9000`. Live detail → `dev/config/moos-federation.topology.json`.

## Relational spine (4.0 vocabulary; alias-first)
```
user/group  —WF02 governs→  agent               (authority/delegation; delegated role/capabilities ride WF02 properties)
role/group  —WF02 delegates-to→  role           (capability narrowing, v3.13 — role-to-role, never user-to-agent)
workspace(session)  —WF19 has-occupant→  agent   (liveness/occupancy)
workspace(session)  —WF19 opens-on→  engine(kernel)   (topology intent)
agent  —presents-as→  persona (= Φ(purpose))     (D4; presentation, NOT authority)
surface  —realizes→  channel / workspace          (D8; observed-first, S0 substrate)
```
A user/group **governs** an agent (T=249 drift fix — the live WF02 relation is `governs`; `delegates-to` is role→role only, see `dev/design/manifold-bump-4_0/20260708-t249-governance-authority-note.md` §7); an agent **occupies** a workspace; an agent **may present-as** a persona derived from purpose; IDE/harness panes/windows/tabs are **S0 surfaces** that project and evidence the workspace — never authority principals, never durable truth until G-ingested.

## 4.0 vocabulary (manifold paradigm) — ALIAS-FIRST; ADDITIVE BUMP LANDED (ontology v4.0.0, T=231)
First mention dual-names: `workspace (session)`, `engine (kernel)`; thereafter the 4.0 term where context is clear.
**The additive, alias-first 4.0 bump is APPLIED (`ontology.json` v4.0.0, T=231): `manifold` type, `workstation.kind`, `channel.kind` infra+surface, `workspace`/`engine` aliases, `persona`-as-derivation. STILL GATED: the hard URN / runtime-type-id rewrite (`session`/`kernel` stay canonical until the reviewed 4.0.x) plus the deferred relations. This file authorizes no URN change.**

| Δ | Change | Status |
|---|---|---|
| D1 | `manifold` — new top category (application/domain grouping; colimit of branch-episodes) | ✅ LANDED v4.0.0 (S2 type, identity-first; spanning relations deferred) |
| D2 | `session` → `workspace` (alias-first) | ✅ LANDED v4.0.0 (alias on `session`; URN rewrite → 4.0.x) |
| D3 | `persona = Φ(purpose)` as a `derivation`, not authority | ✅ LANDED v4.0.0 (derivation convention + nomenclature) |
| D4 | `presents-as` (agent↔persona relation) | ⏸ DEFERRED → 4.0.x (no persona node — persona is a derivation; WF/target undefined) |
| D5 | `channel.kind` expansion (infra: domain/dns-zone/cloudflare-*/registrar; surface: workstation-surface/virtual-desktop/window/tab-group/browser-tab/harness-pane) | ✅ LANDED v4.0.0 (folded with D7) |
| D6 | `kernel` → **`engine`** (`engine := fold(log)`; re-ratified T=239 from `instance`); alias in 4.0, hard ~59-site URN rewrite gated to 4.0.x | ✅ LANDED v4.0.0 (alias on `kernel`; canonical term **engine**; `instance` deprecated; URN rewrite → 4.0.x) |
| D7 | workstation surface layer — S0 projection substrate (desktops/windows/panes/tabs), observed-not-authored | ✅ LANDED v4.0.0 (addressability via channel.kind; doctrine = observed-only) |
| D8 | `realizes / realized-by` (surface↔channel/workspace), observed-first | ⏸ DEFERRED → 4.0.x (observed-first; reify only if the pipeline must write it) |

Grammar_fragments (`dev/design/manifold-bump-4_0/20260620-t231-grammar-fragment-proposals.md`): **P1** `workstation.kind` + **P2** `channel.kind +=` LANDED v4.0.0 (`v400-2`/`v400-3`); **P3** `inference_kind += {lowering,lifting}` + **P4** §M11 occupant-guard DEFERRED (axis-mixing / authority-model). `my-tiny-data-collider` is the worked example manifold. The 4.0 additive core is now **current code**; the URN-rewrite tail (4.0.x) remains parallel-dev.

## Skills (capabilities; model-invoked by description) — `dev/claude-skills/` (synced to `~/.claude/skills/`)
Authoring/ops: `moos-rewrite-envelope` · `moos-state-readback` · `moos-round-close` · `moos-running-state-validator` · `moos-cross-persona-audit` · `moos-workstation-operator`.
Orientation: `moos-seat-hydration` (seat readback + hydration; used by `/orient` + the `.claude/agents/` cards).
Projection/ingest: `moos-session-context-projection` (F) · `moos-workspace-ingest` (G text) · `moos-multimodal-ingest` (G binary) · `moos-github-project-bridge`.
Seat lanes: `moos-categorical-research` + `moos-compiler-lowering` (Karpathy) · `moos-tooling-dx` (Steinberger) · `moos-cowork-readback` (the Cowork seats: Zappa · John Lydon).
Detail lives in each `SKILL.md` — do not restate here.

## Repos & branching
- `ffs0` (this repo) = private control/research workspace + KB. `moos-kernel` (Go runtime), `moos-router` (federation). `moos-config` = LEGACY, do not use. All at `github.com/Collider-Data-Systems/*`.
- **Trunk-first on `main`** for verified single-lane/non-colliding work (T208). **Branch + merge-with-provenance** for collision-prone multi-lane work (T218: `branch=F(workspace)`, `merge=G(branch)`; trailer `authored-by: <agent-urn> / <session-urn> / <purpose-slug>`). Runtime code branches `feat/<purpose-slug>` in `moos-kernel`/`moos-router`.
- **Worktree-per-branch on shared checkouts (T249, both boxes):** the default branch stays parked on the canonical checkout (hydration/readback surface — no seat switches it); branch work lives in `git worktree add ../<repo>.wt/<branch> <branch>` (git enforces one-checkout-per-branch = lane partition as filesystem fact); worktree removed at round close. Runtime-repo extra: worktree builds never touch live binaries; worktree kernels never point `--log` at anything but the canonical sovereign log.
- **Attribution (T=239, additive)** — keep the required trailer above; add the optional fields **only when they disambiguate** (multi-user, cross-channel, or a non-IDE channel like an Android Keep note landing in the repo): `user: <user-urn>` · `workstation: <workstation-urn>` · `channel-kind: <kind>`. For complex/multi-source merges add a `## Contribution` commit-body block (source channel / workstation / user / agent / workspace / purpose). Solo Sam-on-Z440 commits stay as today. Full doctrine: `dev/design/manifold-bump-4_0/20260607-t218-branching-strategy.md`.

## Safety / boundaries
Never commit `secrets/` values, API tokens, or `.vscode/mcp.json`. Mutations (commit/push, merge, DNS/Cloudflare/tunnel/Access, Calendar/Workspace writes, HG apply) are explicit boundary acts — surface before doing, never as a side effect of readback. Do not emit HG rewrites, seat scoped-idle workspaces, or apply raw Keep notes from readback. IDE/UI/pinned-chat state is not durable HG truth.

## Tool-mirror map (this file is the source)
- `CLAUDE.md` (ffs0 + root) — `@import` this + Claude-specific deltas only.
- `.github/copilot-instructions.md` — thin mirror + Copilot-specific skill/prompt routing.
- `ANTIGRAVITY.md` (root) — Antigravity's primary directive; the AG tool-mirror (parallel to CLAUDE.md / copilot). AG reads `AGENTS.md` natively; this carries the `moos-diary` / multimodal-curation lane deltas.
Mirrors carry a header: source · manual/generated · source-commit · "don't edit except emergency de-rot." (Phase-2 mirror-body trim landed — mirrors are deltas-only.)
- **IDE surface (`*.code-workspace`):** tracked `ffs0.code-workspace` = portable baseline (tasks · extension recs · excludes); gitignored `*.local.code-workspace` = per-instance delta (multi-root layout · orientation · local roots) — a **D7 surface realization, never trunk-projected** (the `.gitignore` is the projection-fidelity boundary). Same baseline-first / local-divergence split as `AGENTS.md` ↔ `CLAUDE.md`.

---
*Phase-1 draft, Cowork-Z440. Review on ffs0#58.*
authored-by: agent:claude-cowork.hp-z440 / session:sam.z440-cowork-workspace / config-overhaul
