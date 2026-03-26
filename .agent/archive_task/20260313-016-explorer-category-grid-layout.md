# Task 016 — Explorer Category Grid Layout

**ID:** 20260313-016
**Priority:** P1
**Status:** ready
**Depends:** 014 ✅, 015 ✅
**Source:** Antigraviti UX feedback — "layout not human readable"
**Effort:** ~40 lines Go (ui_lens.go)

---

## Problem

`hashPosition()` in `internal/functor/ui_lens.go` uses FNV hash of URN → 20×20 grid with 60px spacing. With 118 nodes this produces random scatter — no semantic grouping, frequent visual collisions, unreadable labels.

## Solution

Replace `hashPosition()` with `categoryGridPosition()` that uses two semantic axes:

- **X-axis:** `broadCategory` group (7 columns: identity, structure, protocol, compute, intelligence, deployment, meta)
- **Y-axis:** stratum band (S0 top → S4 bottom)
- **Within-cell:** offset by node index within that (category, stratum) bucket to prevent overlap

## Implementation

### 1. Replace `hashPosition` in `internal/functor/ui_lens.go`

```go
// categoryGridPosition places nodes on a semantic grid.
// X = broad_category column, Y = stratum row, with intra-cell offset.
func categoryGridPosition(tid cat.TypeID, stratum string, index int) (float64, float64) {
    catIndex := categoryColumnIndex(broadCategory(tid))
    stratIndex := stratumRowIndex(stratum)

    // Column spacing, row spacing
    colW := 180.0
    rowH := 200.0

    // Intra-cell: wrap nodes in a small grid within the cell
    cellCols := 4
    cx := float64(index % cellCols) * 40
    cy := float64(index / cellCols) * 40

    return float64(catIndex)*colW + cx + 40, float64(stratIndex)*rowH + cy + 40
}

func categoryColumnIndex(cat string) int {
    switch cat {
    case "identity":     return 0
    case "structure":    return 1
    case "protocol":     return 2
    case "compute":      return 3
    case "intelligence": return 4
    case "deployment":   return 5
    case "meta":         return 6
    default:             return 7
    }
}

func stratumRowIndex(s string) int {
    switch s {
    case "S0": return 0
    case "S1": return 1
    case "S2": return 2
    case "S3": return 3
    case "S4": return 4
    default:   return 2
    }
}
```

### 2. Update `Project()` call site

Currently:
```go
x, y := hashPosition(string(n.URN))
```

Change to track per-bucket index:
```go
bucketKey := broadCategory(n.TypeID) + ":" + string(n.Stratum)
bucketCount[bucketKey]++
x, y := categoryGridPosition(n.TypeID, string(n.Stratum), bucketCount[bucketKey]-1)
```

Add `bucketCount := map[string]int{}` at top of `Project()`.

### 3. Update SVG viewBox

The canvas area changes from ~1200×1200 to ~1400×1000 (7 cols × 180 + margin, 5 rows × 200 + margin). The client already has pan/zoom (Task 014), so this auto-adjusts. But set a reasonable initial viewBox:

In `explorer.html`, if there's a hardcoded viewBox, update to `0 0 1500 1100`.

### 4. Update test

`ui_lens_test.go` has a determinism test — it should still pass since `categoryGridPosition` is deterministic. Verify positions changed but are still reproducible across calls.

## Acceptance Criteria

- [ ] Nodes visually grouped by broad_category (columns)
- [ ] Strata form visible horizontal bands (S0 top, S4 bottom)
- [ ] No node overlap within a cell (intra-cell offset works)
- [ ] Labels readable without zooming on default view
- [ ] Pan/zoom (Task 014) still works
- [ ] Search dim (Task 014) still works
- [ ] `go test ./...` all green
- [ ] Deterministic layout (same positions on every reload)

## Categorical Note

This is purely a FUN02 presentation concern — the projection F_ui: C → React maps graph structure to visual layout. Position is NOT categorical structure (comment already in code). We're just making the projection more useful by encoding `broadCategory` and `stratum` metadata as spatial coordinates.
