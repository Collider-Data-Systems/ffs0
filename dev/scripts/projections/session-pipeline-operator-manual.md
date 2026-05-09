# Session Pipeline Operator Manual

This is the practical manual for the current mo:os projection filesystem at:

```text
C:\Users\maass\HPlaptop\ffs0\tmp\projections\session_pipeline
```

The short version: this directory is a generated workbench. It is intentionally a little messy because it is doing real projection work across graph state, local files, Google Calendar, Git, dashboard HTML, static visuals, and IDE context. The discipline is not to make it sterile; the discipline is that every file has a typed role, every external surface has an identity path back to HG, and every gate says whether the current mess is usable.

Use it with VS Code Explorer, the editor, Chrome tabs, and filesystem previews. On the Z440 four-screen setup, the intended flow is: dashboard open in Chrome, VS Code Explorer pinned to `tmp/projections/session_pipeline`, JSON/Markdown open in editor tabs, and SVG/DOT visual artifacts grouped in browser/editor tabs for fast comparison.

## One Command

Run from the ffs0 repo root:

```powershell
Set-Location 'C:\Users\maass\HPlaptop\ffs0'
powershell -NoProfile -ExecutionPolicy Bypass -File dev\scripts\projections\run-session-pipeline.ps1
```

Current expected result: `warn`, 19 pass, 1 warn, 0 fail. The remaining warning is the known session-occasion visual lens root-coverage warning: some forced roots are visible, but the deliberately narrow relation filter does not connect them all yet.

This command is dry. It reads folded HG state and writes local artifacts. It does not emit rewrites and does not write to Google Calendar. Real external writes remain explicit actuator steps, such as `google_calendar_writer.jl --mode write`.

## How To Use The Filesystem

Open `tmp/projections/session_pipeline/index.html` first. Treat it as the cockpit. It links the important JSON, Markdown, SVG, DOT, Calendar, recommendation, reconciliation, atlas, and gate outputs.

Then use the folders as evidence trays:

```text
tmp/projections/session_pipeline/
  index.html             local dashboard / cockpit
  README.md              local output note, generated-side convenience
  session_context/       IDE/agent/harness context pack
  graph_artifacts/       selected HG lens engineering reports
  visual/                Graphviz DOT/SVG proof visuals
  calendar/              Calendar projection plans and writer results
  recommendations/       T189/T200 candidate HG plans and reconciliation
  atlas/                 generated surface atlas for humans and agents
  mvp/                   gate JSON/Markdown and dashboard support
```

The generated outputs are local materializations. They are not the truth source and normally should not be committed. The truth chain is:

```text
kernel JSONL log -> folded HG state -> projection artifacts -> dashboard / Calendar / GitHub / docs
```

The dashboard and files make the graph usable, but the graph remains authoritative.

## File Types

### `.html`

`index.html` is the human control surface. Open it in Chrome or the VS Code browser. It shows runtime metadata, pass/warn/fail gates, artifact links, Graphviz visuals, Calendar and recommendation panels, the Surface Context Atlas panel, and Cytoscape.js inspector tabs.

Use it to navigate, not to infer truth by itself. When something matters, open the linked JSON or Markdown artifact behind it.

### `.json`

JSON files are machine-readable typed projection outputs. They are the best files for agents, scripts, reconciliation, and future automation.

Examples:

- `session_context/current_session.json` projects the active session occasion: kernel, session, occupant, purpose, scope roots, skills, extensions, MCP affordances, and handoff shape.
- `graph_artifacts/session_occasion_engineering.json` and `graph_artifacts/t189_recommendation_engineering.json` hold selected nodes, selected relations, roots, filters, findings, and Cytoscape-ready elements.
- `calendar/calendar_time_fabric_plan.json` is the dry F-direction Calendar event plan.
- `calendar/calendar_time_fabric_write_result.json` records the explicit Calendar writer result when the writer has been run.
- `recommendations/t189_t200_recommendation_hg_plan.json` is the dry candidate HG plan for the T189/T200 recommendation lane.
- `recommendations/t189_recommendation_reconciliation.json` compares the dry plan to folded state and separates applied, pending, and deferred rows.
- `atlas/surface_context_atlas.json` is the high-level table of contents for all surfaces and pending moves.
- `mvp/session_pipeline_gate.json` is the structured gate report.

### `.md`

Markdown files are human-readable reports paired with the JSON. Open them when you want the gist without spelunking through fields.

Use Markdown for reading, summarizing, and copying into reports or public-facing text. Use JSON when a script or agent needs exact counts, URNs, filters, or evidence.

### `.dot`

DOT files are Graphviz source. They are the deterministic visual proof layer: stable, local, inspectable text.

Use DOT when you want to audit what the visual renderer was actually asked to draw, change a graph lens, or compare why two SVGs differ.

### `.svg`

SVG files are the rendered Graphviz visuals. They are good for Chrome tabs, large monitors, screenshots, and fast topology inspection.

Current visual lenses include:

- `visual/session_occasion_frame.svg` for the session-occasion implementation frame.
- `visual/temporal_calendar_frame.svg` for Calendar/time-fabric topology.
- `visual/t189_recommendation_frame.svg` for the T189 recommendation lane, including Calendar event observations.

### `.jsonl`

The active kernel log is not inside `tmp/projections/session_pipeline`; it lives in the sibling runtime repo, currently `C:\Users\maass\HPlaptop\moos-kernel\moos.jsonl`.

JSONL is the append-only source persisted by the kernel. The pipeline reads folded state via HTTP JSON endpoints, not by treating the JSONL file as a dashboard. Keep the distinction sharp:

```text
JSONL log = persisted rewrite stream
JSON API = folded graph state at the current log prefix
projection files = local views over folded state
```

## Typed Data Flow

### 1. G Ingest: Keep Notes Into HG

The current lane began with a G-direction observation from Google Keep. The external note was represented in HG as typed evidence: a Keep channel, knowledge item, claims, derivation, and related program/session carriers.

In graph terms, the external source does not become truth directly. It becomes typed HG evidence:

```text
Google Keep / Workspace source
  -> channel:google.keep.sam
  -> knowledge_item / claim / derivation / program nodes
  -> relations that pin and explain the evidence
```

The relevant skill is `moos-workspace-ingest`. Use it when a Gmail thread, Calendar event, Drive doc, Tasks item, Keep-like export, or Cowork artifact needs to become HG evidence. The important rule is one atomic batch per source and explicit `session_urn` on every envelope.

### 2. Session And Occupancy

The current VS Code/agent occasion is not just a chat window. It is evaluated through session machinery.

Current hp-laptop lane:

```text
kernel:hp-laptop.primary
session:sam.governance
agent:claude-code.hp-laptop
purpose:sam.doctrine-governance-and-delegation
```

The session has:

- A kernel place: where rewrites are evaluated.
- An occupant: which agent is currently driving the session.
- A purpose: why this session is active.
- A scope: pinned URNs and reachable topology, including Calendar/time-fabric, T189 recommendation carriers, Calendar event observations, and the surface context atlas carrier.

The session context projection turns that evaluated occasion into files:

```text
folded HG session state
  -> session_context/current_session.json
  -> session_context/current_session.md
```

Use this when you want VS Code, Copilot, Claude Desktop, Cursor, or another harness to stay aligned with the same kernel/session/occupant/purpose/scope.

### 3. F Projection: HG To Local Files

Most of this filesystem is F-direction projection:

```text
folded HG state
  -> session context pack
  -> graph engineering reports
  -> DOT/SVG visual lenses
  -> Calendar event payload plan
  -> recommendation candidate HG plan
  -> reconciliation report
  -> surface context atlas
  -> dashboard
```

These files are dry outputs. They explain what would be done, what is visible, and what has already landed. They do not mutate HG by themselves.

### 4. Explicit Writers

When a projection leaves the local filesystem and touches an external system, it becomes an actuator boundary.

Example: Google Calendar.

```text
calendar_time_fabric_plan.json
  -> google_calendar_writer.jl --mode dry-run
  -> google_calendar_writer.jl --mode write
  -> calendar_time_fabric_write_result.json
```

The writer upserts by `moos_projection_id`, so repeated writes should patch existing events rather than create duplicates. After the external write, G-direction readback can create typed `calendar_event` nodes and WF19 session pins in HG. WF07 source-anchor relations remain deferred until the operad declaration is repaired.

### 5. Reconciliation

Reconciliation is where the pipeline earns trust. It compares dry plans against folded HG state and separates:

- Applied rows: already present in folded state.
- Pending rows: safe candidates not yet applied.
- Deferred rows: intentionally blocked until a schema, authority, identity, or operad question is resolved.

This distinction is essential for long-running programs. A warning is useful when it names exactly which row is waiting and why.

## Dashboard Walkthrough

Open:

```text
tmp/projections/session_pipeline/index.html
```

Use the dashboard top-down:

1. Runtime panel: confirms kernel health, ontology version, T-day, and log length.
2. Stage cards: show the pipeline as G input, F session, F visual, Calendar, recommendations, and operator interface.
3. Priority actions: names current warning/fail next steps.
4. Artifacts: links every generated file.
5. Visual Lenses: embeds session-occasion and T189 recommendation SVGs.
6. Calendar Time-Fabric: links Calendar plan, report, write result, temporal SVG, and DOT.
7. HG Recommendations: links recommendation plan and reconciliation.
8. Interactive HG Inspector: Cytoscape.js tabs for Session Occasion and T189 Recommendations.
9. Surface Context Atlas: links the generated atlas JSON and Markdown.
10. Gates: the detailed pass/warn/fail list with evidence and next actions.

The dashboard should feel like a cockpit. The improvements to prioritize next are not generic polish; they are operational affordances:

- Better why-visible inspection for selected graph nodes.
- Gate drill-down that jumps to the exact JSON/Markdown evidence row.
- Long-running program views grouped by purpose, status, target T-day, and blocker.
- Stable external identity panels for Calendar, GitHub Project, website/DNS, and future application surfaces.

## `dev/scripts` Tooling

The scripts are the source machinery. The generated `tmp` tree is output; `dev/scripts` is where the operators live.

### Orchestrator

- `dev/scripts/projections/run-session-pipeline.ps1` runs the current pipeline end-to-end.

### Core Julia adapters

- `session_context_projection.jl` projects the current session into an IDE/agent/harness context pack.
- `graph_artifact_projection.jl` analyzes selected HG frames and emits engineering reports plus Cytoscape element data.
- `export_t200plus_projection.jl` exports DOT/SVG graph lenses; presets include session occasion, temporal Calendar, and T189 recommendations.
- `calendar_time_fabric_projection.jl` creates the Calendar time-fabric plan.
- `google_calendar_writer.jl` performs explicit OAuth/writer actions for Calendar after review.
- `t189_t200_recommendation_projection.jl` creates candidate HG nodes/relations for recommendation work.
- `t189_recommendation_reconciliation.jl` compares candidate recommendation plans with folded HG state.
- `surface_context_atlas.jl` creates the atlas across JSON, JSONL, Git, Calendar, dashboard, visuals, anchors, and pending moves.
- `session_pipeline_mvp_gate.jl` creates the pass/warn/fail gate report and dashboard.

### Other script areas

- `dev/scripts/tests/` contains focused Julia and Python tests for projection adapters and validators.
- `dev/scripts/ops/` contains operational tools for federation, persona verification, and host-side actions.
- `dev/scripts/validation/` contains graph and hydration validation helpers.
- `dev/scripts/sync-claude-skills.ps1` syncs repo skills into the local agent harness.
- `generate_type_map.py` remains the active Python utility for router type-map generation.

## Skills Tooling

Skills are not magic. They are named operating modes that keep repeated work from being re-invented in every conversation.

Use these most often with the projection filesystem:

- `moos-state-readback`: start-of-session health, git, kernel, and surface readback.
- `moos-session-context-projection`: session packs, IDE/harness context, affordance packs, and graph visualization context.
- `moos-tooling-dx`: VS Code, MCP, PowerShell, dashboard, script, and workflow ergonomics.
- `moos-workspace-ingest`: G-direction ingestion from Workspace/Keep-like artifacts into HG as knowledge items and related evidence.
- `moos-rewrite-envelope`: authoring or debugging ADD/LINK/MUTATE/UNLINK envelopes.
- `moos-github-project-bridge`: GitHub Project #4 as an F/G control surface keyed by `HG URN`.
- `moos-categorical-research`: functor, adjunction, lens, HDC/VSA, or mathematical semantics questions.
- `moos-running-state-validator`: checking running-state prose against live kernel state.
- `moos-round-close`: cleanup, running-state update, commit/push, and handoff once a round is genuinely done.

The manual pattern is: read state, choose the right skill, run the dry projection first, inspect the generated files, then decide whether an explicit writer or HG apply is justified.

## Gates And Long-Running Programs

Long-running programs in mo:os should not be invisible background intent. They should have graph identity and a projection contract.

A healthy long-running program has:

- A `program` URN with status and scope.
- A purpose or parent program that composes it.
- Session pins when it belongs in the current operator scope.
- Optional `view_filter` carriers for repeated lens shapes.
- Projection artifacts that show what it emits.
- Reconciliation that says what has applied, what is pending, and what is deferred.
- Gates that fail or warn with exact next actions.

For the current lane, the long-running shape is the T189/T200 convergence family: Calendar/time-fabric, recommendations, visual lenses, GitHub Project identity, application surface maps, and the surface context atlas. The next useful gates are likely:

- WF07 declaration gate: can Calendar source anchors be applied safely?
- Project #4 identity gate: which active rows have `HG URN` coverage?
- Lens contract gate: which script presets have repeated enough to promote to `view_filter`?
- Application surface-map gate: does `my-tiny-data-collider` have website/DNS/GitHub/Calendar/Workspace/server surfaces represented?
- Long-running program freshness gate: when was each active program last projected, reconciled, or advanced?

## Copy-Ready Organization README Version

mo:os uses `ffs0/tmp/projections/session_pipeline` as a local operator cockpit for graph projections. The pipeline reads folded HG state from the kernel and materializes reviewable JSON, Markdown, DOT, SVG, and HTML artifacts: session context packs, graph engineering reports, static and interactive visual lenses, Calendar projection plans, recommendation plans, reconciliation reports, a surface context atlas, and a pass/warn/fail dashboard. HG remains the source of truth; the generated files are navigable projections. The dashboard is designed for practical multi-window use with VS Code, file explorer, and browser tabs, while scripts under `dev/scripts` and skills under `dev/claude-skills` provide the repeatable tooling for state readback, Workspace ingest, session context projection, visualization, reconciliation, external writers, and round closeout.
