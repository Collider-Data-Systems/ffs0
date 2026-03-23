# mo:os Vision Architecture — Multi-Kernel Hypergraph

**Date:** 2026-03-14
**Author:** Sam Maassen + Claude
**Status:** Vision — informs roadmap, NOT implemented in v0.1.0
**SOT rank:** 3 (design). ontology.json (rank 1) and doctrine (rank 2) remain authoritative for current state.

---

## 1. The Multi-Level Hypergraph

### 1.1 Kernel as Node in H

The kernel is sovereign — but sovereignty is *scoped*. From inside the kernel, the graph is the world. From outside, the kernel instance is itself a node in a larger hypergraph H.

```
Hypergraph H:
  ├── node: kernel-instance-A  (type: kernel_runtime, OWNS graph G_A)
  ├── node: kernel-instance-B  (type: kernel_runtime, OWNS graph G_B)
  ├── node: user-sam           (type: user, OWNS workspace)
  ├── node: group-research     (type: group, OWNS members)
  └── wire: CAN_FEDERATE(kernel-A, kernel-B)
```

Each kernel instance OWNS its own graph G_i as a full subcategory. Cross-kernel communication happens via morphism bundle exchange — CAN_FEDERATE (MOR12) already exists in the ontology for this purpose.

### 1.2 Users, Admins, Groups as Nodes in H

The IRL social topology of users IS a subgraph of H. Users who downloaded the kernel, who forked it, who collaborate — their relationships form edges in H. This is not metaphor; it's structure.

### 1.3 Wolfram Parallel

Stephen Wolfram's key insight: the observer is *embedded in* the hypergraph. Their causal cone is what they call "physics." In mo:os terms:

- **H** = the full hypergraph (all kernel instances, all users, all groups)
- **G_i** = a single kernel's graph (local observer's world)
- **S4 projection** = the observer's causal cone (what the Explorer shows)
- **Multiple kernels** = multiple observers, each with their own causal cone

The "S4 read-only" badge on the Explorer is literally this: you're seeing a projection, never the full state.

### 1.4 Key Principle

**Sovereignty is local, not global.** Each kernel is authoritative within its own G_i. No kernel claims authority over H. Federation is negotiated, not imposed.

---

## 2. Agent as Composed Function

### 2.1 Formal Signature

```
agent : (GraphState × Channel) → Program
```

Where:
- `GraphState` arrives via SSE tap (`/log/stream`) — it's a functor output
- `Channel` = { SSE tap, filesystem tap, UI tap, chat tap } — all URN-addressable
- `Program` = a sequence of morphisms the kernel validates before applying

### 2.2 Composition

An agent is not a special entity. It's a morphism factory:

```
read_channel ∘ interpret ∘ emit_morphisms
```

- **SSE tap** = `/log/stream` (already implemented, Week 2)
- **Filesystem tap** = `handoff.md` (current three-agent protocol)
- **UI tap** = future Explorer form submissions
- **Chat tap** = human input via IDE or chat interface

The human and the LLM are both sources on the input side of this composition. A "filesystemtap" is analogous to human input — both are external data sources that produce morphisms when interpreted.

### 2.3 Implications for AgentSpec (OBJ21)

Current `agent_spec` has `CAN_ROUTE` to any adapter. What's missing: the channel composition — the fact that an agent is a product of (graph_tap × human_tap) → morphism_stream — isn't expressed as graph structure yet. It's implicit in how the three-agent protocol *works*, but not reified as nodes and wires.

**Future:** Explicit channel bindings as typed wires on AgentSpec. Each input channel is a wire with a protocol contract.

---

## 3. Code as Leaves in the Hypergraph

### 3.1 The Black Box Boundary

Code runs in Docker containers, local runtime environments, or any execution context the user controls. The hypergraph sees only metadata:

```
Hypergraph:
  └── node: my-tool (type: system_tool, URN, ports, metadata)
        └── [BLACK BOX: actual Python/JS/Go code, libraries, runtime]
```

The actual code (any language, any libraries) is opaque to the kernel. It runs in the user's/admin's own runtime environment. The kernel knows:
- URN (identity)
- Type (system_tool, OBJ07)
- Ports (what it connects to)
- Metadata (name, description, capabilities)
- **NOT:** the source code, its dependencies, its internal state

### 3.2 Unstructured Data

User filesystems contain files in any format. These are also URN-addressable leaves:
- The hypergraph stores metadata (URN, path, format, size, hash)
- The actual file content is a black box
- Access is via filesystem tap, not via kernel internals

### 3.3 Relationship to Strata

- Code artifacts are **S0** (authored) or **S1** (validated schema)
- Their execution effects are **S3** (evaluated, contingent)
- Their projections are **S4** (never ground truth)

SystemTool (OBJ07) is already the black-box boundary in the current ontology. The vision extends this pattern to all external resources.

---

## 4. URN Addressing — Content-Addressable

### 4.1 Current State

URNs are human-readable: `urn:moos:{kind}:{name}`
- Single kernel, no collision risk
- Example: `urn:moos:provider:anthropic`, `urn:moos:agent:claude-code`

### 4.2 Vision: SHA-Based URNs

Multi-kernel network needs collision-free URNs across independent kernel instances:

```
urn:moos:{kind}:{sha256-prefix-8}:{human-hint}
```

Example: `urn:moos:provider:a3f8c2d1:anthropic`

Properties:
- **Content-addressable** like git objects — same content, same hash
- **Collision-free** across independent kernels
- **Human-readable hint** preserved for developer experience
- **Encrypted access** possible via metadata labeling — hash doesn't reveal content

### 4.3 Access Control via URN

Access control operates at multiple levels:
- **Node level:** who can read/write specific URNs
- **Connection level:** who can establish wires between users
- **Transport level:** WebRTC, UDP, HTTP/2-3, gRPC — each with its own auth model

Solutions from database persistence: metadata labeling can be "hidden" behind hashes with encrypted access. Only the kernel with the right key resolves the full URN.

### 4.4 Migration Path

| Version | URN Scheme | Rationale |
|---------|-----------|-----------|
| v0.1.0 | `urn:moos:{kind}:{name}` | Single kernel, human readability |
| v0.2.0 | SHA optional: `urn:moos:{kind}:{sha}:{hint}` | Multi-kernel experiments |
| v0.3.0 | SHA default for new nodes | Production multi-kernel |

---

## 5. Kernel as I/O Fanout

### 5.1 Position in the Stack

The kernel sits between the local system's OS I/O and the graph:

```
┌─────────────────────────┐
│  External I/O           │  SMTP, POP3, TCP/IP, HTTP, WebRTC, gRPC
├─────────────────────────┤
│  KERNEL (fanout/fanin)  │  Express datatypes, construct wires, validate
├─────────────────────────┤
│  Graph (G_i)            │  Nodes, wires, morphism log
├─────────────────────────┤
│  Local Runtime          │  Docker, tools, filesystem, user processes
└─────────────────────────┘
```

### 5.2 Channel Construction

When an external URN establishes a connection, the kernel:
1. Creates a **ProtocolAdapter** (OBJ11) for the transport
2. Negotiates **datatypes** — what schemas, protocols flow over this wire
3. Creates **CAN_ROUTE** (MOR10) wires based on the negotiated contract
4. Begins **dataflow** — morphisms flow over the constructed channel

### 5.3 Datatype Expression

Kernels are the fanout data splitters that distribute communication channels:
- When a channel is established with an external URN, the kernel **expresses its datatypes**
- These datatypes depend on what's being exchanged: information, knowledge, tool execution
- Different subgraph contracts → different datatypes → different protocols

### 5.4 Existing Ontology Coverage

ProtocolAdapter (OBJ11) + CAN_ROUTE (MOR10) already model this at the type level. The vision is their **full dynamic realization**: channels created on the fly from external connections, not just pre-configured in instance files.

---

## 6. UI Lens as Any-Level Inspection

### 6.1 Current State

- Single Explorer view at `/explorer`
- FUN02 (UI_Lens) projects C → React (SVG graph visualization)
- Read-only S4 projection — correct categorically

### 6.2 Vision: Hierarchical Lens

The UI lens should inspect at **any level** of the hypergraph:

| Level | What You See | Example |
|-------|-------------|---------|
| Code (leaves) | Tool source, skill definitions | View system_tool internals |
| Structure | Node containers, app templates | View a program's structure |
| Protocol | Adapters, routes, channels | View transport topology |
| Kernel | Runtime state, morphism log | View kernel internals |
| Inter-kernel | Federation wires, peer state | View H-level topology |

### 6.3 Write Capability

The UI lens can ADD wires and nodes (morphisms go through kernel validation). But it **cannot push to git**. The human controls the publish boundary. This is the distinction between:
- **Graph writes** (kernel-validated, any user with permission)
- **Code commits** (admin-controlled, git push)

### 6.4 Relationship to FUN02

FUN02 already does single-level projection. The vision is **recursive lens composition**: a lens at level N can embed lenses at level N-1, creating a zoomable hierarchy.

---

## 7. App Templates and Admin Control

### 7.1 The Admin/User Boundary

```
ADMIN DOMAIN (git-controlled):
  ├── Kernel source code (Go)
  ├── App templates (OBJ04)
  ├── Ontology definitions (ontology.json)
  └── Push to main/feature branches

USER DOMAIN (runtime-controlled):
  ├── Instance data (hydrated from templates)
  ├── Agent configurations
  ├── Tool bindings
  └── Local filesystem data
```

### 7.2 Template Hydration

The main Git kernel mo:os code should be **fresh and multi-user**. Definitions for structures (app templates) hydrate the **specific runtime user graph**:

1. Admin creates `AppTemplate` (OBJ04) — immutable subgraph pattern
2. Admin commits template to KB
3. User hydrates: template → instance nodes + wires via `CAN_HYDRATE` (MOR02)
4. User customizes their instance within permitted boundaries

### 7.3 Current Baseline

The current `--kb --hydrate` setup IS the baseline for this pattern:
- `instances/*.json` = pre-built hydration data
- `superset/ontology.json` = type system constraints
- `SeedIfAbsent` = idempotent template instantiation

---

## 8. Promoted Projections — From S4 to Kernel Code

### 8.1 The Promotion Pattern

Certain S4 projections become so stable and fundamental that they get "promoted" to kernel code:

```
S4 Projection (ephemeral)
    ↓  [if stable, fundamental, performance-critical]
Go Function (compiled)
    ↓  [becomes]
I-side or O-side of kernel I/O
```

### 8.2 What Gets Promoted

The I-side and O-side of I/O are promoted projections:
- **I-side:** Parsing incoming data (SMTP → morphisms, HTTP → morphisms, gRPC → morphisms)
- **O-side:** Serializing outgoing data (morphisms → SSE events, morphisms → JSON responses)
- **Middle:** The S2-S3 graph that users/groups/admins hydrate — this stays dynamic

### 8.3 The 5 Kernel Colors ARE Promoted Projections

Already described in `doctrine/concepts.md` as F_sem : O_K^op → Go:
- `runtime_surface` (OBJ09) — promoted to HTTP server code
- `protocol_adapter` (OBJ11) — promoted to transport handlers
- `system_tool` (OBJ07) — promoted to tool dispatch
- `infra_service` (OBJ12) — promoted to store backends
- `agnostic_model` (OBJ06) — promoted to LLM routing

Everything else evaluates uniformly through the 4 invariant NTs. The kernel sub-operad IS the set of promoted projections.

### 8.4 Future Promotions = Ontology Evolution

When a new category becomes stable enough to promote:
1. Add new TypeSpec to ontology.json
2. Add Go struct handling in kernel code
3. The adjunction Include_K ⊣ Restrict_K grows by one color

This is how the kernel evolves: categories migrate from "data" to "code" as they stabilize.

---

## 9. Network Topology — No Central Authority

### 9.1 Design Principles

- **No central server.** Only admins for code (git push permissions).
- **Everything is hypergraph** with rules. Rules are morphism-level constraints (operad validation).
- **Local runtime:** Each user runs kernel + Docker containers + tools locally.
- **External sources:** Lenses/scrapers to www for benchmark updates, industry data — keeping superset provenance guarded.

### 9.2 What Flows Between Kernels

When two kernels establish CAN_FEDERATE:
- **Morphism bundles** (state synchronization)
- **Schema negotiations** (what types are compatible)
- **Scope projections** (what subgraph is visible to the peer)

All data/communication goes through kernels. Agents are functions inside, like any other program structure. Any "upper program" defines "lower programs," ultimately hitting code at leaves.

### 9.3 Local Data

- **Filesystem** with any format files — distributed local state
- **User input** — chat, UI, voice — all channel taps
- **Docker containers** — tools running in isolated environments
- Kernels express datatypes for channels open to the right users

### 9.4 Node Accessibility

Node accessibility is enabled **physically** in a network (not just logically in a graph). A wire in H between two users represents a real connection — WebRTC, UDP, HTTP/2-3, gRPC. The protocol depends on what's being exchanged and what the network supports.

---

## 10. Group/Social Network as Subgraph

### 10.1 The Social Topology

If we consider the hypergraph encompassing both digital and social networks, then user relationships form a subgraph of H:

```
H:
  ├── user-alice ──[KNOWS]── user-bob
  ├── user-bob ──[KNOWS]── user-carol
  ├── group-research ──[OWNS]── {alice, bob, carol}
  └── domain-nlp ──[RELATED]── group-research
```

This is loosely Wolfram's idea applied to social structure: the IRL user network is a projection of H.

### 10.2 Groups as Subgraph Hubs

Any IRL/social user network can be used to **hydrate a group**:
- The group/domain topologies are unlocked to H with their **inner hub**
- Hubs emerge naturally from group topology (most-connected nodes)
- Physical connections (fast, reliable, safe) emerge from kernels' datatype expression
- Dataflow over wires constructed by group contracts

### 10.3 Feature-Group Duality

Groups relate to features. Features relate to domains. There's likely a duality:
- **Group topology** = who works together
- **Feature topology** = what they work on
- The intersection = the active subgraph

This could inform connection prioritization: users in the same feature-group get optimized transport (low-latency WebRTC data channels), while cross-group communication uses reliable but slower HTTP/2.

---

## 11. Transport Layer Vision

### 11.1 Protocol Mapping to Strata

| Strata | Transport | Rationale |
|--------|-----------|-----------|
| S0-S1 | Reliable ordered (HTTP/2, gRPC) | Authored/validated data must not be lost |
| S2-S3 | Reliable streams (WebSocket, HTTP/2) | Materialized/evaluated state needs consistency |
| S4 | Unreliable datagrams OK (WebRTC, UDP) | Projections are ephemeral, can be re-derived |

### 11.2 Causal Invariance and QUIC

Independent QUIC streams map to independent morphisms on disjoint subgraphs. This is **causal invariance** at the transport level:
- Morphisms on disjoint subgraphs **commute** — order doesn't matter
- Each gets its own QUIC stream — no head-of-line blocking
- Morphisms on overlapping subgraphs are serialized within a single stream

### 11.3 HTTP/3 Research

Reference: `.agent/knowledge_base/reference/http3.pdf` (Gemini research, 18pp)

Key finding: HTTP/3's multiplexed streams naturally map to the causal structure of the morphism log. This isn't forced — it's a categorical correspondence.

---

## 12. Ontology Evolution Roadmap (Post v0.1.0)

### 12.1 New Objects (Candidates)

| ID | Name | Type | Purpose | Strata | Rationale |
|----|------|------|---------|--------|-----------|
| OBJ22 | DataChannel | `data_channel` | Typed communication wire with protocol schema | S2-S3 | Kernels express datatypes for channels |
| OBJ23 | Group | `group` | User group with domain topology, inner hub | S2-S3 | Social network as subgraph |
| OBJ24 | FileSystemTap | `filesystem_tap` | External data source (filesystem, API, scraper) | S2 | Agent input channels, www lenses |

### 12.2 New Morphisms (Candidates)

| ID | Name | Decomposition | Purpose | Rationale |
|----|------|--------------|---------|-----------|
| MOR17 | CAN_INSPECT | `LINK(lens, 'inspects', target, 'observed')` | UI lens → any graph level | Hierarchical lens |
| MOR18 | CAN_PROMOTE | `LINK(projection, 'promotes', kernel_fn, 'compiled')` | Stable projection → Go function | Category migration |
| MOR19 | CAN_JOIN | `LINK(user, 'member', group, 'participant')` | User → Group membership | Social topology |

### 12.3 New Categories (Candidates)

| ID | Name | Objects | Morphisms | Purpose |
|----|------|---------|-----------|---------|
| CAT23 | Federation | Kernel instances | CAN_FEDERATE bundles | Multi-kernel mesh |
| CAT24 | Channel | DataChannel instances | Protocol negotiations | Typed communication |
| CAT25 | Social | Users, Groups | CAN_JOIN, KNOWS | Social network topology |

### 12.4 Evaluation Criteria

Before adding ANY of the above to `ontology.json`:

1. **Decomposition:** Does it cleanly decompose to ADD/LINK/MUTATE/UNLINK?
2. **Stratum assignment:** Clear, unambiguous stratum for instances?
3. **Concrete use case:** At least one instance in current data?
4. **Test coverage:** Can it be tested with existing 8 test packages?
5. **Minimal coupling:** Does it require changes to the 5 kernel colors?

### 12.5 What v0.1.0 Ships (Unchanged)

- 21 objects (OBJ01-OBJ21)
- 16 morphisms (MOR01-MOR16)
- 4 invariant NTs (ADD, LINK, MUTATE, UNLINK)
- 22 categories (CAT01-CAT22)
- 5 functors (FUN01-FUN05)
- 5 strata (S0-S4)
- Single kernel, human-readable URNs, file store, HTTP transport

**This vision document is reference for future direction, not implementation scope.**

---

## 13. Terminology Clarification

The user raised: "is kernel even the right term for the main program?"

**Yes.** The term is precise:
- In OS theory, the kernel is the privileged core that mediates between hardware (I/O) and user processes (programs)
- In mo:os, the kernel mediates between external I/O and the graph (programs = node-wire structures)
- The kernel validates all morphisms (operad constraints) before applying them — this is privilege
- User code runs in the graph as leaves — this is unprivileged
- The analogy holds: kernel = authority boundary, programs = user space, I/O = external world

The word "projection" the user keeps reaching for maps to multiple categorical concepts:
- **S4 projection:** functor output (FUN02 UI_Lens, FUN05 Benchmark)
- **Scoped projection:** ScopedSubgraph (BFS on OWNS)
- **Causal cone:** what an embedded observer sees (Wolfram)
- **Promoted projection:** stable S4 that becomes kernel code

All are valid uses. The common thread: a projection is a structure-preserving map from a larger category to a smaller one that loses information but preserves composition.

---

*This document lives at `.agent/knowledge_base/design/20260314-vision-architecture.md`*
*Referenced by: SOT hierarchy rank 3 (design), informs roadmap and paper*
*Does NOT override: ontology.json (rank 1), doctrine/*.md (rank 2)*
