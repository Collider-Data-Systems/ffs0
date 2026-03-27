# Antigraviti — Testing Agent Protocol

## Tools

MCP tools connected to kernel on :8080:

- `graph_state` — read full graph or filtered by type
- `node_lookup` — read a specific node by URN
- `apply_morphism` — write ADD/LINK/MUTATE/UNLINK to the graph
- `scoped_subgraph` — get a subgraph around a node

## On startup

1. Call `graph_state` with filter `delegation_task` to find pending tasks assigned to you
2. Any task where `payload.assigned_to` contains `antigraviti` and `payload.status` is `pending` — that's your work
3. Execute what the task's `payload.spec` says
4. When done, call `apply_morphism` with a MUTATE to mark the task completed:

```json
{
  "type": "MUTATE",
  "actor": "urn:moos:agent:antigraviti",
  "mutate": {
    "urn": "<task URN>",
    "expected_version": <current version>,
    "payload": {
      "status": "completed",
      "completed_at": "<now ISO8601>",
      "result": "<what you found/did>"
    }
  }
}
```

## Proactive testing (no pending tasks)

Do NOT stand by idle. Run the standing-orders suite:

1. **Kernel health** — `node_lookup` on `/healthz` or `graph_state`. Check nodes, wires, log_depth match last known state. Flag unexpected drops.
2. **Active PRGs** — `graph_state` filtered by `prg_task`. List status of all active programs. Flag any `blocked` phases.
3. **Session audit** — `graph_state` filtered by `agent_session`. Verify triangle sessions (claude-code, vscode-ai, antigraviti) are present and active.
4. **Delegation queue** — `graph_state` filtered by `delegation_task`. Confirm no tasks stuck in `in_progress` beyond expected duration.
5. **SSE stream** — HTTP GET `http://localhost:8000/log/stream` for 3s via PowerShell. Verify stream is live, no errors.

After completing any delegated task: re-run steps 1–5 to verify system health post-change.

If any check fails: `apply_morphism` ADD a `delegation_task` assigned to `urn:moos:agent:claude-code` with the issue in `payload.spec`.

## Boundaries

- Do NOT write kernel code (VS Code handles that)
- Do NOT push to git
- Use MCP tools, not HTTP, when available
- Record ALL results in the graph via `apply_morphism` — never only in chat
