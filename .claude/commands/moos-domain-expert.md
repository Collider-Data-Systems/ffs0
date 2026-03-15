# MOOS Domain Expert Skill

This skill grounds Claude in the formal model, research foundations, and cross-domain mappings of the Collider / mo:os system. Read it fully before answering any technical question in this space.

---

## THE CENTRAL TRIANGLE

Every MOOS design decision lives inside this triangle. Never treat any corner in isolation.

```
Category Theory <————————> Hypergraph Rewriting (Wolfram)
       ↑                              ↑
       └—————————— mo:os ————————————┘
                    ↑
       Hypervector Computing (HDC / VSA)
```

**Category Theory** — formal language for objects, morphisms, functors, natural transformations. The kernel speaks this natively.

**Wolfram Hypergraph Rewriting** — the computation model: the graph IS the state. Morphism applications are rewriting rules. Causal invariance is the consistency guarantee.

**HDC / VSA (Kanerva)** — the representation layer: every graph structure encodes as a hypervector. GPU-parallel algebra over these vectors replaces serial graph traversal.

---

## FORMAL FOUNDATIONS

### Axioms (non-negotiable constraints)

1. The primary substrate is a typed hypergraph of objects and morphisms.
2. Meaning ≠ storage payload, metadata, embedding, or UI projection.
3. Structural truth is preserved through morphism composition and replayable change.
4. Evaluation may materialize contingent views without altering foundational ontology.
5. Governance and capability are graph-structural, not external afterthoughts.

### Core Primitives

`object · morphism · wire · scoped object · identity · graph state · authored artifact · payload · morphism log`

### Invariants

- Replayable structural change (append-only morphism log)
- Causal consistency (commutative morphisms produce same state regardless of ordering)
- Ontology separated from contingent configuration
- Semantics separated from metadata and projection
- Stable identity of typed concepts across views

### Semantics vs Syntax — the discipline

This is one of the most frequent failure modes. Enforce it in every code review and design decision:

| NOT semantics | IS semantics |
|---|---|
| Authored syntax | Evaluated meaning after hydration |
| Metadata fields | Morphism-defined structural relationships |
| Embeddings / vector retrieval | Ontological ground truth |
| UI projection / file tree | Foundational graph structure |
| Payload content | Typed graph topology |

**Rule**: A projection into UI, file tree, prompt, or vector space is NEVER the ontology. The Embedding functor output is a VIEW, not ground truth.

---

## STRATA MODEL

Five strata; each has a distinct identity and cannot be collapsed into another:

| Stratum | Name | Description |
|---|---|---|
| S0 | Authored | Raw user-created syntax; not yet validated |
| S1 | Validated | Passed structural constraints; not yet materialized |
| S2 | Materialized | Fully instantiated in graph; operational |
| S3 | Evaluated | Semantics computed; ready for projection |
| S4 | Projected | View emitted (UI, file, embedding, prompt) |

**Reducibility boundary**: S0–S1 are computationally reducible (deterministic, verifiable). S2+ involves LLM outputs, user actions, and irreducible computation.

**Promotion rules**: A concept moves stratum only through an explicit governance-approved step. An agent may PROPOSE a promotion but cannot approve it.

---

## KERNEL ARCHITECTURE

### Structure

```
pure core
  └─ Evaluate(Envelope, GraphState, Time) → (EvalResult, error)
effect shell
  └─ I/O, scheduling, persistence, networking
graph-state envelope
  └─ immutable snapshot passed into pure core
replay/mutation boundary
  └─ append-only morphism log; Σ: Log → State (catamorphism)
```

### The Four Morphisms (rewriting rules)

These are the ONLY ways to transform graph state. Everything else is a projection or query.

| Morphism | HDC analog | Wolfram analog |
|---|---|---|
| ADD | Introduce new basis vector | Create new graph element |
| LINK | Bind (⊗): associate two entities through typed port | Add hyperedge |
| MUTATE | Bundle update (⊕ with new term) | Rewrite local structure |
| UNLINK | Inverse bind | Remove hyperedge |

**Causal invariance**: LINK(A→B) ; LINK(C→D) = LINK(C→D) ; LINK(A→B) when wires are independent. This is the morphism-level Church-Rosser property. The kernel enforces it.

### Five Sanctioned Functors (projections, NOT ground truth)

1. **FileSystem** — graph → directory tree
2. **UI_Lens** — graph → rendered interface
3. **Embedding** — graph → vector space (for similarity retrieval)
4. **Structure** — graph → structural schema views
5. **Benchmark** — graph → evaluation metric surfaces

**Anti-pattern to catch and flag immediately**: treating any functor output as ground truth. The FileSystem functor output is a VIEW. Mutating the view does not mutate the graph.

### Category-Theoretic Constructions

- **Slice** = fan-in (from hyperedge → connected entities); retrieval of sources
- **Coslice** = fan-out (from entity → connected hyperedges); retrieval of dependents
- **Full subcategory** = Container OWNS its contents
- **Σ (catamorphism)** = log collapse to state (NOT a functor; a fold)
- **Natural transformation** = safe mapping between functors preserving graph structure
- **Colimit** = fusion/merge of retrieved subdiagrams (used in hydration)

---

## HYPERDIMENSIONAL COMPUTING (HDC / VSA)

### The Three Operations

Every HDC operation maps to a MOOS graph operation:

| HDC Op | Symbol | Property | MOOS Mapping |
|---|---|---|---|
| Binding | ⊗ | Dissimilar to both inputs; invertible | LINK morphism (wire creation) |
| Bundling | ⊕ | Similar to all inputs; superposition | Node state (superposition of incident wires) |
| Permutation | π^k | Encodes sequence/position | Morphism log temporal ordering |

### Key HDC Properties to Apply

- **Distributed**: ALL dimensions encode ALL information — no slots, holographic
- **Quasi-orthogonality**: Random d-dimensional vectors nearly orthogonal with P → 1 as d grows. Capacity ≈ e^(d/2) concepts per vector space
- **Invertible binding**: SHAPE ⊗ v_{shape-is-circle} ≈ CIRCLE — can recover components
- **Noise robust**: 10x more error-tolerant than neural nets; why the Embedding functor can use approximate nearest-neighbor search

### Wire Encoding (the key HDC formula)

A wire `(source_urn, source_port, target_urn, target_port)` encodes as:

```
w = SRC_ROLE ⊗ φ(source_urn) ⊕ SRC_PORT ⊗ φ(source_port)
    ⊕ TGT_ROLE ⊗ φ(target_urn) ⊕ TGT_PORT ⊗ φ(target_port)
```

### Node Hypervector (the "hypergraph hypervector")

```
φ(node) = ⊕ { w : w ∈ wires(node) }
```

Two nodes with similar neighborhoods → similar hypervectors → GPU similarity search without explicit graph traversal.

### Morphism Log Encoding

```
φ(log) = ⊕ { π^i(φ(m_i)) : i = 0..n }
```

Single hypervector encodes ENTIRE morphism history with temporal order preserved. Log replay becomes similarity search.

### GPU / CUDA Relevance

Once graph structures are encoded as hypervectors, all operations (bind, bundle, permute, similarity) are **embarrassingly parallel** — direct SIMD mapping. This is the "then GPU" from the founder's vision: not serial graph traversal, but parallel vector algebra over the entire graph simultaneously.

**Port diameter** = max graph distance (wire hops) between any two ports in a container's subgraph. Analogous to Wolfram effective dimension.

---

## HYPERGRAPH MATHEMATICS

### Why n-ary, not binary (HyperGraphRAG Proposition 1)

Binary decomposition of a knowledge hypergraph G_H is **provably lossy**:

```
H(X | φ_B(X)) > 0   (binary loses information)
H(X | φ_H(X)) = 0   (hypergraph preserves completely)
```

**Implication**: Any design that collapses 4-tuple wires `(src_urn, src_port, tgt_urn, tgt_port)` to plain binary edges **destroys port semantics**. Always flag this as an architectural regression.

### Bipartite Storage Bijection (Proposition 2)

A hypergraph can be losslessly stored as a bipartite graph:
- Entity nodes = original vertices
- Relation nodes = hyperedges
- Binary edges = participation

The `wires` table with 4-tuple uniqueness IS this bipartite encoding. Lossless and invertible.

### Information Efficiency Density (Proposition 3)

```
η = I(X; Y) / L
```

Hypergraph retrieval transmits more information per token than binary graph retrieval. When evaluating RAG architectures, compare η, not just recall.

---

## MULTI-PATH REASONING (LogicGraph)

### Minimal Support Sets

S ⊆ P is MinSup(S, G) iff S ⊢ G AND ∀S' ⊊ S: S' ⊬ G

**Application**: For any S2 operational state, ask: what is the minimal set of S1 authored objects that fully derive it?

### Convergent vs Divergent Evaluation

- **Convergent**: "Is this morphism sequence valid?" — correctness
- **Divergent**: "What OTHER morphism sequences reach the same state?" — completeness

**Critical finding**: LLMs strongly favor convergent reasoning and systematically miss alternatives (pseudo-divergence). The kernel must force divergent exploration structurally.

### Process vs Outcome Verification

Process-verified (each morphism validated individually) > outcome-verified (only final state checked). Always prefer process verification.

---

## LANGUAGE AND IMPLEMENTATION GUIDANCE

### Kernel Language: Go vs Others

**Go** is the primary recommendation for the kernel's effect shell and operational layer:
- Goroutines + channels = natural model for concurrent morphism processing
- Strong type system without GC unpredictability for hot paths (use sync.Pool)
- `encoding/json`, `net/http`, stdlib completeness → fast iteration
- Morphism log as append-only slice; graph state as struct with copy-on-write semantics

**Rust** is the right choice when:
- Zero-copy zero-allocation is a hard requirement in the pure core
- Writing the HDC vector operation primitives (SIMD via `std::arch` / `packed_simd`)
- Building the CUDA/GPU bridge layer (via `cudarc` or raw FFI)
- Ownership model maps perfectly to the graph-state envelope's immutability contract

**Functional languages** (Haskell, OCaml, Elm for UI) are right when:
- Expressing the categorical model directly: functors as type classes, natural transformations as polymorphic functions
- Algebraic data types for morphism envelopes: `data Morphism = Add URN Payload | Link Wire | Mutate URN Delta | Unlink Wire`
- Proof-carrying code for invariant verification (Idris/Lean for the pure core spec)
- The catamorphism Σ is literally a `fold` — functional languages make this explicit and verifiable

**Anti-pattern**: writing the pure core in a language where effects (I/O, exceptions, mutation) are not structurally separated from pure computation.

### GPU / CUDA for HDC Operations

The HDC algebra maps directly to GPU primitives:
- Binding ⊗ (XOR for binary vectors, elementwise multiply for real) → CUDA elementwise kernel
- Bundling ⊕ (elementwise add + threshold) → CUDA reduction kernel
- Permutation π^k → CUDA shift kernel
- Similarity search (cosine, dot product) → cuBLAS `gemv` / `gemm`

For d = 10,000 dimensions and N nodes: similarity search over the full graph is O(N·d) parallel ops on GPU — milliseconds, not seconds.

### Data Pipelines

The hydration pipeline IS a data pipeline: Authored → Validated → Materialized → Evaluated → Projected.

Design rules:
- Each stage is a **pure function** (or pure functor): same input → same output
- Stages compose: `Σ ∘ Validate ∘ Parse` is itself a valid pipeline
- Failures are typed errors at the stage boundary, not exceptions propagating through
- Backpressure is native to the morphism log: you cannot hydrate S2 from unvalidated S1

Pipeline technology choices:
- In-process: Go channels or Rust `tokio` streams for the kernel pipeline
- Distributed: Apache Arrow Flight (zero-copy columnar) for the GPU CDU bridge
- Streaming: Kafka/Redpanda for append-only morphism log fan-out to subscribers

### Tensor Math

Tensors appear in MOOS at three layers:
- **HDC vectors** — rank-1 tensors; algebra is binding/bundling/permutation
- **Adjacency/incidence matrices** — rank-2 tensors encoding graph topology
- **Attention weights in LLM coprocessor** — rank-3+ tensors; treat as black box at S2 boundary

Key operations:
- `φ(node)` construction = sparse tensor contraction over incident wire encodings
- Port diameter calculation = shortest-path tensor (Floyd-Warshall or BFS over adjacency)
- Embedding functor = linear map T: GraphState → ℝ^d (preserves structure iff T is a functor)

---

## DESIGN DECISION FRAMEWORK

When the user asks "should we use X or Y" or "review this architecture", apply this sequence:

1. **Check the triangle**: Does the decision affect Category (morphism structure), Wolfram (rewriting/replay), or HDC (representation/similarity)? Always map the decision to at least one corner.
2. **Check the semantics/syntax boundary**: Does the design conflate a projection with ground truth? Does it put semantics in metadata?
3. **Check the strata**: Does the design respect the S0→S1→S2→S3→S4 promotion chain? Does it skip validation?
4. **Check invariants**: Is structural change replayable? Is morphism composition causally invariant? Is identity stable across views?
5. **Check the anti-patterns**:
   - Treating functor output as ontology
   - Binary decomposition of n-ary relations
   - Relying on LLM agents for exhaustive divergent reasoning
   - Effects inside the pure core
   - Outcome-verified instead of process-verified

---

## COMMON CROSS-DOMAIN MAPPINGS (quick reference)

| Domain | Concept | MOOS Equivalent |
|---|---|---|
| Category Theory | Object | Node (OBJ01–OBJ13) |
| Category Theory | Morphism | ADD / LINK / MUTATE / UNLINK |
| Category Theory | Functor | FileSystem / UI_Lens / Embedding / Structure / Benchmark |
| Category Theory | Natural Transformation | Safe inter-functor mapping |
| Category Theory | Slice category | Fan-in (entity ← hyperedges) |
| Category Theory | Coslice category | Fan-out (entity → hyperedges) |
| Category Theory | Catamorphism | Σ: Log → State (log collapse) |
| Category Theory | Colimit | Fusion of retrieved subdiagrams |
| Wolfram | Rewriting rule | Morphism application |
| Wolfram | Multiway system | Concurrent agent morphism branches |
| Wolfram | Causal invariance | Replay consistency (commutative morphisms) |
| Wolfram | Effective dimension | Port diameter |
| Wolfram | Ruliad | Full reachable state space via 4 morphisms |
| Wolfram | Computational irreducibility | S2+ strata (LLM+user behavior) |
| Wolfram | Computational reducibility | S0–S1 (kernel invariants) |
| HDC | Binding ⊗ | LINK morphism (wire creation) |
| HDC | Bundling ⊕ | Node state (superposition of wires) |
| HDC | Permutation π^k | Morphism log temporal ordering |
| HDC | Quasi-orthogonality | Embedding functor approximate retrieval |
| HDC | GPU SIMD | Parallel ops over all nodes simultaneously |
| LogicGraph | Minimal support set | Minimal S1 dependency for S2 state |
| LogicGraph | Convergent reasoning | Morphism sequence validity check |
| LogicGraph | Divergent reasoning | Alternative morphism sequences to same state |
| LogicGraph | Process verification | Per-morphism kernel validation |
| HyperGraphRAG | Proposition 1 | Why 4-tuple wires, not binary edges |
| HyperGraphRAG | Proposition 2 | Wire table = bipartite bijection |
| HyperGraphRAG | Bidirectional expansion | Slice + coslice traversal |

---

## AGENT INTERPRETATION RULES

An agent (including Claude) operating in this system:

- **May**: evaluate, materialize, query-navigate a scoped graph
- **May**: propose normalizations and promotions
- **May NOT**: define canon by fiat
- **May NOT**: treat vector retrieval or prompt context as semantic ground truth
- **May NOT**: approve its own promotion proposals (governance approves)

These rules apply to Claude reasoning about MOOS designs too — proposals, not fiat.
