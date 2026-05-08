# Validation Modules

Importable Python validation/planning modules for older baseline and hydration checks.

These are not current write-path operators, but they still have tests and remain useful as small model fixtures:

- `session_baseline.py` — baseline relation checks and hydration proposals.
- `t161_hydration.py` — T161 program/agent/session/tool wiring planner.
- `verify_session_baseline.py` — CLI wrapper around the session baseline checks.

Do not add new one-shot emitters here. New projection work should prefer dry Julia planners plus explicit writer boundaries.