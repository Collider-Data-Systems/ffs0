# FFS0_Factory — mo:os Workspace

**mo:os:** Categorical graph kernel for local-first sovereign AI.

---

## Quick Start

### 1. Open the Workspace
```bash
code FFS0_Factory.code-workspace
```

This opens 3 folders in a single VS Code window:
- **FFS0_Factory (root)** — workspace root
- **Agent Workspace** — KB, configs, tasks, handoff
- **mo:os Kernel** — kernel code + tests

### 2. Run the Kernel
**Press F5** to launch `Kernel (with --kb --hydrate)` or use terminal:
```bash
cd moos/platform/kernel
go run ./cmd/moos --kb D:\FFS0_Factory\.agent\knowledge_base --hydrate
```

Expected output:
```
[boot] kb=D:\FFS0_Factory\.agent\knowledge_base
[boot] registry loaded: 21 types from ...
[shell] replayed 148 morphisms → 68 nodes, 80 wires
[transport] listening on :8000
[mcp] listening on :8080
```

### 3. Verify It's Running
```bash
curl http://localhost:8000/healthz
# {"nodes":68,"status":"ok","wires":80,"log_depth":148}

curl -N http://localhost:8000/log/stream
# : connected
```

### 4. Open Explorer UI
**In browser:** http://localhost:8000/explorer

You should see:
- Graph visualization (68 nodes, colored by type)
- Sidebar (nodes, wires, stats)
- Activity log (real-time morphisms via SSE)

---

## Workspace Tasks

Open **Terminal → Run Task** (Ctrl+Shift+P → "Tasks: Run Task"):

| Task | Purpose |
|------|---------|
| **Kernel: build** | `go build ./cmd/moos` |
| **Kernel: test all** | `go test ./...` (all green) |
| **Kernel: run (with --kb --hydrate)** | Start kernel + hydrate graph |
| **Git: pull latest** | `git pull origin main` |
| **Git: status + log** | Show uncommitted changes + last 5 commits |
| **KB: open handoff.md** | Open strategic comm channel |
| **KB: open testoff.md** | Open test results channel |
| **KB: open delegation-protocol.md** | Read three-agent protocol |

---

## File Structure

```
D:\FFS0_Factory\
├── FFS0_Factory.code-workspace      ← This file (VS Code multi-folder setup)
├── README.md                         ← You are here
├── .agent\                          ← Private: KB, configs, tasks, handoff
│   ├── knowledge_base\              ← Kernel --kb path
│   │   ├── superset\                ← Ontology, categories, glossary, kinds, schemas
│   │   ├── instances\*.json         ← Seed data (15 files)
│   │   ├── design\*.md              ← Architecture specs + timestamped decisions
│   │   ├── industry\                ← External landscape data
│   │   ├── reference\               ← Manifesto, manuscript, paper digests
│   │   ├── handoff.md               ← VS Code ↔ Claude Code
│   │   ├── testoff.md               ← Antigraviti ↔ Claude Code
│   │   └── delegation-protocol.md   ← Three-agent protocol
│   └── configs\
│       ├── agents\*.json            ← Agent state files
│       ├── tasks\                   ← Task definitions
│       ├── copilot-instructions.md  ← VS Code instructions
│       └── antigraviti-instructions.md ← Antigraviti instructions
├── .claude\                         ← Claude Code session state
└── moos\                            ← Git clone (public repo)
    └── platform/kernel\            ← The kernel code
```

---

## Three-Agent Workflow

### Claude Code (Strategic)
- Writes task files to `.agent/configs/tasks/`
- Monitors `handoff.md` for VS Code completions
- Monitors `testoff.md` for Antigraviti results
- Posts strategic directions
- Audits morphism log

### VS Code AI (Execution)
- Reads task files, implements code
- Posts completions to `handoff.md`
- Submits morphisms as `urn:moos:agent:vscode-ai`
- Updates state file: `.agent/configs/agents/vscode-ai.json`

### Antigraviti (Testing)
- Reads test plan from `testoff.md`
- Runs 95 browser test cases
- Posts results to `testoff.md`
- Submits test morphisms as `urn:moos:agent:antigraviti`
- Updates state file: `.agent/configs/agents/antigraviti.json`

**See:** `.agent/knowledge_base/delegation-protocol.md`

---

## Key Paths

| What | Where |
|------|-------|
| Kernel source | `moos/platform/kernel/` |
| Ontology (SOT) | `.agent/knowledge_base/superset/ontology.json` |
| Seed data | `.agent/knowledge_base/instances/` |
| Architecture specs | `.agent/knowledge_base/design/` |
| Comm channels | `.agent/knowledge_base/handoff.md`, `testoff.md` |
| Task definitions | `.agent/configs/tasks/` |
| Agent state | `.agent/configs/agents/` |
| IDE instructions | `.agent/configs/copilot-instructions.md`, `antigraviti-instructions.md` |

---

## Kernel Routes (16 total)

### Read (11 routes)
| Route | Purpose |
|-------|---------|
| `GET /healthz` | Health check + counts |
| `GET /state` | Full graph state |
| `GET /state/nodes` | All nodes |
| `GET /state/nodes/<urn>` | Single node by URN |
| `GET /state/wires` | All wires |
| `GET /state/wires/outgoing/<urn>` | Outgoing wires from node |
| `GET /state/wires/incoming/<urn>` | Incoming wires to node |
| `GET /state/scope/<urn>` | Scoped subgraph (OWNS transitive closure) |
| `GET /log` | Full morphism log (with `?actor=`, `?type=`, `?after=`, `?limit=` filters) |
| `GET /log/stream` | **SSE stream** — live morphisms |
| `GET /semantics/registry` | Operad registry (21 types) |

### Write (3 routes)
| Route | Purpose |
|-------|---------|
| `POST /morphisms` | Submit single envelope (ADD/LINK/MUTATE/UNLINK) |
| `POST /programs` | Submit batch of envelopes (atomic) |
| `POST /hydration/materialize` | Hydrate instance files into programs |

### Projection (2 routes)
| Route | Purpose |
|-------|---------|
| `GET /functor/ui` | UI projection (FUN02: graph → React) |
| `GET /functor/benchmark/<suite>` | Benchmark projection (FUN05: providers → metrics) |

### UI (1 route)
| Route | Purpose |
|-------|---------|
| `GET /explorer` | Explorer web UI (embedded HTML + Explorer JS) |

---

## MCP Bridge (:8080)

**5 tools for LLM-driven kernel interaction:**
1. `graph_state` — read full state
2. `node_lookup` — read single node
3. `apply_morphism` — submit envelope
4. `scoped_subgraph` — read actor's owned subgraph
5. `benchmark_project` — query benchmarks

---

## Typical Session

```bash
# Terminal 1: Start kernel
cd moos/platform/kernel
go run ./cmd/moos --kb D:\FFS0_Factory\.agent\knowledge_base --hydrate

# Terminal 2: Watch SSE stream
curl -N http://localhost:8000/log/stream

# Terminal 3: Work on code
code FFS0_Factory.code-workspace
# Then: implement task, commit, push

# Browser: Monitor UI
# http://localhost:8000/explorer
```

---

## Git Workflow

```bash
# Pull latest
git pull origin main

# Check status
git status -s

# Implement + test
go test ./...

# Commit
git commit -m "feat: description [task:20260313-NNN]"

# Push
git push origin main

# Audit
git log --oneline -5
```

---

## Resources

- **Kernel README:** `moos/platform/kernel/README.md`
- **Delegation Protocol:** `.agent/knowledge_base/delegation-protocol.md`
- **Architecture Specs:** `.agent/knowledge_base/design/`
- **Ontology (immutable SOT):** `.agent/knowledge_base/superset/ontology.json`
- **ACT 2026 Paper:** `.agent/.papers/act2026/main.tex`

---

## Troubleshooting

**Kernel won't boot:**
- Check `.agent/knowledge_base/superset/ontology.json` exists
- Check port 8000 is free: `lsof -i :8000`
- Check Go version: `go version` (1.21+)

**Tests fail:**
- Run individually: `go test -v -run TestName ./internal/cat`
- Check lock contention: `go test -race ./...`

**Git push rejected:**
- Pull first: `git pull origin main`
- Check branch: `git branch` (should be `main`)

**Explorer not loading:**
- Kernel must be running on `:8000`
- Check: `curl http://localhost:8000/healthz`
- Hard refresh browser: `Ctrl+Shift+R`

---

**Status:** Week 3 complete. Paper draft, Explorer UI, demo scripts, .agent extraction done.

**Next:** Week 4 — v0.1.0 release, CI pipeline, arXiv submission, open-source docs.
