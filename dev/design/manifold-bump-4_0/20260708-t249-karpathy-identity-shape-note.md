# T=249 — Identity shape: persona-as-derivation, manifold spanning relations, owner placement

> **Lane:** Karpathy / `session:sam.karpathy-seat` (identity-relations commission, t248 plan §4 — "the shape").
> **GATE (prose-only):** this note authorizes NO ontology change, NO URN change, NO HG rewrite. Every structural proposal below matures via `grammar_fragment` (`status: proposed`) and the ONE collected WF20 review round per t248 plan §5.2.
> **Sources:** ontology.json v4.0.0 (derivation + purpose type blocks) · live fold :8000 (T=249) · t248 identity-relations plan (G1, G2) · t249 governance-authority-note §3 (P4 orthogonality) + §4 (R2 birth workspaces) + §7 (spine drift fix) · moos-categorical-research skill · moos-compiler-lowering skill (the "engine code = F-projection of operad" framing).
> **Companion:** `20260707-t248-identity-relations-plan.md` (the commission) · `20260708-t249-governance-authority-note.md` (authority lane).

---

## §1 — G1: persona-as-derivation — the D4 target shape

### The question

D3 (landed v4.0.0) ratified `persona = Φ(purpose)` as a *derivation* — a reified inference of presentational identity from purpose/scope/affordance evidence. D4 (`presents-as`) was deferred because there was nothing to point at. G1 asks: what is the target shape?

### Proposal: persona IS a derivation instance

The `derivation` type (v3.14, S2) already carries:

- `inference_kind` ∈ {bayesian, llm_completion, deterministic_rule, dag_walk, hand_authored, hybrid}
- `confidence` (0–1)
- `status` ∈ {open, closed, retracted}
- out-ports: `produces`, `consumes`
- in-ports: `authored-by`

A persona derivation is:

```
derivation:persona.<name>
  inference_kind = "deterministic_rule"   (Φ is a pure function of purpose + scope)
  confidence = 1.0                        (by construction — the derivation IS the name)
  status = "closed"                       (persona is born closed; it is a conclusion, not a process)
  owner_urn = urn:moos:user:sam
  name = "<persona-name>"                 (e.g. "karpathy", "zappa", "wolfram")
```

### The D4 relation: `presents-as`

```
agent —presents-as→ derivation:persona.<name>    (WF = new? or WF02 additional pair? see below)
```

The evidence chain:

```
purpose:sam.<slug>  —WF21 causes→  derivation:persona.<name>   (Φ input)
session:sam.<seat>  —WF19 has-purpose→  purpose:sam.<slug>     (already live)
agent:<principal>   —presents-as→  derivation:persona.<name>   (D4 target)
```

### WF placement for `presents-as`

**Conjecture C1 (marked):** `presents-as` is NOT an authority relation — it is a *presentation* relation. It does not grant capability, does not participate in §M11/§M12 gate resolution, and does not widen what an agent may do. It is the component of a **counit** in the F⊣G adjunction between the identity category (users, agents, purposes) and the surface category (persona names, display labels, UI renderings).

If C1 holds, `presents-as` belongs to a **new WF** or a **WF19 additional pair** (since WF19 already governs session↔agent↔purpose topology). It must NOT ride WF02 — governance is authority, and persona is explicitly not authority (D3 doctrine sentence: "never an authority principal").

**Proposed fragment shape:**

```jsonc
// grammar_fragment: urn:moos:grammar_fragment:d4-presents-as   (status: proposed)
// fragment_kind: "port" — WF19 additional_port_pair
{
  "src_port": "presents-as",
  "tgt_port": "presented-by",
  "src_types": ["agent"],
  "tgt_types": ["derivation"],
  "description": "D4 persona presentation. Agent presents-as a persona derivation. Presentation only, never authority. At-most-one per agent (single persona per principal); rotation = MUTATE of the LINK target_urn.",
  "added_in_version": "4.0.x",
  "promotes_fragment": "urn:moos:grammar_fragment:d4-presents-as"
}
```

### Conjecture C2 (categorical, marked)

**The counit reading.** In the F⊣G adjunction where F projects identity into surface labels and G observes surface behavior back into graph evidence:

- The **unit** η: agent → G(F(agent)) says "observe the projection of an agent and you recover the agent" — this is identity reconciliation (the MVP gate's actor/occupant check).
- The **counit** ε: F(G(persona)) → persona says "project-then-observe a persona and you recover the persona" — this is `presents-as`: the surface projection of the persona (the seat table row, the `@karpathy` card, the VS Code agent) collapses back to one derivation node via a single relation.

If C2 holds, `presents-as` is the graph realization of ε, and its round-trip fidelity is the measurable projection-fidelity metric for persona identity. This is the same structure as the T189 Calendar projection-fidelity claim, instantiated for identity rather than events.

**Not settled.** C2 is a categorical reading, not a gate decision. Mark it conjecture; let it mature through the WF20 round alongside D4.

---

## §2 — G2: manifold spanning relations — the two-level colimit

### The question

The `manifold` type (v4.0.0 D1, S2) landed identity-first with spanning relations explicitly deferred. The type has `ports.self: [identity]` and nothing else. G2 asks: what WF and port pair connects a manifold to its constituents?

### The two-level colimit (doctrine, t218)

The branching strategy (t218) established:

```
workspace (session) = colimit of branch-episodes sharing one purpose-slug
manifold            = colimit of per-repo branches sharing one purpose-slug (across repos)
```

In plain topology: `my-tiny-data-collider` is a manifold whose cocone legs are the purposes / programs / channels / sessions that share its slug across ffs0 / moos-kernel / moos-router.

### Proposal: manifold spanning relation via WF18 extension

WF18 (Program composition) already wires `program → session`, `program → purpose`, `purpose → program`. Its port pair is `composes / composed-by`. A manifold is the top-level composition container — it composes everything below it.

**Proposed fragment shape:**

```jsonc
// grammar_fragment: urn:moos:grammar_fragment:g2-manifold-spans   (status: proposed)
// fragment_kind: "wf_clause" — WF18 additional_port_pair + src_types extension
{
  "WF18": {
    "src_types_add": ["manifold"],
    "additional_port_pair": {
      "src_port": "spans",
      "tgt_port": "spanned-by",
      "src_types": ["manifold"],
      "tgt_types": ["purpose", "program", "session", "channel", "group"],
      "description": "Manifold spanning — the cocone legs of the two-level colimit. A manifold spans purposes, programs, sessions, channels, and groups that share its identity domain. Many-to-many; no at-most-one constraint."
    }
  }
}
```

### Conjecture C3 (categorical, marked)

**The cocone vertex.** In the colimit construction:

- Objects: the per-repo/per-session branch-episodes (purposes, programs, sessions) that share a domain slug.
- Morphisms: the WF18 `composes/composed-by` and WF19 `pins-urn` relations that wire them.
- Cocone vertex: `manifold:my-tiny-data-collider`.
- Cocone legs: `spans/spanned-by`.
- Universal property: any other node that receives all the same legs factors uniquely through the manifold.

**Not settled.** Whether this is a *strict* colimit or merely a *weak* one (up to equivalence) depends on whether the HG category has enough limits/colimits to make the universal property decidable. In practice, the manifold is authored (an ADD), not computed — so the universal property is a design constraint on what gets spans, not a runtime derivation. The colimit framing is the *justification* for the relation's existence, not its *implementation*.

### Owner placement in the colimit

**Conjecture C4 (marked):** The manifold's `owner_urn` is a *provenance stamp* (like every other `owner_urn` property), NOT a cocone morphism. Ownership is a **WF01 relation** (`user/group —owns→ manifold`), not a spanning leg. The cocone vertex has provenance (who filed the paper) and topology (what it spans) — these are orthogonal. `group:my-tiny-data-collider` already exists as the application group; it plausibly becomes the owner (via WF01), and the manifold spans through it to its channels/purposes. But "owns" ≠ "spans" — the owner is not inside the colimit diagram; the owner is the filing clerk who named the vertex.

---

## §3 — P4/§M12 orthogonality (Lydon §3 cross-reference)

Lydon's governance note §3 proposes P4 (occupant-guard) as a **soft hook first** (WF17 t_hook), with exemption set E1–E4. His text marks the following for Karpathy-adjacent verification:

> "Composition with §M12 — conjecture, marked as such: occupancy (liveness axis) and capability (authority axis) are orthogonal; the guard composes with, and never substitutes for, §M12."

### Conjecture C5 (marked, Karpathy-adjacent)

**Orthogonality claim.** §M11 (liveness) answers "does this actor have a live session on this fold?" §M12 (admin capability) answers "does this actor's authority chain include superadmin for admin-scope ops?" P4 (occupant-guard) would answer "is this actor the currently-declared occupant of the target session?"

These three predicates form a **product** in the boolean lattice of gate decisions:

```
pass = M11(env) ∧ M12(env) ∧ P4(env)
```

They are orthogonal iff no predicate implies another:

- M11 ⇏ P4: an actor can have a session without being the *current* occupant (idle rotation).
- P4 ⇏ M11: being declared occupant of a session does not mean the session is *on this fold* (cross-fold mismatch, per R1 strict sovereignty).
- M12 ⇏ P4: superadmin capability says nothing about occupancy.
- P4 ⇏ M12: occupancy says nothing about admin scope.

**Verdict (conjecture):** orthogonal. The product decomposition is correct; no predicate should be removed in favor of another. P4's soft-hook-first disposition (Lydon R-P4) is the operationally safe way to validate the orthogonality claim at runtime before hardening.

### Verification surface (Wolfram lane, G5)

The runtime verification that the loader actually enforces what the grammar declares is NOT this lane's work — it belongs to the G5 loader-gap check dispatched to Wolfram. What this note contributes: the *claim* that the three predicates compose as a product, which means the loader must evaluate them independently and never short-circuit one on behalf of another.

---

## §4 — Open questions (for Sam, not blocking this note's delivery)

1. Does `presents-as` live on WF19 (same WF as the rest of the seat spine) or on a new WF? WF19's name is "Session governance" which is authority-flavored; persona is explicitly not authority. But adding a new WF for one relation is heavyweight.
2. Does the manifold's first `spans` LINK wait for the `manifold:my-tiny-data-collider` node to be ADDed, or does the node exist only in config (the current state)? If ADDed, it's a Sam-gated batch.
3. Does the Φ function eventually become mechanically computable (derive persona from purpose + scope + affordance evidence via a runtime derivation), or does it stay a human-named convention? If mechanizable, `inference_kind` should be `deterministic_rule`; if not, `hand_authored`.

---

## §5 — Fragment summary (all status: proposed)

| Fragment URN | Kind | What it does |
|---|---|---|
| `urn:moos:grammar_fragment:d4-presents-as` | port | WF19 additional pair `agent —presents-as→ derivation` |
| `urn:moos:grammar_fragment:g2-manifold-spans` | wf_clause | WF18 additional pair `manifold —spans→ purpose/program/session/channel/group` + src_types extension |

Both ride the collected WF20 round alongside Lydon's g6a/g6b.

---

## §6 — Conjectures ledger

| ID | Statement | Register | Status |
|---|---|---|---|
| C1 | `presents-as` is not an authority relation; it does not participate in §M11/§M12 | HG topology | conjecture |
| C2 | `presents-as` is the graph realization of the counit ε in the identity F⊣G adjunction | formalism | conjecture |
| C3 | manifold is the cocone vertex of a two-level colimit over branch-episode objects | formalism | conjecture |
| C4 | manifold `owner_urn` is provenance (WF01), orthogonal to cocone topology (spans) | HG topology | conjecture |
| C5 | §M11, §M12, P4 form a product in the boolean gate lattice (orthogonal predicates) | formalism + runtime | conjecture (Lydon-adjacent) |

---
authored-by: urn:moos:agent:vscode.hp-z440.lola / urn:moos:session:sam.karpathy-seat / t249-identity-shape
workstation: urn:moos:workstation:hp-z440
channel-kind: harness-pane
