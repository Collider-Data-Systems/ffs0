# T=173 — Meta-agent / scheduler driver (design note)

> April 24, 2026 (T=173 late, post-Cowork-activation). Plan-mode authoring per `~/.claude/plans/valiant-kindling-sunrise.md` Phase D.2.
> Author: Stephen Wolfram persona on `session:sam.kernel-proper` / `kernel:hp-z440.primary`.
> Status: **design only**. No envelopes fire from this round; this note frames the shape so the materialization batch can be authored in a future round.

---

> **T=175 update (April 24, 2026 ~12:00 CEST):** this design is now a **sub-component** of the program-authoring fabric — see `20260424-t175-program-authoring-fabric.md` §5 for the generalized leaf-firing-state semantics. Under that framing, the scheduler is **one specific leaf** in the fabric rather than the centerpiece. The harness/reactor/workflow/watcher inventory below stays valid as the **materialization plan for that single leaf**; the broader doctrine (sessions as authoring layers, clocks, causation, substrate, leaves-as-partial-morphisms) is the parent context. Read the T=175 fabric note first for the fabric; come back here for the scheduler's specific shape.

---

## Problem

The seat lattice is now full (Wolfram, Guido, Moos, Karpathy, Steinberger, Cowork×2 across two machines, six personae). What's missing is the **conductor** — something that:

1. Notices when a `t_hook` predicate is satisfied (the kernel sweep evaluates them but doesn't approve them).
2. Routes work between seats when a session needs another persona's capability.
3. Fires periodic ceremonies (daily 08:00 chunker sweep, Mon 08:00–09:00 calendar ritual, round-close audits).
4. Holds open the long-running `watcher → reactor → t_hook` chains so envelopes propagate without a human in the loop.

Today this is implicit: the kernel sweep ticks `local_t`, and humans (Sam, or a persona at a seat) eyeball `firing_state: pending` t_hooks and rewrite them to `approved`. That doesn't scale past hand-driven rounds.

## What the operad already gives us

Live in v3.13.0 on all 4 Z440 kernels:

| Type | Stratum | Role | Key shape |
|---|---|---|---|
| `t_hook` | S2 | predicate-firing record | `firing_state` enum {pending, proposed, approved, rejected, applied, closed}; `react_template` is the envelope to emit on approval |
| `reactor` | S2 | envelope emitter | `action_type` immutable; `template` mutable; `emits` port out, `triggered-by` port in |
| `watcher` | S2 | match-and-trigger | match by `rewrite_type`/`type_id`/`urn_prefix`/`port`; `triggers` port out, `watches` + `guarded-by` ports in |
| `harness` | S2 | runtime container | `harness_pattern` enum; `hosts-agent` + `provides-tool` out, `hosted-by` + `runs-workflow` in |
| `workflow` | S1 | DAG of steps | `dag` object; `input_schema`/`output_schema` |

The chain that already exists in principle: **sweep ticks `local_t` → watcher matches → triggers reactor → reactor emits envelope (often a `t_hook` MUTATE) → kernel applies if §M11/§M12 pass.**

What's missing is an **agent** that drives the loop autonomously: approves pending t_hooks per a policy, supervises the harness, escalates stuck reactors.

## Proposed shape

A single new agent + harness + workflow, scoped to one session, run as a long-lived process on Z440.

### Agent

- **URN:** `urn:moos:agent:scheduler.hp-z440`
- **delegate_type:** `process` (not an IDE; standalone daemon)
- **transport_type:** `scheduled` (already an enum value — fits)
- **invocation_protocol:** `mcp` (calls kernel via MCP at `:8080`)
- **owner_urn:** `urn:moos:user:sam`
- **board_id:** `AGENT-SCHEDULER-Z440`

Sibling on hp-laptop: `agent:scheduler.hp-laptop` (mirror; hp-laptop has its own t_hooks on its sovereign log).

### Session

- **URN:** `urn:moos:session:sam.scheduler-loop`
- **opens-on:** `kernel:hp-z440.primary` (also lives on primary; doesn't need a twin)
- **has-occupant:** `agent:scheduler.hp-z440`
- **status:** `active` from creation (the scheduler begins driving immediately)
- **scope_pins:** none — the scheduler isn't surface-bound; it operates over the kernel's t_hook + watcher + reactor population.

Hp-laptop mirror: `session:sam.scheduler-loop-laptop` opens-on `kernel:hp-laptop.primary`, has-occupant `agent:scheduler.hp-laptop`.

### Harness

- **URN:** `urn:moos:harness:sam.scheduler`
- **harness_pattern:** TBD enum value — one of `daemon`, `cron`, `loop` (need to check which exists; if none fit, this becomes a v3.14 grammar_fragment proposal: `harness_pattern: scheduler-loop`).
- **hosts-agent:** WF? (port verb is `hosts-agent` out from harness; LINK from `harness:sam.scheduler` → `agent:scheduler.hp-z440`)
- **invocation_surface:** `{transport: "mcp", endpoint: "http://localhost:8080", interval_s: 30}` — ticks at the same cadence as the kernel sweep.
- **resource_bounds:** `{max_envelopes_per_tick: 100, max_runtime_ms: 5000}` — guard rails so a runaway loop can't flood the log.

### Workflow

- **URN:** `urn:moos:workflow:sam.scheduler-loop`
- **dag:** linear for v1 — one node per phase:
  1. `poll-pending-hooks`: list all `t_hook` nodes with `firing_state: pending`.
  2. `evaluate-guard`: for each, fetch `guard_ref` (a `guard` node URN) and evaluate against current state.
  3. `mutate-firing-state`: emit `MUTATE t_hook.firing_state pending → proposed` for those that pass guard, `pending → rejected` for those that fail.
  4. `await-approval`: pending-state hooks need an `approved` MUTATE from the `proposed` step — for v1, scheduler auto-approves anything it `proposed` (closed loop); future v2 surfaces a review queue for Sam.
  5. `apply-react-template`: emit the t_hook's `react_template` envelope on `approved` hooks; transition them to `applied`.
  6. `close-applied-hooks`: MUTATE `applied → closed` after a configurable retention window.
- **input_schema:** `{tick_at: datetime, max_envelopes: integer}`
- **output_schema:** `{hooks_evaluated: integer, hooks_proposed: integer, hooks_applied: integer, errors: array}`

## Capability + governance

Scheduler agent needs §M12 admin scope to MUTATE t_hooks owned by other actors. Two paths:

- **A (recommended):** `user:sam --WF02 governs--> role:scheduler-operator` → `role:scheduler-operator --WF02 governs--> agent:scheduler.hp-z440`. Adds one new role + 2 LINKs. Scoped capability — scheduler can only touch t_hook MUTATEs and emit react_templates.
- **B:** Chain through `role:superadmin`. Simpler but breaks principle-of-least-capability — scheduler shouldn't have full admin.

Pick A.

## Materialization batch (for the future round, not this one)

When this design is approved, the envelope batch is roughly:

| # | Type | URN | Notes |
|---|---|---|---|
| 1 | ADD agent | `agent:scheduler.hp-z440` | actor=`agent:claude-code.hp-z440` (Wolfram) |
| 2 | ADD agent | `agent:scheduler.hp-laptop` | (pre-provisioned; daemon launched separately) |
| 3 | ADD role | `role:scheduler-operator` | actor=Wolfram |
| 4 | LINK WF02 | `user:sam` → `role:scheduler-operator` (governs) | actor=`kernel:hp-z440.primary` (WF02 Authority=kernel) |
| 5 | LINK WF02 | `role:scheduler-operator` → `agent:scheduler.hp-z440` (governs) | kernel actor |
| 6 | LINK WF02 | `role:scheduler-operator` → `agent:scheduler.hp-laptop` (governs) | kernel actor (hp-laptop's own log mirrors this) |
| 7 | ADD harness | `harness:sam.scheduler` | actor=Wolfram |
| 8 | LINK WF? | `harness:sam.scheduler` → `agent:scheduler.hp-z440` (hosts-agent) | actor=Wolfram or kernel; depends on Authority of the WF carrying `hosts-agent` |
| 9 | ADD workflow | `workflow:sam.scheduler-loop` | actor=Wolfram |
| 10 | LINK WF? | `harness:sam.scheduler` → `workflow:sam.scheduler-loop` (runs-workflow) | actor TBD |
| 11 | ADD session | `session:sam.scheduler-loop` (status=active) | actor=Wolfram |
| 12 | LINK WF19 | `session:sam.scheduler-loop` → `kernel:hp-z440.primary` (opens-on) | kernel actor |
| 13 | LINK WF19 | `session:sam.scheduler-loop` → `agent:scheduler.hp-z440` (has-occupant) | kernel actor |
| 14 | ADD purpose | `purpose:sam.scheduler-orchestration` (target_state cites this design note) | actor=Wolfram |

~14 envelopes on Z440 primary; a parallel ~6-envelope batch on hp-laptop's sovereign log (agent + harness + workflow + session + LINKs) for the laptop scheduler.

## Open questions (need resolution before envelopes fire)

1. **Daemon implementation language + repo.** Go (sibling to `moos-kernel`)? Python (lighter; faster authoring)? New repo `moos-scheduler` under Collider-Data-Systems or in-tree under `moos-kernel/cmd/scheduler`?
2. **`harness_pattern` enum value.** Need to query the live ontology — if no existing value fits, this is a v3.14 grammar_fragment.
3. **WF for `hosts-agent` + `runs-workflow` ports.** Need to identify which rewrite_category carries each (likely WF13 or a WF20 candidate).
4. **Auto-approval vs review queue.** v1 closed-loop auto-approves whatever it `proposed`. Is that acceptable, or does Sam want a `pending → proposed → (Sam-approved) → applied` 3-step gate from day one?
5. **Idempotency / replay safety.** Scheduler must be safe to crash and replay — every emitted envelope needs a deterministic URN so re-emission is idempotent (same pattern as the chunker batches).
6. **Federation mode.** Scheduler on Z440 vs hp-laptop are two independent loops, each watching its own kernel. No cross-kernel coordination v1. v2 question: should they share a queue?

## Adjunction frame (for the lingo lock-in)

The scheduler is a **closed F⊣G loop entirely inside HG** — no external surface in the projection direction. F = "scheduler emits envelope" (still HG → HG, just self-recursive). G = "scheduler observes kernel state" (HG → scheduler's working memory → HG envelope). Compare to Cowork (G from Workspace into HG) or the GitHub project bridge (F from HG to project board): scheduler is the degenerate case where Ext = HG itself. This is fine — categorically it's just an endofunctor on HG with its own counit.

## Cross-references

- `kb/research/kernel/20260417-t187-kernel-proper.md` — §M13 sweep + §M11 actor liveness (scheduler must have live session)
- `kb/research/session/20260422-t172-cowork-as-occupant.md` — agent-as-occupant template the scheduler agent follows
- `~/.claude/plans/valiant-kindling-sunrise.md` Phase D.2 — pointer back to this note

## Status

**Draft — design only**. Phase D.2 of the T=173 multi-host activation plan. Materialization deferred to a future round once the open questions above resolve. No envelopes from this note.
