# CLAUDE.md

@AGENTS.md

> **Mirror of `AGENTS.md`** (the project SOT) · manual · don't edit except emergency de-rot. Canonical cross-tool orientation lives in **`AGENTS.md`** (kernel) + `dev/reference/agents-reference.md` (deep tier). This file = Claude-Code-specific deltas only.

Personal portable private workspace for mo:os. Owner `urn:moos:user:sam`. **Read `kb/superset/running-state.md` first for live state**; folded HG + live `/healthz` outrank any doc (readback wins).

## Actor discipline (§M11/§M12 — for envelope authoring)
Every envelope carries `actor`: **agent** (`urn:moos:agent:<short>`, default; multi-workspace agents Zappa/John Lydon set `session_urn` explicitly) · **kernel** (`urn:moos:kernel:<ws>.<name>`, bypasses §M11+§M12; required for ontology-governed ADDs, kernel-authority MUTATEs, WF19 `opens-on` LINKs) · **user** (`urn:moos:user:sam`, fails §M11; only inside `SeedIfAbsent`). `env.actor` = who emits (ephemeral); `owner_urn` = who owns (sticky). Envelope shapes + field gotchas → skill **`moos-rewrite-envelope`**.

## Skills
12 moos skills, model-routed by description; canonical in `dev/claude-skills/`, synced per-seat via `dev/scripts/sync-claude-skills.ps1 [-Seat <key>]`. Seat mounts: `.claude/rules/seat-context.md`. Index: agents-reference.

## Projection lane
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File dev\scripts\projections\run-session-pipeline.ps1
```
Outputs under `tmp/projections/session_pipeline/`. Detail → skill `moos-session-context-projection`.

## Workspace
`kb/superset/` (ontology.json + running-state.md) · `kb/moos-diary/` (round wrap-ups) · `dev/` (scripts · tools · claude-skills · config · design · reference) · `secrets/` (GITIGNORED) · `.github/` (Copilot mirror + Project-sync Action). Runtime repos (siblings): `moos-kernel` (Go) · `moos-router` (federation) · `moos-config` = LEGACY.

## Safety
Never commit `secrets/` values or `.vscode/mcp.json`. Destructive/outward actions are explicit boundary acts. IDE conversations are **S0 substrate** until G-ingested — not durable HG truth.
