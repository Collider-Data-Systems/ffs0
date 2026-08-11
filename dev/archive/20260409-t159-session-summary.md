# mo:os T=159 Session Summary

Date: 2026-04-09 | T=159
Precedes: T=162 (Menno presentation sprint)
Status: Complete. All items shipped, all repos clean, all issues closed.

---

## What T=159 Was

T=159 was the **ignition sprint**: the first session where mo:os ran as a real multi-agent, multi-workstation system rather than a single-machine prototype. Two workstations, six IDE agents, a shared project board, and a federated kernel topology were wired up, documented, and tested under live conditions.

The session closed the gap between the theoretical codex (locked at T=153) and operational infrastructure. Every major capability discussed in T=158 was either implemented, formalized, or explicitly deferred with a documented reason.

---

## 1. Ontology v3.3 — What Was Added

Three new node types and one new rewrite category:

### `program` (S2 infrastructure)

Forward-looking intent node. Temporal properties are **mutable** because plans shift; the append-only log records when they shifted.

```json
{
  "type_id": "program",
  "properties": {
    "title":       { "mutability": "immutable" },
    "owner_urn":   { "mutability": "immutable" },
    "status":      { "mutability": "mutable", "authority_scope": "owner" },
    "scope":       { "mutability": "mutable", "authority_scope": "owner" },
    "target_t":    { "mutability": "mutable", "authority_scope": "owner" },
    "starts_t":    { "mutability": "mutable", "authority_scope": "owner" },
    "deadline_t":  { "mutability": "mutable", "authority_scope": "owner" },
    "completed_t": { "mutability": "mutable", "authority_scope": "owner" }
  }
}
```

Contrast with `prg_task` (Wave 0 legacy): temporal coordinates were immutable — frozen snapshots. `program` nodes are living plans.

### `repository` (S2 infrastructure)

Git repositories as first-class graph nodes. Enables agents to be connected to repos via WF06 (topology), and programs to reference repos via WF18.

### `git_issue` (S2 infrastructure)

GitHub issues as graph nodes. Allows a program to LINK to a git_issue via WF18, making the project board a projection of the graph (not a separate system).

### WF18 — Program Composition

```
src: program
tgt: prg_task | knowledge_item | agent_session | program | git_issue | repository
ports: composes, depends-on, blocks, produces, scheduled-after
mutate_scope: status, scope, target_t, starts_t, deadline_t, completed_t
```

WF18 is the temporal DAG rewrite category. It governs how program nodes compose legacy tasks, express dependencies, and reference development artifacts.

---

## 2. Temporal Dependency Model

Full reference: `20260409-temporal-dependency-model-t159.md`. Key decisions:

### Two dependency modes

**Known-node** — LINK to a specific URN. Used when the exact dependency is known at wiring time:
```
LINK program:sam.hackathon-mvp --depends-on--> program:sam.t159-ignition
```

**Property-pattern** — Watcher filter matching ANY node meeting conditions. Used when the dependency is structural, not specific:
```
WATCH match_type_id=knowledge_item, filter: {domain: "federation", status: "validated"}
```

Property-pattern dependencies are **multiway**: multiple branches of the graph can satisfy the same condition simultaneously. This is not a bug — it is the correct model for open-world dependencies.

### Why temporal properties are mutable

`target_t`, `starts_t`, `deadline_t`, `completed_t` — all mutable. The log records each change with a timestamp. Human IS the clock: temporal properties encode intent, and the human MUTATEs `status` and `completed_t` when conditions are met IRL. The kernel does not poll external time systems.

### Temporal DAGs are nilpotent

Time does not cycle. Therefore the cascade submatrices of a temporal dependency DAG are strictly upper-triangular → nilpotent → spectral radius ρ(C) = 0 → temporal watchers cannot diverge. This is the formal guarantee that reactive evaluation terminates on temporal graphs.

### T=159 Temporal DAG (seeded)

```
t159-ignition (T=159, active)
  ↑ depends-on
t162-presentation (T=162, draft)
  ↑ depends-on
hackathon-mvp (T=169, active, deadline=169)
  ↑ depends-on
full-spec (T=180, draft)
```

---

## 3. Multi-Agent Infrastructure

### Agent nodes (6, seeded)

| URN | IDE | Workstation | Model |
|-----|-----|-------------|-------|
| `urn:moos:agent:hp-vsc` | VS Code | hp-laptop | claude-opus-4-6 |
| `urn:moos:agent:hp-ag` | Antigravity | hp-laptop | claude-opus-4-6 |
| `urn:moos:agent:hp-cc` | Claude Code CLI | hp-laptop | claude-opus-4-6 |
| `urn:moos:agent:z440-vsc` | VS Code | hp-z440 | gpt-4.1 |
| `urn:moos:agent:z440-ag` | Antigravity | hp-z440 | gpt-4.1 |
| `urn:moos:agent:z440-cc` | Claude Code CLI | hp-z440 | gpt-4.1 |

Governance: sam owns all 6 via WF02. All 6 connected to all 4 repos via WF06.

### Multi-kernel spawn

`moos-config/bootstrap/New-MoosKernel.ps1`:
- Creates `kernels/<name>/` directory with `config.json`
- Auto-assigns ports (8001+N)
- Starts kernel process with correct flags
- Health-checks the new instance
- `-Register` flag: ADDs `shard_rule` + `kernel` nodes in primary, wires router→shard→kernel via WF16

Intended use on Z440: `.\New-MoosKernel.ps1 -Name "agent-writer" -Port 8001 -Register`

### Branch naming convention

`moos-config/docs/branching.md`. Key rules:
- Agent branches: `agent/<ws>-<ide>/<slug>` (e.g. `agent/z440-ag/ops-cockpit`)
- Feature branches: `feat/t<NNN>-<slug>` (e.g. `feat/t159-program-node-type`)
- No numbered IDs in slugs — Wave 0 legacy
- Agents must not push directly to default branches

---

## 4. GitHub Infrastructure

### Project board automation

Single source of truth in `moos-config/.github/workflows/project-sync-reusable.yml`. Thin callers in all 4 repos. Any PR or Issue opened/closed/merged → Status field updated automatically.

### IDE agent guides

- `moos-config/ide/vscode/codex-bootstrap.md` — GPT Codex / VS Code bootstrap
- `moos-config/ide/antigravity/codex-bootstrap.md` — AG bootstrap + gh CLI fallback for when MCP token expires
- `moos-config/bootstrap/New-MoosKernel.ps1` — spawn script

### Two-workstation mirror checklist

`moos-config/ide/vscode/two-workstation-mirror-checklist.md` — pre-flight procedure ensuring commit parity across hp-laptop and hp-z440 before starting shared work.

---

## 5. Repo State at T=159 Close

| Repo | Branch | Commit | Notes |
|------|--------|--------|-------|
| ffs0 | main | `5cc6339` | ontology v3.3 + temporal doc + Z440 workspace layout |
| moos-config | master | `fd62b26` | all ops tooling + branching convention |
| moos-kernel | master | `e97dfef` | project-sync workflow |
| moos-router | master | `e809254` | hardened fan-out (unchanged from T=157) |

All issues closed. No open PRs.

---

## 6. Deferred to T=162+

### Landing page (Cloudflare Worker)

Root domain `https://my-tiny-data-collider.nl` currently returns a 502. The moos-router receives the request but has no registered node for `/` → fan-out returns empty → Cloudflare fails. Fix: a lightweight Cloudflare Worker at the root route that serves a static landing page or redirects, before any request reaches the router. This is not a kernel concern — it is a CF infrastructure task.

### Property-pattern watch filter syntax

The watcher mechanism (WF17) supports `match_urn_prefix` for known-node dependencies. Property-pattern dependencies (`match_type_id` + property conditions) need a formal filter expression syntax. Deferred pending T=162 design discussion.

### Z440 kernel rebuild

Z440 should pull ffs0 `main` at `5cc6339` and rebuild kernel binary against ontology v3.3. The sprint that required the rebuild (`moos-config#1`) is closed — procedure documented in the AG guide.

---

## 7. What T=160-162 Needs

1. Z440 kernel running v3.3 ontology
2. Menno presentation material (T=162 program node has `starts_t=162`)
3. Landing page CF Worker (small, independent)
4. Watch filter syntax design (enables property-pattern dependencies to be formally expressed)

---

*T=159 was the session where the map became the territory: every coordination pattern we discussed — 2WS, 6 agents, project board, temporal DAG, multi-kernel spawning — is now running in the graph itself.*
