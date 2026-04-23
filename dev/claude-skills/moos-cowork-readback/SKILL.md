---
name: moos-cowork-readback
description: Round-open readback scoped to a Cowork session's t-cone. Use at the start of any Cowork-driven work session (Z440 Desktop or hp-laptop Desktop) to verify the seat is occupied, the heartbeat is alive, the scope-pins resolve, and no stale orphan chunks are pending. Companion to `moos-state-readback` but narrower — one session's picture, not the whole fleet's. Trigger on: Desktop launch, "am I still seated?", "what's pending in my workspace curation lane?", or the daily 08:00 chunker-sweep wakeup.
---

# moos-cowork-readback

Open-of-round discipline for Cowork sessions. Answers three questions in 15 seconds:

1. **Am I seated?** — Cowork agent still has the has-occupant edge; session status is `active`.
2. **Am I alive?** — session `local_t` has advanced recently (within the configured liveness window); no stuck heartbeat.
3. **What's pending in my scope?** — each pinned channel has a clear ingest state; no orphan artifacts waiting on a chunker run.

This skill is READ-ONLY. No envelopes emitted. If something needs correction (rotate occupant, re-pin scope, re-chunk an orphan), that's a separate skill invocation (`moos-rewrite-envelope` + `moos-workspace-ingest` respectively).

## Which host am I on?

```
agent:claude-cowork.hp-z440       → session:sam.z440-cowork-workspace   → kernel:hp-z440.primary   :8000
agent:claude-cowork.hp-laptop     → session:sam.laptop-cowork-workspace → kernel:hp-laptop.primary :8000
```

One binary, two sessions, two kernels. Pick the right endpoint from the `agent` URN Cowork is running as.

## The 15-second sequence

### Step 1 — resolve your session URN

Derive from the agent URN suffix (`.hp-z440` → `sam.z440-cowork-workspace`, `.hp-laptop` → `sam.laptop-cowork-workspace`). No kernel call needed.

### Step 2 — session node health

```bash
curl -sS http://localhost:8000/state/nodes/urn:moos:session:sam.<host>-cowork-workspace \
  | jq '{status: .properties.status.value, local_t: .properties.local_t.value, scope_pins: .properties.scope_pins.value}'
```

**Expected:**
- `status == "active"` — session is driving. If `pending_driver`, Desktop launched but nothing's been emitted yet; first envelope flips it. If anything else (`paused`, `archived`), the session is off-duty and emissions will be rejected at §M11 gate.
- `local_t` — positive integer. Compare against the previous round's readback if you have one; if it's identical, no heartbeat happened between rounds (fine if the session sat idle; a flag if a chunker sweep was supposed to fire).
- `scope_pins` — array of 4 channel URNs (gmail, calendar, drive, tasks). If missing or truncated, the pinning decayed (shouldn't happen via MUTATE alone, but verify).

### Step 3 — has-occupant is you

```bash
curl -sS 'http://localhost:8000/state/relations/src/urn:moos:session:sam.<host>-cowork-workspace' \
  | jq '[.[] | select(.src_port == "has-occupant" and .tgt_port == "is-occupant-of")] | .[0]'
```

**Expected:** exactly one relation; `tgt_urn == "urn:moos:agent:claude-cowork.<host>"`. If zero → you were evicted. If >1 → §M19 violation (should have been caught by RotateSessionOccupant). If tgt_urn is someone else → a rotation happened; Sam's call whether to re-rotate back to you.

### Step 4 — opens-on pins the kernel

Same query, filter `src_port == "opens-on"`. Expected: `tgt_urn == "urn:moos:kernel:hp-<host>.primary"`. If missing the session is orphan at the host-facet level — escalate to Wolfram (Z440) or Guido (hp-laptop).

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

**WF correction (T=173 ~22:30 CEST):** Earlier drafts of this skill and the ingest skill prescribed WF18 `composes`/`composed-by` (inbound at channel via the `tgt` relations endpoint). That was wrong: WF18 is program composition (`src_types: [program, purpose]`), which excludes `channel`. The correct category is WF12 `provides-kb`/`kb-source` (KB hydration; channel→umbrella is a WF12 src→tgt edge, so query the `src` relations endpoint with `src_port == "provides-kb"`).

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
| kernel `/healthz` 500 / connection refused | Kernel is down or restarting | Wait ~5s + retry; if persistent, route to Wolfram (Z440) or Guido (hp-laptop); do NOT emit work during kernel-down window |
| `local_t` frozen since last readback | Heartbeat dead; either session off-duty or your Cowork process died | Check Cowork process state first; if alive, emit any envelope to tick |

## Cross-references

### Inside ffs0

- `kb/research/session/20260422-t172-cowork-as-occupant.md` — the doctrine this skill readback-checks
- `kb/research/session/20260419-t169-session-generalization.md` — 5-facet tuple (scope, purpose, host, owner, occupant); all 5 are what readback inspects
- `kb/superset/running-state.md` — fleet-wide ground truth for comparison

### Companion skills

- `moos-state-readback` — fleet-wide parent; run first
- `moos-workspace-ingest` — the chunker that resolves "orphan" flags this skill surfaces
- `moos-rewrite-envelope` — envelope shape reference if a recovery requires an emission
- `moos-round-close` — close-of-round discipline; run after anomalies resolve

## Status

**Draft — T=173 authoring**, paired with `moos-workspace-ingest`. Neither has been invoked in anger yet — first real run happens when Sam launches Claude Desktop on Z440 (or hp-laptop), at which point Cowork emits its first envelope, the seat flips from `pending_driver` → `active`, and this readback becomes the daily-08:00 ritual's first step.
