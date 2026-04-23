# kb-reference-apr5 — archived Google Workspace mirror

**Freeze date:** April 5, 2026 (T≈155; single bulk-sync event, ~10:18 UTC+2)
**Archive date:** April 23, 2026 (T=173)
**Origin:** `ffs0/kb/reference/` — Google Calendar + Drive + Tasks JSON/ICS snapshot, 47 files, ~2.1 MB
**Archived by:** claude-code.hp-z440 (Stephen Wolfram persona, `session:sam.kernel-proper`) at Sam's T=173 direction.

## Why archived

By Sam's T=173 principle: "Anything IRL that isn't sourced from the HG itself — ephemeral mirrors, past-round scratch, superseded notes — belongs in `dev/reference/research-archive/`. `kb/` stays live doctrine + HG-authoritative research only."

The Apr 5 snapshot was a single bulk dump with no refresh cadence. As of T=173 it was 18 days stale, never actively consulted by round-to-round work, and operationally superseded by the Cowork substrate that landed the same round:

- `channel:google.gmail.sam`
- `channel:google.calendar.sam`
- `channel:google.drive.sam`
- `channel:google.tasks.sam`

These channel nodes (log_seq 259–262 on `kernel:hp-z440.primary`) are the live HG representations of the Workspace surfaces. Ingest from them will flow through the `moos-workspace-ingest` skill (queued) into `knowledge_item` chunks per the chunking discipline in `kb/research/session/20260422-t172-cowork-as-occupant.md` §3.

## Contents

```
calendar/
  entries/  — 30 JSON event records
  exports/  — 1 ICS (moos-dynamic-sync-2.ics)
drive/
  entries/  — 12 JSON folder/file records
tasks/
  entries/  — 4 JSON task records
```

## Retrieval

This archive is read-only history. If a past calendar event, drive file, or task needs to be referenced:

1. Check if it's already represented via an HG node (search `knowledge_item` or `calendar_event` nodes for matching external identifiers).
2. If not, read the relevant JSON directly from this archive.
3. If the info should enter the HG, emit a fresh ADD envelope (per `moos-workspace-ingest` once shipped, or manually).

Do **not** re-introduce this tree under `kb/`. The live Workspace state belongs in HG via channel nodes, not mirrored snapshots.

## Cross-references

- `kb/research/session/20260422-t172-cowork-as-occupant.md` — the doctrine that supersedes this mirror
- `kb/superset/running-state.md` — T=173 round-open section notes the archive move
- `dev/reference/research-archive/` — sibling archive entries (T=158–T=162 research notes + T=169 round-close scratch + T=164 wires-come-from)
