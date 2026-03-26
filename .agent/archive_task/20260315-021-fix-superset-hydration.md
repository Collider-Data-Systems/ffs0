# Task 021 — Fix Superset Hydration Path

**ID:** 20260315-021
**Priority:** P0 (blocks fresh clone boot)
**Status:** ready
**Depends:** none
**Source:** KB restructure — glossary/categories/kinds moved instances/ → superset/
**Effort:** ~10 lines Go

---

## Problem

`hydration/batch.go` InstanceOrder references `glossary.json`, `categories.json`, `kinds.json` in the `instances/` directory. These files were moved to `superset/` during KB restructure. Current kernel boots fine because `morphism-log.jsonl` has the 51 `urn:moos:cat:*` nodes replayed — but a fresh clone with `--hydrate` would skip them (logged as "skip: file not found").

## Solution

Two options (pick the simpler one):

### Option A: Dual-path hydration (preferred)
Extend `HydrateAll()` to also load from `superset/` directory. The `--kb` root already points to the KB root containing both `instances/` and `superset/`. Add a second pass:

```go
// After instance hydration
supersetFiles := []string{"glossary.json", "categories.json", "kinds.json"}
for _, f := range supersetFiles {
    path := filepath.Join(kbRoot, "superset", f)
    // same LoadInstanceFile logic
}
```

### Option B: Symlinks in instances/
Create symlinks `instances/glossary.json → ../superset/glossary.json` etc. No Go changes. But fragile on Windows.

## Acceptance Criteria

- [ ] `go run ./cmd/moos --kb <path> --hydrate` with EMPTY morphism log loads all 51 `urn:moos:cat:*` nodes
- [ ] `/healthz` shows nodes ≥ 118 after fresh hydration
- [ ] `go test ./...` all green
- [ ] No changes to superset/*.json file format

## Files

- Edit: `internal/hydration/batch.go` (add superset path to load order)
- Possibly: `internal/hydration/loader.go` (if superset JSON schema differs from instance schema)

## Commit

`fix: hydrate superset glossary/categories/kinds from correct path [task:20260315-021]`
