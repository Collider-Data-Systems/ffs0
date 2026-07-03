# mo:os Session Pipeline MVP Gate

Generated: 2026-07-03T19:14:33Z
Base URL: http://localhost:9000
Overall: FAIL

This is a dry gate report for the T189 Keep/session/visual/Calendar/recommendation projection lane. It does not emit rewrites or write to external systems.

## Lingo
- Calendar_projection: HG graph artifact -> Google Calendar payloads. Calendar is a visible projection surface; the graph remains source of truth.
- F_G_role_color: A renderer hint derived from node type: authority, F-context, G-evidence, surface, lens, lineage, or substrate. It is visual metadata, not HG truth.
- F_projection: HG folded state -> external/session artifact. For this lane: session context pack, graph engineering report, DOT/SVG visual aid.
- G_ingest: External source -> HG evidence. For this lane: Google Keep export/manual download -> channel + knowledge_item + claim/derivation topology.
- HG_inspector: A typed interactive view of graph-artifact JSON. Use it when you need selectable node/relation metadata rather than the static Graphviz layout.
- HG_occupant: The folded WF19 has-occupant target for a session. This is the principal §M11 sees, regardless of which local process window is visible.
- IDE_harness_surface: The local tool container currently hosting the operator, such as VS Code/Copilot, Claude Desktop, Claude Code, or Antigravity. It is evidence for reconciliation, not itself a session.
- Recommendation_projection: Approved T189 recommendations -> dry candidate HG nodes/relations. This is a plan surface, not an APPLY batch.
- S0_conversation_staging: Raw chat/debug-log transcript substrate. It becomes durable only after G-ingest as knowledge_item/claim/derivation topology.
- SVG_zoom_pane: A deterministic Graphviz SVG with local fit, zoom, reset, scroll, and wide-view controls. Use it to inspect layout, labels, and topology without changing the graph.
- actor_occupant_reconciliation: A dry check that actor_urn, the folded HG occupant, and the current harness agent candidate name the same driver before the handoff is used to emit rewrites.
- agent_neighborhood_lens: A lens widening rule: agents directly connected to selected session/program nodes stay visible in graph artifacts, SVGs, and inspectors even when ordinary type or match filters would otherwise hide them.
- lens: A typed view functor: roots + radius + WF/port/type/predicate filters + authority/session context -> selected subgraph.
- mvp_gate: A generated check that the G input, F outputs, session header, and visual lens artifacts exist and expose known gaps instead of hiding them.
- reconciliation: A comparison of a dry plan against folded HG state: applied, pending, and deferred rows are named explicitly.
- relation_family_insight: A renderer hint derived from WF category: ownership, delegation, ingest, composition, session pinning, source anchoring, federation, proposal, or causal lineage.
- scope: The domain of a lens: explicit roots plus reachable topology under chosen relation families. Session pins and view_filter nodes are durable scope carriers.
- visual_aid: A renderer of a lens result, not a truth source. DOT/SVG is the current static renderer; Cytoscape.js is the likely next interactive renderer.

## Gates
- [pass] runtime health - Kernel health endpoint is ok.
- [pass] G input channel - Keep channel exists as the G-ingest boundary.
- [pass] G input knowledge item - Keep knowledge_item exists as ingested evidence.
- [pass] G input evidence topology - Keep knowledge_item participates in WF12 evidence topology.
- [pass] F session handoff header - Session context pack carries the expected actor and session_urn.
- [pass] session actor/occupant reconciliation - Session context pack reconciles actor_urn with the folded HG occupant and current IDE harness candidate.
- [fail] session occasion topology - Session pack exposes kernel place, occupant, and scope roots.
  Next: Repair WF19 opens-on/has-occupant/pins-urn topology before using this as a live session header.
- [warn] session purpose color - Session has no durable has-purpose relation; the projection is using its focus string as temporary occasion color.
  Next: When the durable purpose is clear, add/rotate the WF19 has-purpose relation instead of relying on a prompt focus string.
- [pass] F affordance pack - Session projection recommends concrete skills, VS Code extensions, and MCP servers.
- [pass] F graph artifact analysis - Graph artifact projection produced a reviewable engineering frame with root coverage.
- [pass] Temporal Calendar lens - The Calendar Time-Fabric has its own graph artifact lens aligned with the temporal-calendar visual.
- [pass] T189 recommendation lens - The grouped recommendation apply has a dedicated graph artifact lens.
- [pass] Calendar scope lens - The Calendar F/G surface has a dedicated scope graph with session, purpose, channel, programs, writer result, and G-ingest anchors visible.
- [pass] visual lens root coverage - All explicit roots are relation-connected in the selected graph lens.
- [pass] static visual output - Session-occasion, temporal/calendar, T189 recommendation, and Calendar-scope DOT/SVG visual artifacts exist.
- [pass] Calendar time-fabric artifacts - Calendar time-fabric projection plan and Markdown report exist.
- [pass] T189/T200 recommendation artifacts - T189/T200 recommendation HG plan and Markdown report exist.
- [warn] T189 recommendation reconciliation - The recommendation plan has not been reconciled against folded HG state yet, or apply-ready rows are still pending.
  Next: Run t189_recommendation_reconciliation.jl after the recommendation HG plan, then inspect pending rows before any further APPLY work.
- [pass] deferred apply boundaries - WF07 source anchors are declared and visible as explicit pending apply-review rows.
- [pass] lens flexibility controls - The graph projection records roots plus WF, port, type, and match filters.
- [pass] agent neighborhood visibility - The current actor/occupant agent is visible across all four graph artifacts and therefore reaches the SVG and inspector surfaces.
- [pass] one-shot apply script cleanup - No ignored one-shot grouped apply script remains under the generated projection tree.
- [pass] interactive visual aid - The dashboard embeds Cytoscape.js typed element sets for four lenses: session occasion, Calendar Time-Fabric, T189 recommendations, and Calendar scope.
- [pass] surface context atlas - The dashboard has a generated atlas explaining JSON, JSONL, Git, Calendar, dashboard, visual, type/relation/program, and pending-move surfaces.

## Renderer Candidates
- Graphviz DOT/SVG (keep): MVP baseline: deterministic, local, reviewable in git, already wired through export_t200plus_projection.jl
- Cytoscape.js (next): Best next fit from Context7 scan: accepts graph elements JSON, supports selectors/styles/layouts, and has selection/viewport events for node inspection.
- Cytoscape layout extensions (later): Dagre and cose-bilkent are useful follow-ups when the inspector needs hierarchy or cleaner compound layouts; keep built-in Cose/Grid/Circle/Breadthfirst/Concentric for the local no-build dashboard.
- svg-pan-zoom (defer): Good library fit for polished pan/zoom on static Graphviz SVGs, but the generated dashboard keeps native controls so offline/local file review still works.
- vis-network (fallback): Quick node/edge DataSet setup and clustering; useful if the first interactive prototype should be very small.
- force-graph (later): Good for larger exploratory graphs with pan/zoom/drag interactions, but less semantically structured than Cytoscape for typed HG inspection.
- Sigma.js + Graphology (later): Strong for high-volume read-only exploration and graph analytics pipelines; less direct than Cytoscape for typed relation selectors and inspector-first workflows.
- GraphMakie + Graphs.jl (analysis path): Best Julia-side option when metrics, layouts, or notebooks need to stay inside the Julia process; keep generated JSON as the browser/dashboard contract.
- ELK / Dagre hierarchical layout (next layout extension): Useful for F/G pipelines, WF21 causality, and Calendar/recommendation lineage once the local dashboard can bundle layout extensions cleanly.
