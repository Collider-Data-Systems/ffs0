---
title: "T187 report: T186 Google Calendar projection lane"
date: 2026-05-07
t_day: 187
covers_t_days:
  - 186
  - 187
actor_urn: urn:moos:agent:claude-code.hp-laptop
session_urn: urn:moos:session:sam.governance
candidate_hg_type: knowledge_item
candidate_hg_urn: urn:moos:ki:guido.t187.t186-google-calendar-projection-report
projection_surfaces:
  - Google Calendar
  - DOT/SVG graph projection
  - running-state hydration
source_artifacts:
  - dev/scripts/google_calendar_projection.jl
  - dev/scripts/google_calendar_writer.jl
  - dev/scripts/tests/test_google_calendar_projection.jl
  - dev/scripts/tests/test_google_calendar_writer.jl
  - tmp/projections/google_calendar_projection_plan.json
  - tmp/projections/google_calendar_write_result.json
  - tmp/projections/t200plus_with_session_lens.dot
related_hg_urns:
  - urn:moos:program:sam.t200plus.temporal-projection-fabric
  - urn:moos:program:sam.t200plus.google-calendar-projection-contract
  - urn:moos:program:sam.t200plus.google-calendar-projection-planner
  - urn:moos:program:sam.t200plus.google-calendar-oauth-writer
  - urn:moos:derivation:guido.t200plus-google-calendar-write-result
---

## T187 Report: T186 Google Calendar Projection Lane

This report records the T186 working arc and the T187 morning readback that followed it. It is written as projection-ready log material: readable as plain markdown today, but shaped so it can later be chunked into `knowledge_item` nodes, related to the existing derivation, and projected outward to calendar, graph, board, or summary surfaces.

The short version: T186 turned the HG projection idea from a visual demo into a real external write. The graph stayed authoritative. Julia compiled graph facts into Google Calendar event payloads. OAuth was kept as an explicit boundary. The writer inserted four real events into Sam's primary Google Calendar, then the result was reified back into HG as a derivation.

## Starting Point

The day began from the T187/T200+ design question: the kernel code was not the main object of attention; the ontology and HG were. The user framed ontology as the DNA of the spec. That set the direction for the session: talk in nodes, relations, rewrite categories, type algebra, operads/cooperads, wiring diagrams, categories, functors, and projections.

The active conceptual move was from "a graph can be visualized" to "a graph can be interpreted by a surface." DOT/SVG was the first interpretation: a folded-state graph projection. Google Calendar became the second and more demanding interpretation: same source, but the target surface has identity, side effects, OAuth, and idempotency requirements.

T187 itself is now mostly historical in the log. The old `sam.t187-kernel-proper` and `sam.t187-distributed-hg-mvp` programs are archived. Their real continuation is the T200+ program family: Tiny Data Collider federation, temporal projection fabric, visual projection fabric, programming-language/type-algebra work, GitHub board bridge, and transport/data-plane lanes.

## What Was Built

Three projection layers now exist locally.

First, the visual projection compiler reads folded HG state and emits DOT/SVG views. The important artifact for this report is `tmp/projections/t200plus_with_session_lens.dot`, which shows the causal handoff from `sam.t187-distributed-hg-mvp` into `sam.t200plus.tiny-data-collider-federation`, and the composition of that T200+ node with temporal, visual, calendar, VCS, board, programming-language, and transport lanes.

Second, the dry Google Calendar projection adapter reads folded HG state and writes a reviewable JSON plan at `tmp/projections/google_calendar_projection_plan.json`. This adapter performs no OAuth and no external writes. It maps HG program nodes into all-day Google Calendar event payloads, derives stable `moos_projection_id` values, embeds the source URN and projection contract in private extended properties, and keeps the graph as source of truth.

Third, the OAuth writer consumes that plan and applies it to Google Calendar. It supports credential checks, auth URL generation, loopback OAuth capture, manual code exchange, dry-run, and real write. The real write path upserts by `extendedProperties.private.moos_projection_id`, so reruns should patch existing events rather than creating duplicates.

## Concrete Calendar Result

The final write result is at `tmp/projections/google_calendar_write_result.json`:

| Source URN | Projection ID | Action | Google Event ID |
| --- | --- | --- | --- |
| `urn:moos:program:sam.t200plus.google-calendar-oauth-writer` | `moos-6af2cf970ff6d871a9677576` | insert | `6rsqas3aouikea0v89iugqqldc` |
| `urn:moos:program:sam.t200plus.google-calendar-projection-contract` | `moos-ab1e731bb43b044f37ec53a4` | insert | `cpcaak7bkroqb0n7k8ielfrnn4` |
| `urn:moos:program:sam.t200plus.google-calendar-projection-planner` | `moos-d43e8ae430ef540c5f94636e` | insert | `p1irm1chjve988bqq9fnk754hk` |
| `urn:moos:program:sam.t200plus.temporal-projection-fabric` | `moos-f7cf15c14fe89a6cf964c73d` | insert | `adcc2e5sulgdcj5l8nc6f7880k` |

The Google Calendar UI showed three long bars in the later May week because three events span 2026-05-06 through 2026-05-26. The dry projection planner is a one-day all-day event from 2026-05-06 through 2026-05-07, so it is not visible in that later week.

The write was recorded in HG as `urn:moos:derivation:guido.t200plus-google-calendar-write-result`, WF21-caused-by the OAuth writer program. This is the important loop closure: external side effect out, derivation back in.

## Design Choices

The writer deliberately treats Google Calendar as a projection surface, not a source of truth. The HG program nodes carry identity, status, description, T-day timing, and relations. Google Calendar receives a derived view. If the calendar event is edited by hand later, that edit is external substrate drift until an explicit G-direction ingest lane pulls it back.

The OAuth boundary stayed explicit. Credential file references are modeled in HG as storage nodes, but real credential values live only under `secrets/` and are gitignored. The token and OAuth client are mounted local substrate, not graph truth.

The dry planner and writer are split on purpose. The dry planner is a pure-ish interpreter from folded graph state to target payloads. The writer is an actuator boundary: it takes already-reviewable payloads and performs side effects. That separation is a good pattern for every future surface: compile first, write second, reify result third.

The idempotency key is graph-derived. Each calendar event carries a stable `moos_projection_id`, derived from the source URN and projection contract. This gives the external surface something like a foreign key without making Google Calendar authoritative.

## Programming Patterns

The T186 implementation used a mostly functional shape even though the code is Julia scripts rather than a formal FP system. The useful distinction is this: the core adapters are written as transformations from immutable-ish input data to output data, while the side effects are isolated at the boundary.

The recurring pattern is:

1. Read folded HG state.
2. Select a reachable subgraph by root URN and traversable relations.
3. Interpret node properties and relations as typed arguments.
4. Emit target payloads with stable identities.
5. Apply side effects only in the writer/actuator layer.
6. Reify the result back into HG.

This is functional programming in the practical sense: small functions, explicit inputs, deterministic transforms, and side effects pushed outward. But the better mo:os lingo is not just "FP." It is a catamorphic projection pipeline: fold the log to state, interpret the state through a surface functor, then land an observation of the result back into the graph.

## Branchless Node-Dependent Arguments

Sam noticed the pattern where behavior comes from node data rather than hand-written branches. A good name for it is data-dependent argument synthesis. In graph terms: arguments are not assembled by `if this then that` control flow; they are resolved from node type, properties, ports, and reachable relations.

Other useful names, depending on emphasis:

- node-local argument resolution: each node contributes the arguments its type and properties declare.
- operadic wiring: ports and rewrite categories say which boxes can plug into which other boxes.
- declarative projection contract: the target payload is a consequence of graph data plus a named interpreter.
- branchless dispatch by type algebra: code selects behavior through typed tables and small functions instead of deep imperative branching.
- dataflow graph interpretation: relations carry dependency and composition; the interpreter walks the flow.

The advantage is that adding a new projection target should eventually be more like adding a contract and a small interpreter than writing a new procedural workflow from scratch. The control structure is in the graph. The code becomes the semantics of a surface.

## Purpose, Session, Leaves, Actuators

A `purpose` node is the why: an objective, desired state, or terminal condition. It is not a process. It gives a session or program a reason to exist.

A `session` is the live context where work can happen. In current doctrine, a session is present when purpose, occupant, and scope evaluate from graph data. The session pins the relevant subgraph, has an occupant/agent, opens on a host kernel, and gives §M11 liveness enough context to accept or reject rewrites.

A `program` is the structured what: a decomposable intent bundle. It can compose subprograms, depend on siblings, and cause derivations. It is not necessarily running code. It is a graph-resident plan, claim, or work unit.

An actuator is the side-effect leaf. In this lane, Google Calendar writer execution is an actuator boundary. The leaf receives graph-derived arguments and touches the outside world. That touch should be explicit, auditable, and followed by an HG derivation or knowledge item that records what happened.

So the clean sentence is: a purpose seats a session; a session scopes and authorizes the work; a program decomposes the work; an actuator leaf performs a boundary action; a derivation records the observed result.

## Category-Theoretic Reading

HG is the syntax category: nodes, relations, rewrites, and folds. Google Calendar is an external category/surface with its own objects, identifiers, and update rules. The projection adapter is a functor-like interpreter from HG state into that surface.

The useful pair remains `F: HG -> Ext` and `G: Ext -> HG`.

`F` is projection: graph facts become Calendar events, GitHub board rows, DOT/SVG diagrams, or other surfaces.

`G` is ingest: Gmail threads, Drive docs, Calendar edits, GitHub board changes, local files, or media artifacts become `knowledge_item`, `claim`, `derivation`, `program`, or other graph nodes.

The desired discipline is an adjunction-shaped workflow, `F ⊣ G`: project outward with stable graph-derived identity, observe or edit in the external surface, ingest back with enough provenance that the graph can compare, accept, reject, or reconcile the external observation.

The fold is the catamorphism: log to state. The projection is an interpretation of that state. The writer is not the semantics itself; it is a boundary actuator that realizes one interpretation.

## Applications And Surfaces Exercised

Julia 1.12.6 was the implementation language for both planner and writer. `JSON3`, `Dates`, `SHA`, `Random`, `Sockets`, `Downloads`, and `Test` were used across the scripts and tests.

Google Cloud OAuth supplied the OAuth client. Google Calendar supplied the external projection surface. The browser was used for consent and loopback redirect. PowerShell and GitHub CLI supported local verification, issue/project readback, and shell orchestration. VS Code remained the IDE substrate for this conversation and the file edits.

Important Julia boundary lessons:

- `Downloads.request` POST bodies need `input=IOBuffer(body)`; a plain string is treated as a filename.
- Headers must be Pair values like `"Content-Type" => "application/x-www-form-urlencoded"`.
- Browser callback responses should be best-effort; socket close should not throw away a captured OAuth code.
- Loopback listeners need to ignore unrelated localhost hits while waiting for the OAuth callback.

## T187 Morning Readback

The T187 readback showed hp-laptop kernel health at ontology v3.16.0, T-day 187, log length 1031. On-disk ontology also parses as v3.16.0. The old running-state file was stale at the top; it still described T=183 and an old T187 active program table. HG state is ahead of that prose.

The active issue vehicle remains `ffs0#47`, though parts of it are now historical or superseded by T200+ graph progress. `ffs0#36` remains open as a historical round-13/14 discussion surface. The GitHub Projects board is useful but stale relative to HG: it should be treated as a projection surface needing a refresh, not as authority.

Node lookup confirmed the T187 programs are no longer active drivers: `sam.t187-kernel-proper` and `sam.t187-distributed-hg-mvp` are archived, `sam.t187.categorical-contract` is completed, and `session:sam.t187-mvp` is abandoned. The live continuation is the T200+ graph.

## Pending Fixes And Bugs

The OAuth client secret was rotated after the debugging session. A local terminal error echoed the prior client secret text; it was not committed, and rotation closed that boundary hygiene item.

`external_op:sam.t200plus-google-calendar-oauth-writer` remains `pending` even though the write succeeded. The closeout path is blocked by the current liveness/owner model: the status field is owner-scoped to `user:sam`, but §M11 rejects `user:sam` as a non-occupant actor. The result derivation is the current truth record; the external_op status model needs a clean closeout design.

The project board needs a G/F cleanup pass. The board has stale status rows relative to HG, and should not be read as current truth until the bridge refreshes it.

The local worktree has useful WIP: Julia projection scripts, writer tests, docs, secret examples, generated projection artifacts, and a separate moos-kernel validator test WIP. These should be reviewed and committed in focused groups rather than swept together.

The running-state file needed a T187 correction because its historical body still contains old T169/T183 active-program prose and references to doctrine paths that have since moved into HG/archive.

## How To Reify This Report Later

This report can land in HG as one umbrella `knowledge_item`, with section chunks composed under it by WF18. The candidate umbrella URN is `urn:moos:ki:guido.t187.t186-google-calendar-projection-report`.

Suggested links:

- WF18 `composes/composed-by` from umbrella to section chunks.
- WF21 `caused-by` from the report to `urn:moos:derivation:guido.t200plus-google-calendar-write-result` and the four calendar projection programs.
- WF19 `pins-urn` from `session:sam.governance` if this remains active context for the continuation.
- A future projection-contract relation to the Google Calendar projection contract once companion derivation/projection port-pairs are promoted.

The next G-direction item is Sam's Google Keep note, deferred until mid-T187. It should be treated as an external substrate observation first, then classified after reading: likely `knowledge_item` if it is raw memory, `claim` if it states doctrine, `program` if it asks for work, or `derivation` if it synthesizes prior evidence.
