# ffs0

Private portable workspace for mo:os research, ontology, projection lanes, skills, reports, and local operator artifacts. Runtime code lives in sibling repositories: `moos-kernel` and `moos-router`.

## Current State

Read `kb/superset/running-state.md` first. It is the hydration entrypoint for current T-day, kernel state, sessions, active lanes, and key URNs.

As of T189, hp-laptop primary is live on ontology v3.16.1 with `session:sam.governance` as the active governance/projection lane. That session now pins the Calendar/time-fabric program family, and the current local pipeline projects HG state into session context, graph artifacts, static visuals, Calendar payloads, recommendation HG plans, and a local dashboard.

Run the current projection lane with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File dev\scripts\projections\run-session-pipeline.ps1
```

The dashboard is generated at `tmp/projections/session_pipeline/index.html`.

## Repository Role

`ffs0` is not the kernel runtime. It is the research/control workspace around the runtime:

- `kb/superset/ontology.json` is the current ontology source.
- `kb/superset/running-state.md` is the current operating readback.
- `kb/moos-diary/` holds projection-ready reports and selected diary material.
- `dev/scripts/` holds dry planners, validators, projection runners, and explicit writer boundaries.
- `dev/claude-skills/` holds project skills synced into agent harnesses.
- `dev/reference/research-archive/` holds historical scratch, shipped plans, and prior-round context.
- `secrets/` is local-first and gitignored.

## Kernel And Applications

The kernel is separate from applications that run on the HG.

- `moos-kernel` is the OS-facing runtime program: fold the log, validate rewrites, enforce session/authority gates, expose transport and actuator boundaries.
- `moos-router` is the federation/read-routing surface across sovereign kernels.
- Application groups such as `my-tiny-data-collider` are domain uses of the HG through those kernels. They may include websites, DNS, servers, Calendar, GitHub, Workspace, and other external surfaces, but they are not the kernel codebase.

There can be many application groups. `my-tiny-data-collider` may become the dominant one, but it should remain modeled as a group/purpose/program/channel family inside HG, not as the kernel itself.

## Projection Discipline

Use the F/G boundary consistently:

- `F: HG -> external surface`: Calendar events, GitHub project rows, dashboards, DOT/SVG, website/DNS plans, IDE context packs.
- `G: external observation -> HG`: `knowledge_item`, `claim`, `derivation`, `calendar_event`, status MUTATEs, or other typed graph evidence.

Default to dry planners first. Writers and API calls are actuator boundaries and should be explicit. External surfaces need graph-derived identity so they can be ingested back without guesswork.

## Current T189 Priorities

- Validate and commit the Calendar time-fabric planner/dashboard/recommendation lane.
- Review the hybrid Calendar G-ingest plan: 16 individual `calendar_event` nodes plus one grouped derivation/result.
- Refresh the GitHub Project #4 bridge so active rows carry `HG URN` identity.
- Prototype a Cytoscape.js typed-HG inspector while keeping Graphviz DOT/SVG as deterministic review artifacts.
- Model `my-tiny-data-collider` as an application group on the HG, separate from kernel/runtime repositories.

## Safety

- Never commit `secrets/` values or `.vscode/mcp.json`.
- Do not use legacy `moos-config` for current runtime work.
- Keep generated `tmp/projections/` artifacts local unless explicitly asked to preserve a snapshot.

