# MUSTREAD.md — Handoff to Claude Code on HP Laptop

**Date:** 2026-03-16
**From:** Claude Opus (claude.ai session with Sam)
**To:** Claude Code (HP laptop, local terminal)
**Purpose:** Bootstrap the HP laptop as a working mo:os development workstation

---

## 1. IMMEDIATE TASK — Clone repos locally

```bash
# 1. Choose a workspace root
mkdir -p ~/FFS0_Factory && cd ~/FFS0_Factory

# 2. Clone public repo (no auth needed)
git clone https://github.com/MSD21091969/moos.git

# 3. Clone private repo (needs PAT — Sam will provide or use SSH key)
git clone https://<PAT>@github.com/MSD21091969/ffs0-factory-super.git .

# 4. Strip PAT from remote after clone
git remote set-url origin https://github.com/MSD21091969/ffs0-factory-super.git

# 5. Set up credential helper so PAT isn't needed in URLs
git config --global credential.helper store
```

**Sam's PAT must be rotated** — it was exposed in a chat session. Generate a new one:
GitHub → Settings → Developer settings → Personal access tokens → regenerate with `repo` scope.

**Alternative: SSH key setup (preferred)**
```bash
ssh-keygen -t ed25519 -C "sam@moos"
cat ~/.ssh/id_ed25519.pub
# Add output to GitHub → Settings → SSH and GPG keys
git remote set-url origin git@github.com:MSD21091969/ffs0-factory-super.git
cd moos && git remote set-url origin git@github.com:MSD21091969/moos.git
```

---

## 2. WHAT THESE REPOS ARE

### `moos/` — Public kernel (Go)
- **Path:** `moos/platform/kernel/`
- **Entry:** `cmd/moos/main.go`
- **Language:** Go 1.23, zero external deps, pure stdlib
- **Build:** `cd moos/platform/kernel && go build ./cmd/moos`
- **Run:** `./moos --kb ../../.agent/knowledge_base --hydrate`
- **Test:** `go test ./...` (9 packages, all green as of March 15)
- **Health:** `curl http://localhost:8000/healthz`
- **Explorer UI:** `http://localhost:8000/explorer`
- **MCP bridge:** `:8080`
- **Latest commit:** `5097dcf` (March 15) — explorer UX fixes, task 027
- **State:** 118 nodes, 131 wires, 249 log entries

### `ffs0-factory-super/` (cloned as workspace root) — Private workspace
- **`.agent/knowledge_base/`** — ontology, instances, design docs, references, papers
- **`.agent/configs/tasks/`** — task queue (001–027 complete)
- **`.agent/configs/agents/`** — three-agent state files
- **`.agent/knowledge_base/handoff.md`** — strategic comms (Claude Code ↔ VS Code AI)
- **`.agent/knowledge_base/testoff.md`** — test comms (Claude Code ↔ Antigraviti)
- **`.agent/.papers/act2026/`** — ACT 2026 conference paper (LaTeX)
- **`.agent/skills/`** — ~1000 automation skills + custom MOOS skills
- **`CLAUDE.md`** — workspace orchestration (read this on session start)

---

## 3. WHAT mo:os IS

A categorical graph kernel for local-first sovereign AI. The formal model:

```
state(t) = fold(log[0..t])
```

Four invariant natural transformations — **ADD, LINK, MUTATE, UNLINK** — are the only ways to mutate graph state. Everything else is a functor (projection).

### The Central Triangle
```
Category Theory ←→ Hypergraph Rewriting (Wolfram)
       ↑                        ↑
       └────── mo:os ──────────┘
                 ↑
    Hypervector Computing (HDC / VSA)
```

### Architecture (packages in `platform/kernel/internal/`)
| Package | Role | Purity |
|---------|------|--------|
| `cat` | Value types: Node, Wire, Envelope, GraphState, URN, TypeID, Stratum | Pure — no IO |
| `fold` | Σ-catamorphism: `(GraphState × Envelope) → GraphState` | Pure — no IO |
| `shell` | Effect shell: RWMutex state, append-only log, subscriber broadcast | Effects |
| `transport` | HTTP API: 18 routes, SSE streaming | Effects |
| `lens` | Composable graph filter predicates (read-only) | Pure |
| `functor` | UI_Lens, Benchmark projections | Pure |
| `hydration` | S0→S2 pipeline: KB files → MaterializeRequest → Program | Pure |
| `operad` | Type registry, constraint validation | Pure |
| `mcp` | MCP JSON-RPC bridge (5 tools) | Effects |
| `config` | Config loading from file or KB root | Effects |

### Five Strata (S0–S4)
| Stratum | Name | Description |
|---------|------|-------------|
| S0 | Authored | Raw user-created syntax, not yet validated |
| S1 | Validated | Schema-checked, admissible |
| S2 | Materialized | Graph-ready, operational |
| S3 | Evaluated | Semantics computed |
| S4 | Projected | Views, lenses, embeddings (NEVER ground truth) |

### Five Functors
| ID | Name | Signature |
|----|------|-----------|
| FUN01 | FileSystem | Manifest → C |
| FUN02 | UI_Lens | C → React |
| FUN03 | Embedding | payload → ℝ^1536 |
| FUN04 | Structure | subgraph → DAG (planned) |
| FUN05 | Benchmark | Provider → Met |

### SOT Hierarchy
1. `superset/` — always wins (ontology)
2. `design/*.md` — architectural specs
3. `instances/*.json` — deployment seed data
4. `industry/*.json` — landscape data
5. `CLAUDE.md` — workspace policy
6. Task files — reference SOTs, never restate

---

## 4. THREE-AGENT PROTOCOL

| Role | Agent | URN | Channel |
|------|-------|-----|---------|
| Strategic | Claude Code | `urn:moos:agent:claude-code` | `handoff.md` |
| Execution | VS Code AI (Sonnet 4.6) | `urn:moos:agent:vscode-ai` | `handoff.md` |
| UX Testing | Antigraviti (Gemini 3.1 Pro) | `urn:moos:agent:antigraviti` | `testoff.md` |

Full protocol: `.agent/knowledge_base/delegation-protocol.md`

---

## 5. THE CARPET — Core Design Principle

From `.agent/knowledge_base/design/20260314-the-carpet.md`:

> There is a free category (the ontology). There is a fold (the kernel). There are models (the functors). Syntax is fixed. Semantics is variable. Everything else — transport, storage, UI, agents, benchmarks, social graphs, industry landscapes, code, files, users — is either an object in the free category or a functor image of one.

Key insight: the ontology IS a syntax category in Lawvere's sense. Functors ARE the models. What industry calls "semantic" is actually syntactic (schemas, types, validation). True semantics comes from functors mapping syntax to target categories.

---

## 6. LOST CONVERSATION CONTEXT (z440 session, recovered)

Saved at `.agent/knowledge_base/design/lost conversation.txt`. Key points:

1. **Hypergraph H is meta to the kernel.** Kernel instance is a node in H. Federation lives at H level. Social topology is a subgraph of H.
2. **Agent = composed function:** `(graph_state × human_input_channel) → morphism_program`
3. **Workspace separation:** `moos/` public, `ffs0-factory-super/` private. Ontology shared, instances per-workspace.
4. **Sam's directive:** Clean ffs0, eliminate doctrine, separate schemas/superset from implementation and industry. JSONs are serialization — graph is topological and always on. Unlock dataflow from foundational sources to graph.

---

## 7. SAM'S CONTEXT

- Started programming April 2025 with ChatGPT, moved through Gemini, GCloud, Python, explored math → category theory
- Self-describes as "sub-average" dev level but has deep conceptual grasp of the formal model
- Prefers: no metaphors, yes to sci-fi references
- Located: Netherlands (Lelystad)
- Workstations: z440 (primary), z330 (secondary), HP laptop (this one — new)
- The HP laptop needs to function as another local branch point that can push to feature branches on both repos

---

## 8. OPEN ITEMS

- **`urn:moos:agent:copilot-interim`** — 8 wires in graph, flagged by both agents. Sam hasn't ruled on whether to keep it.
- **PAT rotation** — the PAT used in this session must be rotated immediately.
- **ACT 2026 paper** — draft at `.agent/.papers/act2026/main.tex`, needs TikZ figures and implementation section.
- **Cleanup directive** — Sam wants to clean ffs0, remove doctrine, restructure KB. Not yet started.
- **Go runtime** — HP laptop needs Go 1.23+ installed for kernel development.

---

## 9. SKILL FILE

There is a custom Claude skill at `/mnt/skills/user/moos-domain-expert/SKILL.md` (in claude.ai).
For Claude Code, the equivalent lives at `.agent/skills/category-master/SKILL.md` and related `vsa-*`, `harmony-hdc` skills in `.agent/skills/`.

Read `.agent/CLAUDE.md` and `CLAUDE.md` (root) before starting any work.

---

## 10. SESSION START CHECKLIST (for Claude Code)

1. Read `CLAUDE.md` (root)
2. Read `.agent/knowledge_base/delegation-protocol.md`
3. Read `.agent/knowledge_base/handoff.md` (latest messages)
4. Read `.agent/knowledge_base/testoff.md` (latest messages)
5. Check `.agent/configs/tasks/` — all 027 tasks complete, pick up next or Sam's directive
6. Verify Go is installed: `go version` (need 1.23+)
7. Build kernel: `cd moos/platform/kernel && go build ./cmd/moos`
8. Boot: `./moos --kb ../../.agent/knowledge_base --hydrate`
9. Verify: `curl http://localhost:8000/healthz`
