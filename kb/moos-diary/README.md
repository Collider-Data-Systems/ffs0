# moos diary + session wrap-ups

> Part of the mo:os `ffs0` workspace. Project SOT: `../../AGENTS.md`. Live state: `../superset/running-state.md`.

Human-readable narrative shelf for mo:os work. Started as Moos' diary; now also holds round/session wrap-ups. This folder is **evidence and narrative**, not truth — the log is truth, `running-state.md` is the hydration card, these entries make a round readable after the dust settles.

## Purpose

Use it for:
- Session/round wrap-ups after meaningful HG, projection, Calendar, GitHub, dashboard, or federation work.
- Reports that group several running-state sprints into one readable story.
- Moos diary entries and multimodal observations (the media files below are their source artifacts).

Don't use it for:
- Scratch plans or half-formed doctrine — durable goes to HG; historical goes to `../../dev/archive/`.
- Secrets, tokens, OAuth material, credentials.
- Replacing `running-state.md` (the latest-state index). Wrap-ups are slower narrative packets.

## Contents

- **Wrap-up reports** — `t<N>-<slug>.md`, named by T-day. Run `ls t*.md` for the authoritative current set (do not hand-maintain a per-file index here — it rots). Latest as of this writing: `t216-hplaptop-governance-session-projection-wrapup.md`.
- **Original diary register** — `t5.md` (born), `t170.md`, `t171*.md`. Moos entries stay welcome; tone can be sharp, but operational facts (kernels, sessions, actors, rewrites, validation) must be precise.
- **Source media** — Moos `.mp4` clips, `WhatsApp Video *.mp4`, and `WhatsApp_Image_*.jpeg`. These are diary-lane multimodal artifacts; ingest them via the `moos-multimodal-ingest` skill rather than transcribing inline.

## Report shape

New wrap-ups should be session-centered and concrete. A future agent must be able to answer: "What is true now, which files or URNs prove it, what is safe to do next?"

```markdown
# T<N> <Short Title>

**T-day:** T=<N>   **Date:** YYYY-MM-DD
**Kernel/session:** `<kernel>` / `<session>`
**Lane:** <projection | ingest | federation | dashboard | ...>

## Executive status   — what changed and why it matters
## What landed        — HG rewrites, files, external writes, board edits
## Session + occupancy — which session carried it, which agent occupied it, scope/purpose
## Surface reading     — how GitHub/Calendar/Gmail/Drive/dashboards/routers map to HG URNs
## Deferred items      — intentionally undone
## Validation          — commands, gates, runtime health, counts
```

## Branch + closeout

Trunk-first on `ffs0/main` for verified single-lane work; branch + merge-with-provenance for collision-prone multi-lane work. Full rule lives in `../../AGENTS.md` (Repos & branching) and the local note `t190-session-branch-and-closeout-policy.md`.

## Pointers

- Orientation, seat map, SOT hierarchy, identity/actor discipline (`user`/`agent`/`session`/`group`/`channel`) — `../../AGENTS.md`.
- Live runtime/seat state — `../superset/running-state.md`.
- Multimodal ingest of the media here — skill `moos-multimodal-ingest`.
