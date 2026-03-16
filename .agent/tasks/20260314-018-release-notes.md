# Task 018 — Release Notes & Changelog

**ID:** 20260314-018
**Priority:** P1
**Status:** ready
**Depends:** 017 (CI green)
**Source:** 4-week MVP plan, Week 4 Day 1-2
**Effort:** ~150 lines markdown

---

## Problem

No changelog, contributing guide, or code of conduct. Open-source contributors need these.

## Deliverables

### 1. CHANGELOG.md

Summarize Weeks 1-3 as Wave 0 / v0.1.0:

```markdown
# Changelog

## [0.1.0] — 2026-03-14

### Added
- Categorical graph kernel with 4 invariant morphisms (ADD, LINK, MUTATE, UNLINK)
- 21-object typed operad with port validation
- KB-aware boot (`--kb`, `--hydrate`)
- 16 HTTP routes on :8000
- MCP bridge on :8080 (5 tools, SSE, JSON-RPC 2.0)
- Explorer UI with category grid layout, search, glossary toggle
- Benchmark functor (FUN05: Provider → Met)
- Deterministic replay from morphism log
- Zero external dependencies (Go stdlib only)

### Metrics
- 118 nodes, 131 wires, 249 log depth
- 8 test packages, ~4K LOC
- Single-command boot: `./moos --kb <path> --hydrate`
```

### 2. CONTRIBUTING.md

- How to contribute (fork, branch, PR)
- Go conventions (pure core, effect shell, table-driven tests)
- Commit format: `feat|fix|chore: <description>`
- Zero external deps policy — stdlib only
- Test requirement: `go test ./platform/kernel/...` must pass

### 3. CODE_OF_CONDUCT.md

Standard Contributor Covenant v2.1.

## Acceptance Criteria

- [ ] All 3 files exist in repo root
- [ ] CHANGELOG accurately reflects Weeks 1-3 work
- [ ] CONTRIBUTING references correct test command and conventions

## Files

- Create: `CHANGELOG.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`
