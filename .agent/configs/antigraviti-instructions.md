# Antigraviti IDE Instructions

**For:** Antigraviti (Gemini 3.1 Pro + Claude Opus 4.6)
**Role:** UX testing + HTTP/3 research agent
**Workspace:** Open `c:\Users\HP\FFS0_HPlaptop\ffs0-factory-super\FFS0_Factory.code-workspace` (3 folders: root, .agent, moos)
**Protocol:** `.agent/knowledge_base/delegation-protocol.md` (v3)
**Workstation:** HP laptop — browser UNLOCKED (local IDE, can access localhost)

---

## Session Start Checklist

1. **Read state:** `configs/agents/antigraviti.json` — check test plan + status
2. **Read direction:** `.agent/knowledge_base/testoff.md` — check latest phase directions from Claude Code
3. **Verify kernel:** Kernel must be running on `:8000` + `:8080`
   - Check: `curl http://localhost:8000/healthz` (should return `status: ok`)
   - Check: `curl -N http://localhost:8000/log/stream` (should show `: connected`)
4. **Update state:** Set `status: "active"`, session start time in `configs/agents/antigraviti.json`

## Test Execution Flow

1. **Read test plan** from `.agent/knowledge_base/testoff.md` (Phase N)
2. **Execute test cases** (headless browser)
   - Navigate to `http://localhost:8000/explorer`
   - Verify page load, DOM structure, data fetch
   - Interact with elements (filters, sidebar, activity log)
   - Capture screenshots on failure
3. **Record results:**
   - Pass/fail count per section
   - Screenshots of any failures
   - Performance metrics (load time, render time)
4. **Post results** to `.agent/knowledge_base/testoff.md`
5. **Await next phase direction** from Claude Code

## Test Plan Structure

The UX test plan is located at:
`design/20260315-explorer-ux-test-plan.md` (but design/ is archived — see testoff.md for current phase)

**Test phases:**
- **Phase 1:** Sections 0-2 (server preconditions, page structure, data fetch) — ~13 tests
- **Phase 2:** Sections 3-5 (canvas, sidebar, stats) — ~16 tests
- **Phase 3:** Sections 6-8 (filters, color map) — ~13 tests
- **Phase 4:** Sections 9-12 (security, performance, error handling) — ~22 tests
- **Phase 5:** Sections 13-15 (API integration, accessibility) — ~17 tests

**Total:** 95 test cases across 15 sections

---

## Kernel Architecture (for testing context)

The kernel you're testing:
- **HTTP server** on `:8000` with 17 routes
- **SSE stream** on `GET /log/stream` — new morphisms appear in real-time
- **Explorer UI** at `GET /explorer` — renders graph + activity log
- **State projection** via `GET /functor/ui` — FUN02 functor maps graph → React components
- **MCP bridge** on `:8080` — 5 tools for LLM-driven testing
  - Bridged to IDE via `mcp-remote` (stdio proxy) — available as `moos-kernel` MCP tool in this IDE
  - Tools: `graph_state`, `node_lookup`, `apply_morphism`, `scoped_subgraph`, `benchmark_project`

---

## Key Test Categories

### Category A: Server Preconditions (Section 0)
- [ ] Kernel boots with `--kb --hydrate`
- [ ] Port `:8000` listening
- [ ] `/healthz` returns JSON
- [ ] `/state` returns graph nodes + wires

### Category B: Page Structure (Section 1)
- [ ] Explorer HTML loads
- [ ] DOM contains `<svg>` canvas element
- [ ] Sidebar has 3 panels: nodes, wires, stats
- [ ] Activity log panel present (bottom)
- [ ] No console errors

### Category C: Data Fetch & SSE (Section 2)
- [ ] `GET /functor/ui` returns node/edge data
- [ ] `GET /log/stream` accepts connection (SSE)
- [ ] New morphisms appear in activity log (live)
- [ ] No network errors

[Continue with Sections 3-15 as per design doc...]

---

## Rules

- **Never modify task files** — read-only for you
- **Never modify handoff.md** — that's the Claude Code ↔ VS Code channel ONLY
- **Never modify handoff.md** — even to raise observations for Claude Code, use testoff.md
- **Do write to testoff.md** — ONLY write channel for Antigraviti
- **Do update your state file** — `configs/agents/antigraviti.json` at session start/end
- **Do capture screenshots** — on any failure, include in testoff.md message
- **Do verify actor attribution:** When submitting test morphisms, use `urn:moos:agent:antigraviti` as actor
- **Never close kernel** between test phases — keep it running for live testing
- **Always post results** even if tests fail — document what passed and what didn't
- **Browser is UNLOCKED** on HP laptop — use `browser_subagent` tool for visual Explorer tests

---

## Phase 1+2 Results (Completed)

**Phase 1:** ALL GREEN ✅ (26/26 — server health, page structure, data fetch)
**Phase 2:** 85% PASS 🟡 (core rendering, sidebar, toggles, SSE, resilience)

**3 gaps identified:**
1. **Missing search box** (test 3.6) → Task 014 assigned to VS Code
2. **Mobile responsive** → Deferred (desktop-first MVP)
3. **Glossary/Kernel filter vacuum** (tests 6.x, 7.x) → Task 015 assigned to VS Code

**Phase 3 (current):** Multi-actor morphism test — see testoff.md for instructions.

---

## Multi-Actor Morphism Testing (Phase 3)

When you're ready to test multi-user scenarios:

1. **You submit a morphism as Antigraviti:**
   ```bash
   curl -X POST http://localhost:8000/morphisms \
     -d '{
       "type": "ADD",
       "actor": "urn:moos:agent:antigraviti",
       "add": {"urn": "urn:moos:test:antigraviti-node-1", "type_id": "node_container", ...}
     }'
   ```

2. **Watch it appear in Explorer activity log:**
   - Timestamp
   - Actor: `urn:moos:agent:antigraviti`
   - Type: `ADD`
   - Target: your node URN

3. **Audit full trail:**
   ```bash
   curl http://localhost:8000/log?actor=urn:moos:agent:antigraviti
   ```

This tests:
- Multi-actor writes to same graph
- SSE push to all subscribers
- Morphism audit trail
- Actor attribution in UI

---

## Communication Cadence

- **Session start:** Read testoff.md for phase direction
- **Phase complete:** Post results to testoff.md + update state file
- **Blocked:** Post blocker to testoff.md with details + screenshot
- **Questions:** Post question to testoff.md, await Claude Code response
- **Session end:** Update `configs/agents/antigraviti.json` with final status + summary

---

## Quick Reference

| Need | Path | Action |
|------|------|--------|
| Current phase | `knowledge_base/testoff.md` | Read latest message |
| Test cases | `design/20260315-explorer-ux-test-plan.md` (archived) | Referenced in testoff |
| Kernel health | CLI | `curl http://localhost:8000/healthz` |
| SSE stream | CLI | `curl -N http://localhost:8000/log/stream` |
| Post results | `knowledge_base/testoff.md` | Append message, update state file |
| Agent state | `configs/agents/antigraviti.json` | Update on session change |
| Morphism audit | CLI | `curl http://localhost:8000/log?actor=urn:moos:agent:antigraviti` |

---

## Troubleshooting

**Kernel not running:**
- HP laptop: `Set-Location "c:\Users\HP\FFS0_HPlaptop\moos\platform\kernel"; go run ./cmd/moos --kb "c:\Users\HP\FFS0_HPlaptop\ffs0-factory-super\.agent\knowledge_base" --hydrate`
- Or use workflow: `/boot-kernel`
- Wait for boot log: `[transport] listening on :8000`
- Check health: `curl http://localhost:8000/healthz`

**Explorer not loading:**
- Check network: `curl http://localhost:8000/explorer` (should return HTML)
- Check browser console (F12) for JS errors
- Try hard refresh: `Ctrl+Shift+R`

**SSE stream not connecting:**
- Check headers: `curl -v http://localhost:8000/log/stream | head -5`
- Should see: `Content-Type: text/event-stream`
- If timeout: kernel may be blocked, check `go test ./...` for lock contention

**Activity log not updating:**
- SSE must be live: `curl -N http://localhost:8000/log/stream` should show `: connected`
- Try submitting a test morphism (POST `/morphisms`) and watch SSE
- Check kernel logs for any apply errors

**Test results unclear:**
- Take screenshot
- Run test case step-by-step manually (don't automate yet)
- Post to testoff.md with: test case #, expected behavior, actual behavior, screenshot

---

## Success Criteria

A test phase is "green" when:
- ✅ All test cases in the phase pass
- ✅ No console errors in browser
- ✅ No network errors (HTTP 200-299 responses)
- ✅ Screenshots captured for any anomalies
- ✅ Results posted to testoff.md
- ✅ State file updated with phase + pass count

---

## Notes on Architecture

### Why the Graph?
The kernel models the entire system as a **typed hypergraph**:
- **Nodes** = objects (models, tools, configs, data)
- **Wires** = relationships (OWNS, CAN_ROUTE, LINK_NODES, etc.)
- **Morphisms** = state changes (ADD, LINK, MUTATE, UNLINK)

Your test validates that the **Explorer UI correctly projects** this graph as React components.

### Why SSE?
Real-time morphism streaming means:
- You see changes instantly (no manual refresh)
- Multi-actor updates are visible simultaneously
- Audit trail is live (not retroactive)

### Why Actor URNs?
Every morphism has an actor (who submitted it). Future multi-user testing will show:
- VS Code's morphisms as `urn:moos:agent:vscode-ai`
- Your test morphisms as `urn:moos:agent:antigraviti`
- All visible in the activity log with correct attribution
