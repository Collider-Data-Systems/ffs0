# Yoneda-HDC Graded Algebra — Category Space Characterization

> T=160 | The Yoneda embedding IS the HDC encoding. Types emerge from wiring.
> This document defines the computational architecture for the Z440 team.

---

## 1. The Bridge: Yoneda = φ(node)

The Yoneda lemma states: `Nat(h_A, F) ≅ F(A)` — an object is fully determined by
the totality of morphisms into it. In the kernel, a node is fully determined by its
incident relations (links). The HDC encoding:

```
φ(node) = ⊕ { SRC_ROLE ⊗ φ(src) ⊕ SRC_PORT ⊗ φ(src_port)
             ⊕ TGT_ROLE ⊗ φ(tgt) ⊕ TGT_PORT ⊗ φ(tgt_port)
             : (src, src_port, tgt, tgt_port) ∈ relations(node) }
```

This IS the Yoneda image of the node in ℝ^d. The functor:

```
y_HDC: GraphState → ℝ^d
y_HDC(node) = φ(node)
y_HDC(relation) = w(relation)
```

is fully faithful up to quasi-orthogonality: distinct wiring patterns produce
near-orthogonal hypervectors with probability → 1 as d grows.

**Consequence**: Two nodes with `cos(φ(A), φ(B)) > threshold` are categorically
similar — they participate in the same relation pattern. This is computable type
equivalence without inspecting the ontology.

---

## 2. The Graded Algebra

HDC operations (bind ⊗, bundle ⊕, permute π) combined with category composition
yield a graded algebra. Each grade is a functor from the previous:

```
Grade 0:  Atom      = random basis vector per URN           φ₀(urn) ∈ ℝ^d
Grade 1:  Wire      = binding of role-value pairs           φ₁ = ROLE ⊗ φ₀(urn)
Grade 2:  Node      = bundling of incident wires            φ₂ = ⊕{φ₁ : rel ∈ node}
Grade 3:  Fiber     = bundling of nodes in a kernel         φ₃ = ⊕{φ₂ : node ∈ K}
Grade 4:  Federation = bundling of kernel fibers            φ₄ = ⊕{φ₃ : K ∈ federation}
```

The inclusion functors:

```
ι₀₁: Grade 0 → Grade 1    (bind with role)
ι₁₂: Grade 1 → Grade 2    (bundle wires → node)
ι₂₃: Grade 2 → Grade 3    (bundle nodes → fiber)
ι₃₄: Grade 3 → Grade 4    (bundle fibers → federation)
```

Each ι is structure-preserving: cos(ι(A), ι(B)) ≈ cos(A, B) when A,B are from
the same grade. This is the n-category depth: not just maps, but maps between maps,
and the HDC closure property means ALL grades live in the same ℝ^d.

### Inverse Functors (unbinding)

Because bind is invertible:

```
ι₁₀: Grade 1 → Grade 0    φ₁ ⊗⁻¹ ROLE → φ₀(urn)    "what is this wire about?"
ι₂₁: Grade 2 → Grade 1    probe φ₂ with ROLE → φ₁    "what wires does this node have?"
ι₃₂: Grade 3 → Grade 2    probe φ₃ with NODE → φ₂    "what does this node look like here?"
ι₄₃: Grade 4 → Grade 3    probe φ₄ with KERNEL → φ₃  "what does this kernel contain?"
```

Probing a higher grade with a lower-grade key extracts the component — this is
the computational form of restriction morphisms in the presheaf model.

---

## 3. Spectral Characterization of Category Space

Given φ₂ for all nodes, construct the similarity graph:

```
S[i,j] = cos(φ₂(node_i), φ₂(node_j))
```

The graph Laplacian L = D - S (where D = diag(row sums)):

- **Eigenvalue λ₁ = 0** always (connected component)
- **Number of λ ≈ 0**: number of connected components = number of "true types"
  - If this equals 37 → ontology is correctly decomposed
  - If less → some types are redundant (should merge)
  - If more → some types should split
- **Fiedler vector** (eigenvector of λ₂): natural 2-partition of the graph
  - Sign of Fiedler(i) determines which half node_i belongs to
  - Recursive bisection → hierarchical type taxonomy
- **Cheeger constant** h(G) via Cheeger inequality:
  - `½(d - λ₂) ≤ h(G) ≤ √(2d(d - λ₂))`
  - Small h(G) → fibers are hard to separate (entangled knowledge)
  - Large h(G) → clean fiber boundaries (well-separated domains)

### Spectral Radius of Cascade Matrix

The cascade matrix C = T · P (from reactive-topology) has ρ(C) governing
termination. The HDC-encoded version:

```
C_HDC[i,j] = cos(φ_watcher(i), φ_reactor(j))
```

ρ(C_HDC) < 1 iff the reactive layer converges — testable via power iteration
on the hypervector similarity matrix.

---

## 4. Fiber Bundle Structure

The 4-kernel federation is a discrete fiber bundle:

```
π: E → B

B = {sam, menno, lola, moos}           base space (kernel identities)
F(K) = P2(K) = {nodes in kernel K}     fiber over K
E = ∐_{K ∈ B} F(K)                     total space (disjoint union)
π(node) = home_kernel(node)            projection
```

### Structure Group

G = Aut(ontology) = type-preserving automorphisms. A morphism g ∈ G acts on
fibers by permuting nodes within types:

```
g: F(K₁) → F(K₂)    preserving type_id
```

### Transition Functions

For overlapping fibers (nodes visible in multiple kernels via federation):

```
t_{K₁,K₂}: F(K₁) ∩ F(K₂) → F(K₂) ∩ F(K₁)
```

This is WF16 federation sync. The cocycle condition:

```
t_{K₁,K₂} ∘ t_{K₂,K₃} = t_{K₁,K₃}
```

guarantees consistency — three kernels seeing the same node agree on its state.

### Fiber Splitting via HDC

The Fiedler vector of the similarity graph suggests optimal fiber allocation:

```
assign(node) = argmin_{K ∈ B} ||φ₃(K) - φ₂(node)||
```

Place each node in the kernel whose fiber it's most similar to. This minimizes
cross-kernel communication (Cheeger cut) while maximizing intra-fiber coherence.

---

## 5. Type Expression and Distribution

Instead of static type_id assignment, types EXPRESS through the graded algebra:

```
type_expressed(node) = argmax_{t ∈ Types} cos(φ₂(node), μ(t))
```

where μ(t) is the centroid hypervector of all nodes with type_id = t.

### Type Drift Detection

If `cos(φ₂(node), μ(type_id(node)))` drops below threshold → the node's wiring
pattern has drifted from its declared type. Either:
1. The ontology needs a new type (type splitting)
2. The node needs reclassification
3. The node is at a crosswalk boundary between two types

### Type Distribution Across Federation

Each kernel's fiber has a type distribution:

```
dist(K) = histogram of { type_expressed(n) : n ∈ F(K) }
```

The Jensen-Shannon divergence between kernel type distributions:

```
JSD(K₁, K₂) = ½ D_KL(dist(K₁) || M) + ½ D_KL(dist(K₂) || M)
```

measures how differently two kernels "see" the type space. High JSD = complementary
knowledge domains (good). Low JSD = redundant fibers (merge candidate).

---

## 6. Crosswalks as Rotation Matrices

A crosswalk between classification scheme A and scheme B is a natural
transformation η: C_A → C_B. In HDC space:

```
η_HDC ≈ argmin_R ||R · φ_A - φ_B||   where R is orthogonal
```

The crosswalk IS the rotation matrix that aligns one scheme's cluster structure
with another's. For recursive crosswalks (crosswalk → crosswalk), this is
composition of rotations:

```
η_{A→C} = η_{B→C} ∘ η_{A→B} = R_{B→C} · R_{A→B}
```

The group of all crosswalks forms SO(d) restricted to meaningful rotations —
a Lie subgroup whose dimension equals the number of independent classification
axes in the knowledge space.

---

## 7. Implementation Architecture

### Phase A: HDC Engine (moos-kernel/internal/hdc/)

```go
package hdc

const Dim = 10000  // d = 10,000

type HV [Dim]float32

func Random(seed uint64) HV           // grade 0: atomic basis
func Bind(a, b HV) HV                 // ⊗: elementwise multiply
func Bundle(vs ...HV) HV              // ⊕: elementwise sum + normalize
func Permute(v HV, k int) HV          // π^k: circular shift by k
func Cosine(a, b HV) float32          // similarity
func Unbind(bound, key HV) HV         // ⊗⁻¹: recover component

type Codebook struct {
    mu   sync.RWMutex
    book map[graph.URN]HV              // URN → atomic basis vector
}

func (cb *Codebook) Encode(urn graph.URN) HV    // lazy: create if absent
```

### Phase B: Node Encoder (reactive — fires on every rewrite)

```go
type NodeEncoder struct {
    codebook *Codebook
    index    map[graph.URN]HV          // grade 2 cache
}

func (ne *NodeEncoder) EncodeRelation(rel graph.Relation) HV {
    return Bundle(
        Bind(ne.codebook.Encode("SRC_ROLE"), ne.codebook.Encode(rel.SrcURN)),
        Bind(ne.codebook.Encode("SRC_PORT"), ne.codebook.Encode(graph.URN(rel.SrcPort))),
        Bind(ne.codebook.Encode("TGT_ROLE"), ne.codebook.Encode(rel.TgtURN)),
        Bind(ne.codebook.Encode("TGT_PORT"), ne.codebook.Encode(graph.URN(rel.TgtPort))),
    )
}

func (ne *NodeEncoder) EncodeNode(state graph.GraphState, urn graph.URN) HV {
    var wires []HV
    for _, rel := range state.Relations {
        if rel.SrcURN == urn || rel.TgtURN == urn {
            wires = append(wires, ne.EncodeRelation(rel))
        }
    }
    return Bundle(wires...)
}
```

### Phase C: Spectral Analysis (new endpoint)

```
GET /hdc/similarity-matrix         → N×N cosine similarity (CSV or JSON)
GET /hdc/eigenvalues?top=10        → top eigenvalues of Laplacian
GET /hdc/fiedler                   → Fiedler vector (natural partition)
GET /hdc/type-coherence            → per-type centroid + per-node drift score
GET /hdc/fiber-distribution        → type histogram per kernel fiber
```

### Phase D: Reactive HDC Index

Register a watcher that fires on every LINK/UNLINK/ADD:
- Recompute φ₂(affected_nodes)
- Update the similarity index
- Check type drift → emit CLAIM if threshold exceeded
- Update fiber distribution

### Phase E: Federation Fiber Optimizer

Given similarity matrix + 4 kernels:
1. Compute Fiedler vector → suggest fiber rebalancing
2. Report Cheeger constant → fiber separability score
3. Suggest node migrations between kernels to minimize cross-fiber communication

---

## 8. Success Metrics

| Metric | How to Measure | Target |
|--------|---------------|--------|
| Type cluster separation | Inter-cluster / intra-cluster cosine ratio | > 3.0 |
| Ontology alignment | # HDC clusters vs 37 ontology types | ±5 |
| Crosswalk accuracy | cos(R · φ_A, φ_B) for known crosswalks | > 0.8 |
| Fiber separability | Cheeger constant h(G) | > 0.5 |
| Type drift detection | nodes where type_expressed ≠ type_id | flag all |
| Encoding stability | cos(φ₂(t), φ₂(t+1)) after incremental update | > 0.95 |
| Grade ladder coherence | cos(ι(A), ι(B)) ≈ cos(A, B) per grade | r > 0.9 |
