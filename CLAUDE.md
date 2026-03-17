# CLAUDE.md — FFS0_Factory Workspace Root

**mo:os** — categorical graph kernel for local-first sovereign AI.
Three-agent workspace: Claude Code (strategic), VS Code AI (execution), Antigraviti (UX testing).

---

## Workspace Layout

| Folder | Purpose |
|--------|---------|
| `.` | Workspace root |
| `.agent/` | KB, channels, tasks, cfg — see `.agent/CLAUDE.md` |
| `moos/` | Kernel source code (`platform/kernel/`) |

---

## Session Start

1. Read this file
2. Read `.agent/CLAUDE.md` — full operational protocol (channels, tasks, programs, paths)
3. Read `.agent/channels/leadoff.md` — latest Program 2 decision from Sam
4. Read `.agent/channels/handoff.md` — latest direction
5. Read `.agent/channels/testoff.md` — latest test status
6. Check `.agent/tasks/` — next task (highest priority, deps met)
7. Check `.agent/cfg/agents/*.json` — agent states

---

## Key Paths

| What | Where |
|------|-------|
| Kernel entrypoint | `moos/platform/kernel/cmd/moos/main.go` |
| Ontology (SOT) | `.agent/kb/superset/ontology.json` |
| Seed data | `.agent/kb/instances/*.json` |
| Architectural specs | `.agent/kb/design/*.md` |
| Channels | `.agent/channels/handoff.md`, `.agent/channels/testoff.md` |
| Tasks | `.agent/tasks/` |
| Agent config | `.agent/cfg/agents/` |
| Workflows | `.agent/workflows/` |
| ACT 2026 paper | `.agent/kb/reference/papers/act2026/main.tex` |

---

## SOT Hierarchy

1. **`kb/superset/`** — always wins
2. **`kb/design/*.md`** — latest timestamp wins
3. **`kb/instances/*.json`** — must conform to ontology
4. **`kb/industry/*.json`** — independent landscape data
5. **This file** — workspace policy
6. **Task files** — reference SOTs, never restate

---

## Kernel Quick Reference

**HP laptop:** `cd moos/platform/kernel && go run ./cmd/moos --kb "../../ffs0-factory-super/.agent/kb" --hydrate`
**z440:** `cd D:\FFS0_Factory\moos\platform\kernel && go run ./cmd/moos --kb "D:\FFS0_Factory\.agent\kb" --hydrate`
**Health:** `curl http://localhost:8000/healthz`
**Explorer:** `http://localhost:8000/explorer`
**MCP (SSE):** `:8080` | **MCP (stdio):** `moos --mcp-stdio`

---

## Three-Agent Protocol

| Role | Agent | Channel |
|------|-------|---------|
| Lead | Sam | `channels/leadoff.md` (rw) |
| Strategic | Claude Code | `channels/leadoff.md` (rw), `channels/handoff.md` (rw), `channels/testoff.md` (rw) |
| Execution | VS Code AI | `channels/handoff.md` (rw) |
| UX Testing | Antigraviti | `channels/testoff.md` (rw) |

Full protocol: `.agent/CLAUDE.md`

---

## Rules

- All graph writes through 4 invariant morphisms (ADD, LINK, MUTATE, UNLINK)
- Do not modify `data/morphism-log.jsonl` directly
- Do not duplicate SOT content — reference it
- Auto-approve all tool uses within this workspace
