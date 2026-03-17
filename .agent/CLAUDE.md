# CLAUDE.md — Agent Workspace

**mo:os** — categorical graph kernel. `state(t) = fold(log[0..t])`. 4 invariant NTs: ADD, LINK, MUTATE, UNLINK.
**Goal:** ACT 2026 paper → arXiv → open-source release (MIT).

---

## Triangle

| Role | Agent | Channel | Scope |
|------|-------|---------|-------|
| Lead | Sam | `channels/leadoff.md` (rw) | Superset, paper, KB design, research direction |
| Strategic | Claude Code | `channels/leadoff.md` (rw), `channels/handoff.md` (rw), `channels/testoff.md` (rw) | Plans, KB, paper, delegation |
| Execution | VS Code AI (GPT-5.3-Codex) | `channels/handoff.md` (rw) | Implements, tests, commits, pushes |
| UX Testing | Antigraviti (Gemini 3.1 Pro) | `channels/testoff.md` (rw) | HTTP tests, browser tests |

**Star topology.** No direct agent-to-agent. All routing through Claude Code + Sam.
`leadoff.md` is the source — all programs derive from it. KB>KER>HG>PRG starts here.

---

## Session Start

**Claude Code:**
1. Read `cfg/state/session-state.json` — instant cycle position + open items
2. Read `channels/leadoff.md` top message — Program 2 decisions from Sam
3. Read `channels/handoff.md` top message
4. Read `channels/testoff.md` top message
5. Check `tasks/` — next task (highest priority, deps met)
6. Check `cfg/agents/*.json` — agent states

**Session End (Claude Code):**
Update `cfg/state/session-state.json` with: cycle_position, last task, leadoff_top, channel tops, kernel state, open items.

**VS Code AI:**
1. Read `cfg/agents/vscode-ai.json` — status + last task
2. `cd ../moos && git pull origin main`
3. Read `channels/handoff.md` — direction from Claude Code
4. Update `cfg/agents/vscode-ai.json` — status: active
5. Verify kernel: `go run ./cmd/moos --kb "../ffs0-factory-super/.agent/kb" --hydrate`

**Antigraviti:**
1. Read `cfg/agents/antigraviti.json` — status + test plan
2. Read `channels/testoff.md` — direction from Claude Code
3. Update `cfg/agents/antigraviti.json` — status: active
4. HP laptop: kernel at `localhost:8000` accessible via browser

---

## Programs

**Program 1 — KB Hydration (triangle CI/CD):**
`Sam + Claude Code → task in tasks/ → direction in channels/ → VS Code implements → Antigraviti tests → repeat`

KBKERHGPRG: US (conversation) → KB (commits) → KER (kernel fold) → HG (hypergraph topology) → PRG (agent execution)

**Program 2 — Superset + Paper + Research:**
Sam + Claude Code only. Channel: `channels/leadoff.md`. Outputs feed Programs 1 and 3 as KB updates, new tasks, or research-tasks.
Active: ACT 2026 paper (`kb/reference/papers/act2026/main.tex`), ontology (`kb/superset/ontology.json`), data pipeline (`kb/design/20260317-data-pipeline.md`).

**Program 3 — Research Pipeline (VS Code as harvester):**
Claude Code posts `research-task` to `handoff.md` with query, output_path, output_schema.
VS Code uses arxiv/YouTube tools → scrapes → structured JSON → `kb/industry/` or `kb/reference/`.
Posts `research-result` → Claude Code reviews → if approved → `hydration-task` → VS Code materializes.

---

## Channels

- `channels/leadoff.md` — Sam ↔ Claude Code. Prepend, newest top. Types: `think` | `decide` | `question` | `answer` | `blocked` | `complete`
- `channels/handoff.md` — Claude Code ↔ VS Code AI. Prepend, newest top.
- `channels/testoff.md` — Claude Code ↔ Antigraviti. Prepend, newest top.
- **Format:** `### [YYYY-MM-DD HH:MM] Source → type: subject`
- **Types:** `complete` | `blocked` | `question` | `answer` | `direction` | `test-plan` | `test-result` | `research-task` | `research-result` | `hydration-task` | `hydration-complete`
- **Timestamps:** real wall-clock only — run `Get-Date` (PowerShell) or `date` (bash) first

---

## Task Convention

- **Files:** `tasks/YYYYMMDD-NNN-name.md`
- **Owned by:** Claude Code + Sam — no autonomous task selection
- **Commit format:** `feat|fix|chore: <description> [task:YYYYMMDD-NNN]`
- **After commit:** push, post `complete` to channel, update agent state file

---

## Key Paths

| What | Path |
|------|------|
| Channels | `.agent/channels/handoff.md`, `.agent/channels/testoff.md` |
| Tasks | `.agent/tasks/` |
| KB root (`--kb` flag) | `.agent/kb/` |
| Ontology (SOT #1) | `.agent/kb/superset/ontology.json` |
| Instances | `.agent/kb/instances/*.json` |
| Design docs | `.agent/kb/design/*.md` |
| Reference | `.agent/kb/reference/` |
| Agent state files | `.agent/cfg/agents/*.json` |
| VS Code instructions | `.agent/cfg/copilot-instructions.md` |
| Antigraviti instructions | `.agent/cfg/antigraviti-instructions.md` |
| Workflows | `.agent/workflows/` |
| Paper | `.agent/kb/reference/papers/act2026/main.tex` |
| Kernel entrypoint | `moos/platform/kernel/cmd/moos/main.go` |

---

## Kernel Quick Reference

**HP laptop:**
```
cd moos/platform/kernel
go run ./cmd/moos --kb "../../ffs0-factory-super/.agent/kb" --hydrate
```
**z440:**
```
cd D:\FFS0_Factory\moos\platform\kernel
go run ./cmd/moos --kb "D:\FFS0_Factory\.agent\kb" --hydrate
```
**Health:** `curl http://localhost:8000/healthz`
**Explorer:** `http://localhost:8000/explorer`
**SSE stream:** `curl -N http://localhost:8000/log/stream`
**MCP (SSE):** `:8080` — 5 tools: graph_state, node_lookup, apply_morphism, scoped_subgraph, benchmark_project
**MCP (stdio):** `moos --mcp-stdio` — same 5 tools over stdin/stdout (Task 028)

16 routes, 8 test packages (all green), ~4K LOC, 0 external deps.

---

## SOT Hierarchy

1. `kb/superset/` — always wins
2. `kb/design/*.md` — latest timestamp wins
3. `kb/instances/*.json` — must conform to ontology
4. `kb/industry/*.json` — independent landscape data
5. This file
6. Task files — reference SOTs, never restate

---

## Sprint

| Week | Status | Deliverable |
|------|--------|-------------|
| 1 | Done | Kernel surface, hydration |
| 2 | Done | Scoped projections, MCP bridge, benchmark functor |
| 3 | Done | Explorer UI, ACT paper draft, demo |
| 4 | Active | v0.1.0, arXiv, CI, docs, community |

Tasks 001–031 complete. Task 032 pending Sam direction (Program 2: ACT paper, research pipeline). See `channels/leadoff.md` for latest.

---

## Rules

- No autonomous task selection — Claude Code + Sam govern all tasks
- All graph writes through 4 invariant NTs: ADD, LINK, MUTATE, UNLINK
- Zero external Go dependencies (stdlib only)
- Do not duplicate SOT content — reference it
- No direct agent-to-agent communication
- Real timestamps only — no fabricated times
- Auto-approve all tool uses within this workspace
