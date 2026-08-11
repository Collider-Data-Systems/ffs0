# PRG-in-Graph: KG → HG Migration

**Date:** 2026-03-21
**Author:** Claude Code + Sam
**Status:** Active
**Supersedes:** Markdown-based task tracking (tasks/*.md)

---

## Summary

Move PRG (progression tracking) from Knowledge Graph files into the Hypergraph kernel. PRG tasks, calendar events, Keep notes, session state, and key channel decisions become graph nodes — queryable, wirable, and causally ordered via the morphism log.

## Motivation

**Problem:** Session state lives in files (`session-state.json`, `leadoff.md`, task `.md` files). When a Claude context window compacts, the conversation state is lost except for what survives in summaries. Files can diverge, conflict, or go stale. No temporal awareness — PRG tasks exist outside time.

**Solution:** Write runtime state INTO the kernel graph. Any Claude instance starts with `GET /state` and gets complete ground truth. Calendar events provide temporal anchors. Keep notes bridge IRL→graph. The catamorphism `state(t) = fold(log[0..t])` already makes the log the source of truth — we now extend it to cover PRG and session state.

## New OBJ Types (committed to ontology.json)

| ID | type_id | broad_category | Description |
|----|---------|---------------|-------------|
| OBJ24 | `agent_session` | identity | Claude session state — kernel snapshot, PRG focus, active sources |
| OBJ25 | `prg_task` | structure | PRG task — status, dependencies, gate ordering |
| OBJ26 | `calendar_event` | structure | Temporal anchor from GCal — maps IRL time to PRG |
| OBJ27 | `keep_note` | structure | Sam's mobile notes from Keep — S0 authored signals |
| OBJ28 | `channel_message` | structure | Key channel decision promoted from .md to graph |

## What Moves, What Stays

### Moves to graph (ground truth IN kernel)
- PRG task status and dependencies → `prg_task` nodes + `LINK_NODES` wires
- Session state → `agent_session` nodes (written at session start/end)
- Calendar anchors → `calendar_event` nodes (hydrated from GCal MCP)
- Keep notes → `keep_note` nodes (hydrated from Keep, reviewed in sessions)
- Key decisions → `channel_message` nodes (promoted from channels)

### Stays in KB files (S0/S1 authored layer)
- `ontology.json` — type registry (SOT for all OBJ definitions)
- `instances/*.json` — hydration seeds (the initial ADD/LINK envelopes)
- `design/*.md` — design documents (reference, human-readable)
- `channels/*.md` — human-readable session log (S4 projection of graph state)
- `reference/` — papers, YouTube, external sources

## Session Protocol (new)

### Session Start
1. Boot kernel: `go run ./cmd/moos --kb ... --hydrate`
2. `GET /state` → ground truth (all nodes, wires, log depth)
3. Read `leadoff.md` → human context layer (S4 projection)
4. `POST /morphisms` → ADD `agent_session` node with:
   - kernel state snapshot (nodes, wires, depth)
   - agent version (claude-opus-4-6)
   - PRG focus (current task)
   - active sources (gmail, gcal, gdrive, kernel_mcp, github)
5. LINK session → current PRG task

### During Session
- Key decisions → MUTATE relevant `prg_task` node payload
- New Keep notes reviewed → ADD `keep_note` nodes
- Calendar events wired → ADD `calendar_event` + LINK to prg_task

### Session End
- MUTATE session node: mark complete, add summary
- Prepend summary to `leadoff.md` (S4 projection for human readability)
- Push to remote

### Context Compaction Recovery
Instead of relying solely on conversation summaries:
1. `GET /state` → full graph truth
2. Filter nodes by type `agent_session` → find latest session
3. Filter nodes by type `prg_task` → find current task + status
4. Continue from graph state, not from memory

## Time Mapping

```
IRL (Sam's life)
    ↓ Google Calendar events
calendar_event nodes (temporal anchors)
    ↓ LINK_NODES wires
prg_task nodes (planned work)
    ↓ dependency wires
Gate 1: 034 naturality → Gate 2: 035 PTP → Gate 3: 036 Cloverleaf → Gate 4: 037 Inspect/Run
    ↓
Morphism log = history of what happened and when
```

Past calendar events = completed morphisms (log entries with timestamps).
Future calendar events = proposed morphisms (S1 validated, awaiting execution).
Keep notes = S0 signals → promoted to S1 when reviewed → S2 when committed.

## Git Branch Protocol (proposed)

Related to but distinct from the KG→HG migration. When multiple Claude instances work in parallel:

| Branch Kind | Purpose | Lifecycle |
|------------|---------|-----------|
| `main` | Hub (Sam's authority, merged production) | Persistent |
| `instance/<agent-name>` | Persistent home for a running Claude instance | Persistent |
| `feature/NNN-name` | Task implementation work | Ephemeral (PR → merge → delete) |

PRs from instance branches = the messaging channel between parallel Claude instances.
PR comments = async back-and-forth. All PRs target main (star topology preserved).

## Governance Model

```
1 AuthUser (Sam) — owns main, has GitHub permissions
    ↓ delegation (LINK morphisms)
Agents — each gets scoped permissions on their instance branch
    ↓ feature work
Each Claude instance = 1 branch = 1 KernelLeaf view
PRs = the message from that instance to the lead
```

- `main` = admin graph (KernelHub) — only Sam merges
- Instance branches = user graph (KernelLeaf) — each agent pushes to its own
- Delegation = LINK morphism from AuthUser to agent via "delegates" port

## Relation to Existing Design Docs

- **PTP PortBindings** (`20260319-ptp-binding-categories.md`): OBJ IDs shifted. PortBinding → OBJ29+, not OBJ24. Design unchanged, just re-numbered when committed.
- **Cloverleaf** (`20260319-cloverleaf-kernel-topology.md`): KernelLeaf/Hub → OBJ30/31. Git branch topology maps directly to Cloverleaf cooperad topology.
- **Inspect/Run** (`20260319-inspect-run-separation.md`): Keep note "LLM as state transformer" confirms the two-graph model (user graph vs admin graph).
