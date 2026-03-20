# Task 032b — Hydration Bug Fix: Source Seeding + CLASSIFIES Port Validation

**Date:** 2026-03-17
**Status:** COMPLETE
**Program:** 1 (triangle implementation)
**Depends on:** Task 032 Workstream B (911da8a — shipped but broken at runtime)
**Parent:** Task 032

---

## Problem

Task 032 Workstream B (911da8a) passes `go test ./...` but fails at runtime during kernel boot + hydration. Two bugs:

### Bug 1: Source seeding — invalid stratum

```
[seed] source add urn:moos:source:artificial-analysis: invalid stratum: type node_container does not admit stratum S1
```

**Root cause:** `cmd/moos/main.go:257-258` seeds source nodes as `TypeID: "node_container"` at `Stratum: cat.S1`. But OBJ05 (NodeContainer) only allows `["S2", "S3"]`. All 12 source nodes fail to create. All OWNS links from kernel→source also fail (target not found).

**Impact:** No source nodes in graph. Industry hydration OWNS links (source→industry) also fail silently because source nodes don't exist.

### Bug 2: CLASSIFIES links — invalid port on target

```
[hydration] industry classify link urn:moos:industry:industry-providers:ind-provider-anthropic -> urn:moos:provider:anthropic: invalid port: target type provider does not define port source
```

**Root cause:** MOR17 CLASSIFIES uses `TargetPort: "source"` (from decomposition). The operad derives input ports from `target_connections`. Provider (OBJ17) has `target_connections: ["OWNS"]` — no `"CLASSIFIES"` entry. So `provider` has no `source` input port. The operad correctly rejects the LINK.

The `target: "any"` fallback in `loader.go:119` adds all types as admissible targets on the SOURCE side, but the TARGET types still need the `source` input port declared via `target_connections`.

**Impact:** Industry entity nodes ARE created (S0 ADDs succeed), but zero CLASSIFIES wires exist. The classifying functor is broken.

### Net result

- Industry entity nodes: created (S0 ADDs work) but have NO wires
- Source nodes: zero (all fail stratum validation)
- CLASSIFIES wires: zero (target port validation fails)
- OWNS wires (source→industry): zero (source nodes don't exist)
- Graph: 214 nodes, 81 wires — same as pre-032 log replay

---

## Fix

### Fix 1: Source node type + stratum

**Option A (recommended):** Change source seeding to use `Stratum: cat.S2` instead of `cat.S1`. Sources are materialized operational nodes, not authored declarations. S2 is semantically correct and `node_container` allows it.

**Option B:** Create a new OBJ23 `SourceNode` type with `allowed_strata: ["S1", "S2"]`. More principled but heavier. Discuss with Sam if preferred.

**File:** `moos/platform/kernel/cmd/moos/main.go` line 258

### Fix 2: CLASSIFIES target port

Add `"CLASSIFIES"` to `target_connections` of every object type that should be a valid CLASSIFIES target. At minimum:

- OBJ17 Provider: `target_connections: ["OWNS", "CLASSIFIES"]`
- OBJ06 AgnosticModel: `target_connections: ["OWNS", "CAN_SCHEDULE", "CAN_ROUTE", "CLASSIFIES"]`
- OBJ07 SystemTool: `target_connections: ["OWNS", "CAN_HYDRATE", "CAN_ROUTE", "CLASSIFIES"]`
- OBJ05 NodeContainer: `target_connections: ["OWNS", "CAN_HYDRATE", "LINK_NODES", "ADD_NODE_CONTAINER", "CLASSIFIES"]`

This gives these types the `source` input port (derived from MOR17 decomposition `LINK(industry_node, 'classifies', instance_node, 'source')`).

**File:** `.agent/kb/superset/ontology.json` — add `"CLASSIFIES"` to `target_connections` arrays

### Fix 3: Update tests

Existing tests pass because they test in isolation (mock state, no operad). Need integration test that boots kernel with real KB and verifies:
- Source nodes exist at S2
- Industry entity nodes exist at S0
- CLASSIFIES wires connect industry→instance
- `healthz` shows increased node/wire counts

---

## Verification

1. `go test ./...` — all green
2. Boot: `go run ./cmd/moos --kb ... --hydrate`
3. No errors in boot log (grep for `invalid stratum` and `invalid port`)
4. `curl http://localhost:8000/healthz` — node count > 214, wire count > 81
5. Industry entity nodes present: `curl /state` | grep `industry_entity`
6. CLASSIFIES wires present: `curl /state` | grep `classifies`
7. Source nodes present: `curl /state` | grep `urn:moos:source:`

---

## Key Files

| File | Change |
|------|--------|
| `moos/platform/kernel/cmd/moos/main.go` | Fix 1: source stratum S1→S2 |
| `.agent/kb/superset/ontology.json` | Fix 2: add CLASSIFIES to target_connections |
| `moos/platform/kernel/internal/hydration/industry_test.go` | Fix 3: integration test |
