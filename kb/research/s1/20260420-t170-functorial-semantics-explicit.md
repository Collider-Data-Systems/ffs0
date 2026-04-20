# T=170 — Functorial semantics, explicit

> Naming the coat. FS is already the spine of mo:os; the spine has just been wearing ontology clothes.
> Author: claude-code on hp-laptop (T=170 ~20:00 CEST).
> Companion to: `20260418-t168-s1-superset-doctrine.md` (WF20 Promote ⊣ Express), `20260418-t168-irl-to-hg-pipeline.md` (three-views identity).

---

## 0. Motivation

T=170 gdoc, sam:

> I havent found a use of FS specifically yet, nor in its importance at the operadic level as a pure math projection to the semantic category.

This is wrong-on-inspection. FS is already **three load-bearing pieces** of mo:os doctrine; what's been missing is the label. This note supplies the label and the three identifications, then turns the lens on federation — which we'll argue is FS in production.

## 1. What FS is (one paragraph, Lawvere)

Functorial semantics (Lawvere 1963): **interpreting syntax = functor from a syntax category to a semantic category.** A theory `T` is a category (objects = sorts, morphisms = operations, equations = commuting diagrams). A model of `T` in `Set` is a functor `M: T → Set`. Models of `T` in some other category `C` are functors `M: T → C`. Models form a category themselves (natural transformations between functors). The classifying topos of `T` is the universal semantic target; any `Set`-valued model factors through it.

In one sentence: **the thing that turns a formal grammar into something you can actually evaluate** is a functor, and the choice of target category is the choice of what "evaluation" means.

## 2. Where FS already lives in mo:os

### 2.1 Fold : `log` → `GraphState`

The fold (`internal/fold/evaluate.go`) IS a functor.

- **Syntax category**: the free category on envelopes `{ADD, LINK, MUTATE, UNLINK}`. Objects = positions in the log; morphisms = envelope sequences. Composition = concatenation. Identity = empty segment.
- **Semantic category**: `GraphState` — a `Set^{URN-index}` shape with typed-property cells and relation hyperedges, equipped with the secondary indexes (`NodesByType`, `RelationsBySrc`, `RelationsByTgt`) as structure-preserving projections.
- **Functor**: `Fold: LogCat → GraphStateCat`. Preserves identity (empty segment → empty state), preserves composition (`fold(l₁ ∘ l₂) = apply(fold(l₁), l₂)`).
- **FS identity**: "state at T is the image of log[0..T] under Fold" is the literal content of functorial semantics — the log is the theory, state is the model, Fold is the interpretation.

### 2.2 WF20 Promote ⊣ Express

The v3.9 audit and the s1-superset doctrine described this as the **S4 → S1 adjoint**:

- **Promote**: `S4 (system_instruction) → S1 (grammar_fragment)`. Takes an overlay (what an agent recurrently cites) and proposes an ontology extension (what the next ontology baseline admits).
- **Express**: `S1 → S4`. Takes an ontology primitive and writes the canonical system_instruction that would have proposed it. Not yet shipped in code.

This is a **geometric morphism** `f: 𝓔_{S4} → 𝓔_{S1}` between classifying toposes (Spivak 2012). The unit `η: Id → Express ∘ Promote` says: every S4 overlay you promote should be recoverable by applying Express to its S1 image. The counit `ε: Promote ∘ Express → Id` says: every S1 primitive expressible as an overlay, once promoted back, is (up to isomorphism) itself. The adjoint laws are ASSERTED in v3.9; not yet mechanically checked.

**The unshipped half (Express) is where S4 feedback closes the loop.** Until Express runs, the strata cycle is S4 → S1 → S2 → observation → human → S4 (manual). Once it runs, the last edge becomes automatic: observed patterns at S2 express themselves as candidate overlays at S4.

### 2.3 Three-views identity (v310-2 crosswalk)

From `20260418-t168-irl-to-hg-pipeline.md` §4: the same crosswalk object has three presentations, all equivalent up to natural iso:

1. **Orthogonal rotation** aligning two HDC frames: `R* = UVᵀ` (Procrustes, Schönemann 1966).
2. **Pullback functor between schema categories**: `Δ_F: [C₁, Set] → [C₀, Set]` (Spivak data migration).
3. **Inverse-image part of a geometric morphism** between classifying toposes: `f*: 𝓔₁ → 𝓔₀`.

The grammar_fragment `v310-2-crosswalk` carries this as a candidate S1 type with properties `rotation_artifact_urn`, `procrustes_error`, `direction: {pullback_delta, leftkan_sigma, rightkan_pi}`. **Three presentations, one functor.** CI-6 (still unproved) is the coherence statement that all three agree.

## 3. Consequences of calling it FS

Three things become cheaper once the label is explicit:

1. **No re-inventing Express.** The math of geometric-morphism inverse-image is 60 years old. We don't design Express; we implement the left adjoint of Promote.
2. **S0 vocab (op-node, slot, yield, threading, weave) becomes placeable.** Operads are themselves a kind of Lawvere theory — the multi-input generalization. S0 sits above S1 as the meta-theory whose models are S1 theories. Same math, different stratum.
3. **Federation gets a known shape.** (See §4.)

What stays hard:

- Checking adjoint laws mechanically (Promote ∘ Express vs Id up to which natural iso?).
- Proving CI-6 (three-views coherence) — Procrustes error bound vs Δ_F composition vs geometric-morphism naturality square.
- Wiring HDC similarity into the picture so "similar patterns" in HDC space induce the right natural transformations.

## 4. Applied — federation as a sheaf over the category of kernels

Sam's T=170 ramble surfaced a cluster of connected concerns: kernel type advertisement, "free set" for federation, inheritance from a primordial kernel, network topology as a map, presheaves, DNS/routing, the Wolfram multiway angle. They resolve cleanly once FS is in hand.

### 4.1 Kernel as a site

Each running kernel — hp-laptop.primary, hp-z440.primary, hp-z440.lola, etc. — is a **site** in a Grothendieck-topology sense. It holds:

- a local log (the sequence of rewrites it has witnessed)
- a local state (the fold over that log)
- an operadic signature (which WFs + types it speaks — determined by its loaded ontology version)

The **category of kernels** `𝓚` has kernels as objects and *ontology-version morphisms* + *parent-child lineage edges* as arrows. Morphisms:

- `kernel_A → kernel_B` if A's ontology ⊆ B's (B can speak everything A can; inclusion = refinement).
- `kernel_A → kernel_B` if A spawned B (lineage; WF19-analogue at the kernel stratum). The "first kernel" is the initial object of the lineage subcategory.

### 4.2 Kernel operadic signature (the "node type carried by kernels")

Each kernel exposes, at runtime, a signature:

```
Sig(K) = (ontology_version, type_set, wf_set, port_color_matrix, capability_set)
```

This is just **what's in `/operad/node-types` and `/operad/rewrite-categories` as observable endpoints.** Today implicit; formalize as `kernel_operadic_signature` S1 type in v3.13 (candidate fragment below).

Sam's phrase *"information on the combined node types in order to define new free sets for federation"* means exactly: given multiple kernels with signatures Sig(K₁), Sig(K₂), ..., what's the **free operadic theory** they jointly present? In category-theory terms:

- **Colimit** `⊔_i Sig(K_i)` — the largest operad such that each `Sig(K_i)` embeds. Every federated rewrite must live in this colimit.
- **Limit** `∩_i Sig(K_i)` — the largest operad every kernel understands. Every federation-wide broadcast must live here.
- **Free extension** — when you add a new kernel whose signature has types none of the others do, the colimit grows; when you remove one, it (may) shrink.

Federation planning is **signature-colimit planning**. Today it's ad-hoc (same ontology.json checked into ffs0 means all kernels happen to share a signature). When kernels carry different signatures (a realistic future), the colimit becomes a live object to query.

### 4.3 Kernel lineage — has-parent-kernel

Today: running-state says kernel hp-laptop.primary has `created_at=2026-04-03T01:05:11Z` and hp-z440.primary has `created_at=2026-04-05T08:45:00Z`. Implied: hp-laptop was the first; z440 came later. But the *spawn* relationship isn't recorded as a LINK.

Candidate fragment for v3.13: a WF19-extension port pair `spawned-by / spawned` on `kernel`. Each kernel but the initial one has exactly one `spawned-by` edge; kernels form a tree (or DAG if we allow kernel-merges). Sam's *"inheritance lineage straight to first kernel"* is traversable via this edge.

The initial object of that tree IS the "first kernel" — a distinguished terminal of the lineage subcategory. Fold from there gives you the complete operadic genealogy of any kernel.

### 4.4 Presheaves, sheaves, routing, DNS

A **presheaf** `F: 𝓚ᵒᵖ → Set` assigns to each kernel a set (typically: its URN namespace, its state projection, or the view a given agent gets from that kernel), and to each morphism `K → K'` a restriction map `F(K') → F(K)` (the opposite-direction arrow — big kernel's data restricted to small kernel).

A **sheaf** is a presheaf plus a gluing condition: local agreement between overlapping sites implies a unique global section. Required for the federation to be coherent.

Concrete map:

| Sam's term | FS term |
|---|---|
| network topology map | the category `𝓚` itself |
| routing | finding the stalk `F_K` for a URN's authoritative kernel K |
| DNS | the presheaf `URN → Set of (kernel, local state)` — lookup table realized as presheaf evaluation |
| "information boundary" | the site boundary — beyond which the presheaf is silent (no kernel speaks that URN) |
| "combined node types" / free set | the colimit of `type_set`'s along `𝓚`'s arrows |
| inheritance lineage | the spawned-by subcategory |

**Sheaf condition** in federation: whenever two kernels both speak a URN, their local states for that URN agree under some coherence check (HLC ordering, property-value equality under CI-2, etc.). When they disagree → sheaf condition violated → inconsistency → governance_proposal to reconcile.

### 4.5 Wolfram multiway — the connection

Wolfram's physics project (2020–) studies **multiway graphs**: given a rewrite rule and an initial hypergraph, the multiway graph has as nodes all reachable states and as arrows all rewrite events. The **causal graph** is the DAG of event-dependencies within one branch. The **entanglement cone** is the set of branches that share a common causal past.

Mo:os under federation is a multiway system:

- Each kernel's local log is a **single branch** of the multiway graph.
- Cross-kernel rewrites not yet propagated are **independent branches**.
- The `twin_link` (local kernel duplication for code-refresh) is a **branch-fork** within one host.
- Sheaf-condition checking across branches is **Wolfram's "causal invariance"** — when does path-independence hold?

Mo:os distinguishes itself from naive Wolfram by:

- **Log-is-truth per kernel** (sovereignty §M9) — branches aren't collapsed by default.
- **HLC + governance** — reconciliation is explicit, not automatic.
- **Typed operad** — our rewrite rules are a typed Lawvere theory, not untyped hypergraph string-rewrites.

**The classifying topos over 𝓚** is, approximately, the coherence layer Wolfram gestures at without naming. Each kernel is a site; sheaves on 𝓚 are the coherent global states; geometric morphisms between classifying toposes are the meaningful cross-kernel maps.

### 4.6 The "information boundary something dinges"

Sam reached for *"an information boundary something dinges"*. Candidate crispings:

1. **Site boundary** — the edge of what a kernel can see. Beyond it, the local presheaf returns empty.
2. **Causal horizon** — à la Wolfram: the set of events that could have influenced the current kernel via some path through the multiway graph.
3. **Coverage boundary** — where the Grothendieck topology's covers stop: the maximal refinement of site-covers before coherence checking stops being tractable.
4. **Sheafification boundary** — the point beyond which a presheaf cannot be sheafified without loss (the presheaf is no longer separated).

I'd lean **site boundary** as the plain-language winner. "Boundary of what the kernel sees, at this moment, under its current ontology version." Everything else (routing, DNS, lineage, federation colimit) is about crossing that boundary.

## 5. v3.13-candidate grammar_fragments

This note argues for four fragments to add at `status=proposed` in the HG:

| URN suffix | Kind | Crystallises |
|---|---|---|
| `v313-1-functorial-semantics-spine` | doctrine | §1–§3 above: FS is already live in three places; name it so we don't re-invent the math of its unshipped halves (Express, CI-6) |
| `v313-2-kernel-operadic-signature` | type (S1) | §4.2: `kernel_operadic_signature` as an S1 type; properties `ontology_version, type_count, wf_count, signature_hash, computed_at`. Observable via `/operad/*` endpoints. |
| `v313-3-kernel-lineage` | port | §4.3: WF19 port pair `spawned-by / spawned` on `kernel`. Initial-kernel is a distinguished root. |
| `v313-4-federation-presheaf` | doctrine | §4.1–§4.4: federation as Grothendieck-topology on 𝓚, routing as stalk-lookup, sheaf-condition as coherence gate. Required before any multi-kernel divergence reconciliation can be implemented. |

A fifth candidate belongs with the diary + S0 work (separate notes):

- `v313-5-diary` — `diary` S2 type (see `kb/moos-diary/README.md`)

A sixth candidate goes with the S0 materialization note:

- `v313-6-op-node` (and companions for slot/yield/threading/weave) — see `20260420-t170-s0-materialization.md`.

## 6. What I'm NOT claiming

- **I'm not promoting anything**. This note argues for propose-status fragments. WF20 ceremony is a separate round.
- **No new code**. Express is not shipped here. CI-6 is not proved here. `kernel_operadic_signature` isn't wired into the kernel's `/operad/*` output as a structured object yet.
- **No federation action**. No `/twin/ingest`, no router reconfiguration. Doctrine first, wiring later.

## 7. Cross-references

- `kb/research/s1/20260418-t168-s1-superset-doctrine.md` — the original Promote ⊣ Express sketch.
- `kb/research/s1/20260418-t168-irl-to-hg-pipeline.md` §4, §7 — three-views identity + CI-6 obligation.
- `kb/research/s1/20260418-t168-v3.9-ontology-audit.md` §F — WF20 doctrine.
- `kb/research/s1/20260418-t168-s0-operadic-layer.md` — S0 vocab (op-node, slot, yield, threading, weave).
- `kb/research/kernel/20260417-t187-kernel-proper.md` §M9 — kernel sovereignty.
- `kb/research/session/20260419-t169-session-generalization.md` §2 — three-algebras CT correction (applies here too — the federation story has all three: transition-monoids per kernel, operadic scope colimits, topology lattices).
- Spivak 2012 "Functorial data migration"; Lawvere 1963 "Functorial semantics of algebraic theories"; Wolfram 2020 "A Class of Models with the Potential to Represent Fundamental Physics".

## 8. Open questions (carried forward)

1. **Express implementation**: what's the pattern-mining algorithm that takes S2 repetition and emits an S4 overlay candidate? HDC + clustering likely; unwritten.
2. **CI-6 mechanization**: can we check Procrustes/Δ_F/f* coherence by construction rather than by numerical sampling?
3. **Signature-colimit hashing**: for a federation of K kernels, can `hash(Sig(K₁) ⊔ ... ⊔ Sig(K_k))` be computed incrementally as kernels join/leave?
4. **HLC vs Wolfram causal time**: are they the same object at different granularity? Probably yes (HLC is event-time; causal graph is event-dependency); confirm.
5. **Sheaf-condition failure as governance input**: when two kernels disagree on a URN's state, is the right response always a human-approved reconciliation via WF13 governance_proposal? Or are there automatic coherence laws (CI-2 preservation) that can resolve some classes?

— end —
