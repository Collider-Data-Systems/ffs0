# mo:os — running state

> Hydration entrypoint. Read this first in any new conversation.
>
> Updated: **T=208 (May 28, 2026) ~19:58 CEST — Z440 VS Code lead rejoined; local runtime crisp, local router full-state read has HP ProDesk timeout caveat** — Z440 VS Code/Copilot hydrated from `Collider-Data-Systems/ffs0#54`, the current ffs0 instructions/prompts, live repo state, and live kernel/router readback. Current Z440 IDE harness is VS Code/Copilot as `urn:moos:agent:vscode.hp-z440.primary` occupying `urn:moos:session:sam.z440-vscode-projection-lead` on `urn:moos:kernel:hp-z440.primary`; this does not activate Wolfram/Claude Code, Steinberger, Karpathy, Moos/Antigravity, Cowork, or `urn:moos:user:sam` as an apply actor. Repos are current after guarded fetch/pull: `ffs0/main@cec622f` clean, `moos-kernel/master@71c7f16` clean, `moos-router-feat-type-map-routing@f51c0a7` clean, and `moos-router/master@18212eb` has no remote delta but still has a local tracked `moos-router.exe` modification preserved. Local Z440 runtime is now on `ontology_version=3.16.2`, `t_day=208`: primary/twins `localhost:{8000,8001,8002,8003}` report log lengths `449/13/11/16`; MCP TCP `localhost:8080` is reachable. Z440 router `localhost:9000/healthz` is healthy and peers to hp-laptop `192.168.1.14` plus offline HP ProDesk `172.29.0.32`; hp-laptop `192.168.1.14:{8000,9000}` is healthy and sees Z440 at `192.168.1.13`. `Test-MoosFederation.ps1` needs `MOOS_LOCAL_HOST=hp-z440` on this Windows host because `COMPUTERNAME=desktop-42d00rd`; with that set, Doctor passes for live kernels and `VerifyPersona` passes for `z440-vscode-lead`, `guido`, `steinberger`, and `karpathy`. The no-arg Z440 session pipeline initially failed because local router `http://localhost:9000/state/nodes` stalled while the offline HP ProDesk peer was configured; rerunning through hp-laptop router with explicit Z440 identity succeeded: `run-session-pipeline.ps1 -BaseUrl http://192.168.1.14:9000 -SessionUrn urn:moos:session:sam.z440-vscode-projection-lead -ActorUrn urn:moos:agent:vscode.hp-z440.primary`, producing `tmp/projections/session_pipeline/index.html` and gate `warn`, 23 pass / 1 warn / 0 fail. The warning is T189 recommendation reconciliation: 43 candidate Calendar event nodes/pins/source anchors are pending in the dry plan after the current T208 anchor, not a startup/emit blocker. No HG rewrites, Calendar writes, Project sync, DNS/Cloudflare changes, raw Keep-note apply, commits, or branch changes were performed. New operator report: `kb/moos-diary/t208-z440-vscode-rejoin-readback.md`; issue handoff reply posted on `Collider-Data-Systems/ffs0#54` after the doc update.
>
> ## Federation port → kernel URN map (T=175 v3.14.0, canonical)
>
> | Endpoint                     | Kernel URN                       | Persona seat (WF19 opens-on)            | Current emit target |
> |------------------------------|----------------------------------|------------------------------------------|---------------------|
> | http://192.168.1.13:8000     | kernel:hp-z440.primary           | sam.kernel-proper (Wolfram), sam.moos-diary (AG-Z440), sam.z440-cowork-workspace, sam.mvp-delivery | **Z440 receiving kernel for Wolfram + VSCode persona emits (:8080 MCP)** |
> | http://192.168.1.13:8001     | **kernel:hp-z440.menno**         | **sam.steinberger-seat**                 | Opens-on metadata; Steinberger emits to :8000 until §M9 twin sync |
> | http://192.168.1.13:8002     | **kernel:hp-z440.lola**          | **sam.karpathy-seat**                    | Opens-on metadata; Steinberger emits to :8000 until §M9 twin sync |
> | http://192.168.1.13:8003     | kernel:hp-z440.moos              | (Moos-overflow lane; AG-Z440 actually opens-on .primary) | Overflow metadata; AG-Z440 emits to :8000 |
> | http://192.168.1.13:9000     | (WF16 router)                    | n/a                                      | Federation read router, not an emit target |
> | http://192.168.1.14:8000      | kernel:hp-laptop.primary         | sam.governance (Guido) + sam.laptop-cowork-workspace + sam.laptop-moos-diary | hp-laptop receiving kernel (:8080 MCP on host) |
> | http://172.29.0.32:8000      | kernel:hpprodesk.primary         | sam.hpprodesk-setup (active setup) | HP ProDesk primary bootstrap target (:8080 MCP on host); shared HG mirror and local setup session applied |
>
> **Note on `:8001 = menno` vs `:8002 = lola`, and emit-target vs opens-on** — script-of-record (`D:\HPZ440\start_federation.ps1`) binds `:8001` to the menno log and `:8002` to lola; this matches the WF19 `opens-on` LINKs in HG state. The T=172 wolframs-court doctrine note was originally drafted with the opposite mapping; corrected at T=173 ~17:00 CEST. `opens-on` is topology intent, not state replication: §M11 evaluates the **receiving kernel's** local state, and today the VSCode seat-topology lives on Z440 primary. Persona-takeover prompts must cite this table as authoritative; any drift is a Steinberger-flag-to-Guido-audit cycle. (Patch landed by Wolfram T=175 ~late after Guido's [round-13 audit + port-mapping rectification](https://github.com/Collider-Data-Systems/ffs0/issues/36#issuecomment-4320199704); emit-target clarification follows Wolfram's `emit-target ≠ opens-on` catch on `ffs0#36`.)
>
> ## Persona → emit-target mapping (T=175 v3.14.0, current capability)
>
> **Architectural clarification (T=175 ~late, after Karpathy's local-doctor catch).** The `opens-on` column above declares **topology intent** — which kernel a session "belongs to" semantically. It does NOT imply state-replication. Seat-topology (sessions + agents + WF19 LINKs) was materialized at T=173 batch B on **Z440 primary :8000 only** (log_seq 273–284); twin kernels :8001/:8002/:8003 ran fresh from federation startup with their own sovereign logs and don't carry seat-state. §M11 runs against the **receiving kernel's state** — primary has the seat-topology, twins do not.
>
> **Practical rule until §M9 twin-kernel adjoint sync ships (round-15+, paired with §M10 QUIC):** all Z440 persona emits target `:8000` primary HTTP / `:8080` primary MCP regardless of opens-on. Hp-laptop persona emits target hp-laptop's primary `:8000` / `:8080` (already aligned, single-kernel host).
>
> | Persona | actor URN | emit-target HTTP | emit-target MCP | opens-on (future twin-target) |
> |---|---|---|---|---|
> | Wolfram | `agent:claude-code.hp-z440` | `:8000` | `:8080` | `hp-z440.primary` (already aligned) |
> | Karpathy | `agent:vscode.hp-z440.lola` | `:8000` | `:8080` | `hp-z440.lola` (post-§M9 sync) |
> | Steinberger | `agent:vscode.hp-z440.menno` | `:8000` | `:8080` | `hp-z440.menno` (post-§M9 sync) |
> | Moos / AG-Z440 | `agent:antigravity.hp-z440` | `:8000` | `:8080` | `hp-z440.primary` (already aligned) |
> | Cowork-Z440 | `agent:claude-cowork.hp-z440` | `:8000` | `:8080` | `hp-z440.primary` (already aligned) |
> | Guido / hp-laptop VS Code | `agent:vscode.hp-laptop.copilot` | hp-laptop `:8000` | hp-laptop `:8080` | `hp-laptop.primary` (already aligned) |
> | Cowork-laptop | `agent:claude-cowork.hp-laptop` | hp-laptop `:8000` | hp-laptop `:8080` | `hp-laptop.primary` (already aligned) |
> | AG-laptop | `agent:antigravity.hp-laptop` | hp-laptop `:8000` | hp-laptop `:8080` | `hp-laptop.primary` (already aligned) |
> | HP ProDesk VS Code | `agent:vscode.hpprodesk.primary` | HP ProDesk `:8000` | HP ProDesk `:8080` | `hpprodesk.primary` (bootstrap target; explicit `session_urn=sam.hpprodesk-setup`) |
>
> Once §M9 twin_link adjoint sync ships (round-15+), the emit-target column collapses into the opens-on column for the three twin-bound personae (Karpathy/Steinberger/Moos-overflow); twin kernels become first-class emit-targets.
>
> Updated: **T=207 (May 27, 2026) ~01:35 CEST — Keep source acquisition sprint attempted; Takeout ZIP staging ready; pipeline all-pass after live Calendar observation lock** — hp-laptop primary remains healthy on `localhost:8000/healthz = {status: ok, ontology_version: 3.16.2, t_day: 207, log_len: 1467}`; no HG rewrites and no external Calendar writes were performed. Sam approved moving from postponed raw Keep ingest into structured source staging, but the official Google Keep API path is still externally blocked: `Invoke-KeepIngestHarness.ps1 -Mode ApiAuthListen -UseCalendarOAuthClient -OpenBrowser` again reached Google's consent screen and returned `Error 400: invalid_scope` for `https://www.googleapis.com/auth/keep.readonly`. Local credential readback: no dedicated Keep OAuth client/token is present; Calendar OAuth client/token are present but the owning Google Cloud project still cannot request the Keep scope. Local source scan found only the old `scratch/keep/t187-keep-notes.txt`; `Invoke-KeepIngestHarness.ps1 -Mode Stage -SourcePath scratch\keep -RunPipeline` parsed 1 note, selected 0 T195-T206 notes, excluded the T183 note as outside the requested window, and kept `apply_ready=false`. The stager now accepts Google Takeout `.zip` archives directly, using stable `file://...zip#member` source URLs, so a Takeout ZIP/folder/manual export can be staged without OAuth once placed locally. The Calendar time-fabric planner now locks written sources against live folded `calendar_event --WF07 anchors--> source` observations, preserving already-applied Calendar event dates across T-day rollover; this closes the transient T207 recommendation warning. Full session pipeline reports `pass`, 24 pass / 0 warn / 0 fail; recommendation reconciliation is again converged at grouped nodes 10/10, grouped relations 16/16, Calendar event nodes 22/22, Calendar session pins 22/22, Calendar WF07 anchors 22/22, deferred relations 0. Validation passed: Keep stager tests including ZIP support, Calendar time-fabric tests including written-source and observation-date locks, and full pipeline regeneration. New operator report: `kb/moos-diary/t207-keep-source-acquisition-and-calendar-lock-sprint.md`.
> Updated: **T=208 (May 28, 2026) ~15:15 CEST — Workspace Keep API path works; T190-T208 raw notes staged; Z440 live rejoin discovered** — hp-laptop primary is healthy at `localhost:8000/healthz = {status: ok, ontology_version: 3.16.2, t_day: 208, log_len: 1467}` and its local router was restarted to peer with live Z440 at `192.168.1.13` (router readback now sees hp-laptop `log_len=1467` and Z440 primary `log_len=449`). Z440 is physically/runtimely alive but stale: `http://192.168.1.13:{8000,8001,8002,8003}` all answer on `ontology_version=3.16.1` with log lengths `449/13/11/16`, and the Z440 router still peers to old hp-laptop `192.168.1.18`; local Z440 repo sync + federation restart remain required before Z440 agents emit. Google Keep changed from blocked/empty to real Workspace source: service-account domain-wide delegation plus keyless IAM `signJwt` now mints delegated tokens for `sam@my-tiny-data-collider.nl`; private Gmail shared notes are API-visible in the Workspace account. `Invoke-KeepIngestHarness.ps1 -Mode ApiDelegatedKeylessFetch -UseCalendarOAuthClient -TStart 190 -TEnd 208 -OutDir tmp\projections\session_pipeline\keep_t190_t208 -ApiOutDir scratch\keep\t190-t208\api` fetched 16 Keep notes, exported 16, selected 15 T190-T208 notes, excluded one T173 note, and generated a review-only candidate map of 21 nodes / 67 relations with `apply_ready=false`. No HG rewrites, Calendar writes, Project sync, or raw-note applies were performed. New wrap-up: `kb/moos-diary/t208-workspace-keep-and-z440-room-tie-wrapup.md`; handoff issue: `Collider-Data-Systems/ffs0#54`.
>
> Updated: **T=206 (May 27, 2026) ~00:50 CEST — session pipeline all-pass after visual root sprint** — hp-laptop primary still reports `localhost:8000/healthz = {status: ok, ontology_version: 3.16.2, t_day: 206, log_len: 1467}`. No HG rewrites and no external Calendar writes were performed. The visual-root warning was closed by aligning the session-occasion lens with existing folded topology: WF20 `promotes/promoted-from`, WF19 `pins-urn/pinned-by-session`, and WF07 `anchors/anchor`. The Calendar time-fabric planner now locks to source URNs present in the stored writer result when that result exists, so widened visual context does not create fresh Calendar G-readback candidates. Regenerated root coverage marks all five explicit session-occasion roots connected. Full session pipeline now reports `pass`, 24 pass / 0 warn / 0 fail; Calendar recommendation reconciliation remains converged at grouped nodes 10/10, grouped relations 16/16, Calendar event nodes 22/22, Calendar session pins 22/22, Calendar source anchors 22/22, deferred relations 0. Validation passed affected Julia tests plus full pipeline regeneration. New operator report: `kb/moos-diary/t206-visual-lens-root-coverage-sprint.md`.
>
> Updated: **T=206 (May 26, 2026) ~21:55 CEST — WF07 anchors/anchor repaired, runtime reloaded, Calendar source anchors applied** — hp-laptop primary was restarted against `kb/superset/ontology.json` v3.16.2 and now reports `localhost:8000/healthz = {status: ok, ontology_version: 3.16.2, t_day: 206, log_len: 1467}`. The ontology patch adds WF07 `anchors/anchor` as an explicit `additional_port_pair` for `calendar_event` source anchors while preserving the primary `participates/participated-by` pair. The reviewed catch-up program `dev/scripts/ops/t206-wf07-calendar-anchor-catchup.program.json` applied 66 envelopes via `Test-MoosFederation.ps1 -Mode PostProgram -Persona guido`: 22 `calendar_event` ADDs, 22 WF19 governance pins from `session:sam.governance`, and 22 WF07 `anchors/anchor` source links. Regenerated reconciliation reports grouped nodes 10/10, grouped safe relations 16/16, Calendar event nodes 22/22, Calendar session pins 22/22, Calendar source anchors 22/22, and deferred relations 0. Latest session pipeline gate is `warn`, 23 pass / 1 warn / 0 fail; only visual lens root coverage remains. Google Keep raw-note ingest remains postponed until Sam structures and approves source notes; this patch only closes the Calendar source-anchor deferral. Validation passed: ontology JSON parse, affected Julia projection/reconciliation/gate/atlas tests, `MOOS_INTEGRATION=1 go test ./internal/operad`, Keep harness `Check`, full session pipeline regeneration, endpoint preflight for all catch-up LINKs, and post-apply `/healthz` readback. New operator report: `kb/moos-diary/t206-keep-api-mvp-and-wf07-wrapup.md`.
>
> Updated: **T=194 (May 14, 2026) ~23:50 CEST — T194/T200 big topology sprint applied and Calendar readback converged** — hp-laptop primary is now `localhost:8000/healthz = {status: ok, ontology_version: 3.16.1, t_day: 194, log_len: 1354}`. The T200+ continuation was split into five scoped-idle session lanes: `session:sam.t200plus-calendar-readback`, `session:sam.t200plus-project-bridge`, `session:sam.t200plus-s0-staging`, `session:sam.t200plus-application-surface-map`, and `session:sam.t200plus-z440-rejoin`. These sessions are pinned and purpose-colored but intentionally have no `has-occupant` relations; they are not emit lanes until a reviewed payload seats an actor. Two reviewed ADD/LINK-only batches landed: the main 145-envelope `dev/scripts/ops/t194-t200-big-sprint-session-topology.program.json` moved readback to `log_len=1338`, and the 15-envelope catch-up `dev/scripts/ops/t194-t200-big-sprint-session-topology.candidate.program.json` moved readback to `log_len=1354` after the new lanes exposed five more Calendar observations. Post-apply topology planning returns `0` envelopes. Final recommendation reconciliation reports grouped nodes 10/10, grouped safe relations 16/16, Calendar event nodes 22/22, and Calendar session pins 22/22 applied; 22 WF07 `anchors/anchor` relations remain deferred for operad review. Latest session pipeline gate is `warn`, 23 pass / 1 warn / 0 fail; the remaining warning is visual lens root coverage. Validation passed: all 11 Julia test files under `dev/scripts/tests/test_*.jl`, touched JSON parse checks, and `git diff --check`. New operator report: `kb/moos-diary/t194-t200-big-sprint-topology-wrapup.md`.
>
> Updated: **T=194 (May 14, 2026) ~23:15 CEST — four-lens agent neighborhood and F/G relation-insight dashboard verified** — Follow-up sprint after the VS Code/Copilot occupancy correction makes the current context agent visible as first-class review context in every generated projection surface. `run-session-pipeline.ps1` now passes the resolved `ActorUrn` as `context-agent-urns` to all four graph artifacts and as `MOOS_PROJECTION_CONTEXT_AGENT_URNS` to all four DOT/SVG exporters. The graph/SVG lens widening rule keeps the explicit context agent plus immediate WF01/WF02/WF19 ownership, delegation, and session neighborhood visible even when ordinary type/WF/match filters would hide it. Verified generated artifacts now include `urn:moos:agent:vscode.hp-laptop.copilot` in all four graph artifact JSON node arrays and all four DOT files. The dashboard also carries F/G visual metadata: node roles (`authority`, `f-context`, `g-evidence`, `surface`, `lens`, `lineage`, `substrate`), WF relation-family labels (`authority ownership`, `delegation and role`, `channel ingest`, `composition and scope`, `session/purpose/pin`, `causal lineage`, etc.), per-lens F/G Relation Insights cards, and Graphview Stack Notes comparing Graphviz DOT/SVG, Cytoscape.js, Cytoscape layout extensions, svg-pan-zoom, vis-network, force-graph, Sigma.js + Graphology, GraphMakie + Graphs.jl, and ELK/Dagre hierarchical layouts. Latest full runner final gate reports `warn`, 22 pass / 2 warn / 0 fail. Remaining warnings are still visual lens root coverage and T189 recommendation reconciliation. Extensive validation passed: all 10 Julia projection tests under `dev/scripts/tests` passed, 338/338 total; full pipeline completed; artifact verification passed for all four graph JSONs, all four DOTs, `session_pipeline_gate.json`, `index.html`, and `git diff --check`.
>
> Updated: **T=194 (May 14, 2026) ~22:05 CEST — hp-laptop VS Code/Copilot occupancy corrected; actor/occupant/harness gate live** — Sam reported that Claude Code was not running in the current hp-laptop workstation session. Live readback confirmed the mismatch: folded HG still seated `session:sam.governance` and stale `session:t187-mvp` on `agent:claude-code.hp-laptop`, while the active IDE surface was VS Code/Copilot. hp-laptop applied the reviewed 7-envelope correction `dev/scripts/ops/t194-hplaptop-vscode-copilot-occupancy.program.json`: ADD `agent:vscode.hp-laptop.copilot`, LINK `group:sam --owns--> agent:vscode.hp-laptop.copilot`, pin the new agent to `session:sam.governance`, UNLINK both old Claude Code `has-occupant` relations, LINK `session:sam.governance --has-occupant--> agent:vscode.hp-laptop.copilot`, and MUTATE the legacy Claude Code agent status to `idle`. Runtime readback is now `localhost:8000/healthz = {status: ok, ontology_version: 3.16.1, t_day: 194, log_len: 1192}`; `agent:claude-code.hp-laptop` has 0 remaining `has-occupant` relations. Lingo/rule now used by prompts, skills, configs, and generated artifacts: HG occupant = folded WF19 topology; IDE harness surface = local VS Code/Copilot/Claude/Antigravity container; S0 conversation staging = raw chat/debug substrate pending G-ingest; actor_urn = envelope principal; mounted tool = invokable affordance, not necessarily the occupant. The session context projection now emits an `identity` block, and the MVP gate has `session actor/occupant reconciliation`; latest identity-gate runner reported `warn`, 21 pass / 2 warn / 0 fail, with identity status `pass` for `actor=vscode.hp-laptop.copilot` and occupant `vscode.hp-laptop.copilot`. Remaining warnings were visual lens root coverage and T189 recommendation reconciliation. Focused validation passed: session-context projection tests 29/29, MVP gate tests 69/69 plus 4/4 gap tests, config JSON parse, `VerifyPersona -Persona guido` against the new actor, and `go test ./internal/operad` after updating the kernel helper so v3.13 `group` principals are accepted by occupancy/admin resolution. Skill sync refreshed 12 local Claude skills from `dev/claude-skills`. `moos-kernel` code is tested but the live hp-laptop binary has not been rebuilt in this entry; the live topology correction itself is already applied on the graph.
>
> Updated: **T=194 (May 14, 2026) ~21:34 CEST — VS Code Agents surface, four-lens Calendar dashboard, Google Calendar write, SVG zoom panes, and S0 staging closeout** — Current hp-laptop readback remains `localhost:8000/healthz = {status: ok, ontology_version: 3.16.1, t_day: 194, log_len: 1184}`; router `localhost:9000` is ok with local hp-laptop up and Z440 still down. Session traceability for this projection lane was `urn:moos:session:sam.governance` / `urn:moos:agent:claude-code.hp-laptop` on `urn:moos:kernel:hp-laptop.primary` before the later T194 VS Code/Copilot occupancy correction above; HP ProDesk projection readback remains tied to `urn:moos:session:sam.hpprodesk-setup` / `urn:moos:agent:vscode.hpprodesk.primary` on `urn:moos:kernel:hpprodesk.primary`. The T194 local worktree now carries intended projection/IDE edits: VS Code custom-agent/opener prompt wiring, portable workspace verification, HP ProDesk MCP template update, session-affordance refresh, four graph artifacts, four DOT/SVG visual lenses with SVG zoom panes, four Cytoscape inspector views, Calendar planner metadata, MVP gate update, focused tests, and a refreshed `moos-session-context-projection` skill source. Latest full runner final gate was generated at `2026-05-14T19:34:32Z` (`~21:34 CEST`) and reports `warn`, 20 pass / 2 warn / 0 fail; the remaining warnings are visual lens root coverage and T189 recommendation reconciliation. Focused MVP gate tests pass 69/69, and Edge/CDP browser validation passed against `tmp/projections/session_pipeline/index.html`, including four SVG objects, SVG zoom/reset/wide controls, and four Cytoscape inspector tabs. Calendar Time-Fabric lens selects 44/433 nodes and 54/444 relations; Calendar-scope lens selects 53/433 nodes and 62/444 relations, with 8 components, largest component 46, 11 explicit roots, and 0 disconnected forced roots. The dashboard groups review surfaces by role; static SVG zoom panes are deterministic Graphviz projection views, while the interactive HG inspector has search, fit, zoom, reset, layout, and wide-view modal controls over graph-artifact JSON. External Google Calendar write was performed deliberately as an actuator boundary: 16 existing events were patched by `moos_projection_id`, 0 inserts. No HG rewrites were applied for this T194 closeout; the new T194 Calendar `calendar_event` observations and WF19 session pins remain pending HG apply rows, while WF07 source anchors remain deferred. New operator report: `kb/moos-diary/t194-vscode-agents-calendar-scope-and-session-staging-wrapup.md`.
>
> Updated: **T=194 (May 14, 2026) ~18:56 CEST — hp-laptop readback after HP ProDesk T193; T187 path re-synthesized** — Current hp-laptop readback is stable and doc-only: `localhost:8000/healthz = {status: ok, ontology_version: 3.16.1, t_day: 194, log_len: 1184}`; `localhost:9000/healthz` is ok with the local kernel up and remote Z440 still down. Repo readback: `ffs0/main` has one local tracked workspace edit (`ffs0.code-workspace`, Downloads path style only); `moos-kernel/master` is clean; `moos-router/feat/type-map-routing` is clean. GitHub readback: no open `ffs0` issues; Project #4 `mo:os` is active with 107 items and 19 fields. `kb/superset/ontology.json` parses as JSON and reports version `3.16.1`. The old instruction path `kb/research/kernel/20260417-t187-kernel-proper.md` no longer exists in this checkout; current references to it are stale historical references unless the archive copy is recovered elsewhere. Use the running-state T187 rows plus the T187/T188/T189 diary reports as the current path: old `program:sam.t187-kernel-proper` and `program:sam.t187-distributed-hg-mvp` are archived, `session:sam.t187-mvp` is abandoned, and the live continuation is the Keep/session/visual/Calendar/recommendation/atlas projection family proven again by HP ProDesk against the shared hp-laptop graph. New operator report: `kb/moos-diary/t194-t187-path-and-hplaptop-readback.md`. No HG rewrites, topology payloads, Calendar writes, Project G-sync, or ontology edits were performed in this readback.
>
> Updated: **T=193 (May 13, 2026) ~19:55 CEST — HP ProDesk copied projection report received; closeout confirmed** — The HP ProDesk VS Code agent copied back its final readback after the shared-graph dry projection. Its local `ffs0/main` was clean at `e6ed37b` during the run, while hp-laptop had already advanced the closeout docs to `d12b52a`. The copied report confirms Julia `1.12.6` and `JSON3` work on HP ProDesk; local primary remains `http://localhost:8000/healthz = {status: ok, ontology_version: 3.16.1, t_day: 193, log_len: 26}`; `VerifyPersona -Persona hpprodesk-vscode` passes; hp-laptop is reachable on `172.29.0.38:8000` and `:9000`; shared projection from `http://172.29.0.38:8000` completed with `PROJECTION_EXIT=0`; local ignored artifacts exist at `tmp/projections/session_pipeline/session_context/current_session.md`, `tmp/projections/session_pipeline/mvp/session_pipeline_gate.md`, and `tmp/projections/session_pipeline/index.html`; gate result is `warn`, 17 pass / 3 warn / 0 fail. The remaining warnings are known projection-surface work: visual lens root coverage, missing Graphviz/static SVG output on HP ProDesk, and T189 recommendation reconciliation. No blocker remains for HP ProDesk seating. No HG payloads were applied, neither T193 program JSON was replayed, and the identity boundary held: no `user:geurt`, no `group:geurt`, no Gmail/auth/account channels, no secret nodes, and no account identity nodes.
>
> Updated: **T=193 (May 13, 2026) ~19:25 CEST — HP ProDesk runtime proof complete; shared-graph projection succeeds locally** — HP ProDesk VS Code on workstation key `hpprodesk` is now a real local mo:os setup session and a projection-capable workstation. Local machine readback: hostname `DESKTOP-3FC7C3F`, Windows login `desktop-3fc7c3f\geurt` (social/report context only), Ethernet IPv4 `172.29.0.32/26`, repos under `C:\Users\Geurt\CDS`, and `ffs0/main@8a90b65` with `## main...origin/main`. Local HP ProDesk primary remains `http://localhost:8000/healthz = {status: ok, ontology_version: 3.16.1, t_day: 193, log_len: 26}` and active `moos-kernel/moos.jsonl` remains 26 lines; `VerifyPersona -Persona hpprodesk-vscode` passes against `agent:vscode.hpprodesk.primary` / `session:sam.hpprodesk-setup`. Julia was installed on HP ProDesk via winget at `C:\Users\Geurt\AppData\Local\Programs\Julia-1.12.6\bin\julia.exe` (`julia version 1.12.6`), with the needed user-environment packages including `JSON3`; this was a local tool install, not a repo edit. A first projection attempt against the 26-line local graph correctly stopped at the graph-artifact step because the minimal HP ProDesk local graph lacks the historical T187/T189 roots. The successful projection run used HP ProDesk as the local artifact writer but read the shared hp-laptop graph at `http://172.29.0.38:8000`: `dev/scripts/projections/run-session-pipeline.ps1 -BaseUrl http://172.29.0.38:8000 -SessionUrn urn:moos:session:sam.hpprodesk-setup -ActorUrn urn:moos:agent:vscode.hpprodesk.primary` completed with exit code 0 and generated local ignored artifacts under `tmp/projections/session_pipeline/`, including `session_context/current_session.md`, `mvp/session_pipeline_gate.md`, and `index.html`. Final MVP gate: `warn`, 17 pass / 3 warn / 0 fail. Warnings are projection-surface issues, not bootstrap blockers: forced/disconnected visual roots under the current lens, missing SVGs because Graphviz is not installed on HP ProDesk, and T189 recommendation reconciliation/pending-deferred rows. Health after projection stayed stable: HP ProDesk local `log_len=26`; hp-laptop primary `status=ok`, `ontology_version=3.16.1`, `t_day=193`, `log_len=1184`. No HG payloads were applied, neither T193 program JSON was reapplied, and the identity boundary held: no `user:geurt`, no `group:geurt`, no Gmail/auth/account channels, no secret nodes, and no account identity nodes.
>
> Updated: **T=193 (May 13, 2026) ~18:25 CEST — HP ProDesk local setup session bootstrapped; persona verification passes** — hp-laptop then applied the local HP ProDesk session-layer bootstrap to `kernel:hpprodesk.primary` via `dev/scripts/ops/t193-hpprodesk-local-session-bootstrap.program.json` and `Test-MoosFederation.ps1 -Mode PostProgram -Persona hpprodesk-vscode -Force`. Force was required because the target session/occupant/open-on links were the missing preflight items. The 21-envelope batch preserved the 5-line seed graph and added local `group:sam`, `agent:vscode.hpprodesk.primary`, `purpose:sam.hpprodesk-workstation-bootstrap`, `session:sam.hpprodesk-setup`, and `program:sam.t193.hpprodesk-topology-materialization`, plus ownership, purpose-program, and WF19 session links. HP ProDesk local readback is now `/healthz = {status: ok, ontology_version: 3.16.1, t_day: 193, log_len: 26}`; `VerifyPersona -Persona hpprodesk-vscode` passes; the setup session has 9 outgoing relations and `group:sam` has 6 HP ProDesk ownership relations. Deliberate non-scope remains unchanged: no Geurt authority node, no account/channel modeling, and no secrets.
>
> Updated: **T=193 (May 13, 2026) ~18:15 CEST — HP ProDesk shared topology materialized on hp-laptop primary** — Sam moved from inventory to implementation, and hp-laptop applied the topology-safe HP ProDesk batch via `dev/scripts/ops/t193-hpprodesk-topology-materialization.program.json` using `Test-MoosFederation.ps1 -Mode PostProgram -Persona guido`. The 23-envelope batch landed on `kernel:hp-laptop.primary`, moving runtime readback to `/healthz = {status: ok, ontology_version: 3.16.1, t_day: 193, log_len: 1184}`. New shared-HG nodes now resolve: `workstation:hpprodesk`, `kernel:hpprodesk.primary`, `agent:vscode.hpprodesk.primary`, `purpose:sam.hpprodesk-workstation-bootstrap`, `session:sam.hpprodesk-setup`, and `program:sam.t193.hpprodesk-topology-materialization`. Readback confirms 9 outgoing WF19 relations from the setup session (`opens-on`, `has-purpose`, `has-occupant`, and 6 pins), 6 HP ProDesk ownership relations from `group:sam`, and one WF03 hosting relation from `workstation:hpprodesk` to `kernel:hpprodesk.primary`. Deliberate non-scope remains unchanged: no `user:geurt`, no `group:geurt`, no Gmail/auth/account channel, and no secrets or raw account identifiers. This apply materialized the shared governance mirror on hp-laptop; the HP ProDesk local session layer landed in the follow-up entry above.
>
> Updated: **T=193 (May 13, 2026) ~17:35 CEST — HP ProDesk social/topology inventory written; identity remains proposal-only** — New diary packet `kb/moos-diary/t193-hpprodesk-social-topology-inventory.md` records the read-only HP ProDesk inventory and the revised Geurt/Gmail identity proposal. Readback: HP ProDesk local kernel remains `status=ok`, `ontology_version=3.16.1`, `t_day=193`, `log_len=5`; hp-laptop kernel remains reachable at `172.29.0.38:8000` with `log_len=1160`; hp-laptop router `:9000` is `status=ok` and reports Z440 `192.168.1.11` down. Local HP ProDesk HG is only `user:sam`, `workstation:hpprodesk`, `kernel:hpprodesk.primary`, WF01 user ownership, and WF03 hosting. Shared hp-laptop HG has no `workstation:hpprodesk`, `kernel:hpprodesk.primary`, `agent:vscode.hpprodesk.primary`, `session:sam.hpprodesk-setup`, `purpose:sam.hpprodesk-workstation-bootstrap`, `group:geurt`, `group:geurt-household`, or `user:geurt` yet. Identity correction: current ontology makes `user` an authority-bearing human principal; Geurt and HP ProDesk Gmail/Google settings should enter first as report context, `knowledge_item` evidence, or reviewed `channel`/auth-account surface. `user:geurt` is non-default and requires Sam approval. No HG rewrites, secrets, raw email addresses, OAuth IDs, tokens, or client files were applied or recorded. Next gate: Sam chooses whether account identity is evidence, mailbox channel, or future auth-account model before the reviewed HP ProDesk topology batch.
>
> Updated: **T=193 (May 13, 2026) ~16:55 CEST — HP ProDesk local primary proved; docs are projection/readback, not source of truth** — HP ProDesk at Geurt's place is running as workstation key `hpprodesk` on Windows host `DESKTOP-3FC7C3F`, Ethernet IPv4 `172.29.0.32/26`. The local CDS clones are `C:\Users\Geurt\CDS\{ffs0,moos-kernel,moos-router}` with `ffs0/main@6647d47` (`docs: fix HP ProDesk seed identity`), `moos-kernel/master@b5935e0`, and `moos-router/master@18212eb`. Go test/build passed on `moos-kernel`; one local primary kernel was restarted from `C:\Users\Geurt\CDS\moos-kernel\moos-kernel.exe` with explicit `--seed --seed-user sam --seed-ws hpprodesk`, replaying the 5-line HP ProDesk seed log and reporting `/healthz = {status: ok, ontology_version: 3.16.1, t_day: 193, log_len: 5}` on `localhost:8000`. The earlier mistaken `hp-laptop` seed log was preserved as `moos.hp-laptop-seed-misfire.20260513-161015.jsonl`; active `moos.jsonl` contains no `workstation:hp-laptop` or `kernel:hp-laptop` seed refs. Hp-laptop is reachable at `172.29.0.38`: kernel `:8000` reports `status=ok`, `ontology_version=3.16.1`, `t_day=193`, `log_len=1160`; router `:9000` reports `status=ok` and still marks Z440 `192.168.1.11` down. No HP ProDesk HG rewrite batch has been applied yet. This running-state entry is a hot hydration projection of verified readback; live JSONL logs plus `/healthz` remain the operational source of truth.
>
> Updated: **T=193 (May 13, 2026) ~16:30 CEST — HP ProDesk topology packet wrapped on ffs0/main** — The HP ProDesk concrete readback is now the admin/control baseline: workstation key `hpprodesk`, planned kernel `kernel:hpprodesk.primary`, setup session `session:sam.hpprodesk-setup`, VS Code actor `agent:vscode.hpprodesk.primary`, HP ProDesk LAN `172.29.0.32`, and hp-laptop LAN `172.29.0.38`. `dev/config/moos-federation.topology.json`, `dev/config/session-affordance-map.json`, `Test-MoosFederation.ps1`, the HP ProDesk bootstrap prompt, and the T193 inventory generator/test were normalized away from the old `hppro` placeholder and pushed as `ffs0/main@0725b48`. Validation passed: config JSON parse, PowerShell parser, Julia inventory test 18/18, and `git diff --check`. No HG rewrites or secret transfer happened yet; HP ProDesk should next pull `main`, prove one local primary `/healthz`, and report back before applying the reviewed workstation/session batch. Full diary report: `kb/moos-diary/t193-hpprodesk-workstation-bootstrap-wrapup.md`.
>
> Updated: **T=193 (May 13, 2026) ~14:15 CEST — ffs0 trunk-first admin policy corrected + HP ProDesk bootstrap packet on main path** — Sam clarified that `ffs0` is the private KB/admin/dev-control repo, while `moos-kernel` and `moos-router` are the portable runtime code repos downloaded and run by workstations. Policy is now trunk-first for `ffs0`: verified running-state, diary, shared prompts, setup packets, topology notes, and tested dry planners should land on `ffs0/main` promptly so hp-laptop, HP ProDesk, and later Z440 hydrate without feature-branch ceremony. `ffs0` branches are exceptional conflict/WIP shelves only; stale feature branches should be merged/fast-forwarded to `main` and deleted after verification. Runtime code changes still branch in `moos-kernel` and `moos-router`. T193 HP ProDesk bootstrap packet started as commit `8136b8a` on `sam/t190-team-workspace-expansion`; this policy correction carries the packet to the `ffs0/main` path and makes branch retirement the correct closeout after verification.
>
> Updated: **T=190 (May 10, 2026) ~09:05 CEST — session branch/closeout policy clarified** — `ffs0/main` is now the coordination trunk for verified state packets: running-state updates, `kb/moos-diary/` wrap-ups, small handoff prompts, and apply records should travel together there when they are verified and needed by other sessions immediately. Branch first for WIP, projection/script implementation, workspace file edits, runtime repo code, large doc reorganizations, and identity/account proposals. Durable policy: `kb/moos-diary/t190-session-branch-and-closeout-policy.md`; shared prompt update: `.github/prompts/multi-workstation-git-flow.prompt.md`; Z440 finish prompt now points at the policy. Session is HG occasion; branch is repo transport; workstation/persona names belong in branch names when they help handoff.
>
> Updated: **T=190 (May 10, 2026) ~05:05 CEST — Z440 Windows 11 session desktops scaffolded** — Z440 now has a local Windows-session startup map at `dev/config/z440-session-desktops.json` and launcher `dev/scripts/ops/Start-Z440SessionDesktops.ps1`. Desktop 1 is mapped to `session:sam.z440-vscode-projection-lead` / `agent:vscode.hp-z440.primary` as the four-monitor VS Code projection cockpit; Desktop 2 maps to `session:sam.kernel-proper`, Desktop 3 to `session:sam.steinberger-seat`, Desktop 4 to `session:sam.karpathy-seat`, and Desktop 5 to `session:sam.moos-diary`. `setup-autostart-z440.ps1` now keeps federation autostart separate and replaces the old one-app-per-task launchers with `moos-session-desktops-autostart`. Dry-run validated local health plus Desktop 1 app launch preview. Current W11 caveat: no `VirtualDesktop` PowerShell module or PowerToys install is present on this host, so the launcher intentionally starts only Desktop 1 apps until a compatible virtual-desktop helper is installed; Desktop 2+ are still recorded as the session map. Full report: `kb/moos-diary/t190-z440-windows-session-desktops-wrapup.md`.
>
> Updated: **T=190 (May 10, 2026) ~04:45 CEST — Z440 finish prompt executed; no-arg session pipeline works from VS Code lead** — Z440 VS Code pulled the hp-laptop handoff through commit `781f756`, protected local ffs0 work on branch `z440/t190-projection-finish`, and pushed finish commit `7488906` plus the diary/running-state follow-up. Doctor remains green across all five kernels on `ontology_version=3.16.1` (Z440 primary `log_len=449`, hp-laptop primary `1160`), `VerifyPersona -Persona z440-vscode-lead` passes, and the four T190 admin parity relations remain present. `run-session-pipeline.ps1` now auto-resolves the Z440 lead session/actor from primary and uses local router `http://localhost:9000` as the read-only projection surface for shared graph lenses; no-argument runner result is `warn`, 18 pass, 2 warn, 0 fail, dashboard `tmp/projections/session_pipeline/index.html`. Remaining warnings: disconnected forced roots on the session-occasion lens and pending/deferred Calendar-event recommendation rows. Full finish report: `kb/moos-diary/t190-z440-projection-finish-wrapup.md`.
>
> Updated: **T=190 (May 10, 2026) ~04:20 CEST — Z440 VS Code lead HG parity applied + session-centered handoff packet** — Sam approved the reviewed Z440 admin parity batch and hp-laptop applied it to Z440 primary via `Test-MoosFederation.ps1 -Mode PostProgram -Persona z440-vscode-lead`. Z440 primary readback moved to `ontology_version=3.16.1`, `t_day=190`, `log_len=449`; all four intended relations are now present: `group:sam` owns `session:sam.z440-vscode-projection-lead`, `purpose:sam.z440-vscode-projection-lead-operations`, and `program:sam.t190.z440-vscode-projection-lead-transition`, and the session pins `group:sam` via WF19 `pins-urn`. Apply record: `dev/scripts/ops/t190-z440-admin-parity-review.program.json` (marked applied/do-not-reapply). Project #4 HG identity repair stayed separate from HG rewrites: five unambiguous `HG URN` text fields were populated, raising coverage from 26/57 to 31/57; 26 rows remain empty, 4 of those have multiple resolvable URNs needing human choice, and 2 populated rows still carry legacy non-URN values. No board status G-sync was performed. `kb/moos-diary/` is now framed as a session-centered wrap-up shelf for all agents/personae, with `kb/moos-diary/t190-z440-vscode-lead-handoff-wrapup.md` closing the T189/T190 handoff arc. Handoff prompt `.github/prompts/z440-vscode-t190-finish-today.prompt.md` now tells Z440 to read running-state plus the diary packet, branch before shared-file edits, treat IDE conversations as S0 substrate, and model added Gmail/Git accounts as `channel` surfaces rather than authority-bearing `user` principals. Shared-repo rule: hp-laptop can land canonical state/prompt docs on `ffs0/main`, but Z440 should branch before editing shared scripts/docs/workspace files.
>
> Updated: **T=190 (May 10, 2026) — Z440 VS Code lead access parity and bidirectional router readback** — Z440's active Ethernet IPv4 is now confirmed as `192.168.1.11` (gateway `192.168.1.1`, MAC `90:E2:BA:14:81:DA`). The federation port map, topology config, router README example, and audit skill comments were refreshed from the stale `.13` address to `.11`. Hp-laptop's router autostart now launches `moos-router.exe` with shard `urn:moos:ws:hp-z440=http://192.168.1.11:8000` and peer cascade `--peer http://192.168.1.11:9000`; the live router was restarted without touching the kernel/log. Readback: hp-laptop router `:9000` resolves both `session:sam.governance` and `session:sam.z440-vscode-projection-lead`; Z440 router `:9000` resolves both sessions as well; all five kernels pass `Test-MoosFederation.ps1 -Mode Doctor` on v3.16.1. Cloudflare tunnel `3b748eb8-9032-4e9f-a20c-a06d494e9b58` is running from the hp-laptop startup config, metrics port `20241` is reachable, and `https://api.my-tiny-data-collider.nl/healthz` plus `https://kernel.my-tiny-data-collider.nl/healthz` return HTTP 200. Remaining operational recommendation: reserve `192.168.1.11` for the Z440 Ethernet MAC in DHCP so the federation map stays stable.
>
> Updated: **T=189 (May 9, 2026) ~17:35 CEST — surface context atlas integrated** — The projection lane now generates a `Surface Context Atlas` as a first-class local artifact and dashboard section. Runtime readback after the small HG carrier batch is `ontology_version=3.16.1`, `t_day=189`, `log_len=1160`. Five rewrites landed on hp-laptop primary: ADD `program:sam.t189.surface-context-atlas`, WF18 compose from `purpose:sam.t189-t200plus-time-fabric-convergence`, WF19 governance pin from `session:sam.governance`, and two WF21 causal links from `derivation:guido.architecture-syntax-interpretation` and `program:sam.t189.cytoscape-typed-hg-inspector`. New script `dev/scripts/surface_context_atlas.jl` emits `tmp/projections/session_pipeline/atlas/surface_context_atlas.{json,md}` with seven explanatory surfaces: JSON API, JSONL log, Git repositories, Google Calendar, dashboard, visuals, and types/relations/programs. It also lists existing HG anchors for category/functor logic, UI/UX visualization, and the `my-tiny-data-collider` application surface map; includes a step-by-step HG use path; and names the five pending moves. The runner now does first MVP gate -> atlas -> final MVP gate, so `index.html` links the atlas JSON/Markdown. Latest full runner: `warn`, 19 pass, 1 warn, 0 fail. Focused validation passed: atlas test 17/17, MVP gate tests 41/41 plus 4/4 gap tests, reconciliation 23/23, Calendar time-fabric 12/12, recommendation projection 15/15. WF07 remains honestly marked `pending-ontology-patch`; Project #4 row identity, reusable lens contracts, `my-tiny-data-collider` surface map, and runtime-repos-boring remain named next moves. Latest operator report: `kb/moos-diary/t189-surface-context-atlas-wrapup.md`.
>
> Updated: **T=189 (May 9, 2026) ~17:10 CEST — Calendar event readback applied, skills refreshed, public surfaces updated** — The individual Calendar readback slice is now applied on hp-laptop primary. Runtime readback is `ontology_version=3.16.1`, `t_day=189`, `log_len=1154`. Reconciliation now reports grouped nodes 10/10 applied, grouped safe relations 16/16 applied, Calendar event nodes 16/16 applied, Calendar event session pins 16/16 applied, and 16 WF07 `anchors/anchor` relations explicitly deferred for operad review. Google Calendar writer was rerun as the explicit actuator boundary and produced 16 `patch` actions keyed by `moos_projection_id`, with no duplicate inserts. The T189 recommendation lens now includes `calendar_event`; latest recommendation graph artifact is 46 nodes / 58 relations with all 16 Calendar event observations visible. Five active skills were assessed and updated: `moos-tooling-dx`, `moos-session-context-projection`, `moos-state-readback`, `moos-categorical-research`, and `moos-rewrite-envelope`. Public surfaces moved too: GitHub Project #4 description/readme now frames the board as an HG-identity control surface, and the public `Collider-Data-Systems/.github` org profile now presents kernel/router/runtime/application/projection boundaries. Latest operator report: `kb/moos-diary/t189-calendar-event-public-surface-wrapup.md`. Validation: reconciliation test 23/23, MVP gate tests 38/38 plus 4/4 gap tests, Calendar time-fabric tests 12/12, recommendation projection tests 15/15, full runner `warn` with 18 pass, 1 warn, 0 fail. Remaining warning is the older disconnected forced-root coverage on the session-occasion lens.
>
> Updated: **T=189 (May 9, 2026) ~15:55 CEST — recommendation reconciliation + T189 lens visible** — The session pipeline now has an explicit T189 recommendation scope lens and reconciliation artifact. New outputs under `tmp/projections/session_pipeline/`: `graph_artifacts/t189_recommendation_engineering.{json,md}`, `visual/t189_recommendation_frame.{dot,svg}`, and `recommendations/t189_recommendation_reconciliation.{json,md}`. Reconciliation compares the dry recommendation plan against folded HG state: grouped nodes are 10/10 applied, safe grouped WF01/WF18/WF19/WF21 relations are 16/16 applied, 16 individual `calendar_event` nodes remained pending at that checkpoint, and 16 WF07 `anchors/anchor` relations remained deferred for operad review. Dashboard `index.html` exposes two Cytoscape.js inspector tabs: Session Occasion and T189 Recommendations. The ignored one-shot `tmp/projections/session_pipeline/recommendations/apply_t189_grouped.ps1` actuator script was removed after its prior apply use; the cleanup gate now passes. Validation at that checkpoint: reconciliation test 16/16, MVP gate tests 42/42, graph artifact tests 11/11, Calendar time-fabric tests 12/12, recommendation projection tests 15/15, full runner `warn` with 18 pass, 1 warn, 0 fail. Browser check confirmed Cytoscape loaded and the T189 tab rendered. Hp-laptop health readback then: `ontology_version=3.16.1`, `t_day=189`, `log_len=1121`.
>
> Updated: **T=189 (May 9, 2026) ~15:35 CEST — grouped recommendation HG apply + Cytoscape inspector prototype** — First safe apply candidate from the T189 recommendation plan is now on hp-laptop primary: 26 envelopes landed via `POST /programs` as a top-level array, moving runtime to `ontology_version=3.16.1`, `t_day=189`, `log_len=1113`. The batch ADDed the 10 grouped carriers (`purpose:sam.t189-t200plus-time-fabric-convergence`, the three T189 program nodes, `view_filter:sam.t189-time-fabric-session-lens`, `group:my-tiny-data-collider`, `purpose:sam.my-tiny-data-collider-application`, `program:sam.t192.application-group-model-my-tiny-data-collider`, `program:sam.t200plus.identity-stable-projection-surface-convergence`, and the grouped Calendar ingest derivation) plus 16 safe WF01/WF18/WF19/WF21 relations. Calendar-event nodes and WF07 `anchors/anchor` relations remain deferred pending fresh Calendar readback and operad review. The dashboard generator now embeds an `Interactive HG Inspector` backed by Cytoscape.js element data from `session_occasion_engineering.json`; focused tests pass 31/31, the full runner reports `warn`, 14 pass, 1 warn, 0 fail, and a browser check confirmed Cytoscape loaded with 16 nodes / 20 relations. The only remaining MVP warning is disconnected forced visual roots under the current lens.
>
> Updated: **T=189 (May 9, 2026) ~14:45 CEST — recommendation HG projection and T200 node/relation plan** — Second T189 sprint added a dry recommendation projection lane: `dev/scripts/t189_t200_recommendation_projection.jl` reads the ontology plus Calendar plan/write result and emits `tmp/projections/session_pipeline/recommendations/t189_t200_recommendation_hg_plan.{json,md}`. The plan chooses a hybrid Calendar G-ingest shape: each real Google Calendar write becomes an individual candidate `calendar_event` node carrying `date`, `t_day`, `gcal_id`, `color_label`, and `status`; one grouped derivation records the ingest decision and causes `program:sam.t189.calendar-event-g-ingest-shape`. The five T189 recommendations now project as candidate HG carriers: `program:sam.t189.calendar-event-g-ingest-shape`, `program:sam.t189.github-project-urn-refresh`, `program:sam.t189.cytoscape-typed-hg-inspector`, `view_filter:sam.t189-time-fabric-session-lens`, and `group:my-tiny-data-collider`, under purpose `purpose:sam.t189-t200plus-time-fabric-convergence` and T200 carrier `program:sam.t200plus.identity-stable-projection-surface-convergence`. The runner now includes the recommendation projection before the MVP gate; dashboard `index.html` has an `HG Recommendations` panel. Latest full runner before apply: `warn`, 13 pass, 2 warn, 0 fail; recommendation artifact contains 26 candidate nodes, 32 candidate relations, and 16 deferred WF07 `anchors/anchor` relation checks because `calendar_event` declares an `anchors` port and port-color compatibility mentions WF07 anchors, but the top-level WF07 declaration still names `participates/participated-by`. New report: `kb/moos-diary/t189-recommendation-hg-projection-wrapup.md`.
>
> Updated: **T=189 (May 9, 2026) ~12:30 CEST — T189 wrap-up broadens Calendar/dashboard/org boundary** — New report `kb/moos-diary/t189-calendar-dashboard-organization-wrapup.md` records progress since the T188 session-pipeline report: live Calendar proof, widened governance session pins, Calendar time-fabric planner, dashboard/visual integration, GitHub org/project readback, and the clarified kernel/application boundary. GitHub readback: `Collider-Data-Systems` has 5 repos (`moos-kernel`, `moos-router`, `.github`, private `ffs0`, private `demo-repository`); Project #4 `mo:os` is active/private with 55 items, 19 fields, and status counts 24 Done / 17 Todo / 14 In Progress. The current CLI item readback reports 0 non-empty `HG URN` fields, so Project #4 remains a useful human control surface but is not yet G-direction round-trip-safe. Repository docs/instructions now make the boundary explicit: `moos-kernel` is the OS-facing runtime function program, `moos-router` is federation routing, `ffs0` is the research/control workspace, and `my-tiny-data-collider` should be modeled as an HG application group/domain with websites, DNS, servers, Calendar/GitHub/Workspace surfaces, not as the kernel codebase itself. Next T189/T200 priorities: commit the Calendar/dashboard doc set, choose Calendar-event G-ingest shape, refresh Project #4 `HG URN` coverage, prototype Cytoscape.js typed-HG inspector, and model application groups separately from runtime repos.
>
> Updated: **T=189 (May 9, 2026) ~11:45 CEST — governance session scope widened for Calendar/time-fabric continuation** — Runtime readback is `ontology_version=3.16.1`, `t_day=189`, `log_len=1086`. Sam's cited Google Calendar event decodes to `adcc2e5sulgdcj5l8nc6f7880k`, matching the prior T186 Calendar projection event for `program:sam.t200plus.temporal-projection-fabric` in `kb/moos-diary/t187-t186-google-calendar-projection-report.md`. Rather than only adding a standalone proof-result node, the T189 first move was to broaden `session:sam.governance` directly: six kernel-authored WF19 `pins-urn` LINKs now pin the existing Calendar/time-fabric roots and result (`channel:google.calendar.sam`, `derivation:guido.t200plus-google-calendar-write-result`, `program:sam.t200plus.temporal-projection-fabric`, `program:sam.t200plus.google-calendar-projection-contract`, `program:sam.t200plus.google-calendar-projection-planner`, `program:sam.t200plus.google-calendar-oauth-writer`). Regenerated `tmp/projections/session_pipeline/session_context/current_session.{json,md}` now shows 9 scope roots, so future session context includes the Calendar projection fabric as live governance scope. The May 8 Calendar time-fabric proof also wrote 16 `mo:os ...` events to Sam's primary Google Calendar; local planner/test/docs WIP lives in `dev/scripts/calendar_time_fabric_projection.jl`, `dev/scripts/tests/test_calendar_time_fabric_projection.jl`, and README updates. The local dashboard now includes the Calendar time-fabric plan/report/write-result links and embeds a second Graphviz surface, `tmp/projections/session_pipeline/visual/temporal_calendar_frame.svg`, beside the existing session-occasion SVG. Latest runner result: `warn`, 12 pass, 2 warn, 0 fail. Next T189 items: finish validating/committing the Calendar time-fabric planner lane, decide whether to G-ingest the 16 written events as `calendar_event` nodes or one derivation/result, and continue the interactive typed-HG lens inspector.
>
> Updated: **T=188 (May 8, 2026) ~15:50 CEST — T187/T188 session pipeline wrap-up report written** — Closed the T187/T188 Keep/session/visual projection lane with report `kb/moos-diary/t188-t187-session-pipeline-mvp-report.md`, mirroring the prior Google Calendar report format: starting point, concrete pipeline result, design choices, programming patterns, root-coverage/lens semantics, category-theoretic reading, filesystem interface, cleanup provenance, current MVP status, and T189 recommendations. Current result: the dry lane is MVP-usable with warnings, not blocked. The durable WF19 purpose gap for `session:sam.governance` is closed; remaining warnings are disconnected forced visual roots and absence of an interactive Cytoscape.js-style inspector. Next T189 focus: interactive typed-HG lens surface, reusable lens spec / possible `view_filter` carrier, and relation decision for the forced roots. Runtime remains `ontology_version=3.16.1`, `t_day=188`, `log_len=1080`.
>
> Updated: **T=188 (May 8, 2026) ~13:20 CEST — Keep/session/visual projection lane MVP-gated** — Continued the T187 1-2-3 lane as a dry CICD/functorial-semantics pipeline: G-ingest from Sam's Keep export into HG evidence; F-projection from folded HG into a VS Code/agent/harness session context pack; F-projection from folded HG into graph engineering JSON/Markdown and DOT/SVG visual artifacts. New Julia gate `dev/scripts/session_pipeline_mvp_gate.jl` emits `tmp/projections/mvp/session_pipeline_gate.{json,md}` and checks live runtime health, Keep channel + knowledge_item + WF12 evidence topology, session handoff header, session occasion topology, affordance pack, graph root coverage, static visuals, lens controls, and renderer readiness. Live T188 run: runtime `ontology_version=3.16.1`, `t_day=188`, `log_len=1079`; session context tests 24/24; graph artifact tests 16/16; MVP gate tests 13/13; regenerated session pack has 5 skills, 8 extensions, 7 MCP servers; graph pack and SVG have 16 nodes and 20 relations; MVP gate result is `warn` with 10 pass, 3 warn, 0 fail. Warnings are the intended next gates: `session:sam.governance` still lacks durable WF19 `has-purpose`, four forced graph roots are visible but not relation-connected under the current lens, and interactive visual inspection is not built yet. Context7/library scan chose: keep Graphviz DOT/SVG for static MVP review; prototype Cytoscape.js next for interactive typed-HG lensing; keep vis-network as a small fallback and force-graph for later dense canvas exploration. No HG rewrites emitted in this step.
>
> Updated: **T=188 (May 8, 2026) ~14:40 CEST — session pipeline control surface + artifact layout** — Organized the current Keep/session/visual projection lane as a local FS pipeline under `tmp/projections/session_pipeline/`: `session_context/` for the session pack, `graph_artifacts/` for the engineering report, `visual/` for DOT/SVG, `mvp/` for gate JSON/Markdown, and `index.html` as the human-facing control surface. Added orchestrator `dev/scripts/projections/run-session-pipeline.ps1`; kept the existing Julia adapters as stable entrypoints but changed their session-lane defaults to the grouped artifact layout. `session_pipeline_mvp_gate.jl` now emits pipeline stages, priority actions, interface-principle metadata, and HTML. Best-practice scan applied: Dagster-style asset health/freshness/materialization metadata -> pass/warn/fail gates plus runtime/artifact metadata; Cytoscape.js graph UI practice -> next interactive renderer should use typed element data, selectors/styles/layouts, selection events, and an inspector panel. Validation after reorg: skill sync 12/12; session context tests 24/24; graph artifact tests 16/16; MVP gate tests 20/20; full runner result `warn` with 10 pass, 3 warn, 0 fail. Dashboard opened locally from `tmp/projections/session_pipeline/index.html`; Graphviz filter label was wrapped and SVG/DOT direct links added after first visual sanity check showed the static graph too compressed. No HG rewrites emitted.
>
> Updated: **T=188 (May 8, 2026) ~15:20 CEST — scripts/output README cleanup + governance WF19 purpose anchored** — Added README markers for active script lanes (`dev/scripts/ops`, `dev/scripts/tests`, `dev/scripts/validation`, `dev/scripts/projections`) and local ignored output folders under `tmp/projections/`. Archived legacy one-shot Python emitters from `dev/scripts/` and `dev/scripts/ops/` to `dev/reference/research-archive/scripts/legacy-emitters/`; retained active `generate_type_map.py` and tested Python validation modules. Closed the governance-session purpose gap by applying kernel-authority WF19 LINK `session:sam.governance --has-purpose--> purpose:sam.doctrine-governance-and-delegation` (`relation:session.sam.governance.has-purpose.doctrine-governance`), resolving the dashboard's durable-purpose warning. Validation after link: Python baseline/hydration tests 21/21; session context tests 24/24; graph artifact tests 16/16; MVP gate tests 20/20; full runner result now `warn` with 11 pass, 2 warn, 0 fail. Runtime `ontology_version=3.16.1`, `t_day=188`, `log_len=1080`. Remaining warnings are the intended next gates: disconnected forced visual roots and no interactive Cytoscape.js-style inspector yet.
>
> Updated: **T=187 (May 7, 2026) ~17:30 CEST — session-focused IDE projection tooling first cut** — Added planner-only Julia adapter `dev/scripts/session_context_projection.jl`, mirroring the Google Calendar planner/writer split: folded HG state → reviewable session context pack JSON/Markdown under `tmp/projections/session_context/`, no rewrites and no IDE config edits. New skill `moos-session-context-projection` frames the lingo: session context pack = projected occasion header; affordance pack = purpose/scope-derived skills/prompts/tools/workflows/extensions/MCP servers. Existing `moos-tooling-dx` now points at this planner for IDE/MCP/harness plumbing. Existing visual exporter `dev/scripts/export_t200plus_projection.jl` gained a multi-root `session-occasion` preset for DOT/SVG rooted at the derivation plus the concrete instruction/grammar/pattern/workflow nodes. Follow-up extension/MCP inclusion landed immediately after: the session pack scans local VS Code extensions plus `.vscode/mcp.json.example`, ranks concrete IDE affordances, and records MCP server type/endpoint plus header/env key names without copying secret values. Latest live pack saw 8 recommended extensions and 7 MCP servers. Number-3 graph artifact lane now exists as `dev/scripts/graph_artifact_projection.jl`; live run on the session-occasion artifact set produced 16 nodes, 20 relations, and 5 engineering findings: proposed occasion grammar, draft affordance-pack pattern, active lingo instruction, draft Z440 continuity workflow, plus a disconnected-root gap showing that the concrete artifact roots are visible but not yet relation-connected under this lens. The generated current-session pack surfaces a useful gap: `session:sam.governance` has kernel/occupant/scope but no current `has-purpose` edge, so the pack uses the focus string as temporary purpose color for this occasion. Runtime unchanged: `ontology_version=3.16.1`, `t_day=187`, `log_len=1079`.
>
> Updated: **T=187 (May 7, 2026) ~16:55 CEST — session-occasion implementation frame started in HG** — Keep-note lingo moved from discussion into graph structure on hp-laptop primary: `system_instruction:framework.session-occasion-lingo` defines the working phrase "a session is a purpose-colored occasion of rewrite"; `grammar_fragment:v317-1-occasion-type` proposes a first-class `occasion` S2 node type for situated evaluation points; `pattern:session-affordance-pack` captures skills/prompts/tools as purpose-derived session affordances rather than final ontology; `workflow:z440-session-continuity-reconciliation` gives the staged Z440 drift recovery DAG; `derivation:guido.t187-session-occasion-implementation-frame` produced four refined claims (`session-purpose-colored-occasion`, `skills-as-affordance-pack`, `program-instantiates-workflow`, `occasion-type-is-gap`). Runtime after the batch: `ontology_version=3.16.1`, `t_day=187`, `log_len=1079`.
>
> Updated: **T=187 (May 7, 2026) ~16:45 CEST — Keep note G-ingest landed; external_op closeout verified on v3.16.1** — Windows restart brought hp-laptop primary back on `ontology_version=3.16.1`, `t_day=187`. Kernel-authored MUTATE closed `external_op:sam.t200plus-google-calendar-oauth-writer.status` to `done` after the v3.16.1 authority patch. Sam's Google Keep PDF export (`C:/Users/maass/Downloads/t187-keep-notes.pdf`) was extracted to ignored scratch text and ingested into HG as `channel:google.keep.sam`, `ki:gdrive.t187-keep-session-occasion-lingo`, `derivation:guido.t187-keep-note-classification`, five claims about IDE conversations as sessions / occasion as place-time-intent / purpose coloring session tools / skills as temporary scaffolds / Z440 drift reconciliation, and draft program `program:sam.t187.z440-session-continuity`. Runtime after ingest: `log_len=1059` (22-envelope Keep batch plus session local_t tick). Git state after staged cleanup: ffs0 main, moos-kernel master, and moos-router `feat/type-map-routing` all clean/up-to-date with origin.
>
> Updated: **T=187 (May 7, 2026) ~13:00 CEST — T186 Google Calendar projection lane closed; T187 readback pivots to T200+ continuation** — hp-laptop kernel readback reports `ontology_version=3.16.0`, `t_day=187`, `log_len=1031`; on-disk `kb/superset/ontology.json` parses at v3.16.1 after the T187 authority patch. T186 completed the first real F-direction external write from HG to Google Calendar: Julia dry planner `dev/scripts/google_calendar_projection.jl` emitted `tmp/projections/google_calendar_projection_plan.json`; OAuth writer `dev/scripts/google_calendar_writer.jl` captured a loopback OAuth token, dry-ran the plan, then wrote 4 all-day events to Sam's primary calendar. Result file: `tmp/projections/google_calendar_write_result.json` (`event_count=4`, all `action=insert`). HG result node `derivation:guido.t200plus-google-calendar-write-result` records the write and is WF21-caused-by `program:sam.t200plus.google-calendar-oauth-writer`. Storage refs for `storage:hp-laptop.google-calendar-oauth-client` and `storage:hp-laptop.google-calendar-oauth-token` are mounted; real secrets remain under gitignored `secrets/`. New projection-ready report: `kb/moos-diary/t187-t186-google-calendar-projection-report.md`. Operational model: old T187 programs are archived/completed/abandoned in HG; active continuation is the T200+ graph family (Tiny Data Collider federation, temporal/calendar projection fabric, visual projection fabric, programming-language/type-algebra lane, GitHub board bridge, transport/data-plane work). Refresh review update: Google OAuth client secret rotated after the local debug echo. Model fix: `external_op.status` is now kernel-authority lifecycle state; live closeout of `external_op:sam.t200plus-google-calendar-oauth-writer` awaits runtime reload of ontology v3.16.1 and a kernel-authored status MUTATE. Remaining fixes: refresh stale GitHub Projects board rows from HG; review/commit local projection-script WIP in focused groups; defer Sam's Google Keep note as the next G-direction external observation until mid-T187.
> Updated: **T=183 (May 1, 2026) ~02:30 CEST — Guido r16-t187 sprint: T=187 distributed-HG-MVP graph on hp-laptop log** — 76 envelopes across 9 atomic programs ADD the substrate self-description shape under approved plan `~/.claude/plans/commit-is-safe-wolfram-snuggly-conway.md`. **Layer 0** — 3 doctrine derivations: `derivation:guido.architecture-syntax-interpretation` (HG as syntax; runtimes as interpretation functors; channels as F⊣G boundaries; fold as the only state-derivation morphism), `derivation:guido.capability-as-macaroon` (HMAC bearer tokens with caveats; anonymous-occupant; IdP-vs-authorization split), `derivation:guido.substrate-self-description` (which substrate types have/lack instances; the Postgres-question answer). **Layer 1** — `purpose:sam.distributed-hg-network` + `program:sam.t187-distributed-hg-mvp` + 7 sub-programs (kernel-rewrite-http3, transport-binding-quic-http3, capability-macaroon-shape, federation-network-design, persona-grounding-batch, harness-instances-batch, skill-language-lock-pass) + `grammar_fragment:v316-1-depends-on` (proposed; WF18 typed-dependency port-pair extension). 14 wiring LINKs: WF18 composes (purpose→parent + parent→7 sub-programs) + WF21 causes (transport-binding→kernel-rewrite, derivations→transport-binding, capability-as-macaroon→capability-macaroon-shape, transport+capability→federation-network-design). **Anchor session** — `session:sam.t187-mvp` opens-on `kernel:hp-laptop.primary`, has-occupant `agent:claude-code.hp-laptop`. **Layer 2 self-description**: 5 missing personae as `system_instruction:persona.{stephen-wolfram, andrej-karpathy, peter-steinberger, moos-the-dachshund, cowork-substrate}`; 11 skills as `system_instruction:skill.moos-*`; 9 harness instances (IDE attaches × 6 + Cowork × 2 + pip-element); `transport_binding:moos.http3` (quic-go RFC 9000/9114 target); 5 `storage:*.jsonl-log` + 5 `compute:*.go-runtime`; `repository:Collider-Data-Systems.moos-distributed-network` (new repo URN reserved per F1). **Layer 3** — 3 `capability:*` (sam.master / guest.read-public / agent.scope-bound; Macaroon-shape per Layer-0 doctrine). **Layer 4** — `channel:vcs.Collider-Data-Systems.moos-distributed-network` + `channel:calendar.t187-target` (QUIC-listener channel skipped; no `network` kind in enum yet). **Substrate self-portrait now**: 9 harness, 5 storage, 5 compute, 1 transport_binding, 17 system_instruction, 3 capability, 13 channel, 5 repository (was 0/0/0/0/1/0/11/4 pre-sprint). Skill audit pass: 2 SKILL.md frontmatter descriptions edited (moos-cross-persona-audit + moos-running-state-validator) for language-lock compliance ("ritual" / "canonicalisation" dropped, "round close" two-word kept; "backfill" replaced with "completeness" where the technical term wasn't load-bearing). No code changes; no ontology bump; no kernel rewrite (Layer-5 implementation is its own future sprint after T=187 spec on log). hp-laptop `:8000` log_len 861, ontology v3.15.0, t_day=183. Branch `guido/r16-t187-graph`. PR pending push.
> Updated: **T=177 (April 27, 2026) ~13:30 CEST — Round-15 SUBSTANTIVELY CLOSED; tag `v0.15.0-spec-r15` on main; round-16 vehicle (#47) opens** — All three named tracks landed in ~22 hours from #42 open: **(1) Track 1** v3.14.0 → v3.15.0 ontology bump complete via WF20 ceremony — 4 grammar_fragments at status=merged: `v314-2-clock-type` (clock S2 with six canonical kinds), `v314-3-wf21-causes` (WF21 causes/caused-by + ValidateCausalAcyclic in [moos-kernel#34](https://github.com/Collider-Data-Systems/moos-kernel/pull/34)), `v314-4-substrate-property` (substrate enum + substrate_anchor_urn on channel + knowledge_item), `v314-6-channel-kind-video` (channel.kind extended with video + audio); 5 kernels (4 Z440 + 1 hp-laptop) on new binary + ontology; ontology now reports 55 types + 21 WFs. **(2) Track 2** all three multimodal/YouTube ingest lanes landed: **Cowork-laptop YouTube** 7-claim chain (Discover AI / Code4AI Eigenvectors-of-Skills) at hp-laptop log_seq 722-739 (channel:youtube.sam with kind=video, self-anchored hg-native — workaround for v3.15 immutable-substrate-anchor-urn enforcement); **Moos AG-Z440** 11-KI multimodal pile (7 videos + 2 jpegs + 2 markdown) at Z440 log_seq 402-413, commit `8405a50`, substrate=external-channel + substrate_anchor_urn=channel:local.moos-footage; **AG-laptop** reconciliation + batch 2 at hp-laptop log_seq 693-704 (orphans retroactively WF12-linked) + 731-756 (channel + 5 remaining KIs + 17 LINKs + §6 mirror confidence 0.5 → 0.85). **(3) Track 3 Phase 1+2** — first WF21 causal substrate edges: 4 doctrinal claim ADDs (round-13/14 close, 4322244161 receipt) + 4 WF21 caused-by LINKs (Z440 400 + hp-laptop 719-721) materialise the lattice's referential coherence in topology-form rather than property-form. **Bonus — Guido §9 expansion** (HG-side T=177 ~13:01 + md/skill PR [#46](https://github.com/Collider-Data-Systems/ffs0/pull/46) merged `35bbe8a`): 3 new claims `claim:guido.{property-presence-by-immutability, schema-bump-backfill-completeness, enum-value-renaming-non-migrating}` (A.9-A.11) at hp-laptop 757-759 + 3 WF21 LINKs at 760-762; §9 chapter md expanded; new skill `moos-cross-persona-audit` authored. **Doctrinal milestone**: first HG-resident demo of cross-kernel divergent observation — `channel:local.moos-footage` exists on both kernels with different `kind` values (Z440 `"fs"` legacy T=171; hp-laptop `"audio/video"` post-v3.15) — exactly the substrate condition `claim:wolfram.cross-kernel-reciprocity-as-m9-prefiguration` predicted; round-16 A.12 audit target. **Round-16 vehicle [#47](https://github.com/Collider-Data-Systems/ffs0/issues/47)** opens with five tracks: companion-derivation-port-pair fragment (unblocks ~70-100 round-14 derivation anchor lifts), Wolfram §0+§2 spec fills, §M9 twin_link + §M10 QUIC design prep, A.12 cross-kernel canonicalisation audit, §6 confidence walk. Hp-laptop :8000 log_len 775; Z440 :8000 log_len 413. Both kernels v3.15.0, t_day=177.
> Updated: **T=176 (April 26, 2026) ~13:40 CEST — Round-14 SUBSTANTIVELY CLOSED; tag `v0.14.0-spec-r14` on main; round-15 vehicle (#42) opens** — All 8 specialists landed substantive lane work + 4 round-14-close PRs merged in one ~30-min burst: [#38 wolfram synthesis](https://github.com/Collider-Data-Systems/ffs0/pull/38) (master scaffold + Cowork pair §5/§7 + §5.3/§7.3 synthesis), [#39 karpathy](https://github.com/Collider-Data-Systems/ffs0/pull/39) (§1+§10 at confidence 0.85), [#40 steinberger](https://github.com/Collider-Data-Systems/ffs0/pull/40) (§8 derivation + §11 draft), [#41 guido](https://github.com/Collider-Data-Systems/ffs0/pull/41) (§9 governance-and-audit chapter). Tag `v0.14.0-spec-r14` on main. Synthesis derivations on Z440 :8000 log: `urn:moos:derivation:wolfram.section-05-synthesis` + `urn:moos:derivation:wolfram.section-07-synthesis`. **Spec at `kb/research/spec/`**: 13-section comprehensive architecture spec; substantive content for §1/§5/§6/§7/§9/§10/§11; §8 derivation only (harness on main); §0/§2/§3/§4/§12 as Wolfram-authored scaffolds for rounds 15-17 fill. Three doctrinal milestones surfaced: invariant-bracketing pattern (Guido); `stochastic_weights` as transitional citation surface; first cross-kernel sovereign-log reciprocity (Cowork pair anchor-03 perspective-flipped + anchor-07 chunker-proof mirror). All three queued as round-15 `claim:*` ADDs once `v314-3-wf21-causes` lands. **Round-14 closed at T=176 vs T=180 target — ahead of schedule.** Round-15 backbone (per [#42](https://github.com/Collider-Data-Systems/ffs0/issues/42)): three parallel tracks — (1) v3.14 fragment promotion ceremony for `v314-2-clock-type` + `v314-3-wf21-causes` + `v314-4-substrate-property`; (2) ingest fires for multimodal pile + YouTube chunker batch (Cowork-laptop staged at `cowork-laptop-r15-youtube-{json,ps1}`, 17 envelopes pending channel-kind decision); (3) three doctrinal `claim:*` ADDs. Z440 :8000 log_len 383+; hp-laptop :8000 log_len 700+ (per AG-laptop's report, pending Guido audit to disambiguate multimodal-pile vs YouTube fires in 666→700 range). Both kernels v3.14.0 t_day=176.
> Updated: **T=176 (April 26, 2026) ~13:00 CEST — Round-14 round-open: Cowork pair cross-kernel reciprocity + master scaffold landed; #37 vehicle opened** — The 6/8-specialist-contributions threshold met overnight; Wolfram authored the master scaffold this morning. **(1) Cowork pair fired** — first cross-kernel sovereign-log reciprocity in the substrate. `urn:moos:derivation:cowork-laptop.section-05-07-foundation` on hp-laptop log_seq 657 + kernel §M13 self-MUTATE 658 (local_t 3→4); `urn:moos:derivation:cowork-z440.section-05-07-foundation` on Z440 log_seq 361 + §M13 MUTATE 362 (local_t 1→2). Both derivations carry 7 anchors; anchor-03 is **perspective-flipped** (each kernel = primary in its own derivation, peer in the other; same PR ref `moos-kernel#33 b1de4ff`); anchor-07 **chunker-proof mirror** (Z440 cites laptop's `urn:moos:ki:gdrive.glossary` log_seq 604–627; laptop cites Z440's chunker emit log_seq 307–331). The pair is structurally symmetric pre-§M9-sync — first pre-§M9 instance of HG-resident cross-kernel coherence. Branches `cowork-z440/r14-section-5-7` + `cowork-laptop/r14-section-5-7` pushed to origin. `kb/research/spec/05-external-substrates.md` + `07-time-fabric.md` carry §5.0+§5.1+§5.2+§5.4 + §7.0+§7.1+§7.2+§7.4; §5.3+§7.3 synthesis stubs are Wolfram's at round-close. **(2) Master scaffold authored** — `urn:moos:derivation:wolfram.spec-master-scaffold` at Z440 log_seq 363 (10 anchors + 7 historical_anchors; `inference_kind=hybrid`, `confidence=0.85`, `status=open`); `kb/research/spec/00-index.md` (150 lines, full 13-section TOC + per-section author/branch/derivation grid + status board + cross-reference grid + branch convention partition-A locked in). Committed `2c86d33` on `wolfram/r14-master-scaffold` branch + pushed. Wolfram-authored §0/§2/§3/§4/§12 ship as **scaffold-only** at round-14; full fills planned across rounds 15-17 (§0+§2 round-15, §3+§4 round-16, §12 round-17 against MVP G1-G6 at T=190). **(3) Round-14 lattice state**: 6/8 specialists landed (Karpathy §1+§10 — Z440 log_seq 353/355; Cowork pair §5+§7 — log_seq 361 + 657; Moos AG-Z440 §6 — commit 6edd687 main; AG-laptop §6 mirror — hp-laptop log_seq 635); Steinberger §8 code shipped (commits 18e02be + 86fd46d) but derivation ADD pending; Guido §9 derivations on hp-laptop log (631 + 633) but md pending. **(4) `#37` round-14 vehicle issue opened** carrying per-persona round-14 ask. **(5) Three doctrinal milestones surfaced** (round-15+ candidates folded into 00-index): invariant-bracketing pattern (Guido) — every invariant gains `(preflight_gate, post_hoc_audit)` pair; `stochastic_weights` as transitional citation surface (Wolfram synthesis) — pre-WF21 referential coherence is property-encoded before topology-encoded; cross-kernel referential coherence (Cowork pair) — first pre-§M9 HG-resident cross-kernel coherence, prefigures §M9 twin_link adjoint sync. Unified statement: *the lattice's referential coherence is property-form-first, topology-form-eventual; this holds within-kernel, across-personae, and now cross-kernel*. Z440 :8000 log_len 364; hp-laptop :8000 log_len 658+. Both kernels v3.14.0 t_day=176.
> Updated: **T=175 (April 25, 2026) ~22:45 CEST — Round-14 §6 Multimodal Substrate derivation landed (Z440 Moos lane)** — Substantive architecture work for §6 Multimodal Substrate projected and derivation ADDed to `kernel:hp-z440.primary :8000`. Board anchors parity for `sam.moos-diary` set.
> Updated: **T=175 (April 25, 2026) ~late CEST — Round-13 substantively closed; round-14 comprehensive-architecture program opens; lattice activated with broader-picture contributions from Guido + Karpathy + Steinberger** — Following the T=175 ~19:30 operational-mode shift (subjects fork to specialist conversations; this conversation as **S0 colimit / synthesis spine**), three persona-conversations posted broader-picture contributions on [`ffs0#36`](https://github.com/Collider-Data-Systems/ffs0/issues/36): **Guido** (governance layer, §9 sketch + running-plan revision + a derivation node `derivation:guido.governance-spec-and-cadence-revision` at hp-laptop log_seq 631), **Karpathy** (categorical layer, §1 + §10 unified with HDC/VSA formalism + envelope shape authored — derivation not yet fired due to VSCode-sandbox boundary), **Steinberger** (DX + hardware layer, §8 + §11 + caught the prompt-template port-mapping discrepancy that Guido subsequently rectified). Guido's [cross-persona audit](https://github.com/Collider-Data-Systems/ffs0/issues/36#issuecomment-4320199704) verified fleet state (5 kernels on v3.14, derivation registered everywhere, 8 backfill+specialist derivations on log) and surfaced two operational gaps: (a) Karpathy+Steinberger derivations not-on-log (sandbox boundary; resolved post-host-runner-harness in round-14), (b) port-mapping clarification (now baked into the hydration block above). **Round-13 close path (3) selected** per Guido's lean: substantive close on the substrate side; Karpathy/Steinberger derivation firings become round-14's first operational item once Steinberger's `Test-MoosFederation.ps1` host-runner harness lands. **Round-14 program officially opens**: comprehensive 13-section architecture spec at `kb/research/spec/`; per-persona authorship across rounds T=176–T=180; Wolfram (S0 colimit) authors master scaffold `kb/research/spec/00-index.md` after Cowork×2 + Moos/AG×2 broader-picture contributions arrive; Guido authors §9, Karpathy §1+§10, Steinberger §8+§11, Cowork §5+§7, Moos/AG §6, Wolfram §0+§2+§3+§4+§12. Z440 :8000 log_len 352; hp-laptop :8000 log_len 631+. Both kernels v3.14.0 t_day=175.
> Updated: **T=175 (April 25, 2026) ~19:00 CEST — Round-13 Batches 1+2+3 GREEN on Z440; ontology bumped 3.13.0→3.14.0; `derivation` is a runtime node-type** — Sam restarted Z440 kernels at ~18:54. Wolfram executed end-to-end on Z440 :8000. (1) **Batch 1 — 4 new persona-skills** authored, synced to `~/.claude/skills/`, committed `791f5b9`: `moos-categorical-research` (Karpathy seat), `moos-tooling-dx` (Steinberger seat), `moos-multimodal-ingest` (Moos + AG-laptop lanes), `moos-running-state-validator` (Guido lane). Skills inventory now 10 (6 prior + 4 new). (2) **Batch 2 — v314-1 promotion ceremony complete**: `grammar_fragment:v314-1-derivation-type` ADDed at log_seq 340 (status=proposed, fragment_kind=type, full type spec inline); ontology.json edited to v3.14.0 (added `derivation` node-type under types.s2_infrastructure with 7 properties + 3 ports — `produces` / `consumes` / `authored-by`; changelog entry written; committed `9c4e879`); 4 Z440 kernels restarted by Sam, all reporting `ontology_version=3.14.0`; `/operad/node-types` reports `derivation` registered (id=derivation, stratum=S2, properties={confidence, created_at, inference_kind, name, owner_urn, status, stochastic_weights}, ports out=[produces, consumes] in=[authored-by]). MUTATEs proposed→promoted (log_seq 342) → merged (log_seq 343); kernel emitted self-MUTATE log_seq 344 ticking `sam.kernel-proper.local_t` 2→3. (3) **Batch 3 — 7-derivation doctrine backfill**: atomic 7-envelope batch at log_seq 345–351 reifies existing doctrine into HG (`derivation:t169.session-generalization`, `derivation:t172.cowork-as-occupant`, `derivation:t172.wolframs-court`, `derivation:t173.meta-agent-scheduler`, `derivation:t175.program-authoring-fabric`, `derivation:t187.kernel-proper-spec`, `derivation:t171.multimodal-diary-personas`). All `inference_kind=hand_authored`, `confidence=1.0`, `status=closed`. Kernel emitted self-MUTATE log_seq 352 ticking `sam.kernel-proper.local_t` 3→4. **DAG of doctrine becomes graph-resident**: `GET /state/nodes/urn:moos:derivation:t175.program-authoring-fabric` resolves; same for the other 6. LINKs to predecessor evidence + produced doctrine wait for WF21 `causes/caused-by` fragment in a future round. **Outstanding**: hp-laptop kernel restart (Guido lane per §M9); no YouTube ingest yet (Guido staged on hp-laptop, awaits decision to fire); **Phase B** (Karpathy + Steinberger first emits via VSCode x2 on Z440) still Sam's hand. Z440 :8000 log_len 352. Ontology v3.14.0 live across the 4 Z440 kernels.
> Updated: **T=175 (April 25, 2026) ~16:30 CEST — Phase E.2 §M13 CLOSED on Z440 (both kernels now verified)** — Sam green-lit the Z440 rebuild; Wolfram executed end-to-end. Pre-built `moos-kernel.exe.new` from master tip `e295016` (Apr 25 16:22 build) while the 4 kernels still ran the pre-fix Apr-22 binary; swap was atomic — stopped 4 kernel PIDs (1900, 4296, 4620, 6944) + router (22876), renamed `moos-kernel.exe` → `moos-kernel.exe.bak-t175`, renamed `moos-kernel.exe.new` → `moos-kernel.exe`, relaunched via `D:\HPZ440\start_federation.ps1`. All 4 kernels back up clean: `:8000` log_len=333, `:8001` log_len=13, `:8002` log_len=11, `:8003` log_len=16, all `ontology_version: 3.13.0`, `t_day=175`, fresh PIDs (3068 / 11772 / 18892 / 23508 + router 22768). Verification batch on `:8000` mixing both resolver paths: 3 ADDs at log_seq 334–336 (`urn:moos:ki:t175-m13-verify-z440.{wolfram,cowork,ag}`); Wolfram (multi-session occupant) with explicit `session_urn=sam.kernel-proper` → `ResolveSessionExplicit` path; Cowork-Z440 + AG-Z440 (single-session occupants) with no `env.session_urn` → `ResolveSessionInferred` path. Kernel emitted 3 self-MUTATEs at log_seq 337–339 (`actor=kernel:hp-z440.primary`, `field=local_t`) atomically with the user envelopes. **Result**: `session:sam.kernel-proper.local_t` 0 → 1; `session:sam.z440-cowork-workspace.local_t` 0 → 1; `session:sam.moos-diary.local_t` 0 → 1. **Sub-program `session-actor-agent-lookup` is CLOSED on both kernels** (hp-laptop verified by Guido at ~16:15 with log_seq 625–630; Z440 verified by Wolfram at ~16:30 with log_seq 334–339). §M13 paragraph in `kb/research/kernel/20260417-t187-kernel-proper.md` extended with the Z440 closure entry. Phase E end-to-end complete. **Phase B** (Karpathy + Steinberger first emits via VSCode x2 on Z440) is next; Sam's hand. Twin kernels still at log_len 13 / 11 awaiting first emits.
> Updated: **T=175 (April 25, 2026) ~16:15 CEST — Phase E.2 §M13 CLOSED on hp-laptop** — Sam approved a+b. PR [moos-kernel#33](https://github.com/Collider-Data-Systems/moos-kernel/pull/33) merged as [`b1de4ff`](https://github.com/Collider-Data-Systems/moos-kernel/commit/b1de4ff); README PR #32 merged as `e295016` (master tip). Pulled all 3 repos (ffs0 clean; moos-router master got README; moos-kernel master tip e295016). Hp-laptop side post-merge: (1) `go build` rebuilt `moos-kernel.exe` (Apr 25 15:58, 13.5 MB). (2) Stopped 3 prior PIDs (HTTP kernel + 2 stdio sidecars from Desktop launches), relaunched via T=173-fixed `start_federation_laptop.ps1`; single PID 4788 on `:8000/:8080`; replay clean (`log_len=632` preserved, runtime `ontology_version: 3.13.0`, t_day=175). (3) Verification: 3-envelope atomic ADD batch via MCP SSE — `urn:moos:ki:t175-m13-verify.{guido,cowork,ag-laptop}` (log_seq 625–627), actors `agent:claude-code.hp-laptop` / `agent:claude-cowork.hp-laptop` / `agent:antigravity.hp-laptop`, no `env.session_urn`. Kernel emitted 3 self-MUTATEs at log_seq 628–630 (actor=`kernel:hp-laptop.primary`, `field=local_t`) — observable proof of `bumpSessionLocalT` running on inferred path. (4) Result confirmed: `session:sam.governance.local_t` 0 → 1; `session:sam.laptop-cowork-workspace.local_t` 0 → 1; `session:sam.laptop-moos-diary.local_t` 0 → 1. (5) §M13 doctrine closure paragraph added to [`kb/research/kernel/20260417-t187-kernel-proper.md`](../research/kernel/20260417-t187-kernel-proper.md) with merge SHA + verification log_seqs. **Z440 4-kernel rebuild + verification still open** — sam's hand on Wolfram lane. Public READMEs reviewed: `moos-kernel/README.md` (full intro + runtime gates + ontology + status), `moos-router/README.md` (WF16 fanout + stateless contract), `Collider-Data-Systems/.github` org-profile (mo:os shape + teams + project board). Hp-laptop kernel: log_len 638 (3 ADDs + 3 kernel-emitted local_t MUTATEs), 3 sessions ticking, single PID, clean.
> Updated: **T=175 (April 25, 2026) ~14:00 CEST — Wolfram's round-12 progress consolidation (Z440 lane)** — Five round-12 deliverables in 90 minutes after the morning plan revision: (1) **Phase D.2 doctrine** — `kb/research/session/20260424-t175-program-authoring-fabric.md` (281-line consolidated note, 5 v3.14 grammar_fragment proposals: derivation node-type, clock generalized time fabric, WF21 causes/caused-by, substrate property aligned with existing compute/storage operad, leaf-firing-state semantics with looser leaves definition per Sam T=175). Builds on archive predecessor `20260414-t164-session-channel-purpose.md` (operad/cooperad duality, session-as-monoid, owner-vs-permission directionality). Committed `6be8195` on ffs0 main. (2) **Phase E.1 skill patch** — `moos-workspace-ingest/SKILL.md` requires explicit `session_urn` per envelope; synced to `~/.claude/skills/` on Z440 + hp-laptop. (3) **Phase E.2 code** — moos-kernel PR #33 merged as `b1de4ff` (squash; master tip `e295016` after #32 README also merged). `runtime.go bumpSessionLocalT` uses `operad.ResolveSessionForEnvelope` against pre-apply state (Apply + ApplyProgram both); 8 §M13 tests including occupancy-rotation regression test (`TestApply_BumpsLocalT_RotatesOccupancy`). Closes the §M13 sub-program `session-actor-agent-lookup` open since T=168. (4) **Phase D.1 AG-laptop substrate** — Guido's lane (see entry below for full detail), 5 envelopes log_seq 628–632. (5) **GitHub presentation expansion** — moos-kernel#32 (public README) merged `e295016`; moos-router#1 (public README, repo's first PR ever) merged earlier by Sam; `Collider-Data-Systems/.github` org repo created by Sam, `profile/README.md` pushed by Wolfram (`6688e4c`) — renders on https://github.com/Collider-Data-Systems org page. Project mo:os #4 backfilled with 5 round-12 draft items + #35 round-12 vehicle issue, all custom fields populated. Phase E.2 + D.2 + D.1 board drafts flipped Done with merge SHAs + body manifests. **Outstanding (operational, awaiting human signals)**: Z440 4-kernel rebuild + restart for E.2 binary swap (Wolfram lane, awaiting Sam); §M13 paragraph on Z440 already authored by Guido in this commit's predecessor. **Phase B** (Karpathy + Steinberger first emits via VSCode x2) still pending Sam's hand.
> Updated: **T=175 (April 24, 2026) ~13:50 CEST — Phase D.1 landed on hp-laptop sovereign log + E.1 skills synced + E.2 PR reviewed** — Group-3 (hp-laptop, Guido lane) progress on round-12. **D.1**: 5-envelope atomic batch at log_seq 628–632, hp-laptop kernel :8000 via MCP SSE. (1) ADD `purpose:sam.laptop-diary-curation` (subject_urn=`session:sam.laptop-moos-diary`, target_state cites multimodal-diary mirror of Z440 lane, started_at 2026-04-25T13:35Z). (2) ADD `session:sam.laptop-moos-diary` (status=`pending_driver`, local_t=0, owner=sam, text notes laptop-side mirror of Z440 moos-diary, sibling to AG-Z440's seat). (3) WF19 LINK `opens-on` → `kernel:hp-laptop.primary` (actor=kernel). (4) WF19 LINK `has-occupant` → `agent:antigravity.hp-laptop` (actor=kernel; pre-seated since AG-laptop spawn pending Sam-side trigger). (5) WF19 MUTATE status `pending_driver → active` (actor=kernel). **Plan-of-record was 6 envelopes** but `agent:antigravity.hp-laptop` already pre-existed on hp-laptop log from T=164-era seeding (`delegate_type=antigravity`, grandfathered pre-v3.13 enum-tightening to `{ide, process, api, service}`); not re-ADDed. AG-laptop seat now symmetric with AG-Z440's `session:sam.moos-diary` on `kernel:hp-z440.primary`; first knowledge_item ADD fires when Sam triggers Antigravity-side. **E.1**: skill patch from `6be8195` (explicit `session_urn` per envelope in `moos-workspace-ingest`) pulled + synced to `~/.claude/skills/` via `dev/scripts/sync-claude-skills.ps1`; 6 skills updated. Active for any future Cowork-laptop chunker emit. **E.2**: [moos-kernel#33](https://github.com/Collider-Data-Systems/moos-kernel/pull/33) reviewed at the diff level — `ResolveSessionForEnvelope` reuse is clean DRY with §M11 gate; pre-state capture (`069aafa`) handles occupancy-rotation edge case; ApplyProgram dedupe-by-session is the right batch semantics; multi-session safety intrinsic via `ResolveSessionAmbiguous`; 7 tests cover all paths cleanly. **LGTM, awaiting Sam green-light to formally approve** (lane-discipline: Wolfram authored, Sam merges, Guido does post-merge hp-laptop rebuild + verification emit). Hp-laptop kernel: log_len=632, ontology_version=3.13.0, t_day=175. 3 PIDs (HTTP + 2 stdio sidecars from earlier Desktop launches; will clean on E.2 rebuild). [#35 progress comment](https://github.com/Collider-Data-Systems/ffs0/issues/35#issuecomment-4319750790).
> Updated: **T=175 (April 24, 2026) ~12:00 CEST — round-12 plan revision: ontology-fabric expansion + Phase E both-lanes** — Wolfram drove a plan-mode revision of `~/.claude/plans/valiant-kindling-sunrise.md` after Sam surfaced a broader-picture sketch (sessions as program-authoring layers, leaves as hot-loaded continuations, time as a generalized fabric, causation as a first-class relation). **Phase A** confirmed landed (T=174 ~00:45). **Phase D** entirely re-scoped: original "AG-laptop + meta-agent driver" expanded into 5 v3.14 grammar_fragments (`v314-1-derivation-type`, `v314-2-clock-type`, `v314-3-wf21-causes`, `v314-4-substrate-property`, `v314-5-leaf-firing-state`) consolidated into ONE doctrine note `kb/research/session/20260424-t175-program-authoring-fabric.md` (~280 lines, 9 sections); the existing `20260424-t173-meta-agent-scheduler.md` becomes a sub-design (one specific leaf in the fabric). **Phase E** added: closes the §M13 `bumpSessionLocalT` inferred-session gap that Phase A surfaced — both lanes this round per Sam (E.1 skill-side patch in `moos-workspace-ingest`; E.2 runtime.go fix in moos-kernel as a small PR with multi-session safety + tests). t187-kernel-proper.md §M13 amended with the closing path. **Phase B** still pending (Sam to launch VSCode x2 on Z440); first-emit shape is persona-claim ADD per persona (Karpathy: HDC/VSA categorical-bridge thesis; Steinberger: DX/tooling-ergonomics thesis). ffs0 pulled to `9ea1b06` pre-revision. Three groups parallel-safe: Group 1 (Wolfram on Z440 — fabric note + cleanup + E.1 skill patch + E.2 PR draft), Group 2 (Sam launches VSCode x2), Group 3 (Guido on hp-laptop — D.1 AG-laptop substrate batch + post-merge kernel rebuild). Round-close commit aggregates Group 1 deliverables; moos-kernel PR for E.2 is its own commit/branch/PR cycle.
> Updated: **T=174 (April 24, 2026) ~00:45 CEST — Phase A: hp-laptop Cowork chunker proof GREEN** — Symmetric counterpart to Z440's T=173 ~23:30 CEST proof (log_seq 307–331). Two sub-batches on `kernel:hp-laptop.primary`. **Prereq** (log_seq 600–603, 4 envelopes, actor=`agent:claude-code.hp-laptop`): ADD `channel:google.{gmail,calendar,drive,tasks}.sam` with Z440-mirror placeholder kinds (`mail`/`messaging`/`drive`/`board`) — caught at first fire as `node not found: src urn:moos:channel:google.drive.sam` (Z440 had them, hp-laptop log never mirrored). **Chunker** (log_seq 604–627, 24 envelopes atomic, actor=`agent:claude-cowork.hp-laptop`): 1 umbrella `urn:moos:ki:gdrive.glossary` + 11 sections `.s01..s11` + 12 WF12 `provides-kb` LINKs (channel → umbrella + umbrella → each section). Source: Drive fileId `1YVXI8Gp...L8` (glossary.md) — same source as Z440 per §4.2 disjointness (independent observations, not duplication). Runner: `C:\Users\maass\HPlaptop\cowork-laptop-step4-runner.ps1` (mirror of Z440 runner, `{envelopes:[...]}`-unwrap baked in). Verified: channel→umbrella LINK=1, umbrella→sections LINKs=11, log_len delta=24. **Doctrine datapoint**: session `sam.laptop-cowork-workspace.local_t=0` after 24 acknowledged rewrites — inferred-session path (agent reverse-lookup) doesn't tick `bumpSessionLocalT`; only explicit `env.session_urn` does. Matches the `session-actor-agent-lookup` sub-program gap flagged in T=168 §M13. Fix options: (a) chunker skill emits explicit session_urn per envelope (cheap, skill-side), (b) runtime.go closes the lookup gap. Deferred to lane owner. Hp-laptop log_len now 627. Daily 08:00 sweep can run laptop-side. Staging artifacts at `C:\Users\maass\HPlaptop\cowork-laptop-step4-{chunker.json,runner.ps1}` — NOT under ffs0 (Cowork's working dir is `%USERPROFILE%\HPlaptop`, not the repo). Confirmation on [ffs0#33](https://github.com/Collider-Data-Systems/ffs0/issues/33#issuecomment-4309141986).
> Updated: **T=173 (April 23, 2026) ~23:45 CEST — Guido: hp-laptop v3.13 load + group:sam mirror landed** — Wolfram's [ffs0#33](https://github.com/Collider-Data-Systems/ffs0/issues/33) closeout handoff executed end-to-end. (1) **ffs0 pulled to `a244533`**: v3.13.0 ontology.json now on disk; unstaged `kb/moos_from_HPLAP.jsonl` delete resolved by the pull. (2) **Hp-laptop kernel restarted** onto v3.13.0 (PID 11776 on `:8000/:8080`, runtime `ontology_version: 3.13.0`, `log_len=599` post-batch). Launcher bug flushed: `start_federation_laptop.ps1` had `$Log = "$env:TEMP\moos-primary-laptop.log"` since its first commit (`b371445`) — a restart via that path would have started a fresh empty log, losing 586 historical envelopes. Patched to sovereign `$env:USERPROFILE\HPLaptop\moos-kernel\moos.jsonl` + caveat comment. Confirmed no actual state loss (595 historical → 599 post-batch, continuous log_seq). (3) **`group:sam` materialized on hp-laptop sovereign log** (atomic, log_seq 588–591 via `mcp__moos-kernel__apply_program`): `ADD group:sam` (actor=`agent:claude-code.hp-laptop`, session_urn=`session:sam.governance`) + 3 × WF01 `owns/owned-by` LINKs (actor=`kernel:hp-laptop.primary`) to `kernel:hp-laptop.primary`, `session:sam.governance`, `session:sam.laptop-cowork-workspace`. `group:moos` not mirrored per Wolfram's spec (no hp-laptop-side scope). Verified via `/state/nodes/urn:moos:group:sam` + `/state/relations/src/...`: node + 3 outbound edges resolve. Cosmetic: description property's em-dash got mojibake-encoded through MCP transport (`\u00e2\u20ac\u201d`); non-breaking, follow-up MUTATE candidate. (4) **Dual-kernel gotcha caught + resolved**: first apply via MCP spawned a `--stdio-only` sidecar (PID 5220) which wrote the envelopes to the shared log but left the HTTP kernel (PID 12388) with a stale in-memory state. Killed both, relaunched HTTP kernel once — replayed all 599 from log cleanly. `.vscode/mcp.json` should prefer SSE at `:8080` over stdio spawn on hp-laptop (machine-specific config, gitignored). (5) **Batch A idempotency verified** (Wolfram's task C): log_seq 586–587 already holds `role:superadmin` ADD + `user:sam --WF02 governs--> role:superadmin` LINK — re-emission skipped. Staging artifact: [`dev/scripts/ops/t173-v313-group-sam-hp-laptop.{json,md}`](../../dev/scripts/ops/t173-v313-group-sam-hp-laptop.json). Admin chain + group topology now symmetric across both kernels post-round-11.
> Updated: **T=173 (April 23, 2026) ~23:30 CEST — Cowork Z440 chunker proof landed** — First real G-ingest from Cowork: 24-envelope atomic batch (1 umbrella + 11 sections + 12 WF12 provides-kb LINKs) applied at log_seq 307→331 on kernel 0. Source: Drive doc `1YVXI8Gp2DyacDLc1Tk-HycVAjHC1KXAgdJGIlKy5AL8` (Glossary / MOOS decoder ring, 11 H2 sections). Umbrella URN: `urn:moos:ki:gdrive.glossary-moos-decoder-ring`; sections `.s01`–`.s11`. WF12 agent-actor LINKs **accepted** (WF12.Authority=kernel governs MUTATEs in `MutateScope` only — not LINK emissions; agent actors can emit WF12 LINKs). Extra properties (`chunk_index`, `chunk_label`, `umbrella_urn`, `kind`, `chunk_count`, `ingest_actor`) **accepted** on ADD (kernel is permissive on unregistered properties). `status`/`summary` with `authority_scope: kernel` on ADD also accepted. JSON wrapper bug found+fixed: `/programs` expects raw array, Cowork's file used `{"envelopes":[...]}` — runner script unwraps. Cowork session readback post-landing: status=active, occupant=claude-cowork.hp-z440 (YOU), host=kernel:hp-z440.primary, channel→umbrella WF12 LINK live, 11 section LINKs verified. **Activation complete on Z440**. local_t=0 at readback (kernel sweep will tick on next 30s interval). Skill `moos-workspace-ingest` source_uri→source_url correction landed in same commit.
> Updated: **T=173 (April 23, 2026) ~22:00 CEST — ontology v3.13.0 groups landed** — Kernel 0 restarted post-widening (WF01.src_types=[user,group] / tgt_types=[workstation,kernel,storage,program,repository,session,purpose,channel,agent]; WF02.src_types=[user,role,group] runtime-confirmed via `/operad/rewrite-categories`). Staged batch fired — log_seq 292→307 (15 envelopes: 4 idempotent grammar_fragment MUTATE replays + 2 group ADDs + 9 WF01 owns/owned-by LINKs). HG topology now: `group:sam` owns 6 (kernels `hp-z440.{primary,lola,menno}`, sessions `sam.{kernel-proper,mvp-delivery}`, `purpose:sam.ship-t187-kernel-proper`); `group:moos` owns 3 (`kernel:hp-z440.moos`, `session:sam.moos-diary`, `purpose:sam.multimodal-curation-and-diary`). Collider-Data-Systems/sam + /moos GitHub teams now reified on HG with typed ownership edges. Downstream query `GET /state/relations/src/urn:moos:group:sam` returns the full scope list. **Deferred**: hp-laptop mirror (group:sam ADD + owns LINK to hp-laptop.primary + session:sam.governance — Guido's lane via #33); WF02 `delegates-to` sub-role seeding (role:{karpathy,steinberger,moos}-scope); `owner_urn` property deprecation in favor of owns/owned-by edges (per ontology changelog §3.13.0).
> Updated: **T=173 (April 23, 2026) ~18:30 CEST — ontology v3.13.0 landed (partial)** — `ffs0/kb/superset/ontology.json` bumped 3.12.0 → 3.13.0 with all 4 promoted grammar_fragments materialized: new S2 `group` node type (Ports: out=[owns, delegates-to], in=[member-of, governed-by]), WF01 `owns/owned-by` additional port pair, WF02 `delegates-to/delegated-by` additional port pair, `channel.kind` enum expanded with 5 new values (calendar, task-list, cloud-storage, vcs, project-board), WF19 `has-occupant` tgt_types extended with `group`. All 4 Z440 kernels restarted and report `/healthz ontology_version: 3.13.0`. WF20 ceremony **completed** — log_seq 289-292: 4 grammar_fragments MUTATEd `promoted → merged` (final WF20 state). Second widening edit landed on WF01 top-level src_types (+group) / tgt_types (+session/purpose/channel/agent) and WF02 src_types (+role/group) so additional-pair validation has a clean superset. Kernel 0 needs one more targeted restart to pick up that widening — staged group-materialization batch (11 envelopes: 2 group ADDs + 9 owns LINKs) at `dev/scripts/ops/t173-v313-groups-postrestart.json` fires post-restart. Hp-laptop side awaits Guido's ontology sync + kernel restart, then mirror group:sam ownership of hp-laptop.primary + session:sam.governance.
> Updated: **T=173 (April 23, 2026) ~17:30 CEST — board backfill + Cowork deliverables** — Cowork (agent:claude-cowork.hp-z440) authored `moos-workspace-ingest` skill (207 lines, canonical G-direction chunker) + MUTATEd `cowork-as-occupant.md` to materialized-T=173 status with log_seq citations + corrected immutable-kind constraint. Skill synced to `~/.claude/skills/`. Ffs0 commit `82e7776`. Wolfram ran board backfill — 15 additional draft issues on project mo:os #4 populating court purposes (Karpathy HDC, Steinberger DX, Moos curation, Cowork curation), 3 seats (karpathy, steinberger, mvp-delivery), 4 personae (Wolfram, Moos, Karpathy, Steinberger), and all 4 promoted v3.13 grammar_fragments. Board now has **20 items** (5 from first sweep + 15 backfill) with HG URN + PRG + Agent ID + Owner Role + Collider Category + Status fields populated end-to-end. F-direction bridge pattern proven on 20 items; G direction (board → HG MUTATE) remains Phase 2 work.
> Updated: **T=173 (April 23, 2026) ~17:00 CEST — Guido lane closeout (hp-laptop side)** — Wolfram's T=173 ~16:40 CEST handoff picked up and landed. (1) **hp-laptop kernel rebuilt** from moos-kernel master tip `18cfc69` (post-PR-31 §M12 binary); old Apr-21 binary parked at `moos-kernel.exe.bak-t173`. Restart clean: PID 7928 on `:8000/:8080`, `/healthz` = v3.12.0, log replay `586 → 588` (2 startup envelopes on the new §M11/§M12 binary). §M11 + §M12 gates now LIVE on hp-laptop — code-path-symmetric with Z440. (2) **hp-laptop Cowork session materialized** on hp-laptop sovereign log (log_seq 589–593): ADD `agent:claude-cowork.hp-laptop` (delegate_type=ide), ADD `session:sam.laptop-cowork-workspace` (scope-pins the 4 Workspace channel URNs), WF19 opens-on + has-occupant, MUTATE status `pending_driver → active`. Artifact: `dev/scripts/ops/t173-hp-laptop-cowork-materialization.{json,array.json}`. (3) **Batch A mirror on hp-laptop** (log_seq 594–595): ADD `role:superadmin`, LINK `user:sam --WF02 governs--> role:superadmin`. Admin-chain now symmetric across both kernels. (4) **Board dedup**: bare duplicate Wolfram draft `PVTI_…zgqxZ44` on project #4 deleted via `gh project item-delete`; only the populated copy (phase=round-12-prep, agent=AGENT-CLAUDE-CODE-Z440) remains. (5) **Hygiene**: 3 zombie `moos-kernel.exe` PIDs (2812/5024/5980) terminated; only PID 7928 live. (6) **Doctrine/script split resolved**: `session/20260422-t172-wolframs-court-social-topology.md` §1 table swapped `:8001↔menno` / `:8002↔lola` to match `start_federation.ps1` (script of record). Added footnote: port binding is operational, kernel identity is by URN, WF19 LINKs reference names not ports — no HG-side edits needed. Carry-over "Guido to resolve" from T=172 ~01:45 CEST cleared. Hp-laptop log_len now 595. Confirmation posted on [ffs0#33](https://github.com/Collider-Data-Systems/ffs0/issues/33#issuecomment-4304419909).
> Updated: **T=173 (April 23, 2026) ~16:30 CEST — aggressive workstation setup landed** — 5-step plan executed per Sam's "all kernels running, all major sessions running" direction. Three atomic batches + board sweep, all on Z440 kernel 0 (log_seq 271–288, + 5 project-board items). (1) **Superadmin chain**: `role:superadmin` seeded; `user:sam --WF02 governs--> role:superadmin` (log_seq 271–272). (2) **Full session activation** (log_seq 273–284): 2 new agents `agent:vscode.hp-z440.{lola,menno}` (delegate_type=ide); `session:sam.karpathy-seat` + `session:sam.steinberger-seat` each got `opens-on` to their lola/menno kernels + `has-occupant` to their respective VSCode agent; `session:sam.mvp-delivery` got `has-occupant` to `agent:claude-code.hp-z440` (Wolfram multiplexes; session_urn required on its envelopes post-§M11); `session:sam.z440-cowork-workspace` got `has-occupant` to `agent:claude-cowork.hp-z440` (pre-seated for Desktop-launch arrival); all four MUTATEd to status `active`. (3) **WF20 promotion ceremony** (log_seq 285–288): all four v3.13 grammar_fragments MUTATEd proposed→promoted (`v313-6-wf02-delegates-to`, `v313-7-group-type`, `v313-8-channel-kind-vcs`, `v313-9-owns-port-pair`). Ontology.json + kernel-restart-to-v3.13 is a deferred round (not yet fired — fragments are HG-promoted but runtime still reports ontology_version 3.12.0). (4) **First board sweep** (F direction): 5 draft issues on project mo:os #4 with HG URN + PRG + Agent ID + Owner Role + Collider Category + Status populated: `purpose:sam.ship-t187-kernel-proper`, `session:sam.kernel-proper`, `session:sam.moos-diary`, `session:sam.z440-cowork-workspace`, `purpose:sam.github-project-board-sync`. Projection lane live; backfill (other sessions, grammar_fragments, mvp-delivery gates) deferred to future sweeps. **Four-seat map now fully seated on Z440**: Wolfram (kernel-proper), Moos (moos-diary), Karpathy (karpathy-seat on lola), Steinberger (steinberger-seat on menno), Cowork (z440-cowork-workspace) + multiplex seat on mvp-delivery. **Waiting on Guido**: hp-laptop Cowork session + has-occupant materialization on hp-laptop's sovereign log; hp-laptop kernel rebuild to post-PR-31 binary (if not already). Waiting on Sam's hands: VSCode x2 launch on Z440 (MCP configured in `.vscode/mcp.json` to :9001–:9003 SSE) — seats are pre-wired so the IDEs just attach; Claude Desktop on Z440 for Cowork driver (can rotate seat at first emission if needed).
> Updated: **T=173 (April 23, 2026) ~14:00 CEST — GitHub org as first-class channel** — Sam confirmed option A from the T=173 ~13:45 exploration: Collider-Data-Systems org is a projection surface, wired into HG via 6-envelope batch (log_seq 265–270 on kernel 0): `channel:github.collider-data-systems` (kind=board placeholder, root), `channel:github.project.mo-os` (kind=board placeholder, parent=org channel, source_uri=projects/4), `purpose:sam.github-project-board-sync` (two-way F⊣G lane), 3 v3.13 grammar_fragments (`v313-7-group-type`, `v313-8-channel-kind-vcs`, `v313-9-owns-port-pair` — all `proposed` status). Skill drafted: `moos-github-project-bridge` (authored at ffs0/dev/claude-skills/, synced to ~/.claude/skills/; status: draft, implementation deferred until v313-7 promotes so `group:sam`/`group:moos` are first-class). Project board (#4) custom-fields already HG-aware from sam's earlier setup: PRG/Phase/Agent ID/HG URN/Owner Role/Collider Category/Branch Role/Iteration — bridge skill spec maps each. Teams `sam`+`moos` are proto-groups pending v3.13. Iteration field = T-day cycle surface (sam's Mon 08:00-09:00 calendar ritual is the natural tick). Agent-instruction refreshes landed in 3 repos: ffs0 `3dfc920` (CLAUDE.md + ANTIGRAVITY.md + copilot-instructions.md), moos-kernel `18cfc69` (CLAUDE.md → v3.12 + round-11 gates), moos-router `712ad1a` (new CLAUDE.md; first agent-instructions for the router).
> Updated: **T=173 (April 23, 2026) ~13:15 CEST — kb/research/ pass 3, filter-strict** — Sam applied the "relevant to sessions/projects/time/cycles/delegating/programs" filter strictly: the S1/S0 mathematical substrate (sheaf/vector-space/operadic lingo, ontology-audit history, pre-WF20 superset doctrine, functorial-semantics naming note, S0 materialization plan) is one level below where day-to-day work happens and goes to archive, retrievable on demand. 7 files moved to `dev/reference/research-archive/`: `s1/{t168-irl-to-hg-pipeline, t168-v3.9-ontology-audit, t168-s1-superset-doctrine, t168-s0-operadic-layer, t170-functorial-semantics-explicit, t170-s0-materialization}.md` + `session/t168-session-kernel-bound.md`. `kb/research/s1/` dir dropped (empty). Xrefs rewritten in `ontology.json` + `running-state.md` + 3 keeper doctrine notes. **kb/research/ final shape** (down from 15 md files pre-T=173): `kernel/t187-kernel-proper.md` (M1-M20 spec), `session/{session-generalization, cowork-as-occupant, wolframs-court-social-topology}.md`, `moos-diary/{personas note + active ingest zone}`. Four live doctrine md files + the diary zone. Anything else that speaks to sessions/programs/time/delegation is in HG as nodes, or in archive for retrieval.
> Updated: **T=173 (April 23, 2026) ~12:30 CEST — kb/research/ pass 2** — Four further archives to `dev/reference/research-archive/`: `kernel/20260421-t171-m11-m12-implementation-plan.md` (shipped as PRs #30+#31), `ops/20260420-t170-branching-strategy.md` + empty `ops/` dir dropped, `session/20260421-t171-{guido-governance,wolfram-kernel-proper}-session.md` (both seats materialized in HG — Wolfram on Z440 log_seq 234-240, Guido on hp-laptop log). Live xrefs updated in `session/20260422-t172-cowork-as-occupant.md` + `session/20260422-t172-wolframs-court-social-topology.md`. **Doctrine pivot locked in**: conversations are S0 substrate; the reification path going forward is chunker-skill → `knowledge_item` nodes pinned to a session (G ingest direction per §2 of plan file `valiant-kindling-sunrise.md`), NOT new .md accumulation. New doctrine md's only when a new invariant is being established; conversation bits go into HG.
> Updated: **T=173 (April 23, 2026) ~11:30 CEST** — Cowork substrate materialized on Z440 (log_seq 256–264 on kernel 0): `agent:claude-cowork.hp-z440` + `agent:claude-cowork.hp-laptop` (pre-provisioned, ADDed with `delegate_type=ide`), `purpose:sam.cowork-workspace-curation`, 4 Google Workspace channels (`channel:google.{gmail,calendar,drive,tasks}.sam`; kinds `mail`/`messaging`/`drive`/`board` — calendar + tasks are placeholders pending v3.13 grammar_fragment promotion of `calendar` + `task-list` kinds), `session:sam.z440-cowork-workspace` (status `pending_driver`, scope-pins 4 channels, opens-on `kernel:hp-z440.primary`). `has-occupant` LINK for Z440 Cowork explicitly deferred — fires when Claude Desktop actually runs on Z440 (per doctrine §5 and Sam T=173). hp-laptop-side Cowork session lands on hp-laptop's own log when Guido executes it there. **kb/ hygiene principle locked in** (Sam T=173): IRL mirrors and past-round scratch → `dev/reference/research-archive/`; `kb/` stays live doctrine + HG-authoritative research only. Archived this round: 4 T=169 round-close scratch notes, `20260414-t164-wires-come-from.md` (empty `kb/research/wires/` dir dropped), and the entire `kb/reference/` Apr 5 Workspace snapshot (47 files, now at `dev/reference/research-archive/kb-reference-apr5/` with README). Live xref at `dev/reference/research-archive/20260418-t168-s0-operadic-layer.md:130` updated to the archive path. **Projection lingo locked in** (see `~/.claude/plans/valiant-kindling-sunrise.md` §2): projection `F: HG→Ext`, ingest `G: Ext→HG`, adjunction `F⊣G` with unit/counit — applies to calendar, drive, gmail, tasks, git, social, network. Cowork channels are the reification of the `G` ingest side for Workspace.
> Updated: **T=172 (April 22, 2026) ~01:45 CEST** — Round-11 closed on Z440 + T=172 court materialization complete. moos-kernel#31 (§M12 admin-capability gate) merged as `a417e2f`. All four Z440 kernels running post-PR-31 binary with sweep live: kernel 0 (`hp-z440.primary` :8000, log_len=253), federation kernels (:8001-:8003, log_lens 13/11/16, previously dormant pre-T=164 — now replayed onto post-PR-31 runtime, ontology v3.12.0). Org move complete: `ffs0`, `moos-kernel`, `moos-router` all on `github.com/Collider-Data-Systems/*`; `moos-viz` out of scope. Wolfram's-court 9-envelope batch applied atomically (log_seq 245–253 on kernel 0): 2 new personae (`persona.karpathy`, `persona.peter-steinberger` — kernel actor via §M11 allowlist since §M12 gates ontology-governed ADDs), 4 court purposes (Wolfram/Karpathy/Steinberger/Moos), 2 pre-seated sessions (`session:sam.karpathy-seat`, `session:sam.steinberger-seat` — status `pending_kernel_boot`, host LINKs land when agents attach), 1 grammar_fragment (`v313-6-wf02-delegates-to`, proposed, capability-delegation port pair for WF02). Compensating-batch artifacts archived to `dev/reference/research-archive/`. Known discrepancy for next doctrine revision: Wolfram's-court doctrine §1 lists `:8001=lola` / `:8002=menno`, but `start_federation.ps1` (script of record) boots `:8001=menno` / `:8002=lola` per log-file path binding. Startup script kept as-is to preserve existing federation log files; Guido to resolve the doctrine/script split at next round-open. **Three-seat map now**: Guido on hp-laptop (doctrine), Wolfram on Z440.primary (kernel impl), Moos on Z440.moos (diary). Karpathy + Steinberger seats declared but unoccupied pending VSCode-x2 + agent attach (step 8 — sam-driven).
> Updated: **T=171 (April 21, 2026) ~09:30 CEST** — Multimodal Moos Diary agenda corrected on Z440. Antigravity IDE agent persona established (`session:sam.moos-diary`, `system_instruction:persona.moos-dachshund` context overlay). Google Labs Flow videos pending ingestion.
> Updated: **T=170 (April 20, 2026) ~18:00 CEST** — round 10.5 hp-laptop retrofits landed (14-envelope atomic batch): mis-classified `session:sam.claude-code-hp-*` WF19 opens-on LINKs UNLINKed; `session:hp-laptop.primary` birth-session ADDed + WF19 opens-on LINK wired; 5 v3.12-promoted grammar_fragments (D19.2/D19.3/D19.4/D20.1/D20.2) MUTATEd `proposed → promoted → merged` mirroring the ontology. Hp-laptop kernel runtime ontology **still v3.11** — restart to load v3.12 pending explicit approval. Yesterday (T=169 ~15:00 CEST): z440-claude shipped round 10 Conversations A–D on Z440 kernel (doctrine note, ontology v3.12, 4 D22.* proposals, 5 note archive). Round 9/9.5 prior closed: 9 moos-kernel PRs + ffs0 PRs for v3.10 (D19.1 has-occupant) and v3.11 (t_hook.firing_state). **Z440 kernel 0 also still running v3.11** — pick up v3.12 requires a restart (pending explicit approval). Federation kernels 1-3 on :8001-:8003 still dormant on pre-T=164 code.

---

## T=175 round 14 — Multimodal Substrate Foundation (§6)

**April 25, 2026 ~22:45 CEST**
Authored by Moos/AG-Z440 lane (`agent:antigravity.hp-z440`). Focused on bringing visual/auditory artifacts into the hypergraph as boundary relations, aligning with encoder-as-functor paradigms.

| Envelope type | Count | Summary |
|---|---|---|
| ADD | 1 | `derivation:moos.section-06-multimodal-substrate-foundation` (status=closed) |

**Explicitly deferred:** Actual chunker ingestion of the 8-video/2-jpeg stack via `moos-multimodal-ingest`; this round establishes the architectural doctrine (§6 spec) and board anchors.

**Kernel stats:** +1 derivation node via HTTP :8000.

### Key URNs
- `urn:moos:derivation:moos.section-06-multimodal-substrate-foundation`

---

## Current operating context

| | |
| --- | --- |
| Runtime | hp-laptop primary `192.168.1.14:8000`, `ontology_version=3.16.2`, `t_day=208`, `log_len=1467`; hp-laptop router `192.168.1.14:9000` status ok and sees Z440 primary at `192.168.1.13:8000`. Z440 primary/twins `localhost:{8000,8001,8002,8003}` are live on `ontology_version=3.16.2`, `t_day=208`, log lengths `449/13/11/16`; Z440 router `localhost:9000` peers to hp-laptop `192.168.1.14:9000` and HP ProDesk `172.29.0.32:9000`, with HP ProDesk currently offline/non-blocking. MCP TCP `localhost:8080` is reachable. |
| Active driver | hp-laptop governance remains `agent:vscode.hp-laptop.copilot` occupying `session:sam.governance`. Z440 now has a verified VS Code/Copilot lead surface: `agent:vscode.hp-z440.primary` occupying `session:sam.z440-vscode-projection-lead` on `kernel:hp-z440.primary`; this is the Z440 control cockpit, not a blanket activation of Wolfram, Steinberger, Karpathy, Moos/Antigravity, Cowork, or `user:sam` as an apply actor. Legacy `agent:claude-code.hp-laptop` remains idle/not occupant unless restored. The five T200+ hp-laptop sessions remain scoped-idle with no occupants. External Google Calendar writes remain actuator-boundary observations; HG Calendar readback is represented by applied `calendar_event` nodes, WF19 session pins, and WF07 source anchors. No Project G-sync has been performed in this closeout. |
| T187 status | `program:sam.t187-kernel-proper` and `program:sam.t187-distributed-hg-mvp` are archived; `program:sam.t187.categorical-contract` is completed; `session:sam.t187-mvp` is abandoned. The old `kb/research/kernel/20260417-t187-kernel-proper.md` path is absent in this checkout and should be treated as a stale historical reference until recovered or deliberately retired. |
| Current projection lane | Keep/session/visual/Calendar/recommendation/atlas pipeline: `dev/scripts/projections/run-session-pipeline.ps1` -> session pack, session/Temporal Calendar/T189/Calendar-scope graph reports, DOT/SVG visuals when Graphviz is installed, Calendar plan/write-result, recommendation HG plan, recommendation reconciliation, surface context atlas, MVP gate, dashboard with four SVG zoom panes and Cytoscape.js inspectors for session occasion, Calendar Time-Fabric, T189 recommendations, and Calendar scope. Latest hp-laptop runner after the visual-root sprint remains the all-pass baseline: `pass`, 24 pass / 0 warn / 0 fail, with recommendation reconciliation converged at grouped nodes 10/10, grouped safe relations 16/16, Calendar event nodes 22/22, Calendar session pins 22/22, WF07 source anchors 22/22, deferred relations 0. Latest Z440 lead runner used the responsive hp-laptop router read surface with explicit Z440 identity after local Z440 router `/state/nodes` stalled on the offline HP ProDesk peer: `warn`, 23 pass / 1 warn / 0 fail; identity reconciliation passes for `actor=vscode.hp-z440.primary`, folded occupant `vscode.hp-z440.primary`, and VS Code/Copilot harness candidate. The one warning is a dry T189 recommendation reconciliation set of 43 pending future Calendar event nodes/pins/source anchors, not a startup/emit blocker. |
| Latest operator report | `kb/moos-diary/t208-z440-vscode-rejoin-readback.md` is the current Z440 VS Code lead rejoin report. `kb/moos-diary/t208-workspace-keep-and-z440-room-tie-wrapup.md` remains the hp-laptop Workspace Keep/API and Z440 room-tie handoff. `kb/moos-diary/t207-keep-source-acquisition-and-calendar-lock-sprint.md`, `kb/moos-diary/t206-visual-lens-root-coverage-sprint.md`, and `kb/moos-diary/t206-keep-api-mvp-and-wf07-wrapup.md` remain the latest projection/Keep/WF07 reports. T194/T193 reports remain provenance for the T200 topology sprint and HP ProDesk setup. |
| Next T208 items | Review and chunk the real T190-T208 Keep corpus with Sam before any raw-note HG apply; keep `apply_ready=false` until curated. For Z440, leave `agent:vscode.hp-z440.primary` as the single active IDE lead unless a reviewed seating activates Wolfram, Steinberger, Karpathy, Moos/Antigravity, or Cowork. Investigate local Z440 router full-state fanout behavior with offline HP ProDesk before relying on no-arg pipeline runs; the current safe workaround is the hp-laptop router read surface with explicit Z440 session/actor. Preserve the local tracked `moos-router.exe` modification until Sam decides whether it is a rebuild artifact to clean or keep. Continue Project #4 `HG URN` coverage and `my-tiny-data-collider` surface mapping; no Project G-sync from this readback. |

Historical sections below are retained as provenance. Prefer the T=187 update block above and live HG readback over older T=169/T=183 prose when deciding current state.

## Current kernel occupancy (post-T=170 retrofit)

**T=170 correction** — per `kb/research/session/20260419-t169-session-generalization.md`: the IDE-conversation-shaped `session:sam.claude-code-hp-*` nodes were mis-classified under the corrected model. Each kernel gets one **birth-session** (kernel-owned, URN = `urn:moos:session:<kernel-short>`) present from startup; additional purpose-scoped sessions stack on top. Hp-laptop side of this retrofit landed in T=170 round 10.5; z440-claude will mirror on Z440 when they pick up round 11.

| Session URN | Kernel | Role | `local_t` | Notes |
|-------------|--------|------|-----------|-------|
| `urn:moos:session:hp-laptop.primary` | `urn:moos:kernel:hp-laptop.primary` | birth-session (kernel-owned) | 0 | ADDed T=170; WF19 opens-on live |
| `urn:moos:session:hp-z440.primary` | `urn:moos:kernel:hp-z440.primary` | birth-session (kernel-owned) | 0 | ADDed yesterday on Z440 kernel; WF19 opens-on live |
| `urn:moos:session:sam.round10-session-generalization` | `kernel:hp-z440.primary` | workspace (sam-owned) | ≥0 | Z440-local; the session doctrine was driven from this |
| `urn:moos:session:sam.mvp-delivery` | `kernel:hp-z440.primary` | workspace (sam-owned) | ≥0 | Z440-local; MVP roadmap projection |

### Unlinked (WF19 opens-on removed T=170, nodes retained for provenance)

- `urn:moos:session:sam.claude-code-hp-laptop` — previously WF19-LINKed to hp-laptop kernel; retrofit UNLINKed. Node persists (log-is-truth) but has no active kernel binding.
- `urn:moos:session:sam.claude-code-hp-z440` — same treatment. Node persists.

### Historical sessions (T-day-suffixed, archived earlier rounds)

- `sam.claude-code-hp-laptop.t164` · `sam.claude-code-hp-laptop.t167` · `sam.claude-code-hp-z440.t168` — already WF19 UNLINKed in round 4 merge; retained as provenance.

### Session property redundancy cleanup (v3.9)

Two session properties are marked `deprecated: true` (scheduled for removal in v3.10):
- `session.status` (active/closed/abandoned) — subsumed by `seat_role` + permanent-session model.
- `session.turn_count` — subsumed by `local_t` (§M13 kernel-maintained heartbeat).

New merged sessions are ADDed with only `started_at` (immutable) + `seat_role` + `local_t`. Legacy nodes keep the deprecated fields until v3.10 migration.

---

## Kernel — hp-laptop

| | |
|--|--|
| URN | `urn:moos:kernel:hp-laptop.primary` |
| PID | 5944 |
| Endpoint | `:8000` (transport) + `:8080` (MCP). 3 stale `moos-kernel.exe` PIDs (13460, 7520) + 1 extra exist with no port bindings — leftover dev processes, safe to ignore |
| Log entries | 580 (561 pre-T=170 + 14 round-10.5 retrofit + 5 round-10.6 v3.13-candidate fragments) |
| Ontology at runtime | **v3.12.0** — kernel restarted T=170 ~18:01 CEST (new PID 1208, replayed 575 rewrites, `invocation_protocol` + v3.12 port pairs visible via `/operad/node-types`) |
| Ontology on disk | **v3.12.0 — 52 types, 20 WFs** (v3.12: first-ever WF20 ceremony promoted D19.2/D19.3/D19.4/D20.1/D20.2; baseline session type fixes; `seat_role` deprecated. Ffs0 commits `2a0a0f1` + `dcd75d9`) |
| Kernel binary | `C:\Users\maass\HPlaptop\moos-kernel\moos-kernel.exe` — mtime `2026-04-18 00:12`; **pre-round-9**. No `--sweep-interval` flag support; sweep loop NOT running. Ontology-load path works; rebuild to master tip (`go build ./cmd/moos`) needed before sweep comes alive. |

## Z440 (federation partner)

**T=169 11:xx CEST status — back on-site.** Kernel 0 caught up from T=164:

| | |
|--|--|
| PID | 23896 |
| Endpoint | `:8000` (transport) + `:8080` (MCP) |
| Log replay | 180 rewrites (Z440's own local history; diverges from hp-laptop's 561) |
| Ontology | v3.11.0 (same as hp-laptop) |
| Kernel binary | from master tip `88f0f96` (round-9 + round-9.5 merged) |
| Sweep | live, 30s interval |
| twin sync goroutine | started (but no active twin_link to hp-laptop yet — peering is next) |

**Federation kernels 1-3** (`PIDs 26020, 22004, 20556` on :8001-:8003): still running pre-T=164 code. Dormant — federation shard testing paused. Restart with `--sweep-interval=30s` when federation comes back into scope.

**Log divergence (381 rewrites)** is the expected consequence of the two kernels running independently since T=164 with no active twin_link syncing between them. Reconciliation options (not yet picked):
- **One-shot POST /twin/ingest** of hp-laptop's log[180..561] to Z440 — brings Z440 to parity once
- **Two-way twin_link** with `sync_mode=eager` — ongoing reconciliation; matches §M9 doctrine
- **Accept divergence** — treat Z440 as its own kernel with its own history until explicit twin-deploy

---

## Ontology delta

**v3.9 (T=168 — baseline audit):** See `dev/reference/research-archive/20260418-t168-v3.9-ontology-audit.md` and `dev/reference/research-archive/20260418-t168-s1-superset-doctrine.md`.
- **Renames:** S1 `endpoint` → `network_endpoint`; `session.role` → `session.seat_role` (non-destructive; both coexist until v3.10)
- **Deprecations:** `prg_task`, `agent_session`, `watcher`, `reactor` (all S2)
- **Stratum clarifications:** `system_instruction` confirmed S2 with `overlay_role: S4` (was incorrectly S4 in v3.8); `twin_link` confirmed S2
- **New types (6):** `skill` (S1), `grammar_fragment` (S1), `pattern` (S1), `workflow` (S1), `view_filter` (S2), `harness` (S2)
- **New WF (1):** WF20 `grammar_promotion` — carries S4→S1 adjoint Promote (src: system_instruction, governance_proposal; tgt: grammar_fragment; authority: admin)
- **Audit annotations:** top-level `free_category_note`, `fold_contract` stub, `changelog`; per-type/WF `audit_note` where gaps found
- **Deferred to v3.10:** `benchmark`, `evaluation`, `dataset`, `dsl`; full WF20 promotion algorithm; per-WF CR-safety contracts; kernel validator retirement of `session.role`

51 node types total (35 S2 + 12 S1 + 4 interaction), 20 WFs.

**v3.8 (T=167):** Added `system_instruction` (S4, M7 context overlay), `transport_binding` (S2, M10 QUIC binding).
`session` type extended: `local_t`, `context_urn`, `role` properties. WF19 mutate_scope includes `local_t`, `context_urn`.
45 node types total.

**v3.7 (T=164):** Added `channel` (S2, kinds: filesystem / messaging / board / drive / mail), `purpose` (S2), WF19 (session governance).
Source of truth: `kb/superset/ontology.json`

---

## T=187 program tasks (sub-programs, WF18 composes)

All ten are `program` nodes with URN `urn:moos:program:sam.t187.<suffix>`, status=draft, owned by `urn:moos:user:sam`. Dependencies are `depends-on` LINKs between siblings.

| Suffix | Title | Depends on | §M |
|--------|-------|------------|----|
| `session-chrono-t` | Session.local_t as first-class carrier | — | M1 |
| `t-hooks-first-class` | Node.t_hooks as explicit port substructure | session-chrono-t | M6 |
| `gates` | gate type + fail-closed pathway | t-hooks-first-class | M8 |
| `system-instruction` | system_instruction S4 type + session.context_urn | — | M7 |
| `fold-endpoint` | Expose fold as HTTP observable + SSE over HTTP/3 | **http3-quic** | M3, M10 |
| `twin-kernel` | twin_link + adjoint sync protocol over QUIC | gates, **http3-quic** | M9, M10 |
| `strata-enforcement` | Compile-time strata filtration | — | M5 |
| `answer-walk-Q1-Q4` | Answer walk Q1..Q4 | — | — |
| `categorical-contract` | Proof obligations for CI-1..CI-5 + categorical claims | all others | M1..M10 |
| `twin-deploy-mtdc` | Deploy twin at my-tiny-data-collider.nl | twin-kernel | M9, M10 |
| **`http3-quic`** | **HTTP/3 QUIC transport binding — ServeQUIC + Alt-Svc + quic-go** | **—** | **M10** |

Opening envelope batch: `dev/scripts/open-t187.py` (35 envelopes, log_seq 300..334).
M10 addition: 4 envelopes (log_seq 335..338).

---

## T=167→168 implementation sprint (completed)

Eight of eleven sub-programs implemented across two sessions:

| Sub-program | Commit | §M | Key deliverable |
|-------------|--------|----|-----------------|
| `http3-quic` | `9fa37aa` | M10 | `transport/quic.go`, quic-go v0.59.0, Alt-Svc |
| `strata-enforcement` | `9fa37aa` | M5 | `ValidateStrataLink` in operad + runtime gate |
| `fold-endpoint` | `9fa37aa` | M3 | `GET /fold?to=<t>` + SSE stream |
| `session-chrono-t` | `9fa37aa` | M1 | `bumpSessionLocalT` in runtime.Apply |
| `system-instruction` | `9fa37aa` | M7 | ontology v3.8 S4 type (no new code) |
| `t-hooks-first-class` | `aeee6c2` | M6 | `t_hook` type, Pass 2 in reactive engine |
| `gates` | `dc4961a` | M8 | `gate` type, `checkGatesLocked` in Apply path |
| `twin-kernel` | `9c24bad` | M9 | `twin_link` type, `/twin/ingest`, `RunTwinSync` |

Session `urn:moos:session:sam.claude-code-hp-laptop.t167` wired (WF19, role=occupier).
Kernel binary: `moos-kernel-new.exe` (all above), log 346, 45 ontology types.

## T=187 sub-program status

All 11 sub-programs complete or active:

| Sub-program | Status | §M |
|-------------|--------|----|
| `http3-quic` | completed | M10 |
| `strata-enforcement` | completed | M5 |
| `fold-endpoint` | completed | M3 |
| `session-chrono-t` | completed | M1 |
| `system-instruction` | completed | M7 |
| `t-hooks-first-class` | completed | M6 |
| `gates` | completed | M8 |
| `twin-kernel` | completed | M9 |
| `twin-deploy-mtdc` | **active** (twin_link ADDed, remote kernel pending) | M9 |
| `answer-walk-Q1-Q4` | completed | — |
| `categorical-contract` | completed | M1..M10 |

`twin-deploy-mtdc` ops remaining: start kernel process at mtdc, activate `urn:moos:twin_link:hp-laptop.mtdc` (MUTATE status→active) once remote `POST /twin/ingest` returns 200.

---

## T=168 spec-enrichment backlog (9 new sub-programs, status=draft)

Added T=168 via `kb/research/kernel/20260417-t187-kernel-proper.md` §M11..§M17 appendix. All ADDed to HG as `program` nodes WF18 `composes-by/composed-of` linked to `urn:moos:program:sam.t187-kernel-proper`. Implementation deferred to later sprints.

| Sub-program | §M / Origin | Depends on | One-line scope |
|-------------|-------------|------------|----------------|
| `session-liveness` | §M11 | session-chrono-t | Kernel refuses rewrites when no seat-holder (occupier/delegate) |
| `admin-capability-enforcement` | §M12 | gates, session-liveness | operad.Validate checks actor's WF02 caps for admin-scope rewrites |
| `t-local-simplification` | §M13 | — | Re-wording: `t_local` = ticker, `T` = calendar; retire M1 chrono-t language |
| `t-hook-predicate-catalog` | §M14 | t-hooks-first-class | Rich predicate shapes (fires_at, window, after_urn, recurs_every, …) |
| `t-cone-projection` | §M15 | t-hook-predicate-catalog | `GET /t-cone?session=…&at=T` — occupier's view of open-hook nodes |
| `ontology-publication` | §M16 | twin-kernel | `ontology_publication` type + read-only twin-link flow |
| `external-op-stub` | §M17 | — | `external_op` type for CF tunnel / remote kernel start / bootstrap |
| `session-actor-agent-lookup` | Q3 specslist | session-chrono-t | `bumpSessionLocalT` agent→session lookup via WF19 `occupied-by` |
| `session-role-rename` | Q-knob defer | — | `session.role` → `session.seat_role` rename (disambiguate from S1 role) |

Total T=187 sub-programs after this pass: **20** (11 existing + 9 new).

---

## T=168 round 3 — §M18..§M20 session generalization (archived in round 4 merge)

Added T=168 round 3 via `kb/research/kernel/20260417-t187-kernel-proper.md` §M18..§M20 appendix. Builds on v3.9 primitives (view_filter, harness, skill). 8 grammar-fragment candidates identified (D19.1–D19.4, D20.1–D20.4) — awaiting WF20 promotion in a future round.

The 6 round-3 sub-programs (`session-generalization`, `session-view-holder`, `session-occupant-relation`, `tool-mounting`, `cli-as-tool-protocol`, `recursive-tool-construction`) were archived in round 4 and merged into `session-view` + `session-tools` + `session-occupancy`. See round 4 section below.

---

## T=168 round 4 — sub-program merge (T-ref cleanup + by-monitoring-scope naming)

Directive (sam, T=168): "merge these and don't use t-refs in the name. we should name them by scope or with tags, but for now we name them for what they monitor." Session-layer group topology: "stratified by monoid per kernel, not by ownership".

Outcome: 14 draft T=168 sub-programs → 7 merged sub-programs named for what they monitor. `session-role-rename` marked completed (v3.9 audit delivered the seat_role rename). `session-chrono-t` retained (active, pre-round-1).

### Active T=187 sub-programs after round 4 (19 live composes from `sam.t187-kernel-proper`)

| Sub-program URN suffix | Status | Monitors / Scope |
|------------------------|--------|------------------|
| **Originals (pre-T=168, 11)** | | |
| `t187.http3-quic` | active | HTTP/3 QUIC transport (§M10) |
| `t187.strata-enforcement` | active | Compile-time strata filtration (§M5) |
| `t187.fold-endpoint` | active | fold as HTTP observable + SSE over HTTP/3 (§M3) |
| `t187.session-chrono-t` | active | Session.local_t as first-class carrier (§M1) |
| `t187.system-instruction` | active | system_instruction S4 type + session.context_urn (§M7) |
| `t187.t-hooks-first-class` | completed | Node.t_hooks as explicit port substructure (§M6) |
| `t187.gates` | completed | gate type + fail-closed pathway (§M8) |
| `t187.twin-kernel` | completed | twin_link + adjoint sync protocol (§M9) |
| `t187.twin-deploy-mtdc` | active | Deploy twin at my-tiny-data-collider.nl |
| `t187.answer-walk-Q1-Q4` | completed | Answer walk Q1..Q4 |
| `t187.categorical-contract` | completed | Proof obligations CI-1..CI-5 |
| **Round 4 merged (7, all status=draft)** | | |
| `session-occupancy` | draft | seat_role + occupant LINKs (§M19) + WF02 capability gate (§M12). Merged: session-liveness + admin-capability-enforcement + session-occupant-relation. |
| `session-timeline` | draft | local_t heartbeat (§M13) + actor→agent resolution. Merged: t-local-simplification + session-actor-agent-lookup. |
| `session-view` | draft | view_filter + pins + filtered-by (§M18) + t-cone projection (§M15). Merged: t-cone-projection + session-generalization + session-view-holder. |
| `session-tools` | draft | mounts-tool + invocation_protocol + constructs (§M20). Merged: tool-mounting + cli-as-tool-protocol + recursive-tool-construction. |
| `hook-predicates` | draft | t_hook.predicate algebra (§M14). Renamed from t-hook-predicate-catalog. |
| `ontology-publication-prg` | draft | ontology_publication event + grammar_fragment manifest (§M16). Renamed from t187.ontology-publication (suffix -prg to avoid collision with v3.9 carrier). |
| `external-op` | draft | external_op type + WF-exec pairing (§M17). Renamed from external-op-stub. |
| **Completed during round 4 (1)** | | |
| `t187.session-role-rename` | completed | Delivered in v3.9 audit (seat_role added, legacy role deprecated). |

### Round 4 depends-on chain (5 WF18 depends-on links between merged sub-programs)

```
session-occupancy  (foundational — no deps)
  ↑
  ├── session-timeline  (needs seat-model for actor resolution)
  │     ↑
  └─────┤
        └── session-view  (also depends on hook-predicates for t-cone predicate algebra)

hook-predicates  (foundational — no deps)
  ↑
  ├── session-view  (predicate algebra for view_filter)
  └── ontology-publication-prg  (predicate spec for publication manifests)

session-tools  — depends on session-occupancy (tools need occupant)

external-op  — standalone, no deps
```

### Archived in round 4 (14 sub-programs, status=archived)

Original URNs kept (log-is-truth — no UNLINK of ADD). `scope` MUTATEd to point at merged replacement URN. WF18 composes-from-kernel-proper UNLINKed (14) plus inter-subprogram depends-on (12) UNLINKed.

| Archived URN | Merged into |
|--------------|-------------|
| `t187.session-liveness` | `session-occupancy` |
| `t187.admin-capability-enforcement` | `session-occupancy` |
| `t187.session-occupant-relation` | `session-occupancy` |
| `t187.t-local-simplification` | `session-timeline` |
| `t187.session-actor-agent-lookup` | `session-timeline` |
| `t187.t-cone-projection` | `session-view` |
| `t187.session-generalization` | `session-view` |
| `t187.session-view-holder` | `session-view` |
| `t187.tool-mounting` | `session-tools` |
| `t187.cli-as-tool-protocol` | `session-tools` |
| `t187.recursive-tool-construction` | `session-tools` |
| `t187.t-hook-predicate-catalog` | `hook-predicates` (rename) |
| `t187.ontology-publication` | `ontology-publication-prg` (rename) |
| `t187.external-op-stub` | `external-op` (rename) |

---

## v3.9 baseline audit (T=168 side-step, pre-round-4)

Research notes:
- `dev/reference/research-archive/20260418-t168-v3.9-ontology-audit.md` — full audit: findings A..F, decisions, migration actions
- `dev/reference/research-archive/20260418-t168-s1-superset-doctrine.md` — S4→S1 adjoint (Promote / Express), WF20 grammar_promotion, pipeline, open questions

HG materialisation (4 envelopes):
- MUTATE `urn:moos:session:sam.claude-code-hp-laptop.t164` `seat_role → observer` (WF19)
- MUTATE `urn:moos:session:sam.claude-code-hp-laptop.t167` `seat_role → occupier` (WF19)
- ADD `urn:moos:program:sam.ontology-publication-v3.9` (type_id=program; carrier for §M16 ontology_publication — real type in v3.10)
- LINK `urn:moos:program:sam.t187.ontology-publication --WF18 composes / composed-by--> urn:moos:program:sam.ontology-publication-v3.9`

---

## T=168 round 5 — demo materialization + IRL-time gates + S0 operadic lingo

Directive (sam, T=168): *"eval the kb/research and remove redundancy and or move to session... continue where we left bf the version audit bump, something to do with demo session role or type... 'adding specs deliverables project t hooks' is my term for hydrating graph in a irl connected way... effectively mapping spec gates over irl time through te session object."*

### Research reorg

`kb/research/wires/` subdir created; 2 wires-topic notes relocated:
- `20260414-t164-wires-come-from.md` — moved from root
- `20260417-t166-wire-answer-folder-nesting.md` — moved from root

Cross-ref fix in `wires-come-from.md`: pointer to `session/20260414-t164-session-channel-purpose.md` updated to relative `../session/...`.

Research root is now 4 clean subdirs: `kernel/` · `s1/` · `session/` · `wires/`. No stray top-level notes.

### Demo materialization — 6 ADDs (v3.9 types put to use)

Originally deferred from round 2 pre-v3.9-audit. Now materialized:

| URN | Type | Role |
|-----|------|------|
| `urn:moos:view_filter:sam.important-programs` | view_filter (S2) | Sam's personal t-cone lens (type=program, owner=sam, status ∈ {active, draft}) |
| `urn:moos:view_filter:sam.t168-open-deliverables` | view_filter (S2) | IRL-time filter using §M14 `fires_at` predicate on `starts_t ≥ 168` + `status=draft` |
| `urn:moos:agent:sam.claude-code-desktop` | agent | Placeholder future occupant per §M19 — transport=mcp-stdio, status=placeholder |
| `urn:moos:grammar_fragment:d19-1-session-has-occupant` | grammar_fragment (S1) | WF19 extension proposal — new port pair `has-occupant / is-occupant-of`, extend tgt_types with user+agent |
| `urn:moos:grammar_fragment:d20-2-agent-invocation-protocol` | grammar_fragment (S1) | agent property proposal — `invocation_protocol` enum [stdio, mcp, http] |
| `urn:moos:grammar_fragment:d14-1-time-predicates` | grammar_fragment (S1) | §M14 predicate-shape catalog — 12 time predicates + boolean composition (all_of, any_of) |

All 3 grammar_fragments carry `status=proposed`, awaiting WF20 promotion ceremony. They crystallise §M14/§M19/§M20 doctrine as candidate S1 extensions.

LINK demos (view_filter→session, agent→session) deferred — no live WF carrier in v3.9 (WF18 excludes view_filter from src_types). Standalone ADDs land the concepts for t-cone projection to pick up via property-level predicates.

### IRL-time hydration — 6 MUTATE `target_t` on active sub-programs

Sam's directive (*"mapping spec gates over irl time through the session object"*) materialized as `target_t` property on each active T=187 sub-program. Parent `sam.t187-kernel-proper` already holds `target_t=220`; sub-targets stage the 6 active deliverables across T=195..220:

| Sub-program | target_t |
|-------------|----------|
| `t187.session-chrono-t` | 195 |
| `t187.system-instruction` | 200 |
| `t187.strata-enforcement` | 205 |
| `t187.fold-endpoint` | 210 |
| `t187.http3-quic` | 215 |
| `t187.twin-deploy-mtdc` | 220 |

`view_filter:sam.t168-open-deliverables` now has live targets to surface via any t-cone reader that honours §M14 `fires_at` predicates. Predicate evaluator itself deferred — see `hook-predicates` sub-program.

### S0 operadic layer — new lingo note

`dev/reference/research-archive/20260418-t168-s0-operadic-layer.md` — proposes **op-node / slot / yield / threading / weave** terminology for the category-over-S1-categories layer where `purpose`, `session`, `program`, `workflow`, `channel` live as operadic elements with typed slots. Maps sam's "semantic-to-syntax pattern" onto S4 → S0-weave → S1 → S2 → leaves pipeline. Five open questions carried forward (purpose arity; channel stratum; harness as embedded op; threading as projection; S0 bounded vs unbounded).

---

## T=168 round 6 — IRL→HG pipeline research + 6 v3.10 grammar_fragment proposals

Directive (sam, T=168): *"and humor me, and do some research too, for ex. use context 7 or relevant sources on math, category, data pipeline metrics, http3, hdc, concurrency, sheafs... classification schemas help me with lingo here i think i am talking about vector spaces here. Then polish extraction bf adding proposals."*

### Legacy extraction (pre-proposals)

Quick-extraction pass over 2 legacy folders; contents absorbed into conversation context and into the IRL→HG pipeline note, then set aside per sam's "forget about them" instruction:

- `dev/reference/research-archive/` — 15 pre-T=164 notes. Gems pulled forward: cascade matrix spectral check; Laplacian/Fiedler/Cheeger type coherence; crosswalks as SO(d) rotations; Ricci curvature on branchial graphs; graded algebra (grades 0-4); Shapley O(|E|) attribution; Yoneda-HDC `φ(node)`; Watch+React unification.
- `dev/design/` — 9 pre-T=158 design notes. Gems pulled forward: two-space CS↔HG architecture (T=152); CI-1..CI-5 formulation (T=152 origin); port typing + PortBinding reification (direct predecessor of v3.10-1 proposal); dynamic fiber + interface ports + completeness metric (predecessor of v3.10-3); bridge as natural transformation (predecessor of v3.10-2 three-views identity); governance proposal promotion loop (direct predecessor of WF20).

Both folders are now superseded by `kb/research/` + `kb/superset/ontology.json`. Retained on-disk as historical archive only.

### 4-axis research (context7 + arXiv + HF sources)

Research threads dispatched in parallel; each returned formalism + primary references:

| Axis | Key results | Primary references |
|------|-------------|--------------------|
| **Sheaf theory** | Cellular sheaves on graphs — stalks `F(v)`, restriction maps `F_{v→e}`, sheaf Laplacian `L_F = δ*δ`. `ker(L_F)` = global sections. Presheaf→sheaf via equalizer gluing axiom. Geometric morphism `f* ⊣ f_*` between classifying toposes = the correct "map of kernels". Data migration functor `Δ_F` (Spivak) with adjoint triple `Σ_F ⊣ Δ_F ⊣ Π_F`. | Hansen-Ghrist 2019 (arXiv:1808.01513); Spivak 2012; Spivak 2013 (arXiv:1305.0297, UWD operads) |
| **HDC / VSA** | HRR binding = circular convolution = unitary rotation (Plate); BSC via XOR (Kanerva); MAP via Hadamard (Gayler). Procrustes rotation `R* = UV^T` (Schönemann 1966) — the formal way to align two classification schemes. Stiefel manifold `V_k(ℝ^d) = O(d)/O(d−k)` is the moduli space of size-k classification schemes. Tight frame / ETF = the formal name for a classification scheme (not a basis). | Plate 1995 (HRR); Kanerva 2009 (BSC); Gayler 2003 (MAP); Schönemann 1966 (Procrustes); |
| **Pipeline metrics & concurrency** | Little's Law `L = λW` for reactive backpressure sizing. Watermarks = event-time completeness lower bound (Akidau MillWheel VLDB 2013). HLC (Kulkarni 2014) is the right choice for twin_link causality. CRDTs: OR-Set for nodes/edges, LWW-Register-with-HLC for properties (Shapiro 2011). QUIC 0-RTT is safe only for idempotent GETs (replay attacks block admin rewrites). | Akidau 2013; Kulkarni 2014; Shapiro 2011; RFC 9000 |
| **Ollivier-Ricci on graphs** | `κ(x,y) = 1 − W₁(μ_x, μ_y)/d(x,y)` — Wasserstein-1 over neighbour distributions. Forman-Ricci = O(deg) combinatorial proxy with ~0.7-0.9 Spearman corr vs Ollivier. Ricci flow outperforms modularity for community detection (Ni et al. Nature Sci Rep 2019). Jost-Liu 2014: `κ ≥ κ_min ⇒ λ₂ ≥ κ_min` — bridges curvature to spectral gap. | Ollivier 2007; Lin-Lu-Yau 2011; Ni 2019; Jost-Liu 2014 |

**Three-views identity** (v3.10 proof obligation): **Procrustes rotation = data migration functor Δ_F = geometric morphism f***.  
The same crosswalk object can be presented as (a) an orthogonal rotation aligning two HDC frames, (b) a pullback functor between schema categories, or (c) the inverse-image part of a geometric morphism between classifying toposes. All three must agree up to natural isomorphism — this becomes CI-6.

### Polished research note

`dev/reference/research-archive/20260418-t168-irl-to-hg-pipeline.md` — 9-section ~500-line note:

1. IRL→HG pipeline stages (S4 intent → S1 wire → S0 weave → S2 occupancy → S1 reflect)
2. Vector-space lingo sam asked for (tight frames, Stiefel, Procrustes, HDC binding)
3. Sheaf-theoretic lingo (stalks, sections, restriction maps, sheaf Laplacian)
4. Three-views identity (Procrustes = Δ_F = geometric morphism)
5. Mapping to current doctrine (where §M14..§M20 fit each frame)
6. Concurrency / federation dynamics (Little's Law, HLC, CRDT, Ollivier-Ricci)
7. v3.10 proof obligations (CI-6 three-views identity, plus the 6 candidate fragments)
8. Vocabulary cards — one-card-per-term for session hand-offs
9. References (~30 primary sources)

Serves as the foundation for the 6 proposals below.

### 6 grammar_fragment proposals for v3.10 (all ADDed, status=proposed)

Each fragment crystallises doctrine from the pipeline note into a concrete candidate S1 extension. Awaiting WF20 promotion ceremony in a future round.

| URN suffix | Kind | Crystallises | Specification highlights |
|------------|------|--------------|--------------------------|
| `v310-1-port-binding` | type | Design-era PortBinding reification (OBJ24 candidate) | New S1 type `port_binding`. Properties: `src_type, src_port, tgt_type, tgt_port, wf_category, benchmarks, req_schema, resp_schema`. Turns implicit (type, port) pairs into first-class nodes. |
| `v310-2-crosswalk` | type | Three-views identity (§7 pipeline note) | New type `crosswalk`. Properties: `source_classification_urn, target_classification_urn, rotation_artifact_urn, procrustes_error, direction: {pullback_delta, leftkan_sigma, rightkan_pi}, verified`. Presents the three-way equivalence as a single node. |
| `v310-3-fiber-completeness` | property | Dynamic fiber + interface ports (design-era) | New `completeness` property on `channel, view_filter, twin_link`. Computation: `|wires_present| / |wires_expected|`. Trigger: emit `bridge.sync.needed` when completeness < 0.8. |
| `v310-4-branchial-ricci` | property | Ollivier-Ricci axis + Jost-Liu spectral bridge | New properties on `twin_link`: `ollivier_ricci`, `forman_ricci`. Composition with spectral gap via Jost-Liu 2014. Ricci flow community detection via Ni et al. 2019. |
| `v310-5-cascade-spectral-bound` | predicate_shape | Cascade matrix stability (archive gem) | New predicate shape `cascade_stable(C, threshold)`. Formula: `ρ(C) < threshold` (spectral radius of cascade matrix). References Newman 2018 §17.8; Barrat-Barthélemy-Vespignani 2008 ch.9. |
| `v310-6-sheaf-laplacian-inconsistency` | predicate_shape | Hansen-Ghrist sheaf Laplacian | New predicate shape `sheaf_laplacian_inconsistent(F, tolerance)`. Formula: `L_F = δ*δ` has nonzero eigenvalue > tolerance. Flags consistency failure across the graph's sheaf of restrictions. |

All 6 ADDs succeeded (batch via `mcp__moos-kernel__apply_program`). `affected_node_urn` returned per fragment. Kernel stats: log 457→463 (+6), nodes 142→148 (+6), relations 198 unchanged.

---

## T=168 round 7 — still-pending cleanup (10 more grammar_fragment proposals)

Directive (sam, T=168): *"continu where we left bf we did the last in a serie of md docs evals"* — resume from the "still pending for later rounds" backlog that was set aside for the legacy-folder evals.

### Backlog identification

Two residual streams pending since earlier rounds:

1. **§M18..§M20 round-3 candidates** (from `kb/research/kernel/20260417-t187-kernel-proper.md` round-3 appendix, lines 529-536). 8 fragments proposed by name in round 3; only 2 (D19.1, D20.2) + 1 late-addition (D14.1) materialised in round 5. **6 still un-materialised.**
2. **v3.9 audit §D deferred types** (from `dev/reference/research-archive/20260418-t168-v3.9-ontology-audit.md` lines 61-64). 4 types (benchmark, evaluation, dataset, dsl) explicitly deferred to v3.10.

Round 7 lands all 10 as grammar_fragment proposals. One atomic batch.

### 6 §M18..§M20 backlog proposals (status=proposed, stratum_origin=1 matching round-3 siblings)

| URN suffix | Kind | Crystallises |
|------------|------|--------------|
| `d19-2-session-view-prefs` | property | §M18: `session.view_prefs` object (`sort_by, fold_depth, density, theme`) — scalar UI prefs for t-cone rendering. Distinct from view_filter (predicate) and pins (topology). |
| `d19-3-session-pins-urn` | port | §M18: session `pins-urn / pinned-by-session` — topology-color port to any node. Occupant's persistent visibility anchors. |
| `d19-4-session-filtered-by` | port | §M18: session `filtered-by / filters-session` → view_filter. Semantic-color port; §M15 t-cone composes as intersection over all bound predicates. |
| `d20-1-session-mounts-tool` | port | §M20: session `mounts-tool / tool-mounted-in-session` → agent. Mounted tools invokable by occupant under WF02 caps. |
| `d20-3-agent-runs-in-harness` | port | §M20: agent `runs-in / runs` → harness. Capability intersection at runtime with `harness.allowed_capabilities`. |
| `d20-4-agent-constructs-agent` | port | §M20: agent `constructs / constructed-by` → agent. Recursive tool-making. **Candidate CI-6: capability isolation** — no auto-inherit from constructor; explicit upper bound. |

### 4 v3.10 deferred-type proposals (status=proposed, stratum_origin=2 matching round-6 siblings)

| URN suffix | Kind | Crystallises |
|------------|------|--------------|
| `v310-7-benchmark` | type | S2 type. Fixture + expected outcomes + scoring rubric. Pairs with `evaluation`. Can target harness/agent/workflow. Dataset-backed when bulk. |
| `v310-8-evaluation` | type | S2 type, append-only. Run-level node carrying scores, pass/fail, artifacts, run_t. Time-series metric tracking + pass/fail gates. |
| `v310-9-dataset` | type | S2 type, versioned. Structured input corpus; versioning lets evaluations fix a snapshot. Doubles as **HDC tight-frame support** (per §3.4 pipeline note) when used as a classification scheme. |
| `v310-10-dsl` | type | S1 type. Bundles many grammar_fragments into a named, versioned micro-grammar. Activation via proposed WF20-2 `dsl_activation` (atomic promote-all-and-activate). |

### Crosswalks & provenance links (via `evidence_urns`)

Fragment proposals wire themselves together through evidence pointers — lets any reader discover the candidate S1 cluster:

- `v310-8-evaluation` → `v310-7-benchmark` (requires)
- `v310-9-dataset` → `v310-2-crosswalk` (HDC-frame connection; `v310-2` already established the three-views identity)
- `v310-10-dsl` → `v310-7-benchmark + v310-8-evaluation + v310-9-dataset` (bundling)
- D19.4 → `view_filter:sam.important-programs + view_filter:sam.t168-open-deliverables` (round-5 demo instances)
- D20.4 → `agent:claude-code.hp-laptop + agent:sam.claude-code-desktop` (constructor / constructed candidates)

### Kernel stats after round 7

All 10 ADDs succeeded in one atomic batch. Kernel: log 463→473 (+10), nodes 148→158 (+10 grammar_fragment), relations 198 unchanged.

**Grammar_fragment census:** 19 total (3 from round 5 + 6 from round 6 + 10 from round 7). All `status=proposed`. WF20 promotion ceremony remains the outstanding gate for any of these to become live S1 grammar.

### What's left in the backlog after round 7

- **WF20 promotion algorithm** — how evidence aggregates, how admin signs acceptance, how canonical types materialise. Doctrine declared in v3.9 audit §F; kernel validator not yet exercising WF20.
- **Per-WF CR-safety contracts** — v3.9 adds `audit_note` per WF flagging CR-safety; explicit contract declarations deferred.
- **Kernel validator retirement of `session.role`** — `seat_role` added, legacy `role` marked deprecated; validator still accepts both. Removal scheduled for v3.10.
- **LINK demos (view_filter→session, agent→session)** — deferred in round 5 (no live WF carrier); still pending a WF or WF-extension landing.
- **Predicate evaluator implementation** — §M14 `fires_at`, `window`, etc. declared; evaluator in the `hook-predicates` sub-program (status=draft).

---

## T=168 round 8 — T=187 delivery clock + successor programs + external_op IRL gates

Directive (sam, T=168): *"we have the t187 as a hook, a possible calendar event a delivery date, a possible node that future nodes will depend on, nodes that are composed by this node. Surprise me."*

**Central idea.** T=187 = **May 7, 2026** (T=0 is 2025-11-01). The `t187-kernel-proper` program is now treated as a real IRL-time delivery node — the kind that gates successors, anchors sub-program sprint checkpoints, and gets its own t_hook cascade. The HG becomes its own **spec-level CI/CD pipeline**: t_hooks fire at target_t values across the T=187→T=220 window, each marking a sub-program checkpoint visible via the t-cone.

Full doctrine: `dev/reference/research-archive/20260418-t168-t187-delivery-clock.md` (archived in T=169 round 10).

### Calendar map

| T-value | Calendar date | Role |
|---------|--------------|------|
| T=168 | 2026-04-18 | Today — round 8 |
| T=187 | 2026-05-07 | Delivery window opens |
| T=195 | 2026-05-15 | `session-chrono-t` checkpoint |
| T=200 | 2026-05-20 | `system-instruction` checkpoint |
| T=205 | 2026-05-25 | `strata-enforcement` checkpoint |
| T=210 | 2026-05-30 | `fold-endpoint` checkpoint |
| T=215 | 2026-06-04 | `http3-quic` checkpoint |
| T=220 | 2026-06-09 | `twin-deploy-mtdc` checkpoint; delivery window closes; v310-delivery starts |
| T=240 | 2026-06-29 | v3.10 delivery target — 23 grammar_fragments promoted |
| T=250 | 2026-07-09 | wiring-proposer target — HDC-grounded auto-wiring active |

### Batch A — 10 t_hook ADDs (delivery clock)

| URN | owner_urn | predicate | react |
|-----|-----------|-----------|-------|
| `t_hook:sam.t187.delivery-opens` | `program:sam.t187-kernel-proper` | `fires_at t=187` | MUTATE kernel-proper `delivery_phase=in-delivery` |
| `t_hook:sam.t187.delivery-closes` | `program:sam.t187-kernel-proper` | `closes_at t=220` | MUTATE kernel-proper `delivery_phase=closed` |
| `t_hook:sam.t187.checkpoint.session-chrono-t` | `program:sam.t187.session-chrono-t` | `fires_at t=195` | MUTATE status=checkpoint |
| `t_hook:sam.t187.checkpoint.system-instruction` | `program:sam.t187.system-instruction` | `fires_at t=200` | MUTATE status=checkpoint |
| `t_hook:sam.t187.checkpoint.strata-enforcement` | `program:sam.t187.strata-enforcement` | `fires_at t=205` | MUTATE status=checkpoint |
| `t_hook:sam.t187.checkpoint.fold-endpoint` | `program:sam.t187.fold-endpoint` | `fires_at t=210` | MUTATE status=checkpoint |
| `t_hook:sam.t187.checkpoint.http3-quic` | `program:sam.t187.http3-quic` | `fires_at t=215` | MUTATE status=checkpoint |
| `t_hook:sam.t187.checkpoint.twin-deploy-mtdc` | `program:sam.t187.twin-deploy-mtdc` | `fires_at t=220` | MUTATE status=checkpoint |
| `t_hook:sam.v310-delivery.startable` | `program:sam.v310-delivery` | `all_of(fires_at t=220, after_urn kernel-proper.status=completed)` | MUTATE status=startable |
| `t_hook:sam.wiring-proposer.startable` | `program:sam.wiring-proposer` | `all_of(fires_at t=240, after_urn kernel-proper.status=completed, after_urn v310-delivery.status=completed)` | MUTATE status=startable |

`owner_urn` is a `t_hook` property (not a separate LINK) — kernel attaches via property lookup. Predicate evaluator for `all_of` + `after_urn` deferred to `t187.hook-predicates` sub-program (currently only `fires_at` is evaluated).

### Batch B — 2 successor programs + 3 WF18 LINKs

| Program | status | starts_t | target_t | Depends on |
|---------|--------|----------|----------|------------|
| `program:sam.v310-delivery` | draft | 220 | 240 | `t187-kernel-proper` |
| `program:sam.wiring-proposer` | inert (pre-existing node, MUTATEd starts_t/target_t) | 240 | 250 | `t187-kernel-proper`, `v310-delivery` |

WF18 LINKs added (composes/composed-by + depends-on/depended-by):
- `v310-delivery --depends-on--> t187-kernel-proper`
- `wiring-proposer --depends-on--> t187-kernel-proper`
- `wiring-proposer --depends-on--> v310-delivery`

### Batch C — 3 external_op ADDs (IRL-condition gates)

Models §M17 doctrine: IRL manual operations whose completion gates sub-program status. Added `external_op` to `ontology.json` as an S2 type (not a grammar_fragment promotion — the type landed directly since the plan required it). One test node `external_op:sam.test` persists in log with status=cancelled (log-is-truth; cannot be removed).

| URN | deadline_t | automates_via | command_hint |
|-----|-----------|---------------|--------------|
| `external_op:sam.mtdc-kernel-start` | 187 | `program:sam.t187.twin-deploy-mtdc` | `ssh mtdc; cd moos-kernel; ./moos-kernel-new --port 8000` |
| `external_op:sam.cf-tunnel-api-mtdc` | 187 | `program:sam.t187.twin-deploy-mtdc` | `cloudflared tunnel route dns mtdc api.my-tiny-data-collider.nl` |
| `external_op:sam.ontology-bootstrap-mtdc` | 220 | `program:sam.v310-delivery` | `curl -X POST http://api.my-tiny-data-collider.nl/ontology -d @kb/superset/ontology.json` |

### Batch D — 4 more grammar_fragment proposals (23 total now)

All four status=proposed, awaiting WF20 promotion.

| URN suffix | Kind | Crystallises |
|------------|------|--------------|
| `v310-11-ontology-publication` | type | §M16 formalised. New S1 type `ontology_publication` with version / content_hash / signed_by / promoted_fragment_urns / supersedes_urn. Twin-link read-only sync makes v3.10 landing atomic. |
| `v310-12-grammar-fragment-enrichment` | property | Adds `blocked_until: urn` to grammar_fragment (mutable, admin scope). Enables dependency-aware promotion queue. Verified rejection_reason already in v3.9. |
| `v310-13-purpose-arity2` | wf_clause | Purpose as S0 arity-2 op-node. `phi_current` and `phi_target` become slots (WF01 LINKs with new port pairs) not scalar properties. Yield = phi-space direction computed at t-cone read time. |
| `v310-14-startable-status` | property | Dual-kind: `program.status` enum gains `startable` + canonical `all_of(fires_at, after_urn*)` t_hook shape. Independent programs: arity-1; dependent programs: arity-N. Materialised by `v310-delivery.startable` + `wiring-proposer.startable` t_hooks. |

### Round 8 batch summary

| Batch | Rewrites | Net nodes | Net relations |
|-------|----------|-----------|---------------|
| A — delivery clock | 10 ADD + 1 MUTATE (ontology_publication-v3.9 calendar_date props) | +10 t_hook | 0 |
| B — successor programs | 1 ADD (v310-delivery) + 2 MUTATE (wiring-proposer starts_t/target_t) + 3 LINK | +1 program | +3 WF18 |
| C — external_op gates | 4 ADD (3 IRL + 1 test) + 2 MUTATE (test→cancelled) | +4 external_op | 0 |
| D — grammar_fragments | 4 ADD | +4 grammar_fragment | 0 |

Totals: **+19 nodes, +3+ relations, ~88 log entries**.

**Grammar_fragment census:** 23 total (3 round 5 + 6 round 6 + 10 round 7 + 4 round 8). All status=proposed.

### Deferred to future rounds (status at round-8 close)

- Predicate evaluator (`after_urn` + `all_of`) — **shipped in round 9** (`t187.hook-predicates` sub-program). See next section.
- 6 active sub-program startable t_hooks — now evaluable; sweep emits governance_proposals when conditions meet.
- MUTATEs to t187-kernel-proper `delivery_phase / calendar_date_open / calendar_date_close` — fields still not in program type spec; awaiting future ontology bump.
- external_op → sub-program LINK via `automates_via` port (WF extension TBD).
- WF20 grammar_promotion ceremony for the remaining 22 fragments (D19.1 merged in round 9).

---

## T=168→169 round 9 — kernel code (no HG hydration)

Round 9 is the first round where the delta is in Go code, not HG ADDs. The `t187.hook-predicates` sub-program is now shipped end-to-end, plus session-occupancy (§M11+§M12+§M19) and t-cone (§M15).

### PRs merged to master

| # | Scope | Branch |
|---|-------|--------|
| **#15** | T=187 sprint v2 replacement for closed #8 | `agent/z440-claude/hdc-engine` |
| **#17** | pure predicate evaluator (§M14 subset: fires_at, closes_at, after_urn, before_urn, all_of, any_of) | hook-predicates |
| **#18** | `GET /t-hook/evaluate/{urn}?at=T` introspection endpoint | thook-evaluate-endpoint |
| **#19** | `POST /t-hook/evaluate` batch endpoint (max 1 MiB body) | thook-batch |
| **#20** | time-driven sweep + WF13 governance_proposal emission (`--sweep-interval` flag, default 30s) | sweep-loop |
| **#21** | `GET /t-cone?session=...&at=T` projection | t-cone |
| **#22** | 4 extended §M14 kinds: window, expires_at, on_prop_set, when_capability (with EvalContext) | predicates-extended |
| **#23** | review-comment followups (correctness tightening across #12–#16) | round-9-review-followups |
| **#24** | **T=169** perf followups: shared `internal/tday` + NodesByType/Relations{Src,Tgt} indexes | t169-perf-followups |
| **ffs0 #31** | **ontology v3.10.0** — D19.1 merged; WF19 gains has-occupant/is-occupant-of port pair and tgt_types {user, agent} | v3.10-session-occupancy |

### New / extended APIs

```
POST /t-hook/evaluate        { "urns": [...], "at": T }    → [{urn, at_t, fires, ...}]
GET  /t-hook/evaluate/{urn}  ?at=T                         → {urn, at_t, fires, ...}
GET  /t-cone                 ?session=urn&at=T             → occupier's projection
```

### New CLI flag

```
--sweep-interval=30s   (0 disables)
```

### Package additions

- `internal/tday` — single source of truth for the mo:os T-day epoch + `Now()` / `At(t)` helpers. Used by `cmd/moos`, `internal/transport`, `internal/kernel/sweep`.
- `internal/operad/occupancy.go` — `ResolveSessionOccupant(state, sessionURN)` and `CheckAdminCapability(state, actor)` (§M11/§M12).
- `internal/kernel/sweep.go` — `SweepOnce`, `RunTimedSweep`, `SweepTick`, `SetSweepActor`.

### Structural hardening (T=169)

- `graph.GraphState` gains 3 secondary indexes (JSON-omitted, rebuilt on load): `NodesByType`, `RelationsBySrc`, `RelationsByTgt`. Maintained by `fold.apply{ADD,LINK,UNLINK}`. Accessors `NodesOfType` / `RelationsFrom` / `RelationsTo` fall back to a full scan when the index is nil (keeps test fixtures correct without Rebuild).
- Hot paths (sweep, occupancy helpers, t-cone, when_capability) migrated from O(N)/O(R) scans to O(bucket-size).

### Firing semantics (locked for this round)

Sweep **proposes via WF13 governance** — NEVER auto-applies. Each firing hook produces a `governance_proposal` node with `status=pending`, `source_t_hook_urn`, `fires_at_t`, `proposed_envelope` (the decoded react_template). Admin sessions flip status to approved or rejected; a separate approver-reactor (not yet shipped) applies the envelope on approval. Matches §M12 fail-closed stance.

### Deferred to future rounds

- Approver reactor (governance_proposal.status=approved → apply proposed_envelope). **Still pending** — see T=169.5 section below for the state-machine prerequisites.
- `firing_state` property on t_hook — **shipped in T=169.5 (v3.11.0 + moos-kernel PR #25)**. See below.
- Bounded worker pool for `forwardToEagerTwins` (closed #8 Gemini flagged; structural, separate PR).
- Event-shape JSON round-trip fast-path in reactive engine (closed #8 Gemini flagged; cache parsed shape on t_hook node).
- `GraphState.Clone` copy-on-write (T=169 Gemini MEDIUM, TODO in code).

---

## T=169.5 — firing_state lifecycle (v3.11 + kernel PR #25)

Round-9.5 extends the sweep's idempotency from "does a governance_proposal with matching source_t_hook_urn exist?" (O(proposals) scan per tick) to a first-class state machine on the hook itself.

### Ontology (ffs0 PR #32, merged)

`t_hook.firing_state` enum: `{pending, proposed, approved, rejected, applied, closed}`. Default `pending`. Authority `kernel` — only sweep/reactor mutate it.

Transition graph:

```
pending  ──(sweep fires)────▶ proposed
proposed ──(admin approves)─▶ approved  ──(approver reactor applies)─▶ applied
proposed ──(admin rejects)──▶ rejected  (terminal)
applied                                  (terminal for one-shot hooks)
closed   (future: expires_at / manual)   (terminal)
```

### Kernel (moos-kernel PR #25)

- Sweep filters on `firing_state ∈ {"", "pending"}` (empty = pending default).
- Each firing emits TWO envelopes atomically in one ApplyProgram batch:
  1. `ADD urn:moos:proposal:kernel.<slug>-t<T>-seq<N>` (unchanged shape)
  2. `MUTATE <hookURN> firing_state pending → proposed`
- The old O(proposals) scan is gone. ApplyProgram is all-or-nothing, so the pair lands together or not at all (log-is-truth + CI-4 preserved).

### Rollback & migration

- Pre-v3.11 hooks (round-8 t_hooks, no firing_state on node) work transparently — first sweep evaluation produces an additive MUTATE setting firing_state → proposed. One-time per hook, idempotent on replay.
- Pre-v3.11 kernels reading v3.11-style hooks ignore the extra property. The ADD proposal shape is unchanged, so old-kernel idempotency-via-proposal-existence still works. Rollback-safe.

### Next (still pending)

- **Approver reactor** — watches `governance_proposal.status` MUTATEs, applies `proposed_envelope` on approve, transitions hook's firing_state proposed → applied | rejected. Needs design around actor-authority threading (whose authority is the reactor acting under when it applies? the admin who approved? a kernel-synthesized actor?).
- Bounded twin worker pool (now matters once Z440 peers).
- event_shape JSON fast-path.
- Clone-COW.

---

## T=169 round 10 — session generalization (closed; Conversations A–D done on Z440; hp-laptop retrofit in T=170 round 10.5 below)

Directive (sam, T=169): generalize the session concept beyond claude-code-per-kernel. Tools, CLI agents, third-party agentic frameworks; users + delegates; **kernel-bound workspace, not IDE conversation**. Completion-drive = session's purpose; spec-completion = the drive; incomplete data = gate-blocked realization.

Plan file: `C:/Users/hp/.claude/plans/1-if-specs-are-parsed-jellyfish.md` (decomposes round 10 into Conversations A/B/C/D + E for round 11).

### Doctrine note

`kb/research/session/20260419-t169-session-generalization.md` — the corrected model:

- **Session = (scope, purpose) × (host, owner, occupant)** — five orthogonal facets. Persistent, always-on, host-bound workspace. Tmux-session / Chrome-tab analogy. IDE conversations are ephemeral; their rewrites are traced via `actor_urn`, not via session nodes.
- **CT lingo corrected** — three separable algebras: per-session transition-monoid (identity = no-op morphism, not empty-object); operadic scope composition (sessions nest; birth-session as root scope); user/group topology as an orthogonal lattice (WF02 capability carries pieces of this, full formalization deferred).
- **Single-driver invariant** — has-occupant LINK single-valued per session (D19.1 merged v3.10; D22.2 formalizes at-most-one invariant in v3.12 proposals). Rotation = MUTATE of LINK target_urn.
- **Kernel-birth atomic pair** — ADD kernel:K + ADD session:<K-short> in the same ApplyProgram envelope (D22.4 proposed).
- **Purpose as higher-level semantic wiring** — not a leaf tool. Gradient φ(purpose) = φ(target_state) − φ(current_state). D22.1 wires purpose-steers-session; cos-similarity scoring deferred to wiring-proposer (T=240+). Purpose is a future-operational building-block, like tools; not actively steering rewrites until session layer is operational.
- **Disposition** — mis-classified `session:sam.claude-code-hp-*` nodes live only on hp-laptop kernel (Z440 is sovereign per §M9). Z440-local retrofit ADDed correctly-named `session:hp-z440.primary` as the birth-session. hp-laptop-side retire/replace is a separate conversation's work.

### Conversation A (complete, commit 37124d5) — doctrine + Z440 opening HG rewrites

8 envelopes applied atomically to Z440 kernel 0, log 180 → 188:

- ADD `program:sam.round10-session-generalization` (status=active, starts_t=169, target_t=175)
- ADD `purpose:sam.coherent-session-doctrine` (generic intent, not round-specific naming)
- LINK `purpose --WF18 composes--> program`
- ADD `t_hook:sam.round10-session-generalization.target` (fires_at=175, react: MUTATE program status→checkpoint)
- ADD `session:hp-z440.primary` (birth-session retrofit, started_at=kernel.created_at)
- LINK `session:hp-z440.primary --WF19 opens-on--> kernel:hp-z440.primary`
- ADD `session:sam.round10-session-generalization` (round workspace — Chrome-tabs demonstrator)
- LINK `session:sam.round10-session-generalization --WF19 opens-on--> kernel:hp-z440.primary`

Note: `has-occupant` LINKs declared in v3.10 as WF19 additional_port_pairs but not consumed by operad/loader.go yet — deferred to Conversation E / round 11.

### Conversation B (complete, commit 2a0a0f1) — ontology v3.11 → v3.12, first WF20 ceremony

Ontology-level promotion of 5 proposed grammar_fragments (HG-level status MUTATEs remain for hp-laptop kernel, which holds the proposal nodes):

- D19.2 session-view-prefs → `session.view_prefs` object property
- D19.3 session-pins-urn → WF19 additional_port_pair (session → any node)
- D19.4 session-filtered-by → WF19 additional_port_pair (session → view_filter)
- D20.1 session-mounts-tool → WF19 additional_port_pair (session → agent)
- D20.2 agent-invocation-protocol → `agent.invocation_protocol` enum {stdio, mcp, http}

Baseline session type fixes alongside the ceremony:
- `urn_pattern` → kernel-short | owner.purpose-slug
- `description` → persistent kernel-bound workspace semantics
- `seat_role` deprecated (single-driver-via-LINK model supersedes)
- Type-level note rewritten with transition-monoid + operadic-scope + user/group-lattice framing

Known code gap: `operad/loader.go` does not consume `additional_port_pairs`. The 4 pairs on WF19 (has-occupant + 3 new v3.12) validate only as the primary opens-on/occupied-by pair. Round 11 session-occupancy closes this.

### Conversation C (complete) — 4 new D22 grammar_fragment proposals

Applied to Z440 kernel 0, log 188 → 192:

- D22.1 session-has-purpose (port pair, 1-to-1 with rotation, WF19 extension)
- D22.2 session-single-driver-invariant (at-most-one has-occupant per session)
- D22.3 session-attach-detach (attach/detach/rotate verbs on single-driver model)
- D22.4 kernel-birth-session-pair (atomic-pair invariant for kernel ADDs; seed-code change blocked on this promotion)

All 4 status=proposed. No ontology bump.

### Conversation D (this update) — archive + running-state close

5 research notes moved to `dev/reference/research-archive/`:

- `20260418-t187-categorical-contract.md` (proofs hold by construction; landed)
- `20260418-t187-walk-answers-Q1-Q4.md` (Q1–Q4 answered + implemented)
- `20260414-t164-session-channel-purpose.md` (T=164 foundational work; in HG)
- `20260418-t168-t187-delivery-clock.md` (schedule live in v3.11 firing_state)
- `20260417-t166-wire-answer-folder-nesting.md` (Q5 answered, ontology-only)

Cross-refs updated across: ontology.json (`t164_delta_reference`), running-state.md, the new doctrine note, `wires/20260414-t164-wires-come-from.md`, `s1/20260418-t168-s0-operadic-layer.md`.

### Deferred to round 11 (Conversation E)

- session-occupancy Go implementation — 4 stacked PRs: RotateSessionOccupant + validator, §M11 liveness check in runtime.Apply, §M12 admin-cap gate extended to occupant chain, `GET /session/<urn>/occupant?at=T` endpoint.
- operad/loader.go gains multi-port-pair awareness (closes the additional_port_pairs gap).
- hp-laptop-side retire/replace of mis-classified session:sam.claude-code-hp-* nodes (UNLINK WF19 + ADD session:hp-laptop.primary + has-occupant wiring).
- kernel restart to load v3.12 (still pending explicit approval as of T=169 round-10 close).

### Open questions (not blocking)

- WF home for `purpose --has-purpose--> session` (D22.1) — WF19 extended likely; new WF21 possible. Promotion-ceremony decision, not design-ahead.
- Cos-similarity as one of many "cutting methods" (operads, type algebra, Ricci curvature, symmetry groups, Wolfram hypergraph, sheaf Laplacian, Procrustes rotation, cascade spectral radius). Candidate future discussion node: `program:sam.cutting-methods`.
- D20.3 agent-runs-in-harness + D20.4 agent-constructs-agent — for agents we author (Google ADK, PydanticAI, CLI), not the prepackaged IDE agents. Blocked on harness concept + CI-6 capability isolation + first bespoke-agent prototype.
- v310-13 purpose-arity2 — structural change to purpose (phi_current, phi_target as slots, not scalars). Later round, after operational experience with purpose at t-cone read time.
- Platform-as-host (Reading B, D22.5 future) — extending session.host beyond `kernel` to `platform` for non-mo:os agent runtimes (Google ADK, Anthropic workspace, external MCP daemons).

### Round-10 grammar_fragment census (Z440 kernel perspective)

4 new at status=proposed (D22.1–D22.4). Z440 kernel does not hold the 23 pre-existing rounds 5–8 proposals (those live only on hp-laptop kernel; sovereign-kernels principle).

### Kernel stats (Z440 kernel 0, post-Conversation A+C+MVP-spec projection)

- Log: 223 entries
- Ontology on-disk: v3.12.0 (kernel runtime still loading v3.11 — restart pending)
- Sessions: 4 (`hp-z440.primary` birth, `sam.round10-session-generalization` workspace, `sam.mvp-delivery` workspace, `vscode-codex-hp-z440.t161` legacy-mis-classified non-round-10-scope)
- Grammar_fragments: 4 (all D22.*)

---

## T=170 round 10.5 — hp-laptop retrofits (2026-04-20 ~18:00 CEST)

Round 10.5 lands the hp-laptop-side counterpart of z440-claude's round-10 work: the mis-classified session-WF19-LINKs are unwired, the hp-laptop birth-session is installed, and the five grammar_fragments that z440-claude promoted in the ontology ceremony get their HG-level status MUTATEd to match (`proposed → promoted → merged`). No new doctrine written — the z440-claude note is authoritative. This is pure mechanical sync.

### What landed (single atomic batch, 14 envelopes, hp-laptop kernel)

| Envelope | Details |
|----------|---------|
| UNLINK ×2 | `wf19.sam.claude-code-hp-laptop.opens-on` + `wf19.sam.claude-code-hp-z440.opens-on` removed; sessions persist un-wired |
| ADD ×1 | `session:hp-laptop.primary` (birth-session; `started_at=2026-04-03T01:05:11Z` ≡ kernel's `created_at`; `local_t=0`) |
| LINK ×1 | `wf19.hp-laptop.primary.opens-on` — birth-session → kernel |
| MUTATE ×10 | D19.2, D19.3, D19.4, D20.1, D20.2 each: status `proposed → promoted` then `promoted → merged` (WF20, admin authority) |

Corrected state-machine enum note: grammar_fragment.status is `proposed → rejected | promoted | merged` per ontology; z440-claude's conv sum used "approved/applied" casually — the retrofit uses the correct enum values.

### Explicitly **not** done (deferred)

- **`session:hp-laptop.primary --has-occupant--> agent:claude-code.hp-laptop`** — v3.11 runtime loader doesn't consume `additional_port_pairs`, so the `has-occupant` port would fail validation. Deferred until Round-11 Conversation E PR 1 (loader extension) lands.
- **Z440 side identical work** (analogous UNLINKs + birth-session ADD for any kernel missing it) — z440-claude's `t169round10_next_plan.md` owns that. Not hp-laptop's call.
- **Kernel restart to load v3.12** — destructive, pending explicit sam approval.
- **`POST /twin/ingest` of `kb/moos_from_HPLAP.jsonl`** — file is in ffs0 git; not applied into z440's running HG. Per §M9 sovereign kernels, divergence is normal — this stays optional.

### Kernel stats (hp-laptop kernel, post-retrofit + post-restart)

- Log: 575 entries (+14 from the atomic batch)
- Ontology at runtime: **v3.12.0** — kernel restarted T=170 ~18:01 CEST (PID 5944 → 1208)
- Replay on startup: clean, 575 rewrites applied against v3.12 validator; one known idempotent skip (`twin_link:hp-laptop.mtdc` duplicate ADD at seq 347 index 354 — pre-existing, benign)
- Kernel binary pre-round-9 (mtime 2026-04-18 00:12) — no sweep loop. Rebuild pending if sweep-on-hp-laptop matters; for now hp-laptop runs v3.12 validator + HTTP/MCP surface only
- Sessions at this kernel: `session:hp-laptop.primary` (birth, WF19-LINKed) + `session:sam.claude-code-hp-laptop` + `session:sam.claude-code-hp-z440` (both persisted without WF19 binding) + the historical `.t164/.t167/.t168` nodes
- Grammar_fragments at this kernel: 23 total; 5 now `status=merged` (D19.2/D19.3/D19.4/D20.1/D20.2); 18 remaining `status=proposed` (including 4 D22.* that live only on Z440 — still unmirrored here)

### Open: D22.* proposals un-mirrored on hp-laptop

D22.1 session-has-purpose · D22.2 single-driver invariant · D22.3 attach/detach verbs · D22.4 kernel-birth-session pair were ADDed only on Z440 kernel. Mirroring them onto hp-laptop kernel is a later round's call — not urgent; doctrine is already in the shared note. Flagged for future.

### Claude skills scaffolded (T=170)

Two skills added under `~/.claude/skills/` — both triggered automatically from now on:

- **`moos-state-readback`** — 10-sec open-of-round dance: `git fetch` on ffs0 + moos-kernel, diff vs origin, running-state header read, kernel PID + port check, MCP `/healthz` ping, handoff-issue comment scan. Prevents the "local `git status` lies by omission" failure mode that cost T=170 an initial plan revision.
- **`moos-round-close`** — end-of-round checklist: running-state update (header + kernel block + new section + Key URNs), single atomic commit (HEREDOC-formatted), push, optional handoff-issue comment. Prevents partial closes.

These supplement the existing `moos-rewrite-envelope` skill (envelope-shape cheat sheet). Trio now covers open + rewrite + close. Also shared at `dev/claude-skills/` for any workstation to install via copy-to-`~/.claude/skills/`.

---

## T=170 round 10.6 — doctrine + S0 sketch + 5 v3.13-candidate fragments + tidy

Round 10.6 lands the "coat thing" conversation as three artifacts plus HG hydration plus a tidy:

### Artifacts

- **`dev/reference/research-archive/20260420-t170-functorial-semantics-explicit.md`** — names FS as the spine of mo:os; identifies 3 places it already lives (Fold, WF20 Promote⊣Express, v310-2-crosswalk three-views identity); applies the lens to federation (kernels as sites, sheaves over kernel-category, routing = stalk lookup, DNS = presheaf evaluation, free-set = signature colimit, lineage = spawned-by subcategory, Wolfram multiway = the unnamed coherence layer).
- **`dev/reference/research-archive/20260420-t170-s0-materialization.md`** — draft type specs for op_node / slot / yields / threading / weave as v3.13-candidate types. Not hydrated this round; sketch only.
- **`dev/reference/research-archive/20260420-t170-branching-strategy.md`** — branching question write-down (archived T=173). Answer: keep current pattern (one branch per kernel, PRs for coordination). Four candidate reconstructions listed in the note.

### Hydration — 5 v3.13 grammar_fragments ADDed (all status=proposed)

| URN suffix | Kind | Crystallises |
|---|---|---|
| `v313-1-functorial-semantics-spine` | wf_clause (stretch — true kind = doctrine; fragment_kind enum extension is itself a future proposal) | FS as the spine; unshipped halves = Express + CI-6 |
| `v313-2-kernel-operadic-signature` | type (S1) | Each kernel publishes `kernel_operadic_signature` with ontology_version + type_count + wf_count + signature_hash |
| `v313-3-kernel-lineage` | port | WF19-extension `spawned-by / spawned` on kernel; initial-kernel is root; tree-structured lineage |
| `v313-4-federation-presheaf` | wf_clause (stretch — doctrine) | Federation as sheaf over category of kernels; routing=stalk, DNS=presheaf evaluation, sheaf-violation → WF13 governance_proposal |
| `v313-5-diary` | type (S2) | `diary` type + canonical instance `urn:moos:diary:moos.main` (moos the dachshund, narrator) |

### Tidy

4 memory-snapshot files moved from `kb/research/` (top-level clutter) → `dev/reference/research-archive/`:
- `t169_memory_MEMORY.md`
- `t169_memory_project_moos.md`
- `t169_memory_project_prg_naming.md`
- `t169_memory_user_sam.md`

These captured the T=169 consolidated-memory moment; the live Claude MEMORY has moved on, and the snapshots are historical from here.

### Grammar_fragment census (hp-laptop kernel)

After round 10.5+10.6: 28 total (was 23 pre-T=170).
- `status=merged`: 5 (D19.2/D19.3/D19.4/D20.1/D20.2 — the v3.12 ceremony)
- `status=proposed`: 23 (18 pre-existing + 5 new v313-1..v313-5)

Z440 kernel's 4 D22.* proposals (D22.1..D22.4) still live only on Z440.

### Key URNs added this round

```
urn:moos:grammar_fragment:v313-1-functorial-semantics-spine  (status=proposed, doctrine-via-wf_clause-stretch)
urn:moos:grammar_fragment:v313-2-kernel-operadic-signature   (status=proposed, type)
urn:moos:grammar_fragment:v313-3-kernel-lineage              (status=proposed, port)
urn:moos:grammar_fragment:v313-4-federation-presheaf         (status=proposed, doctrine-via-wf_clause-stretch)
urn:moos:grammar_fragment:v313-5-diary                       (status=proposed, type)
```

### Explicit next steps, deferred

- **Promote these 5** — needs a second WF20 ceremony (admin cap, doctrine review, batch MUTATE chain). Should rollup with Z440's D22.1..D22.4 when z440-claude completes Round 11.
- **Extend fragment_kind enum to include 'doctrine'** — itself a candidate proposal; meta-recursive. Track for v3.14.
- **S0 type specs (op_node/slot/yields/threading/weave)** — sketch only; hydration in a later round.
- **FS-spine + federation-presheaf mirrored onto Z440** — z440-claude's call when they pull.
- **Express adjoint implementation** — pattern-mining algorithm from S2 → S4 overlays. Not code-ready; design pending.

---

## T=171 round 10.7 — Antigravity moos-diary doctrine & alignment

**Date:** April 21, 2026 (~09:30 CEST)
Antigravity IDE ingestion of the moos-diary multimodal vision. Corrected `session` ontology against Guido's strict S4 parameterization rules (no host conflation, stripped unauthorized `WF22`/`WF18` syntax). Drafted `kb/moos-diary/t171.md` establishing the dachshund's 1-year anniversary of watching Sam struggle. `z440-claude` handles Z440 kernel restart and Round 11 implementation next.

---

## MVP delivery — spec-in-HG (projected T=169, 2026-04-19 ~15:00)

Round-10 close-out projection: the 6-gate path to MVP lives in the HG as time-dependent programs + t_hooks + calendar_events + a dedicated session. Each gate is a `program` node with `target_t` + a `t_hook` firing at that T that MUTATEs the program status → checkpoint on arrival. Each gate also has a `calendar_event` as IRL-time anchor. `sam.mvp-delivery` session pins them operationally (scope-via-pins pending loader extension per round 11 G1).

Purpose: `urn:moos:purpose:sam.mvp-sovereign-knowledge-os` — *"Demo-able sovereign knowledge OS: local kernel stable, one real knowledge channel flowing in, HDC reasoning over it, live moos-viz visualization, auditable log-is-truth, twin federation via mtdc. A non-technical friend can sit in front of one screen and see: your data, your graph, your AI, no cloud. Anchored at T=190 (2026-05-10)."*

### Gate map

| Gate | Program URN | T | Wall-clock | Status | Dependencies |
|---|---|---|---|---|---|
| parent | `program:sam.mvp-delivery` | 190 | 2026-05-10 | active | composes G1–G6 |
| G1 session layer | `program:sam.mvp-g1-session-layer` | 173 | 2026-04-23 | active | scheduled-after `round10-session-generalization` |
| G2 approver reactor | `program:sam.mvp-g2-approver-reactor` | 176 | 2026-04-26 | draft | after G1 (firing_state needs session infra) |
| G3 first channel | `program:sam.mvp-g3-first-channel` | 180 | 2026-04-30 | draft | after G2 (real-data flow needs approver) |
| G4 moos-viz live | `program:sam.mvp-g4-moos-viz-live` | 182 | 2026-05-02 | draft | parallel with G3 (reads state independent of data) |
| G5 HDC query demo | `program:sam.mvp-g5-hdc-query-demo` | 185 | 2026-05-05 | draft | after G3 (needs data to score) |
| G6 twin-deploy | `program:sam.mvp-g6-twin-deploy` | 190 | 2026-05-10 | draft | after T=187 delivery-window-opens + G1-G5 |

### Dependency sketch

```
round10-session-generalization (done) ─scheduled-after→ G1 (session layer code)
                                                         │
                                                         ▼
                                                        G2 (approver reactor)
                                                         │
                                       ┌─────────────────┴─────────────────┐
                                       ▼                                   ▼
                                      G3 (first channel)               G4 (moos-viz live)
                                       │
                                       ▼
                                      G5 (HDC query demo)
                                       │                  T=187 delivery-window-opens
                                       ▼                  │
                                      G6 (twin-deploy mtdc) ◀─ delivery-window
                                       │
                                       ▼
                                      MVP close (T=190)
```

### t_hook map

Each gate has a `fires_at` t_hook (predicate `{kind: fires_at, t: <target_t>}`, react_template MUTATE program.status → checkpoint, firing_state=pending). Once the v3.11 sweep tick crosses T=173/176/180/182/185/190, hooks auto-fire proposing checkpoint MUTATEs. Approver reactor (G2 itself!) is the thing that actually applies them — bootstrap dependency: G1+G2 must land before later hooks can auto-progress status. Until G2, gates advance via manual sam-authored MUTATEs.

### Calendar anchor map

Six calendar_event nodes bridge kernel-T to wall-clock:

| URN | Date | t_day | Anchor |
|---|---|---|---|
| `cal:2026-04-23.mvp-g1` | 2026-04-23 | 173 | G1 target |
| `cal:2026-04-26.mvp-g2` | 2026-04-26 | 176 | G2 target |
| `cal:2026-04-30.mvp-g3` | 2026-04-30 | 180 | G3 target |
| `cal:2026-05-02.mvp-g4` | 2026-05-02 | 182 | G4 target |
| `cal:2026-05-05.mvp-g5` | 2026-05-05 | 185 | G5 target |
| `cal:2026-05-10.mvp-close` | 2026-05-10 | 190 | MVP close + G6 target |

Color: all purple (PRG-tracked, per `calendar_event` color_label convention).

### Session anchor

`urn:moos:session:sam.mvp-delivery` — sam's persistent MVP workspace, WF19 opens-on kernel:hp-z440.primary. Currently occupant-less at the HG level (has-occupant LINKs blocked on loader extension); operationally driven by whichever agent is working on the MVP at the moment. Pins pending until D19.3 pins-urn LINK support lands in round 11 G1 (loader awareness).

### Existing Z440 infrastructure MVP can reuse (posted by antigravity.hp-z440 earlier T=169)

While scoping MVP gates I realized Z440's HG was already populated with several MVP-relevant nodes — antigravity on Z440 posted them in a 20-rewrite burst at log_seq 161-180. Not reinventing; MVP gates reference these:

- **9 source_feeds already configured**: `feed:arxiv.cs-ai`, `feed:arxiv.physics`, `feed:yt.mlst`, `feed:yt.discover-ai`, `feed:paperswithcode`, `feed:lmsys-arena`, `feed:web.lmsys-arena`, `feed:web.paperswithcode`, `feed:ifrs.news`. G3 = pick one, flip to active — default `arxiv.cs-ai` (clean RSS, public, no auth). MVP-G3 scope MUTATEd to reference these.
- **Ingest pipeline already wired**: `watcher:raw-ki-claim-extract` + `reactor:emit-claim-extract-task`. The ingest → raw knowledge_item ADD → claim-extract reactor chain is present. G3 likely just activates the fetch-side (HTTP poll / RSS parse).
- **2 classification_schemes with tag LINKs**: `scheme:arxiv` (tags: cs-ai, cs-lg, math-ct, physics-hep-th, q-bio), `scheme:ifrs` (tags: 9, 15, 16, 17). G5 HDC scoring has ready-made classification frames for cos-similarity. MVP-G5 scope MUTATEd to reference scheme:arxiv.
- **5 git_issues**: ffs0#13/14/15 + moos-config#5/6. Pre-existing project-board wiring — MVP gates can add more as round-11+ PRs open. Pattern is `git_issue` type nodes mirroring GitHub issue numbers.
- **Watcher/reactor pairs also present**: `watcher:tool.verify_baseline` + `reactor:tool.verify_baseline`. Test-harness wiring; outside MVP scope but confirms the reactive-engine pattern is exercised on Z440.

The 4 federation kernel nodes (hp-z440.primary, lola, menno, moos) all exist on Z440; kernels 1-3 are dormant. MVP-G6 twin-deploy targets the mtdc CF tunnel (not these federation shards).

Actor distribution on Z440 kernel log (log_seq 1-223 at round-10 close):
- `user:sam` — 191 rewrites (my round-10 + mvp + pre-existing)
- `agent:antigravity.hp-z440` — 20 rewrites (the infrastructure burst above)
- `user:lola`, `user:menno`, `user:moos` — 4 each (federation-user placeholders)
- `$actor` — 2 (template-stub debris; harmless)

Claude-code.hp-laptop has NOT posted directly to Z440 kernel (sovereign-kernels per §M9; hp-laptop's work lives on hp-laptop kernel). The `kb/moos_from_HPLAP.jsonl` file (committed to ffs0) is hp-laptop's log snapshot for reference.

### Why project the MVP plan into HG

- **Queryability**: `GET /t-cone?session=sam.mvp-delivery&at=185` tells us at T=185 which gates fired, which are still open, which are blocked.
- **MUTATE-ability**: as reality shifts (target slips, dependencies re-order), `MUTATE target_t` on any program; log records the revision. No spreadsheet, no planning tool — the HG IS the plan.
- **Auditability**: log-is-truth over every adjustment. Future-sam can run `fold?to=T=185` and see exactly what the plan looked like at that point.
- **Composability**: post-MVP programs can `depends-on` `mvp-delivery` directly. The MVP is a node like any other — it doesn't disappear once shipped; it becomes provenance for everything downstream.
- **Spec-realizer applied to itself**: the entire pattern sam articulated ("specs + incomplete data mapped over time") describes how to treat any idea. Doing it to the MVP plan is the test of the pattern's self-consistency.

---

## Key URNs

```
urn:moos:user:sam
urn:moos:kernel:hp-laptop.primary
urn:moos:kernel:hp-z440.primary
urn:moos:program:sam.t187-kernel-proper
urn:moos:program:sam.t164-room-tying  (completed)
urn:moos:program:sam.ontology-publication-v3.9  (v3.9 publication carrier)

# Round 4 merged sub-programs (by-monitoring-scope names, no t-ref prefix)
urn:moos:program:sam.session-occupancy
urn:moos:program:sam.session-timeline
urn:moos:program:sam.session-view
urn:moos:program:sam.session-tools
urn:moos:program:sam.hook-predicates
urn:moos:program:sam.ontology-publication-prg
urn:moos:program:sam.external-op

urn:moos:purpose:sam.t164-tie-the-room-together
urn:moos:agent:claude-code.hp-laptop
urn:moos:agent:claude-code.hp-z440

# T=170 round 10.5 — hp-laptop retrofit
urn:moos:session:hp-laptop.primary   (birth-session, WF19 opens-on kernel:hp-laptop.primary)
urn:moos:session:sam.claude-code-hp-laptop   (persisted, WF19 UNLINKed T=170)
urn:moos:session:sam.claude-code-hp-z440     (persisted, WF19 UNLINKed T=170)

# Round 5 demo nodes (v3.9 types in use)
urn:moos:view_filter:sam.important-programs
urn:moos:view_filter:sam.t168-open-deliverables
urn:moos:agent:sam.claude-code-desktop  (placeholder future occupant, §M19)
urn:moos:grammar_fragment:d19-1-session-has-occupant  (status=proposed)
urn:moos:grammar_fragment:d20-2-agent-invocation-protocol  (status=proposed)
urn:moos:grammar_fragment:d14-1-time-predicates  (status=proposed)

# Round 6 v3.10 grammar_fragment proposals (all status=proposed)
urn:moos:grammar_fragment:v310-1-port-binding
urn:moos:grammar_fragment:v310-2-crosswalk
urn:moos:grammar_fragment:v310-3-fiber-completeness
urn:moos:grammar_fragment:v310-4-branchial-ricci
urn:moos:grammar_fragment:v310-5-cascade-spectral-bound
urn:moos:grammar_fragment:v310-6-sheaf-laplacian-inconsistency

# Round 7 §M18..§M20 backlog proposals (all status=proposed)
urn:moos:grammar_fragment:d19-2-session-view-prefs
urn:moos:grammar_fragment:d19-3-session-pins-urn
urn:moos:grammar_fragment:d19-4-session-filtered-by
urn:moos:grammar_fragment:d20-1-session-mounts-tool
urn:moos:grammar_fragment:d20-3-agent-runs-in-harness
urn:moos:grammar_fragment:d20-4-agent-constructs-agent

# Round 7 v3.10 deferred-type proposals (all status=proposed)
urn:moos:grammar_fragment:v310-7-benchmark
urn:moos:grammar_fragment:v310-8-evaluation
urn:moos:grammar_fragment:v310-9-dataset
urn:moos:grammar_fragment:v310-10-dsl

# Round 8 successor programs (T=187 as delivery anchor)
urn:moos:program:sam.v310-delivery       (starts_t=220, target_t=240, status=draft)
urn:moos:program:sam.wiring-proposer     (starts_t=240, target_t=250, status=inert)

# Round 8 delivery-clock t_hooks (10)
urn:moos:t_hook:sam.t187.delivery-opens          (fires_at=187)
urn:moos:t_hook:sam.t187.delivery-closes         (closes_at=220)
urn:moos:t_hook:sam.t187.checkpoint.session-chrono-t     (fires_at=195)
urn:moos:t_hook:sam.t187.checkpoint.system-instruction   (fires_at=200)
urn:moos:t_hook:sam.t187.checkpoint.strata-enforcement   (fires_at=205)
urn:moos:t_hook:sam.t187.checkpoint.fold-endpoint        (fires_at=210)
urn:moos:t_hook:sam.t187.checkpoint.http3-quic           (fires_at=215)
urn:moos:t_hook:sam.t187.checkpoint.twin-deploy-mtdc     (fires_at=220)
urn:moos:t_hook:sam.v310-delivery.startable      (all_of fires_at=220, after_urn kernel-proper=completed)
urn:moos:t_hook:sam.wiring-proposer.startable    (all_of fires_at=240, after_urn kernel-proper=completed, after_urn v310-delivery=completed)

# Round 8 external_op IRL gates (3 + 1 test)
urn:moos:external_op:sam.mtdc-kernel-start           (deadline_t=187)
urn:moos:external_op:sam.cf-tunnel-api-mtdc          (deadline_t=187)
urn:moos:external_op:sam.ontology-bootstrap-mtdc     (deadline_t=220)
urn:moos:external_op:sam.test                        (status=cancelled — HTTP-API verification artifact)

# Round 8 grammar_fragment proposals (all status=proposed)
urn:moos:grammar_fragment:v310-11-ontology-publication
urn:moos:grammar_fragment:v310-12-grammar-fragment-enrichment
urn:moos:grammar_fragment:v310-13-purpose-arity2
urn:moos:grammar_fragment:v310-14-startable-status

# Live sessions on hp-laptop kernel (pre-round-10 model; mis-classified under the v3.12 kernel-bound model — scheduled for retire/replace in a hp-laptop-side conversation)
urn:moos:session:sam.claude-code-hp-laptop  (WF19-LINKed, seat_role=occupier)
urn:moos:session:sam.claude-code-hp-z440    (WF19-LINKed, seat_role=observer)

# Round 10 — corrected session nodes (Z440 kernel only; hp-laptop kernel gets its own in a separate conversation)
urn:moos:session:hp-z440.primary                      (birth-session; WF19 opens-on kernel:hp-z440.primary)
urn:moos:session:sam.round10-session-generalization   (round-10 workspace; WF19 opens-on kernel:hp-z440.primary)

# Round 10 new nodes
urn:moos:program:sam.round10-session-generalization  (starts_t=169, target_t=175, status=active)
urn:moos:purpose:sam.coherent-session-doctrine       (generic intent, reusable across rounds)
urn:moos:t_hook:sam.round10-session-generalization.target  (fires_at=175, firing_state=pending)

# Round 10 D22 grammar_fragment proposals (all status=proposed on Z440 kernel)
urn:moos:grammar_fragment:d22-1-session-has-purpose
urn:moos:grammar_fragment:d22-2-session-single-driver-invariant
urn:moos:grammar_fragment:d22-3-session-attach-detach
urn:moos:grammar_fragment:d22-4-kernel-birth-session-pair

# Archived sessions (provenance; no WF19 LINK)
urn:moos:session:sam.claude-code-hp-laptop.t164
urn:moos:session:sam.claude-code-hp-laptop.t167
urn:moos:session:sam.claude-code-hp-z440.t168
```

---

## Architecture

```
hp-laptop:  kernel :8000 | MCP :8080
            CF tunnel: kernel.my-tiny-data-collider.nl (SSE) | api.my-tiny-data-collider.nl (REST)
Z440:       kernel :8000–:8003 | router :9000 (federation, WF16)
```

Agents per workstation: `claude-code` · `vscode-codex` · `antigravity`
Repos: `moos-kernel` (Go, public) · `moos-router` · `ffs0` (this workspace, private)

### moos-router (feat/type-map-routing — merged PR #2)
Type routing via `--type-map type_id=url` checked before URN-prefix shard rules.
Companion: `dev/scripts/generate_type_map.py` emits flags from ontology.json strata.

---

## Codex (archived)

`dev/reference/research-archive/20260408-foundation-t158.md` — foundations, nomenclature,
node types, two-presheaf model, functorial semantics, federation architecture.
Active type system: `kb/superset/ontology.json` supersedes for formal types.
