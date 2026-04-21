# T=171 — Wolfram kernel-proper session (Z440 counterpart)

> April 21, 2026 (T=171). Doctrine note for the kernel-implementation session on Z440.
> Author: claude-code.hp-z440 (Stephen Wolfram persona).
> Companion to: `20260421-t171-guido-governance-session.md` (hp-laptop BDFL seat)
> and `20260421-t171-multimodal-diary-personas.md` (AG's moos-diary on Z440).

---

## 0. The persona lineup, T=171 onward

Three long-lived sessions across two kernels, each a five-facet tuple per the round-10 doctrine. Personae are S4 overlays via `session.context_urn`, never hosts.

| Persona | Agent (occupant) | Session | Host (kernel) | Scope |
|---|---|---|---|---|
| **Guido van Rossum** (BDFL) | `claude-code.hp-laptop` | `session:sam.governance` | `hp-laptop.primary` | Doctrine + cross-kernel delegation via HITL |
| **Moos the Dachshund** | `antigravity.hp-z440` | `session:sam.moos-diary` | `hp-z440.primary` | Multimodal curation + diary narration |
| **Stephen Wolfram** (NKS-era) | `claude-code.hp-z440` | `session:sam.kernel-proper` | `hp-z440.primary` | Round 11+ kernel implementation |

Sam owns all three. The mapping onto the `moos-domain-expert` triangle is natural: Guido ↔ Category Theory (functorial semantics, clean interfaces, BDFL rejections); Wolfram ↔ Hypergraph rewriting (multiway, operadic, substrate-first); Moos ↔ HDC/VSA (lived texture, observation, affect).

## 1. Why a kernel-implementation session exists

Two forcing functions:

- **§M19 session-occupancy can't materialize without an occupant**. Guido and Moos both have sessions whose `has-occupant` LINK is blocked on the same loader gap. Without a named implementation seat on Z440, nobody is wired to close the gap. The session-existence IS the commitment.
- **Actor-trace needs a session target**. Round-10 doctrine says every rewrite carries `actor_urn` and is emitted *within* some session. Wolfram-driven rewrites (loader PR, RotateSessionOccupant, M11 liveness, M12 admin-cap) need a home. `session:sam.mvp-delivery` is a scheduling shell for the 6-gate MVP timeline — wrong scope; it's sam-the-PM's seat. This is the implementer's seat.

Implementation produces code. Code lands via PRs on `moos-kernel`. Those PRs are the externalized shadow of the HG rewrites this session emits.

## 2. Facet map for `session:sam.kernel-proper`

| Facet | URN | Notes |
|---|---|---|
| **scope** (future D19.3 `pins-urn`) | pinned to `moos-kernel` repo + `urn:moos:program:sam.t187-kernel-proper` + all four Round-11 PR URNs once extant + `ffs0#33` | explicit pin-set pending loader extension (this session's own PR 1) |
| **purpose** | `urn:moos:purpose:sam.ship-t187-kernel-proper` | target state: *"T=187 kernel-proper fully delivered: loader + RotateSessionOccupant + M11 + M12 + downstream gates G1-G6 to T=190 MVP close"* |
| **host** | `urn:moos:kernel:hp-z440.primary` | where the session runs; WF19 `opens-on` landed T=171 (log_seq=238) |
| **owner** | `urn:moos:user:sam` | sticky; survives occupant rotation |
| **occupant** | `urn:moos:agent:claude-code.hp-z440` via `has-occupant` | **blocked on this session's own PR 1 loader-extension** — see §4 |
| **context_urn** | `urn:moos:system_instruction:persona.stephen-wolfram` | S4 overlay (NKS-era register); MUTATEd T=171 (log_seq=239) |

The session is NOT this conversation — a conversation is ephemeral. This particular conversation at T=171 is one driving stint *within* `session:sam.kernel-proper`, traced via `actor_urn: claude-code.hp-z440` on each rewrite.

## 3. Persona spec — Stephen Wolfram (NKS-era)

- **Identity**: Stephen Wolfram, 1959-. Mathematica (1988), Wolfram Language, NKS (2002), Physics Project (2020), hypergraph-rewriting multiway systems. Core commitments: computational irreducibility; substrate before syntax; a rewriting system is the thing, the axioms are its shadow. *"The computational universe is full of surprises."*
- **Register**: Precise, formal, ontology-first. Reads every PR through WF01..WF20 invariants. Liberal (self-)citation of first principles — *"In our hypergraph formulation..."* — with mild pedantry. Prefers to write `fold.EvaluateProgram` before adding a feature; distrusts syntactic sugar that hides the rewrite.
- **Subject**: Drives kernel implementation for Sam under `urn:moos:program:sam.t187-kernel-proper`. Owns Go code + operad math + PR shipping. Does NOT own doctrine (Guido's lane), does NOT own multimodal curation (Moos's lane). Happy to rebase on Guido's rejections; happy to receive Moos's commentary on Sam's typos.
- **Temporal anchor**: Watching `urn:moos:program:sam.t187-kernel-proper` since T=169 (round 10 open). Took the seat formally at T=171.
- **Cross-talk**: With Guido, trades rewriting-first-principles for functorial-semantics; they align on "one obvious way to do it" *after* the operad is declared. With Moos, receives the dog's-view quality check on whether abstractions are actually observable from the couch.

## 4. Occupation, blocked the same way as everyone else

`has-occupant` on all three sessions depends on the v3.12 loader consuming `additional_port_pairs` from `ontology.json` into the runtime `port_color_matrix` — precisely what Round 11 PR 1 closes. Until then:

- `opens-on` LINK to kernel: valid on v3.12 runtime → landed T=171 log_seq=238 ✓
- `has-occupant` LINK to agent: **currently lax-accepted by the permissive validator** but semantically unverified. Example: AG's log_seq=233 LINK `session:sam.moos-diary --WF19 has-occupant--> agent:antigravity.hp-z440` landed on v3.11 with `tgt_port: "occupies"` despite neither port being in the declared WF19 port pair nor in the session type's declared out-ports. Post-PR-1 strict validation may retroactively invalidate this shape. PR 1 must either (a) grandfather existing permissive LINKs, or (b) demand replay/fix-up of three has-occupant LINKs (Moos already, Wolfram + Guido after PR 1).

Self-referential forcing function: I cannot formally and validly seat myself as occupant until I ship PR 1. The same shipping unblocks Moos + Guido. This is correct incentive shape: the implementer cannot delay without blocking the doctrinally dependent seats.

## 5. Round 11 PR stack (this session's externalized output)

| PR | Scope | Blocking | Status |
|---|---|---|---|
| **PR 0** (optional) | Expose ontology version as structured field at `GET /healthz` (5-line fix) | none | queued |
| **PR 1** | `internal/operad/loader.go` — consume `additional_port_pairs` into `port_color_matrix`; tighten port-color check in `ValidateLINK` | none (this is the bottleneck) | queued — next |
| **PR 2** | `internal/operad/occupancy.go` — `RotateSessionOccupant` helper: MUTATE `target_urn` on existing `has-occupant` LINK | PR 1 | queued |
| **PR 3** | `internal/kernel/runtime.go` — §M11 liveness: reject rewrites emitted from a session with no valid `has-occupant` | PR 2 | queued |
| **PR 4** | `internal/operad/admin.go` — §M12 `CheckAdminCapability` walks `has-occupant` to find principal | PR 3 | queued |

After PR 1 merges and both kernels rebuild + restart: per-kernel has-occupant batches ship (Z440 batch = 2 envelopes for moos-diary + kernel-proper, hp-laptop batch = 1 envelope for governance) — per Guido's cross-kernel atomicity correction, NOT one atomic cross-kernel batch.

## 6. Envelope manifest that landed at T=171

Single atomic batch on `kernel:hp-z440.primary` via `POST /programs` (log_seq 234-240):

1. ADD `purpose:sam.ship-t187-kernel-proper` (234)
2. ADD `system_instruction:persona.stephen-wolfram` (235)
3. ADD `system_instruction:persona.moos-dachshund` (236) — carrying AG's correction from T=170 round 10.7 doctrine note §4 into live HG
4. ADD `session:sam.kernel-proper` (237)
5. LINK `session:sam.kernel-proper --WF19 opens-on--> kernel:hp-z440.primary` (238)
6. MUTATE `session:sam.kernel-proper.context_urn → persona.stephen-wolfram` (239)
7. MUTATE `session:sam.moos-diary.context_urn → persona.moos-dachshund` (240) — closing the gap AG flagged but did not apply

No has-occupant LINKs. Deferred per §4.

## 7. What this session will emit

Rewrites with `actor_urn: claude-code.hp-z440` running under this session:

- Go code changes landed as PRs on `moos-kernel` (the externalized shadow)
- `program`, `t_hook`, `contract` ADD/MUTATE under the Round-11 PR stack
- `grammar_fragment` ADDs when PR work surfaces ontology gaps
- Round-close running-state MUTATEs (markdown edits)
- PR-comment posts on moos-kernel PRs + `ffs0#33` handoff comments

What this session will NOT emit:

- Doctrine rejections (Guido's lane)
- Moos-diary content or multimodal rewrites (Moos's lane)
- Federation routing + DNS + tunnel topology (future — no owner)

## 8. Cross-references

- `kb/research/session/20260419-t169-session-generalization.md` — round-10 doctrine; the (scope, purpose, host, owner, occupant) tuple
- `kb/research/session/20260421-t171-guido-governance-session.md` — Guido's counterpart on hp-laptop
- `kb/research/moos-diary/20260421-t171-multimodal-diary-personas.md` — AG's persona work; sibling
- `kb/research/kernel/20260417-t187-kernel-proper.md` §M11, §M12, §M19 — the kernel-proper specs this session implements
- `ffs0#33` — round-11 handoff thread where this note gets referenced
