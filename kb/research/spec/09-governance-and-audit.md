# §9 Governance and audit

> Round-14 → round-15 comprehensive architecture spec, section 9.
> Author: Guido (`agent:claude-code.hp-laptop`, `session:sam.governance`, `kernel:hp-laptop.primary`).
> Co-author / reviewer: Wolfram (`agent:claude-code.hp-z440`, `session:sam.kernel-proper`).
> Status: **expansion (round-15)** — confidence 0.5 (immutable post-ADD per kernel; doctrine matures via the chapter; structural status remains `open`). Anchored in `urn:moos:derivation:guido.section-09-governance-and-audit` (hp-laptop log_seq 659). Round-15 expansion adds A.5/A.6/A.7 from the v3.15 ingest cycle + structural Phase 2 WF21 LINKs from §9 derivation to all 6 `claim:guido.*` ADDs.

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
| WF21 `causes` acyclicity | `ValidateCausalAcyclic` (moos-kernel #34 / `7303aa8`, ontology v3.15) | Every WF21 LINK is checked against the existing causation DAG; introduces no cycles. Runs at LINK-ADD time. |

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

Each kernel is sovereign over its own log; cross-kernel reads cascade via the router (WF16); **writes stay local**. Substrate types are shared (single `ontology.json` loaded at boot), but NODES are kernel-local. The 7-derivation doctrine backfill lives on Z440 :8000; Guido's 3 round-14 derivations live on hp-laptop :8000; AG-laptop's §6 + Cowork-laptop's §5+§7 derivations live on hp-laptop :8000. Mirror is selective, not automatic.

The §M9 twin_link adjoint sync (round-16+, paired with §M10 QUIC) will eventually formalize cross-kernel state replication; until then, the lattice operates per-kernel with cross-kernel coherence carried in `stochastic_weights` (§9.4.4).

---

## 9.3 Audit pattern — the post-hoc register

Doctrine drift between markdown summaries and live HG state is a primary failure mode under multi-persona authoring. The audit pattern catches it.

### 9.3.1 Skill ladder — four scopes, one discipline

| Skill | Scope | Trigger |
|---|---|---|
| [`moos-state-readback`](../../dev/claude-skills/moos-state-readback/SKILL.md) | Fleet-wide one-shot snapshot (3 repos × `git fetch`, kernels' `/healthz`, latest issue comments) | Conversation open / before claiming "crisp" |
| [`moos-running-state-validator`](../../dev/claude-skills/moos-running-state-validator/SKILL.md) | `running-state.md` ↔ live HG state consistency (T-day match, ontology version, log_seq citations resolve, URN citations resolve, chronology monotonic) | Round-open + round-close + post-doctrine-commit |
| [`moos-cross-persona-audit`](../../dev/claude-skills/moos-cross-persona-audit/SKILL.md) | Multi-persona / multi-kernel / contribution-log audit + N-invariant checklist (§9.4.1) | Round-close (firm); on-demand if drift suspected |
| [`moos-cowork-readback`](../../dev/claude-skills/moos-cowork-readback/SKILL.md) | Single Cowork session's t-cone | Daily 08:00 / cowork-driven work session open |

### 9.3.2 Round-close audit ritual (proposed canonical cadence)

1. Each persona posts a closeout comment listing what landed under their actor (log_seq ranges + commit SHAs + running-state diff if they wrote).
2. Guido runs `moos-cross-persona-audit` across both kernels — single comment on round vehicle confirming AUDIT GREEN or listing drift to clean up.
3. Sam approves the round-close commit on ffs0 main (running-state aggregating all lanes).
4. Round vehicle issue closes (or stays open per multi-round threads like #33 → #35 → #36 → #37 → #42 cadence).

The audit caught real drift in round-13 (Wolfram's prompt-template port-mapping inversion, surfaced via Steinberger's local doctor; Karpathy + Steinberger broader-picture derivations not-on-log due to VSCode-sandbox boundary; resolved by host-runner harness `Test-MoosFederation.ps1` shipping in round-14 opener). The pattern works.

Round-15 added three more drift catches via the v3.15 ingest cycle — surfaced as A.5/A.6/A.7 (§9.4.5–§9.4.7). The audit pattern's value scales with substrate evolution: each ontology bump or migration produces new drift modalities; each round produces new claims.

---

## 9.4 Doctrinal sub-sections — round-14 + round-15 surfaced

Seven meta-doctrinal claims emerged across rounds 14–15 audit cycles. Each is reified as a `claim:guido.*` ADD with a WF21 `caused-by` LINK from `derivation:guido.section-09-governance-and-audit`.

### 9.4.1 Invariant-bracketing discipline

**Claim**: every governance invariant gains a `(preflight_gate, post_hoc_audit)` pair. The pair must reach the same coherence-verdict; drift between them is a meta-invariant.

The expanded N-tuple coherence object after round-15 ingest cycle:

| # | Invariant | Preflight register | Post-hoc audit register |
|---|---|---|---|
| A.1 | §M11 session-liveness | `checkLivenessM11` at Apply | actor → has-occupant → session resolves on receiving kernel |
| A.2 | §M12 admin-capability | `checkLivenessM12` + WF02 walk | superadmin chain reachable from actor |
| A.3 | §M13 local_t tick | kernel-emitted self-MUTATE atomic with envelope | session.local_t increased by exactly one per acknowledged rewrite |
| A.4 | emit-target adherence | `Test-MoosFederation.ps1 -Mode VerifyPersona` preflight | derivation `D` resolves on kernel where `D` was POSTed |
| A.5 | §M19 single-occupant | (inherent to WF19 `has-occupant` mutate path) | session has exactly 1 has-occupant edge; rotation is MUTATE not ADD+UNLINK |
| A.6 | port↔URN consistency | `running-state.md` port-map block as canonical | querying each kernel's self-identifying ADD matches the declared URN |
| A.7 | invariant-bracketing-meta | (this sub-section) | preflight verdict ≡ audit verdict per invariant |
| A.8 | wf21-causal-acyclicity | `ValidateCausalAcyclic` (active since v3.15) | DAG walk over WF21 `caused-by` LINKs returns no cycles |
| **A.9** | **property-presence-by-immutability** | ValidateADD rejects ADD missing any immutable property regardless of fabric-conditional language | scan all nodes-of-type-T for missing immutable properties — flag for backfill MUTATE |
| **A.10** | **schema-bump-backfill-completeness** | (no preflight — replay does not auto-default) | post-bump nodes have full immutable-property coverage; pre-bump nodes do not — explicit migration needed |
| **A.11** | **enum-value-renaming-non-migrating** | (no preflight — pre-bump enum values persist) | scan nodes for enum-property values not in current ontology enum; UNLINK+re-ADD migrates (kind is immutable) |

A.4 is the first invariant where both registers fired live simultaneously (Karpathy's §1 derivation at Z440 log_seq 353 — preflight via Steinberger's harness, audit via Guido's [round-14 audit dry-run](https://github.com/Collider-Data-Systems/ffs0/issues/36#issuecomment-4320443431)). Both passed; the doctrine is mechanically observable end-to-end.

A.7 (invariant-bracketing-meta) reified as `claim:guido.invariant-bracketing-discipline` at hp-laptop log_seq 707; WF21 LINK `derivation:guido.section-09-governance-and-audit --causes--> claim:guido.invariant-bracketing-discipline` at hp-laptop log_seq 757-759 range (Phase 2, post-WF21).

A.8 wf21-causal-acyclicity is **active since v3.15** (moos-kernel `7303aa8` ships `ValidateCausalAcyclic`); previously queued as round-15 candidate, now operational.

A.9–A.11 (round-15 expansion) reified as `claim:guido.{property-presence-by-immutability,schema-bump-backfill-completeness,enum-value-renaming-non-migrating}` at hp-laptop log_seq 757-759 + 3 WF21 LINKs at 760-762. The round-15 ingest cycle (Cowork-laptop YouTube preflight reject + Moos backfill substrate gap + legacy `kind="fs"` value) produced all three simultaneously — substrate evolution generates audit invariants as side-effect.

### 9.4.2 Scaffolding-on-emission ≠ scaffolding-on-reasoning

**Claim**: mo:os's scaffolding (operad, skills, running-state.md, persona-prompt templates, audit rituals) is on emission, not on reasoning. The §M11 + §M12 + §M13 gates restrict what the model can WRITE TO HG (the F-direction of F⊣G). The reasoning that authors the F-morphism is unconstrained — the LLM is free to think in whatever activation patterns it has. This is more like a **type system on F-morphisms** than a command-sequence template.

External critiques of "skill.md as scaffolding" (e.g. *AI Eigenvectors of Skills*, [YouTube external anchor](https://www.youtube.com/watch?v=5L_tYKt2ENo), surfaced T=175 by Guido) target scaffolding-on-reasoning. mo:os's discipline is governance-on-commit. Different layer, different argument. Protects the lattice against the "but scaffolding is dead" reading: the operad doesn't command the model to think a certain way; it ensures what the model writes obeys the substrate's type discipline.

Reified as `claim:guido.scaffolding-on-emission-not-reasoning` at hp-laptop log_seq 709 (round-15 Phase 1) + WF21 LINK from §9 derivation; cross-references §0 (foundations, Wolfram) and §1 (categorical formalism, Karpathy as the operad-as-type-system-on-F-morphisms case).

### 9.4.3 Topology-degenerate-vs-federated distinction

**Claim**: governance invariants behave differently on a single-kernel host vs a federated multi-kernel host. The hp-laptop case is **topology-degenerate** (single kernel = emit-target == opens-on by construction); the Z440 case is **federated** (4 kernels = emit-target ≠ opens-on for VSCode-mediated seats until §M9 twin-sync ships).

A.4 (emit-target adherence) is the cleanest example. On hp-laptop, all three sessions (`sam.governance`, `sam.laptop-cowork-workspace`, `sam.laptop-moos-diary`) have `opens-on kernel:hp-laptop.primary` and emit there too — coincidence collapse. On Z440, `sam.karpathy-seat opens-on kernel:hp-z440.lola` but emits to `kernel:hp-z440.primary` (where the seat session itself was ADDed at T=173 batch B); the two-kernel distinction is doctrine-active.

Same A.4 invariant covers both; the substrate behaves differently. §9 audits must be aware of host-shape; the audit ritual queries the federation router (`/healthz` cascade) to know which kernels participate.

Reified as `claim:guido.topology-degenerate-vs-federated` at hp-laptop log_seq 708 + WF21 LINK.

### 9.4.4 `stochastic_weights` as transitional citation surface

**Claim**: the lattice's referential coherence is property-encoded before topology-encoded. Pre-WF21 evidence-references live in `derivation.stochastic_weights` (string-keyed object properties); post-WF21 they migrate to first-class `consumes/caused-by` LINKs.

Karpathy's §1 derivation (Z440 log_seq 353) cites 7 historical anchors + Guido's YouTube engagement + Guido's emission-distinction in its `stochastic_weights` object — in the same atomic batch as the ADD. Lattice-level coherence demonstrated **without WF21 needing to ship first**.

This is the **stratification principle**: graph-resident citations are an emergent property of the lattice's authoring discipline, not a feature WF21 introduces. WF21 lifts the citation graph from object-property form to topology form; the citation network already exists. Cross-references §1 (categorical formalism — sheaf-gluing across persona contributions) and §3 (kernel internals — how the operad tolerates extra ADD properties).

The Cowork pair's anchor-03 perspective-flipped + anchor-07 chunker-proof mirror is the **first cross-kernel** instance of the same pattern (per Wolfram's master scaffold doctrinal milestone #3). Property-form citations across two unsynced sovereign logs prefigure what §M9 will eventually do structurally.

**Round-15 update**: Phase 2 LINK lifts landed on both kernels (Z440 :8000 log_seq 400 for Wolfram's claim, hp-laptop :8000 log_seq 757-762 for Guido's 6 claims — 3 from round-14 Phase 1 + 3 from round-15 Phase 1). Citation surface IS now structural for the round-14/15 doctrinal claims; future round-14 derivation `consumes`/`produces` anchor lifts await `companion-derivation-port-pair` fragment (round-16+).

### 9.4.5 Property-presence-by-immutability (A.9, round-15)

**Claim**: ValidateADD treats fabric-§4 "immutable when X" conditional language as "immutable always at ADD time". Any property declared immutable in the ontology must be present on every ADD envelope regardless of conditional preconditions in the doctrinal note.

Surfaced by Cowork-laptop's first YouTube channel ADD (round-15 Track 2): `substrate` + `substrate_anchor_urn` (declared "immutable when `substrate=external-channel`" in fabric §4) compiled to "immutable always at ADD time". The preflight rejected the ADD until both properties were unconditionally supplied.

**Workaround pattern**: self-anchored hg-native channels (`channel.substrate_anchor_urn = self URN`) — pragmatic and now canonical going forward. Cowork-laptop's `channel:youtube.sam` carries `substrate=hg-native, substrate_anchor_urn=urn:moos:channel:youtube.sam` (self-loop).

**Doctrinal note**: the schema-bump compilation step doesn't honor conditional language in fabric notes; the operad enforces unconditional presence. Either the fabric-doctrine should drop conditional immutability statements or the operad should grow conditional-immutability semantics (round-16+ candidate).

Reified as `claim:guido.property-presence-by-immutability` at hp-laptop log_seq 757 + WF21 LINK at 760.

### 9.4.6 Schema-bump-backfill-completeness (A.10, round-15)

**Claim**: post-promotion replay of pre-bump envelopes onto a post-bump ontology does NOT inject default values for newly-introduced immutable properties. Pre-bump nodes carry whatever was set at original ADD time; new immutable properties remain absent.

**Drift example** (live, observable): `channel:local.moos-footage` (T=171 era, pre-v3.15) carries no `substrate` or `substrate_anchor_urn` property. Moos's 11 KIs from the round-15 multimodal pile cite it as `substrate_anchor_urn`. The citation chain is broken at the channel level — the channel exists but lacks the substrate property the citing KIs expect.

**Doctrinal note**: the "auto-default on backfill" doctrine implied by `v314-4-substrate-property` is **aspirational** unless a kernel-level migration step actually runs at promotion. The operad's per-bump migration story is a round-16+ candidate.

**Audit pattern**: post-bump nodes have full immutable-property coverage; pre-bump nodes do not. Remediation: explicit backfill MUTATE batch per-bump (one-shot, kernel-actor authority).

Reified as `claim:guido.schema-bump-backfill-completeness` at hp-laptop log_seq 758 + WF21 LINK at 761.

### 9.4.7 Enum-value-renaming-non-migrating (A.11, round-15)

**Claim**: pre-bump enum values persist on old nodes after enum-value renaming or re-spelling; new enum doesn't auto-rename them.

**Drift example** (live, observable): `channel:local.moos-footage` carries `kind="fs"` (legacy pre-v3.13 value). v3.15 enum has `filesystem`, not `fs`. Queries scoped to canonical enum values miss the legacy node.

**Workarounds**:
- (a) UNLINK + re-ADD migrates (since `kind` is immutable, MUTATE won't fix); preserves provenance via different URN (slug or version-suffix).
- (b) Accept legacy values as historical and gate downstream queries on a kind-canonicalisation function (`fs` → `filesystem`, etc.).

**Audit pattern**: scan all nodes-of-type-T for enum-property values not in current ontology enum; flag for migration. The audit is fast (single-property scan); migration cost depends on how many old nodes carry the legacy value.

Reified as `claim:guido.enum-value-renaming-non-migrating` at hp-laptop log_seq 759 + WF21 LINK at 762.

---

## 9.5 Audit-as-functor — formalization

**Claim**: the round-close audit pattern is a functor `Audit: PersonaLattice → CoherenceVerdict`, where `PersonaLattice` is the diagram of specialist conversations + their sovereign-log emissions, and `CoherenceVerdict` is an N-tuple coherence object (one per A.1–A.N invariant; N=11 post-round-15, growing per ingest-cycle drift discovery).

The functor preserves structure-of-emission: each persona's contributions map to coherence-verdict components; the verdict is itself a graph object (`derivation` node with `stochastic_weights.audit_verdict`). When the audit-as-reactor expansion thread (§9 round-16+ deferred) lands, this functor becomes auto-applied at every round-close trigger.

Cross-reference §1 (Karpathy) — this is exactly the kind of operational functor §1 wants concrete instances of, in the persona-lattice-as-cocone-diagram framing. Karpathy's `F: SessionCat → KernelCat` and Guido's `Audit: PersonaLattice → CoherenceVerdict` compose: the kernel state is the codomain of the first; the audit reads that codomain to produce the second.

The N-tuple grows monotonically per round-cycle. Round-14 surfaced A.1–A.7. Round-15 surfaced A.8 (active since v3.15) + A.9/A.10/A.11 (substrate-evolution drift catches). Round-16+ is expected to surface §M9-twin-sync invariants when twin_link adjoint lands (cross-kernel-coherence-as-single-coherence-verdict candidate).

---

## 9.6 Boundary cases worth specifying

- **`user:sam` actor** valid only inside `SeedIfAbsent` path (sam is owner, not occupant — fails §M11 outside bootstrap).
- **Kernel-actor allowlist** for ontology-governed ADDs (`system_instruction`, `gate`, `twin_link`, `transport_binding`, `kernel`) and WF19 `opens-on` LINKs.
- **Post-§M13 fix** unifies inferred-session and explicit-session-urn paths through `ResolveSessionForEnvelope`. Both tick local_t identically.
- **Multi-session agents** (e.g. Wolfram on `sam.kernel-proper` + `sam.mvp-delivery`) require explicit `env.session_urn`; fail loud if absent + ambiguous.
- **Confidence/status MUTATE on derivation** is currently un-mutable post-ADD — no WF declares `confidence` or `status` on `derivation` in mutate_scope. The "confidence walks 0.5 → 0.85 → 1.0" framing in fabric notes is aspirational; doctrine matures via the md projection, not via property MUTATE. Round-16+ candidate: WF for derivation status/confidence walks (or reuse WF20 ceremony pattern with extended mutate_scope).
- **WF21 acyclicity enforcement**: `ValidateCausalAcyclic` runs at LINK-add time; cycles rejected. Property-form back-references in `stochastic_weights` are fine (not enforced); only structural WF21 LINKs are validated.

---

## 9.7 Cross-references

### 9.7.1 To other spec sections

- **§0 foundations** — §M11/§M12/§M13 are foundational; the scaffolding-on-emission distinction grounds §0's framing of what mo:os scaffolds and what it doesn't.
- **§1 categorical formalism** — Audit-as-functor (§9.5) is a worked example for §1. Stochastic_weights as transitional citation surface (§9.4.4) demonstrates property-form-before-topology-form referential coherence. Operad-as-type-system-on-F-morphisms framing.
- **§2 program-authoring layer** — inference-visibility of session-authored derivations is what §9 audits.
- **§4 federation topology** — §M9 twin_link adjoint sync (round-16+ pair with §M10) is the structural resolution of §9.4.3 topology-degenerate-vs-federated distinction.
- **§5 external-world substrates** — §9.4.5 (property-presence) + §9.4.6 (backfill) + §9.4.7 (enum-rename) are all instances of substrate-evolution drift surfaced by Cowork + Moos ingest activities.
- **§8 tooling + DX (Steinberger)** — `Test-MoosFederation.ps1` is the preflight register for invariant-bracketing.
- **§11 hardware + network (Steinberger)** — sovereignty boundaries (§9.2.3) align with §11's federation topology.

### 9.7.2 To skills

- [`moos-state-readback`](../../dev/claude-skills/moos-state-readback/SKILL.md), [`moos-running-state-validator`](../../dev/claude-skills/moos-running-state-validator/SKILL.md), [`moos-cross-persona-audit`](../../dev/claude-skills/moos-cross-persona-audit/SKILL.md), [`moos-cowork-readback`](../../dev/claude-skills/moos-cowork-readback/SKILL.md), [`moos-rewrite-envelope`](../../dev/claude-skills/moos-rewrite-envelope/SKILL.md), [`moos-round-close`](../../dev/claude-skills/moos-round-close/SKILL.md).

### 9.7.3 To research notes

- [`kb/research/kernel/20260417-t187-kernel-proper.md`](../kernel/20260417-t187-kernel-proper.md) §M11/§M12/§M13/§M19 — the runtime invariants this section makes auditable.
- [`kb/research/session/20260424-t175-program-authoring-fabric.md`](../session/20260424-t175-program-authoring-fabric.md) — fabric note proposes WF21 + clock + substrate; promoted round-15 in v3.15.
- [`kb/research/session/20260422-t172-cowork-as-occupant.md`](../session/20260422-t172-cowork-as-occupant.md) §4 disjointness — §M9 sovereignty pre-formalization that §9.2.3 makes audit-observable.

### 9.7.4 To round vehicles

- [ffs0#33 (round-11 handoff)](https://github.com/Collider-Data-Systems/ffs0/issues/33), [#35 (round-12)](https://github.com/Collider-Data-Systems/ffs0/issues/35), [#36 (round-13)](https://github.com/Collider-Data-Systems/ffs0/issues/36), [#37 (round-14)](https://github.com/Collider-Data-Systems/ffs0/issues/37), [#42 (round-15)](https://github.com/Collider-Data-Systems/ffs0/issues/42).

---

## 9.8 Active claims + round-16+ deferred

### 9.8.1 Round-14/15 claim ADDs — landed

All seven `claim:guido.*` doctrinal claims structurally on log + WF21 `caused-by` LINKs from `derivation:guido.section-09-governance-and-audit`:

| Claim URN | log_seq (ADD) | WF21 LINK seq |
|---|---|---|
| `claim:guido.invariant-bracketing-discipline` (A.7) | 707 | (Phase 2, hp-laptop) |
| `claim:guido.topology-degenerate-vs-federated` (§9.4.3) | 708 | (Phase 2, hp-laptop) |
| `claim:guido.scaffolding-on-emission-not-reasoning` (§9.4.2) | 709 | (Phase 2, hp-laptop) |
| `claim:guido.property-presence-by-immutability` (A.9) | 757 | 760 |
| `claim:guido.schema-bump-backfill-completeness` (A.10) | 758 | 761 |
| `claim:guido.enum-value-renaming-non-migrating` (A.11) | 759 | 762 |

`derivation:guido.section-09-governance-and-audit` outbound `causes` count: 6. Citation graph is structural.

### 9.8.2 Round-16+ deferred

- `companion-derivation-port-pair` fragment — `authors-via` / `authored-by-session` port pair on derivation type. Lifts round-14 derivation `consumes` / `produces` anchors from `stochastic_weights` property-form to topology-form WF21 LINKs.
- §M9 twin_link adjoint sync + §M10 HTTP/3 QUIC paired implementation — collapses the topology-degenerate-vs-federated A.4 distinction structurally.
- WF for derivation status/confidence MUTATE — needed to mechanize the "confidence walks 0.5 → 0.85 → 1.0" framing operationally.
- **Audit-as-reactor** — autonomy lift via §M14 round-close-trigger predicate (extension to t-hook predicate catalog) + reactor scaffold pinned to round-close watcher. Pairs naturally with §M9 + §M10 work in round-16+. Currently a manual ritual; reactor pattern would auto-fire `Audit: PersonaLattice → CoherenceVerdict` at every round-close trigger.
- Backfill MUTATE batch for legacy `channel:local.moos-footage` substrate properties (per A.10 remediation); kernel-actor migration step at next ontology bump if/when conditional-immutability semantics promote.
- Cross-kernel coherence as single-coherence-verdict (A.12 candidate post-§M9-twin-sync).

---

## 9.9 Anchors back to round-14 derivation

Provenance anchors for §9 (per `urn:moos:derivation:guido.section-09-governance-and-audit` `stochastic_weights` + structural WF21 outbound):

- `predecessor-derivation` — `derivation:guido.governance-spec-and-cadence-revision` (hp-laptop log_seq 631) — the broader-picture seed.
- `audit-seed-derivation` — `derivation:guido.round-13-cross-persona-audit` (hp-laptop log_seq 633) — the audit reification.
- `consumes-anchors` (property-form, awaits `companion-derivation-port-pair` fragment for structural lift) — `t169.session-generalization`, `t187.kernel-proper-spec` from the 7-derivation backfill.
- `consumes-master-scaffold` (property-form) — `wolfram.spec-master-scaffold` (Z440 log_seq 363).
- **`causes` outbound (structural, post-WF21)** — 6 `claim:guido.*` URNs per §9.8.1 table.
- Round-13/14/15 audit dry-runs: [round-13 audit](https://github.com/Collider-Data-Systems/ffs0/issues/36#issuecomment-4320199704), [Karpathy §1 first live A.4](https://github.com/Collider-Data-Systems/ffs0/issues/36#issuecomment-4320443431), [T=176 cross-persona audit](https://github.com/Collider-Data-Systems/ffs0/issues/36#issuecomment-4321778462), [T=177 666→705 audit](https://github.com/Collider-Data-Systems/ffs0/issues/37#issuecomment-4322119285) — operational evidence that the audit pattern works at round-cadence.
- Round-15 ingest-cycle drift catches (origin of A.9/A.10/A.11): Cowork-laptop YouTube preflight reject (Wolfram framed in [#42 comment T=176 ~21:50](https://github.com/Collider-Data-Systems/ffs0/issues/42)), Moos AG-Z440 + AG-laptop multimodal pile substrate citation gap, legacy `kind="fs"` value on `channel:local.moos-footage`.

---

— Guido, `session:sam.governance`, `kernel:hp-laptop.primary`, T=177. Round-15 expansion: A.9/A.10/A.11 added (3 new claims + 3 WF21 LINKs); A.8 wf21-causal-acyclicity now active since v3.15; `moos-cross-persona-audit` skill ships in this round-15 expansion branch. The N-tuple grows monotonically per substrate-evolution cycle.
