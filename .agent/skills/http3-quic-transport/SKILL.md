---
name: http3-quic-transport
description: HTTP/3 + QUIC transport layer for mo:os kernel — quic-go integration, dual-stack topology, stream types, TLS 1.3, connection migration. Use when working on kernel transport code, network architecture, or upgrading from HTTP/2 to HTTP/3.
---

# HTTP/3 QUIC Transport — mo:os Kernel IO Boundary

Expert on upgrading the mo:os kernel transport layer from HTTP/2 (TCP) to HTTP/3 (QUIC/UDP) using the quic-go library. This is where **kernel meets OS** — the effect shell's network boundary.

---

## Why HTTP/3 for mo:os

The mathematical property that makes this work: **causal invariance ↔ QUIC stream commutativity**.

Independent morphisms in the hypergraph commute (Church-Rosser). Independent QUIC streams transmit without blocking each other during packet loss. The math maps directly to the network:

```
Category Theory:  LINK(A→B) ; LINK(C→D) = LINK(C→D) ; LINK(A→B)  (when disjoint)
QUIC Transport:   Stream α (Agent A: ADD+LINK) ‖ Stream β (Agent B: MUTATE)  (independent)
                  Packet loss on α → ONLY α retransmits. β continues uninterrupted.
```

TCP forces serial ordering on causally independent updates. This is **transport-level HoL blocking** — the exact bottleneck HTTP/3 eliminates.

---

## Protocol Evolution (know the history)

| Feature | HTTP/1.1 (TCP) | HTTP/2 (TCP) | HTTP/3 (QUIC/UDP) |
|---------|---------------|-------------|-------------------|
| Concurrency | Pipelining (FIFO) | Binary multiplexing | Native stream mux |
| HoL Blocking | App + Transport | Transport only | **Eliminated** |
| Encryption | Optional TLS | Mandatory TLS 1.2+ | Built-in TLS 1.3 |
| Connection Setup | 2–3 RTT | 2–3 RTT | **0–1 RTT** |
| Network Migration | Drops on IP change | Drops on IP change | **Connection ID migration** |

---

## quic-go Library

**Pure Go implementation** — no C bindings. RFC 9000/9001/9002/9114 compliant.

```
go get github.com/quic-go/quic-go
```

> [!IMPORTANT]
> This is the **first external dependency** in the mo:os kernel. The zero-dep policy applies to the Pure Core (`internal/cat/`, `internal/fold/`, `internal/operad/`). The Effect Shell (`internal/transport/`, `internal/shell/`) MAY import quic-go.

### Key Types

| quic-go Type | Purpose | mo:os Mapping |
|-------------|---------|---------------|
| `http3.Server` | HTTP/3 server (UDP) | Kernel listener on `:8000` |
| `http3.RoundTripper` | HTTP/3 client | FPU agent client |
| `quic.Stream` | Bidirectional reliable | S0–S3 morphism envelopes |
| `quic.SendStream` | Unidirectional reliable | Morphism log broadcast |
| `quic.ReceiveStream` | Unidirectional reliable | Log subscription |
| HTTP Datagrams (RFC 9297) | Unreliable, congestion-controlled | S4 projections (UI, telemetry) |

### Stream Types Decision

```
Need reliability + bidirectional?  → quic.Stream       (morphism submission)
Need reliability + one-way?        → quic.SendStream    (log replication)
Ephemeral, loss-tolerant?          → HTTP Datagram      (S4 UI projections)
Branching DAG exploration?         → WebTransport       (System 3 reasoning)
```

---

## Dual-Stack Architecture (MANDATORY)

```
┌──────────────────────────────────┐
│        mo:os Kernel :8000         │
├──────────────────────────────────┤
│  HTTP/3 (UDP) ← External agents  │  ← eliminates HoL blocking
│  HTTP/2 (TCP) ← Local IPC        │  ← leverages kernel offloading
│  Alt-Svc header announces H3     │
└──────────────────────────────────┘
```

> [!WARNING]
> HTTP/3 is NOT always faster than HTTP/2. On localhost/loopback, TCP has decades of kernel optimizations (TSO, GRO, zero-copy). QUIC in userspace generates expensive user-kernel boundary transitions. Use HTTP/2 for local, HTTP/3 for distributed agents.

### Reference Implementation

```go
package transport

import (
    "crypto/tls"
    "log"
    "net/http"
    "github.com/quic-go/quic-go/http3"
)

func InitializeTransport(mux *http.ServeMux, certPath, keyPath string) {
    h3Server := &http3.Server{
        Handler: mux,  // All 16 kernel routes
        Addr:    ":8000",
    }

    // HTTP/2 fallback (TCP) — announces Alt-Svc for H3 upgrade
    go func() {
        log.Printf("Starting mo:os HTTP/2 fallback on TCP :8000")
        err := http.ListenAndServeTLS(":8000", certPath, keyPath,
            http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
                w.Header().Set("Alt-Svc", `h3=":8000"; ma=86400`)
                mux.ServeHTTP(w, r)
            }))
        if err != nil { log.Fatal(err) }
    }()

    // Primary HTTP/3 (UDP)
    log.Printf("Starting mo:os HTTP/3 kernel transport on UDP :8000")
    err := h3Server.ListenAndServeTLS(certPath, keyPath)
    if err != nil { log.Fatal(err) }
}
```

---

## TLS 1.3 Requirements

QUIC **mandates** TLS 1.3 — no negotiation:
- Local dev: self-signed certs via `mkcert` or Go `crypto/tls` generation
- Production: proper CA-signed certs
- QUIC Connection IDs enable **connection migration** (WiFi → cellular without re-handshake)

---

## Concurrency & Mutex Strategy

With HTTP/3 unlocking massive concurrent streams, the `sync.RWMutex` in `shell.Runtime` becomes the primary bottleneck:

```
Read operations (RLock):     GET /state, GET /log, GET /state/wires/*
                             → Thousands of QUIC streams concurrently, no blocking

Write operations (Lock):     POST /morphisms
                             → Channel-based ingestion queue:
                               QUIC handler → buffered channel → single writer goroutine
                               → batch validate → batch append to log → fold
                             → Amortizes mutex acquisition over batches
```

---

## QPACK Header Compression

HTTP/3 uses QPACK (not HPACK) for header compression. Dedicated unidirectional stream for dictionary updates. quic-go handles this intrinsically. Result: near-zero header overhead for high-volume morphism submissions.

---

## Key Files

| File | Purpose |
|------|---------|
| `internal/transport/routes.go` | Current 16 HTTP routes (upgrade target) |
| `internal/transport/server.go` | Server initialization (add dual-stack) |
| `internal/shell/state.go` | RWMutex state (add ingestion channel) |
| `cmd/moos/main.go` | Entry point (add `--cert`, `--key` flags) |
| `.agent/knowledge_base/reference/HTTP_3 Pipelining Hypergraph Data.txt` | Full research doc |
