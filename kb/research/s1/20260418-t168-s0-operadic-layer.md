# S0 — the operadic layer over S1

> T=168 (April 18, 2026). Companion to `20260418-t168-s1-superset-doctrine.md` and `20260418-t168-v3.9-ontology-audit.md`.
> Origin: sam's ask for lingo at the op level.

## Sam's framing (verbatim)

> "s0 is may way to say 'the categories of or over the s1 categories or the connecting ones, structures big small'. it has purpose and session already, this is the semantic to syntax pattern in the form of op level abstract objects/ports/wires (help me lingo). the leaves, tools, cli whatever et the kernels."

## What S0 is (definition-by-position)

S1 is the grammar — types, ports, WFs. A free category of declared generators.

**S0 is the layer of objects that compose *multiple* S1-typed sub-structures into a single coherent run.** It sits *over* S1 (it names S1-shaped compositions) and *through* S4 (it is how intent becomes composition).

Operad theory gives us the shape: an **operad** is a family `{O(n)}` where each `O(n)` holds elements with `n` input slots and one output. You fill the slots with other elements (maybe from `O(k)`, whose own slots must be filled in turn), and the whole thing composes to a tree.

In mo:os the S0 nodes are exactly the operadic elements. They have:
- **arity** — how many sub-compositions they accept
- **slots** — typed holes waiting for sub-compositions (or S1 leaves)
- **output** — the run / occupancy / direction / process they yield when every slot is filled

Existing S0 nodes (post-v3.9):

| Node type | arity | slots (what goes in) | output (what comes out) |
|-----------|-------|----------------------|-------------------------|
| `purpose` | 1 | current-state node (S1 or S2) | a direction in φ-space |
| `session` | N | occupant (agent), mounted tools, pinned URNs, view filter | an occupancy |
| `program` | N+1 | sub-programs (many) + harness (one) | a run |
| `workflow` | N | steps (DAG) | a process template |
| `channel` | N | message-typed slots | a message stream |

These are **not** leaves. They never *do* anything by themselves — they compose. The leaves are S1-typed nodes: agents, CLIs, tools, kernels. That's what sam means by "the leaves, tools, cli whatever et the kernels".

## Proposed lingo

Mo:os already reserves `node` / `relation` / `port` / `property` for S1. The operadic layer needs distinct words so S0 talk stays unambiguous. Proposal:

| Operad term | Mo:os S0 term | Meaning |
|-------------|---------------|---------|
| operadic element | **op-node** | An S0 node (purpose, session, program, workflow, channel) |
| arity | **arity** | Unchanged — count of input slots |
| input slot | **slot** | A typed hole on an op-node. Shape is an S1 type (or another op-node type for nesting). |
| output | **yield** | What the op-node produces when all slots are filled. Distinguished from "output" (S1 ports have outputs). |
| composition (plugging ops together) | **threading** | The act of connecting op-nodes and S1 leaves into a composed run. Distinct from S1 `LINK` rewrites — threading is a read-time projection of LINKs that respect slot typing. |
| substitution (expanding an op) | **unfold** | Replace an op-node with its definition in place. Reverses a fold. |
| identity op | **passthrough** | The trivial op that yields its single input unchanged. Needed for monoid identity (§M1). |
| n-ary composition | **weave** | The full threaded tree of op-nodes + leaves. A `session` weave is an occupancy; a `program` weave is a run. |

One coinage with a specific job: **thread**. A thread is a relation that fills a slot. It is *not* a new WF category — it is a projection label over existing WF18 (composes) / WF19 (opens-on) / WF02 (capability) relations when they act in slot-filling mode. A thread has a direction: downward through the tree from op-node to the leaf that fills its slot.

Strictness:
- `thread` is a noun only at the op-layer. The underlying topology is always a relation, always lives in S1, and is always governed by an existing WF.
- CLAUDE.md still forbids "wire" as informal for relation. Thread is *additive* — it names a role a relation plays in an S0 composition, not a replacement for relation.

## The semantic-to-syntax pattern

Sam's phrase "semantic to syntax" now has a concrete shape:

```
S4 (semantic intent)           — system_instruction, governance_proposal, observation
  │
  │ (a human or agent authors free-form intent)
  ▼
S0 (op-layer composition)      — purpose, session, program, workflow
  │
  │ (threading: slots get filled with S1 leaves or nested op-nodes)
  ▼
S1 (syntactic grammar)         — types, ports, WF clauses, capability scopes
  │
  │ (LINK/ADD rewrites instantiate nodes of declared types)
  ▼
S2 (instances)                 — the live HG: agents, kernels, CLIs, view filters
  │
  ▼
Leaves                         — tools, CLIs, kernels actually running
```

The two adjoints from the v3.9 audit (§F) now sit at the boundaries:

- **Promote** (`S4 → S1`): left adjoint, grows S1. Carried by `grammar_fragment` + WF20. Runs through S0 *as a composition* — a promoted fragment is the crystallised form of a repeated S0 weave.
- **Express** (`S1 → S4`): right adjoint, grounds S1. A canonical type can always be explained in natural S4 language. S0 is the bridge: expressing means showing the weave.

## Worked example — `program` as op-node

Take `urn:moos:program:sam.t187-kernel-proper` (status=draft, 26 sub-programs):

- **arity**: 26 sub-program slots + 1 harness slot + 1 purpose slot = 28
- **slots** (typed):
  - 26 × `program` (sub-programs) — filled via WF18 `composes / composed-by`
  - 1 × `harness` (execution env) — filled via the harness relation (still under draft; §M18/§M20 hint at WF extension)
  - 1 × `purpose` (direction) — filled via WF01 `steers / steered-by` when ratified
- **yield**: a `run` — the t187 program executing through T=187..T=220
- **weave**: the full tree of 26 filled sub-program slots, each of which is itself a program op-node with its own arity.

Threading this program is reading the WF18 closure downward from the root. The kernel does not "execute" the op-node — it publishes the yield by making the weave observable (fold endpoint, M3 sub-program).

## What S0 being operadic buys us

1. **Natural fit for purpose, session, program, workflow.** They were always multi-input composables. Now they have a category (S0) that names them correctly.

2. **Grammar_fragment promotion becomes a weave.** A `grammar_fragment` is proposed at S4, observed as a weave of S0 op-nodes, ratified at S1. WF20 is the morphism that transports the weave up the stack.

3. **Session-as-workspace-anchor (§M18) clicks.** The session op-node has slots for occupant, mounted tools, view filters, pinned URNs. It is an operadic object whose yield is "an occupancy for kernel K under user U". The t-cone (§M15) is a projection of the weave.

4. **Twin kernel adjunction (§M9) is operadic sync.** Two kernels each carry S0 op-nodes. A twin_link is a natural transformation between the two op-functors, carrying op-node yields across machines while respecting slot typing.

5. **Yoneda for agent-as-tool (§M20).** An agent is determined by what it maps to — which slots in which op-nodes it can fill. The catalogue of agent-as-tool invocations is exactly the set of op-nodes with an agent slot.

## Open questions

1. **Is `purpose` really arity 1 or is it an endo-op that carries both current-state and target-state slots?** Current ontology has `phi_current` and `phi_target` as properties — operadically those should probably be slots taking S1 state-bearing nodes. Candidate v3.10 work.

2. **Does `channel` belong in S0 or S2?** v3.9 keeps channel in S1 as a type (S2 as an instance). But channels are clearly compositional — arity = how many message-typed sub-streams they carry. Probably S0 as an op-node *category*, S1 as a type, S2 as an instance. The three-layer separation already supports this.

3. **How does `harness` (v3.9 S2 type, D6) relate to S0?** A harness *is* an execution environment for a program — so it is a slot-filler, not an op-node. But a harness itself composes (it has a runner, a worker pool, a log sink). So harness is operadic *inside*, a leaf *from the outside*. This is fractal — and the right lingo term is **embedded op** for an op-node whose composition is hidden inside a slot-filler.

4. **Do we need a new WF for threading?** Probably not — threading is a projection, not a rewrite. Keep S0 as a *reading frame* over existing WF18/WF19/WF02 relations for now. If a specific threading semantic surfaces that no existing WF covers, promote via WF20.

5. **Is S0 bounded or unbounded in depth?** Operads compose recursively — an op-node can fill a slot on another op-node indefinitely. Sam's "structures big small" phrasing suggests unbounded. CI-3 (identity stability) needs to hold across arbitrary threading depth.

## Cross-references

- `20260418-t168-s1-superset-doctrine.md` — S1 as free-category superset; S4↔S1 adjunction
- `20260418-t168-v3.9-ontology-audit.md` — v3.9 baseline (purpose, session, program, workflow are now all declared S1 types; S0 is the category *over* them)
- `../kernel/20260417-t187-kernel-proper.md` §M1 — session as monoid object (monoids are arity-2 ops with identity)
- `../kernel/20260417-t187-kernel-proper.md` §M15 — t-cone projection (a reading of a session weave)
- `../kernel/20260418-t187-categorical-contract.md` — CI-1..CI-5 proofs (the contracts S0 must respect)
- `../session/20260414-t164-session-channel-purpose.md` — foundational T=164 paper introducing session/channel/purpose as distinct kinds; this note names the kind
- `../wires/20260414-t164-wires-come-from.md` §2 — "nodes are incomplete datasets with optional T-hooks" — compatible with op-node shape (slots are the T-hooks of an op-node)

## One-line summary

> S0 is the operadic layer where purpose, session, program, workflow, and channel live as op-nodes with typed slots that yield coherent runs when threaded with S1 leaves. "Semantic to syntax" is S4 → S0 weave → S1 grammar → S2 instances → leaves.
