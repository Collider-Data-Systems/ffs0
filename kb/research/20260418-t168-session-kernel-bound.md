# Sessions are kernel-bound — FAQ

> T=168 (April 18, 2026). Standalone companion to `20260417-t187-kernel-proper.md` §M11.
> Origin: sam's correction when I mis-proposed closing the T=167 session and ADDing a T=168 one.

## The correction (verbatim)

> "i think sessions are kernel bound and stay. its a matter of who occupies. please read our kb on this please"

## The mistake it corrected

I had proposed:

1. `ADD urn:moos:session:sam.claude-code-hp-laptop.t168` (a new session node for today)
2. `LINK WF19 opens-on urn:moos:kernel:hp-laptop.primary` (bind it)
3. `MUTATE urn:moos:session:sam.claude-code-hp-laptop.t167` `status → closed`

This treats a session as a *per-work-period* entity — created each day, closed when the day ends. That is wrong. The `<T-day>` in `urn:moos:session:<user>.<agent>.<T-day>` is a **creation-time label**, not a lifetime bound.

## The correct model

A `session` is a **permanent S2 node** bound to a kernel by a persistent WF19 `opens-on / occupied-by` LINK. Once ADDed and WF19-LINKed, it stays in the HG forever (the log is immutable; UNLINK is rare). What *changes* over time is the `session.role` property — the **seat state**.

| State | `session.role` value | Meaning |
|-------|----------------------|---------|
| Currently driving the kernel | `occupier` | At most one per kernel |
| WF19-LINKed but not driving | `observer` | Any number per kernel |
| Delegated authority | `delegate` | Specific capability inheritance |

Multiple sessions may be WF19-LINKed to the same kernel simultaneously. They form the **occupancy ledger** of that kernel — its history of seat-holders.

## Why this is a categorical necessity

Per M1, sessions are monoid objects `(S, ∘, e)`. Monoid identity `e` is the empty session. Monoid objects in a category are not created-and-destroyed per interaction; they *exist* (or they don't) and participate in compositions. Rotating occupancy is a *morphism* between seat-states — WF19 `transfers-to` is the concrete rewrite. Creating a new session per calendar day would break the monoid structure by creating-and-abandoning objects in each compositional step.

## What `t_local` actually counts

Per §M13: **a dumb ticker**. `session.local_t` increments by 1 per kernel-acknowledged rewrite attributed to this session. It is not a calendar — it is a heartbeat. It does not participate in causal reasoning about time.

For causal reasoning about time (deadlines, dependencies, "when does this hook fire?"), we use the **global `T`** — the moos-time day counter since T=0 (2025-11-01 00:00 CEST). `T` lives on nodes as properties (`starts_t`, `deadline_t`, `fires_at`, `completed_t`, etc.) and drives the t-hook firing algebra (§M14).

## So what happens when a new calendar T-day arrives?

**Nothing, by default.** The same session continues. `session.local_t` keeps ticking on the same node. If the occupier changes (different agent takes the seat, or the admin transfers to a delegate), that is a MUTATE or WF19 `transfers-to` on the *existing* session, not a new ADD.

A *new* session is ADDed only when:

- A new user enters the kernel for the first time (ADD their session on first claim)
- A new agent begins occupying a kernel it has never occupied before
- An explicit design choice demands separation (e.g. isolate a time-limited delegate's activity from the admin's)

None of these is triggered by calendar time passing.

## Current hp-laptop kernel state (at T=168)

```
urn:moos:session:sam.claude-code-hp-laptop.t164
  status=active  role=(unset → MUTATEd to observer in this enrichment)
  started_at=2026-04-14
  --WF19 opens-on/occupied-by--> urn:moos:kernel:hp-laptop.primary

urn:moos:session:sam.claude-code-hp-laptop.t167
  status=active  role=occupier  local_t=1
  started_at=2026-04-18
  --WF19 opens-on/occupied-by--> urn:moos:kernel:hp-laptop.primary
```

Both sessions are WF19-LINKed. t167 carries `role=occupier`. t164 becomes `role=observer` (HG-hygiene MUTATE applied in this enrichment pass) to make the occupancy ledger explicit.

## Naming going forward

The existing `<T-day>` in URNs (`.t164`, `.t167`) is grandfathered — we do not migrate URNs. Future sessions created on hp-laptop could follow a cleaner pattern like `urn:moos:session:<user>.<agent>.<kernel-short>` (no T-day), but the ontology's `urn_pattern` spec change is deferred to sub-program `t187.session-role-rename` (which will also handle the `session.role` → `session.seat_role` rename in one pass).

## Why the §M11 liveness clause matters

If sessions are permanent, why do we need a liveness guarantee? Because a **permanent node WF19-LINKed to the kernel** is not the same as **a permissioned seat-holder currently driving the kernel**. The liveness guarantee (§M11) says: at least one such WF19-LINKed session must carry `role ∈ {occupier, delegate}` for the kernel to accept rewrites. Otherwise the kernel is present but frozen — alive in the categorical sense of having an identity morphism, but incapable of non-identity moves.

This is why `session.role` is mutable and part of WF19's `mutate_scope`. The rotation of `role` across the sessions WF19-LINKed to a kernel IS how occupancy transfers.

## Cross-references

- `kb/research/20260417-t187-kernel-proper.md` §M1 — session as monoid (algebra)
- `kb/research/20260417-t187-kernel-proper.md` §M11 — session as kernel-liveness guarantee
- `kb/research/20260417-t187-kernel-proper.md` §M13 — `t_local` vs `T` disambiguation
- `kb/superset/ontology.json` — `session` type (S2), `role` type (S1), `capability` type (S1), WF19 `mutate_scope`
