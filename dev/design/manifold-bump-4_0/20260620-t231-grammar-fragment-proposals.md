---
agent: "moos-categorical-research"
description: "Use when: maturing the so:om / Poly conjectures into governance-gated grammar_fragment proposals — the device→workstation.kind discriminator, the channel.kind surface/infra fold, derivation.inference_kind lowering/lifting, and the M11 PreToolUse occupant-guard. Conjecture-marked PROSE draft; status: proposed; authorizes no ontology/URN change, applies no kernel rewrite."
---

# Grammar-fragment proposals — maturing the so:om / Poly conjectures (T=231)

> **Status: design draft (S0 → pending G-ingest). All four proposals are PROSE SKETCHES at
> `status: proposed` — NONE applied. GATE: prose only — this authorizes NO `ontology.json` edit, NO
> kernel rewrite, NO URN rename. The ontology stays v3.16.2.** Authored T231 as the
> `grammar_fragment` maturation of the conjectures flagged in `20260620-t231-moos-soom.md` §4/§4a/
> §Conjectures and `20260620-t231-poly-foundations.md` §9/§10, reconciled against the live ontology
> (`kb/superset/ontology.json` v3.16.2 — types `workstation`, `channel`, `derivation`, `t_hook`;
> the WF20 `grammar_promotion` category; the `grammar_fragment` node-type + its
> `proposed → rejected|promoted|merged` status lifecycle; §M11/§M12) and the 4.0 vocab table in
> `AGENTS.md` (D1–D8) + `20260605-t216-ontology-4.0-draft.md` / `20260607-t218-manifold-instance-vocab-delta.md`.

## 0. What a grammar_fragment is here (the mechanism we are using)

A `grammar_fragment` (S1) is the carrier of the S4→S1 adjoint `Promote` (WF20 `grammar_promotion`).
Its shape (from the live spec):
- `fragment_kind ∈ {type, port, wf_clause, predicate_shape, property}` (immutable),
- `specification` (object — the partial S1 patch),
- `evidence_urns` (array<urn> — S4 `system_instruction` / S2 `governance_proposal` citations),
- `status ∈ {proposed → rejected | promoted | merged}` (admin authority).

**WF20 promotion path (identical for all four below):**
```
ADD grammar_fragment (status: proposed, admin/kernel actor)        ← what these four sketches are
  → admin review (§M12 capability-gated MUTATE)
    → status: rejected (rejection_reason set)            [terminal]
    | status: promoted (enters the next 4.0 ontology draft)
      → status: merged (folded into ontology baseline; version bump)  [terminal]
```
None of the four is even ADDed yet — they are pre-fragment sketches. The "exact ontology delta"
shown per proposal is the `specification` payload a future ADD **would** carry, displayed so the
reviewer can read the patch without it being applied.

**Gate vocabulary (from `AGENTS.md` §4.0 table):** a **4.0 (alias/bump)** change is an additive,
reviewed `ontology.json` bump (new enum value / new property / new discriminator) with no URN
churn. A **4.0.x (hard URN rewrite)** is the gated ~59-site `kernel→instance` URN rename class —
build-gate = apply-gate (Doctor + `go test ./...`). Each proposal is tagged with which gate it
needs.

---

## P1 — `workstation.kind` discriminator `{server, mobile, …}`

**Conjecture matured:** `moos-soom` §4 / §Conjectures — "model the phone as `workstation` with
`workstation.kind ∈ {server, mobile, …}` — a discriminator, not a separate `device` type — every
kind running an instance at some F/G capability degree." This **retires the `device` MISSING ⚠ row**
in `moos-soom` §3: there is no new top type; `device` collapses into a `workstation` property.

**Rationale.** The live `workstation` type (S2, `urn:moos:workstation:<name>`) already hosts kernels
and carries `hostname/os/arch` immutables. Android / hp-z440 / hp-laptop / hp-prodesk are all
`workstation` nodes that *run an instance* (`moos-soom` §4 revision per Sam #73). The only missing
distinction is **what class of host** it is — which downstream gates the F/G-degree it can carry
(`moos-soom` §4a). A discriminator property is the minimal, additive way to say that; a new `device`
type would duplicate ownership/hosting topology and split a clean type for no gain.

**Exact ontology delta it WOULD make (proposed sketch — NOT applied):**
```jsonc
// grammar_fragment: urn:moos:grammar_fragment:p1-workstation-kind   (status: proposed)
// fragment_kind: "property"
// specification — additive property on the existing `workstation` type:
"kind": {
  "mutability": "immutable",          // class is an identity fact, set at ADD (CI-3 family)
  "type": "enum",
  "values": ["server", "mobile", "laptop", "desktop", "vm", "edge"],
  "note": "Host class discriminator. Every kind runs an instance at some F/G capability degree
           (see moos-soom §4a); this is NOT a separate `device` top type. server/desktop/laptop =
           full G-reach; mobile/edge = reduced G-reach, surface-heavy F-reach."
}
// evidence_urns: [ S4 instr citing moos-soom §4, this draft ]
```
Note: `kind` is proposed **immutable** to mirror `channel.kind`'s immutability (a re-class is
UNLINK+re-ADD, consistent with the v3.13 `channel.kind` note).

**Open coupling (flagged, not bundled):** the F/G **capability degree** itself (`moos-soom` §4a,
the `(rewrite-reach × surface-reach)` vector) is a *separate* question — whether it is a property
vector on the workstation or derived from attached `capability` nodes (WF02) is **P-future**, not
P1. P1 only adds the host-class label; it does not encode capability.

**WF20 path / gate:** **4.0 (alias/bump)** — additive enum property, no URN change, no relation
change. Safe in the 4.0 bump alongside D1–D8.

**Risks + open questions.**
- (risk) Enum value bikeshed — `mobile` vs `phone` vs `handset`; `vm`/`edge` may be premature. Keep
  the value set minimal at promotion; enums extend cheaply later (the `channel.kind` precedent).
- (open) Does `mobile` imply a *default* F/G-degree, or is degree fully orthogonal to `kind`?
  Conjecture: orthogonal — `kind` is host class, degree is capability; a beefy phone ≠ a weak phone.
- (open) Backfill: existing `workstation` nodes have no `kind`. Promotion needs a one-time additive
  MUTATE per node (parallel to the `t_hook.firing_state` v3.11 backfill pattern) — additive MUTATE,
  rollback-safe.

---

## P2 — `channel.kind +=` surface/infra kinds (fold D5 infra + D7 surface into ONE migration)

**Conjecture matured:** `moos-soom` §1 ("add `keep-widget` and other mobile surfaces to
`channel.kind`"), the D7 surface terminus (`20260607-t218-…vocab-delta.md` §D7 —
`workstation-surface/virtual-desktop/window/tab-group/browser-tab/harness-pane`), and the D5 infra
kinds (`20260605-t216-…4.0-draft.md` §D5 — `domain/dns-zone/cloudflare-zone/cloudflare-tunnel/
access-app/registrar/website-endpoint`). Both vocab-delta drafts + governance already concur:
**fold D5 infra and D7 surface into ONE `channel.kind` migration, not two passes.**

**Rationale.** `channel` is the existing S0-substrate entry point (`channel.kind` already carries
`{filesystem, messaging, board, drive, mail, calendar, task-list, cloud-storage, vcs,
project-board, video, audio}`). so:om surfaces (the D7 layer) and mtdc infra facets (the D5 layer)
are both "named streams / topological entry points" — they fit `channel`, observed-first, never
authority. One additive enum extension covers both; `realizes`/`realized-by` (D8) joins them to the
semantic layer separately (that relation is **not** part of this fragment).

**Exact ontology delta it WOULD make (proposed sketch — NOT applied):**
```jsonc
// grammar_fragment: urn:moos:grammar_fragment:p2-channel-kind-surface-infra   (status: proposed)
// fragment_kind: "property"  (enum-extension of the existing immutable channel.kind)
// specification — extend channel.kind.values (additive only):
//   D7 surface kinds:
"workstation-surface", "virtual-desktop", "window", "tab-group", "browser-tab",
"harness-pane", "pip-window", "keep-widget", "compile-target",
//   D5 infra kinds:
"domain", "dns-zone", "cloudflare-zone", "cloudflare-tunnel", "access-app",
"registrar", "website-endpoint"
// note: surface kinds are S0 projection substrate (observed, redaction-safe, NEVER authority);
//       infra kinds are mtdc facets. kind stays immutable — re-class = UNLINK + re-ADD
//       (inherits the v3.13 channel.kind immutability note).
// evidence_urns: [ D5 draft, D7 vocab-delta, moos-soom §1/§2, mtdc-channel-inventory-dry-plan ]
```
The prompt's `{pip-window, harness-pane, compile-target, keep-widget, virtual-desktop, window,
tab-group, browser-tab}` set is included above; `compile-target` is the so:om `moos-soom` §4a
"LLVM backend-target" surface (the destination an IR is lowered onto — see P3).

**WF20 path / gate:** **4.0 (alias/bump)** — additive enum extension, exactly the shape of the
v3.13 `v313-8-channel-kind-vcs` fragment (which extended the same enum and was `promoted → merged`
cleanly). No URN change. Safe in the 4.0 bump.

**Risks + open questions.**
- (risk) Enum bloat / overlap — `window` vs `pip-window` vs `harness-pane` vs `browser-tab` blur.
  Mitigation: promote the *coarse* set first (`virtual-desktop, window, tab-group, browser-tab,
  harness-pane, keep-widget`), defer `pip-window/compile-target` to a follow-on fragment if the
  projection pipeline doesn't yet address them.
- (risk) Secrets boundary (D5): infra kinds must carry **structural** handles only — `source_uri`
  must never durable-store tokens/account-IDs (the T216 migration guard). Surface kinds: never
  durable-store private window/tab *contents*.
- (open) Is `compile-target` a `channel.kind` (a surface) or really a `workstation`-capability
  facet? It straddles P1/P3 — flag, do not force into P2 if it muddies the surface/infra split.
- (open) `realizes`/`realized-by` (D8) is the relation that makes these surfaces addressable from
  the semantic layer — it is a **separate `port` fragment** (open in the vocab-delta), not folded
  here. P2 only names the kinds.

---

## P3 — `derivation.inference_kind +=` `{lowering, lifting}`

**Conjecture matured:** the Poly/so:om F⊣G framing — `persona = Φ(purpose)` is a `derivation` (D3),
and the two legs of every lens are **F (project/lower)** and **G (ingest/lift)**
(`poly-foundations` §3/§4, `moos-soom` §1). To let a `derivation` node record *which leg of the
adjunction* produced it, extend its `inference_kind` enum with the two adjoint directions. This is
what lets `presents-as` (D4) and `persona = Φ(purpose)` (D3) carry their provenance as a *typed
inference direction*, not just free-form weights.

**Rationale.** The live `derivation` type already reifies session-internal inference with
`inference_kind ∈ {bayesian, llm_completion, deterministic_rule, dag_walk, hand_authored, hybrid}`.
Those name the *mechanism*; none names the *adjoint direction*. A persona projected onto a surface
(F = lowering) and a surface observation lifted back into the graph (G = lifting) are categorically
distinct derivations. Adding `lowering`/`lifting` lets the F⊣G round-trip (the unit-defect / HDC
encode-decode-fidelity metric from `…vocab-delta.md` §D7 conjecture) be *queried* off the
derivation log.

**Exact ontology delta it WOULD make (proposed sketch — NOT applied):**
```jsonc
// grammar_fragment: urn:moos:grammar_fragment:p3-derivation-inference-kind-fg   (status: proposed)
// fragment_kind: "property"  (enum-extension of derivation.inference_kind; mutable, owner-scope)
// specification — extend derivation.inference_kind.values (additive only):
"lowering",   // F leg: project/lower a folded frame onto a so:om surface (run-session-pipeline,
              //         a dashboard, persona-presented-onto-pane). Forward map of the lens.
"lifting"     // G leg: ingest/lift surface activity back into typed nodes/rewrites
              //         (moos-workspace-ingest, Keep-ingest). Backward map of the lens.
// note: names the ADJOINT DIRECTION of the derivation, orthogonal to the mechanism values
//       (a `lowering` may itself be `llm_completion`-driven). Supports D3 persona=Φ(purpose) and
//       D4 presents-as carrying a typed F/G provenance. Poly: forward leg φ₁ / backward leg φ#.
// evidence_urns: [ poly-foundations §3/§4, moos-soom §1, vocab-delta §D7 unit-defect ]
```

**Subtlety (flag for review):** `inference_kind` currently names a *mechanism* (how the inference
ran). `lowering`/`lifting` name a *direction* (which adjoint leg). Mixing two axes into one enum is
the **main design risk** — see below. The conservative alternative is a **separate `fg_direction`
property** rather than overloading `inference_kind`; this proposal presents the enum-extension as
the prompt requested but **marks the orthogonality concern as the lead open question.**

**WF20 path / gate:** **4.0 (alias/bump)** — additive enum extension on a mutable, owner-scope
property, no URN change. Safe in the 4.0 bump *if* the orthogonality question is resolved (extend
enum vs. add `fg_direction` property).

**Risks + open questions.**
- (open, lead) **Axis-mixing:** mechanism vs direction in one enum. Resolve before promotion —
  either accept the overload (and document `hybrid`+direction combos as separate derivations) or
  split out a `fg_direction ∈ {lowering, lifting}` property. Conjecture: the *property-split* is
  cleaner and composes with the unit-defect metric better.
- (risk) Two near-synonyms already exist conceptually: `dag_walk` (a deterministic fold) overlaps
  `lowering` when the projection is a pure fold. Define `lowering`/`lifting` strictly as *adjoint
  legs*, not as any fold.
- (open) Should the **HDC encode/decode fidelity** (unit η defect, `…vocab-delta.md` §D7) be a
  property *on the lifting derivation* (round-trip loss measured at G)? Out of P3 scope; flag for
  the Karpathy seat.

---

## P4 — M11 PreToolUse occupant-guard (WF17 `t_hook`/`gate`) — **OPEN, touches the authority model**

**Conjecture matured (kept OPEN):** §M11 actor-discipline + the so:om "ownership-by-key at the
surface leaf" authority-gradient conjecture (`moos-soom` §4a *Auth at the tentacle end* + §7 G2
*authority gradient*). The idea: a guard (WF17) that, **before an envelope is applied**, blocks it
when its `actor` is not the folded `has-occupant` of the envelope's target `session`/workspace.
This is the kernel-side enforcement of "who is driving this workspace may emit; others may not."

**Why it is only a sketch (and stays open).** This is **not** a clean additive enum — it asserts a
*new gating predicate over the authority model*, which §M11 (liveness) and §M12 (admin capability)
already partly cover. The live mechanism exists: WF17 (`gate` blocks kernel Apply, fail-closed;
`t_hook` fires reactively with optional `guard_ref`). The `session —has-occupant→ {user|agent|group}`
port (WF19, at-most-one) is the relation to fold against. So the *primitive* is there — what is
unsettled is whether occupant-mismatch should be a **hard gate** (block Apply) or a **soft hook**
(propose-and-flag), and how it composes with the ownership-by-key gradient.

**Exact ontology delta it WOULD make (proposed sketch — NOT applied):**
```jsonc
// grammar_fragment: urn:moos:grammar_fragment:p4-m11-occupant-guard   (status: proposed, OPEN)
// fragment_kind: "predicate_shape"
// specification — a new gate/predicate shape, NOT a new type:
{
  "predicate_name": "actor_is_session_occupant",
  "mechanism": "gate",            // WF17 gate: evaluated at kernel Apply, fail-closed (M8)
  "evaluates": "env.actor == fold(target_session.has-occupant).target_urn",
  "on_mismatch": "block",         // OPEN: block (hard) vs propose+flag (soft via t_hook)
  "scope_note": "Pre-Apply guard. Folds the at-most-one WF19 has-occupant LINK of the envelope's
                 target session/workspace and compares to env.actor. Kernel/user actors that
                 legitimately bypass §M11 (SeedIfAbsent, ontology-governed ADDs) must be
                 EXEMPTED — this guard sits ABOVE the existing §M11 inferred-session check,
                 it does not replace it.",
  "authority_gradient_hook": "so:om ownership-by-key (moos-soom §4a) — a surface leaf might prove
                 node-ownership by capability token rather than occupancy; if adopted, this guard's
                 predicate becomes `actor ∈ {occupant} ∪ {key-holders}` — OPEN, not specified here."
}
// evidence_urns: [ moos-soom §4a/§7-G2, kernel-proper §M11/§M12, CLAUDE.md actor-discipline ]
```

**WF20 path / gate:** **needs broad review — likely 4.0.x-class, not a safe-soon bump.** Although
the `predicate_shape` patch is technically additive, its *semantics* change who-may-emit at the
kernel boundary — that is an authority-model change, the heaviest review class. **Do not promote
P4 in the same pass as P1–P3.** It needs the authority-model owner (Sam) to settle the gradient
first.

**Risks + open questions (deliberately left OPEN).**
- (open, blocking) **Hard gate vs soft hook.** A hard `gate` that blocks Apply on occupant-mismatch
  could deadlock legitimate multi-occupant or rotation flows (WF19 occupancy *rotates* via MUTATE).
  A soft `t_hook` that proposes-and-flags is safer but weaker. Unsettled.
- (open, blocking) **Exemption set.** Kernel actor (sweep, ontology ADDs, `opens-on` LINKs), user
  actor inside `SeedIfAbsent`, and multi-workspace agents that set `session_urn` explicitly
  (Wolfram, Cowork) must not be blocked. Enumerating the exemptions correctly *is* the hard part —
  get it wrong and the guard either no-ops or bricks the fleet.
- (open) **Ownership-by-key gradient.** `moos-soom` §4a's capability-token auth at the so:om leaf
  would make occupancy *not* the only legitimate authority. If adopted, the predicate widens to
  `actor ∈ occupant ∪ key-holders`. This is the §7-G2 "authority gradient, not a type wall" — kept
  explicitly OPEN; **P4 does not adopt it.**
- (open) **Relationship to §M12.** §M12 already capability-gates admin rewrites at the M8 gate.
  Does occupant-guarding duplicate or compose with it? Conjecture: composes (M11-occupancy is
  orthogonal to M12-capability) — but unverified.
- (risk) **Liveness coupling.** Folding `has-occupant` at every Apply adds a per-envelope fold;
  zero-occupant (idle) sessions would block *all* actors under a naive `block`. Needs an
  "idle ⇒ permissive" clause.

---

## Sequencing & gate note

**Safe-soon (4.0 alias/bump, additive, no authority change, no URN churn):** **P1, P2, P3** are all
additive enum/property extensions of *existing* types (`workstation`, `channel`, `derivation`) and
follow the exact shape of the already-`merged` `channel.kind-vcs` (v3.13) and `firing_state` (v3.11)
fragments — they can ride the 4.0 bump alongside D1–D8 with normal admin review. P2 is the lowest-
risk (proven enum-extension precedent; fold D5+D7 in one pass as both drafts + governance agreed).
P1 retires the phantom `device` type cleanly. P3 is safe-soon **only after** the one axis-mixing
question is settled (extend `inference_kind` vs add a `fg_direction` property) — flag it for that
decision before promotion. **P4 needs broad review and must not ride the 4.0 bump:** it is an
authority-model change (who-may-emit at the kernel boundary), its hard-gate-vs-soft-hook choice and
exemption set are unresolved, and it is entangled with the still-open ownership-by-key gradient
(`moos-soom` §4a / §7-G2). Treat P4 as 4.0.x-class — settle the gradient with the authority owner
(Sam) first, then decide gate vs hook; keep it OPEN until then.

---
*S0 design draft — not HG truth until G-ingested. All four proposals at `status: proposed`; none
ADDed, none promoted, no `ontology.json` edit, no kernel rewrite, no URN change authorized.*
authored-by: agent:claude-cowork.hp-z440 / session:sam.z440-cowork-workspace / grammar-fragment-proposals
