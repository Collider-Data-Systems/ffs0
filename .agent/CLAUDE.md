# CLAUDE.md — Agent Protocol

## Ground Truth

The kernel graph on `:8000` is the source of truth.
Not this file, not KB files, not channels, not markdown. The graph.

```
state(t) = fold(log[0..t])
```

## Connect

1. `GET /healthz` — verify kernel is running
2. `GET /state/lens?kind=prg_task` — read active programs
3. `GET /state/lens?kind=agent_session` — read active sessions
4. `POST /morphisms` — ADD your `agent_session` node
5. `POST /morphisms` — LINK session → `prg:000-session-meta` (out→in)
6. Work from graph state, not from files

## Endpoints

| Port    | Protocol | Key Routes                                                                                                            |
| ------- | -------- | --------------------------------------------------------------------------------------------------------------------- |
| `:8000` | HTTP     | `/healthz`, `/state`, `/state/lens?kind=X`, `/morphisms` (POST), `/programs` (POST), `/explorer`, `/log/stream` (SSE) |
| `:8080` | MCP SSE  | `graph_state`, `node_lookup`, `apply_morphism`, `scoped_subgraph`, `benchmark_project`                                |

## Four Invariant Morphisms

All graph writes use exactly these. No exceptions.

| Type   | Signature          | Envelope Field                                               |
| ------ | ------------------ | ------------------------------------------------------------ |
| ADD    | ∅ → Node           | `add: {urn, type_id, stratum, payload}`                      |
| LINK   | Node × Node → Wire | `link: {source_urn, source_port, target_urn, target_port}`   |
| MUTATE | Node → Node        | `mutate: {urn, expected_version, payload}`                   |
| UNLINK | Wire → ∅           | `unlink: {source_urn, source_port, target_urn, target_port}` |

Envelope: `{type, actor, add|link|mutate|unlink}`
Program (batch): `{actor, envelopes: [...]}` — all same actor, atomic.

## Strata

S0 (authored) → S1 (validated) → S2 (materialized) → S3 (evaluated) → S4 (projected, NEVER truth)

## KB Structure

```
kb/                    Pure categorical space
  superset/            Ontology (28 types), schemas — grammar
  instances/           Infrastructure seeds — hydration input
  industry/            S0 industry entities — external landscape
```

KB = what CAN exist (categorical space). Graph = what DOES exist (hypergraph instance space).
PRG tasks, calendar events, keep notes are graph-native — not in KB.

## Key Paths

| What          | Path                               |
| ------------- | ---------------------------------- |
| This protocol | `.agent/CLAUDE.md`                 |
| Kernel source | `moos/platform/kernel/`            |
| Ontology      | `.agent/kb/superset/ontology.json` |
| Seeds         | `.agent/kb/instances/*.json`       |
| Design docs   | `.agent/dev/design/*.md`           |
| Reference     | `.agent/dev/reference/`            |
| Agent configs | `.agent/cfg/agents/*.json`         |

## Rules

- Graph is truth. Always query before assuming.
- All writes through 4 morphisms. No direct log edits.
- Real timestamps only. No synthetic dates.
- Operad validates port bindings — check `agent_session` ports: child/out/owns.
- `SeedIfAbsent` is idempotent — safe to re-add existing nodes.
- Do not treat S4 functor output as ground truth.

## Temporal Model

Every Node carries `created_at` and `updated_at` (RFC3339Nano, UTC).
Every Wire carries `created_at`. Set by the catamorphism, reconstructible by replay.
The graph epoch (t=0) is the `issued_at` of the first morphism log entry.
Exposed via `GET /healthz` → `epoch` field.

```
Node.CreatedAt  = issuedAt of the ADD that created it
Node.UpdatedAt  = issuedAt of the most recent MUTATE (or ADD if never mutated)
Wire.CreatedAt  = issuedAt of the LINK that created it
```

PRG runtime lifecycle is tracked via payload fields set by MUTATE:
`status` (planned/active/in_progress/completed/ideation), `started_at`, `completed_at`.
The kernel doesn't enforce lifecycle semantics — programs define their own.

## Multi-IDE Delegation

Multiple IDE instances (VS Code, Claude Code, Antigraviti, etc.) can connect
to the same kernel simultaneously. Each conversation = one `agent_session` node.

**Protocol:**

1. Each IDE/conversation ADDs its own `agent_session` node with `{agent, workstation, started_at}`
2. LINK session → `prg:000-session-meta` (out→in) for visibility
3. LINK session → any PRGs it's working on (out→in)
4. One session is designated **lead** per user appointment (in conversation, not in code)
5. The lead coordinates PRG progression and delegates via graph wires, not files
6. Non-lead sessions read the graph, do assigned work, write results back via morphisms
7. Messages between sessions: ADD `channel_message` nodes, LINK from session and PRG

**Invariants:**

- The kernel is the coordination medium. Not files, not chat, not branches.
- A workstation governs its local branches and permitted Git repos.
- The user can appoint any conversation as lead, from any workstation.
- PRGs can exist in any lifecycle state: wires can be pre-constructed for programs
  whose IRL runtime hasn't started yet. The graph is the plan.
- Time flows through the log. `GET /log?after=<RFC3339>` to catch up.
  `GET /log/stream` (SSE) for real-time.
