---
description: "Use when setting up or reviewing multi-workstation git flow, local-vs-portable paths, and branch handoff between machines."
---

# Multi-Workstation Git Flow

Use `ffs0/main` as the coordination trunk for verified state packets, and use normal git branches for WIP, substantial edits, and runtime code. Keep machine-specific customization local.

The durable policy lives at `kb/moos-diary/t190-session-branch-and-closeout-policy.md`.

## Coordination Trunk Rule

`kb/superset/running-state.md` and `kb/moos-diary/` should travel together. When a session closes a verified state change, commit the running-state update, diary wrap-up, prompt/apply records, and small handoff docs together on the same branch.

If the packet is verified, small, and needed by other sessions now, that branch should normally be `ffs0/main`.

Use a branch first when the work is unfinished, touches scripts/workspace files substantially, changes runtime code, proposes ontology/account semantics, or may collide with another workstation.

## Scope Split

- `C:\Users\maass\HPlaptop\.github` is workstation-local customization.
- `ffs0/.github` is repository-shared customization and travels with branches.

## Portable In Branches

- `kb/`
- `dev/`
- `.github/instructions/`
- `.github/hooks/`
- `.github/prompts/`
- `.vscode/mcp.json.example`
- source and docs

## Verified Direct-To-Main In ffs0

- Hot running-state updates backed by live readback.
- Moos-diary/session wrap-ups that explain those updates.
- Shared prompts needed by another workstation/session immediately.
- Apply records for already-approved and already-verified HG batches.
- Tiny topology/docs corrections after verification.

## Branch First

- Projection pipeline or script implementation work.
- Workspace file changes such as `ffs0.code-workspace`.
- Large doc reorganizations.
- Account/person/identity proposals.
- Any `moos-kernel` runtime code change.
- Any `moos-router` route behavior change.

Suggested branch names:

- `hp-laptop/t<N>-<lane>`
- `z440/t<N>-<lane>`
- `<persona>/t<N>-<lane>` when the persona matters more than the machine

Examples: `z440/t190-projection-finish`, `guido/t190-project-urn-repair`, `hp-laptop/t190-calendar-readback`.

## Local Only

- `C:\Users\maass\HPlaptop\.github\skills`
- `secrets/` (except approved templates/docs)
- ephemeral logs/state under `data/` and `dev/`

## Runtime Repos

- `moos-kernel`: branch before code changes; run focused tests; never commit binaries; keep `master` as stable integration.
- `moos-router`: keep routing work on the active feature branch unless Sam says otherwise; route behavior changes need tests.

## Session/Branch Distinction

A session is not a git branch. A session is the HG occasion: purpose, occupant, host kernel, and scope. A branch is just repo transport. Name sessions in commit bodies, diary reports, and branch names when that helps the next agent hydrate.

## Basic Handoff Commands

For verified ffs0 coordination packets:

1. `git switch main`
2. `git fetch --all --prune`
3. `git pull --ff-only`
4. Edit running-state, diary wrap-up, prompts/apply records together.
5. `git add <paths>`
6. `git commit -m "docs: <summary>"`
7. `git push`

For WIP or implementation branches:

1. `git switch main`
2. `git fetch --all --prune`
3. `git pull --ff-only`
4. `git switch -c <workstation-or-persona>/t<N>-<lane>`
5. `git add <paths>`
6. `git commit -m "<type>: <summary>"`
7. `git push -u origin HEAD`
8. On next workstation: `git fetch` then `git switch <branch-name>`

If a push rejects, stop and rehydrate. Do not force-push shared coordination branches.
