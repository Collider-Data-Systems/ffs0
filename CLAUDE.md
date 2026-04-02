# CLAUDE.md

Personal portable private workspace (`ffs0`). Owner: sam (`urn:moos:user:sam`).

## Canonical reference

`kb/research/20260402-codex-unified.md` is the single authoritative pre-code reference for mo:os nomenclature, node types, rewrite categories, and property model.

## The rule

Nothing happens except rewrites. Four operations: ADD, LINK, MUTATE, UNLINK. Edges do not do things. Nodes do not call things. The kernel validates and applies rewrites. The log is truth. State is derived.

## Nomenclature (enforced)

Use ONLY sanctioned terms from codex section 2:
- **node** (not object, element, vertex)
- **relation** (not binding, edge, wire, association)
- **rewrite** (not morphism for the operation, update, mutation)
- **rewrite category** WF01-WF15 (not named static relationship, not UML association)
- **property** (not field, payload, attribute)
- **operad** (not schema, grammar)
- **interaction node** (not transition, event, message)
- **`_urn` / `_urns`** for node references (not `_ref` / `_refs`)

Relations are truth. Properties never duplicate topology.

## Workspace structure

- `kb/research/` — design research and the canonical codex
- `kb/superset/` — formal ontology.json + seed instance data
- `dev/design/` — historical design notes (pre-rebuild, for reference)
- `dev/reference/` — papers, thought notes, youtube digests
- `.github/instructions/` — IDE agent instructions (topic-specific)
- `.github/prompts/` — reusable prompt templates
- `.github/hooks/` — documented agent hooks
- `secrets/` — local-only, never committed

## Safety

- Never commit secret values.
- `secrets/` is sensitive and local-first.
- Public runtime repo `moos` is separate — may not be cloned locally.
- Keep destructive actions explicit and intentional.

## Instruction routing

- Broad defaults: this file
- Design work: `.github/instructions/design-research.instructions.md`
- Session resume: `.github/prompts/resume-ffs0-research.prompt.md`
- Git flow: `.github/prompts/multi-workstation-git-flow.prompt.md`
