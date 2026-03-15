# Task 022 — Explorer Scope Selector (Lens Level 1)

**ID:** 20260315-022
**Priority:** P1
**Status:** ready
**Depends:** none (020 done, kernel running)
**Source:** UX discussion 2026-03-15, Option B
**Effort:** ~40 lines HTML/JS, 0 lines Go

---

## Problem

Explorer shows all 118 nodes as a flat dump. No way to filter to a meaningful subgraph.
The `GET /state/scope/{actor}` endpoint already exists and returns the OWNS subtree for any actor URN.
The FUN02 UILens already projects any GraphState into UIGraph. These just need to be wired to a UI control.

## Solution

Add a **Scope selector** to the Explorer sidebar header. When a scope is active, only nodes and edges within that actor's OWNS subgraph are rendered. Clearing the scope returns to the full view.

---

## Implementation (explorer.html only)

### 1. Scope input control (add to sidebar header, below the filter box)

```html
<div id="scope-bar" style="padding:4px 8px; border-bottom:1px solid #333;">
  <select id="scope-select" style="width:100%; background:#1e1e2e; color:#cdd6f4; border:1px solid #444; border-radius:4px; padding:4px;">
    <option value="">— Full graph (no scope) —</option>
    <!-- populated from /state/nodes actor URNs -->
  </select>
  <div id="scope-label" style="font-size:10px; color:#6c7086; margin-top:2px;"></div>
</div>
```

### 2. Populate selector on load

On startup, extract actor-type nodes from the already-loaded UIGraph (`/functor/ui`):
- All nodes with `type_id: "agent_spec"` or `type_id: "user"` or `type_id: "superadmin"` or `type_id: "collider_admin"` or `type_id: "node_container"` → add as options
- Label: node's `label` field, value: node's `urn`

### 3. Scope change handler

```javascript
scopeSelect.addEventListener('change', async () => {
  const urn = scopeSelect.value;
  if (!urn) {
    // restore full graph
    renderGraph(fullUIGraph);
    scopeLabel.textContent = '';
    return;
  }
  const encodedURN = encodeURIComponent(urn);
  const resp = await fetch(`/state/scope/${encodedURN}`);
  const scopedState = await resp.json();
  // scopedState is GraphState {nodes: {}, wires: {}}
  // convert to UIGraph using same projection logic already in explorer.html
  const scopedUI = graphStateToUIGraph(scopedState);
  renderGraph(scopedUI);
  scopeLabel.textContent = `Scope: ${nodes} nodes, ${wires} wires`;
});
```

### 4. Factor out `graphStateToUIGraph()`

Currently explorer.html fetches `/functor/ui` and renders the result. Extract a `graphStateToUIGraph(state)` function that takes a raw GraphState and applies the same color/position/label logic locally. This lets scope results go through the same visual pipeline.

**Alternative (simpler):** Hit `/functor/ui` with a `?scope=URN` query param — but that requires a Go change. Avoid. Do it client-side.

### 5. Stats line update

When scoped, update the top stats: `"Scope: N nodes, M edges (of 118 total)"` instead of `"118 nodes, 131 edges"`.

---

## Acceptance Criteria

- [ ] Scope dropdown populated with all actor-type nodes on page load
- [ ] Selecting a scope re-renders graph with only OWNS subgraph nodes/edges
- [ ] "Full graph" option clears scope and shows all 118 nodes
- [ ] Stats line reflects scoped counts when active
- [ ] `go test ./...` still green (no Go changes)
- [ ] Kernel still boots and healthz returns ok

---

## Files

- Edit: `platform/kernel/transport/static/explorer.html` (JS + HTML only)
- No Go changes

## Commit

`feat(explorer): scope selector — OWNS subgraph lens [task:20260315-022]`

---

## Why This Matters (for the paper)

The scope selector is FUN02 applied with a user-supplied parameter (the actor URN). It demonstrates:
- `ScopedSubgraph` as a S4 projection (functor image of a subcategory)
- The categorical separation: same syntax (graph), different functor (scope filter = different model)
- The three-agent UX: each agent sees only its own subgraph by default

This is the "lens" concept made tangible. A user clicking their own URN and seeing only what they own IS the mo:os sovereignty claim demonstrated.
