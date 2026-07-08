# T=249 — Guido lane: identity-projection tooling note

> **Lane:** Guido / `session:sam.laptop-vscode-lead` (identity-relations commission, t248 plan §4 — "the projection").
> **GATE (prose-only):** NO ontology change, NO URN change, NO HG rewrite. PR-route for code/config.
> **Contract:** ffs0#131 (rebase discipline, lane claim posted).
> **Sources:** live fold readback t_day 249 (hp-laptop :8000 + Z440 :8000) · `dev/config/seat-display.json` ·
> `config_projection.py` · `Test-MoosFederation.ps1` VerifyPersona · `moos-kernel/internal/operad/loader.go`
> + `validate.go` + `loader_port_pairs_test.go`.

## §1 — G7: purpose-wiring inventory (Φ inputs per seat)

Persona = Φ(purpose): the config join derives persona display-name from purpose URN via a naming
convention. For Φ to be mechanically computable, a session must have a durable `has-purpose` WF19
relation. Readback of both sovereign primary folds (T=249):

### Z440 primary (:8000) — has-purpose present

| Session | Purpose URN | Persona (config) |
|---|---|---|
| `sam.moos-diary` | `purpose:sam.multimodal-curation-and-diary` | Moos / AG-Z440 |
| `sam.steinberger-seat` | `purpose:sam.tooling-ergonomics-and-dx` | Steinberger |
| `sam.z440-primary-vscode-setup` | `purpose:sam.z440-primary-kernel-setup-and-readback` | Z440 VS Code lead |
| `sam.kernel-proper` | `purpose:sam.kernel-implementation-z440` | Wolfram |
| `sam.z440-cowork-workspace` | `purpose:sam.cowork-workspace-curation` | Zappa |
| `sam.karpathy-seat` | `purpose:sam.compiler-lowering` | Karpathy |
| `sam.z440-vscode-projection-lead` | `purpose:sam.z440-vscode-projection-lead-operations` | Z440 VS Code lead |

### hp-laptop primary (:8000) — has-purpose present

| Session | Purpose URN | Persona (config) |
|---|---|---|
| `sam.laptop-cowork-workspace` | `purpose:sam.workspace-ingest-laptop` | John Lydon (governance) |
| `sam.laptop-moos-diary` | `purpose:sam.laptop-diary-curation` | AG-laptop |
| `sam.laptop-vscode-lead` | `purpose:sam.laptop-vscode-lead-operations` | Guido |
| `sam.hpprodesk-setup` | `purpose:sam.hpprodesk-workstation-bootstrap` | HP ProDesk |
| `sam.governance` | `purpose:sam.doctrine-governance-and-delegation` | John Lydon |

### Seats with NO `has-purpose` on their receiving fold

| Persona key | Session | Missing purpose | Status |
|---|---|---|---|
| *(none found)* | — | — | All active seats with persona keys have `has-purpose` wired |

**Finding: G7 is CLOSED for the active 12-seat table.** Every session in the seat table that carries
a persona key has a durable `has-purpose` on its receiving fold. The 5 T200+ scoped-idle lanes also
carry purposes. The Φ join is therefore mechanically computable *right now* for all 7 band members
with seat-display entries.

### Φ computation path (current vs. post-G1)

Today: `config_projection.py` reads `seat-display.json[agent_urn].persona` (config, keyed by agent).
Post-G1: `session --has-purpose--> purpose`, then derive persona display-name from purpose's
`name`/`slug` property or a future `derivation:persona.*` node if D4 lands. The seat-table columns
`Persona` and `Surface` are currently tagged `(config)` and sourced from `seat-display.json`.
Retirement of those columns requires a HG-derivable persona + a surface-realization path (D8).

## §2 — Config-projection readiness: retire the two config columns

**Persona column retirement (post-G1):**
- Precondition: every agent's presenting persona is derivable from HG. Verified: all agents' sessions have `has-purpose`. What's missing: the naming join — purpose node has no `display_name` property today; the slug IS the name by convention (e.g. `sam.cowork-workspace-curation` → "Zappa" is a *creative* name, not derivable from the purpose slug alone).
- Two paths: (A) stay config forever (persona IS a display alias, not graph data), or (B) add a `display_name` property to purpose nodes (mutable, owner-scoped — a MUTATE path per G6b's pattern). Path B requires the WF20 round.
- **Recommendation:** retire the Persona column to a HG-derivable form **only if G1 decides persona IS a graph entity** (D4 `presents-as` landing). If G1 rules "config-forever", the column stays and `seat-display.json` is the durable home — no retirement needed, only a formal "Q2-persona-nodes: RETIRED" declaration.

**Surface column retirement (D8 `realizes`):**
- Deferred to 4.0.x per D8 status. Observation: surfaces are inherently workstation-local and session-ephemeral; graph-reifying every window/tab/pane is overhead with no demonstrated consumer. Recommend D8 stays config/observed-only forever unless a concrete G-ingest consumer appears.

## §3 — VerifyPersona extension: per-fold checks (twins)

Current `Test-Persona` checks: emit-kernel health, opens-on topology, actor/session declarations,
MCP reachability, session-on-receiving-kernel node exists, `has-occupant` and `opens-on` relations
present on the receiving fold, and target-kernel healthz.

**Extension plan (PR-routed code change in `Test-MoosFederation.ps1`):**

1. **`has-purpose` check** — verify the session's `has-purpose` relation exists on the receiving fold (new row in the VerifyPersona table). Trivial addition: filter `$relations` for `src_port -eq 'has-purpose'`.
2. **Twin-fold readback** — for personae whose `opens_on_kernel` differs from `emit_kernel` (Steinberger, Karpathy), issue a supplementary healthz check against the opens-on URL and flag whether the twin is reachable + on which ontology version. This does NOT check seat-topology on the twin (R2 birth workspaces haven't landed).
3. **Post-R2 future:** once twins get birth workspaces (§4 of Lydon's note), `VerifyPersona` can additionally check user-existence + governs + session on the twin fold. Gated on R2 batch application.

## §4 — G5: loader-gap verification — RESOLVED

The t248 plan G5 states: "Whether the loader caught up is a code readback, not a doc question."
Code readback performed:

- `moos-kernel/internal/operad/loader.go:76-96` — `LoadRegistry` iterates `wf.AdditionalPortPairs` (the `additional_port_pairs` JSON field) and builds `AdditionalPortPair` structs with `SrcPort`, `TgtPort`, `SrcTypes`, `TgtTypes` per pair.
- `moos-kernel/internal/operad/validate.go:34,63,86-91` — `ValidateLINK` consults `wfSpec.AdditionalPortPairs` for pair-level type enforcement.
- `moos-kernel/internal/operad/loader_port_pairs_test.go` — dedicated test covering v3.10+ port-pair loading (WF19 has-occupant, has-purpose, pins-urn; WF07 anchors/anchor; src_types/tgt_types).
- `moos-kernel/internal/operad/validate_link_pair_test.go` — pair-specific type enforcement tests.
- Live evidence: `ffs0/dev/tools/moos-lsp` pair-type diagnostics (PR #111) match the kernel's enforcement — both consume the same ontology field.

**Verdict: the loader IS current.** `additional_port_pairs` has been consumed since v3.10 (the PR history shows `loader_port_pairs_test.go` landed with PR #26, T=171). G5 gap is **non-existent** — the t248 plan's concern was valid at the time of writing (citing v3.12 behavior) but the implementation has since landed. No Wolfram work needed.

**Residual (documentation):** the WF19 entry in `ontology.json` still carries a comment block listing `port_color_compatibility` pairs (claims-session, transfers-to) that are NOT declared in `additional_port_pairs` and therefore NOT loaded or validated. These are either legacy/dead (never emitted) or deferred-future. A doc sweep (flag or remove them) is low-priority hygiene, not a loader bug.

## §5 — Deliverables summary

| # | Deliverable | Target | Status |
|---|---|---|---|
| 1 | This tooling note | ffs0 PR (this branch) | done |
| 2 | `has-purpose` check in VerifyPersona | ffs0 PR (code, same branch) | ready |
| 3 | Twin-fold healthz in VerifyPersona | ffs0 PR (code, same branch) | ready |
| 4 | G5 loader-gap issue for Wolfram | **NOT NEEDED** — gap resolved | closed-at-plan |
| 5 | Lane claim on ffs0#131 | issue comment | done |

---
authored-by: urn:moos:agent:vscode.hp-laptop.copilot / urn:moos:session:sam.laptop-vscode-lead / t249-identity-projection
workstation: urn:moos:workstation:hp-laptop
channel-kind: harness-pane
