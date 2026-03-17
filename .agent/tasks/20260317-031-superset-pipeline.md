# Task 031: Superset Pipeline Formalization

**ID:** 20260317-031
**Priority:** P0
**Status:** in-progress
**Program:** P2 (design) → P1 (implementation)
**Design:** `kb/design/20260317-superset-pipeline.md`
**Depends:** Tasks 001-030 complete

---

## Objective

Wire ontology.json as single SOT for the entire KB pipeline. Delete dead files, create missing S0 gate, update existing schemas, add kernel-level ontology hydration.

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

- [ ] New function `HydrateFromOntology(ontologyPath string) ([]cat.Node, error)` in `internal/hydration/`
  - Reads ontology.json
  - Generates glossary nodes (CAT:Object, CAT:Morphism, etc.) — same URNs as deleted glossary.json
  - Generates category satellite nodes (CAT01-CAT22)
  - Generates kind reference nodes (OBJ01-OBJ21)
  - All nodes get `stratum: "S1"`, `type_id: "app_template"`
- [ ] Update `HydrateAll()` to call `HydrateFromOntology()` before instance hydration
- [ ] Tests: `hydration_ontology_test.go`
  - Verify node count matches ontology.json objects + categories + glossary
  - Verify all generated URNs follow `urn:moos:cat:*` or `urn:moos:obj:*` pattern
  - Verify stratum = S1 for all generated nodes

## Acceptance Criteria

1. `superset/` contains exactly 7 files (ontology.json, sources.json, 5 schemas)
2. `industry.schema.json` rejects files without source URN
3. `instance.schema.json` accepts optional industry_source/industry_ref
4. Kernel generates satellite nodes from ontology.json at boot
5. `go test ./...` all green
6. No regressions in existing hydration flow
