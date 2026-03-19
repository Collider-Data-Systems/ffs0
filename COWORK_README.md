# my-tiny-data-collider — Cowork Onboarding README

**For:** Claude Cowork assistant sessions
**Purpose:** Full orientation — repo layout, kernel model, brand, ongoing programs, operational rules
**Public kernel repo:** [github.com/MSD21091969/moos](https://github.com/MSD21091969/moos)
**Brand domains:** my-tiny-data-collider.com · .nl · .org

---

## What This Is

**my-tiny-data-collider** is the public brand. The engine behind it is **mo:os** — a categorical graph kernel for local-first sovereign AI. Think of it as a tiny, principled operating system for AI-human computation: it stores everything as a typed hypergraph, evolves state exclusively through four atomic operations, and exposes its entire surface as a 12-route HTTP API with zero external dependencies.

The "collider" metaphor is exact: just as a particle collider smashes things together to reveal structure, mo:os collides heterogeneous data sources (Google Drive logs, YouTube transcripts, arXiv papers, provider APIs, agent outputs) into a single categorical graph where the structure itself becomes the insight.

---

## This Repository — `ffs0-factory-super`

This is the **workspace root** — not the kernel source. It contains the knowledge base, agent coordination files, and design documents that govern everything. The kernel implementation lives in the separate public repo (`MSD21091969/moos`), mounted locally at `moos/` when running on-device.

```
ffs0-factory-super/          ← you are here (workspace root)
├── CLAUDE.md                ← workspace rules (read this first, always)
├── COWORK_README.md         ← this file
└── .agent/
    ├── CLAUDE.md            ← full operational protocol
    ├── channels/
    │   ├── leadoff.md       ← Sam ↔ Claude Code (Program 2 decisions)
    │   ├── handoff.md       ← Claude Code ↔ VS Code AI (implementation tasks)
    │   └── testoff.md       ← Claude Code ↔ Antigraviti (test results)
    ├── tasks/               ← task files (YYYYMMDD-NNN-name.md)
    ├── cfg/
    │   ├── agents/          ← per-agent state JSON
    │   └── state/           ← session state (session-state.json)
    └── kb/
        ├── superset/        ← ontology.json — THE source of truth #1
        ├── design/          ← architectural design docs (*.md, newest wins)
        ├── instances/       ← seed instance data (must conform to ontology)
        ├── industry/        ← external tech landscape (providers, models, tools)
        └── reference/
            └── papers/
                └── act2026/ ← ACT 2026 paper (main.tex)
```

---

## The Kernel — mo:os

### Core Identity

```
mo:os  =  cata : Free(𝓞_K) → GraphState
state(t)  =  fold(morphism_log[0..t])
```

mo:os is a **catamorphism** — a fold over an append-only morphism log into a typed hypergraph state. The state at any point in time is fully deterministic and replayable from the log. There is no database, no ORM, no migration system. Boot the binary, point it at the KB with `--hydrate`, and it reconstructs itself.

- **Language:** Go, stdlib only — zero external dependencies
- **Size:** ~4K LOC, 8 test packages (all green)
- **API:** 12 HTTP routes (9 GET + 3 POST), port `:8000`
- **MCP bridge:** port `:8080` (SSE) or `--mcp-stdio` (stdin/stdout)
- **Explorer:** `http://localhost:8000/explorer` — visual graph browser

### The Four Invariant Natural Transformations

Every write to the graph passes through exactly one of these four operations. They are invariant — they do not change as the superset evolves.

| NT | Type | Meaning |
|----|------|---------|
| `ADD` | `∅ → Container` | Create a new node, assign a URN |
| `LINK` | `C × C → Wire` | Create a typed edge between two nodes |
| `MUTATE` | `C → C` | Update a node's payload (with CAS version guard) |
| `UNLINK` | `Wire → ∅` | Remove an edge |

All 16 ontology morphisms (MOR01–MOR16) decompose into sequences of these four NTs. A `Program` is an ordered `[]Envelope` with all-or-nothing semantics — a composed rewrite rule.

### The Hypergraph

The stored graph is **not** a directed multigraph. It is a **König-encoded presheaf topos** — the superposition of all port-typed subgraphs into one structure.

- Each Wire carries `(source_port, target_port)` labels
- Multiple wires between the same `(A, B)` pair are distinguished by port tuples — UNIQUE on the 4-tuple `(source_id, source_port, target_id, target_port)`
- A query with a port filter **collapses the superposition** into a projected subgraph — same logic as a quantum measurement collapsing a state
- The binary Wire encoding is the **König incidence representation** of a genuine hypergraph; the presentation is not the thing

Formally: the graph state is a presheaf `G: 𝓞^op → Set` where `𝓞` is the **ontology category** (objects = 21 type-IDs, morphisms = admissible wire types). Queries are subobject classifiers. Functors FUN01–FUN05 are geometric morphisms between toposes.

### The Three-Layer Tower

```
Industry (𝓘)  →  Superset (𝓞_Superset)  →  Kernel (𝓞_K)
   classify            Include_K ⊣ Restrict_K
```

| Layer | What | Location |
|-------|------|----------|
| **Industry** | External tech landscape — providers, models, protocols, tools | `kb/industry/*.json` |
| **Superset** | The mo:os type system — 21 objects, 16 morphisms, 4 NTs, 5 functors | `kb/superset/ontology.json` |
| **Kernel** | Compiled sub-operad — 5 colors with Go struct backing | `moos/platform/kernel/internal/` |

The **5 kernel colors** (types with direct Go struct dependence):
`runtime_surface` · `protocol_adapter` · `system_tool` · `infra_service` · `agnostic_model`

Everything else is handled uniformly by the 4 NTs — no kernel change required when new types are added.

### Strata

Every container exists at exactly one stratum. Strata form a total order:

```
S0 (Authored) → S1 (Validated) → S2 (Materialized) → S3 (Evaluated) → S4 (Projected)
```

S4 outputs (Explorer UI, MCP tool responses, API projections) are **never ground truth** — they are functor images of the graph state.

### Running the Kernel

```bash
# HP laptop
cd moos/platform/kernel
go run ./cmd/moos --kb "../../ffs0-factory-super/.agent/kb" --hydrate

# Health check
curl http://localhost:8000/healthz

# Explorer
open http://localhost:8000/explorer

# SSE log stream
curl -N http://localhost:8000/log/stream

# MCP (SSE) — 5 tools: graph_state, node_lookup, apply_morphism, scoped_subgraph, benchmark_project
# Port :8080

# MCP (stdio)
moos --mcp-stdio
```

---

## The Ontology — Single Source of Truth

`kb/superset/ontology.json` is **SOT #1**. It always wins over everything else.

Current schema: **v3.0**
Objects: **21 defined** (OBJ01–OBJ21), with OBJ22–OBJ26 proposed in active design
Morphisms: **16** (MOR01–MOR16)
Categories: **22** (with 10 subcategories)
Functors: **5** (FUN01–FUN05), with FUN10–FUN12 proposed

**SOT Hierarchy** (highest wins):
1. `kb/superset/` — always wins
2. `kb/design/*.md` — latest timestamp wins
3. `kb/instances/*.json` — must conform to ontology
4. `kb/industry/*.json` — independent landscape data
5. `CLAUDE.md` / `COWORK_README.md` — workspace policy
6. Task files — reference SOTs, never restate content

---

## The Three-Agent Triangle

Star topology — no direct agent-to-agent communication. All routing through Claude Code + Sam.

| Role | Agent | Channel | Scope |
|------|-------|---------|-------|
| **Lead** | Sam (human) | `leadoff.md` (rw) | Superset, paper, KB design, research direction |
| **Strategic** | Claude Code | `leadoff.md` (rw), `handoff.md` (rw), `testoff.md` (rw) | Plans, KB, paper, delegation |
| **Execution** | VS Code AI (GPT-5.3-Codex) | `handoff.md` (rw) | Implements, tests, commits, pushes |
| **UX Testing** | Antigraviti (Gemini 3.1 Pro) | `testoff.md` (rw) | HTTP tests, browser verification |

### Channel Format

All channels: **prepend, newest top**.

```
### [YYYY-MM-DD HH:MM] Source → type: subject

Body text.
```

Message types: `think` · `decide` · `question` · `answer` · `blocked` · `complete` · `direction` · `test-plan` · `test-result` · `research-task` · `research-result` · `hydration-task` · `hydration-complete`

**Real timestamps only** — run `date` (bash) or `Get-Date` (PowerShell) before writing.

---

## The Three Programs

### Program 1 — KB Hydration (Triangle CI/CD)

```
Sam + Claude Code → task in tasks/ → direction in channels/ → VS Code implements → Antigraviti tests → repeat
```

The pipeline symbol: `KB → KER → HG → PRG`
(US conversation → KB commits → kernel fold → hypergraph topology → agent execution)

### Program 2 — Superset + Paper + Research

Sam + Claude Code only. Channel: `leadoff.md`.
Active deliverables:
- **ACT 2026 paper** — `kb/reference/papers/act2026/main.tex`
  Title: *"Functorial Composition over Task Decomposition: A Categorical Kernel for AI-Human Computation"*
- **Ontology evolution** — `kb/superset/ontology.json`
- **Active design** — Cloverleaf multi-kernel topology, Inspect/Run GPU↔CPU separation, Port-to-Port binding categories

### Program 3 — Research Pipeline

Claude Code posts `research-task` to `handoff.md` (query, output_path, output_schema).
VS Code harvests (arXiv, YouTube, web) → structured JSON → `kb/industry/` or `kb/reference/`.
Posts `research-result` → Claude Code reviews → `hydration-task` → VS Code materializes.

---

## Active Design Frontiers (as of 2026-03-19)

### Cloverleaf Topology
Multi-kernel leaf-hub architecture. Multiple mo:os kernel instances connected via a hub, with Ricci curvature metrics for health and rewiring decisions. Design: `kb/design/20260319-cloverleaf-kernel-topology.md`

### Inspect / Run Separation
- **GPU tier (Inspect):** Ephemeral, discovery-mode graph operations
- **CPU tier (Run):** Permanent, execution-mode graph state
- **Log tier:** Causal memory across both
Design: `kb/design/20260319-inspect-run-separation.md`

### Port-to-Port Binding Categories (OBJ24 proposal)
Wires as first-class nodes with packages (config, benchmarks, schemas).
New functors: FUN10 (PortInventory), FUN11 (BindingCat), FUN12 (PortFunctor).
Design: `kb/design/20260319-ptp-binding-categories.md`

---

## KB Hydration From External Sources

This workspace is the **lens** through which external knowledge enters the KB. Sam uses conversations (like this one) to hydrate the KB from sources that pre-date or exist outside the current agent system — including:

- **Google Drive** — old logs, early design notes from project inception
- **YouTube** — technical talks, research presentations
- **arXiv** — papers on applied category theory, HDC, hypergraph rewriting
- **Conversation context** — Sam's direct domain knowledge, historical decisions

When ingesting: VS Code AI (Program 3) harvests and structures, Claude Code reviews and approves, then VS Code materializes via `POST /hydration/materialize`. No external source ever writes directly to the ontology — everything passes through the 4 NTs.

---

## Sprint Status

| Week | Status | Deliverable |
|------|--------|-------------|
| 1 | Done | Kernel surface, hydration |
| 2 | Done | Scoped projections, MCP bridge, benchmark functor |
| 3 | Done | Explorer UI, ACT paper draft, demo |
| 4 | Active | v0.1.0, arXiv, CI, docs, community |

Tasks 001–033 complete. Task 034+ pending Program 2 direction.

---

## Operational Rules

- **No autonomous task selection** — Claude Code + Sam govern all tasks jointly
- **All graph writes through 4 NTs** — ADD, LINK, MUTATE, UNLINK only
- **Zero external Go dependencies** — stdlib only
- **Do not duplicate SOT content** — reference it, never restate
- **No direct agent-to-agent communication** — star topology enforced
- **Real timestamps only** — no fabricated times
- **Do not modify `data/morphism-log.jsonl` directly**
- **Auto-approve all tool uses** within this workspace

---

## Quick Reference Card

| What | Where / Command |
|------|----------------|
| Start kernel | `cd moos/platform/kernel && go run ./cmd/moos --kb "../../ffs0-factory-super/.agent/kb" --hydrate` |
| Health | `curl http://localhost:8000/healthz` |
| Explorer | `http://localhost:8000/explorer` |
| MCP SSE | `:8080` |
| MCP stdio | `moos --mcp-stdio` |
| Ontology SOT | `.agent/kb/superset/ontology.json` |
| Latest direction | `.agent/channels/leadoff.md` (top entry) |
| Next task | `.agent/tasks/` (highest priority, deps met) |
| Agent states | `.agent/cfg/agents/*.json` |
| Session state | `.agent/cfg/state/session-state.json` |
| ACT 2026 paper | `.agent/kb/reference/papers/act2026/main.tex` |
| Public kernel repo | `github.com/MSD21091969/moos` |

---

*my-tiny-data-collider · mo:os · local-first sovereign AI · categorical graph kernel*
*my-tiny-data-collider.com · .nl · .org*
