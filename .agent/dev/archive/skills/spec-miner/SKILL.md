---
name: spec-miner
description: Ontology extraction and doctrine parsing for mo:os. Use when analyzing ontology.json, extracting TypeSpecs, validating doctrine compliance, or syncing knowledge base with kernel.
---

# Spec Miner — Ontology & Doctrine Parser

Expert on extracting, validating, and syncing specifications between the knowledge base (SOT) and the kernel implementation.

---

## SOT Hierarchy (priority order)

1. **`superset/ontology.json`** — always wins
2. **`doctrine/*.md`** — prose specifications
3. **`design/*.md`** — timestamped decisions (latest wins)
4. **`instances/*.json`** — must conform to ontology
5. **Root `CLAUDE.md`** — workspace policy
6. **Task files** — reference SOTs, never restate

---

## Ontology Structure (ontology.json)

```json
{
  "kinds": [...],           // 21 type definitions
  "morphisms": [...],       // 16 morphism types
  "natural_transformations": [...],  // 4 NTs
  "functors": [...]         // 5 sanctioned functors
}
```

### 21 Kinds (current)
Extract and validate against `internal/operad/registry.go`. Each kind defines:
- `name` — PascalCase type name
- `ports` — array of named connection points with arity
- `stratum` — default initial stratum (S0-S4)
- `container` — boolean (can own children via full subcategory?)

---

## Validation Tasks

### Ontology ↔ Kernel Sync
```
For each kind in ontology.json:
  ✓ TypeSpec exists in operad/registry.go
  ✓ Port names match
  ✓ Arity constraints match
  ✓ Container flag matches

For each TypeSpec in registry.go:
  ✓ Kind exists in ontology.json
  ✓ No undocumented extensions
```

### Doctrine ↔ Ontology Sync
```
For each doctrine/*.md:
  ✓ Referenced kinds exist in ontology.json
  ✓ Referenced morphisms are one of the 4
  ✓ Referenced functors are one of the 5
  ✓ No contradictions with ontology
```

### Instance Validation
```
For each instances/*.json:
  ✓ URN format: urn:moos:{kind}:{name}
  ✓ Kind exists in ontology.json
  ✓ Required ports populated
  ✓ Payload conforms to kind schema
```

---

## Extraction Patterns

### From ontology.json → TypeSpec code
```go
TypeSpec{
    Kind:      "KindName",
    Ports:     []Port{{Name: "in", Arity: 1}, {Name: "out", Arity: -1}},
    Container: true,
}
```

### From doctrine markdown → validation rules
Parse doctrine headers, extract MUST/SHOULD/MAY requirements, map to testable assertions.

---

## Key Files

| File | Purpose |
|------|---------|
| `.agent/knowledge_base/superset/ontology.json` | Ground truth |
| `.agent/knowledge_base/doctrine/*.md` | Prose specifications |
| `.agent/knowledge_base/instances/*.json` | Seed data |
| `platform/kernel/internal/operad/registry.go` | Kernel TypeSpecs |
| `.agent/knowledge_base/archive/design.*/*.md` | Design decisions |
