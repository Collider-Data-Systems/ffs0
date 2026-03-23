# Session Graph — The Meta-Program
### Conversations as Graph State, Not IDE Memory
### 2026-03-22 | T=141

---

## 1. The Problem

Session context currently lives in three wrong places:

| Where it lives now | What's wrong |
|---|---|
| `cfg/state/session-state.json` | File on disk. Not in graph. Not queryable. |
| Claude's context window | Ephemeral. Dies on compaction. IDE-specific. |
| `channels/leadoff.md` | Deprecated. Markdown. Not structured. |

When Sam opens a different IDE, switches workstation, or starts a new conversation — context is lost. The agent bootstraps from files, not from graph truth.

**The fix:** Session state IS graph state. The graph IS the session. Any client (IDE, CLI, browser, MCP tool) connects to the kernel and reads its context from the graph.

---

## 2. The Meta-Program

Sam's insight: "session state is pretty much our main PRG to the PRGs."

The session IS a program. It is the root PRG — the one that governs all other PRGs. It tracks:
- Which PRGs are active, which are blocked, which are complete
- Which workstation/workspace is currently in use
- Which git branches map to which PRGs
- What happened in the last session (for recovery)
- What's scheduled next (calendar anchors)

### The Node

```
urn:moos:prg:000-session-meta
type_id: prg_task
status: "active" (always — this PRG never completes)
payload: {
  "title": "Session Meta-Program",
  "description": "Root PRG — orchestrates all sub-PRGs, tracks session context, workspace state, and timeline",
  "gate": 0,
  "is_meta": true
}
```

### Links FROM meta to sub-PRGs

```
prg:000-session-meta -(governs:sub_prg)→ prg:034-naturality-harness
prg:000-session-meta -(governs:sub_prg)→ prg:035-ptp-portbinding
prg:000-session-meta -(governs:sub_prg)→ prg:036-inspect-run  (was 037)
prg:000-session-meta -(governs:sub_prg)→ prg:038-moos-media
prg:000-session-meta -(anchored:timeline)→ event:20260419-hackathon
```

### Links FROM sessions to meta

```
session:20260322-lead -(focus:current)→ prg:000-session-meta
session:20260322-lead -(on:workstation)→ workstation:hplaptop
session:20260322-lead -(using:branch)→ (branch info in payload)
```

The meta-program is the ONLY prg_task that is always active.
All other PRGs are children of it.
Sam's timeline is the temporal projection of this node's LINK history.

---

## 3. What Gets Absorbed Into the Graph

| Currently | Becomes | Node Type |
|-----------|---------|-----------|
| `session-state.json` | `agent_session` nodes with full state | OBJ24 |
| `session-state.json` kernel_state | payload on `agent_session` | — |
| `session-state.json` open_items | individual `prg_task` nodes | OBJ25 |
| `session-state.json` instance_branches | payload on workspace/session nodes | — |
| `session-state.json` sources_active | payload on `agent_session` or links to runtime_surface nodes | OBJ09/OBJ24 |
| `leadoff.md` direction | `prg:000-session-meta` payload + latest `agent_session` summary | OBJ25/OBJ24 |
| `handoff.md` tasks | `prg_task` nodes with agent assignment | OBJ25 |
| `testoff.md` results | `agent_session` nodes with test outcomes | OBJ24 |
| `CLAUDE.md` protocol | remains as file (S0 seed for agents) | — |
| Git branch mapping | payload on `agent_session` or dedicated workspace PTP | — |

### What stays as files

- `CLAUDE.md` — agent boot instructions. File because agents need it BEFORE they connect to graph.
- `ontology.json` — categorical space. File because it defines what the graph CAN be.
- `instances/*.json` — hydration seeds. Files because they bootstrap the graph from empty.
- Kernel source code — Go files. Files because they ARE code.

Everything else: graph.

---

## 4. The Workspace Concept

A **workspace** is: a working context on a specific machine, in a specific filesystem location, on a specific git branch, with a specific IDE and agent.

Currently this is implicit. It should be explicit — either as a new type or as structured payload on `agent_session`.

### Option A: Workspace as agent_session payload

No new type. The `agent_session` node carries workspace info:

```json
{
  "id": "urn:moos:session:20260322-lead",
  "type_id": "agent_session",
  "payload": {
    "agent": "urn:moos:agent:claude-code",
    "started_at": "2026-03-22T10:26:00+01:00",
    "workstation": "urn:moos:workstation:hplaptop",
    "workspace": {
      "filesystem": "C:/Users/HP/FFS0_HPlaptop",
      "git_branch": "main",
      "ide": "claude-code",
      "repos": {
        "ffs0-factory-super": { "branch": "main", "instance_branches": ["instance/claude-code"] },
        "moos": { "branch": "main", "instance_branches": ["instance/vscode-ai"] }
      }
    },
    "kernel_state_at_start": { "nodes": 292, "wires": 168, "depth": 470 },
    "focus": "urn:moos:prg:000-session-meta"
  }
}
```

**Pro:** No schema change. Uses existing OBJ24.
**Con:** Workspace info buried in payload, not linkable as a separate node.

### Option B: Workspace as new type (OBJ29)

New type: `workspace`. Separate node that persists across sessions.

```json
{
  "id": "urn:moos:workspace:hplaptop-main",
  "type_id": "workspace",
  "payload": {
    "workstation": "urn:moos:workstation:hplaptop",
    "filesystem": "C:/Users/HP/FFS0_HPlaptop",
    "git_branch": "main",
    "repos": ["ffs0-factory-super", "moos"],
    "ide_affinity": ["claude-code", "vscode-ai"]
  }
}
```

Links:
```
workspace:hplaptop-main -(on:machine)→ workstation:hplaptop
workspace:hplaptop-main -(tracks:branch)→ (branch state in payload)
session:20260322-lead -(in:workspace)→ workspace:hplaptop-main
```

**Pro:** Workspace persists. Multiple sessions can reference same workspace. Branch state is a first-class node.
**Con:** Adds OBJ29 to ontology. More wires.

### Recommendation: Option A now, Option B later

Start with workspace-as-payload. It's sufficient for single-user, 2-workstation setup. When multi-user or multi-kernel arrives, promote to OBJ29.

The key principle: **the agent_session node must carry enough context that any fresh agent connecting to the kernel can fully orient itself from graph state alone.**

---

## 5. The Graph Session Protocol (replaces file-based protocol)

### Any Agent, Any IDE, Any Workstation

```
┌─────────────────────────────────────────────────────────┐
│ 1. CONNECT to kernel MCP (:8080)                        │
│    or kernel HTTP (:8000)                                │
│                                                          │
│ 2. GET /state                                            │
│    → filter type_id = "agent_session"                    │
│    → find latest session (by started_at)                 │
│    → read its payload → workspace, PRG focus, kernel     │
│                         state, decisions, summary        │
│                                                          │
│ 3. GET /state                                            │
│    → filter type_id = "prg_task"                         │
│    → find prg:000-session-meta → read active sub-PRGs    │
│    → identify: what gate? what's blocked? what's next?   │
│                                                          │
│ 4. GET /state                                            │
│    → filter type_id = "calendar_event"                   │
│    → find upcoming anchors → deadlines, scheduled work   │
│                                                          │
│ 5. POST /morphisms                                       │
│    → ADD agent_session node for THIS session             │
│    → include: agent, workstation, workspace, timestamp   │
│    → LINK to prg:000-session-meta (focus)                │
│    → LINK to relevant prg_task (current work)            │
│                                                          │
│ 6. WORK                                                  │
│    → all significant decisions → MUTATE prg_task nodes   │
│    → all completions → MUTATE agent_session              │
│    → new calendar items → ADD calendar_event + LINK      │
│                                                          │
│ 7. END                                                   │
│    → MUTATE session node: status=complete, add summary   │
│    → summary = what was done, what's next, open items    │
│    → this summary IS the "leadoff" for the next session  │
└─────────────────────────────────────────────────────────┘
```

### Key Point: Step 2 replaces everything

The latest `agent_session` node's payload IS the session state.
Its summary IS the leadoff.
Its workspace IS the branch/workstation info.
Its links to `prg_task` nodes IS the task tracking.
Its links to `calendar_event` nodes IS the timeline.

No files needed. No memory needed. Graph is truth.

### When Kernel Is Not Running

If no kernel is running (cold start, new machine), the agent falls back to:
1. Read `CLAUDE.md` (file) — boot instructions
2. Boot kernel from instance seeds (files)
3. Kernel hydrates → graph appears → protocol resumes from step 2

The files are the **cold start bootstrap**. Once the kernel is running, they are redundant. This is the S0→S2 transition: files are S0 (authored), graph is S2 (materialized).

---

## 6. Git Branches as Graph Reflections

Sam: "My timeline is a reflection of the main program and its branches including filesystems"

### Current Branch Model

```
main ← Sam's authority, merged production
instance/<agent> ← persistent per-agent branches
feature/NNN-name ← ephemeral task work
```

### How This Maps to the Graph

| Git Concept | Graph Representation |
|---|---|
| `main` branch | prg:000-session-meta (the meta-program = main line) |
| `feature/034-*` branch | prg:034-naturality-harness node + agent_session working on it |
| `instance/claude-code` branch | agent_session nodes for claude-code with branch in workspace payload |
| PR from instance → main | channel_message node (OBJ28) — the decision record |
| Merge to main | MUTATE prg_task status → "complete" |
| Branch creation | LINK from agent_session to prg_task (starting work) |
| Branch deletion | UNLINK or MUTATE agent_session status → "complete" |

### The Reflection Principle

Sam's IRL timeline is:
```
calendar_event chain (temporal anchors)
  ↕ LINK
prg_task DAG (work structure)
  ↕ LINK
agent_session chain (who did what when)
  ↕ payload
workspace state (which branch, which machine, which filesystem)
```

Each layer is a different PROJECTION of the same meta-program.
The calendar is the temporal projection.
The PRG DAG is the structural projection.
The session chain is the agent projection.
The workspace is the physical projection.

All four projections compose into one graph rooted at `prg:000-session-meta`.

---

## 7. Multiple Kernels, Same Graph Truth

Sam: "Kernels are needed for the graph to run and are run by a user that has his agents and can run multiple kernels."

### The Setup

```
Sam (user)
├── z440 (workstation_config)
│   └── kernel instance on :8000/:8080
│       └── HG with full state
├── HP laptop (workstation_config)
│   └── kernel instance on :8000/:8080
│       └── HG with full state
└── z330 (workstation_config)
    └── (future kernel)
```

### Sync via Git + Hydration

Two kernels running independently = two HG instances.
They stay in sync because:
1. Same `instances/*.json` seeds (via git push/pull)
2. Same `morphism-log.jsonl` (via git push/pull)
3. `fold(log)` is deterministic (CI-4) → same log = same state

This is not real-time sync. It's **eventual consistency via shared log**.

Real-time sync (CAN_FEDERATE / MOR12) is future work.
For now: git push/pull between sessions is sufficient.

### What This Means for the Agent

An agent doesn't care WHICH kernel it's talking to.
It connects to `:8080`, reads the graph, orients itself.
The graph tells it everything. The kernel is interchangeable.

If Sam starts a session on z440, works, pushes.
Then opens HP laptop, pulls, boots kernel.
The graph state is identical (CI-4).
The new session reads the latest `agent_session` → picks up where z440 left off.

This IS the "conversations should not start inside Claude Desktop env" — the conversation persists in the graph, not in the IDE. The IDE is a projection surface. The graph is the truth.

---

## 8. What This Replaces

### Files That Become Redundant Once Protocol Is Live

| File | Replaced By | When |
|------|-------------|------|
| `cfg/state/session-state.json` | `agent_session` nodes in graph | Immediately |
| `channels/leadoff.md` | Latest `agent_session` summary field | Already deprecated |
| `channels/handoff.md` | `prg_task` nodes + GitHub PRs | Already deprecated |
| `channels/testoff.md` | `agent_session` nodes with test results | Already deprecated |
| `cfg/agents/*.json` | Could become `agent_spec` nodes (OBJ21) — already in ontology | Later |

### Files That STAY

| File | Why |
|------|-----|
| `CLAUDE.md` | Cold start bootstrap — agents need it before graph exists |
| `ontology.json` | CS definition — defines what graph CAN be |
| `instances/*.json` | Hydration seeds — bootstrap graph from empty |
| `kb/design/*.md` | S0 authored reference — human-readable design docs |
| Kernel source (Go) | Code IS code |

---

## 9. Implementation Path (no code — direction only)

### Phase 1: Meta-Program Node (now)

ADD `prg:000-session-meta` to graph.
LINK all existing prg_task nodes to it.
LINK calendar events (hackathon, studio, etc.) to it.
Start writing session summaries into `agent_session` payload instead of `session-state.json`.

### Phase 2: Workspace-in-Payload (next session)

New `agent_session` nodes include full workspace payload:
- workstation URN
- filesystem path
- git branch
- IDE
- repos + instance branches

Previous session's summary field = the new session's bootstrap context.

### Phase 3: Drop session-state.json (after Phase 2 proven)

Stop writing to `session-state.json`.
All session context comes from graph.
`session-state.json` becomes a read-only archive.

### Phase 4: Agent configs as graph nodes (later)

Move `cfg/agents/*.json` content into `agent_spec` nodes (OBJ21 already exists).
Agent capabilities, permissions, tool access = graph structure, not file config.

---

## 10. The Through-Line

```
SESSION = GRAPH = TRUTH

  IRL (Sam)
    ↓ calendar_event
  Timeline (GCal)
    ↓ LINK
  Meta-Program (prg:000)
    ↓ LINK
  Sub-PRGs (prg:034, 038, ...)
    ↓ LINK
  Sessions (agent_session nodes)
    ↓ payload
  Workspaces (branch, machine, IDE)
    ↓ LINK
  Morphisms (the actual graph changes)
    ↓ fold
  State (what is true now)
```

Every layer is a different zoom level on the same structure.
No layer lives outside the graph (except the cold-start bootstrap files).
Any IDE, any workstation, any agent can connect and read the full context.
The conversation does not live in Claude. The conversation lives in the kernel.
Claude is a functor: `agent: (GraphState × Channel) → MorphismProgram`.
The graph persists. The functor is stateless. That's the architecture.
