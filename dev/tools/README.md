# dev/tools

Compiled developer tools for mo:os (Go). These are **tooling**, not kernel runtime
(the kernel/router live in the sibling `moos-kernel` / `moos-router` repos). A
`go.work` unions both modules so the Go extension / gopls resolves them together.

| Tool | What it is |
|---|---|
| [`moos-mcp/`](./moos-mcp) | MCP server bridging one kernel to any IDE agent (reads + atomic writes). |
| [`moos-lsp/`](./moos-lsp) | Language server: live ontology diagnostics / completion / hover for rewrite envelopes. |

## Build

```sh
cd dev/tools
go build ./moos-mcp/... ./moos-lsp/...
go test  ./moos-lsp/...
```

## Why these two

They are the productized form of "one server → every IDE": `moos-mcp` gives agents a
uniform tool surface onto the kernel; `moos-lsp` gives humans live operad feedback while
authoring envelopes. See `dev/reference/landscape.md` for the surrounding technology map.
