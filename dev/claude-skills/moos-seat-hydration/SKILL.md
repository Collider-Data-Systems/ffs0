---
name: moos-seat-hydration
description: Hydrate a fresh mo:os conversation for whatever seat it lands on — the operational replacement for Sam's re-pasted orientation prompt (the old `tmp/*handoff*.md` blocks). Use at the very first turn of any new conversation in an mo:os workspace (`ffs0`, `moos-kernel`, `moos-router`, `moos-viz`), or whenever you need to (re)establish who/where you are before doing work. Resolves the current seat from an explicit arg or from cwd/host, reads the live running-state header + the seat's AGENTS.md row, runs `moos-state-readback`, optionally runs `moos-session-context-projection`, and emits a tight who/where/engine/4.0-version orientation with the active lane and any open handoff items. Trigger phrases: "hydrate this seat", "orient me", "where am I / who am I", "fresh conversation — get oriented", "open this seat", "what seat is this", "catch me up before I start". Composes `moos-state-readback` + `moos-session-context-projection` + `moos-cowork-readback` rather than duplicating them. Use `engine` (4.0 alias) for the runtime that folds the log; URN/type-id stay `kernel` until the gated 4.0.x rewrite.
---

# moos-seat-hydration

The operational successor to Sam's hand-pasted orientation prompt. Where the old flow was: paste a `tmp/*handoff*.md` block at the top of every fresh conversation and let the model absorb it (an **S0 paste** — raw substrate, re-typed each time, drifting the moment any fact changed), this skill makes orientation an **S1 operation** — a procedure that reads live truth (`/healthz`, `running-state.md`, `AGENTS.md`) at invocation time and synthesizes the same orientation from current state. Same output, no stale paste.

> **It supersedes the hand-pasted handoff.** When Sam would have pasted "you are Cowork-Z440, kernel 0 on :8000, T=231, the lane is the 4.0 manifold-bump…", invoke this instead. The facts come from readback, not from a block that was true three rounds ago.

This skill is **READ-ONLY**. It emits no envelopes, pulls no repos, restarts nothing. It orients. Any correction it surfaces (pull a behind repo, re-seat an evicted occupant, restart a version-skewed kernel) is a separate, owner-gated act.

## 4.0 nomenclature note

This round's decision: the canonical 4.0 term for the runtime that folds the log is **`engine`** (re-ratified from the earlier `instance` alias; from the **mo:os ⊣ so:om** engine/surface framing — the engine is the operational side, the surface is the observed side). Use `engine` everywhere as the 4.0 alias. `instance` is the **now-deprecated** prior alias — recognize it in older docs, don't author it. The runtime **type-id and URN stay `kernel`** (`urn:moos:kernel:<host>.<name>`) until the gated 4.0.x URN rewrite lands. So: say "engine", write `urn:moos:kernel:…`.

## Procedure

Run the five steps in order. Steps 2–3 are the cheap core (no kernel restart, no repo mutation); steps 3–4 compose existing skills; step 5 is the synthesis.

### Step 1 — resolve the current seat

Resolve which **seat** (persona × workspace × agent × engine × surface) this conversation occupies. Precedence:

1. **Explicit arg.** If the invocation carries a seat key or an agent/session URN (e.g. `moos-seat-hydration cowork-z440`, or a passed `session_urn`), use it. This wins over inference.
2. **cwd + host inference.** Otherwise derive from the working directory and hostname:

   | Signal | Likely seat(s) |
   |---|---|
   | host `desktop-42d00rd` (Z440) + Cowork/Claude-Code pane | **Cowork-Z440** (`agent:claude-cowork.hp-z440` / `session:sam.z440-cowork-workspace`) or **Wolfram** (`agent:claude-code.hp-z440` / `session:sam.kernel-proper`) |
   | host Z440 + VS Code, `moos-router` cwd | **Steinberger** (`agent:vscode.hp-z440.menno` / `session:sam.steinberger-seat`) |
   | host Z440 + VS Code, research cwd | **Karpathy** (`agent:vscode.hp-z440.lola` / `session:sam.karpathy-seat`) |
   | host Z440 + Antigravity | **Moos / AG-Z440** (`agent:antigravity.hp-z440` / `session:sam.moos-diary`) |
   | host `lap-sam` (hp-laptop) + Claude Code / Claude Desktop | **John Lydon** (governance; formerly Guido) (`agent:claude-code.hp-laptop` / `session:sam.governance`) |
   | host `lap-sam` (hp-laptop) + VS Code/Copilot | **Guido** (laptop VS Code lead, T247 split) (`agent:vscode.hp-laptop.copilot` / `session:sam.laptop-vscode-lead`) |
   | host hp-laptop + Cowork | **Cowork-laptop** (`agent:claude-cowork.hp-laptop` / `session:sam.laptop-cowork-workspace`) |
   | host ProDesk (`desktop-3fc7c3f` / `desktop-42d00rd`-distinct) + VS Code | **HP ProDesk** (`agent:vscode.hpprodesk.primary` / `session:sam.hpprodesk-setup`) |

   On Z440 the harness is the tie-breaker: a Cowork/Claude-Code pane → Cowork-Z440; a VS Code/Copilot pane on `moos-kernel` → Wolfram; on `moos-router` → Steinberger; on a research/`ffs0` root with VS Code → Karpathy. When the harness is ambiguous, **state the candidate set and ask** rather than guessing — a wrong seat poisons the whole orientation.

3. **Authoritative source for the resolved seat's row:** the **Seats table in `AGENTS.md`** (`D:\HPZ440\ffs0\AGENTS.md`, "Seats — agent × workspace × instance × surface") and the per-seat entry in `dev/config/session-affordance-map.json` (skills/prompts/`emit_kernel`/`mcp_server`/`opens_on_kernel`). Read the row, don't reconstruct it from memory.

   ```bash
   # quick host probe
   hostname
   ```
   ```powershell
   $env:COMPUTERNAME
   ```

### Step 2 — read live header + the seat's row

Two reads, both cheap, both live-truth:

1. **Running-state header** — `kb/superset/running-state.md`, the top `> Updated:` block. Gives the live **T-day**, what shipped this/last round, and what's **pending**. This is the hydration entrypoint; read it before claiming any state is current.

   ```bash
   head -10 /d/HPZ440/ffs0/kb/superset/running-state.md
   ```

2. **The seat's AGENTS.md row** — the resolved persona's line in the Seats table: its `agent` (principal), `workspace`(⟵`session`), `engine`(⟵`kernel`) + port, surface/IDE, and MCP port. Cross-check against `session-affordance-map.json` for the seat's mounted **skills** and `emit_kernel` / `opens_on_kernel` topology.

   **Engine discipline (read directly from the row, don't assume):** Z440 personae **emit** to `hp-z440.primary` :8000 / MCP :8080 today; the twins (`menno` :8001/:9001, `lola` :8002/:9002) carry `opens-on` **topology intent**, not state replication, pre-§M9. So the seat's *emit engine* and its *opens-on engine* can differ — name both if they do.

### Step 3 — run `moos-state-readback`

Invoke **`moos-state-readback`** (don't re-implement it here). It performs the per-repo `git -C <path> fetch` + divergence check on `ffs0` / `moos-kernel` / `moos-router`, pings `/healthz` on the seat's **engine** (reading `ontology_version` directly), audits the engine process + ports, and lists open handoff-issue comments. That gives you:

- per-repo crisp/behind status (do **not** claim "crisp" without it),
- the engine's **runtime 4.0 version** from `/healthz` (vs on-disk `ontology.json`),
- open `ffs0#<N>` handoff comments from peer agents.

If the seat is a **Cowork** seat, also run **`moos-cowork-readback`** for the narrower one-session picture (seat occupied? heartbeat alive? scope-pins resolve? orphan chunks pending?). `moos-state-readback` is fleet-wide; `moos-cowork-readback` is this seat's t-cone — run the fleet one first, then the seat one.

### Step 4 — (optional) session-context projection

When a **fuller** picture is wanted — not just "am I crisp" but "what skills/prompts/MCP/extensions should be mounted for this seat, and what does the folded session subgraph look like" — invoke **`moos-session-context-projection`** (the F-direction projection from HG into the harness context pack). Skip it for a fast open; run it when hydrating a seat you'll do substantial work in, or when the affordance set is in doubt.

### Step 5 — emit the orientation

Synthesize a tight orientation block. This is the **replacement for the pasted handoff** — generated from steps 1–4, not retyped:

```
seat:     <Persona> — agent:<principal> / session:<workspace-urn>
engine:   kernel:<host>.<name> :<port> (4.0 alias: engine) — runtime v<X.Y.Z> [on-disk v<A.B.C>] · MCP :<mcp-port>[ · opens-on :<twin-port>]
host:     <hostname> (<Tailscale/LAN>) · surface <IDE/pane>
repos:    ffs0 <state> · moos-kernel <state> · moos-router <state>   (from state-readback)
lane:     T=<day> — <active-lane one-liner from running-state header>
pending:  <pending items from running-state header>
handoff:  ffs0#<N> — <new peer comments / none>
skills:   <mounted skills for this seat from affordance-map>
verdict:  <crisp + seated, ready> | <N blockers: pull X / re-seat Y / restart Z>
```

Keep it to that. If a row would say "behind" or "version-skew" or "unseated", the conversation **opens with the fix plan**, not with a doctrine claim — same discipline as `moos-state-readback`.

## What this composes (don't duplicate)

This skill is a **conductor**, not a reimplementation:

- **`moos-state-readback`** — does the repo/engine/health/handoff readback. This skill calls it; it does not re-do `git fetch` logic.
- **`moos-cowork-readback`** — the one-session seat check for Cowork seats. Called for Cowork seats only.
- **`moos-session-context-projection`** — the F-direction affordance pack + session subgraph. Called optionally for a fuller open.

`moos-seat-hydration` adds exactly one thing on top: **seat resolution + synthesis into the orientation block that used to be a paste.** If you find yourself re-implementing fetch/health/projection logic here, stop — call the owning skill.

## Why it exists (S0 paste → S1 operation)

Per `AGENTS.md`, IDE/agent conversations are **S0 substrate** — the raw rewriting layer. Sam's old orientation prompt was a literal S0 artifact: a `tmp/*handoff*.md` block, hand-pasted at the top of each fresh conversation, that the model absorbed as context. It worked, but it had the failure mode of every paste: it was **true at authoring time and stale by the next fact-change** — a new T-day, a merged PR, a re-seated occupant, a version bump all silently invalidated it, and nobody re-pastes a 20-line block every round.

Promoting orientation from **S0 paste → S1 operation** removes the staleness: the skill reads `/healthz`, `running-state.md`, and the `AGENTS.md` Seats table **at invocation**, so the orientation is current by construction. The handoff stops being a document you maintain and becomes a derivation you run. That is the same F⊣G move the whole project makes (`S0 conversation → chunker → knowledge_item → projected back out`) applied to the orientation step itself.

## Safety / boundaries

- Read-only. No envelopes, no pulls, no restarts, no commits — every state change stays an explicit owner-gated boundary act.
- If seat resolution is ambiguous, **state candidates and ask**; never silently pick a seat.
- Readback wins over any authored doc: if `AGENTS.md`'s Seats table disagrees with live `/healthz` + HG, the readback is truth — re-read, don't force the table (it is an authored F-projection, not operational truth).
- Never print token/secret values surfaced by any composed step.

## Cross-references

- `moos-state-readback` — fleet-wide repo/engine readback (composed; run it, don't reimplement).
- `moos-cowork-readback` — one-session Cowork seat check (composed for Cowork seats).
- `moos-session-context-projection` — F-direction affordance pack (composed, optional).
- `AGENTS.md` — Seats table + relational spine + 4.0 vocab; the authoritative row source for step 1–2.
- `dev/config/session-affordance-map.json` — per-seat skills/prompts/`emit_kernel`/`mcp_server`.
- `kb/superset/running-state.md` — live header read in step 2; the hydration entrypoint this skill front-ends.

authored-by: agent:claude-cowork.hp-z440 / session:sam.z440-cowork-workspace / t239-catchup
