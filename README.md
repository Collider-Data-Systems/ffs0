# ffs0-factory-super

Private workspace for [mo:os](https://github.com/MSD21091969/moos) — a categorical graph kernel for local-first sovereign AI.

## The Claim

Four invariant morphisms (ADD, LINK, MUTATE, UNLINK) over a typed hypergraph are sufficient to model any sovereign AI system. State at any time is a deterministic fold over an append-only morphism log:

```
state(t) = fold(log[0..t])
```

The kernel graph is the source of truth. Everything else — files, UIs, projections — derives from it.

## Architecture

**Two spaces, one principle:**

| Space | What | Where |
|-------|------|-------|
| **Categorical Space (CS)** | Grammar of what CAN exist | `kb/superset/ontology.json` — 28 types, 17 morphisms, 5 functors |
| **Hypergraph Instance (HG)** | What DOES exist | Kernel `:8000` — 300+ nodes, 180+ wires |

The ontology defines the syntax category. Functors project structure-preserving views into target categories (filesystem, UI, embeddings, benchmarks). The separation of syntax and semantics IS the categorical discipline.

**Three-layer tower:**

```
Industry (C)        — external tech landscape (providers, benchmarks, frameworks)
    ↓ classify
Superset (𝓞)       — 28-type mo:os ontology (grammar)
    ↓ compile
Kernel (𝓞_K)       — 5 compiled colors (minimal runtime dependency)
```

## Current State — T=141 (March 22, 2026)

**Kernel:** Go 1.23, zero external dependencies, ~4K LOC, 10 test packages

| Endpoint | What |
|----------|------|
| `:8000` HTTP | 20 routes — `/state`, `/morphisms`, `/explorer`, `/log/stream` (SSE) |
| `:8080` MCP | 5 tools — `graph_state`, `node_lookup`, `apply_morphism`, `scoped_subgraph`, `benchmark_project` |

**Active Programs (PRG):**

| PRG | Title | Gate | Status |
|-----|-------|------|--------|
| 000 | Session Meta-Program | — | active (always) |
| 034 | Naturality harness for FUN02 UI_Lens | 1 | planned → T=142 |
| 035 | PTP PortBinding + FUN10/11/12 | 2 | planned (depends 034) |
| 036 | Cloverleaf multi-kernel topology | 3 | planned (depends 035) |
| 037 | Inspect/Run separation | 4 | planned (depends 036) |
| 038 | Moos Media Channel | — | ideation |
| 039 | Session Identity — conversation as graph node | — | planned |

Gates 1–4 are a locked sequence. PRG034 starts Tuesday T=142 (act week).

**Five Causal Invariancies:**
1. Church-Rosser commutativity — order-independent concurrent morphisms
2. Functor naturality — `Project(Apply(M, S)) == Apply(M', Project(S))`
3. Identity stability — self-referential port `urn(x) = x`
4. Log replay determinism — same log always produces same state
5. PTP compatibility stability — valid port bindings compose

## Timeline

| T | Date | Milestone |
|---|------|-----------|
| -194 | Sep 2025 | ChatGPT era begins |
| -155 | Oct 2025 | HAL/MDS — first structured data attempt |
| -106 | Dec 2025 | Vertex AI + Google ecosystem |
| -81 | Jan 2026 | ADK agent framework |
| -62 | Jan 2026 | Pydantic structured models |
| 0 | Feb 12 | **Moos born** — categorical graph kernel |
| 40–70 | Mar 2026 | Collider sprint: hypergraph + ontology |
| 114 | Mar 14 | FFS0_Factory established |
| 135 | Mar 21 | HP laptop workstation (this workspace) |
| 141 | Mar 22 | Calendar goes live, Option B, kb/ purified |
| 142 | Mar 23 | **Act week starts** — PRG034 naturality harness |
| 143 | Mar 24 | Studio photoshoot (PRG038 media) |
| 169 | Apr 19 | Hackathon demo target |

## Repository Layout

```
.agent/
  kb/                  Pure categorical space (hydration sources only)
    superset/          Ontology (28 types), schemas, sources
    instances/         S0/S2 infrastructure seeds (15 JSON files)
    industry/          S0 industry entities (providers, benchmarks, frameworks)
  dev/                 Development tooling, docs, reference
    design/            Architecture documents (carpet, firestarter, session-graph, ...)
    reference/         Papers, YouTube transcripts, calendar schema, evaluations
    archive/           Archived seeds (prg/calendar/keeps — now graph-native)
  cfg/                 Agent configs, provider registry, secrets policy
    agents/            Per-agent state files (3 agents)
  scripts/             Active PowerShell/Python utilities (6 scripts)
  workflows/           Operational runbooks (8 workflows)
  skills/              Claude Code skills (49 dirs)
  secrets/             API keys (gitignored)
moos/                  -> ../moos (public kernel repo)
.mcp.json              Kernel MCP server config (SSE on :8080)
.github/workflows/     CI — Go vet + test + cross-platform build
```

## Key Design Documents

| Document | Core Concept |
|----------|-------------|
| The Carpet | `state(t) = fold(log[0..t])` — syntax vs functors, one principle |
| Firestarter | Graph growth agent: `F_fire: (C × Disk) → C` — classify + hydrate |
| Categorical Space | CS vs HG, 5 causal invariancies, PTP inventory |
| Session Graph | Session as meta-program, workspace-as-payload, multi-kernel sync |
| Cloverleaf | Non-interaction invariant, kernel leaves + hub topology |
| Inspect/Run | GPU = discovery (ephemeral), CPU = proven (serial), Log = memory |
| PTP Bindings | Port-to-Port 4-tuple reified as S1 node, BindingCategories |

All design docs in `.agent/dev/design/`.

## Five Strata

| Stratum | Name | Semantics |
|---------|------|-----------|
| S0 | Authored | Human-written seeds, industry data |
| S1 | Validated | Schema-checked, operad-approved |
| S2 | Materialized | Hydrated into kernel graph |
| S3 | Evaluated | Functor outputs, catamorphism results |
| S4 | Projected | UI, filesystem, embeddings — NEVER ground truth |

## Agents

| Agent | Role | IDE |
|-------|------|-----|
| Claude Code | Strategic lead — planning, delegation, research | Claude Desktop |
| VS Code AI | Execution — Go code, testing, git | VS Code (Sonnet 4.6) |
| Antigraviti | UX testing — HTTP verification, Explorer | Antigraviti (Gemini 3.1 Pro) |

Sessions are graph nodes (`agent_session` type). PRG tasks are graph nodes (`prg_task` type). The kernel graph is truth — not files, not channels, not markdown.

## Quick Start

```powershell
# Clone both repos side by side
git clone https://github.com/MSD21091969/ffs0-factory-super.git
git clone https://github.com/MSD21091969/moos.git

# Boot kernel with KB hydration
cd moos/platform/kernel
go run ./cmd/moos --kb "../../ffs0-factory-super/.agent/kb" --hydrate

# Verify
Invoke-RestMethod http://localhost:8000/healthz
```

## License

This repository is private. The public kernel code is MIT licensed at [MSD21091969/moos](https://github.com/MSD21091969/moos).
