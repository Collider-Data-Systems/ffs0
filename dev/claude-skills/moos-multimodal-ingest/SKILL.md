---
name: moos-multimodal-ingest
description: Multimodal artifact ingestion for the Moos diary lane (`session:sam.moos-diary` on `kernel:hp-z440.primary` driven by `agent:antigravity.hp-z440`, mirrored on hp-laptop by `agent:antigravity.hp-laptop` on `session:sam.laptop-moos-diary`). Use when chunking photos, videos, audio recordings, screen captures, or other non-textual artifacts into `knowledge_item` nodes. Complements `moos-workspace-ingest` (Workspace text-only) by handling the binary/perceptual register. Trigger on: a new diary photo or video to ingest, a Google Labs Flow output, an audio recording, a multi-frame screen capture, or any artifact whose semantic content is not directly text. Daily 08:00 multimodal-sweep wake-up if scheduled.
---

# moos-multimodal-ingest

The chunker for the multimodal G-direction (External multimedia → HG). Where `moos-workspace-ingest` handles Drive docs / Gmail threads / Calendar events as text-bearing knowledge_items, this skill handles **artifacts whose primary content is binary or perceptual** — photos, videos, audio, screen captures.

## Triggers

- A new artifact file on disk (jpeg, png, mp4, webm, wav, mp3, gif) that should land in HG
- A Google Labs Flow output (video) ready to ingest
- A multi-frame moos-diary photo set
- A scheduled multimodal-sweep wake-up
- Any persona request to "ingest this image/video/audio"

## What this skill is NOT

- Not for text-bearing artifacts in Workspace surfaces — use `moos-workspace-ingest` for those
- Not for live-streaming media — that's a future leaf-firing case (per T=175 fabric §5)
- Not for the F-direction (rendering HG state as media) — that's a future projection skill

## Cardinal rule — actor + session + substrate

```
actor:        urn:moos:agent:antigravity.hp-z440  (Z440 / Moos lane)
              OR urn:moos:agent:antigravity.hp-laptop  (hp-laptop / AG-laptop lane)
session_urn:  urn:moos:session:sam.moos-diary  (Z440)
              OR urn:moos:session:sam.laptop-moos-diary  (hp-laptop)
substrate:    external-channel (when the source lives outside HG)
              OR hg-native (rare; only for AG-authored artifacts living only in HG)
```

Always set `session_urn` explicitly per the §M11 best-practice (post-§M13 fix it's redundant for single-session agents but the convention stays).

## Inputs

| Source kind | URN shape | Channel | Tool |
|---|---|---|---|
| Photo (jpeg/png) on disk | `urn:moos:ki:photo.<slug>` | `channel:local.moos-footage` (Z440) | filesystem read + perceptual hash |
| Video (mp4/webm) on disk | `urn:moos:ki:video.<slug>` | `channel:local.moos-footage` | filesystem + frame sampling |
| Google Labs Flow output | `urn:moos:ki:labs-flow.<run-slug>` | `channel:web.labs-flow` | web fetch + transcoding |
| Audio recording | `urn:moos:ki:audio.<slug>` | `channel:local.moos-footage` | filesystem + transcription |
| Multi-frame screen capture | `urn:moos:ki:screen.<session-slug>.<frame-N>` | `channel:local.moos-footage` | filesystem + per-frame embed |

If the source can't be reached, **skip + log a single line; no envelopes**. Failed lookup is not a rewrite.

## Dispatch rule (chunk grain)

```python
def chunk_unit(source):
    if source.kind == "photo":
        return "per-item"             # one knowledge_item per photo
    if source.kind == "video":
        return "per-keyframe"         # umbrella + one chunk per keyframe (≥1 keyframe per 5s)
    if source.kind == "audio":
        if source.duration_s < 60:
            return "per-item"         # one knowledge_item, full transcription
        return "per-segment"          # umbrella + one chunk per ~30s segment
    if source.kind == "screen-capture":
        return "per-frame"            # umbrella + one chunk per frame
    return "per-item"                 # safe default
```

## Per-item case (single artifact)

```json
{
  "rewrite_type": "ADD",
  "actor": "urn:moos:agent:antigravity.hp-z440",
  "session_urn": "urn:moos:session:sam.moos-diary",
  "node_urn": "urn:moos:ki:<source-type>.<source-slug>",
  "type_id": "knowledge_item",
  "properties": {
    "title":        {"value": "<artifact title — derived from filename or caption>", "mutability": "immutable", "authority_scope": "", "stratum_origin": 2},
    "source_url":   {"value": "<file:// path OR https:// URL>", "mutability": "immutable", "authority_scope": "", "stratum_origin": 2},
    "source_type":  {"value": "<photo|video|audio|screen-capture>", "mutability": "immutable", "authority_scope": "", "stratum_origin": 2},
    "language":     {"value": "<en|nl|none|...>", "mutability": "immutable", "authority_scope": "", "stratum_origin": 2},
    "created_at":   {"value": "<ISO-8601 capture time>", "mutability": "immutable", "authority_scope": "", "stratum_origin": 2},
    "retrieved_at": {"value": "<ISO-8601 ingest time>", "mutability": "immutable", "authority_scope": "", "stratum_origin": 2},
    "status":       {"value": "raw", "mutability": "mutable", "authority_scope": "kernel", "stratum_origin": 2},
    "ingest_actor": {"value": "urn:moos:agent:antigravity.hp-z440", "mutability": "immutable", "authority_scope": "", "stratum_origin": 2},
    "media_kind":   {"value": "<image|video|audio>", "mutability": "immutable", "authority_scope": "", "stratum_origin": 2},
    "media_meta":   {"value": "{\"width\":..., \"height\":..., \"duration_s\":..., \"perceptual_hash\":...}", "mutability": "immutable", "authority_scope": "", "stratum_origin": 2}
  }
}
```

`media_kind` + `media_meta` are extra properties — kernel accepts unregistered properties on ADD (proven at T=173 chunker proof). Once the v3.14 substrate property promotes, add `substrate: external-channel` + `substrate_anchor_urn`.

## Multi-chunk case (umbrella + per-keyframe / per-segment / per-frame)

Order in the batch:

1. **Umbrella** — one ADD `knowledge_item` for the whole video/audio/capture-set; carries `chunk_count: N`, `media_meta` for the whole.
2. **Chunks** — one ADD per keyframe / segment / frame; carries `chunk_index`, `chunk_label` (timestamp), `umbrella_urn`.
3. **LINKs** — channel→umbrella + umbrella→each chunk via WF12 `provides-kb`/`kb-source`.

Same shape as `moos-workspace-ingest`'s multi-chunk case; see that skill for the canonical LINK envelope.

## Channel placeholders (T=171–T=175 era)

Two channels exist on Z440 sovereign log:
- `channel:local.moos-footage` — local filesystem moos-diary photos/videos (kind=filesystem)
- `channel:web.labs-flow` — Google Labs Flow renders (kind=messaging placeholder; future v3.15 candidate kind=labs-flow)

Hp-laptop side: mirrors needed once AG-laptop starts ingesting. Add as needed via 2-envelope batch (same pattern as the T=174 hp-laptop channel mirror).

## Idempotence

Before ADD, check `urn:moos:ki:<source-type>.<source-slug>` doesn't already exist. If it does:

- **Same `source_url` + same `ingest_actor`** → skip; emit one duplicate-ingest claim
- **Different `source_url` or `ingest_actor`** → URN collision; bail loud; ask Sam to disambiguate

Slug from filename + perceptual-hash prefix (8 hex chars) ensures uniqueness in practice.

## Cross-references

- `moos-workspace-ingest` — text-bearing G-ingest companion; same envelope shape, different sources
- `moos-rewrite-envelope` — envelope shapes, gates, immutability
- `kb/research/moos-diary/20260421-t171-multimodal-diary-personas.md` — Moos persona origin + diary lane doctrine
- `kb/research/session/20260422-t172-cowork-as-occupant.md` §3 — chunking discipline (text variant; parallel applies here)
- `kb/research/session/20260424-t175-program-authoring-fabric.md` §4 — substrate property doctrine (post-v3.14)

## Status

**Round-13 deliverable** (T=176). First skill authored for the Moos + AG-laptop multimodal lanes. Iterates as Moos refines from actual diary ingest patterns; consider extending with more `media_kind` enum values or per-kind chunk-grain overrides as the corpus grows.
