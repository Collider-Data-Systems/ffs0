# Websource to HG Knowledge Flow — T=160

Purpose: operational recipe for turning external web sources into knowledge items in the hypergraph.
Canonical ontology source: `kb/superset/ontology.json`.

---

## 1. Core node path

Use this node path:

1. `source_feed`
2. `knowledge_item`
3. `claim`
4. `domain_tag`
5. `classification_scheme` and `crosswalk` (optional refinement)

This keeps source provenance explicit while preserving atomic claims.

---

## 2. Rewrite categories by stage

- WF12 semantic content links:
  - `source_feed --produces--> knowledge_item`
  - `knowledge_item --asserts--> claim`
  - `knowledge_item --tagged--> domain_tag`
  - `claim --tagged--> domain_tag`
- WF17 reactive automation:
  - watcher/guard/reactor pipelines for extraction and tagging.
- WF18 workflow control:
  - link ingestion work to `program` nodes and dependencies.

---

## 3. Intake pipeline

### Stage A: register source feed

ADD node:

- type_id: `source_feed`
- immutable properties: `name`, `url`, `source_type`, `protocol`, `created_at`
- mutable properties: `poll_interval`, `filter_keywords`, `status`

### Stage B: add knowledge item

ADD node:

- type_id: `knowledge_item`
- immutable properties: `title`, `source_url`, `source_type`, `language`, `retrieved_at`, `created_at`
- mutable properties: `summary`, `status`

LINK (WF12):

- `source_feed --produces--> knowledge_item`

### Stage C: extract claims

For each atomic assertion:

ADD node:

- type_id: `claim`
- immutable properties: `text`, `source_ki_urn`, `created_at`
- mutable property: `confidence`

LINK (WF12):

- `knowledge_item --asserts--> claim`

### Stage D: classify and map

ADD or reuse `domain_tag` nodes.

LINK (WF12):

- `knowledge_item --tagged--> domain_tag`
- `claim --tagged--> domain_tag`

Optional:

- link tags to `classification_scheme` via WF15 contract-driven semantic relations.
- map between schemes with `crosswalk` nodes.

---

## 4. Reactive automation pattern

Use WF17 wiring:

1. watcher: detect ADD/MUTATE on `knowledge_item` where status=`raw`.
2. guard: permit only if source provenance and policy checks pass.
3. reactor: emit ADD/LINK rewrites for `claim` and tagging updates.

Convergence policy:

- ensure cascade matrix remains convergent for configured watcher/reactor graph.

---

## 5. Minimal envelope examples

Example link source to item (WF12):

```json
{
  "rewrite_type": "LINK",
  "rewrite_category": "WF12",
  "actor": "urn:moos:user:sam",
  "relation_urn": "urn:moos:rel:feed-yt-ml.produces.ki-transformers-overview",
  "src_urn": "urn:moos:feed:yt.ml",
  "src_port": "produces",
  "tgt_urn": "urn:moos:ki:youtube.transformers-overview",
  "tgt_port": "produced-by"
}
```

Example link item to claim (WF12):

```json
{
  "rewrite_type": "LINK",
  "rewrite_category": "WF12",
  "actor": "urn:moos:user:sam",
  "relation_urn": "urn:moos:rel:ki-transformers-overview.asserts.claim-01",
  "src_urn": "urn:moos:ki:youtube.transformers-overview",
  "src_port": "asserts",
  "tgt_urn": "urn:moos:claim:transformers-overview.01",
  "tgt_port": "asserted-in"
}
```

Example link claim to tag (WF12):

```json
{
  "rewrite_type": "LINK",
  "rewrite_category": "WF12",
  "actor": "urn:moos:user:sam",
  "relation_urn": "urn:moos:rel:claim-transformers-overview-01.tagged.category-theory",
  "src_urn": "urn:moos:claim:transformers-overview.01",
  "src_port": "tagged",
  "tgt_urn": "urn:moos:tag:custom.category-theory",
  "tgt_port": "tagged-in"
}
```

---

## 6. Quality gates

Before promoting extraction output:

1. Provenance gate: every claim must link back to one knowledge item and source feed path.
2. Topology gate: no duplicated topology in properties; use relations for all cross-node facts.
3. Vocabulary gate: codex terms only.
4. Replay gate: resulting log replays deterministically.
5. Program gate: ingestion program status and dependencies modeled with WF18.

---

## 7. Z440 execution mapping

Primary execution path for this workstation:

- run extraction via primary kernel MCP on `localhost:8080`.
- shard or delegate claim extraction to `9001`, `9002`, `9003` by domain or source.
- keep principal authority rooted at user node; delegates operate through governed scope.

This keeps throughput high while preserving provenance and CI-5 authority constraints.
