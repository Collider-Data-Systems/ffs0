# CLAUDE.md — ffs0 Factory Workspace

## Identity

**mo:os** — categorical graph kernel for local-first sovereign AI.

- User: `urn:moos:user:sam` (superadmin, hp-laptop)
- Workspace: `C:\Users\maass\HPlaptop\ffs0\` — agent, kb, config, tooling
- Kernel code: `C:\Users\maass\HPlaptop\moos\` — separate repo (`../moos` in workspace)
- T=0 = Nov 1, 2025. Today ≈ T=150 (Mar 31, 2026).

## Current Status: FULL REBUILD (T=150)

The system is being rebuilt from scratch. Categories are being redefined. The old kernel
(14,000+ wires, no system discipline) is archived. The `moos` repo may be cloned as
reference but new kernel code will be written. Old PRGs are retired — new ones will emerge.

## Core Claim

Four invariant morphisms over a typed hypergraph are sufficient to model any sovereign AI system:

```
ADD · LINK · MUTATE · UNLINK   →   state(t) = fold(log[0..t])
```

## Architecture

| Space | Role |
|-------|------|
| Categorical Space (CS) | Grammar — types, morphisms, functors |
| Hypergraph Instance (HG) | Live state — kernel at `:8000` |

Three-layer tower: `Industry (C) → Superset (𝓞) → Kernel (𝓞_K)`

Five strata: S0 Authored → S1 Validated → S2 Materialized → S3 Evaluated → S4 Projected

**S4 is never ground truth. The kernel graph is truth — not files, not projections.**

## Skills — use these for domain reasoning

| Skill | When |
|-------|------|
| `/moos-domain-expert` | Any design question: morphisms, strata, invariants, category theory, triangle |
| `/golang-backend-development` | Go kernel code: pure core vs effect shell, testing, zero deps |
| `/harmony-hdc` | HDC/VSA: wire encoding, GPU mapping, binding/bundling/permutation |
| `/quic-graph-streaming` | Transport: strata-to-stream mapping, log replication, MCP over QUIC |
| `/http3-quic-transport` | HTTP/3 kernel integration, dual-stack topology |

## Agents

| Agent | Role | Tool |
|-------|------|------|
| Claude Code (you) | Strategic lead — planning, architecture, research | Claude Desktop |
| VS Code AI | Execution — Go code, testing, git | VS Code Sonnet 4.6 |
| Antigraviti | UX testing — HTTP, Explorer verification | Antigraviti |

## Repo Layout

```
ffs0/                     ← this repo (agent workspace)
  CLAUDE.md               ← you are here
  moos.yaml               ← kernel boot config (ports 8000/8080)
  .mcp.json               ← MCP SSE → localhost:8080/sse
  .agent/
    kb/
      superset/           ← ontology (being rebuilt)
      reference/          ← calendar, drive, tasks
    dev/design/           ← architecture docs (carpet, firestarter, cloverleaf, ...)
    cfg/                  ← agent configs, users.yaml, api_providers.yaml
    skills/               ← Claude Code skill packs (9 skills)
    scripts/              ← PowerShell/Python utilities
    secrets/              ← api_keys.env (gitignored)

moos/                     ← kernel code (../moos, separate repo)
  platform/kernel/        ← Go source — being rebuilt
```

## Key Ports

- `:8000` — Kernel HTTP API
- `:8080` — MCP SSE bridge

## Invariants (never break)

1. Append-only morphism log — never mutate history
2. Causal commutativity — independent morphisms commute
3. Functor naturality — `Project(Apply(M, S)) == Apply(M', Project(S))`
4. Log replay determinism — same log → same state
5. Identity stability — `urn(x) = x`
