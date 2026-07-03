---
agent: "moos-session-context-projection"
description: "Phase-4 spec (#58) for moos-config-projection — the F-direction generator that folds HG state into tool-config markdown (first artifact: the AGENTS.md seat/surface table, then the wider mirror set). The F leg of the F⊣G pair whose G leg is moos-workspace-ingest. Conjecture-marked design draft; authorizes no ontology/URN change."
---

# moos-config-projection — generating tool-config markdown FROM folded HG (#58 Phase-4)

> **STATUS UPDATE (T=244): Artifact A LANDED.** `config_projection.py` now implements
> `--mode write` (fenced region in `AGENTS.md`, first-adoption replaced the hand-authored
> seat table after the §6 acceptance test passed: semantic-equal fold, 11 rows via router
> fan-in incl. cross-kernel seats — Q1 resolved as router-read), byte-exact `--mode check`
> (blocking in `moos-round-close` step 0; warn-stage in `run-session-pipeline.ps1`;
> fence-integrity in CI `.github/workflows/config-drift.yml`), idempotent re-write, and a
> shrink-guard against partial fan-ins. Display enrichment: `dev/config/seat-display.json`
> (Q2 persona-nodes still open). Artifacts B/C remain future slices.
>
> **Original status: design draft (S0 → pending G-ingest). Conjecture-marked. GATE: prose/design only —
> this authorizes no ontology or URN change, applies no kernel rewrite, touches no secrets or
> `.vscode/mcp.json`.** Authored T231, Cowork-Z440, on the #58 Phase-4 lane. Reconciled against
> `AGENTS.md` (Phase-1 merged, PR #59), `run-session-pipeline.ps1` + its README +
> `session-pipeline-operator-manual.md`, the skill `moos-session-context-projection`,
> `dev/config/moos-federation.topology.json` + `session-affordance-map.json`, and the F⊣G framing in
> `20260620-t231-moos-soom.md` (§1, §5) and `20260620-t231-poly-foundations.md` (§3–§4).

## 0. One sentence
`moos-config-projection` is **F**: it folds the HG seat/surface topology and renders it as the
generated regions of the tool-config markdown set (`AGENTS.md` first), so those files stop being
hand-authored. It is the exact mirror of **G = `moos-workspace-ingest`** (the chunker that lifts
surface artifacts back into HG); together they are the `F ⊣ G` pair the system already runs, now
closed at the config-projection end.

## 1. Goal — replace hand-authoring of the seat table, then the mirror set

`AGENTS.md` already declares (line 4, line 29–30) that the **Seats table is the "Phase-4
moos-config-projection pilot"** and "the lowest F⊣G unit defect, highest duplication payoff → first
artifact `moos-config-projection` will generate." This spec makes that concrete.

**Why the seat table first (lowest projection defect).** The seat/surface table is a pure function
of a small, stable set of node-types and relations (agent · session/workspace · kernel/instance ·
purpose · channel + a handful of WF01/WF02/WF19 relations). Every row is mechanically derivable; the
hand-authored table is *already* a manual F-image that drifts (the AGENTS.md note: "If this table and
live `/healthz`+HG readback disagree, the readback wins"). Generating it removes the drift class
entirely — the table becomes a fold, not a transcription.

**Sequenced scope (this spec covers the whole arc, ships the first slice):**

1. **Artifact A — the `AGENTS.md` seat/surface table** (the `## Seats` block). First and only
   *write* target of the initial slice.
2. **Artifact B — the relational-spine block + the network/federation facts** (`AGENTS.md` §
   "Relational spine", "Network / federation") — same node/relation source, also fully derivable.
   Second slice.
3. **Artifact C — the wider mirror set**: the seat/surface regions of the mirrors that restate it —
   `CLAUDE.md` (×2), `.github/copilot-instructions.md`, `ANTIGRAVITY.md`. These currently carry a
   manual header ("source · manual/generated · source-commit") per AGENTS.md "Tool-mirror map"; the
   projection flips the `manual` flag to `generated` for the regions it owns. Third slice.

**Non-goals (stay hand-authored / out of scope):** doctrine prose (the rule, SOT hierarchy,
design-doc discipline, safety) — that is authored judgement, not a fold of topology. The projection
owns *only* the mechanically-derivable regions and never touches the prose around them.

## 2. Inputs — the folded node-types + relations that feed F

Read from the running kernel (or the federation router) over the same HTTP JSON surface the existing
adapters use — `GET /state/nodes` and `GET /state/relations` (the `run-session-pipeline.ps1`
adapters already read folded state this way; `Test-MoosNodeExists` in that script hits
`/state/nodes/<urn>`). **Conjecture (router path):** when the projection must span both kernels
(Z440 + hp-laptop seats both appear in the one table), read through the federation router fan-in
(`http://localhost:9000`) exactly as `run-session-pipeline.ps1` already conditionally does for the
`z440-vscode-projection-lead` session (lines 100–102). Single-kernel runs read `:8000` directly.

**Node-types consumed** (all already in the ontology, v3.16.2; alias-first 4.0 names in parens):

| Node type | Role in the seat table |
|---|---|
| `agent` | the principal of a row (the row key) |
| `session` (workspace, D2) | the Workspace column |
| `kernel` (instance, D6) | the Instance column + its `:port` |
| `workstation` | the host/surface grouping (Z440 / laptop / ProDesk) |
| `channel` | the Surface / IDE-instance column (D7/D8 surface, `channel.kind`) |
| `purpose` | the input to the Persona column via `persona = Φ(purpose)` (D3) |
| `user` / `group` | the authority head of the delegation chain (provenance, not a column) |

**Relations consumed** (canonical port names verified against `ontology.json`):

| Relation (port / inverse) | WF | What the row reads from it |
|---|---|---|
| `owns` / `owned-by` | WF01 | authority head: `user`/`group` → `agent`/`session` (provenance) |
| `delegates-to` / `delegated-by` | WF02 | delegation chain `user/group → agent` (who may emit) |
| `has-occupant` / `is-occupant-of` | WF19 | **the row generator** — one row per occupied workspace (single-valued, D22.2) |
| `opens-on` | WF19 | topology intent: which `kernel`/instance the workspace opens on (`:port`) |
| `has-purpose` / `purpose-of-session` | WF19 | the `purpose` feeding `Φ(purpose)` → Persona |
| `presents-as` (agent↔persona) | D4 (endorsed #57) | explicit persona presentation when present, else derive via `has-purpose` |
| `realizes` / `realized-by` (surface↔channel/workspace) | D8 (endorsed #57) | the Surface/IDE column when the D7 surface layer is modelled |

**Crucial input distinction — emit-target vs opens-on (the §M9 split).** The topology config and
`session-affordance-map.json` both encode that `opens-on` is *topology metadata* and `emit_kernel`
is the *current receiving-kernel reality* until twin sync lands. The projection MUST render both
faithfully and NOT collapse them: a Z440 twin seat (Steinberger/Karpathy) opens-on `:8001`/`:8002`
but emits to `:8000` — exactly as the current hand-authored table shows ("emits :8000 pre-§M9").
This is a guardrail, not a column choice (see §3, MCP column).

**Config side-inputs (planning facts, NOT HG truth).** `moos-federation.topology.json` and
`session-affordance-map.json` are projection *configs* — the operator manual is explicit that they
"do not replace folded HG state." **Decision (conjecture):** the projection's authority spine is HG
(`/state/*`); the configs may supply *display-only* enrichment that HG does not yet carry (e.g. the
human-readable Persona name "Wolfram" if no `persona` node exists, the LAN/Tailscale IPs in the
network block). Any field sourced from config-not-HG is tagged in the row provenance so the drift
check (§4) does not false-positive against HG. **Open question Q2** covers whether persona names
should instead be first-class `persona` nodes so the table is 100% HG-derived.

## 3. The projection function — how one seat ROW is folded

The fold is a left fold over the `has-occupant` relation set. **One row per `has-occupant` edge**
(its single-valued, rotatable semantics — D22.2 — guarantees at most one occupant per workspace, so
the row set is well-defined and stable).

```
seatRows = sort_by(rowKey,
  for each r in relations.filter(port == "has-occupant"):
    let ws       = r.src        # session (workspace)
    let agent    = r.tgt        # agent | user | group  (the row principal)
    Row {
      persona  = Φ( purposeOf(ws) ),                 # D3 derivation (see below)
      agent    = agent.urn → alias,
      workspace= ws.urn → alias  (D2),
      instance = opensOnOf(ws) → kernel.urn + ":" + portOf(kernel)   (D6),
      surface  = surfaceOf(agent, ws),               # realizes/channel.kind (D7/D8)
      mcp      = mcpOf(emitKernelOf(ws | agent))     # :8080 etc, + opens-on MCP note
    }
)
```

Column-by-column derivation:

- **Persona = Φ(purpose) (D3).** Resolve in priority order: (1) an explicit `presents-as` relation
  agent→persona, else (2) `Φ(has-purpose(ws))` — the derivation that maps the workspace's purpose to
  its persona view. **Conjecture:** if neither a `persona` node nor `presents-as` exists yet, fall
  back to a config-supplied display label (tagged config-sourced per §2). Φ is a *derivation*, never
  authority (D3) — the column is presentation only.
- **Agent (principal).** The `has-occupant` target. Rendered as the 4.0 alias with the canonical URN
  retained in machine output (JSON sidecar) so the Gate's "URNs stay canonical" rule holds.
- **Workspace ⟵ session (D2).** The `has-occupant` source, alias-first.
- **Instance ⟵ kernel (D6).** Follow `opens-on` from the workspace to its kernel; append the
  kernel's HTTP `:port` (from the kernel node's properties / topology config). For twins, render the
  opens-on port and annotate the emit port — never silently merge them (§2 guardrail).
- **Surface / IDE-instance (D7).** If the D7/D8 surface layer is modelled, read `realizes`/
  `realized-by` to the `channel` whose `channel.kind ∈ {harness-pane, window, …}`. Until then,
  config-supplied surface label, tagged.
- **MCP.** The emit-kernel's MCP endpoint (`:8080`), plus the twin's `opens-on` MCP note
  (`:9001`/`:9002`) where applicable — the exact two-value shape the current table already shows.

**Ordering / determinism:** rows sorted by a stable key — **conjecture:** `(workstation-host,
instance-port, workspace-urn)` reproduces the current table's host-grouped Z440-then-laptop-then-
ProDesk order. The sort key is part of the spec because byte-identical output (§4) requires a total
order independent of HG iteration order.

**Dormant/idle seats.** `sam.mvp-delivery` is occupant-less (`has-occupant` UNLINKed T=219) — with
no `has-occupant` edge it produces **no row**, which is exactly the current table's "intentionally
omitted" behaviour. Scoped-idle sessions in `session-affordance-map.json` (`actor_urn: ""`) likewise
generate no row. **This falls out of the fold for free** — the projection does not special-case it,
which is the correctness argument for keying on `has-occupant`.

## 4. Idempotence + the DRIFT CHECK (the round-close / CI gate)

**Idempotent re-runs.** Same folded HG ⇒ byte-identical generated block. Requirements:
- the total sort order of §3 (no reliance on map/iteration order);
- canonical alias rendering (a single alias table, not ad-hoc abbreviation);
- normalized whitespace + a fixed column layout (render through one table-emitter, not string
  concatenation);
- **no timestamps / run-ids inside the generated block** (those belong in the sidecar, not the
  committed markdown), so two runs at the same log prefix diff to nothing.

This mirrors the Calendar writer's idempotence (`moos_projection_id` upsert) and the operator
manual's reconciliation discipline: a re-projection is a *patch to byte-equality*, never an append.

**The drift check (`--check` mode).** A second mode that does NOT write. It:
1. folds the current seat table from HG (the §3 function);
2. extracts the committed generated block from `AGENTS.md` (delimited region, §5);
3. diffs them.
- **Equal ⇒ exit 0** (gate pass).
- **Diverged ⇒ exit non-zero**, printing the unified diff and a verdict line naming whether HG or the
  committed file is ahead.

**Direction of authority on failure.** Per the AGENTS.md Gate ("the readback wins — re-read, don't
force the table"), the *resolution* is regenerate-from-HG, not edit-the-markdown-by-hand. The gate
failing means "someone hand-edited a generated region, or HG advanced and the file was not
re-projected" — both fixed by re-running write mode. **Caveat (conjecture):** the check must compare
only the *generated* region, not config-sourced display fields that HG cannot adjudicate (§2) — those
are excluded from the diff or compared against the config, not HG, to avoid false fails.

**Where the gate runs:** (a) in `run-session-pipeline.ps1` as a non-fatal `warn` stage during normal
operator runs (surfaces drift without blocking the dry pipeline); (b) as a **blocking** check in the
`moos-round-close` flow and/or a CI Action on `AGENTS.md` changes, so a round cannot close with a
drifted seat table. This is the natural home: round-close already owns the running-state-vs-HG
consistency gate (`moos-running-state-validator`); seat-table-vs-HG is the same class of check.

## 5. Pipeline slot + write target (delimited block vs generated file)

**New pipeline stage.** Add one `Invoke-Step` to `run-session-pipeline.ps1`, after the session
context pack and before/with the MVP gate. Two sub-modes driven by a param:

```
Invoke-Step "Config projection (seat table)" {
    & $Julia "dev\scripts\config_projection.jl" `
        "--base-url" $ProjectionBaseUrl `
        "--target"   "AGENTS.md" `
        "--mode"     "check"        # default in the pipeline = non-mutating drift check
}
```

- **Default in the operator pipeline: `--mode check`** — dry, emits a gate row, writes nothing into
  the repo (consistent with the pipeline's "dry by default; do not commit generated artifacts"
  boundary). It may write its *evidence* under `tmp/projections/session_pipeline/config/`
  (folded table JSON + diff) like every other stage.
- **`--mode write`** — the explicit boundary act (like `google_calendar_writer.jl --mode write`):
  regenerates the delimited region in `AGENTS.md` in place. Run deliberately, reviewed, then
  committed. Keeps planner/writer separated exactly as the skill guardrail requires.

**Write target — delimited generated block inside `AGENTS.md` (NOT a fully-generated file).**
Decision: a **delimited region** wins for Artifacts A/B because `AGENTS.md` interleaves generated
topology with hand-authored doctrine; a wholesale generated file would force splitting doctrine out.
Use HTML-comment fences the markdown renderers ignore:

```markdown
<!-- BEGIN GENERATED: moos-config-projection seat-table v1 (source: HG /state, do not hand-edit) -->
| Persona (=Φ(purpose), D3) | Agent (principal) | Workspace ⟵session (D2) | … |
| … generated rows … |
<!-- END GENERATED: moos-config-projection seat-table -->
```

The writer replaces only the bytes between the fences; everything outside is untouched. The drift
check reads the same fences. **Mirror set (Artifact C):** same fenced-region technique inside each
mirror, and the projection flips that region's header flag from `manual` to `generated`. **Conjecture:**
a *fully*-generated standalone file (e.g. `dev/config/seats.generated.md`) that the mirrors `@import`
or transclude would be cleaner long-term (single source, zero fence-management), but mo:os mirrors are
read *natively* by heterogeneous tools (Copilot, Antigravity, Cursor) that do not all support
transclusion — so the in-place fenced block is the portable choice for now. Revisit when/if a
transclusion mechanism is standardized (Q4).

## 6. Phase sequencing vs #58 Phases 2/3/5 — and restore-now-vs-wait

`AGENTS.md` line 4 lists Phase-2 as "mirror-body trim, `.claude/rules/`, Antigravity surface,
`moos-config-projection`." So `moos-config-projection` is *named in Phase-2's scope* but is the
*Phase-4* generator. Reconciliation of the sequence (conjecture where the #58 phase list is not
verbatim in the read material):

- **Phase-2 (mirror trim / `.claude/rules/` / Antigravity surface):** prepares the *targets* — it
  decides which regions of which mirrors are projection-owned. **This must land first**: the
  projection needs stable fence locations to write into. Trimming mirror bodies before the generator
  exists is safe because the generator will re-fill the owned regions.
- **Phase-3 (assumed: the D7/D8 surface-layer reification — `realizes`/`channel.kind` surfaces):**
  is the input the Surface column wants. **Sequencing decision:** do NOT block Phase-4 on Phase-3.
  Ship the seat table now with the Surface/MCP columns sourced from config (tagged, §2); upgrade
  those columns to HG-sourced `realizes` reads when Phase-3 lands. The fold function is written so
  the surface resolver is a single swappable step.
- **Phase-4 (this spec):** the generator itself, shipped in the slice order of §1 (Artifact A → B →
  C). Artifact A is shippable against *today's* HG (agent/session/kernel/purpose + WF01/02/19 all
  exist at v3.16.2) — no ontology bump required.
- **Phase-5 (assumed: the 4.0 vocab hard-cut / URN rewrite, gated to 4.0.x):** the projection
  *consumes* the alias-vs-URN split but does not depend on the hard URN rewrite. Because the
  generated block renders aliases for humans and keeps canonical URNs in the sidecar, the same
  generator survives the 4.0.x URN rewrite with only its alias table updated.

**Restore-now-vs-wait decision.** **Recommendation: ship `--mode check` (drift gate) now; defer
`--mode write` (auto-regeneration of the committed table) until Phase-2 fence placement lands.**
Rationale: the check is pure read + diff against the existing hand-authored table — zero risk, and it
*immediately* starts catching seat-table drift (the highest-payoff defect the AGENTS.md note flags).
The write mode mutates a merged, governance-approved file (`AGENTS.md` Phase-1 is APPROVED on PR #59),
so it should wait for fences to exist and for one reviewed write to confirm byte-equality with the
current hand-authored table (proving the fold is faithful before it takes over authorship).
Conjecture: that first reviewed write is itself the acceptance test — "generate, diff against the
hand-authored table, expect empty diff."

## 7. Conjectures vs settled

- **Settled (grounded in read material / ontology):** F⊣G framing with F=`moos-config-projection`,
  G=`moos-workspace-ingest` (`moos-soom` §1, `poly-foundations` §4); `/state/nodes` + `/state/relations`
  read path (existing adapters); the relation/port names + WFs (verified in `ontology.json`);
  `has-occupant` single-valued D22.2 → one row per edge; emit-target vs opens-on §M9 split (topology
  config + affordance map); planner/writer separation + idempotent-upsert discipline (operator
  manual, Calendar writer); the seat table as the named Phase-4 pilot (`AGENTS.md` line 29).
- **Conjecture (governance-gated, not applied):** router-vs-direct read path for cross-kernel spans;
  config-supplied display fields (persona names, IPs) as tagged non-HG enrichment; the
  `(host, port, workspace-urn)` sort key reproducing current order; the fenced-block-vs-standalone-file
  choice; the assumed content of #58 Phases 3/5; Φ falling back to config labels when no `persona`
  node exists; the first reviewed write as the acceptance test.

## 8. Open questions

1. **Cross-kernel read authority:** does the seat table fold from the **router** fan-in (one read,
   both hosts) or from per-kernel reads merged client-side? The router gives one consistent prefix;
   per-kernel reads can skew if one kernel is mid-rewrite. (Relates to the §M9 twin-sync gap.)
2. **Persona as HG node vs derivation-only:** should the human persona names (Wolfram, Steinberger,
   Karpathy, Guido…) become first-class `persona` nodes (making the Persona column 100% HG-derived
   and drift-checkable), or stay `Φ(purpose)` derivations with config-supplied display labels? This
   decides whether the Persona column is inside or outside the drift check (§4).
3. **Drift-check granularity in CI:** block on *any* byte difference, or only on semantic difference
   (ignore alias-table/cosmetic churn)? Byte-exact is simplest and matches idempotence; semantic
   tolerance avoids noisy fails when only the alias table is bumped.
4. **Fenced block vs transclusion for the mirror set:** is there (or should there be) a portable
   transclusion mechanism so the mirrors share one generated seat-table source instead of each
   carrying its own fenced copy — given the mirrors are read natively by Copilot / Antigravity /
   Cursor with differing include support?

---
*S0 design draft — not HG truth until G-ingested. No ontology/URN change authorized.*
authored-by: agent:claude-cowork.hp-z440 / session:sam.z440-cowork-workspace / config-projection
