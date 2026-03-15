---
name: vsa-boundary-modeler
description: VSA stratum boundaries, promotion rules, guard conditions. Use when reasoning about S0→S4 transitions, validation gates, or governance boundaries.
---

# VSA Boundary Modeler — Stratum Boundaries

Expert on stratum boundaries and promotion rules in the mo:os kernel. Every concept traverses S0 → S1 → S2 → S3 → S4. Each boundary is a gate with explicit guard conditions.

---

## Stratum Transitions

```
S0 (Authored)  ──guard: schema valid──▷  S1 (Validated)
S1 (Validated) ──guard: governance OK──▷  S2 (Materialized)
S2 (Materialized) ──guard: deps met──▷   S3 (Evaluated)
S3 (Evaluated) ──guard: functor cfg──▷   S4 (Projected)
```

---

## Guard Conditions per Boundary

### S0 → S1 (Validation)
- JSON payload conforms to TypeSpec schema
- URN is well-formed: `urn:moos:{kind}:{snake_case_name}`
- Kind is one of 21 registered types in operad registry
- Required ports declared (per TypeSpec.ports)
- No reserved field collisions

### S1 → S2 (Materialization)
- Governance approval (agent may PROPOSE, cannot APPROVE)
- No duplicate URN exists in graph
- If wire: source and target nodes both at ≥ S2
- If wire: source port and target port pass type validation
- Morphism logged to append-only log

### S2 → S3 (Evaluation)
- All inbound dependencies resolved
- catamorphism fold produces consistent state
- Port connections satisfy arity constraints
- Container ownership (full subcategory) verified

### S3 → S4 (Projection)
- Functor selected (FileSystem, UI_Lens, Embedding, Structure, Benchmark)
- Projection configuration valid
- Result is a VIEW — read-only, NOT ground truth

---

## Anti-patterns

- ❌ Skipping strata (S0 → S2 without validation)
- ❌ Agent self-approving S1 → S2 promotion
- ❌ Mutating S4 projections as if they were S2 state
- ❌ Treating S3 evaluation results as permanent (they're recomputable)

---

## HDC Perspective

Each stratum transition can be modeled as a vector rotation:

```
φ(S_{n+1}) = guard_n ⊗ φ(S_n)
```

Failed guard → orthogonal rejection (concept stays in current stratum).
