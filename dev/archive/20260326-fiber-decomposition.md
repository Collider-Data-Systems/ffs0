# PRG036.2 — Dynamic Fiber Decomposition

## Summary

A **dynamic fiber** is the minimal coherent set of nodes + wires that a kernel process needs to complete its current operation. Fibers are not pre-partitioned by type (static). They are discovered at runtime by the demand pattern of the operation (dynamic).

## Definitions

### Fiber

Given a kernel K, a root node `r`, and a traversal depth `d`:

```
fiber(K, r, d) = { n ∈ Nodes(K) : dist(r, n) ≤ d }
              ∪ { w ∈ Wires(K) : source(w) ∈ fiber ∨ target(w) ∈ fiber }
```

A fiber crosses all wire families (OWNS, LINK_NODES, CLASSIFIES, CAN_ROUTE, etc.). It is bounded by causal dependency, not by morphism type.

### Interface Ports

The **interface** of a fiber is the set of ports where wires exit the fiber boundary:

```
interface(fiber) = { (n, port, dir) : n ∈ fiber ∧ ∃w where
                     (dir=out ∧ target(w) ∉ fiber) ∨
                     (dir=in  ∧ source(w) ∉ fiber) }
```

Interface ports are the "dangling wires" — connections to the rest of the graph that the fiber doesn't include. They define what the fiber needs from other fibers to be complete.

### Fiber Completeness

```
completeness(fiber, K, t) = |wires_present(fiber, K, t)| / |wires_expected(fiber)|
```

When completeness < 1.0, the kernel cannot execute operations on this fiber. The missing wires must be fetched via bridge sync.

## Cooperad Structure

### Why Cooperad (not Operad)

An **operad** defines how to compose n local interfaces into one global structure (bottom-up assembly). A **cooperad** defines how to decompose one global structure into n local parts (top-down splitting).

Dynamic fiber generation IS cooperad evaluation:

```
δ: C(global_graph) → C(k) ⊗ C(fiber_1) ⊗ ... ⊗ C(fiber_k)
```

The cooperad ensures:
1. Every node appears in exactly one fiber
2. Interface ports between fibers are compatible (no dangling wires without a matching port on the adjacent fiber)
3. The union of all fibers reconstructs the global graph (completeness)

### Composition Rule

Two fibers F_A and F_B can be merged iff their interface ports are dual:

```
merge(F_A, F_B) iff ∀(n, port, out) ∈ interface(F_A):
    ∃(m, port', in) ∈ interface(F_B) where wire(n, port, m, port') ∈ Wires
```

This is the cooperad counit — it tells you when two fibers can be glued back together.

## Algorithm: Demand-Driven Fiber Discovery

### Input
- `root_urn`: the node the operation targets
- `depth`: traversal radius (default: 2)
- `wire_filter`: optional filter on wire families (default: all)

### Steps

1. **Seed:** Start with root node.
2. **Expand:** BFS traversal to depth `d`, following all wire families (or filtered set).
3. **Collect:** All nodes + wires within the traversal = the fiber.
4. **Boundary:** Identify interface ports — wires that cross the fiber boundary.
5. **Classify:** For each interface port, record:
   - `direction`: in or out
   - `wire_family`: which PTP family the crossing wire belongs to
   - `remote_urn`: the node on the other side of the boundary
6. **Return:** `{root, depth, nodes, wires, interface_ports}`

### Complexity
- O(|V| + |E|) within the depth-bounded subgraph
- In practice: depth=2 on a 500-node graph touches ~50 nodes max (sparse graph)

## Synchronization Protocol

### When Fiber Crosses Kernels

If K_A needs a fiber rooted at node `r` but some nodes in the fiber live on K_B:

1. K_A computes `fiber(K_A, r, d)` — gets local portion + interface ports
2. K_A identifies missing nodes (interface ports where `remote_urn` is not in K_A)
3. K_A sends `POST /bridge/sync` to K_B with the list of missing URNs
4. K_B responds with the sub-fiber: nodes + wires for the requested URNs
5. K_A merges the sub-fiber into its local fiber
6. K_A's fiber completeness reaches 1.0 — operation can proceed

### Cursor Semantics

Each bridge connection maintains a cursor (monotonic position in the source kernel's morphism log). When K_A syncs with K_B:

- K_A sends its cursor position for K_B
- K_B returns all morphisms since that cursor that affect the requested fiber
- K_A applies those morphisms locally and advances its cursor
- This is incremental — only deltas, not full state transfer

## Pipeline Metric: Rate Mismatch

### Definition

For a fiber F shared between kernels K_A (producer) and K_B (consumer):

```
rate_produce(K_A, F) = morphisms_affecting_F(K_A) / time_window
rate_consume(K_B, F) = sync_requests_for_F(K_B) / time_window
mismatch(F, K_A, K_B) = rate_produce - rate_consume
```

- **Positive mismatch:** K_A is ahead. Buffer or throttle.
- **Negative mismatch:** K_A is behind. K_B waits. Trigger priority sync.
- **Zero:** Optimal flow.

### Bottleneck Detection via Ricci Curvature

Compute Ollivier-Ricci curvature on the branchial graph (fiber-to-fiber connections):

```
κ(F_A, F_B) = 1 - W(μ_A, μ_B) / d(F_A, F_B)
```

Where W is the Wasserstein distance between the neighbor distributions of F_A and F_B, and d is the graph distance.

- **κ < 0:** Bottleneck. Too many fibers need to sync through a small overlap.
- **κ > 0:** Surplus capacity. Fibers well-separated.
- **κ ≈ 0:** Optimal flow.

The pipeline metric triggers re-decomposition when κ drops below threshold: split the bottleneck fiber into smaller fibers with wider interfaces.

## Endpoint Spec

### GET /bridge/{kernel_urn}/fiber

**Query params:**
- `root` (required): URN of the root node
- `depth` (optional, default 2): traversal radius
- `families` (optional): comma-separated wire family filter

**Response:**
```json
{
  "kernel": "urn:moos:kernel:hplaptop-primary",
  "root": "urn:moos:prg:036-cloverleaf",
  "depth": 2,
  "nodes": [
    {"urn": "...", "type_id": "...", "stratum": "S2", "payload": {...}}
  ],
  "wires": [
    {"source_urn": "...", "source_port": "out", "target_urn": "...", "target_port": "in"}
  ],
  "interface_ports": [
    {"urn": "...", "port": "out", "direction": "outbound", "wire_family": "LINK_NODES", "remote_urn": "..."}
  ],
  "completeness": 1.0,
  "node_count": 23,
  "wire_count": 31,
  "interface_count": 5
}
```

## Relation to Other PRGs

- **PRG035 (PTP):** The 7 PTP families define the wire types. Fibers cross ALL families — they're not bounded by PTP.
- **PRG036.1 (Kernel-as-Functor):** Each kernel IS a functor K: Ontology → Instance. The fiber is a subgraph of the functor image.
- **PRG036.3 (Bridge):** The bridge transport syncs fibers between kernels. The fiber endpoint uses the bridge for cross-kernel fiber assembly.
- **PRG036.4 (Pipeline Metrics):** Curvature on the branchial graph uses fibers as nodes. Defined here, measured there.
- **PRG041 (Firestarter):** Firestarter trigger can specify a fiber scope — "fire when this fiber changes."

## Validation Condition (036.2)

Given a sample query (root=prg:036, depth=2), the fiber endpoint returns:
1. A coherent subgraph with all nodes within 2 hops
2. Interface ports identifying boundary connections
3. Completeness = 1.0 (all local wires present)
4. Cross-kernel sync: if fiber spans two kernels, bridge sync fills missing nodes
