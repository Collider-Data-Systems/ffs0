# T207 Keep Source Acquisition And Calendar Lock Sprint

Date: 2026-05-27 CEST

Session: `urn:moos:session:sam.governance`

Actor: `urn:moos:agent:vscode.hp-laptop.copilot`

Kernel: `urn:moos:kernel:hp-laptop.primary`

Runtime readback: `ontology_version=3.16.2`, `t_day=207`, `log_len=1467`

## Outcome

Sam approved moving the T195-T206 raw Keep lane from postponed into structured staging, but the source boundary remains active. No raw Keep note content was available locally in the requested T-window, and the official Google Keep API path is still blocked externally by Google's OAuth consent/scope layer.

No HG rewrites were emitted and no external Calendar writes were performed in this sprint.

## Keep Source Readback

- `Invoke-KeepIngestHarness.ps1 -Mode Check` confirmed the known T206 anchors and credential state.
- No `secrets/google_keep_oauth_client.json` or `secrets/google_keep_token.json` is present.
- `secrets/google_calendar_oauth_client.json` and `secrets/google_calendar_token.json` are present.
- `Invoke-KeepIngestHarness.ps1 -Mode ApiAuthListen -UseCalendarOAuthClient -OpenBrowser` reached Google's OAuth page, then failed with `Error 400: invalid_scope` for `https://www.googleapis.com/auth/keep.readonly`.
- Local source scan found only the old T187 Keep text export under `scratch\keep`.
- Staging `scratch\keep` parsed 1 note, selected 0 T195-T206 notes, excluded the T183 row as outside the window, and kept `apply_ready=false`.

## Implementation

- Added direct Google Takeout ZIP support to `dev/scripts/keep_t195_t206_ingest_stage.jl`.
- ZIP members are extracted locally and tracked with stable source URLs shaped like `file://...takeout.zip#Takeout/Keep/<note>.json`.
- ZIP extraction prefers Windows `tar.exe`, with PowerShell Archive and `unzip` fallbacks.
- Added ZIP regression coverage to `dev/scripts/tests/test_keep_t195_t206_ingest_stage.jl`.
- Added live folded Calendar observation locks to `dev/scripts/calendar_time_fabric_projection.jl`.
- The session pipeline now passes `--base-url` into the Calendar planner so written-source locks can preserve existing applied Calendar event dates across T-day rollover.

## Validation

- Keep stager tests passed, including the new ZIP source testset.
- Calendar time-fabric tests passed, including written-source URN locks and written observation date preservation.
- Full session pipeline regenerated successfully: `pass`, 24 pass / 0 warn / 0 fail.
- Recommendation reconciliation converged: grouped nodes 10/10, grouped relations 16/16, Calendar event nodes 22/22, Calendar session pins 22/22, Calendar WF07 anchors 22/22, deferred relations 0.

## Deferred

- Google Cloud OAuth scope approval is still external. The owning project must allow `https://www.googleapis.com/auth/keep.readonly` before the official API can read notes.
- All-note processing can proceed immediately if Sam stages a real Google Takeout ZIP/folder, API export, clipboard/manual export, or equivalent local source artifact.
- Only after a stage report selects real T195-T206 notes and Sam approves the structured artifact should an HG apply program be generated.