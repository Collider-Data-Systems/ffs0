# Config to KB SoT Transition — T=160

Date: 2026-04-10
Status: Active extraction completed for durable knowledge.

---

## 1. Decision

`ffs0/kb/` is the only source of truth for durable semantics, workflow policy, and federation operating doctrine.

`moos-config` remains an implementation adapter for bootstrap scripts, IDE wiring, and workstation-local execution details.

---

## 2. Extracted durable knowledge from moos-config

### 2.1 Multi-workstation operating model

- Two-workstation model is stable: hp-laptop + hp-z440.
- Z440 is the main federation runner for this cycle.
- Runtime layout for Z440:
  - primary kernel `:8000`, MCP `:8080`
  - menno kernel `:8001`, MCP `:9001`
  - lola kernel `:8002`, MCP `:9002`
  - moos kernel `:8003`, MCP `:9003`
  - router `:9000`
- Federation reads route by WF16 shard prefixes and optional peer cascade.

### 2.2 Project-board communication protocol

Communication uses GitHub issues and PRs with Project `mo:os` board status as operator signal.

Operational rules:

1. Open issue in the owning repository for each task.
2. Open PR against the same repository and link issue in PR body.
3. Keep issue updated with verification evidence (health check, rewrite/log evidence, outcome).
4. Use project board as shared queue across workstations/IDEs.

Automation rule extracted from workflow:

- `opened`/`reopened`/`ready_for_review` -> status `In Progress`
- merged close -> status `Done`
- non-merged close -> status `Todo`

### 2.3 Agent identity and board mapping

- Agent identity in the graph is authoritative: `urn:moos:agent:*`.
- `board_id` on `agent` nodes bridges graph identity to Project assignment identity.
- Convention: `AGENT-<TOOL>-<WORKSTATION>`.
- Governance remains WF02 with invariant `P(delegate) <= P(principal)`.

### 2.4 Branch protocol

- Agent branches: `agent/<ws>-<ide>/<slug>`
- Human branches: `feat|fix|chore|ci|docs/<scope>/<slug>`
- No direct pushes by agents to default branches.
- T-day scoped work should include `t<NNN>` in branch scope when applicable.

### 2.5 Kernel birth and registration semantics

From operational scripts, the durable semantics are:

1. New kernel instance gets own log and config under `kernels/<name>/`.
2. Birth includes principal and kernel identity rewrites.
3. Registration to primary uses WF16 topology (`routes-to`, shard linking).
4. Primary graph carries federation routing truth; scripts are just emitters.

---

## 3. What is not SoT and stays outside KB authority

- Workstation-local paths and shell profile details.
- Startup folder batch placement mechanics.
- IDE extension preferences as personal defaults.
- Any state DB patching details for one IDE runtime.

These remain implementation details and can change without changing graph semantics.

---

## 4. Placement map inside ffs0 SoT

- Foundations and invariants:
  - `kb/research/20260408-foundation-t158.md`
- Delegation/provenance model:
  - `kb/research/20260410-agent-delegate-provenance-t160.md`
- Session fundamentals map:
  - `kb/research/20260410-fundamentals-map-t160.md`
- Websource to knowledge flow:
  - `kb/research/20260410-websource-to-hg-ki-flow-t160.md`
- This transition record:
  - `kb/research/20260410-config-to-kb-sot-transition-t160.md`

---

## 5. Freshness checks (operator gate)

Before new delegated implementation work:

1. Verify board and repo visibility from current IDE.
2. Verify local kernel/router health (`:8000`, `:9000`).
3. Verify MCP endpoint reachability for active kernels.
4. Verify that any new workflow rule is written to `kb/research/` before relying on it.

If a rule exists only in config scripts or ephemeral conversation, it is not yet SoT.
