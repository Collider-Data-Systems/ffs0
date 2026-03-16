# Task 024 — Lens Rules HTTP Routes

**ID:** 20260315-024
**Priority:** P1
**Status:** ready
**Depends:** 023 (lens package)
**Source:** v0.2 planning 2026-03-15
**Effort:** ~40 lines Go

---

## Problem

The lens package (Task 023) has no HTTP surface. The Data Lens Explorer needs endpoints to fetch filtered graph state.

## Solution

Add `GET /state/lens` and `POST /state/lens` to the transport layer.

---

## Implementation

### In `server.go` — register two routes:

```go
s.mux.HandleFunc("GET /state/lens", s.handleLens)
s.mux.HandleFunc("POST /state/lens", s.handleLensPost)
```

### `handleLens` (GET):

1. Check for `scope` query param → if present, call `r.runtime.ScopedSubgraph(scope)`, else `r.runtime.State()`
2. Parse remaining query params via `lens.ParseQueryParams(r.URL.Query())`
3. Call `lens.Apply(state, spec)`
4. JSON-encode and return the filtered `GraphState`

### `handleLensPost` (POST):

1. Check for `scope` query param (even on POST, scope comes from URL)
2. Decode JSON body into `lens.LensSpec`
3. Call `lens.Apply(state, spec)`
4. JSON-encode and return

### Error handling:

- Invalid JSON body on POST: 400 with error message
- No errors possible on GET (unknown params ignored — forward-compatible)

### API examples:

```bash
# Simple: show only providers
GET /state/lens?kind=provider

# Composed: providers at S2 within alice's scope
GET /state/lens?scope=urn:moos:user:alice&kind=provider&stratum=S2

# Complex multi-rule (POST)
POST /state/lens
{"rules": [{"category": ["identity"]}, {"category": ["compute"]}], "mode": "union"}

# Neighborhood
GET /state/lens?neighborhood=urn:moos:provider:openai&depth=2
```

---

## Acceptance Criteria

- [ ] `GET /state/lens` returns filtered GraphState
- [ ] `POST /state/lens` accepts LensSpec body
- [ ] `?scope=` composes with lens filters (scope narrows first)
- [ ] No filters returns full state (identity)
- [ ] Invalid POST body returns 400
- [ ] `go test ./internal/transport/...` green
- [ ] Route count increases to 19

## Files

- Edit: `platform/kernel/internal/transport/server.go` (add routes + handlers)
- Edit: `platform/kernel/internal/transport/transport_test.go` (add lens endpoint tests)
- Import: `platform/kernel/internal/lens`

## Commit

`feat(transport): lens filter endpoints GET+POST /state/lens [task:20260315-024]`
