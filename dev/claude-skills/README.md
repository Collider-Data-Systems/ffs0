# mo:os claude-code skills

Shared Claude Code skills for the mo:os workspace. Live here so any machine checked out of ffs0 can install them locally.

## Install — two separate places, depending on which Claude surface

Claude has two skill-discovery mechanisms and they are **not** linked:

| Surface | How it finds skills | Where they live |
|---|---|---|
| **Claude Code runtime** (CLI, IDE plugin, claude-code chat) | Auto-scans `~/.claude/skills/*/SKILL.md` at session start; enumerates available skills in the session context | `~/.claude/skills/<skill-name>/SKILL.md` |
| **Claude Desktop — Customize > Skills panel** | Shows only skills registered through its own UI flow ("Create skill", "Upload a skill", "Create with Claude"). Does NOT auto-scan the filesystem. | Separate internal location that the Desktop app manages |

**Implication**: dropping files into `~/.claude/skills/` is enough for Claude Code to use them, but **not enough** to make them appear in the Customize panel. Both may be useful. Pick based on how you work.

### Option A — filesystem drop (Claude Code runtime)

Sufficient if you only need the skills to auto-trigger in claude-code sessions:

```bash
# PowerShell / Git Bash (Windows)
cp -r dev/claude-skills/moos-state-readback "$USERPROFILE/.claude/skills/"
cp -r dev/claude-skills/moos-round-close     "$USERPROFILE/.claude/skills/"
cp -r dev/claude-skills/moos-rewrite-envelope "$USERPROFILE/.claude/skills/"
```

On Linux / macOS: `~/.claude/skills/` is the destination.

**Test it worked**: open a new claude-code conversation. The opening system-reminder lists available skills. Your three moos-* entries should appear (no `plugin:` prefix — they're personal/filesystem-scanned).

If they don't appear in the session's available-skills list, Claude Code isn't discovering them for some reason (plugin conflict, version quirk, etc.) — fall back to Option B.

### Option B — UI registration (Claude Desktop Customize panel)

Needed if you want the skills visible in Customize > Skills panel, or if Option A isn't working:

1. Open Claude Desktop.
2. Customize > Skills.
3. Click `+` > **Upload a skill**.
4. Point at `dev/claude-skills/<skill-name>/SKILL.md` (or the whole directory if the dialog accepts folders). Repeat for each of the three.

After registering, the panel shows them under "Personal skills" with Added by / Last updated metadata. They're now invokable via slash command and auto-triggered per the `description`.

### Explicit invocation always works

Whatever the discovery state, you can always point Claude at a skill by path:

```
Run the instructions at ~/.claude/skills/moos-state-readback/SKILL.md
```

That bypasses discovery entirely. Use when a skill won't auto-trigger or auto-list.

## Current skills

| Skill | Purpose |
|---|---|
| `moos-state-readback` | 10-sec open-of-round check: `git fetch` + log-range + running-state header + kernel PID/port + MCP `/healthz` + peer-handoff issue comments |
| `moos-round-close` | End-of-round checklist: running-state update + atomic commit + push + optional issue comment |
| `moos-rewrite-envelope` | Envelope-shape cheat sheet for `mcp__moos-kernel__apply_program` (field names, placement gotchas, additive vs standard MUTATE, PropertySpec rules) |
| `moos-workstation-operator` | Workstation operator (Claude twin of `.github/agents/moos-workstation-operator.agent.md`): repo + runtime readback, MCP/session-context projection, IDE/affordance setup, multi-workstation handoff |

> Note: the table above is illustrative, not exhaustive — `dev/claude-skills/` currently holds 13 skill directories; browse the folder for the full set.

## Adding a new skill

```bash
mkdir -p dev/claude-skills/my-new-skill
# Write dev/claude-skills/my-new-skill/SKILL.md with YAML frontmatter:
#   ---
#   name: my-new-skill
#   description: When to trigger and what this skill does.
#   ---
#
#   # My New Skill
#
#   Body ...
```

Commit + push. Install locally per above. Any machine pulling ffs0 and running the install step picks it up.

## Why not `.claude/skills/` at ffs0 root?

Claude Code auto-discovers skills from **home-dir** `~/.claude/skills/`, not from project-local paths. These skills are user-scoped config, not repo-scoped. The `dev/claude-skills/` location here is the **shared source-of-truth**; `~/.claude/skills/` is the **active copy**. Keep the two in sync via the install command above.
