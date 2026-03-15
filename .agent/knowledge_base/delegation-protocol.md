# Three-Agent Protocol v3

**Effective:** 2026-03-13 (runtime programming phase)
**Participants:** Claude Code (strategic), VS Code AI (execution), Antigraviti (testing)
**Topology:** Star (all routing through Claude Code hub)

---

## Workspace Layout

```
D:\FFS0_Factory\                         ← Workspace root
├── FFS0_Factory.code-workspace          ← Open this in VS Code / Antigraviti
├── .agent\                              ← Shared KB, configs, tasks (NOT in git)
│   ├── knowledge_base\                  ← Kernel --kb path
│   │   ├── superset\ontology.json       ← SOT #1 (21 kinds, 16 morphisms)
│   │   ├── instances\*.json             ← Seed data (15 files)
│   │   ├── design\*.md                  ← Architectural specs + decisions
│   │   ├── handoff.md                   ← Claude Code ↔ VS Code
│   │   ├── testoff.md                   ← Claude Code ↔ Antigraviti
│   │   └── delegation-protocol.md       ← This file
│   └── configs\
│       ├── agents\*.json                ← Agent state files
│       ├── tasks\*.md                   ← Task definitions
│       ├── copilot-instructions.md      ← VS Code session start
│       └── antigraviti-instructions.md  ← Antigraviti session start
├── .claude\                             ← Claude Code session state
└── moos\                                ← Git clone (public repo)
    └── platform\kernel\                 ← Kernel source code
```

---

## Agent Roles

### Claude Code (Strategic Lead)
- **IDE:** Claude Code CLI
- **URN:** `urn:moos:agent:claude-code`
- **Instructions:** Read this file + CLAUDE.md at session start
- **Responsibilities:**
  - Write all task definitions to `.agent/configs/tasks/`
  - Monitor `handoff.md` for VS Code completions
  - Monitor `testoff.md` for Antigraviti results
  - Update `.agent/configs/agents/*` state files
  - Audit morphism log: `GET /log?actor=<urn>&after=<time>`
  - Post strategic directions to handoff/testoff
  - Evolve paper, review code, manage release
- **Permissions:** Read/write all channels

### VS Code AI (Execution)
- **IDE:** VS Code (OpenAI Codex 5.3)
- **URN:** `urn:moos:agent:vscode-ai`
- **Instructions:** Read `.agent/configs/copilot-instructions.md` at session start
- **Responsibilities:**
  - Read task files from `.agent/configs/tasks/`
  - Implement, test, commit, push
  - Post completions to `handoff.md`
  - Update own state file: `.agent/configs/agents/vscode-ai.json`
  - Submit morphisms as actor `urn:moos:agent:vscode-ai`
- **Permissions:** Read tasks, write handoff, read-only on testoff

### Antigraviti (Testing)
- **IDE:** Antigraviti (Gemini 3.1 Pro / Gemini 3 Flash, headless browser + Playwright)
- **URN:** `urn:moos:agent:antigraviti`
- **Instructions:** Read `.agent/configs/antigraviti-instructions.md` at session start
- **Responsibilities:**
  - Read test plans from `testoff.md` and `.agent/configs/tasks/`
  - Execute browser test cases against live kernel
  - Post results (pass/fail, screenshots, perf metrics) to `testoff.md`
  - Update own state file: `.agent/configs/agents/antigraviti.json`
  - Submit test morphisms as actor `urn:moos:agent:antigraviti`
- **Permissions:** Read test plans, write testoff, read-only on handoff

---

## Communication: Three Layers

### Layer 1: Files (Durable Record)

| Channel | Between | Format | Message Types |
|---------|---------|--------|---------------|
| `handoff.md` | Claude Code ↔ VS Code | Markdown, newest on top | `complete` `blocked` `question` `answer` `direction` |
| `testoff.md` | Claude Code ↔ Antigraviti | Markdown, newest on top | `test-plan` `test-result` `blocked` `direction` |
| `configs/agents/*.json` | Each agent | JSON | Runtime state (status, current task, last commit) |

### Layer 2: SSE (Live Signal)

All agents can observe real-time morphism flow:
```bash
# Watch all morphisms live
curl -N http://localhost:8000/log/stream

# Each event is a PersistedEnvelope JSON with actor, type, timestamp
```

Explorer at `http://localhost:8000/explorer` shows LIVE MORPHISMS panel.

### Layer 3: Kernel Log (Audit Trail)

```bash
# All morphisms
curl http://localhost:8000/log

# Filter by actor
curl http://localhost:8000/log?actor=urn:moos:agent:vscode-ai

# Filter by type
curl http://localhost:8000/log?type=ADD

# Filter by time
curl http://localhost:8000/log?after=2026-03-13T12:00:00Z
```

**Principle:** Files = durable record, SSE = live signal, kernel log = audit trail. Three layers, not one replacing another.

---

## Kernel Interaction

### Starting the Kernel
```bash
cd D:\FFS0_Factory\moos\platform\kernel
go run ./cmd/moos --kb "D:\FFS0_Factory\.agent\knowledge_base" --hydrate
```

### Health Check
```bash
curl http://localhost:8000/healthz
# {"log_depth":148,"nodes":68,"status":"ok","wires":80}
```

### Submitting Morphisms (as your agent)
```bash
# ADD a node
curl -X POST http://localhost:8000/morphisms \
  -H "Content-Type: application/json" \
  -d '{
    "type": "ADD",
    "actor": "urn:moos:agent:YOUR-AGENT",
    "add": {"urn": "urn:moos:test:probe-001", "type_id": "node_container", "label": "Test Probe"}
  }'

# LINK two nodes
curl -X POST http://localhost:8000/morphisms \
  -H "Content-Type: application/json" \
  -d '{
    "type": "LINK",
    "actor": "urn:moos:agent:YOUR-AGENT",
    "link": {"source_urn": "urn:moos:identity:admin-local-dev", "source_port": "OWNS", "target_urn": "urn:moos:test:probe-001", "target_port": "child"}
  }'
```

### Reading State
```bash
curl http://localhost:8000/state/nodes                    # All nodes
curl http://localhost:8000/state/nodes/urn:moos:agent:claude-code  # Single node
curl http://localhost:8000/state/wires                    # All wires
curl http://localhost:8000/state/scope/urn:moos:identity:admin-local-dev  # Scoped subgraph
curl http://localhost:8000/functor/ui                     # FUN02 UI projection
curl http://localhost:8000/functor/benchmark/             # FUN05 benchmark projection
```

---

## Task File Format

**File:** `.agent/configs/tasks/YYYYMMDD-NNN-short-name.md`

```markdown
# Task NNN: <title>

**Priority:** P0 | P1 | P2
**Depends on:** (list tasks)
**Estimated effort:** ~X lines, ~Y hours

## Objective
What needs to happen (1-3 sentences).

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Tests pass

## Implementation Notes
Files to touch, key decisions, gotchas.

## Commit
`feat|fix|chore: <description> [task:YYYYMMDD-NNN]`
```

Claude Code writes these. VS Code reads and executes. Antigraviti reads for test context.

---

## Git Convention

**Commits:** `feat|fix|chore: <description> [task:YYYYMMDD-NNN]`

**Claude Code reviews:** `git log --oneline --since="<time>"`

**Branch:** `main` (single branch for MVP)

---

## Roles & Permissions Matrix

| Action | Claude Code | VS Code | Antigraviti |
|--------|------------|---------|-------------|
| Write tasks | ✅ | ❌ | ❌ |
| Read tasks | ✅ | ✅ | ✅ |
| Write handoff | ✅ | ✅ | ❌ |
| Read handoff | ✅ | ✅ | ✅ |
| Write testoff | ✅ | ❌ | ✅ |
| Read testoff | ✅ | ✅ | ✅ |
| Submit morphisms | ✅ | ✅ | ✅ |
| Read kernel log | ✅ | ✅ | ✅ |
| Watch SSE stream | ✅ | ✅ | ✅ |
| Git commit/push | ❌ | ✅ | ❌ |
| Write design docs | ✅ | ❌ | ❌ |
| Write ontology | ✅ | ❌ | ❌ |

---

## Session Start Checklist

### All Agents
1. Open `D:\FFS0_Factory\FFS0_Factory.code-workspace`
2. Read your instruction file (see Agent Roles above)
3. Read this file (`delegation-protocol.md`)
4. Check your state file in `.agent/configs/agents/`
5. Check your channel (`handoff.md` or `testoff.md`)
6. Verify kernel: `curl http://localhost:8000/healthz`

### VS Code Specific
7. Read `.agent/configs/tasks/` — pick highest-priority task with deps met
8. `git pull origin main` before starting work
9. Update state file: `status: active`, `current_task: <task-id>`

### Antigraviti Specific
7. Read test direction from `testoff.md`
8. Verify Explorer loads: `http://localhost:8000/explorer`
9. Update state file: `status: active`

---

## SOT Hierarchy (Read Order)

1. **`superset/`** — always wins (ontology.json + categories, glossary, kinds, schemas)
2. **`design/*.md`** — architectural specs + timestamped decisions (latest wins)
3. **`instances/*.json`** — seed data (must conform to ontology)
4. **`industry/*.json`** — independent landscape data
5. **`CLAUDE.md`** — workspace policy
6. **Task files** — reference SOTs, never restate them
