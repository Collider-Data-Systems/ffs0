# Task 015: Fix FUN02 Glossary/Kernel Filter Projection

**Priority:** P1
**Depends on:** Task 009 (Explorer UI — done)
**Estimated effort:** ~40 lines Go + JS
**Source:** Antigraviti test gap #3 (tests 6.x, 7.x — toggles show 0 nodes)

## Objective

When "show glossary" or "show kernel/feature nodes" toggles are enabled in Explorer, the corresponding nodes should appear. Currently toggles are wired but show 0 nodes.

## Investigation Needed

1. Are glossary nodes (`urn:moos:cat:*`) seeded in the kernel graph? Check hydration.
2. Does FUN02 (`internal/functor/ui_lens.go`) filter them out?
3. Are kernel/feature nodes a separate type_id or a category filter?

## Acceptance Criteria

- [ ] "Show glossary" toggle reveals category-theory reference nodes (if seeded)
- [ ] "Show kernel/feature" toggle reveals system nodes
- [ ] Stats update when toggles change
- [ ] SVG canvas renders new nodes when toggles are enabled
- [ ] If nodes aren't seeded, create seed data in instances/ and document the decision

## Implementation Notes

Check `internal/functor/ui_lens.go` Project() method — does it skip certain type_ids?
Check `explorer.html` toggle logic — does it filter by `kind` or `broad_category`?
May need new instance file or additions to existing ones.

## Context

Antigraviti Phase 2 tests 6.x and 7.x: toggles present and wired, but data shows 0 nodes for both categories. Either a seeding gap or a projection filter issue.

## Commit

`fix: enable glossary/kernel nodes in Explorer FUN02 projection [task:20260313-015]`
