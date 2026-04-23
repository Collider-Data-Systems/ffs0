# T=170 — S0 operadic vocab, materialization sketch

> Turning the S0 lingo note into candidate v3.13 type specs.
> Companion to: `20260418-t168-s0-operadic-layer.md` (the lingo-note that named them).

---

## Background

The S0 operadic-layer note proposed 5 terms for the meta-stratum that sits above S1 as its meta-theory:

- **op-node** — an S0 object whose internal structure is a typed operadic element (multi-input, typed slots, one output).
- **slot** — a typed input position on an op-node.
- **yield** — the output of an op-node (singular, typed; may be an op-node itself).
- **threading** — a path through op-nodes that's evaluated at read-time as a projection.
- **weave** — a composite of op-nodes whose shape is itself an op-node (recursive).

All 5 are currently lingo-only. This note drafts them as v3.13-candidate type/port specs so they become promotable via WF20.

---

## 1. `op_node` (S0 type)

```
id: op_node
stratum: S0
urn_pattern: urn:moos:op_node:<slug>
urn_example: urn:moos:op_node:purpose.steers

ports:
  out: [yields]         # 1 yield port, singular output
  in:  [slot-of]        # receives slot LINKs from 0..N slots

properties:
  arity:           { mutability: immutable, type: integer, note: "number of slot-of edges in expected signature" }
  yield_type_urn:  { mutability: mutable, authority_scope: owner, type: urn, note: "type_id the yield is expected to present as, or null if polymorphic" }
  slot_schema:     { mutability: mutable, authority_scope: owner, type: array<object>, note: "per-slot: {name, type_urn, required, default_urn}" }
  signature_note:  { mutability: immutable, type: string, note: "human-readable operadic signature, e.g. 'purpose × context → scored_action'" }

semantics: |
  An op-node names a typed operadic element. At evaluation time, its slot-of
  edges are filled with concrete S1/S2 nodes; its yield projection computes
  an output. Sits above S1 because its slot types are themselves S1 types.

  op-nodes let us name recurring semantic shapes (purpose, scope-binding,
  session-occupancy, governance-firing) without committing to a specific
  S1 implementation. Think Lawvere theories generalized to multi-input.

v3.13 promotion prerequisites:
  - slot type (below)
  - yield port pair (below)
  - threading relation (below)
```

## 2. `slot` (S0 type)

```
id: slot
stratum: S0
urn_pattern: urn:moos:slot:<op-slug>.<slot-name>

ports:
  out: [slot-of]         # LINK to parent op_node
  in:  [fills]           # receives a LINK from whatever node is filling this slot (S1 or S2)

properties:
  slot_name:        { mutability: immutable, type: string }
  type_urn:         { mutability: immutable, type: urn, note: "expected type of the fill" }
  required:         { mutability: immutable, type: boolean }
  default_urn:      { mutability: mutable, authority_scope: owner, type: urn, note: "default fill when required=false and nothing provided" }
  position_index:   { mutability: immutable, type: integer, note: "for ordered-slot ops; optional" }

semantics: |
  A slot is a typed input position on an op-node. Filling a slot is a LINK
  (slot --fills-- actual-node) rather than a property, because slot-values
  are typed references, not scalars.
```

## 3. `yields / yielded-by` — port pair

```
src_port: yields
tgt_port: yielded-by
src_types: [op_node]
tgt_types: [any]
port_color: semantic

semantics: |
  Yield is the output of an op-node. Exactly one yields edge per op-node.
  The yield can be any node — S1 type, S2 instance, or another op-node
  (for nested ops). yielded-by on the target lets us traverse "what
  produced this node's current binding".
```

## 4. `threading` — relation (candidate new WF or WF18 extension)

```
src_port: threads
tgt_port: threaded-by
src_types: [op_node, weave]
tgt_types: [op_node, yield-target-set]

semantics: |
  A threading is an ordered path through op-nodes' yields, evaluated as a
  projection at read-time. Think "composition of Lawvere-theory morphisms"
  — threading is the operadic analog of function composition.

  Thread as a first-class object (rather than an implicit sequence) lets
  sessions pin a thread for reuse, or capabilities restrict which threads
  are evaluable under a given actor-scope.
```

## 5. `weave` (S0 composite)

```
id: weave
stratum: S0
urn_pattern: urn:moos:weave:<slug>

ports:
  out: [composes-weave]
  in:  [composed-in-weave]

properties:
  shape_signature: { mutability: immutable, type: string, note: "the operadic signature of the weave considered as an op itself" }
  threads:         { mutability: mutable, authority_scope: owner, type: array<urn>, note: "list of threading URNs making up this weave" }

semantics: |
  A weave is a bundle of threadings that together form an operadic composite.
  Distinguished from a plain op_node by being recursive — a weave IS an
  op_node at a coarser granularity, and can in turn be a slot-fill on a
  larger weave. Weaves are the mo:os name for 'large functors made of small
  functors' that Sam's s0-operadic-layer note was reaching for.
```

---

## 6. Mapping back to FS (short)

Each S0 element has a functorial-semantics read:

| S0 element | FS reading |
|---|---|
| op_node | morphism in a Lawvere-theory-with-multi-input (operad) |
| slot | typed domain factor |
| yield | codomain |
| threading | composition in the operad |
| weave | sub-operad, or operadic morphism between operads |

The whole S0 stratum IS the meta-theory whose models are S1 theories. Materializing these as v3.13 types lets mo:os talk about *its own type system* as if that system were data. Reflective layer, not just descriptive.

---

## 7. Proposed v3.13 grammar_fragments (for a future hydration round)

Not hydrated this round — noted for when we have the doctrine circulation to propose them together.

| URN suffix | Kind | Spec source |
|---|---|---|
| `v313-6-op-node` | type | §1 |
| `v313-7-slot` | type | §2 |
| `v313-8-yields` | port | §3 |
| `v313-9-threading` | wf_clause | §4 (possibly via new WF21 or WF18 extension) |
| `v313-10-weave` | type | §5 |

Each citation → `20260418-t168-s0-operadic-layer.md` + this note as `evidence_urns`. Promotion via WF20 in a separate round.

---

## 8. Dependencies

Proper S0 materialization wants:

- **FS spine** (`v313-1-functorial-semantics-spine`) promoted first — it gives S0 a home in doctrine.
- **Purpose-arity2** (`v310-13-purpose-arity2`, still proposed) as the first worked example of an arity-2 op-node.
- **Op-node evaluator** — code path (post-v3.13) that computes yields given slot fills. Either in the kernel sweep or as a separate projection service. Deferred.

---

## 9. Open questions

1. Do op-nodes live at S0 strictly (no LINKs down to S2) or do they admit S1 mixing (hybrid theory with data)? Leaning strict.
2. When a slot's required=true and nothing fills it, is the op-node "blocked" (per gate semantics) or "unresolvable" (per t-hook predicate)? Probably the latter — treat as predicate failure.
3. How do weaves compose with WF18 depends-on/composes? Are they orthogonal abstractions (S0 vs S2) or is WF18 a special case of weave?
4. Procrustes three-views — does it have an op-node presentation? Probably `op_node:crosswalk.three-views` with slots `classifier_a, classifier_b, rotation_method` and yield `crosswalk`.

---

## 10. Cross-references

- `kb/research/s1/20260418-t168-s0-operadic-layer.md` — the original lingo note
- `kb/research/s1/20260420-t170-functorial-semantics-explicit.md` — the FS spine
- `kb/research/s1/20260418-t168-irl-to-hg-pipeline.md` §3.4 — tight frames / HDC connection to operadic slots

— end —
