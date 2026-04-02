# mo:os Codex — Unified Pre-Code Reference

Date: 2026-04-02 | T=152
Mode: Discussion only, no kernel rebuild edits
Supersedes: codex-milestone-01.md, codex-milestone-02.md, codex-milestone-03.md

---

## 1. Foundations

### 1.1 Three-Layer Model

```
┌─────────────────────────────────────────────┐
│  L3: HDC/VSA  (compute + similarity)        │
│  φ(node) = ⊕{hypervectors of relations}     │
├─────────────────────────────────────────────┤
│  L2: Spivak Operads  (grammar / types)      │
│  ports · wiring diagrams · composition law   │
├─────────────────────────────────────────────┤
│  L1: Wolfram Hypergraph  (runtime)          │
│  nodes · relations · rewrite rules           │
└─────────────────────────────────────────────┘
```

A **relation** (L1) IS a **wire connecting typed ports** (L2) IS a **hypervector binding** (L3). Same object, three views.

### 1.2 The Catamorphism

```
state(t) = fold(log[0..t])
```

The append-only log is truth. State is derived. Every rewrite is logged. Any state can be replayed from genesis.

### 1.3 Four Rewrites — The Only Operations

| Rewrite | What it does |
|---------|-------------|
| **ADD** | Create a new node with typed properties |
| **LINK** | Create a new relation (hyperedge) connecting nodes |
| **MUTATE** | Change one typed property value on one existing node |
| **UNLINK** | Remove one relation |

Nothing else exists. An edge does not "do" anything. A node does not "call" anything. The kernel receives a rewrite request, validates it against constraints, applies it, and logs it. That is the entire runtime.

### 1.4 Five Causal Invariants

| ID | Invariant | Formal | Scope |
|----|-----------|--------|-------|
| CI-1 | Church-Rosser commutativity | $M_a ; M_b = M_b ; M_a$ when $\text{affected}(M_a) \cap \text{affected}(M_b) = \emptyset$ | All rewrites |
| CI-2 | Projection naturality (structure-preserving only) | $\text{Project}(\text{Apply}(M, S)) = \text{Apply}(M', \text{Project}(S))$ for projections where a corresponding $M'$ is defined | Only projections with declared rewrite correspondence |
| CI-3 | Identity stability | $\forall M, \forall x: \text{urn}(M(x)) = \text{urn}(x)$ | All rewrites |
| CI-4 | Log replay determinism | Same log → same state, always | Per kernel |
| CI-5 | Rewrite category stability | Permitted rewrite categories do not change under rewrites — only governance changes the operad | All non-governance rewrites |

CI-2 note: NOT all projections commute with all rewrites. Aggregate projections (counts, rankings, UI composites) may have no natural $M'$. CI-2 applies only when the projection is structure-preserving and the rewrite correspondence is explicitly declared. Projections that do not satisfy CI-2 are "lossy" — valid for display, invalid as source of truth.

Causal invariance is strictly stronger than confluence. Independent rewrites on disjoint node sets commute.

---

## 2. Nomenclature

### 2.1 Decision Table

| Concept | Use this | Not this | Layer |
|---------|----------|----------|-------|
| Identity point in graph | **node** | element, vertex, anchor, object | L1 |
| Typed connection between nodes | **relation** | binding, edge, wire, association | L1 |
| Category of a relation | **relation type** | binding kind, wire kind | L1/L2 |
| Interface point on a node type | **port** | slot, endpoint | L2 |
| Valid composition rules | **operad** | CS grammar, categorical space | L2 |
| Type registry | **operad** (or registry) | grammar, schema | L2 |
| Role a node plays in a relation | **role** | participant | L1/L2 |
| Attachment point (role + port) | **incidence** | binding slot | L1 |
| Graph transformation operation | **rewrite** | morphism (for the op), update, mutation | L1 |
| Log of all rewrites | **causal graph** | morphism log, event log | L1 |
| Category of allowed rewrites | **rewrite category** (WF01-WF15) | named relation, UML association | L1/L2 |
| Node that represents a discrete interaction artifact | **interaction node** | transition, event, message | L1 |
| HDC vector multiply | **binding** (HDC only) | — | L3 |
| HDC vector add | **bundling** | — | L3 |
| HDC encoding of a node | **hypervector** / φ(x) | embedding | L3 |
| Node identity | **URN** | SHA hash, content address | all |
| Reference from one property to another node's URN | **`_urn` (single) or `_urns` (plural)** | `_ref`, `_refs` | all |
| Access control | **permission / capability** | content-addressing | all |
| Typed key-value on a node | **property** | field, payload, attribute | L1 |

### 2.2 Forbidden Terms

| Do not use | Why | Replacement |
|------------|-----|-------------|
| binding (for graph) | Collides with HDC ⊗ operation | relation |
| edge | Implies 2-arity only | relation |
| morphism (for the wire) | Morphism = the rewrite operation, not the result | relation |
| kind | Ambiguous, deprecated | Use specific type suffixes: `delegate_type`, `compute_type`, `storage_type` |
| object | Implies OOP behavior and state encapsulation | node |
| schema (for the operad) | Too database-flavored | operad |
| transition (for interaction nodes) | Collides with "state transition" (= rewrite application) | interaction node |
| _ref / _refs (as property suffix) | Ambiguous — could be URN, could be opaque ID | `_urn` (single) or `_urns` (plural) |

### 2.3 The Critical Distinction

A **relation** exists in the graph because a past LINK rewrite created it. It will persist until a future UNLINK rewrite removes it. It does not carry messages, invoke methods, or trigger behavior. It is topology — structure that the kernel reads when validating future rewrites.

A **rewrite category** (WF01-WF15) classifies which ADD/LINK/MUTATE/UNLINK operations are allowed, under what constraints, on what port types, with what authority. It is NOT a named static relationship. It is NOT a UML association.

---

## 3. Architecture

### 3.1 Five Planes

| Plane | Contains | Role |
|-------|----------|------|
| Governance | Principal, delegate, capability, policy, promotion | Who can do what |
| Ontology | Shared operad, rewrite categories, invariants | What is valid |
| Instance | Per-kernel realized graph + rewrite log | What exists now |
| Substrate | CPU, GPU, container, storage, network | What runs where |
| Projection | UI, file tree, API, embeddings | Read-only views — **never source of truth** |

### 3.2 Strata

| Stratum | Name | Description |
|---------|------|-------------|
| S0 | Authored | Human-written seeds, design docs, industry data |
| S1 | Validated | Operad-checked, type-approved |
| S2 | Materialized | Hydrated into kernel graph, operational |
| S3 | Evaluated | Concurrent subgraph eval: hypervector encoding, ranking |
| S4 | Projected | UI, filesystem, API — never ground truth |

Every property records its stratum origin. S4 cannot become source of ontology truth.

### 3.3 Multi-Kernel and Federation

- Each kernel maintains a local instance graph consistent with the shared ontology (operad, rewrite categories, invariants). The kernel validates inbound rewrites against the ontology before applying them.
- Working hypothesis: this consistency relationship may be formalizable as a functor $K: \text{Ontology} \to \text{Instance}$, where the ontology category has node types as objects and rewrite categories as morphisms, and the instance category has node sets as objects and applied rewrites as morphisms. **This is not yet proven — it is a design conjecture guiding implementation.**
- Kernels share a common **ontology** but maintain separate **local instance** state.
- Local state: $S_k(t) = \text{fold}(L_k[0..t])$ — each kernel folds its own log.
- Federation is explicit sync, not implicit global memory.
- No kernel rewrites another kernel's history.
- Observers (non-kernel-owning users) have read-only access via projection, with auth. Access is separate from kernel ownership.

### 3.4 Identity Discipline

- Identity is a **URN** — stable, not content-addressed. Changing properties does not change identity (CI-3).
- SHA hashes are for integrity verification only.
- Access is controlled by capability relations, not by hash knowledge.
- Owner is an **immutable property** set at ADD time. No MUTATE can touch it.
- Authority model: $P(\text{delegate}) \subseteq P(\text{principal})$ — enforced at rewrite validation time.

---

## 4. Node Type Catalog

### 4.0 Topology-Property Boundary Rule

**Relations are truth. Properties never duplicate topology.**

If a fact is expressed as a relation (LINK), it MUST NOT also be stored as a property on either participating node. The graph topology is the single source of structural truth.

To discover which capabilities a delegate holds, query the graph for WF02 relations incident to that delegate node. Do NOT maintain a `capability_urns` property on the delegate.

If a denormalized cache is needed for performance, it is an **S4 projection cache** — labeled as such, never treated as authoritative, and rebuilt from topology on demand.

| Pattern | Correct | Incorrect |
|---------|---------|-----------|
| "Which capabilities does agent X hold?" | Query: all WF02 relations incident to X | Read: X.capability_urns |
| "Which role does user Y have?" | Query: all WF02 relations incident to Y where target is role node | Read: Y.role_urns |
| "Which ports does kernel Z expose?" | Query: all WF05 relations incident to Z | Read: Z.port_urns |

### 4.1 S2 Infrastructure Anchors

Port columns list the port names through which this node type **commonly participates** in relations, as governed by the operad. The operad is the authority on valid compositions — not this table. This table is a convenience summary.

| Node type | URN pattern | Properties | Common ports (out) | Common ports (in) |
|-----------|-------------|------------|---------------------|-------------------|
| user (principal) | `urn:moos:user:<name>` | name ᴵ, created_at ᴵ | owns, governs | identity |
| kernel realization | `urn:moos:kernel:<ws>.<name>` | version ᴵ, status ᴹ | exposes, computes-on, persisted-in | hosted-on, kb-source |
| workstation | `urn:moos:workstation:<name>` | hostname ᴵ, os ᴵ, arch ᴵ | hosts, contains | child |
| agent (delegate) | `urn:moos:agent:<user>.<name>` | name ᴵ, delegate_type ᴵ, owner_urn ᴵ, transport_type ᴹ, model ᴹ, system_prompt ᴹ, temperature ᴹ, status ᴹ | connects-to, participates | governed-by |
| endpoint | `urn:moos:endpoint:<ws>.<kernel>.<port>` | transport_type ᴵ, status ᴹ | implements | exposed-by, connected-to |
| compute substrate | `urn:moos:compute:<ws>.<type>` | compute_type ᴵ, execution_model ᴵ, capacity ᴹ | bound-to | contained-in, computed-by |
| storage substrate | `urn:moos:storage:<ws>.<name>` | storage_type ᴵ, path_or_url ᴵ, status ᴹ | synced-via, provides-kb, bound-to | contained-in, persists, sync-target |
| session | `urn:moos:session:<user>.<agent>.<T>` | status ᴹ, started_at ᴵ, turn_count ᴹ | focus, on | participated-by |
| governance proposal | `urn:moos:proposal:<user>.<slug>` | title ᴵ, status ᴹ, evidence_urns ᴹ | promotes-to | — |
| role | `urn:moos:role:<name>` | name ᴵ | — | granted-by |
| capability | `urn:moos:capability:<principal>.<name>` | scope ᴵ, granted_by_urn ᴵ, max_rewrites ᴹ, created_at ᴵ | — | attached-to |

ᴵ = immutable (set at ADD, no MUTATE allowed) · ᴹ = mutable (governed by authority_scope)

Note: `_urn` properties (e.g., `owner_urn`, `granted_by_urn`) are immutable references set at ADD time. They point to a node but are NOT topology — they are provenance stamps. Topology (who currently governs whom, which capabilities are attached) is expressed ONLY through relations.

### 4.2 S1 Grammar Anchors

| Node type | Role in composition | URN pattern |
|-----------|---------------------|-------------|
| protocol | Transport and protocol type semantics | `urn:moos:protocol:<name>` |
| language | Implementation language marker | `urn:moos:language:<name>` |
| runtime | Executable runtime class | `urn:moos:runtime:<name>` |
| package | Dependency identity and constraints | `urn:moos:package:<name>` |
| stratum | Self-describing layer boundary token | `urn:moos:stratum:<name>` |

### 4.3 Domain Interaction Nodes (Proposed, Require Governance Promotion)

These are **interaction nodes** — discrete artifacts that arise during operation. Each is a node with its own identity and immutable content. They do not "carry" messages or "trigger" behavior. They are ADDed to the graph and LINKed to session/context nodes, and the kernel evaluates further rewrites based on the resulting graph state.

| Node type | Why needed | Key properties |
|-----------|-----------|----------------|
| message_packet | First-class message identity in sessions | direction ᴵ, content_type ᴵ, sender_urn ᴵ, content ᴵ, correlation_id ᴵ |
| tool_call | Separate tool invocation from generic message | tool_name ᴵ, arguments ᴵ, requester_urn ᴵ, status ᴹ |
| tool_result | Result identity and provenance chain | status ᴵ, output ᴵ, for_call_urn ᴵ, latency_ms ᴵ |
| event_notice | Async event identity | event_type ᴵ, source_urn ᴵ, timestamp ᴵ |
| stream_chunk | Streaming fragment identity | stream_id ᴵ, seq ᴵ, encoding ᴵ |
| auth_credential_node | Auth identity without secret payload | credential_type ᴵ, issuer_urn ᴵ, scope_urn ᴵ, expiry ᴹ |
| resource_operation | Read/write op identity | operation_type ᴵ, target_urn ᴵ, consistency_mode ᴵ |
| contract_schema | Stable reusable contract identity | schema_uri ᴵ, version ᴵ, compatibility_mode ᴵ |
| port_signature | Typed port compatibility unit | direction ᴵ, cardinality ᴵ, payload_type_urn ᴵ |

---

## 5. Rewrite Categories (WF01-WF15)

These are **categories of allowed rewrites**, not named static relationships. Each category defines what ADD/LINK/MUTATE/UNLINK operations are valid, on which node types, through which ports, under what authority.

A relation in the graph labeled WF01 exists because a past LINK rewrite in category WF01 created it.

| ID | Category | Allowed rewrites | Source port → Target port | Source types | Target types | Authority | MUTATE scope (if applicable) |
|----|----------|-----------------|---------------------------|-------------|-------------|-----------|------------------------------|
| WF01 | Ownership | LINK, UNLINK | owns → child | user | workstation, kernel, storage | principal only | — |
| WF02 | Governance | LINK, UNLINK, MUTATE | governs → governed-by | user | agent, role | principal only | target: `delegate_type`, `transport_type`, `model`, `system_prompt`, `temperature` |
| WF03 | Hosting | LINK, UNLINK | hosts → hosted-on | workstation | kernel | substrate | — |
| WF04 | Containment | LINK, UNLINK | contains → contained-in | workstation | compute, storage | substrate | — |
| WF05 | Exposure | LINK, UNLINK | exposes → exposed-by | kernel | endpoint | kernel | — |
| WF06 | Connection | LINK, UNLINK | connects-to → connected-to | agent | endpoint | delegate with capability | — |
| WF07 | Session | LINK, UNLINK, MUTATE | participates → participated-by | agent, user | session | principal or delegate | session: `status`, `turn_count` |
| WF08 | Substrate binding | LINK, UNLINK | bound-to → binds | compute, storage | workstation | substrate | — |
| WF09 | Compute attachment | LINK, UNLINK | computes-on → computed-by | kernel | compute | kernel | — |
| WF10 | Persistence | LINK, UNLINK | persisted-in → persists | kernel | storage | kernel | — |
| WF11 | Sync (storage-storage) | LINK, UNLINK | synced-via → sync-target | storage | storage | kernel | — |
| WF12 | KB provision | LINK, UNLINK | provides-kb → kb-source | storage | kernel | kernel | — |
| WF13 | Promotion | LINK, UNLINK, MUTATE | promotes-to → promotion-target | governance_proposal | storage, kernel | principal + governance approval | proposal: `status`, `evidence_urns` |
| WF14 | Implementation | LINK, UNLINK | implements → implemented-by | agent, kernel, endpoint | protocol, language, capability, runtime, package | kernel | — |
| WF15 | Semantic (open) | LINK, UNLINK, MUTATE with explicit contract_urn | {semantic} → {semantic} | any | any | per contract_urn | per contract_schema declaration |

**WF15 rule**: allowed only with explicit port names AND a contract_schema reference. No untyped semantic relations.

**MUTATE scope rule**: when a WF category permits MUTATE, the "MUTATE scope" column is exhaustive — no other fields on the target node may be changed under that category. If a field is not listed, a MUTATE targeting it under that WF is rejected.

---

## 6. Property Model

### 6.1 Typed Property + Rewrite

Properties are typed, constrained key-value pairs bound to nodes. They are NOT opaque payload blobs. They are NOT edges to value-nodes. They are NOT denormalized topology caches.

Change mechanism: **MUTATE** is a rewrite with preconditions:
- The target field must be in `allowed_fields` for that node type AND for that rewrite category
- The target field must NOT be in `forbidden_fields`
- The requester must satisfy `authority_scope`
- The new value must pass `validation_urn`

This is not OOP. This is typed rewriting with constraints.

### 6.2 Property Meta Requirements

Every property on every node type must declare:

| Meta-property | Meaning |
|---------------|---------|
| mutability | `immutable` (set at ADD only) or `mutable` (MUTATE allowed) |
| authority_scope | Who can MUTATE: principal, kernel, owner, delegate, or specific capability |
| validation_urn | Schema or constraint reference for valid values |
| stratum_origin | S0/S1/S2/S3/S4 origin of the value |
| cardinality | one, optional, or many |

**Rule**: No mutable property without authority_scope + validation_urn.

### 6.3 MUTATE Boundary Contract

Per node type, define allowed and forbidden fields.

**Global immutables** (no MUTATE ever, on any node type):
- Identity URN
- Creation timestamp (`created_at`)
- Owner URN (`owner_urn`)
- Sender URN (on interaction nodes)

**Law**: MUTATE is valid iff:
1. Field ∈ allowed_fields for that node type
2. Field ∈ MUTATE scope for the rewrite category being invoked
3. Field ∉ forbidden_fields
4. Authority scope is satisfied
5. Validation passes

### 6.4 Topology-Property Boundary

Properties express **intrinsic, per-node state**: what a node IS.
Relations express **structural connections between nodes**: how nodes relate.

**Test**: if the information involves two or more nodes, it is a relation (LINK/UNLINK). If it involves only one node's internal state, it is a property (MUTATE).

| Information | Correct representation | Incorrect |
|-------------|----------------------|-----------|
| Agent's model | Property on agent node (`model ᴹ`) | — |
| Agent's owner | Immutable property (`owner_urn ᴵ`) set at ADD | — |
| Which capabilities agent holds | WF02 relations to capability nodes | `capability_urns` property on agent |
| Which roles user has | WF02 relations to role nodes | `role_urns` property on user |
| Which endpoints kernel exposes | WF05 relations to endpoint nodes | `port_urns` property on kernel |
| Session's turn count | Property on session node (`turn_count ᴹ`) | — |
| Who participates in session | WF07 relations to user/agent nodes | `participant_urns` property on session |

**Exception**: `owner_urn` and `sender_urn` are immutable provenance stamps set at ADD time. They reference another node but are NOT topology. They cannot be UNLINKED, only read. They are closer to "birth certificate" data than to structural relations.

---

## 7. Port Colors and Composition

### 7.1 Color Catalog

| Color | Meaning | Example ports |
|-------|---------|---------------|
| auth | Principal, delegate, role flow | governs, governed-by, granted-by |
| topology | Ownership and hosting shape | owns, child, hosts, hosted-on |
| transport | Network and protocol routing | exposes, connects-to, implements |
| compute | Execution substrate mapping | computes-on, computed-by |
| storage | Persistence and sync | persisted-in, persists, synced-via |
| workflow | Session and task control | participates, focus, on |
| semantic | Open domain relations (WF15) | Per contract_urn |
| projection | Read model / output only | projected-to, rendered-as |

### 7.2 Composition Law

1. Compose only when source and target port colors are declared compatible: $\text{Compat}(c_{\text{out}}, c_{\text{in}}) = \text{true}$.
2. WF01-WF14 define fixed compatibility channels.
3. WF15 is allowed only with explicit semantic port names AND contract_schema reference.
4. No projection-color relation can become source of ontology truth.

---

## 8. Interaction Contracts and Federation

### 8.1 Interaction Node Contract

Every interaction node type (message_packet, tool_call, tool_result, event_notice, stream_chunk, auth_credential_node, resource_operation) must declare:

- Required source node type (what ADDs it / what it LINKs from)
- Required target node type (what it LINKs to)
- Required contract_schema reference
- Required port_signature references
- Allowed rewrite categories
- Deterministic failure mode

**Law**: No interaction node instance is valid without contract_schema and port_signature references.

### 8.2 Federation Sync Contract

Rewrite categories classified by sync requirement:

| Sync mode | Categories | Semantics |
|-----------|-----------|-----------|
| **Strict** | WF01, WF02, WF13 | Must propagate immediately. Conflicts block and require governance resolution. |
| **Eventual** | WF05, WF06, WF07, WF11, WF12, WF14, WF15 | Converge eventually. Conflicts resolved by deterministic tie-break: `(event_time, kernel_id, event_id)`. |
| **Local-only** | WF03, WF04, WF08, WF09, WF10 | Never leave the originating kernel. |

**Rules**:
1. Never rewrite remote history.
2. Strict conflicts block until governance resolves.
3. Eventual conflicts resolve by tie-break tuple, deterministically.

---

## 9. Operational Semantics

Transport (HTTP/2, HTTP/3, MCP, SMTP, filesystem) is the adapter layer. It is NOT part of the graph. The kernel normalizes all inbound data into rewrites. Cross-provider translation (e.g., Anthropic ↔ OpenAI) is a design conjecture that may be formalizable as a natural transformation between functors — a proof obligation, not a default assumption.

### 9.1 Create a delegate

```
ADD  urn:moos:agent:sam.writer
     name="writer" ᴵ, owner_urn=urn:moos:user:sam ᴵ,
     delegate_type="llm" ᴵ,
     model="claude-sonnet-4-6" ᴹ, system_prompt="..." ᴹ,
     temperature=0.7 ᴹ, status="idle" ᴹ,
     created_at=2026-04-02T10:00:00Z ᴵ
```

One node. No relations yet. The delegate cannot do anything.

### 9.2 Grant capability

```
ADD  urn:moos:capability:sam.writer.messaging
     scope=["WF07","WF15"] ᴵ, granted_by_urn=urn:moos:user:sam ᴵ,
     max_rewrites=1000 ᴹ, created_at=2026-04-02T10:01:00Z ᴵ

LINK WF02  [urn:moos:agent:sam.writer] ←→ [urn:moos:capability:sam.writer.messaging]
     authority: principal
```

Now the kernel can check: does this delegate hold a capability covering the requested rewrite category? The check is a graph query — find WF02 relations incident to the delegate node where the other end is a capability node with matching scope. No property on the agent node stores this.

### 9.3 Change delegate spec

```
MUTATE  urn:moos:agent:sam.writer  .model = "claude-opus-4-6"
        rewrite_category: WF02
        authority: owner (urn:moos:user:sam)

MUTATE  urn:moos:agent:sam.writer  .system_prompt = "You are a technical writer..."
        rewrite_category: WF02
        authority: owner
```

Same node, same identity, same relations. Properties changed. Logged. Kernel reads these on next API construction. Both fields are in WF02's MUTATE scope — validated before application.

### 9.4 Start session

```
ADD  urn:moos:session:sam.writer.T152-001
     status="active" ᴹ, started_at=2026-04-02T10:05:00Z ᴵ, turn_count=0 ᴹ

LINK WF07  [urn:moos:session:...] ←→ [urn:moos:user:sam]        role: principal_participant
LINK WF07  [urn:moos:session:...] ←→ [urn:moos:agent:sam.writer] role: delegate_participant
```

### 9.5 Send message

```
ADD  urn:moos:message:sam.T152-001.msg-001
     content="Draft the intro section" ᴵ, sender_urn=urn:moos:user:sam ᴵ,
     content_type="text/plain" ᴵ, created_at=2026-04-02T10:05:30Z ᴵ

LINK WF07  [urn:moos:session:...] ←→ [urn:moos:message:...msg-001]  sequence=1

MUTATE  urn:moos:session:...  .turn_count = 1
        rewrite_category: WF07
        authority: kernel
```

The message did not "travel through a wire." A node was added and linked. The session's turn_count is in WF07's MUTATE scope.

### 9.6 Kernel dispatches to provider

**Zero rewrites.** The kernel reads graph state (delegate properties, session-linked message nodes, capability relations) and projects it into an API call over transport. Transport is invisible to the graph.

### 9.7 Delegate response arrives

```
ADD  urn:moos:message:sam.T152-001.msg-002
     content="# Introduction\nmo:os is..." ᴵ, sender_urn=urn:moos:agent:sam.writer ᴵ,
     content_type="text/markdown" ᴵ, provider_urn="anthropic" ᴵ,
     token_count=347 ᴵ, latency_ms=2840 ᴵ, created_at=2026-04-02T10:05:33Z ᴵ

LINK WF07  [urn:moos:session:...] ←→ [urn:moos:message:...msg-002]  sequence=2

MUTATE  urn:moos:session:...  .turn_count = 2
        rewrite_category: WF07   authority: kernel
MUTATE  urn:moos:agent:sam.writer  .status = "idle"
        rewrite_category: WF07   authority: kernel
```

### 9.8 Tool call

```
ADD  urn:moos:tool_call:sam.T152-001.tc-001
     tool_name="file_write" ᴵ, arguments={path:"intro.md"} ᴵ,
     requester_urn=urn:moos:agent:sam.writer ᴵ, status="pending" ᴹ,
     created_at=2026-04-02T10:05:34Z ᴵ

LINK WF15  [urn:moos:session:...] ←→ [urn:moos:tool_call:...tc-001]

— CAPABILITY CHECK: query graph for WF02 relations from delegate
  to capability nodes. Does any capability's scope include WF15+file_write? —
— If no: MUTATE tool_call.status = "rejected", stop —
— If yes: kernel executes, then: —

ADD  urn:moos:tool_result:sam.T152-001.tr-001
     status="success" ᴵ, output={bytes_written:2048} ᴵ,
     for_call_urn=urn:moos:tool_call:sam.T152-001.tc-001 ᴵ,
     created_at=2026-04-02T10:05:35Z ᴵ

LINK WF15  [urn:moos:tool_call:...tc-001] ←→ [urn:moos:tool_result:...tr-001]

MUTATE  urn:moos:tool_call:...tc-001  .status = "completed"
        rewrite_category: WF15   authority: kernel
```

### 9.9 Revoke capability

```
UNLINK WF02  [urn:moos:agent:sam.writer] ←→ [urn:moos:capability:sam.writer.messaging]
       authority: principal
```

Delegate node still exists. Capability node still exists (audit trail). The relation between them is gone. Next time the delegate requests a WF07 rewrite, the kernel queries for capability relations, finds none with matching scope, and rejects.

### 9.10 End session

```
MUTATE  urn:moos:session:sam.writer.T152-001  .status = "closed"
        rewrite_category: WF07   authority: kernel
MUTATE  urn:moos:agent:sam.writer  .status = "idle"
        rewrite_category: WF07   authority: kernel
```

All relations (participation, message links) remain — they are history. Nothing is deleted. Replay from log recovers any point in time.

---

## 10. Open Design Questions

1. **Structural vs emergent**: Do user, agent, kernel remain structural ontology types, or dissolve into emergent port-signature patterns?
2. **Natural transformation as proof**: Cross-provider translation is conjectured as NT — what is the verification mechanism? (See 3.3: this is a working hypothesis, not settled.)
3. **Presheaf model**: Fibers as local sections of a presheaf, gluing condition as overlap consistency — working hypothesis, not settled theorem.
4. **Principal immutability**: Should principal ownership anchors be globally immutable with zero exceptions?
5. **WF15 governance**: How much structure must a semantic relation carry before it warrants promotion to a dedicated WF?
6. **CI-2 boundary**: Which projections are structure-preserving enough to satisfy CI-2? Need an explicit registry of CI-2-compliant projections vs lossy projections.
7. **S4 projection caches**: When (if ever) are denormalized property caches justified for performance, and what is the rebuild/invalidation contract?

---

## 11. Pre-Code Readiness Gate

Implementation starts only when ALL hold:

1. Every glossary term has exactly one definition and one relation locus. ✓ §2
2. Every node type has URN pattern, required properties (with mutability + authority_scope + validation_urn), and common ports. ✓ §4
3. Every rewrite category (WF01-WF15) has explicit source/target types, ports, allowed rewrites, authority, AND exhaustive MUTATE scope. ✓ §5
4. Every mutable property has authority_scope + validation_urn. ✓ §6
5. Port color compatibility matrix exists for all active colors. ✓ §12
6. Every interaction node type (message, tool, event, stream, auth, resource) has a complete interaction contract or is explicitly rejected. ✓ §8 (contracts declared) / §4.3 (interaction nodes)
7. Federation scope statement assigns every active WF to strict, eventual, or local-only. ✓ §8.2
8. MUTATE boundary contracts cover every mutable field on every active node type. ✓ §6.3
9. Topology-property boundary is respected: no property duplicates what a relation expresses. ✓ §4.0, §6.4

**Gate status: ALL ITEMS CLOSED. Kernel scaffolding may begin.**

---

## 12. Port Color Compatibility Matrix

### 12.1 Port Color Assignments

Every port belongs to exactly one color. The color governs which source→target color pairs produce valid relations.

| Port name | Color | Example node type |
|-----------|-------|-------------------|
| governs | auth | user |
| governed-by | auth | agent, role |
| granted-by | auth | role |
| identity | auth | user |
| promotes-to | auth | governance_proposal |
| promotion-target | auth | storage, kernel |
| owns | topology | user |
| child | topology | workstation, kernel, storage |
| hosts | topology | workstation |
| hosted-on | topology | kernel |
| contains | topology | workstation |
| contained-in | topology | compute, storage |
| binds | topology | workstation |
| exposes | transport | kernel |
| exposed-by | transport | endpoint |
| connects-to | transport | agent |
| connected-to | transport | endpoint |
| implements | transport | agent, kernel, endpoint |
| implemented-by | transport | protocol, language, capability, runtime, package |
| computes-on | compute | kernel |
| computed-by | compute | compute |
| bound-to (compute) | compute | compute |
| bound-to (storage) | storage | storage |
| persisted-in | storage | kernel |
| persists | storage | storage |
| synced-via | storage | storage |
| sync-target | storage | storage |
| provides-kb | storage | storage |
| kb-source | storage | kernel |
| participates | workflow | agent, user |
| participated-by | workflow | session |
| focus | workflow | session |
| on | workflow | session |
| {semantic} | semantic | any (WF15 only) |
| projected-to | projection | any (S4 output, never truth) |
| rendered-as | projection | any (S4 output, never truth) |

### 12.2 Compatibility Matrix

✓ = compatible (truth-carrying relation allowed) · WF15 = semantic allowed with contract_urn · R = read-only sink · — = incompatible / rejected at validation time

| src color \ tgt color | auth | topology | transport | compute | storage | workflow | semantic | projection |
|-----------------------|------|----------|-----------|---------|---------|----------|----------|------------|
| **auth** | ✓ | ✓ | — | — | — | — | ✓ WF15 | R |
| **topology** | — | ✓ | — | — | — | — | ✓ WF15 | R |
| **transport** | — | — | ✓ | — | — | — | ✓ WF15 | R |
| **compute** | — | ✓ | — | ✓ | — | — | ✓ WF15 | R |
| **storage** | — | ✓ | — | — | ✓ | — | ✓ WF15 | R |
| **workflow** | — | — | — | — | — | ✓ | ✓ WF15 | R |
| **semantic** | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | R |
| **projection** | — | — | — | — | — | — | — | — |

**Column R** (projection): projection-color ports may receive from any color (kernel writes S4 views out), but no projection-color relation may become source of ontology truth. Projection columns carry no causal authority.

### 12.3 Declared Compatible Pairs by WF

| WF | src port color | tgt port color | Notes |
|----|---------------|---------------|-------|
| WF01 | topology (owns) | topology (child) | |
| WF02 | auth (governs) | auth (governed-by) | |
| WF03 | topology (hosts) | topology (hosted-on) | |
| WF04 | topology (contains) | topology (contained-in) | |
| WF05 | transport (exposes) | transport (exposed-by) | |
| WF06 | transport (connects-to) | transport (connected-to) | |
| WF07 | workflow (participates) | workflow (participated-by) | |
| WF08 | compute (bound-to) | topology (binds) | compute→topology cross |
| WF08 | storage (bound-to) | topology (binds) | storage→topology cross |
| WF09 | compute (computes-on) | compute (computed-by) | |
| WF10 | storage (persisted-in) | storage (persists) | |
| WF11 | storage (synced-via) | storage (sync-target) | |
| WF12 | storage (provides-kb) | storage (kb-source) | kb-source treated as storage color |
| WF13 | auth (promotes-to) | auth (promotion-target) | |
| WF14 | transport (implements) | transport (implemented-by) | |
| WF15 | semantic | any | contract_urn required |

**Rule**: Any (src color, tgt color) pair not listed in §12.3 is **rejected at validation time** — no exception, no silent success.

---

## 13. CI-2 Projection Registry

### 13.1 What CI-2 Requires

CI-2 holds for projection P if there exists a rewrite correspondence M' such that:

```
Project(Apply(M, S)) = Apply(M', Project(S))
```

This means: applying a rewrite M to the full graph then projecting gives the same result as projecting first then applying the corresponding M' to the projected view. Only structure-preserving projections can satisfy this.

A projection NOT in this registry is **lossy** — valid for display, invalid as source of truth, does not satisfy CI-2.

### 13.2 CI-2–Compliant Projections

| Projection ID | Definition | Source WF(s) | Corresponding M' | Notes |
|---------------|-----------|-------------|-----------------|-------|
| P_node(urn) | All properties of one specific node | Any MUTATE on that node | M' = MUTATE same field on projected record | Single-node, deterministic |
| P_agent(urn) | Agent node + all mutable property values | WF02 MUTATE | M' = MUTATE corresponding projected field | Compliant only for MUTATE — not for ADD/UNLINK of unrelated nodes |
| P_session_participants(urn) | Set of all WF07 relations incident to a session | WF07 LINK, UNLINK | M' = add/remove entry from projected set | Set-valued, but structurally faithful |
| P_capabilities(agent_urn) | Set of all WF02 relations from agent to capability nodes | WF02 LINK, UNLINK | M' = add/remove capability entry | Replaces the forbidden `capability_urns` property pattern |
| P_kernel_endpoints(kernel_urn) | Set of all WF05 relations from kernel to endpoint nodes | WF05 LINK, UNLINK | M' = add/remove endpoint entry | Replaces the forbidden `port_urns` property pattern |
| P_rewrite_log(kernel_urn) | Ordered list of all logged rewrites for a kernel | Any rewrite | M' = append to log | Append-only; trivially CI-2 compliant |

### 13.3 Lossy Projections (Valid for Display, NOT CI-2)

These projections have no defined M'. They may be used in S4 views but must never be used as authority for determining graph state.

| Projection | Why lossy | Notes |
|-----------|-----------|-------|
| P_dashboard_counts | Aggregate counts (active sessions, idle agents, etc.) | No M' — many rewrites can produce the same delta or cancel |
| P_message_feed | Time-ordered display stream of message_packet nodes | Ordering is derived; insertion doesn't commute with ranking |
| P_ui_card(urn) | Rendered summary card composed from multiple node properties | Many-to-one: same display from different graph states |
| P_search_rank | HDC/VSA similarity ranking of nodes | S3 evaluation artifact; ranking is non-invertible |
| P_file_tree | Filesystem rendering of storage nodes and relations | Filesystem layout != graph topology; multiple S4 views possible |
| P_api_snapshot | REST/GraphQL response containing a computed view | Joins and computed fields have no natural M' |

**Rule**: Lossy projections must be marked `"stratum": "S4"` in all representations. They MUST NOT be compared, diffed, or merged to produce causal decisions.

---

## 14. S4 Cache Denormalization Contract

### 14.1 When an S4 Cache is Justified

An S4 denormalization cache is permitted only when ALL of:
1. The corresponding CI-2–compliant query (§13.2) exists and is the definitive source.
2. The query is proven expensive enough to warrant caching (latency budget exceeded).
3. The cache is **explicitly labeled** `"stratum": "S4"` everywhere it appears.
4. The cache rebuild procedure is documented and automated.
5. The cache is **never read for authority** — only for display/perf.

### 14.2 Allowed Cache Fields

Only denormalize what can be derived from a CI-2–compliant projection. Allowed S4 cache patterns:

| Cache name | Backing CI-2 projection | Cached fields | Invalidation trigger |
|------------|------------------------|---------------|----------------------|
| agent_capabilities_cache | P_capabilities(agent_urn) | `[{capability_urn, scope, max_rewrites}]` | Any WF02 LINK or UNLINK on that agent |
| session_participants_cache | P_session_participants(session_urn) | `[{participant_urn, role}]` | Any WF07 LINK or UNLINK on that session |
| kernel_endpoints_cache | P_kernel_endpoints(kernel_urn) | `[{endpoint_urn, transport_type, status}]` | Any WF05 LINK or UNLINK on that kernel |
| agent_properties_cache | P_agent(agent_urn) | Full mutable property set | Any WF02 MUTATE on that agent |

### 14.3 Forbidden Cache Patterns

The following are explicitly forbidden — they violate topology-property boundary or CI-2:

| Forbidden cache | Why |
|----------------|-----|
| `capability_urns` property on agent node | Topology stored as property — violates §4.0 rule |
| `participant_urns` property on session node | Topology stored as property — violates §4.0 rule |
| `port_urns` property on kernel node | Topology stored as property — violates §4.0 rule |
| Any S4 cache read by rewrite validator | Cache used for authority — forbidden |
| Any S4 cache used to initialize ADD/LINK source | Bootstrapping truth from projection — forbidden |

### 14.4 Cache Lifecycle Contract

```
BUILD:      query = run CI-2 projection against current graph state
            write result with stratum="S4", cache_ts=now, source_urn=[origin node]

INVALIDATE: trigger = any rewrite in the backing WF category touching the source node
            action  = mark cache stale OR delete and rebuild before next read

READ:       if stale → rebuild before returning
            always label response: stratum="S4", authoritative=false

AUDIT:      log every cache rebuild with: timestamp, trigger_rewrite_urn, duration_ms
```

### 14.5 S4 Stratum Rule

All S4 cache data must carry:

```json
{
  "stratum": "S4",
  "authoritative": false,
  "backing_projection": "<projection-id from §13.2>",
  "cache_ts": "<ISO-8601>",
  "invalidated_by_wf": ["WF02"]
}
```

**No field in S4 stratum data may be promoted to S1 or S2 without explicit governance promotion (WF13).**
