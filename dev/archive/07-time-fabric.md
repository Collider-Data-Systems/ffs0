# Section 07 — Time Fabric and Cycles

> Architecture Specification §7 — Time Fabric Foundation
> Co-authored by Cowork-Z440 (`§7.0`, `§7.2`, `§7.4`) and Cowork-laptop (`§7.1`); synthesized by Wolfram (`§7.3`).
> Derived from: `urn:moos:derivation:cowork-z440.section-05-07-foundation` (Z440 side, log_seq 361)
> + `urn:moos:derivation:cowork-laptop.section-05-07-foundation` (hp-laptop side, log_seq 665)
> + `urn:moos:derivation:wolfram.spec-master-scaffold` (synthesis spine, Z440 log_seq 363).
> Authoring lanes: `agent:claude-cowork.hp-z440` on `session:sam.z440-cowork-workspace`; `agent:claude-cowork.hp-laptop` on `session:sam.laptop-cowork-workspace`; `agent:claude-code.hp-z440` on `session:sam.kernel-proper`. Round-14 close, T=176.

## §7.0 — Frame

Time in mo:os is not a single dimension — it is a fabric of co-existing clocks, each with its own substrate, cadence, and authority scope. The kernel maintains some (`local_t` per session); the operator anchors others (`T-day` epoch); external substrates impose still others (Drive `modifiedTime`, Calendar event timestamps, GitHub PR merge timestamps); future fabric promotion (v314-2 `clock` type, v314-3 WF21 `causes`/`caused-by`) will reify the relationships among them.

Two invariants, both verified at T=175:

1. **Sovereign-log time is per-kernel.** `local_t` ticks on emit, per session, per kernel. No shared clock between kernels until §M9 twin sync produces a sheaf-glued time over the federation diagram. `T=175` on Z440 and `T=175` on hp-laptop are *labels Sam aligns externally*, not identities the kernel proves.
2. **Time is observation, not assertion.** A clock tick is a kernel-emitted MUTATE; nothing outside the kernel can fabricate one. Cowork can request time advances by emitting work; only the kernel sweep grants them. Authority discipline is symmetric to the substrate-observation discipline in §5.

§7.1 covers hp-laptop sovereign-log time (clock taxonomy enumerated as named instances, ready for v314-2 promotion). §7.2 covers Z440 sovereign-log time (multiplex-host case adds session-tick-disjointness as a sixth implicit clock). §7.3 reconciles into the time-fabric axiomatization including the v3.14 promotions.

## §7.1 — hp-laptop sovereign-log view

Authored by `agent:claude-cowork.hp-laptop`, session `sam.laptop-cowork-workspace`, on `kernel:hp-laptop.primary`. Anchors per `urn:moos:derivation:cowork-laptop.section-05-07-foundation`.

### §7.1.1 — The hp-laptop clock taxonomy, before promotion

Five clock instances are *implicit* on hp-laptop today; v3.14-2 promotion makes them HG-resident nodes:

| Implicit clock | Cardinality | Embedding | Frame | Density | Density_n | Scope |
|---|---|---|---|---|---|---|
| `clock:kernel-hp-laptop.sweep` | point | linear | absolute | sweep | 1 | every kernel-managed node |
| `clock:kernel-hp-laptop.t-day` | point | linear | absolute | T-day | 1 | every program/t_hook with `t_target` or `fires_at` |
| `clock:sam.daily-08-chunker` | point | cyclic | absolute (cycle_period=1d) | T-day | 1 | scope_pinned channels of `session:sam.laptop-cowork-workspace` |
| `clock:sam.round-rollover` | point | linear | absolute | round | 1 | every program with round-bound `target_t` |
| `clock:sam.youtube-ingest-event` | point | linear | absolute | event-driven | n/a | (forward-looking) the next YouTube chunker fire — argument-arrival on the staged ingest derivation |

Pre-promotion these aren't HG nodes; the `keeps-time-with` LINKs that the fabric proposes don't exist yet. They are inferable from existing properties (`t_hook.fires_at`, `program.target_t`, schedule-task config, watcher predicates). Post-promotion, each becomes one ADD + one or more `keeps-time-with` LINKs from the time-bound nodes.

### §7.1.2 — Hp-laptop sovereign-log time, the linear-absolute clock

`kernel:hp-laptop.primary`'s log is itself a clock surface — every envelope acknowledged increments `log_seq` and ticks the receiving session's `local_t` (post-§M13 closure, T=175 ~16:15 CEST, PR `moos-kernel#33` `b1de4ff`). The log is monotone-increasing, single-writer per kernel, sovereign per §M9. `local_t` lives in session-property space; `log_seq` lives in log-tail space; both advance in lockstep but encode different things — `log_seq` is the kernel's clock, `local_t` is the session's clock specialized to that kernel.

Observed hp-laptop progression in T=174→T=176:

```
T=174 ~00:45 CEST   log_seq 600..627    Phase A chunker proof
T=175 ~13:50 CEST   log_seq 628..632    Phase D.1 AG-laptop substrate
T=175 ~16:15 CEST   log_seq 625..630    Phase E.2 §M13 verify (kernel self-MUTATEs ticking local_t)
T=175 ~22:44 CEST   log_seq 633..656    round-13 close + autonomous routines
T=176 ~12:00 CEST   log_seq 635..656    AG-laptop §6 + daily routines (purple-calendar 07:06 + daily-digest 08:07)
T=176 ~13:00 CEST   log_seq 665..666    Cowork-laptop §5+§7 derivation (this round)
```

Two T-day boundaries crossed (T=174 ~midnight CEST → T=175 morning), but the log doesn't observe T-day directly; it observes log_seq. T-day is a derived clock (linear-absolute, density=T-day) that reads kernel wall-clock at envelope-application time. A future `clock:kernel-hp-laptop.t-day` node makes the derivation explicit and queryable.

### §7.1.3 — Daily 08:00 chunker ritual — the canonical cyclic clock

Per `cowork-as-occupant.md §5.1`, the daily 08:00 chunker sweep matches Sam's "Mon 08:00-09:00 calendar ritual." That ritual is a clock instance in the canonical sense:

```
clock:sam.daily-08-chunker
  cardinality      = point
  embedding        = cyclic
  frame            = absolute
  cycle_period     = { unit: "day", n: 1, anchor: "08:00 Europe/Amsterdam" }
  density          = T-day
  density_n        = 1
  scope            = session:sam.laptop-cowork-workspace.scope_pins
                     (the 4 channel:google.*.sam URNs)
```

The chunker skill (`moos-workspace-ingest`) is the reaction; the daily 08:00 fire is the predicate satisfaction. Pre-promotion, `mcp__scheduled-tasks__create_scheduled_task` carries the schedule; post-promotion, the schedule lives as `clock:sam.daily-08-chunker --keeps-time-with--> session:sam.laptop-cowork-workspace` plus a `t_hook` (or fabric-generalized `clock-bound predicate-and-reaction`) whose firing emits the chunker batch.

The chunker fire is the canonical heartbeat for Cowork-laptop's session liveness (§M11). Each fire ≥ 1 envelope ⇒ session ticks ⇒ liveness window resets. T=176 ~12:00 production proof: `purple-calendar-scanner` 07:06 UTC + `daily-moos-digest` 08:07 UTC fired clean; 6/6 audit GREEN per Guido.

### §7.1.4 — Event-driven density — the YouTube ingest case

The fabric (§2 + §5) ties event-driven clocks to leaf-firing. The round-15 YouTube ingest is a forward-looking instance: when the staged YouTube source's argument-relation arrives (the ingest derivation moves from `provisioned → hot → firing`), the implicit `clock:sam.youtube-ingest-event` ticks. That tick is observable on hp-laptop log as the YouTube chunker batch landing — a single batch is one tick.

This is the case where the clock is most degenerate (one tick total, then the clock is closed). It still pays its way: the firing-state semantics let upstream derivations cite the clock as their argument-arrival predicate.

### §7.1.5 — Federation time — what hp-laptop *cannot* say

Cross-kernel time is not on hp-laptop's log. WF16 federation events are router-mediated; the router is stateless and no kernel-of-record hosts federation log. Per `running-state.md` hydration block, twin-kernel state-sync (post-§M9 + §M10 QUIC, round-15+) will materialize cross-kernel observation; until then, hp-laptop's view of "what time is it on Z440 :8000" is whatever the last federation read pulled — which is a stale observation, not a clock.

Observation: post-§M9 sync, a `clock:federation.t-day` becomes meaningful as a colimit clock with all five kernels' T-day densities reconciled. Pre-§M9, the closest analog is "Sam's wall clock is the federation clock" — out-of-band, by convention.

### §7.1.6 — Pre-WF21 transitional citation for time

Pre-WF21 has no `caused-by` LINK from a fired derivation back to the clock-tick that triggered it. The transitional citation is the same shape as §5.1.5 substrate citation: encode the clock URN in the derivation's `stochastic_weights.anchors` with `kind=clock_tick`, and on WF21 promotion lift those anchors into outbound `caused-by` LINKs without property migration.

The round-14 derivation `urn:moos:derivation:cowork-laptop.section-05-07-foundation` follows this rule — `anchor-04-youtube-ingest-decision` is a forward-looking clock-tick citation; once the YouTube fire happens, anchor-04 resolves to a real `clock:sam.youtube-ingest-event` URN and a real fire timestamp.

## §7.2 — Z440 sovereign-log view

Authored by `agent:claude-cowork.hp-z440`, session `sam.z440-cowork-workspace`, on `kernel:hp-z440.primary`. Anchors per `urn:moos:derivation:cowork-z440.section-05-07-foundation`.

### §7.2.1 — Five clocks observable from this seat, plus a sixth implicit one

From inside `session:sam.z440-cowork-workspace`, five distinct clocks are visible — each with its own tick source and authority:

| Clock | Tick source | Cadence | Authority | Visibility |
|---|---|---|---|---|
| `kernel.sweep` | `kernel:hp-z440.primary` background loop | 30s nominal | kernel | all sessions on this kernel |
| `session.local_t` | kernel self-MUTATE on every acknowledged rewrite (post-§M13) | per-emit | kernel | own session via `node_lookup`; peer sessions via `state/nodes/<urn>` |
| `T-day` (operator epoch) | Sam's manual update to `running-state.md` header | per-round (~daily) | user | global, by convention; not enforced |
| `daily-08-chunker` (cyclic) | `mcp__scheduled-tasks__create_scheduled_task` daily 08:00 trigger | 24h | session-occupant | own session only (Z440 mirror of laptop's) |
| `round-rollover` | kernel-emitted MUTATEs on round-close commit | per-round | user → kernel | running-state preamble bumps |

Z440's multiplex-host case adds a sixth implicit clock — **session-tick-disjointness**: six sessions each tick `local_t` independently; their relative ordering is determined by emit ordering on the shared log, not by any shared time index. From `kernel.sweep`'s POV they're a single ordered sequence; from each session's own POV they're isolated heartbeats.

### §7.2.2 — `local_t` after §M13 closure (verified Z440-side)

Pre-§M13 (T=174 ~00:45 surfaced the gap): `session:sam.laptop-cowork-workspace.local_t = 0` after 24 acknowledged rewrites — inferred-session path failed to invoke `bumpSessionLocalT`. Post-§M13 (PR #33, T=175 ~16:30 verified Z440-side at log_seq 334-339): three test envelopes mixing `ResolveSessionExplicit` (Wolfram on `sam.kernel-proper`) and `ResolveSessionInferred` (Cowork-Z440, AG-Z440) all triggered kernel self-MUTATEs at log_seq 337-339, bumping respective sessions' `local_t` 0 → 1.

Substrate consequence: time is now uniform across actor-resolution paths. Multi-session agents (Wolfram) and single-session agents (Cowork, AG) measure their own session's clock identically. Pre-fix this was a substrate hazard that could have been fossilized into doctrine if not surfaced.

### §7.2.3 — Federation time visibility (pre-§M9)

What this seat **cannot** say from `kernel:hp-z440.primary`'s log:
- Whether `session:sam.governance.local_t` (hp-laptop, Guido) ticked recently.
- Whether `session:sam.laptop-cowork-workspace.local_t` is in sync with mine.
- Whether laptop's chunker-proof at log_seq 604-627 was emitted before or after Z440's at log_seq 307-331 in *wall-clock* time. (Anchored externally by Sam's running-state entries; not knowable from either kernel's log alone.)

What it **can** say:
- Sam's `T=175` is a label both kernels accept. Both kernels independently bumped `t_day` on round-rollover.
- Both kernels reached `ontology_version: 3.14.0` after their respective round-13 batch-2 ceremonies (Z440 first at T=175 ~19:00; hp-laptop at T=175 ~late per Guido lane).
- The cross-machine cooperation block emitted T=175 ~22:55 carries explicit timestamps; the answer-pair is the closest thing to a synchronized event we have until §M9 lands.

§M9 twin-sync closure will produce a federation-time sheaf gluing the per-kernel local clocks via the WF16 router; until then, federation time is a Sam-curated overlay, not a kernel-evident invariant.

### §7.2.4 — Round-cycle as macro-clock

Sam's round-by-round cadence is the highest-level clock the substrate sees: round-N → round-N+1 happens via `running-state.md` preamble bumps + ffs0 commits + (optionally) atomic ontology promotions. Round-13 closed at T=175 ~late ("substantively"); round-14 opened with this spec's §5/§7 contributions; round-14 closes at T=176 ~13:30 with the master scaffold + all 8 specialist branches.

The cadence is not isochronous — round-12 ran T=175 mid-day, round-13 closed T=175 late, round-14 opened T=175 late same day, round-14 closes T=176. Multi-round per T-day happens; cross-T-day rounds happen. The macro-clock is *event-driven over deliverable-readiness*, not wall-clock paced. Future operationalization (per `t175.program-authoring-fabric` §7) frames this as `clock.kind = round-cyclic` with `period = variable`.

### §7.2.5 — Pre-WF21 causation: time without causes

The current substrate carries time but not causation. Anchor-N consumes anchor-M is documented in `stochastic_weights` JSON; on WF21 promotion (`causes`/`caused-by` port pair on `derivation`), each consumes-relationship lifts to a typed LINK. Until then, temporal precedence and causal precedence are both inline-JSON observations; the kernel cannot distinguish them.

This section's `derivation` carries seven anchors with implicit causal ordering (anchor-01 enables anchor-04 enables this section; anchor-07 reciprocates anchor-01 across sovereign logs). Post-WF21, the seven inline anchors become seven outbound `consumes` LINKs and the reciprocal cross-derivation citation becomes a `caused-by` LINK between the two Cowork derivations.

## §7.3 — Synthesis (Wolfram)

This section unifies §7.1 (hp-laptop's 5-clock taxonomy) and §7.2 (Z440's 5+1 multiplex-host case) into a single time-fabric axiomatization, sketches the v314-2 `clock` type schema, outlines §M9 twin-sync sheaf-gluing, and folds the WF21 lift path.

### §7.3.1 — Clock count: six canonical kinds, multiplex adds one disjointness invariant

The unified taxonomy has **six canonical clock kinds** observable across both sovereign logs:

| Kind | Embedding | Density | Scope |
|---|---|---|---|
| `kernel.sweep` | linear | sweep (~30s) | per-kernel |
| `session.local_t` | linear | per-emit | per-session |
| `t-day` | linear | T-day | global (operator-anchored) |
| `cyclic-ritual` (e.g., daily-08-chunker, round-rollover) | cyclic | per-cycle | session-occupant |
| `event-driven` (e.g., youtube-ingest-event, leaf-firing) | linear | one tick total | argument-arrival predicate |
| `multi-session-disjoint` (Z440 multiplex-host only) | linear | per-emit, per-session | within-kernel disjoint sessions |

The sixth kind (multi-session-disjoint) is not a fundamentally new clock — it is the observation that `session.local_t` ticks across multiple sessions on a single kernel are *interleaved on `log_seq` but disjoint on each session's own clock*. Single-kernel hosts (hp-laptop, currently) don't surface this distinction; multi-kernel federated hosts (Z440 today; future after §M9 twin-deploy) make it canonical. The v314-2 `clock` schema (§7.3.4 below) covers all six under one type.

### §7.3.2 — Federation time pre-§M9 vs post-§M9

**Pre-§M9 (today)**: federation time is operator-overlay only. Sam's wall-clock is the de-facto federation clock; cross-kernel events are anchored externally via `running-state.md` entries; kernel logs cannot prove cross-kernel temporal ordering. The cross-machine cooperation block (T=175 ~22:55 / ~23:10 paired emit between Cowork-Z440 and Cowork-laptop) is the closest pre-§M9 instance of synchronized federation time — and it is property-form citation, not a kernel-evident invariant.

**Post-§M9 (round-15+)**: a `clock:federation.t-day` becomes a colimit clock with all participating kernels' T-day densities reconciled via `twin_link` adjoint sync. The sheaf gluing produces a single global section over the federation diagram; cross-kernel ordering becomes kernel-evident via `twin_link.last_synced_at`. The transitional doctrine: **federation time is property-form-first (operator overlay), topology-form-eventual (sheaf-glued via twin-link adjoint)** — the same shape as §5.3.2's bootstrap-origin transition.

### §7.3.3 — Round-cycle as the highest-level user-anchored clock

Sam's round cadence is the only clock whose authority is `user`, not `kernel`. All five other clocks are kernel-authority (kernel emits the MUTATE). Round-rollover is human-driven: Sam decides when round-N closes by committing `running-state.md` preamble bumps. The substrate consequence: round-cycle observations cannot fossilize into kernel invariants without operator action; this is doctrinally desirable (rounds are HITL deliverable units, not wall-clock units).

Round-14 close at T=176 ~13:30 is one such observation. The macro-clock advanced by one tick.

### §7.3.4 — Promotion-ready spec for `v314-2-clock-type`

```
node-type:   clock
stratum:     S2
urn-pattern: urn:moos:clock:<owner>.<slug>
properties:
  cardinality          enum {point, interval}                immutable
  embedding            enum {linear, cyclic, dag, branching} immutable
  frame                enum {absolute, relative}             immutable
  frame_anchor_urn     urn (when frame=relative)             immutable
  density              enum {sec, min, hr, sweep, T-day, round, program-cycle, event-driven, custom} immutable
  density_n            number                                immutable
  cycle_period         object (when embedding=cyclic)        immutable
  authority            enum {kernel, user, session-occupant} immutable
  scope_descriptor     string                                immutable
  status               enum {active, closed}                 mutable, kernel-authority

ports:
  out: [ticks-on, keeps-time-with]
  in:  [keeps-time-with]
```

`keeps-time-with` is bidirectional (mutual-binding, like WF19 occupant-pair). Initial promotion targets the six kinds enumerated in §7.3.1; the schema is forward-compatible with future kinds via the `density: custom` escape hatch.

### §7.3.5 — WF21 lift path for time-fabric anchors

Pre-WF21, both substrate citations (§5.1.5) and time citations (§7.1.6) live in `stochastic_weights.anchors[].kind`. Post-WF21, they lift to typed LINKs: substrate citations become `caused-by` edges to channel/derivation; time citations become `caused-by` edges to clock instances. The lift is property-form-to-topology-form; no property migration; the inline anchor schema already names the target URN.

WF21 promotion alongside `v314-2-clock-type` produces the first kernel-evident causal-temporal substrate. The two fragments pair naturally; round-15+ promotes them together with `claim:wolfram.cross-kernel-reciprocity-as-§M9-prefiguration` as the meta-doctrine wrapping both.

### §7.3.6 — Cross-references

- §1 categorical formalism (Karpathy) — clocks are functor-objects in `TimeCat`; `keeps-time-with` is a natural transformation
- §2 session as program-authoring layer — `local_t` is the session's own clock; sessions are time-bound contexts
- §3 kernel internals — sweep loop is the kernel's heartbeat; produces `kernel.sweep` clock instances
- §4 federation topology — §M9 twin-link is the sheaf-gluing diagram for federation time
- §5 external substrates — substrate observations are time-tagged; `external-channel` ingest creates time-anchored KIs
- §9 governance — invariant-bracketing applies to clock correctness: preflight scheduled-task config + post-hoc audit on tick reliability
- §12 MVP delivery — round-14 close at T=176 vs target T=180 is on-the-curve evidence; MVP G1-G6 at T=190 is the macro-clock target

## §7.4 — Anchors and provenance

Combined Z440 + laptop anchor map for §7:

| Anchor id (Z440) | Cited where in §7.2 | Mirror id (laptop) | Cited where in §7.1 |
|---|---|---|---|
| `anchor-01-z440-chunker-proof` | §7.2.5 (causal anchor, post-WF21 lift target) | `anchor-01-chunker-proof` | §7.1.2 (concrete sovereign-log time tick) |
| `anchor-02-channel-substrate-priority` | §7.2.3 (temporal asymmetry observation) | — | — |
| `anchor-03-m13-closure` | §7.2.2 (verifies time uniformity across actor-resolution paths) | `anchor-03-m13-closure` | §7.1.2 (local_t reliability dependency) |
| `anchor-04-ontology-v3-14-ceremony` | §7.2.4 (round-cycle as macro-clock) | `anchor-04-youtube-ingest-decision` | §7.1.4 (event-driven density) |
| `anchor-05-multiplex-host-evidence` | §7.2.1 (six concurrent sessions on one kernel = session-tick-disjointness) | `anchor-05-doctrine-fabric` | §7.1.1 (clock taxonomy) |
| `anchor-06-cross-machine-cooperation` | §7.2.3 (cross-machine wall-clock pair as best-available federation time anchor pre-§M9) | `anchor-06-cross-machine-cooperation` | §7.1.5 (federation time blindness) |
| `anchor-07-laptop-chunker-proof-reciprocity` | §7.2.3 (peer-kernel time evidence pre-§M9) | — | — |

On WF21 promotion, each anchor lifts to an outbound `consumes` LINK on the respective derivation. The reciprocal anchor-07 ↔ cowork-laptop's anchor-07 establishes the *first* cross-kernel `caused-by` LINK between sovereign-log derivations — a structural primitive the v3.14 substrate has been waiting for and §M9 twin-sync will need to honor. The synthesis derivation `urn:moos:derivation:wolfram.section-07-synthesis` (round-14 close) consumes both Cowork derivations + Wolfram's master scaffold + the v314-2 `clock` candidate fragment.
