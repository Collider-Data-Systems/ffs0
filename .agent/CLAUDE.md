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

## PRG Governance

- Every PRG with phases MUST have a `validation` field per phase.
- Phase status lifecycle: `planned → delegated → active → completed | blocked`.
- Gated PRGs (034→035→036→037) use `fixed-plan-sequential` harness pattern.
  Gate N+1 cannot begin execution until gate N's `gate_output` is satisfied.
- Operational PRGs (038, 040) use `dynamic-plan-adaptive` harness pattern.
  Phases can be reordered, added, or removed at runtime.
- Sub-PRGs (034a, 038a, 040a) are wired `parent.out → sub.in`.
- Delegation: ADD `delegation_task` with assigned_to, status, prg_urn, spec. Query: `GET /state/lens?kind=delegation_task`.
  `channel_message` is DEPRECATED for routing (Wave 4). Use only for structural PRG decisions.
  Human-readable summaries are functor output (FUN06/FUN07), never stored in graph.
- Session roles: lead/active/listening. Lead coordinates, others execute assigned phases.
- Auto-ack dedup: messages with tag `auto-ack` MUST NOT trigger further acks.

### Validation Loop (Karpathy Gate Rule)

Every phase transition MUST pass validation before promotion. No exceptions.

```
plan → implement → validate → promote (or block)
```

- **validation_condition**: Each phase declares what must be true for completion.
  No empty validation fields. "It works" is not a validation condition.
- **Gate check**: Before MUTATE status→completed, the lead (or delegated agent)
  verifies the validation_condition against observable graph state or endpoint output.
- **Block on fail**: If validation fails, MUTATE status→blocked with reason in payload.
  Do not skip. Do not hand-wave. Fix → re-validate → promote.
- **March of nines**: Each gate adds reliability. Gate 1 gets you from 0→0.9.
  Gate 2 from 0.9→0.99. Gate 3 from 0.99→0.999. The last 1% takes as long as the first 90%.
  Budget time accordingly — later gates are harder, not easier.

## Temporal Model

Three layers of time. Never confuse them.

| Layer | What | Source | Example |
|-------|------|--------|---------|
| **Log time** | Position in the morphism log | `issued_at` on each envelope | Morphism #742 issued at 2026-03-17T14:02:00Z |
| **Runtime time** | Kernel-stamped creation/mutation | `created_at`, `updated_at` on nodes/wires | Node created when ADD processed |
| **IRL time** | Real-world event time | Payload fields (`started_at`, `completed_at`, `scheduled_at`) | PRG phase started at 10am meeting |

**Log time** is the total order. `state(t) = fold(log[0..t])`. Deterministic replay.
**Runtime time** is set by the catamorphism — reconstructible from log replay.
**IRL time** is authored by humans/agents in payloads — the kernel does not enforce it.

```
Node.CreatedAt  = issuedAt of the ADD that created it          (runtime)
Node.UpdatedAt  = issuedAt of the most recent MUTATE           (runtime)
Wire.CreatedAt  = issuedAt of the LINK that created it         (runtime)
PRG.started_at  = when the phase actually began IRL             (IRL, payload)
PRG.completed_at = when the phase actually finished IRL         (IRL, payload)
```

The graph epoch (t=0) is the `issued_at` of the first morphism log entry.
Exposed via `GET /healthz` → `epoch` field.

PRG runtime lifecycle is tracked via payload fields set by MUTATE:
`status` (planned/active/in_progress/completed/ideation), `started_at`, `completed_at`.
The kernel doesn't enforce lifecycle semantics — programs define their own.

**Invariant:** Log time never lies. If runtime/IRL timestamps conflict with log order, log order wins.

## Multi-IDE Delegation (The Triangle)

Multiple IDE instances connect to the same kernel simultaneously.
Each conversation = one `agent_session` node.

**Known agents** (from `cfg/users.yaml`):

| Agent URN | IDE | Role | Branch Prefix |
|-----------|-----|------|---------------|
| `urn:moos:agent:claude-code` | Claude Desktop | lead | `agent/claude-code` |
| `urn:moos:agent:vscode-ai` | VS Code (Sonnet 4.6) | execution | `agent/vscode-ai` |
| `urn:moos:agent:antigraviti` | Antigraviti (Gemini 3.1 Pro) | testing | `agent/antigraviti` |

**Protocol:**

1. Each IDE ADDs its own `agent_session` node with `{agent, workstation, started_at}`
2. LINK session → `prg:000-session-meta` (out→in) for visibility
3. LINK session → any PRGs it's working on (out→in)
4. One session is designated **lead** per user appointment
5. Lead delegates work via `delegation_task` nodes (ADD + LINK to PRG + LINK to assignee)
6. Non-lead sessions poll `GET /state/lens?kind=delegation_task&assigned_to=X&status=pending`
7. Results flow back as MUTATE on the delegation_task (status→completed, output in payload)
8. Real-time: `GET /log/stream` (SSE) — firestarter agents react to `firestarter-trigger` events

**Invariants:**

- The kernel is the coordination medium. Not files, not chat, not branches.
- A workstation governs its local branches and permitted Git repos.
- The user can appoint any conversation as lead, from any workstation.
- PRGs can exist in any lifecycle state: wires can be pre-constructed for programs
  whose IRL runtime hasn't started yet. The graph is the plan.
- Human-readable summaries are NEVER stored in the graph. They are functor output
  (FUN06/FUN07) projected to Google Workspace, Slack, calendar — S4 surfaces only.
- Any session, from any workstation, by any agent, in any PRG, can be picked up anytime.
  Cold-start: `GET /healthz` → `GET /state` → read graph → resume.
