# Script Tests

Tests for local projection and validation helpers.

Julia tests cover the active projection lanes:

- `test_google_calendar_projection.jl`
- `test_google_calendar_writer.jl`
- `test_graph_artifact_projection.jl`
- `test_session_context_projection.jl`
- `test_session_pipeline_mvp_gate.jl`

Python tests cover older but still importable validation planners:

- `test_session_baseline.py`
- `test_t161_hydration.py`

Run the active session-pipeline validation through `dev/scripts/projections/run-session-pipeline.ps1` after the Julia tests.