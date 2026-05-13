---
description: "Use when setting up or reviewing ffs0 trunk-first admin flow, multi-workstation paths, and runtime repo branch discipline."
---

# ffs0 Trunk-First Admin Flow

Use `ffs0/main` as the normal working branch for private admin/control state. `ffs0` stores KB, running-state, prompts, handoff packets, projection planners, operator reports, and local setup docs. It is not the runtime product repository. Avoid feature-branch ceremony here unless work is genuinely unfinished, risky, or conflicting.

Use normal engineering branches in `moos-kernel` and `moos-router`, because those are the runtime codebases downloaded and run by workstations.

The durable policy lives at `kb/moos-diary/t190-session-branch-and-closeout-policy.md`.

## ffs0 Main Rule

`ffs0/main` is the live admin trunk. When a verified admin packet is useful to the next workstation or session, land it on `main` and push it promptly.

These belong on `main` by default:

- `kb/superset/running-state.md` hydration updates.
- `kb/moos-diary/` wrap-ups and policy notes.
- Shared prompts under `.github/prompts/`.
- Setup/checklist scripts and dry inventory planners with tests.
- Reviewed topology/readback docs and apply records.
- Small operational fixes that make the next workstation hydrate correctly.

Branches in `ffs0` are exceptional. Use one only when the work cannot be finished and verified in the current sitting, may break the projection pipeline, has unresolved semantics, or must preserve conflicting local workspace state.

## Scope Split

- `C:\Users\maass\HPlaptop\.github` is workstation-local customization.
- `ffs0/.github` is repository-shared customization and travels with branches.

## Portable In ffs0

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
- Setup/checklist scripts and dry planners with focused validation.
- Apply records for already-approved and already-verified HG batches.
- Tiny topology/docs corrections after verification.

## ffs0 Branch Only When

- The work is unfinished and you must leave the machine.
- A script or projection change is not yet tested.
- A large doc reorganization may collide with another workstation.
- Account/person/identity semantics are unresolved.
- A workspace file such as `ffs0.code-workspace` is machine-sensitive and not yet made portable.
- You need a temporary conflict shelf while syncing from another workstation.

Suggested branch names:

- `hp-laptop/t<N>-<lane>`
- `z440/t<N>-<lane>`
- `<persona>/t<N>-<lane>` when the persona matters more than the machine

Examples: `z440/t190-projection-finish`, `guido/t190-project-urn-repair`, `hp-laptop/t190-calendar-readback`. Merge or fast-forward these back to `main` quickly once verified; do not keep stale ffs0 feature branches around as alternate truth lanes.

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

For normal ffs0 admin packets:

1. `git switch main`
2. `git fetch --all --prune`
3. `git pull --ff-only`
4. Edit running-state, diary wrap-up, prompts, setup packets, or apply records together.
5. `git add <paths>`
6. `git commit -m "docs: <summary>"`
7. `git push`

For exceptional ffs0 WIP branches:

1. `git switch main`
2. `git fetch --all --prune`
3. `git pull --ff-only`
4. `git switch -c <workstation-or-persona>/t<N>-<lane>`
5. `git add <paths>`
6. `git commit -m "<type>: <summary>"`
7. `git push -u origin HEAD`
8. On next workstation: `git fetch` then `git switch <branch-name>` only if the branch is intentionally still WIP.

After verification, fast-forward or merge the packet back to `main`, push `main`, and delete the stale branch.

If a push rejects, stop and rehydrate. Do not force-push shared coordination branches.
