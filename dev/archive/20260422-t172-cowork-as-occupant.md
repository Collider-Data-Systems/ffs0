# T=172 — Cowork as platform-host: Claude Desktop occupying a Workspace session

> April 22, 2026 (T=172). Doctrine draft for Z440's Claude Desktop instance
> as a first-class session host pinned to Google Workspace nodes.
> Author: claude-cowork.hp-z440 (`agent:claude-cowork.hp-z440`,
> `session:sam.z440-cowork-workspace` — both materialized in HG T=173).
> Status: **materialized (T=173, partial)** — Z440 substrate live (kernel 0 log_seq 256–284, status `active`, has-occupant LINKed pre-Desktop-launch); hp-laptop side waits on Guido. Three v3.13 fragments still pending (channel.kind expansion, D19.3 pins-urn, D22.5 running_host).

---

## 0. Why this note exists

Sam runs two Claude Desktop instances (hp-laptop + Z440). Each has its own skills, connectors, scheduled tasks, artifact library. Today they're free-floating — they touch Google Workspace (Gmail, Calendar, Drive, Tasks), produce artifacts, and don't show up in the HG at all.

That's a sovereignty violation by omission: Workspace-side state is operator-observable, but the kernel can't see it, can't gate on it, can't t-cone it. The fix is to **seat each Cowork instance as a session occupant**, with a host-facet that admits "platform" — the future Reading B / D22.5 `running_host` supertype.

This note settles:

1. The shape of the new session (5-facet tuple, occupant = Cowork agent).
2. The Workspace-channel pinning pattern (scope-facet contents).
3. The chunking discipline (Workspace artifact → HG fragments).
4. Per-host isolation (two Cowork instances, two sessions, no Desktop-state sync).
5. Pending v3.13 grammar fragments (channel.kind, running_host).

Companion to `../../../dev/reference/research-archive/20260421-t171-wolfram-kernel-proper-session.md` (Wolfram on Z440.primary; archived T=173 once seat was materialized in HG) and `20260422-t172-wolframs-court-social-topology.md` (5-kernel court). Wolfram is sam-as-implementer **inside** the kernel; Cowork is sam **outside** the kernel reaching back in.

---

## 1. The 5-facet tuple, instantiated

Per `20260419-t169-session-generalization.md` §1, a session is `(scope, purpose) × (host, owner, occupant)`.

For Z440 Cowork:

```
session:sam.z440-cowork-workspace
  scope ⊇ {
    channel:google.gmail.sam,
    channel:google.calendar.sam,
    channel:google.drive.sam,
    channel:google.tasks.sam,
    artifact:cowork.<id>...    # pinned per-session as Cowork creates them
  }
  purpose → purpose:sam.cowork-workspace-curation
  host    → kernel:hp-z440.primary  (today, WF19 opens-on)
          → running_host:cowork.hp-z440  (future, post-D22.5)
  owner_urn = urn:moos:user:sam
  occupant → agent:claude-cowork.hp-z440  (WF19 has-occupant)
```

For hp-laptop Cowork (analogous, distinct session):

```
session:sam.laptop-cowork-workspace
  scope ⊇ same channel.* URNs (shared Workspace, see §4 for the disjointness proof)
  purpose → purpose:sam.cowork-workspace-curation  (same purpose, OK)
  host    → kernel:hp-laptop.primary
  owner_urn = urn:moos:user:sam
  occupant → agent:claude-cowork.hp-laptop
```

Two sessions, two occupants, two hosts. **One owner.** The Workspace nodes are the shared substrate; the sessions are the per-machine views onto it.

### 1.1 Why not "host = the Cowork process directly"

Because Cowork isn't a kernel — no log, no operad validator, no §M11 liveness contract. It's a platform that emits work. Today, the host facet has to be a `kernel`, so the kernel-on-the-same-machine takes the host role and the Cowork agent goes in the occupant slot. That gives us heartbeat (kernel ticks `local_t`), persistence (kernel log), and gate evaluation (kernel sweep).

Future fix (D22.5): `running_host` supertype with subtypes `kernel` and `platform`. Cowork becomes a `platform:cowork.hp-z440`. The session moves its host LINK to the platform node directly, and the kernel becomes a separately-LINKed gate-evaluator (still required, just not the host). Until then, the kernel double-duty is fine — it's a simulation of the post-D22.5 shape.

---

## 2. Workspace channels — the scope-facet contents

Workspace surfaces map to `channel` S2 nodes, one per surface per user. Proposed kinds (v3.13 candidates, **not yet promoted**):

| Channel URN | kind | Notes |
|---|---|---|
| `channel:google.gmail.sam` | `email` | maps to Gmail MCP (`b6a45e2f-...`) |
| `channel:google.calendar.sam` | `calendar` | maps to Calendar MCP (`ddd9ba36-...`) |
| `channel:google.drive.sam` | `filesystem` (existing) or new `cloud-storage` | Drive MCP (`d9ef29a4-...`) |
| `channel:google.tasks.sam` | `task-list` (new) | no MCP yet — read-only via Calendar Tasks endpoint or skill |

Until v3.13 promotes the new kinds, ADD with the closest-existing kind (T=173 batch used `mail`/`messaging`/`drive`/`board` placeholders, log_seq 259–262) and leave a `TODO(cds): v3.13 channel-kind` comment on the envelope. **`channel.kind` is `Mutability=immutable`** per ontology spec — a post-promotion upgrade is NOT a single MUTATE. Two paths:

- (a) UNLINK the channel + re-ADD with the new kind. Loses URN continuity and any `pins-urn` LINKs (or `scope_pins` property entries) referencing the old URN — those have to be re-emitted too.
- (b) Narrow ontology migration window: temporarily flip `kind` to mutable, MUTATE, flip back. Needs a grammar_fragment + WF20 ceremony just for the migration.

Either way, plan the upgrade as a deliberate batch, not a casual rewrite. (a) is simpler if no scope-pins exist yet; (b) preserves URN continuity once the channels are widely referenced. Decision deferred until v3.13 channel-kind promotes — by then we'll know how many pins reference each channel.

### 2.1 Pinning into the session scope

Use D19.3 `pins-urn` LINK (still proposed — drop in WF? per the eventual D19.3 promotion). For now, add `scope_pins: [urn, urn, ...]` as a property on the session and migrate to LINKs once D19.3 lands. **Don't reify scope as a property forever** — that's the trap §M5 strata exists to prevent.

### 2.2 Per-session vs per-Cowork pinning

Channel nodes are **session-scoped pins**, not agent-attached. The Cowork agent is the occupant; what it can attend to is determined by the session's pinned scope. Same agent in a different session sees different channels. That's the right shape — Cowork can drive multiple sessions over time (curation today, calendar-triage tomorrow) and the kernel sees the scope swap.

---

## 3. Chunking discipline — Workspace artifact → HG fragments

Sam wants Cowork artifacts broken into HG pieces for further session processing. Three chunking units, **skill picks based on item type**:

| Chunk unit | When | Example |
|---|---|---|
| **Per Workspace item** | atomic source object (one email, one calendar event, one Drive file) | a Gmail thread → one `knowledge_item` with the thread URN as source |
| **Per semantic section** | structured doc with H1/H2 boundaries | a Drive doc → one `knowledge_item` per H2; `provides-kb`/`kb-source` LINKs (WF12) reflect the doc structure |
| **Per Cowork artifact section** | Cowork-emitted HTML/markdown artifact with internal sections | a meeting-prep brief → one `knowledge_item` per top-level section, all hydrated from an umbrella `knowledge_item` via WF12 `provides-kb` |

Skill choice rule (per the chunker skill, see §6):

```
if source.type in {gmail-thread, calendar-event, task}:
    chunk = per-item
elif source.type == drive-doc and source.has_h2_structure:
    chunk = per-section
elif source.type == cowork-artifact:
    chunk = per-artifact-section
else:
    chunk = per-item  # safe default
```

### 3.1 The umbrella pattern

For multi-chunk sources, ADD an **umbrella `knowledge_item`** first, then ADD each chunk as its own `knowledge_item`, then LINK each chunk to the umbrella via WF12 `provides-kb`/`kb-source` (src_port=`provides-kb`, tgt_port=`kb-source`). The umbrella is the WF12 source; each chunk is a WF12 target. The umbrella carries the source URN; the chunks carry their offset/section identifier as a property.

This preserves both grain (per-chunk t-cones, per-chunk tagging) and provenance (one URN traces back to the source artifact).

**WF correction note (T=173 ~22:30 CEST):** Earlier drafts of this doctrine and the chunker skill prescribed WF18 `composes`/`composed-by`. That was wrong — WF18 is program composition (`src_types: [program, purpose]`), not KB hydration. The right category is **WF12 `provides-kb`/`kb-source`** (KB provision and hydration), whose `src_types` include `channel` and `knowledge_item` and whose `tgt_types` include `knowledge_item`. This file and both Cowork skills corrected inline; pattern clarified before the first chunker proof landed.

### 3.2 What does NOT get chunked

- Raw Workspace metadata (sender, recipients, timestamps) — those go on the channel node or as `knowledge_item` properties, not as separate nodes. Don't reify metadata; it duplicates topology.
- Cowork's internal scratchpad notes — they stay in Cowork. Only artifacts the user explicitly persists or that the chunker skill is invoked on land in the HG.
- Attachments that aren't opened — link to them via the Drive channel node, don't duplicate bytes.

---

## 4. Per-host isolation — HG-only sync, §M9 preserved

**Cardinal rule**: the two Cowork instances do NOT sync directly. No shared cookie jar, no shared scheduled-task list, no shared artifact library. Each Cowork is a sovereign platform-host on its own machine.

### 4.1 What's actually shared

Only the HG. Both kernels (hp-laptop and hp-z440.primary) hold their own log; cross-machine coherence happens via `moos-router` (WF16) when explicitly invoked. The two Cowork sessions LINK to the same Workspace channels, but those LINKs live in **different kernel logs** until federation reconciles them.

### 4.2 The disjointness invariant

For any Workspace item processed:

```
chunk processed by laptop-Cowork → envelopes land on kernel:hp-laptop.primary
chunk processed by z440-Cowork   → envelopes land on kernel:hp-z440.primary
```

Same source URN may appear in both logs as a chunk source. That's **not duplication** — it's two independent observations of the same external substrate. The router can dedupe at federation time (or not; the operator may prefer parallel curations).

### 4.3 What this prevents

- The bug where laptop-Cowork's scheduled task races z440-Cowork's scheduled task and both write the same chunk to one log.
- The bug where a Cowork artifact "exists" only on one machine but the other machine's session pretends it does (no — pin-by-URN means the URN must resolve via the local kernel).
- The bug where rotating sam's Workspace OAuth scope on one machine silently breaks the other (each Cowork holds its own credential).

§M9 sovereignty: log-is-truth, per kernel. This pattern keeps Cowork from quietly violating it via a shared cloud surface.

---

## 5. Heartbeat and liveness

Cowork doesn't tick `local_t` — only kernels do. The session's heartbeat comes from the kernel host. §M11 liveness for `session:sam.z440-cowork-workspace` is satisfied by:

- Kernel sweep ticking `local_t` on the session per acknowledged rewrite (existing mechanism).
- Cowork emitting at least one rewrite per session-active interval (chunker run, artifact creation, scheduled-task fire).

If Cowork goes idle for the configured liveness window, the session goes idle (occupant LINK survives, just no recent transitions). It does NOT auto-evict — eviction is sam's call via MUTATE has-occupant target_urn (per D22.2 single-valued occupant invariant).

### 5.1 Scheduled tasks as heartbeat sources

Cowork's scheduled-tasks feature (`mcp__scheduled-tasks__*`) fires periodic chunker runs. Each fire = ≥1 envelope = heartbeat. Recommended: a daily 08:00 chunker sweep (matches sam's "Mon 08:00-09:00 calendar ritual" already in CLAUDE.md). That makes the session deterministically alive with no operator effort.

---

## 6. Skills supporting the pattern

1. **`moos-workspace-ingest`** (chunker, **authored T=173**) — `dev/claude-skills/moos-workspace-ingest/SKILL.md`. Canonical invocation surface for §3. Takes a Workspace URN or Cowork artifact, picks the chunk unit, emits umbrella + chunks + composes LINKs + scope-pin MUTATE as a single atomic `apply_program` batch. Idempotent (re-ingest emits a `claim`, not a duplicate). Read this skill before any Cowork ingest.
2. **`moos-cowork-bridge`** (setup, **deferred**) — would ADD the platform-host nodes, pin Workspace channels, set up has-occupant. **Skipped**: T=173 batch did this directly via Wolfram-driven envelope batches (log_seq 256–284). A reusable bridge skill earns its keep only when a third Cowork instance arrives; until then, the pattern lives in this doc + the running-state log.
3. **`moos-cowork-readback`** (status, **queued**) — open-of-round check for the Cowork session: occupant, last heartbeat, pending chunks, recent artifacts. Companion to `moos-state-readback` but scoped to the Cowork session's t-cone. Author when the daily 08:00 chunker sweep (§5.1) goes live.

All emit envelopes per `moos-rewrite-envelope` rules (one field per MUTATE, top-level type_id, immutable properties supplied, actor `urn:moos:agent:claude-cowork.<host>` via inferred-session lookup).

---

## 7. Open design questions

1. **Platform-host promotion timing**: do we wait for D22.5 / Reading B before seating Cowork, or seat-as-occupant-on-kernel-host today and migrate later? Lean: seat today. The migration is one MUTATE per session post-D22.5; not blocking.

2. **Channel.kind grammar**: do `email` / `calendar` / `task-list` go in v3.13 or get folded into a single `external-saas` kind? Lean: separate kinds — they have different operational semantics (email is asynchronous, calendar is timestamped, tasks have status). Cost is 3 grammar fragments instead of 1.

3. **Cross-Cowork dedupe**: when both Cowork instances chunk the same Workspace item independently, does the router dedupe? Lean: no automatic dedupe. Two observations are valid HG state. Sam decides via UNLINK if one is wrong. Premature dedupe collapses information.

4. **Cowork artifact persistence boundary**: which Cowork artifacts get auto-pinned into the session scope vs left ephemeral? Lean: opt-in only — chunker skill is invoked explicitly, no implicit pinning. Cowork's artifact library is sam's scratchpad; the HG is sam's commitment.

5. **Slack/Asana/etc.**: same pattern extends to other connector channels. Out of scope for this note; covered by the same `moos-cowork-bridge` skill once the Workspace path is live.

6. **Session name for the laptop side**: today the laptop also has `session:sam.governance` (Guido seat). Is `session:sam.laptop-cowork-workspace` a sibling or a child of governance? Lean: sibling. Cowork is workspace curation; governance is doctrine audit. Different purposes, no operadic containment.

---

## 8. Implementation queue

### Landed T=173 (Z440 side, Wolfram-driven)

1. ✅ ADD `agent:claude-cowork.hp-z440` and `agent:claude-cowork.hp-laptop` (S4, `delegate_type=ide`) — log_seq 256, 257
2. ✅ ADD `purpose:sam.cowork-workspace-curation` — log_seq 258
3. ✅ ADD 4 Workspace channels with placeholder kinds (`mail`/`messaging`/`drive`/`board`) — log_seq 259–262
4. ✅ ADD `session:sam.z440-cowork-workspace` (status `pending_driver` → `active` in 16:30 batch) — log_seq 263
5. ✅ LINK `opens-on kernel:hp-z440.primary` (log_seq 264) + `has-occupant agent:claude-cowork.hp-z440` (log_seq 273-ish in the 16:30 batch, pre-seated for Desktop arrival)
6. ✅ Property-pin via `scope_pins` (4 channel URNs) on the session

### Deferred (future rounds)

- **hp-laptop side**: ADD `session:sam.laptop-cowork-workspace` + opens-on hp-laptop kernel + has-occupant `agent:claude-cowork.hp-laptop`. Lands on hp-laptop's own log when Guido executes there. Waiting on hp-laptop kernel rebuild to post-PR-31 binary first.
- **D22.5** grammar fragment for `running_host` supertype + `platform` subtype. Not in T=173 WF20 batch.
- **v3.13 channel.kind expansion** (`email`, `calendar`, `task-list`, `cloud-storage`). Not in T=173 WF20 batch (which promoted `delegates-to`, `group-type`, `channel-kind-vcs`, `owns-port-pair`).
- **D19.3** promotion of `pins-urn` port pair. Once live, scope_pins property migrates to LINKs.
- **Ontology v3.13 bump + 5-kernel restart** to load the promoted fragments at runtime (today: HG `promoted`, runtime still 3.12.0).
- **Router rule** for Cowork-side dedupe heuristic (post-WF16-stabilization).
- **`moos-cowork-readback` skill** — author when daily 08:00 chunker sweep goes live.
- **F-direction Workspace projection skill** — pair to `moos-workspace-ingest`; emits HG → Calendar/Tasks via the F leg of the adjunction.
- **Claude Desktop launch on Z440** — sam-driven; first non-trivial chunker invocation will be Cowork's first kernel rewrite.

---

## 9. Cross-references

### Inside ffs0

- `dev/claude-skills/moos-workspace-ingest/SKILL.md` — **canonical invocation surface for §3** (chunker; G-direction)
- `dev/claude-skills/moos-rewrite-envelope/SKILL.md` — envelope shapes the chunker uses (read first when authoring any rewrite)
- `dev/claude-skills/moos-github-project-bridge/SKILL.md` — F-direction sibling for the GitHub board; same adjunction shape, different surface
- `kb/research/session/20260419-t169-session-generalization.md` — 5-facet tuple, Reading B / D22.5 hint about `running_host`/`platform`
- `dev/reference/research-archive/20260418-t168-session-kernel-bound.md` — kernel-bound discipline (still binds; Cowork inherits it via the kernel host)
- `dev/reference/research-archive/20260421-t171-wolfram-kernel-proper-session.md` — Wolfram seat on Z440.primary (Cowork is a sibling-occupant with a different scope; archived T=173)
- `kb/research/session/20260422-t172-wolframs-court-social-topology.md` — 5-kernel court (Cowork sessions are NOT new kernels, they're occupants on existing kernels)
- `kb/research/kernel/20260417-t187-kernel-proper.md` §M9 (sovereignty), §M11 (liveness), §M15 (t-cone), §M16 (ontology publication)
- `kb/superset/running-state.md` — fleet ground truth; T=173 ~16:30 batch entry covers the materialization. Bump Key URNs section at round-close with first ingested umbrella URNs.

### Inside zoom-plugin (companion plugin pattern)

- `skills/moos-zoom-comms/SKILL.md` — same shape, different platform: Zoom is the comms-bus occupant pattern; Cowork is the curation occupant pattern
- `CONTEXT.md` — 5-kernel persona topology (the Cowork sessions sit alongside the persona seats, not on top of them)

### External

- Reading B / D22.5 — pending grammar fragment for `running_host` supertype
- D19.3 — pending grammar fragment for `pins-urn` port pair
- D22.2 — single-valued occupant invariant (Cowork sessions inherit this)
- `ffs0#33` — round-11 handoff thread (surface this note here for review)
