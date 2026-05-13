# T190/T193 ffs0 Admin Trunk And Closeout Policy

**T-day:** T=190  
**Date:** 2026-05-10  
**Scope:** `ffs0`, `moos-kernel`, `moos-router`, sessions, workstations, and shared handoff docs  
**Decision:** `ffs0/main` is the normal admin/control trunk; runtime code uses engineering branches

**T193 correction:** Sam clarified that `ffs0` is a private KB/admin/dev-control repo, not the runtime product. It should not accumulate stale feature branches for ordinary setup prompts, running-state packets, inventory planners, or workstation handoffs. `moos-kernel` and `moos-router` remain the code repos with stricter branch discipline.

## Short rule

`ffs0/main` is the live admin trunk. `kb/superset/running-state.md`, `kb/moos-diary/`, shared prompts, setup packets, topology notes, and small validated dev helpers should land there when they are useful to the next workstation or session.

Branches in `ffs0` are exceptional. Use them only for unfinished work, untested/risky script changes, large reorganizations, unresolved identity/account semantics, or temporary conflict protection. Merge or fast-forward back to `main` quickly once verified.

## Why this is the rule

Running-state is the hot hydration card. The diary wrap-up is the slower readable packet. If they diverge across branches, a fresh IDE conversation can read the latest running-state without the report that explains it, or read a report without the hot endpoint/log facts. That is exactly the confusion we want to avoid.

So the invariant is:

```text
verified state fact -> running-state update
session arc / rationale -> moos-diary wrap-up
handoff mechanics -> prompt/apply record
all three travel together
```

## ffs0 policy

Use `ffs0/main` as the normal branch for private admin/control state:

- Running-state updates that describe live, verified runtime or repo state.
- Moos-diary/session wrap-ups that explain those updates.
- Shared prompts that another session needs immediately.
- Setup/checklist scripts and dry inventory planners with focused tests.
- Small apply records or review records that document already-applied HG batches.
- Tiny ops/topology doc fixes after live verification.

Create a temporary `ffs0` branch only when:

- You cannot finish and verify in one sitting.
- Editing scripts or projection pipelines without passing focused tests yet.
- Writing proposals whose semantics are not yet approved.
- Updating many files or touching generated artifacts.
- Protecting local workstation differences such as `ffs0.code-workspace` until they are made portable or intentionally left local.

Recommended ffs0 branch names:

- `hp-laptop/t190-<lane>`
- `z440/t190-<lane>`
- `<persona>/t190-<lane>` when the persona matters more than the workstation

Examples:

- `z440/t190-projection-finish`
- `guido/t190-project-urn-repair`
- `hp-laptop/t190-calendar-readback`

## Runtime repo policy

`moos-kernel` and `moos-router` are not diary/control-plane repos. Treat them as stricter engineering repos.

For `moos-kernel`:

- Runtime code changes branch first.
- Run focused tests before closing.
- Do not commit binaries.
- Keep `master` as the stable integration branch.

For `moos-router`:

- Routing behavior changes stay on a feature branch, currently `feat/type-map-routing` unless Sam says otherwise.
- Add or update router tests for route behavior.
- Docs-only address/readback fixes may be small, but still check whether the active branch or `master` is the intended target.

## Session and workstation policy

A session is not a git branch. A session is the HG occasion that carries purpose, occupant, kernel, and scope. A branch is only a transport for repo work.

Use the session in branch names, commit messages, and diary headings when it clarifies who should pick up the work. Use the workstation in branch names when local path or machine state matters.

Good closeout references name all three:

- Session: `session:sam.z440-vscode-projection-lead`.
- Workstation/kernel: `hp-z440.primary` or `hp-laptop.primary`.
- Repo branch/commit: `ffs0/main@<sha>` or `z440/t190-projection-finish@<sha>`.

## Collision policy

Before any commit or pull:

1. `git fetch --all --prune`.
2. Check `status --short --branch`.
3. If clean and behind, `pull --ff-only`.
4. If local WIP exists, do not reset. Branch or stash only with explicit intent.
5. If remote moved while you were working, re-read running-state and rebase or merge deliberately.

Never force-push shared coordination branches. If a push rejects, stop and rehydrate.

## Account and identity policy

Do not solve account topology by minting new authority-bearing users. Under the current ontology, `user:sam` is the human principal. Additional Gmail accounts, Git accounts, calendars, repositories, websites, DNS zones, and dashboards should enter first as `channel` surfaces owned by `group:sam` or `user:sam`.

IRL people such as Menno and Lola should not silently become kernel `user` principals. Model them through session names, groups, channels, knowledge items, or a future reviewed identity/personhood design.

## Practical closeout checklist

For a normal verified ffs0 admin packet:

1. Update `kb/superset/running-state.md` with the hot fact.
2. Add or update `kb/moos-diary/<tday>-<lane>-wrapup.md` when the work spans more than one sprint or changes handoff assumptions.
3. Update shared prompts, setup packets, or apply records if another session needs the handoff.
4. Commit those together on `ffs0/main` when verified.
5. Push immediately so other sessions can hydrate from the same branch.

For exceptional ffs0 WIP:

1. Branch only for the unresolved part.
2. Keep running-state updates provisional until verified.
3. Merge or fast-forward back to `main` after tests/readback pass.
4. Delete stale ffs0 feature branches once their content is on `main`.

This keeps the system boring in the right place: truth in logs, hydration on `ffs0/main`, rare ffs0 WIP branches, and runtime code behind engineering discipline.
