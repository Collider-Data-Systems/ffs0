---
name: vsa-pattern-selector
description: HDC operation selection guide for graph operations. Use when choosing between Bind, Bundle, Permute for encoding graph structures into hypervectors.
---

# VSA Pattern Selector — HDC Operation Guide

Expert guide for choosing the correct HDC/VSA operation for each graph operation in mo:os.

---

## Decision Matrix

| I need to... | HDC Operation | Formula | Why |
|-------------|---------------|---------|-----|
| Create a new wire | **Bind** ⊗ | `SRC ⊗ φ(src) ⊕ TGT ⊗ φ(tgt)` | Pairing preserves both identities |
| Merge node neighborhoods | **Bundle** ⊕ | `φ(n) = ⊕ wires(n)` | Superposition keeps all info |
| Encode temporal order | **Permute** π^k | `π^i(φ(m_i))` | Position-encodes sequence |
| Find similar nodes | **Cosine similarity** | `cos(φ(a), φ(b))` | Bundled neighborhoods compared |
| Remove a wire | **Inverse bind** | `⊗^{-1}` (XOR self-inverse for binary) | Undo binding |
| Scope a subgraph | **Bundled binding** | `⊕{ φ(w) : BFS(root, depth) }` | Container as vector |
| Encode a TypeSpec | **Role binding** | `KIND ⊗ φ(kind_name)` | Kind as role vector |
| Encode port pair | **Bidirectional bind** | `SRC_PORT ⊗ φ(sp) ⊕ TGT_PORT ⊗ φ(tp)` | Port semantics preserved |

---

## Vector Space Configuration

| Parameter | Recommended | Notes |
|-----------|-------------|-------|
| Dimensionality (d) | 10,000 | Balance capacity vs compute |
| Vector type | Binary ∈ {0,1}^d | XOR binding, majority bundling |
| Alternative | Bipolar ∈ {-1,+1}^d | Multiply binding, sum bundling |
| Codebook size | ≤ e^(d/2) | Quasi-orthogonality guarantee |

---

## Pattern: Wire Encoding (complete)

```
w = SRC_ROLE ⊗ φ(source_urn)
  ⊕ SRC_PORT ⊗ φ(source_port)
  ⊕ TGT_ROLE ⊗ φ(target_urn)
  ⊕ TGT_PORT ⊗ φ(target_port)
```

**Why 4 terms?** Because wires are 4-tuples. Binary decomposition (2 terms) destroys port semantics. See HyperGraphRAG Proposition 1.

---

## Pattern: Morphism Log as Vector

```
log_vector = ⊕ { π^i(φ(morphism_i)) : i = 0..n }
```

Single vector encodes entire history. Query with `cos(log_vector, π^k(φ(query)))` to check "was this morphism applied at position k?"

---

## Anti-patterns

- ❌ Using Bind for aggregation (use Bundle)
- ❌ Using Bundle for pairing (use Bind)
- ❌ Ignoring port terms in wire encoding
- ❌ Forgetting permutation for ordered sequences
