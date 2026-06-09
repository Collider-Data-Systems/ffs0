---
name: moos-workspace-ingest
description: Chunker for the Cowork-as-occupant ingest direction (G in the F⊣G adjunction). Use when a Cowork session needs to land a Workspace artifact (Gmail thread, Calendar event, Drive doc, Tasks item) or a Cowork-authored artifact (markdown/HTML brief) as `knowledge_item` nodes in the HG. Picks chunk grain per source type, emits a single atomic `apply_program` batch with umbrella + chunks + provides-kb/kb-source LINKs (WF12). Idempotent — re-ingest of a previously-chunked source emits a `claim` flagging the duplicate rather than re-ADDing. Trigger on: "ingest this Drive doc", "chunk this email thread into HG", "land this brief as knowledge_items", or any Workspace URN passed to a Cowork session for HG persistence.
---

# moos-workspace-ingest

The G-direction skill for Cowork sessions. External Workspace state (Gmail / Calendar / Drive / Tasks) and Cowork-authored artifacts come **into** the HG as `knowledge_item` chunks pinned to the active Cowork session's scope.

This skill is the canonical invocation surface for the doctrine reified as `derivation:t172.cowork-as-occupant` on log (chunking discipline). Don't reinvent the chunker per ingest — call this.

## Cardinal rule — one atomic batch per source

Every ingest of a single source URN lands as exactly one `apply_program` batch on exactly one kernel (Cowork's host kernel — `kernel:hp-z440.primary` for `agent:claude-cowork.hp-z440`, `kernel:hp-laptop.primary` for `agent:claude-cowork.hp-laptop`). Either all envelopes apply or none do. No partial chunks left half-landed in the log.

If the source spans 200 sections and the batch validation rejects on chunk 73, the whole batch fails — fix the offending chunk's properties, retry. Don't chunk-then-LINK in two transactions.

## Cardinal rule — actor is the Cowork agent, scope is the session (set EXPLICITLY)

```
actor:        urn:moos:agent:claude-cowork.hp-z440  (or .hp-laptop)
session_urn:  urn:moos:session:sam.z440-cowork-workspace  (or sam.laptop-cowork-workspace)
```

**T=175 update — set `session_urn` explicitly on every envelope.** The inferred-session path (reverse-lookup via `has-occupant`) is functionally accepted by §M11 but currently fails to tick `session.local_t` per the §M13 sub-program `session-actor-agent-lookup` gap. Surfaced concretely at T=174 ~00:45 CEST: `session:sam.laptop-cowork-workspace.local_t = 0` after 24 acknowledged Phase A rewrites. Phase E.2 of `~/.claude/plans/valiant-kindling-sunrise.md` closes the gap in `runtime.go`; until that PR merges + 5 kernels rebuild, **always set `session_urn` explicitly**. After E.2 lands, the rule still holds as best practice — explicit beats implicit, and multi-session agents (Wolfram on `sam.kernel-proper`+`sam.mvp-delivery`) require it anyway.

Per `moos-rewrite-envelope` §1 (canonical envelope shape) — every envelope carries both `actor` and `session_urn`; never omit `session_urn` on the bet that reverse-lookup will infer it.

## Inputs

| Source kind | URN shape | Lives in scope-pin | MCP fetch tool |
|---|---|---|---|
| Gmail thread | `gmail:thread:<thread-id>` | `channel:google.gmail.sam` | `mcp__b6a45e2f-...__get_thread` |
| Calendar event | `calendar:event:<event-id>` | `channel:google.calendar.sam` | `mcp__ddd9ba36-...__get_event` |
| Drive file | `drive:file:<file-id>` | `channel:google.drive.sam` | `mcp__d9ef29a4-...__read_file_content` |
| Tasks item | `tasks:item:<task-id>` | `channel:google.tasks.sam` | (read-only via Calendar Tasks endpoint or skill — pending) |
| Cowork artifact | `artifact:cowork.<artifact-id>` | (per-artifact pin; no parent channel) | `mcp__cowork__list_artifacts` + render |

If the URN doesn't resolve via its MCP, **skip + log a single line; no envelopes**. Failed lookup is not a rewrite.

## Dispatch rule (chunk grain)

```python
def chunk_unit(source):
    if source.kind in {"gmail-thread", "calendar-event", "task"}:
        return "per-item"        # atomic, one knowledge_item per source
    if source.kind == "drive-doc" and source.has_h2_structure:
        return "per-section"     # umbrella + one chunk per H2
    if source.kind == "cowork-artifact":
        return "per-artifact-section"  # umbrella + one chunk per top-level section
    return "per-item"            # safe default
```

Override only with explicit user instruction. If unsure between per-section and per-item for a Drive doc, default to **per-item** — coarser-grain is recoverable (re-ingest at finer grain), finer-grain is not (you'd have to UNLINK + GC, which we don't do).

## Output shape

### Per-item case (single chunk)

One `ADD knowledge_item` envelope. Source URL goes on `source_url` (immutable). No umbrella. No `provides-kb` LINKs. One `channel --WF12 provides-kb--> knowledge_item` LINK back to the source channel so downstream readback counts it.

**Proof note (T=173 ~23:30 CEST):** Live ontology `knowledge_item` operad has `source_url` (not `source_uri`). URN pattern is `urn:moos:ki:<source-type>.<slug>` (not `urn:moos:knowledge_item:*`). `owner_urn` and `body` are NOT in the registered property set — use `ingest_actor` for provenance; `summary` (authority_scope=kernel, mutable) for body. Extra properties (`chunk_index`, `chunk_label`, `umbrella_urn`, `ingest_actor`) are accepted by the kernel on ADD but are unregistered.

```json
{
  "rewrite_type": "ADD",
  "actor": "urn:moos:agent:claude-cowork.hp-z440",
  "session_urn": "urn:moos:session:sam.z440-cowork-workspace",
  "node_urn": "urn:moos:ki:<source-type>.<source-slug>",
  "type_id": "knowledge_item",
  "properties": {
    "title":       {"value": "<source title>", "mutability": "immutable", "authority_scope": "", "stratum_origin": 2},
    "source_url":  {"value": "<full source URL>", "mutability": "immutable", "authority_scope": "", "stratum_origin": 2},
    "source_type": {"value": "<gdrive|email|website|...>", "mutability": "immutable", "authority_scope": "", "stratum_origin": 2},
    "language":    {"value": "en", "mutability": "immutable", "authority_scope": "", "stratum_origin": 2},
    "created_at":  {"value": "<ISO-8601 source created>", "mutability": "immutable", "authority_scope": "", "stratum_origin": 2},
    "retrieved_at":{"value": "<ISO-8601 fetch time>", "mutability": "immutable", "authority_scope": "", "stratum_origin": 2},
    "status":      {"value": "raw", "mutability": "mutable", "authority_scope": "kernel", "stratum_origin": 2},
    "ingest_actor":{"value": "urn:moos:agent:claude-cowork.hp-z440", "mutability": "immutable", "authority_scope": "", "stratum_origin": 2}
  }
}
```

**On hp-laptop swap `actor` to `urn:moos:agent:claude-cowork.hp-laptop` and `session_urn` to `urn:moos:session:sam.laptop-cowork-workspace`.**

### Multi-chunk case (umbrella + N chunks)

Order in the batch:

1. **Umbrella** — `ADD knowledge_item` for the source as a whole. `source_url` = source URL; `source_type` = source kind. Set `chunk_count` (extra property, kernel accepts). Set `status: "summarized"` if preamble available; `"raw"` otherwise.
2. **Chunks** — one `ADD knowledge_item` per chunk. Each carries `chunk_index` + `chunk_label` (H2 text or section heading) + `umbrella_urn` (extra properties — all accepted by kernel on ADD). Their `source_url` references the section anchor, not the umbrella URN.
3. **LINKs** — one per chunk via WF12 `provides-kb`/`kb-source` (umbrella is source, chunk is target), plus one LINK from the source `channel` to the umbrella (channel is source, umbrella is target):

```json
{
  "rewrite_type": "LINK",
  "actor": "urn:moos:agent:claude-cowork.hp-z440",
  "session_urn": "urn:moos:session:sam.z440-cowork-workspace",
  "relation_urn": "urn:moos:rel:<umbrella-slug>.provides-kb.<chunk-slug>",
  "src_urn":  "urn:moos:knowledge_item:cowork.<umbrella-slug>",
  "src_port": "provides-kb",
  "tgt_urn":  "urn:moos:knowledge_item:cowork.<chunk-slug>",
  "tgt_port": "kb-source",
  "rewrite_category": "WF12"
}
```

And the channel→umbrella LINK:

```json
{
  "rewrite_type": "LINK",
  "actor": "urn:moos:agent:claude-cowork.hp-z440",
  "session_urn": "urn:moos:session:sam.z440-cowork-workspace",
  "relation_urn": "urn:moos:rel:<channel-slug>.provides-kb.<umbrella-slug>",
  "src_urn":  "urn:moos:channel:google.drive.sam",
  "src_port": "provides-kb",
  "tgt_urn":  "urn:moos:knowledge_item:cowork.<umbrella-slug>",
  "tgt_port": "kb-source",
  "rewrite_category": "WF12"
}
```

**WF correction (T=173 ~22:30 CEST):** Earlier drafts of this skill and `cowork-as-occupant.md` §3 prescribed WF18 `composes`/`composed-by` here. That was wrong — WF18 is program composition (`src_types: [program, purpose]`), which excludes both `channel` and `knowledge_item`. The correct category is WF12 `provides-kb`/`kb-source` (KB provision and hydration; see ontology.json WF12). Fixed inline before the first chunker proof fired. Readback-skill grep counts accordingly.

## Pinning into the Cowork session scope

Per `cowork-as-occupant.md` §2.1 — D19.3 `pins-urn` is **proposed** (not yet runtime-loadable). Today: append the umbrella URN to `session.scope_pins` via a single MUTATE on the session.

```json
{
  "rewrite_type": "MUTATE",
  "actor": "urn:moos:agent:claude-cowork.hp-z440",
  "session_urn": "urn:moos:session:sam.z440-cowork-workspace",
  "target_urn": "urn:moos:session:sam.z440-cowork-workspace",
  "field": "scope_pins",
  "new_value": [...existing pins..., "urn:moos:knowledge_item:cowork.<umbrella-slug>"]
}
```

After D19.3 promotes + ontology bumps + kernel restart: replace the property-MUTATE with a `LINK pins-urn` per pin. Track via TODO comment on the property-MUTATE envelope: `TODO(cds): D19.3 LINK migration`.

## Idempotence — re-ingest emits a claim, not a duplicate

Before emitting any ADD, check via `node_lookup` whether `urn:moos:knowledge_item:cowork.<source-slug>` already exists:

- **Exists, same `source_uri`, same `ingest_actor`** → emit one `ADD claim` envelope flagging duplicate-ingest. **No new knowledge_items.** No new LINKs.
- **Exists, different `source_uri` or `ingest_actor`** → URN collision (someone else ingested under the same slug). Bail with an error; ask sam to disambiguate. Don't auto-resolve.
- **Doesn't exist** → proceed with the full batch.

Slug collision is rare in practice (source IDs are usually globally unique within a Workspace) but the check is cheap and the failure mode is loud-fail-fast.

## What this skill does NOT do

- Does NOT push back to Workspace. This is the G direction only. The F direction (writing HG state out to Workspace via Calendar / Tasks creation) is a separate skill, not yet written.
- Does NOT auto-summarize. The chunk `body` is the source verbatim (or the source's exported text). Summarization belongs upstream of ingest, in a separate skill.
- Does NOT pin Cowork's internal scratchpad. Only artifacts the user explicitly persists or that this skill is invoked on land in the HG. Cowork's transient notes stay in Cowork.
- Does NOT chunk attachments by default. Attachments are LINKed to the Drive channel node, not duplicated as bytes. To chunk an attachment, invoke this skill again with the attachment's Drive URN.
- Does NOT mutate channel kinds. `channel.kind` is immutable per ontology spec — upgrading e.g. `messaging` → `email` requires UNLINK + re-ADD (loses URN continuity + scope-pins) or a narrow ontology migration window. Out of scope here.
- Does NOT cross kernels. A `claude-cowork.hp-z440` ingest lands on Z440 kernel only. Same source URN ingested from hp-laptop is a separate observation, separate log entry — per `cowork-as-occupant.md` §4 disjointness.

## Reporting shape — after a successful ingest

```text
source:    <source URN>
kind:      <gmail-thread|calendar-event|drive-doc|task|cowork-artifact>
chunked:   <per-item|per-section|per-artifact-section>
batch:     <N envelopes> (1 umbrella + <K> chunks + <K>+1 WF12 provides-kb LINKs + 1 scope_pins MUTATE)
landed on: kernel:hp-z440.primary  log_seq <start>..<end>
umbrella:  urn:moos:knowledge_item:cowork.<umbrella-slug>
session:   session:sam.z440-cowork-workspace (scope_pins now has <P> entries)
```

For a duplicate-ingest claim instead:

```text
source:    <source URN>
existing:  urn:moos:knowledge_item:cowork.<umbrella-slug>  (ingested at log_seq <N>)
emitted:   1 claim envelope, no new knowledge_items
```

## Fail modes

| Trigger | Behavior |
|---|---|
| Source URN doesn't resolve via MCP | Skip + log line. No envelopes. |
| Empty source (zero bytes) | Skip + log line. No envelopes. Don't ADD an empty knowledge_item. |
| Re-ingest of existing source | Emit `claim` only. Idempotent. |
| URN-slug collision under different `source_uri` | Bail + ask sam. No envelopes. |
| One chunk fails operad validation | Whole batch fails (atomic). Fix the chunk, retry. Log doesn't grow. |
| Source larger than batch limit | Split umbrella into umbrella-of-umbrellas (recurse one level). Don't split a single chunk across batches. |
| Session not `active` | Bail. The session must be live + occupied (you, the agent) before ingest can land. |

## Invocation patterns

### Explicit, by URN

```
Use moos-workspace-ingest on drive:file:1ABC...XYZ
```

### Implicit, on a Cowork artifact you just authored

After Cowork creates an artifact via `mcp__cowork__create_artifact`, you can offer:

```
Land this brief in the HG as a chunked knowledge_item? (will pin to your session scope)
```

If sam says yes, invoke this skill with `artifact:cowork.<artifact-id>`.

### Scheduled (per cowork-as-occupant.md §5.1)

A daily 08:00 chunker sweep matches sam's existing Mon 08:00-09:00 calendar ritual. Set up via `mcp__scheduled-tasks__create_scheduled_task` to run a list of pending sources through this skill in one session. Heartbeat side-effect: at least one rewrite per scheduled fire = §M11 liveness satisfied for the Cowork session.

## See also

### Inside ffs0

- `derivation:t172.cowork-as-occupant` (on log) — full doctrine; this skill implements the chunking discipline
- `derivation:t169.session-generalization` (on log) — 5-facet tuple, Cowork session shape
- `kb/superset/running-state.md` — current Cowork session URNs, scope-pins state, kernel host bindings

### Companion skills

- `moos-rewrite-envelope` — envelope shapes, actor discipline, validation gotchas (read first when authoring any rewrite)
- `moos-state-readback` — open-of-round check; run **before** an ingest sweep to confirm session is `active` and host kernel is alive
- `moos-round-close` — end-of-round; bump `running-state.md` Key URNs section with new umbrella URNs ingested this round
- `moos-github-project-bridge` — F-direction sibling for the GitHub Projects board; same adjunction shape, different surface

### Pending dependencies

- D19.3 `pins-urn` port pair promotion → flips scope-pin from property-MUTATE to LINK
- channel.kind grammar (`email` / `calendar` / `task-list` / `cloud-storage`) → no effect on this skill, but lets the channel nodes carry the right kind tag
- Tasks MCP wiring → currently no fetch path for `tasks:item:*` URNs; pending Calendar-Tasks endpoint or dedicated skill
- F-direction Workspace projection skill → pair to this G-direction one; not yet authored
