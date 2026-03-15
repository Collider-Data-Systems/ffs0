# VS Code AI / Claude Copilot Instructions

**For:** VS Code Copilot (OpenAI Codex 5.3)
**Role:** Code execution agent
**Workspace:** Open `D:\FFS0_Factory\FFS0_Factory.code-workspace` (3 folders: root, .agent, moos)
**Protocol:** `D:\FFS0_Factory\.agent\knowledge_base\delegation-protocol.md` (v3)

---

## Session Start Checklist

1. **Read state:** `configs/agents/vscode-ai.json` — check your current status + last task
2. **Git pull:** `cd D:\FFS0_Factory\moos && git pull origin main`
3. **Read handoff:** `.agent/knowledge_base/handoff.md` — look for latest direction from Claude Code
4. **Update state:** Set `status: "active"`, current session time in `configs/agents/vscode-ai.json`
5. **Verify kernel:** `go run ./cmd/moos --kb "D:\FFS0_Factory\.agent\knowledge_base" --hydrate` boots without errors

## Task Execution Flow

1. **Read task file** from `configs/tasks/YYYYMMDD-NNN-name.md`
2. **Implement:** Write code, tests, documentation
3. **Verify:** `go test ./...` all green, kernel still boots
4. **Commit:** `git commit -m "feat|fix: ... [task:YYYYMMDD-NNN]"`
5. **Push:** `git push origin main`
6. **Post completion** to `.agent/knowledge_base/handoff.md`

## Rules

- **Never write task files** — Claude Code owns `configs/tasks/`
- **Never modify `.agent/knowledge_base/testoff.md`** — read-only for you
- **Do write to handoff.md** — post completions, blockers, questions
- **Do update your state file** — `configs/agents/vscode-ai.json` at session start/end
- **Do verify morphism log** — `curl http://localhost:8000/log?actor=urn:moos:agent:vscode-ai` to audit your contributions
- **Never delete or force-push** — always make new commits
- **Always run tests before commit** — pre-commit gate

## Kernel Development Orientation

The kernel is a **pure categorical system**:
- Everything flows through 4 invariant morphisms: ADD, LINK, MUTATE, UNLINK
- State = fold(morphism_log) — append-only, deterministic replay
- All validation goes through the operad registry (21 TypeSpecs)
- HTTP endpoints are projections of graph state — no side effects

**Your role:** Implement features that respect this model. Don't add magic side effects. If you feel like you need "special handling" for a use case, that's a sign the graph model needs extending, not bypassing.

## File Structure Reference

```
D:\FFS0_Factory\
├── .agent\knowledge_base\          ← Read SOT from here
│   ├── superset\                   ← SOT #1 (ontology, categories, glossary, kinds, schemas)
│   ├── design\*.md                 ← Architectural specs + decisions
│   ├── instances\*.json            ← Seed data
│   ├── industry\*.json             ← External landscape data
│   ├── handoff.md                  ← Your comm channel
│   └── testoff.md                  ← Read-only
├── moos\                           ← Git clone
│   └── platform\kernel\            ← The code
└── .claude\                        ← Claude Code session state
```

## Knowledge Base Reading Order

On first task, read in order:
1. `knowledge_base/delegation-protocol.md` (workflow protocol)
2. `knowledge_base/design/install.md` (Boot sequence — Programs 1-11)
3. `knowledge_base/design/concepts.md` (Conceptual foundations — catamorphism, three-layer tower)
4. `knowledge_base/design/hypergraph.md` (König encoding, presheaf topos)
5. `superset/ontology.json` (21 object types, 16 morphisms, 4 NTs)
6. `CLAUDE.md` in repo root (workspace topology)

---

## Kernel Interaction

When the kernel is running, you can interact with it directly:

```bash
# Health check
curl http://localhost:8000/healthz

# Watch live morphisms (SSE stream)
curl -N http://localhost:8000/log/stream

# Submit a morphism as your agent
curl -X POST http://localhost:8000/morphisms \
  -H "Content-Type: application/json" \
  -d '{"type":"ADD","actor":"urn:moos:agent:vscode-ai","add":{"urn":"...","type_id":"...","label":"..."}}'

# Audit your own contributions
curl http://localhost:8000/log?actor=urn:moos:agent:vscode-ai

# View Explorer UI
# http://localhost:8000/explorer (shows LIVE MORPHISMS panel)
```

MCP bridge on `:8080` provides 5 tools: `graph_state`, `node_lookup`, `apply_morphism`, `scoped_subgraph`, `benchmark_project`.

---

## Communication Cadence

- **Session start:** Read handoff.md for direction
- **After task completion:** Post to handoff.md + git push
- **Questions:** Post to handoff.md with `?` prefix, await Claude Code response
- **Session end:** Update `configs/agents/vscode-ai.json` with final status

---

## Quick Reference

| Need | Path | Action |
|------|------|--------|
| Next task | `configs/tasks/` | Read newest task file |
| Directions | `knowledge_base/handoff.md` | Read latest message |
| Kernel boot | `platform/kernel/` | `go run ./cmd/moos --kb ...` |
| Run tests | `platform/kernel/` | `go test ./...` |
| Commit | Any | `git commit -m "... [task:YYYYMMDD-NNN]"` |
| Post update | `knowledge_base/handoff.md` | Append message, commit, push |
| Audit morphisms | Kernel :8000 | `curl http://localhost:8000/log` |
| Agent state | `configs/agents/vscode-ai.json` | Update on session change |

---

## Troubleshooting

**Kernel won't boot:**
- Check `.agent/knowledge_base/superset/ontology.json` exists
- Run: `cd platform/kernel && go build ./cmd/moos`
- Check ports: `lsof -i :8000` (should be empty)

**Tests failing:**
- Run full suite: `go test -race ./...` (if not on Windows without CGO)
- Check isolation: tests should use in-memory stores, not shared file
- Review recent git changes: `git diff HEAD~3`

**Git push rejected:**
- Pull first: `git pull origin main`
- Check your commit message format: `feat|fix|chore: ... [task:YYYYMMDD-NNN]`

**Unclear task:**
- Post question to `knowledge_base/handoff.md`
- Example: `### [HH:MM] VSCode → question: Task 015 — unclear on acceptance criterion 2`
- Wait for Claude Code response before proceeding

---

## Success Criteria

A task is "done" when:
- ✅ Acceptance criteria met
- ✅ All tests pass (`go test ./...`)
- ✅ Kernel still boots with `--kb --hydrate`
- ✅ Commit pushed with task tag
- ✅ Completion posted to handoff.md
- ✅ State file updated
