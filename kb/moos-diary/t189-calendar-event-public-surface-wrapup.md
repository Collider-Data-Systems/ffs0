# T189 Calendar Event and Public Surface Wrap-Up

**T-day:** T=189  
**Date:** 2026-05-09  
**Kernel:** `hp-laptop.primary`  
**Runtime readback:** `ontology_version=3.16.1`, `t_day=189`, `log_len=1154`  
**Lane:** Keep/session/visual/Calendar/recommendation projection pipeline

## Executive status

The five T189 recommendations are now real in the operator lane, not just phrased as a plan. The grouped recommendation carriers are applied in HG, the individual Calendar observation slice is applied in HG, the Google Calendar projection has been written safely by upsert, and the dashboard/reconciliation reports now show applied, pending, and deferred rows as separate states.

The public-facing layer also moved forward. Project #4 now has a refreshed description/readme that explains the board as a projection/control surface, and the public `Collider-Data-Systems/.github` organization profile now presents mo:os as a kernel/router substrate plus identity-stable projection surfaces and application groups.

## Answer 1: actual implementation of the five T189 recommendations

### 1. Calendar event G-ingest shape

Status: implemented through the safe boundary.

What is applied:

- 10/10 grouped T189/T200 carrier nodes are present in folded HG state.
- 16/16 grouped safe relations are present in folded HG state.
- 16/16 individual `calendar_event` nodes are present in folded HG state.
- 16/16 WF19 session pins from `session:sam.governance` to those Calendar events are present.

What remains deferred:

- 16 WF07 `anchors/anchor` source-anchor relations remain intentionally deferred.
- Reason: `calendar_event` exposes an `anchors` out port and port-color compatibility mentions the `anchors/anchor` pair, but the top-level WF07 declaration still names `participates/participated-by`. This is an operad declaration cleanup, not a missing Calendar write.

Interpretation: the Calendar observation layer is in HG. The source-anchor topology is waiting for a clean WF07 declaration before any apply batch should touch it.

### 2. GitHub Project #4 URN refresh

Status: projected and publicly framed; row-level identity repair remains next.

What is done:

- The Project #4 readme/description now states the board identity rule: rows that represent graph work need `HG URN` coverage or an explicit `HG URN:` line.
- The project is framed as a control surface, not graph truth.
- The next board-to-HG step is no longer vague: active rows need identity repair before any G-direction board sync is trusted.

What remains:

- Row-level field update across the 55 project items was not applied in this sprint.
- The prior readback still matters: CLI item readback had 0 non-empty `HG URN` field values. Treat Project #4 as human-useful but not yet round-trip-safe.

Interpretation: the public board now says the right thing. The next implementation step is the actual row identity sweep.

### 3. Cytoscape typed-HG inspector

Status: implemented as an MVP operator surface.

What is done:

- `tmp/projections/session_pipeline/index.html` now has Cytoscape.js inspector tabs for Session Occasion and T189 Recommendations.
- The T189 recommendation lens now includes `calendar_event` in the selected node types.
- The latest T189 recommendation graph artifact reports 46 nodes and 58 relations, with the 16 Calendar event observations visible.

What remains:

- The only MVP warning is still visual lens root coverage for the session-occasion lens: disconnected forced roots remain visible as disconnected, which is honest for the current narrow lens.

Interpretation: the interactive inspector exists and is doing the job for this slice. Future work is richer lens control and durable `view_filter` promotion, not basic renderer existence.

### 4. Reusable lens and reconciliation language

Status: implemented in code, reports, and skills.

What is done:

- The T189 recommendation lens now filters for `calendar_event` nodes.
- Reconciliation now reports grouped rows, Calendar event nodes, Calendar event session pins, pending rows, and deferred WF07 rows separately.
- The MVP gate now treats Calendar event nodes/session pins as apply-ready rows and keeps WF07 anchors as a named deferred boundary.
- Skills now use the lingo: projection, writer, reconciliation, lens, control surface, and F/G boundary.

Interpretation: the pipeline has the language needed for future slices. It can answer "what is applied?" without mixing that up with "what is deferred?"

### 5. `my-tiny-data-collider` application group

Status: graph carrier applied and public framing refreshed.

What is applied:

- `group:my-tiny-data-collider` is part of the grouped T189 recommendation apply.
- `purpose:sam.my-tiny-data-collider-application` and `program:sam.t192.application-group-model-my-tiny-data-collider` are also in the grouped carrier set.
- The public org profile now names application domains as HG group/purpose/program/channel families above the kernel/router substrate.

What remains:

- The actual website/DNS/server/content shape for `my-tiny-data-collider` still needs its own projection/ingest plan.
- That plan should not live in `moos-kernel` or `moos-router`; those repos remain runtime substrate.

Interpretation: the application group is now a real carrier, not just a phrase. The next move is to give it its own surface map.

## Answer 2: Google Calendar projection status

The Google Calendar projection was run as an explicit writer boundary after the plan was generated. The result was safe and idempotent:

- Writer mode: `write`.
- Event count: 16.
- Actions: 16 `patch` actions.
- Duplicate inserts: 0.
- Identity key: private extended property `moos_projection_id`.

This means Google Calendar already had the projected events and the writer updated them in place. The Calendar API result and the HG readback are separate facts:

- Google Calendar side: 16 external events exist and were patched/upserted.
- HG side: 16 `calendar_event` observation nodes exist and are pinned into `session:sam.governance`.

This is the right F/G shape: `F` projects the Calendar plan out to Google Calendar, the writer performs the explicit external effect, and `G` observes the external result back into HG as typed nodes.

## Five active skills assessed and updated

### `moos-tooling-dx`

Added T189 projection-control DX rules:

- Run projection commands from the repo root or use full paths.
- Keep one-shot actuators out of ignored projection folders.
- Expose applied, pending, and deferred rows separately.
- Treat public surfaces as identity-stable projection targets.

Why it matters: this turns the path-slip and one-shot-script lessons into reusable operator discipline.

### `moos-session-context-projection`

Added the current pipeline shape and lingo:

- Reconciliation.
- Lens.
- Control surface.
- Calendar writer/readback boundary.
- GitHub org/project as projection surfaces.

Why it matters: future agents should not confuse local generated artifacts, Google Calendar writes, GitHub Project rows, and HG truth.

### `moos-state-readback`

Added projection/public-surface readback commands:

- Full Windows path discipline.
- `gh` org/project checks.
- Calendar credential check shape.
- A `surfaces:` reporting row.

Why it matters: round-open readback now includes the surfaces most likely to drift from HG.

### `moos-categorical-research`

Added a worked example for identity-stable projection surfaces:

- External surfaces as functorial projections from folded HG.
- Unit/counit test as identity stability.
- Drift as unresolved or low-similarity binding rather than a vague mismatch.

Why it matters: the T200 goal now has a clean categorical reading that is directly tied to implementation boundaries.

### `moos-rewrite-envelope`

Added a concrete T189 Calendar observation example:

- `calendar_event` ADD shape.
- WF19 session pin shape.
- Explicit instruction not to apply WF07 `anchors/anchor` until the operad declaration is resolved.

Why it matters: future Calendar readback can be applied without re-deriving the envelope shape or accidentally crossing the deferred WF07 boundary.

## Code and artifact changes

The implementation changes are narrow and projection-lane-focused:

- `dev/scripts/t189_recommendation_reconciliation.jl` now counts Calendar event nodes and Calendar session pins as first-class applied/pending rows.
- `dev/scripts/session_pipeline_mvp_gate.jl` now gates on grouped rows plus Calendar event nodes/session pins and keeps WF07 anchors as explicit deferred rows.
- `dev/scripts/export_t200plus_projection.jl` and `dev/scripts/projections/run-session-pipeline.ps1` include `calendar_event` in the T189 recommendation lens.
- `dev/scripts/tests/test_t189_recommendation_reconciliation.jl` and `dev/scripts/tests/test_session_pipeline_mvp_gate.jl` cover the new reconciliation/gate semantics.
- Generated artifacts under `tmp/projections/session_pipeline/` now show the applied Calendar event readback.

## Validation

Latest confirmed results:

- Runtime health: `status=ok`, `ontology_version=3.16.1`, `t_day=189`, `log_len=1154`.
- T189 recommendation reconciliation test: 23/23 pass.
- MVP gate tests: 38/38 plus 4/4 gap tests pass.
- Calendar time-fabric tests: 12/12 pass.
- T189/T200 recommendation projection tests: 15/15 pass.
- Full session pipeline: `warn`, 18 pass, 1 warn, 0 fail.
- Remaining warning: `visual lens root coverage` on the session-occasion lens.

The warning is acceptable. It says forced roots are visible but not relation-connected under the current session-occasion lens; it does not mean the T189 Calendar/recommendation apply is incomplete.

## Public surfaces updated

### GitHub Project #4

The project description/readme now states:

- The board is a public-facing control surface for the mo:os convergence arc.
- HG state remains authoritative.
- `moos-kernel`, `moos-router`, `ffs0`, and application groups have separate roles.
- Rows that represent graph work need `HG URN` coverage before board edits become rewrite candidates.
- T189 status includes the 16 Calendar event observations, 16 Calendar pins, writer upsert behavior, and WF07 deferred boundary.

### Collider-Data-Systems organization profile

The public org profile now states:

- `moos-kernel` is the OS-facing rewriting runtime.
- `moos-router` is the WF16 federation gateway.
- External systems are projection/ingest surfaces, not truth stores.
- Calendar events and Project rows need stable graph identity.
- Application domains such as `my-tiny-data-collider` are HG group/purpose/program/channel families above the runtime substrate.

## T200 vision from this slice

The T200 shape is now clearer: mo:os should not become one giant app, one giant dashboard, or one giant sync daemon. It should become a disciplined graph substrate where each external surface has a named contract.

The pattern is:

```text
folded HG state
  -> planner artifact
  -> explicit writer or local surface
  -> external object with graph identity
  -> readback observation into HG
  -> reconciliation report
  -> gate/dashboard
```

Calendar proved the loop at small scale. GitHub Project #4 is halfway there: public narrative and project README are aligned, but row identity still needs repair. The organization profile is now a public explanation of the architecture rather than a stale snapshot. `my-tiny-data-collider` becomes the first application group that can use the same machinery for websites, DNS, servers, content, data products, and Workspace surfaces.

This is the useful lingo for the next round:

- **Truth:** folded HG state from kernel logs.
- **Surface:** Calendar, Project, dashboard, org profile, website, DNS, Workspace, local OS host.
- **Projection:** HG to surface.
- **Observation:** surface back to HG.
- **Identity:** HG URN, `moos_projection_id`, or equivalent stable binding.
- **Reconciliation:** applied, pending, deferred.
- **Gate:** whether the current surface is safe enough to use as an operator view.

## Next recommended moves

1. Resolve the WF07 top-level declaration so the 16 Calendar source-anchor relations can become an ordinary apply batch.
2. Run a Project #4 row identity repair pass and populate `HG URN` coverage for active rows.
3. Promote reusable lens contracts toward `view_filter` carriers only where the lens is stable enough to deserve graph identity.
4. Give `my-tiny-data-collider` a first explicit surface map: website, DNS, GitHub repo/project, Calendar/Workspace channels, server/runtime lane, and readback contract.
5. Keep the runtime repos boring: kernel correctness in `moos-kernel`, routing correctness in `moos-router`, application projections elsewhere.
