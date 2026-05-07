---
name: moos-session-context-projection
description: "Session-focused F-direction projection from HG into IDE, agent, or harness context packs. Use when making the current VS Code conversation stay aligned with the current session kernel, projecting session context to VS Code/Copilot/Claude Desktop/Cursor/agent harnesses, generating Julia session context plans, deciding which skills/prompts/tools/extensions/MCP servers should be mounted from a session purpose, or analyzing and visualizing newly added HG nodes. Trigger phrases: session context pack, purpose-colored occasion, affordance pack, VS Code projection, harness handoff, current session kernel, session-focused skills, VS Code extensions, MCP servers, visualize new graph nodes."
---

# moos-session-context-projection

Use this skill when the work is about turning the current folded HG state into a context artifact for an IDE conversation, another agent, or a harness. The core move is F-direction projection:

```text
HG folded state -> session context pack -> IDE / agent / harness surface
```

The pack is dry by default. It reads state, derives context, and writes reviewable artifacts. It does not mutate HG, edit IDE settings, or call external APIs.

## Lingo

- **Occasion**: the evaluated situation at a log prefix where kernel/place, session, occupant, purpose, scope, authority path, and available operations meet.
- **Session context pack**: the projected artifact for one occasion. It contains the session header, kernel place, occupant, purpose, scope roots, mounted tools, owners, and handoff prompt seed.
- **Affordance pack**: the skills/prompts/tools/workflows/extensions/MCP servers that follow from the session's purpose and scope. Current IDE skills are transitional projections of this pack; extensions and MCP servers are concrete IDE/harness affordances.
- **Writer**: a later explicit boundary step that takes an approved pack and installs or sends it somewhere. The first pass is planner-only.

## Current Planner

Run the Julia planner from the ffs0 repo root:

```powershell
& 'C:\Users\maass\AppData\Local\Programs\Julia-1.12.6\bin\julia.exe' dev\scripts\session_context_projection.jl
```

Default output:

- `tmp/projections/session_context/current_session.json`
- `tmp/projections/session_context/current_session.md`

Useful options:

```powershell
& 'C:\Users\maass\AppData\Local\Programs\Julia-1.12.6\bin\julia.exe' dev\scripts\session_context_projection.jl `
  --base-url http://localhost:8000 `
  --session-urn urn:moos:session:sam.governance `
  --actor-urn urn:moos:agent:claude-code.hp-laptop `
  --focus "session-focused VS Code projection and visual graph analysis" `
  --skill-limit 5 `
  --extension-limit 8 `
  --mcp-configs .vscode/mcp.json.example
```

The planner scans `dev/claude-skills`, the local VS Code extension directory, and configured MCP JSON files by default. MCP headers/env values are not copied into the pack; only server names, transport type, endpoint/command shape, and header/env key names are recorded.

## Workflow

1. Read `kb/superset/running-state.md` first and verify `/healthz`.
2. Generate the session context pack with the Julia planner.
3. Inspect the JSON or Markdown pack before using it as a prompt seed or handoff.
4. If a tool needs to consume it automatically, build a writer as a separate explicit boundary.
5. Reify durable results back into HG as a derivation, claim, pattern, workflow, or external_op result when the result matters beyond the current IDE session.

## Projection Targets

- **VS Code / Copilot**: use the Markdown handoff as the conversation seed and the JSON as machine-readable state.
- **Claude Desktop / Cursor / other IDEs**: pass the same pack as a session header before asking for rewrites or analysis.
- **Harnesses**: pass `handoff.session_header` so emitted envelopes carry the right actor and `session_urn`.
- **VS Code extensions**: use the ranked extension list as the concrete IDE affordance surface for this occasion.
- **MCP servers**: use the server list to decide which tool surfaces belong in the session, without leaking header or environment values.
- **Visual analysis**: pair this pack with `export_t200plus_projection.jl` for DOT/SVG and `graph_artifact_projection.jl` for engineering summaries rooted at the session, purpose, pattern, workflow, grammar_fragment, or a multi-root artifact set.

## Guardrails

- Keep planner and writer separate, like the Google Calendar projection lane.
- Prefer current HG state over hand-written IDE assumptions.
- Treat `opens-on` as topology metadata and emit-target as current receiving-kernel reality until twin sync lands.
- Treat extensions and MCP servers as projected affordances until they are reified as HG nodes or relations.
- Do not promote `occasion` into ontology from this skill alone; the current source of truth is `grammar_fragment:v317-1-occasion-type` until review and merge.

## Companion Skills

- `moos-state-readback` for round/session open health.
- `moos-tooling-dx` for IDE attach, MCP, and harness plumbing.
- `moos-rewrite-envelope` when a projected action becomes an actual rewrite batch.
- `moos-categorical-research` for the indexed/fibered reading of session-purpose affordances.
- `moos-running-state-validator` when the projection changes durable state documentation.
