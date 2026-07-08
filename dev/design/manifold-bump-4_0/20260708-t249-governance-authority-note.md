# T=249 — Governance authority note: four superadmins, four folds

> **Lane:** John Lydon / `session:sam.governance` (identity-relations commission, t248 plan §4 — "the authority").
> **GATE (prose-only):** this note authorizes NO ontology change, NO URN change, NO HG rewrite. Every structural proposal below matures via `grammar_fragment` (`status: proposed`) and the ONE collected WF20 review round per t248 plan §5.2. Rulings recorded here are Sam's (t249, per-question elicitation); staged batches remain Sam-gated per batch.
> **Sources:** live fold readback t_day 249 (all 5 kernels, `/state/nodes` + `/state/relations`) · `moos-kernel/internal/kernel/liveness.go` + `internal/operad/session_context.go` + `occupancy.go` (enforcement code, doctrine inline) · `ontology.json` v4.0.0 · t208 wrap-up (guardrail verbatim) · t247 workstation-reification note.
> **Companions:** `20260707-t248-identity-relations-plan.md` (the commission) · `20260707-t248-mtdc-conceptual-continuity.md` (doctrine seed for §5) · `20260620-t231-grammar-fragment-proposals.md` (P4 sketch this note extends).

## §0 — Commission and scope

The t248 plan dispatched this lane to answer: multi-user §M11/§M12 semantics (four superadmins, four folds — what may cross?); the P4 occupant-guard exemption set; the G3 ruling (family engines: pure ownership vs. birth workspaces); G4 cross-fold identity doctrine; the G6 mutate_scope cleanup fragment; and to extend the cross-persona audit to the twins. All six are addressed. Two findings surfaced en route (F1 authority gap, F2 spine drift) and two hygiene items (H1, H2).

## §1 — Readback: what the gates actually enforce, per fold

§M11 (liveness): a non-kernel envelope's `actor` must resolve to a seated `session` — explicit `session_urn` whose session carries `has-occupant → actor`, or actor-is-an-occupied-session, or a unique inferred reverse `has-occupant`. §M12 (admin capability): admin-scope envelopes (ADD of `system_instruction`/`gate`/`twin_link`/`transport_binding`/`kernel`; MUTATE of `authority_scope: kernel` properties) additionally require principal `—WF02 governs→ urn:moos:role:superadmin`. Both fail closed. Bypass (from `operad.SystemInternalEnvelope`): kernel-URN actors; ADD of infrastructure types (`user`, `workstation`, `kernel`); `SeedIfAbsent` bypasses §M11 structurally.

| Fold | users | sessions | governs → superadmin | net consequence for user actors |
|---|---|---|---|---|
| Z440 `:8000` (primary) | sam | full WF19 seat spine | sam ✓ | live, admin-capable |
| laptop `:8000` | sam | seat spine | sam ✓ | live, admin-capable |
| `:8001` (menno) | menno | **none** | **none** | frozen (see theorem) |
| `:8002` (lola) | lola | **none** | **none** | frozen |
| `:8003` (moos) | moos, sam (guest) | **none** | **none** | frozen |

**Frozen-twin theorem (corrected form):** for every rewrite *except* ADDs of infrastructure types and `SeedIfAbsent`, the twins accept only kernel-actor envelopes today — LINK/MUTATE/UNLINK have no infra bypass and no session exists to seat any actor; `kernel`-type ADD is additionally kernel-actor-only via §M12 fail-closed. The family users are, in the t168 phrase, "alive in the categorical sense of having an identity morphism, but incapable of non-identity moves" — on their own engines.

**Finding F1 (authority gap, security-class).** The infra-ADD bypass is **actor-agnostic**: any actor — agent, user, group, seated or not — can today ADD a `user` or `workstation` node on any fold, including a *second* `user` on a twin. §M12 catches only the `kernel`-type ADD. Meanwhile the T=208 guardrail (t208 wrap-up, verbatim: *"Do not create new `user` nodes for private Gmail, Workspace accounts, Menno, Lola, Moos, or external identities without a separate identity-design decision."*) and the `user` type's own doctrine sentence (*"Exactly one user per kernel. Superadmin of their own graph."*) are enforced by prose alone — the exact rewrite class the guardrail prohibits is the class both gates wave through. **Disposition:** flag as a P4-adjacent hardening candidate (a narrow gate on `user`-type ADD, or a one-user-per-fold operad invariant); deliberately NOT bundled into P4 (§3), which is occupancy-shaped, not type-shaped. Reserved for Sam with the WF20 round.

## §2 — Ruling R1: §M11/§M12 are fold-local (strict sovereignty)

**Ruled by Sam, t249.** Fold-locality is *doctrine*, not implementation accident: `ResolveSessionForEnvelope` folds the local graph only, and that is correct behavior. A session on `:8000` cannot seat an actor on `:8001`. Four superadmins therefore span four disjoint capability spaces; no authority crosses a fold boundary. What crosses today — kernel actors and the F1 carve-out — is infrastructure, not authority. Cross-fold *acts* are reads: router fan-in (`:9000`) is the only legitimate cross-fold surface, and it is read-only. `user:sam`'s presence on `:8003` is a **guest node**: local paperwork filed on Moos's fold (a workstation `owns` relation), carrying no governs, no capability, no seat. Guest presence is legal (§5, clause 2) and confers nothing.

Consequence for envelope authoring: an agent emitting to a twin (post-R2) must hold a seat *on that twin's fold* — a primary-fold seat grants nothing across the boundary. Multi-workspace agents keep explicit `session_urn` per the existing discipline, and that URN must name a session folded on the target kernel.

## §3 — P4 occupant-guard: exemption set (soft-hook-first)

**Ruled by Sam, t249: soft hook first.** The guard lands as WF17 `t_hook` (propose-and-flag, never blocks), not `gate`. Promotion to a hard gate is deferred until observed firings establish the false-positive rate — the t231 sketch's brick-the-fleet risk is real precisely because the exemption enumeration is the hard part. The predicate is unchanged from P4: `env.actor == fold(target_session.has-occupant).target_urn`.

Exemption set (proposed for the WF20 review):

| # | Exempt | Why |
|---|---|---|
| E1 | kernel-URN actors | below the governance line; sweep, ontology ADDs, WF19 `opens-on` |
| E2 | `SeedIfAbsent` envelopes | bootstrap precedes any session; §M11's own structural bypass |
| E3 | ADD of infrastructure types | mirrors §M11's bypass — the guard sits ABOVE the existing check, never below it (but see F1: this exemption inherits the same gap and narrows if F1's hardening lands) |
| E4 | zero-occupant (idle) target session | idle ⇒ permissive; an unoccupied workspace blocks nothing |

**Explicit non-exemption:** multi-workspace agents with explicit `session_urn` are the guard's *primary subjects* — the predicate exists to check exactly their claimed seat. Exempting them would no-op the guard.

**Composition with §M12 — conjecture, marked as such:** occupancy (liveness axis) and capability (authority axis) are orthogonal; the guard composes with, and never substitutes for, §M12. Verification is a runtime-lane item (Wolfram) and rides the G5 loader-gap verification, since both require reading what the loader actually enforces.

The ownership-by-key gradient (`moos-soom` §4a) stays OPEN and unadopted, as in the t231 sketch.

## §4 — Ruling R2: G3, birth workspaces for the family engines

**Ruled by Sam, t249: birth workspaces.** The options were: (A) pure-ownership monuments — honest, zero motion, family users stay frozen (§1 theorem) until §M9 twin-sync; (B) birth workspaces — per twin, ADD one `session` + WF19 LINK `has-occupant → user:<name>`, kernel-actor-emitted (session ADD has no infra bypass), plus a `role:superadmin` node and WF02 `governs` LINK so §M12 has something to walk. Sam ruled **B**: the minimal liveness kit. Each being gets a stage with a band on it — §M11 path 1/3 becomes resolvable for the owner, and admin scope opens through the owner's own WF02 `governs` LINK to `role:superadmin` rather than staying kernel-actor-only.

**T=208 disposition:** the guardrail asked for "a separate identity-design decision" before family identity work; this commission and ruling *are* that decision, recorded here. The batch touches **relations and non-user nodes only** — no new `user` nodes; the seed-era family users (2026-04-10 birth certificates) are the grandfathered substrate this ruling finally furnishes.

**Staging (Sam-gated, NOT applied):** one kernel-actor batch per twin — `ADD session:<name>.birth-workspace` · `LINK has-occupant → user:<name>` · `ADD role:superadmin` (per-fold node; URN-equal across folds per §5) · `LINK user:<name> —WF02 governs→ role:superadmin` · `LINK session —WF19 opens-on→ kernel:hp-z440.<name>`. Envelope drafts belong to the WF20 round's paperwork, shaped per `moos-rewrite-envelope`. Timing vs §M9 is Open Question 2.

## §5 — Doctrine D: cross-fold identity (G4)

**Ruled by Sam, t249.** Three clauses:

1. **URN-equality is identity.** The same URN on any fold denotes the same being. There is no cross-fold reference relation and none is needed — the URN *is* the cross-reference card. (Doctrine seed, mtdc dossier: "the beings precede and outlive any single representation.")
2. **Asymmetric presence is legal.** A being's node exists on a fold when that fold has paperwork involving the being — presence is demand-driven, never sync-driven. Absence ≠ nonexistence, and **absence is not a delta**: t248 produced two false "missing node" claims in one day from primary-only readbacks, and the per-fold cardinal rule (readback skill, post-#134) is the operational form of this clause. The t247 spine reconciliation deliberately left the twins untouched; that was correct.
3. **Spine-shape may differ per fold.** The twins' direct `user —WF01 owns→ kernel` and the primary's `user —owns→ workstation —WF03 hosts→ kernel` are both legal realizations; identity does not require isomorphic local topology.

**Audit consequences (folded into `moos-cross-persona-audit` this round):** when auditing twins, absence-flags are suppressed (clause 2); what IS flagged: same being under a *different URN form* — which violates clause 1.

**H1 (violates clause 1, listed not executed):** duplicate workstation URN forms live now — `urn:moos:workstation:hp-z440` and legacy `urn:moos:ws:hp-z440` coexist on `:8000`, and laptop `user:sam —owns→` points at the *legacy* form. Reconciliation (UNLINK + re-LINK to the canonical form, kernel-actor) is a separate Sam-gated batch.
**H2 (doc hygiene):** the canonical M-series doctrine file `kb/research/kernel/20260417-t187-kernel-proper.md` is absent from this checkout — §M11/§M12 are cited here from enforcement code and surviving archive restatements; cite by archive path until the doctrine file is restored.

## §6 — G6: mutate_scope cleanup — two fragments

Split by review-risk class (house precedent: P1–P3 vs P4): pruning is subtractive and cannot widen authority; orphan adoption grants MUTATE paths that do not exist today. Independently rejectable; both ride the collected WF20 round.

```jsonc
// grammar_fragment: urn:moos:grammar_fragment:g6a-mutate-scope-prune   (status: proposed)
// fragment_kind: "wf_clause" — subtractive mutate_scope edit on two rewrite_categories:
{
  "WF19": { "mutate_scope_remove": ["status", "turn_count", "role", "seat_role"],
            "mutate_scope_keep":   ["local_t", "context_urn"] },
  "WF07": { "mutate_scope_remove": ["status", "turn_count", "role"] }
}
// Removes properties deprecated v3.9–v3.12 (removal scheduled since v3.10/v3.13) from the
// scopes that still grant them. No new authority. WF20 class: safe bump.
```

```jsonc
// grammar_fragment: urn:moos:grammar_fragment:g6b-orphan-property-adoption   (status: proposed)
// fragment_kind: "wf_clause" — give mutable/owner properties currently in NO WF a legal MUTATE home:
{
  "WF02": { "mutate_scope_add": ["max_rewrites", "invocation_protocol", "board_id"] }
}
// capability.max_rewrites, agent.invocation_protocol, agent.board_id are declared mutable
// (authority_scope: owner) but appear in no rewrite_category's mutate_scope — they cannot be
// legally MUTATEd at all. WF02 is the natural home (tgt_types already [agent, role, capability];
// existing scope is agent-config-shaped). Mild authority widening — review separately from g6a.
// (open) mutate_scope is per-WF and type-blind; property-name collisions across tgt_types argue
// for a per-tgt_type scope shape eventually — not proposed here.
```

## §7 — F2: relational-spine drift correction (`delegates-to` → `governs`)

AGENTS.md's spine (mirrored in `.claude/rules/seat-context.md`) reads `user/group —WF02 delegates-to→ agent`. The declared grammar disagrees on both ends: `user`'s out-ports are `[owns, governs]` (no `delegates-to` port), and WF02's `delegates-to/delegated-by` is an *additional pair* `role|group → role` (v3.13, capability narrowing). The live folds agree with the grammar: every authority relation in existence is `governs` (sam → 6 agents + `role:superadmin`, primary + laptop). No charitable reading survives — the spine line uses a *distinct declared port pair of the same WF* for the wrong relation, which is exactly the drift class the nomenclature block prohibits.

Corrected spine lines (applied to both files in this commit — prose projection, not WF20 material; readback wins per the SOT hierarchy):

```
user/group  —WF02 governs→  agent          (delegation authority; delegated role/capabilities ride WF02 properties)
role/group  —WF02 delegates-to→  role      (capability narrowing, v3.13 — role-to-role, never user-to-agent)
```

Nuance (cross-ref G5): the v3.12-era loader may not consume `additional_port_pairs` at all, so `delegates-to` may be declared-but-unloaded — a runtime question for the Wolfram lane, irrelevant to the prose correction.

## §8 — Open questions

- Does F1's hardening (guardrail-as-gate on `user`-type ADD / one-user-per-fold invariant) land as P4's sibling predicate or as an operad invariant — and does E3 then narrow?
- Does the R2 birth-workspace batch precede §M9 twin-sync or wait for it? (Sequencing only; the ruling itself is made.)

---
authored-by: agent:claude-cowork.hp-laptop / session:sam.governance / governance
