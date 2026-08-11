---
agent: "moos-seat-hydration"
description: "Use when: ingesting Google Keep notes from API, Takeout, browser clipboard, or manual exports into the mo:os T190-T208 review-only staging lane from any agent harness."
---

# Keep Ingest Any Harness

You are the agent responsible for moving Google Keep notes or loose-thought exports into the mo:os review pipeline. This prompt is harness-neutral: VS Code/Copilot, Claude Desktop, Claude Code, Antigravity, Cursor, or a terminal runner should all follow the same contract.

## Identity

- Default session: `urn:moos:session:sam.governance`
- Default actor on hp-laptop VS Code/Copilot: `urn:moos:agent:vscode.hp-laptop.copilot`
- Source channel: `urn:moos:channel:google.keep.sam`
- Runtime: `http://localhost:8000`
- Dashboard: `tmp/projections/session_pipeline/index.html`

Before emitting any HG rewrite, verify live `/healthz`, actor/session liveness, and folded occupancy. A Keep note visible in the browser is S0 source material until it has a local source artifact and a stage report.

Use existing graph/projection state first:

- Reuse `urn:moos:session:sam.governance` as the active hp-laptop governance session unless live session context says otherwise.
- Reuse `urn:moos:channel:google.keep.sam` as the Keep source channel; do not create a second Keep channel.
- Reuse `urn:moos:program:sam.t206.keep-api-mvp-delivery`, `urn:moos:ki:gdrive.t206-keep-api-mvp-status`, and `urn:moos:external_op:sam.t206-google-keep-oauth-scope-approval` as the existing T206 process/status carriers.
- Read `tmp/projections/session_pipeline/session_context/current_session.json`, `tmp/projections/session_pipeline/mvp/session_pipeline_gate.json`, and `tmp/projections/session_pipeline/graph_artifacts/t206_keep_mvp_engineering.json` before deciding what a new harness needs.
- Add new nodes only for approved source-note content or a genuinely new derivation/claim/program; otherwise add missing valid relations to existing nodes.
- As of T208, Workspace DWD/API Keep source acquisition works for Workspace-visible notes and preserves attachment metadata, but the source boundary still holds: do not invent or assert Keep note content unless it came from a local Takeout ZIP/folder, official API export, clipboard/manual export, or other explicit source artifact. Keep staged material remains review-only with `apply_ready=false` until Sam chunks/approves it.

## Source Acquisition

Use exactly one source path per pass:

- `ApiFetch`: use the official Google Keep API path when live credentials are present; the current successful path is Workspace domain-wide delegation/keyless signing for Workspace-visible notes.
- `Stage`: use a local Google Takeout ZIP/folder, JSON file, HTML file, Markdown file, or plain text file.
- `ClipboardStage`: ask Sam to select/copy notes from the Google Keep web UI, then capture the clipboard into `scratch/keep/t195-t206/manual/` and stage it.

Do not infer note text from a screenshot. Do not use unofficial browser storage scraping as durable evidence. Do not print OAuth secrets or token contents.

## Modes, Relations, Skills

Use these runner modes:

- `Check`: runtime and OAuth readiness readback.
- `Check`: runtime, ontology/session anchors, current projections, and OAuth readiness readback.
- `Stage`: local Takeout/export folder or file to review artifact.
- `ClipboardStage`: copied Keep note text to local S0 source artifact, then review artifact.
- `ApiAuthListen`: official OAuth loopback for Keep once Google Cloud permits the scope.
- `ApiFetch`: official Keep API to normalized local JSON plus review artifact.
- `Pipeline`: regenerate the projection dashboard after staging.

Use these HG relation families only after Sam approves a structured stage report:

- `WF12 provides-kb/kb-source`: `channel:google.keep.sam` to approved `knowledge_item` evidence.
- `WF18 composes/composed-by`: approved program to its reviewed KI/derivation carriers.
- `WF19 pins-urn/pinned-by-session`: governance or deliberately seated scoped session to the staged carriers.
- `WF21 causes/caused-by`: source KI or derivation to reviewed derivation/claim/program outcomes.

Emit `WF07 anchors/anchor` for Calendar source anchors only after live runtime health shows an ontology that declares the pair and the row is part of an explicit reviewed apply program. Do not link `external_op` through `WF18` or `WF21`; pin it with `WF19` when it is only a follow-up action.

Ontology guardrails:

- `WF12` is the evidence/hydration relation; it permits `channel -> knowledge_item` and `knowledge_item -> claim` evidence flow.
- `WF18` is program/purpose composition; it permits `program -> knowledge_item`, `program -> program`, `program -> session`, `program -> purpose`, and `program -> channel` composition.
- `WF19` is session governance; use `pins-urn` for workspace scope, `has-occupant` for occupancy, and `has-purpose` for session purpose. Do not rotate occupancy from this prompt.
- `WF21` is acyclic causality between derivation/claim/KI/program carriers; never create a causal cycle.
- `external_op` is an action boundary. Treat it as a pinned follow-up, not as evidence or a causal proof.

Load or honor these skills when the harness supports skills:

- `moos-state-readback` for live runtime/session readback.
- `moos-workspace-ingest` for Google Workspace / Keep source chunking discipline.
- `moos-session-context-projection` for harness handoff and dashboard projection.
- `moos-tooling-dx` for cross-harness runner and prompt wiring.
- `moos-rewrite-envelope` before any reviewed apply program.
- `moos-cross-persona-audit` after durable state-doc or round-close changes.

## Commands

From `c:\Users\maass\HPlaptop\ffs0`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File dev\scripts\ops\Invoke-KeepIngestHarness.ps1 -Mode Check
```

For the browser currently open to Google Keep, ask Sam to select the relevant notes or open a note, copy the note text, then run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File dev\scripts\ops\Invoke-KeepIngestHarness.ps1 -Mode ClipboardStage -RunPipeline
```

For a Takeout/export folder or file:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File dev\scripts\ops\Invoke-KeepIngestHarness.ps1 -Mode Stage -SourcePath scratch\keep\t195-t206 -RunPipeline
```

For a Takeout ZIP:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File dev\scripts\ops\Invoke-KeepIngestHarness.ps1 -Mode Stage -SourcePath scratch\keep\t195-t206\takeout.zip -RunPipeline
```

For official API fetch with the live Workspace DWD/API path or another verified Keep credential:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File dev\scripts\ops\Invoke-KeepIngestHarness.ps1 -Mode ApiFetch -RunPipeline
```

If the default Keep OAuth client is absent but Calendar OAuth exists and the Google Cloud project has Keep enabled:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File dev\scripts\ops\Invoke-KeepIngestHarness.ps1 -Mode ApiAuthListen -UseCalendarOAuthClient -OpenBrowser
```

Historical T207 readback: the Calendar-client loopback reuse path reached Google and failed with `Error 400: invalid_scope` for `https://www.googleapis.com/auth/keep.readonly`. That remains provenance for the OAuth-client path only; do not let it override the T208 Workspace DWD/API source path when live readback shows delegated fetch working.

## Review Boundary

The runner writes:

- `tmp/projections/session_pipeline/keep_t206/google_keep_credential_check.json`
- `tmp/projections/session_pipeline/keep_t206/google_keep_fetch_result.json`
- `tmp/projections/session_pipeline/keep_t206/keep_t195_t206_stage.json`
- `tmp/projections/session_pipeline/keep_t206/keep_t195_t206_stage.md`

The stage report is intentionally `apply_ready=false`. Only create or post a `dev/scripts/ops/` HG apply program after Sam explicitly approves the structured source artifact. If the stage finds zero selected T195-T206 notes, report the source acquisition gap and do not emit an empty/raw-note apply program. Treat WF07 Calendar `anchors/anchor` rows as a separate reviewed apply surface once the live runtime has loaded the repaired operad declaration.

## Closeout

Report the source mode, selected note count, skipped/duplicate rows, theme buckets, attachment counts, candidate node/relation counts, dashboard path, credential path used, and whether the staged artifact remains `apply_ready=false`.