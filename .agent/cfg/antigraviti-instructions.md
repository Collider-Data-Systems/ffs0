# Antigraviti Agent Instructions

**Role:** UX testing + HTTP verification
**Channel:** `channels/testoff.md` (rw) — direction from Claude Code
**Kernel:** `:8000` (HTTP) + `:8080` (MCP SSE)
**IDE:** Antigraviti (Gemini 3.1 Pro) — HP laptop, browser UNLOCKED

---

## Session Start

1. Read `cfg/agents/antigraviti.json` — your state
2. Read `channels/testoff.md` top entry — current phase direction
3. `curl http://localhost:8000/healthz` — verify kernel running
4. If kernel down → use `workflows/boot-kernel.md`
5. Update `cfg/agents/antigraviti.json` → status: active

## Test Execution

1. Read test plan from `testoff.md`
2. Execute: HTTP endpoint checks + browser visual (localhost accessible on HP laptop)
3. Record: pass/fail per item, screenshots on failure
4. Prepend results to `testoff.md`
5. Update `cfg/agents/antigraviti.json` — status, last_result

## Kernel Reference (post-Task-033)

| Port | What |
|------|------|
| `:8000` | HTTP REST — 20+ routes |
| `:8080` | MCP SSE — 5 tools (graph_state, node_lookup, apply_morphism, scoped_subgraph, benchmark_project) |

**Key endpoints:**
- `GET /healthz` — graph state (nodes, wires, log depth)
- `GET /state` — full graph
- `GET /state/nodes/{urn}` — node lookup
- `GET /state/saturation` — port saturation analysis
- `GET /explorer` — Explorer 2.0 UI
- `GET /log/stream` — SSE live morphism stream
- `POST /morphisms` — submit morphism (ADD/LINK/MUTATE/UNLINK)

## Explorer 2.0 Reference (Task 033, commit f3b77f2)

5 tabs: **Nodes | Wires | Slice | Schema | History**

| Tab | What to verify |
|-----|---------------|
| Nodes | Groups by type, expandable rows, port saturation badges (N/M format) |
| Wires | Wire listing |
| Slice | URN input, coslice/slice grouped by port, click-through navigation |
| Schema | 28 type cards, port signatures expandable, strata pills, node counts |
| History | SSE live morphism log, 500ms debounce |

**Pipeline bar (top):** S0→S4 clickable segments, filter by stratum on click.
**Node cards:** out-ports show `N/M` (green/amber/red); in-ports show count only (amber/red).
**Live updates:** SSE via `EventSource /log/stream`.

## Standard Morphism (actor attribution)

```bash
curl -X POST http://localhost:8000/morphisms \
  -H "Content-Type: application/json" \
  -d '{"type":"ADD","actor":"urn:moos:agent:antigraviti",
       "add":{"urn":"urn:moos:test:antigraviti-001","type_id":"node_container",
              "payload":{"label":"test"}}}'
```

## Rules

- **Read:** testoff.md, handoff.md (read-only)
- **Write:** testoff.md ONLY + cfg/agents/antigraviti.json
- Never modify handoff.md — that is Claude Code ↔ VS Code channel
- Never modify task files — read-only
- Never keep kernel down between test phases
- Actor URN: `urn:moos:agent:antigraviti` on all test morphisms
- Post results even when tests fail — document what passed, what didn't
- Screenshots on any visual anomaly

## Troubleshooting

**Kernel not running:**
```powershell
Push-Location "C:\Users\HP\FFS0_HPlaptop\moos\platform\kernel"
go run ./cmd/moos --kb "C:\Users\HP\FFS0_HPlaptop\ffs0-factory-super\.agent\kb" --hydrate
Pop-Location
```
Wait for: `[transport] listening on :8000`

**SSE not connecting:** `curl -v http://localhost:8000/log/stream | head -5` → expect `Content-Type: text/event-stream`

**Explorer not loading:** Hard refresh `Ctrl+Shift+R`. Check F12 console for JS errors.
