---
name: golang-backend-development
description: "Use when editing Go code in moos/platform/kernel for the incidence-first kernel (Node, Binding, Property), grammar/seed loading, rewrite plans, proof HTTP server, and tests."
---

# Go Backend Development - Current Kernel

Use this skill for code changes under `moos/platform/kernel`.

## Current architecture

Pure core (no IO):

```
internal/model   - Node, Port, Binding, Property, incidence primitives
internal/cs      - grammar registry and grammar.json loader
internal/hg      - in-memory graph store and seed loader
internal/rewrite - rewrite plans and apply engine
internal/fiber   - connected-scope extraction
```

Effect shell (IO allowed):

```
internal/demo  - boot from grammar + seed + demo plans
internal/proof - HTTP endpoints and explorer page
cmd/moos       - server boot and port fallback
```

## Rules

1. Do not reintroduce generic payload bags.
2. Keep semantics relation-first: Node + Port + Binding + Property.
3. Property writes must be validated by `PropertySpec` when declared.
4. Keep core packages deterministic and side-effect free.
5. Prefer table-driven tests for all new behavior.

## Current source-of-truth files

1. `grammar.json` for admissible node types, ports, binding kinds, and property specs.
2. `seed.json` for initial realized graph state.

## Required checks after changes

1. `go test ./internal/...`
2. If HTTP surface changed, verify:
   1. `GET /healthz`
   2. `GET /nodes`
   3. `GET /bindings`
   4. `GET /grammar`
   5. `GET /explorer`

## Common change patterns

### Add grammar feature

1. Update `grammar.json`.
2. Extend `internal/cs` loader/validation if schema changed.
3. Add loader tests.

### Add seeded behavior

1. Update `seed.json`.
2. Ensure `hg.LoadSeed` still enforces order: nodes -> properties -> bindings.
3. Add seed loader tests for both success and rejection paths.

### Add rewrite capability

1. Extend `internal/rewrite/plan.go`.
2. Keep clone-apply-replace flow in proof server.
3. Add rewrite tests and endpoint tests.
