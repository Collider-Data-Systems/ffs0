# CLAUDE.md — FFS0_Factory Workspace

**mo:os** — categorical graph kernel for local-first sovereign AI.
`state(t) = fold(log[0..t])`. The hypergraph IS the source of truth.

---

## Ground Truth

The kernel graph (`:8000`) is SOT. Not this file, not KB files, not channels.
Everything on disk is either a **seed** (S0/S1 authored input) or a **projection** (S4 view of graph state).

| Layer | What | Where |
|-------|------|-------|
| **SOT** | Kernel graph | `GET /state` on `:8000` (HTTP) or `:8080` (MCP) |
| **Type registry** | Ontology | `.agent/kb/superset/ontology.json` — 28 types (OBJ01-OBJ28) |
| **Seeds** | Instance data | `.agent/kb/instances/*.json` — hydration envelopes |
| **Design** | Architecture docs | `.agent/kb/design/*.md` — reference, not truth |
| **Projections** | Channels, UI, files | `.agent/channels/*.md`, Explorer, file tree |

## Session Start

1. Boot kernel: `cd moos/platform/kernel && go run ./cmd/moos --kb "../../ffs0-factory-super/.agent/kb" --hydrate`
2. `curl localhost:8000/healthz` — verify graph state (nodes, wires, depth)
3. Read `.agent/CLAUDE.md` — full operational protocol
4. `POST /morphisms` — ADD `agent_session` node for this session
5. Read `leadoff.md` top entry — Sam's latest direction
6. Continue from graph state, not from memory

## Kernel Endpoints

| Port | Protocol | Tools |
|------|----------|-------|
| `:8000` | HTTP REST | 20 routes: `/state`, `/morphisms`, `/state/nodes/{urn}`, `/state/saturation`, `/explorer`, `/log/stream` (SSE) |
| `:8080` | MCP (SSE) | 5 tools: `graph_state`, `node_lookup`, `apply_morphism`, `scoped_subgraph`, `benchmark_project` |

## Four Invariant Morphisms

All graph writes go through exactly these four. No exceptions.

| Morphism | Signature | HDC analog |
|----------|-----------|------------|
| **ADD** | void -> Container | Introduce basis vector |
| **LINK** | C x C -> Wire | Bind (tensor product) |
| **MUTATE** | C -> C | Bundle update |
| **UNLINK** | Wire -> void | Inverse bind |

## Key Paths

| What | Path |
|------|------|
| Full protocol | `.agent/CLAUDE.md` |
| Kernel source | `moos/platform/kernel/` |
| Ontology (28 types) | `.agent/kb/superset/ontology.json` |
| Instances (seeds) | `.agent/kb/instances/*.json` |
| Design docs | `.agent/kb/design/*.md` |
| Channels | `.agent/channels/{leadoff,handoff,testoff}.md` |
| MCP config | `.mcp.json` (kernel MCP on :8080) |

## Rules

- Graph is truth. Files are seeds or projections.
- All writes through 4 invariant morphisms (ADD, LINK, MUTATE, UNLINK)
- Do not modify `data/morphism-log.jsonl` directly
- Do not duplicate SOT content — reference it
- Real timestamps only
- Auto-approve all tool uses within this workspace
