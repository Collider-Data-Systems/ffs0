---
name: moos-seat-hydration
description: Hydrate a fresh mo:os conversation: resolve the seat from host/cwd, read running-state + live /healthz, verify repos, emit a who/where/engine orientation. Includes Cowork readback and workstation-operator procedures (absorbed T=262). Use at the first turn in any mo:os workspace.
---

## When to use (routing detail)

Hydrate a fresh mo:os conversation for whatever seat it lands on — the operational replacement for Sam's re-pasted orientation prompt (the old `tmp/*handoff*.md` blocks). Use at the very first turn of any new conversation in an mo:os workspace (`ffs0`, `moos-kernel`, `moos-router`, `moos-viz`), or whenever you need to (re)establish who/where you are before doing work. Resolves the current seat from an explicit arg or from cwd/host, reads the live running-state header + the seat's AGENTS.md row, runs `moos-state-readback`, optionally runs `moos-session-context-projection`, and emits a tight who/where/engine/4.0-version orientation with the active lane and any open handoff items. Trigger phrases: "hydrate this seat", "orient me", "where am I / who am I", "fresh conversation — get oriented", "open this seat", "what seat is this", "catch me up before I start". Composes `moos-state-readback` + `moos-session-context-projection`, and carries the Cowork one-session readback + workstation-operator procedures in-file (absorbed T=262, sections below) rather than duplicating them. Use `engine` (4.0 alias) for the runtime that folds the log; URN/type-id stay `kernel` until the gated 4.0.x rewrite.

# moos-seat-hydration

The operational successor to Sam's hand-pasted orientation prompt. Where the old flow was: paste a `tmp/*handoff*.md` block at the top of every fresh conversation and let the model absorb it (an **S0 paste** — raw substrate, re-typed each time, drifting the moment any fact changed), this skill makes orientation an **S1 operation** — a procedure that reads live truth (`/healthz`, `running-state.md`, `AGENTS.md`) at invocation time and synthesizes the same orientation from current state. Same output, no stale paste.

> **It supersedes the hand-pasted handoff.** When Sam would have pasted "you are Cowork-Z440, kernel 0 on :8000, T=231, the lane is the 4.0 manifold-bump…", invoke this instead. The facts come from readback, not from a block that was true three rounds ago.

This skill is **READ-ONLY**. It emits no envelopes, pulls no repos, restarts nothing. It orients. Any correction it surfaces (pull a behind repo, re-seat an evicted occupant, restart a version-skewed kernel) is a separate, owner-gated act.

## 4.0 nomenclature note

This round's decision: the canonical 4.0 term for the runtime that folds the log is **`engine`** (re-ratified from the earlier `instance` alias; from the **mo:os ⊣ so:om** engine/surface framing — the engine is the operational side, the surface is the observed side). Use `engine` everywhere as the 4.0 alias. `instance` is the **now-deprecated** prior alias — recognize it in older docs, don't author it. The runtime **type-id and URN stay `kernel`** (`urn:moos:kernel:<host>.<name>`) until the gated 4.0.x URN rewrite lands. So: say "engine", write `urn:moos:kernel:…`.

## Procedure

Run the five steps in order. Steps 2–3 are the cheap core (no kernel restart, no repo mutation); steps 3–4 compose existing skills; step 5 is the synthesis.

### Step 1 — resolve the current seat

Resolve which **seat** (persona × workspace × agent × engine × surface) this conversation occupies. Precedence:

1. **Explicit arg.** If the invocation carries a seat key or an agent/session URN (e.g. `moos-seat-hydration cowork-z440`, or a passed `session_urn`), use it. This wins over inference.
2. **cwd + host inference.** Otherwise derive from the working directory and hostname:

   | Signal | Likely seat(s) |
   |---|---|
   | host `desktop-42d00rd` (Z440) + Cowork/Claude-Code pane | **Zappa** (Cowork-Z440; `agent:claude-cowork.hp-z440` / `session:sam.z440-cowork-workspace`) |
   | host Z440 + VS Code, `moos-router` cwd | **Steinberger** (`agent:vscode.hp-z440.menno` / `session:sam.steinberger-seat`) |
   | host Z440 + VS Code, research cwd | **Karpathy** (`agent:vscode.hp-z440.lola` / `session:sam.karpathy-seat`) |
   | host Z440 + Antigravity | **Moos / AG-Z440** (`agent:antigravity.hp-z440` / `session:sam.moos-diary`) |
   | host `lap-sam` (hp-laptop) + Claude Desktop / Cowork | **John Lydon** (governance; formerly Guido) (`agent:claude-cowork.hp-laptop` / `session:sam.governance`; same agent also occupies `sam.laptop-cowork-workspace` — session_urn disambiguates) |
   | host `lap-sam` (hp-laptop) + VS Code/Copilot | **Guido** (laptop VS Code lead, T247 split) (`agent:vscode.hp-laptop.copilot` / `session:sam.laptop-vscode-lead`) or **Wolfram** (kernel-proper, T250 re-seat; `agent:vscode.hp-laptop.wolfram` / `session:sam.kernel-proper`, emits cross-box to `hp-z440.primary`) — the VS Code chat agent/model pane is the tie-breaker |
   | host hp-laptop + Cowork, curation lane | **John Lydon**'s second workspace (`agent:claude-cowork.hp-laptop` / `session:sam.laptop-cowork-workspace` — same agent as governance; explicit `session_urn` disambiguates) |
   | host ProDesk (`desktop-3fc7c3f` / `desktop-42d00rd`-distinct) + VS Code | **HP ProDesk** (`agent:vscode.hpprodesk.primary` / `session:sam.hpprodesk-setup`) |

   On Z440 the harness is the tie-breaker: a Cowork pane → Zappa (Cowork-Z440); a VS Code/Copilot pane on `moos-router` → Steinberger; on a research/`ffs0` root → Karpathy or the Z440 VS Code lead (`vscode.hp-z440.primary`). (Wolfram left Z440 at the T250 re-seat — kernel-proper is now driven from hp-laptop VS Code as `vscode.hp-laptop.wolfram`.) When the harness is ambiguous, **state the candidate set and ask** rather than guessing — a wrong seat poisons the whole orientation.

3. **Authoritative source for the resolved seat's row:** the **Seats table in `AGENTS.md`** (`D:\HPZ440\ffs0\AGENTS.md`, "Seats — agent × workspace × engine × surface") and the per-seat entry in `dev/config/session-affordance-map.json` (skills/prompts/`emit_kernel`/`mcp_server`/`opens_on_kernel`). Read the row, don't reconstruct it from memory.

   ```bash
   # quick host probe
   hostname
   ```
   ```powershell
   $env:COMPUTERNAME
   ```

### Step 2 — read live header + the seat's row

Two reads, both cheap, both live-truth:

1. **Running-state header** — `kb/superset/running-state.md`, the top `> Updated:` block. Gives the live **T-day**, what shipped this/last round, and what's **pending**. This is the hydration entrypoint; read it before claiming any state is current.

   ```bash
   head -10 /d/HPZ440/ffs0/kb/superset/running-state.md
   ```

2. **The seat's AGENTS.md row** — the resolved persona's line in the Seats table: its `agent` (principal), `workspace`(⟵`session`), `engine`(⟵`kernel`) + port, surface/IDE, and MCP port. Cross-check against `session-affordance-map.json` for the seat's mounted **skills** and `emit_kernel` / `opens_on_kernel` topology.

   **Engine discipline (read directly from the row, don't assume):** Z440 personae **emit** to `hp-z440.primary` :8000 / MCP :8080 today; the twins (`menno` :8001/:9001, `lola` :8002/:9002) carry `opens-on` **topology intent**, not state replication, pre-§M9. So the seat's *emit engine* and its *opens-on engine* can differ — name both if they do.

### Step 3 — run `moos-state-readback`

Invoke **`moos-state-readback`** (don't re-implement it here). It performs the per-repo `git -C <path> fetch` + divergence check on `ffs0` / `moos-kernel` / `moos-router`, pings `/healthz` on the seat's **engine** (reading `ontology_version` directly), audits the engine process + ports, and lists open handoff-issue comments. That gives you:

- per-repo crisp/behind status (do **not** claim "crisp" without it),
- the engine's **runtime 4.0 version** from `/healthz` (vs on-disk `ontology.json`),
- open `ffs0#<N>` handoff comments from peer agents.

If the seat is a **Cowork** seat, also run the **Cowork one-session readback** (absorbed section below) for the narrower one-session picture (seat occupied? heartbeat alive? scope-pins resolve? orphan chunks pending?). `moos-state-readback` is fleet-wide; the Cowork readback is this seat's t-cone — run the fleet one first, then the seat one.

### Step 4 — (optional) session-context projection

When a **fuller** picture is wanted — not just "am I crisp" but "what skills/prompts/MCP/extensions should be mounted for this seat, and what does the folded session subgraph look like" — invoke **`moos-session-context-projection`** (the F-direction projection from HG into the harness context pack). Skip it for a fast open; run it when hydrating a seat you'll do substantial work in, or when the affordance set is in doubt.

### Step 5 — emit the orientation

Synthesize a tight orientation block. This is the **replacement for the pasted handoff** — generated from steps 1–4, not retyped:

```
seat:     <Persona> — agent:<principal> / session:<workspace-urn>
engine:   kernel:<host>.<name> :<port> (4.0 alias: engine) — runtime v<X.Y.Z> [on-disk v<A.B.C>] · MCP :<mcp-port>[ · opens-on :<twin-port>]
host:     <hostname> (<Tailscale/LAN>) · surface <IDE/pane>
repos:    ffs0 <state> · moos-kernel <state> · moos-router <state>   (from state-readback)
lane:     T=<day> — <active-lane one-liner from running-state header>
pending:  <pending items from running-state header>
handoff:  ffs0#<N> — <new peer comments / none>
skills:   <mounted skills for this seat from affordance-map>
verdict:  <crisp + seated, ready> | <N blockers: pull X / re-seat Y / restart Z>
```

Keep it to that. If a row would say "behind" or "version-skew" or "unseated", the conversation **opens with the fix plan**, not with a doctrine claim — same discipline as `moos-state-readback`.

## What this composes (don't duplicate)

This skill is a **conductor**, not a reimplementation:

- **`moos-state-readback`** — does the repo/engine/health/handoff readback. This skill calls it; it does not re-do `git fetch` logic.
- **Cowork one-session readback** (absorbed section in this file) — the one-session seat check. Used for Cowork seats only.
- **`moos-session-context-projection`** — the F-direction affordance pack + session subgraph. Called optionally for a fuller open.

`moos-seat-hydration` adds exactly one thing on top: **seat resolution + synthesis into the orientation block that used to be a paste.** If you find yourself re-implementing fetch/health/projection logic here, stop — call the owning skill.

## Why it exists (S0 paste → S1 operation)

Per `AGENTS.md`, IDE/agent conversations are **S0 substrate** — the raw rewriting layer. Sam's old orientation prompt was a literal S0 artifact: a `tmp/*handoff*.md` block, hand-pasted at the top of each fresh conversation, that the model absorbed as context. It worked, but it had the failure mode of every paste: it was **true at authoring time and stale by the next fact-change** — a new T-day, a merged PR, a re-seated occupant, a version bump all silently invalidated it, and nobody re-pastes a 20-line block every round.

Promoting orientation from **S0 paste → S1 operation** removes the staleness: the skill reads `/healthz`, `running-state.md`, and the `AGENTS.md` Seats table **at invocation**, so the orientation is current by construction. The handoff stops being a document you maintain and becomes a derivation you run. That is the same F⊣G move the whole project makes (`S0 conversation → chunker → knowledge_item → projected back out`) applied to the orientation step itself.

## Safety / boundaries

- Read-only. No envelopes, no pulls, no restarts, no commits — every state change stays an explicit owner-gated boundary act.
- If seat resolution is ambiguous, **state candidates and ask**; never silently pick a seat.
- Readback wins over any authored doc: if `AGENTS.md`'s Seats table disagrees with live `/healthz` + HG, the readback is truth — re-read, don't force the table (it is an authored F-projection, not operational truth).
- Never print token/secret values surfaced by any composed step.

## Cross-references

- `moos-state-readback` — fleet-wide repo/engine readback (composed; run it, don't reimplement).
- Cowork one-session readback — absorbed into this skill T=262; see the absorbed section below.
- `moos-session-context-projection` — F-direction affordance pack (composed, optional).
- `AGENTS.md` — Seats table + relational spine + 4.0 vocab; the authoritative row source for step 1–2.
- `dev/config/session-affordance-map.json` — per-seat skills/prompts/`emit_kernel`/`mcp_server`.
- `kb/superset/running-state.md` — live header read in step 2; the hydration entrypoint this skill front-ends.

authored-by: agent:claude-cowork.hp-z440 / session:sam.z440-cowork-workspace / t239-catchup


---

# Absorbed (T=262): moos-cowork-readback

> Former standalone skill; body preserved verbatim — skill names referenced inside are historical (the content IS this section). Former description: Round-open readback scoped to a Cowork session's t-cone. Use at the start of any Cowork-driven work session (Z440 Desktop or hp-laptop Desktop) to verify the seat is occupied, the heartbeat is alive, the scope-pins resolve, and no stale orphan chunks are pending. Companion to `moos-state-readback` but narrower — one session's picture, not the whole fleet's. Trigger on: Desktop launch, "am I still seated?", "what's pending in my workspace curation lane?", or the daily 08:00 chunker-sweep wakeup.

# moos-cowork-readback

Open-of-round discipline for Cowork sessions. Answers three questions in 15 seconds:

1. **Am I seated?** — Cowork agent still has the has-occupant relation; session status is `active`.
2. **Am I alive?** — session `local_t` has advanced recently (within the configured liveness window); no stuck heartbeat.
3. **What's pending in my scope?** — each pinned channel has a clear ingest state; no orphan artifacts waiting on a chunker run.

This skill is READ-ONLY. No envelopes emitted. If something needs correction (rotate occupant, re-pin scope, re-chunk an orphan), that's a separate skill invocation (`moos-rewrite-envelope` + `moos-workspace-ingest` respectively).

## Which host am I on?

```
agent:claude-cowork.hp-z440       → session:sam.z440-cowork-workspace   → kernel:hp-z440.primary   :8000
agent:claude-cowork.hp-laptop     → session:sam.governance (John Lydon, governance lane)      → kernel:hp-laptop.primary :8000
agent:claude-cowork.hp-laptop     → session:sam.laptop-cowork-workspace (same agent, curation)  → kernel:hp-laptop.primary :8000
```

One binary, three sessions, two kernels — the hp-laptop agent is multi-workspace since the T247 split. Pick the right endpoint from the `agent` URN Cowork is running as; on hp-laptop always set `session_urn` explicitly.

## The 15-second sequence

### Step 1 — resolve your session URN

Derive from the agent URN suffix (`.hp-z440` → `sam.z440-cowork-workspace`). On `.hp-laptop` the agent occupies two workspaces since the T247 split (`sam.governance` — the John Lydon lane — and `sam.laptop-cowork-workspace`): use the explicit `session_urn` for the lane being driven, never infer from the suffix alone. No kernel call needed.

Set it once for the steps below:

```bash
SESSION_URN=urn:moos:session:sam.z440-cowork-workspace   # or sam.governance / sam.laptop-cowork-workspace on hp-laptop
```

### Step 2 — session node health

```bash
curl -sS "http://localhost:8000/state/nodes/$SESSION_URN" \
  | jq '{status: .properties.status.value, local_t: .properties.local_t.value, scope_pins: .properties.scope_pins.value}'
```

**Expected:**
- `status == "active"` — session is driving. If `pending_driver`, Desktop launched but nothing's been emitted yet; first envelope flips it. If anything else (`paused`, `archived`), the session is off-duty and emissions will be rejected at §M11 gate.
- `local_t` — positive integer. Compare against the previous round's readback if you have one; if it's identical, no heartbeat happened between rounds (fine if the session sat idle; a flag if a chunker sweep was supposed to fire).
- `scope_pins` — array of 4 channel URNs (gmail, calendar, drive, tasks). If missing or truncated, the pinning decayed (shouldn't happen via MUTATE alone, but verify).

### Step 3 — has-occupant is you

```bash
curl -sS "http://localhost:8000/state/relations/src/$SESSION_URN" \
  | jq '[.[] | select(.src_port == "has-occupant" and .tgt_port == "is-occupant-of")] | .[0]'
```

**Expected:** exactly one relation; `tgt_urn == "urn:moos:agent:claude-cowork.<host>"`. If zero → you were evicted. If >1 → §M19 violation (should have been caught by RotateSessionOccupant). If tgt_urn is someone else → a rotation happened; Sam's call whether to re-rotate back to you.

### Step 4 — opens-on pins the kernel

Same query, filter `src_port == "opens-on"`. Expected: `tgt_urn == "urn:moos:kernel:hp-<host>.primary"`. If missing the session is orphan at the host-facet level — escalate to Wolfram (Z440) or John Lydon (hp-laptop).

### Step 5 — pinned channels resolve

For each URN in `scope_pins`, check the channel node exists and its `status == "active"`:

```bash
for ch in $(echo "$SCOPE_PINS" | jq -r '.[]'); do
  curl -sS "http://localhost:8000/state/nodes/$ch" \
    | jq '{urn: .urn, kind: .properties.kind.value, status: .properties.status.value, source_uri: .properties.source_uri.value}'
done
```

**Expected:** 4 rows, all `status: active`. If a channel is `paused` or `archived`, that surface is off-line; chunker should skip it on next sweep.

### Step 6 — recent ingests per channel

Walk relations **outbound** from each channel via the WF12 `provides-kb`/`kb-source` port pair to count umbrella `knowledge_item` nodes. This is the "chunked something from this channel recently" signal:

```bash
for ch in $(echo "$SCOPE_PINS" | jq -r '.[]'); do
  count=$(curl -sS "http://localhost:8000/state/relations/src/$ch" | jq '[.[] | select(.src_port == "provides-kb")] | length')
  echo "$ch → $count umbrella KIs"
done
```

**WF correction (T=173 ~22:30 CEST):** Earlier drafts of this skill and the ingest skill prescribed WF18 `composes`/`composed-by` (inbound at channel via the `tgt` relations endpoint). That was wrong: WF18 is program composition (`src_types: [program, purpose]`), which excludes `channel`. The correct category is WF12 `provides-kb`/`kb-source` (KB hydration; channel→umbrella is a WF12 src→tgt relation, so query the `src` relations endpoint with `src_port == "provides-kb"`).

A channel with 0 umbrellas that you expected to have chunks = an **orphan source** (artifact exists externally, no HG reification yet). Either:
- Chunker didn't run for that surface (schedule or invocation missed)
- Chunker was invoked but failed (check fail-mode log)
- Surface genuinely has nothing to chunk (fine)

### Step 7 — orphan artifacts under Cowork's own authorship

Cowork sometimes creates local artifacts (meeting-prep briefs, research summaries) that SHOULD land in HG via per-artifact-section chunking but didn't. If Cowork's artifact library has items from this round that aren't represented in HG, flag them for the next chunker sweep.

This step is platform-specific (Cowork artifact library location is outside HG). Check whichever folder the Cowork platform stores its output in; compare against HG knowledge_items whose `source_uri` references that folder.

## Reporting shape

Compact five-line summary on success:

```
cowork readback (session:sam.z440-cowork-workspace)
  seat:      claude-cowork.hp-z440 (occupied), status=active, local_t=<N>
  host:      kernel:hp-z440.primary ← opens-on
  channels:  gmail (active, 3 KIs), calendar (active, 0), drive (active, 12), tasks (active, 0)
  orphans:   2 in drive channel (1 doc unchunked from Apr 23; 1 Cowork brief from this round)
  verdict:   alive + seated + 2 orphans to chunk; next chunker invocation covers them
```

Fuller report on anomaly (any of: unseated, ambiguous, stale-heartbeat-by-threshold, unreachable-channel, missing-scope-pin):

```
cowork readback: ANOMALY
  <symptom>
  <likely cause>
  <remediation path>
```

## Integration with moos-state-readback

`moos-state-readback` is fleet-wide (all repos, all kernels, all personae). `moos-cowork-readback` is one session. Call sequence:

1. **Round open** on Cowork machine: `moos-state-readback` first (verify repos + kernels + ontology version + running-state drift), THEN `moos-cowork-readback` (verify your specific seat).
2. **Mid-round** check: `moos-cowork-readback` alone. Fast.
3. **Round close**: `moos-cowork-readback` to catch orphans that should chunk before handoff, then `moos-round-close` to commit/push/comment per the fleet discipline.

## Fail modes and recovery

| Symptom | Cause | Recovery |
|---|---|---|
| `status=pending_driver` after Desktop launched | First envelope hasn't landed yet | Emit a trivial rewrite (e.g. MUTATE session.turn_count +1) to flip the flag; subsequent chunker invocation re-checks |
| `has-occupant` missing | Session was un-seated since last round (manual UNLINK or rotation elsewhere) | Route to Sam for re-seating; `RotateSessionOccupant` helper on kernel-side |
| `has-occupant` points at someone else | Rotation happened | Sam's call whether to rotate back; do NOT freelance a rotation from readback |
| channel node 404 | Channel UNLINKed / kernel restored from a stale log | Route to Wolfram for re-ADD; the scope_pins property still references the URN |
| channel `status=archived` | Surface retired | Skip in chunker; update scope_pins to drop archived channels in next round (requires MUTATE, not this skill) |
| kernel `/healthz` 500 / connection refused | Kernel is down or restarting | Wait ~5s + retry; if persistent, route to Wolfram (Z440) or John Lydon (hp-laptop); do NOT emit work during kernel-down window |
| `local_t` frozen since last readback | Heartbeat dead; either session off-duty or your Cowork process died | Check Cowork process state first; if alive, emit any envelope to tick |

## Cross-references

### Inside ffs0

- `derivation:t172.cowork-as-occupant` (on log) — the doctrine this skill readback-checks
- `derivation:t169.session-generalization` (on log) — 5-facet tuple (scope, purpose, host, owner, occupant); all 5 are what readback inspects
- `kb/superset/running-state.md` — fleet-wide ground truth for comparison

### Companion skills

- `moos-state-readback` — fleet-wide parent; run first
- `moos-workspace-ingest` — the chunker that resolves "orphan" flags this skill surfaces
- `moos-rewrite-envelope` — envelope shape reference if a recovery requires an emission
- `moos-round-close` — close-of-round discipline; run after anomalies resolve

## Status

**Operational** (first authored T=173, paired with `moos-workspace-ingest`). The Cowork seats are live — Zappa on Z440; John Lydon on hp-laptop driving `session:sam.governance` plus the curation workspace since the T247 split (resolve `session_urn` per step 1) — and this readback is the round-open first step on any Cowork seat.


---

# Absorbed (T=262): moos-workstation-operator

> Former standalone skill; body preserved verbatim. Former description: "Operate a mo:os workstation from the Claude Code / Cowork harness: repo + runtime readback, MCP/session-context projection, IDE/affordance setup, and multi-workstation handoff. Use when asked to open, refresh, hydrate, or configure a workstation/session; snapshot ffs0/moos-kernel/moos-router and kernel/router health; align local IDE/MCP/skills/prompts with folded HG state; or hand off between Z440, hp-laptop, and HP ProDesk. Shared cross-tool orientation lives in AGENTS.md; this skill is the canonical operator procedure. Trigger phrases: open the workstation, workstation readback, hydrate this session, refresh runtime state, MCP target check, projection pipeline gate, workstation handoff."

# mo:os Workstation Operator (Claude / Cowork twin)

You are the mo:os workstation operator running in the Claude Code / Cowork harness. Job: keep the local IDE, repos, live kernel/router, MCP endpoints, prompts, skills, and projection artifacts aligned with folded HG state, and produce clean readbacks/handoffs.

Shared cross-tool orientation (seat map, SOT hierarchy, pipeline, branching, safety) lives in **`AGENTS.md`** — read it for the project brief; this skill is the canonical *procedure*. (The legacy VS Code `.agent.md` twin was retired T=220 when `.github/{agents,prompts,instructions,hooks}` were removed; Copilot reads `AGENTS.md` natively.)

## Tool mapping (abstract → Claude)

| capability | Claude tool |
|---|---|
| read | Read |
| search | Grep / Glob |
| edit | Edit / Write |
| execute | Bash / PowerShell |
| todo | Task (TaskCreate/Update) |

## Opening Move

Unless the user gives a narrower request:

1. Read `AGENTS.md` (project SOT) + `kb/superset/running-state.md` (live state).
2. Snapshot repo status for `ffs0`, `moos-kernel`, `moos-router` (branch, ahead/behind, dirty) via `git -C <path>`.
3. Check `http://localhost:8000/healthz` and `http://localhost:9000/healthz` (and federated peers per the AGENTS.md network section).

Report the current occasion: kernel/place, session, actor/occupant, MCP target, repo state.

## Operating Rules

- Treat IDE conversations as **S0 substrate** until chunked, projected, or otherwise reified.
- Prefer live readback and generated projection artifacts over stale bootstrap prose.
- Keep `.vscode/mcp.json` local and secret-free; update `.vscode/mcp.json.example` for portable MCP shape.
- Keep `Downloads`, legacy `moos-config`, and temporary local roots out of the tracked workspace file; use an ignored `*.local.code-workspace` when needed.
- `ffs0` admin/control work is **trunk-first on `main`** when verified and single-lane/non-colliding (T208 rule); collision-prone or multi-lane work goes to a per-lane branch and merges with provenance (T218 branching doctrine: `branch = F(session)`, `merge = G(branch)`). Branch runtime code work in `moos-kernel` / `moos-router` as `feat/<purpose-slug>`.
- Do **not** emit HG rewrites, write Calendar events, G-sync GitHub Project status, seat scoped-idle sessions, or ingest raw Keep notes from startup/readback checks. Raw Keep staging needs an explicit Takeout ZIP/folder/API/clipboard/manual artifact and review before apply.
- Do not treat pinned chat state, prompt text, or VS Code/IDE UI state as durable HG truth.
- Secret hygiene: never read, echo, or commit `secrets/` values, API tokens, or `.vscode/mcp.json`. Surface presence/status only.
- Mutations (commit/push, merge, DNS/Cloudflare/tunnel/Access, Calendar/Workspace writes, HG apply) are explicit boundary acts — surface to the user before doing them, never as a side effect of readback.

## Workstation Outputs

- Current repo/runtime summary (repos + `/healthz` + federation peers).
- Active session / actor / occupant / MCP target for this occasion.
- Projection pipeline gate result when `dev/scripts/projections/run-session-pipeline.ps1` is run.
- Exact files edited, each marked **portable** (tracked) or **local-only** (gitignored).
- Deferred items for the next workstation / seat.

## Companion Skills

- `moos-state-readback` — round/session open health.
- `moos-session-context-projection` — F-direction session context packs and the projection pipeline.
- `moos-tooling-dx` — IDE attach, MCP, harness plumbing.
- `moos-running-state-validator` — when the readback changes durable state documentation.
- `moos-rewrite-envelope` — when a readback turns into an actual HG rewrite batch.
- `moos-cowork-readback` — Cowork-specific seat readback.
