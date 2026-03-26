# Task 031: Superset Pipeline Formalization

**ID:** 20260317-031
**Priority:** P0
**Status:** COMPLETE ✅ — All phases shipped + tested (Phase 1-2: e90352a, Phase 3: f7471e5, Antigraviti: 11:20 all green)
**Program:** P2 (design) → P1 (implementation)
**Design:** `kb/design/20260317-superset-pipeline.md`
**Depends:** Tasks 001-030 complete
**Phase 1-2 Commit:** e90352a (2026-03-17 10:36)

---

## Objective

Wire ontology.json as single SOT for the entire KB pipeline. Delete dead files, create missing S0 gate, update existing schemas, add kernel-level ontology hydration.

---

## Test Status (as of 2026-03-17 10:15)

**Antigraviti Phase 1-3 Results:**

- Phase 1 (Schema validation): 2 FAILs found + fixed
  - ❌ → ✅ ontology.schema.json glossary label + URN pattern (e90352a)
  - ❌ → ✅ benchmarks.json industry_source URN (e90352a)
- Phase 2 (Kernel boot): ✅ all PASS
- Phase 3 (Satellite nodes): ⚠️ node count discrepancy observed in one run (72 found vs 51 expected). Expected formula is:
  - `len(objects)` + `len(core+stratum_chain+hydration_pipeline+functor_codomains+cross_provider)` + `len(glossary)`
  - Current ontology totals: `21 + 22 + 8 = 51`
  - 72 indicates legacy `instances/{glossary,categories,kinds}.json` were also hydrated in that run.

**Final:** All phases verified. Phase 2-3 retest at 11:20 — go test PASS, kernel boot PASS (104 nodes, 111 wires post-reset), healthz PASS, URN patterns PASS, node count 51 PASS (30 cats + 21 objs), stratum S1 PASS.

## Phase 1: Clean superset/ dead files (Claude Code — done)

- [x] Delete `schema.json` (useless 4-field validator)
- [x] Delete `ontology.csv` (generated artifact)
- [x] Delete `changelog.jsonl` (git log does this)
- [x] Delete `categories.json` (duplication of ontology.json)
- [x] Delete `kinds.json` (duplication of ontology.json)
- [x] Delete `glossary.json` (folded into ontology.json)

## Phase 2: Wire schemas (Claude Code — done)

- [x] Create `schemas/industry.schema.json` — S0 gate requiring source ∈ sources.json + ontology_targets
- [x] Update `schemas/instance.schema.json` — add optional industry_source, industry_ref
- [x] Add `glossary` array to `ontology.json` (8 math vocabulary entries from deleted glossary.json)

## Phase 3: Kernel hydration from ontology (VS Code — pending)

- [x] New function `HydrateFromOntology(ontologyPath string) ([]cat.Node, error)` in `internal/hydration/`
  - Reads ontology.json
  - Generates glossary nodes (CAT:Object, CAT:Morphism, etc.) — same URNs as deleted glossary.json
  - Generates category satellite nodes (CAT01-CAT22)
  - Generates kind reference nodes (OBJ01-OBJ21)
  - All nodes get `stratum: "S1"`, `type_id: "app_template"`
- [x] Update `HydrateAll()` to call `HydrateFromOntology()` before instance hydration
- [x] Tests: `hydration_ontology_test.go`
  - Verify node count matches `objects + (core + stratum_chain + hydration_pipeline + functor_codomains + cross_provider) + glossary`
  - Verify all generated URNs follow `urn:moos:cat:*` or `urn:moos:obj:*` pattern
  - Verify stratum = S1 for all generated nodes

## Acceptance Criteria

1. `superset/` contains exactly 7 files (ontology.json, sources.json, 5 schemas)
2. `industry.schema.json` rejects files without source URN
3. `instance.schema.json` accepts optional industry_source/industry_ref
4. Kernel generates satellite nodes from ontology.json at boot
5. `go test ./...` all green
6. No regressions in existing hydration flow
