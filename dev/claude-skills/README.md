# mo:os Claude skills

> Part of the mo:os `ffs0` workspace. Project SOT: `../../AGENTS.md`. Live state: `../../kb/superset/running-state.md`.

Canonical source-of-truth for the mo:os Claude skills. They live in git (here in `ffs0`) so any checked-out machine — Z440, hp-laptop — installs the same set. `~/.claude/skills/` holds the **active copy**; this directory is the **shared origin**. Keep the two in sync with `sync-claude-skills.ps1` (below).

These are user-scoped skills (no `plugin:` prefix). Claude Code auto-scans `~/.claude/skills/*/SKILL.md` at session start; Claude Desktop's Customizations panel picks them up on restart.

## Install / sync

```powershell
# from the ffs0 repo root, on any machine:
pwsh dev/scripts/sync-claude-skills.ps1
```

Copies every `dev/claude-skills/<skill>/` into `$env:USERPROFILE\.claude\skills\` (replacing existing copies), then lists the installed `moos-*` skills. For Claude Desktop's Customizations panel, fully quit and restart the app after syncing. Run it on each machine after pulling `ffs0`.

To confirm: open a new Claude Code conversation — the opening system-reminder lists available skills; the `moos-*` entries should appear. To bypass discovery entirely, point Claude at a path directly, e.g. `Run the instructions at ~/.claude/skills/moos-state-readback/SKILL.md`.

## Current skills (13)

Grouped by role; each `SKILL.md` carries its own trigger `description` (the authoritative when-to-use) — not restated here. Index also in `AGENTS.md`.

| Group | Skills |
|---|---|
| Authoring / ops | `moos-rewrite-envelope` · `moos-state-readback` · `moos-round-close` · `moos-running-state-validator` · `moos-cross-persona-audit` · `moos-workstation-operator` |
| Projection (F) / ingest (G) | `moos-session-context-projection` · `moos-workspace-ingest` (text) · `moos-multimodal-ingest` (binary) · `moos-github-project-bridge` |
| Seat lanes | `moos-categorical-research` (Karpathy) · `moos-tooling-dx` (Steinberger) · `moos-cowork-readback` (Cowork) |

## Adding a skill

Create `dev/claude-skills/<name>/SKILL.md` with YAML frontmatter (`name`, `description`) and a body:

```markdown
---
name: my-new-skill
description: When to trigger and what this skill does.
---

# My New Skill

Body ...
```

Commit + push, then re-run `sync-claude-skills.ps1` on each machine. The sync script enumerates directories, so a new skill is installed with no edits to this file or the script.
