# Task 20260316-028 — MCP stdio transport

**Status:** pending
**Priority:** P1
**Assigned:** VS Code AI
**Skill:** `/golang-backend-development`
**Deps:** None (kernel builds clean, MCP bridge operational)
**Commit:** `feat(mcp): add stdio transport alongside SSE [task:20260316-028]`

---

## Source

Antigraviti observation (testoff.md, 2026-03-16 16:54): kernel MCP uses SSE transport,
IDE MCP panels require stdio. Current workaround: `mcp-remote` bridge. Adding native
stdio eliminates the external dependency.

## Objective

Add a `--mcp-stdio` flag to `cmd/moos/main.go`. When enabled, start a goroutine that:
1. Reads JSON-RPC 2.0 requests from stdin (one per line, newline-delimited)
2. Calls `Server.dispatch(req)` (already transport-agnostic at server.go:174)
3. Writes JSON-RPC 2.0 response to stdout (one per line)

Both transports run simultaneously: SSE on :8080 for HTTP clients, stdio for IDE panels.

## Acceptance Criteria

- [ ] `--mcp-stdio` flag accepted by main.go
- [ ] stdin/stdout JSON-RPC loop works (test: echo request | moos --mcp-stdio)
- [ ] SSE transport unchanged and still works when --mcp-stdio is set
- [ ] All existing tests pass (`go test ./...`)
- [ ] No external dependencies added

## Implementation Notes

- `dispatch()` at server.go:174 takes `Request`, returns `Response` — no HTTP coupling
- The stdio goroutine needs access to the `Server` instance (or just dispatch)
- Consider exporting `dispatch` or adding a `HandleStdio(in io.Reader, out io.Writer)` method
- Newline-delimited JSON is the MCP stdio convention (not length-prefixed)
- Handle stdin EOF gracefully (IDE closed the pipe)
- Do NOT remove or change the SSE transport — both must coexist

## Files to Touch

- `platform/kernel/cmd/moos/main.go` — add `--mcp-stdio` flag, start stdio goroutine
- `platform/kernel/internal/mcp/server.go` — export dispatch or add `HandleStdio` method
- `platform/kernel/internal/mcp/server_test.go` — add stdio round-trip test

## Test Plan

Antigraviti will run full test cycle after completion (see testoff.md for plan).
