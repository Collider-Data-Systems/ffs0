---
agent: "moos-categorical-research"
description: "Use when: orienting in the 4.0 categorical stack — a guided six-stop tour from mo:os to the category Set, naming what lives at each stop and the math that holds it. Companion to 20260620-t231-poly-foundations.md."
---

# Poly navigation map — mo:os → so:om → mtdc → Poly → functorial semantics → Set

A one-screen tour of the territory. Each stop: **what lives here** · **the math** · **the file**.
Full reasoning in `20260620-t231-poly-foundations.md`.

| # | Stop | What lives here | The math | Where in repo |
|---|------|-----------------|----------|---------------|
| 1 | **mo:os** | the durable data/graph **engine** — HG, instances, `state = fold(log)`; the dachshund | a **comonoid in Poly** (= a category); fold = catamorphism functor | `20260620-t231-moos-soom.md`, t170, act2026 |
| 2 | **so:om** | the active **surface** matrix — tabs/apps/widgets/panes; the octopus | **lenses + coalgebras** in Poly: a surface = a polynomial, a tentacle = a lens, a live workspace = a Moore machine | `20260620-t231-moos-soom.md` §0–§4 |
| 3 | **mtdc** | one **deployment** — `my-tiny-data-collider`, the running thing | a **specific coalgebra** "colliding" input streams into one folded state | `20260605-t216-mtdc-channel-inventory-dry-plan.md` |
| 4 | **Poly** | the **shared home** — interaction itself | `(Poly, ◁, ⊗)`: positions & directions; comonoids = categories; free monad = trees; `Set` underneath | `20260620-t231-poly-foundations.md` (Drive: poly-book, Abacus) |
| 5 | **functorial semantics** | the **syntax↔semantics** bridge | theory `C` (Lawvere) → model `M: C → Set`; `Promote ⊣ Express` | t170 functorial-semantics, act2026 §Background |
| 6 | **Set** | the **ground** — functions and sets | positions and directions are sets; functions are the maps; everything else is built over it | (the base; nothing to "store") |

## The route, in one breath
**Set** is the ground (functions and sets). **Poly** is the layer of *interaction* built over it
(positions = states, directions = inputs). Inside Poly, **categories are comonoids** — so the
**mo:os** ontology is a comonoid, and a folded instance is its `Set`-model (**functorial
semantics**). The **so:om** surfaces are *other* polynomials, and the octopus **tentacles are
lenses** (Poly morphisms) wiring engine ⇄ surface — the forward leg is **F** (project), the
backward leg is **G** (ingest). **mtdc** is one chosen coalgebra running that loop. Trees
(repos/branches) are **free monads** on polynomials; pointers are **directions**; `ADD` allocates a
**position**; a URN is a position's **identity** (`urn(M(x))=urn(x)`). No objects — only positions,
directions, and lenses.

## Two adjoint mascots
- **mo:os = dachshund** — nose pointed at one thing: the fold. The comonoid/engine.
- **so:om = octopus** — eight lenses into eight surfaces: the tentacles. The interaction layer.

They are the **forward and backward legs of the same lens.**
