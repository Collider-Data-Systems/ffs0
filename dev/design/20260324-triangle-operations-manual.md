# Triangle Operations Manual
### mo:os Multi-IDE Harness — User Guide
### 2026-03-24 | T=142 | Wave 3

---

## What This Is

You run three IDE conversations simultaneously, all connected to one kernel graph on `:8000`. The kernel is the source of truth. The IDEs are stateless functors that read state, do work, and write morphisms back. You (Sam) are the user and appointer of roles.

This manual describes how to operate this system **right now** as it stands after Wave 3 hydration.

```
        Sam (user, appointer)
         |
    ┌────┼────────────────────┐
    |    |                    |
 Claude Code    VS Code AI    Antigraviti
 (lead)         (execution)   (listening)
    |    |                    |
    └────┼────────────────────┘
         |
    Kernel (:8000)
    414 nodes, 346 wires
    Log depth ~770
```

---

## 1. Start the System

### 1a. Boot the Kernel

The kernel is a Go binary. It must be running before any IDE connects.

```powershell
cd C:\Users\HP\FFS0_HPlaptop\moos\platform\kernel
go run ./cmd/moos --kb ../../ffs0-factory-super/kb --hydrate
```

Verify:
```
curl http://localhost:8000/healthz
```
Response should show `"status": "ok"`, node/wire counts, and `epoch`.

### 1b. Open the Three IDEs

Open them in any order. Each creates its own `agent_session` node on connect.

| IDE             | How to Start                               | Role                                                            |
| --------------- | ------------------------------------------ | --------------------------------------------------------------- |
| **Claude Code** | Terminal: `claude` in `ffs0-factory-super` | Lead. Strategic. Proposes, discusses, agrees, hydrates.         |
| **VS Code**     | Open `ffs0-factory-super` workspace        | Execution. Kernel code, Go tests, ontology patches.             |
| **Antigraviti** | Open Agent Manager                         | Listening. UX testing, browser verification, delegation pickup. |

### 1c. Start the AG Auto-Listener

This is the script that lets Antigraviti automatically pick up delegations from the graph:

```powershell
# Listener helper scripts are no longer stored in this portable repo.
# Use direct graph queries for delegation checks.
```

What it does:
- Connects to kernel SSE stream (`/log/stream`) for real-time events
- Falls back to polling (`/log?after=...`) if SSE drops
- Detects `channel_message` nodes tagged `delegation` + `antigraviti`
- Auto-ACKs by adding a response `channel_message` to the graph
- Shows Windows toast notifications for visual feedback
- Singleton mutex prevents duplicate instances
- State persisted in `.antigraviti-auto-listener-state.json`

**Dedup rule:** Messages with tag `auto-ack` are never re-acked. The `Is-DelegationPayload` function checks `$isSelfAck` — if the sender is antigraviti or tags contain `auto-ack`, it's skipped. This prevents the feedback cascade.

### 1d. Verify the Triangle

```
curl http://localhost:8000/state/lens?kind=agent_session
```

You should see three sessions for today, each with a `role` field:
- `session:20260324-claude-code` — role: `lead`
- `session:20260324-vscodeHPL` — role: `active`
- `session:20260324-antigraviti-hp` — role: `listening`

Visual check: open `http://localhost:8000/explorer` in browser. History tab shows all morphisms with timestamps and actors.

---

## 2. The PRG System

PRGs (Programs) are the unit of work. They are `prg_task` nodes in the graph, wired to `prg:000-session-meta` (the meta-program that never completes).

### 2a. PRG Lifecycle

```
planned → delegated → active → in_progress → completed
                                     ↓
                                  blocked
```

Every PRG has:
- **phases** — ordered steps with validation conditions
- **harness_pattern** — `fixed-plan-sequential` (gate PRGs) or `dynamic-plan-adaptive` (operational PRGs)
- **gate_output** — what must be true before the next gate PRG can start

### 2b. The Gate Sequence (Deterministic Rails)

These four PRGs form a locked sequence. Each gate adds a "nine" of reliability (Karpathy's march of nines). No gate can start execution until the previous gate's `gate_output` is satisfied.

```
Gate 1: PRG034 — Naturality Harness
  Proves: F(Apply(M,S)) == Apply(M', F(S))
  Phases: 034.1 broadCategory fix → 034.2 FUN02 test → 034.3 proof
  Blocks: everything downstream

Gate 2: PRG035 — PTP PortBinding
  Reifies: 12 morphism families as S1 nodes (7 generators, not 268 pairs)
  Phases: 035.1 family nodes [DONE] → 035.2 FUN10 → 035.3 FUN11 → 035.4 FUN12
  Blocks: multi-kernel topology

Gate 3: PRG036 — Cloverleaf Topology
  Enables: multiple kernel leaves composable via cooperad ports
  Phases: 036.1 ontology → 036.2 isolation → 036.3 BRIDGES → 036.4 sync → 036.5 Ricci
  Blocks: GPU/CPU separation

Gate 4: PRG037 — Inspect/Run Separation (Capstone)
  Achieves: GPU inspects (ephemeral hypotheses), CPU runs (proven facts), Log remembers
  Phases: 037.1 substrate → 037.2 HDC pipeline → 037.3 promote/discard → 037.4 time delta → 037.5 S3-S4 gate
```

### 2c. Operational PRGs (Adaptive)

These run concurrently with the gate sequence. Their phases can be reordered, added, or removed at runtime.

| PRG | What                                                   | Status      |
| --- | ------------------------------------------------------ | ----------- |
| 001 | Calendar Hydration — bridge IRL time to graph time     | in_progress |
| 038 | Moos Media — YouTube/Instagram/TikTok channel          | active      |
| 039 | Session Identity — typed, role-bearing sessions        | in_progress |
| 040 | The Bridge — retroactive Drive/Calendar/Docs hydration | active      |

### 2d. Sub-PRGs

Sub-PRGs are child tasks wired `parent.out → sub.in`. They have context isolation — each works on a narrow scope without polluting the parent's context. This is the Karpathy pattern of sub-agent delegation.

| Sub-PRG | Parent | Owner   | Task                    |
| ------- | ------ | ------- | ----------------------- |
| 034a    | 034    | VS Code | broadCategory fix       |
| 038a    | 038    | AG      | Studio shoot today      |
| 040a    | 040    | AG      | Google Drive retro-scan |

---

## 3. How to Work

### 3a. The Propose-Discuss-Agree-Hydrate Cycle

This is the lead conversation pattern. Claude Code (lead) runs this cycle:

```
1. PROPOSE  — Claude analyzes graph state and proposes changes
2. DISCUSS  — Sam and Claude discuss implications, tradeoffs
3. AGREE    — Sam approves ("agreed", "approved", "proceed")
4. HYDRATE  — Claude writes morphisms to the graph (ADD, LINK, MUTATE)
5. DELEGATE — Claude sends channel_messages to VS Code and AG
```

This IS the specialized harness from the Karpathy video. The conversation is the orchestrator (7K tokens context). The IDE agents are sub-agents (isolated context, cheaper models). The graph is the shared state machine.

### 3b. Delegating to VS Code

VS Code handles kernel code, Go tests, and ontology patches. To delegate:

1. From lead conversation, describe the task
2. Claude ADDs a `channel_message` with `from`/`to` session URNs
3. Claude LINKs the message to the target PRG
4. VS Code picks up the message (via SSE listener or manual check)
5. VS Code does the work, then ADDs a completion message back

Example delegation message:
```json
{
  "from": "urn:moos:session:20260324-claude-code",
  "to": "urn:moos:session:20260324-vscodeHPL",
  "subject": "PRG034.1 broadCategory fix",
  "body": "Fix broadCategory() in lens.go...",
  "tags": ["delegation", "vscode", "prg034"]
}
```

### 3c. Delegating to Antigraviti

AG has the auto-listener running. Delegation is automatic:

1. Claude ADDs a `channel_message` tagged `delegation` + `antigraviti`
2. AG's listener detects it via SSE within seconds
3. AG auto-ACKs with a response message in the graph
4. AG shows a toast notification on your screen
5. AG's conversation picks up the task

You can also delegate manually from any IDE using the script:
```powershell
# Helper script removed from portable repo.
# Create delegation channel_message nodes directly in the graph.
```

### 3d. Checking Progress

**From any IDE:**
```
curl http://localhost:8000/state/lens?kind=channel_message
```

**From the browser:**
Open `http://localhost:8000/explorer` → History tab → filter by actor

**From Claude Code:**
Query the graph via MCP tools or curl. Claude reads delegation responses and reports back.

---

## 4. Time

Three temporal layers. Each serves a different purpose.

### 4a. Log Time (the truth)

```
state(t) = fold(log[0..t])
```

Every morphism has an `issued_at` timestamp. This is monotonic causal order — the only time that is truth. The kernel doesn't care about wall clocks. It cares about the order of events.

- Epoch: `2026-03-17T13:47:40Z` (first morphism)
- Current depth: ~770 log entries
- Queryable: `GET /log?after=<RFC3339>`
- Streamable: `GET /log/stream` (SSE)

### 4b. Runtime (program clocks)

PRG lifecycle tracked via MUTATE payload fields:
- `status`: planned/active/in_progress/completed
- `started_at`, `completed_at`: set when status changes
- `phases[].status`: per-phase progress

The phase array IS the state machine. Gate PRGs use `fixed-plan-sequential` — phases execute in order, no skipping. Operational PRGs use `dynamic-plan-adaptive` — phases can be reordered.

This is Karpathy's "specialized harness as state machine." Each phase has a `validation` condition. The validation IS the nine.

### 4c. IRL Time (tagged metadata)

Calendar events, Gmail timestamps, YouTube `retrieved_at`, Drive `modified_at`. This time is tagged, not authoritative. It comes from external systems.

- `moos_epoch`: 2025-11-03 (Moos birthday, T=0)
- `moos_day`: 142 (today)
- IRL anchors: hackathon 2026-04-19, studio shoot 2026-03-24

Calendar events wire to PRGs: `event.out → prg.in`. This creates the temporal projection — when you look at your calendar, you see the PRG timeline.

---

## 5. The Graph

### 5a. What's In It

| Type               | Count | Purpose                             |
| ------------------ | ----- | ----------------------------------- |
| `prg_task`         | 14    | Programs with phases and gates      |
| `agent_session`    | 8     | IDE conversations with roles        |
| `channel_message`  | ~75   | Delegation, ACKs, checkpoints       |
| `calendar_event`   | 11    | IRL time anchors                    |
| `keep_note`        | ~5    | Design references, mappings         |
| `ontology_term`    | 12    | PTP family nodes at S1              |
| `industry_entity`  | ~100  | External landscape (S0)             |
| Other S2 instances | ~190  | Infrastructure, sources, benchmarks |

### 5b. Strata

```
S0 (authored)    → KB files, industry entities, keep_notes
S1 (validated)   → Ontology terms, PTP families (the grammar)
S2 (materialized)→ Sessions, PRGs, messages, events (the runtime)
S3 (evaluated)   → Benchmark scores, Ricci curvature (future)
S4 (projected)   → UI views, calendar projections (NEVER truth)
```

### 5c. The Four Morphisms

Every write to the graph uses exactly one of:

| Morphism | What           | When                                   |
| -------- | -------------- | -------------------------------------- |
| ADD      | Create a node  | New PRG, message, event, note          |
| LINK     | Wire two nodes | Delegation→PRG, event→PRG, session→PRG |
| MUTATE   | Update a node  | Phase status change, role assignment   |
| UNLINK   | Remove a wire  | Supersede a connection                 |

Programs (atomic batches) wrap multiple morphisms: `POST /programs` with `{actor, envelopes: [...]}`.

---

## 6. Wave Protocol

Work is organized in waves. Each wave is a batch of morphisms applied atomically, followed by delegation to the other IDEs.

### Current Wave History

| Wave | What Was Hydrated                                                                                 | Nodes After |
| ---- | ------------------------------------------------------------------------------------------------- | ----------- |
| W1   | PRG000 governance + temporal model, 12 PTP families, Karpathy mapping note                        | 408         |
| W2   | Phase arrays on 034/035/038/040, validation protocol note                                         | 411         |
| W3   | PRG039 session identity + phases, PRG036/037 phase design, CLAUDE.md rules, PRG001 calendar audit | 417         |

### How to Run a Wave

1. **Query** — `GET /state/lens?kind=prg_task` to see current state
2. **Propose** — Claude drafts the morphisms (in conversation)
3. **Discuss** — Sam reviews, adjusts scope
4. **Agree** — Sam says "approved" or "proceed"
5. **Hydrate** — Claude posts the program batch to `/programs`
6. **Verify** — Claude queries graph to confirm
7. **Delegate** — Claude sends `channel_message` to VS Code and AG
8. **Monitor** — Check Explorer, SSE stream, or toast notifications

---

## 7. Files That Matter

### Always-On Files (cold start bootstrap)
| File                           | Purpose                                      |
| ------------------------------ | -------------------------------------------- |
| `CLAUDE.md`                    | Workspace boot protocol and identity notes   |
| `kb/superset/ontology.json`    | Categorical space — what the graph CAN be    |
| `kb/superset/instances/*.json` | Hydration seeds — bootstrap graph from empty |

### Operational Scripts

Script helpers were removed from the portable repo layout. Use direct graph operations and documented prompts/hooks in `.github/`.

### Design Docs (S0 reference)
| File                                                   | Covers                                          |
| ------------------------------------------------------ | ----------------------------------------------- |
| `dev/design/20260322-categorical-space.md`             | Session/space framing and categorical grounding |
| `dev/design/20260325-cloverleaf-autonomous-kernels.md` | Gate 3: multi-kernel                            |
| `dev/design/20260326-fiber-decomposition.md`           | Gate 4: decomposition and execution structure   |
| `dev/design/20260319-ptp-binding-categories.md`        | Gate 2: port binding                            |

### Agent Configs

Agent config files were removed from this repo layout.

---

## 8. Common Operations

### "I want to check what's happening"
```powershell
curl http://localhost:8000/healthz                    # node/wire counts
curl http://localhost:8000/state/lens?kind=prg_task   # all PRGs with status
curl http://localhost:8000/state/lens?kind=channel_message  # all messages
```
Or open `http://localhost:8000/explorer` in browser.

### "I want to delegate a task to AG"
```powershell
# Helper script removed from portable repo.
# Delegate by adding a channel_message delegation node via API/MCP.
```

### "I want to add a calendar event to the graph"
From Claude Code (lead), describe the event. Claude will:
1. ADD a `calendar_event` node
2. LINK it to the relevant PRG
3. Optionally create it in Google Calendar via MCP

### "I want to see the PRG phase progress"
```powershell
curl http://localhost:8000/state/nodes/urn:moos:prg:034-naturality-harness
```
Look at `payload.phases` — each has `id`, `name`, `status`, `owner`, `validation`.

### "I want to start a new session tomorrow"
1. Open your IDEs
2. Each IDE ADDs a new `agent_session` node: `session:20260325-<ide>`
3. LINKs to `prg:000-session-meta`
4. Reads latest messages and PRG state to orient
5. You appoint a lead in conversation

### "I want to appoint a different lead"
Say it in any conversation. The new lead MUTATEs its session node to `role: "lead"` and the previous lead to `role: "active"`. This is a user appointment, not a code change.

---

## 9. What's Missing (Known Gaps)

| Gap                               | Severity | Where It Hurts                                   |
| --------------------------------- | -------- | ------------------------------------------------ |
| No per-phase output validation    | Medium   | Gates block but don't verify artifacts           |
| No token/cost tracking            | Low      | Can't measure march-of-nines cost per gate       |
| agent_session has no `in` port    | Medium   | PRGs can't wire back to sessions (039.4 pending) |
| No automated gate unlock          | Low      | Lead must manually check gate_output conditions  |
| FUN06 calendar functor incomplete | Medium   | Calendar projection doesn't round-trip to GCal   |
| AG toast requires WinRT           | Low      | Fails silently on some pwsh versions             |
| No session end/summary protocol   | Medium   | Sessions don't formally close with handoff       |

---

## 10. The Architecture in One Sentence

Three IDE conversations, each a stateless functor, compose morphisms into a shared kernel graph whose catamorphic fold is the single source of truth, with PRG programs as the state machine and channel messages as the delegation bus — a specialized harness where the user is the orchestrator, the lead IDE is the supervisor, and the graph is the deterministic rail.
