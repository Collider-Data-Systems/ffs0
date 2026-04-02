# Nomenclature Foundations — mo:os
Date: 2026-04-01 | T=151

Deep research establishing the three-layer terminology for mo:os.
This document is the authoritative source for naming decisions in the kernel.

---

## The Three Layers

mo:os is built on three distinct traditions that compose cleanly:

```
┌─────────────────────────────────────────────┐
│  Layer 3: HDC/VSA  (compute + similarity)   │
│  φ(element) = ⊕{hypervectors of relations}  │
├─────────────────────────────────────────────┤
│  Layer 2: Spivak Operads  (grammar/types)   │
│  ports · wiring diagrams · valid wiring     │
├─────────────────────────────────────────────┤
│  Layer 1: Wolfram Hypergraph  (runtime)     │
│  elements · relations · rewrite rules       │
└─────────────────────────────────────────────┘
```

A **relation** (Layer 1) IS a **wire connecting typed ports** (Layer 2) IS a **hypervector binding** (Layer 3). Same object, three views.

---

## Layer 1 — Wolfram Hypergraph (Runtime)

**Source:** Wolfram Physics Project Technical Background
https://www.wolframphysics.org/technical-introduction/additional-material/appendix-graph-types/
https://www.wolframphysics.org/glossary/
https://wolframinstitute.org/research/hypergraph-rewriting

### Terms

**Element** (= atom of space, = vertex, = node)
A single point in the hypergraph. Has identity but no intrinsic structure.
Identity is defined by the relations it participates in, not by internal fields.
In mo:os code: `model.Node` (keep "node" as it's standard in graph theory).

**Relation** (= hyperedge)
A tuple of elements connected together. In a directed hypergraph, the tuple
has a source set and a target set. In mo:os: a relation connects elements
through typed ports (see Layer 2). In code: replaces `model.Binding`.

**Update Rule** (= rewrite rule, = morphism in the log)
A pattern `H1 → H2`: find a matching sub-hypergraph, replace it.
In mo:os the four update rules are: ADD, LINK, MUTATE, UNLINK.
These are logged in the causal graph. In code: `rewrite.Plan`.

**Causal Graph**
A directed acyclic graph where each vertex is an update event, and
edge A→B exists iff event B was only possible because of event A.
In mo:os: the morphism log. `state(t) = fold(log[0..t])`.

**Causal Invariance**
All orderings of update rule application yield isomorphic causal graphs.
Stronger than Church-Rosser/confluence. Equivalent to: independent updates commute.
In mo:os: CI-1 (the first of five causal invariants).

### What NOT to use
- "binding" — collides with HDC binding operation (see Layer 3)
- "edge" — too generic, implies 2-arity only
- "morphism" for the graph element — morphism = the operation, not the wire

---

## Layer 2 — Spivak Operads (Grammar / Type System)

**Source:** David Spivak, "The operad of wiring diagrams" (2013)
https://arxiv.org/abs/1305.0297
https://math.libretexts.org/Bookshelves/Applied_Mathematics/Seven_Sketches_in_Compositionality:_An_Invitation_to_Applied_Category_Theory_(Fong_and_Spivak)/06:_Circuits_-_Hypergraph_Categories_and_Operads/6.03:_Hyper_Graph_Categories

**nLab reference:**
https://ncatlab.org/nlab/show/hypergraph+category

### Terms

**Port**
A named, typed interface point on an element. Ports define what relations
can attach and in what direction. Port compatibility determines valid wiring.
In mo:os code: `model.Port`, `model.PortSpec` — unchanged, correct.

**Wiring Diagram**
A pattern showing how ports of multiple elements connect.
In Spivak: morphisms in the operad. In mo:os: a `rewrite.Plan` is a wiring diagram.

**Operad**
The collection of all valid wiring patterns and their composition rules.
In mo:os: the `cs.Registry` IS the operad — it defines what port-to-port
connections are admissible and how they compose.

**Hypergraph Category**
A symmetric monoidal category where each object has Frobenius monoid structure.
This is the categorical foundation of undirected wiring diagrams.
Key fact: hypergraph categories have been rediscovered 5+ times under different names.
In mo:os: the full system (CS grammar + HG instance) forms a hypergraph category.

**Port Saturation**
For each port declared on an element type, is that port connected to a relation?
Saturated = all mandatory ports are wired. This is the König property on the
incidence bipartite graph: minimum vertex cover = maximum matching.
In mo:os: the Explorer's "saturation" view measures this.

### What NOT to use
- "CS Grammar" — vague, not a math term. Use "operad" or "type registry"
- "binding kind" — use "relation type"
- "categorical space" — use "operad" (it IS an operad)

---

## Layer 3 — HDC / VSA (Compute + Similarity)

**Source:** Pentti Kanerva, "Hyperdimensional Computing" (2009)
https://www.semanticscholar.org/paper/Hyperdimensional-Computing:-An-Introduction-to-in-Kanerva/425931e434f6b370cc6cdd2db58873843def7d7f
https://en.wikipedia.org/wiki/Hyperdimensional_computing
https://pmc.ncbi.nlm.nih.gov/articles/PMC10588678/

### Terms

**Hypervector**
A very high-dimensional binary or real-valued vector (typically D=10,000).
Random hypervectors are nearly orthogonal — two random ones share ~50% components
but are treated as dissimilar. The high dimension makes them robust to noise.

**Binding (HDC)**  ⊗ : H × H → H
Multiplies two hypervectors element-wise (XOR for binary, Hadamard product for bipolar).
Result is dissimilar to both inputs but encodes the ordered pair.
IMPORTANT: This is NOT the same as "binding" in graph theory. In mo:os code,
use "binding" ONLY in HDC context. Use "relation" for graph hyperedges.

**Bundling** (HDC)  ⊕ : H × H → H
Adds hypervectors (majority vote for binary, sum for real).
Result is SIMILAR to all inputs — encodes a set.
In mo:os: φ(element) = ⊕{hypervectors of incident relations} = the element's
position in vector space, defined by its relational context.

**Permutation** (HDC)  ρ : H → H
Rotates components of a hypervector. Encodes sequence/order.
In mo:os: encodes the ordered role an element plays in a relation.

**VSA (Vector Symbolic Architecture)**
The family of HDC systems. Notable variants:
- BSC (Kanerva): binary vectors, XOR binding, majority bundling
- HRR (Plate): real vectors, circular convolution binding
- MAP (Gayler): bipolar ±1, Hadamard binding

### What NOT to use
- "binding" for graph relations — use only in HDC context
- "HDC embedding" — the correct term is φ(x) = the hypervector encoding of element x

---

## Node Identity and Access Control

**NOT content-addressing:** Node identity in mo:os is NOT the hash of its content
(that is the Merkle/IPFS model where changing content changes identity).

**CORRECT model:** URN-based stable identity + key-controlled access.
- Node URN = stable identifier, like a blockchain public address
- SHA hashes = used for INTEGRITY VERIFICATION (has this node been tampered with?)
- Access = controlled by ownership/role permissions, not by hash knowledge
- A user with "superadmin" role can read/write any node
- A user with "member" role can only read nodes they "own" via a governs relation

This is closer to the blockchain/PKI model: the address is public, access requires
the right key or governance relation.

**Source:** IPFS Merkle DAG (for contrast)
https://docs.ipfs.tech/concepts/merkle-dag/

---

## String Diagrams (CT foundation)

**Source:** Joyal & Street (1991), Selinger (2009)
https://en.wikipedia.org/wiki/String_diagram
https://ncatlab.org/nlab/show/string+diagram

In string diagrams:
- **Wires** = objects (types) — the flowing "stuff"
- **Boxes** = morphisms (transformations) — the operations
- Composition = connecting output wire of one box to input wire of another

This is DUAL to how we think of graphs (where nodes are objects and edges are morphisms).
In mo:os: elements are boxes (they DO things via their ports), relations are wires
(they carry the typed flow between ports). This duality is intentional and correct.

---

## Causal Invariance vs Church-Rosser

**Source:** Gorard, "ZX-Calculus and Extended Hypergraph Rewriting" (2020)
https://www.researchgate.net/publication/344505638_ZX-Calculus_and_Extended_Hypergraph_Rewriting_Systems_I_A_Multiway_Approach_to_Categorical_Quantum_Information_Theory

- **Church-Rosser / Confluence**: all divergent rewriting paths eventually reconverge
- **Causal Invariance**: all paths yield ISOMORPHIC CAUSAL GRAPHS (strictly stronger)
- Causal invariance → confluence, but not vice versa
- In mo:os CI-1: independent relations (non-overlapping affected elements) commute

---

## Nomenclature Decision Table

| Concept | Use This | Not This | Layer |
|---------|----------|----------|-------|
| Identity point in graph | node | element, vertex, anchor | L1 |
| Typed connection between nodes | relation | binding, edge, wire | L1 |
| Type of a relation | relation type | binding kind, wire kind | L1/L2 |
| Interface point on a node | port | slot, endpoint | L2 |
| Valid composition rules | operad | CS grammar, categorical space | L2 |
| The type registry | operad (or registry) | grammar, schema | L2 |
| Role a node plays in a relation | role | participant | L1/L2 |
| Attachment point (role+port) | incidence | binding slot | L1 |
| Graph transformation operation | rewrite / update | morphism (for the op) | L1 |
| The log of rewrites | causal graph | morphism log | L1 |
| HDC multiply two vectors | binding (HDC) | — | L3 |
| HDC add two vectors | bundling | — | L3 |
| HDC vector of a node | hypervector / φ(x) | embedding | L3 |
| Node identity | URN | SHA hash | all |
| Access control | permission / ownership | content-addressing | all |
