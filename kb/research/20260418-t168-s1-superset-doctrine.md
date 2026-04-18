# S1 as semantic embedding superset

> T=168 (April 18, 2026). Companion to `20260418-t168-v3.9-ontology-audit.md` §F.
> Origin: sam — "s1 should provide semantic embedding for new grammar and types from the s4. imho this is one of the main issues we need to dive into."

## The problem

Today mo:os has one-way ingress from S1 to S4:

```
S1 grammar (types, WFs, ports) ───── constrains ────▶ S2 instances ──── overlays ────▶ S4 system_instructions
```

S1 is immutable-from-the-graph: no node authored at S2 or S4 can extend it. A user writing a `system_instruction` can guide a session, can gate WF exercise, can forbid operations — but cannot say "this pattern I keep expressing should become a new port, a new type, a new WF clause."

The consequence: natural language, intent, purpose, and all the "what I really meant" of a user live ungrounded in S4 (as free-form text) without ever feeding back into S1's formal vocabulary. S1 grows only by human edit of `ontology.json`.

Sam's ask: close the loop. Give S1 an **absorption pathway** for S4 observations.

## The pattern — an adjoint pair

```
             Promote (left adjoint)
         ┌──────────────────────────▶
  S4     │                            S1
observed │                           grammar
 patterns│                          generators
         ◀──────────────────────────┘
             Express (right adjoint)
```

Two functors, composed in a unit/counit pair:

- **`Promote : S4 → S1`** — given a pattern observed in S4 context (repeated phrases, structurally similar instructions, crosscutting concerns), propose a new S1 generator: a type, a port, a WF clause, a predicate shape.
- **`Express : S1 → S4`** — given an S1 generator, render it as a form an occupant could instantiate in a system_instruction. Every S1 type must be round-trippable through natural instruction language.

**Unit** (η : Id_{S4} → Express ∘ Promote): any S4 pattern that gets promoted to S1 is also expressible back into the instruction language — nothing is "lost" in the formalization that could not be named in the first place.

**Counit** (ε : Promote ∘ Express → Id_{S1}): any S1 generator's natural-language expression, when observed in S4 at sufficient frequency, promotes back to the same (or equivalent) S1 generator — the grammar is stable under its own observation.

This is the universal property that makes S1 a **semantic embedding superset**: it is the free category on all patterns that any user or agent would formalize, given they see the pattern often enough.

## The graph objects that implement the pattern (v3.9 minimum)

- **`grammar_fragment` (S1, new in v3.9)** — a proposed extension carrying: a candidate type/port/WF clause, the evidence (source S4 nodes), and status (`proposed | promoted | rejected | merged`).
- **`pattern` (S1, new in v3.9)** — a first-class template class that both t-hooks and grammar_fragments can reference. Generalizes `t_hook.react_template`.
- **`WF20 grammar_promotion` (new in v3.9)** — the rewrite category that carries `Promote`. Src: `system_instruction`, `governance_proposal`. Tgt: `grammar_fragment`. Authority: admin.
- **`governance_proposal` (S0–S2, existing)** — the evidence aggregator. Already in v3.8; v3.9 clarifies it as a Promote evidence-carrier.

## The pipeline (end-to-end, ungated for now)

```
1. Occupant writes system_instructions in a session (normal §M7 behaviour)
2. An observer (manual or automated) notices a recurring structural pattern across multiple S4 instructions
3. Observer authors a governance_proposal citing the S4 nodes as evidence_urns
4. Admin (WF20) ADDs a grammar_fragment with status=proposed, links evidence
5. Admin review: either
   a. MUTATE status → rejected
   b. MUTATE status → promoted (carries into next ontology.json as a real type/port/WF)
   c. MUTATE status → merged (shorthand for promoted + applied)
6. On merged: the ontology.json gets the new generator; version bumps (e.g. 3.9 → 3.10)
```

Steps 2–3 are **not automated in v3.9** — they are human-driven. v3.9 only gives the nouns and a verb (WF20). Step 6 requires a real publishing flow (§M16, still draft).

## Why the adjoint shape matters

Not every "add a type" flow is an adjoint. Many are just: user proposes, committee accepts, artifact lands. What the adjoint adds:

- **Coherence invariant.** An S1 type cannot survive in v3.9+ if it can't be expressed in S4 (the counit ensures naturality). Forces every formal type to have a natural-language idiom, which in turn lets new users instantiate it.
- **Expressiveness bound.** S1 is exactly as large as the patterns reliably observed in S4 across all users — no larger, no smaller. This resists both ossification (adding types no one uses) and starvation (patterns stuck in S4 that should be formal).
- **Composability.** Adjoints compose. If we later define Promote'/Express' between S4 and some external schema (industry taxonomy: skill, harness, workflow, benchmark), the composition Promote' ∘ Promote gives a direct pathway from external vocabulary into S1 via the intermediate S4.

## What this unlocks

- **Industry-standard concepts adopt themselves.** "Skill," "harness," "workflow," "benchmark" were added in v3.9 (D2, D5, D6) because an audit noticed they kept surfacing in discussion and T=164/T=187 research notes. Future concepts surface through the same pipeline — no architect decree required.
- **User DSLs become first-class.** An agent or user can accumulate their own idiomatic types in S4 (via repeated system_instructions). When those patterns harden, WF20 promotes them.
- **Ontology growth is audit-trailed.** Every new S1 generator carries its evidence_urns. v3.10's changelog becomes a real diff between observed and formalized reality.
- **Cross-kernel ontology sync becomes tractable.** §M16 ontology_publication carries grammar_fragments along with canonical types; user kernels see both the current grammar and the in-flight proposals.

## What it does NOT do (anti-scope)

- **Not an inference engine.** v3.9 does not propose types automatically. Humans still author governance_proposals and promote them. The adjoint is a *design principle*, not an algorithm — not yet.
- **Not a replacement for S1 curation.** Admin authority over WF20 remains. Gatekeeping is explicit, not emergent.
- **Not a DSL engine.** v3.9 lacks `dsl` type (deferred). Grammar extensions are one-shot generators (a type, a port, a WF clause), not executable languages.

## Open questions (for later rounds)

1. **Evidence aggregation.** How many S4 instances, how much structural similarity, over how long a window, qualifies a pattern for promotion? Needs to be spec'd before automation.
2. **Embedding calculation.** "Semantic embedding" in the name of this doc implies a metric. The HDC layer (T=163) gives a natural cosine-similarity between node fingerprints — can it ground the "same pattern" judgment?
3. **Adjoint verification.** The unit/counit laws are claimed here. Verifying them requires enumerating all S1 generators and checking each has an S4 expressibility witness. Doable manually at v3.9 scale (45 types → 51 types); may need tooling as S1 grows.
4. **Rejection semantics.** If a pattern is proposed and rejected, what prevents it from being re-proposed next week? Need a `blocked_until` or `rejection_reason` on grammar_fragment.
5. **Relationship to `crosswalk` (existing S1 type).** A crosswalk is the "graph-native witness of natural transformation" between classification schemes — that's already an adjoint-adjacent primitive. Is `crosswalk` the canonical way to record an Express witness? Almost certainly yes. v3.10 should formalize.

## Cross-references

- `kb/research/20260418-t168-v3.9-ontology-audit.md` §F — Finding that motivated this doctrine
- `kb/research/20260417-t187-kernel-proper.md` §M7 — system_instruction as S4 overlay (predecessor)
- `kb/research/20260417-t187-kernel-proper.md` §M16 — ontology_publication (the publishing side)
- `kb/superset/ontology.json` v3.9 — types `grammar_fragment`, `pattern`, `crosswalk`, `classification_schema`, `governance_proposal`; WF20
