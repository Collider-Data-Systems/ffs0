# planning

The state of the substrate. What it can do. What's open.

## Substrate

5 kernels, both machines on ontology v3.15.0, t_day=178.

| kernel | port | log_len | role |
|---|---|---|---|
| `hp-z440.primary` | :8000 | 413 | seat-bearing for 6 sessions |
| `hp-z440.menno` | :8001 | 13 | twin metadata only (Steinberger seat opens-on) |
| `hp-z440.lola` | :8002 | 11 | twin metadata only (Karpathy seat opens-on) |
| `hp-z440.moos` | :8003 | 16 | overflow lane |
| `hp-laptop.primary` | :8000 | 775 | seat-bearing for 3 sessions |

9 sessions, all occupied:

| session | occupant | scope | runs |
|---|---|---|---|
| `sam.kernel-proper` | `claude-code.hp-z440` (Wolfram) | kernel doctrine | nothing scheduled |
| `sam.mvp-delivery` | `claude-code.hp-z440` (Wolfram, multi) | MVP T=190 gate sequence | nothing scheduled |
| `sam.z440-cowork-workspace` | `claude-cowork.hp-z440` | 4 Workspace channels | nothing scheduled |
| `sam.moos-diary` | `antigravity.hp-z440` (Moos) | `channel:local.moos-footage` | nothing scheduled |
| `sam.karpathy-seat` | `vscode.hp-z440.lola` | categorical/HDC research | nothing scheduled |
| `sam.steinberger-seat` | `vscode.hp-z440.menno` | DX + tooling | nothing scheduled |
| `sam.governance` | `claude-code.hp-laptop` (Guido) | doctrine + audit | nothing scheduled |
| `sam.laptop-cowork-workspace` | `claude-cowork.hp-laptop` | 4 Workspace channels + youtube | **2 cron-driven** routines daily |
| `sam.laptop-moos-diary` | `antigravity.hp-laptop` | `channel:local.moos-footage` (mirror) | nothing scheduled |

11 skills mounted runtime-side. ~15 channels (Workspace × 4 × 2 + youtube + 2 local + a few legacy). Hundreds of knowledge_items pinned via WF12. 7 doctrinal claims with 7 WF21 caused-by edges. 6 reified-doctrine derivations on log.

No clock instances. No scheduled programs firing. The only thing actually running on a schedule is Cowork-laptop's two cron-driven routines, which predate the substrate (scheduled-task config + skill behavior, not reified as `clock` + `program` nodes).

## What the operad gives you

The types that matter for running things:

- **session** — scope, purpose, occupant, host kernel, local_t. Where work happens.
- **program** — name, target_t, status. What runs. Programs compose via WF18 `scheduled-after`.
- **t_hook** — predicate-and-reaction. firing_state ∈ {pending, proposed, approved, rejected, applied, closed}. The atomic firing primitive.
- **prg_task** *(deprecated since v3.9; do not use; programs compose programs directly via WF18)*
- **clock** *(NEW v3.15, zero instances)* — cardinality, embedding, frame, density. Six canonical kinds: kernel.sweep, session.local_t, t-day, cyclic-ritual, event-driven, multi-session-disjoint.
- **knowledge_item** — chunk pinned to channel.
- **channel** — boundary to external. kind ∈ {filesystem, messaging, board, drive, mail, calendar, task-list, cloud-storage, vcs, project-board, video, audio}.
- **claim** — assertion with source_ki_urn.
- **derivation** — inference object; ports produces / consumes / authored-by.
- **grammar_fragment** — proposed / promoted / merged ontology change.

The WFs that wire things:

- **WF12** `provides-kb / kb-source` — channel ingests KIs.
- **WF18** `scheduled-after / scheduled-before` — temporal succession.
- **WF19** `opens-on / has-occupant / pins-urn / mounts-tool` — session topology + scope + tools.
- **WF21** `causes / caused-by` *(NEW v3.15)* — causal DAG, acyclic enforced.

Promoted but not yet wired to firing semantics: **clock** (no instances), **leaf-firing-state** (named in T=175 fabric note as v314-5; never promoted).

## How a running thing wires

Concrete shape with current types:

```
clock:sam.<x>      with cardinality, embedding, density
                   --keeps-time-with--> session:sam.<seat>

session:sam.<seat> has scope_pins (channel URNs)
                   has purpose:sam.<p>
                   has-occupant agent:<a>

program:sam.<y>    with target_t, status
                   --runs-in--> session:sam.<seat>     (port-pair pending)
                   --scheduled-after--> program:sam.<prev>   (WF18; succession)

t_hook:sam.<z>     with predicate, firing_state, target_t
                   --fires_at--> clock:sam.<x>          (predicate satisfaction)
                   --reaction--> emits HG envelopes (G-direction)
                                 and/or projects to external (F-direction)
```

The pieces are all there. Nothing connects them yet for a real running program.

## What's missing for ignition

- **Zero clock instances.** Need at least one: e.g., `clock:sam.weekly-mon-08` (cyclic, anchor=Mon 08:00 Europe/Amsterdam).
- **No `program-runs-in-session` port-pair.** Programs exist as nodes but the topology link from program to session isn't typed. WF20 ceremony candidate.
- **No `t_hook-fires-at-clock` port-pair.** `t_hook` has `fires_at` as a property pointing at a t-day target (existing) but not a clock URN (new). Either extend `fires_at` semantics or add a port-pair connecting `t_hook` to `clock`.
- **No leaf-firing-state semantics.** v314-5 was named (firing_state enum across tool_call/external_op/compute) but never promoted. Without it, "task fires" remains conceptual.
- **F-direction projection skills exist for ingest only** (moos-workspace-ingest is G-direction). The reverse — `program → calendar event`, `task → github issue`, `claim → website paragraph` — has no skill. Cowork-laptop's daily-digest is the closest thing (it projects email-summary state into HG, then a future skill would project HG-summary state back to a calendar/Drive surface).

## What's open (decisions)

1. **First running thing** — pick one to wire end-to-end:
   a. Mon 08:00-09:00 calendar ritual (your standing weekly thing; clock + program + task → red calendar event)
   b. MVP T=190 gate sequence (round-rollover clock + 6 G1-G6 tasks → project board issues)
   c. Cowork daily routines refactored as proper clock+program (smallest scope; reifies what already runs)
2. **Project mo:os #4 board** — 53 items, ~10 dead `Phase B/D/E` labels, ~9 persona/session anchors, rest = clutter. Cull?
3. **Round numbering** — keep `round-N` HITL macro-clock, or drop it (event-driven only)?
4. **Spec md** — already trashed in this PR (along with research/session/* + research/kernel/* + research/moos-diary/*). Confirm policy: no new chapter authoring.
5. **PR-comment Copilot bugs** — wrong relative paths to skills, off-by-one claim counts, hardcoded `192.168.1.13` LAN IP in `moos-cross-persona-audit` skill. All except the IP are in trashed md. Fix the IP?
6. **Round-15 derivation `consumes`/`produces` anchor lifts (~70-100 LINKs)** — busywork; the property-form citations already work. Drop?

## Round-16 candidates (if we pick one, it shapes the round)

- **(a) Ignition** — fire the Mon-morning ritual end-to-end (clock + program + task + F-projection skill). One persona. One purpose. One running thing.
- **(b) Operad-completion** — promote `v314-5-leaf-firing-state` + `companion-derivation-port-pair` (program-runs-in-session, task-fires-at-clock). Substrate gets fully wired but nothing runs yet.
- **(c) Cleanup** — board cull, skill IP fix, round-numbering decision, no new code or envelopes.

## Conventions (what I cut going forward)

- New spec chapter md — none.
- "Track 1 / Phase 2 / Batch / Option" labels — none. Just describe what's happening.
- Long PR or issue summary tables — keep them ≤10 lines.
- Plan-file novella — mine becomes scratchpad.
- Derivation/claim ADDs that don't drive operational work — no.
- Ceremonial round-close comments — minimal; the tag and the closed issue carry the receipt.

— Wolfram, T=178. The substrate is ready. Pick one running thing.
