# Firestarter — Graph Growth Agent

Formal definition of the Firestarter: the centerpiece agent that accelerates graph hydration by reading external artifacts, classifying them against the ontology, and submitting Programs to the kernel.

**References:** [the-carpet](20260314-the-carpet.md), [concepts](concepts.md), [graph-topology](20260318-graph-topology-and-mathematical-paradigms.md)

---

## §1 What It Is

The Firestarter is an **endofunctor on the graph category**:

```
F_fire : (C × Disk) → C
```

It takes the current graph state and a filesystem artifact (SKILL.md, email, arXiv paper, YouTube transcript) and produces new morphisms that extend the graph. It is the only agent whose primary purpose is graph growth — all other agents consume graph structure, the Firestarter produces it.

In categorical terms: the Firestarter is a **counit** of the adjunction between the external world and the graph. External data enters; typed, wired structure comes out.

```
External artifacts (untyped, unstructured, opaque)
        │
        ▼  F_fire
Graph state (typed, wired, governed)
```

---

## §2 What It Is Not

- **Not a functor.** FUN01–FUN05 are projections: graph → target category. The Firestarter goes the other direction: source → graph. It is an **import morphism**, not a projection.
- **Not autonomous.** It does not decide what to ingest. Sam or another agent points it at an artifact. It classifies and hydrates. Governance remains human.
- **Not semantic.** It generates **syntax** (ADD, LINK). Semantics emerge when functors are applied to the resulting structure. The Firestarter keeps Lawvere's discipline: syntax and semantics are separate.
- **Not a 5th NT.** Everything it does decomposes to ADD + LINK + MUTATE. No new invariant.

---

## §3 Categorical Identity

### As an Object

```
urn:moos:agent:firestarter
type_id: agent_spec (OBJ21)
stratum: S2 (materialized)
broad_category: identity
```

It is a node in the graph it grows. Self-referential: the Firestarter can enrich its own node with metadata about what it has processed. This is not a paradox — it's a fixed point: `F_fire(graph_with_firestarter) ⊇ graph_with_firestarter`.

### As a Morphism Composer

The Firestarter's output is always a **Program** — an atomic batch of Envelopes:

```
Program = [ADD(node), LINK(root, owns, node, child), ...]
```

Every Program decomposes to the 4 invariant NTs. The Firestarter composes them; the kernel evaluates them. Separation of composition and evaluation.

### Ports (from OBJ21 AgentSpec)

| Port | Direction | Target | Meaning |
|------|-----------|--------|---------|
| CAN_HYDRATE | out | any | Permission to ADD/LINK/MUTATE nodes |
| CAN_ROUTE | out | system_tool | Routes to tools it discovers |
| SYNC_ACTIVE_STATE | out | node_container | Tracks processing state |
| OWNS | in | identity.* | Owned by kernel root |

### Wires

```
urn:moos:kernel:wave-0 ──OWNS──→ urn:moos:agent:firestarter
urn:moos:agent:firestarter ──CAN_HYDRATE──→ (any target it creates)
urn:moos:agent:firestarter ──CAN_ROUTE──→ (tools it discovers)
```

---

## §4 The Pipeline

The Firestarter operates a 4-stage pipeline. Each stage is a pure function; side effects happen only at stage 4 (kernel submission).

### Stage 1: READ

Input: filesystem path to an artifact (SKILL.md, .json, .txt, email body).
Output: structured record with extracted fields.

```
read : Path → Record
Record = {
    name        : String,
    description : String,
    when_to_use : String,
    when_not_to_use : String,
    capabilities : [String],
    dependencies : [String],
    key_files   : [Path],
    raw_content : String
}
```

This is extraction, not interpretation. No classification yet.

### Stage 2: CLASSIFY

Input: Record from Stage 1.
Output: ontology assignment (type_id, stratum, URN).

```
classify : Record → (TypeID × Stratum × URN)
```

Classification rules (current):
- Default: `system_tool` (OBJ07), S2
- If agent behavior detected (orchestrate, compose, delegate): `agent_spec` (OBJ21), S2
- If reusable template pattern: `app_template` (OBJ04), S1/S2
- If external industry reference: `industry_entity` (OBJ22), S0

The classify function is the **classifying functor** from the design doc — it maps untyped external artifacts into the typed ontology.

### Stage 3: GENERATE

Input: Record + classification.
Output: Program (array of Envelopes).

```
generate : (Record × Classification) → Program
```

Two modes:
- **add**: For new nodes. Produces ADD + LINK(OWNS).
- **enrich**: For existing nodes. Produces MUTATE with enriched payload.

The payload is the **metadata sticker** — the graph-visible description of an opaque leaf:

```json
{
    "name": "...",
    "description": "...",
    "when_to_use": "...",
    "when_not_to_use": "...",
    "capabilities": ["..."],
    "skill_path": "...",
    "dependencies": ["..."],
    "key_files": ["..."],
    "source": "ind:skill:...",
    "classified_as": "OBJ07",
    "user_stars": 0
}
```

`user_stars` — human rating (0=unrated, 1–5). Only Sam mutates this field. It is the **governance signal** — the one payload field that flows upstream from human to graph, not from artifact to graph. Future: Explorer renders stars, FUN03 weights embeddings by rating.
```

### Stage 4: HYDRATE

Input: Program from Stage 3.
Output: kernel response (success, conflict, error).

```
hydrate : Program → Result
```

Submission via `POST /programs`. The kernel validates (operad), persists (log), and updates state (fold). The Firestarter does not bypass governance — every envelope goes through `ValidateAdd`, `ValidateLink`, `ValidateMutate`.

---

## §5 What It Forces

The Firestarter is valuable not just for what it produces but for what it **forces us to define**:

1. **Categories**: Every skill must be classified. Classification requires that the ontology has a type for it. If it doesn't, the ontology must grow.
2. **Operads**: Every LINK must satisfy port constraints. If a skill needs a wire type that doesn't exist, the operad must grow.
3. **Projections**: Once skills are in the graph, functors can project them — Explorer shows them, embeddings encode them, benchmarks measure them.
4. **Metadata schema**: The payload structure (when_to_use, capabilities, etc.) is a de facto schema for skill metadata. It will stabilize through use, potentially promoting to a formal TypeSpec field.

This is the growth mechanism from the topology doc (§6): patterns enter as data, stabilize, and eventually promote to structure.

---

## §6 Extension Points

The 4-stage pipeline is generic. The Firestarter currently handles SKILL.md files. The same pipeline extends to:

| Source | READ adapter | CLASSIFY mapping | Notes |
|--------|-------------|-----------------|-------|
| SKILL.md | YAML frontmatter + markdown sections | OBJ07/OBJ21/OBJ04 | Current MVP |
| Gmail | MCP `gmail_read_message` → subject, body, sender | OBJ22 (S0) or OBJ05 | Google hackathon, devtools, research |
| arXiv | PDF extract → title, abstract, authors | OBJ22 (S0) | Papers, benchmarks, methods |
| YouTube | Transcript extract → title, summary, topics | OBJ22 (S0) | Industry scoping, PRG references |
| MCP tools | Tool schema → name, description, parameters | OBJ07 | Auto-discover from connected MCPs |
| npm/pip packages | Package.json / pyproject.toml | OBJ07 or OBJ12 | Dependency graph hydration |

Each source gets a READ adapter. CLASSIFY and GENERATE are shared. HYDRATE is always the same kernel endpoint.

### Gmail PRG (Planned)

Sam directive: Claude Code monitors Gmail for interesting content (Google hackathon invites, devtools announcements, research links). This is a **running PRG** — not a one-shot batch like SKILL.md processing.

Pipeline: `gmail_search_messages` → filter by sender/subject patterns → `gmail_read_message` → READ adapter extracts structured record → CLASSIFY as `industry_entity` (OBJ22, S0) or `external_reference` (OBJ05) → HYDRATE → wire to `leadoff.md` as a running conversation item.

Governance: Sam approves which senders/patterns trigger ingestion. The Firestarter does not autonomously ingest — it classifies candidates and presents them for human approval. This preserves the "not autonomous" constraint from §2.

### YouTube / VS Code Workflow (Active, External)

VS Code AI proceeded with YouTube KB hydration independently (YouTube API added to VS Code toolchain). This is a parallel READ adapter operating outside the Firestarter's direct control but producing compatible output — structured records that can be classified and hydrated through the same GENERATE → HYDRATE pipeline. Convergence point: both pipelines target the same kernel endpoint.

### Chrome WebMCP (Future, Early Preview)

Chrome is previewing WebMCP — making websites agent-ready by exposing structured actions via MCP protocol. Instead of scraping artifacts, websites expose tool schemas that classify directly to OBJ07. The web becomes a source category for F_fire. Status: early preview, not production-ready. Hydrated as `urn:moos:industry:chrome-webmcp-preview` (OBJ22, S0) for tracking.

### Google Developer Knowledge API + MCP Server (Evaluating)

Google-hosted MCP server providing canonical developer documentation. Research-task posted to VS Code for evaluation as a Firestarter READ adapter. If viable, this gives us an authoritative documentation source that maps directly to the CLASSIFY stage — docs about specific APIs/services classify as `system_tool` (OBJ07) or `industry_entity` (OBJ22). Hydrated as `urn:moos:industry:google-developer-knowledge-api-mcp` (OBJ22, S0).

---

## §7 Current Implementation

| File | Role |
|------|------|
| `.agent/kb/instances/agents.json` | Firestarter node definition (OBJ21) |
| `.agent/workflows/firestarter/classify-skill.py` | Stages 1–3: read, classify, generate |
| `.agent/workflows/firestarter/hydrate-skill.ps1` | Stage 4: submit to kernel, auto-detect add/enrich |
| `.agent/workflows/firestarter/batch-hydrate.ps1` | Batch processor for all skills |

### Proven Results (March 18, 2026)

**Batch 1 (manual, 7 skills):**

| Metric | Before | After |
|--------|--------|-------|
| Graph nodes | 226 | 233 |
| Graph wires | 102 | 110 |
| Skills in graph | 10 | 17 |
| Log depth | 328 | 344 |

**Batch 2 (full batch-hydrate.ps1, 49 skills):**

| Metric | Before | After |
|--------|--------|-------|
| Graph nodes | 232 | 272 |
| Graph wires | 108 | 148 |
| Skills in graph | 17 | 49 |
| Log depth | 341 | 430 |
| Success rate | — | 49/49 (100%) |

Breakdown: 40 skills ADD'd (new nodes), 9 skills ENRICHED (existing nodes mutated with full metadata). All 49 SKILL.md files processed. Zero failures. Payload includes `user_stars` field (default 0, human-only mutation).

---

## §8 Relation to Task Decomposition vs Functorial Composition

Sam's constraint: keep these separate.

**Task decomposition** is what the Firestarter does at Stage 3 — it breaks "ingest this skill" into a sequence of ADD + LINK envelopes. This is mechanical. It follows rules. It's in the enforce regime (S0–S2).

**Functorial composition** is what happens AFTER the graph grows — when FUN02 renders the Explorer, when FUN03 embeds the descriptions, when a future FUN06 routes an agent to the right tools based on graph traversal. This is in the discover regime (S3–S4).

The Firestarter stays on the enforce side. It generates syntax. The functors generate semantics. The boundary is clean.
