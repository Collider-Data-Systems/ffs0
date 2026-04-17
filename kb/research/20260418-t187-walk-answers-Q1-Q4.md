---
title: T=187 walk — answers Q1..Q4
t_day: 168
program: urn:moos:program:sam.t187-kernel-proper
sub_program: urn:moos:program:sam.t187.answer-walk-Q1-Q4
status: completed
---

# T=187 walk — answers Q1..Q4

Socratic walk surfaced four design questions about the kernel doctrine. Answers recorded here for the log.

---

## Q1 — The first kernel

Before any session exists, before the first rewrite, the graph state is ∅. This appears circular: a rewrite requires an actor URN, but the actor (the kernel node itself) does not yet exist. The resolution is definitional, not philosophical. The seed script (`cmd/moos main.go seedInfrastructure`) performs a privileged bootstrap ADD that does not require a prior actor — it is the axiom that starts the log. The node `urn:moos:kernel:hp-laptop.primary` is written at log_seq 1, and from that moment every subsequent rewrite has a valid actor URN to record. In the session monoid (M1), the identity element `e` is the empty session (zero rewrites, zero state change); the kernel seed is what makes a non-empty session possible at all. The self-reference is not a paradox but a deliberate grounding move: the kernel ADDs itself, and thereafter nothing in the log is unanchored. **Conclusion: the first kernel is the self-referential axiom established by the seed script; it has no prior actor because it is the prior actor.**

---

## Q2 — Purpose vector for wiring

A `purpose` node (schema S2) carries three fields: `subject_urn` (the node or cluster it is about), `target_state` (the desired property configuration), and an optional HDC gradient vector encoding that target state as a hyperdimensional point. The wiring-proposer (introduced near log_seq ~299) operates by computing the current HDC embedding of each candidate node cluster and scoring proposed LINKs by cosine similarity to the purpose's `target_state` vector. A cosine score near 1 means the proposed LINK would move the cluster's embedding toward the intended state; a score near 0 or negative means it would not. Purpose is therefore not a label or a comment — it is a directional constraint expressed in the same embedding space the kernel uses for all semantic reasoning. The HDC gradient vector is optional because early-stage purposes may only have a symbolic `target_state`; the vector is filled in when the purpose is mature enough to drive automated wiring. **Conclusion: a purpose node is the directional intent that tells the wiring-proposer which connections advance the goal, expressed as a target in the hyperdimensional embedding space; cosine similarity is the compass that turns intent into a ranking.**

---

## Q3 — 2-cell lift

In the kernel's categorical model, rewrites are 1-cells (morphisms between graph states) and natural transformations between rewrites are 2-cells. A bare LINK between two nodes is a 1-cell: it exists in the graph but cannot itself be governed, mutated, or reasoned about as an object. "Promoting a relation to a node" — the 2-cell lift — means issuing an ADD for a new node that reifies the relation, followed by LINKs from that node to the original endpoints. The reified node is now a first-class citizen: it can carry properties, be MUTATEd, be guarded by a WF contract, be wired to a purpose, and appear as the subject of further rewrites. WF15 contract nodes are an existing example of this pattern in the live graph. The design decision from T=164 was to lift selectively, not universally: lifting every LINK would explode node count without benefit. The criterion for lifting is whether the relation itself needs to be governed, observed, or mutated over time — if yes, lift; if the relation is static and structural, leave it as a bare LINK. **Conclusion: the 2-cell lift promotes a relation to a first-class node when that relation must itself participate in the rewrite algebra; selective lifting keeps the graph tractable while preserving full expressiveness where it matters.**

---

## Q4 — Agent-as-tool (Yoneda)

The Yoneda lemma states that an object X in a category C is fully characterized by the presheaf `Hom(-, X): C^op → Set` — the totality of morphisms into X from every other object. Applied to agents: an agent is not characterized by its metadata or a prose `skills.md` file, but by its `capability` nodes (schema WF02), each reachable via an `agent --connects-to--> capability` LINK. The set of capability nodes is the agent's Hom-set; what the agent can do fully determines what the agent is. When a `program` node references an agent via `tool_call.agent_urn` (added in ontology v3.7), the tool_call is a witnessed instance of the agent's presheaf: it records that a specific morphism (capability invocation) was actually exercised. This makes the tool_call auditable and queryable in the same graph traversal language as everything else. A flat `skills.md` file cannot be versioned per-node, gated by a WF contract, or used as a wiring target — capability nodes can be all three. **Conclusion: agent-as-tool means the agent's identity is its capability graph in the Yoneda sense; `skills.md` is obsolete because capabilities are first-class nodes that can be queried, versioned, gated, and wired to purposes.**
