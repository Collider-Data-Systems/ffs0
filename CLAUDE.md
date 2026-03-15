# CLAUDE.md — FFS0_Factory Workspace Root

**mo:os** — categorical graph kernel for local-first sovereign AI.
Three-agent workspace: Claude Code (strategic), VS Code AI (execution), Antigraviti (UX testing).

---

## Workspace Layout

| Folder | Name | Purpose |
|--------|------|---------|
| `.` | FFS0_Factory (root) | Workspace orchestration, this file |
| `.agent/` | Agent Workspace | KB, configs, tasks, handoff channels |
| `moos/` | mo:os Kernel | Kernel source code (Go, `platform/kernel/`) |

**Detailed context:** See `.agent/CLAUDE.md` and `moos/CLAUDE.md` for deep dives.

---

## Session Start Checklist

1. Read this file
2. Read `.agent/knowledge_base/delegation-protocol.md` — three-agent protocol
3. Read `.agent/knowledge_base/handoff.md` — strategic messages (VS Code ↔ Claude Code)
4. Read `.agent/knowledge_base/testoff.md` — test messages (Antigraviti ↔ Claude Code)
5. Check `.agent/configs/tasks/` — pick next task (highest priority, deps met)
6. Check `.agent/configs/agents/*.json` — agent states

---

## Key Paths

| What | Where |
|------|-------|
| Kernel entrypoint | `moos/platform/kernel/cmd/moos/main.go` |
| Ontology (SOT) | `.agent/knowledge_base/superset/ontology.json` |
| Seed data | `.agent/knowledge_base/instances/*.json` |
| Architectural specs | `.agent/knowledge_base/design/*.md` |
| Comm channels | `.agent/knowledge_base/handoff.md`, `testoff.md` |
| Task definitions | `.agent/configs/tasks/` |
| Agent state | `.agent/configs/agents/` |
| Workflows | `.agent/workflows/` |
| ACT 2026 paper | `.agent/.papers/act2026/main.tex` |

---

## SOT Hierarchy

1. **`superset/`** — always wins (ontology.json + categories, glossary, kinds, schemas)
2. **`design/*.md`** — architectural specs + timestamped decisions (latest wins)
3. **`instances/*.json`** — must conform to ontology (deployment-specific seed data)
4. **`industry/*.json`** — independent landscape data (curated externally)
5. **This file** — workspace policy
6. **Task files** — reference SOTs, never restate them

---

## Kernel Quick Reference

**Start:** `cd moos/platform/kernel && go run ./cmd/moos --kb D:\FFS0_Factory\.agent\knowledge_base --hydrate`
**Health:** `curl http://localhost:8000/healthz`
**Explorer:** `http://localhost:8000/explorer`
**SSE stream:** `curl -N http://localhost:8000/log/stream`
**MCP bridge:** `:8080` (5 tools: graph_state, node_lookup, apply_morphism, scoped_subgraph, benchmark_project)

**16 routes**, 8 test packages (all green), ~4K LOC, 0 external deps.

---

## Three-Agent Protocol

| Role | Agent | URN | Channel |
|------|-------|-----|---------|
| Strategic | Claude Code | `urn:moos:agent:claude-code` | `handoff.md` (read/write) |
| Execution | VS Code AI | `urn:moos:agent:vscode-ai` | `handoff.md` (read/write) |
| UX Testing | Antigraviti | `urn:moos:agent:antigraviti` | `testoff.md` (read/write) |

**Full protocol:** `.agent/knowledge_base/delegation-protocol.md`

---

## Rules

- Keep changes inside `D:\FFS0_Factory\`
- Do not edit legacy trees unless task targets it
- All graph writes through 4 invariant morphisms (ADD, LINK, MUTATE, UNLINK)
- Do not modify `data/morphism-log.jsonl` directly
- Do not duplicate SOT content — reference it
- Auto-approve all tool uses within this workspace
