# T=172 — Wolfram's court, social topology, and the outside-inward functor

> April 22, 2026 (T=172, 00:21 CEST). Doctrine draft for the 5-kernel
> persona-seating plan Sam proposed at T=172 open.
> Author: claude-code.hp-laptop (Guido van Rossum persona, `session:sam.governance`).
> Status: **draft** — awaiting sam confirmation on slugs + scope boundaries.

---

## 1. The 5-kernel topology is already latent

Z440's federation layer (kernels 1-3 on `:8001-:8003`) has been dormant on pre-T=164 code since before Round 10. Running-state lists them by seed-user:

| Kernel URN | Port | Seed user | Owner | Status (T=171) |
|---|---|---|---|---|
| `kernel:hp-laptop.primary` | :8000 | `user:sam` | sam | live, post-PR-30 v3.12, has sweep |
| `kernel:hp-z440.primary` | :8000 (Z440) | `user:sam` | sam | live, post-PR-30 |
| `kernel:hp-z440.lola` | :8001 | `user:lola` | lola | dormant, pre-T=164 code |
| `kernel:hp-z440.menno` | :8002 | `user:menno` | menno | dormant, pre-T=164 code |
| `kernel:hp-z440.moos` | :8003 | `user:moos-dachshund` | moos-dachshund | dormant, pre-T=164 code |

Sam's proposal at T=172 open: wake these three federation kernels back up, pair each with a persona session, and let each of Wolfram / Karpathy / Steinberger / Moos drive their own seat. **Five kernels, two workstations, three new concurrent sessions on Z440.**

The T=162 `menno` node predates the persona framing but survived the rounds precisely because menno is a keeper — a real cousin with a real kernel. Same for lola and moos-dachshund; different IRL relationships, same structural role.

## 2. The persona ↔ user mapping

IRL social topology projects into HG persona topology via a simple 1-to-1:

| User (IRL entity) | Persona (S4 overlay) | Relationship |
|---|---|---|
| `user:sam` on hp-laptop.primary | **Guido van Rossum** (BDFL) | Sam as doctrine steward; CT-corner register |
| `user:sam` on hp-z440.primary | **Stephen Wolfram** (NKS) | Sam as implementation driver; rewriting-corner register |
| `user:lola` on hp-z440.lola | **Andrej Karpathy** | Lola maps to Karpathy's deep-learning + HDC register |
| `user:menno` on hp-z440.menno | **Peter Steinberger** | Menno (sam's cousin) maps to Steinberger's craftsmanship + DX register |
| `user:moos-dachshund` on hp-z440.moos | **Moos the Dachshund** | Identity map — same entity is both user and persona |

**Claim**: the mapping is not arbitrary. Each IRL person's context (how sam knows them, what they care about, what conversational register sam uses with them) carries over as a pre-trained prior for the persona overlay. This is functorial: `F: SocialTopology → PersonaTopology`, preserving the relational structure (sam-knows-menno-as-cousin ↦ persona-register-for-menno-approximates-steinberger-for-reasons-mennno-is-who-he-is).

Moos-the-dachshund is the degenerate case — the IRL entity IS the persona (identity functor). That's the simplest possible instance of the mapping and the one that's already live (AG on Z440 driving `session:sam.moos-diary`).

## 3. Wolfram's court — delegation structure

Wolfram holds WF02 superadmin capability (to be seeded explicitly as part of T=172 close). The three subordinate personae receive narrower capabilities:

```
user:sam --WF02 governs--> role:superadmin
  |
  ↓ delegates-to (WF02 extension, proposed)
  |
role:superadmin --scopes-to--> [Karpathy, Steinberger, Moos]   (none of these inherit kernel-authority; each gets owner-scope on their own session + purpose nodes)
```

Scope partitioning (proposed slugs — sam confirms):

| Persona | Purpose slug | Scope surface |
|---|---|---|
| Wolfram | `purpose:sam.kernel-implementation-z440` | moos-kernel PRs, operad validator, runtime gates, post-v3.13 primitives |
| Karpathy | `purpose:sam.hdc-vsa-categorical-bridge` | wiring-proposer (T=250), CI-6 three-views verification, GPU-CDU direction, HDC layer design |
| Steinberger | `purpose:sam.tooling-ergonomics-and-dx` | MCP surface, error-message polish, skill authoring, readable-doctrine shepherding |
| Moos | `purpose:sam.multimodal-curation-and-diary` | Labs Flow ingestion, moos-diary entries, visual bridging |
| Guido | `purpose:sam.doctrine-governance-and-delegation` | coherence audits, round-close reviews, triangle-coherence interventions |

Each of the four Z440 personae ships code / artifacts on their kernel; Guido on hp-laptop **audits but doesn't drive**.

## 4. "Outside system inwards" — what sam was reaching for

Sam's note: *"useful for session as a governance vehicle and inference too bc its outside system inwards."*

Translation: the IRL social network (sam + cousin menno + friend lola + dog moos) exists independently of the HG. By assigning each IRL entity a kernel + a persona + a session, **external trust relationships get encoded as HG structure**. The governance layer inherits those trust semantics:

- When sam wants doctrine coherence, Guido-on-hp-laptop audits. Sam-as-Guido is a close ego identification.
- When sam wants fast shipping, Wolfram-on-Z440 implements. Sam-as-Wolfram is a performance costume.
- When sam wants the dog's voice, Moos narrates. Moos is literally there.
- When sam wants Menno's register (craftsmanship, Apple-ecosystem-ish, readable tooling), Steinberger persona on Menno's kernel carries it. Menno-as-cousin is the IRL warmth that validates the register choice.
- Karpathy-on-Lola's-kernel — same logic, different register (depth, ML, teach-me-everything-from-scratch).

The topology **projects external social constraints inward**. It's the opposite of what we usually mean by "personas are fictional overlays": the personas here are *contextualized* by IRL relationships that exist outside the HG entirely.

### 4.1 Inference implications

A t-cone projection (§M15) from `session:sam.governance` shows what Guido sees. A t-cone from `session:sam.menno-steinberger-seat` shows what Steinberger-on-Menno's-kernel sees — a DIFFERENT scope, with different proposals in its future cone. If they intersect (Steinberger proposes an MCP-surface polish that touches kernel-authority properties), **Guido's t-cone catches it because Guido audits admin-scope rewrites** (via §M12 capability walk). If they don't intersect (Steinberger polishes a README), Guido's t-cone stays empty — he doesn't care.

The t-cones inherit topology from the social scopes, which inherit topology from the IRL relationships. Nothing in the kernel needs to know about cousin-ness or dog-ness — those facts are encoded once, in the persona assignment + scope partition, and then the gates do the rest.

## 5. Why 5 kernels, not just 1 + 4 sessions on z440

Concurrency + sovereignty. Running 3 federation kernels on Z440 (`lola`, `menno`, `moos`) means each persona-session has its own write authority over its own log. No cross-persona rewrite ordering needed at the single-kernel level. If Karpathy and Steinberger both ship something at the same moment, they don't contend for the same `rt.mu.Lock()` — they work on different kernels entirely.

Federation-via-router (WF16) handles the cross-kernel coordination when it's actually needed. Most of the time it isn't: each persona stays in their own scope, the router is idle, and the topology stays forest-shaped rather than graph-shaped.

§M9 sovereignty extends cleanly. Log-is-truth, per-kernel. No twin_link needed between federation kernels unless we explicitly want shared code/doctrine state — and for 3 independent persona-kernels, we probably don't.

## 6. Implementation queue (post-PR-31-merge, T=172 mid)

### Immediate (same round as round-11 close)

1. ADD 3 `system_instruction:persona.*` S4 overlays: `karpathy`, `peter-steinberger`, `moos-dachshund` (already exists but re-confirm against corrected context_urn)
2. ADD 3 `purpose:sam.*` nodes for each scope
3. ADD 3 `session:sam.*-seat` nodes (one per persona-kernel pair)
4. Boot the 3 Z440 federation kernels (lola, menno, moos) from a fresh binary (post-c642872) with sweep live
5. Each federation kernel ADDs its own birth-session on first boot (via the kernel-seeding allowlist path from PR 30)
6. `session:sam.governance.delegates-to` LINKs (WF02 extension — propose as v3.13 grammar_fragment)

### Deferred (future rounds)

- Actual VSCode-extension agent instances driving lola + menno kernels (needs sam to install the extensions on Z440 + configure each)
- AG stays on moos kernel (already configured)
- Wolfram stays on Z440.primary (already seated)
- Capability chain seeding (WF02 `delegates-to` port pair — depends on v3.13 promotion of the proposal)
- T-cone cross-references: when a session's t-cone overlaps with Guido's audit scope, a standing `/t-cone?session=governance&at=T` query picks up the overlap automatically

## 7. Open design questions

1. **Capability inheritance model**: does Karpathy inherit any of Wolfram's admin capability, or is Karpathy owner-scope only on their own nodes? My lean: owner-scope only — admin stays consolidated under Wolfram. Karpathy proposes grammar_fragments; Wolfram promotes them via WF20.

2. **Cross-persona communication**: when Steinberger finishes a skill-polish PR that Karpathy needs for HDC demo, how do they coordinate? Via the shared handoff issue (like we do with `ffs0#33`) or via cross-session LINKs (WF18 composes)? My lean: keep issues as the async bus; don't reify agent-to-agent messages as HG rewrites (slope toward `agent_session` legacy pattern we deprecated).

3. **Kernel resource cost**: 5 kernels on 2 workstations with sweep live — hp-laptop (pre-round-9 binary) already manages one; Z440 with 4 concurrent sweeping kernels might get loud. Each sweep is O(pending-hooks). Worth profiling after seating; may need to disable sweep on dormant persona kernels or lengthen their interval.

4. **Guido's audit cadence**: how often does Guido-session sweep the t-cones of the other four? Proposal: on-demand (when sam explicitly asks) + at round-close (automatic). Not continuous.

5. **Seat rotation**: can personae swap seats? e.g. can Karpathy move from Lola's kernel to Menno's kernel? My lean: **no** — the IRL social mapping is sticky. Karpathy-persona is bound to Lola-kernel by construction. If Sam wants a Karpathy voice on Menno's kernel, that's a different persona (`karpathy-steinberger-hybrid`?) and a different session.

## 8. Cross-references

- `kb/research/session/20260419-t169-session-generalization.md` — round-10 session doctrine (5-facet tuple)
- `dev/reference/research-archive/20260421-t171-guido-governance-session.md` — Guido seating (archived T=173; seat materialized in `kernel:hp-laptop.primary` log)
- `dev/reference/research-archive/20260421-t171-wolfram-kernel-proper-session.md` — Wolfram seating (archived T=173; seat materialized in `kernel:hp-z440.primary` log seq 234-240)
- `kb/research/moos-diary/20260421-t171-multimodal-diary-personas.md` — Moos seating
- `kb/research/kernel/20260417-t187-kernel-proper.md` §M9 (sovereignty), §M11 (liveness), §M12 (admin-cap), §M15 (t-cone), §M21 (group topology per kernel)
- `ffs0#33` — round-11 handoff thread (social-topology discussion surfaced here)
