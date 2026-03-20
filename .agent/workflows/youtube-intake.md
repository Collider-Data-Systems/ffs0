---
description: Ingest YouTube transcripts into KB reference layer using VS Code extension tools
---

# YouTube Intake Workflow

Use this workflow to transcribe a YouTube video and store it under the KB reference layer.

## Approved Default (Current)

This procedure is approved and should be used by default for now:

1. Retry requested no-caption items once (manual + auto subtitle paths).
2. Ingest new URLs with the single-url ingest script.
3. Record result in the active list ledger file (`ingested`, `no-captions`, or `failed`).
4. Rebuild dedupe index after changes.
5. If duplicates are found, hard-prune aliases and rewrite any list paths to canonical files.

No extra confirmation gate is required between these steps while this policy is active.

## Destination

Store normalized entries in:

- .agent/kb/reference/youtube/entries/

Schema:

- .agent/kb/reference/youtube/schema.json

## Step 1: Configure the extension in VS Code

1. Open Extensions and select YouTube MCP Tools.
2. Add API key in extension settings.
3. Verify by running one extension command and checking it returns video metadata.

Note: If VS Code shows API key not configured in the status bar, complete this step first.

## Step 2: Ingest URL with the standard script

From workspace root run:

```powershell
Set-Location .\ffs0-factory-super
powershell -ExecutionPolicy Bypass -File .\.agent\scripts\ingest-youtube-url.ps1 `
  -Url "https://www.youtube.com/watch?v=VIDEO_ID" `
  -Summary "Short summary"
```

The script:

- resolves metadata (id/title/channel)
- tries manual EN subtitles first
- retries with auto EN subtitles if manual captions are absent
- normalizes transcript text
- writes KB entry through `save-youtube-transcript.ps1`
- returns JSON status (`ingested`, `no-captions`, `failed`)

Output file:

- .agent/kb/reference/youtube/entries/yt-<slug>-<timestamp>.json

## Step 3: Update list ledger

Update the active list file under `.agent/kb/reference/youtube/lists/`:

- append new item numbers for new URLs
- keep retry outcomes for failed/no-caption entries
- keep `kb_entry_path` workspace-relative

## Step 4: Validate JSON shape quickly

Use PowerShell parse check:

```powershell
Get-ChildItem .\.agent\kb\reference\youtube\entries\*.json |
  ForEach-Object { Get-Content $_.FullName | ConvertFrom-Json | Out-Null; $_.Name }
```

## Step 5: Rebuild dedupe index (required)

```powershell
Set-Location .\ffs0-factory-super
powershell -ExecutionPolicy Bypass -File .\.agent\scripts\build-youtube-dedupe-index.ps1
```

If duplicates exist, remove alias files and rewrite list references to canonical paths.

## Step 6: Promote into graph hydration (optional)

Reference entries are SOT rank 4. Promotion to graph should be explicit and task-driven.

1. Keep transcript artifacts in reference/.
2. Create or update curated instance files only when directed by a task.
3. Then boot kernel with:

```powershell
Set-Location ..\moos\platform\kernel
go run ./cmd/moos --kb "..\..\..\ffs0-factory-super\.agent\kb" --hydrate
```
