# FFS0 Programs — Reference

**Owner:** Sam Maassen + Claude Code
**Last updated:** 2026-03-16
**Purpose:** Canonical reference for the two active programs. Survives conversation loss.

---

## Program 1 — KB Hydration Machine

**What it is:** The triangle as CI/CD pipeline. Sam + Claude Code govern the KB; VS Code implements; Antigraviti tests; results fold back into KB.

**Stack (KBKERHGPRG):**

| Layer | What | Who |
|-------|------|-----|
| US | Conversation (strategic direction, task creation) | Sam + Claude Code |
| KB | Committed knowledge base (superset, design, instances, tasks) | ffs0-factory-super |
| KER | Kernel fold: `state(t) = fold(log[0..t])` — hydration materializes KB into graph | mo:os |
| HG | Hypergraph: multi-workstation topology, agents as nodes, wires as channels | Kernel state |
| PRG | Task execution by triangle agents | VS Code AI + Antigraviti |

**Cycle:**

```
Sam + Claude Code
  → task in configs/tasks/
  → direction in handoff.md or testoff.md
  → VS Code AI implements (commits to moos/)
  → Antigraviti tests (posts to testoff.md)
  → Claude Code reviews, merges, updates KB
  → next task
```

**Invariant:** No agent picks tasks autonomously. Sam + Claude Code govern task selection. Agents execute only what is explicitly assigned.

**Channel protocol:**
- `handoff.md` — Claude Code ↔ VS Code AI (prepend, newest top)
- `testoff.md` — Claude Code ↔ Antigraviti (prepend, newest top)
- Message types: `complete` | `blocked` | `question` | `answer` | `direction` | `test-plan` | `test-result`
- Commit convention: `feat|fix|chore: <description> [task:YYYYMMDD-NNN]`

**Current sprint:** Week 4 (release). Tasks 001–027 done. Task 028 (MCP stdio transport) in progress — VS Code AI implementing, Antigraviti standing by to test.

---

## Program 2 — Superset + Paper + Research

**What it is:** Deep conceptual work between Sam and Claude Code. No triangle agents involved. Outputs eventually feed Program 1 as new KB content or tasks.

**Active workstreams:**

| Thread | Status | Output target |
|--------|--------|---------------|
| ACT 2026 paper | Draft exists (`.papers/act2026/main.tex`) | arXiv + conference |
| Superset category | Ongoing — ontology.json is living SOT | KB superset/ |
| Industry projections | Curated externally → industry/*.json | KB industry/ |
| .agent/ structure design | Open — see structural debt below | Design decision |
| arXiv + YouTube ingress | Proposed by VS Code — needs governing decision | KB tooling |

**How Program 2 feeds Program 1:** Conceptual clarity → KB doc or ontology update → committed → hydrated → visible in graph → new task assigned to VS Code.

---

## .agent/ Structure — Known Debt

**Current layout mixes four concerns:**

| Concern | Content | Should live in |
|---------|---------|----------------|
| KB | superset/, design/, instances/, industry/, reference/ | Stable presheaf — commit-and-read |
| PRG | configs/tasks/, workflows/, handoff.md, testoff.md | Execution artifacts — live wires |
| CFG | configs/agents/*.json, *-instructions.md | Functor config — agent parameterization |
| S1 | skills/ | Context mounting — injected per task |

**Category error:** `handoff.md` and `testoff.md` live inside `knowledge_base/` but are PRG artifacts — they have temporal structure (append-only log), directional structure (sender → receiver), and volatile state. KB content is stable (commit-and-forget). PRG channels are live wires. These are different categorical objects.

**Why not fixed yet:** All three agents have the KB paths hardcoded in their CLAUDE.md, instructions, and configs. Migration requires coordinated update across all agents plus delegation-protocol.md. It is structural debt, not urgent.

**Target structure (future):**
```
.agent/
├── kb/          # stable presheaf content
├── prg/         # execution: tasks, channels (handoff/testoff), workflows
├── cfg/         # functor config: agents, instructions
└── s1/          # skills: context mounting content
```

**When to fix:** After v0.1.0 release (post-Week 4). Create as a task.

---

## Triangle — Agent Roles

| Role | Agent | Model | Channel | Scope |
|------|-------|-------|---------|-------|
| Strategic | Claude Code | Claude Sonnet | handoff.md (rw), testoff.md (rw) | Plans, KB, paper, delegation, research |
| Execution | VS Code AI | GPT-4.1-Codex | handoff.md (rw) | Implements, tests, commits, pushes |
| UX Testing | Antigraviti | Gemini 3.1 Pro | testoff.md (rw) | HTTP tests, browser tests, test cycles |

**Workstations:** z440 (primary), HP laptop (secondary, both agents running locally), z330 (dormant).

**Multi-workstation:** KB is git. All workstations sync via `git pull`. No workstation-specific state except agent config files.

---

## Open Items (as of 2026-03-16)

| Item | Status | Owner |
|------|--------|-------|
| Task 028 — MCP stdio transport | VS Code implementing | VS Code AI → Antigraviti |
| ACT 2026 paper — TikZ figures + implementation section | Open | Claude Code + Sam |
| PAT rotation | Overdue — PAT exposed in conversation | Sam (manual) |
| CLAUDE.md — still references `D:\FFS0_Factory\` paths | Known | Claude Code |
| arXiv + YouTube ingress tooling | Proposed, not governed | Sam + Claude Code |
| .agent/ structure refactor | Structural debt, post-release | Sam + Claude Code → task |
