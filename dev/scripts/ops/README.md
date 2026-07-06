# Ops Scripts

> Part of the mo:os `ffs0` workspace. Project SOT: `../../../AGENTS.md`. Live state: `../../../kb/superset/running-state.md`.

Operational PowerShell helpers for local kernel/federation, the Windows-11 session-desktop projection, GitHub-issue coordination, and Keep ingest. Run scripts with `pwsh` (PowerShell 7+), not Windows PowerShell 5.1 (5.1 `ConvertFrom-Json` corrupts comment-list JSON).

## Scripts

| Script | Purpose |
|---|---|
| `Test-MoosFederation.ps1` | Doctor / Start / VerifyPersona / PostProgram helper for the local federation + per-persona MCP surface. Reads `dev/config/moos-federation.topology.json` + `.vscode/mcp.json`. |
| `ops-snapshot.ps1` | Local readback: per-repo git status + `/healthz` for the fleet. |
| `Start-Z440SessionDesktops.ps1` | Windows-11 startup launcher mapping virtual desktops to mo:os sessions via `dev/config/z440-session-desktops.json`. |
| `setup-autostart-z440.ps1` | Registers Z440 logon tasks (federation + session desktops). Elevated. |
| `start_federation_laptop.ps1` | hp-laptop primary-kernel launcher (`:8000` / MCP `:8080`). No secondaries on laptop. |
| `Watch-GitHubIssue.ps1` | Profile-aware GitHub-issue watcher / conservative auto-ack for coordination threads. |
| `Sync-ProjectBoard.ps1` | mo:os board (org project #4) operator: Audit (read-only, default) / Attach / Sweep (`-Apply` to mutate). No HG rewrites. Runbook: `dev/reference/github-org-operations.md`. |
| `Invoke-KeepIngestHarness.ps1` | Google Keep clipboard/API capture + staging harness. Runbook: `dev/reference/keep-ingest-runbook.md`. |

`__init__.py` is a vestigial Python package marker; the `t*.json` / `t*.md` / `r15-*` files are dated replay/reference payloads (T173–T206). Older one-shot Python emitters live in `dev/reference/research-archive/scripts/legacy-emitters/`.

## Z440 session desktops

The Z440 human workspace is a Windows projection (S0 surface) of durable mo:os sessions. Desktop→session map: `dev/config/z440-session-desktops.json` (Desktop 1 = VS Code projection lead, 2 = kernel-proper, 3 = Steinberger seat, 4 = Karpathy seat, 5 = moos-diary).

Dry preview, then register logon tasks (elevated):

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File dev\scripts\ops\Start-Z440SessionDesktops.ps1 -DryRun
pwsh -NoProfile -ExecutionPolicy Bypass -File dev\scripts\ops\setup-autostart-z440.ps1
```

Windows 11 has no stable built-in virtual-desktop placement API. Without a compatible `VirtualDesktop` module the launcher only starts Desktop 1 and leaves Desktop 2+ as the authoritative session map; install one to let the manifest create/switch desktops before launch.

## GitHub issue watcher

Lightweight workstation coordination only: reads comments, tracks a profile high-water mark under `tmp/issue-watch/`, can post conservative auto-acks. It does not emit HG rewrites, touch DNS/Cloudflare/secrets, write Calendar/Workspace state, or edit the repo. Profiles: `z440-vscode-lead`, `hp-laptop-governance`.

```powershell
# Z440 VS Code lead
pwsh -NoProfile -ExecutionPolicy Bypass -File dev\scripts\ops\Watch-GitHubIssue.ps1 -Issue 54 -Profile z440-vscode-lead -IntervalSeconds 180 -AutoReply -Watch

# hp-laptop governance, with redacted cloudflared readback
pwsh -NoProfile -ExecutionPolicy Bypass -File dev\scripts\ops\Watch-GitHubIssue.ps1 -Issue 54 -Profile hp-laptop-governance -IntervalSeconds 180 -AutoReply -CloudflaredReadback -Watch
```
