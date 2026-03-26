# Task 019 — Documentation Polish

**ID:** 20260314-019
**Priority:** P1
**Status:** ready
**Depends:** none (parallel with 017-018)
**Source:** 4-week MVP plan, Week 4 Day 3-4
**Effort:** ~2 hours review + light edits

---

## Problem

Exported Go functions lack godoc comments. DEVELOPERS.md may need updates for public audience.

## Scope

### 1. Godoc Comments

Add doc comments to all exported functions in:
- `internal/cat/` — Node, Wire, GraphState, Envelope types
- `internal/fold/` — Evaluate, Replay, EvaluateProgram
- `internal/shell/` — Runtime, Apply, ApplyProgram, Subscribe, ScopedSubgraph
- `internal/operad/` — Registry, TypeSpec, Validate
- `internal/transport/` — NewServer, route handlers
- `internal/hydration/` — HydrateAll, LoadInstanceFile, Materialize
- `internal/mcp/` — NewMCPServer, tool handlers
- `internal/functor/` — UILens.Project, BenchmarkFunctor

### 2. DEVELOPERS.md Review

- Verify no internal path references
- Ensure architecture description matches current code (16 routes, not 12)
- Verify package descriptions match actual content

### 3. Verify `go doc` Output

Run `go doc ./...` — should produce clean, informative output for all packages.

## Acceptance Criteria

- [ ] All exported types and functions have doc comments
- [ ] `go doc ./platform/kernel/internal/cat` shows clean output
- [ ] DEVELOPERS.md is accurate and public-safe
- [ ] No internal workspace paths in any tracked file

## Files

- Edit: all `internal/*/` Go files (add comments only)
- Edit: `DEVELOPERS.md` (if needed)
