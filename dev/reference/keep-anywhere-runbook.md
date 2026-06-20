---
agent: "moos-workstation-operator"
description: "Use when: making all Google Keep notes (personal + Workspace) readable on every device — Android and any workstation, including Claude Desktop — via a Keep→Drive mirror read through the Drive MCP, plus optional live Keep MCP. Both accounts."
---

# Keep Anywhere

Make **all Keep notes (personal gmail + `mtdc.nl` Workspace) readable on any device** — Android,
Z440, laptop, ProDesk, and **Claude Desktop**. Keep is the one Google app with no clean
cross-device API, so the design uses **Drive as the unifier**.

## Why this shape
- Personal gmail has **no official Keep API** — only unofficial `gkeepapi` (master token).
- Workspace has the **official Keep API** (service account + domain-wide delegation) — already
  plumbed (`dev/scripts/google_keep_fetch.jl`, `Invoke-KeepIngestHarness.ps1`, see
  `keep-ingest-runbook.md`).
- An **MCP server runs on a workstation, not on Android.** So "any device" can't come from an MCP;
  it needs a device-independent store. **Drive** is on every device *and* already has an MCP.

## Architecture — two layers
1. **Any-device (Android included): Keep → Drive mirror.** A scheduled job on **Z440** (always at
   home) fetches both accounts and syncs Markdown/JSON to a Drive folder `keep-mirror/`. Android
   reads it in the Drive app; Claude Desktop reads it via the **Drive MCP**; so does the ffs0
   session.
2. **Live (Claude Desktop, optional): a Keep MCP.** For real-time personal-account access, add a
   community gkeepapi Keep MCP to `claude_desktop_config.json`. Convenience, not the backbone.

## The pieces (in this repo)
| File | Role |
|---|---|
| `dev/scripts/keep_personal_fetch.py` | personal account → Markdown (gkeepapi, master token) |
| `dev/scripts/ops/Invoke-KeepDriveMirror.ps1` | orchestrator: personal + workspace → `keep-mirror/` → `rclone` to Drive |
| `dev/scripts/ops/Invoke-KeepIngestHarness.ps1` | existing Workspace official-API fetch (reused) |
| `dev/config/claude_desktop_config.example.json` | Claude Desktop MCP config (Drive + optional Keep) |
| `secrets/keep_personal.env.example` | template for the personal master token (real file gitignored) |

## Setup (once, on Z440)
1. **Personal token.** `pip install gkeepapi gpsoauth`. Obtain a **master token** once (see the
   header of `secrets/keep_personal.env.example`), then `cp secrets/keep_personal.env.example
   secrets/keep_personal.env` and fill `KEEP_EMAIL` + `KEEP_MASTER_TOKEN`. The real `.env` is
   gitignored — **never commit or paste it**.
2. **Workspace.** Already configured per `keep-ingest-runbook.md` (service account
   `moos-keep-ingest@…`, delegated subject `sam@my-tiny-data-collider.nl`, scope `keep.readonly`).
3. **rclone.** `rclone config` → add a Drive remote named `gdrive` for the account that owns the
   `keep-mirror` folder (your personal Drive is simplest — it's what Android + the Drive MCP see).
4. **Run it:**
   ```pwsh
   pwsh -File dev/scripts/ops/Invoke-KeepDriveMirror.ps1 -DriveRemote gdrive:keep-mirror
   # personal-only smoke test, no push:
   pwsh -File dev/scripts/ops/Invoke-KeepDriveMirror.ps1 -SkipWorkspace -SkipUpload
   ```
5. **Schedule** (Z440 Task Scheduler, hourly): the same command. Z440 is the only box that needs to
   run it; the others just read Drive.

## Read it from Claude Desktop (any box)
Copy the `google-drive` block from `dev/config/claude_desktop_config.example.json` into your real
`claude_desktop_config.json` (Windows `%APPDATA%\Claude\`), authenticate the Drive MCP, and ask
Claude to read the `keep-mirror/` folder. Optionally add the `google-keep-personal` block for live
access. (Claude Desktop config is **strict JSON** — drop the `_comment` keys.)

## Android
Nothing to install: the **Drive app** shows `keep-mirror/` once the Z440 job has run. (This is the
"on my Android as well" path — it does not depend on an MCP.)

## Per-box
- **Z440** — runs the scheduled mirror (always home). The source of truth for the sync.
- **laptop** — reads Drive via Claude Desktop; can also run the mirror if Z440 is off.
- **ProDesk** — on dispatch only; just reads Drive, never needs the job.

## Caveats (read before wiring)
- **Master token = password.** Lives only in `secrets/keep_personal.env` (gitignored). If it leaks,
  revoke via Google account security.
- **gkeepapi is unofficial** and can break when Google changes auth — the Drive mirror keeps your
  notes available even when the live path breaks.
- **Vet any third-party Keep MCP** before installing — it runs with your Google credentials. Prefer
  one whose source you can read.
- **Workspace ≠ personal.** Two accounts, two credential paths; they converge only at the Drive
  folder. Decide which account's Drive hosts `keep-mirror/` (personal recommended — widest reach).
