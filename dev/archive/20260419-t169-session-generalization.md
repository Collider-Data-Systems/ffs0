# T=169 — Session generalization: kernel-bound workspaces, not IDE conversations

> April 19, 2026 (T=169). Round-10 doctrine note.
> Author: claude-code on hp-z440 (driving session `sam.round10-session-generalization`).
> Supersedes: parts of `20260418-t168-session-kernel-bound.md` (§M11 FAQ) and `../../../dev/reference/research-archive/20260414-t164-session-channel-purpose.md` §2 (monoid framing; archived T=169 round 10).

---

## 0. Why this note exists

The session concept accumulated a set of related but partially-sloppy claims across three rounds of doctrine:

- §M1 (kernel-proper.md): "session is a monoid `(S, ∘, e)`; identity = empty session"
- §M11 (kernel-proper.md): at least one non-identity element of the monoid must be bound to the kernel for liveness
- `20260418-t168-session-kernel-bound.md`: sessions are permanent kernel-bound; occupancy ledger = multiple sessions per kernel, one occupier
- `../../../dev/reference/research-archive/20260414-t164-session-channel-purpose.md` §2: "Session is a MONOID over kernel occupancy — identity = the empty session (kernel idle, no delegate), binary operation = s₁ ∘ s₂" (archived T=169 round 10)

Each captured part of the truth but left open: what exactly is the carrier of the monoid (object? transitions?); is a session per-kernel or per-user; what is an IDE conversation relative to a session; how do delegates / groups / nested workspaces fit. This round-10 note settles the corrections in one place, lifts the CT framing to the right algebraic register (operadic + monoid + lattice), and defines the session tuple the kernel code will act on from round 11 onward.

---

## 1. What a session is (corrected, tuple form)

A **session** is a persistent, always-on HG node defined by the tuple

```
session = (scope, purpose) × (host, owner, occupant)
```

Five orthogonal facets. Everything else about a session derives from how these are wired.

| Facet | Carrier | Description |
|---|---|---|
| **scope** | D19.3 `pins-urn` LINKs (proposed) + D22.5 `contains-session` (future) | The set of nodes the session is attending to. Arbitrary nodes: kernels, programs, purposes, other sessions, knowledge_items, calendar_events, whatever the owner cares to pin. |
| **purpose** | D22.1 `has-purpose` LINK (proposed this round, single-valued with rotation) | What the session is FOR. Fine-grained purposes nest under coarse ones in a purpose-containment lattice (`purpose-of-round-10 ⊑ purpose-of-session-doctrine ⊑ purpose-of-moos`). |
| **host** | WF19 `opens-on / occupied-by` LINK to a kernel | Where the session runs — provides heartbeat (`local_t` ticks per acknowledged rewrite), persistence, gate evaluation. Today always a `kernel`; a future `running_host` supertype (Reading B, candidate D22.5) would admit `platform` for non-mo:os hosts (Google ADK, Anthropic workspace, external MCP daemons). Until then, host = kernel — self-owned or hosted-by-someone-else (same binding, different `kernel.owner_urn`). |
| **owner** | `session.owner_urn` property (carried as property for now; could lift to a `served-by / serves` LINK later) | The principal the session serves. Sticky — survives occupant rotation and host migration. Birth-sessions are kernel-owned (self-owned); user workspaces are user-owned; agent scratchpads are agent-owned. |
| **occupant** | WF19 `has-occupant / is-occupant-of` LINK to a user or agent (D19.1 merged v3.10) | Who's currently driving. Single-valued (D22.2 invariant, proposed this round). Rotation = MUTATE of the LINK's target_urn, atomic, preserves session identity per CI-3. |

**Example — sam's Z440-control session:**

```
session:sam.z440-admin
  scope ⊇ { kernel:hp-z440.primary, agent:claude-code.hp-z440, ...infra nodes pinned for monitoring }
  purpose → purpose:sam.admin-operations (generic, reusable across rounds)
  host → kernel:hp-z440.primary  (WF19 opens-on)
  owner_urn = urn:moos:user:sam
  occupant → agent:claude-code.hp-z440  (when sam drives from Z440)
           → agent:claude-code.hp-laptop  (when sam drives remotely — via MUTATE target_urn)
```

The session persists across IDE conversations. The occupant rotates as sam moves between machines / agents. The purpose stays while the work is coherent; it rotates to a different purpose URN when sam repurposes the session.

**IDE conversations are not sessions.** What a claude-code or antigravity panel is *doing* is ephemeral — the rewrites it emits are traced via `actor_urn` on each envelope, and they produce transitions *within* some session. But the conversation itself is not a first-class HG object. The existing `session:sam.claude-code-hp-laptop` / `session:sam.claude-code-hp-z440` nodes were mis-classified against this model — their URN pattern `<user>.<agent>.<T-day>` encoded IDE-conversation identity, not session identity per this corrected definition. Conversation A retires them.

**URN conventions:**

- Kernel birth-session (kernel-owned, one per kernel): `urn:moos:session:<kernel-short>` — e.g. `session:hp-z440.primary`.
- User/agent-owned session (workspace or purpose-scoped): `urn:moos:session:<owner-short>.<scope-or-purpose-slug>` — e.g. `session:sam.z440-admin`, `session:sam.round10-session-generalization`.
- No `<T-day>` segment. That was creation-time decoration, not a lifetime bound.

---

## 2. CT lingo (corrected — operadic, not just monoidal)

The original §M1 claim "session is a monoid `(S, ∘, e)` — identity = empty session" was partially right but conflated several structures. Three separable algebraic layers actually live here, each doing different work:

### 2.1 Per-session transition-monoid

Each session snapshot is a **single-object category**. The self-morphisms of that object are the session's internal transitions:

- advance `local_t` (heartbeat tick, per §M13)
- rotate `has-occupant` target_urn (occupant change)
- repurpose: rotate `has-purpose` target_urn (scope-of-intent change)
- add / remove a `pins-urn` LINK (scope change)
- mount / unmount a tool (D20.1)
- context-swap (change `context_urn` system_instruction overlay)

These morphisms form a monoid under composition. **Identity = the no-op transition** (the morphism that leaves the session snapshot unchanged). Associativity is free (morphism composition is always associative). Not a group (transitions are not invertible — log-is-truth).

§M4's "session as monoid functor" `S: SessionCat → KernelCat` is exactly this: S maps the transition-monoid of a session to its image as a sequence of kernel rewrites. WF19 is the naturality square — a session transition commutes with the kernel rewrite that realizes it.

**Side-by-side correction:**

| Was (session-channel-purpose.md §2) | Now |
|---|---|
| "Identity element: the empty session (kernel idle, no delegate)" | Identity MORPHISM: the no-op transition. The session OBJECT is always fully-formed (born with the kernel). What's trivial is the morphism, not the object. |
| "Binary operation: `s₁ ∘ s₂` = session s₁ closed, session s₂ opened, same kernel" | Binary operation on **transitions**: `t₁ ∘ t₂` = apply transition t₂ after transition t₁. Sessions don't close; transitions compose. |
| "Not a group: no inverse — you cannot un-session historical occupancy" | Still true, at the transition level: transitions are not invertible because log entries are not retractable. |

### 2.2 Operadic scope composition (multi-input)

Sessions nest. `session A contains session B` is a real relationship — A's pinned scope includes B, or A has a `contains-session / contained-in-session` LINK to B (candidate D22.5 in a future round). This is **operadic**, not monoidal: many-inputs → one-output, which matches §M4's acknowledgment that sessions have WF07 participants (plural, distinct from the single occupier).

Root of the operad on a given kernel = the kernel's birth-session (kernel-owned, privileged scope position — includes the kernel itself plus seeded infra nodes). Every other session on that kernel is operadically subordinate in the scope-containment lattice.

An agent's primary session can operadically include the user-owned sessions it's currently driving. This is reified nesting — the agent session doesn't *become* the user session, it *contains* a reference to it. Identity and containment stay separate.

### 2.3 User/group topology (orthogonal lattice)

Which principals can open/occupy which sessions = a separate lattice from scope-containment. Today partially expressed via WF02 `capability` nodes (scope, max_rewrites, authority). Full formalization (teams, delegation trees, group sessions) deferred to a future research note — candidate `kb/research/session/YYYYMMDD-session-operad-and-topology.md`, not this round.

**Three algebras compose, they don't collapse.** Transition-monoid describes what each session does over time. Operadic scope describes how sessions nest. User/group topology describes who can access what. The original "session is a monoid" claim only saw the first, and even that conflated identity-morphism with empty-object.

---

## 3. Designated-driver invariant (single-valued via LINK)

D19.1 merged the `has-occupant / is-occupant-of` port pair (WF19, tgt_types user+agent) in v3.10 but did not itself enforce at-most-one. That's D22.2's invariant, proposed this round:

> ∀ session S, ∀ t-instant T: `|{l : S --has-occupant--> l}| ∈ {0, 1}`
>
> Zero = session alive but idle (no current driver). Exactly one = session occupied and driving.
>
> Rotation = MUTATE of the LINK's target_urn (atomic, preserves session identity per CI-3).
>
> Validator rejects any ADD has-occupant on a session that already has one; the valid rotation path is MUTATE, not ADD+UNLINK.

Once D22.2 promotes, the kernel operad validator enforces this. Until then, it's doctrine-only and the round-11 session-occupancy Go code (Conversation E per the round plan) prospectively respects it.

**No separate observer/delegate role on the session.** The old `seat_role` enum `{occupier, observer, delegate}` conflated "is driving" with "is attached". Under the corrected model: the has-occupant LINK's presence = "has a driver"; its target_urn = "who's driving"; absence = "idle but alive". Observers and delegates, if needed, are carried via WF02 `delegates-to` LINKs *between principals*, outside the session — the session simply reflects the current driver.

`seat_role` is therefore deprecated in v3.12 (Conversation B's ontology update). Scheduled for removal in v3.13. Existing sessions carrying the property aren't re-written; validators ignore it.

---

## 4. Sessions proliferate by purpose, not by conversation

Every kernel has at least one session (its birth-session) from log-seq 0 onward — the atomic-pair invariant (D22.4, proposed this round). Additional sessions may be ADDed when a purpose materializes; each is a distinct workspace with its own pins, purpose, occupant.

Analogy: the kernel is the OS; the birth-session is the login shell (always there); purpose-scoped sessions are additional terminal windows, each with its own working directory, environment, and current activity.

The round-10 work itself gets its own session: `urn:moos:session:sam.round10-session-generalization`, hosted on hp-z440.primary, owned by sam, occupied by agent:claude-code.hp-z440 (for the duration of this round), with has-purpose pointing at `purpose:sam.coherent-session-doctrine`. When round 10 closes, the session persists; when round 11 opens the Go implementation work, a new session is ADDed for that — or the round-10 session is repurposed via MUTATE of has-purpose target_urn.

---

## 5. Future: autonomous HG-program occupant

Today `has-occupant` accepts tgt_types `{user, agent}` (D19.1 in v3.10). A future WF02 extension will admit `program` as a tgt_type, letting a properly-authorized HG program node occupy a session without a human/agent driver. That's how autonomous runtime behavior emerges — a program pins its own scope, carries its own purpose, drives its own session. Gates and approver-reactor mediate admin-scope actions.

Requires: the approver reactor (governance_proposal.status=approved → apply envelope) landing; CI-6 capability-isolation formalized; bespoke-agent harness (D20.3) crystallized so programs have a runtime-envelope story.

Out of scope for round 10; flagged here so the doctrine note doesn't over-specify "occupant is always a user or agent."

---

## 6. Generalization to tools and CLI agents

The following grammar_fragments (all proposed rounds 5–7, targeting WF20 promotion in Conversation B of this round) together give the session its full workspace-anchor shape:

| Fragment | Adds |
|---|---|
| D19.2 session-view-prefs | `session.view_prefs` scalar object (sort_by, fold_depth, density, theme) |
| D19.3 session-pins-urn | `pins-urn / pinned-by-session` port → any node |
| D19.4 session-filtered-by | `filtered-by / filters-session` port → view_filter |
| D20.1 session-mounts-tool | `mounts-tool / tool-mounted-in-session` port → agent |
| D20.2 agent-invocation-protocol | `agent.invocation_protocol` enum {stdio, mcp, http} |

These project onto any agentic framework's session-like construct:

- **MCP client sessions** — 1:1 client-server connection with capability negotiation → mounts-tool edges per server, invocation_protocol=mcp.
- **LangGraph threads + checkpoints** — pins-urn + view_filter for the thread's scope; local_t as checkpoint counter.
- **CrewAI crews** — operadic scope: a crew session contains its member agent-sessions.
- **tmux / screen sessions** — the original detach/attach precedent; multiple has-occupant rotations across attached clients.
- **Emacs** — buffers as pins, modes as view_filters, M-x as tool invocation.

Vocabulary lock-in: we keep **session** — load-bearing across the §M-series and the ontology, and the Chrome-tab / tmux-session metaphor is more accurate than "thread" (implies transience) or "trajectory" (implies a path).

---

## 7. Purpose as higher-level semantic wiring

Tools are leaf capabilities — signatures, port colors, invocation protocols. They're *what the system can do*.

Purpose is a gradient field that steers *which* capabilities fire in *which* order:

```
φ(purpose) = φ(target_state) − φ(current_state)
```

Purpose-in-session is the completion-drive: rewrites the occupant emits should be biased toward closing gates on incomplete-spec nodes, aligned with the purpose gradient. The occupant fills in properties, the sweep proposes realizations when predicates hold, the approver-reactor applies on admin approval.

D22.1 (this round) proposes `session has-purpose purpose` as a single-valued rotatable LINK, so purpose-steers-session is first-class rather than routed through program composition. Three lingo registers for what purpose does:

- **gradient** (HDC math) — cos-similarity between candidate-rewrite-effect and purpose-gradient scores a rewrite.
- **attractor** (dynamical systems) — purpose is the attractor; rewrites tend toward it over time.
- **telos** (philosophy, Aristotelian final cause) — playful jab at the "industry buzzword for what-the-system-is-for"; purpose topologized becomes structure.

All three reference the same φ structure; choice of register depends on audience. Cos-similarity scoring in the sweep itself is deferred to `wiring-proposer` (target_t=250), not round 10.

**Purpose as topologized buzzword.** Industry accumulates agentic terms (tools → workflows → skills → context → intent → harness → purpose), each adding semantics through adjective accumulation. "Purpose" is the apex: supposedly denotes what-the-system-is-for, yet the most vacuous when floating free. mo:os neutralizes this by making `purpose` a node with typed internal relations (`steers / declared-by / has-purpose`). The Yoneda move: a thing IS what it connects to. Buzzwords topologized = structure; buzzwords untopologized = **boundary relations** — keys into relations whose codomain lives outside the system (formerly called metadata).

Every "collide the data into the graph" move is the promotion of a boundary relation into an internal relation. v310-1 port_binding reifies the 4-tuple (src_type, src_port, tgt_type, tgt_port) this way; D22.1 does it for the session-purpose relation.

---

## 8. Completion-drive and incomplete specs

A node captured with empty properties + a `t_hook` whose predicate fires at some target_t + a `react_template` that attempts the realization MUTATE = spec-realizer promise. The node persists whether or not the realization lands.

`gate` nodes (§M8) are the first-class "incomplete data" primitive — they block realization MUTATEs via fail-closed predicates. When the sweep fires a t_hook's react_template at target_t, gates are evaluated first. Gate fails → rewrite blocked → firing_state doesn't advance past `proposed`.

Session's occupant drives completion:

1. Occupant MUTATEs properties on the incomplete-spec node over time (fills in gaps).
2. The kernel sweep ticks; at target_t, the node's t_hook predicate holds.
3. Sweep emits `ADD governance_proposal` + `MUTATE t_hook.firing_state proposed` atomically (v3.11).
4. Gates evaluate. If all pass: admin/approver-reactor MUTATEs proposal status to `approved`, then the approver-reactor applies the proposed envelope (firing_state → applied).
5. If gates fail: admin MUTATEs status to `rejected` (firing_state → rejected), or the hook simply expires (firing_state → closed) and can be re-proposed with a new target_t.

Node persists either way. The incomplete-spec-mapped-over-time pattern is the substrate; purpose-in-session is the scoring signal; sweep + firing_state is the machinery.

---

## 9. Disposition of the mis-classified session nodes

Log-is-truth forbids retyping nodes. The existing nodes stay; only their active wiring is unwound.

Round 10 Conversation A:

- **UNLINK** `session:sam.claude-code-hp-laptop --WF19 opens-on--> kernel:hp-laptop.primary` (the LINK was ADDed at log_seq 486 per the hplap log).
- **UNLINK** `session:sam.claude-code-hp-z440 --WF19 opens-on--> kernel:hp-z440.primary` (log_seq 487).
- Historical `.t164 / .t167 / .t168`-suffixed sessions already UNLINKed per round-4 merge; they remain as provenance.

Then ADD the correctly-named kernel-bound birth-sessions, retrofitting the atomic-pair invariant for the two existing kernels:

- **ADD** `session:hp-laptop.primary` with `started_at=2026-04-03T01:05:11Z` (verbatim from `kernel:hp-laptop.primary.created_at`), `local_t=0`, `owner_urn=kernel:hp-laptop.primary`. Seat-role property omitted (deprecated in v3.12).
- **LINK** `session:hp-laptop.primary --WF19 opens-on/occupied-by--> kernel:hp-laptop.primary`.
- **LINK** `session:hp-laptop.primary --has-occupant--> agent:claude-code.hp-laptop` (current driver).
- **ADD** `session:hp-z440.primary` with `started_at=2026-04-05T08:45:00Z`, `local_t=0`, `owner_urn=kernel:hp-z440.primary`.
- **LINK** `session:hp-z440.primary --WF19 opens-on/occupied-by--> kernel:hp-z440.primary`.
- **LINK** `session:hp-z440.primary --has-occupant--> agent:claude-code.hp-z440`.

New kernels from round 11 onward will emit the kernel+birth-session atomic pair in a single ApplyProgram envelope (once D22.4 promotes and the `--seed` code is updated).

---

## 10. Cross-references

Live doctrine (still authoritative):

- `kb/research/kernel/20260417-t187-kernel-proper.md` — §M1 (session as monoid — CT-framing superseded by §2 of this note), §M4 (monoid functor — accurate), §M11 (liveness — accurate), §M13 (t_local as heartbeat — accurate), §M18–§M20 (session generalization — accurate), §M21 (group topology — accurate).
- `dev/reference/research-archive/20260418-t168-s0-operadic-layer.md` — operadic lingo, applicable to §2.2 of this note.
- `dev/reference/research-archive/20260418-t168-s1-superset-doctrine.md` — S4→S1 adjoint, grammar_fragment lifecycle.
- `dev/reference/research-archive/20260418-t168-v3.9-ontology-audit.md` — baseline audit, WF20 promotion pipeline.

Superseded (partially) by this note:

- `dev/reference/research-archive/20260418-t168-session-kernel-bound.md` — the FAQ model of "multiple sessions per kernel, one with seat_role=occupier" is replaced by "one birth-session per kernel + additional purpose-scoped sessions; at-most-one has-occupant LINK per session". The FAQ stays as historical record.
- `dev/reference/research-archive/20260414-t164-session-channel-purpose.md` — §2 "Session is a MONOID over kernel occupancy" with identity = empty session is replaced by §2.1 of this note (transition-monoid with identity morphism). Archived T=169 round 10 Conversation D.

Archived in Conversation D (pure-absorption, full content carried forward into live doctrine):

- `dev/reference/research-archive/20260418-t187-categorical-contract.md` — proofs hold by construction; landed.
- `dev/reference/research-archive/20260418-t187-walk-answers-Q1-Q4.md` — Q1-Q4 answered + implemented.
- `dev/reference/research-archive/20260414-t164-session-channel-purpose.md` — T=164 foundational work; in HG.
- `dev/reference/research-archive/20260418-t168-t187-delivery-clock.md` — schedule live in v3.11 firing_state.
- `dev/reference/research-archive/20260417-t166-wire-answer-folder-nesting.md` — Q5 answered, ontology-only.

---

## 11. Round-10 HG wiring summary (Conversation A)

For provenance, the rewrites this round emits:

**Opening batch** — ADDs for round-10 program + purpose + t_hook; WF18 composes to sub-programs.

**Retire batch** — UNLINKs for mis-classified sessions; ADDs for correctly-named birth-sessions; has-occupant LINKs to current driving agents.

**Optional demonstrator** — ADD `session:sam.round10-session-generalization` as a Chrome-tabs-model workspace session for this round, WF19-linked to hp-z440.primary, has-occupant → agent:claude-code.hp-z440. Has-purpose LINK to `purpose:sam.coherent-session-doctrine` deferred until D22.1 promotes (until then, purpose-steers-program via existing WF18).

Conversation B promotes 5 grammar_fragments (D19.2, D19.3, D19.4, D20.1, D20.2) via the first-ever WF20 ceremony, plus baseline `session` type fixes (urn_pattern, description, deprecate seat_role).

Conversation C proposes 4 new grammar_fragments: D22.1 (session-has-purpose), D22.2 (single-driver invariant), D22.3 (attach/detach/rotate verbs), D22.4 (kernel-birth-session atomic pair).

Conversation D archives 5 research notes, updates running-state, closes round 10.

Conversation E (round 11) lands the session-occupancy Go implementation as 4 stacked PRs on moos-kernel.
