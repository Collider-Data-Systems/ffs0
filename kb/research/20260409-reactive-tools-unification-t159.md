# Reactive Tools Unification — Watch+React IS the Tool Layer

Date: 2026-04-09 | T=159
Related: `20260408-foundation-t158.md` §11, `20260408-reactive-topology-t158.md`, `20260409-value-attribution-t159.md`
Status: Conceptual agreement. Not yet implemented beyond depth-1 Watch/React/Guard.
Origin: Sam braindump during Zappa Live in Rotterdam 1980 session.

---

## 1. The Core Claim

**Watch+React is the only execution mechanism. There is no other "tool layer."**

When anything in the graph needs to DO something — where to act, how to act, how much — it manifests as a MUTATE on an existing node. That MUTATE fires a watcher. The reactor emits the next rewrite. The chain IS the program.

```
"do something" = MUTATE property on existing node
                       ↓
              watcher matches the MUTATE
                       ↓
              guard checks preconditions
                       ↓
              reactor emits next rewrite(s)
                       ↓
              ... chain continues until no watchers fire
```

There is no function call. There is no RPC. There is no side-channel. An AI agent "using a tool" = the agent emitting a MUTATE that a watcher picks up. The watcher+reactor pair IS the tool.

---

## 2. The Self-Similar Pattern

Categories, classification schemes, and watchers are the same pattern at different scales:

| Level | Pattern | Matches | Produces |
|-------|---------|---------|----------|
| WF category | Rewrite category | (src_type, tgt_type, rewrite_type) | Valid rewrite |
| Classification scheme | Taxonomy node | (domain, convention, standard) | Classification LINK |
| Watcher | Reactive rule | (rewrite_type, type_id, property condition) | Reactor emission |
| Bayesian weighting | Stochastic functor | (prior, evidence) | Posterior weight |

Every level is: **match a condition → emit a consequence**. The operad is self-similar. The WF categories are macro-watchers. The classification schemes are domain-watchers. The WF17 watchers are micro-watchers. Same structure, different granularity.

---

## 3. Reverse Engineer the Operad from Existing Categories

**Do not design ports and morphisms top-down.**

Real-world classification systems (LCC, IFRS, npm, arXiv, ISO, RFC) already define:
- What entities exist (→ node types)
- What relationships are valid (→ port compatibility)
- What transitions are meaningful (→ rewrite categories)
- What hierarchies structure the domain (→ parent-child tree in property layer)

The operad should be DERIVED from these conventions, not invented. The manifold hypothesis (presheaf doc §11) says: useful knowledge graphs lie on a low-dimensional manifold. The conventions ARE the manifold's coordinate system.

```
Existing formal category (e.g., IFRS)
    → extract entity types (assets, liabilities, equity, revenue, expenses)
    → extract valid relationships (owns, consolidates, denominates-in)
    → extract transitions (recognize, derecognize, impair, revalue)
    → map to operad: node types, port pairs, rewrite categories
```

This IS the classification functor C: Class → Know, run in reverse:

```
C⁻¹: Know → Class    (derive the classification from the knowledge structure)
```

When C and C⁻¹ compose to identity (up to natural isomorphism), the operad is aligned.

---

## 4. Time Is a Property, Not an Axis

Time does not privilege nodes. Time is a matchable property like any other:

```
WATCH match_type_id = "program"
      filter: { "target_t": 162, "status": "draft" }
```

This watcher fires when a program node with target_t=162 gets MUTATEd. Time doesn't create a separate dimension — it creates a filterable condition. This IS multiway: at any "moment" (projection at t), the graph state is fold(log[0..t]).

"At the moment what is" = G(t) = { n ∈ Nodes(G) : relevant_at(n, t) }.

The temporal presheaf (presheaf doc §12) formalizes this: a presheaf over (T, ≤) with restriction maps that forget later nodes. But from the watcher's perspective, t is just another property to match.

**Implication**: Every watcher that filters on time is a temporal watcher. Every watcher that filters on status is a state watcher. Every watcher that filters on type_id is a type watcher. They compose — a single watcher can filter on all three. No special temporal machinery needed.

---

## 5. Tree Structure in the Property Layer — Triple Symmetry

Three views of the same graph reality:

### Axis 1: Topology (graph state)
All hyperedges incident to a node. The LINK structure. Relations are truth.

### Axis 2: Tree (property layer)
Parent-child structure encoded in provenance stamps: `owner_urn`, `source_ki_urn`, `parent_urn`. Not topology (these are immutable birth certificates), but they form a tree that mirrors the topological DAG. The tree is the projection of topology onto single-parent inheritance.

### Axis 3: HDC Encoding (manifold coordinates)
```
phi(n) = bundling{ binding(src_port, tgt_port, phi(neighbor)) : for all relations of n }
```
The hypervector IS the manifold coordinate of the node. It encodes both topology (axis 1) and tree position (axis 2). Similarity in hypervector space = structural similarity in graph space.

**Triple symmetry**: any fact about the graph can be read from any of the three axes. They are three coordinate systems on the same manifold. The Yoneda lemma guarantees this: a node is fully determined by its morphisms (relations), which are fully encoded in the hypervector, which reflect the tree position.

---

## 6. Programming Languages as Ontology Subset

A programming language defines:
- Types (→ node types, or classification_scheme entries)
- Functions (→ rewrite patterns)
- Modules (→ tree structure in property layer)
- Dependencies (→ LINK topology)

This is a SUBSET of what the ontology can express. The ontology is the superset:

```
Natural language ⊂ Ontology
Programming language ⊂ Ontology
Formal classification (LCC, IFRS) ⊂ Ontology
```

The ontology expands in three directions:
- **Upward**: more abstract (natural language, intent, generation)
- **Inward**: latent space (HDC encoding, similarity manifold)
- **Outward**: more specific (domain conventions, industry standards)

ONE superset. THREE axes of the central triangle. Multiway means any node is reachable from any axis.

---

## 7. Git Is Just a Node

`repository` and `git_issue` are already node types (ontology v3.3). Branches, commits, PRs — these are graph topology. Version control is not a special system sitting outside mo:os; it is nodes and relations INSIDE mo:os.

The "flow" of development is a chain of rewrites: ADD git_issue → LINK to program (WF18) → agent session produces code → MUTATE git_issue.status = "closed". The reactive chain handles the transitions.

---

## 8. No New Nodes for Tools — Use Existing Nodes

**Critical**: A tool is not a new node type. A tool is a watcher+reactor pair that watches EXISTING nodes.

The watcher asks: "Did a property on an existing node change in a way that means I should act?"

The issue is semantic pre-wiring: watchers must know WHAT to look for BEFORE the MUTATE happens. This is the Bayesian connection — the watcher's filter is a prior. The MUTATE is evidence. The reactor's emission is the posterior action.

```
Prior:    watcher filter = "I expect knowledge_items with status=raw to appear"
Evidence: MUTATE knowledge_item.status = "raw"
Posterior: reactor emits MUTATE status = "claim-pending" (the action)
```

The classification functor weights the priors: if the classification scheme says this domain produces many raw KIs, the watcher's confidence is high. If the domain is sparse, confidence is low. Bayesian watchers.

---

## 9. Free Category Superset + Versioning Twin Kernel

The ontology is the **free category** over node types and rewrite categories. Adding a new node type or WF = extending the free category by one generator.

**Versioning via twin kernel**: To validate ontology v(N+1):
1. Spawn a twin kernel with ontology v(N+1)
2. Replay the existing log against the new ontology
3. If fold converges (no validation failures), the new ontology is backward-compatible
4. If fold diverges, the new ontology breaks existing data — fix or add migration rewrites
5. Promote via WF13 governance

The twin kernel IS the proof environment. No separate test harness needed — the kernel itself is the validator, because state = fold(log) and fold is deterministic (CI-4).

This connects to the multi-kernel spawn script (New-MoosKernel.ps1): spawn a twin, replay, validate, promote or discard.

---

## 10. Summary: One Mechanism, Three Axes, Self-Similar

```
Execution = Watch + React (the ONLY mechanism)
Structure = Topology × Tree × HDC (triple symmetry)
Knowledge = Free category superset (expands upward, inward, outward)
Time      = Property, not axis (multiway: filterable like any other)
Tools     = Watcher+Reactor pairs on EXISTING nodes
Value     = Causal attribution through provenance topology
```

The operad is seeded by reverse-engineering real-world classification systems. But the manifold extends far beyond existing conventions — there is room at the bottom (Feynman) and between: sentences, stories, skills, purpose, and n-ary semantic junctions. Conventions are level-2 landmarks; the manifold has recursive depth. Crosswalks connect to crosswalks (maps between maps, n-category structure). HDC binding is closed — every level encodes at the same dimensionality. The Bayesian extension weights matches by prior confidence.

Everything is the same pattern at different scales. The graph is self-similar.
