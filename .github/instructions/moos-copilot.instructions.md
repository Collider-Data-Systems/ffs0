---
applyTo: "**"
---

# mo:os — GitHub Copilot Review Instructions

This repository implements **mo:os**, a categorical graph kernel for local-first sovereign AI.
The codebase spans a Go kernel, a KB/design workspace, and a three-agent protocol.
Apply these instructions to every PR review.

---

## Repository Structure

| Path | What it is |
|------|-----------|
| `moos/platform/kernel/` | Go kernel — the only production kernel executable (other executables are tooling/scripts under `.agent/**`) |
| `.agent/kb/` | Knowledge base — design docs, ontology, instances, papers |
| `.agent/channels/` | Agent communication channels (Markdown channel logs, newest entries at top — prepend pattern) |
| `.agent/cfg/` | Agent config and session state |
| `.agent/tasks/` | Task files — owned by Claude Code + Sam |

**KB files (`.agent/kb/**`, `.agent/channels/**`, `.agent/cfg/**`) are documentation and
coordination artifacts, not source code.** Do not apply code-quality or lint standards to them.

---

## Core Model

**Four invariant morphisms — the ONLY ways to change graph state:**

| Morphism | What it does |
|----------|-------------|
| `ADD` | Create a new node |
| `LINK` | Create a typed wire between two nodes via named ports |
| `MUTATE` | Update a node's payload |
| `UNLINK` | Remove a wire |

**`state(t) = fold(log[0..t])`** — the kernel state is always a catamorphic fold over
an append-only morphism log. Never mutate `data/morphism-log.jsonl` directly.

**Five strata:** S0 (authored) → S1 (validated) → S2 (materialized) → S3 (evaluated) → S4 (projected).
A node moves strata only through governance-approved steps. S0 proposals are not bugs.

---

## Design Document Conventions

Design docs in `.agent/kb/design/` follow these conventions:
- `**Status: S0**` = proposal, not yet implemented. This is correct — do not flag as incomplete.
- `OBJnn` / `FUNnn` = ontology object/functor candidates. Pending approval is intentional.
- Informal language in quoted sections (indented, quoted from Sam's notes) is correct.
- `urn:moos:*` patterns are typed URNs — structural identity, not magic strings.
- `→` in URN patterns is the Unicode right arrow, correct for PTP notation.

---

## MOOS-Specific Vocabulary

Terms that appear unexplained but are defined in the workspace:

| Term | Meaning | Defined in |
|------|---------|-----------|
| CDMU | Copy, Discard, Multiply, Unit — comonoid structure for string diagram composition | `kb/design/20260314-the-carpet.md` |
| PTP | Port-to-Port binding — the 4-tuple `(src_type, src_port, tgt_type, tgt_port)` | `kb/design/20260319-ptp-binding-categories.md` |
| PortBinding / OBJ24 | Reified PTP node — S1 inventory node with params package | same |
| BindingCategory | Full subcategory induced by any WireAlgebra (set of PortBindings) | same |
| PortFunctor / FUN12 | Functor between BindingCategories — existence = navigable path | same |
| φ(node) | HDC hypervector: `⊕{ w : w ∈ wires(node) }` | `kb/design/concepts.md` |
| port diameter | Max wire hops between ports in a container — semantic distance metric | `kb/design/hypergraph.md` |
| Ricci curvature | Ollivier-Ricci wire curvature — positive = robust, negative = rewire candidate | `kb/design/20260319-cloverleaf-kernel-topology.md` |
| KernelLeaf / OBJ25 | Scoped kernel instance in cloverleaf topology | same |
| KernelHub / OBJ26 | Governance node owning cooperad terminals | same |
| S0–S4 | Strata model: authored → validated → materialized → evaluated → projected | `.agent/CLAUDE.md` |
| KBKERHGPRG | KB → Kernel → Hypergraph → Program cycle | `.agent/CLAUDE.md` |
| The Carpet | Foundational design doc — syntax/semantics separation | `kb/design/20260314-the-carpet.md` |
| Coslice | Fan-out from entity → connected hyperedges (cooperad direction) | `kb/design/hypergraph.md` |
| Slice | Fan-in from hyperedge → connected entities (operad direction) | same |

---

## Go Kernel Standards

The kernel (`moos/platform/kernel/`) follows strict rules:

- **Zero external Go dependencies** — stdlib only. Do not suggest third-party packages.
- **No mutation of graph state outside morphism log** — flag any direct state mutation.
- **Append-only log** — `data/morphism-log.jsonl` is never rewritten, only appended.
- **Effect shell / pure core separation** — `internal/` packages are pure; I/O is in `cmd/`.
- **Causal invariance** — morphisms on independent wires must commute. Flag ordering assumptions.
- **Port topology is semantics** — do not suggest moving wire structure to payload/metadata.

**Legitimate patterns (do not flag):**
- `|| 1` fallback only if it's for out-ports (cooperad ceiling); in-ports have no ceiling — if you see `|| 1` applied to in-port saturation, that IS a bug.
- `broadCategory` switch in multiple files is known tech debt (ticket exists), not a new issue.
- `state_payload` as JSONB on nodes is intentional — it's compressed wire bundle, not attribute soup.

---

## Channel / KB File Standards

`.agent/channels/*.md` files are **append-only communication logs**:
- Newest message is always at the top (prepend pattern).
- Format: `### [YYYY-MM-DD HH:MM] Source → type: subject`
- Types: `think | decide | question | answer | blocked | complete | direction | research-task | research-result | hydration-task | hydration-complete | test-plan | test-result`
- Do not flag missing "conclusion" or "resolution" — messages may be open questions.

`session-state.json` is an agent coordination file — timestamps and free-form strings are intentional.

---

## What NOT to Flag

- S0-status proposals ("pending Sam direction") — governance is intentional, not incomplete.
- Design docs with no corresponding code change — KB updates are first-class commits.
- Unicode in URN patterns (`→`, `⊕`, `⊗`, `φ`) — structural notation, correct by design.
- Informal / quoted language in design docs — these are captured design sessions.
- Functor names (FUN10, FUN11, FUN12) without implementations — proposed, not forgotten.
- `OBJnn` candidate labels — ontology governance, not TODO items.
- Absence of unit tests for design docs — they are not code.
