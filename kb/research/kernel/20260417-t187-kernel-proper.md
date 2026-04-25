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

**T=175 update — sub-program `session-actor-agent-lookup` closing.** The inferred-session path of `bumpSessionLocalT` (in moos-kernel `runtime.go`) currently fails to increment `session.local_t` when an envelope arrives without explicit `env.session_urn`, even though the kernel reverse-resolves the session via `has-occupant` lookup. Surfaced concretely by Guido at T=174 ~00:45 CEST during Phase A: `session:sam.laptop-cowork-workspace.local_t = 0` after 24 acknowledged rewrites because Cowork emits without explicit `session_urn`. Fix is small (~5–10 lines runtime.go + tests) and lands as Phase E.2 of `~/.claude/plans/valiant-kindling-sunrise.md`: increment `local_t` whenever the kernel resolves an envelope to a session, regardless of explicit-vs-inferred path. Multi-session agents (e.g. Wolfram on `sam.kernel-proper` + `sam.mvp-delivery`) still require explicit `env.session_urn` or fail loud — single-session agents tick automatically. After PR merge + 5-kernel rebuild, this sub-program closes; §M13 heartbeat becomes universally reliable across all agents and all leaves (the latter per `kb/research/session/20260424-t175-program-authoring-fabric.md` §5).

**T=175 ~16:15 CEST closure — sub-program `session-actor-agent-lookup` CLOSED on hp-laptop.** PR [#33](https://github.com/Collider-Data-Systems/moos-kernel/pull/33) merged as [`b1de4ff`](https://github.com/Collider-Data-Systems/moos-kernel/commit/b1de4ff); README PR [#32](https://github.com/Collider-Data-Systems/moos-kernel/pull/32) merged as `e295016` (master tip). Hp-laptop kernel rebuilt from master tip, restarted via the (T=173-fixed) `start_federation_laptop.ps1` launcher; single PID 4788 on `:8000/:8080`; replay clean (`log_len=632` preserved across restart, runtime `ontology_version: 3.13.0`, `t_day=175`). Verification batch: 3 inferred-session ADDs (`urn:moos:ki:t175-m13-verify.{guido,cowork,ag-laptop}` at log_seq 625–627, actors `agent:claude-code.hp-laptop` / `agent:claude-cowork.hp-laptop` / `agent:antigravity.hp-laptop` respectively, no `env.session_urn` set). Kernel emitted 3 self-MUTATEs at log_seq 628–630 (actor `kernel:hp-laptop.primary`, `field=local_t`) atomically with the user envelopes — observable proof of `bumpSessionLocalT` running on the inferred path. Result: `session:sam.governance.local_t` 0 → 1; `session:sam.laptop-cowork-workspace.local_t` 0 → 1; `session:sam.laptop-moos-diary.local_t` 0 → 1. The `ResolveSessionForEnvelope`-based unified path (single resolver shared between §M11 gate-check and `bumpSessionLocalT`) is design-clean — no drift possible between liveness and heartbeat code-paths. **Z440 4-kernel rebuild + verification still open** under sam's hand on Wolfram lane.

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
2. Standalone FAQ note — `dev/reference/research-archive/20260418-t168-session-kernel-bound.md` (ratified session model)
3. Ontology doc annotations on session / role / capability types (no new types, no version bump)
4. `running-state.md` — rewritten active-session block + spec-enrichment backlog
5. HG hygiene — t164 `session.role` MUTATE to `observer`
6. HG materialisation — atomic batch ADDs the 9 new sub-programs + WF18 `composes-by/composed-of` LINKs + dependency LINKs

**No kernel code changes this session.**

---

# T=168 round-3 addendum — session generalization (§M18..§M20)

> Picks up after the v3.9 baseline audit side-step. The v3.9 audit added the type primitives this section needs (`view_filter` S2, `harness` S2, `skill` S1); §M18..§M20 describe how session binds them.

## §M18 — Session as generalized workspace anchor

A session is simultaneously:
1. **Kernel seat** (§M11 liveness, §M13 timers) — the previously-specified role.
2. **Workspace anchor** (new) — carrier of the occupant's t-cone view (§M15), pinned URNs, mounted tools, view preferences.

The v3.8 session had just `role`, `local_t`, `context_urn`, `status`, `turn_count`, `started_at`. v3.9 renamed `role → seat_role` (non-destructive). §M18 adds:

**New properties (candidate — not yet active in v3.9 ontology):**
- `view_prefs` (mutable, owner) — scalar UI preferences only: `{sort_by, fold_depth, density, theme}`. Anything topological (pinned URNs, filter predicates) is a relation, per `topology_property_boundary`.

**New relations (candidate — carried as grammar_fragments pending promotion):**
- `session --pins-urn / pinned-by-session--> <URN>` — a session can pin any node into its attention. Arbitrary target type (generic topology port).
- `session --filtered-by / filters-session--> view_filter` — a session can have zero or more named view_filter nodes scoping its t-cone projection.

**Why relations not lists-in-property.** The `topology_property_boundary` rule says "If the information involves two or more nodes, it is a relation." A pin to a program URN is a relation between session and program; it must not be a property array. This is what distinguishes the carpet from a record database.

**agent_session merge.** v3.9 deprecated `agent_session`. Its salvageable fields map to session:
- `agent_session.agent_urn` → session's occupant relation (§M19).
- `agent_session.role` (lead|active|listening) — discarded; session `seat_role` + occupant covers it.
- `agent_session.focus` port — retained on session (attention surface).
- `agent_session.reads` port — discarded (no matching in-port anywhere, per audit §A5).

**§M15 t-cone composition.** The v3.8 t-cone was a raw projection of "nodes with open t-hooks the occupier's capability grants access to." §M18 composes it with session.view_filter relations: `t-cone(session, T) = { n ∈ open_hooks(T) ∩ WF02_visible(session.occupant) | ∀ vf ∈ session.filtered-by. vf.predicate(n) }`.

## §M19 — Occupant as first-class

Occupant = the principal actually driving the session. Distinct from `seat_role` (a scalar describing session's place in kernel occupancy).

**New relation (candidate):** `session --has-occupant / is-occupant-of--> agent | user`

WF19 extends to carry this port pair:
- `src_types: session` (unchanged)
- `tgt_types: [kernel, session, agent_session, user, agent]` (v3.9 adds user + agent as tgt_types for has-occupant — grammar_fragment D19.1)

The occupant's `capability` set (WF02) bounds what rewrites the session may submit. Kernel gate-check at Validate: `session.submit_rewrite(r) allowed IFF r.category ∈ capabilities(session.occupant) ∧ session.seat_role ∈ {occupier, delegate}`.

**Rotation.** Changing occupant = MUTATE of the has-occupant LINK's target_urn (one edge, atomic). Not ADD+UNLINK. This preserves session identity (CI-3) across occupant rotation.

**Concrete path.** Sam's direction:
- Session `sam.claude-code-hp-laptop.t167` currently has occupant = `urn:moos:agent:claude-code.hp-laptop` (this process).
- Future: rotate to `urn:moos:agent:sam.claude-code-desktop` when the Claude Code Desktop app is wired in.
- Further future: rotate to a homemade agent URN running locally, connected via MCP.

## §M20 — Tool-mounting and recursive tool construction

Occupants need tools. Tools themselves are agents. The relation that binds them:

**New relation (candidate):** `session --mounts-tool / tool-mounted-in-session--> agent`

The tool-agent's invocation surface is declared on the agent node:
- `agent.invocation_protocol ∈ {"stdio", "mcp", "http"}` (property candidate)
- Harness for runtime: `agent --runs-in / runs--> harness` (v3.9 `harness` type, §D6)

When the occupant invokes a mounted tool, the tool-call node (existing interaction type) records `tool_call.agent_urn = mounted_agent`, rows for argument/result flow through existing WF11 (tool invocation).

**Recursive tool construction.** Tools that make tools.

**New relation (candidate):** `agent --constructs / constructed-by--> agent`

CI-invariant (stated, not formally verified in v3.9): nested tool construction must preserve rewrite isolation. Each constructed tool has its own capability scope; the constructor's capabilities do NOT auto-inherit to the constructed tool. This prevents privilege escalation via recursive construction (a low-privileged constructor cannot produce a high-privileged tool).

**Canonical first mount — Claude CLI.** The Claude Code CLI binary is the canonical first tool. Its invocation_protocol = "stdio". A session's occupant can spawn it as a sub-tool for:
- Generating code (which the occupant then applies as an edit).
- Running a sub-prompt against a different model (Opus for analysis, Haiku for bulk transforms).
- Producing a new tool binary that becomes a further mount.

**Caveat.** v3.9 does NOT implement the Claude CLI mounting — only the doctrine. The `cli-as-tool-protocol` and `recursive-tool-construction` sub-programs (below) carry implementation.

## Grammar fragments this round adds (as governance_proposal candidates for WF20)

Per the S1-superset doctrine (`dev/reference/research-archive/20260418-t168-s1-superset-doctrine.md`), §M18..§M20 propose S1 extensions. These are NOT landed in v3.9 ontology.json; they are described here, ready to be ADDed as `grammar_fragment` nodes in a later round once the WF20 promotion flow has been exercised:

| Fragment | Kind | Shape |
|----------|------|-------|
| `D19.1-session-has-occupant` | wf_clause | WF19 tgt_types += [user, agent]; src_port alias `has-occupant` / tgt_port alias `is-occupant-of` |
| `D19.2-session-view-prefs` | property | session.view_prefs: object (sort_by, fold_depth, density, theme); authority: owner |
| `D19.3-session-pins-urn` | port | session `pins-urn / pinned-by-session` — topology port color; tgt: any |
| `D19.4-session-filtered-by` | port | session `filtered-by / filters-session` — semantic port; tgt: view_filter |
| `D20.1-session-mounts-tool` | port | session `mounts-tool / tool-mounted-in-session`; tgt: agent |
| `D20.2-agent-invocation-protocol` | property | agent.invocation_protocol: enum(stdio, mcp, http); mutability: mutable |
| `D20.3-agent-runs-in-harness` | port | agent `runs-in / runs`; tgt: harness |
| `D20.4-agent-constructs-agent` | port | agent `constructs / constructed-by`; tgt: agent; with CI note on capability isolation |

Pipeline: each fragment becomes an ADD+MUTATE chain via WF20 — first `status=proposed` (ADD), admin review, then `promoted` or `rejected` (MUTATE). When all D19.*/D20.* fragments reach `merged`, the ontology bumps to v3.10 carrying them as live grammar.

## Updated T=187 sub-program table — 6 new (total 26)

| Suffix | §M | Depends on | Nature (this session) |
|--------|----|------------|----------------------|
| `session-generalization` | §M18 | — (umbrella) | Spec: merge `agent_session` into `session`; view/occupant/tool-mount faculties |
| `session-view-holder` | §M18 | t-hook-predicate-catalog (§M14), v3.9 view_filter type | Spec: view_filter usage + pins-urn / filtered-by relation shapes |
| `session-occupant-relation` | §M19 | session-liveness | Spec: WF19 extension for has-occupant / is-occupant-of; WF02 capability-bound gate |
| `tool-mounting` | §M20 | session-occupant-relation, v3.9 harness type | Spec: session mounts-tool → agent; invocation_protocol property |
| `cli-as-tool-protocol` | §M20 | tool-mounting | Spec: canonical Claude CLI stdio-tool mount pattern |
| `recursive-tool-construction` | §M20 | cli-as-tool-protocol | Spec: agent constructs agent relation + capability-isolation CI |

All 6 ADDed with `status=draft`, `starts_t=168`, scope pointing back to this note's §M anchor.

Dependency DAG:
```
session-generalization (umbrella)
   │
   ├─ session-view-holder     (→ M14 + v3.9 view_filter)
   ├─ session-occupant-relation (→ session-liveness)
   │      │
   │      └─ tool-mounting     (→ v3.9 harness)
   │             │
   │             └─ cli-as-tool-protocol
   │                    │
   │                    └─ recursive-tool-construction
```

## Deliverable trail (T=168 round 3, this section)

1. This appended section — §M18..§M20 + 8 grammar-fragment proposals + updated sub-program table (20 → 26) ✓
2. HG materialisation — 6 new `program` ADDs + 6 WF18 composes LINKs + 5 WF18 depends-on LINKs
3. `running-state.md` — update sub-program count to 26, add round-3 entry

**No kernel code changes this round. No ontology.json changes this round (v3.9 is the baseline; §M18..§M20 extensions are captured as grammar-fragment candidates awaiting WF20 promotion).**

---

# T=168 round 4: sub-program merge + session-layer group-topology clarification

> Appended T=168 (April 18, 2026). Reduces the 20-→-26 explosion from rounds 1+3 to a coherent 19 live sub-programs named by what they monitor, and formalises that the session-layer is a per-kernel group-topology stratification.

## §M21 — Session-layer is group-topology, stratified by kernel

The session layer divides not by ownership (`owner_urn`) but by **kernel occupancy**. Each kernel's WF19-LINKed sessions form its own **occupancy ledger**; at any instant, at most one carries `seat_role=occupier`. Sessions across different kernels are topologically disjoint — they do not compose under the session monoid (§M1), because M1's composition `∘` is "sequential kernel claims" and requires a common kernel. The **group-topology** phrasing (sam's framing): the top layer is the disjoint union

```
Sessions = ⊔_{k ∈ Kernels} Sessions_k
```

where each `Sessions_k` is a monoid (§M1) and the disjoint union carries the stratification. Ownership is a property on each session (`session`-has-`owner_urn`) — a **provenance stamp**, not a topological axis. The consequence: per-kernel liveness (§M11), per-kernel occupancy transfer (§M19), per-kernel t-cone (§M15).

**Consequence for session creation.** A new session is ADDed only when:
- A new user enters a kernel they haven't claimed before, OR
- A new agent begins occupying a kernel it has never occupied before, OR
- An explicit design choice demands separation (time-limited delegate, isolated subroutine).

**1-per-kernel floor.** For every materialised kernel `k ∈ Kernels`, there must exist at least one `s ∈ Sessions_k` with a valid WF19 `opens-on/occupied-by` LINK. Otherwise the kernel is "dark" — visible in the HG but with no session-attributed rewrite path. At T=168 round 4 (second pass) we merged the three historical T-day-suffixed sessions into two canonical ones — `urn:moos:session:sam.claude-code-hp-laptop` (occupier) and `urn:moos:session:sam.claude-code-hp-z440` (observer) — one per kernel, no T-day in URN. The three historical nodes (`.t164`, `.t167`, `.t168`) remain in the HG as provenance but are no longer WF19-LINKed.

## §M22 — Naming scope: drop the T-ref prefix (programs AND sessions)

The `t187.<suffix>` and `t168.<suffix>` URN prefixes were a round-marker convention useful for attributing creation-time provenance. As sub-programs consolidate and round-markers lose meaning (a sub-program merged across rounds has no single "starting round"), the prefix is dropped in favour of **names that state what the node monitors or represents**. The same rule applies to sessions: the `.t<N>` T-day suffix was a creation-time label, not a lifetime bound, and serves no topological purpose once sessions are permanent kernel-bound nodes (§M11, §M21). Post-round-4 convention:

**Programs.** Named by monitoring scope:

| Scope (what it monitors) | URN suffix |
|--------------------------|------------|
| seat_role + occupant + cap gate | `session-occupancy` |
| local_t + actor resolution | `session-timeline` |
| view_filter + pins + t-cone | `session-view` |
| mounts-tool + invocation + construction | `session-tools` |
| t_hook.predicate algebra | `hook-predicates` |
| ontology_publication events | `ontology-publication-prg` |
| external_op nodes | `external-op` |

**Sessions.** Named by `<user>.<agent>-<kernel-short>` — no T-day:

| Live session URN | Kernel |
|------------------|--------|
| `urn:moos:session:sam.claude-code-hp-laptop` | `kernel:hp-laptop.primary` |
| `urn:moos:session:sam.claude-code-hp-z440` | `kernel:hp-z440.primary` |

The `t187.` prefix is retained on original pre-T=168 sub-programs (`t187.http3-quic`, `t187.strata-enforcement`, etc.) since they were materialised under that namespace and renaming without value would be churn. Same principle for historical sessions — `.t164 / .t167 / .t168` nodes remain in the HG as provenance, but are no longer WF19-LINKed and don't participate in the live occupancy ledger.

## §M23 — Session property redundancy (v3.9 deprecations)

Two `session` properties are marked `deprecated: true` in v3.9 (slated for removal in v3.10):
- `session.status` (enum active/closed/abandoned) — subsumed by `seat_role` + permanent-session model. Sessions don't close; they become `observer`.
- `session.turn_count` — subsumed by `local_t` (§M13 authoritative heartbeat). `turn_count` was never used by the v3.8+ runtime.

New merged sessions (`sam.claude-code-hp-laptop`, `sam.claude-code-hp-z440`) are ADDed with `seat_role` + `local_t` + `started_at` only; historical `.t164 / .t167 / .t168` nodes keep both fields until v3.10 migration.

## Merge map — round 4

14 draft sub-programs from rounds 1+3 → 7 merged sub-programs named by what they monitor. `session-role-rename` marked completed (v3.9 audit delivered it). `session-chrono-t` retained as standalone (active, pre-round-1).

| Merged URN | Merges (archived, status=archived) |
|------------|-----------------------------------|
| `session-occupancy` | session-liveness + admin-capability-enforcement + session-occupant-relation |
| `session-timeline` | t-local-simplification + session-actor-agent-lookup |
| `session-view` | t-cone-projection + session-generalization + session-view-holder |
| `session-tools` | tool-mounting + cli-as-tool-protocol + recursive-tool-construction |
| `hook-predicates` | t-hook-predicate-catalog (rename only) |
| `ontology-publication-prg` | t187.ontology-publication (rename only; `-prg` suffix to avoid collision with `urn:moos:program:sam.ontology-publication-v3.9` carrier) |
| `external-op` | external-op-stub (rename only) |

### Post-merge depends-on chain (5 WF18 depends-on relations)

- `session-timeline` → `session-occupancy` (actor resolution needs seat-model)
- `session-view` → `hook-predicates` (t-cone uses predicate algebra)
- `session-view` → `session-timeline` (t-cone bounded by local_t window)
- `session-tools` → `session-occupancy` (tools need occupant)
- `ontology-publication-prg` → `hook-predicates` (publishing manifests cite predicates)

### Post-merge live sub-program count

Active WF18 `composes` from `sam.t187-kernel-proper`: **19** (11 originals + 7 merged + 1 completed `session-role-rename`). Down from 26 mid-round-3.

## Deliverable trail (T=168 round 4, this section)

### Pass A — sub-program merge (14 drafts → 7)

1. §M21..§M23 doctrine (this section) + merge map + post-merge depends-on chain ✓
2. HG materialisation:
   - 1 MUTATE `sam.t187.session-role-rename` status → completed
   - 7 ADD merged sub-programs (session-occupancy / -timeline / -view / -tools + hook-predicates + ontology-publication-prg + external-op)
   - 7 LINK WF18 composes from `t187-kernel-proper` to each
   - 5 LINK WF18 depends-on between merged sub-programs
   - 26 UNLINK (14 old composes + 12 old depends-on)
   - 28 MUTATE (14 status→archived + 14 scope pointers)
3. Ontology v3.9: `session.status` + `session.turn_count` marked `deprecated: true` (no version bump; redundancy cleanup is consistent with v3.9 baseline audit philosophy)

### Pass B — session merge (3 historical T-day sessions → 2 canonical per-kernel)

Directive (sam, T=168): "merge the sessions i want the exact amount of sessions with correct names replacing these." Apply §M22 naming rule (drop T-ref) to sessions themselves.

1. ADD `urn:moos:session:sam.claude-code-hp-laptop` (seat_role=occupier, fresh local_t=0)
2. ADD `urn:moos:session:sam.claude-code-hp-z440` (seat_role=observer, fresh local_t=0)
3. LINK WF19 `opens-on/occupied-by` for both to their respective kernels
4. MUTATE `sam.claude-code-hp-laptop.t167` seat_role → observer (hand off)
5. UNLINK old WF19 opens-on relations: `rel:t164-session-opens-on-kernel`, `rel:t167.session.opens-on.kernel`, `rel:wf19.hp-z440.t168.opens-on`

Post-state: exactly 2 WF19-LINKed sessions (one per kernel), 3 historical nodes retained as provenance with no WF19 LINK.

### Pass C — running-state.md + research cross-refs

- `running-state.md` — occupancy table reduced to 2 rows (canonical URNs only); historical sessions listed in a sub-section; key URNs block updated
- `kb/research/*.md` — post-merge session URN conventions propagated; historical URN references kept where they document historical rewrites

**No kernel code changes this round.**
