# Projection Scripts

> Part of the mo:os `ffs0` workspace. Project SOT: `../../../AGENTS.md`. Live state: `../../../kb/superset/running-state.md`.

Orchestration entrypoints for the local projection lane (F-direction: folded HG state → reviewable local artifacts). The Julia adapters this orchestrator drives live one level up in `dev/scripts/` (kept there for existing calls and tests).

## Contents

| File | Role |
|---|---|
| `run-session-pipeline.ps1` | End-to-end runner for the session/visual/Calendar/recommendation/atlas/gate lane. |
| `session-pipeline-operator-manual.md` | Practical guide to the generated `tmp/projections/session_pipeline/` workbench: file types, dashboard walkthrough, typed data flow, adapter/skill index. |

## Run

From the ffs0 repo root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File dev\scripts\projections\run-session-pipeline.ps1
```

Resolves the active session/actor from `/healthz` + `/state/nodes` readback, then runs the adapter chain (session context pack → graph engineering reports → DOT/SVG lenses → Calendar time-fabric plan → recommendation plan + reconciliation → surface atlas → MVP gate). Outputs land under `tmp/projections/session_pipeline/`; open `index.html` as the cockpit.

Optional params: `-BaseUrl`, `-Julia`, `-SessionUrn`, `-ActorUrn`, `-Focus`, `-AnchorT` (defaults auto-resolve from the running kernel).

## Boundaries

Dry by default — reads folded HG state and writes local files; emits no rewrites and performs no external writes. Google Calendar writes remain an explicit actuator step via `dev/scripts/google_calendar_writer.jl --mode write`. The recommendation plan proposes candidate HG nodes/relations; reconciliation reports what is applied / pending / deferred against folded state. Generated artifacts are projections, not truth — do not commit them.

## See also

- Doctrine, seat map, F⊣G pipeline: `../../../AGENTS.md`
- Adapter/file-type/dashboard detail: `session-pipeline-operator-manual.md`
- Projection skill: `moos-session-context-projection` (F) · ingest: `moos-workspace-ingest` (G)
