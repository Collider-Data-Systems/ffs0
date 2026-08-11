# YouTube transcript archive

> Part of the mo:os `ffs0` workspace. Project SOT: `../../../AGENTS.md`. Live state: `../../../kb/superset/running-state.md`.

Reference archive of YouTube transcripts in normalized JSON, captured for research hydration. Live ingest tooling: `dev/scripts/youtube/` (T=260 rebuild of the retired `.agent\dev\` trio, removed at `d649b60`) — `ingest-youtube-url.ps1` (single URL), `ingest-youtube-list.ps1` (batch + ledger), `save-youtube-transcript.ps1` (entry writer), sharing `youtube-common.ps1`. Entries land here; both ingest scripts refuse duplicates by video id unless `-Force`.

## Contents

| Path | What |
|---|---|
| `schema.json` | JSON Schema (draft-07) for one transcript entry — required fields: `id`, `source_type`, `source_url`, `retrieved_at`, `title`, `channel`, `language`, `summary`, `keywords`, `transcript` |
| `entries/` | 19 transcript entries, `yt-<slug>-<timestamp>.json`; mostly ML/AI talks (Karpathy, MLST, Yi Ma, neurosymbolic, hypergraph transformers) + one Rick Astley debug fixture |
| `lists/` | Source-list ledgers (`youtube-list-*.json`) with per-item `status` + `kb_entry_path` |
| `dedupe-index.json` | Canonical/alias duplicate report (last generated 2026-03-29; 18 unique groups, 0 duplicates) |

Note: paths inside `dedupe-index.json` and the list ledgers point at a historical `FFS0_HPlaptop\ffs0-factory-super\.agent\...` capture location and are not current. The entries themselves are the source of truth.

## Usage

To pull a transcript into the HG as `knowledge_item` nodes, hand the entry file to the workspace ingest lane — skill `moos-workspace-ingest` (G in the F⊣G adjunction, WF12 provides-kb). Keep these files in `reference/` until a directed task promotes selected data into instance files.
