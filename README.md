# ffs0

Private portable workspace for mo:os research, ontology, projection lanes, skills, reports, and local operator artifacts. Runtime code lives in sibling repositories: `moos-kernel` and `moos-router`.

## Current State

Read `kb/superset/running-state.md` first. It is the hydration entrypoint for current T-day, kernel state, sessions, active lanes, and key URNs.

As of T189, hp-laptop primary is live on ontology v3.16.1 with `session:sam.governance` as the active governance/projection lane. That session now pins the Calendar/time-fabric program family, the grouped T189/T200 recommendation carriers, 16 individual `calendar_event` observations from the Calendar proof, and the `program:sam.t189.surface-context-atlas` carrier. The current local pipeline projects HG state into session context, graph artifacts, static visuals, Calendar payloads, recommendation HG plans, reconciliation reports, a surface context atlas, and a local dashboard.

Run the current projection lane with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File dev\scripts\projections\run-session-pipeline.ps1
```

The dashboard is generated at `tmp/projections/session_pipeline/index.html`.
The atlas is generated at `tmp/projections/session_pipeline/atlas/surface_context_atlas.{json,md}` and explains the JSON API, JSONL log, Git repos, Calendar, dashboard, visuals, type/relation/program surface, existing HG anchors, and pending moves.

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

## Current T189/T200 Priorities

- Keep the session pipeline as the daily operator screen: Graphviz for deterministic review, Cytoscape.js for typed inspection, and gates that distinguish applied, pending, and deferred rows.
- Finish the WF07 Calendar source-anchor operad cleanup so the 16 applied `calendar_event` nodes can link back to their source HG nodes without a deferred boundary.
- Refresh GitHub Project #4 row identity so active items carry `HG URN` and board edits can become conservative G-direction rewrite candidates.
- Grow `my-tiny-data-collider` as an application group on HG: websites, DNS, servers, Calendar, GitHub, Workspace, and content/data products as explicit external surfaces.
- Keep public-facing organization/project content aligned with the graph while runtime repos stay focused on kernel and router substrate.

## Safety

- Never commit `secrets/` values or `.vscode/mcp.json`.
- Do not use legacy `moos-config` for current runtime work.
- Keep generated `tmp/projections/` artifacts local unless explicitly asked to preserve a snapshot.

