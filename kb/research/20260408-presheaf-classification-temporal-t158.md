# Presheaf Formalization, Classification Functors, and Temporal Model

Date: 2026-04-08 | T=158
Status: Theoretical agreement. Not yet implemented.
Related: `20260408-foundation-t158.md` §6-7, §11-12, §18

---

## 1. Presheaf Over Kernels: Base Category K

### Objects of K

Each running moos-kernel process is an object in K:
- hp-laptop kernel
- z440-user-alice kernel
- z440-agent-writer kernel
- (future spawned kernels)

### Morphisms of K

A morphism f: K1 -> K2 means "K1 federates with K2" — requests can flow from K1 to K2.
Direction matters: models access/routing asymmetry. K1 may reach K2 without reciprocal.
These are the WF16 federation links (shard_rule, endpoint connections).

---

## 2. P1: Structural Presheaf

```
P1: K^op -> Set
```

P1 assigns to each kernel K its structural fiber:

```
P1(K) = {
    access_policy: Actor -> Set(RewriteType),
    hardware_profile: {compute, storage, network},
    ontology_slice: Set(NodeType),
    federation_endpoints: Set(Endpoint)
}
```

### Restriction map for P1

For a morphism f: K1 -> K2 (K1 federates with K2):

```
P1(f): P1(K2) -> P1(K1)
```

Meaning: when K1 federates with K2, what structural properties of K2 are visible from K1?
Answer: public endpoints and the intersection of access policies.
K1 can see K2's public topology but not K2's private governance.

---

## 3. P2: Knowledge Domain Presheaf

```
P2: K^op -> Set
```

P2 assigns to each kernel K its knowledge fiber:

```
P2(K) = {
    nodes: Set(Node) x Properties,
    relations: Set(Relation),
    classification_scheme: ClassificationSystem
}
```

### Restriction map for P2

For a morphism f: K1 -> K2:

```
P2(f): P2(K2) -> P2(K1)
```

Meaning: what nodes from K2 are visible from K1?
Answer: nodes where P1(K1).access_policy(actor) entails READ for the requesting actor.

**Critical**: P1 gates P2. The structural presheaf determines what the knowledge presheaf reveals.

---

## 4. Rewrite Permission (Two-Stage Validation)

A rewrite `env` by actor `a` on kernel K is permitted iff:

```
P1(K).access_policy(a) entails env.rewrite_type    // P1 check (structural)
  AND env.target_urn in dom(P2(K))                  // P2 check (knowledge exists)
  AND operad.validates(env, P2(K).nodes[env.target_urn])  // operad check
```

Current Go code: one `validate()` call.
Target: two sequential presheaf checks before the operad check. P1 gates P2.

---

## 5. Sheaf Condition: Gluing on Federation

When two kernels share views of the same node (same URN in both knowledge fibers),
do their views agree?

### Overlap set

```
P2(K1) intersection P2(K2) = { n : urn(n) appears in both kernels }
```

### Gluing condition

```
For all n in the overlap:
  P2(K1).properties(n) = P2(K2).properties(n)     // property agreement
  P2(K1).relations(n) subset P2(K2).relations(n) union local(K1)  // relation consistency
```

### Stratified sheaf: mapping to federation sync contract

| Sync mode | WF categories | Sheaf interpretation |
|-----------|--------------|---------------------|
| **Strict** | WF01, WF02, WF13 | Gluing must hold immediately. Disagreement blocks until governance resolves. Presheaf with values in pointed sets — distinguished "locked" state during conflict. |
| **Eventual** | WF05-WF07, WF11-WF15 | Gluing restored after delay. Tie-break tuple (event_time, kernel_id, event_id) is the canonical section — deterministic pick. Separated presheaf (uniqueness part of gluing holds, existence may lag). |
| **Local-only** | WF03, WF04, WF08-WF10 | No gluing requirement. Sections live in one kernel only. Restriction map sends them to empty set on other kernels. |

**Key insight**: mo:os does not need to be a full sheaf everywhere.
It is a **stratified sheaf**: strict on governance (P1), eventual on knowledge (P2), local on substrate.
The sheaf condition is enforced per-WF, not globally.

---

## 6. Natural Transformation: P1 -> P2 (Visibility)

There is a natural transformation eta: P1 -> P2 — "access policy materializes as visible nodes."

For kernel K and actor a:

```
eta_K(a) = { n in P2(K) : P1(K).access_policy(a) entails READ(n) }
```

This is the **visible fiber** — the subset of knowledge domain that actor a can see on kernel K.

### Naturality condition

For a federation morphism f: K1 -> K2:

```
eta_{K1} . P1(f) = P2(f) . eta_{K2}
```

Meaning: restrict structural access first then compute visibility = compute visibility first then
restrict knowledge. This is a correctness condition on the federation router.

If the router violates this, an actor sees different nodes depending on which kernel they query
through — a federation bug. Naturality = federation consistency.

---

## 7. Content-Addressed URN

### Definition

For a node with type_id T and immutable properties I:

```
urn(n) = "urn:moos:" + T + ":" + SHA256(canonical_serialize(T, I))[:16]
```

Where `canonical_serialize` = deterministic JSON (sorted keys, no whitespace, UTF-8 normalized).

### CI-3 compatibility

Identity stability: urn(M(x)) = urn(x) for all rewrites M.
Since MUTATE only touches mutable properties, and URN is derived from immutable properties only,
CI-3 holds by construction. The URN never changes because the hash inputs never change.

### Deduplication

If two kernels independently ADD the same concept (same type, same immutable properties),
they get the same URN. Federation merge is idempotent: P2(K1) union P2(K2) collapses duplicates.

### Migration path

Current human-readable URNs remain valid — they are just human-chosen immutable strings.
SHA scheme coexists: new nodes get SHA URNs, old nodes keep readable URNs.
The operad doesn't care about URN format, only uniqueness.

### Open question

Human-readable alias system? `urn:moos:alias:sam` LINK to `urn:moos:user:a7f3b2...`.
This is a relation, not a property — consistent with topology-property boundary.

---

## 8. Program Node Type

### Ontology definition

```
Node type: program
URN: urn:moos:program:<owner>.<slug>
Properties:
  - title (I)
  - owner_urn (I)
  - status (M): draft | active | completed | archived
  - created_at (I)
  - target_t (M): target moos-time for completion (e.g., T=180)
  - scope (M): description of what the program delivers
```

### Relations

A program node LINKs to:
- prg_task nodes (constituent tasks) — via WF18
- knowledge_item nodes (outputs/artifacts) — via WF18
- session nodes (conversations that contributed) — via WF18
- program nodes (nesting, sub-programs) — via WF18

### New rewrite category: WF18 (Program Composition)

| Field | Value |
|-------|-------|
| ID | WF18 |
| Category | Program composition |
| Allowed rewrites | LINK, UNLINK, MUTATE |
| Source types | program |
| Target types | prg_task, knowledge_item, session, program |
| Authority | owner |
| MUTATE scope | status, target_t, scope |

---

## 9. PRGs as Time-Stamped Data

### The temporal model

Legacy PRGs and ongoing work items are program nodes with temporal coordinates.
Not a separate concept — same type, different status, different time.

| Temporal position | Status values | Stratum | Mutability |
|-------------------|--------------|---------|------------|
| Past | completed, archived | S2 (materialized) | Immutable log entries |
| Present | active | S2 (materialized) | Running, mutable status/scope |
| Future | draft | S0 (authored) or S4 (projected) | Proposals, targets |

### Examples

- "Current implementation spec" = program node, target_t = T=180, status = draft
- "Moos diary entry T=158" = program node, status = completed, scope = "session summary"
- "T=162 presentation for Menno" = program node, target_t = T=162, status = draft
- Legacy PRG "calendar-purple" = program node, status = archived, original T-stamps preserved

### Graph logic

Every piece of work is a subgraph with temporal annotations.
The difference between a specification, a diary entry, and a task is stratum and completeness,
not type. "Thinking in graph logic" = one node type, differentiated by topology and time.

---

## 10. Classification Functors

### The classification category Class

Objects: classification schemes (LCC, Dewey, GAAP, IFRS, Go package taxonomy,
npm registry, arXiv categories, Python PEPs, RFC series, ISO standards).

Morphisms: mappings between schemes (LCC-to-Dewey crosswalk, GAAP-to-IFRS equivalence).

### The classification functor

```
C: Class -> Know
```

Maps a classification scheme to the set of knowledge nodes that use it:
- C(LCC) = all nodes classified under Library of Congress headings
- C(npm) = all nodes classified as npm packages
- C(GAAP) = all nodes classified under GAAP

### Crosswalks as natural transformations

A morphism in Class (e.g., LCC -> Dewey crosswalk) maps to a natural transformation
between the corresponding knowledge fibers.

In the graph:

```
[classification_scheme:LCC]   <-- WF15 semantic:classifies --> [ki:jaarrekening-2025]
[classification_scheme:IFRS]  <-- WF15 semantic:standard   --> [ki:jaarrekening-2025]
[crosswalk:LCC-IFRS]          <-- WF15 semantic:maps        --> [classification_scheme:LCC]
[crosswalk:LCC-IFRS]          <-- WF15 semantic:maps        --> [classification_scheme:IFRS]
```

The crosswalk node IS the natural transformation — a node that witnesses the mapping
between two classification schemes.

### Industry alignment

When the ontology's WFs align with industry conventions, the operad's structure mirrors
real-world professional practice:
- WF for accounting compliance -> maps to GAAP/IFRS
- WF for software dependency -> maps to npm/cargo/go-modules
- WF for legal jurisdiction -> maps to country codes / regulatory frameworks

Conventions are the TYPES in the operad — the ports through which real-world knowledge attaches.
Purpose reflected with known conventions = operad aligned with industry classification landscape.

---

## 11. Manifold Hypothesis

### The claim

The space of all possible knowledge graphs is high-dimensional (combinatorially explosive).
But actually useful knowledge graphs lie on a much lower-dimensional manifold, determined by:

1. The operad — constrains valid wiring patterns (dramatically reduces dimension)
2. Classification conventions — constrain meaningful node types and relations
3. User intent — actual queries and rewrites trace paths on the manifold

### HDC connection

The encoding phi(node) = bundling{incident wires} maps graph structure to R^d.
If the manifold hypothesis holds:

```
dim(manifold of useful graphs) << dim(R^d) << |possible graph states|
```

Similarity search works because useful knowledge is clustered on the manifold,
not scattered uniformly in R^d.

### Operad as tangent space

The operad defines the manifold's tangent space:
- Each valid rewrite category (WF) is a "direction" you can move on the manifold
- Port color compatibility matrix defines which directions compose — manifold curvature
- Well-aligned operad = low intrinsic dimensionality = good similarity search
- Misaligned operad = high intrinsic dim = distorted manifold = poor search results

### Testable prediction

Measure intrinsic dimensionality of the hypervector space as the graph grows.
If it stays low relative to d=10,000 -> operad is well-aligned.
If it grows toward d -> operad is too loose or constrained in the wrong dimensions.

Methods: PCA on phi(node) vectors, or intrinsic dimension estimators (MLE, correlation dimension).

### Connection to convention alignment (#10)

If the operad is aligned with industry conventions (classification functors map cleanly),
the manifold that HDC encodes faithfully represents the knowledge domain.
If misaligned — wrong port colors, wrong WFs, categories that don't match user thinking —
the manifold is distorted.

The classification functor C: Class -> Know provides an EXTERNAL CHECK on operad alignment:
if C maps standard industry categories to well-separated clusters in hypervector space,
the operad is doing its job.

---

## 12. Calendar as Temporal Projection

### Definition

```
P_calendar: GraphState -> TimeSeries
```

Where TimeSeries = { (t, Set(Node)) : t in MoosTime }

At each time point, the set of nodes that are active or relevant at that time.

### Temporal subgraph at time t

```
G(t) = { n in Nodes(G) : created_at(n) <= t AND (status(n) != archived OR archived_at(n) > t) }
```

### Presheaf over time

This is a presheaf over the time category (T, <=) — time-ordered,
with restriction maps that forget later nodes.

The calendar projection flattens this presheaf into a 1D timeline view.
It is **lossy** (not CI-2 compliant): many different graph states produce the same calendar view.
Valid for display and navigation, never for authority.

### Node positions in the calendar

| Temporal position | Source | Calendar representation |
|-------------------|--------|------------------------|
| Past | completed programs, closed sessions, archived items | Fixed markers on timeline |
| Present | active programs, running sessions | Current position |
| Future | draft programs with target_t, scheduled tasks | Projected markers (S4) |

### Calendar as S4 projection

The calendar is an S4 artifact. It must carry:

```json
{
  "stratum": "S4",
  "authoritative": false,
  "backing_projection": "P_calendar",
  "note": "Lossy: collapses full graph to 1D timeline"
}
```

---

## 13. Social Topology Functor

### Definition

```
Social: GraphState -> UserSpace
```

Maps every node to the user(s) who can reach it via upward traversal
(following WF01 ownership, WF02 governance relations).

### Fibers

The fibers of Social (inverse image of each user) are individual knowledge domains.
Overlaps between fibers (nodes reachable by multiple users) are shared knowledge.

### Fibration property

Social has the path-lifting property: any path in UserSpace
(user A shares access with user B) lifts to a path in GraphState
(the actual access/governance relations that enable sharing).

### Connection to P1

The Social functor factors through P1:

```
GraphState --P1--> StructuralFiber --forget--> UserSpace
```

Social = (forget access details) . P1

This means: social topology is a coarsening of structural topology.
You can always refine from social (who) to structural (who can do what).

---

## 14. Summary: All Theoretical Items Closed

| # | Topic | Status | Where in this doc |
|---|-------|--------|-------------------|
| 1-8 | (covered in previous docs) | Done | foundation-t158.md, reactive-topology-t158.md |
| 9 | Presheaf gluing | Done | Sections 1-6 |
| 10 | Content-addressed URN | Done | Section 7 |
| 11 | Program node type | Done | Section 8 |
| 12 | PRGs as time-stamped data | Done | Section 9 |
| 13 | Classification functors | Done | Section 10 |
| 14 | Manifold hypothesis | Done | Section 11 |
| 15 | Calendar as temporal projection | Done | Section 12 |
| 16 | Social topology functor | Done | Section 13 |
| + | Multi-kernel spawning | Addressed in foundation-t158.md section 9 |

### New ontology additions proposed

- Node type: **program** (section 8)
- Rewrite category: **WF18** (Program composition, section 8)
- Node type: **classification_scheme** (referenced in section 10, needs formal definition)
- Node type: **crosswalk** (referenced in section 10, needs formal definition)

### Implementation queue (not yet coded)

- Two-stage validation (P1 then P2) in Runtime.Apply()
- WF18 in ontology.json
- Program node type in ontology.json
- SHA256 URN generation option
- Cascade matrix rho(C) check (from reactive-topology-t158.md)
