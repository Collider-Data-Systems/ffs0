---
name: mo:os project — durable orientation
description: mo:os is a categorical hypergraph rewriting kernel. Workspace at ffs0 (private), kernel at moos-kernel (public Go). Single source of live state is kb/superset/running-state.md — read it first each session.
type: project
originSessionId: cde10d83-f64f-44cd-a439-5578c4df362b
---

## Live state — read this file first each session

**`C:\Users\maass\HPlaptop\ffs0\kb\superset\running-state.md`** — the hydration entrypoint. Always current: T-day, active program, kernel stats, round-by-round log, Key URNs.

This memory file carries only **durable orientation**. For anything that changes round-to-round (T-day, log count, node count, open sub-programs), read running-state.md.

## Workspace layout

```
C:\Users\maass\HPlaptop\
  ffs0\                  — private workspace (this is where kb/ lives)
    CLAUDE.md            — Claude Code context (lean, points at running-state)
    ANTIGRAVITY.md       — AG context
    kb\
      superset\
        ontology.json    — authoritative S1 type + WF registry
        running-state.md — LIVE state / doctrine file
      research\
        kernel\          — T=187 kernel-proper doctrine
        s1\              — S1 superset / ontology audits / S0 operadic layer / delivery clock
        session\         — session-kernel-bound FAQ
        wires\           — "wires come from" topic
    dev\
      scripts\           — ops + utility scripts
      reference\
        research-archive\ — pre-T=164 notes (retrieve into context as needed)
    .github\
      instructions\      — IDE-specific auto-injected context
      prompts\           — stored prompts
    secrets\             — GITIGNORED
  moos-kernel\           — Go kernel (sibling repo, public)
    internal\graph       — pure types (Envelope, Node, Relation)
    internal\fold        — pure catamorphism (Evaluate, Replay, EvaluateProgram)
    internal\operad      — type system (WF01..WF20, ValidateADD/MUTATE/LINK)
    internal\kernel      — effect layer (Runtime, Store, LogStore)
    internal\reactive    — Watch/React/Guard engine (t_hooks)
    internal\hdc         — hyperdimensional computing
    internal\transport   — HTTP + MCP adapters
    moos.jsonl           — kernel's persistent log
  moos-router\           — federation router (WF16)
```

## Endpoints

- **hp-laptop**: kernel `:8000` · MCP SSE `:8080`
- **Cloudflare tunnels**: `kernel.my-tiny-data-collider.nl` (SSE) · `api.my-tiny-data-collider.nl` (REST) — for the mtdc twin, pending
- **Z440**: kernel `:8000–:8003` · router `:9000`

## Canonical doctrine pointers

Durable doctrine lives in research notes. Where to look:

| Topic | File |
|-------|------|
| T=187 kernel-proper (M1..M20) | `kb/research/kernel/20260417-t187-kernel-proper.md` |
| Session-as-kernel-bound | `kb/research/session/20260418-t168-session-kernel-bound.md` |
| S1 superset + S4→S1 adjoint | `kb/research/s1/20260418-t168-s1-superset-doctrine.md` |
| v3.9 ontology audit | `kb/research/s1/20260418-t168-v3.9-ontology-audit.md` |
| S0 operadic layer | `kb/research/s1/20260418-t168-s0-operadic-layer.md` |
| IRL→HG pipeline (vector spaces, sheaves) | `kb/research/s1/20260418-t168-irl-to-hg-pipeline.md` |
| T=187 delivery clock | `kb/research/s1/20260418-t168-t187-delivery-clock.md` |

## The rule (nomenclature — non-negotiable)

Four rewrites only: **ADD · LINK · MUTATE · UNLINK**. Log is truth. State is derived.

Correct terms: `node` / `relation` / `rewrite` / `property` / `operad` / `port` / `rewrite_category WF01..WF20` / `_urn` / `_urns`.
Never: edge, wire, field, mutation, schema, association, binding, _ref.

## Skill routing for this project

- **`moos-rewrite-envelope`** (user skill, `~/.claude/skills/`) — envelope shape / validator paths / common errors. Auto-triggers on HG rewrite authoring.
- **`anthropic-skills:moos-domain-expert`** — categorical reasoning, HDC, sheaves, strata.
- **`context7`** plugin — library docs lookup.

## Safety reminders

- `ffs0/secrets/` is gitignored — never commit.
- `.vscode/mcp.json` is machine-specific (gitignored) — copy from `.vscode/mcp.json.example` on new machines.
- Never auto-commit `Untitled.png` or similar drag-drop artifacts.
- `ffs0/` is a sibling repo to `moos-kernel/` — when working in moos-kernel, `../../ffs0/kb/superset/ontology.json` is the canonical ontology.
