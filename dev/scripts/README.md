# Scripts

Operational tools for testing, validation, and delegation.

## validation/

Graph and phase validation — state checking, schema debugging.

## ops/

Operational tools — delegation, checkpointing, graph audits.

## Loose files

- `debug_schema.py` — debug KB schema
- `export_t200plus_projection.jl` — folded-state DOT/SVG exporter for T200+ graph lenses.
- `graph_artifact_projection.jl` — dry folded-state graph artifact analyzer for newly added HG frames. It writes JSON/Markdown engineering summaries and pairs with the DOT/SVG exporter for visualization.
- `google_calendar_projection.jl` — F-direction planning adapter from folded HG state to Google Calendar event payloads. It writes a reviewable JSON plan and does not perform OAuth or cloud writes.
- `google_calendar_writer.jl` — explicit OAuth boundary writer for applying an approved Google Calendar projection plan. Defaults to dry-run/check modes; real writes require local gitignored OAuth files and `--mode write`.
- `session_context_projection.jl` — F-direction planning adapter from folded HG state to a session context pack for IDE, agent, or harness handoff. It writes reviewable JSON and Markdown, and does not edit IDE config or emit rewrites.

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

The preset roots at `derivation:guido.t187-session-occasion-implementation-frame` and emits `tmp/projections/session_occasion_frame.dot` plus SVG when Graphviz is available.

### Graph Artifact Engineering Projection

```powershell
& 'C:\Users\maass\AppData\Local\Programs\Julia-1.12.6\bin\julia.exe' dev\scripts\graph_artifact_projection.jl
```

The adapter emits `tmp/projections/graph_artifacts/session_occasion_engineering.json` and `.md`. It defaults to the T187 session-occasion artifact set: the derivation, session lingo instruction, proposed occasion grammar fragment, affordance-pack pattern, and Z440 continuity workflow. The output includes root coverage, so explicitly requested roots that have no selected relations are visible as disconnected instead of looking topologically proven. Use `--root-urns`, `--radius`, `--wfs`, `--ports`, `--types`, and `--match` to analyze a different graph frame.

### Session Context Projection Pack

```powershell
& 'C:\Users\maass\AppData\Local\Programs\Julia-1.12.6\bin\julia.exe' dev\scripts\session_context_projection.jl
```

The adapter emits `tmp/projections/session_context/current_session.json` and `tmp/projections/session_context/current_session.md`. This is a dry F-direction pack: HG stays authoritative, and the output can be passed to VS Code, another agent, or a harness as a session header. Use `--session-urn`, `--actor-urn`, `--focus`, `--skill-limit`, `--extensions-dir`, `--extension-limit`, and `--mcp-configs` to narrow the occasion and the projected affordance pack.

By default it scans canonical mo:os skills, local VS Code extensions, and `.vscode/mcp.json.example`. MCP secrets are not copied into the output; the pack records server names, transport type, endpoints/commands, and header/env key names only.

### Google Calendar Projection Plan

```powershell
& 'C:\Users\maass\AppData\Local\Programs\Julia-1.12.6\bin\julia.exe' dev\scripts\google_calendar_projection.jl
```

The adapter emits `tmp/projections/google_calendar_projection_plan.json`. This is a dry F-direction plan only: HG stays the source of truth, and no Google OAuth or Calendar API write is attempted.

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
