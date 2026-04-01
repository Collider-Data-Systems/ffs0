---
description: "Use when editing proof server or Explorer UI (proof endpoints, explorer page, state visualization)."
applyTo: "moos/platform/kernel/internal/proof/**"
---

# Proof Surface Rules

- Treat Explorer as a proof tool for graph semantics, not a generic dashboard.
- Prefer reading from `/nodes`, `/bindings`, `/grammar`, `/morphisms`.
- Keep node properties inline with node cards.
- Show binding incidences and port direction clearly.
- Avoid adding framework dependencies; keep static HTML/JS simple.
- Keep endpoint contracts backward-compatible unless explicitly changing tests.

## Required Validation

- Run: `go test ./internal/proof/...`.
- Then run: `go test ./internal/...`.
