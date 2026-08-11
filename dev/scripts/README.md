# dev/scripts

> Part of the mo:os `ffs0` workspace. Project SOT: `../../AGENTS.md`. Live state: `../../kb/superset/running-state.md`.

Operational + projection tooling: validation checks, ops helpers, and the dry F-projection lane (folded HG state → local artifacts under `tmp/projections/`). Scripts read HG/folded state and write reviewable local artifacts; they never emit rewrites or perform cloud writes except at explicit OAuth-boundary writers (`--mode write`). Historical one-shot Python emitters are archived under `dev/archive/scripts/legacy-emitters/`.

Active projection lane is Julia-first. Julia binary on Z440: `C:\Users\maass\AppData\Local\Programs\Julia-1.12.6\bin\julia.exe`.

## Layout

| Path | Purpose |
|------|---------|
| `projections/` | Lane orchestration entrypoints + operator manual (`session-pipeline-operator-manual.md`). See `projections/README.md`. |
| `ops/` | Federation/kernel management, issue watcher, autostart, session-desktop launcher; reviewed HG apply payloads (`*.program.json`). See `ops/README.md`. |
| `validation/` | Importable Python baseline/hydration planners (not write-path). See `validation/README.md`. |
| `tests/` | Julia + Python tests for the lanes above. See `tests/README.md`. |

## Loose scripts (one level up)

| Script | What it does |
|--------|--------------|
| `export_t200plus_projection.jl` | Folded-state DOT/SVG exporter for T200+ graph lenses. |
| `graph_artifact_projection.jl` | Dry folded-state graph-artifact analyzer (JSON/Markdown engineering summaries); pairs with the DOT/SVG exporter. |
| `session_context_projection.jl` | Dry F-projection of a session into an IDE/agent/harness context pack (JSON/Markdown). No IDE-config edits, no rewrites. |
| `session_pipeline_mvp_gate.jl` | Dry MVP gate report for the Keep/session/visual lane; writes the HTML dashboard. Exits nonzero only on `fail` gates. |
| `surface_context_atlas.jl` | Generated operator/agent atlas tying together JSON/JSONL/HG state, Git, Calendar, dashboard, and visual surfaces with their trust boundaries. |
| `calendar_time_fabric_projection.jl` | F-direction planner: recent graph artifact → Google Calendar payloads; can lock to a writer result + live folded observations across T-day rollover. |
| `google_calendar_projection.jl` | Dry F-direction Calendar plan (JSON only); no OAuth, no cloud write. |
| `google_calendar_writer.jl` | OAuth-boundary Calendar writer; dry-run by default, real writes require local gitignored OAuth files + `--mode write`. Upserts by `moos_projection_id`. |
| `t189_t200_recommendation_projection.jl` | Dry planner: T189 recommendations → candidate HG nodes/relations + T200+ recommendation artifacts. |
| `t189_recommendation_reconciliation.jl` | Dry reconciliation of the recommendation plan against folded HG state (grouped rows, Calendar events, session pins, WF07 anchors, deferred rows). |
| `t193_workstation_inventory.jl` | Dry three-workstation/persona inventory; folds local log vs `dev/config/moos-federation.topology.json`. |
| `t194_t200_big_sprint_topology.jl` | Dry T194-T300 session-topology audit; emits a JSON/Markdown packet + candidate `ops/t194-t200-big-sprint-session-topology.program.json`. |
| `keep_t195_t206_ingest_stage.jl` | Dry G-direction stager for T195-T206 Keep material (Takeout ZIP/folder/manual export/API JSON). Stays `apply_ready=false` until reviewed. |
| `google_keep_fetch.jl` | OAuth-boundary Google Keep readonly fetch (`--mode check\|auth-listen\|fetch`); writes normalized JSON, feeds the dry stager. |
| `t206_keep_mvp_delivery.jl` | Narrow T206 MVP carrier planner for the Keep API/S0 staging boundary; raw note content stays deferred. |
| `generate_type_map.py` | Active utility: generate moos-router type-map flags from `kb/superset/ontology.json`. |
| `google_oauth_loopback_token.mjs` | Node loopback OAuth helper minting a `cloud-platform` token cache under `secrets/`. |
| `google_keep_service_account_token.mjs` | Node service-account / IAM `signJwt` helper minting a Keep readonly token under `secrets/`. |

## Run the projection lane

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File dev\scripts\projections\run-session-pipeline.ps1
```

Regenerates the Keep/session/visual/Calendar/recommendation lane and writes `tmp/projections/session_pipeline/index.html` (the operator dashboard). Dry — no rewrites, no cloud writes. Step-by-step detail and the artifact layout (`session_context/`, `graph_artifacts/`, `calendar/`, `recommendations/`, `atlas/`, `visual/`, `mvp/`) are in `projections/session-pipeline-operator-manual.md` and `projections/README.md`.

Individual adapters run directly, e.g.:

```powershell
& 'C:\Users\maass\AppData\Local\Programs\Julia-1.12.6\bin\julia.exe' dev\scripts\export_t200plus_projection.jl
```

`export_t200plus_projection.jl` presets via `$env:MOOS_PROJECTION_PRESET` (`temporal-calendar`, `session-occasion`), narrowable with `MOOS_PROJECTION_{WFS,TYPES,PORTS,MATCH,ROOT,OUT}`.

## Keep / Calendar OAuth boundaries

Google Calendar/Keep writers are explicit actuator steps, not part of the dry lane. Local OAuth client + token files live under `secrets/` (gitignored). The full Keep ingest contract (source modes, review boundary, and the Cloud Console `invalid_scope` fix) is the harness-neutral runbook `dev/runbooks/keep-ingest-runbook.md`. Harness-neutral entrypoint:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File dev\scripts\ops\Invoke-KeepIngestHarness.ps1 -Mode Check
```

## Usage pointers

- Orientation, seat map, rewrite vocabulary, branching, safety: `../../AGENTS.md`. Do not duplicate it here.
- Live round-to-round state: `../../kb/superset/running-state.md` (read first).
- Workstation bring-up/refresh: skill `moos-seat-hydration` (Claude) or `AGENTS.md` + running-state (any harness).
- Relevant skills: `moos-state-readback`, `moos-session-context-projection`, `moos-workspace-ingest`, `moos-tooling-dx`, `moos-rewrite-envelope`, `moos-cross-persona-audit`.
- Python status: keep `generate_type_map.py` (router) and `validation/*.py` + their tests (importable baseline/hydration checks). Do not add new one-shot emitters — prefer dry Julia planners + explicit writer boundaries.
