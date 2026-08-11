---
name: program / PRG naming convention
description: Programs (and legacy prg_task) use semantic slugs from the work's purpose, not numbered IDs. Numbered PRG NNN IDs are Wave 0 / pre-codex artifacts to skip.
type: project
originSessionId: cde10d83-f64f-44cd-a439-5578c4df362b
---
Programs in the hypergraph use semantic slugs derived from the work's purpose (lowercase, hyphens, typically ≤40 chars).

**Applies to:** `program` nodes (S2 canonical type since v3.9). Legacy `prg_task` nodes are `deprecated: true` in v3.9 and are being phased out — treat `program` as the forward type.

## Correct URN patterns

- `urn:moos:program:sam.t187-kernel-proper`
- `urn:moos:program:sam.v310-delivery`
- `urn:moos:program:sam.wiring-proposer`
- `urn:moos:program:sam.t164-room-tying`  (completed)
- `urn:moos:program:sam.session-occupancy`  (round-4 merged, scope-named)

**Structure:** `urn:moos:program:<owner-short>.<slug>`. `<owner-short>` is typically `sam`. `<slug>` is a purpose/scope phrase, not a number.

## Round-4 preference: scope-named, not T-prefixed

As of T=168 round 4, merged sub-programs are named by what they **monitor / scope** rather than T-tagged:

- Prefer `sam.session-occupancy` · `sam.session-view` · `sam.session-tools` · `sam.hook-predicates`
- Avoid `sam.t187.<suffix>` unless the sub-program is genuinely tied to the T=187 delivery window (e.g. `sam.t187.twin-deploy-mtdc` is legitimate because it's a T=187 sprint item).

## What to skip

**Numbered PRG IDs** (e.g. `PRG000`, `PRG304`..`PRG040`) are Wave 0 / pre-codex legacy artifacts.

- `urn:moos:prg:prg-000` in the log (early log_seqs) came from the purple-calendar-scanner reading a calendar event literally named "PRG 000".
- The codex-locked kernel (T=153+) does not use numbered IDs.
- If a calendar scanner encounters a legacy "PRG NNN" event summary, **skip or flag** rather than ADDing a node.

## Heuristic

When naming a new program:
1. What does it monitor, deliver, or scope? → that phrase, slug-form.
2. Anchor to T-window only if genuinely time-bound (`.t187.twin-deploy-mtdc` ok; `.t168.anything` usually wrong — T=168 is today, not a delivery window).
3. Owner prefix is usually `sam` unless authored by another user/agent.
