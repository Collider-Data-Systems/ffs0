# Task 032 — Authority Filtration: Populate C_0, Formalize Trust Chain

**Date:** 2026-03-17
**Status:** COMPLETE
**Program:** 2 (paper + KB design) → feeds Program 1 (triangle implementation)
**Depends on:** Task 031 (superset pipeline — COMPLETE)

---

## Context

The stratum chain C_0 ⊆ C_1 ⊆ ... ⊆ C_4 is defined in ontology.json but C_0 is empty — no object type has `allowed_strata: ["S0"]`. Industry data exists as flat JSON files outside the graph. The classifying functor (industry → superset) is a JSON field lookup, not a graph morphism.

This task populates C_0 for the first time, making the stratum chain complete and the data pipeline graph-internal. It also formalizes the Authority Filtration theorem for the ACT 2026 paper.

## Workstream A — Paper (Program 2: Claude Code + Sam)

1. Add Authority Filtration theorem to `main.tex`
   - New subsection: §3.3 or §5.5
   - Theorem: stratum chain as exhaustive filtration with authorized inclusions
   - Connect to AX5 (governance is structural) — upgrade axiom to theorem
2. Add TikZ figure: trust tower
   - kernel(self-seed) → source(boot) → industry(S0) → instance(S2) → projection(S4)
   - Show LINK authorization at each level
3. Connect to Wolfram causal cone and traced extension

## Workstream B — Implementation (Program 1: triangle)

### Phase 1: Ontology Evolution
- Add OBJ22 `IndustryEntity` to ontology.json
  - `type_id: "industry_entity"`
  - `broad_category: "industry"`
  - `allowed_strata: ["S0"]`
  - `mutable: false` (S0 immutability)
  - `source_connections: ["CLASSIFIES"]`
  - `target_connections: ["OWNS"]`
- Add MOR17 `CLASSIFIES` to ontology.json
  - `decomposition: "LINK(industry_node, 'classifies', instance_node, 'source')"`
  - `source: "industry.*"`
  - `target: "any"`

### Phase 2: Source Seeds
- Convert sources.json entries → seed morphisms (ADD source nodes at boot)
- Source nodes: `urn:moos:source:{name}` (e.g., `urn:moos:source:anthropic-docs`)
- LINK source nodes to kernel self-seed via OWNS

### Phase 3: Industry Hydration
- Extend hydration pipeline to read industry/*.json
- ADD each industry entry as IndustryEntity node at S0
- LINK each to corresponding instance node via CLASSIFIES (MOR17)
- LINK each to source node via OWNS (provenance)

### Phase 4: Verification
- `go test ./...` — all green
- S0 ADD: new IndustryEntity nodes appear in graph
- S0 MUTATE rejection: kernel blocks MUTATE on S0 nodes (existing behavior)
- CLASSIFIES LINK: industry nodes linked to instance nodes
- Explorer: S0 nodes visible in Explorer view
- `curl http://localhost:8000/healthz` — increased node/wire count

## Evaluation Criteria (vision doc §12.4)

| Criterion | Status |
|-----------|--------|
| Decomposition to 4 NTs | ADD + LINK |
| Clear stratum assignment | S0 |
| Concrete use case | industry/*.json (7 files) |
| Testable with existing packages | Yes |
| No changes to 5 kernel colors | Yes (uniform evaluation) |

## Key Files

| File | Change |
|------|--------|
| `.agent/kb/superset/ontology.json` | Add OBJ22, MOR17 |
| `.agent/kb/reference/papers/act2026/main.tex` | Authority Filtration theorem |
| `moos/platform/kernel/internal/hydration/` | Industry hydration pipeline |
| `moos/platform/kernel/internal/operad/` | TypeSpec for IndustryEntity |
| `moos/platform/kernel/cmd/moos/main.go` | Source seed at boot |

## Notes

- First ontology evolution since v3
- OBJ22 is OUTSIDE Include_K (not promoted) — uniform evaluation by 4 NTs
- S0 immutability already enforced by applyMutate guard in evaluate.go
- Trust chain: kernel → source → industry → instance → projection
