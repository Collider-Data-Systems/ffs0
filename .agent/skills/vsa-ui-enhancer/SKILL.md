---
name: vsa-ui-enhancer
description: UI_Lens functor expert for mo:os — Explorer graph visualization, S4 projection rules, real-time SSE. Use when working on Explorer UI, graph rendering, or data projection for display.
---

# VSA UI Enhancer — Explorer & UI_Lens Functor

Expert on the UI_Lens functor — the S3→S4 projection that transforms the categorical graph into rendered interface in the Explorer.

---

## UI_Lens Functor

```
UI_Lens : GraphCategory → RenderCategory
```

**Input:** S3 Evaluated graph state (nodes + wires + semantic metadata)
**Output:** S4 Projected render tree (HTML/SVG/Canvas elements)

---

## Explorer Architecture

```
Kernel (:8000)
  ├── GET /explorer         → Embedded HTML (go:embed)
  ├── GET /state            → Full graph JSON
  ├── GET /state/nodes      → Nodes array
  ├── GET /state/wires      → Wires array
  ├── GET /log?limit=N      → Morphism log entries
  ├── GET /log/stream       → SSE real-time stream
  └── GET /semantics/registry → 21 TypeSpecs
```

The Explorer is a **single-page app** embedded via `go:embed` in `transport/static/`. It consumes kernel REST endpoints and the SSE stream.

---

## Real-Time Updates (SSE)

```javascript
const source = new EventSource('/log/stream');
source.onmessage = (e) => {
    const morphism = JSON.parse(e.data);
    // Update graph visualization in real-time
};
```

Every morphism applied to the kernel fires an SSE event. The Explorer receives it and re-renders the affected subgraph.

---

## Graph Rendering Rules

1. **Nodes** → visual elements (circles, cards, icons) based on `Kind`
2. **Wires** → directed lines/arcs with port labels
3. **Containers** → bounding boxes (full subcategory visual grouping)
4. **TypeSpec coloring** → each Kind gets a consistent color from the 21-kind palette
5. **Layout** → force-directed or hierarchical (strata-based vertical layers)

---

## Projection Constraints

- Explorer shows S4 projection — **never mutate through the UI**
- UI state is ephemeral — refresh reconstructs from kernel state
- Filter/search in Explorer = scoped subgraph query, not local JS filtering
- Node detail panel reads `/state/nodes/{urn}`, not cached client data

---

## Semantic Registry Visualization

The Explorer should present all 21 TypeSpecs from `/semantics/registry`:
- Kind name, ports, arity constraints
- Visual legend mapping Kind → color/icon
- Port compatibility matrix (which ports can wire to which)

---

## Testing (Antigraviti Agent)

The Antigraviti agent tests Explorer via:
1. Page load verification (200 OK)
2. Graph rendering correctness (nodes visible, wires connected)
3. SSE stream connectivity
4. Morphism playback (apply morphism → see real-time update)
5. 95-case test plan in `design.20260313/20260315-explorer-ux-test-plan.md`
