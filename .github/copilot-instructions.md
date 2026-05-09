# ffs0 Repository Instructions

## Scope

Personal portable private workspace (`ffs0`). Runtime code lives in sibling repos (`moos-kernel`, `moos-router`). `moos-config` is legacy.

All three repos at `github.com/Collider-Data-Systems/*` since T=172.

## Running state

**Read `kb/superset/running-state.md` first.** Current T-day, active program, kernel state, personae seatings, key URNs.

Current T189 hp-laptop state: kernel `hp-laptop.primary` is live on `ontology_version=3.16.1`, `t_day=189`, `log_len=1086`. `session:sam.governance` has durable WF19 purpose `purpose:sam.doctrine-governance-and-delegation` and now pins the Calendar/time-fabric program family. The active working lane is the Keep/session/visual/Calendar/recommendation projection pipeline; latest report is `kb/moos-diary/t189-recommendation-hg-projection-wrapup.md`.

For projection work, run the local pipeline before making claims about MVP status:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File dev\scripts\projections\run-session-pipeline.ps1
```

Outputs land under `tmp/projections/session_pipeline/`: session context pack, graph engineering report, session-occasion DOT/SVG, temporal/calendar DOT/SVG, Calendar time-fabric plan/report, recommendation HG plan/report, MVP gate, and `index.html` control surface. Current expected gate is `warn` with 13 pass, 2 warn, 0 fail; remaining warnings are disconnected forced graph roots and no interactive Cytoscape.js-style inspector.

Kernel/application split: `moos-kernel` is the OS-facing runtime function program; `moos-router` is federation routing; application domains such as `my-tiny-data-collider` are HG groups/program families that run through the kernels and may project to websites, DNS, Calendar, GitHub, Workspace, and servers. Keep those entities/codebases separate.

Round-level context from prior rounds lives under `dev/reference/research-archive/` — retrieve explicitly when needed. `kb/research/` is reserved for live doctrine only (T=173 pivot).

## Working style

Small, safe, focused edits. Preserve folder structure unless change is requested.

Avoid process-heavy documents unless explicitly requested. `.md` accumulation is consciously ended as of T=173 — conversations reify into HG as `knowledge_item` nodes via the chunker skill, not new scratch files under `kb/research/`.

## Domain knowledge

Invoke `moos-session-context-projection` for session context packs, IDE/harness projection, local MVP gate checks, or graph visualization/analysis of newly added HG nodes.
Invoke the `moos-domain-expert` skill for categorical/mathematical reasoning.
Invoke `moos-rewrite-envelope` for envelope authoring (post-§M11 actor discipline: agent-default, kernel-for-ontology-governed, never user:sam in Apply path).

## Safety

Never commit secret values. `secrets/` is local-first. Destructive actions are explicit.
