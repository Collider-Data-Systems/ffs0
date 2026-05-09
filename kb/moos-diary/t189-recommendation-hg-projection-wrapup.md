---
title: "T189 report: recommendation HG projection and T200 node/relation plan"
date: 2026-05-09
t_day: 189
covers_t_days:
  - 189
actor_urn: urn:moos:agent:claude-code.hp-laptop
session_urn: urn:moos:session:sam.governance
candidate_hg_type: knowledge_item
candidate_hg_urn: urn:moos:ki:guido.t189.recommendation-hg-projection-wrapup
projection_surfaces:
  - local HTML dashboard
  - recommendation HG JSON plan
  - recommendation HG Markdown report
  - Calendar time-fabric plan
  - DOT/SVG graph projection
source_artifacts:
  - dev/scripts/t189_t200_recommendation_projection.jl
  - dev/scripts/tests/test_t189_t200_recommendation_projection.jl
  - dev/scripts/projections/run-session-pipeline.ps1
  - dev/scripts/session_pipeline_mvp_gate.jl
  - tmp/projections/session_pipeline/recommendations/t189_t200_recommendation_hg_plan.json
  - tmp/projections/session_pipeline/recommendations/t189_t200_recommendation_hg_plan.md
  - tmp/projections/session_pipeline/index.html
related_hg_urns:
  - urn:moos:session:sam.governance
  - urn:moos:purpose:sam.doctrine-governance-and-delegation
  - urn:moos:purpose:sam.t189-t200plus-time-fabric-convergence
  - urn:moos:program:sam.t189.calendar-event-g-ingest-shape
  - urn:moos:program:sam.t189.github-project-urn-refresh
  - urn:moos:program:sam.t189.cytoscape-typed-hg-inspector
  - urn:moos:view_filter:sam.t189-time-fabric-session-lens
  - urn:moos:group:my-tiny-data-collider
  - urn:moos:program:sam.t200plus.identity-stable-projection-surface-convergence
---

# T189 Report: Recommendation HG Projection And T200 Node/Relation Plan

This report closes the second T189 sprint after the Calendar/dashboard/organization wrap-up. The instruction for this sprint was to use the five T189 recommendations, choose what should be individual and what should be grouped, analyze first, implement the projection, and then explain the result as HG structure rather than loose temporal talk.

The short version: the five recommendations are now projected as a dry candidate HG plan. The individual choice is Calendar G-ingest: each real Google Calendar write should become its own `calendar_event` node with `date`, `t_day`, `gcal_id`, `color_label`, and `status`. The grouped choice is the T189/T200 continuation itself: a purpose, programs, a `view_filter`, and the `my-tiny-data-collider` group carry the broader lane. The runner and dashboard now project those recommendations beside the Calendar artifacts. Latest runner result: `warn`, 13 pass, 2 warn, 0 fail.

## Starting Point

The prior report left five T189 recommendations:

1. Commit the Calendar/dashboard/source-doc WIP after validation.
2. Decide the G-ingest shape for the 16 Calendar events.
3. Refresh GitHub Project #4 by restoring `HG URN` coverage.
4. Prototype a small Cytoscape.js inspector beside Graphviz.
5. Promote the lens spec to reusable JSON, then later to a `view_filter` if reused.

Sam approved the direction and sharpened the model: use the time fabric by using the ontology. IRL is not mystical time. It is events with T-related properties. Programs may have T properties when they are scheduled or targeted, but they do not need to become IRL events directly.

That framing ruled out a vague temporal abstraction. The implementation uses existing ontology nodes and relations: `calendar_event`, `program`, `purpose`, `view_filter`, `group`, WF01, WF07, WF18, WF19, and WF21.

## Analysis Before Implementation

The ontology already has the pieces needed for a clean dry plan.

`calendar_event` is the individual IRL event carrier. It has immutable `summary`, `date`, `t_day`, `gcal_id`, `color_label`, and mutable kernel-status. That is the right shape for the 16 written Google Calendar events because they are external events that can drift independently.

`program` is the planned-work carrier. It already has mutable `starts_t`, `target_t`, `deadline_t`, and `completed_t`. That means a program can be scheduled, but it does not need to be a Calendar event. A Calendar event may participate in or anchor a program, but the program remains the work node.

`purpose` is the directional umbrella. It composes programs through WF18.

`view_filter` is the reusable lens carrier. It is the right next form for the current session/time-fabric lens before any new ontology type is justified.

`group` is the application-domain carrier. `my-tiny-data-collider` belongs there: application group first, not kernel repo, not router repo.

The one ontology wrinkle is useful rather than blocking. `calendar_event` declares an `anchors` out port and the ontology's port-color compatibility table mentions WF07 `anchors/anchor`, but the top-level WF07 declaration still names `participates/participated-by`. The recommendation projection therefore emits Calendar source-anchor links as deferred checks, not as apply-ready relations. That is the right discipline: expose the intended relation and the operad ambiguity before writing envelopes.

## What Changed

New planner:

```text
dev/scripts/t189_t200_recommendation_projection.jl
```

New test:

```text
dev/scripts/tests/test_t189_t200_recommendation_projection.jl
```

New generated artifacts:

```text
tmp/projections/session_pipeline/recommendations/t189_t200_recommendation_hg_plan.json
tmp/projections/session_pipeline/recommendations/t189_t200_recommendation_hg_plan.md
```

The planner reads the ontology, the Calendar time-fabric plan, and the Calendar write result. It outputs candidate nodes, candidate relations, deferred relation checks, the selected five T189 recommendations, and a T200+ recommendation list. It does not emit rewrites.

The session pipeline runner now includes this step after Calendar projection and before the MVP gate. The dashboard now has an `HG Recommendations` panel with links to the JSON and Markdown recommendation artifacts. The gate has a new passing check, `T189/T200 recommendation artifacts`, requiring a non-empty candidate-node plan and exactly five selected T189 recommendations.

## Calendar G-Ingest Shape

The chosen shape is hybrid.

Individual side: create one `calendar_event` node for each real Google Calendar write. These are IRL events with T properties. For the 16 proof events, the dry plan creates 16 candidate `calendar_event` nodes, each with:

- `summary`
- `date`
- `t_day`
- `gcal_id`
- `color_label`
- `status`
- `created_at`

Grouped side: create one derivation node that records the decision and causes the Calendar G-ingest program:

```text
urn:moos:derivation:guido.t189-calendar-event-g-ingest-decision
urn:moos:program:sam.t189.calendar-event-g-ingest-shape
```

Session scope side: candidate WF19 `pins-urn` relations pin the individual event nodes and the grouped decision/program into `session:sam.governance`.

Deferred source-anchor side: candidate WF07 `anchors/anchor` relations from each `calendar_event` to the source HG URN are listed as `requires-operad-review`. That preserves the intended topology without pretending the loader has already accepted that port pair as apply-ready.

## The Five T189 Recommendations As Nodes

The dry plan models the five recommendations as candidate graph structure:

| Recommendation | Carrier | Mode |
| --- | --- | --- |
| Calendar G-ingest shape | `program:sam.t189.calendar-event-g-ingest-shape` plus 16 `calendar_event` nodes | individual plus group |
| GitHub Project HG URN refresh | `program:sam.t189.github-project-urn-refresh` | group |
| Cytoscape inspector | `program:sam.t189.cytoscape-typed-hg-inspector` | group |
| Reusable lens spec | `view_filter:sam.t189-time-fabric-session-lens` | group |
| Application group model | `group:my-tiny-data-collider` | group |

The umbrella purpose is:

```text
urn:moos:purpose:sam.t189-t200plus-time-fabric-convergence
```

The T200 convergence carrier is:

```text
urn:moos:program:sam.t200plus.identity-stable-projection-surface-convergence
```

Candidate WF18 relations compose the umbrella purpose into the grouped programs. Candidate WF19 relations pin the purpose, programs, lens, decision derivation, and event nodes into `session:sam.governance`. Candidate WF01 relations make `group:my-tiny-data-collider` own its application purpose.

## T200+ Recommendations As HG Work

The T200 recommendations are now phrased as graph work, not as generic future prose.

T189-T190: land the Calendar G-ingest shape. Apply the individual `calendar_event` nodes after reviewing the deferred WF07 anchor relation. This makes Calendar readback a proper G-direction observation, not only a write-result JSON file.

T190: repair GitHub Project identity. Reproject active Project #4 rows from HG and populate `HG URN`. Only after identity coverage is restored should board edits become candidate MUTATEs.

T190-T191: add the Cytoscape.js typed HG inspector. Feed it the existing graph artifact JSON. Keep Graphviz as deterministic review output; add Cytoscape for selection, filtering, and inspector affordances.

T191-T192: model `my-tiny-data-collider` as an application group. The first application graph should be `group + purpose + program family + channels`, with websites, DNS, GitHub, Calendar, Workspace, and servers as projection/ingest boundaries.

T192-T200: converge identity-stable projection surfaces. Calendar events, GitHub rows, dashboard artifacts, website pages, DNS records, Workspace items, and future OS-host channels should all carry graph-derived identity and have explicit dry planner, writer, and readback adapters.

## Projection Result

Focused tests passed:

- Recommendation projection test: 15/15.
- Session pipeline MVP gate test: 27/27.

Full runner result:

- Session context pack: generated.
- Graph artifact pack: 16 nodes, 20 relations, 5 findings.
- Session-occasion visual: DOT/SVG generated.
- Temporal/calendar visual: DOT/SVG generated.
- Calendar plan/report: 16 events.
- Recommendation plan/report: 26 candidate nodes, 32 candidate relations, 16 deferred relation checks.
- MVP gate: `warn`, 13 pass, 2 warn, 0 fail.

The two remaining warnings are still the intended ones: disconnected forced visual roots and no interactive Cytoscape.js inspector yet.

## Next Apply Candidates

The recommendation artifact is deliberately dry. The next apply-ready work should be reviewed in this order:

1. Apply the grouped purpose/program/view_filter/group candidate nodes and safe WF18/WF19/WF01 relations.
2. Decide whether to apply the 16 `calendar_event` nodes now or after a fresh Calendar readback.
3. Resolve the WF07 `anchors/anchor` ambiguity before applying Calendar source-anchor relations.
4. Re-run Project #4 readback after `HG URN` repair and generate a board projection plan.
5. Build the Cytoscape inspector against the existing graph artifact JSON, not a new data model.

## Reification Candidate

Candidate umbrella URN:

```text
urn:moos:ki:guido.t189.recommendation-hg-projection-wrapup
```

Suggested relations later:

- WF18 `composes/composed-by` from the umbrella to section chunks.
- WF19 `pins-urn` from `session:sam.governance` while this remains active T189/T200 context.
- WF21 `caused-by` from the report to `program:sam.t189.calendar-event-g-ingest-shape`, `program:sam.t189.github-project-urn-refresh`, and `program:sam.t200plus.identity-stable-projection-surface-convergence` once those nodes are applied.
