# Conversation Summary

This summarizes the conversation starting from the point where you challenged the "GPU as memory for embeddings/similarity" framing and ending at the later proposed execution order for a rebuilt kernel.

## 1. GPU, memory, and concurrency

You pushed back on the idea that GPU should be understood mainly as memory for embeddings or similarity search.

Your position was:

- The kernel itself runs on CPU in Go.
- The graph is loaded, folded, and grown on CPU.
- As inference and programs grow the graph, parts of it should be split into subgraphs.
- GPU should be understood as the fastest substrate for concurrent execution over those subgraphs.
- Hypervectors are a storage/execution medium for high-dimensional representations of sets of subgraphs.
- Wire splitting is what makes concurrent partitioning possible.

The conclusion reached in response to this was that GPU should not be modeled merely as a passive embedding/search layer. Instead:

- CPU is the sequential spine: fold, validation, deterministic log/state handling.
- GPU is the concurrent executor: many independent subgraph partitions in parallel.
- The partition rule should be based on independence of affected graph regions.

This became the first major correction to the prior framing.

## 2. First implementation plan, then growing doubt

An implementation plan was proposed around:

- rewriting the ontology loader,
- rewriting hydration,
- creating a seed graph,
- adding URN validation,
- adding permission and scope enforcement,
- updating examples and tests.

That plan still assumed the older ontology and kernel architecture were mostly right, just in need of adaptation.

As the conversation continued, you increasingly challenged the deeper assumptions behind that work.

## 3. Explorer, morphisms, and the missing state transition

You questioned what was actually being morphed and where the state transition really was.

The answer that emerged was:

- ADD changes node existence.
- LINK changes graph topology.
- MUTATE changes local node payload/metadata.
- UNLINK removes topology.

But this explanation exposed the real problem: Explorer showed mostly relations and snapshots, while the actual semantics of change were not visible in a graph-native way.

This made clear that the earlier implementation still behaved too much like:

- object records,
- plus connections,
- plus event handlers.

That was already drifting away from the intended categorical/hypergraph model.

## 4. Payload became the core conceptual problem

You repeatedly objected to the idea that state change should be understood as mutation of payload fields on nodes.

Your critique was:

- This is OOP thinking.
- A graph is not a set of business objects with attached fields.
- Ports and relations matter more than payload.
- The semantics should be in the port-to-port relations and the morphisms that transform them.
- Properties only make sense insofar as they participate in legal bindings and state transitions.

This led to a stronger distinction:

- node-local facts might exist,
- but relational semantics should not be hidden in opaque payload blobs,
- and runtime parameters should not be treated like permanent object fields.

From there, the earlier payload-centered implementation was increasingly recognized as the wrong center of gravity.

## 5. Agent as function/program/structure, not object

You then made the stronger point that an `agent` should not be modeled as an object at all.

The refined interpretation became:

- `agent` should be treated as function/program/structure.
- A node is at most an identity/interface anchor.
- Behavior belongs to morphisms, rewrite programs, or bound execution context.
- Runtime parameters such as provider choice, temperature, tool access, and so on should not live as intrinsic object properties on an `agent` node.

This was the turning point away from the OOP-ish graph model.

## 6. Research turn: stop patching, rethink the model

You explicitly asked to stop patching code and instead research the actual semantic direction.

The investigation then shifted to:

- the surviving design docs,
- external references on hypergraphs,
- graph rewriting,
- adhesive categories,
- and DPO/span rewriting.

The strongest conclusion from that research was:

- Hypergraph semantics do not force meaning into node payloads.
- Important semantics can live on vertices, edges, or incidences.
- In your case, many of the important semantics look incidence-level or binding-level.
- Real state change is better understood as graph rewriting over matched subgraphs than as field mutation on opaque nodes.

This aligned with the stronger line in the surviving design docs:

- categorical space defines admissible bindings,
- hypergraph space realizes actual ones,
- the port-to-port binding is more fundamental than the object-like node.

## 7. Rereading the design docs and deleting the drifting ones

The design docs were reread with this stricter lens.

The strongest remaining semantic line was identified in the docs on:

- PTP binding categories,
- categorical space,
- fiber decomposition,
- and PRG-in-graph.

The docs that drifted back toward payload/object modeling were identified as:

- `20260322-session-graph.md`,
- `20260331-rebuild-architecture.md`,
- and parts of `20260318-firestarter.md`.

You then asked to delete the drifting docs, and they were removed, leaving a reduced design base centered more cleanly on relation-first semantics.

## 8. Decision: build an incidence-first hypergraph rewriting kernel

After rereading the reduced design set and checking external references, the decisive recommendation became:

- Do not rebuild node records with payload plus edges.
- Build a minimal rewrite kernel with two spaces:
  - CS: the grammar of admissible bindings.
  - HG: the realized bindings and rewrites.

Within that framing:

- nodes are identity/interface anchors,
- ports are participation boundaries,
- wires are realized semantic bindings,
- incidences/port-bindings are the real semantic primitive,
- state is mainly topology plus minimal local state where unavoidable,
- programs are rewrite families over matched subgraphs,
- fibers are operational scopes discovered from dependency and structure.

This was the cleanest conceptual reset of the conversation.

## 9. Why the first demo was still wrong

Even after that reset, you pointed out that a demo based on `user`, `agent`, and `provider` still did not make sense as an application model.

The resulting clarification was:

- a real application graph should model the application domain itself,
- not a meta-control-plane story about user/agent/provider.

For your example of email processing, the right anchors would be things like:

- mailbox,
- message,
- attachment,
- parser-interface,
- extracted-number-set,
- report,
- destination,
- policies or rules where needed.

And the important semantics would be in relations like:

- belongs-to,
- can-be-parsed-by,
- derived-from,
- produced-report,
- sent-to,
- triggered-by,
- constrained-by.

That clarified that the earlier demo domain was still too meta and not yet proof that the graph kernel could model a real application.

## 10. Better plan proposed at the end

From that, a more useful implementation strategy was proposed.

The core criticism of everything before it was:

- the grammar was too hardcoded in Go,
- the demo domain was wrong,
- the Explorer proof was too thin,
- programs were hardcoded instead of being first-class data,
- and the kernel was not yet domain-agnostic enough to be genuinely useful.

The better plan proposed was:

### Phase 1 — File-driven kernel

- Load CS grammar from JSON, not hardcoded Go.
- Load seed graph from JSON.
- Define rewrite programs in JSON.
- Make domains data-driven instead of code-driven.

### Phase 2 — Real state

- Add an append-only log of applied rewrites.
- Make state a fold over the log.
- Replay from log on boot.

### Phase 3 — Explorer as design tool

- Show admissible grammar.
- Show realized graph state.
- Show fibers.
- Show available programs and what they would do.
- Apply programs and inspect topology changes.

### Phase 4 — HTTP API + MCP

- Submit programs via REST.
- Query state via REST.
- Add an MCP bridge so external agents can drive the graph.

### Phase 5 — First real domain

- Define an actual application domain entirely through grammar + seed + programs.
- Use the kernel to prove the system works on a real graph, not a toy meta-domain.

The final proposed execution order was:

1. Phase 1 first, because without file-driven grammar and seed, nothing is testable against a real domain.
2. Phase 2 immediately after, because without log/replay, state is ephemeral.
3. Phase 3 next, because it makes the system visible.
4. Phase 4 after that, because it makes the system drivable.
5. Phase 5 last, because it proves the approach on a real domain.

## Bottom line

Across this part of the conversation, the model shifted from:

- ontology adaptation,
- payload mutation,
- and object-like nodes,

to:

- relation-first semantics,
- incidence-first hypergraph rewriting,
- programs as rewrite families,
- fibers as execution scope,
- and a domain-agnostic, file-driven kernel as the next serious implementation target.
