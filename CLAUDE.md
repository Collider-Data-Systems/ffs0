# ffs0

Personal portable workspace for moos research and operations.
Owner: `urn:moos:user:sam` — pulled on every workstation.
Machine-specific IDE config (MCP ports) is **gitignored** — copy
`.vscode/mcp.json.example` → `.vscode/mcp.json` on first checkout.

---

## Running state

**Read `kb/superset/running-state.md` first.** Current T-day, active program,
kernel state, open items, key URNs.

Current snapshot (T=166, April 16, 2026):

| | |
|--|--|
| T-day | T=166 |
| Active program | `urn:moos:program:sam.t164-room-tying` |
| hp-laptop log | 298 entries · 95 nodes · 157 relations |
| Ontology | v3.6 — 40 node types, 19 WFs |
| Z440 | offline at T=166 — tasks parked |

---

## The Rule

Four rewrites only: `ADD` · `LINK` · `MUTATE` · `UNLINK`
Log is truth. State is derived. Nodes don't call things. Relations don't carry messages.

---

## Nomenclature

| Use | Never use |
|-----|-----------|
| node | object, element, vertex |
| relation | binding, edge, wire, association |
| rewrite | morphism, update, mutation |
| rewrite category WF01–WF19 | named relation, UML association |
| property | field, payload, attribute |
| operad | schema, grammar |
| interaction node | transition, event, message |
| `_urn` / `_urns` | `_ref` / `_refs` |

Relations are truth. Properties never duplicate topology.

---

## Ontology

`kb/superset/ontology.json` — v3.6, 40 node types, 19 WFs.
WF19 (session governance, local-only, authority=kernel) added at T=164.
Do not edit without reading running-state.md first.
Canonical research reference: `kb/research/20260408-foundation-t158.md`
T=164 delta: `kb/research/20260414-t164-session-channel-purpose.md`

---

## Workspace Structure

```
kb/
  superset/
    ontology.json         — v3.6, source of type system truth
    running-state.md      — live hydration entrypoint (update each session)
  research/               — active research notes (T=164+)
dev/
  moos-viz/               — React/TypeScript graph dashboard
  scripts/                — Python 3 ops and utility scripts
    ops/                  — ops snapshots, health checks, autostart
    tests/                — hydration and session baseline tests
  reference/
    research-archive/     — T=158–T=162 notes (retrieve into context as needed)
  design/                 — design docs (design-research rules apply)
.github/
  instructions/           — IDE-injected context (design-research.instructions.md)
  prompts/                — stored prompts for all IDEs
secrets/                  — GITIGNORED
```

---

## Runtime Repos (siblings)

| Repo | Language | Purpose |
|------|----------|---------|
| `moos-kernel/` | Go 1.23 | Graph rewrite kernel |
| `moos-router/` | Go 1.23 | Federation gateway / reverse proxy |

---

## moos-viz Development

```bash
cd dev/moos-viz
npm install
npm run dev      # Vite dev server (http://localhost:5173)
npm run build    # tsc && vite build
```

Key dependencies: React 19.2.5, @xyflow/react 12.10, Vite 8.0.4, TypeScript 6.0.
CORS target: `http://localhost:8000` (hp-laptop kernel).

---

## Python Scripts

Located in `dev/scripts/`. Python 3, stdlib only.

| Script | Purpose |
|--------|---------|
| `t164_wire_program.py` | Wire T=164 program nodes via REST |
| `t164_delegate_z440.py` | Delegate ops targeting Z440 kernel |
| `ops/verify_kernel_t161.py` | Health + state verification |

Run against a live kernel on `http://localhost:8000` unless path overridden.

---

## Design Rules

From `.github/instructions/design-research.instructions.md`:

- Keep model language **relation-first** and **rewrite-first**.
- No OOP framing: no objects with payload bags, no static UML associations.
- Distinguish: **operad** (admissible grammar) vs **instance** (graph topology + rewrite log).
- All state changes are rewrites (ADD, LINK, MUTATE, UNLINK) — nothing else.
- Relations are topology. Rewrite categories are families of allowed operations.
- Properties are typed, governed, and constrained — not free-form payloads.
- Relations are truth. Properties never duplicate what topology expresses.
- Use only sanctioned nomenclature (see the [Nomenclature](#nomenclature) section).
- Mark conjectures as conjectures — do not assert unproven categorical claims.

---

## Domain Knowledge

Invoke the `moos-domain-expert` skill for categorical/mathematical reasoning.
Archive material: `dev/reference/research-archive/` (T=158–T=162).

---

## Instruction Routing

| Scope | File |
|-------|------|
| Broad defaults | this file |
| Design work | `.github/instructions/design-research.instructions.md` |
| Git flow | `.github/prompts/multi-workstation-git-flow.prompt.md` |
| Running start | `.github/prompts/running-start-t164.prompt.md` |

---

## Safety

- Never commit `secrets/` values or API keys.
- Never commit `.vscode/mcp.json` (machine-specific MCP port config).
- Keep destructive actions explicit and intentional.
