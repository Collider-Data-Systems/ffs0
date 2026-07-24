# DECISION — mo:os HG as an AlgebraicJulia ACSet (T=260)

Semantic-oracle spike. Reference model, **not** a kernel replacement. Verified against the
installed depot: **Catlab 0.17.6 · ACSets 0.2.29 · AlgebraicRewriting 0.5.0 · GATlab 0.2.4**
(static-source-verified; no REPL run in-subagent — a 30s `using` smoke-test is the final gate).

## 1. Dependency decision

**Depend on `Catlab + AlgebraicRewriting` (+ `JSON3`, + `Downloads` stdlib). ACSets is transitive.**

```julia
using Catlab                 # @reexports the ENTIRE ACSets API + Δ/Σ data-migration
using AlgebraicRewriting     # Rule, rewrite, rewrite_match, create, id[cat] — NOT in Catlab
using JSON3                  # load the /fold snapshot
using Downloads              # stdlib — fetch the live snapshot
```

Rationale: `using Catlab` transitively `@reexport`s the whole ACSets public surface
(`@present`/`@acset_type`/`@acset`/`AttrVar`/part-ops) **and** the functorial data-migration
API (`DeltaMigration`/`SigmaMigration`/`migrate`), so a separate `using ACSets` is redundant.
But **Catlab alone is insufficient** — `Rule`/`rewrite`/`rewrite_match` and the DPO/SPO/SqPO/PBPO
strategies live only in AlgebraicRewriting, which does **not** re-export Catlab. Hence both, and only
both. Do **not** add `DataMigrations.jl` (v0.1.2 pins Catlab 0.16.12 / GATlab 0.0.7–0.1 → a
destructive downgrade that breaks the ACSet + AlgebraicRewriting 0.5 core) or `GATlab` (transitive).

`Project.toml` UUIDs: Catlab `134e5e36-…`, AlgebraicRewriting `725a01d3-…`, JSON3 `0f8b85d8-…`;
ACSets `227ef7b5-…` may stay listed for explicitness (harmless, same bindings). Pin at 0.17.6 / 0.5.0 / 0.2.29.

## 2. Schema rationale (faithful-but-minimal C-set = the FOLD SHAPE)

3 objects `Node/Relation/Property`; `src,tgt: Relation→Node` (Catlab's `SchGraph` — a directed
multigraph); `owner: Property→Node`; everything else attributes. Why faithful:

- **Binary relations** — the fold emits every relation as one `src_urn/src_port → tgt_urn/tgt_port`
  pair; no n-ary hyperedge is realized, so binary `src,tgt` is exact (no incidence object needed).
- **`node_type` as an attribute on a single sort**, not a 56-way multi-sorted schema — mirrors the
  kernel (single-sorted typed-node store + separate validating operad; CI-5 "enforced at rewrite
  validation time"), and avoids regenerating the schema every ontology bump.
- **Ports as `rel_src_port`/`rel_tgt_port` attributes** — ports are type-level operad constructs
  (declared per node-type, coloured, gated by a matrix); first-class `Port` parts (SchCPortGraph)
  would over-model (let two instances of one type carry different ports, which the operad forbids).
- **`Property` as its own EAV part**, not Catlab's `SchPropertyGraph` free-form dict-bag — doctrine
  forbids free-form payloads. URN-valued provenance stamps (`owner_urn`/`sender_urn`) stay attributes,
  never Homs (`topology_property_boundary.exception`).

**Discipline:** the C-set is the fold **shape**; the operad (56 type-ids, per-type port sets, the
8-colour port-compatibility **matrix**, per-WF src/tgt types) is an admissibility **predicate** over
instances — a plain C-set cannot encode the colour matrix, so do not fold the operad into the schema.

**One hard bugfix vs the strawman:** `@acset_type MoosHG(…) <: ACSet` is an arity error (`ACSet{PT}`
takes 1 param; `@acset_type` codegen applies the parent with 3). Fix: `@abstract_acset_type
AbstractMoosHG` then `@acset_type MoosHG(SchMoosHG, index=[:src,:tgt,:owner],
unique_index=[:node_urn]) <: AbstractMoosHG`. `unique_index=[:node_urn]` makes urn→part O(1).

## 3. The four-rewrite encoding

A `Rule(l, r)` is a **span** `L ⟵l— K —r⟶ R`: both legs point **out of the interface K**
(`l: K→L`, `r: K→R`), **not** `L→R`. Default semantics = **DPO**; its gluing/dangling condition
**is** the kernel's referential-integrity guard (keep it — do **not** use SPO, which silently
auto-deletes dangling parts). The installed 0.17/0.5 stack is **model-dispatched**: build one
category object and thread `cat=` everywhere. Use `VarACSetCat` throughout (handles both
topology-only rules and attribute rebinds).

```julia
𝒱 = ACSetCategory(VarACSetCat(MoosHG()))
```

| Rewrite | Span `L ⟵ K ⟶ R` | Encoding | Δ | Status |
|---|---|---|---|---|
| **ADD** | `∅ ⟵ ∅ ⟶ {node}` | `Rule(id[𝒱](∅), create[𝒱](R); cat=𝒱)` | +1 Node | [PROVEN-BY-API] |
| **LINK** | `{n1,n2} ⟵ {n1,n2} ⟶ {n1,n2,rel}` | `Rule(id[𝒱](K), homomorphism(K,R;cat=𝒱); cat=𝒱)` | +1 Relation | [PROVEN-BY-API] |
| **UNLINK** | `{n1,n2,rel} ⟵ {n1,n2} ⟶ {n1,n2}` | `Rule(homomorphism(K,L;cat=𝒱), id[𝒱](K); cat=𝒱)` | −1 Relation | [PROVEN-BY-API] |
| **MUTATE** | `{node,prop@AttrVar} ⟵ {node} ⟶ {node,prop@AttrVar}` | `Rule(l, r; cat=𝒱, expr=Dict(:PVal=>[f]))` | ±0 parts, 1 value | [PROVEN-BY-API]* |

**MUTATE (the crux).** Plain concrete-attribute DPO cannot rebind a value in place (a morphism maps
`v` only to `v`). Fix = **variable attributes**: `AttrVar(1)` in `prop_val` of `L` matches any current
value; `R` re-adds the Property with `AttrVar(1)` bound by `expr=Dict(:PVal=>[old->…])`. This is the
test-backed path (AlgebraicRewriting weighted-graph rebind test + `full_demo.jl §7`). \*The encoding
deletes+re-adds the Property **row** — since a fold-shape Property has no independent URN (keyed by
`owner+key`), that is observationally identical to the kernel's single one-field MUTATE log entry.
Use `PVal=Bool` (not `Any`) for the demo instance so AttrVar hom-search value-matching stays clean.

## 4. Migration verdict (honest ledger)

| t260 construction | Grounded TODAY? | API |
|---|---|---|
| `view_filter = Δ_F` (projection/reindex/rename) | **PROVEN-BY-API** | `migrate(TgtType, X, DeltaMigration(F))` — pure precomposition `X∘F`; a real functor (acts on morphisms too). |
| `push = Lan_f = Σ_F` | **PROVEN-BY-API** | `SigmaMigrationFunctor(F, dom, codom)(X)`; Σ_F is the left adjoint to Δ_F (= pointwise left Kan extension); `return_unit=true` gives the adjunction unit η. |
| `frame = L_p(fold(log))` | **PARTIAL** | fold→C-set is proven; the purpose-placement `L_p` is a Δ/Σ migration along a placement functor — real API, but the specific placement functor is authored, not library-given. |
| `view_filter` with predicate-selection / joins | **NOT on this stack** | needs the conjunctive `@migration` DSL → DataMigrations.jl, which will not co-install with Catlab 0.17.6. Δ covers projection only. |
| `branch = cartesian lift of a fibration` | **CONJECTURE** | no Catlab `fibration`/`cartesian_lift` API. Hand-roll from `elements` (category of elements / Grothendieck construction) + `pullback`. |

Caveat on push: Σ-migration is **chase-based / semi-decidable** — `SigmaMigrationFunctor(…)(X; n=100)`
errors if the chase doesn't converge in `n` steps, and the implementation carries in-source
"should be replaced / not optimized" flags. Treat `push=Lan_f` as *supported but may not terminate /
needs a bound*, not *always computable*. Σ also needs DenseACSets (representables).

## 5. Open conjectures (marked, per AGENTS.md doctrine)

1. **[CONJECTURE]** Preserving the Property **part** (not delete+re-add) while rebinding its value
   under the pure `rewrite_match` (var-in-K ↦ concrete-in-R) — classically awkward; no direct passing
   test found. Proven alternatives: (a) delete+re-add via `expr` (used here); (b) in-place `rewrite!`
   + concrete value in R (`SetAttr`/`Const`, both legs monic).
2. **[CONJECTURE]** `branch = cartesian lift of a fibration` — no named API; must be assembled from
   `elements` + `pullback`, and `elements` only handles the CSet (non-attribute) part cleanly.
3. ~~**[CONJECTURE]** `frame`'s purpose-placement functor `L_p` — expressible as a Δ/Σ migration in
   principle; the exact functor is not yet authored/verified.~~
   **RESOLVED-NEGATIVE (T=266, spike §5, executed).** `L_p` is **not** a schema-level Δ/Σ migration, and
   this is now proven by enumeration rather than argued: `SchMoosHG` has exactly three homs — `src`,
   `tgt`: Relation→Node and `owner`: Property→Node — and **no Node→Node hom**, so `P`'s generating
   morphism (window ≤ desktop) has no image under any functor sending rooms and windows to `Node`.
   In the fold schema a relation between two nodes is an **object** (a Relation part with src/tgt),
   never a hom, and a functor cannot send a hom to an object. The claim above and the instance-level
   `L_p` authored at T=265 (`dev/design/manifold-bump-4_0/20260725-t265-lp-placement-functor.md` §0)
   are about **different constructions**; the note's schema-vs-instance ruling is confirmed.
   **Constructive half PASSES:** placement needs no new schema and no migration — rooms are Nodes and
   containment is a Relation, so the fold schema holds the 14 rooms + 24 windows verbatim
   (Node=38 Relation=24 Property=52). Measured on the live fold, `L_p` lands 7 of 14 rooms on a fold
   node, **0 of 24 windows have any image**, and the fold carries **0** relations with port `realizes`.
   Both gaps are minted objects, not mathematics — which is independently the note's §7 ruling
   ("reify the objects, defer the relation").
4. **[CONJECTURE / semi-decidable]** `push=Lan_f` termination — real API, but chase may not converge;
   needs an `n` bound and DenseACSets.
5. ~~**Runtime confirmation pending** — all API is static-source-verified against the pinned depot, not
   executed.~~ **RESOLVED — this item was stale.** The spike ran live at **T=260** (recorded in
   `kb/superset/running-state.md`: log 607, Node 286 / Relation 201 / Property 1880, all four Δs
   correct) and again at **T=266 (2026-07-25)** against a grown fold and a bumped ontology:
   **ontology 4.0.4 · log 643/643 · Node=294 Relation=223 Property=1941 · ADD Δ=+1 · LINK Δ=+1 ·
   UNLINK Δ=−1 · MUTATE ΔProperty=0 with the value rebound true→false.** The model-dispatched `cat=`
   calls and the MUTATE `expr` path both execute. Two tracked artifacts had disagreed about this gate
   since T=260; that drift is what this edit closes.
   **Anti-fixture discipline (keep it):** `fetch_fold` falls back to a 2-node inline fixture when
   `:8000` is unreachable, and the four asserts then pass against fake data. A run counts only if the
   printed `nodes=`/`relations=`/`log_len=` equal a `/fold` read captured in the same session and no
   `unreachable` warning appears. The four PASS lines alone prove nothing.

---
authored-by: agent:claude-cowork.hp-z440 / session:sam.z440-cowork-workspace / t260-acset-oracle-spike
