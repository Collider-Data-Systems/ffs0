---
name: harmony-hdc
description: "Use only when the task explicitly concerns HDC/VSA encoding, hypervectors, similarity search, or GPU vector algebra for mo:os representations."
---

# Harmony HDC — Hyperdimensional Computing for mo:os

You are an HDC/VSA (Hyperdimensional Computing / Vector Symbolic Architecture) expert for mo:os. HDC is the representation layer: every graph structure encodes as a hypervector. GPU-parallel algebra over these vectors replaces serial graph traversal.

---

## The Three Operations

| HDC Op          | Symbol | Property                              | mo:os Mapping                       |
| --------------- | ------ | ------------------------------------- | ----------------------------------- |
| **Binding**     | ⊗      | Dissimilar to both inputs; invertible | LINK morphism (wire creation)       |
| **Bundling**    | ⊕      | Similar to all inputs; superposition  | Node state (superposition of wires) |
| **Permutation** | π^k    | Encodes sequence/position             | Morphism log temporal ordering      |

---

## Key HDC Properties

- **Distributed**: ALL dimensions encode ALL information — no slots, holographic
- **Quasi-orthogonality**: Random d-dimensional vectors nearly orthogonal with P → 1 as d grows
- **Capacity**: ≈ e^(d/2) concepts per vector space
- **Invertible binding**: `SHAPE ⊗ v(circle) ≈ CIRCLE` — can recover components
- **Noise robust**: 10× more error-tolerant than neural nets

---

## Wire Encoding (core formula)

A wire `(source_urn, source_port, target_urn, target_port)` encodes as:

```
w = SRC_ROLE ⊗ φ(source_urn) ⊕ SRC_PORT ⊗ φ(source_port)
    ⊕ TGT_ROLE ⊗ φ(target_urn) ⊕ TGT_PORT ⊗ φ(target_port)
```

---

## Node Hypervector

```
φ(node) = ⊕ { w : w ∈ wires(node) }
```

Two nodes with similar neighborhoods → similar hypervectors → GPU similarity search without explicit graph traversal.

---

## Morphism Log Encoding

```
φ(log) = ⊕ { π^i(φ(m_i)) : i = 0..n }
```

Single hypervector encodes ENTIRE morphism history with temporal order preserved.

---

## GPU / CUDA Mapping

| HDC Operation       | CUDA Primitive              | Complexity |
| ------------------- | --------------------------- | ---------- |
| Binding ⊗ (binary)  | Elementwise XOR kernel      | O(d)       |
| Binding ⊗ (real)    | Elementwise multiply        | O(d)       |
| Bundling ⊕          | Elementwise add + threshold | O(d)       |
| Permutation π^k     | Circular shift kernel       | O(d)       |
| Similarity (cosine) | cuBLAS gemv / gemm          | O(N·d)     |

For d=10,000 dimensions and N nodes: full graph similarity search = **milliseconds on GPU**.

---

## Hypergraph Mathematics

### Why n-ary, not binary (HyperGraphRAG Proposition 1)

```
H(X | φ_B(X)) > 0   (binary loses information)
H(X | φ_H(X)) = 0   (hypergraph preserves completely)
```

Binary decomposition of 4-tuple wires **destroys port semantics**. Always flag as regression.

### Bipartite Storage Bijection (Proposition 2)

The `wires` table with 4-tuple uniqueness IS a lossless bipartite encoding.

### Information Efficiency Density (Proposition 3)

```
η = I(X; Y) / L
```

Hypergraph retrieval transmits more information per token than binary graph retrieval.

---

## Port Diameter

**Port diameter** = max graph distance (wire hops) between any two ports in a container's subgraph. Analogous to Wolfram effective dimension.

Used for: complexity metrics, benchmark functor, subgraph scoping decisions.

---

## Design Anti-patterns

- ❌ Treating Embedding functor output as ground truth (it's a VIEW)
- ❌ Binary decomposition of n-ary wire relations
- ❌ Serial graph traversal when HDC similarity search suffices
- ❌ Ignoring temporal ordering (use permutation π^k)
