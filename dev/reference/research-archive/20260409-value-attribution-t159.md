# Economic Value Attribution via Graph Topology

Date: 2026-04-09 | T=159
Related: `20260408-foundation-t158.md` sections 6-7, `20260408-presheaf-classification-temporal-t158.md` sections 10-13
Status: Theoretical framework. Not yet implemented.

---

## 0. The Question

The total graph has economic value — measured by any external benchmark (revenue, cost avoided, knowledge coverage, decision quality, compliance satisfied). Each node traces back to effort: a human wrote it, an agent extracted it, a reactor propagated it. The question is:

**How do we decompose V(G) into per-contributor shares such that the attribution is fair, stable, and derivable from topology alone?**

This is not metadata. This is the economic foundation of the system.

---

## 1. Value Is Not a Property — It Is a Functor

A node does not "have" a value in isolation. A node has value because of what it connects to, what depends on it, and what external outcome it enables. A claim with zero downstream relations is worth nothing. The same claim, once three programs depend on it and two crosswalks validate it, is load-bearing.

The valuation is a functor:

```
V: GraphState → ℝ≥0
```

V maps the entire graph state to a non-negative real number: the total economic value of the graph at that point in time. V is externally defined — the system does not invent its own worth. Examples of V:

- Revenue attributable to decisions informed by the knowledge graph
- Cost of recreating the graph from scratch (replacement value)
- Number of validated claims × average decision impact (coverage × leverage)
- Compliance score: percentage of regulatory requirements covered by structured knowledge
- Benchmark score against industry-standard test (e.g., accuracy on a domain QA benchmark)

V can be multiple functors simultaneously — there is no single "value." A graph can be worth EUR 50K in replacement cost AND 0.87 in compliance coverage AND 340 validated claims. Each V is independent.

---

## 2. Attribution as Causal Decomposition

Given V(G), we need:

```
α: Nodes(G) → ℝ≥0
such that Σ_{n ∈ G} α(n) = V(G)
```

α is the attribution function: it assigns each node its share of the total value.

### 2.1 Shapley Value (cooperative game theory)

The canonical fair attribution in cooperative games. Given:

- N = set of contributors (nodes, or rewrites, or agents)
- v: 2^N → ℝ (characteristic function: value of any coalition)

The Shapley value of contributor i is:

```
φ_i = Σ_{S ⊆ N\{i}} [|S|!(|N|-|S|-1)! / |N|!] · [v(S ∪ {i}) - v(S)]
```

This is the weighted average of i's marginal contribution across all possible orderings.

**Properties** (all desirable for economic fairness):
- **Efficiency**: Σ φ_i = v(N) — total value is fully distributed
- **Symmetry**: interchangeable contributors get equal shares
- **Null player**: zero marginal contribution → zero share
- **Additivity**: value of sum = sum of values (composable benchmarks)

### 2.2 Why the Graph Makes Shapley Tractable

Naive Shapley requires evaluating v(S) for all 2^|N| coalitions — exponential. But the graph provides causal structure:

A node n's marginal contribution depends only on its **causal neighborhood**: the nodes that depend on n (downstream) and the nodes n depends on (upstream). The provenance topology (WF12 links, WF18 composition, WF07 session traces) IS the causal DAG.

For a DAG-structured causal model, Shapley attribution reduces to:

```
α(n) = V(G) × [causal_reach(n) / Σ_{m ∈ G} causal_reach(m)]
```

Where `causal_reach(n)` = number of "valuable endpoints" reachable downstream from n, weighted by path length.

This is O(|E|), not O(2^|N|) — linear in the number of relations, not exponential in nodes.

### 2.3 The Provenance DAG IS the Causal Model

```
source_feed  →WF12→  knowledge_item  →WF12→  claim  →WF12→  domain_tag
                                        ↓WF18
                                     program  →WF18→  git_issue
                                        ↓WF07
                                   agent_session (who did the work)
```

Every LINK records a causal dependency. Every ADD records who created it (owner_urn). Every MUTATE records who changed it (the log entry has sender_urn). The graph already IS the attribution ledger — we just need to read it.

---

## 3. Three Layers of Attribution

### Layer 1: Node-Level Attribution (what)

Each node's α(n) = its share of V(G). Derived from causal topology.

### Layer 2: Agent-Level Attribution (who)

Roll up node attribution to the agent or user who created/modified the node:

```
α_agent(a) = Σ_{n : owner(n) = a OR last_mutator(n) = a} weight(n, a) · α(n)
```

Where `weight(n, a)` accounts for shared authorship (multiple agents contributed to a node's provenance chain).

This is the **economic value of each agent's work**. An agent that extracts 100 high-confidence claims from 10 sources has a computable value share. An agent that produces noise has a measurably lower share.

### Layer 3: Effort-Level Attribution (how much work)

Each rewrite in the log is a unit of effort. Some rewrites are cheap (MUTATE status), some are expensive (ADD knowledge_item after processing a 2-hour video transcript). Effort weighting:

```
effort(r) = f(rewrite_type, node_type, content_size, computation_time)
```

The economic efficiency of a contributor is:

```
efficiency(a) = α_agent(a) / Σ_{r : sender(r) = a} effort(r)
```

Value produced per unit of effort. This is the economic signal that governs resource allocation: which agents get more compute, which kernels get more storage, which programs get more funding.

---

## 4. Connection to Existing Architecture

### 4.1 P1 (Structural Presheaf) — WHO

P1 tracks ownership, governance, access. It knows who created what and who can modify what. P1 provides the agent-level roll-up.

### 4.2 P2 (Knowledge Domain Presheaf) — WHAT

P2 tracks the knowledge itself. Node count, claim confidence, classification coverage. P2 provides the node-level attribution.

### 4.3 V (Valuation Functor) — HOW MUCH

External benchmark applied to fold(log). This is the third axis: not who, not what, but how much is it all worth.

```
The three-axis model:

   P1 (who)  ×  P2 (what)  ×  V (how much)
      ↓              ↓              ↓
   agent_urn     node topology   benchmark score
      ↓              ↓              ↓
                 α = fair share
```

### 4.4 Stochastic Functor (foundation-t158 §7.2)

The stochastic functor [[_]]_w is exactly this: weighted semantics where each instance carries a value.

```
[[_]]_w : Syn → Meas
```

Maps the ontology (syntax) to a measured space (semantics with weights). Each node instance has a measure (its α value). The operad composition law preserves measures — if two nodes compose via WF18, the composed value flows correctly.

### 4.5 HDC Encoding

The hypervector phi(n) = bundling{incident wires} already encodes structural importance. A heavily-connected node has a richer, higher-norm hypervector. Economic value should correlate with hypervector norm — if it doesn't, the encoding is misaligned with value.

Testable prediction: `correlation(||phi(n)||, α(n))` should be significantly positive. If not, either V is misspecified or the operad structure is distorting the encoding manifold.

### 4.6 Classification Functors and Value

The classification functor C: Class → Know maps external standards to knowledge fibers. When a knowledge_item is classified under IFRS (via classification_scheme node), that classification ADDS value — it makes the knowledge findable, compliant, and benchmarkable against industry standards.

A crosswalk between two classification schemes doesn't just translate labels — it creates economic value by making knowledge reachable from a new domain. The crosswalk node's α should reflect this: its value is the increase in V(G) when the crosswalk is present vs absent (marginal contribution).

---

## 5. Copyright as Value Gate

The copyright presheaf (P1 restriction on knowledge flow) is an economic gate:

- Licensed content (CC-BY, MIT, proprietary) carries attribution obligations
- When a claim is extracted from a licensed source_feed, the provenance chain (WF12 LINK) encodes the license dependency
- The attribution function α must respect license constraints: if source S requires attribution, α(S) > 0 whenever any derived node has α > 0
- This is automatically satisfied by the causal decomposition: if downstream nodes have value, upstream provenance nodes have proportional value

Copyright enforcement IS value attribution. The graph doesn't need a separate copyright system — the attribution functor IS the copyright accounting system, because both follow the same causal topology.

---

## 6. Datamining as Value Production

The WF12 pipeline (source_feed → knowledge_item → claim → domain_tag) is a value production chain:

1. **Ingestion** (source_feed ADD): raw material enters the graph. Low α because no downstream structure yet.
2. **Extraction** (knowledge_item ADD, claim ADD): structure is created. α increases as claims connect to domain_tags and programs.
3. **Classification** (LINK to classification_scheme): value jumps — the knowledge is now findable and benchmarkable against industry standards.
4. **Validation** (MUTATE claim.confidence, corroboration via multiple sources): α increases with confidence — high-confidence claims are more valuable.
5. **Composition** (WF18 LINK to program): the knowledge serves a purpose. α peaks when claims inform active programs with economic outcomes.

Each step is traceable in the log. Each step has a sender_urn. The value chain IS the attribution chain.

### 6.1 Reactive Datamining (WF17)

Automated extraction via Watch/React/Guard:
- Watcher matches `ADD knowledge_item, status="raw"`
- Reactor emits `MUTATE status="claim-pending"` + triggers agent extraction
- Agent session extracts claims, classifies them
- Guard checks confidence threshold before promoting to validated

Each reactive step adds measurable value. The reactive chain's contribution is computable: V(G with reactive chain) - V(G without reactive chain) = marginal value of automation.

---

## 7. Implementation Path

### 7.1 What Already Exists

- Provenance topology: owner_urn, source_ki_urn, WF12/WF18 LINK chains
- Log with sender_urn per rewrite
- claim.confidence (mutable, kernel authority)
- classification_scheme + crosswalk nodes (ontology v3.4)
- HDC encoding (phi = bundling{incident wires})

### 7.2 What v3.4 Adds

- `classification_scheme` node type — represents external value benchmarks as graph nodes
- `crosswalk` node type — natural transformation witness, creates cross-domain value
- WF12 extended: domain_tag → classification_scheme → crosswalk pipeline

### 7.3 What Comes Next (not in v3.4)

1. **Valuation projection** (S4): A projection `P_value: GraphState → ValueReport` that:
   - Takes an external benchmark V
   - Walks the provenance DAG
   - Computes α per node and rolls up to agent level
   - Outputs a value report (JSON or dashboard)

2. **value_benchmark node type**: Represents a specific V functor as a graph node (meta: the system tracks how it's measured). Properties: benchmark_name, measurement_method, last_measured_at, total_value.

3. **Efficiency watcher**: A WF17 watcher that monitors agent efficiency (α_agent / effort) and flags underperforming agents for review.

4. **License enforcement reactor**: When a claim is derived from a licensed source, auto-LINK the license constraint. When the claim's α > 0, verify that attribution obligations are met.

---

## 8. The Shapley-Presheaf Connection

The Shapley value has a deep categorical structure. For a presheaf P over a category C:

```
Shapley(P) = ∫^{c ∈ C} P(c) × Δ(c)
```

Where Δ(c) is the "position" of object c in the category (its centrality, essentially). This is a **coend** — the categorical generalization of summing over all objects.

In mo:os terms:
- C = K (category of kernels)
- P = P2 (knowledge presheaf)
- Δ(K) = K's position in the federation topology (how many other kernels query through it)
- Shapley(P2) = economic value of the knowledge, weighted by federation reach

A kernel that serves as a federation hub (many shard_rules pointing to it) amplifies the value of its knowledge — it makes that knowledge reachable by more consumers. The federation topology IS the value amplifier.

This connects to the router-as-graph-traversal design: routing decisions are value-routing decisions. A shard_rule that routes queries to the most valuable knowledge fiber is economically optimal routing.

---

## 9. Open Questions

1. **Which V to use?** Multiple benchmarks are possible. Is there a canonical V, or does the system always carry multiple valuations? (Likely: multiple. This is the additivity property of Shapley.)

2. **Temporal discounting**: Should α decay over time? A claim validated last week is more valuable than one validated a year ago. The temporal presheaf (section 12 of presheaf doc) provides the framework — restrict to G(t) and recompute α.

3. **Negative value**: Can a node have α < 0? (Misinformation, stale claims, broken crosswalks.) This breaks the non-negative assumption. The fix: split V into V+ (value) and V- (cost), attribute separately.

4. **Privacy of attribution**: Should α be visible to all agents? Or is attribution part of P1 (structural, access-controlled)? An agent shouldn't necessarily see another agent's efficiency score.

5. **Bootstrap problem**: When the graph is small, attribution is noisy. How many nodes / what graph density before α stabilizes? Related to the manifold hypothesis — the attribution manifold needs sufficient data to be meaningful.

---

*The graph is not a database. It is a value accounting system. Every rewrite is a transaction. Every provenance link is a line item. The fold of the log is the balance sheet. The Shapley attribution is the dividend.*
