---
applyTo: "**"
---

# mo:os — GitHub Copilot Review Instructions

## What This Repo Is

Private workspace for the mo:os categorical graph kernel.
The public kernel code is at [MSD21091969/moos](https://github.com/MSD21091969/moos).
This repo contains: knowledge base (`.agent/kb/`), agent channels, configuration, and tooling.

## Core Model

The kernel graph is the source of truth. `state(t) = fold(log[0..t])`.

**4 invariant morphisms** — the ONLY way to change graph state:
- ADD: create node
- LINK: create wire (typed 4-tuple: src_urn, src_port, tgt_urn, tgt_port)
- MUTATE: update node payload
- UNLINK: remove wire

**28 ontology types** (OBJ01-OBJ28) defined in `kb/superset/ontology.json`.
Types OBJ24-28 are operational: `agent_session`, `prg_task`, `calendar_event`, `keep_note`, `channel_message`.

## File Categories

| Pattern | Category | Review focus |
|---------|----------|-------------|
| `kb/superset/ontology.json` | Type registry | Schema correctness, type_id uniqueness |
| `kb/instances/*.json` | Hydration seeds | Valid `id`, `type_id`, `stratum` per ontology |
| `kb/design/*.md` | Design docs | Consistency with ontology, correct terminology |
| `channels/*.md` | S4 projections | Prepend pattern (newest top), correct timestamps |
| `cfg/**` | Agent config | Valid JSON, no secrets in committed files |
| `scripts/*.ps1` | Automation | PowerShell correctness |

## Vocabulary

| Term | Meaning |
|------|---------|
| CDMU | The 4 invariant morphisms: Create(ADD), Define(LINK), Mutate, Unlink |
| PTP | Port-to-Port — typed wire connection (4-tuple) |
| S0-S4 | Strata: Authored, Validated, Materialized, Evaluated, Projected |
| SOT | Source of Truth — the kernel graph, not files |
| HG | Hypergraph — the kernel's live graph state |
| KG | Knowledge Graph — file-based KB (seeds, not truth) |
| PRG | Progression — task tracking now as `prg_task` graph nodes |
| URN | `urn:moos:<domain>:<name>` — unique node identity |

## Go Kernel Standards (moos repo)

- Zero external dependencies (stdlib only)
- Go 1.26+ with ServeMux pattern matching
- `internal/` packages: `cat`, `shell`, `transport`, `mcp`, `hydration`, `operad`
- Tests: `go test -v ./...` — all packages must pass
- The pure core (`cat/`) has no I/O — effects live in `shell/`

## What NOT to Flag

- `.agent/channels/*.md` growing large — they are append-only logs
- Payload content in `instances/*.json` — these are user-authored S0 data
- `.agent/skills/` folder structure — these are Claude Code IDE skills, not kernel code
- `.agent/kb/reference/` content — external reference material
- `stratum` field values — these are validated by the kernel's operad registry
- `broad_category` field — organizational grouping, not enforced constraint
