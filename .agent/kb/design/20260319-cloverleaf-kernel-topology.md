# Cloverleaf Multi-Kernel Topology

**Date:** 2026-03-19
**Status:** S0 — Proposed. Pending Sam direction.
**Source:** Sam mobile session (verbal). Captured by Claude Code.
**Related:** `20260319-ptp-binding-categories.md`, `kb/superset/ontology.json`

---

## Core Idea

Multiple local kernel instances arranged in a cloverleaf topology: each "leaf" is a scoped
kernel (user filesystem, code context, server group, etc.) connecting at a shared hub.
The key invariant: **leaf graphs cannot interact except through formally typed ports.**

This is not a limitation — it IS the structural guarantee. The operad/cooperad boundary
defines exactly where composition stops. Interaction only happens when a LINK morphism
explicitly bridges two leaf containers via a typed port.

---

## Topology

```
          [leaf: user-fs]    [leaf: code-ctx]
                 \                 /
          [kernel A]         [kernel B]
                 |                 |
                 └──── [hub] ───────┘
                           |
              [leaf: server-kernel C]   [leaf: group-kernel D]
```

Each leaf = a `Container` node (OBJ05) in the superset graph, scoped to a platform/machine/process.
The hub = a governance node linking kernels via LINK morphisms at cooperad terminals.

---

## Invariants

### Non-interaction (default)
Two kernel containers K_A and K_B are **non-interacting** iff there is no wire path between
any node in K_A and any node in K_B in the hypergraph.

In Wolfram terms: independent causal cones. Morphisms applied in K_A and K_B commute
trivially — they are in disjoint multiway branches that never merge.

### Interaction (explicit)
When interaction is desired, a LINK morphism introduces a typed wire at a cooperad terminal.
Wire complexity and Ricci curvature of that bridge wire are then measurable.

### Non-causality = parallelism
Multiple local kernels with no shared wires are non-causal with respect to each other.
They can run concurrently with no synchronization cost. This is the multi-local case Sam named.

---

## Strata Mapping

| Strata | Cloverleaf role |
|--------|----------------|
| S0,1 | Kernel Container authored + validated; PTP inventory (PortBindings) defined |
| S2 | Kernel instantiated; wires materialized between leaves via LINK |
| S3 | Ricci curvature + wire complexity computed over active topology |
| S4 | Rewiring proposals surfaced (UNLINK + LINK candidates), admin-gated |

**Operad/cooperad at S0,2:** Structure is defined by how containers compose — what ports
they expose, what PTPs connect them. This is the BindingCategory of the hub.

**Metrics at S3,4:** Ricci curvature measures information-flow health across leaf connections.
Wire complexity (port diameter) measures semantic distance. Both feed back to S0 as
rewiring proposals — never auto-applied; governance approves.

---

## Memory Hierarchy for Graph State

```
GPU (primary)    ← HDC hypervectors for all active nodes
                   φ(node) = ⊕ { w : w ∈ wires(node) }
                   All similarity ops: O(N·d) parallel, milliseconds

Fast RAM         ← S2 materialized state cache ("collider tier")
                   Evicted when session closes

CPU RAM          ← Catamorphism buffer: Σ: Log → State
                   S0/S1 authored state

Disk             ← Append-only morphism-log.jsonl (the truth)
                   Never mutated; always replayable
```

A **state transition** (morphism application) propagates up the hierarchy:
1. Append to disk log
2. Update CPU catamorphism result
3. Rebundle GPU hypervector for affected nodes (`φ` update)
4. Optionally: rewiring proposal computed from S3 metrics → posted to governance queue

---

## Ricci Curvature as Rewiring Signal

**Ollivier-Ricci curvature** on a wire W(A→B):
- Positive curvature → redundant paths (robust, healthy bridge)
- Negative curvature → bottleneck wire (fragile, rewire candidate)
- Zero curvature → tree-like (neutral)

Wire complexity = port diameter across the bridge.

**Feedback loop:**
```
S3 metric computation → negative-curvature wire identified
  → S0 rewiring proposal: UNLINK(W) + LINK(W') with better path
  → governance-gated MUTATE or LINK morphism
  → S2 state updated
  → GPU hypervectors rebundled
```

This is the "availability, locality, state transition, rewiring" cycle Sam named.

---

## Kernel Set Expansion

Each new platform kernel (Mac, Linux, server, group) enters the graph as:

```
ADD  {urn: kernel:mac:001, type: Container, platform: mac, status: active}
LINK kernel:mac:001 → kernel-registry [port: member]
LINK admin-group:X  → kernel:mac:001  [port: governs]
```

Kernel capability is graph-structural, not external config.
Admin/group governance nodes already in the superset graph.
Expansion = ADD + LINK, governed by existing morphism invariants.

---

## Connection to Existing Work

| Existing | Cloverleaf role |
|----------|----------------|
| Task 033 saturation lens | Runtime foundation — measures port fill per kernel |
| In/out-port saturation fix | IS the operad/cooperad distinction at leaf level |
| FUN10 PortInventory (proposed) | Global PTP space across all leaves |
| FUN11 BindingCat (proposed) | Dynamic subcategory per active kernel set |
| FUN12 PortFunctor (proposed) | Cross-kernel path finding (cooperad bridge) |
| OBJ24 PortBinding (proposed) | Wire type reified — the leaf-to-leaf connector |

---

## Open Questions (S0, for Sam)

1. **Hub governance** — is the hub a first-class kernel node or a virtual join in the superset?
2. **Kernel-to-kernel LINK semantics** — what port types are valid at cooperad terminals?
3. **GPU tier ownership** — one GPU graph per leaf, or shared GPU across all leaves with
   scoped subvector regions?
4. **Lifetime policy** — when a leaf kernel is removed (UNLINK from hub), what happens
   to its dangling wires? Cascade UNLINK or orphan preservation?
5. **Ricci threshold** — what curvature value triggers a rewiring proposal vs. an alert?

---

## Proposed New Ontology Entries (candidates)

| Proposed ID | Name | Description |
|-------------|------|-------------|
| OBJ25 | KernelLeaf | Scoped kernel instance in the cloverleaf topology |
| OBJ26 | KernelHub | Governance node connecting leaves; owns cooperad terminals |
| REL?? | BRIDGES | Wire type for cross-kernel cooperad connection |

All S0. Pending Sam candidacy decision.
