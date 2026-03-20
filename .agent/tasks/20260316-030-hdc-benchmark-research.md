# Task 030 — HDC Benchmark Research (Program 3: Research Pipeline)

**Type:** research-task
**Assigned:** VS Code AI (harvester)
**Channel:** handoff.md
**Status:** COMPLETE (2026-03-16 23:40)
**Commit:** `5e18f54` (ffs0-factory-super)
**Output:** `kb/industry/hdc-benchmarks.json` — 10 papers, 6+ task domains
**Depends:** none

---

## Objective

First research-task via Program 3. VS Code scrapes arxiv for HDC/VSA benchmark papers and produces structured JSON conforming to `kb/industry/schema.json`.

## Scope

Search arxiv for papers on:
- Hyperdimensional computing (HDC) benchmarks and evaluations
- Vector Symbolic Architectures (VSA) performance comparisons
- Kanerva's sparse distributed memory benchmark results
- HDC vs neural network comparisons (accuracy, efficiency, energy)
- Hardware implementations (FPGA, in-memory, CUDA) with published numbers

## Output

**File:** `kb/industry/hdc-benchmarks.json`
**Schema:** `schema.json` (industry layer)
**Format:**
```json
{
  "$schema": "schema.json",
  "domain": "industry_hdc_benchmarks",
  "description": "Published HDC/VSA benchmark results from arxiv papers",
  "last_curated": "2026-03-16",
  "entries": [
    {
      "id": "ind:hdc:paper:<arxiv-id>",
      "name": "<paper title>",
      "type": "paper",
      "source_url": "https://arxiv.org/abs/<id>",
      "year": 2024,
      "tasks": ["classification", "language-recognition", ...],
      "dimensions_tested": 1000-10000,
      "encoding": "binary|bipolar|real",
      "accuracy_pct": 95.2,
      "comparison_baseline": "CNN/SVM/etc",
      "hardware": "CPU|GPU|FPGA|in-memory",
      "key_finding": "one-sentence summary"
    }
  ]
}
```

## Acceptance

- [ ] File validates against `kb/industry/schema.json`
- [ ] Minimum 10 papers with benchmark numbers
- [ ] Covers at least 3 task domains (classification, NLP, biosignals, etc.)
- [ ] Each entry has source_url pointing to real arxiv paper
- [ ] No fabricated data — only published results

## Why

The superset ontology includes HDC as a core pillar (binding ⊗, bundling ⊕, permutation π). The Embedding functor maps graph structures to hypervectors. We need real benchmark data to:
1. Ground the ACT 2026 paper's HDC claims in published results
2. Populate FUN05 (Benchmark functor) with HDC-specific dimensions
3. Establish baseline comparisons for when we implement the CUDA CDU
