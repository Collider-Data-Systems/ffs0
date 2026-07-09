# OKF ⇄ mo:os — Google's Open Knowledge Format as a structural interchange layer inside a purpose

> **Authored 2026-07-09 15:55 CEST (t250, wall-clock verified per the t249 chronology discipline).**
> Commissioned by Sam's `t250;15.33 /goal`: research + design an implementation of Google's OKF, whether it can be a structure inside our purpose, with datasets like library classifications or Wikipedia.
> **Design/research note — no HG writes, no applied grammar. Conjectures marked. Every claim grounded (ontology type/port, file:line, live URN, or web source).**
> Method: 4-lane parallel design sweep (categorical mapping · KOS+datasets · purpose-placement · implementation-staging), all web-verified for the external facts.

---

## §0 TL;DR

- **OKF (Google Cloud Open Knowledge Format, v0.1, June 2026)** represents curated knowledge as *a directory of markdown files with YAML frontmatter* — only `type` is required, links are plain markdown (**untyped** — meaning lives in prose), reserved `index.md`/`log.md`. It is deliberately document-oriented: **no taxonomy, no query language, no RDF**. ([spec](https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md) · [blog](https://cloud.google.com/blog/products/data-analytics/how-the-open-knowledge-format-can-improve-data-sharing/))
- **OKF is the untyped-edge shadow of mo:os.** concept.md ↔ node · `type:` ↔ `type_id` · `resource:` ↔ URN · markdown-link ↔ relation-minus-its-WF · `index.md` ↔ manifold · `log.md` ↔ the rewrite log. That correspondence is an **F⊣G adjunction** (project forgets typing; ingest must re-add it), and it is **buildable on today's 4.0.2 grammar with zero new types** — an OKF bundle ingests as `knowledge_item`s wired by WF12 `provides-kb`, because OKF's untyped link and WF12's single generic port are *the same shape*.
- **Three unlocks bigger than the question:**
  1. **The prize is the crosswalk hub, and it = one small fragment.** Your `classification_scheme` + `crosswalk` + `domain_tag` machinery is already ~70% SKOS. Hold LCC *and* Dewey *and* arXiv *and* Wikidata plus the mappings between them, and an item classified in one scheme is discoverable through every other. **Wikidata (CC0) is the ready-made hub** — its items already carry LCC (`P1149`), Dewey (`P1036`), UDC (`P1190`) IDs, so you read the crosswalks off it for free. The one missing primitive is **concept-level mapping** (the current `crosswalk` maps scheme↔scheme, not concept↔concept).
  2. **OKF gives the deferred D8 `realizes` its long-missing write-need.** D8 stayed deferred because every surface is *observed*, never *written*. An OKF bundle mo:os **produces** (F-project → a git repo Google Cloud Knowledge Catalog then ingests) is the first surface the pipeline must WRITE — flipping D8's gate from false to true.
  3. **OKF gives the t250 R4 η-iso test a real external anchor.** The HG→OKF→HG round-trip *is* the η measurement; the "typed-relations-in-preserved-frontmatter" convention makes it lossless on the typed core.
- **mo:os is already ~80% an OKF producer** — one `type:` frontmatter field (targeted, not bulk) makes the durable project readable by Google Cloud Knowledge Catalog and any OKF consumer.
- **Licensing reality: build the hub on the two clean-license pillars — LCSH (US-gov public domain, native SKOS) + Wikidata (CC0).** Dewey-full is OCLC-proprietary (blocked); full Wikidata is 1.6 TB (subset, don't ingest whole). Keep per-scheme, license-segregated bundles.
- **One forcing function is Sam's to decide:** crosswalks are intra-fold, but your classification seeds are split across the twins (LCC on menno, Dewey on lola, ISO on moos) — a `lcc↔dewey` crosswalk is literally unbuildable while they live on different folds. The KOS backbone must consolidate onto **one fold** (recommend primary :8000).

---

## §1 What OKF actually is (authoritative, web-verified)

A **bundle** is a directory of markdown files. Each concept document carries YAML frontmatter with exactly one **required** field, `type` (a free string — e.g. `BigQuery Table` — *not* centrally registered); recommended: `title`, `description`, `resource` (a URI that identifies the underlying asset), `tags` (list), `timestamp` (ISO-8601). **Producers MAY add any keys; consumers MUST preserve unknown keys on round-trip** — this fact turns out to be load-bearing (§5). Two reserved filenames: `index.md` (directory listing / progressive disclosure; the *only* place `okf_version: "0.1"` may appear, at bundle root) and `log.md` (chronological update history). Concept ID = the file path minus `.md`. **Links are ordinary markdown links** — a link A→B asserts a relationship, but its *type is untyped*: the meaning is conveyed by surrounding prose only, and consumers must tolerate broken links. There is **no taxonomy, no query language, no RDF/OWL/SPARQL, no schema enforcement** — maximal permissiveness by design. Google Cloud's Knowledge Catalog ingests OKF and serves it to agents.

The design intent: kill knowledge silos and vendor lock-in by formalizing "the LLM-wiki pattern" into a portable format that any producer can write and any consumer can read — the exact **producer/consumer split** mo:os already runs as F (project) ⊣ G (ingest).

---

## §2 The core correspondence — OKF is the untyped-edge shadow of mo:os

| OKF construct | mo:os construct (cited) | Direction note |
|---|---|---|
| concept doc `path/concept.md` | `node` (identity) | 1:1 |
| concept ID = path − `.md` | so:om **path-URN** / surface address (`moos-soom` §2) | *where* it's projected |
| frontmatter `resource` (URI) | node **URN** `urn:moos:<type>:<short>` | *what* it is — canonical id |
| frontmatter `type` (free string) | operad **`type_id`** (closed, ~30 registered) | F: closed→open (faithful); G: open→closed (partial inference) |
| other frontmatter keys | node **`properties`** (typed) | OKF preserves unknown keys ⇒ mo:os keys survive round-trip |
| markdown link A→B (**untyped**) | **`relation`** (WF01–WF21-typed) | **the central asymmetry** — F forgets the WF; G must infer it |
| `index.md` (dir listing; holds `okf_version`) | **`manifold`** / grouping (colimit) | bundle boundary |
| `log.md` (chronological history) | the **rewrite `log`** (`state = fold(log)`) | F-image of the WF-typed log as prose |
| bundle (directory) | **`channel`** (the ingress entry-point) | so:om surface |
| body `# Schema/# Examples/# Citations` | property values / `claim` nodes | soft, prose-carried |

**Two structural coincidences that aren't coincidences.** (1) OKF hands you *two* ids per concept — a path ID and a `resource` URI — exactly as mo:os splits the so:om path-URN (address) from the canonical kernel URN. (2) OKF's *deliberate untypedness of links* is **isomorphic to WF12's single generic `provides-kb`/`kb-source` port** — both flatten relation-semantics into one conduit and push meaning to prose. That is *why* an OKF bundle slots into the WF12 ingest path with no new grammar.

**Why it's an adjunction, not an isomorphism.** F (project, HG→OKF) forgets on both cells: node `type_id` (closed) → free-string `type` (recoverable if kept); WF-category (WF01–WF21) → a single untyped link (**many-to-one, genuinely lossy**). G (ingest, OKF→HG) must *re-add* both: map free strings → `type_id` (partial), assign a WF to each untyped link (inference). Structure-adding vs structure-forgetting is the definition of **Free ⊣ Forgetful**.

> **Finding (categorical lane, conjecture worth Karpathy's eye):** the house slogan `mo:os ⊣ so:om = F⊣G` with *F=project on the left* is only consistent if G is read as the **cofree** (maximal-observation) lift. The mathematically natural *free* (structure-adding) lift makes **ingest the left adjoint** (`G_free ⊣ F`). The practical `moos-workspace-ingest` is neither — it's an inference-chosen section between free and cofree, which is *why it carries no η-iso guarantee*. Recommendation: state the F⊣G pair as a named project/ingest pair, and separately name the load-bearing `G_free ⊣ F`. The `⊣` in the house doc is doing double duty. (Does not block any of the build work below; flagged for doctrine hygiene.)

---

## §3 The KOS backbone + the crosswalk-hub prize

Your live grammar is already a Knowledge Organization System. Mapped onto SKOS (verified against `kb/superset/ontology.json`):

| SKOS | mo:os 4.0.2 | Status |
|---|---|---|
| `skos:ConceptScheme` | `classification_scheme` | ✅ |
| `skos:Concept` | `domain_tag` | ✅ |
| `skos:prefLabel` | `domain_tag.label` | ✅ (one label) |
| `skos:broader/narrower` | `domain_tag.parent_urn` (mutable **property**, single-parent) | ⚠ tree-only; not topology; no poly-hierarchy |
| `skos:exactMatch/broadMatch/…` | `crosswalk.mapping_type ∈ {equivalence,broader,narrower,related}` | ⚠ **right vocabulary, wrong arity** — binds scheme↔scheme, not concept↔concept |
| `skos:notation` / `altLabel` / `scopeNote` | — | ❌ missing (additive props) |

**The prize is the crosswalk hub, and it equals the one missing primitive.** Because `classification_scheme` can hold many schemes *and the maps between them*, the value isn't any single classification — it's the **join**: an item tagged in LCC becomes discoverable through Dewey, arXiv, Wikidata. But the current `crosswalk` maps *schemes*, so it can't yet say "LCC QA76 ≈ Dewey 005". Concept-level mapping is the one fragment that unlocks everything — and it's also what makes the `crosswalk` type's own description (*"graph-native witness of a natural transformation"*) literally true, since a natural transformation is **concept-indexed** (a component per object), not a single scheme→scheme morphism. *(Conjecture: this concept-indexing is the real content of "witness of a natural transformation" — worth Karpathy confirming.)*

**Wikidata is the ready-made hub, CC0, and it already did the crosswalk labor.** Each Wikidata item carries external classification IDs as statements — `P1149` (LCC), `P1036` (Dewey), `P1190` (UDC), `P244` (LC name authority). So the Q-item for "Category theory" *already holds its LCC, Dewey and UDC codes*: you join LCC-concept ↔ Dewey-concept **through the shared Wikidata item** for free, instead of authoring N² pairwise crosswalks. Build the hub on the CC0 pivot, read the mappings off it.

---

## §4 Where it sits "inside a purpose"

Two readings; **(b) is load-bearing and (a) reduces to it.** (a) "inside the mo:os *project* purpose (the endeavor)" is strategy, and in the HG can only be realized as a `purpose` node — which already exists: `purpose:sam.mvp-sovereign-knowledge-os` ("one real knowledge channel flowing in, HDC reasoning over it"). (b) "inside a `purpose` *node*" (out-ports `steers`/`composes`) — an OKF bundle / KOS subtree scoped to and steered by a purpose. **A `knowledge-os` purpose should be a child/sibling of the existing MVP purpose, not greenfield** — else the KOS forks the very purpose it serves.

**Precision (easy to get wrong):** `purpose.steers` is authored-intent only — **no WF pair binds it** (it appears only in the `declared_pairs_by_wf` block, which is *"AUTHORED INTENT, NOT LOADED"*). A purpose steers via **HDC cosine scoring** (`cos(φ(rewrite_effect), φ(purpose))`), not a `steers` LINK. Composition (`composes`, WF18) is topology; steering is a derived score. Design accordingly.

Load-bearing node topology (verified buildable vs gap, against 4.0.2):
```
manifold:knowledge-os  (reuse manifold:my-tiny-data-collider)
  --WF18 spans--> purpose:sam.knowledge-os          [NOW]
  --WF18 spans--> channel:okf-bundle.mtdc-kb        [NOW — channel ∈ spans tgt]
purpose:sam.knowledge-os
  --WF18 composes--> channel + program + knowledge_item   [NOW]
  --WF21 causes----> derivation:knowledge-org.*     [GAP d4b — purpose ∉ WF21 src]
  φ-steering over candidate KB rewrites             [NOW — scoring, not a LINK]
channel:okf-bundle.*  (kind: GAP §6 — reuse 'vcs'/'filesystem' now)
  --WF12 provides-kb--> knowledge_item:<each concept doc>  [NOW]
classification_scheme:* --WF12 provides-kb--> ki | domain_tag  [NOW, flattened]
crosswalk:* --WF12 provides-kb--> classification_scheme:*      [NOW, scheme-level]
```

---

## §5 The two strategic unlocks

### 5.1 OKF gives D8 `realizes` its write-need
D8 (`surface --realizes--> channel/workspace`) has been deferred three rounds with the rule *"observed-first; reify only if the pipeline must WRITE it."* Every surface so far (desktops, windows, tabs) is observed, never written — no write-need, stays deferred. **An OKF bundle mo:os produces is the first surface the pipeline must write** (F-project the HG → a git repo of markdown that Google Cloud Knowledge Catalog then ingests). That flips D8's gate from false to true — the strongest existing justification to finally reify `realizes`. *(Conjecture, load-bearing: holds only if Sam commits to mo:os WRITING OKF, not just importing it — see §8.)*

### 5.2 OKF gives the t250 R4 η-iso test a real external anchor
The t250 program's R4 = "η-iso per surface" (a projection is lossless exactly where the unit η is iso = HDC encode/decode fidelity). OKF makes it concrete and *external* instead of self-referential: **F: HG→bundle; G: bundle→throwaway :8899; diff.** η = fraction of nodes round-tripping with identical `type_id`+properties AND relations with identical `(src,port,tgt,wf)`. OKF is η-iso **only on the typed core**: it breaks on OKF's permissive tail (arbitrary frontmatter keys have no typed slot; free-string `type` collapses onto the closed `source_type` enum). **Fix — and it rides an authoritative OKF fact:** since consumers preserve unknown keys on round-trip, carry the typed relations in **preserved frontmatter** (`broader: [...]`, `exact_match: [...]`, `notation: "QA76"`, and a `relations:` record `{port, wf, target}`), using the untyped markdown-link body only for human disclosure. Frontmatter round-trips byte-faithfully → **η becomes iso for the typed core**. This is a sharp, testable claim for R4: *the KOS→OKF projection is lossless exactly when typed relations live in preserved frontmatter, not in prose-typed links.*

---

## §6 Grammar-gap ledger — REUSE now vs additive fragments

**The governing fact (verified in the kernel, not inferred):** `ValidateLINK`/`ValidateStrataLink` enforce *only* the WF's declared port-pairs (from `rewrite_categories[*].additional_port_pairs` + primary) and src/tgt types. Node types' own `ports` arrays are **never consulted**. So `classifies`, `tagged`, `maps-to`, `mapped-from` are **authored-intent decorations** today — every live KB relation rides the one loaded WF12 pair `provides-kb`/`kb-source`. (The `declared_pairs_by_wf` block is a **decoy** — `"AUTHORED INTENT, NOT LOADED"`; don't author LINKs on its phantom ports or you hit `port pair not declared`.)

**REUSE (buildable now, no fragment):** channel→ki ingest (WF12 `provides-kb`); scheme→ki/tag "classifies" (flattened onto `provides-kb`); crosswalk↔scheme SKOS-shaped (WF12 + `crosswalk.mapping_type`); ki→tag tagging (`provides-kb`; the dedicated `tagged` pair is the open moos-kernel#52-class gap); manifold→purpose/channel (WF18 `spans`, landed 4.0.1); purpose→channel/ki (WF18 `composes`); shallow tag hierarchy (`parent_urn`).

**NEW FRAGMENT (additive, WF20-promoted, in rough priority):**
1. **Concept-level mapping** — *the prize*. Add `exact-match`/`broad-match` ports binding `domain_tag`↔`domain_tag` across schemes (reuse the `crosswalk.mapping_type` vocabulary at concept level), or re-arity `crosswalk` to bind concept URNs. Unlocks the hub.
2. **`domain_tag.taxonomy` enum widening** — currently only `{arxiv, custom, lcsh}` (narrower than `classification_scheme.taxonomy_source`'s 10 values). Cannot truthfully hold `lcc/dewey/udc/iso/ifrs` tags. Either widen (additive), or **(DRY, preferred)** drop the property and derive taxonomy from a `provides-kb` LINK to the scheme (topology over property).
3. **`classifies/classified-by` + `maps-to/mapped-from` wired pairs** — turn the dangling out-ports into real WF12 relation-pairs so classification/crosswalk are distinguishable from generic ingest.
4. **`channel.kind += "okf-bundle"`** — additive enum bump (mirror `v400-3`). *Only if* the ingest skill must dispatch on kind; otherwise reuse `vcs` (OKF's preferred git distribution) or `filesystem` now.
5. **poly-hierarchy `broader/narrower/related`** as domain_tag→domain_tag relations — LCSH/UDC need multi-parent, which `parent_urn` (single) can't express.

**Live t250 tie-in:** the staged-proposed **d4b** (WF21 purpose-as-src) gets a concrete second use here — `purpose:knowledge-os --causes--> derivation:knowledge-org.*` reifies *why/how* a corpus was organized. **g2b** (WF01 manifold-as-tgt) lets `group:sam --owns--> manifold:knowledge-os`. Both already Low-risk additive in the t250 backlog.

---

## §7 Datasets — honest availability, license, scale (all web-verified)

| Dataset | Open? | Format | License | Scale | Verdict |
|---|---|---|---|---|---|
| **LCSH** | ✅ | SKOS/RDF bulk (id.loc.gov) | **Public domain** (US-gov) | ~500k, multi-GB | **INGEST NOW** — cleanest pillar; subset by domain |
| **LCC Outline** | ✅ | PDF outline | free | small | outline now; full = paid ClassWeb (PDF-scrape) |
| **Dewey full** | ❌ | WebDewey | **OCLC proprietary** | — | **BLOCKED** |
| **Dewey Summaries** | ✅ (~1,000) | PDF | **CC BY-NC-ND 3.0** | top-3 levels | NC blocks commercial, ND blocks derivative *redistribution* — private use only |
| **UDC Summary** | ✅ (~2,600) | **SKOS XML/RDF, 48 langs** | **CC BY-SA 3.0** | — | INGEST NOW; SA propagates to derivatives |
| **MSC2020** | ✅ | CSV/TeX | **CC BY-NC-SA** | ~6,000 | CSV→OKF now; NC constrains sharing |
| **arXiv** | ✅ | web list; meta CC0 | open | ~155 | **already seeded** — reference impl |
| **Wikidata** | ✅ | JSON/RDF dump + SPARQL | **CC0** | 100M+ items, ~1.6 TB | **SUBSET ONLY** (scale, not license) — the hub |
| **DBpedia** | ✅ | RDF | CC BY-SA 3.0 | ~1.3B triples | subset; SA sticky → prefer Wikidata |
| **Wikipedia** | ✅ | dumps/API | CC BY-SA 4.0 | huge, cyclic cats | **content bodies only**, not a clean KOS |

**The compounding hazard:** a *combined redistributable* bundle inherits the strictest term — any Dewey-Summary (ND) makes it non-redistributable; any NC scheme blocks commercial/federated use; any SA forces share-alike on the whole. **Design rule: per-scheme, license-segregated bundles (one bundle = one license); build the crosswalk hub on the CC0+public-domain pillars (Wikidata + LCSH) only; treat NC/ND/SA scheme-tags as private-workspace references reachable *through* the clean hub, never baked into it.**

**Wikipedia/Wikidata scoped-subset strategy** (you cannot ingest 1.6 TB): seed from the domains mo:os works in (category theory, HDC, functor, adjunction, sheaf); traverse `P279`/`P361`/`P31` to bounded depth via SPARQL CONSTRUCT / WDumper; a domain subtree is ~10³–10⁴ items *(conjecture — estimate)*, bounded and ingestable; project → OKF bundle → `domain_tag`/`knowledge_item` via WF12.

---

## §8 Staged implementation (bounded, Sam-gated, throwaway-:8899, expected-REJECT gates document the gaps)

Two skills mirror the existing F/G pair: **`moos-okf-project`** (F, read-only — fold a `manifold` span-closure → OKF bundle under `kb/okf/<slug>/`, deterministic/diffable) and **`moos-okf-ingest`** (G — parse a bundle → one atomic gate-tested batch; mo:os-native bundles recover `type_id` from `type: "moos:<type>"` and rebuild LINKs from a `relations:` frontmatter record; foreign bundles land every concept as `knowledge_item` + every link as `provides-kb`, deferring typed promotion — same "does NOT auto-type" discipline as `moos-workspace-ingest`).

- **Round 1 — dogfood, NO HG writes.** Ship `moos-okf-project` + targeted `type:` stamping of ~5 durable/generated surfaces (running-state, AGENTS.md, the manifold-bump index) — **not** a bulk retrofit (AGENTS.md itself slates these files to become *generated*, so hand-stamping N files is negative-EV). Output: `kb/okf/my-tiny-data-collider/` and mo:os is a valid OKF producer readable by Google Cloud Knowledge Catalog. Reuse `keep-anywhere` as the Drive-mirror precedent (rclone → Catalog + Android read it). Zero grammar, zero HG risk.
- **Round 2 — KOS ingest (LCSH first — public-domain, `taxonomy:lcsh` valid today, zero grammar).** `moos-okf-ingest` lands a `classification_scheme` + `domain_tag` hierarchy on one fold. Expected-REJECT gate on :8899: `ADD domain_tag {taxonomy:"udc"}` rejects (gap 2) → documents and justifies the round's ONE additive enum PR.
- **Round 3 — crosswalk hub + scoped Wikidata subtree.** Expected-REJECT gates: `LINK crosswalk --maps-from--> scheme` and concept-level `exact-match` reject → justify the round's ONE PR (the concept-mapping fragment + wired pairs). Bounded BFS from a seed QID; `P279`→broader; read external IDs off the hub.
- **Round 4 — round-trip η test.** Ship the §5.2 checker; flips R4 from "single-instance loop pass" to a law with an external anchor. Expected η=1.0 on the mo:os-native bundle, η<1.0 with an enumerated `lossy_fields` list on a foreign bundle — that list is the round's finding.

---

## §9 Decisions for Sam (the gate list)

1. **Does mo:os WRITE OKF (F-project to git), or only import it?** This single decision flips D8 `realizes` from deferred to reify-now (§5.1), and decides whether OKF is an interchange surface or an import.
2. **Fold placement (forcing function, not preference).** Crosswalks are intra-fold; your schemes are split across the twins (LCC/menno, Dewey/lola, ISO/moos) — a `lcc↔dewey` crosswalk is **unbuildable** until they co-reside. Recommend consolidating the KOS backbone onto **primary :8000** (emit-discipline-aligned), carrying the `manifold spans` toward the twins as topology intent so a future §M9 migration needs no URN rewrite.
3. **`knowledge-os` purpose: new node or the existing `purpose:sam.mvp-sovereign-knowledge-os`?** Minting a new one forks the purpose the KOS serves.
4. **η-iso tail: accept lossy η on the permissive tail (typed core only), or add a passthrough slot** (raw-frontmatter blob — anchored on a `derivation` S0-substrate node per the §5.2 conjecture, to avoid the no-free-form-payload doctrine violation)?
5. **Fragment batching:** the additive fragments (concept-mapping, taxonomy enum, classifies/maps pairs, poly-hierarchy) as one WF20 ceremony, or one-per-round as the expected-REJECT→ACCEPT flip the t250 loop prescribes?
6. **Redistribution posture:** is mo:os ever intended to *share* a combined KOS bundle (federation/public), or is all KOS ingest strictly private-workspace? This decides whether the NC/ND/SA schemes are usable beyond one machine.

---

## §10 Discrepancy flags surfaced en route (verify before building)

- **`domain_tag.taxonomy` enum is `{arxiv, custom, lcsh}`** on primary — narrower than the brief and than `classification_scheme.taxonomy_source` (10 values). The live LCC/Dewey/ISO/IFRS seed tags must currently be `taxonomy:"custom"` (or the twins run a divergent ontology) — **needs a live per-fold readback to resolve before the enum bump**.
- **The `manifold` type-note is stale** — it says spanning relations "not yet declared," but WF18 carries the `spans/spanned-by` pair (landed 4.0.1). True up the prose; readers trusting it will wrongly conclude manifold spanning is unbuildable.
- **`declared_pairs_by_wf` is a decoy** — `classifies`/`tagged`/`steers` listed there are **not loaded**; only `rewrite_categories[*].additional_port_pairs` + primaries are enforced.
- **Live scheme inventory is thinner than assumed** — primary :8000 documents only `scheme:arxiv` + `scheme:ifrs`; LCC/Dewey/ISO live on the twins (dormant/older code, emit-to-:8000 pre-§M9). Verify they resolve on a live fold before building crosswalks on them.

---
*Sources: 4-lane design sweep (session scratchpad `okf/lane*.md`) · [OKF SPEC.md](https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md) · [Google Cloud OKF blog](https://cloud.google.com/blog/products/data-analytics/how-the-open-knowledge-format-can-improve-data-sharing/) · [id.loc.gov](https://id.loc.gov/) · [UDC Summary/finto.fi](https://finto.fi/udcs/en/) · [Wikidata dumps](https://www.wikidata.org/wiki/Wikidata:Database_download) · Wikidata properties P1149/P1036/P1190 · live `kb/superset/ontology.json` v4.0.2 · `dev/design/manifold-bump-4_0/20260620-t231-moos-soom.md` · `20260708-t249-t250-baseline.md`. §5.1/§5.2/§3-natural-transformation marked conjecture; §8 is a proposal — nothing here touches the HG.*

authored-by: agent:claude-cowork.hp-z440 / session:sam.z440-cowork-workspace / t250-okf-design
