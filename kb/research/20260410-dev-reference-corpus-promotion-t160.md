# Dev Reference Corpus Promotion Plan — T=160

Date: 2026-04-10
Status: Snapshot + promotion rules captured in SoT.

---

## 1. Scope

`dev/reference/` is the staging corpus for external artifacts.

Promotion target is graph knowledge through the typed path:

`source_feed -> knowledge_item -> claim -> domain_tag`

using WF12 (semantic wiring), WF17 (automation), and WF18 (program coordination).

---

## 2. Corpus snapshot read at T=160

### Papers (`dev/reference/papers/`)

Observed high-value files include:

- `HyperGraphRAG.pdf`
- `Functorial Semantics as a Unifying Perspective.pdf`
- `Seven Sketches in Compositionality.pdf`
- `LogicGraph  Benchmarking Multi-Path Logical Reasoning.pdf`
- `hypergraphrag_digest.md`
- `wolfram_hdc_digest.md`
- `yoonho_lee_neurips2025_digest.md`

### YouTube transcript corpus (`dev/reference/youtube/`)

From `dedupe-index.json` at read time:

- total files: 18
- unique content groups: 18
- groups with duplicates: 0

Transcript entries and list ledgers are present under:

- `dev/reference/youtube/entries/`
- `dev/reference/youtube/lists/`

Schema exists and is stable in:

- `dev/reference/youtube/schema.json`

### Evaluation artifacts

- `dev/reference/evaluations/google-dev-knowledge-mcp-eval.json`

This confirms a viable read-only MCP adapter for Google documentation retrieval.

### Thought artifacts

Selected sources include:

- `dev/reference/thought/COLLIDER_MANIFESTO.md`
- `dev/reference/thought/my-tiny-data-collider_manuscript.md`
- `dev/reference/thought/System 3 AI - No Humans Needed - transcript.txt`

---

## 3. Priority promotion queue (initial)

### Queue A: category and structure foundations

1. `yt-we-must-add-structure-to-deep-learning-because-20260329-125857.json`
2. `yt-the-mathematical-foundations-of-intelligence-professor-yi-ma-20260317-164716.json`
3. `yoonho_lee_neurips2025_digest.md`
4. `Seven Sketches in Compositionality.pdf`

### Queue B: hypergraph and reasoning systems

1. `HyperGraphRAG.pdf`
2. `LogicGraph  Benchmarking Multi-Path Logical Reasoning.pdf`
3. `yt-code-to-build-a-hypergraph-hypergraph-transformers-20260317-164829.json`

### Queue C: agent and harness engineering

1. `yt-andrej-karpathy-s-math-proves-agent-skills-will-fail-here-s-what-to-build-instead-20260324-102846.json`
2. `yt-stop-hardcoding-ai-agents-w-skill-md-discover-karl-20260317-164739.json`
3. `dev/reference/thought/hARNASS.txt`

---

## 4. Promotion procedure (SoT)

For each selected artifact:

1. ADD or reuse `source_feed` node.
2. ADD `knowledge_item` with immutable provenance (`source_url`, retrieval metadata).
3. LINK feed to item via WF12 `produces/produced-by`.
4. Extract atomic assertions as `claim` nodes.
5. LINK item to claims via WF12 `asserts/asserted-in`.
6. ADD or reuse `domain_tag` nodes.
7. LINK item and claims to tags via WF12 `tagged/tagged-in`.
8. Track promotion work as a `program` node and link dependencies with WF18.

No property should duplicate topology already represented by relations.

---

## 5. Workflow constraints

- Keep raw source assets in `dev/reference/`.
- Keep durable semantic interpretation in `kb/research/` plus graph rewrites.
- Keep communication state in GitHub issues/PRs and project board status.
- If a source cannot be cleanly typed yet, keep it in staging and do not force promotion.

---

## 6. Immediate next operator actions

1. Open one issue per queue (A/B/C) on `ffs0` for promotion batches.
2. Assign agent by `board_id` convention in the board field.
3. Promote Queue A first to reinforce current T160 category/HDC work.
4. Record resulting node/relation URNs in issue comments for replay traceability.
