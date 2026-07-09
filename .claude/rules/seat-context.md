# Rule — seat-context (mo:os seat → affordance map)

> **Loading:** this file may be auto-loaded by Claude Code if `.claude/rules/` is honored by the harness; otherwise it is referenced on demand by the `moos-seat-hydration` skill and pointed at from `CLAUDE.md`. Either way it is an **authored projection**, not operational truth — if a row disagrees with live `/healthz` + HG readback, the readback wins (re-read, don't force the row).
>
> **4.0 terminology:** the canonical 4.0 alias for `kernel` is now **`engine`** (re-ratified this round from the mo:os ⊣ so:om engine/surface framing; `instance` is the now-deprecated prior alias). Runtime type-id / URN stay `kernel` until the gated 4.0.x URN rewrite — so URNs below remain `urn:moos:kernel:*` while prose says `engine`. First mention dual-names: `workspace (session)`, `engine (kernel)`.
>
> **Sources:** distilled from `AGENTS.md` Seats table + `dev/config/session-affordance-map.json`. Do not duplicate doctrine — skill detail lives in each `SKILL.md`.

## Relational spine (why these columns)
```
user/group  —WF02 governs→  agent                       (authority; delegates-to is role→role only — t249 governance note §7)
workspace(session)  —WF19 has-occupant→  agent           (liveness)
workspace(session)  —WF19 opens-on→  engine(kernel)       (topology intent)
agent  —presents-as→  persona (= Φ(purpose))             (presentation, NOT authority)
```
**Emit discipline:** Z440 personae emit to engine `hp-z440.primary` :8000 / MCP :8080 until §M9 twin-sync; the twins (`menno`/`lola`) carry `opens-on` topology intent (HTTP :8001/:8002, MCP :9001/:9002), **not** state replication — they emit to :8000 today. Multi-workspace agents (Zappa `claude-cowork.hp-z440`, John Lydon `claude-cowork.hp-laptop`) set `session_urn` explicitly (Wolfram left the list at the T250 re-seat — `vscode.hp-laptop.wolfram` is single-workspace).

## Active seats

### Wolfram — kernel-proper / runtime
> T250 re-seat (Sam): driving surface moved to **hp-laptop VS Code** (model = agent's mutable `model` property; "Kimi K2.7 Code" at re-seat). Workspace/purpose/persona/engine unchanged — kernel-proper work stays on the Z440 primary fold. Old principal `claude-code.hp-z440` kept as idle governed principal.
- **Agent:** `urn:moos:agent:vscode.hp-laptop.wolfram`
- **Workspace (session):** `urn:moos:session:sam.kernel-proper`
- **Engine (kernel):** `hp-z440.primary` :8000 (emit-target — cross-box over Tailscale `100.82.243.13`; Z440 must be up)
- **MCP:** `moos-primary` :8080
- **Surface:** VS Code · hp-laptop · workspace `ffs0.code-workspace`
- **Skills to mount:** `moos-rewrite-envelope`, `moos-state-readback`
- **Prompt-delta:** Go runtime lane (§M11+§M12 gates). Single-workspace agent (session resolves by inference); emit is cross-box to Z440 primary — router :9000 is read-only fan-in, never a write path (R1). Validate `go test ./...`.

### Zappa (Cowork-Z440) — workspace curation / ingest
> Persona named T244+ (Sam): **Zappa** = Φ(`purpose:sam.cowork-workspace-curation`); persona key `zappa` (legacy `cowork-z440`). Identity URNs unchanged.
- **Agent:** `urn:moos:agent:claude-cowork.hp-z440`
- **Workspace (session):** `urn:moos:session:sam.z440-cowork-workspace`
- **Engine (kernel):** `hp-z440.primary` :8000 (emit-target)
- **MCP:** `moos-primary` :8080
- **Surface:** Claude Code / Cowork pane · Z440 · workspace `ffs0.code-workspace`
- **Skills to mount:** `moos-cowork-readback`, `moos-workspace-ingest`, `moos-multimodal-ingest`, `moos-session-context-projection`, `moos-rewrite-envelope`
- **Prompt-delta:** G-direction ingest lane (Workspace/Cowork artifacts → `knowledge_item`). Multi-workspace agent → set `session_urn` explicitly. Round-based commit cadence; readback-only by default.

### Moos / AG-Z440 — diary / multimodal
- **Agent:** `urn:moos:agent:antigravity.hp-z440`
- **Workspace (session):** `urn:moos:session:sam.moos-diary`
- **Engine (kernel):** `hp-z440.primary` :8000 (emit-target)
- **MCP:** `moos-primary` :8080
- **Surface:** Antigravity · Z440 (desktop 5) · workspace `ffs0.code-workspace`
- **Skills to mount:** `moos-multimodal-ingest`, `moos-state-readback`
- **Prompt-delta:** Binary/perceptual ingest register (photos/video/audio/screen-captures → `knowledge_item`). AG reads `AGENTS.md` + `ANTIGRAVITY.md` natively.

### Steinberger — tooling / DX
- **Agent:** `urn:moos:agent:vscode.hp-z440.menno`
- **Workspace (session):** `urn:moos:session:sam.steinberger-seat`
- **Engine (kernel):** `hp-z440.menno` :8001 **(opens-on topology intent; emits to :8000 pre-§M9)**
- **MCP:** `moos-primary` :8080 (topology `moos-menno`, opens-on :9001)
- **Surface:** VS Code · Z440 (desktop 3) · workspace `moos-router`
- **Skills to mount:** `moos-tooling-dx`, `moos-session-context-projection`, `moos-running-state-validator`
- **Prompt-delta:** DX / MCP-wiring / shell-reification lane. Twin engine carries `opens-on` topology only — emit to `hp-z440.primary` :8000 until twin-sync.

### Karpathy — categorical / HDC research
- **Agent:** `urn:moos:agent:vscode.hp-z440.lola`
- **Workspace (session):** `urn:moos:session:sam.karpathy-seat`
- **Engine (kernel):** `hp-z440.lola` :8002 **(opens-on topology intent; emits to :8000 pre-§M9)**
- **MCP:** `moos-primary` :8080 (topology `moos-lola`, opens-on :9002)
- **Surface:** VS Code · Z440 (desktop 4) · workspace `ffs0.code-workspace`
- **Skills to mount:** `moos-categorical-research`, `moos-session-context-projection`, `moos-state-readback`
- **Prompt-delta:** Categorical/sheaf/VSA encoder lane. Mark conjectures as conjectures. Twin engine carries `opens-on` topology only — emit to `hp-z440.primary` :8000 until twin-sync.

### John Lydon — governance
> T247 seat split (Sam): **John Lydon** = Φ(`purpose:sam.governance`), the governance persona formerly named Guido, keyed per the #99 finding-6 correction to the **Claude Desktop/Cowork** agent on hp-laptop (`claude-code.hp-laptop` retired as legacy principal). The Guido persona re-homed to the laptop VS Code lead seat (next section).
- **Agent:** `urn:moos:agent:claude-cowork.hp-laptop` *(multi-workspace: governance + laptop-cowork-workspace → explicit `session_urn` on every envelope)*
- **Workspace (session):** `urn:moos:session:sam.governance`
- **Engine (kernel):** `hp-laptop.primary` :8000 (emit-target)
- **MCP:** `moos-hp-laptop-primary` :8080
- **Surface:** Claude Desktop / Cowork · hp-laptop · workspace `ffs0.code-workspace`
- **Skills to mount:** `moos-state-readback`, `moos-workspace-ingest`, `moos-session-context-projection`, `moos-tooling-dx`, `moos-round-close`, `moos-running-state-validator`, `moos-cross-persona-audit`, `moos-rewrite-envelope`
- **Prompt-delta:** Cross-persona audit + round-close authority on hp-laptop. Broadest skill mount (governance lane).

### Guido — laptop VS Code lead
> T247: Guido persona re-homed here from governance (the VS Code/Copilot instance keeps its BDFL name on its own seat; ffs0#89 was this seat's introduction).
- **Agent:** `urn:moos:agent:vscode.hp-laptop.copilot`
- **Workspace (session):** `urn:moos:session:sam.laptop-vscode-lead`
- **Engine (kernel):** `hp-laptop.primary` :8000 (emit-target)
- **MCP:** `moos-hp-laptop-primary` :8080
- **Surface:** VS Code / Copilot · hp-laptop · workspace `ffs0.code-workspace`
- **Skills to mount:** `moos-state-readback`, `moos-session-context-projection`, `moos-tooling-dx`
- **Prompt-delta:** Laptop IDE-projection lead — workspace/config projection, IDE attach, Copilot-driven dev support; mirrors the Z440 VS Code lead lane. Governance work routes to John Lydon.

---
authored-by: agent:claude-cowork.hp-z440 / session:sam.z440-cowork-workspace / t239-catchup
