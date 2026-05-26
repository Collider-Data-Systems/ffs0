# Scripts

Operational tools for testing, validation, and delegation.

The current active projection lane is Julia-first. Older one-shot Python emitters from T164/T167/T161/v3.15 have been moved to `dev/reference/research-archive/scripts/legacy-emitters/` so they remain available as provenance without looking like current operators.

## validation/

Graph and phase validation — state checking, schema debugging.

## ops/

Operational tools — delegation, checkpointing, graph audits.

## projections/

Projection-lane orchestration entrypoints. These scripts run multiple adapters together and write organized local artifacts under `tmp/projections/`.

The operator manual for the generated filesystem, dashboard, script stack, typed data flow, gates, and skills is `projections/session-pipeline-operator-manual.md`.

## Loose files

- `export_t200plus_projection.jl` — folded-state DOT/SVG exporter for T200+ graph lenses.
- `generate_type_map.py` — active utility for generating moos-router type-map flags from `kb/superset/ontology.json`.
- `graph_artifact_projection.jl` — dry folded-state graph artifact analyzer for newly added HG frames. It writes JSON/Markdown engineering summaries and pairs with the DOT/SVG exporter for visualization.
- `calendar_time_fabric_projection.jl` — F-direction planner that turns a recent graph artifact into Google Calendar payloads, mapping HG identity, T-day anchor, node type/status, and relation context into visible Calendar events. When locked to a writer result, it also reads live folded Calendar observations to preserve applied event dates across T-day rollover.
- `t189_t200_recommendation_projection.jl` — dry planner that turns the five T189 recommendations into candidate HG nodes/relations and T200+ recommendation artifacts without applying rewrites.
- `t189_recommendation_reconciliation.jl` — dry reconciliation adapter that compares the T189/T200 recommendation plan to folded HG state and reports grouped rows, Calendar event rows, session pins, WF07 Calendar source anchors, and deferred rows separately.
- `surface_context_atlas.jl` — generated operator/agent atlas that explains the live JSON API, JSONL log, Git repos, Google Calendar projection, dashboard, visual lenses, type/relation/program surface, known HG anchors, and pending moves in one JSON/Markdown artifact.
- `t193_workstation_inventory.jl` — dry workstation/persona inventory for T193 three-workstation planning. It folds the local JSONL log, compares it with `dev/config/moos-federation.topology.json`, and emits a JSON/Markdown packet that treats hp-laptop, HP ProDesk, and offline Z440 together without applying rewrites.
- `google_calendar_projection.jl` — F-direction planning adapter from folded HG state to Google Calendar event payloads. It writes a reviewable JSON plan and does not perform OAuth or cloud writes.
- `google_calendar_writer.jl` — explicit OAuth boundary writer for applying an approved Google Calendar projection plan. Defaults to dry-run/check modes; real writes require local gitignored OAuth files and `--mode write`.
- `session_context_projection.jl` — F-direction planning adapter from folded HG state to a session context pack for IDE, agent, or harness handoff. It writes reviewable JSON and Markdown, and does not edit IDE config or emit rewrites.
- `session_pipeline_mvp_gate.jl` — dry MVP gate report for the Keep-note/session/visual-projection lane. It checks live G-ingest evidence, F session handoff output, graph-artifact analysis, static visuals, lens controls, and known gaps.
- `keep_t195_t206_ingest_stage.jl` — dry G-direction stager for T195-T206 Google Keep/loose-thought material. It reads a local Takeout ZIP/folder, manual export file, or API-normalized JSON folder, filters the T-window, marks duplicate/undated notes, classifies hardware/software/HG lifecycle themes, and writes review-only candidate KI/claim/derivation/program topology without emitting rewrites.
- `google_keep_fetch.jl` — explicit official Google Keep API/OAuth boundary. It checks local credential readiness, opens the loopback consent URL, fetches notes when Google permits the Keep scope, writes normalized local JSON, and feeds the same dry stager.
- `t206_keep_mvp_delivery.jl` — narrow T206 MVP carrier planner for the Google Keep API/S0 staging boundary. It emits only new-needed program/derivation/KI/claim/external_op nodes and valid WF12/WF18/WF19/WF21 links; raw Keep-note content remains deferred.

## Python Status

- Keep `generate_type_map.py`: still relevant for router/type-map work.
- Keep `validation/*.py` and their `tests/test_*.py`: these are importable baseline/hydration checks with tests.
- Historical Python emitters are archived under `dev/reference/research-archive/scripts/legacy-emitters/` and should not be used as current write paths.

## Projection Artifact Layout

Session-pipeline artifacts are grouped under the gitignored local directory `tmp/projections/session_pipeline/`:

- `session_context/` — current session context pack JSON/Markdown.
- `graph_artifacts/` — graph engineering JSON/Markdown for the selected lens.
- `calendar/` — Calendar time-fabric projection plans, reports, and explicit writer results.
- `recommendations/` — dry candidate HG plans for T189/T200 continuation work.
- `atlas/` — generated JSON/Markdown surface context atlas for human and agent orientation across HG, files, Git, Calendar, dashboard, and visual surfaces.
- `visual/` — DOT/SVG static visual renderings.
- `mvp/` — generated MVP gate JSON/Markdown.
- `index.html` — human-readable control surface for the lane.

Older projection files may still exist directly under `tmp/projections/`; treat them as prior materializations unless regenerated by the current runner.

## T193 HP ProDesk Bootstrap

For workstation bring-up or refresh, select `.github/agents/moos-workstation-operator.agent.md` in the VS Code Agents window and run `.github/prompts/agent-workstation-open.prompt.md`. The prompt tells the workstation-side agent to read live running state, snapshot the three repos, check local `/healthz`, inspect MCP config without printing secrets, and report before topology edits or HG applies.

### Session Pipeline Control Surface

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File dev\scripts\projections\run-session-pipeline.ps1
```

The runner regenerates the current Keep-note/session/visual lane and writes `tmp/projections/session_pipeline/index.html`. The HTML page is the MVP operator surface: it shows the G-ingest/F-session/F-visual stages, pass/warn/fail gates, runtime metadata, artifact links, the static visual lens, Calendar time-fabric artifacts, recommendation HG artifacts, the surface context atlas, and the next actions for warning gates. It is generated locally and does not emit rewrites. When a Calendar writer result exists, the runner locks the Calendar time-fabric planner to the written source URNs and live folded Calendar observations so widened visual context and T-day rollover remain inspectable without creating new Calendar G-readback candidates.

### T206 Keep/Loose-Thought Ingest Stage

Harness-neutral entrypoint for any agent surface:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File dev\scripts\ops\Invoke-KeepIngestHarness.ps1 -Mode Check
powershell -NoProfile -ExecutionPolicy Bypass -File dev\scripts\ops\Invoke-KeepIngestHarness.ps1 -Mode Stage -SourcePath scratch\keep\t195-t206 -RunPipeline
```

For a Google Takeout ZIP, pass the archive directly:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File dev\scripts\ops\Invoke-KeepIngestHarness.ps1 -Mode Stage -SourcePath scratch\keep\t195-t206\takeout.zip -RunPipeline
```

For the Google Keep web UI, copy selected note text to the clipboard and run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File dev\scripts\ops\Invoke-KeepIngestHarness.ps1 -Mode ClipboardStage -RunPipeline
```

The same contract is captured as `.github/prompts/keep-ingest-any-harness.prompt.md` so VS Code/Copilot, Claude Desktop, Antigravity, Cursor, or a terminal agent can use the same source modes and review boundary.

Proper affordance map for this lane:

- VS Code prompt agent mode: `.github/agents/moos-workstation-operator.agent.md` via `.github/prompts/keep-ingest-any-harness.prompt.md`.
- Runner modes: `Check`, `Stage`, `ClipboardStage`, `ApiAuthListen`, `ApiFetch`, `Pipeline`.
- Skills: `moos-state-readback`, `moos-workspace-ingest`, `moos-session-context-projection`, `moos-tooling-dx`, `moos-rewrite-envelope`, and `moos-running-state-validator` when durable state docs are touched.
- HG relations after review: `WF12 provides-kb/kb-source`, `WF18 composes/composed-by`, `WF19 pins-urn/pinned-by-session`, and `WF21 causes/caused-by`; `WF07 anchors/anchor` is only for explicit reviewed Calendar source-anchor apply batches after the runtime has loaded the repaired operad declaration.
- Existing anchors to reuse: `session:sam.governance`, `channel:google.keep.sam`, `program:sam.t206.keep-api-mvp-delivery`, `ki:gdrive.t206-keep-api-mvp-status`, and `external_op:sam.t206-google-keep-oauth-scope-approval`. `Check` mode reports these anchors and the current session/MVP/T206 graph projections for another harness.

Apply the reviewed T206 MVP carrier after the live readback says hp-laptop primary is healthy:

```powershell
& 'C:\Users\maass\AppData\Local\Programs\Julia-1.12.6\bin\julia.exe' dev\scripts\t206_keep_mvp_delivery.jl
```

The planner writes `tmp/projections/session_pipeline/keep_t206/t206_keep_mvp_delivery.{json,md}` and `dev/scripts/ops/t206-keep-api-mvp-delivery.program.json`. It is intentionally not a raw Keep-note import: it records the implemented API/fetch/staging boundary, the Google OAuth `invalid_scope` blocker, the staged theme buckets, and the WF07 deferral as graph carriers so dashboard and Calendar projections can move while the source-note fetch remains blocked.

```powershell
& 'C:\Users\maass\AppData\Local\Programs\Julia-1.12.6\bin\julia.exe' dev\scripts\keep_t195_t206_ingest_stage.jl --source scratch\keep\t195-t206
& 'C:\Users\maass\AppData\Local\Programs\Julia-1.12.6\bin\julia.exe' dev\scripts\keep_t195_t206_ingest_stage.jl --source scratch\keep\t195-t206\takeout.zip
```

The stager writes `tmp/projections/session_pipeline/keep_t206/keep_t195_t206_stage.json` and `.md`. It is intentionally dry: Google Takeout ZIP/folder/manual-export material becomes a local review artifact first, then candidate HG nodes/relations. It keeps `apply_ready=false` until Sam approves the source structure and a separate `dev/scripts/ops/` apply program is generated. ZIP members get stable archive source URLs such as `file://...takeout.zip#Takeout/Keep/<note>.json`. The T207 local source scan only found the old T187 text export under `scratch\keep`; it selected 0 T195-T206 notes and no HG apply was valid.

Google Keep API fetch is an explicit OAuth boundary, mirroring the Calendar writer. Store local OAuth files under `secrets/`, then run:

```powershell
& 'C:\Users\maass\AppData\Local\Programs\Julia-1.12.6\bin\julia.exe' dev\scripts\google_keep_fetch.jl --mode check
& 'C:\Users\maass\AppData\Local\Programs\Julia-1.12.6\bin\julia.exe' dev\scripts\google_keep_fetch.jl --mode auth-listen
& 'C:\Users\maass\AppData\Local\Programs\Julia-1.12.6\bin\julia.exe' dev\scripts\google_keep_fetch.jl --mode fetch
```

The fetcher uses the Google Keep readonly scope, writes normalized API notes under `scratch/keep/t195-t206/api/notes/`, stores raw API responses beside them, and by default regenerates the same dry stage report. It does not emit HG rewrites and does not print token or client-secret values.

Keep auth uses Google's v2 OAuth endpoint. If Google shows `Error 400: invalid_scope` with request details containing `scope=https://www.googleapis.com/auth/keep.readonly`, the local script path is working: the scope exists in Google's Keep discovery document, but the OAuth client/project is not allowed to present it yet. This was rechecked at T207 using `Invoke-KeepIngestHarness.ps1 -Mode ApiAuthListen -UseCalendarOAuthClient -OpenBrowser`; Google still rejected the scope before any token could be written.

Fix that in Google Cloud Console before retrying the API fetch:

1. Enable the Google Keep API in the project that owns the OAuth client.
2. Add `https://www.googleapis.com/auth/keep.readonly` to the OAuth consent screen scopes.
3. Add Sam's Google account as a test user, or publish/verify the app if Google requires it for this restricted scope.
4. Prefer a dedicated Desktop OAuth client JSON at `secrets/google_keep_oauth_client.json`; reusing the Calendar client only works after that same Cloud project is configured for Keep.
5. Rerun `--mode auth-listen`, then `--mode fetch` after `secrets/google_keep_token.json` is written.

If there is no `secrets/google_keep_oauth_client.json` yet but the Calendar OAuth client exists, reuse the same local OAuth app and write a separate Keep token:

```powershell
& 'C:\Users\maass\AppData\Local\Programs\Julia-1.12.6\bin\julia.exe' dev\scripts\google_keep_fetch.jl --mode auth-listen --credentials secrets\google_calendar_oauth_client.json --token secrets\google_keep_token.json --open-browser true
& 'C:\Users\maass\AppData\Local\Programs\Julia-1.12.6\bin\julia.exe' dev\scripts\google_keep_fetch.jl --mode fetch --credentials secrets\google_calendar_oauth_client.json --token secrets\google_keep_token.json
```

### T200+ Projection Exporter

Default visual lens:

```powershell
& 'C:\Users\maass\AppData\Local\Programs\Julia-1.12.6\bin\julia.exe' dev\scripts\export_t200plus_projection.jl
```

Temporal/calendar lens:

```powershell
$env:MOOS_PROJECTION_PRESET='temporal-calendar'
& 'C:\Users\maass\AppData\Local\Programs\Julia-1.12.6\bin\julia.exe' dev\scripts\export_t200plus_projection.jl
```

The preset can still be narrowed with `MOOS_PROJECTION_WFS`, `MOOS_PROJECTION_TYPES`, `MOOS_PROJECTION_PORTS`, `MOOS_PROJECTION_MATCH`, `MOOS_PROJECTION_ROOT`, and `MOOS_PROJECTION_OUT`.

Session-occasion implementation frame lens:

```powershell
$env:MOOS_PROJECTION_PRESET='session-occasion'
& 'C:\Users\maass\AppData\Local\Programs\Julia-1.12.6\bin\julia.exe' dev\scripts\export_t200plus_projection.jl
```

The preset roots at `derivation:guido.t187-session-occasion-implementation-frame` and emits `tmp/projections/session_pipeline/visual/session_occasion_frame.dot` plus SVG when Graphviz is available.

### Graph Artifact Engineering Projection

```powershell
& 'C:\Users\maass\AppData\Local\Programs\Julia-1.12.6\bin\julia.exe' dev\scripts\graph_artifact_projection.jl
```

The adapter emits `tmp/projections/session_pipeline/graph_artifacts/session_occasion_engineering.json` and `.md`. It defaults to the T187 session-occasion artifact set: the derivation, session lingo instruction, proposed occasion grammar fragment, affordance-pack pattern, and Z440 continuity workflow. The output includes root coverage, so explicitly requested roots that have no selected relations are visible as disconnected instead of looking topologically proven. Use `--root-urns`, `--radius`, `--wfs`, `--ports`, `--types`, and `--match` to analyze a different graph frame.

### Session Context Projection Pack

```powershell
& 'C:\Users\maass\AppData\Local\Programs\Julia-1.12.6\bin\julia.exe' dev\scripts\session_context_projection.jl
```

The adapter emits `tmp/projections/session_pipeline/session_context/current_session.json` and `tmp/projections/session_pipeline/session_context/current_session.md`. This is a dry F-direction pack: HG stays authoritative, and the output can be passed to VS Code, another agent, or a harness as a session header. Use `--session-urn`, `--actor-urn`, `--focus`, `--skill-limit`, `--extensions-dir`, `--extension-limit`, and `--mcp-configs` to narrow the occasion and the projected affordance pack.

By default it scans canonical mo:os skills, local VS Code extensions, and `.vscode/mcp.json.example`. MCP secrets are not copied into the output; the pack records server names, transport type, endpoints/commands, and header/env key names only.

### Session Pipeline MVP Gate

```powershell
& 'C:\Users\maass\AppData\Local\Programs\Julia-1.12.6\bin\julia.exe' dev\scripts\session_pipeline_mvp_gate.jl
```

The gate emits `tmp/projections/session_pipeline/mvp/session_pipeline_gate.json`, `.md`, and the HTML dashboard at `tmp/projections/session_pipeline/index.html`. It treats the current lane as a small CICD/functorial-semantics pipeline: G-ingest from Keep into HG, F-projection from folded state into session/agent/visual artifacts, Calendar time-fabric projection payloads, recommendation reconciliation, and visual lenses whose scope is roots plus WF/port/type/match filters. The report is allowed to return `warn` for known MVP gaps, such as disconnected forced roots under a deliberately narrow lens. Current session-occasion roots are connected through existing WF20, WF19, and WF07 topology; the gate exits nonzero only on `fail` gates.

### Surface Context Atlas

```powershell
& 'C:\Users\maass\AppData\Local\Programs\Julia-1.12.6\bin\julia.exe' dev\scripts\surface_context_atlas.jl --base-url http://localhost:8000
```

The atlas emits `tmp/projections/session_pipeline/atlas/surface_context_atlas.json` plus Markdown. It is the explanatory table of contents for the lane: what is authoritative JSON/JSONL/HG state, what is a local Git/dashboard/visual projection, what Google Calendar mirrors, which existing category/UI/application anchors are visible, and which pending moves are deliberately held for review.

### Google Calendar Projection Plan

```powershell
& 'C:\Users\maass\AppData\Local\Programs\Julia-1.12.6\bin\julia.exe' dev\scripts\google_calendar_projection.jl
```

The adapter emits `tmp/projections/google_calendar_projection_plan.json`. This is a dry F-direction plan only: HG stays the source of truth, and no Google OAuth or Calendar API write is attempted.

### Calendar Time-Fabric Projection

```powershell
& 'C:\Users\maass\AppData\Local\Programs\Julia-1.12.6\bin\julia.exe' dev\scripts\calendar_time_fabric_projection.jl
```

The adapter reads the current session graph artifact and emits `tmp/projections/session_pipeline/calendar/calendar_time_fabric_plan.json` plus a Markdown review report. It uses the same writer contract as the Google Calendar planner, but projects selected recent HG nodes as stable Calendar events with type-based color, URN/type/status metadata, T-day anchor, and relation context. Use `--lock-written-sources true --write-result-path <path> --base-url http://localhost:8000` after a Calendar writer run to keep the readback/HG recommendation lane scoped to events that were actually written and to preserve existing folded `calendar_event` observation dates across T-day rollover.

### T189/T200 Recommendation HG Projection

```powershell
& 'C:\Users\maass\AppData\Local\Programs\Julia-1.12.6\bin\julia.exe' dev\scripts\t189_t200_recommendation_projection.jl
```

The adapter reads the ontology plus the Calendar time-fabric plan/write result and emits `tmp/projections/session_pipeline/recommendations/t189_t200_recommendation_hg_plan.json` plus a Markdown report. It is planner-only: the output chooses a hybrid Calendar G-ingest shape, models the five T189 recommendations as candidate HG nodes/relations, and projects T200+ recommendations as node/relation work rather than applying them.

### T189 Recommendation Reconciliation

```powershell
& 'C:\Users\maass\AppData\Local\Programs\Julia-1.12.6\bin\julia.exe' dev\scripts\t189_recommendation_reconciliation.jl --base-url http://localhost:8000
```

The adapter compares the recommendation plan to folded HG state and emits `tmp/projections/session_pipeline/recommendations/t189_recommendation_reconciliation.json` plus Markdown. Current T189 semantics distinguish grouped purpose/program/view_filter/group rows, individual `calendar_event` nodes, WF19 session pins for those events, WF07 Calendar source anchors, and still-deferred rows.

### Google Calendar OAuth Writer

Local-only credential files live under `secrets/` and are gitignored:

- `secrets/google_calendar_oauth_client.json` — OAuth client JSON from Google Cloud Console.
- `secrets/google_calendar_token.json` — generated refresh/access token cache.

Check whether the local credential refs are present:

```powershell
& 'C:\Users\maass\AppData\Local\Programs\Julia-1.12.6\bin\julia.exe' dev\scripts\google_calendar_writer.jl --mode check
```

Generate the consent URL for first login:

```powershell
& 'C:\Users\maass\AppData\Local\Programs\Julia-1.12.6\bin\julia.exe' dev\scripts\google_calendar_writer.jl --mode auth-url
```

Or let the writer listen on the loopback redirect and capture the code automatically:

```powershell
& 'C:\Users\maass\AppData\Local\Programs\Julia-1.12.6\bin\julia.exe' dev\scripts\google_calendar_writer.jl --mode auth-listen
```

After signing in, exchange the returned `code` or full redirect URL for a local token file:

```powershell
& 'C:\Users\maass\AppData\Local\Programs\Julia-1.12.6\bin\julia.exe' dev\scripts\google_calendar_writer.jl --mode exchange-code --code '<redirect-url-or-code>'
```

Preview the write actions without touching Google Calendar:

```powershell
& 'C:\Users\maass\AppData\Local\Programs\Julia-1.12.6\bin\julia.exe' dev\scripts\google_calendar_writer.jl --mode dry-run
```

Apply the approved plan to Google Calendar:

```powershell
& 'C:\Users\maass\AppData\Local\Programs\Julia-1.12.6\bin\julia.exe' dev\scripts\google_calendar_writer.jl --mode write
```

The writer upserts by the private extended property `moos_projection_id`, so repeated runs update existing projected events instead of duplicating them.
