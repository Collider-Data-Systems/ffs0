# T=175 Phase E.2 — moos-kernel PR draft: close `bumpSessionLocalT` inferred-session gap

> April 24, 2026 (T=175 ~12:30 CEST). Draft authored by Wolfram on `session:sam.kernel-proper`.
> Closes the §M13 `session-actor-agent-lookup` sub-program flagged at T=168.
> Surfaced concretely T=174 ~00:45 by Guido during Phase A: 24 acknowledged Phase A rewrites left `session:sam.laptop-cowork-workspace.local_t = 0`.

## Problem

`Runtime.Apply` and `Runtime.ApplyProgram` in `internal/kernel/runtime.go` bump `session.local_t` only when `env.Actor` is itself a `session` node. The check:

```go
if actorNode, ok := rt.state.Nodes[env.Actor]; ok && actorNode.TypeID == "session" {
    rt.bumpSessionLocalT(env.Actor)
}
```

Locations: line 172 (Apply), line 293 (ApplyProgram inside the per-batch dedupe loop).

The §M11 gate (`liveness.go:checkLivenessM11`) already calls `operad.ResolveSessionForEnvelope` and accepts agent-actor envelopes via the **inferred** path (single-session occupant: agent reverse-resolves to its session via `has-occupant`). When that path passes the gate, the envelope is applied — but the bump check above looks only at `env.Actor`, sees an `agent` not a `session`, and skips. Result: session ticks stop happening for any agent-driven work, which is most work.

This is the §M13 sub-program `session-actor-agent-lookup` carry-over from T=168, line 430 of `kb/research/kernel/20260417-t187-kernel-proper.md`:

> `session-actor-agent-lookup` — `bumpSessionLocalT` agent→session lookup gap in runtime.go

## Fix

Use the same resolver the §M11 gate uses — `operad.ResolveSessionForEnvelope` — to determine which session URN's `local_t` should increment. The resolver already handles all six cases correctly:

| Resolver kind | Action |
|---|---|
| `ResolveSessionExplicit` | bump `env.SessionURN` |
| `ResolveSessionInferred` | bump the unambiguously-inferred session |
| `ResolveSessionActorIsSession` | bump `env.Actor` (same as today) |
| `ResolveSessionAmbiguous` | no bump (gate already rejected upstream) |
| `ResolveSessionExplicitMismatch` | no bump (gate already rejected upstream) |
| `ResolveSessionAbsent` | no bump (system-internal allowlist path; not session-scoped) |

Multi-session safety is intrinsic: `ResolveSessionAmbiguous` returns no session URN, so no bump fires; the §M11 gate would have rejected the envelope upstream regardless. System-internal envelopes (kernel-actor allowlist, sweep emissions) take the `Absent` path → no bump → correct (sweep ticks aren't session-scoped work).

### Patch (single envelope path — `Apply`)

`internal/kernel/runtime.go` ~line 171–174:

```go
// OLD
// M1: increment session local_t if actor is a session node.
if actorNode, ok := rt.state.Nodes[env.Actor]; ok && actorNode.TypeID == "session" {
    rt.bumpSessionLocalT(env.Actor)
}

// NEW
// §M13: increment local_t for the resolved session, regardless of
// whether actor is the session itself, an agent inferring via
// has-occupant, or an explicit env.SessionURN. Closes the
// session-actor-agent-lookup sub-program from T=168.
if sessionURN, ok := rt.resolveSessionForBump(env); ok {
    rt.bumpSessionLocalT(sessionURN)
}
```

### Patch (atomic batch path — `ApplyProgram`)

`internal/kernel/runtime.go` ~line 287–298:

```go
// OLD
// M1: bump local_t for all unique session actors in the batch.
{
    seen := make(map[graph.URN]bool)
    for _, env := range envelopes {
        if !seen[env.Actor] {
            seen[env.Actor] = true
            if actorNode, ok := rt.state.Nodes[env.Actor]; ok && actorNode.TypeID == "session" {
                rt.bumpSessionLocalT(env.Actor)
            }
        }
    }
}

// NEW
// §M13: bump local_t once per unique resolved session in the batch.
// Dedupe by session URN (not by actor) so a single batch from one agent
// to one session counts as one tick, while multi-session batches tick
// each session once.
{
    seenSessions := make(map[graph.URN]bool)
    for _, env := range envelopes {
        sessionURN, ok := rt.resolveSessionForBump(env)
        if !ok {
            continue
        }
        if !seenSessions[sessionURN] {
            seenSessions[sessionURN] = true
            rt.bumpSessionLocalT(sessionURN)
        }
    }
}
```

### New helper

Append after the existing `bumpSessionLocalT` helper (~line 589):

```go
// resolveSessionForBump returns the session URN whose local_t should
// increment for this envelope, regardless of whether env.Actor is itself
// a session, an agent occupying exactly one session (inferred), or
// accompanied by an explicit env.SessionURN.
//
// Returns ok=false when:
//   - actor occupies multiple sessions and env.SessionURN is empty
//     (ResolveSessionAmbiguous; gate rejects upstream)
//   - explicit env.SessionURN doesn't match has-occupant
//     (ResolveSessionExplicitMismatch; gate rejects upstream)
//   - actor occupies no session (ResolveSessionAbsent; system-internal
//     allowlist path — not session-scoped work, no bump warranted)
//
// Closes the §M13 sub-program `session-actor-agent-lookup` (T=168) by
// covering the agent-actor inferred-session path that the prior
// TypeID=="session" check skipped. See:
// ffs0/kb/research/kernel/20260417-t187-kernel-proper.md §M13.
func (rt *Runtime) resolveSessionForBump(env graph.Envelope) (graph.URN, bool) {
    res := operad.ResolveSessionForEnvelope(rt.state, env)
    switch res.Kind {
    case operad.ResolveSessionExplicit,
        operad.ResolveSessionInferred,
        operad.ResolveSessionActorIsSession:
        return res.SessionURN, true
    default:
        return "", false
    }
}
```

## Test plan

Add tests in `internal/kernel/runtime_test.go` (new file or extend existing `runtime_reactive_test.go`):

| Test | Setup | Expected |
|---|---|---|
| `TestApply_BumpsLocalT_ActorIsSession` | session-actor envelope (existing path) | local_t ticks (regression check) |
| `TestApply_BumpsLocalT_ActorIsAgent_Inferred` | agent occupying single session emits envelope without explicit SessionURN | local_t ticks (the new fix path) |
| `TestApply_BumpsLocalT_ActorIsAgent_Explicit` | agent emits with explicit `SessionURN` matching has-occupant | local_t ticks |
| `TestApply_NoBump_Ambiguous` | agent occupying TWO sessions emits without explicit SessionURN | gate rejects; no bump (verify via final state) |
| `TestApply_NoBump_KernelActor` | kernel-actor system-internal envelope | no bump (correct: not session-scoped) |
| `TestApplyProgram_DedupesBySessionNotActor` | batch with 2 agents, both occupying same session | local_t increments by 1 (not 2) |
| `TestApplyProgram_DedupesAcrossAgents` | batch with 2 agents in 2 different sessions | each session ticks once |

Run via `go test ./internal/kernel/...` (race detector requires cgo; CI hook unchanged).

## Doctrine note amendment

Already landed in this round on `D:\HPZ440\ffs0\kb\research\kernel\20260417-t187-kernel-proper.md` §M13 (T=175 update paragraph) — points at this PR as the closing path. Post-merge, that paragraph gets one further amendment:

> Sub-program `session-actor-agent-lookup` **closed** at T=175 round-12 via PR `<URL>`; merged `<sha>`; rebuilt + restarted on all 5 kernels (4 Z440 + 1 hp-laptop). Verification: post-rebuild emit on hp-laptop from `agent:claude-cowork.hp-laptop` ticked `session:sam.laptop-cowork-workspace.local_t` from 0 → 1.

## Rebuild + restart sequence (post-merge)

1. **Z440** (Wolfram): rebuild moos-kernel binary; restart 4 kernels (`hp-z440.{primary, lola, menno, moos}`) via existing federation startup script. Verify each `/healthz` reports new binary tip.
2. **hp-laptop** (Guido): pull moos-kernel; rebuild; swap binary; restart `kernel:hp-laptop.primary`. Verify `/healthz` + log replay clean (~628+ envelopes given Phase A landed at 627).
3. **Verification emit**: any single inferred-session rewrite from any agent should tick its session's `local_t`. Cleanest test: minimal MUTATE on a property of the agent itself by claude-cowork on either host.
4. **Doctrine close**: amend §M13 paragraph with merge SHA + verification log_seq.

## Branch + PR shape

- Branch: `feat/m13-bump-session-local-t-resolver`
- Title: `feat(runtime): bump session.local_t via ResolveSessionForEnvelope (closes §M13 sub-program)`
- Base: `master`
- Closes: refers to `~/.claude/plans/valiant-kindling-sunrise.md` Phase E.2 + `kb/research/kernel/20260417-t187-kernel-proper.md` §M13 carry-over
- CI: `go test ./...` must pass; existing liveness tests should be unaffected (gate path doesn't change).

## Status

**Draft, not yet branched.** Awaits Sam's go-ahead to open the PR. Patches identified, tests outlined, rebuild sequence drafted. Round-12 lands either:
(a) ffs0 commit (D.2 + cleanup + E.1) **first**, then this PR; or
(b) both in parallel (separate repos, no overlap).

I'd run (b) — they're independent, no merge ordering needed.
