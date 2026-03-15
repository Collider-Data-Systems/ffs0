---
name: vsa-implementation-guard
description: Enforces invariants and catches anti-patterns in mo:os code. Use during code review to verify morphism safety, pure/effect separation, and ontological correctness.
---

# VSA Implementation Guard — Invariant Enforcement

Code review and anti-pattern detection for the mo:os kernel. Every code change must pass these checks.

---

## Red-Line Rules (instant rejection)

1. **Fifth morphism** — only ADD, LINK, MUTATE, UNLINK exist. Any new write primitive is wrong.
2. **IO in pure core** — `internal/cat/` and `internal/fold/` must have ZERO imports from `os`, `net`, `io`, `fmt.Print*`.
3. **Direct log mutation** — `morphism-log.jsonl` is append-only via the effect shell. Never `os.OpenFile` it directly.
4. **Binary decomposition** — turning a 4-tuple wire into two binary edges destroys port semantics. Always flag.
5. **Functor output as truth** — any code that reads a UI_Lens or FileSystem projection to derive ontological state is wrong.

---

## Warning-Level Checks

| Pattern | Issue | Fix |
|---------|-------|-----|
| `SeedIfAbsent` used for mutation | SeedIfAbsent is idempotent initialization only | Use `Apply` for mutations |
| Missing `t.Run` in tests | All tests must be table-driven | Wrap in `t.Run(name, ...)` |
| `panic()` in production code | Kernel must not crash on bad input | Return `error` |
| Shared state without `RWMutex` | Data race risk | Use shell's `sync.RWMutex` |
| External dependency added | Zero-dep policy | Use stdlib only |
| URN format violation | Must be `urn:moos:{kind}:{name}` | Fix format |
| Port arity mismatch | Wire ports must match TypeSpec | Check operad registry |

---

## Review Checklist

```
□ Pure core boundary respected?
□ Only 4 morphisms used for writes?
□ Morphism log remains append-only?
□ All wires are 4-tuples (no binary decomposition)?
□ No functor output treated as ground truth?
□ Table-driven tests with t.Run?
□ Error wrapping with context?
□ No external dependencies?
□ URN format correct?
□ Strata transitions explicit?
```

---

## Process vs Outcome Verification

**Process-verified (correct):** Did the morphisms execute correctly? Did the log record accurately?

**Outcome-verified (WRONG):** Does the result look right? Does the UI show the expected thing?

Always verify the PROCESS, not the OUTCOME. Outcomes are projections; processes are ground truth.
