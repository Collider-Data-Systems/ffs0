# Task 20260315-027 — Explorer UX fixes

**Status:** pending
**Assigned:** VS Code AI
**Skill:** `/feature-dev` (implementation) + `/code-review` (self-review)
**File:** `platform/kernel/internal/transport/static/explorer.html` only
**Deps:** Task 026 complete ✅
**Commit:** `fix(explorer): filter reset + log order + dynamic actors + incoming wires [task:20260315-027]`

---

## Source

Full adversarial UX audit by Claude Code via Chrome browser tool (2026-03-15 15:30).
4 confirmed bugs, all in explorer.html frontend JS/HTML — zero Go changes required.

---

## Fixes

### Fix 1 — Filter selects missing "All" reset option

`#kind-filter`, `#stratum-filter`, `#category-filter` have no blank first option.
Once selected, user cannot return to "show all" without reloading.

**Add as first `<option>` to each select:**
```html
<option value="">— All —</option>
```
When value is `""`, treat as no filter for that dimension.

---

### Fix 2 — Log tab: oldest-first instead of newest-first

Log rows render #1 at top, #249 at bottom. Must be reversed.

**In log render JS:** reverse entries before building rows:
```js
logEntries.slice().reverse().forEach(entry => { /* render row */ });
```

---

### Fix 3 — Log actor filter: hardcoded, stale options

`#log-actor` has 3 hardcoded options. Missing `urn:moos:agent:antigraviti` and any future actors.

**Build dynamically from log data after fetch:**
```js
const actors = [...new Set(logEntries.map(e => e.actor).filter(Boolean))].sort();
logActorSel.innerHTML = '<option value="">All</option>';
actors.forEach(a => {
  const o = document.createElement('option');
  o.value = o.textContent = a;
  logActorSel.appendChild(o);
});
```

---

### Fix 4 — Row expansion: incoming wires always 0

Expansion correctly shows outgoing wires (where node is source) but shows 0 incoming.
The wire data is available in the lens/scope response.

**Split wires into two sets in expander JS:**
```js
const outgoing = wires.filter(w => w.src === urn);
const incoming = wires.filter(w => w.dst === urn);
```
Render both tables. Column headers: outgoing = "Target / Source Port / Target Port", incoming = "Source / Source Port / Target Port".

---

### Bonus (non-blocking)

- Add `cursor: pointer` to `tr.row` in CSS — visual affordance that rows are clickable
- Investigate `urn:moos:agent:copilot-interim` (8 wires, not in original design) — flag in commit if intentional

---

## Test

Claude Code will post test plan to `testoff.md` after this ships.
Antigraviti runs: `/boot-kernel` → `/run-tests` → HTTP audit per test plan.
