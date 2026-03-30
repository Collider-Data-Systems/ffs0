# Superset Pipeline — Single SOT, One Direction

**Date:** 2026-03-17
**Status:** Active
**Program:** P2 (Sam + Claude Code)
**Task:** 031

---

## Decision

The KB superset is a typed pipeline, not a flat file collection. `ontology.json` is the single SOT. Everything downstream — schemas, operad registry, satellite nodes — is generated from it. No parallel tracks.

## Problem

superset/ had 12 files and two competing validation systems:
1. **JSON Schema files** in `schemas/` — static, decorative, hardcoded type_id whitelists
2. **Operad registry** in Go (`internal/operad/`) — runtime gate, the real validator

They don't know about each other. Adding OBJ22 to ontology.json requires manual updates in both places. Industry files (`industry/*.json`) have no schema at all — no S0 gate.

## Pipeline Architecture

```
ontology.json (SOT)
  ├──generates──→ operad registry (runtime gate, Go)
  ├──generates──→ schemas per type_id (pre-flight, JSON Schema)
  ├──generates──→ satellite nodes (glossary, categories, kinds — at boot)
  │
  ▼
sources.json (admissibility gate — which external sources feed which OBJ types)
  │
  ▼
industry/*.json (S0 — validate: source ∈ sources.json, entries declare ontology_targets)
  │         NEW: industry.schema.json enforces this
  ▼
instances/*.json (S2 — validate: type_id schema + stratum + optional industry_ref)
  │         UPDATED: instance.schema.json adds industry_source, industry_ref
  ▼
kernel hydrate (validate: operad port/wire/stratum)
  │
  ▼
graph state
```

## What Changed

### Deleted (6 files — duplication or generated artifacts)
- `superset/schema.json` — validated only 4 fields, useless
- `superset/ontology.csv` — CSV export, generated artifact
- `superset/changelog.jsonl` — git log does this
- `superset/categories.json` — 22 CAT entries extracted from ontology.json
- `superset/kinds.json` — 21 OBJ entries extracted from ontology.json
- `superset/glossary.json` — 8 math vocab entries → folded into ontology.json

### Created
- `superset/schemas/industry.schema.json` — S0 gate for industry files
- `ontology.json` gains `glossary` array (8 entries from deleted glossary.json)

### Updated
- `superset/schemas/instance.schema.json` — added optional `industry_source`, `industry_ref`, `role`, `canonicality` fields

### Kept (unchanged)
- `superset/ontology.json` — SOT
- `superset/sources.json` — admissibility gate
- `superset/schemas/ontology.schema.json` — validates ontology structure
- `superset/schemas/graph.schema.json` — validates Node/Wire/Envelope
- `superset/schemas/config.schema.json` — validates cfg/ files

### VS Code implements (Task 031, Program 1)
- `HydrateFromOntology()` — kernel generates glossary/categories/kinds nodes at boot from ontology.json
- Update `HydrateAll()` to call it
- Tests

## Superset After Cleanup

```
superset/
  ontology.json          ← SOT (objects, morphisms, NTs, functors, categories, glossary)
  sources.json           ← admissibility gate (12 authoritative sources)
  schemas/
    ontology.schema.json ← validates ontology.json structure
    instance.schema.json ← validates instances/*.json (updated)
    industry.schema.json ← validates industry/*.json (new)
    graph.schema.json    ← validates Node/Wire/Envelope
    config.schema.json   ← validates cfg/ files
```

7 files. Was 12. Everything traces to ontology.json.

## Program Flow

```
P2 (leadoff) → ontology decisions
  → P3 (handoff) → VS Code harvests industry data (constrained by sources.json)
    → P1 (triangle) → instances → kernel hydrate → graph state
      → functors/lenses → patterns stabilize
        → P4 (promote to kernel code)
          → P5 (federate)
            → P6 (distributed HDC compute)
```

## SOT References
- `kb/superset/ontology.json` — type system
- `kb/superset/sources.json` — admissibility
- `kb/design/20260314-vision-architecture.md` — full architecture
- `kb/reference/20260316_KBKERGHPRG.txt` — KBKERHGPRG cycle
