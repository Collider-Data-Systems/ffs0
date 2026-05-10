# T190 Z440 Projection Finish Pass

**T-day:** T=190  
**Date:** 2026-05-10  
**Kernel/session:** `hp-z440.primary` / `session:sam.z440-vscode-projection-lead`  
**Runtime readback:** Z440 primary `ontology_version=3.16.1`, `t_day=190`, `log_len=449`; hp-laptop primary `ontology_version=3.16.1`, `log_len=1160`  
**Lane:** Z440 VS Code finish pass for projection pipeline, branch hygiene, and handoff closure

## Executive status

The Z440 finish prompt from hp-laptop was executed and the remaining local WIP is now a pushed branch instead of an unprotected editor state. The branch is `z440/t190-projection-finish`; the first finish commit is `7488906 chore: finish z440 projection pipeline handoff`.

The important implementation result is that `dev/scripts/projections/run-session-pipeline.ps1` can now be run from Z440 exactly as the prompt says, with no extra session flags. The runner resolves the Z440 lead session and actor from live primary state, then uses the local router as the read-only projection surface when available. That preserves sovereign logs while still letting shared governance roots appear in generated graph artifacts.

## What landed

Files changed in the finish branch:

- `.github/prompts/z440-vscode-t190-finish-today.prompt.md` now notes that the no-argument runner should auto-bind the Z440 lead context.
- `dev/scripts/projections/run-session-pipeline.ps1` now detects Julia on either Z440 or hp-laptop, resolves session context from live state, accepts explicit overrides, and uses `http://localhost:9000` for Z440 read-only projection when the router is up.
- `ffs0.code-workspace` now uses `${userHome}/Downloads` and includes the clean `moos-router-feat-type-map-routing` worktree.
- `kb/superset/running-state.md` has a compact latest-state entry that points here for the fuller report.
- `kb/moos-diary/t190-z440-vscode-lead-handoff-wrapup.md` records the finish pass as the continuation of the hp-laptop handoff.

No HG rewrites were emitted by this finish pass, and no external writers were run.

## Session and occupancy reading

The ordinary agent identity for this lane is `urn:moos:agent:vscode.hp-z440.primary`, and the session is `urn:moos:session:sam.z440-vscode-projection-lead`. Because the agent can have more than one session context, explicit `session_urn` remains required for future agent-authored envelopes.

The runner itself does not emit envelopes. It reads state and writes local projection artifacts. It resolves the session from `http://localhost:8000`, then projects through `http://localhost:9000` when Z440 is the lead session. That means the session is still grounded on Z440 primary, while the graph views can see both sovereign logs through the router read model.

## Surface and identity reading

The finish pass sharpened the division between running-state and diary reports.

`running-state.md` should stay the hot hydration card: newest endpoint facts, current branch/commit pointers, gate counts, and the next thing an agent must not miss. It should not carry the entire story of why those facts matter.

`kb/moos-diary/` carries the slower session packet. This file is the fuller report for the Z440 finish pass, while `running-state.md` points here. That keeps future readers from digging through a giant running-state update to recover the operational arc.

Project #4 identity repair remains a separate external-surface task. The current known state from hp-laptop is 31/57 rows with populated `HG URN` fields. No board status G-sync should run until row identity coverage is reliable.

## Deferred items

- Keep the two pipeline warnings explicit until they are intentionally resolved: disconnected forced roots on the session-occasion visual lens, and pending/deferred Calendar-event recommendation rows.
- Continue Project #4 `HG URN` repair only for rows with one unambiguous graph identity.
- Decide later whether the repeated session/recommendation lens shapes should become durable `view_filter` carriers.
- Keep account additions as `channel` surfaces unless a reviewed identity/personhood design changes authority semantics.

## Validation

- Doctor: pass across five kernels on `ontology_version=3.16.1`; Z440 primary `log_len=449`, hp-laptop primary `log_len=1160`.
- `VerifyPersona -Persona z440-vscode-lead`: pass.
- T190 admin parity relations: all four present on Z440 primary.
- No-argument runner: selected `session:sam.z440-vscode-projection-lead`, actor `agent:vscode.hp-z440.primary`, Julia `C:\Users\hp\AppData\Local\Programs\Julia-1.12.6\bin\julia.exe`, projection read URL `http://localhost:9000`.
- Final session pipeline gate: `warn`, 18 pass, 2 warn, 0 fail.
- Dashboard: `tmp/projections/session_pipeline/index.html`.
- Git: branch `z440/t190-projection-finish` pushed to origin at `7488906` before this diary/running-state follow-up.