# CLAUDE.md

Personal portable private workspace for mo:os research and operations.
Owner: `urn:moos:user:sam` — pulled on every workstation.
Machine-specific IDE config (MCP ports) is **gitignored** — copy `.vscode/mcp.json.example` → `.vscode/mcp.json` on first checkout.

---

## Running state

**Read `kb/superset/running-state.md` first.** Current T-day, active program, kernel state, open items, key URNs.

---

## The rule

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

`kb/superset/ontology.json` — v3.8, 42 node types, 19 WFs.
Do not edit without reading running-state.md first.

---

## Domain knowledge

Invoke the `moos-domain-expert` skill for categorical/mathematical reasoning.
If needed, archive material can be retrieved from `dev/reference/research-archive/` into conversation context.

---

## Workspace

```
kb/
  superset/     — ontology.json (S1) + running-state.md (hydration entrypoint)
  research/     — active research notes (T=164+)
dev/
  scripts/      — ops and utility scripts
  reference/
    research-archive/  — T=158–T=162 notes (retrieve as needed)
.github/
  instructions/ — IDE-specific auto-injected context
  prompts/      — stored prompts (all IDEs)
secrets/        — GITIGNORED
```

---

## Runtime repos (siblings)

- `moos-kernel/` — Go kernel
- `moos-router/` — federation router
- `moos-config/` — **LEGACY**, do not use

---

## Safety

- Never commit `secrets/` values or API keys.
- Never commit `.vscode/mcp.json` (machine-specific).
- Keep destructive actions explicit and intentional.

---

## Instruction routing

- Broad defaults: this file
- Design work: `.github/instructions/design-research.instructions.md`
- Git flow: `.github/prompts/multi-workstation-git-flow.prompt.md`
- Running start: `.github/prompts/running-start-t164.prompt.md`
