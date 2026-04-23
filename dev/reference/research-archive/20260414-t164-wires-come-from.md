# T=164 — Where do wires come from?

> April 14, 2026, 11:30 CEST. Sam on a walk.
> Continuation of `../../../dev/reference/research-archive/20260414-t164-session-channel-purpose.md` (archived T=169 round 10).
> Bottom-up. Syntax → semantics.

---

## 1. The question

**Where do wires come from?** Not "where are wires stored" (the log), not "what is a wire" (a relation). The generative question: what *makes* a wire appear?

Until now we have three answers and a gap.

| Source of wires | Mechanism | Exists |
|-----------------|-----------|--------|
| Declared by agents | LINK rewrite via WF01–WF19 | ✅ |
| Emitted by schemas | Classification scheme ADD implies LINK rewrites | ✅ (see T=164 #8) |
| Triggered by watchers | WF17 reactive pattern match | ✅ |
| **Discovered by the kernel itself** | ? | ❌ gap |

The gap is what Sam pointed at: *"what program would do that. Each Kernel should have one."*

---

## 2. Nodes are incomplete datasets with optional T-hooks

Reframe: a node is not "an object with properties". A node is:

```
Node = identity (URN) + partial data (properties) + T-hooks (optional)
```

- **identity** — `urn:moos:…`, stable under rewrites (CI-3)
- **partial data** — properties that may be missing, stale, or default
- **T-hooks** — temporal ports that listen for events, rewrites, or clock ticks

A node with **no T-hooks** is static data (a record).
A node with **live T-hooks** is reactive (a process).

Every node type in v3.6 is a Janus: both at once, depending on which ports are wired.

**Corollary (from Sam):** *"Tools can be thought of like that too, even a folder in a filesystem."* Under this reframe there is no ontological difference between:

| Naïve name | In the HG |
|-----------|-----------|
| File | node, owner_urn, no T-hooks, properties=content |
| Folder | node, emits→many, T-hooks on filesystem watcher |
| Tool | node, T-hooks on invocation, properties=signature |
| Application | node, T-hooks on session lifecycle |

They differ in **which wires are lit**, not in what they are.

---

## 3. Relations promoted to nodes — the 2-cell lift

> *"any wire that already exist but gets wires — isn't that a tool or application of a file or folder"*

Currently in v3.6: a relation has a URN (e.g. `urn:moos:rel:t164-program-composes-ch-wa`) but is not itself a node. You cannot LINK to a relation.

**Proposal (defer decision):** allow a relation to be *promoted* to a node when something else wires to it. This is the 2-cell lift in bicategory terms:

```
Graph (1-category):            nodes, relations
Reactive graph (bicategory):   nodes, relations, relations-between-relations
```

A relation-promoted-to-node is exactly what Sam means by "a wire that gets wires becomes a tool or application". The first wire is the morphism; the meta-wire is the 2-cell; the *activation* is the 2-cell being traversed.

**The tell:** `tool_call` → `tool_result` is already a wire. But `tool_call` itself *is* a node. If we generalize, any LINK can host a meta-LINK, and the whole thing stays consistent.

**Cost:** strict Four Rewrites breaks if we let MUTATE operate on relation-bodies. So: keep relations opaque at the rewrite layer; let the 2-cell lift happen as a *projection* (S4) until we can prove CI-1..5 hold for it.

---

## 4. Agents-as-tools — the skills.md problem dissolves

> *"Tools being CLI versions of claude or AG, as popups, solve the missing tools (I don't want to plough through 200000+ skills.md let alone write them)"*

The conventional model: every tool is a pre-written skill with a contract (`skill.md`). At scale this is writing N files for N capabilities. N blows up.

The HG-native model: **an agent pointed at a wire IS a tool for that wire.** The `tool_call` node carries the signature; the agent executes. The capability is not a file on disk; it's a configuration of:

- which `capability` node the delegate holds (WF02)
- which `agent` is bound by WF05 to handle this `tool_call`
- which `program` steers the invocation

When a new capability is needed, you don't write a skills.md. You ADD a `capability` node + LINK it to the agent via WF02. The agent discovers what it can do by querying its own wires. This is the **Yoneda lemma operationally**: the agent *is* what it maps to.

Consequence: skills.md is a historical accident of file-first tool design. The HG eliminates the need. A Claude-CLI popup invoked against a specific URN is a tool — no pre-declaration required.

---

## 5. The wiring program — one per kernel

> *"What about wiring, what program would do that. Each Kernel should have one."*

Every kernel should host a **wiring program** — a first-class `program` whose harness is "propose wires for consideration". Not an agent (agents are delegates of a user). Not a watcher (watchers react). A *proposer*.

**Proposed structure:**

```
program {
  urn:moos:program:<kernel>.wiring-proposer
  harness_pattern: dynamic-plan-adaptive
  owner_urn: <kernel>
  title: "Wiring proposer"
  composed-by: watcher (signal intake)
  steers: purpose (current direction of the kernel)
}
```

**Responsibilities:**

1. Observe the rewrite log (via a WF17 watcher)
2. Compute HDC candidate wires: for every pair of unrelated nodes `(a, b)`, score `cos(φ(a), φ(b))` against the current purpose vector
3. Propose top-K LINKs as `governance_proposal` nodes (WF13)
4. Never LINK directly — the user or a delegate must ratify
5. Fold back: refine its own scoring from accepted/rejected ratifications (the kernel learns its own topology)

**This is the fourth source of wires.** The gap in §1 closes.

Bonus: the wiring program gives every kernel a **personality**. Two kernels with different local purposes will propose different wires against the same log. Federation becomes interesting because each kernel has an *opinion* about what should be connected.

---

## 6. Syntax → semantics, bottom-up

> *"We do syntax to semantics here. That's my direction."*

Syntax-first means: declare structure (types, ports, port colors, WF categories) and let meaning emerge from how the structure is used. The ontology is a grammar, not an encyclopedia (this is already stated in `ontology.json.nomenclature_rules`).

The bottom-up move: semantics emerge from *observed wiring patterns*, not from declared intent.

- A `classification_scheme` is a *syntactic* node until crosswalks give it semantics (the wires map it to other schemes).
- A `purpose` is a *syntactic* node until the HDC gradient gives it direction (the vector field in φ-space).
- A `channel` is a *syntactic* node until messages flow through it and earn it meaning.

Sam's Rumsfeld epistemology: the known unknowns are the declared types; the unknown unknowns are the latent patterns the wiring program discovers.

---

## 7. Open questions for the walk

1. **Should the wiring program run on hp-laptop first, or Z440?** hp-laptop is the low-volume kernel (240 log entries). Easier to watch. Z440 has 4 kernels and more topology.

2. **What is the purpose vector for the wiring program itself?** Meta-question: the proposer needs a purpose to steer its proposals. Is it the *kernel's* purpose, the *user's* purpose, or does the wiring program carry its own `purpose` node?

3. **2-cell lift — project or promote?** Do we keep relations opaque (project 2-cells at S4) or do we canonize them (promote to S2 nodes)? Promotion costs rewrite-category invariants; projection costs one layer of indirection.

4. **Agent-as-tool vs. skill file — transition path.** Keep both for now, or deprecate skill files entirely? Category-master skill is the only one actually running. What replaces it if we drop the file-first model?

5. **Where do FOLDERS go?** A filesystem folder is a channel (kind=filesystem) in v3.6. But a folder also has structure — nested folders. Is a nested folder a sub-channel (child-of) or a knowledge_item (content-of)? Probably sub-channel with `owned-by` parent channel. Worth spelling out.

6. **T-hooks — first-class or implicit?** Right now "T-hook" is just a port on a node. Should we make T-hook an explicit sub-structure on every node so reactive/static is visible at a glance?

---

## 8. What to ratify when Sam returns

Low-cost, high-signal moves ready to execute:

- **A.** ADD `program: wiring-proposer` to hp-laptop kernel (inert until a watcher is attached)
- **B.** Write one more T=164 research note answering one of Q1–Q6
- **C.** Extend `channel` with `parent_channel_urn` (optional) to capture folder nesting
- **D.** Add "tool_call.agent_urn" port so agents-as-tools wire cleanly

Deferred (needs longer thought):

- 2-cell lift (§3 decision)
- Deprecation of skills.md (§4 transition)
- Rewrite validator hardening — MUTATE `value` vs `new_value` silent acceptance (tech debt from T=164 delegation session)

---

## 9. One-line summary

> Nodes are incomplete datasets with optional T-hooks.
> Wires come from declarations, schemas, watchers, and the kernel's own wiring program.
> Tools are agents pointed at URNs, not files on disk.
> The carpet is an ongoing proposal — ratified by the user, proposed by the graph.
