---
name: moos-session-start
description: "Use at the start of any mo:os work session to verify current kernel status, runtime endpoints, active waves, and the surviving design corpus before planning or implementation."
---

# mo:os Session Start — Claude Code

Run this at the start of every session to orient before any design or planning work.

---

## 1. Establish T

T=0 = Nov 1, 2025. Calculate today's T from the date.

---

## 2. Check kernel status

```
GET http://localhost:8000/healthz   → preferred runtime
GET http://localhost:8081/healthz   → fallback runtime
```

If not running, boot:

```powershell
cd C:\Users\maass\HPlaptop\moos\platform\kernel
go run ./cmd/moos
```

---

## 3. Current system state

- **Status:** Incidence-first rebuild with Wave commits applied.
- **Kernel core:** Node, Port, Binding, Property primitives.
- **Boot inputs:** `grammar.json` + `seed.json`.
- **Proof surface:** Explorer and HTTP endpoints for grammar/state/morphisms.

---

## 4. Available skills (invoke as needed)

| Skill                         | Trigger                                                           |
| ----------------------------- | ----------------------------------------------------------------- |
| `/moos-domain-expert`         | Any design, morphism, strata, invariant, category theory question |
| `/golang-backend-development` | Go code, tests, kernel conventions                                |
| `/harmony-hdc`                | HDC/VSA encoding, GPU, wire formulas                              |
| `/quic-graph-streaming`       | Transport design, log replication                                 |
| `/http3-quic-transport`       | HTTP/3 kernel transport                                           |

---

## 5. Runtime quick checks

```
GET /grammar
GET /nodes
GET /bindings
GET /explorer
GET /api/rewrite/plans
```

---

## 6. Three-agent coordination

| Agent             | Role                                         | Contact                      |
| ----------------- | -------------------------------------------- | ---------------------------- |
| Claude Code (you) | Strategic — planning, architecture, research | —                            |
| VS Code AI        | Execution — Go code, testing, git            | `urn:moos:agent:vscode-ai`   |
| Antigraviti       | UX — HTTP verification, Explorer             | `urn:moos:agent:antigraviti` |

To delegate to VS Code AI: apply a `delegation_task` morphism via MCP or describe clearly what to implement.

---

## 7. Design docs (surviving corpus)

All in `.agent/dev/design/`:

| Doc                                            | Core concept                    |
| ---------------------------------------------- | ------------------------------- |
| `20260322-categorical-space.md`                | CS vs HG, 5 invariants          |
| `20260321-prg-in-graph.md`                     | PRG as graph node               |
| `20260319-ptp-binding-categories.md`           | Port-to-port 4-tuple            |
| `20260324-shipping-project-git-hg-strategy.md` | Shipping and migration strategy |
| `20260324-triangle-operations-manual.md`       | Triangle operating model        |
| `20260325-cloverleaf-autonomous-kernels.md`    | Multi-kernel topology           |
| `20260326-fiber-decomposition.md`              | Fiber structure                 |
| `20260330-local-to-ontology-promotion.md`      | Promotion discipline            |
| `20260401-conversation-summary.md`             | Current conversation summary    |

Read the latest doc first to understand current architectural thinking before proposing anything.

---

## 8. Before ending session

1. If waves advanced, append checkpoint note to `.agent/workflows/session-start-vscode.md`.
2. If API surface changed, verify explorer and morphism endpoints manually.
3. Do not add new design docs unless explicitly requested; keep design discussion in chat when asked.
