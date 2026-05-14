---
description: "Use when configuring VS Code, Copilot, Claude Desktop, Antigravity, MCP servers, workspace files, prompts, skills, or multi-workstation agent sessions."
applyTo: "{**/*.code-workspace,**/.vscode/**,**/.github/prompts/**,**/.github/instructions/**,dev/claude-skills/**,dev/config/**}"
---

# Agent Workstation Rules

## Source Of Truth

- Read `kb/superset/running-state.md` before changing IDE, MCP, prompt, skill, or workstation configuration.
- Folded HG state and live `/healthz` readback outrank old bootstrap docs.
- `dev/config/session-affordance-map.json` and `dev/config/moos-federation.topology.json` are projection configs, not HG truth.

## Current hp-laptop Shape

- Local emit target: `moos-hp-laptop-primary` / `http://localhost:8080/sse`.
- Local HTTP kernel: `http://localhost:8000`.
- Local router: `http://localhost:9000`.
- Current governance session: `urn:moos:session:sam.governance`.
- Current agent actor: `urn:moos:agent:claude-code.hp-laptop` unless a task explicitly names another occupant.

## VS Code Agent Surface

- Treat VS Code chat sessions as S0 substrate. If a conversation matters beyond the live IDE, project or chunk it before treating it as durable state.
- Keep repository-wide rules in `.github/copilot-instructions.md`.
- Use scoped `.github/instructions/*.instructions.md` for task or file-family rules.
- Use `.github/prompts/*.prompt.md` for repeatable operator handoffs.
- Use `dev/claude-skills/*/SKILL.md` as the shared source for Claude Code skills; sync to `~/.claude/skills/` for active Claude Code discovery.

## MCP Rules

- Workspace MCP config uses `.vscode/mcp.json` with top-level `servers`.
- Root `.mcp.json` is legacy/non-VS Code client config; VS Code agent sessions use `.vscode/mcp.json` / `.vscode/mcp.json.example`.
- Prefer native VS Code server entries (`type: "sse"` or `type: "http"`) for mo:os endpoints.
- Do not add the remote GitHub Copilot MCP endpoint manually unless its auth path is verified in the current VS Code build; use the built-in GitHub/Copilot integration or `gh` CLI for GitHub work.
- Do not hardcode secrets. Use environment variables for Cloudflare Access headers and local secret stores for OAuth tokens.
- Keep `.vscode/mcp.json` machine-specific and ignored; update `.vscode/mcp.json.example` when the portable shape changes.
- Keep emit-target and opens-on distinct until twin sync lands. Z440 Menno/Lola endpoints are topology/future direct endpoints; current Z440 persona emits still target primary.

## Multi-Repo Workspace

- `ffs0.code-workspace` should contain the portable active repo roots: `ffs0`, `moos-kernel`, and `moos-router`.
- Do not add throwaway worktrees or secret folders to the tracked workspace file.
- Put local-only expansions such as `Downloads`, temporary worktrees, or legacy `moos-config` inspection in an ignored `*.local.code-workspace` file.
- Use VS Code tasks for repeatable readback: Doctor, persona verification, health, multi-repo status, and the session pipeline.

## Validation

- After config edits, check JSON/MCP syntax and run `git diff --check`.
- If the change affects projection work, run `Moos: Run Session Pipeline` or `dev/scripts/projections/run-session-pipeline.ps1` when feasible.
- Report any local-only edits explicitly, especially ignored `.vscode/mcp.json` changes.
