# CLAUDE.md — Agent Protocol

## Ground Truth

The kernel graph on `:8000` is the source of truth.
Not this file, not KB files, not channels, not markdown. The graph.

```
state(t) = fold(log[0..t])
```

## Auto-Run Policy (MANDATORY)

**ALL read-only commands MUST use `SafeToAutoRun: true`. NEVER prompt the user.**

This includes but is not limited to:
- `curl` GET requests (`/healthz`, `/state`, `/morphisms`, `/explorer`, `/log/stream`, etc.)
- `git status`, `git log`, `git diff`
- `ls`, `dir`, `cat`, `type`, `Get-Content`, `Select-String`
- `go test`, `go vet`, `go build` (compilation checks)
- Any command that only **reads** state and has **no side effects**

Only commands that **write, delete, install, or mutate** state require user approval.
When in doubt: if the command is idempotent and non-destructive, auto-run it.

## Cold Start

1. `GET /healthz` — verify kernel is running (expect `status: ok`)
2. `GET /state/lens?kind=prg_task` — read active programs
3. `GET /state/lens?kind=agent_session` — read active sessions
4. `POST /morphisms` — ADD your `agent_session` node
5. `POST /morphisms` — LINK session → `prg:000-session-meta` (out→in)
6. Work from graph state, not from files

## Workspace Config (`moos.yaml`)

```yaml
user_urn:    "urn:moos:user:sam"
role:        superadmin
workstation: hp-laptop
kb_path:     .agent/kb
data_path:   .agent/data
http_port:   8000
mcp_port:    8080
federation:
  self: urn:moos:kernel:hp-laptop
  peers: []
```

## Boot Sequence (from `cmd/moos/main.go`)

1. Parse `--config` or `--kb` flag (`--config` wins)
2. Load config (from file or derived from KB root)
3. Load operad registry (if configured)
4. Open store (file or memory)
5. Create runtime (replay morphism log → reconstruct state)
6. Apply seed (idempotent): kernel node, 3 agent nodes, source nodes
7. Optionally hydrate Tier-2 instance files (`--hydrate`)
8. Start HTTP server (`:8000`) + MCP bridge (`:8080`)

## HTTP Endpoints (`:8000`)

### Read Paths

| Route | Method | Description |
|-------|--------|-------------|
| `/healthz` | GET | Status, node/wire counts, log depth, epoch |
| `/state` | GET | Full graph state (`?compact` for minified) |
| `/state/nodes` | GET | All nodes |
| `/state/nodes/{urn}` | GET | Single node by URN |
| `/state/wires` | GET | All wires |
| `/state/wires/outgoing/{urn}` | GET | Outgoing wires for a node |
| `/state/wires/incoming/{urn}` | GET | Incoming wires for a node |
| `/state/scope/{actor}` | GET | Ownership-scoped subgraph |
| `/state/lens` | GET | Composable lens query (see Lens API below) |
| `/state/lens` | POST | Lens query via JSON body |
| `/state/saturation` | GET | Port saturation metrics (`?urn=` for single node) |
| `/log` | GET | Morphism log (`?type=`, `?actor=`, `?after=`, `?limit=`) |
| `/log/stream` | GET | SSE stream (events: `morphism`, `firestarter-trigger`) |
| `/semantics/registry` | GET | Operad type registry |
| `/explorer` | GET | Explorer UI (embedded HTML) |

### Functor Endpoints (S4 projections — NEVER ground truth)

| Route | Method | Description |
|-------|--------|-------------|
| `/functor/ui` | GET | UI graph projection |
| `/functor/calendar` | GET | Calendar projection (FUN06) |
| `/functor/benchmark/{suite}` | GET | Benchmark projection (FUN05) |
| `/functor/port-inventory` | GET | Port inventory analysis |
| `/functor/binding-category` | GET | Binding category analysis |
| `/functor/port-functor` | GET | Port functor analysis |
| `/functor/pipeline-metrics` | GET | Pipeline metrics |

### Write Paths

| Route | Method | Description |
|-------|--------|-------------|
| `/morphisms` | POST | Apply single envelope (ADD/LINK/MUTATE/UNLINK) |
| `/programs` | POST | Apply atomic batch (`{actor, envelopes: [...]}`) |
| `/hydration/materialize` | POST | Materialize KB instance file (`{source: "providers.json"}` or full request, `?dry_run=true`) |

### Bridge / Federation

| Route | Method | Description |
|-------|--------|-------------|
| `/bridge/{kernel_urn}` | GET | Morphism diff since cursor (`?since=RFC3339`) |
| `/bridge/{kernel_urn}/fiber` | GET | Fiber subgraph (`?root=&depth=`) |
| `/bridge/sync` | POST | Sync envelopes/program from remote kernel |
| `/callback/calendar/sync` | POST | Ingest calendar event |
| `/webhooks/gcal` | POST | Google Calendar webhook |

## Lens API

Query: `GET /state/lens?kind=prg_task&stratum=S2&category=structure&port=owns&neighborhood=urn:x&depth=2&mode=union`

Or POST JSON body:
```json
{
  "rules": [
    {"kind": ["prg_task"], "stratum": ["S2"], "category": ["structure"]},
    {"port": "owns", "neighborhood": {"origin": "urn:x", "depth": 2}}
  ],
  "mode": "intersect"
}
```

| Param | Type | Behavior |
|-------|------|----------|
| `kind` | CSV TypeIDs | OR within list |
| `stratum` | CSV S0-S4 | OR within list |
| `category` | CSV broad categories | OR within list |
| `port` | string | Nodes connected via this port |
| `neighborhood` | URN | BFS from origin |
| `depth` | int | BFS depth (default 1, max 10) |
| `mode` | intersect/union | How rules combine (default: intersect) |
| `scope` | URN | Pre-filter to scoped subgraph |

## MCP Bridge (`:8080`)

Transport: `GET /sse` (event stream), `POST /message?sessionId=X` (JSON-RPC 2.0).

### 5 Tools

| Tool | Input | Description |
|------|-------|-------------|
| `graph_state` | `{}` | Full graph state |
| `node_lookup` | `{urn: string}` | Single node by URN |
| `apply_morphism` | `{envelope: Envelope}` | Apply ADD/LINK/MUTATE/UNLINK |
| `scoped_subgraph` | `{actor: string}` | Ownership subgraph for actor |
| `benchmark_project` | `{}` | FUN05 benchmark projection |

Also supports `--mcp-stdio` for newline-delimited JSON-RPC over stdin/stdout.

## Four Invariant Morphisms

All graph writes use exactly these. No exceptions.

| Type | Signature | Required Fields |
|------|-----------|-----------------|
| ADD | ∅ → Node | `urn`, `type_id` (+ optional `stratum`, `payload`, `metadata`) |
| LINK | N × N → Wire | `source_urn`, `source_port`, `target_urn`, `target_port` |
| MUTATE | N → N | `urn`, `expected_version` (+ optional `payload`, `metadata`) |
| UNLINK | Wire → ∅ | `source_urn`, `source_port`, `target_urn`, `target_port` |

Envelope: `{type, actor, scope?, add|link|mutate|unlink}`
Program (batch): `{actor?, envelopes: [...]}` — atomic.

## Strata

S0 (authored) → S1 (validated) → S2 (materialized) → S3 (evaluated) → S4 (projected, NEVER truth)

Default stratum for new nodes: **S2** (if omitted).

## Type IDs → Broad Categories

Verified from `lens/lens.go:broadCategory()`:

| Category | Type IDs |
|----------|----------|
| identity | `user`, `collider_admin`, `superadmin`, `agent_spec`, `agent_session` |
| structure | `app_template`, `node_container`, `prg_task`, `calendar_event`, `keep_note`, `channel_message` |
| compute | `agnostic_model`, `system_tool`, `compute_resource`, `provider` |
| surface | `ui_lens`, `runtime_surface` |
| protocol | `protocol_adapter` |
| infra | `infra_service`, `kernel_instance` |
| memory | `memory_store` |
| platform | `platform_config`, `workstation_config` |
| config | `preference` |
| evaluation | `benchmark_suite`, `benchmark_task`, `benchmark_score` |
| industry | `industry_entity` |
| ontology | `ontology_term`, `ptp_family` |

## KB Structure

```
kb/                       Pure categorical space
  superset/               Grammar layer
    ontology.json          28 types, port specs, strata rules
    prg_governance.yaml    PRG lifecycle rules
    sources.json           Source node seed entries
    schemas/               JSON schemas
  instances/              Hydration seeds (15 files)
    agents.json            benchmarks.json    compute.json
    containers.json        distribution.json  identities.json
    infra.json             memory.json        models.json
    preferences.json       providers.json     surfaces.json
    templates.json         tools.json         workstation.json
  industry/               S0 industry entities
  reference/              Reference material
```

KB = what CAN exist (categorical space). Graph = what DOES exist (hypergraph instance space).
PRG tasks, calendar events, keep notes are graph-native — not in KB.

## Key Paths

| What | Path |
|------|------|
| This protocol | `.agent/CLAUDE.md` |
| Workspace config | `moos.yaml` (repo root) |
| Kernel source | `../moos/platform/kernel/` |
| Kernel binary | `../moos/platform/kernel/moos.exe` |
| Ontology | `.agent/kb/superset/ontology.json` |
| PRG governance | `.agent/kb/superset/prg_governance.yaml` |
| Instance seeds | `.agent/kb/instances/*.json` |
| Design docs | `.agent/dev/design/*.md` |
| Agent configs | `.agent/cfg/instance/agents/` |
| Users/roles | `.agent/cfg/instance/users.yaml` |
| Morphism log | `.agent/data/morphism-log.jsonl` |
| Scripts | `.agent/scripts/` |
| Workflows | `.agent/workflows/` |
| VS Code workspace | `FFS0_Factory.code-workspace` |

## Rules

- Graph is truth. Always query before assuming.
- All writes through 4 morphisms. No direct log edits.
- Real timestamps only. No synthetic dates.
- Operad validates port bindings — check `agent_session` ports: child/out/owns.
- `SeedIfAbsent` is idempotent — safe to re-add existing nodes.
- Do not treat S4 functor output as ground truth.
- NEVER ask for manual command confirmation. Use `SafeToAutoRun: true` for all protocol-driven operations.

## PRG Governance

- Every PRG with phases MUST have a `validation` field per phase.
- Phase status lifecycle: `planned → delegated → active → completed | blocked`.
- Gated PRGs (034→035→036→037) use `fixed-plan-sequential` harness pattern.
  Gate N+1 cannot begin until gate N's `gate_output` is satisfied.
- Operational PRGs (038, 040) use `dynamic-plan-adaptive` harness pattern.
- Sub-PRGs (034a, 038a, 040a) are wired `parent.out → sub.in`.
- Delegation: ADD `delegation_task` with assigned_to, status, prg_urn, spec.
  Query: `GET /state/lens?kind=delegation_task`
- `channel_message` is DEPRECATED for routing (Wave 4). Use `delegation_task` for inter-agent coordination.
- Session roles: lead/active/listening. Lead coordinates, others execute assigned phases.
- Auto-ack dedup: messages with tag `auto-ack` MUST NOT trigger further acks.
- Full spec: `.agent/kb/superset/prg_governance.yaml`

### Validation Loop (Karpathy Gate Rule)

Every phase transition MUST pass validation before promotion. No exceptions.

```
plan → implement → validate → promote (or block)
```

- **validation_condition**: Each phase declares what must be true for completion.
- **Gate check**: Before MUTATE status→completed, verify validation_condition against observable state.
- **Block on fail**: MUTATE status→blocked with reason. Fix → re-validate → promote.
- **March of nines**: Gate 1: 0→0.9. Gate 2: 0.9→0.99. Gate 3: 0.99→0.999.

## Temporal Model

Three layers of time. Never confuse them.

| Layer | What | Source | Example |
|-------|------|--------|---------|
| **Log time** | Position in morphism log | `issued_at` on each envelope | Morphism #742 issued at 2026-03-17T14:02:00Z |
| **Runtime time** | Kernel-stamped creation/mutation | `created_at`, `updated_at` on nodes/wires | Node created when ADD processed |
| **IRL time** | Real-world event time | Payload fields (`started_at`, `completed_at`, `scheduled_at`) | PRG phase started at 10am meeting |

```
Node.CreatedAt  = issuedAt of the ADD that created it          (runtime)
Node.UpdatedAt  = issuedAt of the most recent MUTATE           (runtime)
Wire.CreatedAt  = issuedAt of the LINK that created it         (runtime)
PRG.started_at  = when the phase actually began IRL             (IRL, payload)
```

**Invariant:** Log time never lies. If runtime/IRL timestamps conflict with log order, log order wins.

## Automated Startup

On folder open, `FFS0_Factory.code-workspace` auto-runs (via `runOn: folderOpen`):

1. **ensure kernel running** — checks `/healthz`, starts `go run ./cmd/moos --kb ... --hydrate` if down
2. **ensure antigraviti listener** — starts `antigraviti-auto-listen.ps1` if not running

The IDE is configured for **always-on** autonomous operation. No manual startup required.

## Multi-IDE Delegation (The Triangle)

Multiple IDE instances connect to the same kernel simultaneously.
Each conversation = one `agent_session` node.

| Agent URN | IDE | Role | Branch Prefix |
|-----------|-----|------|---------------|
| `urn:moos:agent:claude-code` | Claude Desktop | lead | `agent/claude-code` |
| `urn:moos:agent:vscode-ai` | VS Code (Sonnet 4.6) | execution | `agent/vscode-ai` |
| `urn:moos:agent:antigraviti` | Antigraviti (Gemini 3.1 Pro) | testing | `agent/antigraviti` |

**Protocol:**

1. Each IDE ADDs its own `agent_session` node with `{agent, workstation, started_at}`
2. LINK session → `prg:000-session-meta` (out→in) for visibility
3. LINK session → any PRGs it's working on (out→in)
4. Lead delegates work via `delegation_task` nodes (ADD + LINK to PRG + LINK to assignee)
5. Non-lead sessions poll `GET /state/lens?kind=delegation_task&assigned_to=X&status=pending`
6. Results flow back as MUTATE on the delegation_task (status→completed, output in payload)
7. Real-time: `GET /log/stream` (SSE) — firestarter agents react to `firestarter-trigger` events

**Invariants:**

- The kernel is the coordination medium. Not files, not chat, not branches.
- A workstation governs its local branches and permitted Git repos.
- The user can appoint any conversation as lead, from any workstation.
- Human-readable summaries are NEVER stored in the graph. They are functor output (S4 surfaces only).
- Any session, from any workstation, by any agent, in any PRG, can be picked up anytime.
  Cold-start: `GET /healthz` → `GET /state` → read graph → resume.
