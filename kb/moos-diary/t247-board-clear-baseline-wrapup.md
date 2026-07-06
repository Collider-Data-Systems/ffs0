# T247 — the board-clear round: "solve this on all levels"

> Round wrap-up, written T=247 (2026-07-06), the second entry this shelf gets today — the
> hygiene wrap-up (`t247-hygiene-round-wrapup`) closed the practice era this morning; this one
> records the round that followed it to zero. Predecessors: `t247-hygiene-round-wrapup`,
> `t244-manifold-arc-baseline-wrapup`. Evidence and narrative, not truth: the log is truth.

## What this round was for

Sam's directive was three words longer than usual and infinitely broader: *"solve this on all
levels."* Not triage, not another partial diet — every open PR merged or dispositioned, every
open issue closed, across all three repos. The round ended with the board at **zero** on ffs0,
moos-kernel, and moos-router simultaneously. That zero is the new baseline: whatever the next
arc opens, it opens against a clean board.

## What happened, in order

**The router learned to reload itself (moos-router#6, merged).** The federation router gained
`--topology-file`: it watches the topology config and swaps its routing table atomically on
change, with a localhost-guarded `POST /admin/topology/reload` for explicit triggers. Paired
with it, moos-router#5 closed against ffs0#103's `Test-RouterDrift` — the Doctor-mode check in
`Test-MoosFederation` that compares the running router's table against the topology file — and
the pair was live-smoked, not just merged. One deliberate tail: running routers adopt
`--topology-file` at their next restart, so the flag is landed but not yet universal.

**The persona audit fully dispositioned (#99).** Six findings, six verdicts, none forced.
Findings 1–3 fixed in PR #102. Finding 4 delegated to its owning lane. Finding 5 closed by Sam
directly — the live persona map ratified as-is, with idle-seat naming deferred to
**name-on-wake** (a seat earns its name when it wakes, not before). Finding 6 — the audit's
real catch — corrected in the seat split below. Alongside it, #100 and #101 (presence-shaped
issues, not work) were closed on principle: the board carries work items only.

**The seat split applied (#98, hp-laptop log 1564→1572).** The finding-6 correction, made
real in the fold: the governance seat's actual driver has always been the Claude Desktop /
Cowork app, so **John Lydon** = `agent:claude-cowork.hp-laptop` on `session:sam.governance`
(multi-workspace agent — explicit `session_urn` on every envelope), while **Guido** re-homed
to the laptop VS Code lead: `agent:vscode.hp-laptop.copilot` on the new
`session:sam.laptop-vscode-lead` (`purpose:sam.laptop-vscode-lead-operations`, opens-on and
pins wired). `agent:claude-code.hp-laptop` is now retired legacy — it exists in the fold, holds
no occupancy, and is never authored again. The apply taught a §M11 lesson worth keeping:
type-ADDs inside an occupancy-rotation batch must use the **kernel actor**, because §M11
validates the agent actor against *pre-batch* occupancy — the agent you're rotating in doesn't
occupy anything yet, as far as the gate can see. Afterward `config_projection.py --mode write`
regenerated the seat table 11→12 rows and `--mode check` passed clean. Persona court: seven —
Wolfram, Steinberger, Karpathy, Moos, Zappa, John Lydon, Guido.

**Instruction-md de-rot, all levels (#104).** With the split applied, every instruction file
that mentioned the old seating was wrong. The root fleet pair (`AGENTS.md` + `CLAUDE.md`), the
ffs0 pair, and the thin mirrors were all brought to post-split facts — facts only, no new
doctrine smuggled in, naming questions explicitly deferred. The SOT hierarchy did its job: the
generated seat table was already correct the moment the fold changed; only the authored prose
needed hands.

**The spine: design-think, corrected by a probe, then reified (#105).** The round's design
question — how do workstations, engines, users and agents relate? — produced a proposal, and
then a live probe produced a correction: `workstation —hosts→ engine`, `user —owns→
workstation`, `user —governs→ agent` were **already live in the fold**, sovereign per §M9.
The instruments were behind the graph, not the other way around. So the reification apply
shrank to what was genuinely missing: the `workstation.kind` backfill (hp-z440 = `desktop`,
hp-laptop = `laptop`) and one new node — **`workstation:sam-android`** {kind: `mobile`, os:
`android`, arch: `arm64`}, owned-by `user:sam`, hosting **no engine**. That node is the
`.device_samsandroid.noagent.user_sam` matrix coordinate reified: a pure so:om surface, from
which Keep notes reach a fold via channel `google.keep.sam` + G-ingest, their T=239 provenance
trailer now carrying `channel-kind: keep-widget · workstation: sam-android`. Two envelope
lessons banked into `moos-rewrite-envelope`: an **additive MUTATE** (a property not yet
present on the node) takes *no* `rewrite_category`, and a **workstation ADD** requires the
immutable `hostname`/`os`/`arch` trio alongside the mutable `kind`.

## The scoreboard at T=247 (post-split)

| Dimension | Addressed this round | After |
|---|---|---|
| Issues + PRs (ffs0 · moos-kernel · moos-router) | #98/#99/#100/#101/#103/#104/#105/#106 · — · #5/#6 | **0 · 0 · 0** |
| Seat table rows (generated) | 11 | **12** — drift gate PASS |
| hp-laptop log | 1564 | **1572** (split batch) |
| Governance principal | `claude-code.hp-laptop` (wrong driver) | **`claude-cowork.hp-laptop`** — legacy agent retired, occupancy-less |
| Persona court | 6 named | **7** — John Lydon seated, Guido re-homed |
| Router topology | static at start | **hot-reload merged + drift-checked** |
| workstation.kind | absent | backfilled (Z440 · laptop) + **sam-android** added |

**Deferred, chosen, not forgotten:** `hpprodesk.kind` (box off — backfill on next power-on) ·
D4 `presents-as` + D8 `realizes` (4.0.x; the D4 debt ledger stays seat-display.json + topology
personas + agent cards) · finding-6 agent-URN de-surfacing (4.0.x) · the B2 governance apply
(#89) if still pending on the (now Lydon-keyed) governance lane · hp-laptop's router restart
to adopt `--topology-file`.

## What the round proved

The hygiene round proved an inventory needs a reviewed batch and a fold readback. This round
proved the converse discipline: **a design is nothing until a probe has checked whether the
graph already did it.** The spine proposal survived contact with the fold only by shrinking —
three relations it wanted to invent were already sovereign topology, and the honest remainder
was two properties and one node. Same lesson at every level: the seat table regenerated itself
after the split, the mirrors were corrected *to* the fold rather than argued with, and the one
principal that turned out to be fiction (`claude-code.hp-laptop`) was retired in the log, not
erased from it. Board at zero, twelve seats folded live, and every claim above one `/state`
query from verification. That is what "solved on all levels" means here.

---
authored-by: agent:claude-cowork.hp-z440 / session:sam.z440-cowork-workspace / t247-board-clear
