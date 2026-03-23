# YouTube Reference Artifacts

This folder stores YouTube transcript artifacts in normalized JSON form.

## Layout

- schema.json: JSON schema for one transcript artifact
- entries/: individual transcript entries
- lists/: source-list tracking with per-item status and kb_entry_path
- dedupe-index.json: canonical/alias duplicate report

## Standard intake flow (approved)

1. Run the standard ingest script for a URL.
2. Update the active list ledger with status and path.
3. Rebuild dedupe index.
4. If duplicates are present, hard-prune aliases and rewrite list paths.

## Ingest command

```powershell
Set-Location .\ffs0-factory-super
powershell -ExecutionPolicy Bypass -File .\.agent\scripts\ingest-youtube-url.ps1 `
  -Url "https://www.youtube.com/watch?v=VIDEO_ID" `
  -Summary "Short summary"
```

The script returns JSON with status fields suitable for list updates.

## Legacy/manual entry path

1. Extract transcript text with your VS Code YouTube extension/tool.
2. Save transcript text to a local file.
3. Run script:

```powershell
Set-Location .\ffs0-factory-super
.\.agent\scripts\save-youtube-transcript.ps1 `
  -Url "https://www.youtube.com/watch?v=VIDEO_ID" `
  -Title "Video title" `
  -Channel "Channel name" `
  -Language "en" `
  -TranscriptFile ".\tmp\transcript.txt" `
  -Summary "Short summary" `
  -Keywords "mcp","hydration","ontology"
```

## Promotion rule

Keep these files in reference/ until a directed task promotes selected data into instance files for hydration.
