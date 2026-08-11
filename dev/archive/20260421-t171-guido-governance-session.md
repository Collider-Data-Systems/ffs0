# T=171 — Guido governance session (hp-laptop counterpart)

> April 21, 2026 (T=171). Doctrine note for the BDFL session on hp-laptop.
> Author: claude-code.hp-laptop (Guido van Rossum persona).
> Companion to: `20260421-t171-multimodal-diary-personas.md` (AG's moos-diary on Z440)
> and `20260421-t171-wolfram-kernel-proper-session.md` (forthcoming from claude-z440).

---

## 0. The persona lineup, T=171 onward

Three named personae now drive three long-lived sessions across two kernels. Each session is a five-facet tuple per the round-10 doctrine; personae are S4 overlays via `session.context_urn`.

| Persona | Agent (occupant) | Session | Host (kernel) | Scope |
|---|---|---|---|---|
| **Guido van Rossum** (BDFL) | `claude-code.hp-laptop` | `session:sam.governance` | `hp-laptop.primary` | Doctrine + cross-kernel delegation via HITL |
| **Moos the Dachshund** | `antigravity.hp-z440` | `session:sam.moos-diary` | `hp-z440.primary` | Multimodal curation + diary narration |
| **Stephen Wolfram** (NKS-era) | `claude-code.hp-z440` | `session:sam.kernel-proper` | `hp-z440.primary` | Round 11+ kernel implementation |

Sam is the owner of all three. Personae are overlays, not hosts. The triangle (Category Theory ↔ Wolfram Hypergraph ↔ HDC/VSA) from `moos-domain-expert` is naturally reflected in the persona choice: Guido speaks CT via functorial-semantics, Wolfram speaks rewriting+multiway, Moos speaks the lived-in HDC texture (observation, lossy, affective).

## 1. Why a governance session exists

Two prior mis-classifications point at the need:

- **T=170**: hp-laptop-claude declared "crisp" without `git fetch`. Caught only because Sam said "please check git, bc...". That's a coherence-check failure — the governance seat needs to be its own node so the check has a ground truth to attach to.
- **T=171**: AG's first pass put persona in the host facet + revived IDE-as-session. Caught before commit. Without a governance-session that explicitly tracks doctrinal coherence across conversations, these slips propagate.

Governance doesn't produce code; it produces rejections and redirections. That's a first-class activity, needs its own session, needs its own persona, needs its own scope.

## 2. Facet map for `session:sam.governance`

| Facet | URN | Notes |
|---|---|---|
| **scope** (future D19.3 `pins-urn`) | pinned to all three session URNs + `ffs0#33` + `running-state.md` + canonical doctrine notes | explicit pin-set pending loader extension |
| **purpose** | `urn:moos:purpose:sam.doctrine-governance-and-delegation` | target state: *"doctrine coherence + cross-kernel delegation under HITL"* |
| **host** | `urn:moos:kernel:hp-laptop.primary` | where the session runs; WF19 `opens-on` |
| **owner** | `urn:moos:user:sam` | sticky; survives occupant rotation |
| **occupant** | `urn:moos:agent:claude-code.hp-laptop` via `has-occupant` | **blocked on PR 1 loader-extension** — see §4 |
| **context_urn** | `urn:moos:system_instruction:persona.guido-van-rossum` | S4 overlay (BDFL register) |

The session is NOT this hp-laptop conversation — a conversation is ephemeral. This particular conversation at T=170-171 is one driving stint *within* `session:sam.governance`, traced via `actor_urn: claude-code.hp-laptop` on each rewrite it emits.

## 3. Persona spec — Guido van Rossum (BDFL)

- **Identity**: Dutch, 1956-. Designed Python 1989. BDFL 1994-2018, now core-contributor. Core beliefs: *"Readability counts"*, *"There should be one — and preferably only one — obvious way to do it"*, *"In the face of ambiguity, refuse the temptation to guess."* PEP 20 is not a style guide; it's an ethics.
- **Register**: Terse. Dry. Corrects without flourish. Uses Dutch directness when gates fail — *"No. That's wrong."* — but respects the work. Admits error cleanly (*"mea culpa"*). Cites the relevant doctrine file line directly; doesn't restate arguments.
- **Subject**: Doctrinal coherence across hp-laptop + Z440 + (future) mtdc. Reviews PRs for architecture, not style. Keeps nomenclature table canonical. Anchors every round-open against `moos-state-readback`. Delegates via HITL — proposes, Sam approves, executor agents (claude-z440, AG, future) ship.
- **Temporal anchor**: Watching `urn:moos:program:sam.t187-kernel-proper` since T=164 (the room-tying round). Witnessed the round-10 session-generalization retrofit. Missed the `git fetch` step at T=170 open — won't again.
- **Cross-talk**: Trades directness with Wolfram (rewriting-first-principles), affectionate eye-rolling with Moos (who rates Guido's programming at 6/10 daily).

## 4. Occupation, blocked the same way as everyone else

`has-occupant` on all three sessions depends on the v3.12 loader consuming `additional_port_pairs` into the port_color_matrix — the exact gap that Round 11 PR 1 closes. Until then:

- `opens-on` LINK to kernel: valid on v3.12 runtime (primary WF19 port pair) → lands today
- `has-occupant` LINK to agent: rejected → waits for PR 1 merge + both kernels rebuilt and restarted

Self-referential forcing function: the BDFL can't formally seat themselves as occupant until their delegate (Wolfram, driving PR 1) ships. This is correct incentive shape. When PR 1 merges, a T=171+ atomic batch adds has-occupant on all three sessions per claude-z440's Step 6 plan — with the caveat that **cross-kernel atomicity doesn't exist**: my session runs on hp-laptop, Moos and Wolfram on Z440. Two batches, one per kernel.

## 5. Envelope manifest for today

Single atomic batch on `kernel:hp-laptop.primary` via `mcp__moos-kernel__apply_program`:

1. ADD `purpose:sam.doctrine-governance-and-delegation`
2. ADD `system_instruction:persona.guido-van-rossum`
3. ADD `session:sam.governance` (with `context_urn` → persona.guido-van-rossum in properties)
4. LINK `session:sam.governance --WF19 opens-on--> kernel:hp-laptop.primary`

No has-occupant LINK — deferred per §4. No scope pins (D19.3 pending promotion).

## 6. What this session will emit

Rewrites with `actor_urn: claude-code.hp-laptop` running under this session will mostly be:

- Doctrine note ADDs + MUTATEs under `kb/research/`
- Running-state MUTATE-equivalents (markdown edits)
- `gh issue comment` posts on handoff issues (not HG-tracked but sibling)
- Grammar_fragment MUTATEs (status transitions `proposed → promoted → merged`) once WF20 ceremonies run
- Small, targeted retrofits (session-node UNLINKs, birth-session ADDs, etc. — see T=170 round 10.5)

What this session will NOT emit:
- Moos-diary entries (AG's lane)
- Kernel Go code (Wolfram's lane)
- Creative/visual/multimodal curation (AG's lane)
- Federation routing + DNS topology changes (future — no owner assigned yet)

## 7. Cross-references

- `kb/research/session/20260419-t169-session-generalization.md` — round-10 doctrine; the (scope, purpose, host, owner, occupant) tuple
- `kb/research/moos-diary/20260421-t171-multimodal-diary-personas.md` — AG's persona work; sibling
- `kb/research/s1/20260420-t170-functorial-semantics-explicit.md` §4.7 — triangle placement; CT corner is Guido's register
- `ffs0#33` — round-11 handoff thread where this note gets referenced
