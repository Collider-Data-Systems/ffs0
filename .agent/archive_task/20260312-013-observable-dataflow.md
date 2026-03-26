# Task 013: Observable Dataflow — SSE Morphism Stream

**Priority:** P0 — blocks MVP measurements, audit, multi-agent writes
**Depends on:** Tasks 001-011 (all done)
**Estimated effort:** ~80 lines Go, ~20 lines JS

## Goal

Turn the static graph snapshot into a live observable dataflow. Every morphism
applied to the kernel is broadcast in real-time to all connected clients via SSE.

## Categorical Justification

No new invariant NTs. No new morphism types. The 4-NT invariant holds.

- **The stream is a natural transformation** η: C_kernel ⇒ C_observer.
  Each SSE subscriber is an object in the observer category.
  For every morphism m applied in C_kernel, η(m) = SSE push event.
- **Each subscriber is OBJ11 ProtocolAdapter** (type_id: `protocol_adapter`),
  wired to OBJ09 RuntimeSurface via MOR10 CAN_ROUTE.
- **Multi-actor writes already work** — Envelope.Actor carries the URN.
  We just need agent nodes (OBJ21 AgentSpec) seeded at boot.
- **The event payload IS the PersistedEnvelope** — same format as morphism-log.jsonl.

## Implementation

### A. Runtime subscriber system (shell/runtime.go)

Add to Runtime struct:
```go
subscribers   map[string]chan cat.PersistedEnvelope
subscriberMu sync.Mutex  // separate from state RWMutex
nextSubID     int
```

Add methods:
```go
func (r *Runtime) Subscribe() (id string, ch <-chan cat.PersistedEnvelope)
func (r *Runtime) Unsubscribe(id string)
func (r *Runtime) broadcast(entries ...cat.PersistedEnvelope)
```

Call `r.broadcast(result.Persisted)` at the end of `Apply()` (after state update).
Call `r.broadcast(result.Persisted...)` at the end of `ApplyProgram()`.

**Important:** broadcast must NOT hold the state RWMutex. Use non-blocking channel
sends (select with default) so a slow subscriber doesn't block the kernel.

### B. SSE handler (transport/server.go)

New route: `GET /log/stream`

```go
func (s *Server) handleLogStream(w http.ResponseWriter, r *http.Request) {
    flusher, ok := w.(http.Flusher)
    if !ok {
        writeError(w, http.StatusInternalServerError, "streaming unsupported")
        return
    }
    w.Header().Set("Content-Type", "text/event-stream")
    w.Header().Set("Cache-Control", "no-cache")
    w.Header().Set("Connection", "keep-alive")
    w.Header().Set("Access-Control-Allow-Origin", "*")

    id, ch := s.runtime.Subscribe()
    defer s.runtime.Unsubscribe(id)

    for {
        select {
        case <-r.Context().Done():
            return
        case env := <-ch:
            data, _ := json.Marshal(env)
            fmt.Fprintf(w, "event: morphism\ndata: %s\n\n", data)
            flusher.Flush()
        }
    }
}
```

Register: `s.mux.HandleFunc("GET /log/stream", s.handleLogStream)`

### C. Log query parameters (transport/server.go)

Extend `GET /log` to accept optional query params:
- `?after=<RFC3339>` — filter log entries after timestamp
- `?actor=<urn>` — filter by actor URN
- `?type=<ADD|LINK|MUTATE|UNLINK>` — filter by morphism type
- `?limit=<n>` — last N entries

### D. Explorer live update (transport/static/explorer.html)

Add to the Explorer's JavaScript:
```javascript
const es = new EventSource('/log/stream');
es.addEventListener('morphism', (e) => {
    const env = JSON.parse(e.data);
    // Re-fetch state and re-render (simplest MVP approach)
    fetchAndRender();
    // Append to activity log panel
    appendToActivityLog(env);
});
```

Add a small activity log panel below the graph showing the last ~20 morphisms
with timestamp, actor, type, and target URN.

### E. Agent seed nodes (boot sequence)

In the boot/hydration phase, seed three AgentSpec nodes:
- `urn:moos:agent:claude-code` (type_id: agent_spec)
- `urn:moos:agent:vscode-ai` (type_id: agent_spec)
- `urn:moos:agent:antigraviti` (type_id: agent_spec)

Wire each to the root user via OWNS. These become the Actor URNs used by
each IDE/agent when submitting morphisms.

### F. Tests

- `TestSubscribeBroadcast`: subscribe, apply morphism, receive on channel
- `TestUnsubscribe`: unsubscribe, apply morphism, channel closed
- `TestSlowSubscriber`: non-blocking send doesn't block Apply
- `TestLogStreamSSE`: HTTP test with httptest, verify SSE format
- `TestLogFiltering`: query params on GET /log

## Success Criteria

1. `curl -N http://localhost:8000/log/stream` shows SSE events when morphisms are applied
2. Explorer auto-updates when morphisms arrive (no manual refresh)
3. Activity log panel shows actor, timestamp, type for each morphism
4. `GET /log?actor=urn:moos:agent:claude-code` returns only Claude's morphisms
5. Three agent nodes visible in Explorer after boot
6. All existing tests still pass

## Commit

`feat: add SSE morphism stream and live Explorer updates [task:20260312-013]`
