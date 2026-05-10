# T190 Z440 Windows 11 Session Desktops

**T-day:** T=190  
**Date:** 2026-05-10  
**Kernel/session:** `hp-z440.primary` / `session:sam.z440-vscode-projection-lead` for Desktop 1  
**Runtime readback:** local dry-run saw `http://localhost:8000/healthz` and `http://localhost:9000/healthz` healthy  
**Lane:** Windows 11 startup surface for mo:os sessions

## Executive status

Z440 now has the first local scaffold for starting Windows 11 in the same session shape it was closed in. The design treats Windows virtual desktops as a human-facing projection surface over durable mo:os sessions.

The important practical result is Desktop 1. It is mapped to `urn:moos:session:sam.z440-vscode-projection-lead` and launches the four-monitor VS Code projection cockpit: VS Code on `ffs0.code-workspace`, the session pipeline dashboard in Chrome, Explorer at the generated projection artifacts, and a terminal rooted at `D:\HPZ440\ffs0`.

## What landed

New manifest:

- `dev/config/z440-session-desktops.json`

New launcher:

- `dev/scripts/ops/Start-Z440SessionDesktops.ps1`

Updated autostart registration:

- `dev/scripts/ops/setup-autostart-z440.ps1`

Updated ops documentation:

- `dev/scripts/ops/README.md`

The old scheduled-task shape launched Antigravity, VS Code, Chrome, and Claude as separate logon tasks. The new shape keeps federation as its own task and gives app startup to one session-aware task: `moos-session-desktops-autostart`.

## Session and occupancy reading

The current map is:

| Windows desktop | mo:os session | Intended work surface |
| --- | --- | --- |
| Desktop 1 | `session:sam.z440-vscode-projection-lead` | VS Code projection cockpit and dashboard review |
| Desktop 2 | `session:sam.kernel-proper` | Kernel/runtime implementation |
| Desktop 3 | `session:sam.steinberger-seat` | Tooling, router, MCP, and DX work |
| Desktop 4 | `session:sam.karpathy-seat` | Categorical, HDC/VSA, and lens reasoning |
| Desktop 5 | `session:sam.moos-diary` | Diary, multimodal, and observation lane |

This does not make the desktop the truth source. The desktop is an OS surface. The durable identity remains the session URN, actor URN, kernel URN, and graph scope.

## Surface and identity reading

Windows 11 is useful here because it already has a Task View model that Sam can visually close and reopen. The mo:os addition is to name each desktop by session, so the visual habit has a graph identity behind it.

There is one honest W11 limitation. This Z440 does not currently have a `VirtualDesktop` PowerShell module or PowerToys install available. Windows 11 itself does not expose a stable built-in PowerShell API for placing windows on virtual desktops. Because of that, the launcher intentionally starts only Desktop 1 apps today. It records Desktop 2+ as the session map, and it is ready to use a compatible virtual-desktop helper later.

## Deferred items

- Install and test a compatible `VirtualDesktop` PowerShell module or a PowerToys workspace flow before enabling automatic Desktop 2+ placement.
- Tune Desktop 1 app set after observing the next real login; the manifest is the place to add or remove apps.
- Decide whether Windows desktop/session names should later be represented as HG `view_filter` or `channel` carriers.
- Keep this as a local OS projection. Do not treat window position as HG truth.

## Validation

Dry-run command:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File D:\HPZ440\ffs0\dev\scripts\ops\Start-Z440SessionDesktops.ps1 -DryRun -HealthWaitSeconds 3 -LaunchDelaySeconds 0
```

Dry-run result:

- Local primary health OK at `http://localhost:8000/healthz`.
- Local router health OK at `http://localhost:9000/healthz`.
- Virtual desktop helper absent, so Desktop 1-only safety behavior engaged.
- Desktop 1 session resolved as `urn:moos:session:sam.z440-vscode-projection-lead`.
- Planned launches: VS Code workspace, Chrome dashboard, Explorer projection artifacts, Windows Terminal at `D:\HPZ440\ffs0`.
