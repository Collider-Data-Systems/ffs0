# Poly foundations — the polynomial layer that unifies mo:os ⊣ so:om

> **Status: design draft (S0 → pending G-ingest). Conjecture-marked. GATE: prose only — this
> authorizes no ontology or URN change.** Authored T231 (continuation of the phone session that
> produced `20260620-t231-moos-soom.md`). Math grounded in Spivak & Niu, *Polynomial Functors: A
> Mathematical Theory of Interaction* (`poly-book.pdf`) and Spivak, *The Polynomial Abacus* (Topos
> Institute, `Pfunc2021.pdf`); reconciled against the repo's existing categorical spine
> (`dev/reference/research-archive/20260420-t170-functorial-semantics-explicit.md`,
> `dev/reference/papers/act2026/main.tex`, `20260322-categorical-space.md`,
> `20260620-t231-moos-soom.md`, `20260326-fiber-decomposition.md`).

## 0. Thesis: everything is Poly
The repo already proves **mo:os = functorial semantics**: the ontology is a theory category, an
instance is a model `C → Set`, and `fold` is the catamorphism functor (t170, act2026). The
`moos-soom` draft named **so:om = the surface/interaction layer** and called `mo:os ⊣ so:om` an
adjunction. The missing word — the one that makes them *one* structure rather than two bolted
together — is **`Poly`**, the category of polynomial functors.

> **Claim (the spine):** `Poly` is the single setting in which both layers live. The **data layer
> (mo:os) is the comonoids of Poly** (comonoids in `(Poly, ◁)` *are* categories); the **interaction
> layer (so:om) is the lenses and coalgebras of Poly**. "Navigating to functions and sets" =
> `Set` is the ground Poly is built over; functions are lenses; categories are comonoids inside it.

## 1. Poly in sixty seconds
A **polynomial functor** is `p(Y) = Σ_{i ∈ p(1)} Y^{p[i]}`. Read it operationally:
- `p(1)` = the set of **positions** — the states a thing can be *in* (what it currently shows).
- for each position `i`, `p[i]` = the set of **directions** — the moves/inputs available *there*.

A **morphism `φ: p → q` in Poly is a dependent lens**: a forward map on positions
`φ₁: p(1) → q(1)` and, for each position, a *backward* map on directions `φ^#_i: q[φ₁ i] → p[i]`.
**Forward = project a state out; backward = pull an input back in.** A Poly map *is* an F⊣G pair at
one interface.

Three facts do all the work below (all from `poly-book`):
- **Comonoids in `(Poly, ◁, y)` are exactly small categories** (Ahman–Uustalu; poly-book Pt IV):
  positions = objects, directions at an object = morphisms out of it, the comultiplication =
  composition, the counit = identities. *Structure is a comonoid.*
- **The free monad `m_p` on a polynomial is the set of `p`-trees**: nodes labelled by positions,
  branching by directions, leaves free. *Trees are free monads on polynomials.*
- **A Moore machine `(states S, in A, out B)` is a lens `S·y^S → B·y^A`**: a readout `S → B` and an
  update `S × A → S`. *Dynamical systems are coalgebras/lenses; the polynomial `B·y^A` is the
  interface.*

## 2. mo:os = the comonoids (the data layer)
- The **ontology `C`** — the operad of node-types + the four rewrites (ADD·LINK·MUTATE·UNLINK as a
  sub-operad of Spivak's wiring operad `W`, per act2026 §Background) — **is a comonoid in Poly**:
  positions = node types, directions = admissible rewrites/relations out of a type, comultiplication
  = composition of relations (the PTP-chaining already shown to be a category in
  `categorical-space.md` §6).
- An **instance / folded graph** is a **model `C → Set`** (a copresheaf), i.e. a `Set`-valued
  functor / a `c`-coalgebra over the comonoid — exactly t170's "model `M: T → Set`" and act2026's
  catamorphism `state(t) = fold(log[0..t])`. The carrier lives in **`Set`**.
- **`fold` is the functor** `LogCat → GraphStateCat` (t170 §2.1). In Poly terms it is the
  *anamorphism/run* of the coalgebra: replay the directions, land in a position.

## 3. so:om = the lenses + coalgebras (the surface layer)
- A **surface** (Chrome tab, chat window, Keep widget, office pane) **is a polynomial `p`**:
  positions = what it currently displays (its UI states/outputs); directions = the inputs it
  accepts (clicks, keystrokes, an agent action).
- An **octopus tentacle is a lens `p → q`** (a Poly morphism): forward projects engine state onto
  the surface (**F**); backward ingests the surface's chosen input back toward the engine (**G**).
- A **live workspace is a coalgebra** `S·y^S → p` over its surface interface `p` — a Moore machine
  whose "tick" reads out a position and consumes a direction. This is the `moos-soom` §8 game-tick,
  now typed: the **two-channel HTTP/3** split is *readout (datagram, lossy presence)* vs *update
  (reliable stream, the rewrite-log commit)*.

## 4. mo:os ⊣ so:om = the two halves of every lens
The adjunction is not metaphor: **`F` is the forward leg, `G` is the backward leg of the lenses**
that connect the comonoid (structure) to its interfaces (surfaces). Globally,
`F: mo:os → so:om` (project/lower; `run-session-pipeline.ps1`, every dashboard) and
`G: so:om → mo:os` (ingest/lift; `moos-workspace-ingest`, the Keep-ingest runbook) are the
project/ingest pair the system already runs (t170's `Promote ⊣ Express` is the same shape one
stratum up). **Branching is this recursively**: a git write is `F(intent)` onto the VCS surface;
merge is `G(branch)` under RBAC (moos-soom §5).

## 5. mtdc = a chosen coalgebra; GitHub/devices = projection topologies
- **`my-tiny-data-collider`** = one **deployment** = a *specific* polynomial **coalgebra** — a Moore
  machine "colliding" input streams from many surfaces into one folded state. The name is literal:
  a collider is a dynamical system whose directions are incoming data and whose positions are the
  enriched graph.
- **GitHub, each device, each app = projection topologies** — *codomains to lower onto*. GitHub's
  own idiosyncrasy (orgs/users/repos/branches/worktrees) is **one polynomial among many**; an
  instance picks a destination by capability (the F/G-degree of `moos-soom` §4a = an LLVM
  backend-target descriptor). The kernel/HG is the only truth; **every repo/branch/`main` is an
  F-image** (`AGENTS.md` = "an F-image until generated").

## 6. Trees, pointers, allocation — no objects
This is the categorical statement of "no hardcoding, no objects, just pointers/memory/functions":
- **No object has a method.** There are only **positions** (states/cells) and **directions** (the
  moves available there). A node is a position; a function is a lens. (Same ECS/data-oriented move
  as `moos-soom` §3: object→node, field→property, method→relation/rewrite.)
- **URN = identity = the self-pointer.** `urn(M(x)) = urn(x)` (CI-3) is `id_x` — the position's own
  address (`categorical-space.md` §2: "identity = a port that refers to itself").
- **A pointer is a direction**; **memory is the set of positions**; **`ADD` allocates a new
  position**, `UNLINK` frees a direction. "A tree is a set of parent pointers" (Acton) is exact: the
  **repo/monorepo/branch/worktree n-ary tree is the free monad `m_p`** on a branching polynomial —
  nodes = positions, child-pointers = directions, leaves = working trees.

## 7. The folder is a dataflow (why `manifold-bump-4_0/` changed something)
Creating this folder introduced a **polynomial**:
- **positions** = the per-principal branch-workspaces (one per group/user/delegated-AI), each a
  place the system can be "in";
- **directions** = the **bump-hydration deltas** each branch ingests from its apps/Chrome-tabs on
  its workstation/device (the surface activity that `G` lifts in);
- **the merge is the colimit** of those branch-episodes sharing a purpose (t218 E4,
  `manifold = colimit`). The folder is therefore a *little so:om of the repo itself*: a polynomial
  whose run hydrates the shared graph. GitHub is the substrate it's projected onto.

> **ERRATA (T=260):** the phrasing "**the merge** is the colimit" misattributes t218 E4.
> E4 says the **workspace/manifold** is the colimit of its branch-episodes; the **merge** is
> `G(branch)` (ingest of a branch back into the receiving fold), NOT itself a colimit. Read
> "manifold = colimit; merge = G(branch)". Corrected in the t260 categorical-branching staging;
> this line is retained for lineage. (Readback wins over this doc — verify against
> `running-state.md` t260 and the staged branching program.)

## 8. Lineage — your HAL/Erban system already prefigured this (Drive)
From Drive (`Deflijst voor mindmap`, `1-BLACK ArTISTIC- L2R`), the 2025 **HAL/Erban/dG** design is
the same architecture pre-Poly:
- **HAL the "datatrawler" enriching `dG` in realtime** = **`G`** (ingest folding surface activity
  into the graph); `dG` = the folded instance in `Set`.
- the **swipeable app** — left: conventional workspace controls (email/agenda/drive/keep/browser);
  centre: the "social safe space" for G + HAL; right: unexplored external topologies — **is so:om**:
  a **mode-dependent polynomial** whose positions are the swipe-states and whose directions are the
  per-mode actions (left = exploit known, right = explore unknown topology).
- **Erban** ("subject/object/predicate relations… a typed building block") = a **node/derivation**;
  **Erbancode** = the typed direction-language. The **dynamic-prompting cycle**
  `prompt(t) → playbook-change → prompt(t+1)` is *literally a coalgebra tick*.
- **clusters / community-detection / external-topology exploration** = growing the manifold by
  **allocating new positions** in under-explored regions (Granovetter's weak ties = new directions).

The year-long through-line is one idea sharpening: **HAL/Erban/dG → mo:os/so:om → Poly.**

## 9. Conjectures, settled, open
- **Settled math (cited, not ours):** comonoids in Poly = categories; free monad = trees; Moore
  machine = lens. These are Spivak–Niu / Ahman–Uustalu.
- **Conjecture (ours, the proposal):** that mo:os's ontology *is* a Poly comonoid and each so:om
  surface *is* a polynomial with tentacles as lenses — i.e. that the existing kernel is a `Poly`
  program. This is a **recasting**, to be tested by actually presenting `C` as a comonoid and one
  surface as a polynomial. It **extends, does not contradict**, t170/act2026 (which use Lawvere +
  operad `W`); Poly *subsumes* both (comonoids + lenses) and adds the interaction/dynamics layer the
  paper lacks.
- **Open questions (1–2):** (a) Is the right semantic object for an instance a *cofunctor* out of
  the comonoid, or a bimodule `c ▻ Set`? (decides how federation glues — relates to t170's
  sheaf/colimit of signatures.) (b) Does the F/G-degree of an instance (`moos-soom` §4a) become a
  *sub-polynomial* relation (one interface refines another), giving "capability" a clean order?

## 10. GATE & sources
**GATE:** prose only. No node type, URN, port, or WF changes here; `device`, `channel.kind`
surfaces, and the comonoid presentation remain **conjectures / future `grammar_fragment`
proposals**, not applied. The ontology stays v3.16.2.

**Sources:** Spivak & Niu, *Polynomial Functors: A Mathematical Theory of Interaction* (poly-book);
Spivak, *The Polynomial Abacus* (Topos, 2021); Ahman & Uustalu, *Directed Containers as
Categories*; Lawvere 1963 (functorial semantics); repo: t170 functorial-semantics, act2026 paper,
categorical-space, moos-soom, fiber-decomposition, t218 branching. Drive: HAL/Erban/dG glossary,
BLACK-L2R app design. (To fold on a follow-up: `t225_mtdc_WSmanifold`.)

---
authored-by: agent:claude-code.hp-z440 / session:sam.z440-cowork-workspace / poly-foundations
