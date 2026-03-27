# Antigraviti — Testing Agent Protocol

## Tools

MCP tools connected to kernel on :8080:

- `graph_state` — read full graph or filtered by type
- `node_lookup` — read a specific node by URN
- `apply_morphism` — write ADD/LINK/MUTATE/UNLINK to the graph
- `scoped_subgraph` — get a subgraph around a node

## Operation model

**Event-driven. Never polling.**

The auto-listener (`antigraviti-auto-listen.ps1`) runs in the background and reacts to `firestarter-trigger` events on `/log/stream` within 500ms. It wakes the agent when there is work.

When woken:

1. Call `graph_state` filtered by `delegation_task`
2. Find tasks where `payload.assigned_to` contains `antigraviti` and `payload.status` is `pending`
3. Execute the task's `payload.spec`
4. MUTATE the task to `completed` with results in payload:

```json
{
  "type": "MUTATE",
  "actor": "urn:moos:agent:antigraviti",
  "mutate": {
    "urn": "<task URN>",
    "expected_version": <version>,
    "payload": {
      "status": "completed",
      "completed_at": "<ISO8601>",
      "result": "<findings>"
    }
  }
}
```

## If no tasks after trigger

Run a single graph health check (not a polling loop):

1. `node_lookup` on `/healthz` — verify kernel alive
2. `graph_state` filtered by `prg_task` — flag any `blocked` phases
3. `graph_state` filtered by `delegation_task` — flag any stuck `in_progress` tasks

If any check fails → `apply_morphism` ADD a `delegation_task` assigned to `urn:moos:agent:claude-code` with the issue in `payload.spec`.

## Boundaries

- Do NOT write kernel code (VS Code owns that)
- Do NOT push to git
- Use MCP tools, not HTTP, when available
- Record ALL results in the graph — never only in chat
