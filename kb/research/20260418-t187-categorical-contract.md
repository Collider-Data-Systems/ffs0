---
title: T=187 categorical contract — proof obligations CI-1..CI-5 and M1..M10
t_day: 168
program: urn:moos:program:sam.t187-kernel-proper
sub_program: urn:moos:program:sam.t187.categorical-contract
status: completed
---

## CI Invariants

**CI-1 (Church-Rosser / Confluence)**: Concurrent rewrites on disjoint-URN nodes can be applied in any order and produce the same final state. Proof obligation: for any two envelopes e1, e2 with disjoint affected-URN sets, `fold([e1,e2]) == fold([e2,e1])`. Currently: fold.Evaluate is purely functional — state is a value, not mutable. Rewrites on node A do not touch node B's Properties map. The monoid of rewrites is locally confluent on disjoint URNs. Status: **holds by construction** (fold is pure; maps are value-copied).

**CI-2 (Projection registry)**: Every node's stratum is determined by its type_id at ADD time and never changes. Proof obligation: `registry.NodeTypes[typeID].Stratum` is immutable after ontology load; no MUTATE can change a node's TypeID; strata filtration (CI-5 / M5) is monotone. Status: **holds** — TypeID is set at ADD and no MUTATE field changes TypeID (fold.applyMUTATE only touches Properties).

**CI-3 (Identity stability)**: A node's URN is its identity and never changes. Proof obligation: no rewrite modifies a URN after ADD. Status: **holds** — Envelope.NodeURN is only used in ADD; MUTATE uses TargetURN as a lookup key, not a modification target.

**CI-4 (Replay determinism)**: `fold(log[0..t])` produces the same GraphState for any t, in any execution environment. Proof obligation: fold.Replay is deterministic (no randomness, no wall-clock dependence). Applied rewrites depend only on prior state. Status: **holds** — Replay calls Evaluate sequentially; all values are deterministic given the log.

**CI-5 (Strata filtration)**: `S0 ⊆ S1 ⊆ S2 ⊆ S3 ⊆ S4` is a monotone filtration. S4 nodes cannot LINK to S0/S1/S2 nodes. Proof obligation: ValidateStrataLink enforces this for every LINK rewrite. Status: **holds** — implemented in `operad/validate.go:ValidateStrataLink`, called in `kernel/runtime.go:Apply` before fold.Evaluate. Strata parsed via `graph.ParseStratum`; S4→S0/S1/S2 returns error.

## M Laws (proof obligations)

**M1 (Session as monoid)**: (S, ∘, e) — identity=empty session, composition=sequential claim over kernel, `local_t` advances per kernel-acknowledged rewrite. Obligation: associativity of session composition; `local_t` strictly monotone. Status: `bumpSessionLocalT` called after every Apply; WF19 MUTATE persisted and broadcast. Associativity: sessions compose by appending log entries; log is a free monoid (free associativity). **Holds by log structure.**

**M2 (Kernel as category)**: Ob=GraphState, Mor=Rewrite, composition=ApplyProgram. Identity morphism=no-op (SeedIfAbsent on existing node). Obligation: identity law (`apply(no-op, S) = S`); associativity of sequential application. Status: SeedIfAbsent absorbs ErrNodeExists/ErrRelationExists → state unchanged. ApplyProgram is sequential fold. **Holds by fold purity.**

**M3 (Fold as catamorphism)**: `fold: μLog → State`, where μLog is the free monoid on Rewrite. Exposed as `GET /fold?to=<t>`. Obligation: fold is a monoid homomorphism (`fold(a++b) = fold(b)(fold(a))`). Status: fold.Replay implements this sequentially. The time-travel endpoint reuses the same Replay function. **Holds by construction.**

**M4 (Session as monoid functor)**: `F: SessionCat → KernelCat`. WF19 is the naturality square. Obligation: session claims commute with kernel rewrites via WF19. Status: WF19 mutate_scope includes local_t, context_urn; the kernel is the authority. Naturality: a WF19 MUTATE of session.local_t happens after (not during) the actor's rewrite — the commutativity holds because the bump is a SEPARATE rewrite appended to the log. **Holds modulo ordering: bump is post-hoc.**

**M5 (Strata filtration)**: See CI-5. Additional obligation for WF src/tgt type-lists: `ValidateStrataLink` enforces `wfSpec.SrcTypes` and `TgtTypes` when non-empty. **Holds** — both rule 1 (S4 direction) and rule 2 (type-list) enforced.

**M6 (t-hook as endofunctor)**: `h: Node × Event → Option[Envelope]`. The t_hook node is an endofunctor on the category of nodes — it maps a node's events to optional proposed rewrites. Obligation: t_hook firing is pure (no side effects beyond the returned Envelope). Status: `reactive.Engine.Evaluate` Pass 2 reads state (pure), builds proposal (pure), returns. The proposal is applied by `applyReactiveLocked` — same as reactor path. **Holds** — t_hook evaluation is referentially transparent.

**M7 (system_instruction as natural transformation)**: S4 context overlay → S1 ontology read-only. Obligation: system_instruction cannot write S0 or S1; it can only be referenced via `session.context_urn`. Status: system_instruction has no S0 ports; its `projected-to` port targets S3/S4 nodes only (strata filtration enforced by CI-5). Currently ontology-only (no code path yet). **Obligation satisfied by type declaration + strata filtration.**

**M8 (gate as subobject classifier)**: A gate predicate is a characteristic morphism `χ: targetNode → Ω` where Ω = {pass, fail}. Fail-closed. Obligation: gate evaluation is total (always returns bool); missing guard node returns false (fail-closed). Status: `checkGatesLocked` and `EvaluatePredicate` cover all predicate types including `field_set` (M8 completeness). Missing gate node → error returned. **Holds.**

**M9 (twin kernels as adjoint)**: `F ⊣ G`: F forwards rewrites (eager POST to /twin/ingest), G receives and applies. Unit/counit = the sync handshake. Obligation: F ∘ G ≅ id (the rewrite arrives at the twin and is applied faithfully). Status: `twinPost` forwards `[]Envelope{env}` verbatim; `/twin/ingest` calls `ApplyProgram` on the same envelopes. Idempotency: fold.applyADD returns ErrNodeExists on duplicate → graceful. Loop prevention by convention (one side eager, one read-only). **Holds modulo loop prevention (deferred to twin-deploy-mtdc).**

**M10 (QUIC as colimit-compatible transport)**: QUIC streams are independent — concurrent rewrites on disjoint URNs over separate streams preserve CI-1. Obligation: stream independence = no shared mutable state between streams. Status: each QUIC stream becomes an independent HTTP request to the kernel; the kernel's lock (`rt.mu`) serializes Apply calls — CI-1 holds because the kernel is the serialization point, not the transport. **Holds by kernel lock discipline.**

---

All ten M-laws and five CI-invariants hold under the current implementation; the remaining obligation is twin loop-prevention (M9 loop, deferred) and a formal proof of M4 naturality (ordering is post-hoc, not concurrent).
