# ANTIGRAVITY.md

Primary directive for Google Gemini / Antigravity IDE operating in the `ffs0` workspace.  
Owner: `urn:moos:user:sam` — pulled on every workstation.  
Machine-specific IDE config (MCP ports) is **gitignored** — copy `.vscode/mcp.json.example` → `.vscode/mcp.json` on first checkout.

---

## Canonical reference

`kb/research/20260408-foundation-t158.md` — single authoritative source for foundations, nomenclature, node types, rewrite categories, property model, two-presheaf model, functorial semantics, and federation architecture.

`kb/superset/ontology.json` — formal ontology v3.5, 38 node types, 18 rewrite categories. Do not edit without reading the codex first.

---

## The rule

Nothing happens except rewrites. Four operations: ADD, LINK, MUTATE, UNLINK.  
Nodes do not call things. Relations do not carry messages.  
The kernel validates and applies rewrites. The log is truth. State is derived.

---

## Nomenclature (enforced)

| Use | Never use |
|-----|-----------|
| node | object, element, vertex |
| relation | binding, edge, wire, association |
| rewrite | morphism, update, mutation |
| rewrite category WF01-WF18 | named relation, UML association |
| property | field, payload, attribute |
| operad | schema, grammar |
| interaction node | transition, event, message |
| `_urn` / `_urns` | `_ref` / `_refs` |

Relations are truth. Properties never duplicate topology.

---

## Workspace structure

```
kb/
  research/       — codex + design research
  superset/       — ontology.json + seed data
  reference/      — papers, external references
dev/
  design/         — historical notes (pre-rebuild)
  reference/      — digests, evaluations
  scripts/        — ops and utility scripts
secrets/          — GITIGNORED — never committed
```

---

## Runtime repos (siblings — not inside ffs0)

- `moos-kernel/` — Go kernel, branch `agent/z440-claude/hdc-engine`
- `moos-router/` — federation router, branch `master`
- `moos-config/` — **LEGACY**, do not use

---

## Domain knowledge

- For mo:os categorical/mathematical reasoning, invoke the `category-master` skill if available.
- Skills are machine-local (Z440: `~/.agents/skills/`, laptop: `HPlaptop/.github/skills/`) — availability varies per workstation. If a skill is not present, use `kb/research/20260408-foundation-t158.md` as the complete fallback.
- Canonical domain reference: `kb/research/20260408-foundation-t158.md`.

---

## Safety

- Never commit `secrets/` values or API keys.
- Never commit `.vscode/mcp.json` (machine-specific).
- Keep destructive actions explicit and intentional.
