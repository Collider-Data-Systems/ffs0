# Agent Protocol — mo:os

`state(t) = fold(log[0..t])`. Kernel graph = SOT. Everything else is seed or projection.

---

## The Triangle

```
Category Theory <----------> Hypergraph Rewriting (Wolfram)
       ^                              ^
       +---------- mo:os ------------+
                     ^
        Hypervector Computing (HDC/VSA)
```

Every design decision lives inside this triangle. Never treat any corner in isolation.

## Pipeline: KB > KER > HG > PRG

| Stage | What | Where |
|-------|------|-------|
| **KB** | Authored seeds (S0/S1) | `kb/instances/*.json`, `kb/superset/ontology.json` |
| **KER** | Fold: `state = fold(log)` | Kernel replay on boot — morphism-log.jsonl |
| **HG** | Live hypergraph (S2/S3) | `GET :8000/state` — 292+ nodes, 168+ wires |
| **PRG** | Task progression | `prg_task` nodes in graph — wired by dependency |

PRG is IN the graph. Tasks 034-037 are `prg_task` nodes with gate dependencies.
Sessions are `agent_session` nodes. Keep notes are `keep_note` nodes. All queryable.

## Agent Topology

```
Sam (Lead)
  |-- leadoff.md (rw) + Google Workspace (GCal, Gmail, Keep, Drive)
  |
Claude Code (Strategic Lead)
  |-- leadoff.md (rw), handoff.md (rw), testoff.md (rw)
  |-- Kernel MCP (:8080) — direct graph read/write
  |-- GitHub (gh CLI) — PRs as inter-agent messaging
  |
Claude Desktop (Inspect Tier)
  |-- leadoff.md (rw) — design, sources, papers, YouTube
  |-- Kernel MCP (:8080) — graph queries
  |
VS Code AI (Execution)
  |-- handoff.md (rw) — implements kernel code
  |
Antigraviti (UX Testing)
  |-- testoff.md (rw) — HTTP/browser tests
```

Star topology. No direct agent-to-agent. All routing through Claude Code + Sam.

## Session Protocol

### Start (every session)
1. Boot kernel: `go run ./cmd/moos --kb ... --hydrate`
2. `GET /healthz` — read graph state
3. Read `channels/leadoff.md` top entry — Sam's latest
4. `POST /morphisms` — ADD `agent_session` node:
   ```json
   {"type":"ADD","actor":"urn:moos:agent:claude-code",
    "add":{"urn":"urn:moos:session:YYYYMMDD-role","type_id":"agent_session",
    "payload":{"started_at":"...","agent":"...","kernel_state_at_start":{...}}}}
   ```
5. LINK session -> current PRG task via `out`/`in` ports

### During Session
- Key decisions -> MUTATE relevant `prg_task` node
- New Keep notes reviewed -> ADD `keep_note` nodes
- Calendar events -> ADD `calendar_event` nodes + LINK to prg_task

### End
- MUTATE session node: status complete, add summary
- Prepend summary to leadoff.md (S4 projection)
- Update `cfg/state/session-state.json`
- Push to remote

### Context Compaction Recovery
1. `GET /state` — full graph truth
2. Filter by `agent_session` type — find latest
3. Filter by `prg_task` type — find current gate
4. Continue from graph, not from memory

## Programs

**P1 — KB Hydration (triangle CI/CD):**
`Sam + Claude Code -> task -> direction in channels -> VS Code implements -> Antigraviti tests`

**P2 — Superset + Paper + Research:**
Sam + Claude Code only. Outputs feed P1 and P3 as KB updates.

**P3 — Research Pipeline:**
Claude Code posts `research-task` to handoff.md. VS Code harvests -> structured JSON -> `kb/reference/`.

## Sources (live via MCP in lead conversation)

| Source | MCP | Status |
|--------|-----|--------|
| Gmail | `gmail_*` tools | Live — 11k messages |
| Google Calendar | `gcal_*` tools | Live — temporal anchors |
| Google Drive | `google_drive_*` tools | Live — Collider docs |
| Kernel graph | `:8080` MCP (SSE) | Live — 5 tools |
| GitHub | `gh` CLI + PAT | Live — PRs, issues |

## Channels (S4 projections — not ground truth)

- `channels/leadoff.md` — Sam <-> Claude Code. Prepend, newest top.
- `channels/handoff.md` — Claude Code <-> VS Code AI.
- `channels/testoff.md` — Claude Code <-> Antigraviti.

**Format:** `### [YYYY-MM-DD HH:MM] Source -> type: subject`
**Types:** `complete` | `blocked` | `question` | `answer` | `direction` | `think` | `decide`
**Timestamps:** real wall-clock only — `date` or `Get-Date`

## Branch Strategy

| Kind | Pattern | Lifecycle |
|------|---------|-----------|
| **Hub** | `main` | Persistent — Sam's authority, merged production |
| **Instance** | `instance/<agent-name>` | Persistent — home for parallel Claude instances |
| **Feature** | `feature/NNN-name` | Ephemeral — task work, PR -> merge -> delete |

PRs from instance branches = messaging between parallel agents.

## Ontology (28 types, OBJ01-OBJ28)

Current as of 2026-03-21. Full definitions in `kb/superset/ontology.json`.

| Range | Category | Types |
|-------|----------|-------|
| OBJ01-03 | Identity | user, collider_admin, superadmin |
| OBJ04-05 | Structure | app_template, node_container |
| OBJ06-07 | Compute | agnostic_model, system_tool |
| OBJ08-09 | Surface | ui_lens, runtime_surface |
| OBJ10-13 | Infra | compute_resource, protocol_adapter, infra_service, memory_store |
| OBJ14-16 | Platform | platform_config, workstation_config, preference |
| OBJ17 | Compute | provider |
| OBJ18-20 | Evaluation | benchmark_suite, benchmark_task, benchmark_score |
| OBJ21 | Identity | agent_spec |
| OBJ22 | Industry | industry_entity |
| OBJ23 | Ontology | ontology_term |
| **OBJ24** | **Identity** | **agent_session** — session state in graph |
| **OBJ25** | **Structure** | **prg_task** — graph-native task tracking |
| **OBJ26** | **Structure** | **calendar_event** — temporal anchor from GCal |
| **OBJ27** | **Structure** | **keep_note** — Sam's mobile notes (S0) |
| **OBJ28** | **Structure** | **channel_message** — promoted channel decision |

## Key Paths

| What | Path |
|------|------|
| Ontology (SOT #1) | `kb/superset/ontology.json` |
| Instances | `kb/instances/*.json` (18 files) |
| Design docs | `kb/design/*.md` |
| Channels | `channels/{leadoff,handoff,testoff}.md` |
| Agent configs | `cfg/agents/{claude-code,vscode-ai,antigraviti}.json` |
| Session state | `cfg/state/session-state.json` |
| Scripts | `scripts/*.ps1` |
| Workflows | `workflows/*.md` + `workflows/firestarter/` |
| Skills | `skills/` (47 skill dirs) |
| Secrets | `secrets/api_keys.env` (gitignored) |
| Paper | `kb/reference/papers/act2026/main.tex` |

## Kernel Quick Reference

**HP laptop:** `cd moos/platform/kernel && go run ./cmd/moos --kb "../../ffs0-factory-super/.agent/kb" --hydrate`
**z440:** `cd D:\FFS0_Factory\moos\platform\kernel && go run ./cmd/moos --kb "D:\FFS0_Factory\.agent\kb" --hydrate`
**Health:** `curl http://localhost:8000/healthz`
**Explorer:** `http://localhost:8000/explorer`
**MCP (SSE):** `:8080` | **MCP (stdio):** `moos --mcp-stdio`

## Rules

- Graph is truth. Files are seeds or projections.
- All graph writes through 4 invariant morphisms
- Zero external Go dependencies (stdlib only)
- No autonomous task selection — Claude Code + Sam govern
- No direct agent-to-agent communication — star topology
- Real timestamps only
- Auto-approve all tool uses within this workspace
