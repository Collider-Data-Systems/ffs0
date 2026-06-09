# Script Tests

> Part of the mo:os `ffs0` workspace. Project SOT: `../../../AGENTS.md`. Live state: `../../../kb/superset/running-state.md`.

Tests for the projection (`F`) and validation helpers in `dev/scripts/`. Each Julia test 1:1 `include`s its sibling source script (`../<name>.jl`); the Python tests import from `dev/scripts/validation/`.

## Julia tests (projection lanes)

Each mirrors a `dev/scripts/<name>.jl` projection script:

| Test | Source under test |
|---|---|
| `test_google_calendar_projection.jl` | `../google_calendar_projection.jl` |
| `test_google_calendar_writer.jl` | `../google_calendar_writer.jl` |
| `test_calendar_time_fabric_projection.jl` | `../calendar_time_fabric_projection.jl` |
| `test_google_keep_fetch.jl` | `../google_keep_fetch.jl` |
| `test_keep_t195_t206_ingest_stage.jl` | `../keep_t195_t206_ingest_stage.jl` |
| `test_graph_artifact_projection.jl` | `../graph_artifact_projection.jl` |
| `test_session_context_projection.jl` | `../session_context_projection.jl` |
| `test_session_pipeline_mvp_gate.jl` | `../session_pipeline_mvp_gate.jl` |
| `test_surface_context_atlas.jl` | `../surface_context_atlas.jl` |
| `test_t189_recommendation_reconciliation.jl` | `../t189_recommendation_reconciliation.jl` |
| `test_t189_t200_recommendation_projection.jl` | `../t189_t200_recommendation_projection.jl` |
| `test_t193_workstation_inventory.jl` | `../t193_workstation_inventory.jl` |
| `test_t194_t200_big_sprint_topology.jl` | `../t194_t200_big_sprint_topology.jl` |
| `test_t206_keep_mvp_delivery.jl` | `../t206_keep_mvp_delivery.jl` |

Run one: `julia dev\scripts\tests\<name>.jl`

## Python tests (validation planners)

Import from `dev/scripts/validation/`; run from the repo root:

| Test | Module under test |
|---|---|
| `test_session_baseline.py` | `dev/scripts/validation/session_baseline.py` |
| `test_t161_hydration.py` | `dev/scripts/validation/t161_hydration.py` |

Run: `python -m unittest dev.scripts.tests.test_session_baseline dev.scripts.tests.test_t161_hydration`

## Usage

After the Julia tests, run the dry session-pipeline projection end-to-end:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File dev\scripts\projections\run-session-pipeline.ps1
```

Detail on the projection (`F`) lane → skill `moos-session-context-projection`. Pipeline outputs land under `tmp/projections/session_pipeline/`.
