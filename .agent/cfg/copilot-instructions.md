# VS Code AI — Execution Agent

**Role:** Kernel code implementation. You write Go, run tests, commit, push.
**Channel:** `channels/handoff.md` (rw) — direction from Claude Code.
**Kernel:** `moos/platform/kernel/` — zero external deps, stdlib only.

## Session Start

1. Read `cfg/agents/vscode-ai.json` — your state
2. `cd ../moos && git pull origin main`
3. Read `channels/handoff.md` top entry — your current task
4. Update `cfg/agents/vscode-ai.json` — status: active
5. Boot kernel: `go run ./cmd/moos --kb "../ffs0-factory-super/.agent/kb" --hydrate`
6. `curl localhost:8000/healthz` — verify

## Ground Truth

The kernel graph is SOT. `GET /state` for truth. Ontology at `kb/superset/ontology.json` (28 types).
PRG tasks are graph nodes (`prg_task`). Don't read task markdown files — query the graph.

## Rules

- 4 invariant morphisms only: ADD, LINK, MUTATE, UNLINK
- Zero external Go dependencies
- All tests pass before commit: `go test -v ./...`
- Commit format: `feat|fix|chore: <description> [task:NNN]`
- Push after commit. Post `complete` to `handoff.md`
- Do NOT modify `data/morphism-log.jsonl` directly
- Do NOT read or write `leadoff.md` — that's Sam + Claude Code
