# ffs0 Repository Instructions (Copilot)

> **Mirror of `ffs0/AGENTS.md`** (the project SOT) · manual · don't edit except emergency de-rot. Copilot reads `AGENTS.md` natively — that is the canonical cross-tool brief (seat map, 3-tier SOT hierarchy, S0→HG pipeline, 4.0 vocab, branching, safety, skills). This file holds only Copilot-surface deltas.

## Read first
`ffs0/AGENTS.md` (project SOT) → `kb/superset/running-state.md` (live runtime/seat state). Folded HG + live `/healthz` outrank any doc; if a doc and live readback disagree, re-read — readback wins.

## Copilot-surface deltas (not in AGENTS.md)

### MCP wiring
- Workspace MCP = `.vscode/mcp.json` (top-level `servers`); machine-specific + **gitignored** — update `.vscode/mcp.json.example` when the portable shape changes.
- Prefer native VS Code server entries (`type: "sse"` / `"http"`). Root `.mcp.json` is legacy non-VS-Code config.
- Don't hardcode secrets (env vars for Cloudflare Access headers; local store for OAuth). Don't add the remote Copilot MCP endpoint unless its auth is verified on the current build — use the built-in GitHub integration or `gh` CLI.
- Keep emit-target vs opens-on distinct until §M9 twin-sync (Z440 `menno`/`lola` are topology endpoints; current emits target primary).

### Multi-repo workspace
- Tracked `ffs0.code-workspace` = portable baseline (roots `ffs0`/`moos-kernel`/`moos-router` + tasks + extension recs). Local-only roots (Downloads, worktrees, legacy `moos-config`) → gitignored `*.local.code-workspace`. (Per the AGENTS.md `*.code-workspace` model = D7 surface realization.)

### Validation
- After config edits: check JSON/MCP syntax + `git diff --check`. If projection-affected, run `Moos: Run Session Pipeline` / `dev/scripts/projections/run-session-pipeline.ps1`. Report local-only edits (esp. ignored `.vscode/mcp.json`).

## Skill routing
Capabilities live in `dev/claude-skills/` (synced to `~/.claude/skills/`); full index in `AGENTS.md`. Key: `moos-session-context-projection` (F-projection / dashboard / MVP gate), `moos-rewrite-envelope` (envelope authoring, post-§M11 actor discipline), `moos-categorical-research` (categorical / HDC), `moos-tooling-dx` (IDE / MCP / DX), `moos-workspace-ingest` (G-ingest, WF12), `moos-workstation-operator` (workstation open/readback/handoff).

## Safety
Never commit `secrets/` values or `.vscode/mcp.json`. Mutations (commit/push/merge, DNS/Cloudflare/tunnel/Access, Calendar/Workspace writes, HG apply) are explicit boundary acts — surface before doing. IDE/UI/pinned-chat state is not durable HG truth until G-ingested.
