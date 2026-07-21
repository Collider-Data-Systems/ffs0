# AGENTS reference — mo:os doctrine, deep tier

> Moved out of the always-loaded `AGENTS.md` kernel in the T=262 harness diet (this file is fetch-on-demand; the kernel points here per section). Same SOT rules: HG folded state + live readback outrank this file.

## Project status (Phases 1–4)
Endgame: keep everything in HG + jsonl in memory; the `.md` files are a temporary crutch being made *generated* piecewise (Phase 4 landed for the seat table; prose is next).
> **Authored projection SOT for tools.** Cross-tool brief read natively by Copilot, Cursor, Codex, Gemini/Antigravity. Claude reads it via `CLAUDE.md` `@import`.
> **Status: Phases 1–4 COMPLETE (#58 closed T=244+).** Phase-1 approved on ffs0#58 (PR #59); Phase-2 mirror trim + `.claude/rules/` live; Phase-3 Antigravity canary proven; Phase-4 `moos-config-projection` generates the seat table below (`--mode check` = blocking drift gate at round-close step 0).

## Design-doc discipline (`dev/design/**`)
Relation-first, rewrite-first. No OOP framing (no objects-with-payload, no static UML associations). Distinguish **operad** (admissible grammar / valid composition) from **instance** (realized topology + rewrite log). All state change is ADD/LINK/MUTATE/UNLINK — nothing else. Relations are topology (LINK results); rewrite_categories WF01–WF21 are op-families — don't conflate. Properties are typed/governed, never free-form payloads, never duplicate topology. Output: concise conclusions; **mark conjectures as conjectures** (don't assert unproven categorical claims as settled); open questions as 1–2 bullets. Authoritative refs: `running-state.md` + `ontology.json`.

## Network / federation (T=219 Tailscale mesh · T=226 ProDesk rejoin)
Z440 (`desktop-42d00rd`) `100.82.243.13` (Tailscale) / `192.168.1.15` (LAN). hp-laptop (`lap-sam`) `100.106.220.58` (Tailscale) / `192.168.1.10` (LAN). HP ProDesk (`desktop-3fc7c3f`) `100.87.28.95` (Tailscale; mostly powered off — expect Doctor-mode drift flags while down). Federation router fans in cross-box over Tailscale (DHCP-drift retired). Kernels `:8000` (+Z440 twins `:8001-8003`), MCP `:8080` (Z440 twins' opens-on MCP `:9001/:9002/:9003`), router `:9000`. Live detail → `dev/config/moos-federation.topology.json`.

## Relational spine — commentary
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

## Skills index (T=262 consolidation: 15 → 12)
Authoring/ops: `moos-rewrite-envelope` · `moos-state-readback` · `moos-round-close` · `moos-cross-persona-audit` (incl. running-state validation mode; absorbs the retired `moos-running-state-validator`).
Orientation: `moos-seat-hydration` (seat readback + hydration; used by `/orient` + the `.claude/agents/` cards; absorbs the retired `moos-cowork-readback` + `moos-workstation-operator`).
Projection/ingest: `moos-session-context-projection` (F) · `moos-workspace-ingest` (G text) · `moos-multimodal-ingest` (G binary) · `moos-github-project-bridge`.
Seat lanes: `moos-categorical-research` + `moos-compiler-lowering` (Karpathy) · `moos-tooling-dx` (Steinberger).
Detail lives in each `SKILL.md` — do not restate here.

## Repos & branching (full doctrine)
- `ffs0` (this repo) = private control/research workspace + KB. `moos-kernel` (Go runtime), `moos-router` (federation). `moos-config` = LEGACY, do not use. All at `github.com/Collider-Data-Systems/*`.
- **Trunk-first on `main`** for verified single-lane/non-colliding work (T208). **Branch + merge-with-provenance** for collision-prone multi-lane work (T218: `branch=F(workspace)`, `merge=G(branch)`; trailer `authored-by: <agent-urn> / <session-urn> / <purpose-slug>`). Runtime code branches `feat/<purpose-slug>` in `moos-kernel`/`moos-router`.
- **Worktree-per-branch on shared checkouts (T249, both boxes):** the default branch stays parked on the canonical checkout (hydration/readback surface — no seat switches it); branch work lives in `git worktree add ../<repo>.wt/<branch> <branch>` (git enforces one-checkout-per-branch = lane partition as filesystem fact); worktree removed at round close. Runtime-repo extra: worktree builds never touch live binaries; worktree kernels never point `--log` at anything but the canonical sovereign log.
- **Attribution (T=239, additive)** — keep the required trailer above; add the optional fields **only when they disambiguate** (multi-user, cross-channel, or a non-IDE channel like an Android Keep note landing in the repo): `user: <user-urn>` · `workstation: <workstation-urn>` · `channel-kind: <kind>`. For complex/multi-source merges add a `## Contribution` commit-body block (source channel / workstation / user / agent / workspace / purpose). Solo Sam-on-Z440 commits stay as today. Full doctrine: `dev/design/manifold-bump-4_0/20260607-t218-branching-strategy.md`.

## Tool-mirror map (detail; the source is `AGENTS.md`)
- `CLAUDE.md` (ffs0 + root) — `@import` this + Claude-specific deltas only.
- `.github/copilot-instructions.md` — thin mirror + Copilot-specific skill/prompt routing.
- `ANTIGRAVITY.md` (root) — Antigravity's primary directive; the AG tool-mirror (parallel to CLAUDE.md / copilot). AG reads `AGENTS.md` natively; this carries the `moos-diary` / multimodal-curation lane deltas.
Mirrors carry a header: source · manual/generated · source-commit · "don't edit except emergency de-rot." (Phase-2 mirror-body trim landed — mirrors are deltas-only.)
- **IDE surface (`*.code-workspace`):** tracked `ffs0.code-workspace` = portable baseline (tasks · extension recs · excludes); gitignored `*.local.code-workspace` = per-instance delta (multi-root layout · orientation · local roots) — a **D7 surface realization, never trunk-projected** (the `.gitignore` is the projection-fidelity boundary). Same baseline-first / local-divergence split as `AGENTS.md` ↔ `CLAUDE.md`.

---
authored-by: agent:vscode.hpprodesk.primary / session:sam.hpprodesk-setup / t262-harness-diet
