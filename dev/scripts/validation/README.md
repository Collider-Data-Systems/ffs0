# Validation Modules

> Part of the mo:os `ffs0` workspace. Project SOT: `../../../AGENTS.md`. Live state: `../../../kb/superset/running-state.md`.

Importable Python validation/planning helpers for baseline relation checks and hydration planning. These are **not** current write-path operators — they are pure (no side-effect emit), kept because they still have tests and serve as small model fixtures. New projection work belongs in the dry Julia planners under `../projections/` with explicit writer boundaries; do not add new one-shot emitters here.

## Contents

| File | Purpose |
|------|---------|
| `session_baseline.py` | Baseline relation checks (`verify_baseline`) + hydration proposals (`propose_hydration`); HTTP helpers for `/state/*` and `/programs`. |
| `t161_hydration.py` | Pure planner emitting ADD/LINK rewrite envelopes for program/agent/session/tool wiring (no IO — callers handle HTTP/file access). |
| `verify_session_baseline.py` | CLI wrapper around the session-baseline checks. |
| `__init__.py` | Package marker (empty). |

## Usage

Modules import as `dev.scripts.validation.*` and resolve the repo root via `parents[3]`, so run from the `ffs0` repo root.

Verify a kernel's session baseline (exits 2 if checks fail):

```powershell
python -m dev.scripts.validation.verify_session_baseline --base-url http://localhost:8000
# --ontology defaults to kb/superset/ontology.json
```

Tests live in `../tests/` (`test_session_baseline.py`, `test_t161_hydration.py`):

```powershell
python -m unittest dev.scripts.tests.test_session_baseline dev.scripts.tests.test_t161_hydration
```

Rewrite-envelope shape and the four rewrite types (ADD/LINK/MUTATE/UNLINK) are governed by the `moos-rewrite-envelope` skill.
