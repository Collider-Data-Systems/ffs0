# Rule — seat-context (mo:os seat → affordance map)

> Authored projection, not operational truth — if a row disagrees with live `/healthz` + HG readback, the readback wins (re-read, don't force the row). Sources: `AGENTS.md` generated seat table + `dev/config/session-affordance-map.json`; spine + emit-discipline doctrine live in `AGENTS.md`. 4.0 aliases: `engine` = `kernel`, `workspace` = `session`; URNs stay canonical (`urn:moos:kernel:*`, `urn:moos:session:*`).
>
> Emit discipline: Z440 personae emit to `hp-z440.primary` :8000 / MCP :8080 until §M9 twin-sync (twins carry `opens-on` topology intent only, not state). Multi-workspace agents (Zappa, John Lydon) set `session_urn` explicitly on every envelope.

## Active seats (agent · workspace · engine/emit · surface · skills)

**Wolfram** — kernel-proper / Go runtime lane (T250 re-seat). `vscode.hp-laptop.wolfram` · `sam.kernel-proper` · emit `hp-z440.primary` :8000 (cross-box over Tailscale; Z440 must be up; router :9000 is never a write path) · VS Code, hp-laptop · skills: `moos-rewrite-envelope`, `moos-state-readback`. Validate `go test ./...`.

**Zappa** — workspace curation / G-ingest lane. `claude-cowork.hp-z440` · `sam.z440-cowork-workspace` · emit `hp-z440.primary` :8000 · Claude Code / Cowork pane, Z440 · skills: `moos-seat-hydration`, `moos-workspace-ingest`, `moos-multimodal-ingest`, `moos-session-context-projection`, `moos-rewrite-envelope`. Multi-workspace → explicit `session_urn`.

**Moos / AG-Z440** — diary / multimodal ingest. `antigravity.hp-z440` · `sam.moos-diary` · emit `hp-z440.primary` :8000 · Antigravity, Z440 desktop 5 · skills: `moos-multimodal-ingest`, `moos-state-readback`.

**Steinberger** — tooling / DX lane. `vscode.hp-z440.menno` · `sam.steinberger-seat` · opens-on `hp-z440.menno` :8001 (topology intent), emits `hp-z440.primary` :8000 pre-§M9 · VS Code, Z440 desktop 3 · skills: `moos-tooling-dx`, `moos-session-context-projection`, `moos-cross-persona-audit`.

**Karpathy** — categorical / HDC research lane. `vscode.hp-z440.lola` · `sam.karpathy-seat` · opens-on `hp-z440.lola` :8002 (topology intent), emits `hp-z440.primary` :8000 pre-§M9 · VS Code, Z440 desktop 4 · skills: `moos-categorical-research`, `moos-session-context-projection`, `moos-state-readback`. Mark conjectures as conjectures.

**John Lydon** — governance lane (T247 split; the ex-Guido governance persona). `claude-cowork.hp-laptop` · `sam.governance` · emit `hp-laptop.primary` :8000 · Claude Desktop / Cowork, hp-laptop · skills: `moos-state-readback`, `moos-workspace-ingest`, `moos-session-context-projection`, `moos-tooling-dx`, `moos-round-close`, `moos-cross-persona-audit`, `moos-rewrite-envelope`. Multi-workspace → explicit `session_urn`. Cross-persona audit + round-close authority.

**Guido** — laptop VS Code lead (T247 re-home). `vscode.hp-laptop.copilot` · `sam.laptop-vscode-lead` · emit `hp-laptop.primary` :8000 · VS Code / Copilot, hp-laptop · skills: `moos-state-readback`, `moos-session-context-projection`, `moos-tooling-dx`. Governance work routes to John Lydon.

**HP ProDesk** — bootstrap/setup lane. `vscode.hpprodesk.primary` · `sam.hpprodesk-setup` · emit `hpprodesk.primary` :8000 ONLY (never cross-emit to laptop/Z440) · VS Code or Claude Code, ProDesk · skills: `moos-state-readback`, `moos-tooling-dx`, `moos-session-context-projection`, `moos-rewrite-envelope`. Validate `Test-MoosFederation.ps1 -Mode VerifyPersona -Persona hpprodesk-vscode`.

---
authored-by: agent:vscode.hpprodesk.primary / session:sam.hpprodesk-setup / t262-harness-diet
