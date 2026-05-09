---
name: moos-rewrite-envelope
description: Use when composing envelopes for the mo:os kernel (`mcp__moos-kernel__apply_program` / `apply_rewrite`, or `POST /programs` / `POST /rewrites`). Covers the four rewrite types (ADD, LINK, MUTATE, UNLINK) — field names, placement gotchas (top-level `type_id` vs nested), additive vs standard MUTATE paths, PropertySpec rules, one-field-per-MUTATE, `created_at` as immutable property not runtime-injected. Trigger whenever writing a rewrite envelope, debugging operad validation errors like "unknown type_id", "required immutable property missing", "field not declared in type spec", or "field not in mutate_scope".
---

# mo:os rewrite envelope authoring

The mo:os kernel accepts four and only four rewrites: **ADD**, **LINK**, **MUTATE**, **UNLINK**. Each is a JSON envelope. `apply_program` takes an `envelopes` array (atomic — all or nothing). `apply_rewrite` takes a single envelope.

This skill is the hard-won catalog of field names, placement rules, and validation paths. Read the relevant section before composing envelopes.

## Canonical envelope shape (from `internal/graph/rewrite.go`)

```go
type Envelope struct {
    RewriteType RewriteType `json:"rewrite_type"` // "ADD" | "LINK" | "MUTATE" | "UNLINK"
    Actor       URN         `json:"actor"`        // URN, NOT "actor_urn"

    // ADD fields
    NodeURN    URN                 `json:"node_urn,omitempty"`
    TypeID     TypeID              `json:"type_id,omitempty"`   // TOP-LEVEL, not inside properties
    Properties map[string]Property `json:"properties,omitempty"`

    // LINK fields
    RelationURN     URN             `json:"relation_urn,omitempty"`
    SrcURN          URN             `json:"src_urn,omitempty"`
    SrcPort         string          `json:"src_port,omitempty"`
    TgtURN          URN             `json:"tgt_urn,omitempty"`
    TgtPort         string          `json:"tgt_port,omitempty"`
    RewriteCategory RewriteCategory `json:"rewrite_category,omitempty"`
    ContractURN     URN             `json:"contract_urn,omitempty"` // required for WF15

    // MUTATE fields
    TargetURN       URN      `json:"target_urn,omitempty"`
    Field           string   `json:"field,omitempty"`            // one field per MUTATE
    NewValue        any      `json:"new_value,omitempty"`
    ExpectedVersion int64    `json:"expected_version,omitempty"` // 0 = skip CAS
    // PropertySpec is injected by runtime for additive MUTATE — do not set manually
}
```

## ADD — create a new node

**Required fields:** `rewrite_type`, `actor`, `node_urn`, `type_id`, `properties`.

**Property shape:** each property is `{"value": <x>, "mutability": "immutable"|"mutable", "authority_scope": "<scope>", "stratum_origin": <int>}`.

**Gotcha #1 — `type_id` is top-level, NOT inside `properties`.** `ValidateADD` reads `env.TypeID` directly:
```go
spec, ok := r.NodeTypes[env.TypeID]
if !ok { return fmt.Errorf("operad: unknown type_id %q", env.TypeID) }
```
Putting `type_id` only inside `properties` yields `unknown type_id ""`. Fix: put it at both (nested is harmless but redundant) or just top-level.

**Gotcha #2 — every immutable property declared in the type spec must be present.** `ValidateADD` iterates `spec.Properties` and errors on any `mutability: "immutable"` that isn't in `env.Properties`.
- For most types that means at least `owner_urn` and `created_at`.
- `created_at` is an **ontology-declared immutable property with a value you supply** (e.g. `"2026-04-18T16:00:00Z"`) — it is NOT runtime-injected. The node record has a separate `CreatedAt` timestamp the runtime sets, but the *property* is your responsibility.
- Extra properties not in the spec are allowed and stored.

**Gotcha #3 — `actor`, not `actor_urn`.** JSON key is `"actor"` per the struct tag.

**Gotcha #3a — post-§M11 actor discipline (T=171 PR 30+).** Actor URNs that don't resolve to a seated session are rejected by the kernel with `kernel(§M11): no session context for actor=...`. In practice:

- **Agent actor** (`urn:moos:agent:<short>`) is the default. Works via the inferred-session reverse-lookup when that agent occupies exactly one session via WF19 `has-occupant`. This is what Claude Code / Antigravity / Cowork actors use day-to-day.
- **User actor** (`urn:moos:user:sam`) fails §M11 unless `user:sam` is directly seated as a session occupant — which sam is NOT in the current topology (agents are the occupants; sam is the owner). Avoid `user:sam` as actor except inside `SeedIfAbsent` paths (where liveness is structurally bypassed).
- **Kernel actor** (`urn:moos:kernel:<ws>.<name>`) bypasses §M11 via the `SystemInternalEnvelope` allowlist AND bypasses §M12 admin-scope. Use when the envelope is ontology-governed (`system_instruction`, `gate`, `twin_link`, `transport_binding`, `kernel` ADD/MUTATE) AND the current agent doesn't hold WF02 superadmin. Also the canonical actor for WF19 `opens-on` LINKs (Authority=kernel).
- **Ambiguous-session agent**: if one agent occupies multiple sessions, set `session_urn` explicitly on the envelope to disambiguate.

**Canonical ADD example** (agent actor — the common case):
```json
{
  "rewrite_type": "ADD",
  "actor": "urn:moos:agent:claude-code.hp-z440",
  "node_urn": "urn:moos:external_op:sam.mtdc-kernel-start",
  "type_id": "external_op",
  "properties": {
    "title": {"value": "...", "mutability": "immutable", "authority_scope": "", "stratum_origin": 2},
    "owner_urn": {"value": "urn:moos:user:sam", "mutability": "immutable", "authority_scope": "", "stratum_origin": 2},
    "created_at": {"value": "2026-04-18T16:00:00Z", "mutability": "immutable", "authority_scope": "", "stratum_origin": 2},
    "status": {"value": "pending", "mutability": "mutable", "authority_scope": "kernel", "stratum_origin": 2}
  }
}
```

Note the split: `actor` = who emits (agent, traced per envelope), `owner_urn` property = who owns the node (user, sticky provenance). Don't conflate them.

## MUTATE — change one typed property on one node

**Required fields:** `rewrite_type`, `actor`, `target_urn`, `field`, `new_value`. One field per envelope. No `rewrite_category` in the additive path.

**Two validation paths** (from `internal/operad/validate.go`):

### Standard MUTATE — field already on node

- Requires `rewrite_category` (a WF declaring MUTATE in `allowed_rewrites`).
- `field` must be in that WF's `mutate_scope` list.
- Field must not be `mutability: "immutable"` in type spec.
- `authority_scope` is checked: `owner` requires `env.actor == node.properties.owner_urn`.

### Additive MUTATE — field NOT yet on node

- **No `rewrite_category` required.**
- Field MUST be declared in the ontology type spec (not just any new name).
- Field must be `mutability: "mutable"` in the type spec.
- Runtime auto-injects the PropertySpec from the ontology — do NOT set `property_spec` manually in the envelope.
- Authority check still applies.

**Gotcha #4 — cannot add arbitrary fields via MUTATE.** If a field isn't in the ontology type spec, additive MUTATE returns:
```
operad: field "X" not declared in type spec for <type_id>
```
Adding new fields requires a grammar_fragment + WF20 promotion to ontology, then bump ontology.json, then MUTATE.

**Gotcha #5 — one field per MUTATE envelope.** Not `properties: {...}` like ADD. Structure is `{field: "X", new_value: <v>}`. To mutate 3 fields, emit 3 envelopes in one program (atomic batch).

**Canonical MUTATE examples:**

External-op lifecycle closeout (status is kernel-authority as of ontology v3.16.1):
```json
{
  "rewrite_type": "MUTATE",
  "actor": "urn:moos:kernel:hp-laptop.primary",
  "target_urn": "urn:moos:external_op:sam.test",
  "field": "status",
  "new_value": "cancelled"
}
```

Additive (field not yet on node, field IS in type spec):
```json
{
  "rewrite_type": "MUTATE",
  "actor": "urn:moos:agent:claude-code.hp-z440",
  "target_urn": "urn:moos:program:sam.example",
  "field": "scope",
  "new_value": "New optional scope text"
}
```

Standard (field already on node, WF governs):
```json
{
  "rewrite_type": "MUTATE",
  "actor": "urn:moos:agent:claude-code.hp-z440",
  "target_urn": "urn:moos:program:sam.wiring-proposer",
  "field": "target_t",
  "new_value": 250,
  "rewrite_category": "WF18"
}
```

Kernel-authority MUTATE (the actor must be a kernel URN per §M12; `target_t` is `authority_scope: "kernel"` on `program`, so a non-kernel actor gets rejected):

```json
{
  "rewrite_type": "MUTATE",
  "actor": "urn:moos:kernel:hp-z440.primary",
  "target_urn": "urn:moos:program:sam.wiring-proposer",
  "field": "target_t",
  "new_value": 250,
  "rewrite_category": "WF18"
}
```

## LINK — create a hyperedge

**Required fields:** `rewrite_type`, `actor`, `relation_urn`, `src_urn`, `src_port`, `tgt_urn`, `tgt_port`, `rewrite_category`.

**Gotcha #6 — WF15 requires `contract_urn`.** Any other WF, omit it.

**Gotcha #7 — port color compatibility.** `resolvePortColors` + `PortColorMatrix` rejects incompatible color pairings. Use the port pairs the WF explicitly declares (e.g. WF18 uses `composes/composed-by`, `depends-on/depended-by`).

**Gotcha #8 — src/tgt types must be in the WF's declared lists** (if the WF declares non-empty `src_types` / `tgt_types`). Check `operad_registry` or `ontology.json` before linking.

**Gotcha #9 — S4 nodes cannot be the src of a LINK to S0/S1/S2.** Strata filtration in `ValidateStrataLink`.

**Canonical LINK example** (agent actor, non-kernel-authority WF):
```json
{
  "rewrite_type": "LINK",
  "actor": "urn:moos:agent:claude-code.hp-z440",
  "relation_urn": "urn:moos:rel:v310-delivery.depends-on.t187-kernel-proper",
  "src_urn": "urn:moos:program:sam.v310-delivery",
  "src_port": "depends-on",
  "tgt_urn": "urn:moos:program:sam.t187-kernel-proper",
  "tgt_port": "depended-by",
  "rewrite_category": "WF18"
}
```

### T189 Calendar observation example

When a Google Calendar write has already happened and is being observed back into HG, create a `calendar_event` node, then pin it into the active session with WF19. The Google event itself is not truth; this node is the graph observation of that external event.

```json
{
  "rewrite_type": "ADD",
  "actor": "urn:moos:agent:claude-code.hp-laptop",
  "session_urn": "urn:moos:session:sam.governance",
  "node_urn": "urn:moos:cal:2026-05-09.moos-example",
  "type_id": "calendar_event",
  "properties": {
    "summary": {"value": "mo:os program :: example", "mutability": "immutable", "authority_scope": "", "stratum_origin": 2},
    "date": {"value": "2026-05-09", "mutability": "immutable", "authority_scope": "", "stratum_origin": 2},
    "t_day": {"value": 189, "mutability": "immutable", "authority_scope": "", "stratum_origin": 2},
    "gcal_id": {"value": "google-event-id", "mutability": "immutable", "authority_scope": "", "stratum_origin": 2},
    "color_label": {"value": "purple", "mutability": "immutable", "authority_scope": "", "stratum_origin": 2},
    "status": {"value": "confirmed", "mutability": "mutable", "authority_scope": "kernel", "stratum_origin": 2},
    "created_at": {"value": "2026-05-09T16:30:00Z", "mutability": "immutable", "authority_scope": "", "stratum_origin": 2}
  }
}
```

```json
{
  "rewrite_type": "LINK",
  "actor": "urn:moos:kernel:hp-laptop.primary",
  "relation_urn": "urn:moos:rel:t189.calendar-pin.2026-05-09.moos-example",
  "src_urn": "urn:moos:session:sam.governance",
  "src_port": "pins-urn",
  "tgt_urn": "urn:moos:cal:2026-05-09.moos-example",
  "tgt_port": "pinned-by-session",
  "rewrite_category": "WF19"
}
```

Do not apply WF07 `anchors/anchor` for Calendar source anchors until the top-level WF07 declaration and the port-color compatibility entry agree. T189 keeps those relations as deferred rows in reconciliation rather than silently applying a questionable port pair.

## UNLINK — remove a relation

**Required fields:** `rewrite_type`, `actor`, `relation_urn`. `rewrite_category` is optional (resolved from existing relation). Nodes are never removed — UNLINK only removes relations.

## Common errors and fixes

| Error | Cause | Fix |
|-------|-------|-----|
| `operad: unknown type_id ""` | `type_id` nested inside `properties` instead of top-level | Move `"type_id": "<id>"` to envelope top level |
| `operad: unknown type_id "X"` | Type not in loaded ontology | Verify ontology.json has the type; restart kernel if just added |
| `operad: required immutable property "X" missing on ADD of Y` | Immutable property in type spec not supplied | Add it to `properties` (commonly `owner_urn`, `created_at`) |
| `operad: field "X" not declared in type spec for Y` | Additive MUTATE on a field not in ontology | Either use an existing field, or add the field to ontology via grammar_fragment + WF20 |
| `operad: field "X" not in mutate_scope for WFNN` | Standard MUTATE but WF doesn't allow mutating that field | Pick the correct WF, or extend mutate_scope via ontology bump |
| `operad: field "X" is immutable on type Y` | Trying to MUTATE an immutable property | Can't; immutable is immutable |
| `operad: unknown rewrite_category "X"` | Typo or WF not in registry | Verify via `operad_registry` HTTP endpoint |
| `operad: port color incompatibility` | Port pair clashes under that WF | Pick declared port pairs; reuse existing WF port examples |
| `program step N (ADD): node already exists` | URN collision | Look up the node first; maybe you want MUTATE instead |
| `strata(M5): S4 node may not LINK to S2 node` | S4→S0/S1/S2 direction forbidden | Invert direction, or use a different WF/path |

## Validation pipeline (good to know)

From `internal/kernel/runtime.go`:
1. **Structural validation** — `ApplyProgram` validates every envelope without the lock (MUTATE returns nil at this stage — deferred).
2. **Lock acquired.**
3. **PropertySpec injection** — for additive MUTATE where the field IS in the type spec and IS mutable, runtime injects the PropertySpec.
4. **fold.EvaluateProgram** — applies envelopes sequentially via the catamorphism. Pure function over state + envelope.
5. **Log append** — on success, each envelope becomes a `PersistedRewrite` with `LogSeq`.

**Implication:** validation failures fail the whole program (all-or-nothing atomic batch). Inspect the error message, fix the envelope, retry. The log never contains partial programs.

## Introspection tips

- **Don't call `operad_registry` via MCP** — it returns `{"note": "use GET /operad/* HTTP routes"}`. Either hit `http://localhost:8000/operad/node-types` or `/operad/rewrite-categories`, or read `ontology.json` directly.
- **Node lookup:** `mcp__moos-kernel__node_lookup` takes `{urn: "..."}`. Returns type, properties with full property records, `created_at`, `version`.
- **Graph state overflow:** `graph_state` returns everything and commonly exceeds context. Slice the output file via `node -e "fs.readFileSync(...)"` (or `jq` if installed) in 80k-char spans, or use the log file (`moos-kernel/moos.jsonl`) directly with `jq` / `node -e` filtering by `envelope.type_id` / `envelope.rewrite_type`.
- **Log format:** `{"envelope": {...}, "applied_at": "...", "log_seq": N}` per line.

## See also

- `internal/graph/rewrite.go` — Envelope struct + RewriteType constants
- `internal/operad/validate.go` — ValidateADD, ValidateMUTATE, ValidateLINK, ValidateUNLINK, ValidateStrataLink
- `internal/fold/evaluate.go` — applyADD, applyLINK, applyMUTATE, applyUNLINK (pure)
- `internal/kernel/runtime.go` — Apply / ApplyProgram pipeline, PropertySpec injection
- `ffs0/kb/superset/ontology.json` — canonical type + WF registry
