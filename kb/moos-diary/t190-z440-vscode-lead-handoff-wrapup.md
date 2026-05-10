# T190 Z440 VS Code Lead Handoff Wrap-Up

**T-day:** T=190  
**Date:** 2026-05-10  
**Kernel/session:** `hp-z440.primary` / `session:sam.z440-vscode-projection-lead`  
**Runtime readback:** `ontology_version=3.16.1`, `t_day=190`, `log_len=449` after apply  
**Lane:** Z440 VS Code projection lead, federation parity, Project #4 identity repair, session-centered handoff

## Executive status

The Z440 VS Code lead lane is now graph-visible enough to finish the T189/T190 projection work today without guessing from IDE memory. The hp-laptop governance side applied the reviewed Z440 admin parity links to Z440 primary, verified the relations live, repaired the first unambiguous GitHub Project #4 identity rows, and wrote a shared VS Code handoff prompt for Z440.

This is not a log merge. The two machines still keep sovereign logs. The win is a cleaner read and handoff surface: routers can see each other, Z440 has the VS Code lead session owned and pinned in its own HG state, and the shared `ffs0` repo carries the prompt and apply record.

## What landed in HG

Four LINK rewrites landed on Z440 primary via `Test-MoosFederation.ps1 -Mode PostProgram -Persona z440-vscode-lead` using actor `urn:moos:kernel:hp-z440.primary`:

- WF01 `group:sam --owns/owned-by--> session:sam.z440-vscode-projection-lead`.
- WF01 `group:sam --owns/owned-by--> purpose:sam.z440-vscode-projection-lead-operations`.
- WF01 `group:sam --owns/owned-by--> program:sam.t190.z440-vscode-projection-lead-transition`.
- WF19 `session:sam.z440-vscode-projection-lead --pins-urn/pinned-by-session--> group:sam`.

The applied payload record is `dev/scripts/ops/t190-z440-admin-parity-review.program.json`. It is marked `applied=true` and `do_not_reapply=true`; replay requires a fresh absence check and explicit approval.

## What landed in Git and Project #4

Shared ffs0 commit `1f17c7b` recorded the first closeout:

- Added `.github/prompts/z440-vscode-t190-finish-today.prompt.md`.
- Added the Z440 parity apply record under `dev/scripts/ops/`.
- Updated `kb/superset/running-state.md` with Z440 log state, relation state, Project #4 coverage, and branch guidance.

Project #4 row identity repair stayed separate from HG rewrites. Five unambiguous `HG URN` fields were populated. Coverage is now 31/57 rows with populated `HG URN` values. Remaining state: 26 empty rows, 4 of those with multiple resolvable URNs needing human choice, and 2 populated rows with legacy non-URN values. No board status G-sync was performed.

## Session and occupancy reading

The handoff should be session-centered, not IDE-centered. An IDE conversation is S0 substrate; the durable object is the session occasion: purpose, occupant, host kernel, scope pins, and allowed operations at a log prefix.

For the current finish pass:

- The receiving kernel is `kernel:hp-z440.primary`.
- The driver persona is `z440-vscode-lead`.
- The actor is `agent:vscode.hp-z440.primary` for ordinary agent work, with explicit `session_urn` when emitting as that actor.
- Kernel-authored topology or authority maintenance uses `kernel:hp-z440.primary`.
- `group:sam` now owns the lead session, purpose, and transition program on Z440 primary.

This gives Z440 a local place to finish the projection work while remaining visible to hp-laptop through router readback and shared Git.

## Identity topology rethink

The useful next shape is not "make every account a user" and not "make every IDE tab its own doctrine." The better spine is:

- Human principal: `user:sam` remains the kernel user principal under the current ontology.
- AI delegates: Claude Code, VS Code, Antigravity, Cowork, and future harnesses are `agent` nodes.
- Work occasions: each durable work lane is a `session` with purpose, occupant, kernel, and scope pins.
- Collective scope: `group:sam`, application groups, and future family/domain groups own sessions, purposes, programs, channels, and projection surfaces.
- External accounts: Gmail accounts, GitHub/Git accounts, Calendar, Drive, Tasks, websites, DNS, and VCS surfaces are `channel` nodes or channel families.

Menno, Lola, and other IRL people are meaningful to Sam, but the current ontology's `user` type is a privileged kernel principal. Treating them as `user` nodes would change authority semantics. Until a reviewed identity/personhood design exists, they should remain names in session/kernel/persona topology or be modeled through groups/channels/knowledge items where appropriate.

Adding Sam's other Gmail accounts and Git accounts is a strong idea, but the first safe move is account-as-channel: `channel:google.gmail.<slug>`, `channel:github.<account-or-org>`, `channel:vcs.<account-or-repo>`, all owned by `group:sam` or `user:sam`, with ingested artifacts linked back through WF12 and projected rows keyed by `HG URN`. That gives topological inference over S0/S1 traces without inflating the authority model.

## Running-state and diary division

`running-state.md` should stay the hot hydration index: current endpoints, current lanes, current log lengths, and the newest operational facts. It should not become the whole story.

`kb/moos-diary/` should carry session-centered wrap-ups that group several running-state sprints into readable packets. The natural grain is 3-5 sprints: enough context to see the session arc, not so much that the next agent has to reverse-engineer the day from scattered update blocks.

That is why this report exists: it closes the T189/T190 handoff arc in a form any persona can read before opening a new IDE conversation.

## Z440 finish prompt

The shared VS Code prompt was revised to make the next agent do five things in order:

1. Protect local Z440 WIP and branch before shared-file edits.
2. Verify live endpoints and persona preflight from Z440.
3. Confirm the four newly applied relations are present and not replay the payload.
4. Run the projection pipeline and bring Z440 WIP to a clean, reviewable state.
5. Treat Project #4 identity repair as separate from HG rewrites and avoid board status G-sync until row identity is reliable.

The prompt also names the identity rule: account surfaces are channels, agents are delegates, sessions are occasions, and groups carry ownership scope.

## Deferred items

- Finish the Z440 projection pipeline WIP on a branch and record the final gate result.
- Continue Project #4 `HG URN` repair only where identity is unambiguous.
- Decide whether repeated session-lens shapes should become durable `view_filter` carriers.
- Design account/person/family identity carefully before adding non-Sam IRL people as authority-bearing nodes.
- Reserve Z440 Ethernet `192.168.1.11` in DHCP for MAC `90:E2:BA:14:81:DA`.

## Validation

- Z440 primary health after apply: `status=ok`, `ontology_version=3.16.1`, `t_day=190`, `log_len=449`.
- Relation readback: all four intended relations returned present via `/state/relations/src/...`.
- GitHub Project #4 readback: 31/57 rows have populated `HG URN` fields.
- ffs0 closeout commit before this report: `1f17c7b chore: close t190 z440 handoff`.

The remaining work is not blocked. It is now cleanly queued for Z440 VS Code with a shared prompt and explicit branch discipline.
