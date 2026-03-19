# Port-to-Port Bindings and Binding Categories

**Date:** 2026-03-19
**Author:** Sam Maassen + Claude Code (mobile session — Google Keep ideas)
**Status:** Foundational proposal — Program 2 direction, pre-task
**SOT rank:** 3 (design)

---

## Origin

This document crystallizes a Program 2 thinking session (Sam, mobile) against the full
mo:os KB. It extends The Carpet and the superset pipeline with a new layer:
**port-to-port (PTP) bindings as first-class inventory nodes**, dynamically composable
into categories with their own algebras, navigable via cooperad functors.

---

## 1. The PTP — Reifying the Wire Signature

A **port-to-port binding (PTP)** is currently implicit in the operad's `TypeSpec.PortTargets`:

```
Current (implicit):
  TypeSpec{TypeID: "user", PortTargets: [{Port: "owns", TargetType: "any"}]}

Proposed (first-class node):
  ADD(urn:moos:ptp:user.owns→any)
  LINK(ptp_node, "params", benchmark_node, "bench")
  LINK(ptp_node, "params", provider_node, "config")
  LINK(ptp_node, "params", req_schema_node, "req")
  LINK(ptp_node, "params", resp_schema_node, "resp")
```

A PTP node IS the 4-tuple `(src_type, src_port, tgt_type, tgt_port)` materialized as a
named, inventoried container at S1. It comes as a **package**: signature + parametrization
(provider config, benchmarks, req/resp schema). This is how the superset maps into the
user's HG — the PTP node is the wire type made visible and queryable.

### PTP URN pattern

```
urn:moos:ptp:<src_type>.<src_port>→<tgt_type>.<tgt_port>

Examples:
  urn:moos:ptp:user.owns→any.child
  urn:moos:ptp:agnostic_model.can_route→system_tool.transport
  urn:moos:ptp:benchmark_score.scored_on→agnostic_model.result
```

### Why this matters

Any user node with PTP-compatible port configuration can connect and expand the graph.
The PTP node defines the admissibility, the parametrization, and the metrics for that
specific wire type — all in one place. It is the interface between the superset type system
and the user's runtime hypergraph.

---

## 2. Taxonomy — Naming the Structures

The centerpiece work is naming. These are the proposed names:

| Structure | Name | Definition |
|---|---|---|
| Reified 4-tuple node | **PortBinding** | `(src_type, src_port, tgt_type, tgt_port)` + params package. S1, immutable. |
| A wired PortBinding instance | **ActiveBinding** | PortBinding with ≥1 actual wire in graph (saturated) |
| A declared but unwired PortBinding | **LatentBinding** | PortBinding with 0 wires in graph (gap in saturation lens) |
| Any set of PortBindings | **WireAlgebra** | A selected subset of PortBindings — defines which compositions are valid |
| Full subcategory induced by a WireAlgebra | **BindingCategory** | Objects = nodes touching those PTPs; morphisms = those PTPs. Closed under composition. |
| Any combo of bound+unbound ports | **BindingCategory** | Dynamically definable — not pre-enumerated. Any subset is valid. |
| Algebra of a BindingCategory | **PortAlgebra** | The algebraic structure enabled by that WireAlgebra (e.g. OWNS-closure = ownership algebra) |
| Cooperad fan-out from root via WireAlgebra | **BindingCooperad** | Coslice(root) filtered to a WireAlgebra. One-input-many-outputs. |
| Functor between two BindingCategories | **PortFunctor** | F: BindingCat_A → BindingCat_B. Existence = a path between categories. |

### Key property

Any combination of bound and unbound port sets is a valid BindingCategory. There is no
pre-enumeration. The ontology's `broad_category` groupings (identity, compute, surface...)
are *instances* of BindingCategories — not the definition. The definition is strictly:
pick any set of PortBindings, close under composition, get your category.

---

## 3. The Path Mechanism — Cross-Category Traversal

This is the cooperad functor used to find new routes in the user graph.

### The problem

Given a user HG and a question: "can I get from capability A to capability B?"

### The mechanism

```
1. Project: root nodes → all PTPs via PortInventory functor (FUN10, proposed)
   Saturation lens (Task 033) already does this per-node.
   FUN10 generalizes it across all root nodes simultaneously.

2. Partition: PTPs → BindingCategories
   Any selected subset of PTPs defines a BindingCategory.
   The partition is not fixed — user defines it by selecting port names.

3. Test path: PortFunctor F: BindingCat_A → BindingCat_B
   Does a morphism sequence exist from A's objects to B's via the PTP space?
   If yes → that sequence IS the new route.

4. Materialize: LINK morphisms along the path → graph state changes
   The cooperad fan-out from the path's entry node realizes the route.
```

### Formal statement

A **PortFunctor** F: BindingCat_A → BindingCat_B exists iff there is a composable
sequence of PortBindings p₁, p₂, ..., pₙ such that:
- p₁.src_type ∈ objects(BindingCat_A)
- pₙ.tgt_type ∈ objects(BindingCat_B)
- pᵢ.tgt_type = pᵢ₊₁.src_type for all i (composition condition)

The PortFunctor preserves structure: it maps morphisms in A to morphisms in B via the
cooperad composition. Natural transformations between PortFunctors = symmetries of the
path (different routes that produce the same state change).

### Connection to the HG

This path IS the mechanism for assessing a new route in the user graph from *within* the
HG using projection. The projection (Slice/Coslice — already in Explorer 2.0) gives you
the fan-in and fan-out. The PortFunctor tells you whether those fans connect across
categories. If they do, you have a navigable path through the PTP space.

---

## 4. Semantics as Metric — Structural Distance

"Semnet is the key to metrics because it correlates with tree complexity and scope."

### The formal connection

```
port_diameter(BindingCat) = max wire hops between any two PortBindings in that category
```

This IS the semantic complexity metric:
- Higher diameter → more complex semantic task → more graph levels change to satisfy it
- Lower diameter → simpler, more local semantic operation

In HDC terms:
```
φ(node) = ⊕{ w : w ∈ wires(node) }
```
A semantically complex node has more incident wires → richer hypervector → greater cosine
distinguishability. Semantic distance = structural distance = wire-hop count. This is not
metadata — it IS the topology.

Graph state must change on all levels (S0→S4) to satisfy a specific semantic task because
the task *is* a path through the PTP space — it induces a specific WireAlgebra that must
be realized (wired) for the state to be coherent with that semantic intent.

### The mycelium / protein interface analogy

Communication ports on cell membranes (proteins), mycelium network junction points,
geodetic network communication nodes — all are:
- First-class interface nodes (not metadata, not stickers)
- Typed by their connection signature (what they bind to, what they transport)
- Metrics-bearing (throughput, latency, affinity = benchmark package)
- Structurally defined (their identity = their port set)

PortBindings are the mo:os analog. The semantic network IS the wire network.

---

## 5. Properties of Properties — OOP Resolved

"Properties of properties that are parameters of properties — inheritance and composition.
This solves OOP's mess of predefined objects with stickers by letting properties (ports)
define the object together with the types/properties including identity."

### The Yoneda formulation

An object has no essence beyond its port signature + wire bundle. This is Yoneda:

> An object is fully determined by its morphisms (its hom-functor).
> `Hom(-, A) ≅ A` up to natural isomorphism.

OOP hardcodes attributes at the class level = metadata as ontology. This breaks at scale
because the attribute soup is in **Set** (flat, unstructured), while composition lives in
the **free CDMU category** (structured, with port equations).

### Higher-order PTPs

"Properties of properties" = a PortBinding can itself be the target of another PortBinding.
This is the operad's recursive composition:

```
PortBinding_meta: (ptp_node, "params") → (benchmark_node, "bench")
PortBinding_meta: (ptp_node, "req_schema") → (schema_node, "definition")
```

The algebra of a BindingCategory captures this: when PTPs compose to form meta-PTPs,
you get inheritance and delegation without hardcoded class hierarchies. `state_payload`
is just the current wire bundle compressed into JSONB — not an attribute list. The node
IS its morphisms.

---

## 6. Time Direction and Feedback

"The graph can flow both directions but just 1 makes sense because it is correlated with
IRL. Graph state is time-dependent. State is topological — influenced in a network of
wires (PTP). Adding wires is what it does continuously from S0 to S2 and from S4 into
the machine via S0."

### Formal statement

The morphism log is **strictly causal forward** (total order by timestamp). The catamorphism
`state(t) = fold(log[0..t])` always runs in one direction. The apparent bidirectionality
is the S4→S0 feedback loop:

```
S0 (authored) → S1 → S2 → S3 → S4 (projected to user)
                                    ↓
                              user action
                                    ↓
                         new S0 content (new wire ADD)
                                    ↓
                            S0 → S1 → S2...
```

The feedback is IRL-correlated: user interaction (outside the graph) creates new S0 content
(inside the graph). The arrow is always forward in log time. The graph only grows — wire
removal (UNLINK) is itself a forward operation in the log, not time reversal.

"Syn is sem, it's recursive." — The Carpet. There is no metadata. The wire topology IS
the semantic content. The syntax IS the meaning. The ontology IS the type system IS the
semantic ground truth. No top level. Everything is data. Everything is structure.

---

## 7. Proposed New Functors

Each BindingCategory mechanism requires a functor:

| ID | Name | Signature | What it does |
|---|---|---|---|
| FUN10 | PortInventory | C → PTP_Space | Projects all nodes → their full PortBinding set (superset-to-HG map) |
| FUN11 | BindingCat | 2^PTP → SubCat(C) | Maps any PTP subset → its induced full subcategory |
| FUN12 | PortFunctor | SubCat_A × SubCat_B → Path? | Tests/finds cooperad crossing between BindingCategories |

FUN10 extends the saturation lens (Task 033) to a global inventory.
FUN11 is the query surface: "give me the BindingCategory for {OWNS, CAN_ROUTE}".
FUN12 is the path-finding engine: "can I reach B from A via available PTPs?"

---

## 8. Connection to Explorer 2.0 (Task 033)

Task 033 shipped the saturation lens (`GET /state/saturation`) and the Slice tab
(Coslice/Slice fan-out/fan-in). These are the **runtime foundation** for this theory:

- Saturation lens = LatentBinding detection (which PTPs are declared but unwired)
- Slice tab = cooperad fan-out visualization (BindingCooperad in the Explorer)
- Schema tab = PortBinding inventory (currently implicit in TypeSpec; FUN10 would surface it)

The in-port/out-port saturation distinction (the bug fixed in Task 033) is exactly the
operad/cooperad distinction: out-ports = operad (defined ceiling of fan-out targets);
in-ports = cooperad aggregation (no ceiling, count only).

---

## 9. Governance Note

These are **proposals** (S0). Nothing here changes the ontology or kernel without a
formal task + Sam governance approval. The PortBinding node type (new OBJ candidate),
FUN10-12, and the BindingCategory query API are all pending Task creation.

Current canonical OBJ count: 23 (OBJ01–OBJ23).
PortBinding would be OBJ24 if approved.

---

## References

- `kb/design/20260314-the-carpet.md` — syntax/semantics separation, functor taxonomy
- `kb/design/hypergraph.md` — König encoding, presheaf topos, port diameter
- `kb/design/concepts.md` — BindingCategory connects to Scoped(W) and full subcategory
- `kb/superset/ontology.json` — current operad: 23 objects, 17 morphisms, 22 categories
- `channels/leadoff.md` — conversation that generated this doc (2026-03-19)
- Fong & Spivak §4 — colored operads, port typing
- Kanerva — HDC, φ(node) = ⊕{wires}, semantic distance = structural distance
- Wolfram — port diameter as effective dimension
