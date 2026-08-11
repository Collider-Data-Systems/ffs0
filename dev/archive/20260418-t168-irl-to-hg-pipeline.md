# IRL → HG pipeline — the vector-space & sheaf lingo

> T=168 (April 18, 2026). Companion to `20260418-t168-s0-operadic-layer.md` and `20260418-t168-s1-superset-doctrine.md`.
> Origin: sam's ask — *"IRL into HG and the classification schemas help me with lingo here i think i am talking about vector spaces here"*.
> Grounding: two parallel research subagent reports (sheaf theory on graphs; HDC/VSA + orthogonal Procrustes). Pipeline-metrics and Ricci grounding deferred to next round — §7 has the placeholders.

## 1. The question

Sam: *"when we consider the scope of actual grammar: IRL into HG and the classification schemas help me with lingo here i think i am talking about vector spaces here."*

Decoded: what is the formal pipeline by which a real-world signal becomes a typed, wired node in the hypergraph — and what vocabulary names each layer? Vector spaces are one leg of the answer. Sheaves are the other. Operads carry the compositions across.

## 2. The pipeline, top to bottom

```
IRL SIGNAL               (raw; natural language / sensor reading / ticker / file)
   │
   │  EMBED           — map into ℝ^d (HDC hypervector / transformer embedding)
   ▼
EMBEDDING vector φ ∈ ℝ^d
   │
   │  DECODE via FRAME — project against the classification scheme's unit vectors
   ▼
CLASSIFICATION (type assignment; may be multi-hat)
   │
   │  GRAMMAR CHECK  — S1 type + allowed ports admit this wiring?
   ▼
S1 TYPED NODE
   │
   │  ADD/LINK       — four-rewrites commit to the HG
   ▼
S2 INSTANCE in the HG
   │
   │  GLUE           — local kernel's sheaf section, compatible with neighbours via bridges
   ▼
FEDERATED HG — global section across kernels, or inconsistency flagged by the sheaf Laplacian
```

Five layers, each with a different category of vocabulary. Four interfaces, each a **functor** from one category to the next.

## 3. Vector-space lingo (layers 1→3: embedding & classification)

### 3.1 The embedding

`φ : Symbol → ℝ^d` — injective map preserving chosen structure. In HDC, `d` is large (~10,000) so that random vectors are quasi-orthogonal; in transformer embeddings, `d` is moderate (384–4096) with learned structure.

**Operations** (Plate's HRR / Kanerva / Gayler MAP):

| Op | Meaning | Formal shape |
|----|---------|--------------|
| **bundling** `φ_a + φ_b` | superposition (set-like aggregation); preserves similarity to constituents | vector addition, optionally normalize |
| **binding** `φ_a ⊛ φ_b` | pair association (key↔value, role↔filler); non-commutative | circular convolution (HRR) = **unitary operator**, norm-preserving |
| **permutation** `P φ` | sequence / role protection | fixed P ∈ O(d) |

All three are **norm-preserving** and **invertible** — they live in O(d). HRR binding in the Fourier domain = component-wise multiplication of unit-modulus complex vectors = **rotation in ℂ^d**. That's the cleanest "binding-as-rotation" story and it's what justifies treating crosswalks as rotations.

### 3.2 The classification scheme = a tight frame

The word sam wanted: **frame** (Duffin–Schaeffer 1952), not basis.

A **frame** `{ψ_i}` in ℝ^d is a spanning set with energy bounds `A‖x‖² ≤ Σᵢ|⟨x,ψᵢ⟩|² ≤ B‖x‖²`. When types outnumber dimensions (k > d, which is the normal case for a rich classification scheme), a basis cannot accommodate them — you need a **tight frame** (A=B) or an **equiangular tight frame (ETF)** (all pairwise inner products equal). This balances redundancy without collapsing types onto each other.

| Lingo | Use for |
|-------|---------|
| **basis** | k = d, linearly independent. Too restrictive for ontology-scale classification. |
| **orthonormal basis** | k = d, orthogonal unit vectors. Rare in practice. |
| **frame** | generic overcomplete spanning set. |
| **tight frame** | energy-preserving frame. Default choice for a classification scheme. |
| **ETF (equiangular tight frame)** | maximally symmetric tight frame. The optimum when you want every type to be equidistant from every other. |
| **atlas / chart** | *only* if types live on a submanifold and you're gluing local coordinate patches. Wrong register for flat classification. |

**Definition.** A **classification scheme** `C` is a labelled tight frame `{(t_i, ψ_i)}` in ℝ^d where each `ψ_i` is the unit vector encoding type `t_i`. Classifying a signal is taking its embedding `φ` and computing `t* = argmax_i ⟨φ, ψ_i⟩`.

### 3.3 The crosswalk = orthogonal Procrustes = data migration functor

Three names for the same thing, at three levels of abstraction.

**Orthogonal Procrustes (Schönemann 1966).** Given embeddings `Φ_A, Φ_B ∈ ℝ^{d×n}` of the same n nodes under two classification schemes A and B, the best rotation aligning them is

```
R* = argmin_{R ∈ O(d)} ‖R · Φ_A − Φ_B‖_F
```

Closed form via SVD: compute `M = Φ_B Φ_Aᵀ`, decompose `M = UΣVᵀ`, set `R* = UVᵀ`. Restrict to SO(d) (proper rotation, no reflection) by flipping the sign of the last column of U if `det(UVᵀ) = −1`.

**Data migration functor Δ_F (Spivak 2010).** Given schemas A and B as categories, and a functor `F : A → B`, there's a **pullback** `Δ_F : B-Set → A-Set` and left/right adjoints `Σ_F ⊣ Δ_F ⊣ Π_F`. The adjoint triple is the full crosswalk apparatus — pullback (strict), left Kan extension (optimistic), right Kan extension (conservative).

**Geometric morphism between classifying toposes.** Under the sheaf view, a crosswalk is a geometric morphism `f : Sh(B, J_B) → Sh(A, J_A)` — a pair `f* ⊣ f_*` of adjoint functors with `f*` left-exact. The abstract nonsense statement of the same move.

**Identity to prove (v3.10 open).** For well-behaved classification schemes, the three views coincide:
```
Procrustes rotation R*  ⟺  Δ_F on the labels  ⟺  f* on the classifying topos
```

### 3.4 Frame bundles and moduli

When you fix semantic content and ask "what are all the orientations of the classification frame consistent with it?", you get an **O(d)-torsor** — a fibre of the **frame bundle** `F(M)` over the content manifold. For k-type schemes (k < d), the natural moduli space is the **Stiefel manifold** `V_k(ℝ^d) = O(d) / O(d−k)` — orthonormal k-frames in ℝ^d.

This gives us a clean answer to "how many classification schemes of size k are there?" — they're parameterized by points on `V_k(ℝ^d)`, with crosswalks as geodesic paths between them.

## 4. Sheaf-theoretic lingo (layers 4→5: wiring & federation)

### 4.1 Cellular sheaf on the HG

A **cellular sheaf** `F` on the hypergraph `G = (V, E)` assigns:
- a vector space `F(v)` (**stalk**) to each node v — the local data attached there
- a vector space `F(e)` to each relation e
- a linear **restriction map** `F(v → e) : F(v) → F(e)` for each incidence (node touches relation)

A **0-cochain** chooses `s(v) ∈ F(v)` at every node. It is a **global section** iff every restriction agrees:
```
F(v → e) s(v) = F(w → e) s(w)   for every relation e = {v, w}
```

The **sheaf Laplacian** `L_F = δ* δ` generalizes the graph Laplacian. Its kernel is `H⁰(G; F)` = **the space of global sections**. Non-zero spectrum detects **local-to-global inconsistency**: the larger the smallest non-zero eigenvalue, the more strongly local sections disagree along restrictions.

**What this buys us.** A multi-kernel federation with twin_link bridges is exactly a cellular sheaf on the kernel-quotient graph. The sheaf Laplacian detects federation inconsistency *mechanically* — we don't have to hand-write reconciliation code; we run `L_F` and look at the non-zero spectrum.

Canonical refs: Hansen & Ghrist, *Toward a Spectral Theory of Cellular Sheaves* (arXiv:1808.01513); Ghrist, *Elementary Applied Topology* ch. 9.

### 4.2 Presheaf → sheaf: the gluing axiom

A **presheaf** `F : Open(X)ᵒᵖ → Set` is just a functor. It becomes a **sheaf** iff for every open U and every cover `{U_i → U}`, the diagram

```
F(U) → ∏ᵢ F(U_i) ⇒ ∏ᵢⱼ F(Uᵢ ∩ Uⱼ)
```

is an **equalizer**. Concretely: sections on U are tuples `(sᵢ)` with `sᵢ|_{Uᵢ∩Uⱼ} = sⱼ|_{Uᵢ∩Uⱼ}`. Two restrictions into the pairwise intersection must agree.

**Translation.** In our setting: each kernel has a view of the HG (its sections). When kernels overlap (shared URNs across twin_link'd kernels), their views must agree on the intersection. A presheaf that fails this is **not a sheaf** — it has inconsistencies. Sheafification forces the equalizer condition by quotienting out the incompatibilities.

### 4.3 The operad of (undirected) wiring diagrams

Spivak's **operad of undirected wiring diagrams** (arXiv:1305.0297) has algebras that are **network-style data-sharing systems** — exactly the formal pattern for S0 op-nodes aggregating S1 stalks across kernel fibres. Vagner–Spivak–Lerman (arXiv:1408.1598) extends this to open dynamical systems.

**This is the formal grounding for S0.** Our op-nodes (program, session, purpose, workflow, channel) are algebras over the operad of wiring diagrams. Their slots are diagram ports. Their threading is operad composition. Their yield is the algebra evaluation.

## 5. The three-views identity (key claim)

For a well-behaved classification scheme `C` and its crosswalk to another scheme `C'`:

| View | Form | Good for |
|------|------|----------|
| Vector-space | Orthogonal Procrustes rotation `R* = UVᵀ` | Computing it; numerical optimization |
| Category-theoretic | Data migration functor `Δ_F : C'-Set → C-Set` | Reasoning about composition; colimit/limit of crosswalks |
| Topos-theoretic | Geometric morphism `f : Sh(C', J') → Sh(C, J)` | Federation; the sheaf-of-types view |

**Claim (v3.10 proof obligation).** For classification schemes encoded as tight frames in a shared ℝ^d ambient space, these three views produce the same transport of data. Procrustes computes the rotation; Δ_F labels it categorically; the geometric morphism situates it in the sheaf topos. Unit/counit of the adjunction correspond to Procrustes reconstruction error bounds.

## 6. Mapping to current doctrine (what this recontextualizes)

| Current (T=168) | Formal name (this note) | Depth gained |
|-----------------|--------------------------|--------------|
| `classification_scheme` type (S1) | **tight frame in ℝ^d**; labelled unit vectors per type | Can now talk about frame bounds, redundancy, ETF-optimality |
| `crosswalk` (not a type yet) | **orthogonal Procrustes rotation** / **data migration functor Δ_F** / **geometric morphism** | Three views; computable via SVD; composable via functor composition |
| `purpose` HDC formula `φ(target) − φ(current)` | **difference vector in embedding space**, naturally a tangent to the content manifold | Connects purpose to frame-bundle gauge theory |
| WF20 `grammar_promotion` Promote/Express adjoint | Candidate for **adjoint triple Σ_F ⊣ Δ_F ⊣ Π_F**: Σ_F (optimistic Promote), Δ_F (pullback Express), Π_F (conservative Promote) | Three flavours of promotion, not just one |
| `twin_link` federation | **Cellular sheaf on kernel-quotient graph**; inconsistency detected by **sheaf Laplacian** | Mechanical consistency check, not hand-rolled reconciliation |
| S0 op-nodes (program, session, purpose, workflow, channel) | **Algebras over the operad of undirected wiring diagrams** (Spivak) | Slots, threading, yield are now a published mathematical object |
| `view_filter` predicate (§M14, §M15) | **Restriction map** `F(v → e)` of the cellular sheaf | T-cone is a local section; inconsistency with global is a sheaf-Laplacian non-zero eigenvector |
| HDC "ℝ^d on everything" (Yoneda-HDC note, T=160) | Graded algebra on the frame bundle; all grades in ℝ^d via **binding + bundling** | The T=160 note was already this — now it has the right vocabulary |

## 7. Concurrency & federation dynamics

### 7.1 Pipeline metrics (Little, MillWheel, HLC, CRDT, cascade stability)

**Little's Law** `L = λW` (Little 1961).
- `L` = expected items in the system (queue depth + in-service)
- `λ` = long-run arrival rate = `rate_produce`
- `W` = expected sojourn time

In a watcher→reactor→watcher cascade each stage is a queueing node. `rate_produce − rate_consume > 0` means `λ_in > μ` (service rate), so by Little `L → ∞` and `W → ∞` (Pollaczek-Khinchine for M/G/1). "Re-decomposition triggered" is a control policy firing when backlog `L` crosses a threshold — split the work graph to restore `λ_eff ≤ μ`. **Backpressure** is the dual: signal upstream to lower `λ` until `L` stabilizes. Steady-state stability: `ρ = λ/μ < 1`.

**Watermarks** (Akidau et al., *MillWheel*, VLDB 2013). A watermark `W(t)` is a monotone function asserting "no event with event-time ≤ W(t) will arrive after wall-clock t." It is a **heuristic lower bound on event-time completeness**. A window `[a, b]` is **complete** once `W ≥ b`; any result before that is speculative. Late-data policy: triggers (early / on-time / late) + allowed-lateness horizon; past horizon → drop or side-output. Beam formalizes this as (What / Where / When / How). Use for twin_link SSE streams: the kernel emits watermarks so the twin knows when its view is event-time-complete.

**HLC** (Kulkarni et al., *Logical Physical Clocks*, OPODIS 2014). Bounded-drift hybrid of physical + logical clock. Preserves **happens-before** while staying close to wall-clock. O(1) size. **The right choice for twin_link.** Lamport scalars can't detect concurrent divergence; vector clocks don't scale with kernel count. HLC gives causality + wall-clock-meaningful cross-kernel debugging at constant size.

**CRDT shapes** (Shapiro et al., INRIA RR-7506, 2011). Split between **CmRDT** (op-based; commutative ops + causal broadcast) and **CvRDT** (state-based; join-semilattice + idempotent merge). For federated kernels over unreliable links, **CvRDT is safer** (merges are idempotent under replay).

| HG element | CRDT shape |
|------------|-----------|
| Nodes | **OR-Set** (add-wins, per-add unique tag) — survives concurrent add/remove |
| Relations (hyperedges) | **OR-Set of edge-tuples** with causal tombstones (2P2P-Graph as fallback) |
| Properties | **LWW-Register** (HLC-timestamped) or **MV-Register** for multi-value |

**Cascade stability** (Newman, *Networks*, 2nd ed. 2018, §17.8; Barrat-Barthélemy-Vespignani, *Dynamical Processes on Complex Networks*, 2008, ch. 9). For cascade matrix `C = T·P` (`T` = topology adjacency, `P` = per-node propagation gain), the cascade converges iff **spectral radius ρ(C) = max|λᵢ(C)| < 1** (Perron-Frobenius for non-negative C). Epidemic / percolation threshold at `1/ρ(A)`. For our WF17 reactive engine: check `ρ(C) < 1` at configuration time, refuse to attach a watcher-reactor pair that would push the cascade matrix past threshold.

### 7.2 Curvature on the kernel-quotient graph (Ollivier-Ricci, Forman, Ricci flow, Cheeger)

**Ollivier-Ricci** (Ollivier 2007; Lin-Lu-Yau 2011).
```
κ(x, y) = 1 − W₁(μ_x, μ_y) / d(x, y)
```
where `μ_x` is a probability measure at vertex `x` (typically the lazy random walk: stay with probability `α`, step uniformly to a neighbour with probability `(1−α)/deg(x)`), `W₁` is the **Wasserstein-1 / Earth Mover's distance** (infimum over couplings of transport cost), and `d` is graph distance.

- **κ > 0**: neighbourhoods overlap → short transport → information diffuses cheaply (**positively curved, "sphere-like"**).
- **κ < 0**: neighbourhoods disjoint → high W₁ → **bottleneck**; mass must squeeze through a bridge edge. **Exactly our twin_link bridges.**

**Forman-Ricci** — combinatorial alternative. `F(e) = w_e (w_u/w_e + w_v/w_e − parallel-edges corrections)`. **O(deg) per edge** vs Ollivier's O(deg³) / LP. At scale (10⁵+ kernels) Forman wins on throughput but correlates ~0.7–0.9 Spearman with Ollivier (Samal et al. 2018). Recommended: **Forman for screening, Ollivier on top-k candidates**.

**Ricci flow on graphs** (Ni, Lin, Saucan, Gao, Nature Sci Rep 2019). Iterate
```
w_e^{t+1} = w_e^t − ε · κ(e) · w_e^t
```
Negatively-curved edges stretch, positively-curved shrink. After convergence, threshold the metric — **communities emerge as positively-curved clusters, bridges as negatively-curved cuts**. Outperforms modularity on overlapping/hierarchical structure and avoids the resolution limit. Modularity optimizes a null-model statistic; Ricci flow is **geometric** and handles the fibre/bridge topology natively.

**Cheeger inequality.**
```
h(G)² / 2 ≤ λ₂(L) ≤ 2·h(G)
```
where `h(G) = min_S |∂S| / min(|S|, |S̄|)` is **graph conductance** (isoperimetric constant). Small `λ₂` ⇔ near-disconnected ⇔ bottleneck. **Jost-Liu 2014** proved `κ ≥ κ_min ⇒ λ₂ ≥ κ_min` — a **Ricci → spectral** bridge.

**Composition for federation bottleneck detection.**
1. Use Ollivier κ on twin_links to *locate* bottleneck edges (κ ≪ 0 ranks them).
2. Use `λ₂(L_branchial)` of the kernel-quotient Laplacian to *quantify* global throttle.
3. When a bridge's κ crosses a threshold, emit re-decomposition signal (the dynamic-fibre mechanism from the T=162 salvage).

**Branchial / quotient curvature.** No single canonical name. Closest terms: "quotient graph curvature", "contracted Ollivier-Ricci", or (Wolfram physics project) "branchial curvature". Recent work: Sia-Jonckheere 2023 (multi-scale Ricci coarse-graining); Fesser et al. 2024 ("Mitigating over-smoothing via Ricci flow" on quotients); Gosztolai-Arnaudon 2021 (dynamic Ollivier-Ricci on temporal / multiplex graphs — closest to our T-stepped federation). For the kernel-quotient: compute Ollivier κ on the graph where each node = kernel fibre, each edge = twin_link bundle (weight = bundle cardinality or aggregate throughput).

### 7.3 v3.10 proof obligations

- The **three-views identity** (Procrustes = Δ_F = geometric morphism) — state precisely, prove for the flat-frame case.
- **Unit/counit** of WF20 Promote ⊣ Express as ETF reconstruction bounds.
- **Sheaf Laplacian** implementation for the federation consistency check (§M9 twin_link extension).
- **Operad-of-wiring-diagrams algebra structure** on each S0 op-node type — existence + uniqueness.
- **Ricci → Sheaf Laplacian** composition (Jost-Liu-style) — prove that high-curvature regions of the kernel-quotient correspond to kernel cells with large sheaf-Laplacian non-zero eigenvalues. This would unify federation bottleneck detection (Ricci) with federation consistency detection (sheaf).
- **HLC+Watermark** combined watermark on twin_link: event-time completeness statement that uses HLC for causality + wall-clock lower bound.
- **ρ(C) < 1** as a grammar-level precondition on WF17 — configuration-time check rather than runtime depth cutoff.

## 8. Vocabulary card (read-only reference)

### Vector-space side

| Term | One-line |
|------|----------|
| embedding | injective map Symbol → ℝ^d preserving chosen structure |
| vector | element of ℝ^d |
| dimension | d, cardinality of any basis of ℝ^d |
| **frame** | spanning set with energy bounds A‖x‖² ≤ Σ|⟨x,ψᵢ⟩|² ≤ B‖x‖²; generalizes basis |
| tight frame | frame with A = B (energy-preserving) |
| **ETF** | equiangular tight frame; maximally symmetric |
| basis / orthonormal basis | k = d; linearly independent / orthogonal unit |
| atlas / chart | manifold-theoretic; use only when types live on a submanifold |
| rotation | R ∈ SO(d); det = +1; RᵀR = I |
| alignment | finding R that matches two embedding sets |
| binding | invertible pair-combining op; HRR = circular convolution; element of O(d) |
| bundling | superposition (sum + normalize); set-like aggregation |
| permutation | fixed element of O(d) encoding order/role |
| **orthogonal Procrustes** | `R* = argmin_{R∈O(d)} ‖RA − B‖_F`; closed form via SVD |
| SVD | `M = UΣVᵀ`; U,V orthogonal, Σ ≥ 0 diagonal |
| **Stiefel manifold V_k(ℝ^d)** | orthonormal k-frames in ℝ^d; moduli of size-k classification schemes |
| frame bundle | principal GL(d)- (or O(d)-) bundle of frames over a base |

### Sheaf-theoretic side

| Term | One-line |
|------|----------|
| **stalk F(v)** | data space attached to a single node |
| germ | equivalence class of sections agreeing on a neighbourhood of v |
| section | element of F(U) over an open/subcomplex U |
| **global section** | element of F(X); kernel of sheaf Laplacian |
| étale space | total space Ét(F) → X with discrete fibres = stalks |
| **sheafification** | left adjoint aF : PSh → Sh; forces the equalizer axiom |
| fibre bundle | locally trivial map E → B with fibre F |
| presheaf | functor Cᵒᵖ → Set; no gluing required |
| sheaf | presheaf satisfying the equalizer / gluing axiom |
| topos | category of sheaves Sh(C, J); has finite limits, exponentials, subobject classifier |
| **geometric morphism** | adjoint pair f* ⊣ f_* between toposes with f* left-exact; the correct "map of kernels" |
| natural transformation | component family η_X : F(X) → G(X) commuting with restrictions; the right notion of a crosswalk-respecting-schema-morphisms |
| **sheaf Laplacian L_F = δ*δ** | operator whose kernel = global sections; non-zero spectrum = local-to-global inconsistency |
| cellular sheaf | sheaf on a cell complex; the right shape for HG federation |
| **data migration functor Δ_F** (Spivak) | pullback along a schema morphism F; right/left adjoints Σ_F ⊣ Δ_F ⊣ Π_F form the full crosswalk |
| **operad of wiring diagrams** (Spivak) | operad whose algebras are network-style data-sharing systems; formal home of S0 op-nodes |

### Concurrency / federation side

| Term | One-line |
|------|----------|
| throughput | items processed per unit time (`λ` at steady state) |
| latency | per-item end-to-end time (`W` in Little's Law) |
| **Little's Law** | `L = λ·W`; in-flight items = arrival rate × sojourn |
| backpressure | upstream signal to throttle `λ` when downstream `L` rises |
| **watermark** `W(t)` | monotone lower bound on event-time completeness (MillWheel) |
| late data | events with event-time ≤ `W(t)` arriving after wall-clock `t` |
| Lamport timestamp | scalar logical clock; preserves happens-before, not concurrency |
| vector clock | per-process vector; detects concurrency exactly; O(n) |
| **HLC** (Kulkarni 2014) | hybrid logical clock; O(1), bounded skew to wall-clock; right choice for twin_link |
| causal order | partial order induced by happens-before (→) |
| **CRDT** | conflict-free replicated data type; strong eventual consistency |
| **CmRDT** | op-based; commutative ops + causal delivery |
| **CvRDT** | state-based; join-semilattice + idempotent LUB merge |
| **OR-Set** | add-wins CRDT with per-add unique tags; right shape for HG nodes/edges |
| **LWW-Register** | last-write-wins via HLC timestamp; right shape for properties |
| **spectral radius** | `ρ(M) = max|λᵢ(M)|`; stability threshold for cascade |
| cascade matrix | `C = T · P`; topology × per-node gain |
| convergence | `limₙ Cⁿ x = 0` iff `ρ(C) < 1` |

### Curvature side

| Term | One-line |
|------|----------|
| **Ollivier-Ricci κ** | `κ(x,y) = 1 − W₁(μ_x, μ_y) / d(x, y)`; transport-based edge curvature |
| Forman-Ricci | combinatorial curvature; O(deg) cheap proxy for Ollivier |
| **Wasserstein-1** | optimal-transport distance; min expected cost coupling two measures |
| **Ricci flow** | iterate `w_e ← w_e · (1 − ε·κ)`; shrinks positive, stretches negative |
| **Cheeger inequality** | `h²/2 ≤ λ₂(L) ≤ 2h`; links conductance to spectral gap |
| spectral gap | `λ₂(L)`; second eigenvalue of graph Laplacian; small = bottleneck |
| **graph conductance** `h(G)` | `min_S |∂S|/min(vol S, vol S̄)`; bottleneck ratio |
| isoperimetric constant | synonym for `h(G)` (vertex or edge variant) |
| modularity | `Q = Σ(e_ii − aᵢ²)`; null-model community score; has resolution limit |
| **branchial graph** | (Wolfram) quotient graph where each node is an equivalence class / fibre |
| quotient graph `G/∼` | fibres contracted; edges = bridge bundles between classes |

## 9. One-line summary

> IRL → embedding (ℝ^d, HDC) → classification (tight frame) → typed node (S1) → wired node (S2) → federated section (sheaf on kernel-quotient graph). Crosswalks are Procrustes rotations = data migration functors = geometric morphisms. S0 op-nodes are algebras over the operad of wiring diagrams. Sheaf Laplacian detects federation inconsistency mechanically.
