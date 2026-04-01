---
name: quic-graph-streaming
description: "Use only when the task explicitly asks for QUIC-based graph sync, morphism log streaming, WebTransport DAG execution, or Streamable HTTP transport behavior."
---

# QUIC Graph Streaming — Hypergraph Data over HTTP/3

Expert on mapping mo:os categorical graph operations to QUIC transport primitives. This skill covers the application-level protocol design: how morphisms, logs, and projections flow over the wire.

---

## Core Principle: Strata Map to Transport Reliability

Not all graph data needs the same reliability guarantee. The 5-stratum model maps directly to QUIC transport mechanisms:

| Stratum             | Data                        | Transport                                     | Why                               |
| ------------------- | --------------------------- | --------------------------------------------- | --------------------------------- |
| **S0** Authored     | JSON envelopes (raw syntax) | **Reliable bidirectional** `quic.Stream`      | Must arrive intact for validation |
| **S1** Validated    | Schema-checked payloads     | **Reliable bidirectional** `quic.Stream`      | Integrity critical                |
| **S2** Materialized | Graph-ready instances       | **Reliable unidirectional** `quic.SendStream` | One-way to subscribers            |
| **S3** Evaluated    | Ground truth graph state    | **Reliable unidirectional** `quic.SendStream` | Log replication                   |
| **S4** Projected    | UI/telemetry/embeddings     | **Unreliable HTTP Datagrams** (RFC 9297)      | Ephemeral, loss-tolerant          |

> [!IMPORTANT]
> S4 projections are NEVER ground truth (AX2). If a datagram is lost, the client simply renders the next one. This is why unreliable transport is correct — it matches the ontological status of the data.

---

## Pattern 1: Morphism Log Streaming

The true kernel state = `fold(log[0..t])`. New agents must replay this log to sync.

```
Kernel                              Agent (FPU)
  │                                    │
  │──── quic.SendStream ──────────────▷│  (unidirectional, reliable)
  │     JSONL morphism entries         │
  │     Pushed on each Apply()         │
  │                                    │
  │     If packet loss on stream:      │
  │     ONLY this stream retransmits   │
  │     Other streams unaffected       │
```

### Implementation Pattern

```go
// On successful Apply():
func (rt *Runtime) broadcastMorphism(env Envelope) {
    for _, stream := range rt.subscribedStreams {
        data, _ := json.Marshal(env)
        data = append(data, '\n')  // JSONL format
        stream.Write(data)         // quic.SendStream
    }
}
```

---

## Pattern 2: Concurrent Morphism Submission

Multiple agents submit morphisms simultaneously via independent QUIC streams:

```
Agent A ──Stream α──▷ POST /morphisms {ADD node1}     ─┐
Agent B ──Stream β──▷ POST /morphisms {MUTATE node2}   ─┼──▷ Ingestion Channel ──▷ Writer
Agent C ──Stream γ──▷ POST /morphisms {LINK n3→n4}     ─┘         (batch fold)
```

Packet loss on α → β and γ continue. **Causal invariance guarantees correctness** regardless of arrival order (when morphisms are topologically independent).

---

## Pattern 3: S4 Projection Broadcasting (Datagrams)

Explorer UI updates, metric surfaces, embedding snapshots — all S4:

```go
// HTTP Datagram — unreliable, congestion-controlled, encrypted
func (rt *Runtime) broadcastProjection(view []byte) {
    // If datagram dropped: client ignores, renders next frame
    // Like video streaming — stale frames are worthless
    rt.datagramConn.SendDatagram(view)
}
```

This replaces the current SSE stream (`/log/stream`) for ephemeral UI updates. SSE over TCP suffers from HoL blocking. Datagrams over QUIC don't.

---

## Pattern 4: WebTransport for System 3 DAG Reasoning

System 3 = multi-path DAG reasoning via beam search / MCTS over the morphism space.

```
Kernel spawns beam search:
  Branch 1 ──▷ quic.SendStream ──▷ FPU evaluates
  Branch 2 ──▷ quic.SendStream ──▷ FPU evaluates
  Branch 3 ──▷ quic.SendStream ──▷ FPU evaluates

Kernel prunes Branch 2 (invalid composition):
  → CancelWrite(stream2)          // Instant teardown
  → Branch 1 & 3 continue         // No disruption
```

Uses `webtransport-go` library (companion to quic-go). Each DAG branch = one stream. Pruning = stream cancellation. No TCP teardown overhead.

---

## Pattern 5: MCP Bridge over Streamable HTTP

Current MCP: SSE over TCP (HoL blocking vulnerable).
Next-gen MCP: **Streamable HTTP** over QUIC.

```
Before:  FPU ←─ SSE (TCP) ←── MCP Bridge (:8080)     ← HoL blocking
After:   FPU ←─ Bidirectional QUIC Stream ←── Kernel  ← No HoL blocking
```

A single bidirectional QUIC stream replaces the dual SSE+POST channels:

- Read: tool results, graph state queries
- Write: tool calls, morphism proposals
- No separate SSE endpoint needed

---

## Performance Boundaries

### When HTTP/3 wins

- Distributed agents (WAN, cellular, lossy networks)
- High concurrency (100+ simultaneous morphism streams)
- Connection migration (mobile FPUs changing networks)
- Mixed reliability needs (reliable morphisms + unreliable projections)

### When HTTP/2 wins

- Localhost / loopback IPC
- Single-agent local development
- Bulk sequential uploads

### Decision rule

```
if agent.isLocal() {
    use HTTP/2 (TCP)  // OS kernel offloading
} else {
    use HTTP/3 (QUIC) // Eliminate HoL blocking
}
```

---

## Anti-patterns

- ❌ Using reliable streams for S4 projections (waste of retransmission bandwidth)
- ❌ Using unreliable datagrams for S0–S3 (morphisms MUST arrive intact)
- ❌ Assuming HTTP/3 is always faster (loopback TCP outperforms userspace QUIC)
- ❌ Blocking all streams on a single mutex (use ingestion channel + batch writer)
- ❌ SSE for real-time UI when datagrams are available

---

## Key References

- Research docs: `.agent/dev/reference/`
- quic-go: `github.com/quic-go/quic-go` (RFC 9000, 9114)
- webtransport-go: `github.com/quic-go/webtransport-go`
- HTTP Datagrams: RFC 9297
- QPACK: RFC 9204
