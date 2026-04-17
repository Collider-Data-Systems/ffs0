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
