# Session Start — vscode-ai

Agent: `urn:moos:agent:vscode-ai`
Role: execution — golang, testing, git, kernel-development

## 1. Orient

- Kernel code: `C:\Users\maass\HPlaptop\moos\platform\kernel\`
- Module root: `moos/platform/kernel` (`go.mod` lives here)
- Run all tests: `go test ./internal/...` from module root
- T=0 = Nov 1, 2025. Today ≈ T=150+. Full rebuild in progress.

All packages currently green: `cs`, `hg`, `fiber`, `rewrite`, `proof`

## 2. Current Wave — Wave 1: Rename + Property Grammar

**Harness rule: each gate must be fully green before starting the next.**

### Gate 1 — Rename Anchor → Node (mechanical, zero behavior change)

Rename everywhere across `model/`, `cs/`, `hg/`, `fiber/`, `rewrite/`, `proof/`, `demo/`:

| Old                               | New              |
| --------------------------------- | ---------------- |
| `AnchorID`                        | `NodeID`         |
| `AnchorType`                      | `NodeType`       |
| `Anchor` (struct)                 | `Node`           |
| `AnchorSpec`                      | `NodeSpec`       |
| `AddAnchor`                       | `AddNode`        |
| `RemoveAnchor`                    | `RemoveNode`     |
| `Anchor(id)`                      | `Node(id)`       |
| `Anchors()`                       | `Nodes()`        |
| `InterfaceAnchors` (rewrite.Plan) | `InterfaceNodes` |
| `anchors` (map field in hg.Store) | `nodes`          |

**Gate test:** `go test ./internal/...` — all pass, zero new failures.
Commit: `refactor: rename Anchor→Node across kernel [wave:1-gate:1]`

---

### Gate 2 — Add PropertySpec to model

Add to `model/types.go`:

```go
type PropertySpec struct {
    Name     string
    DataType string   // "string" | "int" | "bool" | "enum"
    Values   []string // admissible values when DataType == "enum"; nil otherwise
    Required bool
}
```

Also rename `StateCell` → `Property`:

| Old                       | New                  |
| ------------------------- | -------------------- |
| `StateCell` (struct)      | `Property`           |
| `SetCell`                 | `SetProperty`        |
| `Cell(id, name)`          | `Property(id, name)` |
| `Cells()`                 | `Properties()`       |
| `SetCells` (rewrite.Plan) | `SetProperties`      |

**Gate test:** `go test ./internal/...` — all pass (pure rename + add, no logic change yet).
Commit: `refactor: rename StateCell→Property, add PropertySpec to model [wave:1-gate:2]`

---

### Gate 3 — Add Properties to NodeSpec in CS registry

Extend `cs.NodeSpec`:

```go
type NodeSpec struct {
    Type       model.NodeType
    Ports      map[model.PortName]model.PortSpec
    Properties map[string]model.PropertySpec // nil = no declared properties (permissive)
}
```

Registry stores properties per node type. No validation yet — just storage.

Add to `cs.Registry`:
```go
func (r *Registry) NodeSpec(nodeType model.NodeType) (NodeSpec, bool)
// already exists — extend it to return Properties
```

**Gate test:** Extend `TestValidateBindingUsesIncidences` — register an `agent` type with a
declared property `kind: enum(ide|process|api)`. Confirm `NodeSpec` returns it.
`go test ./internal/cs/...` green.
Commit: `feat: add Properties field to NodeSpec in CS registry [wave:1-gate:3]`

---

### Gate 4 — SetProperty validates against NodeSpec

In `hg.Store.SetProperty()`, after confirming the node exists:

```go
spec, ok := s.registry.NodeSpec(node.Type)
if ok && spec.Properties != nil {
    propSpec, declared := spec.Properties[prop.Name]
    if !declared {
        return fmt.Errorf("node type %q does not declare property %q", node.Type, prop.Name)
    }
    if propSpec.DataType == "enum" && !contains(propSpec.Values, prop.Value) {
        return fmt.Errorf("property %q on type %q: value %q not in %v",
            prop.Name, node.Type, prop.Value, propSpec.Values)
    }
}
// if spec.Properties == nil → permissive, accept any property
```

**Gate tests** (new file `hg/property_validation_test.go`):

```go
TestSetPropertyRejectsUndeclaredProperty   // type has Properties map, key not in it → error
TestSetPropertyRejectsWrongEnumValue       // kind="unknown" when enum is ide|process|api → error
TestSetPropertyAcceptsValidEnumValue       // kind="ide" → ok
TestSetPropertyPermissiveWhenNoSpec        // type registered with nil Properties → accepts anything
TestSetPropertyRequiredEnforcedOnRewrite   // rewrite.Apply with missing required property → error (optional for this gate)
```

`go test ./internal/...` — all pass.
Commit: `feat: SetProperty validates against NodeSpec property grammar [wave:1-gate:4]`

---

## 3. Architecture Rules (never break)

1. Zero external deps in `model/`, `cs/`, `hg/`, `rewrite/`, `fiber/` packages.
2. `proof/` (HTTP server) may import stdlib only.
3. Clone-apply-replace pattern in `rewrite.Apply` — never mutate store in-place.
4. CS registry is append-only after boot — no `RemoveNodeType`, no `RemoveBindingType`.
5. If `NodeSpec.Properties == nil` → permissive (no declared schema). Explicit empty map `{}` → strict (no properties allowed).

## 4. Commit Convention

```
<type>: <description> [wave:<N>-gate:<N>]
```

Types: `refactor` | `feat` | `fix` | `test` | `chore`

## 5. Before Ending Session

- `go test ./internal/...` — all green
- Commit with wave+gate tag
- Leave a one-line note in this file under `## Last Checkpoint` below

---

## Wave 2: JSON Grammar Loader

### Gate 1 — Define `grammar.json` + write the file

New file: `moos/platform/kernel/grammar.json`

```json
{
  "version": "1",
  "node_types": [
    {
      "type": "user",
      "ports": [
        { "name": "owns", "direction": "out" }
      ],
      "properties": {
        "name": { "data_type": "string", "required": true },
        "role": { "data_type": "enum", "values": ["superadmin", "admin", "member"], "required": true }
      }
    },
    {
      "type": "agent",
      "ports": [
        { "name": "governed-by", "direction": "in" },
        { "name": "runs-on", "direction": "out" }
      ],
      "properties": {
        "kind": { "data_type": "enum", "values": ["ide", "process", "api", "service"], "required": true },
        "transport": { "data_type": "enum", "values": ["http", "mcp-sse", "mcp-stdio", "scheduled", "webhook"], "required": false }
      }
    },
    {
      "type": "workstation",
      "ports": [
        { "name": "owned-by", "direction": "in" },
        { "name": "hosts", "direction": "out" }
      ],
      "properties": {
        "hostname": { "data_type": "string", "required": true },
        "os": { "data_type": "string", "required": false }
      }
    },
    {
      "type": "kernel",
      "ports": [
        { "name": "hosted-by", "direction": "in" },
        { "name": "governed-by", "direction": "in" }
      ],
      "properties": {
        "port": { "data_type": "string", "required": true }
      }
    }
  ],
  "binding_kinds": [
    {
      "kind": "governs",
      "roles": [
        { "name": "governor", "node_type": "user", "port": "owns" },
        { "name": "subject",  "node_type": "agent", "port": "governed-by" }
      ]
    },
    {
      "kind": "runs-on",
      "roles": [
        { "name": "agent",       "node_type": "agent",       "port": "runs-on" },
        { "name": "workstation", "node_type": "workstation", "port": "owned-by" }
      ]
    },
    {
      "kind": "hosted-by",
      "roles": [
        { "name": "kernel",      "node_type": "kernel",      "port": "hosted-by" },
        { "name": "workstation", "node_type": "workstation", "port": "hosts" }
      ]
    }
  ]
}
```

**Gate test:** File exists, valid JSON. No Go yet.
Commit: `chore: add grammar.json seed — user/agent/workstation/kernel [wave:2-gate:1]`

---

### Gate 2 — `cs.LoadGrammar(path string) (*Registry, error)`

New file: `cs/grammar.go`

Reads `grammar.json`, populates a `Registry` via `AddNodeType` + `AddBindingType`.
Zero new deps — stdlib `encoding/json` + `os` only.

**Gate tests** (`cs/grammar_test.go`):
```go
TestLoadGrammarRoundtrip           // load grammar.json → registry has 4 node types + 3 binding kinds
TestLoadGrammarRejectsInvalid      // malformed JSON → error
TestLoadGrammarRejectsMissingPort  // binding references port not declared on type → error (AddBindingType catches it)
```

`go test ./internal/cs/...` green.
Commit: `feat: cs.LoadGrammar — boot registry from grammar.json [wave:2-gate:2]`

---

### Gate 3 — Replace hardcoded demo with grammar-loaded registry

`demo/demo.go` currently builds a registry by hand in Go.
Replace with `cs.LoadGrammar("grammar.json")`. Adjust node/binding IDs to match grammar types.

**Gate test:** `go test ./internal/...` all green. `demo.go` compiles.
Commit: `refactor: demo uses LoadGrammar instead of hardcoded registry [wave:2-gate:3]`

---

## Wave 3: Seed Loader

### Gate 1 — Write `seed.json`

New file: `moos/platform/kernel/seed.json`

```json
{
  "version": "1",
  "nodes": [
    { "id": "user:sam",            "type": "user" },
    { "id": "agent:claude-code",   "type": "agent" },
    { "id": "agent:vscode-ai",     "type": "agent" },
    { "id": "agent:antigraviti",   "type": "agent" },
    { "id": "ws:hp-laptop",        "type": "workstation" },
    { "id": "kernel:hp-laptop",    "type": "kernel" }
  ],
  "properties": [
    { "node_id": "user:sam",          "name": "name", "value": "Sam" },
    { "node_id": "user:sam",          "name": "role", "value": "superadmin" },
    { "node_id": "agent:claude-code", "name": "kind", "value": "ide" },
    { "node_id": "agent:claude-code", "name": "transport", "value": "mcp-sse" },
    { "node_id": "agent:vscode-ai",   "name": "kind", "value": "ide" },
    { "node_id": "agent:vscode-ai",   "name": "transport", "value": "mcp-sse" },
    { "node_id": "agent:antigraviti", "name": "kind", "value": "ide" },
    { "node_id": "agent:antigraviti", "name": "transport", "value": "http" },
    { "node_id": "ws:hp-laptop",      "name": "hostname", "value": "hp-laptop" },
    { "node_id": "ws:hp-laptop",      "name": "os", "value": "windows" },
    { "node_id": "kernel:hp-laptop",  "name": "port", "value": "8000" }
  ],
  "bindings": [
    {
      "id": "governs:sam→claude-code",
      "kind": "governs",
      "incidences": [
        { "role": "governor", "node_id": "user:sam",          "port": "owns" },
        { "role": "subject",  "node_id": "agent:claude-code", "port": "governed-by" }
      ]
    },
    {
      "id": "governs:sam→vscode-ai",
      "kind": "governs",
      "incidences": [
        { "role": "governor", "node_id": "user:sam",        "port": "owns" },
        { "role": "subject",  "node_id": "agent:vscode-ai", "port": "governed-by" }
      ]
    },
    {
      "id": "governs:sam→antigraviti",
      "kind": "governs",
      "incidences": [
        { "role": "governor", "node_id": "user:sam",          "port": "owns" },
        { "role": "subject",  "node_id": "agent:antigraviti", "port": "governed-by" }
      ]
    },
    {
      "id": "runs-on:claude-code→hp-laptop",
      "kind": "runs-on",
      "incidences": [
        { "role": "agent",       "node_id": "agent:claude-code", "port": "runs-on" },
        { "role": "workstation", "node_id": "ws:hp-laptop",      "port": "owned-by" }
      ]
    },
    {
      "id": "runs-on:vscode-ai→hp-laptop",
      "kind": "runs-on",
      "incidences": [
        { "role": "agent",       "node_id": "agent:vscode-ai", "port": "runs-on" },
        { "role": "workstation", "node_id": "ws:hp-laptop",    "port": "owned-by" }
      ]
    },
    {
      "id": "runs-on:antigraviti→hp-laptop",
      "kind": "runs-on",
      "incidences": [
        { "role": "agent",       "node_id": "agent:antigraviti", "port": "runs-on" },
        { "role": "workstation", "node_id": "ws:hp-laptop",      "port": "owned-by" }
      ]
    },
    {
      "id": "hosted-by:kernel→hp-laptop",
      "kind": "hosted-by",
      "incidences": [
        { "role": "kernel",      "node_id": "kernel:hp-laptop", "port": "hosted-by" },
        { "role": "workstation", "node_id": "ws:hp-laptop",     "port": "hosts" }
      ]
    }
  ]
}
```

**Gate test:** File exists, valid JSON.
Commit: `chore: add seed.json — Sam hp-laptop initial graph [wave:3-gate:1]`

---

### Gate 2 — `hg.LoadSeed(registry, path) (*Store, error)`

New file: `hg/seed.go`

Reads `seed.json`, calls `AddNode` → `SetProperty` → `AddBinding` in that order. Returns a populated `*Store`. Zero new deps — stdlib `encoding/json` + `os` only.

**Gate tests** (`hg/seed_test.go`):
```go
TestLoadSeedRoundtrip              // load seed.json → store has 6 nodes, 7 bindings, correct properties
TestLoadSeedRejectsUnknownType     // node with type not in registry → error
TestLoadSeedRejectsInvalidProperty // property value violates enum → error
TestLoadSeedRejectsUnknownBinding  // binding kind not in registry → error
```

`go test ./internal/hg/...` green.
Commit: `feat: hg.LoadSeed — boot store from seed.json [wave:3-gate:2]`

---

### Gate 3 — Wire into `proof/` server boot

`proof/server.go` currently boots with an empty or hardcoded store. Replace with:

```go
registry, _ := cs.LoadGrammar("grammar.json")
store, _    := hg.LoadSeed(registry, "seed.json")
```

`GET /state` returns the 6 nodes + 7 bindings from seed.

**Gate test:** `go test ./internal/proof/...` green. Manual check: `go run .` boots without error, `curl localhost:8000/state` returns non-empty graph.
Commit: `feat: proof server boots from grammar.json + seed.json [wave:3-gate:3]`

---

## Wave 4: HTTP API

### Gate 1 — `GET /nodes` and `GET /bindings`

Add two read routes to `proof/server.go`:

```
GET /nodes     → JSON array of all nodes with their properties
GET /bindings  → JSON array of all bindings with their incidences
```

Response shapes:
```json
// GET /nodes
[
  {
    "id": "user:sam",
    "type": "user",
    "properties": { "name": "Sam", "role": "superadmin" }
  }
]

// GET /bindings
[
  {
    "id": "governs:sam→claude-code",
    "kind": "governs",
    "incidences": [
      { "role": "governor", "node_id": "user:sam",          "port": "owns" },
      { "role": "subject",  "node_id": "agent:claude-code", "port": "governed-by" }
    ]
  }
]
```

**Gate tests** (extend `proof/server_test.go`):
```go
TestGetNodesReturnsSeededGraph     // GET /nodes → 6 nodes, user:sam present with properties
TestGetBindingsReturnsSeededGraph  // GET /bindings → 7 bindings, governs:sam→claude-code present
```

`go test ./internal/proof/...` green.
Commit: `feat: GET /nodes + GET /bindings HTTP routes [wave:4-gate:1]`

---

### Gate 2 — `POST /morphisms` (ADD and LINK)

Single route, `"op"` field distinguishes morphism type:

```
POST /morphisms
Content-Type: application/json
```

```json
// ADD a node
{
  "op": "add_node",
  "node": { "id": "agent:new-agent", "type": "agent" },
  "properties": [
    { "name": "kind", "value": "process" }
  ]
}

// LINK two nodes
{
  "op": "add_binding",
  "binding": {
    "id": "governs:sam→new-agent",
    "kind": "governs",
    "incidences": [
      { "role": "governor", "node_id": "user:sam",        "port": "owns" },
      { "role": "subject",  "node_id": "agent:new-agent", "port": "governed-by" }
    ]
  }
}
```

Returns `201` on success, `400` with error message on validation failure.
Uses `rewrite.Apply` — clone-apply-replace, never direct mutation.

**Gate tests**:
```go
TestPostMorphismAddNode               // POST add_node → GET /nodes shows new node
TestPostMorphismAddBinding            // POST add_binding → GET /bindings shows new binding
TestPostMorphismRejectsUnknownType    // add_node with unknown type → 400
TestPostMorphismRejectsInvalidEnum    // add_node with bad property enum value → 400
TestPostMorphismRejectsUnknownNode    // add_binding referencing missing node → 400
```

`go test ./internal/proof/...` green.
Commit: `feat: POST /morphisms — add_node + add_binding with rewrite.Apply [wave:4-gate:2]`

---

### Gate 3 — `GET /grammar`

Expose the loaded grammar so the Explorer can render the type system:

```
GET /grammar → { "node_types": [...], "binding_kinds": [...] }
```

**Gate tests**:
```go
TestGetGrammarReturnsNodeTypes    // GET /grammar → contains "user", "agent", "workstation", "kernel"
TestGetGrammarReturnsBindingKinds // GET /grammar → contains "governs", "runs-on", "hosted-by"
```

`go test ./internal/...` green.
Commit: `feat: GET /grammar — expose type system via HTTP [wave:4-gate:3]`

---

## Wave 5: Explorer Rewire

The Explorer shell exists (`proof/static/explorer.html`, 327 lines, 6 sections). It currently
talks to `/api/state` and `/api/registry` which return Go-cased field names. The new endpoints
`/nodes`, `/bindings`, `/grammar` return snake_case JSON. Wave 5 rewires the Explorer to the
correct endpoints and tightens each render so the UI is actually useful.

**No new Go code in this wave. All changes are in `explorer.html` only.**
**Gate test for all gates: `go test ./internal/...` stays green (no Go changes = no regression).**

---

### Gate 1 — Rewire fetches to new endpoints

In the `refresh()` function, replace:
```js
// OLD
getJSON('/api/state')      → getJSON('/nodes')
getJSON('/api/registry')   → getJSON('/grammar')
// keep: getJSON('/api/rewrite/plans')
// keep: getJSON('/api/fiber?root=...')
```

Update `renderState(state)` → split into `renderNodes(nodes)` and `renderBindings(bindings)`:
- `/nodes` returns `[{ id, type, properties: {k:v} }]` — no separate properties list needed
- `/bindings` returns `[{ id, kind, incidences: [{role, node_id, port}] }]`
- Remove the separate "Local Properties" section — properties now inline on node cards

Update `renderRegistry(grammar)` to use `grammar.node_types` and `grammar.binding_kinds`
(snake_case) instead of `registry.node_types` / `registry.binding_types` (Go-cased).

Commit: `fix: rewire Explorer to /nodes + /bindings + /grammar endpoints [wave:5-gate:1]`

---

### Gate 2 — Node cards: type badge + inline properties

Each node card should show:

```
[agent]  agent:claude-code
         kind: ide   transport: mcp-sse
```

- Type shown as a small coloured badge (use `--accent` colour for the type label)
- Properties rendered as `key: value` pill pairs below the ID
- If no properties: show nothing extra (no empty placeholder)

The fiber root `<select>` still populates from the node list — keep that working.

Commit: `feat: Explorer node cards with type badge + inline properties [wave:5-gate:2]`

---

### Gate 3 — Binding cards: show roles clearly

Each binding card should show:

```
governs:sam→claude-code   [governs]
  governor  user:sam           owns →
  subject   agent:claude-code  ← governed-by
```

- Kind shown as badge
- Each incidence on its own line: `role  node_id  port`
- Port direction indicator: `→` for `out`, `←` for `in`, `↔` for `bidirectional`
  (port direction comes from `GET /grammar`, look up by node type + port name)

Commit: `feat: Explorer binding cards with role+port direction [wave:5-gate:3]`

---

### Gate 4 — Grammar section: ports + property specs

Grammar section currently broken (uses Go-cased field names). Fix and enrich:

Each node type card:
```
user
  ports:   owns →
  props:   name (string, required)
           role (enum: superadmin|admin|member, required)
```

Each binding kind card:
```
governs
  governor → user.owns
  subject  → agent.governed-by
```

Commit: `feat: Explorer grammar section renders ports + property specs [wave:5-gate:4]`

---

### Architecture rule for this wave

- No dropdowns for filtering/scoping — that was the old Explorer's mistake
- No SVG graph — cards only, clean information density
- Fiber section stays as-is (root select + depth=1 view is sufficient for now)
- Programs (rewrite plans) section stays as-is

---

## Wave 6: Nomenclature Rename — Binding → Relation

**Background (mandatory reading before starting):**
`.agent/kb/research/20260401-nomenclature-foundations.md`

Three-layer terminology is now locked:
- L1 Runtime (Wolfram): node, **relation**, rewrite rule, causal graph
- L2 Grammar (Spivak): port, wiring diagram, **operad** (= cs.Registry)
- L3 Compute (HDC/Kanerva): hypervector φ(x), **binding** ⊗ (HDC only!), bundling ⊕

**"binding" is reserved for HDC vector operations only. Graph hyperedges are "relations".**

This wave is a pure rename. Zero behavior change. All tests must stay green.

---

### Gate 1 — Rename in `model/types.go`

| Old | New |
|-----|-----|
| `BindingKind` | `RelationType` |
| `Binding` (struct) | `Relation` |
| `Binding.Kind` field | `Relation.RelationType` |
| `Binding.Incidences` field | `Relation.Incidences` (unchanged) |

**Gate test:** `go test ./internal/...` green.
Commit: `refactor: rename Binding→Relation, BindingKind→RelationType in model [wave:6-gate:1]`

---

### Gate 2 — Rename in `cs/registry.go`

| Old | New |
|-----|-----|
| `BindingSpec` | `RelationSpec` |
| `AddBindingType` | `AddRelationType` |
| `ValidateBinding` | `ValidateRelation` |
| `BindingSpec()` | `RelationSpec()` |
| `BindingSpecs()` | `RelationSpecs()` |
| `BindingKinds()` | `RelationTypes()` |
| `bindingTypes` (internal map) | `relationTypes` |

**Gate test:** `go test ./internal/cs/...` green.
Commit: `refactor: rename BindingSpec→RelationSpec across cs package [wave:6-gate:2]`

---

### Gate 3 — Rename in `hg/store.go`

| Old | New |
|-----|-----|
| `AddBinding` | `AddRelation` |
| `RemoveBinding` | `RemoveRelation` |
| `Binding(id)` | `Relation(id)` |
| `Bindings()` | `Relations()` |
| `ConnectedBindings` | `ConnectedRelations` |
| `bindings` (internal map) | `relations` |
| Error messages: "binding" | "relation" |

Also update `rewrite/plan.go`:
| `AddBindings` | `AddRelations` |
| `RemoveBindings` | `RemoveRelations` |

**Gate test:** `go test ./internal/...` green.
Commit: `refactor: rename Binding→Relation across hg and rewrite packages [wave:6-gate:3]`

---

### Gate 4 — Rename in JSON files + HTTP layer

**grammar.json:** `binding_kinds` → `relation_types`
Each entry: `"kind"` key → `"relation_type"` key

**seed.json:** `bindings` → `relations`
Each entry: `"kind"` key → `"relation_type"` key

**cs/grammar.go** (loader): update JSON field names to match
**hg/seed.go** (loader): update JSON field names to match

**proof/server.go:**
- `GET /bindings` stays as route (breaking API changes deferred)
- Internal variables: `binding*` → `relation*`
- Response struct `bindingResponse` → `relationResponse`
- JSON response key `"kind"` → `"relation_type"`

**Gate test:** `go test ./internal/...` green. `go run ./cmd/moos/` boots, `curl /relations` returns data.
Commit: `refactor: rename binding→relation in JSON files and HTTP layer [wave:6-gate:4]`

---

### Gate 5 — Update Explorer HTML

In `proof/static/explorer.html`:
- Section heading "Realized Bindings" → "Relations"
- Section heading "CS Grammar" → "Operad" (this is the correct CT term)
- JS: `binding.kind` → `relation.relation_type`
- JS: fetch `/bindings` → fetch `/relations` (after route rename above — do route rename in Gate 4)
- Any label "binding kind" → "relation type"

**Gate test:** `go test ./internal/...` green. Open Explorer — sections show "Relations" and "Operad".
Commit: `refactor: Explorer uses relation/operad nomenclature [wave:6-gate:5]`

---

### Notes for VS Code

- Use the skill `/moos-domain-expert` if in doubt about a naming decision
- The research doc at `.agent/kb/research/20260401-nomenclature-foundations.md` is authoritative
- "binding" in HDC context (harmony-hdc skill) is CORRECT — do not rename those
- "incidence" stays — it is the correct mathematical term (hypergraph incidence)
- "role" stays — correct term for the named slot in a relation
- After this wave: cs.Registry is the operad, model.Relation is the hyperedge, model.Node is the element

---

## Last Checkpoint

_T=150 — Wave 1 spec written by Claude Code. Starting Gate 1._
_T=150 — Wave 1 Gates 1-4 implemented locally. `go test ./internal/...` green; commit not created in this session._
_T=151 — Wave 2 spec written by Claude Code. Hand to VS Code._
_T=151 — Wave 2 Gates 1-3 implemented (grammar.json + cs.LoadGrammar + demo grammar boot). `go test ./internal/...` green._
_T=151 — Wave 3 spec written by Claude Code. Hand to VS Code._
_T=151 — Wave 3 Gates 1-3 implemented (seed.json + hg.LoadSeed + proof boot from grammar+seed). `go test ./internal/...` green._
_T=151 — Wave 4 Gates 1-3 implemented (GET /nodes, GET /bindings, POST /morphisms, GET /grammar). `go test ./internal/...` green._
_T=151 — Wave 4 spec written by Claude Code. Hand to VS Code._
_T=151 — Wave 5 spec written by Claude Code. Hand to VS Code._
_T=151 — Wave 5 Gates 1-4 implemented (Explorer rewired to /nodes, /bindings, /grammar with node badges/properties, role+direction binding cards, and grammar ports+property specs). `go test ./internal/...` green._
_T=151 — Wave 6 spec written by Claude Code (nomenclature: binding→relation, CS Grammar→operad). Hand to VS Code._
