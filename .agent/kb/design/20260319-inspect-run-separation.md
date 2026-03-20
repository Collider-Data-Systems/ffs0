# Inspect/Run Separation — GPU Tier Lifecycle

**Date:** 2026-03-19
**Status:** S0 — Proposed. Pending Sam direction.
**Source:** Sam mobile session (verbal stream). Captured by Claude Code.
**Related:** `20260319-cloverleaf-kernel-topology.md`, `20260319-ptp-binding-categories.md`

---

## Core Thesis

**It is about separating inspect code from running code.**

Two substrates. Different physics. Different purposes.

| Tier | What it is | Speed | Parallelism | Property |
|------|-----------|-------|-------------|----------|
| GPU | Inspect substrate | Fast | ✅ Parallel | Discoverable. Ephemeral hypotheses. |
| CPU kernel | Run substrate | Fast | ❌ Serial | Deterministic. Proven facts. |
| Log | Memory | Append-only | N/A | Complete history. No mutation. |

---

## Purpose

**Share new information.** Remove or move known information.

- **GPU = discovery.** New structures land here first. Everything is live, queryable, comparable.
  Once characterized: promote or discard. The GPU is never the truth — it is the question.
- **CPU kernel = known.** Structures that have been Ricci-characterized and proven. This IS
  the kernel state. Morphism-governed. "Proven = known to all."
- **Log = memory.** morphism-log.jsonl is the complete history of every eval result, every
  promotion, every discard. "Graph log has memory of stored eval."

---

## Lifecycle

```
             ADD to GPU
                 │
                 ▼
         [GPU inspect tier]
           HDC hypervectors
           Ricci curvature
           Operad algebra
           Wire complexity
                 │
        ┌────────┴──────────┐
        │                   │
      proven?            disproven?
        │                   │
        ▼                   ▼
    get_eval             discard
    update               destroy (GPU)
    destroy (GPU)        → log remembers
        │
        ▼
  [CPU kernel tier]
   Morphism fold
   Serial. Known.
   Shared global state.
        │
        ▼
   ADD/LINK in kernel log
   → "proven = known to all"
```

Three operations on the GPU-to-CPU transition:

| Op | What |
|----|------|
| `get_eval` | Run Ricci + operad metrics over the GPU structure → produce evaluation result |
| `update` | Promote the proven structure to CPU kernel (materialize as morphism sequence) |
| `destroy` | Remove the structure from GPU graph. Log still has the record. |

---

## Why Losing Discoverability Is Correct

When a structure is promoted from GPU to CPU, it **loses GPU discoverability** — intentionally.

- GPU discoverability = the structure is live in the hypervector space, cosine-comparable to
  everything else, open for further inspection. This is the property of **hypotheses**.
- CPU kernel structures are **known**. They do not need to be discovered again.
- Keeping proven structures in the GPU wastes discovery bandwidth on known facts.
  The GPU should be full of **new** structures, not encyclopedias.

This is how the system **improves global state** over time:
- GPU shrinks (known things leave it)
- CPU kernel grows (proven things accumulate)
- Log grows (everything is remembered)
- Net: more discovery bandwidth per GPU cycle

---

## Ricci as the Promote/Discard Criterion

Ollivier-Ricci curvature characterizes a graph structure **categorically**:

- Positive curvature on a subgraph → robust, well-connected, functorially stable
  → **promote candidate** (known, healthy, worth running)
- Negative curvature → bottleneck, fragile, structurally suspect
  → **discard or rewire candidate** (not worth promoting yet)
- Zero curvature → tree-like, neither → **hold** (continue inspecting)

Operad algebra metric (port diameter, BindingCategory saturation) gives the **semantic dimension**
of the same test: is this structure algebraically complete enough to promote?

Both metrics together gate the promote/discard decision.

---

## Time Delta

**Keep time delta capable.**

The morphism log is indexed by time. Every eval result, promotion, and discard has a timestamp.

Time delta = `t_promote - t_add` = **learning latency** of a structure.

This is observable, queryable, improvable. If learning latency grows → GPU is too full of
known things that haven't been cleared yet. If it drops → system is getting faster at
characterizing new structures.

Time delta is the metric of the inspection pipeline's health.

---

## Claude Desktop as Inspect Agent

Sam noted: connect Claude Desktop as an additional agent. Claude Code remains leadoff.

Proposed role for Claude Desktop:
- Runs as a continuous inspect session over the GPU tier
- Sources: Sam's notes, YouTube channel digests, research papers, PR comments
- Output: new structures to ADD to GPU (not directly to CPU kernel)
- All promotions still go through Claude Code (leadoff) + Sam decision

This extends the three-agent triangle:

```
        Sam
         │ leadoff.md
         ▼
   Claude Code (Strategic)
    ├── Claude Desktop (Inspect / GPU tier agent)
    ├── VS Code AI (Execution / CPU tier agent)
    └── Antigraviti (UX Testing)
```

Claude Desktop's natural interface (conversation, multimodal) maps onto the inspect role:
it surfaces new structures for characterization, not for immediate kernel execution.

---

## Strata Mapping

| Strata | Tier | Role |
|--------|------|------|
| S0,1 | CPU kernel | Structure authored, validated. Morphism log. |
| S2 | CPU kernel | Wires materialized. State folded. |
| S3 | GPU | Ricci curvature computed. Wire complexity measured. |
| S4 | GPU → CPU gate | Rewiring proposals + promote/discard decisions. |

The S4→S0 feedback loop IS the GPU→CPU gate. Metrics at S3,4 decide what moves.

---

## Separation in Code

**Inspect code (GPU tier):**
- Python / CUDA? Separate process from kernel
- Inputs: morphism-log.jsonl (read-only), active graph state
- Operations: HDC encoding, Ricci curvature, operad metric, similarity search
- Output: evaluation results → posted to governance queue (leadoff)
- Never writes to kernel log directly

**Running code (CPU tier):**
- Go kernel (current: `moos/platform/kernel/`)
- Inputs: governance-approved ADD/LINK/MUTATE/UNLINK sequences
- Operations: catamorphic fold, state materialization
- Output: kernel state, served via HTTP + MCP
- Never modifies GPU graph state

**Memory (log tier):**
- `data/morphism-log.jsonl` — never mutated, only appended
- Source of truth for both tiers
- Both tiers replay from log on startup

---

## Open Questions (S0, for Sam)

1. **Inspect process** — separate Go binary, Python, or embedded in kernel with goroutine fence?
2. **Promote morphism** — what ADD/LINK sequence materializes a GPU-proven structure in the kernel?
   Is there a new morphism type? Or does it compose existing ADD+LINK?
3. **GPU graph representation** — is this a separate in-memory graph, or a flagged subgraph of
   the main kernel state? Who owns it?
4. **Discard morphism** — when a structure is discarded, is it an UNLINK from GPU container?
   Or just "not promoted" (never existed in kernel log)?
5. **Ricci implementation** — which Ricci variant? Ollivier (transport) or Forman (combinatorial)?
   Forman is computable in O(E) over sparse graphs; Ollivier is more faithful but O(E·W).
6. **Time delta target** — what is an acceptable learning latency? Does it vary by stratum?

---

## Connection to Existing Work

| Existing | Role here |
|----------|-----------|
| GPU hypervectors `φ(node)` (cloverleaf doc) | IS the inspect substrate |
| Ricci curvature signal (cloverleaf doc) | IS the promote/discard criterion |
| morphism-log.jsonl | IS the memory tier |
| `lens/saturation.go` (Task 033) | Early S3 metric — feeds into eval pipeline |
| FUN10 PortInventory (proposed) | Scans GPU tier for PTP structures ready to eval |
| OBJ24 PortBinding (proposed) | A GPU structure — candidate for promote/discard |
