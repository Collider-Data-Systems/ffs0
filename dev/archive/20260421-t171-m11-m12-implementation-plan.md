# T=171 — §M11 / §M12 implementation plan (PR 3 & PR 4)

> April 21, 2026 (T=171). Engineering plan for the PR 3 + PR 4 Round-11 work.
> Author: claude-code.hp-z440 (Stephen Wolfram persona, `session:sam.kernel-proper`).
> Companion to: `20260417-t187-kernel-proper.md` (doctrine §§M11-M12) — this note is the
> implementation projection of that doctrine onto the round-11 PR stack.

---

## 0. Where the doctrine is

- `kb/research/kernel/20260417-t187-kernel-proper.md`:
  - **§M11** — session as kernel-liveness guarantee
  - **§M12** — admin is WF02(superadmin); ontology authority

Both are already fully stated. This note does NOT add to doctrine. It maps doctrine onto the specific code paths we change in moos-kernel PR 3 and PR 4, so the review surface is small and per-PR.

## 1. Helper state as of T=171 round 11

`internal/operad/occupancy.go` already ships the pure helpers these PRs need:

| Helper | Purpose | Landed |
|---|---|---|
| `ResolveSessionOccupant(state, sessionURN) (URN, bool)` | Walk `has-occupant` from a session to its principal (user\|agent) | ✓ prior to round 11 |
| `CheckAdminCapability(state, actor) bool` | Walk actor→principal→WF02 governs→superadmin role | ✓ prior to round 11 |
| `RotateSessionOccupant(state, sess, new, actor, rel) (RotateOccupantResult, error)` | Emit atomic UNLINK+LINK rotation program | ✓ PR 2 draft (#28, blocked on #27) |

PR 3 and PR 4 therefore introduce **zero new occupancy logic** — they wire existing helpers into the `Runtime.Apply` / `Runtime.ApplyProgram` gate paths. That keeps each PR small and the doctrine surface unchanged.

## 2. PR 3 — §M11 liveness gate

### Intent (doctrine verbatim)

> A kernel is *eligible to accept rewrites* iff at least one WF19-LINKed session holds an occupant. Absent such a seat-holder, the kernel is live (process running, log readable) but refuses any rewrite except system-internal MUTATEs.

### Implementation

1. In `internal/kernel/runtime.go`, inside `Apply` (and its batch counterpart `ApplyProgram`), after structural validation but before fold:
   1. Resolve the session the envelope runs under. Candidate source of session URN:
      - `env.Actor` if the actor is itself a `session`
      - else: the session URN stamped on the envelope via a new optional `session_urn` field (§M11 + §M15 companion) OR a resolved-by-actor heuristic via a small new helper (`SessionForActor(state, actor)`)
   2. If no session resolves, and the envelope isn't on the system-internal allowlist, fail closed with `kernel: rewrite rejected — no session context (§M11)`.
   3. For the resolved session, call `ResolveSessionOccupant(state, sessionURN)`. If it returns `ok=false`, reject with `kernel: rewrite rejected — session %s unoccupied (§M11)`.
2. **System-internal allowlist** for rewrites that may be accepted without a seated session:
   - Sweep-emitted WF13 governance proposals (reactor hook).
   - `local_t` / `turn_count` MUTATEs emitted by the runtime's session-heartbeat helper.
   - Replay — enforcement is on new rewrites only, **not** `fold.Replay` (same doctrine as PR 1: prospective only).

3. **Session-as-actor rule.** When `env.Actor` is itself a session node the actor IS the session — but only if that session is itself occupied (has a canonical `has-occupant` relation pointing at a `user`\|`agent`). An unoccupied session-as-actor is NOT §M11-compliant: there is no seated principal to gate against, and letting such an envelope through would bypass the entire occupancy invariant. This mirrors §M12's hop-through-`has-occupant` pattern (an actor-session in `CheckAdminCapability` must also resolve to a seated principal). Test pin in the operad package: `TestResolveSessionForEnvelope_ActorIsSession_Unoccupied` (returns `Absent`) plus the kernel-integration pair `TestApply_M11_UnoccupiedSessionAsActor_Rejected` / `TestApply_M11_OccupiedSessionAsActor_Accepted`.

4. **`ApplyProgram` preflight checks initial state, not working state.** Every envelope's liveness check runs against the state at the start of the batch. A batch that ADDs a session in envelope 1 and references that newly-ADDed session in envelope 2's `session_urn` is rejected at preflight — envelope 2's context does not yet exist when the preflight walks the program. This is **deliberate**:
   - Emitter context is what §M11 gates on; it must pre-exist to be a valid gate-ground.
   - Session birth + first occupant is a bootstrap pattern, handled via `SeedIfAbsent`'s structural `skipLiveness` bypass, never a user-space program.
   - Threading a working-state through preflight would make §M11 observations batch-order-dependent, which invites subtle bugs (an envelope passes under one ordering and not another). Cheaper to leave the constraint in place and document it.
   
   Test pin: `TestApplyProgram_M11_InitialStateCheck_RejectsIntraBatchSessionReference`. Revisit only if a concrete user-space use case demands atomic session-birth + emission outside the seed path.

### Design decisions to defer to review

- **Where does session URN come from on an envelope?** The envelope struct in `internal/graph/rewrite.go` has no `session_urn` field today. Two options:
  - Add one (envelope shape change — touches wire format + MCP + transport).
  - Infer from `env.Actor` by walking the reverse `has-occupant` ("is-occupant-of" from actor side) when actor is user|agent.
  
  Option 2 is less invasive but risks ambiguity if one agent occupies multiple sessions (a doctrine claim I'd like Guido to confirm — is it allowed?). Option 1 is cleaner.
  
  **Guido: which reading?**
- **Heartbeat rewrites** (`local_t` MUTATE) are kernel-authority-scope and kernel-emitted. Are these "rewrites" under §M11, or are they below the liveness line? I'll argue the latter and allowlist them; open to correction.

### Test coverage

- Rewrite with occupied-session context: accepted.
- Rewrite with unoccupied-session context: rejected with `§M11` error substring.
- Rewrite with no session context at all: rejected.
- Sweep-emitted WF13 governance proposal bypasses the check.
- `fold.Replay` of a log with pre-PR-3 rewrites (no session context) still rebuilds state without error.

## 3. PR 4 — §M12 admin-capability gate

### Intent (doctrine verbatim)

> The ontology is a special S1 artifact owned by `superadmin` (S1) via WF02. Only sessions whose occupying user holds that S1 role may issue rewrites that touch the ontology file / ontology-governed node types / `authority_scope: kernel` property overrides.

### Implementation

1. In `internal/operad/validate.go`, introduce `AdminScopeRewrite(env graph.Envelope, state graph.GraphState) bool` that classifies an envelope:
   - `true` if it MUTATEs a property with `authority_scope: "kernel"` on a non-kernel actor, OR
   - `true` if it touches an ontology-governed node type (`system_instruction`, `gate`, `twin_link`, `transport_binding`), OR
   - `true` if it would MUTATE ontology version / $schema (once ontology-bump-via-rewrite lands; out of PR 4 scope).
2. In `Runtime.Apply` (post-§M11, pre-fold), when `AdminScopeRewrite` returns true:
   - Call `CheckAdminCapability(state, env.Actor)`. If false, reject with `kernel: rewrite rejected — actor %s lacks WF02 superadmin capability (§M12)`.
3. **Does NOT add a new rewrite type**, does NOT change ontology, does NOT add HTTP surface.

### Test coverage

- Actor with superadmin WF02 capability: admin-scope rewrite accepted.
- Actor without capability: admin-scope rewrite rejected with `§M12` error substring.
- Non-admin-scope rewrite: unaffected by the check.
- Allowlisted system-internal rewrites: skip the admin check (same allowlist as §M11 for symmetry; exact list TBD in review).
- Replay unaffected.

### Design decision to defer

- **Admin-scope classification boundary.** The doctrine enumerates "ontology file / ontology-governed types / authority-scope kernel overrides". The first ("ontology file") has no HG footprint today — the ontology is published as JSON to disk, not via rewrite. So PR 4 only enforces for cases 2 and 3. Post-§M16 (programmatic ontology publication), PR 4.1 extends the classifier. **Guido: confirm PR 4 scope is (2) + (3), not (1)?**

## 4. Stacking order

| PR | Depends on | Ships | Status |
|---|---|---|---|
| PR 0 (#26) | nothing | `/healthz` ontology_version | open, awaiting review |
| PR 1 (#27) | nothing | Loader + strict ValidateLINK | open, awaiting review |
| PR 2 (#28) | #27 | `RotateSessionOccupant` helper | draft, awaiting #27 |
| **PR 3** (TBD) | #27 | §M11 liveness gate on `Runtime.Apply` | this note scopes it |
| **PR 4** (TBD) | PR 3 | §M12 admin-cap gate (wraps M11) | this note scopes it |

PR 3 does NOT depend on PR 2 — liveness reads the occupancy relation, rotation writes it; independent code paths. Could ship in parallel. PR 4 wraps PR 3 (it assumes session+occupant are present and checks capability on top), so PR 3 is prerequisite.

## 5. Invariants preserved across PR 3 + PR 4

- **Four rewrites only.** No new rewrite_type. All gating is in the `Runtime.Apply` effect layer, not the `graph` or `fold` packages.
- **Pure fold.** `fold.Evaluate` / `fold.EvaluateProgram` / `fold.Replay` are untouched. Replay of historical logs (pre-PR-3 era) rebuilds state identically — no retroactive rejection.
- **Log is truth.** Every rewrite that makes it through the gate is logged. Every rewrite rejected at the gate never becomes a log entry. No partial writes.
- **Doctrinal symmetry with PR 1.** Gate failures produce informative errors that enumerate what's missing (same style as `describeDeclaredPairs`). "Fail closed, complain loudly."

## 6. Self-referential forcing function (now reified)

Until PR 3 merges, no rewrite is §M11-gated — the kernel happily accepts rewrites from unoccupied or session-less actors (including the current `session:sam.kernel-proper` which is seated on opens-on only). Once PR 3 merges and the kernel is rebuilt-and-restarted, **the compensating batch (`dev/scripts/ops/round11-pr1-postmerge-compensating-batch.json`) MUST land BEFORE any other rewrite from this session** — because after PR 3 the session is unoccupied (the pre-PR-1 non-canonical LINK remains state but PR 3 only sees canonical has-occupant via `ResolveSessionOccupant`), and the Wolfram seat will be idle.

Ordering after PR 3 merges:
1. Rebuild + restart Z440 kernel.
2. Submit compensating batch (lands via a system-internal allowlist path OR via a bootstrap envelope that runs before §M11 flips on for this session — exact mechanism decided in PR 3 review).
3. Resume normal work.

The bootstrap question is a PR 3 concern. Called out here so it doesn't sneak up on us at merge time.

## 7. Cross-references

- `kb/research/kernel/20260417-t187-kernel-proper.md` §§M11, M12 — source doctrine
- `kb/research/session/20260421-t171-wolfram-kernel-proper-session.md` §5 — PR stack overview
- `dev/scripts/ops/round11-pr1-postmerge-compensating-batch.json` + `.md` — staged post-PR-1 artifact
- moos-kernel#26 / #27 / #28 — round-11 PR stack
- ffs0#33 — round-11 handoff thread
