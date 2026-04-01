---
description: "Use when editing mo:os kernel core Go packages (model, cs, hg, rewrite, fiber)."
applyTo: "moos/platform/kernel/internal/**/*.go"
---

# Kernel Core Rules

- Keep the incidence-first model: node + port + binding + incidence.
- Do not introduce generic payload maps.
- Keep properties explicit through `model.Property` and CS `PropertySpec`.
- Prefer topology changes (bindings/incidences) over object-style field bundles.
- Keep kernel core stdlib-only; do not add third-party dependencies.
- Preserve clone-apply-replace semantics in rewrite flow.
- Prefer minimal, test-backed changes.

## Required Validation

- Run: `go test ./internal/...` from `moos/platform/kernel`.
- If touching `cs` or `hg`, include/adjust tests in those packages.
