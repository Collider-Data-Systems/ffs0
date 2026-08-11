# Agent-Delegate-User Provenance Model — T=160

> Formal model for multi-agent delegation, conflict resolution, and provenance splitting.
> Grounded in the two-presheaf model (P1/P2) and the four-rewrite kernel.

---

## The Setup

Sam owns one user node: `urn:moos:user:sam`.  
Sam has delegated work to multiple agents, each with a `board_id`:

| HG URN | board_id | Workstation |
|--------|----------|-------------|
| `urn:moos:agent:claude-code.hp-laptop` | AGENT-CLAUDE-HPLAP | hp-laptop |
| `urn:moos:agent:claude-code.hp-z440` | AGENT-CLAUDE-CODE-Z440 | z440 |
| `urn:moos:agent:vscode-codex.hp-z440` | AGENT-VSCODE-CODEX-Z440 | z440 |
| `urn:moos:agent:antigravity.hp-z440` | AGENT-ANTIGRAVITY-Z440 | z440 |
| `urn:moos:agent:antigravity.hp-laptop` | AGENT-ANTIGRAVITY-HPLAP | hp-laptop |
| `urn:moos:agent:vscode-codex.hp-laptop` | AGENT-VSCODE-CODEX-HPLAP | hp-laptop |

All governed by WF02: `LINK urn:moos:user:sam --governs--> urn:moos:agent:*`

The question: **How does provenance split over delegates? How are conflicts resolved?**

---

## Formal Model

### P1 (Structural Presheaf) — who can write what

Permission inheritance is CI-5: `P(delegate) ≤ P(principal)`.

The user node carries the full authority envelope. An agent, being governed by WF02, inherits a **scoped subset** of that authority:

```
P(agent) = P(user) ∩ scope(WF02 relation)
```

This is a presheaf restriction. The restriction morphism `ρ_{agent ← user}` maps the user's authority bundle to the agent's scoped slice. An agent cannot grant itself permissions not on the WF02 relation — the kernel enforces this at every rewrite.

**Consequence**: multiple agents working for `sam` cannot escalate past `sam`'s authority even if they coordinate. The ceiling is `P(sam)`, not the union of all agents' attempts.

### P2 (Knowledge Presheaf) — what gets written

The kernel is append-only. Every rewrite carries an `actor` field. When agent A writes a node, the log records `actor: urn:moos:agent:claude-code.hp-laptop`. When agent B mutates it, the log records `actor: urn:moos:agent:vscode-codex.hp-z440`.

The provenance of any node is:

```
prov(node) = { (log_seq_i, actor_i) : log[i].affects(node) }
```

This is a **causal DAG of actor-timestamped operations** — not a single owner label, but a full contribution history. The node's version counter indexes into this DAG.

---

## The Conflict Problem

Two agents for the same user may simultaneously propose incompatible MUTATEs:

```
Agent A:  MUTATE node.status → "completed"    (t=214)
Agent B:  MUTATE node.status → "blocked"      (t=215)
```

### Why this is NOT a problem in the kernel

The kernel's append-only log is the single serialization point. Both operations are valid (both agents have P1 authority). The kernel applies them **in log order**. The last write wins on value, but **both contributions are in the log**.

There is no conflict in the graph-theory sense — the log is totally ordered. What appears to be a conflict is just two agents writing sequentially, each overwriting the previous value. The provenance DAG retains both entries.

If the caller cares about preventing overwrite (e.g., "only update if still 'active'"), use **optimistic CAS**:
```json
{ "rewrite_type": "MUTATE", "target_urn": "...", "field": "status",
  "new_value": "completed", "expected_version": 3 }
```
If another agent already incremented the version, the CAS fails — the issuing agent must re-read and decide.

---

## Provenance Splitting — The Shapley View

Total value V(node) can be attributed across all agents who touched it. For a node with contribution history `[(actor_0, effort_0), ..., (actor_n, effort_n)]`:

```
Shapley_i = Σ_{S ⊆ N\{i}} [ |S|!(|N|-|S|-1)! / |N|! ] × [v(S∪{i}) - v(S)]
```

In practice for the kernel: effort is proportional to rewrites. If sam's 3 agents each wrote 10 nodes:

- `agent:claude-code.hp-laptop`: 10 ADDs → contributes 1/3 of structural provenance
- `agent:vscode-codex.hp-z440`: 10 MUTATEs → contributes 1/3 of mutation provenance
- `agent:antigravity.hp-z440`: 10 LINKs → contributes 1/3 of topological provenance

**The user (sam) owns ALL of it** — the agents are instruments, not principals. Sam's Shapley share = 1.0 across all agent contributions, because P(agent) ≤ P(sam) and all rewrites flow through sam's governance.

This is the **user-level consolidation**: no matter how many agents write on sam's behalf, the value attribution graph always folds up to `urn:moos:user:sam` as the final principal.

---

## The Formal Pattern: User-as-Colimit

Treat the user as the **colimit** of all their agents' contribution diagrams:

```
colim { agent_i → user } = user's total provenance
```

Each agent is an injection into the user's provenance bundle. The colimit is the user node — it absorbs all contributions without splitting identity. The user remains one node, one URN, one P1 authority point.

This is why the kernel doesn't need a separate "delegation log": the actor field on every log entry IS the provenance trace, and the WF02 governance relations ARE the delegation topology. No extra infrastructure needed.

---

## Multi-Agent on One Program

For T=162 (Menno presentation), four agents are wired to `ffs0#12..#15`:

```
AGENT-CLAUDE-HPLAP       → Lane A, B, C (me, hp-laptop)
AGENT-CLAUDE-CODE-Z440   → Lane A, C
AGENT-VSCODE-CODEX-Z440  → Lane A, C
AGENT-ANTIGRAVITY-Z440   → Lane B, C
```

These are **competing producers into the same program node**. Protocol:

1. **One agent per issue at a time** — issues are the serialization unit, not the program
2. **CAS on prg_task nodes** — each agent creates/mutates its own `prg_task` subnodes under the program; only the program-level status is shared
3. **Status MUTATE is idempotent via CAS** — first agent to complete a lane wins; others see version conflict and skip

The GitHub project board's `Agent ID` field is the external index into the HG URN table. Agents read it via `gh api` to know which issues are assigned to their `board_id`, then look up their own `urn:moos:agent:*` node to find their HG identity.

---

## Why No "Split User" Is Needed

The user's concern: "split the user's provenance over delegates in a formal way."

The answer: **the log already does this, automatically**. Every entry has `actor`. The topology (WF02 governs edges) declares the delegation structure. The kernel's append-only serialization handles all conflicts. The user node is the colimit — provenance fans out to agents and folds back to the user without any additional machinery.

What IS needed (and now implemented):
- `board_id` property on `agent` nodes — bridges HG identity to board identity
- `urn:moos:agent:<user>.<name>` naming convention — encodes ownership in the URN itself
- WF02 LINK at kernel birth — declares the governance relation formally
- `actor` field on every log entry — provides replay-accurate provenance trace

---

## Invariant: CI-5 Applied to Delegation

```
CI-5: P(delegate) ≤ P(principal)
```

Operationally: when a MUTATE arrives with `actor = urn:moos:agent:claude-code.hp-laptop`, the kernel checks:
1. Is `urn:moos:agent:claude-code.hp-laptop` governed by a user (WF02 relation exists)?
2. Does that user have authority for this field (AuthorityScope check)?
3. Is the WF category in the agent's delegated scope (WF02 mutate_scope)?

If all pass: write is allowed. The agent acts with the user's authority — but only up to the ceiling defined by the WF02 governance relation.

This is the formal "split": not splitting the user node, but splitting the **authority scope** of the user's one-node identity across multiple governed agents, each holding a slice.

---

## Summary

| Concern | Mechanism |
|---------|-----------|
| Multiple agents for one user | WF02 governance relation per agent; all P(agent) ≤ P(user) |
| Conflict resolution | Append-only log is total order; last write wins; CAS for pessimistic control |
| Provenance splitting | `actor` field per log entry; colimit over agent contributions = user node |
| Board ↔ HG identity | `board_id` property on agent nodes; naming: `AGENT-<TOOL>-<WS>` |
| No extra infra needed | The log IS the provenance; the topology IS the delegation |

The kernel's append-only log plus the two-presheaf model (P1 = authority, P2 = knowledge) is sufficient for full multi-agent provenance. No additional layer required.
