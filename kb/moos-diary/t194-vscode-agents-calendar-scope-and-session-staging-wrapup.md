# T194 VS Code Agents, Calendar Scope, And Session Staging Wrapup

**T-day:** T=194
**Date:** 2026-05-14
**Kernel/session:** `urn:moos:kernel:hp-laptop.primary` / `urn:moos:session:sam.governance`
**Actor:** `urn:moos:agent:vscode.hp-laptop.copilot` after the later occupancy correction; `urn:moos:agent:claude-code.hp-laptop` is legacy/idle unless Claude Code is explicitly restored
**Runtime readback:** hp-laptop `localhost:8000` ok, `ontology_version=3.16.1`, `t_day=194`, `log_len=1192`; router `localhost:9000` ok with local kernel up and Z440 remote down
**Lane:** VS Code Agents surface, session-context projection, Calendar scope, S0 conversation staging design, T195+ planning

## Executive Status

This T194 pass expanded the projection lane rather than changing HG truth. The VS Code portable workspace is now the explicit operator surface; the custom agent and opener prompt are wired into `.github/agents/` and `.github/prompts/`; the session pipeline now contains four matched graph artifacts, four DOT/SVG visual lenses, four SVG zoom panes, and four interactive HG inspector lenses; and the Calendar time-fabric planner now says what slice it is projecting, how deep it looks, which temporal properties it trusts, and why Google Calendar is an external surface rather than graph truth.

The live graph did not receive new rewrites in this pass. The external Google Calendar writer did run as an explicit actuator boundary and patched 16 existing events by `moos_projection_id`. Those write effects are not automatically HG state. The regenerated recommendation reconciliation correctly reports the new T194-dated `calendar_event` observations and session pins as pending HG rows, with WF07 source anchors still deferred.

The important forward move is conceptual but concrete: IDE conversations like this one should be treated as S0 substrate with a gated staging layer. A conversation can carry stable session-specific keys that point toward candidate `knowledge_item`, `claim`, `derivation`, `purpose`, `program`, and `view_filter` nodes, but those keys are not graph identity until a G-ingest or APPLY batch lands them in HG.

## T194 Occupancy Correction Addendum

Sam then caught the central mismatch: Claude Code was not running, but the folded graph and several operator surfaces still treated `agent:claude-code.hp-laptop` as the current hp-laptop governance occupant. The correction is now live in HG and reflected in the projection gates.

Applied program: `dev/scripts/ops/t194-hplaptop-vscode-copilot-occupancy.program.json`.

The batch did seven things: added `agent:vscode.hp-laptop.copilot`, linked `group:sam` as owner, pinned the new agent into `session:sam.governance`, removed the stale Claude Code occupant relations from both `session:sam.governance` and abandoned `session:t187-mvp`, linked governance occupancy to the VS Code/Copilot agent, and marked the legacy Claude Code agent `idle`. Health moved from `log_len=1184` to `log_len=1192`. Post-apply readback shows Claude Code with 0 remaining `has-occupant` relations.

The lingo is now explicit:

- HG occupant: folded WF19 `has-occupant` topology; this is what inferred §M11 liveness sees.
- IDE harness surface: the local VS Code/Copilot/Claude/Antigravity process or chat container; evidence for reconciliation, not a session.
- S0 conversation staging: raw chat/debug transcript substrate pending G-ingest.
- `actor_urn`: the envelope principal; it should match the folded occupant unless a reviewed payload deliberately sets an explicit `session_urn` and different actor.
- Mounted tool: an invokable affordance bound to the session, not necessarily the current driver.

This rule lives first in projection/gate/tooling surfaces, not in a new ontology bump: `session_context_projection.jl` now emits an `identity` block, and `session_pipeline_mvp_gate.jl` now has a `session actor/occupant reconciliation` gate. The latest full pipeline is `warn`, 21 pass / 2 warn / 0 fail. The identity block is `pass` with actor, HG occupant, and harness candidate all equal to `urn:moos:agent:vscode.hp-laptop.copilot`.

No new human/auth-account identity node was added. Existing `user:sam`, `group:sam`, and `role:superadmin` already express the user/group/authority side of this pass. The kernel helper was updated and tested so occupancy/admin resolution accepts `group` as a principal, matching the ontology's existing group-as-principal widening.

## What Changed Locally

Tracked local edits now cover four groups.

1. VS Code Agents surface:
   - `.github/agents/moos-workstation-operator.agent.md` now uses VS Code custom-agent frontmatter and is user-invocable.
   - `.github/prompts/agent-workstation-open.prompt.md` is bound to that custom agent.
   - `.github/instructions/agent-workstation.instructions.md` recognizes `.github/agents/**` and keeps prompt/agent routing current.
   - `ffs0.code-workspace` remains the durable three-root workspace: `ffs0-private-workspace`, `moos-kernel`, and `moos-router`.

2. Session affordance and MCP projection:
   - `dev/config/session-affordance-map.json` points HP ProDesk and VS Code sessions at the reusable workstation opener.
   - `.vscode/mcp.json.example` includes the HP ProDesk primary MCP template while leaving `.vscode/mcp.json` local and ignored.

3. Calendar/session pipeline implementation:
   - `dev/scripts/graph_artifact_projection.jl` now reports selected-vs-state coverage and connected components.
   - `dev/scripts/export_t200plus_projection.jl` has a `calendar-scope` preset.
   - `dev/scripts/projections/run-session-pipeline.ps1` emits four graph artifacts and four visual lenses: session occasion, Calendar Time-Fabric, T189 recommendations, and Calendar scope. The Calendar planner receives the Calendar-scope artifact as its reliability/scope context.
   - `dev/scripts/calendar_time_fabric_projection.jl` emits slice policy, temporal-basis metadata, event reliability, relation context, ontology-pattern notes, and Calendar-scope diagnostics.
   - `dev/scripts/session_pipeline_mvp_gate.jl` gates the Calendar Time-Fabric and Calendar-scope lenses, includes all four static visual lenses as SVG zoom panes with fit/zoom/reset/wide controls, and exposes four Cytoscape inspector tabs with search, fit, zoom, reset, layout, and wide-view modal controls.
   - Focused tests for the Calendar planner and MVP gate were updated and pass.

4. Skill and docs refresh:
   - `dev/claude-skills/moos-session-context-projection/SKILL.md` now documents the Calendar-scope artifact/inspector and introduces S0 conversation staging keys.
   - `dev/scripts/README.md` and the T193 HP ProDesk wrap-up were updated away from stale prompt names.

## Validation Readback

Latest local proof after implementation:

- Julia focused tests: `test_calendar_time_fabric_projection.jl` passed 22/22; `test_session_pipeline_mvp_gate.jl` passed 69/69 after the fourth inspector, modal/zoom controls, and SVG zoom panes.
- Identity-focused regression tests after the occupancy correction: `test_session_context_projection.jl` passed 29/29; `test_session_pipeline_mvp_gate.jl` passed 69/69 plus 4/4 gap tests; config/program JSON parsing passed; `VerifyPersona -Persona guido` passed against `agent:vscode.hp-laptop.copilot`; `go test ./internal/operad` passed after the group-principal helper fix.
- Full session pipeline after the identity gate: `warn`, 21 pass, 2 warn, 0 fail.
- Dashboard: `tmp/projections/session_pipeline/index.html`.
- Edge/CDP browser validation passed against the generated dashboard, including headline metrics, four SVG objects, SVG zoom in/out/reset, SVG wide-pane open/close, four Cytoscape tabs, Calendar Time-Fabric tab selection, Calendar Scope tab selection, and no console/runtime errors.
- Calendar writer: credential check passed; dry-run saw 16 events; real write patched 16 existing Google Calendar events, inserted 0.
- Diagnostics on touched Julia/PowerShell/test files: clean.
- `git diff --check`: only CRLF normalization warnings, no whitespace errors.

Generated artifact shape is now symmetrical:

- Graph artifacts: `session_occasion_engineering`, `temporal_calendar_engineering`, `t189_recommendation_engineering`, and `calendar_scope_engineering` as JSON/Markdown pairs.
- Visuals: `session_occasion_frame`, `temporal_calendar_frame`, `t189_recommendation_frame`, and `calendar_scope_frame` as DOT/SVG pairs, surfaced as four SVG zoom panes in the dashboard.
- Interactive inspectors: Session Occasion 16/20, Calendar Time-Fabric 44/54, T189 Recommendations 47/61, and Calendar Scope 53/62.

The two pipeline warnings are expected and useful:

- `visual lens root coverage`: the session-occasion lens still forces four explicit roots into view because the selected relations do not connect them yet: `system_instruction:framework.session-occasion-lingo`, `grammar_fragment:v317-1-occasion-type`, `pattern:session-affordance-pack`, and `workflow:z440-session-continuity-reconciliation`.
- `T189 recommendation reconciliation`: the regenerated T194 Calendar plan has 16 pending `calendar_event` nodes and 16 pending WF19 session pins. WF07 source-anchor relations remain explicitly deferred.

## Current Topology In This Session Scope

The session-context pack is the best current summary of what this VS Code occasion sees.

- Session: `session:sam.governance`.
- Actor: `agent:vscode.hp-laptop.copilot`.
- Kernel place: `kernel:hp-laptop.primary` via WF19 `opens-on`.
- Occupant: the VS Code/Copilot hp-laptop agent via WF19 `has-occupant`.
- Purpose color: `purpose:sam.doctrine-governance-and-delegation` via WF19 `has-purpose`.
- Scope roots: 34 nodes in the regenerated session pack, heavily centered on Calendar/time-fabric, T189/T200 recommendation convergence, visual projection, application-surface modeling, and the current VS Code/Copilot agent.
- Calendar Time-Fabric lens: 44 selected nodes out of 433 state nodes; 54 selected relations out of 444 state relations; no engineering findings after adding `has-purpose/purpose-of-session` to the temporal port filter.
- Calendar-scope lens: 53 selected nodes out of 433 state nodes; 62 selected relations out of 444 state relations; 8 weak components, largest component 46 nodes; 11 explicit roots, all connected.

The dashboard was cleaned up around review roles rather than raw file lists. `Review Surfaces` now groups Atlas, Graph Artifacts, Calendar, Recommendations, and MVP Gate links. The Atlas panel is the table of contents for the local generated surfaces; recommendations remain a dry plan/reconciliation surface; `mvp/` remains the pass/warn/fail contract; and `graph_artifacts/` is now the canonical engineering substrate for the four interactive lenses. The interactive HG inspector now has a wider modal mode with backdrop/close affordance, plus search, fit, zoom in/out, reset, and Cose/Grid layout controls.

The static and interactive visual surfaces now have distinct lingo. An SVG zoom pane is the deterministic Graphviz review layer for labels, rank, and relation visibility. An interactive HG inspector is the Cytoscape-backed typed graph-artifact view for selecting nodes and relations and reading metadata. Both are F-direction projections from folded HG for `urn:moos:session:sam.governance`; neither is a truth source or rewrite surface.

The live `session.status` property still appears as `abandoned` in the generated JSON. That property is deprecated in the ontology and should not be treated as the liveness source. Current liveness is relation-evaluated from WF19: `opens-on`, `has-occupant`, `has-purpose`, and `pins-urn`. A compatibility MUTATE from `abandoned` to `active` is possible under kernel authority, but the stronger fix is for projections and readers to prefer WF19 topology over deprecated scalar session status.

## Relation Families Doing The Work

- WF12 `provides-kb/kb-source`: evidence flow. Keep/Drive/Gmail/Calendar source material becomes `knowledge_item` evidence and then claims/derivations.
- WF18 `composes/composed-by`: work decomposition. Purpose and program nodes compose sub-programs, sessions, channels, repositories, and other work carriers. Program temporal fields (`starts_t`, `target_t`, `deadline_t`, `completed_t`) live here as mutable planning state.
- WF19 `opens-on`, `has-occupant`, `pins-urn`, `filtered-by`, `mounts-tool`, `has-purpose`: session workspace topology. This is the main surface for making the governance session see or stop seeing things.
- WF21 `causes/caused-by`: causal lineage. Derivations, claims, KIs, programs, channels, and clocks use this to explain why something exists or changed.
- WF07 `participates/participated-by` vs `calendar_event.anchors`: still mismatched for the desired Calendar source-anchor shape. Keep these relations deferred until the operad declaration is repaired.

## Mutate And Rewire Effects On Projections

There are two very different classes of change.

Property MUTATE changes a node's scalar data and therefore changes filters, labels, dates, colors, sort order, status gates, and HDC encodings. It does not change graph connectivity by itself. Examples:

- MUTATE `program.target_t`, `starts_t`, `deadline_t`, or `completed_t`: Calendar time-fabric dates become stronger and more reliable because the planner will prefer explicit temporal fields over lens-order placement.
- MUTATE `program.status`: dashboards, Project projection, and recommendation gates may change immediately.
- MUTATE `view_filter.predicate`: can radically change what a session t-cone selects; treat as high-impact even though it is scalar.
- MUTATE `claim.confidence` or `derivation.confidence`: changes evidence ranking and future HDC similarity, not topology.
- MUTATE `knowledge_item.status`: changes ingest lifecycle and evidence gates.
- MUTATE `external_op.status`: records observed actuator lifecycle; status is kernel-authority.

Topology rewires change graph connectivity and projection scope. Examples:

- LINK/UNLINK WF19 `pins-urn`: adds or removes a node from a session workspace without changing the node itself.
- MUTATE a WF19 relation target, such as rotating `has-purpose` or `has-occupant`: preserves relation identity while changing the live purpose or occupant. This is the correct model for a main session whose identity persists while its current driver or reason changes.
- LINK/UNLINK WF18 composition: changes the program/purpose DAG and therefore what the Calendar/recommendation/visual lenses see.
- LINK WF21: changes causal reachability and can connect previously forced roots, but it must remain acyclic.

For projections, relation rewires are louder than most node-property MUTATEs because lenses are rooted in topology. A single new WF19 pin can add a whole subtree to the session pack. A single `view_filter.predicate` MUTATE can hide or reveal a large t-cone. A Calendar `date` cannot be MUTATEd because it is immutable on `calendar_event`; a changed external date must either create a new `calendar_event` observation or wait for an ontology/identity decision about Calendar event URN stability.

## Candidate HG Work For The Next Session

These are recommendations, not applied rewrites.

### 1. T194 Calendar G-readback

The Google Calendar writer patched 16 existing external events using stable `moos_projection_id` values. The graph still contains the prior T189/T200 Calendar observations with immutable dates around 2026-05-09 to 2026-05-12. The current regenerated plan projects T194 dates 2026-05-14 to 2026-05-17.

Recommended HG move:

- ADD 16 new `calendar_event` nodes for the T194-dated observations.
- LINK each new event into `session:sam.governance` with WF19 `pins-urn/pinned-by-session`.
- Keep the 16 WF07 `anchors/anchor` relations deferred until WF07 is repaired.
- Add or close a derivation recording that these are a new G-observation of the external Calendar surface, not a MUTATE of the older `calendar_event` nodes.

Do not try to MUTATE old `calendar_event.date` or `t_day`; both are immutable. If stable Calendar identity should survive date movement, that is a future ontology design, probably a projection identity carrier separate from date-stamped `calendar_event` observations.

### 2. Session purpose and status cleanup

The governance session currently has usable WF19 liveness topology, but stale scalar statuses confuse readers:

- `session:sam.governance.status` is deprecated and appears as `abandoned`.
- The current purpose node used as purpose color also appears historically stale in the Calendar-scope graph.

Two viable paths:

- Conservative: leave scalar statuses alone and update projections to display relation-derived liveness first.
- Topological cleanup: ADD a fresh purpose such as `purpose:sam.t194-t300-projection-governance`, LINK/MUTATE the session `has-purpose` relation to it, and pin this report plus the Calendar-scope artifacts into the session. This preserves the main governance session while giving it a current T194-to-T300 reason.

Avoid treating `session.status` as the main fix. It is deprecated; it may be a compatibility patch, not the ontology answer.

### 3. Make the forced roots real topology

The session-occasion lens still forces four roots into view. Recommended relation work after review:

- Link `system_instruction:framework.session-occasion-lingo` causally or compositionally to the derivation/report that currently relies on it.
- Link `grammar_fragment:v317-1-occasion-type` to the relevant pattern or derivation through the valid promotion/causal path available today.
- Link `pattern:session-affordance-pack` into the session projection family, likely through WF21 and/or a program that owns affordance-pack projection.
- Link `workflow:z440-session-continuity-reconciliation` to the Z440/session-rejoin program family.

Do not invent relation categories for this. Use only valid WF18/WF19/WF21 paths, or keep the warning visible.

### 4. T195 Keep note ingestion

Sam already has a new Keep note queued for T195. Treat it as a regular G-ingest, not as hand-written doctrine.

Recommended shape:

- Use `moos-workspace-ingest` if the note is available as a Drive export or other Workspace-resolvable source.
- Actor: `agent:claude-cowork.hp-laptop`.
- Session: `session:sam.laptop-cowork-workspace`, set explicitly on every envelope.
- Chunk grain: per-item unless the export has real H2/section structure.
- Output: umbrella `knowledge_item` plus section KIs if needed; WF12 `provides-kb/kb-source` links from the Keep/Drive channel to the umbrella and from umbrella to chunks.
- Follow-up: one `derivation` for classification, then extracted `claim` nodes only after the note has been read and the claim boundaries are clear.
- Pin only the umbrella or the resulting derivation/claims into `session:sam.governance` if they matter to governance. The Cowork ingest session and governance session do not have to be the same session.

This should become a ritual: Keep note arrives as S0/Workspace state; G-ingest produces KI evidence; derivation classifies; claims/programs/purposes are emitted only after the gate.

### 5. IDE conversation staging and cleanup

VS Code conversations are S0 substrate. The missing middle layer is a gated staging artifact for conversation state.

Recommended T195/T200 program:

- ADD or plan `program:sam.t195.ide-conversation-staging-gate` under a T194/T300 projection-governance purpose.
- Add a `view_filter` for staged conversation artifacts once the predicate is clear.
- Generate a local staging file under ignored `tmp/projections/session_pipeline/conversation_staging/` with stable keys:
  - `session_urn`
  - `actor_urn`
  - `workspace_file`
  - `folded_state_log_len`
  - `ontology_version`
  - `conversation_source_path` or transcript/debug-log anchor
  - `last_handoff_pack`
  - `candidate_knowledge_item_urns`
  - `candidate_claim_urns`
  - `candidate_derivation_urns`
  - `candidate_purpose_or_program_urns`
  - `accepted`, `deferred`, and `discarded` buckets
- Gate the staging file against folded HG before emitting rewrites. The gate should answer: what is new, what already exists, what is only chat memory, and what must not be persisted.
- Clean up raw conversation state regularly. Keep the latest staging keys and durable HG carriers; do not rely on the chat UI itself as memory.

This gives Sam a way to say: the last S0 state said X, folded HG currently says Y, and the next valid graph action is ADD/LINK/MUTATE Z.

## Z440 GPU, HDC, And File-System Horizon

The Z440 GPU/HDC direction should be treated as a derived-index and harness problem first, not as a kernel-fold dependency. The kernel fold must remain deterministic and replayable from JSONL. GPU/HDC should accelerate projections, similarity, and live indexes derived from folded state.

Current foundation already exists in `moos-kernel/internal/hdc`: spectral, fiber, crosswalk, encode, and live index packages. The next step is not to put GPU code directly into the fold. The next step is to define a derived HDC file-system cache keyed by graph identity and invalidated by rewrites.

Recommended path:

1. Z440 inventory external op:
   - Create `external_op:sam.z440-gpu-hdc-inventory` when Z440 is reachable.
   - Command hints: `nvidia-smi`, `Get-CimInstance Win32_VideoController`, Go build/test readback, Julia/Python GPU package inventory if used.
   - Responsible session: likely `session:sam.karpathy-seat` for HDC semantics plus `session:sam.steinberger-seat` for harness/DX.

2. CPU baseline first:
   - Create a program for HDC live-index baseline over a bounded session scope, e.g. governance + Calendar-scope + T189 recommendations.
   - Encode node vectors from type, URN, properties, relation incidence, and causal neighborhood.
   - Store derived vectors outside HG truth, with keys `(ontology_version, log_len, node_urn, neighborhood_radius, encoder_version)`.

3. GPU acceleration second:
   - Move batch vector operations to GPU only after CPU baseline and invalidation semantics are proven.
   - Keep GPU state as cache. A replay from log plus encoder version must rebuild it.

4. File-system cache shape:
   - Treat the HDC FS as S4/derived storage, not source of truth.
   - Suggested layout: `tmp/hdc/<ontology_version>/<encoder_version>/<log_len>/...` for local experiments, later promoted to a `storage`/`compute` topology if it becomes durable.
   - ADD/LINK/UNLINK/MUTATE invalidation rules:
     - ADD node: encode new node and its immediate relation context.
     - LINK/UNLINK relation: invalidate both endpoints and their radius-N neighborhoods.
     - MUTATE node scalar: re-encode the node and any derived summary vectors that include that property.
     - MUTATE relation target for `has-purpose` or `has-occupant`: invalidate the old target, new target, relation source session, and session context pack.
     - MUTATE `view_filter.predicate`: invalidate the whole lens result.

5. Use in projections:
   - Rank candidate rewrites against purpose vectors.
   - Cluster session scope roots by semantic proximity.
   - Detect stale conversation staging keys whose candidate claims duplicate existing folded graph claims.
   - Suggest which forced roots need WF21 or WF18 relation work.

## Horizon: T195 To T300

The planning horizon is past T200 but before T300, roughly end of June.

### T195-T205: stabilize ingest and staging

- Ingest the T195 Keep note through Cowork/Workspace G-ingest.
- Create the first conversation-staging gate for VS Code S0 chats.
- Decide whether to apply the T194 Calendar G-readback nodes and WF19 pins.
- Keep WF07 anchors deferred unless the ontology/operad patch is ready.

### T205-T225: session hierarchy and projection contracts

- Treat `session:sam.governance` as a main session whose scope pins and purpose relation organize follow-on sessions.
- Pin or lens the supporting sessions: `sam.laptop-cowork-workspace`, `sam.laptop-moos-diary`, `sam.hpprodesk-setup`, and when reachable the Z440 persona sessions.
- Create or activate a T194/T300 projection-governance purpose and link the current program family under it.
- Make `view_filter` contracts reusable rather than only script presets.

### T225-T250: Z440 HDC baseline

- Rejoin Z440 live state.
- Inventory GPU/driver/toolchain.
- Build CPU HDC baseline over folded graph slices.
- Define the HDC FS cache invalidation contract.

### T250-T275: GPU/HDC projection accelerator

- Prototype GPU-backed vector batches outside the kernel fold.
- Use HDC proximity to rank session scope, conversation staging candidates, and forced-root relation recommendations.
- Feed results into the dashboard as derived projection metadata.

### T275-T300: integrated session memory and surface round-trip

- Turn S0 conversation staging into a repeatable skill or script lane.
- Make Calendar, GitHub Project #4, Keep, and VS Code conversations consistent F/G surfaces.
- Keep derived caches rebuildable from log, ontology version, and encoder version.
- Move toward a main-session model where durable sessions persist and secondary sessions follow through pins, filters, purpose, and explicit occupancy rather than branchy chat state.

## Skill Recommendation

Use existing skills for now:

- `moos-session-context-projection`: session pack, lens, dashboard, and S0 conversation staging design.
- `moos-workspace-ingest`: T195 Keep note once the source is available as Workspace/Drive/Keep export material.
- `moos-rewrite-envelope`: when the candidate nodes/relations become an actual APPLY batch.
- `moos-categorical-research`: HDC/VSA and session-purpose vector-field semantics.
- `moos-tooling-dx`: VS Code Agents window, custom agents, MCP, and staging/cleanup ergonomics.

If the conversation-staging pattern stabilizes after one or two T195 runs, promote it into a dedicated skill, likely `moos-ide-conversation-ingest` or a submode of `moos-session-context-projection`. Do not make it a new ontology concept first. Prove it as a dry gate over real VS Code transcript/debug-log artifacts, then decide whether the graph needs a `conversation_checkpoint` node type or whether `knowledge_item` + `derivation` + `claim` is enough.

## Explicitly Not Done

- No HG rewrites were applied in this wrap-up.
- No ontology edits were made.
- No Project #4 G-sync was performed.
- No Z440 GPU commands were run because Z440 is currently down from hp-laptop's router view.
- No T195 Keep note was ingested yet because the source note was not supplied in this session.
- The first dashboard/projection packet was committed and pushed as `502286c`. The later SVG zoom-pane and traceability updates belong to this final wrap-up packet.

## Next Concrete Move

For T195, the best first action is not more projection code. It is a clean G-ingest cycle:

1. Bring the new Keep note into a resolvable source artifact.
2. Run Cowork hp-laptop ingest with explicit session context.
3. Generate KI/derivation/claim candidates.
4. Compare candidates to folded HG.
5. Apply only the accepted batch.
6. Then use the same gate pattern on the current VS Code conversation staging keys.

That gives us a practical bridge from S0 chat and notes into S1/S2 graph carriers without pretending the IDE transcript itself is durable truth.
