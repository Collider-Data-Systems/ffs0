# T313: Designing the mo:os Polynomial

**Authored:** 2026-09-10 (T=313)
**Context:** Formalizing the departure from legacy OOP. Mapping the `mo:os` kernel to Colored Polynomial Functors (Poly_C) and Moore Machines/Coalgebras.

---

## 1. The Definitional Mapping: Colors, Pos, Dir vs. Manifolds

Before we write the equation, we must strictly delineate what each mathematical concept maps to in the `mo:os` 4.0 architecture.

### **Colors (C)**
*   **Math:** The index set for the fibration of polynomials. 
*   **mo:os:** The **Ontology Port Colors** (`auth`, `topology`, `transport`, `compute`, `storage`, `workflow`, `semantic`, `projection`).
*   **Role:** The *Type Checker*. Colors do not store state and do not accept inputs. They exist solely to dictate *which* directions can flow into *which* positions during composition (enforced by the `color_compatibility_matrix`).

### **Positions (I or B)**
*   **Math:** The readout, the observable states of the polynomial interface, typed by an output color (c_out).
*   **mo:os:** A specific **Out-Port Readout** or **F-Projection**.
*   **Role:** When a surface (like your VS Code IDE or the Antigravity UI) looks at the system, it is observing a Position. A Position is *what the system exposes* at a given moment. 

### **Directions (D_i or E)**
*   **Math:** The set of admissible inputs at a given position $i$, typed by an input color (c_in).
*   **mo:os:** The **Rewrite Envelopes** (`ADD`, `LINK`, `MUTATE`, `UNLINK`).
*   **Role:** The parameters entering the In-Ports. If the system is in Position $i$, it exposes a menu of valid Directions (e.g., "You can send a `semantic` ADD envelope here").

### **Manifolds (The State Space S)**
*   **Math:** The hidden state space (S) and the **Coalgebra** (S -> p(S)) that drives the polynomial.
*   **mo:os:** The **D1 Manifold** (`my-tiny-data-collider`) and the **GraphState**.
*   **Role:** The Manifold is the *arena* (the physical and semantic topology). It is NOT the interface itself; it is the entity *behind* the interface. The Manifold evaluates the Coalgebra: it folds the log of Directions to produce the next Position.

---

## 2. Designing Our Poly: p(y)

Let's design the Polynomial Functor p_{moos}(y) for a `mo:os` manifold boundary.

In pure math, a polynomial is written as:
p(y) = \sum_{i \in I} y^{D_i}

For `mo:os`, we define this iteratively:

### The Set of Positions (I)
A position $i$ is a specific observable state of the `GraphState`. 
Let $I$ be the set of all possible valid graph states (or projections thereof) that the kernel can expose via its HTTP `/state` readback.

### The Set of Directions (D_i)
At any given position (GraphState) $i$, what inputs are allowed? 
D_i is the set of all valid **Rewrite Envelopes** that pass validation at state $i$.
D_i = { env \in {ADD, LINK, MUTATE, UNLINK} | Validate(i, env) = True }

### The Typed Fibration (Adding Colors)
Because we use Colored Poly (Poly_C):
1.  The Readout $i$ emits over specific colors (e.g., exposing a `projection` port to VS Code).
2.  The Envelope $d \in D_i$ must carry an input color (e.g., a `workflow` envelope).

Thus, our manifold's interface is the polynomial:
p_{manifold}(y) = \sum_{i \in Readbacks} y^{ValidEnvelopes(i)}

---

## 3. The Coalgebra (The mo:os Engine)

The polynomial p(y) only defines the *shape* of the API. The actual engine is the Coalgebra S -> p(S), which splits into:

1.  **Readout:** S -> I
    *   *Implementation:* The logic that computes `/state` from the raw data.
2.  **Update:** S x D -> S
    *   *Implementation:* The `fold` function! State(t+1) = Fold( State(t), Envelope_{t+1} ).

---

## 4. Next Steps for the Audit
To audit the Go kernel against this design, we must verify:
1. Does `Envelope` strictly act as $D$ (pure data parameter, no hidden execution methods)?
2. Does `GraphState` strictly act as $I$ (pure readout)?
3. Is `Fold` strictly a pure function S \times D \to S?

## 5. Baking Identity into Colors (Dependent Typing)

By choosing to bake authorization into the colors, we shift access control from a *runtime check* inside the Coalgebra to a *structural type check* at the Polynomial interface.

### The New Color Space
Our original color set was exactly 8 colors: 
C_{base} = {auth, topology, transport, compute, storage, workflow, semantic, projection}

Now, the true color set C is a Cartesian product of the base colors and the set of Identities (URNs):
C = C_{base} \times Identities

*   An output port isn't just 	opology; it is (topology, urn:moos:agent:zappa).
*   An incoming MUTATE envelope isn't just 	opology; it carries the identity of the sender (Actor): (topology, urn:moos:agent:lydon).

### Why this is mathematically beautiful:
In Poly_C, composition requires that the output color of the position strictly matches the input color of the direction.
If Lydon tries to MUTATE a node owned by Zappa, the colors (topology, lydon) and (topology, zappa) **do not match**.
The composition evaluates to zero (is annihilated). 

The invalid envelope is rejected structurally by the Polynomial interface *before* it ever reaches the Coalgebra's Fold function. The Fold function remains completely pure and ignorant of authorization logic, because the interface only passes it valid Directions!

