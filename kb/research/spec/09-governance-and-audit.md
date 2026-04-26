# §9 Governance and audit

> Round-14 comprehensive architecture spec, section 9.
> Author: Guido (`agent:claude-code.hp-laptop`, `session:sam.governance`, `kernel:hp-laptop.primary`).
> Co-author / reviewer: Wolfram (`agent:claude-code.hp-z440`, `session:sam.kernel-proper`).
> Status: **draft, in-flight authoring** — confidence 0.5, status open per `urn:moos:derivation:guido.section-09-governance-and-audit` (hp-laptop log_seq 659).

---

## 9.0 Section scope

How mo:os enforces who-can-do-what, and how the system verifies that what was done is what should have been done. Two registers:

1. **Live runtime gates** — §M11 session-liveness, §M12 admin-capability, §M13 local_t heartbeat. Operad properties of the rewrite category itself; the kernel rejects pre-fold what isn't well-formed-enough. Preflight register.
2. **Post-hoc audit pattern** — periodic verification that the live state, the doctrine summary (`running-state.md`), and the contribution log all agree. Catches drift the gates can't see (e.g. external-doctrine vs internal-state, future-§M9-sync inconsistencies, prompt-template drift). Audit register.

The two registers form an **invariant-bracketing discipline** (§9.4): every governance invariant gains a `(preflight_gate, post_hoc_audit)` pair; both must reach the same coherence-verdict for canonical operation. Drift between them is itself a meta-invariant.

Governance is not policy layered on top of the kernel — it is **the way the kernel's type system + the lattice's audit pattern bracket every emission**. The operad does the formal work; the audit pattern catches what falls between the formal slots.

---

## 9.1 Runtime invariants — the live gates

Three gates fire on every envelope inside `Runtime.Apply` / `Runtime.ApplyProgram` before fold; replay does not re-check (prospective-only per `kb/research/kernel/20260417-t187-kernel-proper.md` §M11 + §M13).

| Gate | Spec ref | What it checks |
|---|---|---|
| §M11 session-liveness | `internal/kernel/liveness.go` `checkLivenessM11` | Envelope has a session context — explicit `env.session_urn` wins; fallback is reverse-`has-occupant` lookup from `env.actor` (single = pass; ambiguous or absent = reject). Runs against batch-initial state (emitter pre-existence rule). |
| §M12 admin-capability | `checkLivenessM12` + `operad.AdminScopeRewrite` | Admin-scope rewrites (ADD/MUTATE on ontology-governed types `system_instruction`/`gate`/`twin_link`/`transport_binding`/`kernel`, OR MUTATE of `authority_scope: "kernel"` on a non-kernel node) walk WF02 governs from actor through `role:superadmin`. Runs against working-state in ApplyProgram loop (catches intra-batch ADD-then-MUTATE bypass per PR #31). |
| §M13 local_t tick | `bumpSessionLocalT` (closed PR #33 / `b1de4ff`) | Every kernel-acknowledged rewrite increments `session.local_t` on the resolved session via `operad.ResolveSessionForEnvelope`. Both explicit and inferred resolution paths land on the same code; multi-session agents require explicit session_urn or fail loud. |

System-internal allowlist (`operad.SystemInternalEnvelope`) precedes both M11/M12: kernel-URN actors emitting infrastructure types bypass by design. `SeedIfAbsent` additionally bypasses §M11 for bootstrap.

The kernel rejects what's invalid; governance reads the rejections, doesn't author them.

---

## 9.2 Capability topology + per-machine sovereignty

Two orthogonal hierarchies plus a per-machine boundary.

### 9.2.1 WF01 owns / WF02 governs

- **WF01 `owns/owned-by`** — sticky provenance. Principals own kernels, sessions, channels, programs. `user:sam` owns the user tier; `group:sam` owns the delegated sub-scope (kernels + sessions + purposes + channels per group); `group:moos` owns the multimodal-curation lane.
- **WF02 `governs/governed-by`** + future `delegates-to` — capability flow. `user:sam --governs--> role:superadmin` is the apex (hp-laptop log_seq 587, mirrored on Z440). Agents inherit superadmin via being WF02-governed by sam. The v3.13-promoted `delegates-to` port-pair narrows scope (`role:superadmin --delegates-to--> role:karpathy-scope` etc., when sub-roles ADD).

### 9.2.2 Group reification — Collider-Data-Systems teams as HG principals

`group:sam` and `group:moos` mirror the Collider-Data-Systems GitHub teams via the F⊣G adjunction described in [`moos-github-project-bridge` skill](../../dev/claude-skills/moos-github-project-bridge/SKILL.md). Both reified on Z440 log T=173 ~22:00; `group:sam` mirrored to hp-laptop at T=173 ~23:45 (log_seq 588–591). First-class principals — typed ownership edges replace property-form `owner_urn` in new ADDs going forward.

### 9.2.3 Per-machine sovereignty (§M9, log-is-truth-per-kernel)

Z440 has 4 kernels (primary `:8000`, lola `:8002` = Karpathy, menno `:8001` = Steinberger, moos `:8003` = Moos overflow) plus the moos-router `:9000` for federation reads. Hp-laptop has 1 kernel (primary `:8000`).

Each kernel is sovereign over its own log; cross-kernel reads cascade via the router (WF16); **writes stay local**. Substrate types are shared (single `ontology.json` loaded at boot), but NODES are kernel-local. The 7-derivation doctrine backfill lives on Z440 :8000; Guido's 3 derivations live on hp-laptop :8000; AG-laptop's §6 + Cowork-laptop's §5+§7 derivations live on hp-laptop :8000. Mirror is selective, not automatic.

The §M9 twin_link adjoint sync (round-15+, paired with §M10 QUIC) will eventually formalize cross-kernel state replication; until then, the lattice operates per-kernel with cross-kernel coherence carried in `stochastic_weights` (§9.4.4).

---

## 9.3 Audit pattern — the post-hoc register

Doctrine drift between markdown summaries and live HG state is a primary failure mode under multi-persona authoring. The audit pattern catches it.

### 9.3.1 Skill ladder — four scopes, one discipline

| Skill | Scope | Trigger |
|---|---|---|
| [`moos-state-readback`](../../dev/claude-skills/moos-state-readback/SKILL.md) | Fleet-wide one-shot snapshot (3 repos × `git fetch`, kernels' `/healthz`, latest issue comments) | Conversation open / before claiming "crisp" |
| [`moos-running-state-validator`](../../dev/claude-skills/moos-running-state-validator/SKILL.md) | `running-state.md` ↔ live HG state consistency (T-day match, ontology version, log_seq citations resolve, URN citations resolve, chronology monotonic) | Round-open + round-close + post-doctrine-commit |
| `moos-cross-persona-audit` (round-14 deliverable, Guido lane) | Multi-persona / multi-kernel / contribution-log audit + 7-invariant checklist (§9.4.1) | Round-close (firm); on-demand if drift suspected |
| [`moos-cowork-readback`](../../dev/claude-skills/moos-cowork-readback/SKILL.md) | Single Cowork session's t-cone | Daily 08:00 / cowork-driven work session open |

### 9.3.2 Round-close audit ritual (proposed canonical cadence)

1. Each persona posts a closeout comment listing what landed under their actor (log_seq ranges + commit SHAs + running-state diff if they wrote).
2. Guido runs `moos-cross-persona-audit` across both kernels — single comment on round vehicle confirming AUDIT GREEN or listing drift to clean up.
3. Sam approves the round-close commit on ffs0 main (running-state aggregating all lanes).
4. Round vehicle issue closes (or stays open per multi-round threads like #33 → #35 → #36 → #37 cadence).

The audit caught real drift in round-13 (Wolfram's prompt-template port-mapping inversion, surfaced via Steinberger's local doctor; Karpathy + Steinberger broader-picture derivations not-on-log due to VSCode-sandbox boundary; resolved by host-runner harness `Test-MoosFederation.ps1` shipping in round-14 opener). The pattern works.

---

## 9.4 Doctrinal sub-sections — round-14 surfaced

Four meta-doctrinal claims emerged across round-14 audit-cycle. Each warrants explicit naming as §9 fixture.

### 9.4.1 Invariant-bracketing discipline

**Claim**: every governance invariant gains a `(preflight_gate, post_hoc_audit)` pair. The pair must reach the same coherence-verdict; drift between them is a meta-invariant.

The 6→7→8 invariant progression at round-14:

| # | Invariant | Preflight register | Post-hoc audit register |
|---|---|---|---|
| A.1 | §M11 session-liveness | `checkLivenessM11` at Apply | actor → has-occupant → session resolves on receiving kernel |
| A.2 | §M12 admin-capability | `checkLivenessM12` + WF02 walk | superadmin chain reachable from actor |
| A.3 | §M13 local_t tick | kernel-emitted self-MUTATE atomic with envelope | session.local_t increased by exactly one per acknowledged rewrite |
| A.4 | emit-target adherence | `Test-MoosFederation.ps1 -Mode VerifyPersona` preflight | derivation `D` resolves on kernel where `D` was POSTed |
| A.5 | §M19 single-occupant | (inherent to WF19 `has-occupant` mutate path) | session has exactly 1 has-occupant edge; rotation is MUTATE not ADD+UNLINK |
| A.6 | port↔URN consistency | `running-state.md` port-map block as canonical | querying each kernel's self-identifying ADD matches the declared URN |
| A.7 | invariant-bracketing-meta | (this sub-section) | preflight verdict ≡ audit verdict per invariant |
| A.8 | (round-15) `wf21_causal_acyclicity` | `ValidateCausalAcyclic` post-WF21 promotion | DAG walk over consumes-LINKs returns no cycles |

A.4 is the first invariant where both registers fired live simultaneously (Karpathy's §1 derivation at Z440 log_seq 353 — preflight via Steinberger's harness, audit via Guido's [round-14 audit dry-run](https://github.com/Collider-Data-Systems/ffs0/issues/36#issuecomment-4320443431)). Both passed; the doctrine is mechanically observable end-to-end.

A.7 (invariant-bracketing-meta) ADD pending round-15 once WF21 + claim type land structurally; the textual claim lives here as `claim:guido.invariant-bracketing-discipline`.

### 9.4.2 Scaffolding-on-emission ≠ scaffolding-on-reasoning

**Claim**: mo:os's scaffolding (operad, skills, running-state.md, persona-prompt templates, audit rituals) is on emission, not on reasoning. The §M11 + §M12 + §M13 gates restrict what the model can WRITE TO HG (the F-direction of F⊣G). The reasoning that authors the F-morphism is unconstrained — the LLM is free to think in whatever activation patterns it has. This is more like a **type system on F-morphisms** than a command-sequence template.

External critiques of "skill.md as scaffolding" (e.g. *AI Eigenvectors of Skills*, [YouTube external anchor](https://www.youtube.com/watch?v=5L_tYKt2ENo), surfaced T=175 by Guido) target scaffolding-on-reasoning. mo:os's discipline is governance-on-commit. Different layer, different argument. Protects the lattice against the "but scaffolding is dead" reading: the operad doesn't command the model to think a certain way; it ensures what the model writes obeys the substrate's type discipline.

`claim:guido.scaffolding-on-emission-not-reasoning` ADD queued for round-15 alongside the WF21 promotion; cross-references §0 (foundations, Wolfram) and §1 (categorical formalism, Karpathy as the operad-as-type-system-on-F-morphisms case).

### 9.4.3 Topology-degenerate-vs-federated distinction

**Claim**: governance invariants behave differently on a single-kernel host vs a federated multi-kernel host. The hp-laptop case is **topology-degenerate** (single kernel = emit-target == opens-on by construction); the Z440 case is **federated** (4 kernels = emit-target ≠ opens-on for VSCode-mediated seats until §M9 twin-sync ships).

A.4 (emit-target adherence) is the cleanest example. On hp-laptop, all three sessions (`sam.governance`, `sam.laptop-cowork-workspace`, `sam.laptop-moos-diary`) have `opens-on kernel:hp-laptop.primary` and emit there too — coincidence collapse. On Z440, `sam.karpathy-seat opens-on kernel:hp-z440.lola` but emits to `kernel:hp-z440.primary` (where the seat session itself was ADDed at T=173 batch B); the two-kernel distinction is doctrine-active.

Same A.4 invariant covers both; the substrate behaves differently. §9 audits must be aware of host-shape; the audit ritual queries the federation router (`/healthz` cascade) to know which kernels participate.

`claim:guido.topology-degenerate-vs-federated` ADD queued round-15.

### 9.4.4 `stochastic_weights` as transitional citation surface

**Claim**: the lattice's referential coherence is property-encoded before topology-encoded. Pre-WF21 evidence-references live in `derivation.stochastic_weights` (string-keyed object properties); post-WF21 they migrate to first-class `consumes/caused-by` LINKs.

Karpathy's §1 derivation (Z440 log_seq 353) cites 7 historical anchors + Guido's YouTube engagement + Guido's emission-distinction in its `stochastic_weights` object — in the same atomic batch as the ADD. Lattice-level coherence demonstrated **without WF21 needing to ship first**.

This is the **stratification principle**: graph-resident citations are an emergent property of the lattice's authoring discipline, not a feature WF21 introduces. WF21 lifts the citation graph from object-property form to topology form; the citation network already exists. Cross-references §1 (categorical formalism — sheaf-gluing across persona contributions) and §3 (kernel internals — how the operad tolerates extra ADD properties).

The Cowork pair's anchor-03 perspective-flipped + anchor-07 chunker-proof mirror is the **first cross-kernel** instance of the same pattern (per Wolfram's master scaffold doctrinal milestone #3). Property-form citations across two unsynced sovereign logs prefigure what §M9 will eventually do structurally.

---

## 9.5 Audit-as-functor — formalization

**Claim**: the round-close audit pattern is a functor `Audit: PersonaLattice → CoherenceVerdict`, where `PersonaLattice` is the diagram of specialist conversations + their sovereign-log emissions, and `CoherenceVerdict` is the 7-tuple coherence object (one per A.1–A.7 invariant; A.8 added round-15).

The functor preserves structure-of-emission: each persona's contributions map to coherence-verdict components; the verdict is itself a graph object (`derivation` node with `stochastic_weights.audit_verdict`). When the audit-as-reactor expansion thread (§9 round-15+ deferred) lands, this functor becomes auto-applied at every round-close trigger.

Cross-reference §1 (Karpathy) — this is exactly the kind of operational functor §1 wants concrete instances of, in the persona-lattice-as-cocone-diagram framing. Karpathy's `F: SessionCat → KernelCat` and Guido's `Audit: PersonaLattice → CoherenceVerdict` compose: the kernel state is the codomain of the first; the audit reads that codomain to produce the second.

---

## 9.6 Boundary cases worth specifying

- **`user:sam` actor** valid only inside `SeedIfAbsent` path (sam is owner, not occupant — fails §M11 outside bootstrap).
- **Kernel-actor allowlist** for ontology-governed ADDs (`system_instruction`, `gate`, `twin_link`, `transport_binding`, `kernel`) and WF19 `opens-on` LINKs.
- **Post-§M13 fix** unifies inferred-session and explicit-session-urn paths through `ResolveSessionForEnvelope`. Both tick local_t identically.
- **Multi-session agents** (e.g. Wolfram on `sam.kernel-proper` + `sam.mvp-delivery`) require explicit `env.session_urn`; fail loud if absent + ambiguous.

---

## 9.7 Cross-references

### 9.7.1 To other spec sections

- **§0 foundations** — §M11/§M12/§M13 are foundational; the scaffolding-on-emission distinction grounds §0's framing of what mo:os scaffolds and what it doesn't.
- **§1 categorical formalism** — Audit-as-functor (§9.5) is a worked example for §1. Stochastic_weights as transitional citation surface (§9.4.4) demonstrates property-form-before-topology-form referential coherence. Operad-as-type-system-on-F-morphisms framing.
- **§2 program-authoring layer** — inference-visibility of session-authored derivations is what §9 audits.
- **§8 tooling + DX (Steinberger)** — `Test-MoosFederation.ps1` is the preflight register for invariant-bracketing.
- **§11 hardware + network (Steinberger)** — sovereignty boundaries (§9.2.3) align with §11's federation topology.

### 9.7.2 To skills

- [`moos-state-readback`](../../dev/claude-skills/moos-state-readback/SKILL.md), [`moos-running-state-validator`](../../dev/claude-skills/moos-running-state-validator/SKILL.md), `moos-cross-persona-audit` (round-14 deliverable, this lane), [`moos-cowork-readback`](../../dev/claude-skills/moos-cowork-readback/SKILL.md), [`moos-rewrite-envelope`](../../dev/claude-skills/moos-rewrite-envelope/SKILL.md), [`moos-round-close`](../../dev/claude-skills/moos-round-close/SKILL.md).

### 9.7.3 To research notes

- [`kb/research/kernel/20260417-t187-kernel-proper.md`](../kernel/20260417-t187-kernel-proper.md) §M11/§M12/§M13/§M19 — the runtime invariants this section makes auditable.
- [`kb/research/session/20260424-t175-program-authoring-fabric.md`](../session/20260424-t175-program-authoring-fabric.md) — fabric note proposes WF21 + clock + substrate; §9 cites these as round-15+ promotions.
- [`kb/research/session/20260422-t172-cowork-as-occupant.md`](../session/20260422-t172-cowork-as-occupant.md) §4 disjointness — §M9 sovereignty pre-formalization that §9.2.3 makes audit-observable.

---

## 9.8 Round-15+ deferred

Section content currently as text; structural ADDs queued for round-15+ when WF21 + companion fragments promote:

- `claim:guido.invariant-bracketing-discipline` — §9.4.1 sub-section material.
- `claim:guido.topology-degenerate-vs-federated` — §9.4.3 sub-section material.
- `claim:guido.scaffolding-on-emission-not-reasoning` — §9.4.2 sub-section material; cited by §0 + §1.
- A.7 invariant-bracketing-meta — promotes to canonical 7-tuple coherence object once `claim` type + WF21 ship.
- A.8 wf21_causal_acyclicity — added to invariant checklist post-WF21 promotion; `ValidateCausalAcyclic` becomes preflight register.
- **Audit-as-reactor** — autonomy lift via §M14 round-close-trigger predicate (extension to t-hook predicate catalog) + reactor scaffold pinned to round-close watcher. Pairs naturally with §M9 + §M10 work in round-15+. Currently a manual ritual; reactor pattern would auto-fire `Audit: PersonaLattice → CoherenceVerdict` at every round-close trigger.

---

## 9.9 Anchors back to round-14 derivation

Provenance anchors for §9 (per `urn:moos:derivation:guido.section-09-governance-and-audit` `stochastic_weights`):

- `predecessor-derivation` — `derivation:guido.governance-spec-and-cadence-revision` (hp-laptop log_seq 631) — the broader-picture seed.
- `audit-seed-derivation` — `derivation:guido.round-13-cross-persona-audit` (hp-laptop log_seq 633) — the audit reification.
- `consumes-anchors` — `t169.session-generalization`, `t187.kernel-proper-spec` from the 7-derivation backfill.
- `consumes-master-scaffold` — `wolfram.spec-master-scaffold` (Z440 log_seq 363).
- Round-14 audit dry-runs: [round-13 audit](https://github.com/Collider-Data-Systems/ffs0/issues/36#issuecomment-4320199704), [Karpathy §1 first live A.4](https://github.com/Collider-Data-Systems/ffs0/issues/36#issuecomment-4320443431), [T=176 cross-persona audit](https://github.com/Collider-Data-Systems/ffs0/issues/36#issuecomment-4321778462) — operational evidence that the audit pattern works at round-cadence.

---

— Guido, `session:sam.governance`, `kernel:hp-laptop.primary`, T=176 ~12:NN CEST. Confidence walks 0.5 → 0.85 as md projection settles + `moos-cross-persona-audit` skill authoring lands → 1.0 + status=closed at round-14 close (tag `v0.14.0-spec-r14`).
