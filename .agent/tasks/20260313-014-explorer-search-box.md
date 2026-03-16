# Task 014: Explorer Sidebar Search Box

**Priority:** P1
**Depends on:** Task 009 (Explorer UI — done)
**Estimated effort:** ~30 lines HTML/JS
**Source:** Antigraviti test gap #1 (test case 3.6)

## Objective

Add a search/filter input to the Explorer sidebar so users can find nodes by URN, label, or type_id.

## Acceptance Criteria

- [ ] Text input at top of sidebar, above node list
- [ ] Typing filters node cards in real-time (client-side)
- [ ] Matches against: URN, label, kind (type_id)
- [ ] Case-insensitive
- [ ] Empty input shows all nodes
- [ ] SVG graph highlights matching nodes (optional: dim non-matching)
- [ ] Stats update to show "N of M nodes" when filtered

## Implementation Notes

All client-side in `transport/static/explorer.html`. No Go changes.

```javascript
// Add <input type="text" id="search" placeholder="Filter nodes..."> above #node-list
// On input event: filter nodeCards by textContent match
// Update stats text to show filtered count
```

## Context

Antigraviti Phase 2 test 3.6 identified missing search functionality. Current sidebar has 68+ cards — scrolling without search is inefficient.

## Commit

`feat: add Explorer sidebar search filter [task:20260313-014]`
