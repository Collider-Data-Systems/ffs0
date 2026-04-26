# Round-15 Guido claim staging

**Status**: staged (NOT fired). 4-envelope atomic batch awaiting fire signal.

## What lands when fired

Atomic POST to `kernel:hp-laptop.primary` `:8000` `/programs` (or via `mcp__moos-kernel__apply_program` / `Test-MoosFederation.ps1 -Mode PostProgram`):

| seq+N | rewrite | URN |
|---|---|---|
| ADD #1 | knowledge_item | `urn:moos:ki:spec.section-09-governance-and-audit` (umbrella for §9 chapter) |
| ADD #2 | claim | `urn:moos:claim:guido.invariant-bracketing-discipline` (§9.4.1) |
| ADD #3 | claim | `urn:moos:claim:guido.topology-degenerate-vs-federated` (§9.4.3) |
| ADD #4 | claim | `urn:moos:claim:guido.scaffolding-on-emission-not-reasoning` (§9.4.2 + cited by §0 + §1) |

Plus 4 kernel-emitted §M13 self-MUTATEs ticking `session:sam.governance.local_t` once per envelope (per the post-PR-#33 §M13 path; one tick per acknowledged rewrite).

## Why staged (not fired now)

Per `ffs0#42` round-15 Track 3 + Sam's choice. The claim ADDs themselves don't structurally require WF21 — the `claim` type is already operadic in v3.13/v3.14, and `source_ki_urn` is just a urn-typed property. **What requires WF21**: structural `consumes` / `caused-by` LINKs that lift the textual evidence cited in `stochastic_weights.consumes_anchors` on `derivation:guido.section-09-governance-and-audit` into first-class HG edges from the claims back to their predecessor derivations.

Decoupling shape:
- **Phase 1 (this staging)**: 4 ADDs land structurally; cross-references stay property-form.
- **Phase 2 (post-WF21)**: a follow-on batch fires `LINK claim.* --caused-by--> derivation:guido.section-09-governance-and-audit` for each of the 3 claims; lifts citation graph from property-form to topology-form per §9.4.4 transitional-citation-surface doctrine.

## Fire instructions

```powershell
# Option A — via Steinberger's harness (preflight gate + receiving-kernel verify)
cd C:\Users\maass\HPlaptop\ffs0
.\dev\scripts\ops\Test-MoosFederation.ps1 -Mode PostProgram `
    -Persona guido `
    -Payload .\dev\scripts\ops\r15-guido-claims.json
```

```powershell
# Option B — direct curl (skips harness preflight; use only if harness has runtime issue)
$body = Get-Content .\dev\scripts\ops\r15-guido-claims.json -Raw
Invoke-RestMethod -Uri http://localhost:8000/programs `
    -Method POST -Body $body -ContentType "application/json"
```

## Pre-fire verification (sanity)

```powershell
# Confirm hp-laptop kernel up + on v3.14
Invoke-RestMethod http://localhost:8000/healthz

# Confirm Guido seat occupant intact (§M11 will gate against this)
Invoke-RestMethod http://localhost:8000/state/relations/src/urn:moos:session:sam.governance |
  Where-Object { $_.src_port -eq "has-occupant" }

# Confirm derivation:guido.section-09-governance-and-audit exists (cited indirectly via §9 chapter)
Invoke-RestMethod http://localhost:8000/state/nodes/urn:moos:derivation:guido.section-09-governance-and-audit
```

## Post-fire verification

```powershell
# log_len delta = 4 (atomic) + 4 kernel-emitted MUTATEs on governance.local_t = +8 to log
Invoke-RestMethod http://localhost:8000/healthz

# Each claim resolves
foreach ($c in 'guido.invariant-bracketing-discipline', 'guido.topology-degenerate-vs-federated', 'guido.scaffolding-on-emission-not-reasoning') {
    Invoke-RestMethod "http://localhost:8000/state/nodes/urn:moos:claim:$c"
}

# governance.local_t walked +4 (4 explicit-session-urn ticks per the §M13 path)
(Invoke-RestMethod http://localhost:8000/state/nodes/urn:moos:session:sam.governance).properties.local_t.value
```

## Round-15 follow-on (Phase 2 — post-WF21)

Once `v314-3-wf21-causes` promotes:

```json
[
  {"rewrite_type": "LINK", "rewrite_category": "WF21",
   "src_urn": "urn:moos:claim:guido.invariant-bracketing-discipline",
   "src_port": "caused-by",
   "tgt_urn": "urn:moos:derivation:guido.section-09-governance-and-audit",
   "tgt_port": "causes",
   "actor": "urn:moos:agent:claude-code.hp-laptop",
   "session_urn": "urn:moos:session:sam.governance",
   "relation_urn": "urn:moos:rel:claim.guido.invariant-bracketing-discipline.caused-by.derivation.guido.section-09"},
  // ... topology-degenerate-vs-federated
  // ... scaffolding-on-emission-not-reasoning
]
```

The `claim --tagged--> ?` outbound port pair (per claim type's `ports.out: ["tagged"]`) becomes the connecting edge for downstream uses (e.g. tagging specific proofs that consume each claim).

## Doctrinal citations

- §9.4.1 Invariant-bracketing discipline (master): `kb/research/spec/09-governance-and-audit.md#941`
- §9.4.2 Scaffolding-on-emission-not-reasoning: `#942`
- §9.4.3 Topology-degenerate-vs-federated distinction: `#943`
- §9.4.4 stochastic_weights as transitional citation surface (doctrinal pre-condition): `#944`

Round vehicle: `ffs0#42`.

— Guido, `session:sam.governance`, `kernel:hp-laptop.primary`
