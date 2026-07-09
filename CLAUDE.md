# CLAUDE.md

@AGENTS.md

> **Mirror of `AGENTS.md`** (the project SOT) · manual · don't edit except emergency de-rot. Canonical cross-tool orientation — seat map, 3-tier SOT hierarchy (HG→`AGENTS.md`→mirrors), S0→HG pipeline, 4.0 vocab, branching, safety — lives in **`AGENTS.md`**. This file = Claude-Code-specific deltas only.

Personal portable private workspace for mo:os. Owner `urn:moos:user:sam`. **Read `kb/superset/running-state.md` first for live state**; folded HG + live `/healthz` outrank any doc (if a doc and readback disagree, re-read — readback wins).

## The rule
Four rewrites: **ADD · LINK · MUTATE · UNLINK**. Log is truth, state is derived. Full nomenclature + doctrine in `AGENTS.md`.

## Actor discipline (§M11/§M12 — for envelope authoring)
Every envelope carries `actor`:
- **Agent actor** (`urn:moos:agent:<short>`) — default; resolves via inferred session when the agent occupies exactly one workspace (`session`). Multi-workspace agents (Zappa `claude-cowork.hp-z440`, John Lydon `claude-cowork.hp-laptop`) set `session_urn` explicitly (Wolfram is single-workspace since the T250 re-seat to `vscode.hp-laptop.wolfram`).
- **Kernel actor** (`urn:moos:kernel:<ws>.<name>`) — bypasses §M11 + §M12; required for ontology-governed type ADDs, kernel-authority MUTATEs, WF19 `opens-on` LINKs, sweep emissions.
- **User actor** (`urn:moos:user:sam`) — fails §M11; only inside `SeedIfAbsent`.
`env.actor` = who emits (ephemeral); `owner_urn` property = who owns (sticky). Field gotchas + the four envelope shapes → skill **`moos-rewrite-envelope`**.

## Skills (capabilities) — `dev/claude-skills/` (synced to `~/.claude/skills/`)
Full index in `AGENTS.md`. Authoring: `moos-rewrite-envelope`. Readback: `moos-state-readback`, `moos-cowork-readback`. Projection (F): `moos-session-context-projection`. Ingest (G): `moos-workspace-ingest` (WF12 provides-kb), `moos-multimodal-ingest`. Governance: `moos-running-state-validator`, `moos-cross-persona-audit`, `moos-round-close`. Lanes: `moos-categorical-research` + `moos-compiler-lowering` (Karpathy), `moos-tooling-dx` (Steinberger). Bridge: `moos-github-project-bridge`. Operator: `moos-workstation-operator`. Orientation: `moos-seat-hydration`.

## Projection lane
Local dry pipeline:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File dev\scripts\projections\run-session-pipeline.ps1
```
Outputs under `tmp/projections/session_pipeline/`: session pack, graph/DOT/SVG lenses, Calendar plan, recommendation reconciliation, surface atlas, MVP gate, `index.html`. Detail → skill `moos-session-context-projection`.

## Workspace
```
kb/superset/   ontology.json (S1, v4.0.0) + running-state.md (hydration entrypoint)
kb/moos-diary/ round wrap-ups  (doctrine moved: dev/reference/research-archive/ + dev/design/manifold-bump-4_0/)
dev/           scripts/ (ops+projections · keep-anywhere/ Keep→Drive mirror) · tools/ (Go: moos-mcp · moos-lsp · landscape.md) · claude-skills/ (15) · config/ · design/ (4.0 drafts · manifold-bump-4_0/ = vocab deltas·mtdc·branching·mo:os⊣so:om·Poly) · reference/ (runbooks + research-archive)
secrets/       GITIGNORED, local-first
.github/       copilot-instructions.md (Copilot mirror) + workflows/ (Project-sync Action)
AGENTS.md      project SOT (this file mirrors it); root D:\HPZ440\AGENTS.md = fleet layer
```

## Runtime repos (siblings)
`moos-kernel` (Go, §M11+§M12 gates) · `moos-router` (federation, WF16) · `moos-config` = LEGACY, do not use. All at `github.com/Collider-Data-Systems/*`.

## Safety
Never commit `secrets/` values or `.vscode/mcp.json`. Destructive/outward actions are explicit boundary acts. IDE conversations are **S0 substrate** until G-ingested — not durable HG truth. Design-doc language discipline (`dev/design/**`): see `AGENTS.md`.
