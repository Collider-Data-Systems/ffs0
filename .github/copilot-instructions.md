# mo:os Workspace Instructions

## Current Kernel Baseline

- The active kernel is a rebuild focused on incidence-first graph semantics.
- Core primitives: node, port, binding, incidence, property, rewrite plan, fiber.
- Avoid reintroducing generic payload-bag modeling.

## Ground Truth

- Categorical Space (CS) defines admissible node/binding grammar.
- Hypergraph Instance (HG) holds realized nodes, bindings, and properties.
- Explorer is a proof surface, not the source of truth.

## Implementation Guardrails

- Go stdlib only in kernel internals.
- Keep clone-apply-replace behavior in rewrite flow.
- Prefer minimal, test-backed edits.
- Run `go test ./internal/...` from `moos/platform/kernel` after edits.

## Instruction Routing

- Use file-scoped rules under `.github/instructions/` for detailed behavior.
- Keep this file short and stable; put specific conventions in scoped instruction files.
