# T=187 — Kernel Proper: session-as-actor, categorical backbone

> Opened T=167 (April 17, 2026). Canonical reference for `urn:moos:program:sam.t187-kernel-proper`.
> Replaces legacy "tnodes / programs / whatever" attempts at `my-tiny-data-collider.nl`.
> Each §M below is a *named law* (M1..M10) referenced by the T=187 sub-programs.

## 0. Context

`sam.t164-room-tying` tied the room together: ontology v3.7 (`channel.parent_channel_urn`, `tool_call.agent_urn`), WF19 session governance, wiring-proposer ADDed, Q5 folder nesting answered. With the room tied, the next program is the kernel proper — distributed, decoupled, categorically independent, replacing legacy attempts with a version done properly.

Spine of the doctrine:

> **Session is the actor.** It is a monoid (identity + composable claims); it carries the chrono `t`; it is the seat of t-hook checking; it bridges S4 (context / instruction) through S0 (log) to S2 (kernel). Provenance is not governance; the session *is* the governing actor.

This note states the math once. The implementation is decomposed into 10 sub-programs under `urn:moos:program:sam.t187-kernel-proper`, each referring back by §M anchor.

---

## M1. Session as monoid `(S, ∘, e)`

- **Identity** `e`: the empty session — no claims, no kernel occupancy, no local-`t` advancement.
- **Composition** `∘`: sequential claim of a kernel. Associativity `(s₁ ∘ s₂) ∘ s₃ = s₁ ∘ (s₂ ∘ s₃)` is the statement that session-scoped work is path-independent under rewrite replay.
- **Action on time**: `t_next = t_current + 1` per kernel-acknowledged rewrite issued inside the session. A session is the *only* legitimate advancer of its own local `t`.
- **Occupier**: a session has exactly one `agent_urn` bound via WF19 for any occupancy window. WF07 participants are not occupiers. One seat per session.

Consequence: any actor that wants to take governance over part of the graph must first *be* (or claim) a session. There is no governance without a session object to carry it.

## M2. Kernel as category `KernelCat`

- Objects: `GraphState` (the fold-image of the prefix log).
- Morphisms: `ADD`, `LINK`, `MUTATE`, `UNLINK` and their free sequential composition (a `program` is a morphism made of morphisms).
- Identity morphism: the no-op rewrite.
- Coherence laws CI-1..CI-5 (existing invariants): Church-Rosser confluence (CI-1), projection naturality (CI-2), identity stability (CI-3), replay determinism (CI-4), category stability (CI-5).

CI-1 is the statement that concurrent rewrites composing over a common prefix commute up to equivalence — i.e. the category is a commutative diagram over the log.

## M3. Fold is the catamorphism `fold: μLog → State`

- `μLog` is the free monoid on `Rewrite`: `[] | r :: rs`.
- `state(t) = fold(log[0..t])` is the fundamental ontology invariant.
- CI-4 (replay determinism) is exactly the statement that `fold` is well-defined on log-equivalence classes.
- **Exposure**: the kernel SHALL expose `fold` as an observable via `GET /fold?from=0&to=<t>`, returning the state projection for any prefix. This lets S4 consumers time-travel without side-effects on S0.

Without a public `fold`, S4 must reconstruct state privately — which means there are private category morphisms and the diagram is no longer commutative outside the kernel.

## M4. Session as monoid functor `S : SessionCat → KernelCat`

- `SessionCat` objects: session snapshots (`{agent_urn, local_t, context_urn, claims}`).
- `SessionCat` morphisms: session transitions (acquire-claim, release-claim, context-swap, advance-`t`).
- `S` maps session transitions to rewrite sequences in `KernelCat`.
- WF19 is the naturality square: for any session transition `σ: a → b`, the image `S(σ)` commutes with the occupancy relation. A session cannot advance its `t` without an acknowledged kernel rewrite; a kernel cannot record a rewrite without a sourcing session.

## M5. Strata as filtration `S0 ⊆ S1 ⊆ S2 ⊆ S3 ⊆ S4`

- `S0` log → `S1` ontology (types known) → `S2` infrastructure nodes → `S3` interaction nodes → `S4` projections.
- **"Type is semantics"**: each type carries its stratum; crossing a stratum is a *specific* WF, not a free operation. WF12 is ingestion `S0 → S1`. WF04 is projection `S2 → S4`. Crossings are **laws**, not implementation details.
- **Circularity** "S4 ↔ S0 ↔ S2" is resolved by direction: S4 (system_instruction, projection) READS from S0 and OVERLAYS S1; it never writes S0 directly. Write-back happens via rewrites issued by S2 actors (kernel, agent, session) who are the only parties with WF categories that touch S0.

The filtration is enforced in the operad registry: a rewrite whose src/tgt strata violate the filtration direction is rejected before it reaches `fold`.

## M6. t-hook as endofunctor on nodes

- Signature: `h: Node × Event → Option[Envelope]`.
- Current reactive engine (moos-kernel): `Watch` / `Guard` / `React` live on separate **reactor** nodes wired by WF17.
- T=187 promotion: every node MAY carry `t_hooks: [{event_shape, guard_ref, react_template}]` as an explicit property sub-structure. Reactor nodes remain valid (the old wiring); t-hooks become a first-class port on the owning node itself.
- This answers walk-question Q6 ("t-hooks — first-class or implicit?") as **first-class**, backwards-compatible.

Why a session "checks all t-hooks by type": the session is the morphism advancing local `t`; after each advance, it consults the hook registry for the affected node and applies any fired envelopes as part of the next morphism.

## M7. `system_instruction` at S4 projecting onto S1

- New type `system_instruction` (S4): human- or AI-authored context that overlays the ontology *without* modifying it.
- Projection is strictly read-only toward S1; the only way a `system_instruction` influences the graph is by being referenced in a session's `context_urn` field, which gates which WF categories the session may exercise.
- **Gödel / Turing note**: a `system_instruction` can reference its own session. Self-reference is *typed* (S4 referencing S2 occupier); incompleteness surfaces as `gate` failures (see M8), never as crashes or undefined behaviour.

This is how "a system_instruction places context over S1 while other AI and kernels sit at S2 or higher" — because S4 can only read S1 and influence through the session, not through a direct write.

## M8. `gate` as subobject classifier for incomplete data

- New type `gate`: a predicate node that permits or blocks a rewrite based on presence / shape of referenced data.
- Gates are the **explicit form of incompleteness**: a rewrite fails closed if a required gate is unsatisfied; the session sees the failure and can propose a completion rewrite to fill the hole.
- Generalises current `Guard` but lives on the rewrite pathway, not on reactor nodes.
- Categorically: a gate is a characteristic map `χ : State → Ω` where `Ω = {ok, blocked}`; fail-closed semantics make it the canonical subobject classifier for "well-formed-enough-to-apply".

## M9. Twin kernel as adjoint `F ⊣ G`

- Two kernels `K`, `K'` are **twins** when there exist functors `F : K → K'`, `G : K' → K` with `F` left-adjoint to `G`, and rewrite-sync is the unit / counit of the adjunction.
- Concretely: every `ADD` on `K` produces a pending `ADD` on `K'` via `F`; acknowledgements flow back via `G`. Twin-write compare-and-swap is the naturality condition on the adjunction.
- New type `twin_link`: a relation-node capturing the adjunction-pair URNs + sync mode (`eager | lazy | read-only`).

This is what "separate kernel code pull twin kernel" means: there is no distinguished primary; the adjoint pair is the doctrine.

## M10. HTTP/3 + QUIC as the colimit-compatible transport

The kernel is a category (M2) and its rewrites flow across a network. The transport is not semantics — but the transport's ordering and multiplexing properties determine whether the category's coherence laws (CI-1 through CI-5) can be upheld cheaply across the wire.

**Why HTTP/1.1 / HTTP/2 are wrong:**
- HTTP/1.1: sequential requests; a large ADD blocks MUTATE notifications — violates CI-1 spirit in distributed context.
- HTTP/2: multiplexed but TCP head-of-line blocking means a single packet loss stalls ALL streams. Under rewrite storms (e.g. twin-kernel sync during burst writes), this serialises what should be concurrent morphisms.

**Why QUIC (HTTP/3) is right:**
- QUIC streams are independent. A slow ADD stream does not block a MUTATE stream — concurrent morphisms stay concurrent across the wire. This is the transport-level preservation of the CI-1 Church-Rosser property.
- 0-RTT connection resumption: a session that briefly loses the kernel link can resume without a full TLS handshake, restoring occupancy (M1) at minimal cost.
- Connection migration: QUIC connections survive IP changes (mobile, failover). A session's `local_t` advancement does not reset on roaming — important for human-in-the-loop sessions.
- Unreliable datagrams (RFC 9221): optional fast-path for log-stream fan-out where occasional replay is acceptable.

**Categorical framing:**
- `transport_binding` is a new S2 node type that captures the wire-level protocol of a kernel endpoint: `protocol` ∈ `{http1.1, http2, http3-quic}`, optional `quic_addr` (UDP `host:port`).
- A kernel's endpoint node gets a `transport_binding` relation via WF16 (endpoint-to-kernel routing). The binding is immutable once the kernel is live; migration is a new ADD + LINK, not a MUTATE.
- For twin kernels (M9): the adjoint `F: K → K'` is carried on a QUIC stream. Each rewrite produces a QUIC stream frame; the counit (acknowledgement) travels back on the same QUIC connection. The naturality condition of the adjunction maps to the QUIC stream ordering guarantee *within* a single stream — which is preserved even when the connection migrates.
- For fold-endpoint (M3): the log stream `GET /fold?to=t` is SSE over HTTP/3. Each fold step (applied rewrite) is one event frame. QUIC's multiplexing means a client consuming the fold stream does not interfere with the kernel accepting new rewrites on the same connection.

**Implementation:**
- Library: `github.com/quic-go/quic-go` — most complete Go QUIC implementation (RFC 9000, 9114 HTTP/3, 9204 QPACK). Integrates as a `net.Listener` substitute; existing `http.Handler` code is unchanged.
- CF tunnel: Cloudflare already terminates HTTP/3 at its edge (`kernel.my-tiny-data-collider.nl`). For the public endpoint, no kernel change is needed — CF to kernel can remain HTTP/1.1 or HTTP/2 internally. For direct kernel-to-kernel (twin sync without CF), QUIC is the wire of choice.
- `moos-kernel/internal/transport/server.go`: add a `ServeQUIC(addr string, tlsCfg *tls.Config)` entry point alongside the existing `ServeHTTP`. The QUIC listener is spawned in addition to (not instead of) the TCP listener so existing tooling is not broken.
- Alt-Svc header: the kernel HTTP/1.1 + HTTP/2 response headers emit `Alt-Svc: h3=":<port>"` so HTTP/3-capable clients upgrade automatically.

**New type: `transport_binding` (S2)**

| property | mutability | note |
|----------|------------|------|
| `protocol` | immutable | `http1.1`, `http2`, `http3-quic` |
| `quic_addr` | immutable | UDP `host:port` for QUIC listener |
| `alt_svc` | immutable | `Alt-Svc` header value emitted |
| `status` | mutable | `active`, `deprecated` |

---

## Ontology additions (v3.8 when implemented)

| type_id | stratum | rationale | anchor |
|---------|---------|-----------|--------|
| `t_hook` | S2 | First-class hook port descriptor, owned-by a node | M6, Q6 |
| `gate` | S2 | Incomplete-data predicate, fail-closed | M8 |
| `twin_link` | S2 | Adjoint pair between kernels | M9 |
| `system_instruction` | S4 | Context overlay, S4 → S1 read-only projection | M7 |
| `chrono_t` | S2 | First-class local-`t` tick carrier (may land as `session.local_t` property — decided in `t187.session-chrono-t`) | M1 |
| `transport_binding` | S2 | Wire-level protocol binding for kernel endpoints (HTTP/1.1, HTTP/2, HTTP/3-QUIC) | M10 |

Existing types gaining sub-properties (not yet changed):
- `session` → `local_t`, `context_urn`, `t_hook_registry`
- `kernel` → `twin_of_urn`
- `program` → `succeeded_by_urn` (or a new WF for succession)

---

## T=187 sub-programs (placed in the HG)

The ten sub-programs below each get ADDed as a `program` node under `urn:moos:program:sam.t187.<suffix>` and linked via WF18 (`composes` / `composed-by`) to the T=187 parent. Dependencies are WF18 `depends-on` / `depended-by` LINKs between the sub-programs.

| URN suffix | Title | Depends on | Anchor | Deliverable |
|------------|-------|------------|--------|-------------|
| `t187.session-chrono-t` | Session.local_t as first-class carrier | — | M1 | Ontology entry; kernel `runtime.Apply` path that bumps `local_t` per session |
| `t187.t-hooks-first-class` | Node.t_hooks as explicit port substructure | `session-chrono-t` | M6, Q6 | New `t_hook` type; property sub-structure on all nodes; backwards-compat with reactor nodes |
| `t187.gates` | `gate` type + fail-closed pathway | `t-hooks-first-class` | M8 | New `gate` type; kernel validation step between validate-operad and apply-fold |
| `t187.system-instruction` | `system_instruction` S4 type + session.context_urn | — | M7 | New type; read-only projection semantics; no new WF |
| `t187.fold-endpoint` | Expose `fold` as HTTP observable + SSE over HTTP/3 | — | M3, M10 | `GET /fold?from=0&to=<t>`; SSE stream over QUIC for real-time fold steps |
| `t187.twin-kernel` | `twin_link` + adjoint sync protocol | `gates`, `http3-quic` | M9, M10 | New type; new WF for twin-write CAS; QUIC stream per rewrite; moos-router update |
| `t187.strata-enforcement` | Compile-time strata filtration | — | M5 | Validation pass in operad registry rejecting filtration-violating rewrites |
| `t187.answer-walk-Q1-Q4` | Answer walk Q1..Q4 (first kernel, purpose-vector wiring, 2-cell lift, agent-as-tool path) | — | — | `kb/research/20260417-t187-walk-answers-*.md` |
| `t187.categorical-contract` | Proof obligations for CI-1..CI-5 + monoid/functor/catamorphism claims | all above | M1..M10 | `kb/research/20260417-t187-categorical-contract.md` |
| `t187.twin-deploy-mtdc` | Deploy twin at `my-tiny-data-collider.nl` via CF tunnel | `twin-kernel` | M9, M10 | Ops note + kernel config; CF Alt-Svc HTTP/3 upgrade; twin acknowledgement |
| `t187.http3-quic` | HTTP/3 QUIC transport binding for kernel endpoints | — | M10 | `transport_binding` type; `ServeQUIC` in transport layer; `Alt-Svc` header; `quic-go` dep |

All ten ADDed as `program` nodes (sub-programs of T=187), WF18-linked, status `draft`. The program itself survives across sessions because it lives in the HG, not in a flat document.

---

## Open questions (resolved at plan time)

- **Q-PP1 (succession WF).** t164 → t187 is LINKed via WF18 with `scheduled-after` / `scheduled-before` ports. These ports are already defined on WF18 (src_types and tgt_types both include `program`), so no new WF needed today.
- **Q-PP2 (`chrono_t`).** Chosen shape this session: property `session.local_t` (simpler; delay node-type decision to sub-program `t187.session-chrono-t`).
- **Q-PP3 (prose vs diagrams).** This note is prose-only; diagrams deferred to `t187.categorical-contract`.
- **Q-PP4 (staged vs all-at-once).** All ten sub-programs ADDed in the opening envelope batch, status `draft`; dependency LINKs added in the same batch. Cheapest and keeps the HG the single source of truth for the roadmap.
- **Q-PP5 (HTTP/3 scope).** `t187.http3-quic` is dependency-free (pure transport, independent of data model). `t187.twin-kernel` and `t187.fold-endpoint` pick it up as a hard dependency so the twin-sync and fold-stream land on the right wire from the start. The CF edge already handles HTTP/3 externally; the kernel's QUIC listener is for direct kernel-to-kernel (twin) and for clients that bypass CF.

---

## Files that will be touched by sub-programs (reference)

- `moos-kernel/internal/fold/` — catamorphism lives here (M3)
- `moos-kernel/internal/reactive/engine.go` — Watch/Guard/React, joined (not replaced) by first-class t-hooks (M6)
- `moos-kernel/internal/kernel/runtime.go:317` — depth-1 reactive dispatch; reference point for gate insertion (M8)
- `moos-kernel/internal/graph/node.go` — `Node` struct; `t_hooks` lands as a sub-field
- `moos-kernel/internal/operad/` — stratum filtration validator (M5)
- `moos-router/internal/proxy/proxy.go` — twin routing (M9)
- `moos-kernel/internal/transport/server.go` — `ServeQUIC` entry point, `Alt-Svc` header (M10)
- `kb/superset/ontology.json` — S1 additions for v3.8

---

# T=168 enrichment — session liveness, admin governance, T-semantics, t-cone

> Appended T=168 (April 18, 2026). Extends M1..M10 with §M11..§M17 + 9 new spec-only sub-programs.
> Triggered by sam's correction of the session model:
>
> > "i think sessions are kernel bound and stay. its a matter of who occupies."
>
> And reframing:
>
> > "the session is a kernels security to have at least 1 user or a delegate control the runtime, to keep the network running. all other is on permission level re-writes from any point or role."
>
> T=168 action: **prose + HG materialisation only**. No kernel code.

## Vocabulary clarification before §M11

The ontology has **two** unrelated uses of the word *role*:

| Where | Type | Values | Purpose |
|-------|------|--------|---------|
| `session.role` | S2 enum | `occupier / observer / delegate` | **Seat state** on the kernel (WF19) |
| `role` (standalone) | S1 type | `superadmin / lead / executor / observer / hydrator / monitor` (`builtin_roles`) | **Permission bundle** attached via WF02 |

This collision is acknowledged; rename `session.role → session.seat_role` is deferred to sub-program `t187.session-role-rename` and is not part of this T=168 enrichment. Throughout §M11..§M17 the two are disambiguated by full qualification (`session.role` vs `role` (S1)).

Sam (`urn:moos:user:sam`) holds the S1 `role=superadmin` via WF02 — the per-MEMORY.md founder identity. "Admin" in this note means exactly *a user with WF02-bound superadmin S1 role*.

---

## §M11 — Session as kernel-liveness guarantee

**Statement.** A kernel is *eligible to accept rewrites* iff at least one WF19-LINKed session holds `session.role ∈ {occupier, delegate}`. Absent such a seat-holder, the kernel is live (process running, log readable) but refuses any rewrite except system-internal MUTATEs (e.g. `bumpSessionLocalT`, reactive-cascade propagation).

**Categorical reading.** `KernelCat` (M2) always has an identity morphism (the no-op rewrite). Its *non-identity* arrows, however, require a *source* — a session. Without a seat-holder, only the identity is available; the category is effectively frozen (all observable rewrites become the identity).

**Security consequence.** The graph cannot evolve without a permissioned seat-holder. This is the *liveness–security duality*: liveness requires a session, a session requires WF02 capability binding, therefore every graph evolution is auditably permissioned.

**Delegation path.** If the occupier steps away, a `delegate` can hold the seat via WF19 `transfers-to`. The delegate's S1 role (narrower than superadmin) determines which WFs they may exercise.

**Failure mode.** If all seats empty (all `session.role` → `observer`/unset), the kernel enters **idle state**. Recovery: an authenticated user+session re-opens via WF19 `opens-on`, and — if admin privileges are needed — the session's actor must hold S1 `superadmin` via WF02.

**Relation to M1.** M1 says "session is a monoid." §M11 specifies that *at least one non-identity element of that monoid must be bound to the kernel at all times for the kernel to remain operational*. §M11 is the liveness clause; M1 is the algebra.

---

## §M12 — Admin is WF02(superadmin); ontology authority

**Statement.** The ontology (`kb/superset/ontology.json`) is a special S1 artifact owned by the user holding `superadmin` role (S1) via WF02. Only sessions whose occupying user holds that S1 role may issue rewrites that touch:

- The ontology file itself (publish / MUTATE version)
- Node types that are themselves ontology-governed (`system_instruction`, `gate`, `twin_link`, `transport_binding`)
- Authority-scope-`kernel` property overrides on any node

**Enforcement pathway.** At rewrite validation (`operad.Validate`), every envelope is checked against the actor's session's bound capabilities (WF02-connected `capability` or `role` nodes). Admin-scope rewrites fail closed (via **M8 gates**) when the actor lacks `superadmin` via WF02. This is a composition of §M11 (session required) + M8 (gate classifier) + WF02 (capability binding) — no new mechanism, just the right arrangement of existing pieces.

**Manual-ops bridge.** Some admin responsibilities remain **off-graph** until programmatised:

- Cloudflare tunnel wiring (`kernel.my-tiny-data-collider.nl`, `api.my-tiny-data-collider.nl`)
- Kernel process start/stop on remote hosts (e.g. mtdc deploy)
- First-time ontology publication (bootstrapping — chicken-and-egg with §M16)

These are flagged via sketched `external_op` nodes (§M17) so the admin's t-cone (§M15) surfaces them as pending work.

---

## §M13 — Two timers: `t_local` (ticker) vs `T` (calendar)

Sam's simplification (verbatim):

> `t_local` is just a ticker to be sure that in session, where state is moved into s0 s1 and HG. Possible t-hooks in other nodes will 'pop-up'. The actual time, so presented in T, like always is a value to spot the relevant hooks that are 'open'.

**Reshape of M1's chrono-t claim:**

- **`t_local`** (session-scoped). A monotonic non-negative integer on each `session` node. Increments by 1 per kernel-acknowledged rewrite attributed to this session (directly — `env.Actor` is the session URN — or indirectly via agent-occupier lookup, see sub-program `t187.session-actor-agent-lookup`). **Zero semantic content beyond "this many rewrites happened in this session."** No cross-session comparability, no causal reasoning, no firing semantics. It is a heartbeat.

- **`T`** (global calendar). The moos-time day counter since T=0 (2025-11-01 00:00 CEST). Current T=168. Expressed as property values on nodes (`starts_t`, `deadline_t`, `fires_at`, `completed_t`, `target_t`, etc.). **T is the axis t-hooks fire against.** When a node enters the HG with a T-property, it "pops up" — its hooks evaluate against `current_T` and become open / pending / closed.

**Consequence.** `t_local` participates in replay (CI-4) as a per-session tick, nothing more. T participates in causal reasoning — `after_urn`, `before_urn`, `depends-on`, `deadline_t` all reference T-values. Keep them cleanly separated: code that touches `t_local` does not reason about time; code that reasons about time does not increment `t_local`.

**Existing T-properties in ontology** (on `program`, already present):
- `starts_t`, `target_t`, `deadline_t`, `completed_t`

The T-hook catalog (§M14) generalises T-property semantics to every node type.

**Relation to M1.** M1 stated "action on time: `t_next = t_current + 1`". §M13 clarifies that the `t` in that statement is `t_local` — a session heartbeat, not a calendar. The calendar T is separate, lives on nodes, and drives hooks.

---

## §M14 — T-hook predicate catalog (extends M6)

M6 defined `t_hook` as `{event_shape, guard_ref, react_template}` — the **when-something-changes** hook. §M14 adds the **when-T-crosses-a-threshold** dimension and enumerates the full catalog of natural-language project timing expressions → predicate shapes.

**Recommendation.** Keep `t_hook` as one node type; grow its `predicate` sub-structure to cover the catalog. Do not proliferate types. `predicate` is a typed discriminated union — each variant has its own fields.

### Catalog — time expressions → predicate shapes

| Natural language | Predicate variant | Fields | Example use |
|------------------|-------------------|--------|-------------|
| "starts on T=X" | `fires_at` | `at: int` | `starts_t` on program |
| "due by T=Y" | `closes_at` | `at: int` (open while `T ≤ at`) | `deadline_t` on program |
| "between X and Y" | `window` | `opens_at: int, closes_at: int` | release window |
| "after node N is done" | `after_urn` | `of_urn: URN, status: string` | `depends-on` resolution |
| "before node N" | `before_urn` | `of_urn: URN` | precedence |
| "concurrently with N" | `during_urn` | `of_urn: URN` | overlap (Allen's `during`) |
| "recurs every K days" | `recurs_every` | `period: int, from: int` | standup |
| "recurs on cron X" | `cron` | `spec: string` | weekly review (deferred — needs calendar type) |
| "lasts D days from start" | `duration` | `d: int, anchor_prop: string` | sprint length |
| "expires at T" | `expires_at` | `at: int` (permanently closed after) | token TTL |
| "reopens at T" | `reopens_at` | `at: int` (re-fires after close) | retrospective |
| "on event E" | `on_event` | `op: {ADD,LINK,MUTATE,UNLINK}, of_type: type_id` | M6 classic |
| "on property P set" | `on_prop_set` | `prop: string, of_urn: URN` | completeness gate |
| "on role change" | `on_role_change` | `from: role, to: role, of_urn: URN` | occupancy handover |
| "when permitted" | `when_capability` | `cap_urn: URN` (fires iff session has cap) | WF02 gate |
| "Nth instance" | `nth` | `n: int, of_prop: string` | Nth deployment |
| "first-of" | `first_of_prop` | `prop: string` | kickoff |

Each predicate variant has a canonical evaluation signature:

```
evaluate(current_T: int, state: GraphState, owner_urn: URN) → FiringState
```

Where `FiringState ∈ {open, closed, pending, satisfied}`.

### Firing algebra

- **Open** — predicate holds *right now*. Node is visible in the t-cone (§M15).
- **Closed** — predicate will not hold again (one-shot already fired; or past `expires_at`).
- **Pending** — predicate may hold in the future (`current_T < fires_at`).
- **Satisfied** — one-shot predicate that has already fired; retained for audit.

### Boolean composition

- `all_of: [predicate, ...]` — conjunction (all must be open for the aggregate to be open)
- `any_of: [predicate, ...]` — disjunction

Nested composition allowed. Kept explicit so replay (CI-4) is deterministic.

### CI-1 and CI-4 notes

- **CI-1 (Church-Rosser).** T-hook firing must be *commutative* with respect to concurrent rewrites on the same prefix — two concurrent envelopes that both trigger the same t-hook must yield the same react_template output regardless of order. Predicate evaluation is pure (function of `current_T` + state read-only), so this holds.
- **CI-4 (replay determinism).** Predicates are *deterministic*: `evaluate(T, S, owner)` is a total function. Replaying the log reproduces the exact same firing sequence.

---

## §M15 — t-cone: the occupier's view

**Definition.** The **t-cone** of a session at moment `T` is the sub-hypergraph of nodes whose t-hooks are currently *open* (per §M14) AND whose rewrite pathway is *permitted* by the session's occupying user's role+capability bundle (WF02).

Analogy: a *light-cone* in relativity — the set of events causally accessible from "here, now." In our setting, the t-cone is the set of nodes the session can meaningfully act on at the current calendar T.

**Projection formalism.** t-cone is a CI-2-compliant projection `S2 → S3`:

- **Source domain:** all S2 nodes with at least one attached `t_hook`.
- **Filter:** `any(t_hook.predicates).firing_state == open AND permitted_by(session.user.capabilities)`.
- **Corresponding M' (for CI-2):** identity. Viewing the t-cone does not mutate S0; it is a read-only projection. Changes to the t-cone happen *because* S0 received a rewrite that crossed a hook threshold, not because the t-cone was consulted.

**Endpoint (deferred to sub-program `t187.t-cone-projection`).**

```
GET /t-cone?session=<urn>&at=<T>
```

Returns the filtered sub-hypergraph. Since `fold` is already exposed (M3), implementation is: start from `fold(log[0..current])`, filter nodes by hook-openness + permission.

**As "admin's view on important programs or tasks."** Sam's phrasing maps exactly to the t-cone: the current set of nodes with open hooks that the admin's session is permitted to act on. The t-cone IS the admin dashboard. No separate "dashboard" abstraction needed.

**Nesting / composition.** A session's t-cone at `T=168` is a subgraph of its t-cone at `T=167` intersected with hooks that became open between T=167 and T=168. Time advances monotonically; what becomes "no longer open" is explicit via the `closed`/`satisfied` transition.

---

## §M16 — Ontology publication (recommended mechanism)

**Requirement.** User-kernels (future collaborators, other workstations) must be able to download the ontology published by the admin. Source of truth is admin's kernel; user kernels pull read-only.

**Recommended mechanism** (smallest new surface; spec-only sketches for now):

1. **Wire:** reuse M9 `twin_link` with `sync_mode: read-only`. No new transport. Admin kernel = source; user kernel = read-only twin for the ontology node(s). The existing adjoint `F ⊣ G` (M9) carries `ADD` of new ontology-publication nodes through the counit back to the user kernel.
2. **Provenance:** add a new S1-meta node type `ontology_publication` — a claim carrying:
   - `version: string` (e.g. `"3.9"`)
   - `published_by_urn: URN` — must resolve to a user with `superadmin` via WF02
   - `published_at: datetime`
   - `content_hash: string` (sha256 of `ontology.json` bytes)
   - `signed_by: URN` (placeholder for future crypto signing)
   - `supersedes_urn: URN` (previous publication node)
3. **Flow:**
   (a) admin edits `ontology.json` locally;
   (b) admin session ADDs an `ontology_publication` node with the new hash;
   (c) twin-linked user kernels observe the new publication node via the adjoint;
   (d) user kernel pulls the file content through a sibling endpoint `GET /ontology?version=X` and verifies `content_hash`.

**Why this shape.** The publication *claim* (the node) is auditable inside the HG; the bytes flow out-of-band through a content-addressed endpoint. Twin-link handles the "tell me about new publications" subscription cheaply. Separating claim from bytes keeps the HG small and the sync flexible.

**Alternative considered:** a bespoke `WF20-ontology-sync` category. **Rejected for now** — the read-only `twin_link` adjoint already covers the wire semantics; a new WF adds ontology surface without adding power.

**Deferred to later sprint** (within `t187.ontology-publication` sub-program): signing, conflict resolution (divergent admins), rollback semantics, version migration rewrites.

**Chicken-and-egg note.** The first publication of the ontology onto a new user-kernel is a bootstrapping problem (the user-kernel needs an ontology to validate the `ontology_publication` node type). Bootstrapping is an `external_op` (§M17) — admin delivers the first ontology out-of-band (git clone, scp, etc.), after which subsequent versions flow via the above mechanism.

---

## §M17 — `external_op` stub (supports §M12 manual-ops)

Small auxiliary S2 type to keep manual admin work visible in the HG until it is programmatised.

**Type sketch (spec-only, not landed in ontology.json this session):**

| property | mutability | note |
|----------|------------|------|
| `title` | immutable | e.g. "CF tunnel wiring for kernel.my-tiny-data-collider.nl" |
| `command_hint` | mutable | human-readable "what to run" (free text, not parseable) |
| `responsible_urn` | immutable | must be a user with S1 `superadmin` via WF02 |
| `status` | mutable | `pending`, `in-progress`, `done`, `obsolete` |
| `automates_via_urn` | mutable | URN of a future `program` that, once completed, replaces this stub |
| `deadline_t` | mutable | optional — if set, feeds §M14 `closes_at` predicate |

**Use.** The admin's session-seat t-cone (§M15) surfaces pending `external_op` nodes as work to do. When the admin completes the action (by hand), they MUTATE `status → done`. When the action becomes programmatic, a new `program` is linked via `automates_via_urn` and the stub's `status → obsolete`.

**Examples we'd want right now:**
- `external_op:mtdc-kernel-start` — start the moos-kernel process at my-tiny-data-collider.nl (completes `twin-deploy-mtdc`)
- `external_op:cf-tunnel-api-mtdc` — CF tunnel for `api.my-tiny-data-collider.nl`
- `external_op:ontology-bootstrap-mtdc` — first ontology.json delivery to mtdc (§M16 chicken-and-egg)

These are **not materialised this session** — the type itself is not in ontology.json yet. Listed here as spec input for the `external-op-stub` sub-program.

---

## Updated T=187 sub-program table — 9 new (total 20)

| Suffix | §M / Origin | Depends on | Nature (this session) |
|--------|-------------|------------|----------------------|
| `session-liveness` | §M11 | session-chrono-t (existing, completed) | Spec + gate definition |
| `admin-capability-enforcement` | §M12 | gates, session-liveness | Spec; downstream gate implementations |
| `t-local-simplification` | §M13 | — | Spec + proposal to retire M1 wording of "chrono-t" |
| `t-hook-predicate-catalog` | §M14 | t-hooks-first-class (existing, completed) | Spec (predicate shapes + firing algebra) |
| `t-cone-projection` | §M15 | t-hook-predicate-catalog | Spec + endpoint design |
| `ontology-publication` | §M16 | twin-kernel (existing, completed) | Spec + `ontology_publication` type sketch |
| `external-op-stub` | §M17 | — | Spec + `external_op` type sketch |
| `session-actor-agent-lookup` | Q3 specslist | session-chrono-t | `bumpSessionLocalT` agent→session lookup gap in runtime.go |
| `session-role-rename` | Q-knob-1 deferral | — | Decide + execute `session.role` → `session.seat_role` rename |

All 9 ADDed with `status=draft`, `starts_t=168`, and scope pointing back to this note's §M anchor.

---

## Deliverable trail (T=168)

1. This appended section — §M11..§M17 + updated sub-program table ✓
2. Standalone FAQ note — `kb/research/20260418-t168-session-kernel-bound.md` (ratified session model)
3. Ontology doc annotations on session / role / capability types (no new types, no version bump)
4. `running-state.md` — rewritten active-session block + spec-enrichment backlog
5. HG hygiene — t164 `session.role` MUTATE to `observer`
6. HG materialisation — atomic batch ADDs the 9 new sub-programs + WF18 `composes-by/composed-of` LINKs + dependency LINKs

**No kernel code changes this session.**
