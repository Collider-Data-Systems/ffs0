# T=187 delivery clock — IRL-time anchoring of the kernel-proper program

> T=168 (April 18, 2026). Round 8 research note.
> Companion to `20260418-t168-s0-operadic-layer.md` and `20260418-t168-irl-to-hg-pipeline.md`.

---

## §1 — T=187 as IRL-calendar anchor

The T-counter in mo:os is a **calendar day counter** starting at T=0 = 2025-11-01. It is not a logical clock or sequence number — it is IRL time, discretised to days. T=168 is today: April 18, 2026 (confirmed: Nov 1 + 168 days = April 18).

This gives every T-value in the kernel a precise calendar date. The delivery window for `urn:moos:program:sam.t187-kernel-proper` becomes:

| T-value | Calendar date | Event |
|---------|--------------|-------|
| T=168 | 2026-04-18 | Today — round 8 authored |
| **T=187** | **2026-05-07** | **Delivery window opens** — t_hook fires, `delivery_phase → "in-delivery"` |
| T=195 | 2026-05-15 | `session-chrono-t` sprint checkpoint |
| T=200 | 2026-05-20 | `system-instruction` sprint checkpoint |
| T=205 | 2026-05-25 | `strata-enforcement` sprint checkpoint |
| T=210 | 2026-05-30 | `fold-endpoint` sprint checkpoint |
| T=215 | 2026-06-04 | `http3-quic` sprint checkpoint |
| T=220 | 2026-06-09 | `twin-deploy-mtdc` checkpoint — window closes |
| T=240 | 2026-06-29 | `v310-delivery` target — 19 grammar_fragments promoted |
| T=250 | 2026-07-09 | `wiring-proposer` target — HDC-grounded auto-wiring active |

The full T=187→T=220 delivery window is **33 calendar days** (May 7 – June 9, 2026). Each sub-program has a named checkpoint inside that window, visualisable via the t-cone projection (`GET /t-cone?session=…&at=T`).

---

## §2 — The delivery clock cascade (HG as spec-level CI/CD)

The central architectural move: **t_hooks replace an external scheduler**. Instead of a Gantt chart or a CI pipeline running outside the HG, every delivery milestone is represented as a `t_hook` node inside the HG. When the kernel's internal T-counter ticks past a `fires_at` value, the hook's `react_template` fires — in-kernel, atomic, log-is-truth.

```
T=187 tick
  └─→ t_hook:sam.t187.delivery-opens fires
         └─→ MUTATE t187-kernel-proper.delivery_phase → "in-delivery"

T=195 tick
  └─→ t_hook:sam.t187.checkpoint.session-chrono-t fires
         └─→ MUTATE t187.session-chrono-t.status → "checkpoint"

T=200 tick
  └─→ t_hook:sam.t187.checkpoint.system-instruction fires
         └─→ MUTATE t187.system-instruction.status → "checkpoint"

... (T=205, T=210, T=215)

T=220 tick
  └─→ t_hook:sam.t187.checkpoint.twin-deploy-mtdc fires
         └─→ MUTATE t187.twin-deploy-mtdc.status → "checkpoint"
  └─→ t_hook:sam.t187.delivery-closes fires
         └─→ MUTATE t187-kernel-proper.delivery_phase → "closed"
  └─→ t_hook:sam.v310-delivery.startable evaluates:
         fires_at=220 ✓ AND t187-kernel-proper.status=completed?
         → if yes: MUTATE v310-delivery.status → "startable"
```

The HG **observes its own schedule**. The fold endpoint (`GET /fold?to=T`) replays this in any session. The t-cone (`GET /t-cone?session=…&at=T`) surfaces the open hooks and startable programs for the session occupant.

A checkpoint MUTATE is not a completion certificate — it signals "the calendar says this work should be done by now." Actual completion (`status → completed`) is still a manual rewrite by an authorized actor. The t_hook provides the IRL-time nudge; the human (or agent occupant) closes it.

---

## §3 — The "startable" pattern

### The problem

A program at `status=draft` is ambiguous: it might be immediately actionable (no dependencies, starts_t ≤ T) or deeply blocked (unsatisfied dependencies, hasn't started yet). The t-cone cannot distinguish without a live predicate evaluator. Surfacing "what can I start right now?" requires a separate query across all programs, their depends-on links, and their starts_t values.

### The solution: `status="startable"` + canonical t_hook

Add `"startable"` as a valid `program.status` enum value (grammar_fragment `v310-14-startable-status`). The transition `draft → startable` is driven by a **canonical compound t_hook** with §M14's `all_of` predicate:

```
predicate:
  kind: all_of
  predicates:
    - { kind: fires_at, t: P.starts_t }            ← T-counter gate
    - { kind: after_urn,                             ← per dependency D
        urn: D.urn,
        prop: status,
        value: completed }                           ← one clause per D
react_template:
  rewrite_type: MUTATE
  node_urn: P.urn
  properties: { status: { value: "startable" } }
```

### Independent vs dependent nodes

**Independent node** (no `depends-on` links): the `all_of` reduces to a single `fires_at` clause. The compound predicate is trivially satisfied as soon as `T ≥ starts_t`. This is the degenerate (arity=1) case.

**Dependent node** (N dependencies): the `all_of` carries `fires_at + N × after_urn`. All must hold simultaneously. The node cannot become startable until the last dependency completes AND the calendar is ready.

### The succession chain in round 8

```
sam.t187-kernel-proper  (active, no startable hook — it IS the anchor)
  │
  │  WF18 depends-on
  ▼
sam.v310-delivery        (draft → startable when t187-kernel-proper completes ∧ T≥220)
  │
  │  WF18 depends-on
  ▼
sam.wiring-proposer      (draft → startable when v310-delivery ∧ t187-kernel-proper complete ∧ T≥240)
```

The t-cone for the session occupant at T=220 will surface `v310-delivery` as orange/startable if `t187-kernel-proper.status=completed`. At T=240 it surfaces `wiring-proposer`. Neither requires a scheduler query — the t_hook did the work.

### Why "startable" and not a gate

A `gate` node (§M8) is fail-closed — rewrites are blocked until the gate opens. "Startable" is advisory — it tells the occupant "this is now ready for you," but does not block anything. The distinction: gates enforce kernel invariants; startable informs occupant cognition. Both are necessary; they operate at different layers of the stack.

---

## §4 — The dependency graph: T=187 as anchor node

`urn:moos:program:sam.t187-kernel-proper` is now the **root of a successor dependency tree**. Future programs declare `WF18 depends-on → t187-kernel-proper` to signal "this requires a stable, delivered kernel baseline."

```
                    ┌─────────────────────────────────────────┐
                    │  urn:moos:program:sam.t187-kernel-proper │
                    │  target_t=220 · delivery_phase: cascade  │
                    │  calendar: 2026-05-07 → 2026-06-09       │
                    └──────────────────┬──────────────────────┘
                                       │ WF18 composes (sub-programs)
               ┌───────────────────────┼───────────────────────┐
               │                       │                       │
          session-*              t187.*-* programs         twin-deploy-mtdc
          hook-predicates        (checkpoint t_hooks)      (external_op gates)
          session-tools ...
                                       │ WF18 composed-by (successor)
                    ┌──────────────────┴──────────────────────┐
                    │  urn:moos:program:sam.v310-delivery      │
                    │  starts_t=220 · target_t=240             │
                    │  calendar: 2026-06-09 → 2026-06-29       │
                    │  startable hook: fires_at=220            │
                    │  + t187-kernel-proper.status=completed   │
                    └──────────────────┬──────────────────────┘
                                       │ WF18 depends-on
                    ┌──────────────────┴──────────────────────┐
                    │  urn:moos:program:sam.wiring-proposer    │
                    │  starts_t=240 · target_t=250             │
                    │  calendar: 2026-06-29 → 2026-07-09       │
                    │  startable hook: fires_at=240            │
                    │  + both predecessors completed           │
                    └─────────────────────────────────────────┘
```

### IRL leaves: external_op nodes

Three IRL-condition gates hang off `twin-deploy-mtdc` and `v310-delivery`. They are `external_op` nodes (§M17 S2 type) — manual work that must happen before the automated path can proceed:

| URN | Deadline | Blocks |
|-----|----------|--------|
| `external_op:sam.mtdc-kernel-start` | T=187 | twin_link activation |
| `external_op:sam.cf-tunnel-api-mtdc` | T=187 | twin_link remote endpoint |
| `external_op:sam.ontology-bootstrap-mtdc` | T=220 | v3.10 promotion across twin |

These are visible in the t-cone as `status=pending` items with `deadline_t` in the near future. The occupant sees them as action items alongside sub-program checkpoints.

---

## §5 — Wiring-proposer doctrine (T=164 §8 item A, finally materialised)

The wiring-proposer was designed at T=164 as "the program that closes the open-world wiring problem." Its design:

**Input:** the current HG (fold state) + a `purpose` node carrying a target_state (which may include an HDC gradient vector, per the walk Q1–Q4 answers).

**Mechanism:** For each node N in the HG, compute HDC cosine similarity between N's encoding (T=160 engine: `φ(N) = encode(N.type_id) ⊗ encode(N.urn)`) and the purpose's `gradient_vector`. Rank candidate LINKs by similarity delta: `Δsim(N, M, rel) = sim(φ(N) ⊕ rel, purpose.gradient_vector)`.

**Output:** a set of `governance_proposal` nodes (WF13) — one per top-K candidate LINK — each carrying: `subject_urn, object_urn, wf_category, similarity_score, rationale`. The occupant (or admin) ratifies or rejects each proposal.

**Key insight from Q2 (walk answers):** the purpose vector is the gradient in φ-space pointing from current state toward desired state. The wiring-proposer is literally a **gradient descent step in graph space** — it proposes the LINK that moves the HG most toward the occupant's purpose.

**Dependency on v3.10:** the wiring-proposer wants canonical types (crosswalk, port_binding, etc.) to be live grammar before proposing them as LINK targets. Hence it depends on `v310-delivery` completing.

**Inert until hooked:** `wiring-proposer` is an `ADD`-ed program node (status=draft). It becomes operational when:
1. A `t_hook` watcher is attached (fires_at=250 or on purpose-MUTATE)
2. The HDC engine endpoint is wired (`fold-endpoint` + HDC routes)
3. The HG has enough nodes to generate meaningful similarity rankings (~200+ nodes)

The third condition is nearly met already (158 nodes at round 8 start; 179+ after this round).

---

## §6 — WF20 promotion ceremony sketch

The 19 grammar_fragments at `status=proposed` are the input. The output is v3.10 — a bump of ontology.json from v3.9 to v3.10 where each promoted fragment becomes live grammar.

**The ceremony per fragment:**
1. Admin reviews fragment specification (reads evidence_urns, checks coherence with existing WFs)
2. MUTATE `grammar_fragment.status → "promoted"` (WF20 authority: admin)
3. Ontology author edits `ontology.json` to incorporate the new type/port/property
4. `ontology_publication` node ADDed (v310-11 type, once promoted) carrying the version bump and content_hash
5. MUTATE `grammar_fragment.status → "merged"` (marks it as absorbed)

**Packaging with dsl (v310-10):** related fragments can be grouped into a `dsl` node:
- `session-workspace-dsl` bundles: d19-2, d19-3, d19-4, d20-1, d20-3, d20-4 (all session/agent port fragments)
- `evaluation-dsl` bundles: v310-7, v310-8, v310-9 (benchmark/evaluation/dataset)
- The `startable-status-dsl` bundles: v310-14 with the canonical t_hook shape

Activation: MUTATE `dsl.status → "active"` is atomic for all bundled fragments (WF20-2 candidate).

**Estimated v3.10 type additions** (if all 19 promote):
- 6 new S1 types: port_binding, crosswalk, dsl, ontology_publication + purpose-as-arity-2, plus any from d14-1 predicates
- 4 new S2 types: benchmark, evaluation, dataset + external_op (already sketched)
- ~12 new port pairs across session/agent/twin_link/view_filter
- 2 new predicate_shapes: cascade_stable, sheaf_laplacian_inconsistent
- 3 new properties: fiber completeness, Ricci curvature pair, view_prefs
- 1 new WF clause: WF19 tgt_types extension (d19-1)
- 1 program.status enum value: "startable"

---

## §7 — Open questions inherited

1. **S0 purpose arity** (v310-13): should `phi_current` and `phi_target` be slots (taking S1 state-bearing nodes) rather than scalar properties? If so, purpose is an arity-2 endo-op — its composition `purpose ∘ purpose` is a longer-horizon purpose. Candidate v3.10 / v4.0 work.

2. **Threading as WF vs projection**: S0 threading (slot-filling) is currently specified as a read-time projection over WF18/WF19/WF02 relations. Does any threading semantic need a NEW WF category? Current stance: no (threading is a reading frame, not a rewrite). Revisit if a threading-specific constraint surfaces (e.g., slot arity enforcement at ADD time).

3. **CI-6 three-views proof**: Procrustes rotation = data-migration functor Δ_F = geometric morphism f*. Proved by construction in the IRL→HG pipeline note §5. Formal verification requires: (a) the crosswalk type lands in v3.10, (b) a test case in moos-kernel's `categorical-contract` sub-program that checks round-trip coherence of Procrustes error ↔ sheaf section norm.

4. **Predicate evaluator implementation**: the `hook-predicates` sub-program (status=draft, target_t=215) specifies the §M14 predicate algebra. The `all_of` compound predicate needed for startable t_hooks requires the evaluator to run compound checks at T-tick time. This is the gating implementation task for round 8's architectural claims.

5. **wiring-proposer activation**: what triggers the first wiring proposal run? Candidates: (a) manual admin MUTATE; (b) t_hook with `fires_at=250`; (c) on-purpose-MUTATE event (whenever sam MUTATEs a purpose node, the proposer runs). Option (c) is the most elegant (reactive wiring aligned with intent change) but requires the reactive engine + HDC cosine endpoint both running.

---

## Cross-references

- `20260418-t168-irl-to-hg-pipeline.md` — §3.4 HDC tight frames; §4.2 sheaf Laplacian; grounds v310-7..10
- `20260418-t168-s0-operadic-layer.md` — S0 op-nodes; purpose arity open question §1
- `20260417-t187-kernel-proper.md` §M14..§M20 — t_hook predicate catalog; session workspace; tool-mounting
- `20260418-t187-categorical-contract.md` — CI-1..CI-5 contracts; M9 twin loop prevention
- `20260418-t187-walk-answers-Q1-Q4.md` — Q2 purpose as gradient; Q4 agent-as-tool via Yoneda

## One-line summary

> T=187 = May 7, 2026: the delivery clock anchor that t_hooks the kernel-proper program, checkpoints 6 sub-programs across T=195..220, gates two successor programs via "startable" compound predicates, and surfaces all open IRL actions through the t-cone — making the HG its own spec-level CI/CD pipeline.
