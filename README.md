# ffs0

Private workspace for [mo:os](https://github.com/MSD21091969/moos) — a categorical graph kernel for local-first sovereign AI.

## The Claim

Four invariant morphisms (ADD, LINK, MUTATE, UNLINK) over a typed hypergraph are sufficient to model any sovereign AI system. State at any time is a deterministic fold over an append-only morphism log:

```
state(t) = fold(log[0..t])
```

The kernel graph is the source of truth. Everything else — files, UIs, projections — derives from it.

## Architecture

**Two spaces, one principle:**

| Space                        | What                      | Where                                                            |
| ---------------------------- | ------------------------- | ---------------------------------------------------------------- |
| **Categorical Space (CS)**   | Grammar of what CAN exist | `kb/superset/ontology.json` — 28 types, 17 morphisms, 5 functors |
| **Hypergraph Instance (HG)** | What DOES exist           | Kernel `:8000` — 300+ nodes, 180+ wires                          |

The ontology defines the syntax category. Functors project structure-preserving views into target categories (filesystem, UI, embeddings, benchmarks). The separation of syntax and semantics IS the categorical discipline.

**Three-layer tower:**

```
Industry (C)        — external tech landscape (providers, benchmarks, frameworks)
    ↓ classify
Superset (𝓞)       — 28-type mo:os ontology (grammar)
    ↓ compile
Kernel (𝓞_K)       — 5 compiled colors (minimal runtime dependency)
```

## Current State — T=150 (March 31, 2026) — FULL REBUILD

The prior kernel (undisciplined graph, 14K+ wires) is archived. The system is being
rebuilt from scratch: categories redefined, kernel rewritten, new PRGs to be defined.

The `moos` repo may be cloned as reference. New kernel code is being written.

**Five Causal Invariants (foundational — unchanged):**

1. Church-Rosser commutativity — order-independent concurrent morphisms
2. Functor naturality — `Project(Apply(M, S)) == Apply(M', Project(S))`
3. Identity stability — `urn(x) = x`
4. Log replay determinism — same log always produces same state
5. Append-only log — never mutate or delete morphism history

## Timeline

| T     | Date     | Milestone                                       |
| ----- | -------- | ----------------------------------------------- |
| -194  | Sep 2025 | ChatGPT era begins                              |
| -155  | Oct 2025 | HAL/MDS — first structured data attempt         |
| -106  | Dec 2025 | Vertex AI + Google ecosystem                    |
| -81   | Jan 2026 | ADK agent framework                             |
| -62   | Jan 2026 | Pydantic structured models                      |
| 0     | Feb 12   | **Moos born** — categorical graph kernel        |
| 40–70 | Mar 2026 | Collider sprint: hypergraph + ontology          |
| 114   | Mar 14   | FFS0_Factory established                        |
| 135   | Mar 21   | HP laptop workstation (this workspace)          |
| 141   | Mar 22   | Calendar goes live, Option B, kb/ purified      |
| 142   | Mar 23   | Act week: PRG034–037 gate sequence              |
| 150   | Mar 31   | **Full rebuild begins** — new categories, new kernel |

## Repository Layout

```
CLAUDE.md              Claude Code context (you are here)
.agent/
  kb/                  Pure categorical space (hydration sources only)
    superset/          Ontology (being rebuilt)
    reference/         Reference data (calendar, drive, tasks)
  dev/                 Development tooling, docs, reference
    design/            Architecture documents (carpet, firestarter, session-graph, ...)
  cfg/                 Agent configs, provider registry, secrets policy
  scripts/             Active PowerShell/Python utilities
  workflows/           Operational runbooks
  skills/              Claude Code skills (9 packs)
  secrets/             API keys (gitignored)
moos/                  -> ../moos (kernel repo — reference during rebuild)
.mcp.json              Kernel MCP server config (SSE on :8080)
```

## Key Design Documents

| Document          | Core Concept                                                      |
| ----------------- | ----------------------------------------------------------------- |
| The Carpet        | `state(t) = fold(log[0..t])` — syntax vs functors, one principle  |
| Firestarter       | Graph growth agent: `F_fire: (C × Disk) → C` — classify + hydrate |
| Categorical Space | CS vs HG, 5 causal invariancies, PTP inventory                    |
| Session Graph     | Session as meta-program, workspace-as-payload, multi-kernel sync  |
| Cloverleaf        | Non-interaction invariant, kernel leaves + hub topology           |
| Inspect/Run       | GPU = discovery (ephemeral), CPU = proven (serial), Log = memory  |
| PTP Bindings      | Port-to-Port 4-tuple reified as S1 node, BindingCategories        |

All design docs in `.agent/dev/design/`.

## Five Strata

| Stratum | Name         | Semantics                                       |
| ------- | ------------ | ----------------------------------------------- |
| S0      | Authored     | Human-written seeds, industry data              |
| S1      | Validated    | Schema-checked, operad-approved                 |
| S2      | Materialized | Hydrated into kernel graph                      |
| S3      | Evaluated    | Functor outputs, catamorphism results           |
| S4      | Projected    | UI, filesystem, embeddings — NEVER ground truth |

## Agents

| Agent       | Role                                            | IDE                          |
| ----------- | ----------------------------------------------- | ---------------------------- |
| Claude Code | Strategic lead — planning, delegation, research | Claude Desktop               |
| VS Code AI  | Execution — Go code, testing, git               | VS Code (Sonnet 4.6)         |
| Antigraviti | UX testing — HTTP verification, Explorer        | Antigraviti (Gemini 3.1 Pro) |

Sessions are graph nodes (`agent_session` type). PRG tasks are graph nodes (`prg_task` type). The kernel graph is truth — not files, not channels, not markdown.

## Quick Start

```powershell
# Clone both repos side by side
git clone https://github.com/MSD21091969/ffs0.git
git clone https://github.com/MSD21091969/moos.git

# Boot kernel with KB hydration
cd moos/platform/kernel
go run ./cmd/moos --kb "../../ffs0/.agent/kb" --hydrate

# Verify
Invoke-RestMethod http://localhost:8000/healthz
Invoke-RestMethod http://localhost:8080/healthz
```

## VS Code Daily Fast Path

Use the workspace tasks in this order:

1. `Auto: startup bootstrap`
2. `Kernel: check health`
3. `MCP: check health`
4. `MCP: SSE endpoint smoke`
5. `Kernel: test all`

The root `.mcp.json` points MCP clients to the local SSE bridge on `http://localhost:8080/sse`.

## License

This repository is private. The public kernel code is MIT licensed at [MSD21091969/moos](https://github.com/MSD21091969/moos).
