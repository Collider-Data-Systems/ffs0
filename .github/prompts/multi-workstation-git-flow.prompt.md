---
description: "Use when setting up or reviewing multi-workstation git flow, local-vs-portable paths, and branch handoff between machines."
---

# Multi-Workstation Git Flow

Use normal git branches to move portable state between workstations.
Keep machine-specific customization local.

## Scope Split

- `C:\Users\maass\HPlaptop\.github` is workstation-local customization.
- `ffs0/.github` is repository-shared customization and travels with branches.

## Portable In Branches

- `kb/`
- `dev/`
- `.github/instructions/`
- `.github/hooks/`
- `.github/prompts/`
- `.mcp.json`
- source and docs

## Local Only

- `C:\Users\maass\HPlaptop\.github\skills`
- `secrets/` (except approved templates/docs)
- ephemeral logs/state under `data/` and `dev/`

## Basic Handoff Commands

1. `git switch main`
2. `git pull`
3. `git switch -c chore/<scope>-<short-name>`
4. `git add <paths>`
5. `git commit -m "chore: <summary>"`
6. `git push -u origin HEAD`
7. On next workstation: `git fetch` then `git switch <branch-name>`
