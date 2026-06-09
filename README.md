# ffs0

> Part of the mo:os workspace. Project SOT: `AGENTS.md`. Live runtime/seat state: `kb/superset/running-state.md` (read it first for round-to-round state).

Private portable control/research workspace for mo:os: ontology, knowledge base, projection lanes, skills, scripts, and local operator artifacts. The runtime code lives in sibling repos `moos-kernel` (Go kernel) and `moos-router` (federation). This repo is **not** the kernel — it is the workspace around it.

Orientation (the rule, seat map, SOT hierarchy, F⊣G pipeline, vocabulary, branching, safety) lives in `AGENTS.md` — not duplicated here.

## Layout

| Path | Purpose |
|------|---------|
| `kb/superset/ontology.json` | Ontology source (S1). Version is authoritative in the file + live `/healthz`, not here. |
| `kb/superset/running-state.md` | Hydration entrypoint — current T-day, kernel/router state, sessions, active lanes, key URNs. |
| `kb/superset/instances/` | Instance-level state snapshots. |
| `kb/moos-diary/` | Round wrap-ups and projection-ready diary material. |
| `dev/scripts/` | Projection runners, dry planners, validators, ingest/writer scripts (`ops/`, `projections/`, `validation/`, `tests/`). |
| `dev/claude-skills/` | Project skills (synced to `~/.claude/skills/` via `sync-claude-skills.ps1`). |
| `dev/config/` | Federation topology, session-affordance, desktop maps. |
| `dev/design/` | 4.0 / ontology design drafts (relation-first, rewrite-first; see `AGENTS.md` design discipline). |
| `dev/reference/` | Runbooks (e.g. `keep-ingest-runbook.md`), `research-archive/`, papers, evaluations. |
| `dev/moos-viz/` | Visualization build output. |
| `secrets/` | Local-first, **gitignored** — never commit. |
| `tmp/` | Generated projection artifacts — local unless a snapshot is explicitly requested. |

Tool mirrors of `AGENTS.md`: `CLAUDE.md` (Claude Code), `.github/copilot-instructions.md` (Copilot), root `ANTIGRAVITY.md` (Antigravity). `.github/` holds only `copilot-instructions.md` + `workflows/` (the Project-sync Action).

## Projection lane

Run the local dry session pipeline:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File dev\scripts\projections\run-session-pipeline.ps1
```

Outputs under `tmp/projections/session_pipeline/`: session context pack, graph/DOT/SVG lenses, Calendar plan, recommendation reconciliation, surface context atlas, MVP gate, and a `index.html` dashboard. Operator detail: `dev/scripts/projections/session-pipeline-operator-manual.md`. F (project) / G (ingest) discipline and the skill map are in `AGENTS.md`.

## Safety

- Never commit `secrets/` values, API tokens, or `.vscode/mcp.json`.
- `moos-config` is LEGACY — do not use for current runtime work.
- Mutations (commit/push, DNS/Cloudflare, Calendar/Workspace writes, HG apply) are explicit boundary acts, never readback side effects — see `AGENTS.md`.
