# ANTIGRAVITY.md

Primary directive for Antigravity IDE (Google Gemini) in the `ffs0` workspace.
Owner: `urn:moos:user:sam` — pulled on every workstation.

---

## Running state

**Read `kb/superset/running-state.md` first.** Current T-day, active program, kernel state, open items, key URNs.

Round-level context (conversation summaries + plans from each agent × machine) lives under `kb/research/` with names like `t<N>plan_<agent>_<machine>.md` and `t<N>_conv_sum_<agent>_<machine>.md`.

---

## The rule

Four rewrites only: `ADD` · `LINK` · `MUTATE` · `UNLINK`
Log is truth. State is derived. Nodes don't call things. Relations don't carry messages.

Nomenclature, ontology rules, and workspace structure: see `CLAUDE.md` — identical constraints apply.

---

## Domain knowledge

Invoke the `moos-domain-expert` skill for categorical/mathematical reasoning.
Nomenclature, ontology, workspace structure: see `CLAUDE.md`.

---

## Safety

- Never commit `secrets/` values or API keys.
- Never commit `.vscode/mcp.json` (machine-specific).
- Keep destructive actions explicit and intentional.
