# §7 Time fabric + cycles

> Round-14 comprehensive architecture spec, section 7.
> Multi-author: Cowork-laptop authors hp-laptop-side observations; Cowork-Z440 authors Z440-side; Wolfram synthesizes at round-close.
> Status: **draft, in-flight authoring** — hp-laptop section landed; Z440 + synthesis pending.

---

## 7.0 Section scope

How time enters the kernel. The fabric note `kb/research/session/20260424-t175-program-authoring-fabric.md` §2 generalizes `t_hook` into a `clock` node with five dimensions (cardinality, embedding, frame, density, scope). This section is the architecture-spec face of fabric §2. Hp-laptop observations land here; Z440 observations land below; Wolfram closes the synthesis.

The orienting question: **what makes a "tick" on this kernel?** Sovereign-log discipline means the answer is per-kernel — wall-clock advance, sweep cadence, calendar-anchored ritual, event-driven argument-arrival, T-day rollover. All of those are clock instances; some specialize the others; the fabric makes them comparable.

---

## 7.1 Hp-laptop authorship — Cowork-laptop view

Authored by `agent:claude-cowork.hp-laptop`, session `sam.laptop-cowork-workspace`, on `kernel:hp-laptop.primary`. Anchors back to derivation `urn:moos:derivation:cowork-laptop.section-05-07-foundation` (T=175 ~22:44 CEST).

### 7.1.1 The hp-laptop clock taxonomy, before promotion

Five clock instances are *implicit* on hp-laptop today; v3.14-2 promotion makes them HG-resident nodes:

| Implicit clock | Cardinality | Embedding | Frame | Density | Density_n | Scope |
|---|---|---|---|---|---|---|
| `clock:kernel-hp-laptop.sweep` | point | linear | absolute | sweep | 1 | every kernel-managed node |
| `clock:kernel-hp-laptop.t-day` | point | linear | absolute | T-day | 1 | every program/t_hook with `t_target` or `fires_at` |
| `clock:sam.daily-08-chunker` | point | cyclic | absolute (cycle_period=1d) | T-day | 1 | scope_pinned channels of `session:sam.laptop-cowork-workspace` |
| `clock:sam.round-rollover` | point | linear | absolute | round | 1 | every program with round-bound `target_t` |
| `clock:sam.youtube-ingest-event` | point | linear | absolute | event-driven | n/a | (forward-looking) the next YouTube chunker fire — argument-arrival on the staged ingest derivation |

Pre-promotion these aren't HG nodes; the `keeps-time-with` LINKs that the fabric proposes don't exist yet. They are inferable from existing properties (`t_hook.fires_at`, `program.target_t`, schedule-task config, watcher predicates). Post-promotion, each becomes one ADD + one or more `keeps-time-with` LINKs from the time-bound nodes.

### 7.1.2 Hp-laptop sovereign-log time, the linear-absolute clock

`kernel:hp-laptop.primary`'s log is itself a clock surface — every envelope acknowledged increments `log_seq` and ticks the receiving session's `local_t` (post-§M13 closure, T=175 ~16:15 CEST, PR moos-kernel#33 `b1de4ff`). The log is monotone-increasing, single-writer per kernel, sovereign per §M9. `local_t` lives in session-property space; `log_seq` lives in log-tail space; both advance in lockstep but encode different things — `log_seq` is the kernel's clock, `local_t` is the session's clock specialized to that kernel.

Observed hp-laptop progression in T=174→T=175:

```
T=174 ~00:45 CEST   log_seq 600..627    Phase A chunker proof
T=175 ~13:50 CEST   log_seq 628..632    Phase D.1 AG-laptop substrate
T=175 ~16:15 CEST   log_seq 625..630    Phase E.2 §M13 verify (kernel self-MUTATEs ticking local_t)
T=175 ~22:44 CEST   log_seq 633..(next) round-14 derivation ADD + kernel self-MUTATE (this round)
```

Two T-day boundaries crossed (T=174 ~midnight CEST → T=175 morning), but the log doesn't observe T-day directly; it observes log_seq. T-day is a derived clock (linear-absolute, density=T-day) that reads kernel wall-clock at envelope-application time. A future `clock:kernel-hp-laptop.t-day` node makes the derivation explicit and queryable.

### 7.1.3 Daily 08:00 chunker ritual — the canonical cyclic clock

Per `kb/research/session/20260422-t172-cowork-as-occupant.md` §5.1, the daily 08:00 chunker sweep matches Sam's "Mon 08:00-09:00 calendar ritual." That ritual is a clock instance in the canonical sense:

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

The chunker fire is the canonical heartbeat for Cowork-laptop's session liveness (§M11). Each fire ≥ 1 envelope ⇒ session ticks ⇒ liveness window resets. Without a clock node, that contract is encoded in scheduled-task config + skill behavior; with a clock node, the contract is graph-resident.

### 7.1.4 Event-driven density — the YouTube ingest case

The fabric (§2 + §5) ties event-driven clocks to leaf-firing. The round-14 YouTube ingest decision is a forward-looking instance: when the staged YouTube source's argument-relation arrives (the ingest derivation moves from `provisioned → hot → firing`), the implicit `clock:sam.youtube-ingest-event` ticks. That tick is observable on hp-laptop log as the YouTube chunker batch landing — a single batch is one tick.

This is the case where the clock is most degenerate (one tick total, then the clock is closed). It still pays its way: the firing-state semantics let upstream derivations cite the clock as their argument-arrival predicate.

### 7.1.5 Federation time — what hp-laptop *cannot* say

Cross-kernel time is not on hp-laptop's log. WF16 federation events are router-mediated; the router is stateless and no kernel-of-record hosts federation log. Per running-state.md hydration block, twin-kernel state-sync (post-§M9 + §M10 QUIC, round-15+) will materialize cross-kernel observation; until then, hp-laptop's view of "what time is it on Z440 :8000" is whatever the last federation read pulled — which is a stale observation, not a clock.

Observation: post-§M9 sync, a `clock:federation.t-day` becomes meaningful as a colimit clock with all five kernels' T-day densities reconciled. Pre-§M9, the closest analog is "Sam's wall clock is the federation clock" — out-of-band, by convention.

### 7.1.6 Pre-WF21 transitional citation for time

Pre-WF21 has no `caused-by` LINK from a fired derivation back to the clock-tick that triggered it. The transitional citation is the same shape as §5.1.5 substrate citation: encode the clock URN in the derivation's `stochastic_weights.anchors` with `kind=clock_tick`, and on WF21 promotion lift those anchors into outbound `caused-by` LINKs without property migration.

The round-14 derivation `urn:moos:derivation:cowork-laptop.section-05-07-foundation` follows this rule — `anchor-04-youtube-ingest-decision` is a forward-looking clock-tick citation; once the YouTube fire happens, anchor-04 resolves to a real `clock:sam.youtube-ingest-event` URN and a real fire timestamp.

---

## 7.2 Z440 authorship — Cowork-Z440 view

> _Stub — to be authored by `agent:claude-cowork.hp-z440`, session `sam.z440-cowork-workspace`, on `kernel:hp-z440.primary`. Expected content: Z440-side time observations; the 4-kernel federation cadence; sweep across :8000–:8003; T=173 batch B at log_seq 273-284 + T=175 ontology bump at 340-352 as Z440-side log_seq progression; multi-session occupancy time semantics for Wolfram (kernel-proper + mvp-delivery)._

---

## 7.3 Synthesis — Wolfram

> _Stub — to be authored by `agent:claude-code.hp-z440`, session `sam.kernel-proper`. Expected content: cross-kernel time colimit; promotion-ready `clock` type spec for `v314-2-clock-type`; reconciliation of hp-laptop sovereign-log time with Z440 4-kernel federation time; pre-§M9 vs post-§M9 federation-clock semantics; the WF21 lift path from pre-WF21 transitional citation to causal LINKs._

---

## 7.4 Anchors back to round-14 derivation

Provenance anchors for §7.1 (per `urn:moos:derivation:cowork-laptop.section-05-07-foundation` `stochastic_weights.anchors`):

- `anchor-01-chunker-proof` — T=174 chunker landing, log_seq 604-627 — concrete sovereign-log time tick
- `anchor-03-m13-closure` — Phase E.2 PR #33 — local_t now ticks reliably (this section's existence depends on it)
- `anchor-04-youtube-ingest-decision` — round-14 YouTube ingest clock instance (event-driven density; forward-looking)
- `anchor-05-doctrine-fabric` — fabric §2 maps to this section (clock node-type spec)
- `anchor-06-cross-machine-cooperation` — Z440 + hp-laptop time observations are disjoint until §M9 sync
