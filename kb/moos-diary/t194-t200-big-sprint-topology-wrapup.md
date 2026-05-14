# T194/T200 Big Sprint Topology Wrapup

**T-day:** T=194
**Date:** 2026-05-14
**Kernel/session:** `urn:moos:kernel:hp-laptop.primary` / `urn:moos:session:sam.governance`
**Actor:** `urn:moos:agent:vscode.hp-laptop.copilot`
**Runtime readback:** hp-laptop `localhost:8000` ok, `ontology_version=3.16.1`, `t_day=194`, `log_len=1354`; router `localhost:9000` ok with local hp-laptop up and Z440 still down
**Lane:** T187/T189/T200+ topology solidification, Calendar readback convergence, scoped session delegation staging

## Executive Status

This sprint moved the T187/T189/T200+ projection family from a large planning surface into folded HG topology on hp-laptop primary. The planner read live state plus the generated Calendar/recommendation artifacts, then emitted only safe `ADD` and `LINK` rewrites: no WF07 source anchors, no new `has-occupant` relations, and no Z440 live delegation while the Z440 peer remains down.

Two reviewed batches landed:

- `dev/scripts/ops/t194-t200-big-sprint-session-topology.program.json`: the main 145-envelope topology batch, applied at `2026-05-14T21:45:00Z`, moving hp-laptop readback to `log_len=1338`.
- `dev/scripts/ops/t194-t200-big-sprint-session-topology.candidate.program.json`: a 15-envelope Calendar catch-up batch, applied at `2026-05-14T21:45:57Z`, moving hp-laptop readback to `log_len=1354`.

The catch-up was necessary because applying the new scoped sessions changed the projection surface. After the first batch, the full pipeline found five additional Calendar observations for the newly visible session/group/agent scope. The second batch applied those five `calendar_event` nodes plus governance and Calendar-readback session pins. Post-apply topology planning now returns `0` remaining envelopes.

## New Scoped Session Lanes

The sprint created five T200+ session lanes. They are scoped and pinned, but intentionally idle. No actor may emit as one of these lanes until a reviewed occupant relation seats that actor.

- `urn:moos:session:sam.t200plus-calendar-readback`: Calendar readback and WF07 cleanup.
- `urn:moos:session:sam.t200plus-project-bridge`: GitHub Project identity bridge and board round-trip safety.
- `urn:moos:session:sam.t200plus-s0-staging`: VS Code/Copilot conversation staging before G-ingest.
- `urn:moos:session:sam.t200plus-application-surface-map`: application group and public/private surface mapping, including `my-tiny-data-collider`.
- `urn:moos:session:sam.t200plus-z440-rejoin`: Z440 rejoin and delegation staging while the peer is offline.

The portable projection config `dev/config/session-affordance-map.json` mirrors these rows as scoped-idle affordances. Each row has an empty `actor_urn`, candidate actor suggestions, and an emission policy that forbids lane emits before occupancy is explicitly reviewed.

## Calendar And Recommendation Reconciliation

The final regenerated recommendation reconciliation is closed for the safe rows:

- Grouped nodes: 10/10 applied.
- Grouped safe relations: 16/16 applied.
- Calendar event nodes: 22/22 applied.
- Calendar event session pins: 22/22 applied.
- Pending Calendar event nodes: none.
- Pending Calendar event session pins: none.
- Deferred relations: 22 WF07 `anchors/anchor` rows.

WF07 remains deferred for the same operad reason as before: `calendar_event` exposes the desired `anchors` port shape, but the top-level WF07 declaration still names `participates/participated-by`. This sprint deliberately did not paper over that mismatch.

## Projection Gate

After the catch-up batch, the session pipeline completed with:

- MVP gate: `warn`, 23 pass / 1 warn / 0 fail.
- Remaining warning: visual lens root coverage.
- T189 recommendation reconciliation: pass.
- Deferred apply boundaries: pass, with WF07 explicitly deferred.
- Dashboard: `tmp/projections/session_pipeline/index.html`.

The final gate JSON was refreshed after the full pipeline, and `tmp/projections/session_pipeline/mvp/session_pipeline_gate.json` is non-empty and parseable. The dashboard still uses Graphviz DOT/SVG as deterministic visual proof and Cytoscape.js as the typed interactive inspector surface.

## Planner And Apply Records

New repeatable planner:

- `dev/scripts/t194_t200_big_sprint_topology.jl`
- `dev/scripts/tests/test_t194_t200_big_sprint_topology.jl`

Generated/readback artifacts:

- `tmp/projections/session_pipeline/topology/t194_t200_big_sprint_topology_audit.json`
- `tmp/projections/session_pipeline/topology/t194_t200_big_sprint_topology_audit.md`
- `tmp/projections/session_pipeline/topology/catchup.postapply.audit.json`
- `tmp/projections/session_pipeline/topology/catchup.postapply.audit.md`
- `tmp/projections/session_pipeline/topology/catchup.postapply.program.json` with `0` envelopes

Both applied ops records are marked `applied=true` and `do_not_reapply=true`. The main planner now protects the applied main record by writing a `.candidate.program.json` record if fresh pending rows appear later.

## Validation

Validation after the final apply:

- `dev/scripts/tests/test_t194_t200_big_sprint_topology.jl`: 11/11 pass.
- All 11 Julia test files under `dev/scripts/tests/test_*.jl`: pass.
- JSON parse passed for `dev/config/session-affordance-map.json`, both T194/T200 ops records, `session_pipeline_gate.json`, and `t189_recommendation_reconciliation.json`.
- `git diff --check`: pass.
- hp-laptop health: `status=ok`, `ontology_version=3.16.1`, `t_day=194`, `log_len=1354`.

## Deferred Boundaries

The remaining work is named rather than hidden:

- Repair or review WF07 source-anchor semantics before applying any Calendar `anchors/anchor` relations.
- Turn the forced session-occasion roots into real topology with valid WF18/WF19/WF21 relations, or keep the visual-root warning visible.
- Seat occupants for the new T200+ lanes only after explicit review; until then they are scoped-idle.
- Rejoin Z440 before treating the Z440 lane as live delegation.
- Continue Project #4 `HG URN` coverage and board G-sync only after identity rows are unambiguous.
- Use the S0 staging lane for VS Code transcript/debug-log material before turning conversation state into KIs, claims, derivations, purposes, or programs.

## Current Reading

The graph is now in the shape the next sprint needed: governance still has the current VS Code/Copilot occupant, Calendar safe readback is converged, the T200+ work is split into delegable lanes, and the dashboard's only remaining warning is a real topology-design warning rather than an unapplied Calendar backlog.
