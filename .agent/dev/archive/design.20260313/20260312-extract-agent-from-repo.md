# Design: Extract `.agent` from Git Repo

**Date:** 2026-03-12  
**Status:** Ready for execution  
**Task:** chore [task:20260312-008]

---

## Problem

The `.agent/` directory inside `moos/` contains private workspace assets (knowledge base, agent configs, sprint tasks, skill libraries) that should never be pushed to the public GitHub repo. Currently `knowledge_base/` and `configs/` ARE tracked in git. After a `git clone`, these would land in the cloned repo — leaking internal design docs, handoff notes, sprint plans, and API provider configs.

`.agent/skills/` is already gitignored but should be covered by the broader rule.

---

## Decision

Move the entire `.agent/` directory to `D:\FFS0_Factory\.agent\` — a sibling of `moos\`, mirroring the `.claude\` folder that already lives there. The kernel's `--kb <path>` flag is fully runtime-configurable so **zero Go code changes** are needed.

Target layout:

```
D:\FFS0_Factory\
  .claude\          ← already here
  .agent\           ← moved here (was inside moos\)
    knowledge_base\
      superset\
        ontology.json
      doctrine\
      design\
      instances\
      ...
    configs\
      tasks\
  moos\             ← git repo (clean, no .agent/ content)
```

---

## Implementation Plan

### Phase A — Untrack from git

```powershell
cd d:\FFS0_Factory\moos
git rm -r --cached .agent/
```

Removes git tracking only; leaves files on disk.

### Phase B — Update `.gitignore`

Replace the three fragmented skill-only rules:

```
# OLD (fragmented)
.agent/skills/
.agents/skills/
**/.agent/skills/
skills/
```

With two broader rules:

```
# NEW (clean)
.agent/
.agents/
```

### Phase C — Physical move

```powershell
robocopy "d:\FFS0_Factory\moos\.agent" "d:\FFS0_Factory\.agent" /E /COPYALL
```

Verify `D:\FFS0_Factory\.agent\knowledge_base\superset\ontology.json` exists, then:

```powershell
cd d:\FFS0_Factory\moos\platform\kernel
go run ./cmd/moos --kb "D:\FFS0_Factory\.agent\knowledge_base" --hydrate
```

Only after passing: delete `d:\FFS0_Factory\moos\.agent\`

### Phase D — Create `kb-starter/` template

Create `platform/kernel/examples/kb-starter/` with:

- `superset/ontology.json` — the 21-kind/16-morphism ontology (no internal docs)
- `superset/schema.json` — copy of current schema
- `instances/README.md` — "Add your instance models here"
- `README.md` — explains `--kb /path/to/your/kb` for new cloners

### Phase E — Update docs

- `CLAUDE.md` → Key Paths: mark `superset/ontology.json` as external, path `D:\FFS0_Factory\.agent\knowledge_base\superset\ontology.json`
- `README.md` → update `--kb` example to generic external path, link to `kb-starter/`

### Phase F — Commit

```
chore: extract .agent from repo — KB now external [task:20260312-008]
```

---

## What's Tracked Today (must be untracked)

```
.agent/configs/api_providers.yaml
.agent/configs/tasks/20260312-001-kb-aware-boot.md
.agent/configs/tasks/20260312-002-instance-hydration-flow.md
.agent/configs/tasks/20260312-003-instance-gap-fill.md
.agent/configs/tasks/20260312-004-schema-validation.md
.agent/configs/tasks/20260312-005-week1-verification.md
.agent/configs/users.yaml
.agent/configs/workspace_defaults.yaml
.agent/knowledge_base/**   (archive/, design/, doctrine/, superset/, instances/, etc.)
```

`.agent/skills/` is already gitignored — no git rm needed, just physical copy.

---

## Verification Checklist

1. `git ls-files .agent/` → empty
2. `git status` → `.agent/` untracked (not staged)
3. Kernel starts: `go run ./cmd/moos --kb D:\FFS0_Factory\.agent\knowledge_base --hydrate`
4. `git push --dry-run` → no `.agent/` content included

---

## Constraints

- **Do not** delete `moos\.agent\` before step C verify passes
- **Do not** modify any `.go` files — `--kb` is already runtime-configurable
- `skills/` needs no `git rm` — already gitignored; just robocopy it
