# moos-mcp

A [Model Context Protocol](https://modelcontextprotocol.io) server that exposes one
mo:os kernel to any MCP-capable IDE/agent (Claude Code, VS Code agent mode, Antigravity).
**One server → every IDE's agent talks to the kernel identically.**

Reads map to the kernel's `GET` endpoints; writes map to the atomic `POST /programs`.
Speaks MCP over **stdio**.

## Build

```sh
cd dev/tools/moos-mcp
go build -o moos-mcp .
```

## Run

```sh
./moos-mcp --base-url http://localhost:8000 --actor urn:moos:agent:claude-code.hp-z440
# or via env: MOOS_BASE_URL, MOOS_ACTOR
```

## Tools

| Tool | Endpoint | Notes |
|---|---|---|
| `moos_healthz` | `GET /healthz` | status, ontology_version, t_day, log_len |
| `moos_get_node(urn)` | `GET /state/nodes/{urn}` | one folded node |
| `moos_list_nodes(type_id?)` | `GET /state/nodes` | optional client-side type filter |
| `moos_query_relations(src_urn?)` | `GET /state/relations[/src/{urn}]` | all, or outbound from a node |
| `moos_node_types` | `GET /operad/node-types` | type registry |
| `moos_rewrite_categories` | `GET /operad/rewrite-categories` | WF01..WF21 registry |
| `moos_apply(envelopes[], actor?, session_urn?)` | `POST /programs` | **atomic batch** write |
| `moos_add` / `moos_link` / `moos_mutate` / `moos_unlink` | `POST /programs` | one-envelope convenience builders |

## Resources

- `moos://healthz`, `moos://state/nodes` (static)
- `moos://node/{urn}` (template)

## Safety (§M11 / §M12)

`moos_apply` (and the convenience builders) stamp the supplied `--actor` / `actor` arg
onto envelopes that omit one. The kernel still enforces **§M11 liveness**: the actor must
match the session's seated `has-occupant`, or the whole program is rejected. This server
does not bypass that gate — it is a transport, not an authority. Never run it pointed at a
kernel you are not authorised to write to.

## Wiring into an IDE

Claude Code / VS Code `mcp.json`:

```json
{
  "servers": {
    "moos": {
      "command": "/absolute/path/to/moos-mcp",
      "args": ["--base-url", "http://localhost:8000", "--actor", "urn:moos:agent:..."]
    }
  }
}
```

A tracked example lives at `.vscode/mcp.json.example` (the real `.vscode/mcp.json` is gitignored).

## Follow-ups

- Expose the 13 skills as MCP **prompts**.
- Migrate into `moos-kernel` to share operad types directly rather than re-deriving the wire format.
