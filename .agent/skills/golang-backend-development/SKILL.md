---
name: golang-backend-development
description: Go kernel development conventions for mo:os — pure core vs effect shell, table-driven tests, zero external deps, morphism-based state management. Use for any Go code changes in platform/kernel/.
---

# Go Backend Development — mo:os Kernel

You are a Go backend expert working on the mo:os categorical graph kernel. All code must follow the strict architectural boundaries below.

---

## Architecture: Pure Core + Effect Shell

```
pure core (NO IO)
  └─ internal/cat/    — Node, Wire, GraphState, Envelope types
  └─ internal/fold/   — Evaluate, Replay (catamorphism)
  └─ internal/operad/ — Semantic registry, TypeSpecs, port validation

effect shell (IO allowed)
  └─ internal/shell/     — RWMutex, Apply, ScopedSubgraph
  └─ internal/transport/ — HTTP on :8000 (16 routes)
  └─ internal/hydration/ — Batch materialization from KB
  └─ internal/mcp/       — MCP bridge on :8080
  └─ internal/functor/   — Benchmark functor (FUN05)
```

**Rule:** NO IO in `internal/cat/` or `internal/fold/`. No `fmt.Println`, no `os.Open`, no `net/http`. These are pure computation.

---

## Conventions

### Types
- `Node` — typed graph object with URN, Kind, Payload, Ports
- `Wire` — 4-tuple: `(SourceURN, SourcePort, TargetURN, TargetPort)`
- `GraphState` — immutable snapshot: `Nodes map[string]*Node`, `Wires []*Wire`
- `Envelope` — morphism request wrapper: `Kind`, `URN`, `Payload`, `Wire`

### State Management
- All mutations through 4 morphisms: ADD, LINK, MUTATE, UNLINK
- Append-only morphism log (`data/morphism-log.jsonl`)
- `SeedIfAbsent` for idempotent initialization, NOT `Apply`
- `sync.RWMutex` guards all shared state in effect shell

### Error Handling
- Sentinel error types: `ErrNodeExists`, `ErrWireExists`, `ErrNodeNotFound`
- Return `(result, error)` — never panic in production paths
- Wrap errors with context: `fmt.Errorf("apply ADD %s: %w", urn, err)`

### Testing
- Table-driven tests with `t.Run(name, func(t *testing.T) {...})`
- 4 `..` to repo root in test file paths
- 8 test packages, all must pass
- Run: `cd platform/kernel && go test ./...`
- Race detector: `go test -race ./...`

### Dependencies
- **Zero external dependencies** — stdlib only
- `encoding/json`, `net/http`, `sync`, `embed`, `strings`, `fmt`, `time`
- Use `sync.Pool` for allocation-hot paths

---

## Key Entrypoints

| File | Purpose |
|------|---------|
| `cmd/moos/main.go` | Entrypoint (`--kb`, `--hydrate` flags) |
| `internal/cat/types.go` | Core types (Node, Wire, GraphState) |
| `internal/fold/evaluate.go` | Pure catamorphism (Evaluate, Replay) |
| `internal/operad/registry.go` | 21 TypeSpecs, port validation |
| `internal/shell/state.go` | Mutable state + RWMutex |
| `internal/transport/routes.go` | 16 HTTP routes on :8000 |
| `internal/mcp/bridge.go` | MCP tools on :8080 |
| `transport/static/` | Explorer UI (`go:embed`) |

---

## Commit Convention

```
feat|fix|chore: <description> [task:YYYYMMDD-NNN]
```

---

## Common Patterns

### Adding a new route
1. Define handler in `internal/transport/`
2. Register in route table
3. Add table-driven test
4. Verify with `curl` against running kernel

### Adding a new morphism behavior
1. Update `internal/fold/evaluate.go` — pure core only
2. Update `internal/shell/state.go` — effect shell Apply
3. Add to morphism log format
4. Table-driven test in `internal/fold/`

### Adding a new TypeSpec
1. Add to `internal/operad/registry.go`
2. Update ontology.json (SOT)
3. Add port definitions
4. Test port validation
