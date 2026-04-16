# T=162 Delegation Plan — Menno Presentation Weekend Sprint

## Context
T=160 is closed. The HDC engine, federation, and ontology are stable. The single remaining deliverable is the **T=162 Menno presentation** (ffs0#12) — a live demo of the distributed hypergraph for a non-technical audience (chemist cousin). Target: **this weekend (Apr 12-13)**.

## Executive Position
This Claude Code conversation on Z440 holds executive/coordinator role. All other agents stand by for delegated work.

---

## Work Streams

### Stream A: CORS + Kernel Rebuild (VSCode Codex, Z440)
**Blocker for everything browser-based.**
- Add CORS middleware to `internal/transport/server.go` (Allow-Origin: *, Methods, Headers, OPTIONS preflight)
- Rebuild all 4 kernel binaries, restart federation
- Verify via curl with Origin header

**Files:** `moos-kernel/internal/transport/server.go`, `moos-kernel/cmd/moos/main.go`
**Time:** 30 min | **Priority:** P0 — blocks Stream C

### Stream B: Seed Classification + Temporal Data (Antigravity, Z440)
**Populate the graph with demo-worthy content.**
- 5 classification schemes across 4 kernels (arXiv+IFRS on primary, LCC on menno, Dewey on lola, ISO on moos)
- 3+ crosswalks via WF12 (arXiv↔LCC, IFRS↔ISO, LCC↔Dewey)
- 5 program nodes for temporal DAG (T=159→T=160→T=162→T=169→T=180) linked via WF18
- All operations via POST /rewrites — no daemons, no creative freedom, strict envelope scripts
- Bonus: seed urn:moos:scheme:cas with chemistry domain_tags for Menno relevance

**Files:** Ontology reference at `ffs0/kb/superset/ontology.json`
**Time:** 1-2 hrs | **Priority:** P1 — parallel with Stream C after CORS

### Stream C: Frontend Visualization App (Claude Code executive, Z440)
**Critical path — the delivery vehicle for the demo.**
- Vite + React + @xyflow/react app in new directory (moos-viz/)
- 4 panels in 2x2 CSS grid:
  - Panel 1: Federation topology (live via SSE from all 4 kernels)
  - Panel 2: Classification space (HDC /classification-space endpoint)
  - Panel 3: Temporal DAG (program nodes + WF18 dependencies)
  - Panel 4: Value attribution (type-coherence as Shapley proxy)
- Data via router :9000 (fan-out) + direct kernel ports for per-kernel views
- EventSource for SSE live updates on Panel 1

**Time:** 4-6 hrs | **Priority:** P0 — this IS the demo

### Stream D: Demo Narration Guide (hp-laptop, async)
**The story layer for a non-technical audience.**
- 2-3 page narration script in `ffs0/kb/research/20260412-t162-demo-narration.md`
- Per-panel 2-sentence explainer
- Chemistry tie-in (CAS↔IUPAC crosswalk as concrete analogy)

**Time:** 1-2 hrs | **Priority:** P2 — can happen last

---

## Sequence

```
Friday evening (now)     Saturday morning          Saturday afternoon
Stream A [CORS]──────┐
  30 min              │
                      ├── Stream C [Frontend] ──────────── [Polish]
                      │     4-6 hrs
Stream B [Seed] ──────┤
  1-2 hrs (parallel)  │
                      │
Stream D [Narration] ─┘──────────────────────────── [Rehearse]
  Independent
```

**Critical path:** A → C → Integration
**Integration point:** Saturday afternoon — all 4 kernels seeded, frontend connects, verify all panels

---

## Federation Demo Flow

| Kernel | Port | User | Role | Content |
|--------|------|------|------|---------|
| primary | :8000 | sam | Orchestrator | Agents, programs, temporal DAG, arXiv+IFRS schemes |
| menno | :8001 | menno | Knowledge builder | LCC scheme, chemistry domain_tags |
| lola | :8002 | lola | Research analyst | Dewey scheme, ML research items |
| moos | :8003 | moos | Infrastructure | ISO scheme, system health |

**Live sequence:** Show topology → live-add a knowledge_item to menno → watch SSE propagate → show classification space → show temporal DAG → show value attribution concept.

---

## Fallback
If frontend takes too long: single-panel topology-only app (Panel 1). Panels 2-4 shown as curl → JSON → screenshot.

## Verification
- `http://localhost:5173` loads 4-panel app
- Panel 1 updates live when POST /rewrites hits any kernel
- Panel 2 shows 5 schemes in 3D/2D with crosswalk arrows
- Panel 3 shows temporal DAG with T=162 highlighted
- No CORS errors in browser console
