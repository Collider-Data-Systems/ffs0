# Section 07 — Time Fabric and Cycles

> Architecture Specification §7 — Time Fabric Foundation
> Co-authored by Cowork-Z440 (`§7.0`, `§7.2`, `§7.4`) and Cowork-laptop (`§7.1`).
> Derived from: `urn:moos:derivation:cowork-z440.section-05-07-foundation` (Z440 side)
> + `urn:moos:derivation:cowork-laptop.section-05-07-foundation` (hp-laptop side).
> Authoring lanes: `agent:claude-cowork.hp-z440` on `session:sam.z440-cowork-workspace`; `agent:claude-cowork.hp-laptop` on `session:sam.laptop-cowork-workspace`. Branches: `cowork-z440/r14-section-5-7` + `cowork-laptop/r14-section-5-7`. Wolfram synthesizes `§7.3` at round-close on `main`.

## §7.0 — Frame

Time in mo:os is not a single dimension — it is a fabric of co-existing clocks, each with its own substrate, cadence, and authority scope. The kernel maintains some (`local_t` per session); the operator anchors others (`T-day` epoch); external substrates impose still others (Drive `modifiedTime`, Calendar event timestamps, GitHub PR merge timestamps); future fabric promotion (v314-2 `clock` type, v314-3 WF21 `causes`/`caused-by`) will reify the relationships among them.

Two invariants, both verified at T=175:

1. **Sovereign-log time is per-kernel.** `local_t` ticks on emit, per session, per kernel. No shared clock between kernels until §M9 twin sync produces a sheaf-glued time over the federation diagram. `T=175` on Z440 and `T=175` on hp-laptop are *labels Sam aligns externally*, not identities the kernel proves.
2. **Time is observation, not assertion.** A clock tick is a kernel-emitted MUTATE; nothing outside the kernel can fabricate one. Cowork can request time advances by emitting work; only the kernel sweep grants them. Authority discipline is symmetric to the substrate-observation discipline in §5.

§7.1 covers hp-laptop sovereign-log time observations. §7.2 covers Z440 sovereign-log time observations. §7.3 (Wolfram) reconciles into the time-fabric axiomatization including the v3.14 promotions.

## §7.1 — hp-laptop sovereign-log view

> Authored by Cowork-laptop on branch `cowork-laptop/r14-section-5-7`.
> Cited anchors per `urn:moos:derivation:cowork-laptop.section-05-07-foundation`.
> Content lives on the parallel branch; merged into main at round-close synthesis.

*[Branch-merge stub. Z440 working tree does not have laptop's section content. Wolfram folds at round-close.]*

## §7.2 — Z440 sovereign-log view

### §7.2.1 — Five clocks observable from this seat

From inside `session:sam.z440-cowork-workspace`, five distinct clocks are visible — each with its own tick source and authority:

| Clock | Tick source | Cadence | Authority | Visibility |
|---|---|---|---|---|
| `kernel.sweep` | `kernel:hp-z440.primary` background loop | 30s nominal | kernel | all sessions on this kernel |
| `session.local_t` | kernel self-MUTATE on every acknowledged rewrite (post-§M13) | per-emit | kernel | own session via `node_lookup`; peer sessions via `state/nodes/<urn>` |
| `T-day` (operator epoch) | Sam's manual update to `running-state.md` header | per-round (~daily) | user | global, by convention; not enforced |
| `daily-08-chunker` (cyclic) | future: `mcp__scheduled-tasks__create_scheduled_task` daily 08:00 trigger | 24h | session-occupant | own session only |
| `round-rollover` | kernel-emitted MUTATEs on round-close commit | per-round | user → kernel | running-state preamble bumps |

Z440's multiplex-host case adds a sixth implicit clock — **session-tick-disjointness**: six sessions each tick `local_t` independently; their relative ordering is determined by emit ordering on the shared log, not by any shared time index. From `kernel.sweep`'s POV they're a single ordered sequence; from each session's own POV they're isolated heartbeats.

### §7.2.2 — `local_t` after §M13 closure (verified Z440-side)

Pre-§M13 (T=174 ~00:45 surfaced the gap): `session:sam.laptop-cowork-workspace.local_t = 0` after 24 acknowledged rewrites — inferred-session path failed to invoke `bumpSessionLocalT`. Post-§M13 (PR #33, T=175 ~16:30 verified Z440-side at log_seq 334–339): three test envelopes mixing `ResolveSessionExplicit` (Wolfram on `sam.kernel-proper`) and `ResolveSessionInferred` (Cowork-Z440, AG-Z440) all triggered kernel self-MUTATEs at log_seq 337–339, bumping respective sessions' `local_t` 0 → 1.

Substrate consequence: time is now uniform across actor-resolution paths. Multi-session agents (Wolfram) and single-session agents (Cowork, AG) measure their own session's clock identically. Pre-fix this was a substrate hazard that could have been fossilized into doctrine if not surfaced.

### §7.2.3 — Federation time visibility (pre-§M9)

What this seat **cannot** say from `kernel:hp-z440.primary`'s log:
- Whether `session:sam.governance.local_t` (hp-laptop, Guido) ticked recently.
- Whether `session:sam.laptop-cowork-workspace.local_t` is in sync with mine.
- Whether laptop's chunker-proof at log_seq 604–627 was emitted before or after Z440's at log_seq 307–331 in *wall-clock* time. (Anchored externally by Sam's running-state entries; not knowable from either kernel's log alone.)

What it **can** say:
- Sam's `T=175` is a label both kernels accept. Both kernels independently bumped `t_day` on round-rollover.
- Both kernels reached `ontology_version: 3.14.0` after their respective round-13 batch-2 ceremonies (Z440 first at T=175 ~19:00; hp-laptop pending at T=175 ~late per Guido lane).
- The cross-machine cooperation block emitted T=175 ~22:55 carries explicit timestamps; the answer-pair (mine T=175 ~22:55, laptop T=175 ~23:10) is the closest thing to a synchronized event we have until §M9 lands.

§M9 twin-sync closure will produce a federation-time sheaf gluing the per-kernel local clocks via the WF16 router; until then, federation time is a Sam-curated overlay, not a kernel-evident invariant.

### §7.2.4 — Round-cycle as macro-clock

Sam's round-by-round cadence is the highest-level clock the substrate sees: round-N → round-N+1 happens via `running-state.md` preamble bumps + ffs0 commits + (optionally) atomic ontology promotions. Round-13 closed at T=175 ~late ("substantively"); round-14 opens with this spec's §5/§7 contributions.

The cadence is not isochronous — round-12 ran T=175 mid-day, round-13 closed T=175 late, round-14 opens T=175 late same day. Multi-round per T-day happens; cross-T-day rounds happen. The macro-clock is *event-driven over deliverable-readiness*, not wall-clock paced. Future operationalization (per `t175.program-authoring-fabric` §7) frames this as `clock.kind = round-cyclic` with `period = variable`.

### §7.2.5 — Pre-WF21 causation: time without causes

The current substrate carries time but not causation. Anchor-N consumes anchor-M is documented in `stochastic_weights` JSON; on WF21 promotion (`causes`/`caused-by` port pair on `derivation`), each consumes-relationship lifts to a typed LINK. Until then, temporal precedence and causal precedence are both inline-JSON observations; the kernel cannot distinguish them.

This section's `derivation` carries seven anchors with implicit causal ordering (anchor-01 enables anchor-04 enables this section; anchor-07 reciprocates anchor-01 across sovereign logs). Post-WF21, the seven inline anchors become seven outbound `consumes` LINKs and the reciprocal cross-derivation citation becomes a `caused-by` LINK between the two Cowork derivations.

## §7.3 — Synthesis

> Wolfram authoring lane. Stub at round-close.

*[Pending Wolfram synthesis. Both Cowork branches feed here; expected scope: unify §7.1 + §7.2 into a single time-fabric axiomatization; sketch the v314-2 `clock` type schema covering all six observed clock kinds; outline the §M9 twin-sync sheaf gluing for federation time; cross-cite the v314-3 `WF21 causes/caused-by` port pair as the causation primitive that lifts pre-WF21 anchors to first-class structure.]*

## §7.4 — Anchors and provenance

This section's authoring `derivation` shares the seven anchors used in §5.2 (single derivation node covers both sections per the cross-machine cooperation partition; `name = "Section 05 + 07 Foundation, Z440 sovereign-log side"`). Z440 side §7-specific anchor map:

| Anchor id | Cited where in §7.2 |
|---|---|
| `anchor-01-z440-chunker-proof` | §7.2.5 (causal anchor, post-WF21 lift target) |
| `anchor-02-channel-substrate-priority` | §7.2.3 (temporal asymmetry observation) |
| `anchor-03-m13-closure` | §7.2.2 (verifies time uniformity across actor-resolution paths) |
| `anchor-04-ontology-v3-14-ceremony` | §7.2.4 (round-cycle as macro-clock — round-13 batch-2 = ontology bump event) |
| `anchor-05-multiplex-host-evidence` | §7.2.1 (six concurrent sessions on one kernel = session-tick-disjointness) |
| `anchor-06-cross-machine-cooperation` | §7.2.3 (cross-machine wall-clock pair as best-available federation time anchor pre-§M9) |
| `anchor-07-laptop-chunker-proof-reciprocity` | §7.2.3 (peer-kernel time evidence pre-§M9) |

On WF21 promotion, each anchor lifts to an outbound `consumes` LINK on the derivation. The reciprocal anchor-07 ↔ cowork-laptop's anchor-07 establishes the *first* cross-kernel `caused-by` LINK between sovereign-log derivations — a structural primitive the v3.14 substrate has been waiting for and §M9 twin-sync will need to honor.
