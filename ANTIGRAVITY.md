# ANTIGRAVITY.md

Primary directive for Antigravity IDE (Google Gemini) in the `ffs0` workspace.
Owner: `urn:moos:user:sam` — pulled on every workstation.

> **Pointer to `AGENTS.md`** (the project SOT — read it natively; the T=244 Phase-3 canary
> proved this read→act path end-to-end, ffs0#58). All shared doctrine lives THERE, once:
> the rule (ADD·LINK·MUTATE·UNLINK), SOT hierarchy, generated seat table, S0→HG pipeline,
> actor discipline (§M11/§M12), branching summary, safety. Deep doctrine (4.0 vocab D1–D8,
> full branching/attribution, design-doc discipline, skills index) lives in
> `dev/runbooks/agents-reference.md` (T=262 split).
> **Read `kb/superset/running-state.md` first for live round-to-round state.**
> Workspace rules: `.agents/rules/` (`sot-hierarchy.md`, `four-rewrites.md`, `seat-context.md`).
> Skills sync: `dev/scripts/sync-antigravity-config.ps1` (syncs `dev/claude-skills/` -> `.agents/skills/` & `~/.gemini/antigravity/skills/`).

## Lane — what AG owns on Z440

- `session:sam.moos-diary` as `agent:antigravity.hp-z440`, emit `kernel:hp-z440.primary`
  :8000 / MCP :8080 (`hp-z440.moos` :8003 = overflow-lane metadata only; seat table in `AGENTS.md`).
- `persona.moos-dachshund` (= Φ(purpose), D3) is the S4 context overlay.
- Labs Flow videos / photos / audio → `knowledge_item` chunks pinned to the session
  (skill `moos-multimodal-ingest`; diary entries per-artifact-section with umbrella KI).
- Diary entries under `kb/moos-diary/` (md + media; raw media fine, chunk before doctrine).
- Categorical/HDC reasoning → skill `moos-categorical-research`.

AG does NOT own: kernel Go code (Wolfram), doctrine review (John Lydon — governance on
hp-laptop; Guido = laptop VS Code lead since the T247 split), the other court lanes
(Karpathy HDC / Steinberger DX). `my-tiny-data-collider` is an HG application group/domain,
not the `moos-kernel` codebase — Workspace/DNS/Calendar/GitHub are projection/ingest surfaces.

## AG-specific gotchas

- Envelope actor: `agent:antigravity.hp-z440` (inferred via moos-diary occupancy); kernel
  actor only for ontology-governed ADDs / kernel-authority MUTATEs; never `user:sam` (§M11).
  Full shapes: skill `moos-rewrite-envelope`.
- Never commit `secrets/` values or `.vscode/mcp.json`; destructive actions explicit.
