---
description: "Use when working in design docs to reason about model semantics before implementation."
applyTo: "dev/design/**/*.md"
---

# Design Research Rules

- Keep model language relation-first and rewrite-first.
- Avoid OOP framing: no objects with payload bags, no static UML associations.
- Distinguish clearly:
  - Operad (admissible grammar, valid composition rules)
  - Instance (realized graph topology + rewrite log)
- Treat all state changes as rewrites (ADD, LINK, MUTATE, UNLINK) — nothing else exists.
- Relations are topology (results of LINK). Rewrite categories (WF01-WF19) are families of allowed operations. Do not conflate the two.
- Properties are typed, governed, and constrained — not free-form payloads.
- Relations are truth. Properties never duplicate what topology expresses.
- Use only sanctioned nomenclature: node (not object), relation (not edge/binding), rewrite (not morphism for the op), operad (not schema/grammar), interaction node (not transition).
- Use `kb/superset/running-state.md` and `kb/superset/ontology.json` as authoritative references.

## Output Style

- Prefer concise conclusions over long speculative prose.
- Capture unresolved questions explicitly as 1-2 bullets.
- Mark conjectures as conjectures — do not assert unproven categorical claims as settled.
