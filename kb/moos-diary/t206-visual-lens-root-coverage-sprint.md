# T206 Visual Lens Root Coverage Sprint

## Executive Status

The next-sprint implementation target was the last session-pipeline warning: visual lens root coverage. The hp-laptop runtime is unchanged at `ontology_version=3.16.2`, `t_day=206`, `log_len=1467`; no HG rewrites and no external Calendar writes were performed.

The regenerated session pipeline now reports `pass`: 24 pass, 0 warn, 0 fail.

## Plan And Design

The root cause was a projection-lens mismatch, not missing HG topology. The explicit session-occasion roots already had folded relations:

- WF20 `promotes` / `promoted-from` from the session-occasion instruction to the occasion grammar fragment.
- WF19 `pins-urn` / `pinned-by-session` from the Z440 rejoin session to the continuity workflow.
- WF07 `anchors` / `anchor` from applied Calendar source observations to the session-occasion roots.

The session-occasion graph lens still used stale WF20 port labels and did not admit the WF19/WF07 relation families needed for root coverage. The design fix was to widen the lens to existing, valid topology rather than apply new relations.

Widening the visual lens also exposed a second boundary: Calendar time-fabric planning must not treat visual context nodes as fresh Calendar G-readback candidates. The runner now locks the Calendar planner to the source URNs present in the stored writer result when that result exists.

## Implementation

- `dev/scripts/graph_artifact_projection.jl` and `dev/scripts/export_t200plus_projection.jl` align the session-occasion lens with WF07, WF19, WF20, and the ontology's actual `promotes` / `promoted-from` ports.
- `dev/scripts/calendar_time_fabric_projection.jl` has an explicit written-source lock, reported in JSON and Markdown.
- `dev/scripts/projections/run-session-pipeline.ps1` enables that lock against `calendar_time_fabric_write_result.json`.

## Validation

- `test_graph_artifact_projection.jl`: 33/33 pass, including the new default-root fixture.
- `test_calendar_time_fabric_projection.jl`: 28/28 pass, including the written-source lock fixture.
- `test_session_pipeline_mvp_gate.jl`: 102/102 pass.
- `test_t189_t200_recommendation_projection.jl`: 20/20 pass.
- `test_t189_recommendation_reconciliation.jl`: 29/29 pass.
- Full `run-session-pipeline.ps1`: `pass`, 24 pass / 0 warn / 0 fail.

## Next Sprint

- Keep raw T195-T206 note ingest remains postponed until Sam approves structured source notes.
- Google Keep OAuth scope approval remains external to the repo/runtime.
- With the projection gate all-pass, the next local IDE-facing work can focus on S0 conversation staging keys, scoped-idle session seating by reviewed payload, Z440 rejoin, Project #4 HG URN coverage, and `my-tiny-data-collider` surface mapping.