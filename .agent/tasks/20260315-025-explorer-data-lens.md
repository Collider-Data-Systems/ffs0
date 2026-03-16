# Task 025 — Explorer Data Lens (Full Rewrite)

**ID:** 20260315-025
**Priority:** P1
**Status:** ready
**Depends:** 024 (lens HTTP routes)
**Source:** v0.2 UX pivot 2026-03-15 — Sam: "I need to see data. structure. categories, objects, morphisms, lists."
**Effort:** ~500 lines HTML/JS (rewrite of 786-line explorer.html)

---

## Problem

Current Explorer is an SVG graph visualization + flat scroll list. Both are unusable:
- The scroll list shows 118 URNs with no grouping or hierarchy
- The SVG graph renders as an unreadable blob of dots
- No way to inspect node payloads, wire details, or ontology schema
- Graph visualization needs a proper hypergraph renderer (future project)

## Solution

**Full rewrite of `explorer.html`.** Replace SVG canvas and sidebar with a **tabbed data browser** — pure HTML tables, no visualization. Dark theme, monospace URNs, sticky headers.

**Two-lens architecture:**
- **Data Lens** (this task) — structured table browser, the default
- **Visual Lens** (future) — proper hypergraph renderer, separate project

---

## Implementation (explorer.html only — 0 Go changes)

### Layout

```
┌─────────────────────────────────────────────────────────┐
│ mo:os — Explorer (Data Lens)                    [stats] │
├─────────────────────────────────────────────────────────┤
│ [Kind ▼] [Stratum ▼] [Category ▼] [Scope ▼] [Search__] │
├─────────────────────────────────────────────────────────┤
│ [Objects] [Morphisms] [Ontology] [Log]                  │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  KIND: agent_spec (3)                      [collapse ▼] │
│  ┌──────────────────┬────┬────────┬───────┬───────┐     │
│  │ URN              │ S  │ Owner  │ Label │ Wires │     │
│  ├──────────────────┼────┼────────┼───────┼───────┤     │
│  │ urn:moos:agent:… │ S2 │ root   │ …     │ 4     │     │
│  └──────────────────┴────┴────────┴───────┴───────┘     │
│                                                         │
│  KIND: provider (5)                        [collapse ▼] │
│  ┌──────────────────┬────┬────────┬───────┬───────┐     │
│  │ ...                                              │   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Tab 1: Objects

- Data source: `GET /state` (or `GET /state/lens?...` when filtered)
- Group nodes by `type_id` (kind), sorted alphabetically
- Each group: collapsible section with header showing kind name + count
- Columns: URN (monospace), Stratum, Owner (from OWNS wires), Label (from payload), Wire count
- **Row expansion:** Click a row → inline expand showing:
  - Payload JSON (syntax-highlighted, `<pre>` with color)
  - Outgoing wires table: Target URN, Port, Morphism Type
  - Incoming wires table: Source URN, Port, Morphism Type
- Wire data: derive from the wires in GraphState (no extra fetch needed — wires are in `/state` response)

### Tab 2: Morphisms

- Data source: same `GET /state` response (use `wires` field)
- Group wires by morphism type (derive from `source_port` or `target_port`)
- Each group: collapsible section with type name + count
- Columns: Source URN, Target URN, Stratum (of source node)

### Tab 3: Ontology

- Data source: `GET /semantics/registry`
- **Kinds table:** one row per TypeID
  - Columns: ID (OBJ01-OBJ21), Kind name, Category (broadCategory), Allowed Strata, Ports (list)
- **Morphism Types table:** one row per morphism type
  - Columns: ID (MOR01-MOR16), Type name, Source Kinds, Target Kinds

### Tab 4: Log

- Data source: `GET /log`
- Table: newest first
- Columns: Sequence #, Actor URN, Target URN, Type (ADD/LINK/MUTATE/UNLINK), Timestamp
- Client-side filtering by actor, type (dropdown above table)

### Filter Strip (top bar)

Applies across Objects and Morphisms tabs:
- **Kind dropdown:** multi-select, lists all 21 kinds
- **Stratum dropdown:** checkboxes S0-S4
- **Category dropdown:** checkboxes for broadCategory values
- **Scope dropdown:** actor URNs (reuse Task 022 population logic)
- **Search:** text input, filters visible rows by URN/label substring match

When any filter changes:
1. Build query params from active filters
2. Fetch `GET /state/lens?kind=...&stratum=...` (uses Task 024 endpoint)
3. If scope selected, include `?scope=URN`
4. Re-render current tab with filtered data

### Styling

- Keep: dark theme (`#0b1220` background, `#dbe7ff` text) — matches current Explorer
- Keep: `go:embed` serving pattern, `/explorer` route
- Tables: `border-collapse: collapse`, `1px solid #333` borders
- Headers: `position: sticky; top: 0`, `background: #151a2e`
- Monospace: URNs and JSON payloads in `font-family: monospace`
- Collapsible sections: CSS `details/summary` or JS toggle
- Tab buttons: pill-style, active tab highlighted

### What to remove

- All SVG rendering code (circles, lines, labels, viewBox)
- Force-directed layout / category-grid positioning logic
- Drag/pan/zoom handlers (mousedown, mousemove, wheel)
- `graphStateToUIGraph()` client-side projection
- Sidebar scroll list
- Canvas area div
- All FUN02 UIGraph-specific code

### What to keep

- `go:embed` directive and static file serving
- Dark theme color palette
- `escapeHtml()` function (security — still needed for table content)
- Basic fetch/error handling patterns

---

## Acceptance Criteria

- [ ] Explorer loads at `/explorer` with 4 tabs
- [ ] Objects tab: 21 kind groups, each with correct node count, expandable rows
- [ ] Morphisms tab: grouped by type, shows source → target
- [ ] Ontology tab: 21 kinds + 16 morphism types from registry
- [ ] Log tab: morphism history, newest first, filterable
- [ ] Filter strip: kind/stratum/category/scope/search all functional
- [ ] Filters hit `GET /state/lens?...` endpoint (Task 024)
- [ ] Row expansion shows payload JSON + wire details
- [ ] No SVG, no canvas, no graph visualization
- [ ] Dark theme consistent, monospace URNs
- [ ] `go test ./...` still green (no Go changes)
- [ ] `escapeHtml()` used on all user-controlled content

## Files

- Rewrite: `platform/kernel/internal/transport/static/explorer.html`
- No Go changes

## Commit

`feat(explorer): data lens — tabbed table browser replaces SVG graph [task:20260315-025]`

---

## Why This Matters

The Data Lens is the first "honest" UI for a categorical graph kernel. Instead of faking a graph visualization that can't represent typed hypergraphs properly, it shows the actual data structures — nodes grouped by kind, wires grouped by morphism type, the ontology schema itself. Users can inspect payloads, trace ownership, and filter by categorical predicates. The visualization lens comes later, when we have a proper string diagram or hypergraph renderer.
