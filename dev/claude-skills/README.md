# mo:os claude-code skills

Shared Claude Code skills for the mo:os workspace. Live here so any machine checked out of ffs0 can install them locally.

## Install

Claude Code reads skills from `~/.claude/skills/<skill-name>/SKILL.md` (on Windows: `C:\Users\<you>\.claude\skills\`). Copy each skill's directory there:

```bash
# PowerShell / Git Bash (Windows)
cp -r dev/claude-skills/moos-state-readback "$USERPROFILE/.claude/skills/"
cp -r dev/claude-skills/moos-round-close     "$USERPROFILE/.claude/skills/"
cp -r dev/claude-skills/moos-rewrite-envelope "$USERPROFILE/.claude/skills/"
```

On Linux / macOS: `~/.claude/skills/` is the destination.

Once copied, the skill auto-triggers on matching prompts — Claude Code discovers it from the frontmatter `description`. No restart needed for a new conversation; existing conversations won't pick up the skill until you start a new one.

## Current skills

| Skill | Purpose |
|---|---|
| `moos-state-readback` | 10-sec open-of-round check: `git fetch` + log-range + running-state header + kernel PID/port + MCP `/healthz` + peer-handoff issue comments |
| `moos-round-close` | End-of-round checklist: running-state update + atomic commit + push + optional issue comment |
| `moos-rewrite-envelope` | Envelope-shape cheat sheet for `mcp__moos-kernel__apply_program` (field names, placement gotchas, additive vs standard MUTATE, PropertySpec rules) |

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
