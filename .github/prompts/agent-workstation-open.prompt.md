---
agent: "moos-workstation-operator"
description: "Use when opening or refreshing a mo:os VS Code/Copilot workstation session on hp-laptop, Z440, or HP ProDesk."
---

# mo:os Agent Workstation Open

You are opening a VS Code/Copilot agent session on a mo:os workstation. Treat the IDE conversation as S0 substrate and hydrate from live repo/HG state.

## First Screen

1. Read `kb/superset/running-state.md`.
2. Read `.github/copilot-instructions.md` and `.github/instructions/agent-workstation.instructions.md`.
3. Snapshot repo state without changing branches:
   ```powershell
   git -C . status --short --branch
   git -C ../moos-kernel status --short --branch
   git -C ../moos-router status --short --branch
   ```
4. Check local runtime:
   ```powershell
   Invoke-RestMethod http://localhost:8000/healthz | ConvertTo-Json -Depth 8
   Invoke-RestMethod http://localhost:9000/healthz | ConvertTo-Json -Depth 8
   ```
5. Inspect `.vscode/mcp.json` if it exists and `.vscode/mcp.json.example` without printing secrets.

## Session Context

- hp-laptop governance in this VS Code/Copilot surface: `agent:vscode.hp-laptop.copilot`, `session:sam.governance`, MCP `moos-hp-laptop-primary`.
- hp-laptop legacy Claude Code actor: `agent:claude-code.hp-laptop`; treat it as inactive unless live process/readback and WF19 occupancy say otherwise.
- Z440 VS Code lead: `agent:vscode.hp-z440.primary`, `session:sam.z440-vscode-projection-lead`, MCP `moos-primary`.
- HP ProDesk setup: `agent:vscode.hpprodesk.primary`, `session:sam.hpprodesk-setup`, MCP `moos-hpprodesk-primary`.

Use `dev/config/session-affordance-map.json` for planned skills/prompts/MCP affordances, but trust live HG/running-state over stale config.
Opening readback must distinguish HG occupant, IDE harness surface, S0 conversation staging, and mounted tools before reporting an active actor.
Legacy `moos-config` or local `Downloads` inspection belongs in an ignored `*.local.code-workspace`, not the portable workspace.

## Useful VS Code Tasks

- `Moos: Doctor`
- `Moos: Verify Guido Emit Target`
- `Moos: Run Session Pipeline`
- `Moos: Open Session Dashboard`
- `Ops: Local Federation Health`
- `Ops: Multi-Repo Git Snapshot`

## Guardrails

- Do not emit HG rewrites from a startup readback.
- Do not G-sync GitHub Project status until `HG URN` identity coverage is reliable.
- Do not model account owners as kernel `user` principals without explicit approval.
- Do not hardcode secrets in MCP, prompt, skill, workspace, or config files.
- Preserve local uncommitted workspace edits unless Sam asks to revert them.

## Closeout Report

Report branch/dirty state, kernel/router health, active session/actor, MCP servers touched, tasks run, and any deferred workstation-specific follow-up.
