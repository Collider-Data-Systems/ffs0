---
agent: "moos-workstation-operator"
description: "Use when: making all Google Keep notes readable on every device — Android and any workstation, including Claude Desktop — via a Keep→Drive mirror read through the Drive MCP. Primary account is the collider Workspace (official Keep API, signed in on all workstations); personal gmail is an optional fallback."
---

# keep-anywhere

Make **all Keep notes readable on any device** — Android, Z440, laptop, ProDesk, and **Claude
Desktop**. Keep is the one Google app with no clean cross-device API, so the design uses **Drive as
the unifier** (the only store already on every device *and* already MCP-wired).

## Accounts — Workspace is primary
- **Primary: the collider Workspace account** (Workspace plan, more capability, already signed in on
  all workstations). It has the **official Keep API** (service account + domain-wide delegation),
  already plumbed in `dev/scripts/google_keep_fetch.jl` + `dev/scripts/ops/Invoke-KeepIngestHarness.ps1`
  (see `dev/reference/keep-ingest-runbook.md`). This is the robust path and the default.
- **Optional fallback: personal gmail** — no official API, only unofficial `gkeepapi` (master
  token). Opt in with `-IncludePersonal`; skip it entirely if all the notes you want live on the
  Workspace account.

## Why Drive
An **MCP server runs on a workstation, not on Android** — so "any device" can't come from an MCP; it
needs a device-independent store. **Drive** is on every device (incl. the Android Drive app) *and*
already has a Claude MCP. So we mirror Keep → a Drive `keep-mirror/` folder and read that.

## Architecture
1. **Any-device mirror.** A scheduled job on **Z440** fetches the Workspace account (and personal if
   `-IncludePersonal`) and `rclone`-syncs Markdown/JSON to a Drive `keep-mirror/` folder on the
   **collider Workspace Drive**. Android reads it in the Drive app; Claude Desktop reads it via the
   Drive MCP; so does the ffs0 session.
2. **Live (optional).** A community gkeepapi Keep MCP in `claude_desktop_config.json` for real-time
   personal access — convenience, not the backbone.

## The pieces
| File | Role |
|---|---|
| `Invoke-KeepDriveMirror.ps1` | orchestrator: Workspace (default) + optional personal → `keep-mirror/` → `rclone` to Drive |
| `keep_personal_fetch.py` | optional personal-account fetch → Markdown (gkeepapi) |
| `claude_desktop_config.example.json` | Claude Desktop MCP config (Drive MCP + optional Keep MCP) |
| `dev/scripts/ops/Invoke-KeepIngestHarness.ps1` | existing Workspace official-API fetch (reused) |
| `secrets/keep_personal.env.example` | template for the optional personal master token (real file gitignored) |

## Setup (once, on Z440)
1. **Workspace** — already configured per `dev/reference/keep-ingest-runbook.md` (service account
   `moos-keep-ingest@…`, delegated subject `sam@my-tiny-data-collider.nl`, scope `keep.readonly`).
2. **rclone** — `rclone config` → a Drive remote named `gdrive` on the **collider Workspace Drive**
   (the account signed in on all your boxes), so `keep-mirror/` lands where every device sees it.
3. **Run it:**
   ```pwsh
   pwsh -File dev/scripts/keep-anywhere/Invoke-KeepDriveMirror.ps1 -DriveRemote gdrive:keep-mirror
   # add the personal account too:
   pwsh -File dev/scripts/keep-anywhere/Invoke-KeepDriveMirror.ps1 -IncludePersonal
   ```
4. **(optional) personal token** — only if using `-IncludePersonal`: `pip install gkeepapi gpsoauth`,
   then `cp secrets/keep_personal.env.example secrets/keep_personal.env` and fill `KEEP_EMAIL` +
   `KEEP_MASTER_TOKEN` (master token = password; the real `.env` is gitignored — never commit it).
5. **Schedule** (Z440 Task Scheduler, hourly). Z440 is the only box that runs it; the others read Drive.

## Read it from Claude Desktop (any box)
Copy the `google-drive` block from `claude_desktop_config.example.json` into your real
`claude_desktop_config.json` (Windows `%APPDATA%\Claude\`), authenticate the Drive MCP **to the
collider Workspace account**, and ask Claude to read `keep-mirror/`. (Claude Desktop config is
**strict JSON** — drop the `_comment` keys.)

## Android
Nothing to install: the **Drive app** (collider account) shows `keep-mirror/` once the Z440 job has
run. This is the "on my Android as well" path — it does not depend on an MCP.

## Per-box
- **Z440** — runs the scheduled mirror (always home); the source of truth for the sync.
- **laptop** — reads Drive via Claude Desktop; can run the mirror if Z440 is off.
- **ProDesk** — on dispatch only; just reads Drive.

## Caveats
- The Workspace path is the robust one. **gkeepapi (personal) is unofficial** and can break on
  Google auth changes — the Drive mirror keeps notes available even then.
- **Vet any third-party Keep MCP** before installing — it runs with your Google credentials.
- A gkeepapi **master token = password**; lives only in `secrets/keep_personal.env` (gitignored).
