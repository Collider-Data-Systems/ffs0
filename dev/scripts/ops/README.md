# Ops Scripts

> Part of the mo:os `ffs0` workspace. Project SOT: `../../../AGENTS.md`. Live state: `../../../kb/superset/running-state.md`.

Operational PowerShell helpers for local kernel/federation, the Windows-11 session-desktop projection, GitHub-issue coordination, and Keep ingest. Run scripts with `pwsh` (PowerShell 7+), not Windows PowerShell 5.1 (5.1 `ConvertFrom-Json` corrupts comment-list JSON).

## Scripts

| Script | Purpose |
| --- | --- |
| `Test-MoosFederation.ps1` | Doctor / Start / VerifyPersona / PostProgram helper for the local federation + per-persona MCP surface. Reads `dev/config/moos-federation.topology.json` + `.vscode/mcp.json`. |
| `ops-snapshot.ps1` | Local readback: per-repo git status + `/healthz` for the fleet. |
| `Start-Z440SessionDesktops.ps1` | Idempotent Windows-11 startup launcher for the 14-desktop x 4-monitor Z440 placement cache. |
| `New-Z440SurfaceCache.ps1` | Generates the local HTML/JSON placement view under `tmp/projections/z440_surface_cache/`. |
| `setup-autostart-z440.ps1` | Registers Z440 logon tasks (federation + session desktops). Elevated. |
| `setup-user-autostart-z440.ps1` | Registers/removes the current-user HKCU surface startup fallback without elevation. |
| `start_federation_laptop.ps1` | hp-laptop primary-kernel launcher (`:8000` / MCP `:8080`). No secondaries on laptop. |
| `Watch-GitHubIssue.ps1` | Profile-aware GitHub-issue watcher / conservative auto-ack for coordination threads. |
| `Sync-ProjectBoard.ps1` | mo:os board (org project #4) operator: Audit (read-only, default) / Attach / Sweep (`-Apply` to mutate). No HG rewrites. Runbook: `dev/runbooks/github-org-operations.md`. |
| `Invoke-KeepIngestHarness.ps1` | Google Keep clipboard/API capture + staging harness. Runbook: `dev/runbooks/keep-ingest-runbook.md`. |

`__init__.py` is a vestigial Python package marker; the `t*.json` / `t*.md` / `r15-*` files are dated replay/reference payloads (T173–T206). Older one-shot Python emitters live in `dev/archive/scripts/legacy-emitters/`.

## Z440 session desktops

The Z440 human workspace is a local S0 projection cache over durable HG anchors. The tracked manifest `dev/config/z440-session-desktops.json` records the 14 live Windows desktop GUIDs, observed names, four physical monitor slots, app windows, and browser tab sets. GUID is the stable local key; desktop index, name, coordinates, and tabs are rebuildable placement state, not HG identity.

Desktops 1-6 represent local or remote engine/workstation rooms. Desktops 7-14 represent manifold, access-posture, administration, or reference rooms. Reference desktops are explicitly not authority-bearing HG objects. Each browser window begins with its generated cache page, which serves as the group label and placement summary; Chrome native tab-group mutation is deliberately not required.

Install the pinned current-user desktop provider once, then preview:

```powershell
Install-PSResource -Name VirtualDesktop -Version 1.5.11 -Scope CurrentUser -Repository PSGallery -TrustRepository
pwsh -NoProfile -ExecutionPolicy Bypass -File dev\scripts\ops\Start-Z440SessionDesktops.ps1 -DryRun
```

The launcher resolves each desktop by GUID, reconciles its display name, preserves an existing matching app window on that desktop, launches only missing windows, places new windows on their configured monitors, and returns to the desktop that was active when it started. Useful operator modes:

```powershell
# Generate only the inspectable local cache.
pwsh -NoProfile -File dev\scripts\ops\New-Z440SurfaceCache.ps1

# Repair monitor placement for matching windows without opening duplicates.
pwsh -NoProfile -File dev\scripts\ops\Start-Z440SessionDesktops.ps1 -RepositionExisting

# Limit a manual check to the primary room.
pwsh -NoProfile -File dev\scripts\ops\Start-Z440SessionDesktops.ps1 -Desktop1Only
```

Register persistence only from an elevated PowerShell 7 terminal:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File dev\scripts\ops\setup-autostart-z440.ps1
```

The installer detects a standard session and opens the normal Windows Administrator approval prompt itself; no separate Run as Administrator shell is required. It points `moos-kernel-autostart` at the tracked federation launcher, creates `moos-session-desktops-autostart`, retires the old one-app tasks, and archives the three April-era Startup-folder federation batches under `D:\HPZ440\tmp\startup-disabled-t264`.

When the current terminal is not elevated, the user-scope installer provides an immediate reversible fallback through `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`:

```powershell
pwsh -NoProfile -File dev\scripts\ops\setup-user-autostart-z440.ps1
# Remove only that current-user entry:
pwsh -NoProfile -File dev\scripts\ops\setup-user-autostart-z440.ps1 -Remove
```

It also archives the duplicate Startup-folder federation batches. It cannot retire administrator-owned legacy app tasks; the elevated installer remains the convergence path for those four tasks.

## GitHub issue watcher

Lightweight workstation coordination only: reads comments, tracks a profile high-water mark under `tmp/issue-watch/`, can post conservative auto-acks. It does not emit HG rewrites, touch DNS/Cloudflare/secrets, write Calendar/Workspace state, or edit the repo. Profiles: `z440-vscode-lead`, `hp-laptop-governance`.

```powershell
# Z440 VS Code lead
pwsh -NoProfile -ExecutionPolicy Bypass -File dev\scripts\ops\Watch-GitHubIssue.ps1 -Issue 54 -Profile z440-vscode-lead -IntervalSeconds 180 -AutoReply -Watch

# hp-laptop governance, with redacted cloudflared readback
pwsh -NoProfile -ExecutionPolicy Bypass -File dev\scripts\ops\Watch-GitHubIssue.ps1 -Issue 54 -Profile hp-laptop-governance -IntervalSeconds 180 -AutoReply -CloudflaredReadback -Watch
```
