---
title: "T189 report: Calendar, dashboard, organization, and kernel/application boundary"
date: 2026-05-09
t_day: 189
covers_t_days:
  - 189
actor_urn: urn:moos:agent:claude-code.hp-laptop
session_urn: urn:moos:session:sam.governance
candidate_hg_type: knowledge_item
candidate_hg_urn: urn:moos:ki:guido.t189.calendar-dashboard-organization-wrapup
projection_surfaces:
  - Google Calendar
  - local HTML dashboard
  - DOT/SVG graph projection
  - GitHub organization
  - GitHub Projects v2 board
  - repository README and agent instruction files
source_artifacts:
  - dev/scripts/calendar_time_fabric_projection.jl
  - dev/scripts/google_calendar_writer.jl
  - dev/scripts/projections/run-session-pipeline.ps1
  - dev/scripts/session_pipeline_mvp_gate.jl
  - tmp/projections/session_pipeline/index.html
  - tmp/projections/session_pipeline/calendar/calendar_time_fabric_plan.json
  - tmp/projections/session_pipeline/calendar/calendar_time_fabric_write_result.json
  - tmp/projections/session_pipeline/visual/session_occasion_frame.svg
  - tmp/projections/session_pipeline/visual/temporal_calendar_frame.svg
related_hg_urns:
  - urn:moos:session:sam.governance
  - urn:moos:purpose:sam.doctrine-governance-and-delegation
  - urn:moos:channel:google.calendar.sam
  - urn:moos:program:sam.t200plus.temporal-projection-fabric
  - urn:moos:program:sam.t200plus.google-calendar-projection-contract
  - urn:moos:program:sam.t200plus.google-calendar-projection-planner
  - urn:moos:program:sam.t200plus.google-calendar-oauth-writer
  - urn:moos:derivation:guido.t200plus-google-calendar-write-result
  - urn:moos:purpose:sam.github-project-board-sync
  - urn:moos:channel:github.project.mo-os
---

## T189 Report: Calendar, Dashboard, Organization, And Boundary

This report continues the T187 Google Calendar projection report and the T188 session-pipeline MVP report. It covers the T189 continuation where Calendar stopped being only a proof surface and became part of the live governance session scope, where the local dashboard learned to show the Calendar/time-fabric lane, and where the GitHub organization/project-board surface was re-read as a projection surface rather than authority.

The short version: T189 made the current session wider and more honest. `session:sam.governance` now directly pins the existing Calendar/time-fabric program family. A new Calendar time-fabric planner projects recent HG graph-artifact nodes into Google Calendar payloads. A live writer inserted 16 `mo:os ...` events into Sam's primary Google Calendar. The dashboard now exposes that Calendar lane with a second temporal/calendar Graphviz surface. The GitHub organization and Project #4 remain part of the same project, but today they are external projection surfaces with drift: the board has many useful human rows but is not yet round-trip-safe because the current item readback reports no populated `HG URN` field values.

## Starting Point

The previous two reports established a pattern.

T187 proved that folded HG state can project outward into a real external surface. The Google Calendar planner compiled graph facts into event payloads, the writer performed an explicit OAuth/API actuator step, and a derivation recorded the result back in HG.

T188 wrapped the Keep/session/visual lane in a dry local pipeline. The G side ingested Keep evidence. The F side emitted a session context pack, graph engineering report, DOT/SVG visual, and local HTML control surface. The gate intentionally returned `warn` because it was usable but still carried visible next gates.

T189 began with Sam asking whether Calendar projection should use IRL time, T-day properties, WF21 causality, WF18 dependencies, or project timing. The answer became operational rather than only conceptual: use Calendar as one external time surface, keep HG as source of truth, and let the projection record which time interpretation it used.

## What Changed In The Graph

The decisive T189 move was not to add one isolated proof node. It was to widen the live session scope.

Six kernel-authored WF19 `pins-urn` relations were applied from `session:sam.governance` to the existing Calendar/time-fabric roots:

- `channel:google.calendar.sam`
- `derivation:guido.t200plus-google-calendar-write-result`
- `program:sam.t200plus.temporal-projection-fabric`
- `program:sam.t200plus.google-calendar-projection-contract`
- `program:sam.t200plus.google-calendar-projection-planner`
- `program:sam.t200plus.google-calendar-oauth-writer`

Runtime after those links: `ontology_version=3.16.1`, `t_day=189`, `log_len=1086`.

That was the better model move. A session is purpose, occupant, and scope evaluated from graph data. The Calendar/time-fabric program family is now inside the session's durable scope instead of only being remembered by this conversation or by a local JSON file. Regenerated session context now sees 9 scope roots.

## Calendar Time Fabric

The new planner is `dev/scripts/calendar_time_fabric_projection.jl`. It reads the current graph engineering artifact and emits a writer-compatible Calendar plan at `tmp/projections/session_pipeline/calendar/calendar_time_fabric_plan.json`, plus a Markdown report.

The planner maps each selected HG node into a stable Calendar event:

- `source_urn` and `source_type` become private extended properties.
- `moos_projection_id` is a stable SHA1-derived key from contract URN plus source URN.
- Explicit T fields such as `target_t`, `starts_t`, `deadline_t`, or `completed_t` become IRL dates through the T0 calendar epoch.
- Nodes without explicit T fields are placed by lens order from the active anchor T.
- Incoming/outgoing relation counts and short relation context are written into the event description.

The live proof inserted 16 `mo:os ...` events into Sam's primary Google Calendar. The result is still an F-direction projection: the Calendar event is visible and useful, but HG remains the source of truth. A manual Calendar edit is substrate drift until a future G-direction ingest observes it back into HG as `calendar_event` nodes, a compact derivation/result, or both.

## Dashboard And Visual Surface

The pipeline runner now regenerates more than the T188 session-occasion frame.

`dev/scripts/projections/run-session-pipeline.ps1` now runs:

1. Session context projection.
2. Graph artifact projection.
3. Session-occasion DOT/SVG export.
4. Temporal/calendar DOT/SVG export.
5. Calendar time-fabric planner.
6. MVP gate and HTML dashboard.

`tmp/projections/session_pipeline/index.html` now includes a `Calendar Time-Fabric` panel with links to the Calendar plan, Calendar report, write result, temporal SVG, and temporal DOT. It embeds `visual/temporal_calendar_frame.svg` beside the existing `visual/session_occasion_frame.svg` lane.

The gate now reports `warn`, 12 pass, 2 warn, 0 fail. The new passing checks are meaningful: static visual output now requires both session-occasion and temporal/calendar DOT/SVG files, and the Calendar time-fabric artifact gate requires a non-empty plan plus Markdown report. The remaining warnings are still the intended ones: disconnected forced roots under the current lens, and no interactive Cytoscape.js-style inspector yet.

After browser verification, the embedded SVG boxes were adjusted to keep a readable minimum graph width and scroll horizontally rather than shrinking the graph into an unreadable thumbnail.

## GitHub Organization And Project Board

The GitHub organization is part of the project, but it is not the project. The readback on T189 showed:

- Org: `Collider-Data-Systems`
- Repositories returned: 5 total
- Public repos: `moos-kernel`, `moos-router`, `.github`
- Private repos: `ffs0`, `demo-repository`
- Project #4: `mo:os`, active private project, 55 items, 19 fields
- Project status counts: 24 Done, 17 Todo, 14 In Progress
- Current CLI item readback reported 0 non-empty `HG URN` field values

That last point matters. The board already has useful human-visible rows: sessions, purposes, persona lanes, round handoffs, kernel tasks. But without populated `HG URN` fields, it is not yet round-trip-safe. The `moos-github-project-bridge` skill is correct in principle: `HG URN` is the key for the G direction. Until the board rows carry that key reliably, GitHub Projects is a planning/control surface with drift, not an authoritative state surface.

The recommendation is not to abandon the board. It is to treat it exactly like Calendar: an external surface with explicit F and G adapters. First project HG nodes outward with stable identities. Then ingest board edits back only when the item can be resolved to an HG URN and a valid rewrite.

## Kernel, Operating Systems, And Applications

Sam's T189 framing sharpened the boundary.

`moos-kernel` is not the application. It is the OS-facing function program: the runtime that folds the log, validates rewrites against the operad, enforces session liveness and admin capability, exposes transport surfaces, and eventually channels user data through a user-specified topology and preference layer.

The kernel is currently Go. Longer-term, the OS-facing shape may include a Rust extension layer for Linux and Windows: a host-resident substrate component that watches user-approved surfaces, channels data to the kernels, enforces local policy, and keeps actuator boundaries explicit. That Rust/OS layer should still be an extension of the runtime substrate, not the application domain itself.

`my-tiny-data-collider` is different. It is an application/domain group running on the HG through the kernels. It may include `.com` and `.org` websites, DNS, server infrastructure, data products, content surfaces, and public/private projection targets. It should be modeled as a group or program family inside HG, dominant for Sam's actual use but not identical to the kernel. There can be more such applications: each is a group, purpose, channel set, and program family inside the same HG substrate.

So the clean separation is:

| Layer | Entity | Role |
| --- | --- | --- |
| Runtime substrate | `moos-kernel` | Fold log, validate rewrites, enforce session/authority, expose transports and actuator leaves |
| Federation substrate | `moos-router` | Route and fan out across kernels by URN/type/topology |
| Research/control workspace | `ffs0` | Ontology source, reports, skills, projection planners, local operator surfaces |
| Application group | `my-tiny-data-collider` | One domain/use of the HG, likely dominant, but not the kernel itself |
| External surfaces | Calendar, GitHub, websites, DNS, Workspace | Projection/ingest boundaries with stable identity and explicit drift handling |

This separation keeps the kernel small and principled while allowing rich applications to grow on top of it.

## Design Reading

The recurring structure is now stable.

HG is the syntax and state substrate. The log is truth. The fold gives current state. The operad tells which rewrites and port pairs are valid. Sessions provide purpose-colored context and liveness. Programs decompose intent. Actuators touch outside surfaces. Derivations and knowledge items record what was inferred or observed.

Projection is F-direction:

```text
F: folded HG state -> Calendar events, GitHub board rows, dashboards, DOT/SVG, websites, DNS config, IDE context packs
```

Ingest is G-direction:

```text
G: external observations -> knowledge_item, claim, derivation, calendar_event, program, status MUTATE
```

Every external system needs the same discipline:

1. Stable graph-derived identity on the external artifact.
2. A dry planner before a writer.
3. An explicit writer/actuator boundary.
4. A G-direction readback that can detect drift.
5. A graph-side result node or event node when the observation matters.

Calendar and GitHub now make that discipline concrete. Websites and DNS should use the same shape later.

## Recommendations For The Rest Of T189

T189 should stay focused. Sam's Jeff Bridges window is a good forcing function: keep the round calm, do the obvious next things, and avoid speculative ontology edits unless the graph asks for them.

Recommended T189 sequence:

1. Commit the Calendar/dashboard/source-doc WIP as a focused ffs0 commit after validation.
2. Decide the G-ingest shape for the 16 Calendar events: one compact derivation/result, individual `calendar_event` nodes, or a hybrid.
3. Refresh Project #4 minimally by restoring/populating `HG URN` for the most active rows before attempting any board-to-HG MUTATE path.
4. Prototype a tiny Cytoscape.js inspector against the existing graph artifact JSON. Do not replace Graphviz; add the interactive lens beside it.
5. Promote the lens spec to a reusable JSON artifact. Only reify it as a `view_filter` node after two or three lanes reuse the same shape.

## Recommendations To T200

The period to T200 should be treated as a convergence arc rather than a feature grab bag.

Priority one: stabilize identity across projection surfaces. Calendar events, GitHub project rows, website pages, DNS records, and local dashboards should all carry graph-derived IDs or URNs. Without that, G-direction ingest becomes guesswork.

Priority two: implement the GitHub bridge MVP. A 200-line-ish F-direction sweep that populates Project #4 items from HG nodes with `HG URN`, status, repo, agent, and category would pay off immediately. G direction can remain conservative until field coverage is reliable.

Priority three: settle application grouping. Model `my-tiny-data-collider` as a group/purpose/program family in HG, with explicit channels for `.com`, `.org`, DNS, web hosting, GitHub, Calendar, and Workspace. Keep its repos and deployment code separate from `moos-kernel`.

Priority four: harden the kernel/OS boundary. Keep Go kernel work focused on log/fold/operad/session/transport correctness. Explore a Rust host extension only when the substrate contract is clear: file watchers, OS services, local credentials, policy enforcement, and user-approved data channels.

Priority five: make session projection the daily operating screen. `tmp/projections/session_pipeline/index.html` is already close. The T200 version should have static Graphviz, interactive Cytoscape.js, Calendar/GitHub projection status, runtime health, and a clear warning queue.

Priority six: reify reports through G-ingest instead of accumulating unbounded diary Markdown. This report can become one umbrella `knowledge_item` with section chunks under WF18, pinned to `session:sam.governance`, and related by WF21 to the Calendar/dashboard work.

## Current State After This Report

The system is in a good T189 state: not done, but much less blurry.

The kernel is live. The session scope includes Calendar. The dashboard shows the Calendar lane. Google Calendar has real proof events. The GitHub project has enough structure to be useful and enough drift to justify the bridge. The kernel/application distinction is now explicit enough to write into repo docs and agent instructions.

The next honest gate is round-trip identity: Calendar event IDs and GitHub project rows must become reliable external handles back to HG nodes. Once that is true, `my-tiny-data-collider` can be treated as a real application group on top of mo:os rather than as a tangle of infrastructure notes.

## How To Reify This Report Later

Candidate umbrella URN:

```text
urn:moos:ki:guido.t189.calendar-dashboard-organization-wrapup
```

Suggested links:

- WF18 `composes/composed-by` from umbrella to section chunks.
- WF19 `pins-urn` from `session:sam.governance` while this remains active T189/T200 context.
- WF21 `caused-by` from the report to the Calendar write result derivation and the dashboard/projection programs.
- Future bridge relation to `channel:github.project.mo-os` once GitHub Project rows carry reliable `HG URN` identity.
