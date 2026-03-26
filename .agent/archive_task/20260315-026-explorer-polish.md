---
id: 20260315-026
title: Explorer polish — kind labels + morphism row expansion
status: pending
priority: high
assigned: vscode-ai
deps: [20260315-025]
---

# Task 026: Explorer Polish

Three targeted fixes to the Data Lens Explorer, identified by Antigraviti testing + Sam visual review.

## Fix 1: `app_template` kind label for ontology cat nodes

**Problem:** The 52 `urn:moos:cat:*` nodes hydrated from `superset/glossary.json` and `superset/categories.json`
show as `KIND: app_template (52)` in the Objects tab. These are ontology/glossary nodes, not app templates.

**Root cause:** Their seed envelopes set `type_id: "app_template"`. Check
`D:\FFS0_Factory\.agent\knowledge_base\superset\glossary.json` and `categories.json` for the `type_id` field.

**Fix options (pick one):**
- A: Change the `type_id` in the superset JSON files to a more accurate kind (e.g. `node_container` or a new `cat_node` kind — check ontology.json first for valid kinds)
- B: If the kind is correct per the ontology, rename the display label only in `broadCategory()` in `explorer.html`

Prefer Option A — fix the data, not the display.

## Fix 2: Morphism row expansion

**Problem:** Morphisms tab shows `OWNS (114)` and `CAN_ROUTE (17)` as collapsed groups. Clicking a group
header expands the list of rows but individual rows are not clickable to show detail.

**Fix:** Make each wire row clickable. On click, expand inline to show:
- Source URN (full, monospace)
- Target URN (full, monospace)
- Source port
- Target port
- Wire ID (if available)

Same expand/collapse pattern already used in the Objects tab for node rows.

## Fix 3: Antigraviti IDE note in workflow files

**Problem:** `// turbo-all` directive is not honored by the Antigraviti IDE. The "Always run ↑"
workaround note is in `boot-kernel.md` and `run-tests.md` but NOT in `explorer-smoke-test.md` and `git-sync.md`.

**Fix:** Add the same note to `explorer-smoke-test.md` and `git-sync.md`:
```
> **Antigraviti IDE:** Click **"Always run ↑"** on the first occurrence of each command type. It remembers per pattern for the session.
```

## Deliverables

- [ ] `superset/glossary.json` or `superset/categories.json` — type_id corrected (Fix 1A), OR `explorer.html broadCategory()` updated (Fix 1B)
- [ ] `explorer.html` — morphism row click → inline expansion (Fix 2)
- [ ] `explorer-smoke-test.md` + `git-sync.md` — IDE note added (Fix 3)
- [ ] `go test ./...` still green after any Go changes

## Commit format

```
fix(explorer): kind labels + morphism row expansion [task:20260315-026]
```
