# Ops Scripts

Operational scripts and payloads for local kernel/federation management.

Current operators:

- `Test-MoosFederation.ps1` — doctor/start/verify/post helper for the local federation task surface.
- `ops-snapshot.ps1` — local snapshot helper.
- `Watch-GitHubIssue.ps1` — profile-aware GitHub issue watcher/autoresponder for coordination threads such as `ffs0#54`.
- `setup-autostart-z440.ps1` — Z440 autostart helper.
- `Start-Z440SessionDesktops.ps1` — Windows 11 startup launcher that maps virtual desktops to mo:os sessions using `dev/config/z440-session-desktops.json`.
- `start_federation_laptop.ps1` — hp-laptop federation launcher.

## Z440 Windows 11 Session Desktops

The Z440 human workspace is treated as a Windows projection of durable mo:os sessions. The map lives in `dev/config/z440-session-desktops.json`:

- Desktop 1: `session:sam.z440-vscode-projection-lead` for the four-monitor VS Code projection cockpit.
- Desktop 2: `session:sam.kernel-proper` for kernel/runtime work.
- Desktop 3: `session:sam.steinberger-seat` for tooling, router, MCP, and DX work.
- Desktop 4: `session:sam.karpathy-seat` for categorical/HDC/VSA research.
- Desktop 5: `session:sam.moos-diary` for diary and multimodal work.

Run a dry startup preview:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File D:\HPZ440\ffs0\dev\scripts\ops\Start-Z440SessionDesktops.ps1 -DryRun
```

Register logon startup tasks from an elevated PowerShell:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File D:\HPZ440\ffs0\dev\scripts\ops\setup-autostart-z440.ps1
```

Windows 11 does not expose a stable built-in PowerShell API for virtual desktop placement. If no compatible `VirtualDesktop` PowerShell module is installed, the launcher starts only Desktop 1 apps and leaves Desktop 2+ as the authoritative session map. After installing a compatible helper, the same manifest can create/switch desktops before launching startup apps.

Historical JSON/Markdown payloads in this folder are retained as replay/reference artifacts. Older Python one-shot emitters were moved to `dev/reference/research-archive/scripts/legacy-emitters/`.

## GitHub Issue Watcher

Use the issue watcher for lightweight workstation coordination. It reads GitHub comments, tracks a profile-specific high-water mark under `tmp/issue-watch/`, and can post conservative auto-acknowledgements. It does not emit HG rewrites, change DNS/Cloudflare, handle secrets, write Calendar/Workspace state, or make repo edits.

Run it from Z440 VS Code lead:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File D:\HPZ440\ffs0\dev\scripts\ops\Watch-GitHubIssue.ps1 -Issue 54 -Profile z440-vscode-lead -IntervalSeconds 180 -AutoReply -Watch
```

Run it from hp-laptop governance with redacted cloudflared readback enabled:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File D:\HPZ440\ffs0\dev\scripts\ops\Watch-GitHubIssue.ps1 -Issue 54 -Profile hp-laptop-governance -IntervalSeconds 180 -AutoReply -CloudflaredReadback -Watch
```
