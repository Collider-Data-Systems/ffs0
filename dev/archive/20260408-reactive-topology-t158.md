# Reactive Topology — Cascade Matrix + Leaf Portals

Date: 2026-04-08 | T=158
Status: Theoretical agreement. Not yet implemented.
Related: `20260408-foundation-t158.md` §10 (Reactive Layer)

---

## 1. Depth-1 Is the Wrong Primitive

The current implementation uses a hardcoded depth-1 guard in `applyReactiveLocked()`:
reactive proposals are applied but do not themselves trigger further reactive evaluation.
This is a runtime escape hatch — an algorithmic cutoff to prevent infinite loops.

The correct approach is analytical: replace the runtime depth limit with a
**configuration-time spectral check** on the cascade matrix.

---

## 2. The Cascade Matrix

Model the reactive layer as a matrix problem.

Let W = set of watchers, R = set of reactors in the current graph.

Define:
- **Trigger matrix** T: `T[w,r] = 1` iff watcher w is WF17-linked to reactor r (watcher activates reactor)
- **Production matrix** P: `P[r,w'] = 1` iff reactor r's emitted rewrite would match watcher w'
- **Cascade matrix** C = T · P

C captures: which watchers transitively activate which other watchers through their reactors.

| Expression | Meaning |
|-----------|---------|
| C⁰ = I | No cascade — just the initial trigger |
| C¹ | One step of cascade — current depth-1 |
| Cᵏ | k steps of cascade |
| (I − C)⁻¹ = I + C + C² + C³ + … | **Total cascade** (Neumann series) |

### Spectral Radius ρ(C)

The spectral radius ρ(C) = max|λ| over all eigenvalues λ of C.

| ρ(C) | Behavior |
|------|----------|
| 0 | No cascades at all. Reactors never trigger other watchers. |
| 0 < ρ < 1 | Cascades converge. Neumann series gives closed-form total cascade. |
| ρ = 1 | Marginal. Logarithmic divergence possible. |
| ρ > 1 | **Divergent cascades. Reject configuration at ADD/MUTATE time.** |

### The Implementation Strategy

1. When any WF17 rewrite adds or modifies a watcher or reactor node, recompute ρ(C).
2. If ρ(C) ≥ 1, reject the configuration with a validation error (before it's ever applied).
3. At runtime, let reactive chains run to their natural fixed point. The spectral guarantee
   ensures convergence — no depth limit needed.

This turns a runtime safety hack into a configuration-time proof of termination.

### Size and Cost

C is an |W| × |W| matrix where |W| = number of watchers. For dozens of watchers: O(n³)
exact computation is microseconds. For thousands: use power iteration for ρ estimate.
In practice mo:os graphs will have tens to low hundreds of watchers — exact is fine.

---

## 3. Wolfram, Category Theory, and SSE Connections

### Wolfram: Branchial Space

In the Wolfram multiway system, depth = steps in the multiway rewriting graph.
Depth-1 is one step in the multiway graph.
The Neumann series `(I − C)⁻¹` is the **confluence of all rewriting paths**.
This confluence exists iff the system is causally invariant (CI-1) over the reactive subgraph.
The spectral condition ρ(C) < 1 IS the causal invariance condition for reactive chains.

### Category Theory: F-Coalgebra

The Watch/React/Guard chain is an F-coalgebra where F = powerset functor P:

```
α: GraphState → P(GraphState)
```

Each state maps to a set of possible next states via reactive proposals.
- **Terminal coalgebra** (greatest fixed point) = all possible infinite reactive streams
- **Initial algebra** (least fixed point) = the terminating evaluation we want

The initial algebra exists iff ρ(C) < 1.
Categorical answer and matrix answer agree.

### SSE (Server-Sent Events)

The reactive cascade is a natural source for SSE. Each step of the cascade is an event:
- Initial rewrite → SSE event 1
- Reactor fires → SSE event 2
- ...
- Fixed point reached → SSE stream closes

With the cascade matrix, the kernel knows at configuration time how many events maximum
a given watcher chain can emit (bounded by the Neumann series). Clients can set
`max_events` budgets. This is backpressure with analytical guarantees.

---

## 4. Leaves as Boundary Objects / Portals

### Operadic Boundary

In Spivak's operad of wiring diagrams:
- **Inner wires**: connections between boxes inside a wiring diagram
- **Outer wires**: the boundary interface — ports that connect to the outside world

Leaves in mo:os are the outer wires. Nodes with no further outgoing relations of a
particular type are **at the boundary** of their containing subgraph.
They are where the graph's structural meaning meets raw reality.

### The Boundary Operator

```
∂G = { n ∈ Nodes(G) : n has at least one port with no outgoing relation }
```

These are the leaves. The boundary of the graph.
Boundary operators satisfy ∂² = 0: the boundary of a boundary is empty.
Leaves are terminal from inside the graph.
From outside the graph, they are **portals** — entry/exit points.

### Metadata Is Upstream, Not at the Leaf

Key principle: the leaf is atomic. All meaning accumulates via upstream relations.

```
fileref:jaarrekening.xlsx          (leaf: raw bytes, a pointer)
    ↑ WF15 semantic:source-file
ki:jaarrekening-2025               (KI: classification, KW12)
    ↑ WF12
kernel:hp-laptop                   (jurisdiction)
    ↑ WF01
user:sam                           (accountability, social topology)
```

| Position | What lives there |
|----------|-----------------|
| Leaf | Raw data: file bytes, tool endpoint, API response. No metadata. |
| First hop upstream | Immediate type context (WF classification) |
| Further upstream | Provenance, ownership, method, authentication |
| Apex (user) | Complete social-contextual semantics |

The depth of upstream traversal from a leaf = richness of contextual meaning.
This gradient IS the presheaf restriction: restrict to smaller neighborhoods → lose context.

### The "Jaarrekening" Formalization

An Excel annual accounts file. The leaf is just bytes and a path.
All of the following are relations upstream in the graph — NOT properties on the leaf:

- Owner, date, file format → S0 authored attributes on the KI
- Accounting method, GAAP/IFRS → S1 validated domain classification
- Auditor credentials, authentication method → S1/S2 governance
- Fiscal year, jurisdiction → S1 legal context
- Access log, who/when/why → S2 operational social topology

**New meaning can always be discovered.** A forensic auditor needs different upstream
context than a tax preparer. The graph grows upward from the leaf. The leaf stays atomic.

---

## 5. Co-operadic Meeting Point

Sam's question: "where the hyperedge meets a node" = the **evaluation map** of the operad.

In Spivak's framework:
```
eval: O(n) × Xⁿ → X    (take n-ary operation + n inputs → output)
```

The co-operad dualizes:
```
coeval: X → O(n) × Xⁿ  (decompose a node into operadic context + leaf inputs)
```

Co-evaluation at a node reveals: what operation produced this node, and what atomic
inputs (portals, leaves) went into it.

T=169 and T=180 as temporal leaves: co-evaluation decomposes the "implementation spec"
node into the operadic structure (how it was composed) and the leaf inputs
(what raw data/decisions went into it at that time).

---

## 6. Topological Symmetries at the Boundary

### Structural Symmetry of Leaves

Two leaves are structurally symmetric if there exists a graph automorphism swapping them:

```
n₁ ~ n₂  iff  ∃ σ ∈ Aut(G) : σ(n₁) = n₂
```

The orbits of ∂G under Aut(G) partition leaves into equivalence classes.
Leaves in the same orbit play identical structural roles — interchangeable
without changing the graph's meaning.

**HDC detects this naturally**: symmetric leaves produce similar hypervectors,
because φ(node) = ⊕{incident wires} and symmetric nodes have isomorphic wire neighborhoods.

### Coherence / Sheaf Condition

If two different graph paths reach the same leaf, the data they "see" must agree.
This is the sheaf gluing condition applied to the boundary.
Violations = inconsistency in the knowledge graph = detectable via Čech cohomology
of the covering defined by the two paths.

### Poincaré Duality (approximately)

For well-structured knowledge graphs that approximate compact manifolds:
```
H_k(G) ≅ H_{n-k}(G)    (Poincaré duality)
```

H_0(∂G) = connected components of the boundary (distinct portal groups)
dually constrains H_{n}(G) = top-dimensional topology (global structure of the knowledge).

Implication: counting and classifying leaves (the easy thing) constrains
the global topology (the hard thing). Boundary analysis is a diagnostic tool.

---

## 7. The Cascade Matrix + Leaves: Unified Picture

External events enter through leaf portals. They become rewrites at the boundary.
Those rewrites propagate inward through the reactive layer.
The cascade matrix governs how far they propagate.

```
External reality → Leaf portal → Rewrite at ∂G → Cascade (governed by ρ(C))
                                                       ↓
                                          Fixed point → New GraphState
```

ρ(C) = **impedance of the graph's boundary**:
- Low ρ: changes at leaves dampen quickly → stable, predictable system
- High ρ < 1: changes propagate but converge → sensitive, responsive system
- ρ = 1: critical threshold → phase transition, maximum sensitivity
- ρ > 1: rejected at configuration time → never reached at runtime

---

## 8. Implementation Plan (future sprint)

- [ ] Compute cascade matrix C when WF17 watcher/reactor topology changes
- [ ] Add ρ(C) check to WF17 rewrite validator — reject if ρ ≥ 1
- [ ] Remove depth-1 hardcode from `applyReactiveLocked()`
- [ ] Let reactive chains run to natural fixed point
- [ ] Expose cascade depth estimate via kernel health endpoint
- [ ] Add SSE backpressure using Neumann series bound
