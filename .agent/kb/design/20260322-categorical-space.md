# Categorical Space & PTP Inventory
### The Two-Space Architecture for mo:os
### 2026-03-22 | T=141

---

## 1. The Two Spaces

mo:os operates across two distinct mathematical spaces. Conflating them is the root of every OOP failure mode.

### Categorical Space (CS)

The **grammar** of what can exist. Defines:
- Which port-to-port transitions (PTPs) are permitted
- Which type combinations can wire together
- What port structure each type_id exposes

**Properties:**
- Immutable during normal kernel operation
- Changes require governance morphism (schema migration)
- Lives at S0-S1 stratum
- Currently encoded in: `ontology.json` objects + morphisms + categories
- Proposed: make PTP inventory first-class, explicit, inspectable

### Hypergraph Instance Space (HG)

The **instantiation** of what does exist. Contains:
- Actual nodes (URNs)
- Actual wires (4-tuple PTPs)
- The morphism log
- The fold state: `state(t) = fold(log[0..t])`

**Properties:**
- Append-only mutable via the 4 invariant morphisms
- Lives at S2-S4 stratum
- Is the SOT
- Currently: kernel in-memory + `morphism-log.jsonl`

### Relationship

```
CS ──defines──> permitted PTPs
                    |
                    v
HG ──instantiates──> actual wires (subset of permitted)
```

An object in HG **inherits its port structure** from CS (via its type_id)
but **composes freely** within CS compatibility rules.

CS is the Lawvere theory. HG is the model.

---

## 2. Identity as Self-Referential Property

### The Inversion

Standard OOP:
```
Object → has fields → has identity (field among fields)
```

mo:os (proposed):
```
Identity = port that refers to itself: urn(x) = x
All other properties = ports with bound properties
Object = colimit of its live port composition
```

### In the Kernel

The `urn` field in AddPayload is currently a flat string. Categorically, it is:
- The identity morphism `id_X : X → X`
- A port that maps to itself
- The ONE causal invariant of a specific node across all morphism sequences:
  `∀M ∈ {ADD, LINK, MUTATE, UNLINK}: urn(M(x)) = urn(x)`

### Consequences

| If | Then |
|----|------|
| Remove all wires from node X | X still exists (URN in log) but has no structure |
| MUTATE X's payload | X's identity unchanged, X's properties changed |
| Two nodes share all port types but differ in URN | They are different objects |
| Two nodes share URN (impossible) | Kernel rejects: URN uniqueness is enforced at ADD |

Identity is not a field. Identity is the fixed point. Everything else is bound to it.

### For Agents

Agent identity follows the same principle:
- `urn:moos:agent:claude-code` is the identity port
- Capabilities, sessions, permissions = ports wired to it
- Governance = who can LINK/UNLINK ports to/from the agent's identity
- The "governance thing" Sam asks about: governance morphisms operate on the agent's port structure, not on the agent itself

---

## 3. PTP Inventory (extracted from ontology.json MOR01-MOR17)

Every LINK morphism in the kernel instantiates one of these permitted PTPs.
This table IS the categorical space's morphism grammar.

### LINK-based PTPs (wire-creating)

| PTP ID | MOR | Source Port | Target Port | Source Constraint | Target Constraint |
|--------|-----|-------------|-------------|-------------------|-------------------|
| PTP01 | MOR01 | `owns` | `child` | identity.* | any |
| PTP02 | MOR02 | `can_hydrate` | `hydrate` | identity.* ∪ structure.* ∪ memory.* | any |
| PTP03 | MOR06 | `{port_s}` | `{port_t}` | structure.* | structure.* |
| PTP04 | MOR09 | `can_schedule` | `workload` | identity.admin+ ∪ compute.* | compute.ComputeResource |
| PTP05 | MOR10 | `can_route` | `transport` | protocol.ProtocolAdapter | any |
| PTP06 | MOR11 | `can_persist` | `storage` | any | infra.InfraService ∪ memory.MemoryStore |
| PTP07 | MOR12 | `can_federate` | `peer` | identity.SuperAdmin | surface.RuntimeSurface |
| PTP08 | MOR13 | `can_fork` | `vram_branch` | compute.* ∪ identity.admin+ | compute.ComputeResource |
| PTP09 | MOR14 | `scored_on` | `result` | compute.AgnosticModel | evaluation.* |
| PTP10 | MOR15 | `evaluates_task` | `evaluation` | evaluation.* | structure.* |
| PTP11 | MOR16 | `benchmarked_by` | `membership` | evaluation.* | evaluation.* |
| PTP12 | MOR17 | `classifies` | `source` | industry.* | any |

### MUTATE-based PTPs (state-changing, no new wire)

| PTP ID | MOR | Operation | Constraint |
|--------|-----|-----------|------------|
| PTP-M1 | MOR03 | PRE_FLIGHT_CONFIG | identity.admin+ → surface.* ∪ structure.* |
| PTP-M2 | MOR04 | SYNC_ACTIVE_STATE | surface.* → structure.* |
| PTP-M3 | MOR07 | UPDATE_NODE_KERNEL | identity.* ∪ compute.* → structure.* |

### UNLINK-based PTPs (wire-removing)

| PTP ID | MOR | Operation | Constraint |
|--------|-----|-----------|------------|
| PTP-U1 | MOR08 | UNLINK_EDGE | any → any (removes existing wire by 4-tuple) |

### Notes

**PTP03 (LINK_NODES) is the generic PTP.** Source and target ports are parameters, not fixed. This is the open-ended morphism — any structure.* can wire to any structure.* with arbitrary port names.

This is intentional: PTP03 is how `calendar_event -(causes:deadline)→ prg_task` works, how `agent_session -(focus:current)→ prg_task` works, how any new IRL→HG connection works. The port names are semantic, not schematic — they exist in HG, not in CS.

**The split:**
- PTP01-02, PTP04-12: **schematic PTPs** — port names fixed in CS, enforced by kernel
- PTP03: **semantic PTP** — port names chosen at wire-creation time, enforced only by convention
- PTP-M1/M2/M3: **endomorphic PTPs** — state change, no new topology
- PTP-U1: **destructive PTP** — removes topology

---

## 4. The Five Causal Invariancies

These are the properties that hold regardless of morphism application order, agent identity, or temporal sequence. They define what "correct" means for mo:os.

### CI-1: Morphism Commutativity (Church-Rosser)

```
M_a ; M_b = M_b ; M_a
  when affected_urns(M_a) ∩ affected_urns(M_b) = ∅
```

Independent morphisms commute. The causal DAG is a partial order, not a total order.

**Testable:** Apply two independent ADDs in both orders → same graph state.

**Consequence for multi-kernel:** Two kernels can run in parallel iff their morphism sets are disjoint. This is the sufficient condition for independent kernel instances — no separate "cloverleaf" concept needed.

### CI-2: Functor Naturality (Task 034)

```
Project(Apply(M, S)) = Apply(M', Project(S))
```

For every projection functor F (FUN01-FUN05):
applying a morphism then projecting = projecting then applying the corresponding projected morphism.

**Testable:** ADD a node, then project to UI. vs. project current state, then add the corresponding UI element. Same result.

**This IS the single most important property to prove.** It guarantees that projections (files, UI, embeddings) never diverge from ground truth.

### CI-3: Identity Stability

```
∀M, ∀x ∈ HG: urn(M(x)) = urn(x)
```

No morphism changes a node's URN. The identity port is the one fixed point.

**Testable:** MUTATE any node's payload 1000 times → URN unchanged.

**Consequence:** URNs can be used as stable references across sessions, across agents, across kernels. A `calendar_event` URN from T=0 is still valid at T=141.

### CI-4: Log Replay Determinism

```
∀t: fold(log[0..t]) = fold(log[0..t])
```

The catamorphism is deterministic. Same log → same state. Always.

**Testable:** Boot kernel twice from same log → identical graph state.

**Consequence:** Any kernel instance can reconstruct any historical state. The log IS the complete record. No hidden state.

### CI-5: PTP Compatibility Stability

```
PTP(src_type, src_port, tgt_type, tgt_port) ∈ CS_permitted
  → this membership is invariant under all HG morphisms
```

The categorical space does not change when the HG changes. Adding nodes and wires does not alter what CAN be added.

**Testable:** Before and after 1000 morphisms, the same PTP inventory is valid.

**Consequence:** The schema is a constant of the system. Schema changes require a different class of morphism (governance/migration), operating on CS not HG.

---

## 5. IRL → HG: The Causal Anchor Pattern

### How IRL Events Connect to the Graph

```
IRL event (Sam walks, burns one, has insight)
  → creates calendar_event node (OBJ26) via GCal MCP
  → LINK(calendar_event, 'causes', prg_task, 'anchor') via PTP03
  → prg_task generates agent_session when worked
  → LINK(agent_session, 'focus', prg_task, 'current') via PTP03
  → morphisms in session = causal consequences of IRL event
```

The chain: `IRL → calendar_event → prg_task → agent_session → morphisms`

This makes the HG causal DAG traceable back to IRL causes.

### Temporal Encoding

Every `calendar_event` carries:
```json
{
  "date": "2026-03-22",
  "t_days": 141,
  "gcal_id": "...",
  "color_id": 4
}
```

`t_days` is the temporal coordinate. T=0 is the origin. Negative T = pre-kernel history (the diary). Positive T = kernel-live timeline.

The calendar IS a total order on IRL events. The morphism log IS a total order on HG events. The LINK between `calendar_event` and `prg_task` is the **bridge** between these two orderings.

### Past Events as Causal Anchors

Events before T=0 (the diary period) are valid nodes in the HG even though no morphisms existed then. They are S0 — authored historical records, not materialized kernel events.

```
T=-194 (ChatGPT) = S0 calendar_event, no kernel morphisms
T=0 (kernel born) = S0→S2 transition, first ADD
T=141 (today) = S2 calendar_event, linked to live prg_tasks
```

The diary narrates the S3 evaluated semantics of this causal structure.
The calendar anchors the S2 materialized instances.
The morphism log records the S2 ground truth.
Same structure, three functors.

---

## 6. Composable PTP Sets = Categories

Sam's key insight (19.03): "Any of those sets have their algebras that enable different structures."

### Definition

A **composable PTP set** is any subset of the PTP inventory where:
- The target port of one PTP matches the source port of the next
- The type constraints are compatible across the chain

Example:
```
PTP01(user, owns, app_template, child)
  → PTP02(app_template, can_hydrate, node_container, hydrate)
    → PTP03(node_container, out, node_container, in)
```

This chain: `user OWNS template, template HYDRATES container, container LINKS container`

### Each composable set IS a category

- Objects: the types participating in the chain
- Morphisms: the PTPs in the set
- Composition: PTP chaining (target = next source)
- Identity: the self-referential URN port at each type

### The Algebras

Each composable PTP set has an algebra that describes its structural behavior:

| PTP Set | Algebra | Structure |
|---------|---------|-----------|
| {PTP01} (OWNS only) | Tree algebra | Ownership hierarchy |
| {PTP01, PTP02} (OWNS + HYDRATE) | DAG algebra | Hydration dependency |
| {PTP03} (LINK_NODES only) | Free graph algebra | Arbitrary structure.* topology |
| {PTP09, PTP10, PTP11} (benchmark) | Metric algebra | Provider comparison space |
| {PTP12} (CLASSIFIES only) | Functor algebra | Industry → instance mapping |
| All PTPs | Full HG algebra | The complete kernel |

### Operad / Co-operad Structure

**Operad (fan-in):** Multiple PTPs converge on a single node.
A `prg_task` receives wires from: `calendar_event` (via PTP03), `agent_session` (via PTP03), other `prg_task` (via PTP03 dependency). This convergence = an operad operation.

**Co-operad (fan-out):** A single node sources multiple PTPs.
A `user` emits wires to: owned templates (PTP01), owned containers (PTP01), hydration targets (PTP02). This divergence = a co-operad operation.

**Cross-category path:** A path that traverses multiple composable PTP sets = a co-operad functor. Finding this path in the HG = finding a composition of PTPs that type-checks across category boundaries.

---

## 7. What This Means for the Ontology

### Current State (ontology.json v3)

The PTP inventory is **implicit**:
- Encoded in `source_connections` / `target_connections` arrays per object
- And in `decomposition` strings per morphism
- Port names embedded in decomposition strings, not first-class

### Proposed Evolution

Make PTPs **explicit** as a top-level section in ontology.json:

```json
{
  "ptps": [
    {
      "id": "PTP01",
      "morphism": "MOR01",
      "source_port": "owns",
      "target_port": "child",
      "source_types": ["identity.*"],
      "target_types": ["*"],
      "creates_wire": true,
      "causal_invariant": "CI-1"
    },
    {
      "id": "PTP03",
      "morphism": "MOR06",
      "source_port": "{semantic}",
      "target_port": "{semantic}",
      "source_types": ["structure.*"],
      "target_types": ["structure.*"],
      "creates_wire": true,
      "causal_invariant": "CI-1",
      "note": "Open-ended semantic PTP — port names are parameters"
    }
  ]
}
```

This makes CS inspectable. The kernel can validate: "is this LINK permitted in categorical space?" before applying it. Currently it validates type_id existence but not port compatibility.

### The Schema Migration Question

Changing the PTP inventory = changing CS = a governance event.
This is categorically different from a regular LINK/MUTATE.
It needs its own morphism class — or a meta-morphism that operates on CS rather than HG.

For now: CS is a file (`ontology.json`). Changes to it are Git commits, not kernel morphisms.
Later: CS could be a second kernel — a meta-kernel whose state IS the schema.

---

## 8. Ricci Curvature as Graph Metric (Direction Only)

High Ricci curvature nodes = dense neighborhood = many shared neighbors = hub.

**For mo:os:** compute approximate Ricci per wire:
```
κ(u,v) ≈ |neighbors(u) ∩ neighbors(v)| / max(|neighbors(u)|, |neighbors(v)|)
```

**Purpose:** Identify "Rome" nodes — where many PTPs converge.
These are candidates for promotion: GPU-explored structure → CPU kernel code.

**Not implementing now.** Direction is clear: `GET /state/ricci` endpoint, returns per-wire curvature. The existing `/state/saturation` is the port-level version of this — Ricci adds the topological dimension.

---

## 9. Summary: The Architecture in One Diagram

```
CATEGORICAL SPACE (CS)                    HYPERGRAPH INSTANCE SPACE (HG)
┌─────────────────────────┐               ┌─────────────────────────────┐
│ PTP Inventory           │──defines──>   │ Actual wires (4-tuple)      │
│ Type registry (OBJ*)    │               │ Actual nodes (URN)          │
│ Morphism grammar (MOR*) │               │ Morphism log                │
│ Category defs (CAT*)    │               │ fold(log) = state           │
│ Functor specs (FUN*)    │               │                             │
│                         │               │ ┌─────────────────────────┐ │
│ IMMUTABLE               │               │ │ IRL Causal Anchors      │ │
│ (governance-only change)│               │ │ calendar_event nodes    │ │
│                         │               │ │ T-day coordinates       │ │
│ S0-S1 stratum           │               │ │ LINK to prg_task        │ │
│                         │               │ └─────────────────────────┘ │
│ Lawvere theory          │               │                             │
└─────────────────────────┘               │ APPEND-ONLY MUTABLE         │
                                          │ (4 invariant morphisms)     │
        5 CAUSAL INVARIANCIES             │                             │
        ├ CI-1: Commutativity             │ S2-S4 stratum               │
        ├ CI-2: Naturality                │                             │
        ├ CI-3: Identity stability        │ Model of the theory         │
        ├ CI-4: Replay determinism        └─────────────────────────────┘
        └ CI-5: PTP compatibility
```

---

*This document supersedes implicit schema encoding in ontology.json source/target_connections arrays.*
*The PTP inventory table (§3) is the SOT for permitted wire types.*
*Cloverleaf topology: dropped as concept. Multi-kernel falls out of CI-1 naturally.*
