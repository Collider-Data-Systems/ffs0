# T=175 — Program-authoring fabric: derivations, clocks, causation, substrate, leaves

> April 24, 2026 (T=175 ~12:00 CEST). Doctrine note for the v3.14 ontology-fabric expansion.
> Author: Stephen Wolfram persona (`agent:claude-code.hp-z440`, `session:sam.kernel-proper`, `kernel:hp-z440.primary`).
> Status: **draft, design only** — proposes 5 v3.14 grammar_fragments. Materialization deferred to future rounds via WF20 ceremony.

---

## 0. Why this note exists

Through round 11 (T=170–T=174) we materialized **seats**: who occupies which session on which kernel. That work answers *where* — five personae across two machines, six sessions, kernels federation-symmetric. It does not answer *how programs come into existence*.

Today, when a session emits a `program` envelope, the inference path that derived it lives in the agent's context window. The kernel sees the envelope and applies it; the reasoning behind it is invisible. That gap is acceptable while the substrate is small. It is not acceptable when (a) we want every program auditable back to its evidence, (b) we want time-bound triggers more general than `t_hook`, (c) we want causation distinct from temporal succession, (d) we want substrate (where node-truth lives) to be queryable, and (e) we want leaves — the only places HG crosses outside itself — to be first-class objects rather than implicit side-effects.

This note settles those five threads as one fabric. Five v3.14 grammar_fragments fall out; each can promote independently through the WF20 ceremony when it's ready.

This is **not** about the seating substrate. The five-facet tuple from `20260419-t169-session-generalization.md` stays unchanged. This note adds *what happens inside a session that's already seated*.

---

## 1. The session as program-authoring layer — `derivation` as node

A `session` (per T=169) is a 5-facet scoped context: scope, purpose, host, owner, occupant. Its work-product today is a stream of envelopes. The reasoning between in-scope evidence and emitted envelopes is opaque.

**Reify the inference itself.** A new node-type `derivation` makes the reasoning a first-class graph object.

### Type proposal

```
type_id:    derivation
stratum:    S2
URN:        urn:moos:derivation:<session-slug>.<seq>

Properties
  inference_kind   enum (mutable, owner)
                   {bayesian, llm_completion, deterministic_rule,
                    dag_walk, hand_authored, hybrid}
  stochastic_weights  object (mutable, owner)
                   free-form: priors, biases, temperature, top-p,
                   sampling strategy, model URN — when applicable
  confidence       number [0,1] (mutable, owner)
  status           enum (mutable, kernel)
                   {open, closed, retracted}
  name             string (immutable)
  created_at       datetime (immutable)
  owner_urn        urn (immutable)         provenance stamp

Ports
  out: produces        (target: program, claim, knowledge_item, envelope-batch-target)
  out: consumes        (target: knowledge_item, claim, calendar_event, message_packet, …)
  in:  authored-by     (paired with session.authors-via — v3.14 fragment dependency)
```

### Companion: session port-pair `authors-via / authored-by-session`

Currently `session` has no out-port carrying authoring intent. Add `authors-via` (out, target=`derivation`) and the inverse `authored-by-session` on `derivation` to close the loop.

### Worked example: T=173 chunker batch

When `agent:claude-cowork.hp-z440` emitted the 24-envelope batch on T=173 ~23:30 CEST (log_seq 307→331 on Z440 kernel 0), the inference was: **"For each H2 boundary in the Drive doc, ADD a knowledge_item section; ADD an umbrella; LINK channel→umbrella; LINK umbrella→each section via WF12 provides-kb."** That's a deterministic rule. As a derivation node:

```
urn:moos:derivation:cowork-z440.glossary-h2-chunker
  inference_kind:        deterministic_rule
  stochastic_weights:    null
  confidence:            1.0
  status:                closed
  name:                  "glossary-h2-chunker"
  consumes →             channel:google.drive.sam (the Drive doc artifact)
  produces →             ki:gdrive.glossary-moos-decoder-ring + 11 sections + 12 LINKs
  authored-by ←          session:sam.z440-cowork-workspace
```

Now the batch walks back to its derivation, the derivation walks back to the in-scope channel, and the channel walks out to the external Drive doc that drove the chunking. Provenance closes.

### Grammar fragment

`v314-1-derivation-type` — proposed.

---

## 2. Time as a generalized fabric — `clock` as node

`t_hook` bundles (predicate, scope, reaction, sweep-tick) for one specific case: kernel-sweep-30s evaluating boolean predicates and emitting on satisfaction. The general structure factors:

`(clock × predicate × scope × reaction)`

Express **clock** as its own node-type so multiple sessions share or specialize.

### Type proposal

```
type_id:    clock
stratum:    S2
URN:        urn:moos:clock:<owner>.<slug>

Properties
  cardinality      enum (immutable)        {point, interval}
  embedding        enum (immutable)        {linear, cyclic, dag, branching}
  frame            enum (immutable)        {absolute, relative}
  frame_anchor_urn urn (immutable)         when frame=relative
  density          enum (immutable)
                   {sec, min, hr, sweep, T-day, round, program-cycle,
                    event-driven, custom}
  density_n        integer (immutable)     e.g. density=sweep, density_n=2
                                           → "every 2 sweeps"
  cycle_period     object (immutable)      when embedding=cyclic
  name             string (immutable)
  created_at       datetime (immutable)

Ports
  out: ticks-on
  in:  keeps-time-with
```

### Dimensions, restated

| Dimension | Values | Example |
|---|---|---|
| Cardinality | point / interval | a `t_hook` is a point; a sweep-window is an interval |
| Embedding | linear / cyclic / dag / branching | T-day is linear; Mon-08:00 ritual is cyclic; round-graph is a DAG |
| Frame | absolute / relative | `2026-04-23T22:11Z` is absolute; `+5 sweeps after t187 close` is relative |
| Density | sec / min / hr / sweep / T-day / round / program-cycle / event-driven / custom | most kernel work runs on sweep-density |
| Scope | which nodes tick on this clock | encoded via `keeps-time-with` LINKs |

### Event-driven density unifies leaves and time

The special case `density=event-driven` says: the clock ticks when a watched relation appears, not when wall-clock advances. This is exactly the **leaf-spin model** from §6 below. A leaf is a clock-bound continuation on event-density; the argument-relation arrival *is* the tick.

### `t_hook` becomes a special case

Post-promotion, `t_hook` rewrites as: a clock-bound predicate-and-reaction node with an explicit `keeps-time-with --> clock:kernel.sweep-30s` LINK, rather than the implicit kernel-sweep binding it has today. Existing t_hooks migrate by gaining one LINK; semantics preserved.

### Grammar fragment

`v314-2-clock-type` — proposed.

---

## 3. Causation as first-class — WF21 `causes / caused-by`

`WF18 scheduled-after` carries **temporal succession** (B happens after A in real time). That is not causation. Two events can be temporally ordered without one causing the other.

**Causation** is the counterfactual relation: *A's absence ⇒ B's absence in the relevant counterfactual world.* Pearlian convention; standard for structural causal models.

### Rewrite-category proposal

```
WF21
  src_port:  causes
  tgt_port:  caused-by
  Authority: owner
  src_types: superset of S2 actionable nodes
             {program, derivation, knowledge_item, claim, event_notice,
              tool_result, calendar_event, message_packet, …}
  tgt_types: same superset
  Validator: ValidateCausalAcyclic — `causes` forms a DAG; cycles rejected
```

### Distinct from succession

`causes` and `scheduled-after` can co-exist on the same node pair without conflict. A program causes its sub-programs (causation); the sub-programs are scheduled-after the parent (succession). Both edges are true; both are useful for different queries.

### Why we need it now

Three immediate uses:

1. **Derivation provenance** (§1): every program is `caused-by` exactly one derivation; every derivation is `caused-by` its consumed evidence. Walk the chain to audit.
2. **Closed-loop training** (§7): when Collider-LLM v_n+1 trains on past HG state, its weights are `caused-by` past derivations. The whole self-improvement chain becomes graph-resident.
3. **Counterfactual queries**: "if we hadn't promoted v3.13, what wouldn't have landed?" needs causation, not succession.

### Grammar fragment

`v314-3-wf21-causes` — proposed.

---

## 4. Substrate — where node-truth lives

Some nodes are HG-native: their truth is the kernel log. Some are reifications of external surfaces: their truth lives in Google Drive / Gmail / Calendar / GitHub / etc., and the HG node is a pointer + last-known-state. Some are volatile: they exist only in session cache and never get written. Some are cached: HG node + session-cache copy, with cache eviction policy.

**Pre-existing operad ground.** The ontology already distinguishes substrates structurally:
- `compute` (S2, urn `urn:moos:compute:<workstation>.<type>`) — the computation substrate; `compute.capacity` has `authority_scope: "substrate"`. Substrate is already a recognised authority distinct from owner/kernel/system.
- `storage` (S2, urn `urn:moos:storage:<workstation>.<name>`) — persistent storage resource with `storage_type: {git_repo, local_fs, rewrite_log}`. Memory-location-as-node is already first-class.
- `s4_cache_contract` — the existing s4-cache rules section in `ontology.json` already governs derived caches (e.g. `agent_capabilities_cache`).

The leaf-spin model (§5) needs **node-level** substrate to know where to fetch arguments from when the argument-relation arrives. That's a property orthogonal to the existing `compute` / `storage` types: the types describe *substrate resources*; the property describes *which resource a particular node's truth lives in*. Both are needed.

### Property proposal

Add `substrate` to relevant node-types (knowledge_item, claim, calendar_event, message_packet, channel, plus any new types where it applies):

```
substrate          enum (immutable)
                   {hg-native, external-channel, volatile, cached}
substrate_anchor_urn  urn (immutable, when substrate=external-channel)
                   → channel:<surface> holding the external pointer
substrate_cache_ttl   integer (mutable, owner, when substrate=cached)
                   seconds; 0 = never expire
```

### Backfill plan

- All existing HG-native nodes (sessions, agents, kernels, programs, etc.) get `substrate=hg-native` on next ontology bump (defaultable; no per-node MUTATE needed).
- Channel-derived `knowledge_item`s that already cite a `source_url` get `substrate=external-channel` with `substrate_anchor_urn` resolved from the URL prefix.
- Volatile + cached are forward-only — no existing node needs them; they appear when leaves start emitting.

### Grammar fragment

`v314-4-substrate-property` — proposed.

---

## 5. Leaves are partial morphisms — leaf-firing-state semantics

**Definition (Sam, T=175):** "leaves at the end is a loose term — any structure (fluid, not rigid) that displays values or answers to the session arguments." So a leaf is whichever node-type, in the moment, surfaces a value back into a session that has open arguments. The narrow case is `tool_call`, `external_op`, `compute` — the existing leaf node-types crossing HG → Ext. The broader case admits `knowledge_item` snippets pinned into a session's t-cone, `tool_result`s arriving from past leaf-fires, `claim`s settled by another persona. Anything that closes an open slot for a derivation. The fluid framing matters: leaves are not a fixed type-set — they're whatever node currently delivers a value to an argument-port of an open derivation.

The leaf-firing-state semantics that follow apply to the **narrow** case (the impure-boundary leaves). The fluid case mostly inherits — a `claim` arriving as a leaf doesn't need provisioned/hot/firing/applied/closed states, because it's already-applied; only the impure-boundary leaves need the staging machinery.

Categorically, a narrow leaf is a **partially-applied morphism** `f(a, _): B → C` where `a` is bound from in-scope evidence and the leaf sits at `_: B → C` waiting for a `B`-argument relation to LINK in. When the LINK arrives, the leaf fires, executes externally, and emits a `tool_result` C back into HG. This is a continuation in CS terms; a thunk in lazy-evaluation terms. **Per the T=164 archive note** `dev/reference/research-archive/20260414-t164-session-channel-purpose.md` §5: every `tool_call` is **operadic** (many inputs → one output), and the `watcher → reactor` fan-out that drives leaf transitions is **cooperadic** (one input → many outputs). The leaf-firing fabric is operad-cooperad duality made runtime-explicit.

### State machine

Mirror `t_hook.firing_state` exactly (no coincidence — t_hooks are time-triggered leaves):

```
provisioned  →  hot  →  firing  →  applied  →  closed
                ↓
            (timeout / cancel) → closed
```

- **provisioned** — bindings collected, env staged, code loaded into session cache
- **hot** — process up, waiting for argument-relation
- **firing** — argument arrived, leaf executing externally
- **applied** — `tool_result` emitted back into HG
- **closed** — leaf released, cache evicted

### Watcher pattern

The transition `hot → firing` is kernel-driven via a `watcher`:

```
watcher:
  match_rewrite_type:  LINK
  match_urn_prefix:    <leaf-urn>
  match_port:          <argument-port>
  triggers:            reactor:fire-leaf
```

When the argument LINK lands, the watcher triggers a reactor that emits the leaf-state MUTATE `hot → firing` and the external execution begins. Idempotency: same args + same code SHA → same `tool_result` URN (deterministic; replay-safe).

### Property proposal

Either extend `firing_state` enum to apply on leaf types, or add a sibling enum `leaf_state`. I'd prefer extending — fewer enums, same semantics. Authority: kernel (state transitions are kernel-driven by watchers).

### Grammar fragment

`v314-5-leaf-firing-state` — proposed.

---

## 6. The closed loop — Collider-LLM as endofunctor

The F⊣G adjunction in our doctrine has F as projection (HG → external surface) and G as ingest (external → HG). For most surfaces (Gmail, Drive, Calendar, GitHub) that maps cleanly: G observes external state into channel-derived nodes; F emits envelopes that drive external effects via leaves.

**Collider-LLM is the degenerate case where Ext = HG itself.**

The flow:

1. **G observes**: past HG snapshots are consumed as training corpus by a Collider-LLM training derivation (`inference_kind=hybrid`, `consumes` = past `program`/`derivation`/`knowledge_item` nodes).
2. **F emits**: trained model weights become a property of a `knowledge_item` (or a future `model` node-type) anchored at `substrate=hg-native` since the weights are the HG's own output.
3. **Next-round derivations** with `inference_kind=llm_completion` cite that model URN in their `stochastic_weights.model_urn`.
4. **Causation closes the loop**: each round's outputs are `caused-by` (WF21) the prior round's training outputs, which are `caused-by` the round-before-that's derivations, etc.

The whole self-improvement chain is graph-resident. We can ask: "which programs in T=200 were caused-by which derivations in T=175?" and walk the WF21 DAG.

This isn't blue-sky — it's just where the substrate lands when you take §1–§5 seriously and apply them to the kernel's own outputs.

---

## 7. Adjunction frame — where each piece sits

```
            [ Ext: Drive, Gmail, GitHub, … ]
                     ↑          ↓
                     F          G
                     ↑          ↓
        ┌────────────┴──────────┴─────────────┐
        │                                      │
        │  ┌── derivation (§1) ──┐             │
        │  │  consumes evidence  │             │
        │  │  inference          │             │
        │  │  produces envelopes │             │
        │  └─────────────────────┘             │
        │            ↓                          │
        │        program / claim                │
        │            ↓                          │
        │     leaf (§5) — partial morphism     │
        │            ↓                          │
        │     argument-relation arrives ────────┘  ← clock event-tick (§2)
        │            ↓
        │        leaf fires
        │            ↓
        │     external execution (the only F crossing) → emits tool_result back into HG
        │
        │   substrate (§4) tags every node:
        │   hg-native | external-channel | volatile | cached
        │
        │   causes/caused-by (§3) tracks provenance across all of the above
        │
        │   clocks (§2) trigger derivations + leaves; sessions keep-time-with clocks
        └──────────────────────────────────────────────────────────────────────────────┘
```

Categorically: derivations are **morphisms in HG**; leaves are **morphisms HG → Ext**; F⊣G observes Ext and emits via leaves; causation orders the morphism chain; substrate locates each node's truth; clocks drive everything.

---

## 8. Promotion order + dependencies

Five fragments, with dependency:

| # | Fragment | Depends on | Notes |
|---|---|---|---|
| 1 | `v314-1-derivation-type` | session port-pair `authors-via / authored-by-session` (sub-fragment) | promotes first; minimal blast radius |
| 2 | `v314-2-clock-type` | none | promotes independently |
| 3 | `v314-3-wf21-causes` | none structural; benefits from §1+§2 being live | best after derivations exist to causate over |
| 4 | `v314-4-substrate-property` | none | promotes independently |
| 5 | `v314-5-leaf-firing-state` | §2 (clock event-density semantics), §3 (watcher → causes leaf transition) | promotes last; needs the full fabric |

Suggested round cadence: §1 + §2 in T=176 batch; §3 in T=177; §4 in T=178; §5 in T=179. Conservative — Sam can compress if validators come up clean.

Each fragment goes through the standard ceremony: ADD `grammar_fragment` (proposed) → review → MUTATE proposed → promoted → ontology.json edit + kernel restart → MUTATE promoted → merged. Pattern proven at T=169 round 10 (D19.2/D19.3/D19.4/D20.1/D20.2) and T=173 (v313-6/7/8/9).

---

## 9. Cross-references

- `kb/research/session/20260419-t169-session-generalization.md` — 5-facet tuple this note builds on
- `kb/research/session/20260422-t172-cowork-as-occupant.md` — G-direction adjunction proven at T=174 ~00:45
- `kb/research/session/20260422-t172-wolframs-court-social-topology.md` — court topology that hosts the seats authoring derivations
- `kb/research/session/20260424-t173-meta-agent-scheduler.md` — scheduler-as-driver design; under T=175 framing this becomes one specific leaf in §5
- `kb/research/kernel/20260417-t187-kernel-proper.md` §M13 — `bumpSessionLocalT` gap closing via Phase E.2 (runtime.go fix)
- `~/.claude/plans/valiant-kindling-sunrise.md` Phase D.2 — plan-mode anchor for this note
- **Predecessor doctrine (archive)**: `dev/reference/research-archive/20260414-t164-session-channel-purpose.md` — original "cross this bridge" attempt at T=164: session-as-monoid (over kernel occupancy), session vs provenance (present permission vs past authorship), owner-vs-permission directionality (ownership flows down, delegation flows across), operad/cooperad interface duality (`tool_call` operadic, `watcher → reactor` cooperadic, channels cooperadic upstream of ingestion). The fabric in this T=175 note **builds on** that material rather than restating it; read t164 first if any of the lingo here feels under-defined.

## 10. The framing in one sentence (Sam, T=175)

mo:os is a **semantic functorial network over distributed compute**, where all components — hardware and programs alike — are considered categorically, and **the session is the centerpiece for human and AI inference**, while its relations both make it findable (G-direction adjunction observing the surfaces) and capable of writing the programs that pull the levers (F-direction adjunction emitting through leaves). Leaves are whichever fluid structure displays a value or answer to a session's open arguments at the moment the argument arrives.

That sentence is the doctrine. The five sections above are how the ontology enforces it.

---

## Status

**Draft, design only.** Five v3.14 grammar_fragments named; promotion deferred to rounds T=176–T=179. No envelopes from this note. Materialization order documented in §8.
