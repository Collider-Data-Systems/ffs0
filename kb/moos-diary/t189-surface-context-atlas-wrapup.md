# T189 Surface Context Atlas Wrap-Up

**T-day:** T=189  
**Date:** 2026-05-09  
**Kernel:** `hp-laptop.primary`  
**Runtime readback:** `ontology_version=3.16.1`, `t_day=189`, `log_len=1160`  
**Lane:** Keep/session/visual/Calendar/recommendation/atlas projection pipeline

## Executive status

The projection lane now has a generated surface atlas. It gives the operator and future agents one fresh table of contents for JSON API state, JSONL log truth, Git repositories, Google Calendar, dashboard, visual artifacts, and type/relation/program surfaces. It also names the existing HG anchors for category/functor logic, UI/UX visualization, and the `my-tiny-data-collider` application surface map.

This was not left as a loose note. A new HG carrier, `program:sam.t189.surface-context-atlas`, is applied on hp-laptop primary and pinned into `session:sam.governance`.

## What landed in HG

Five rewrites landed as a narrow carrier batch:

- ADD `program:sam.t189.surface-context-atlas`.
- WF18 `purpose:sam.t189-t200plus-time-fabric-convergence --composes--> program:sam.t189.surface-context-atlas`.
- WF19 `session:sam.governance --pins-urn--> program:sam.t189.surface-context-atlas`.
- WF21 `derivation:guido.architecture-syntax-interpretation --causes--> program:sam.t189.surface-context-atlas`.
- WF21 `program:sam.t189.cytoscape-typed-hg-inspector --causes--> program:sam.t189.surface-context-atlas`.

This keeps the implementation inside the graph's current purpose/scope instead of making the atlas a filesystem-only helper.

## What landed in the projection pipeline

New generator:

- `dev/scripts/surface_context_atlas.jl`.
- Outputs: `tmp/projections/session_pipeline/atlas/surface_context_atlas.json` and `.md`.

Runner integration:

- `run-session-pipeline.ps1` now runs first MVP gate, then the atlas, then a final MVP gate so the dashboard can link the atlas.
- `session_pipeline_mvp_gate.jl` has a new `surface context atlas` gate and dashboard card.

The atlas surfaces are:

- JSON API.
- JSONL Log.
- Git Repositories.
- Google Calendar.
- Dashboard.
- Visuals.
- Types / Relations / Programs.

## Honest opinion on the visualization and context shape

The stack is strong because it preserves trust boundaries. HG folded state is not confused with Git files, generated HTML, Calendar events, or dashboard views. Graphviz remains a deterministic proof artifact, while Cytoscape.js is now the right day-to-day exploration surface.

The weakness was context assembly. A person or agent had to hop between the gate report, dashboard, Calendar plan, reconciliation, graph artifacts, and running-state prose. The atlas fixes that by becoming a generated map of the surfaces and their meaning. The next UI step should not be a prettier static page; it should be why-visible inspection: select a node and see which root, relation, filter, gate, or projection contract admitted it.

## Category, functor, math, and logic-programming hook

The atlas makes the F/G story concrete enough to use:

- `F: HG -> surface` projects folded graph state into Calendar, GitHub, dashboard, visual, or context artifacts.
- `G: surface -> HG` observes external results back as typed nodes or rewrites.
- Reconciliation is the unit/counit check in practical clothing: did the external identity come back to the same HG identity?
- Logic-programming style rules should power future lens membership: why a node is visible, which relation path included it, and which gate makes it actionable.

Existing HG anchors are now listed in the atlas instead of buried in memory: `derivation:guido.architecture-syntax-interpretation`, `grammar_fragment:v316-1-depends-on`, the Cytoscape/view-filter/visual-projection carriers, and the application group/purpose/program for `my-tiny-data-collider`.

## UI and UX result

The dashboard remains the local cockpit, not the truth source. It now links the atlas JSON and Markdown beside the visual lenses, Calendar artifacts, recommendations, reconciliation, gates, and Cytoscape inspector.

For UI/UX, the next useful move is a typed inspector that explains membership and identity:

- Stable identity: HG URN and external projection ID.
- Why visible: root/path/filter/gate evidence.
- What surface: JSON, JSONL, Calendar, Git, dashboard, visual, or program relation.
- What action is safe: dry plan, apply candidate, deferred boundary, or standing rule.

## Pending moves addressed

The atlas names all five pending moves and keeps them separated from completed work:

- WF07 top-level declaration: still `pending-ontology-patch`. Do not apply the 16 Calendar source-anchor relations until `anchors/anchor` is explicitly declared as a WF07 additional port pair and runtime validation agrees.
- Project #4 row identity: still planned. The public project is framed correctly, but row-level `HG URN` repair should start with a dry inventory.
- Reusable lens contracts: still planned. Script presets remain executable proof; repeated lens shapes should become `view_filter` carriers only after reuse proves the contract.
- `my-tiny-data-collider` surface map: already has group/purpose/program anchors; next work is the explicit website/DNS/GitHub/Calendar/Workspace/server map.
- Runtime repos boring: standing rule. `moos-kernel` and `moos-router` stay focused on runtime and routing; application surfaces stay in HG/application lanes.

## Validation

Focused validation passed:

- Surface context atlas test: 17/17.
- MVP gate tests: 41/41 plus 4/4 gap tests.
- T189 recommendation reconciliation: 23/23.
- Calendar time-fabric projection: 12/12.
- T189/T200 recommendation projection: 15/15.
- Full session pipeline: `warn`, 19 pass, 1 warn, 0 fail.

The remaining warning is the existing session-occasion visual lens root-coverage warning. It is honest: forced roots are visible, but the narrow relation set does not connect them all yet.
