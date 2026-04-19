# mo:os — running state

> Hydration entrypoint. Read this first in any new conversation.
> Updated: **T=169 (April 19, 2026)** — round 9 kernel work: 7 PRs merged to master (predicate evaluator, introspection + batch endpoints, sweep loop with WF13 proposals, session-occupancy helpers with v3.10 ontology bump, t-cone endpoint, 4 extended §M14 predicate kinds, plus review-followups). T=169 closed out the in-source TODOs: shared `internal/tday` package + `NodesByType`/`Relations{Src,Tgt}` indexes on GraphState.

---

## Active program

| | |
|--|--|
| Program | `urn:moos:program:sam.t187-kernel-proper` |
| Title | T=187: kernel proper — session-as-actor, twin kernels, gates, admin governance |
| Current T-day | **T=169 (April 19, 2026)** |
| Status | active (hook-predicates sub-program shipped; sweep + t-cone + session-occupancy landed) |
| Canonical spec | `kb/research/kernel/20260417-t187-kernel-proper.md` (M1..M10 + T=168 appendix §M11..§M17) |
| Session model (ratified) | `kb/research/session/20260418-t168-session-kernel-bound.md` |

T=164 `sam.t164-room-tying` closed at T=167: status → completed.
Succession recorded: `t164 --WF18 scheduled-after--> t187`.

## Current kernel occupancy

Sessions are **permanent kernel-bound nodes** (§M11). The session layer is **group topology** (§M21): `Sessions = ⊔_k Sessions_k`, stratified by kernel. Exactly one session per kernel is WF19-LINKed and live; `seat_role=occupier` on the kernel the agent is driving, `seat_role=observer` on the others.

URN convention (T=168 round 4 merge): **no T-day segment**. `urn:moos:session:<user>.<agent>-<kernel-short>`. Historical `.t164 / .t167 / .t168` nodes are archived (WF19 UNLINKed, kept in HG as provenance).

| Session URN | Kernel | `seat_role` | `local_t` |
|-------------|--------|-------------|-----------|
| `urn:moos:session:sam.claude-code-hp-laptop` | `urn:moos:kernel:hp-laptop.primary` | **occupier** | 0 (fresh) |
| `urn:moos:session:sam.claude-code-hp-z440` | `urn:moos:kernel:hp-z440.primary` | observer | 0 |

### Historical sessions (archived, no WF19 LINK, retained for provenance)

- `sam.claude-code-hp-laptop.t164` — merged into `sam.claude-code-hp-laptop`
- `sam.claude-code-hp-laptop.t167` — merged into `sam.claude-code-hp-laptop`
- `sam.claude-code-hp-z440.t168` — merged into `sam.claude-code-hp-z440`

### Session property redundancy cleanup (v3.9)

Two session properties are marked `deprecated: true` (scheduled for removal in v3.10):
- `session.status` (active/closed/abandoned) — subsumed by `seat_role` + permanent-session model.
- `session.turn_count` — subsumed by `local_t` (§M13 kernel-maintained heartbeat).

New merged sessions are ADDed with only `started_at` (immutable) + `seat_role` + `local_t`. Legacy nodes keep the deprecated fields until v3.10 migration.

---

## Kernel — hp-laptop

| | |
|--|--|
| URN | `urn:moos:kernel:hp-laptop.primary` |
| Endpoint | `http://localhost:8000` |
| Log entries | 561 (HG unchanged since round 8 — round 9 was kernel Go code, not HG hydration) |
| Nodes | 177 |
| Relations | 202 |
| Ontology | **v3.10.0 — 52 types, 20 WFs** (D19.1 merged: WF19 extended with has-occupant/is-occupant-of port pair for §M19 session-occupancy; ffs0 PR #31 merged) |

## Z440 (federation partner)

Not present at T=168 (placeholder session ADDed to satisfy 1-per-kernel floor). Tasks parked. Reconnect when back on-site.

---

## Ontology delta

**v3.9 (T=168 — baseline audit):** See `kb/research/s1/20260418-t168-v3.9-ontology-audit.md` and `kb/research/s1/20260418-t168-s1-superset-doctrine.md`.
- **Renames:** S1 `endpoint` → `network_endpoint`; `session.role` → `session.seat_role` (non-destructive; both coexist until v3.10)
- **Deprecations:** `prg_task`, `agent_session`, `watcher`, `reactor` (all S2)
- **Stratum clarifications:** `system_instruction` confirmed S2 with `overlay_role: S4` (was incorrectly S4 in v3.8); `twin_link` confirmed S2
- **New types (6):** `skill` (S1), `grammar_fragment` (S1), `pattern` (S1), `workflow` (S1), `view_filter` (S2), `harness` (S2)
- **New WF (1):** WF20 `grammar_promotion` — carries S4→S1 adjoint Promote (src: system_instruction, governance_proposal; tgt: grammar_fragment; authority: admin)
- **Audit annotations:** top-level `free_category_note`, `fold_contract` stub, `changelog`; per-type/WF `audit_note` where gaps found
- **Deferred to v3.10:** `benchmark`, `evaluation`, `dataset`, `dsl`; full WF20 promotion algorithm; per-WF CR-safety contracts; kernel validator retirement of `session.role`

51 node types total (35 S2 + 12 S1 + 4 interaction), 20 WFs.

**v3.8 (T=167):** Added `system_instruction` (S4, M7 context overlay), `transport_binding` (S2, M10 QUIC binding).
`session` type extended: `local_t`, `context_urn`, `role` properties. WF19 mutate_scope includes `local_t`, `context_urn`.
45 node types total.

**v3.7 (T=164):** Added `channel` (S2, kinds: filesystem / messaging / board / drive / mail), `purpose` (S2), WF19 (session governance).
Source of truth: `kb/superset/ontology.json`

---

## T=187 program tasks (sub-programs, WF18 composes)

All ten are `program` nodes with URN `urn:moos:program:sam.t187.<suffix>`, status=draft, owned by `urn:moos:user:sam`. Dependencies are `depends-on` LINKs between siblings.

| Suffix | Title | Depends on | §M |
|--------|-------|------------|----|
| `session-chrono-t` | Session.local_t as first-class carrier | — | M1 |
| `t-hooks-first-class` | Node.t_hooks as explicit port substructure | session-chrono-t | M6 |
| `gates` | gate type + fail-closed pathway | t-hooks-first-class | M8 |
| `system-instruction` | system_instruction S4 type + session.context_urn | — | M7 |
| `fold-endpoint` | Expose fold as HTTP observable + SSE over HTTP/3 | **http3-quic** | M3, M10 |
| `twin-kernel` | twin_link + adjoint sync protocol over QUIC | gates, **http3-quic** | M9, M10 |
| `strata-enforcement` | Compile-time strata filtration | — | M5 |
| `answer-walk-Q1-Q4` | Answer walk Q1..Q4 | — | — |
| `categorical-contract` | Proof obligations for CI-1..CI-5 + categorical claims | all others | M1..M10 |
| `twin-deploy-mtdc` | Deploy twin at my-tiny-data-collider.nl | twin-kernel | M9, M10 |
| **`http3-quic`** | **HTTP/3 QUIC transport binding — ServeQUIC + Alt-Svc + quic-go** | **—** | **M10** |

Opening envelope batch: `dev/scripts/open-t187.py` (35 envelopes, log_seq 300..334).
M10 addition: 4 envelopes (log_seq 335..338).

---

## T=167→168 implementation sprint (completed)

Eight of eleven sub-programs implemented across two sessions:

| Sub-program | Commit | §M | Key deliverable |
|-------------|--------|----|-----------------|
| `http3-quic` | `9fa37aa` | M10 | `transport/quic.go`, quic-go v0.59.0, Alt-Svc |
| `strata-enforcement` | `9fa37aa` | M5 | `ValidateStrataLink` in operad + runtime gate |
| `fold-endpoint` | `9fa37aa` | M3 | `GET /fold?to=<t>` + SSE stream |
| `session-chrono-t` | `9fa37aa` | M1 | `bumpSessionLocalT` in runtime.Apply |
| `system-instruction` | `9fa37aa` | M7 | ontology v3.8 S4 type (no new code) |
| `t-hooks-first-class` | `aeee6c2` | M6 | `t_hook` type, Pass 2 in reactive engine |
| `gates` | `dc4961a` | M8 | `gate` type, `checkGatesLocked` in Apply path |
| `twin-kernel` | `9c24bad` | M9 | `twin_link` type, `/twin/ingest`, `RunTwinSync` |

Session `urn:moos:session:sam.claude-code-hp-laptop.t167` wired (WF19, role=occupier).
Kernel binary: `moos-kernel-new.exe` (all above), log 346, 45 ontology types.

## T=187 sub-program status

All 11 sub-programs complete or active:

| Sub-program | Status | §M |
|-------------|--------|----|
| `http3-quic` | completed | M10 |
| `strata-enforcement` | completed | M5 |
| `fold-endpoint` | completed | M3 |
| `session-chrono-t` | completed | M1 |
| `system-instruction` | completed | M7 |
| `t-hooks-first-class` | completed | M6 |
| `gates` | completed | M8 |
| `twin-kernel` | completed | M9 |
| `twin-deploy-mtdc` | **active** (twin_link ADDed, remote kernel pending) | M9 |
| `answer-walk-Q1-Q4` | completed | — |
| `categorical-contract` | completed | M1..M10 |

`twin-deploy-mtdc` ops remaining: start kernel process at mtdc, activate `urn:moos:twin_link:hp-laptop.mtdc` (MUTATE status→active) once remote `POST /twin/ingest` returns 200.

---

## T=168 spec-enrichment backlog (9 new sub-programs, status=draft)

Added T=168 via `kb/research/kernel/20260417-t187-kernel-proper.md` §M11..§M17 appendix. All ADDed to HG as `program` nodes WF18 `composes-by/composed-of` linked to `urn:moos:program:sam.t187-kernel-proper`. Implementation deferred to later sprints.

| Sub-program | §M / Origin | Depends on | One-line scope |
|-------------|-------------|------------|----------------|
| `session-liveness` | §M11 | session-chrono-t | Kernel refuses rewrites when no seat-holder (occupier/delegate) |
| `admin-capability-enforcement` | §M12 | gates, session-liveness | operad.Validate checks actor's WF02 caps for admin-scope rewrites |
| `t-local-simplification` | §M13 | — | Re-wording: `t_local` = ticker, `T` = calendar; retire M1 chrono-t language |
| `t-hook-predicate-catalog` | §M14 | t-hooks-first-class | Rich predicate shapes (fires_at, window, after_urn, recurs_every, …) |
| `t-cone-projection` | §M15 | t-hook-predicate-catalog | `GET /t-cone?session=…&at=T` — occupier's view of open-hook nodes |
| `ontology-publication` | §M16 | twin-kernel | `ontology_publication` type + read-only twin-link flow |
| `external-op-stub` | §M17 | — | `external_op` type for CF tunnel / remote kernel start / bootstrap |
| `session-actor-agent-lookup` | Q3 specslist | session-chrono-t | `bumpSessionLocalT` agent→session lookup via WF19 `occupied-by` |
| `session-role-rename` | Q-knob defer | — | `session.role` → `session.seat_role` rename (disambiguate from S1 role) |

Total T=187 sub-programs after this pass: **20** (11 existing + 9 new).

---

## T=168 round 3 — §M18..§M20 session generalization (archived in round 4 merge)

Added T=168 round 3 via `kb/research/kernel/20260417-t187-kernel-proper.md` §M18..§M20 appendix. Builds on v3.9 primitives (view_filter, harness, skill). 8 grammar-fragment candidates identified (D19.1–D19.4, D20.1–D20.4) — awaiting WF20 promotion in a future round.

The 6 round-3 sub-programs (`session-generalization`, `session-view-holder`, `session-occupant-relation`, `tool-mounting`, `cli-as-tool-protocol`, `recursive-tool-construction`) were archived in round 4 and merged into `session-view` + `session-tools` + `session-occupancy`. See round 4 section below.

---

## T=168 round 4 — sub-program merge (T-ref cleanup + by-monitoring-scope naming)

Directive (sam, T=168): "merge these and don't use t-refs in the name. we should name them by scope or with tags, but for now we name them for what they monitor." Session-layer group topology: "stratified by monoid per kernel, not by ownership".

Outcome: 14 draft T=168 sub-programs → 7 merged sub-programs named for what they monitor. `session-role-rename` marked completed (v3.9 audit delivered the seat_role rename). `session-chrono-t` retained (active, pre-round-1).

### Active T=187 sub-programs after round 4 (19 live composes from `sam.t187-kernel-proper`)

| Sub-program URN suffix | Status | Monitors / Scope |
|------------------------|--------|------------------|
| **Originals (pre-T=168, 11)** | | |
| `t187.http3-quic` | active | HTTP/3 QUIC transport (§M10) |
| `t187.strata-enforcement` | active | Compile-time strata filtration (§M5) |
| `t187.fold-endpoint` | active | fold as HTTP observable + SSE over HTTP/3 (§M3) |
| `t187.session-chrono-t` | active | Session.local_t as first-class carrier (§M1) |
| `t187.system-instruction` | active | system_instruction S4 type + session.context_urn (§M7) |
| `t187.t-hooks-first-class` | completed | Node.t_hooks as explicit port substructure (§M6) |
| `t187.gates` | completed | gate type + fail-closed pathway (§M8) |
| `t187.twin-kernel` | completed | twin_link + adjoint sync protocol (§M9) |
| `t187.twin-deploy-mtdc` | active | Deploy twin at my-tiny-data-collider.nl |
| `t187.answer-walk-Q1-Q4` | completed | Answer walk Q1..Q4 |
| `t187.categorical-contract` | completed | Proof obligations CI-1..CI-5 |
| **Round 4 merged (7, all status=draft)** | | |
| `session-occupancy` | draft | seat_role + occupant LINKs (§M19) + WF02 capability gate (§M12). Merged: session-liveness + admin-capability-enforcement + session-occupant-relation. |
| `session-timeline` | draft | local_t heartbeat (§M13) + actor→agent resolution. Merged: t-local-simplification + session-actor-agent-lookup. |
| `session-view` | draft | view_filter + pins + filtered-by (§M18) + t-cone projection (§M15). Merged: t-cone-projection + session-generalization + session-view-holder. |
| `session-tools` | draft | mounts-tool + invocation_protocol + constructs (§M20). Merged: tool-mounting + cli-as-tool-protocol + recursive-tool-construction. |
| `hook-predicates` | draft | t_hook.predicate algebra (§M14). Renamed from t-hook-predicate-catalog. |
| `ontology-publication-prg` | draft | ontology_publication event + grammar_fragment manifest (§M16). Renamed from t187.ontology-publication (suffix -prg to avoid collision with v3.9 carrier). |
| `external-op` | draft | external_op type + WF-exec pairing (§M17). Renamed from external-op-stub. |
| **Completed during round 4 (1)** | | |
| `t187.session-role-rename` | completed | Delivered in v3.9 audit (seat_role added, legacy role deprecated). |

### Round 4 depends-on chain (5 WF18 depends-on links between merged sub-programs)

```
session-occupancy  (foundational — no deps)
  ↑
  ├── session-timeline  (needs seat-model for actor resolution)
  │     ↑
  └─────┤
        └── session-view  (also depends on hook-predicates for t-cone predicate algebra)

hook-predicates  (foundational — no deps)
  ↑
  ├── session-view  (predicate algebra for view_filter)
  └── ontology-publication-prg  (predicate spec for publication manifests)

session-tools  — depends on session-occupancy (tools need occupant)

external-op  — standalone, no deps
```

### Archived in round 4 (14 sub-programs, status=archived)

Original URNs kept (log-is-truth — no UNLINK of ADD). `scope` MUTATEd to point at merged replacement URN. WF18 composes-from-kernel-proper UNLINKed (14) plus inter-subprogram depends-on (12) UNLINKed.

| Archived URN | Merged into |
|--------------|-------------|
| `t187.session-liveness` | `session-occupancy` |
| `t187.admin-capability-enforcement` | `session-occupancy` |
| `t187.session-occupant-relation` | `session-occupancy` |
| `t187.t-local-simplification` | `session-timeline` |
| `t187.session-actor-agent-lookup` | `session-timeline` |
| `t187.t-cone-projection` | `session-view` |
| `t187.session-generalization` | `session-view` |
| `t187.session-view-holder` | `session-view` |
| `t187.tool-mounting` | `session-tools` |
| `t187.cli-as-tool-protocol` | `session-tools` |
| `t187.recursive-tool-construction` | `session-tools` |
| `t187.t-hook-predicate-catalog` | `hook-predicates` (rename) |
| `t187.ontology-publication` | `ontology-publication-prg` (rename) |
| `t187.external-op-stub` | `external-op` (rename) |

---

## v3.9 baseline audit (T=168 side-step, pre-round-4)

Research notes:
- `kb/research/s1/20260418-t168-v3.9-ontology-audit.md` — full audit: findings A..F, decisions, migration actions
- `kb/research/s1/20260418-t168-s1-superset-doctrine.md` — S4→S1 adjoint (Promote / Express), WF20 grammar_promotion, pipeline, open questions

HG materialisation (4 envelopes):
- MUTATE `urn:moos:session:sam.claude-code-hp-laptop.t164` `seat_role → observer` (WF19)
- MUTATE `urn:moos:session:sam.claude-code-hp-laptop.t167` `seat_role → occupier` (WF19)
- ADD `urn:moos:program:sam.ontology-publication-v3.9` (type_id=program; carrier for §M16 ontology_publication — real type in v3.10)
- LINK `urn:moos:program:sam.t187.ontology-publication --WF18 composes / composed-by--> urn:moos:program:sam.ontology-publication-v3.9`

---

## T=168 round 5 — demo materialization + IRL-time gates + S0 operadic lingo

Directive (sam, T=168): *"eval the kb/research and remove redundancy and or move to session... continue where we left bf the version audit bump, something to do with demo session role or type... 'adding specs deliverables project t hooks' is my term for hydrating graph in a irl connected way... effectively mapping spec gates over irl time through te session object."*

### Research reorg

`kb/research/wires/` subdir created; 2 wires-topic notes relocated:
- `20260414-t164-wires-come-from.md` — moved from root
- `20260417-t166-wire-answer-folder-nesting.md` — moved from root

Cross-ref fix in `wires-come-from.md`: pointer to `session/20260414-t164-session-channel-purpose.md` updated to relative `../session/...`.

Research root is now 4 clean subdirs: `kernel/` · `s1/` · `session/` · `wires/`. No stray top-level notes.

### Demo materialization — 6 ADDs (v3.9 types put to use)

Originally deferred from round 2 pre-v3.9-audit. Now materialized:

| URN | Type | Role |
|-----|------|------|
| `urn:moos:view_filter:sam.important-programs` | view_filter (S2) | Sam's personal t-cone lens (type=program, owner=sam, status ∈ {active, draft}) |
| `urn:moos:view_filter:sam.t168-open-deliverables` | view_filter (S2) | IRL-time filter using §M14 `fires_at` predicate on `starts_t ≥ 168` + `status=draft` |
| `urn:moos:agent:sam.claude-code-desktop` | agent | Placeholder future occupant per §M19 — transport=mcp-stdio, status=placeholder |
| `urn:moos:grammar_fragment:d19-1-session-has-occupant` | grammar_fragment (S1) | WF19 extension proposal — new port pair `has-occupant / is-occupant-of`, extend tgt_types with user+agent |
| `urn:moos:grammar_fragment:d20-2-agent-invocation-protocol` | grammar_fragment (S1) | agent property proposal — `invocation_protocol` enum [stdio, mcp, http] |
| `urn:moos:grammar_fragment:d14-1-time-predicates` | grammar_fragment (S1) | §M14 predicate-shape catalog — 12 time predicates + boolean composition (all_of, any_of) |

All 3 grammar_fragments carry `status=proposed`, awaiting WF20 promotion ceremony. They crystallise §M14/§M19/§M20 doctrine as candidate S1 extensions.

LINK demos (view_filter→session, agent→session) deferred — no live WF carrier in v3.9 (WF18 excludes view_filter from src_types). Standalone ADDs land the concepts for t-cone projection to pick up via property-level predicates.

### IRL-time hydration — 6 MUTATE `target_t` on active sub-programs

Sam's directive (*"mapping spec gates over irl time through the session object"*) materialized as `target_t` property on each active T=187 sub-program. Parent `sam.t187-kernel-proper` already holds `target_t=220`; sub-targets stage the 6 active deliverables across T=195..220:

| Sub-program | target_t |
|-------------|----------|
| `t187.session-chrono-t` | 195 |
| `t187.system-instruction` | 200 |
| `t187.strata-enforcement` | 205 |
| `t187.fold-endpoint` | 210 |
| `t187.http3-quic` | 215 |
| `t187.twin-deploy-mtdc` | 220 |

`view_filter:sam.t168-open-deliverables` now has live targets to surface via any t-cone reader that honours §M14 `fires_at` predicates. Predicate evaluator itself deferred — see `hook-predicates` sub-program.

### S0 operadic layer — new lingo note

`kb/research/s1/20260418-t168-s0-operadic-layer.md` — proposes **op-node / slot / yield / threading / weave** terminology for the category-over-S1-categories layer where `purpose`, `session`, `program`, `workflow`, `channel` live as operadic elements with typed slots. Maps sam's "semantic-to-syntax pattern" onto S4 → S0-weave → S1 → S2 → leaves pipeline. Five open questions carried forward (purpose arity; channel stratum; harness as embedded op; threading as projection; S0 bounded vs unbounded).

---

## T=168 round 6 — IRL→HG pipeline research + 6 v3.10 grammar_fragment proposals

Directive (sam, T=168): *"and humor me, and do some research too, for ex. use context 7 or relevant sources on math, category, data pipeline metrics, http3, hdc, concurrency, sheafs... classification schemas help me with lingo here i think i am talking about vector spaces here. Then polish extraction bf adding proposals."*

### Legacy extraction (pre-proposals)

Quick-extraction pass over 2 legacy folders; contents absorbed into conversation context and into the IRL→HG pipeline note, then set aside per sam's "forget about them" instruction:

- `dev/reference/research-archive/` — 15 pre-T=164 notes. Gems pulled forward: cascade matrix spectral check; Laplacian/Fiedler/Cheeger type coherence; crosswalks as SO(d) rotations; Ricci curvature on branchial graphs; graded algebra (grades 0-4); Shapley O(|E|) attribution; Yoneda-HDC `φ(node)`; Watch+React unification.
- `dev/design/` — 9 pre-T=158 design notes. Gems pulled forward: two-space CS↔HG architecture (T=152); CI-1..CI-5 formulation (T=152 origin); port typing + PortBinding reification (direct predecessor of v3.10-1 proposal); dynamic fiber + interface ports + completeness metric (predecessor of v3.10-3); bridge as natural transformation (predecessor of v3.10-2 three-views identity); governance proposal promotion loop (direct predecessor of WF20).

Both folders are now superseded by `kb/research/` + `kb/superset/ontology.json`. Retained on-disk as historical archive only.

### 4-axis research (context7 + arXiv + HF sources)

Research threads dispatched in parallel; each returned formalism + primary references:

| Axis | Key results | Primary references |
|------|-------------|--------------------|
| **Sheaf theory** | Cellular sheaves on graphs — stalks `F(v)`, restriction maps `F_{v→e}`, sheaf Laplacian `L_F = δ*δ`. `ker(L_F)` = global sections. Presheaf→sheaf via equalizer gluing axiom. Geometric morphism `f* ⊣ f_*` between classifying toposes = the correct "map of kernels". Data migration functor `Δ_F` (Spivak) with adjoint triple `Σ_F ⊣ Δ_F ⊣ Π_F`. | Hansen-Ghrist 2019 (arXiv:1808.01513); Spivak 2012; Spivak 2013 (arXiv:1305.0297, UWD operads) |
| **HDC / VSA** | HRR binding = circular convolution = unitary rotation (Plate); BSC via XOR (Kanerva); MAP via Hadamard (Gayler). Procrustes rotation `R* = UV^T` (Schönemann 1966) — the formal way to align two classification schemes. Stiefel manifold `V_k(ℝ^d) = O(d)/O(d−k)` is the moduli space of size-k classification schemes. Tight frame / ETF = the formal name for a classification scheme (not a basis). | Plate 1995 (HRR); Kanerva 2009 (BSC); Gayler 2003 (MAP); Schönemann 1966 (Procrustes); |
| **Pipeline metrics & concurrency** | Little's Law `L = λW` for reactive backpressure sizing. Watermarks = event-time completeness lower bound (Akidau MillWheel VLDB 2013). HLC (Kulkarni 2014) is the right choice for twin_link causality. CRDTs: OR-Set for nodes/edges, LWW-Register-with-HLC for properties (Shapiro 2011). QUIC 0-RTT is safe only for idempotent GETs (replay attacks block admin rewrites). | Akidau 2013; Kulkarni 2014; Shapiro 2011; RFC 9000 |
| **Ollivier-Ricci on graphs** | `κ(x,y) = 1 − W₁(μ_x, μ_y)/d(x,y)` — Wasserstein-1 over neighbour distributions. Forman-Ricci = O(deg) combinatorial proxy with ~0.7-0.9 Spearman corr vs Ollivier. Ricci flow outperforms modularity for community detection (Ni et al. Nature Sci Rep 2019). Jost-Liu 2014: `κ ≥ κ_min ⇒ λ₂ ≥ κ_min` — bridges curvature to spectral gap. | Ollivier 2007; Lin-Lu-Yau 2011; Ni 2019; Jost-Liu 2014 |

**Three-views identity** (v3.10 proof obligation): **Procrustes rotation = data migration functor Δ_F = geometric morphism f***.  
The same crosswalk object can be presented as (a) an orthogonal rotation aligning two HDC frames, (b) a pullback functor between schema categories, or (c) the inverse-image part of a geometric morphism between classifying toposes. All three must agree up to natural isomorphism — this becomes CI-6.

### Polished research note

`kb/research/s1/20260418-t168-irl-to-hg-pipeline.md` — 9-section ~500-line note:

1. IRL→HG pipeline stages (S4 intent → S1 wire → S0 weave → S2 occupancy → S1 reflect)
2. Vector-space lingo sam asked for (tight frames, Stiefel, Procrustes, HDC binding)
3. Sheaf-theoretic lingo (stalks, sections, restriction maps, sheaf Laplacian)
4. Three-views identity (Procrustes = Δ_F = geometric morphism)
5. Mapping to current doctrine (where §M14..§M20 fit each frame)
6. Concurrency / federation dynamics (Little's Law, HLC, CRDT, Ollivier-Ricci)
7. v3.10 proof obligations (CI-6 three-views identity, plus the 6 candidate fragments)
8. Vocabulary cards — one-card-per-term for session hand-offs
9. References (~30 primary sources)

Serves as the foundation for the 6 proposals below.

### 6 grammar_fragment proposals for v3.10 (all ADDed, status=proposed)

Each fragment crystallises doctrine from the pipeline note into a concrete candidate S1 extension. Awaiting WF20 promotion ceremony in a future round.

| URN suffix | Kind | Crystallises | Specification highlights |
|------------|------|--------------|--------------------------|
| `v310-1-port-binding` | type | Design-era PortBinding reification (OBJ24 candidate) | New S1 type `port_binding`. Properties: `src_type, src_port, tgt_type, tgt_port, wf_category, benchmarks, req_schema, resp_schema`. Turns implicit (type, port) pairs into first-class nodes. |
| `v310-2-crosswalk` | type | Three-views identity (§7 pipeline note) | New type `crosswalk`. Properties: `source_classification_urn, target_classification_urn, rotation_artifact_urn, procrustes_error, direction: {pullback_delta, leftkan_sigma, rightkan_pi}, verified`. Presents the three-way equivalence as a single node. |
| `v310-3-fiber-completeness` | property | Dynamic fiber + interface ports (design-era) | New `completeness` property on `channel, view_filter, twin_link`. Computation: `|wires_present| / |wires_expected|`. Trigger: emit `bridge.sync.needed` when completeness < 0.8. |
| `v310-4-branchial-ricci` | property | Ollivier-Ricci axis + Jost-Liu spectral bridge | New properties on `twin_link`: `ollivier_ricci`, `forman_ricci`. Composition with spectral gap via Jost-Liu 2014. Ricci flow community detection via Ni et al. 2019. |
| `v310-5-cascade-spectral-bound` | predicate_shape | Cascade matrix stability (archive gem) | New predicate shape `cascade_stable(C, threshold)`. Formula: `ρ(C) < threshold` (spectral radius of cascade matrix). References Newman 2018 §17.8; Barrat-Barthélemy-Vespignani 2008 ch.9. |
| `v310-6-sheaf-laplacian-inconsistency` | predicate_shape | Hansen-Ghrist sheaf Laplacian | New predicate shape `sheaf_laplacian_inconsistent(F, tolerance)`. Formula: `L_F = δ*δ` has nonzero eigenvalue > tolerance. Flags consistency failure across the graph's sheaf of restrictions. |

All 6 ADDs succeeded (batch via `mcp__moos-kernel__apply_program`). `affected_node_urn` returned per fragment. Kernel stats: log 457→463 (+6), nodes 142→148 (+6), relations 198 unchanged.

---

## T=168 round 7 — still-pending cleanup (10 more grammar_fragment proposals)

Directive (sam, T=168): *"continu where we left bf we did the last in a serie of md docs evals"* — resume from the "still pending for later rounds" backlog that was set aside for the legacy-folder evals.

### Backlog identification

Two residual streams pending since earlier rounds:

1. **§M18..§M20 round-3 candidates** (from `kb/research/kernel/20260417-t187-kernel-proper.md` round-3 appendix, lines 529-536). 8 fragments proposed by name in round 3; only 2 (D19.1, D20.2) + 1 late-addition (D14.1) materialised in round 5. **6 still un-materialised.**
2. **v3.9 audit §D deferred types** (from `kb/research/s1/20260418-t168-v3.9-ontology-audit.md` lines 61-64). 4 types (benchmark, evaluation, dataset, dsl) explicitly deferred to v3.10.

Round 7 lands all 10 as grammar_fragment proposals. One atomic batch.

### 6 §M18..§M20 backlog proposals (status=proposed, stratum_origin=1 matching round-3 siblings)

| URN suffix | Kind | Crystallises |
|------------|------|--------------|
| `d19-2-session-view-prefs` | property | §M18: `session.view_prefs` object (`sort_by, fold_depth, density, theme`) — scalar UI prefs for t-cone rendering. Distinct from view_filter (predicate) and pins (topology). |
| `d19-3-session-pins-urn` | port | §M18: session `pins-urn / pinned-by-session` — topology-color port to any node. Occupant's persistent visibility anchors. |
| `d19-4-session-filtered-by` | port | §M18: session `filtered-by / filters-session` → view_filter. Semantic-color port; §M15 t-cone composes as intersection over all bound predicates. |
| `d20-1-session-mounts-tool` | port | §M20: session `mounts-tool / tool-mounted-in-session` → agent. Mounted tools invokable by occupant under WF02 caps. |
| `d20-3-agent-runs-in-harness` | port | §M20: agent `runs-in / runs` → harness. Capability intersection at runtime with `harness.allowed_capabilities`. |
| `d20-4-agent-constructs-agent` | port | §M20: agent `constructs / constructed-by` → agent. Recursive tool-making. **Candidate CI-6: capability isolation** — no auto-inherit from constructor; explicit upper bound. |

### 4 v3.10 deferred-type proposals (status=proposed, stratum_origin=2 matching round-6 siblings)

| URN suffix | Kind | Crystallises |
|------------|------|--------------|
| `v310-7-benchmark` | type | S2 type. Fixture + expected outcomes + scoring rubric. Pairs with `evaluation`. Can target harness/agent/workflow. Dataset-backed when bulk. |
| `v310-8-evaluation` | type | S2 type, append-only. Run-level node carrying scores, pass/fail, artifacts, run_t. Time-series metric tracking + pass/fail gates. |
| `v310-9-dataset` | type | S2 type, versioned. Structured input corpus; versioning lets evaluations fix a snapshot. Doubles as **HDC tight-frame support** (per §3.4 pipeline note) when used as a classification scheme. |
| `v310-10-dsl` | type | S1 type. Bundles many grammar_fragments into a named, versioned micro-grammar. Activation via proposed WF20-2 `dsl_activation` (atomic promote-all-and-activate). |

### Crosswalks & provenance links (via `evidence_urns`)

Fragment proposals wire themselves together through evidence pointers — lets any reader discover the candidate S1 cluster:

- `v310-8-evaluation` → `v310-7-benchmark` (requires)
- `v310-9-dataset` → `v310-2-crosswalk` (HDC-frame connection; `v310-2` already established the three-views identity)
- `v310-10-dsl` → `v310-7-benchmark + v310-8-evaluation + v310-9-dataset` (bundling)
- D19.4 → `view_filter:sam.important-programs + view_filter:sam.t168-open-deliverables` (round-5 demo instances)
- D20.4 → `agent:claude-code.hp-laptop + agent:sam.claude-code-desktop` (constructor / constructed candidates)

### Kernel stats after round 7

All 10 ADDs succeeded in one atomic batch. Kernel: log 463→473 (+10), nodes 148→158 (+10 grammar_fragment), relations 198 unchanged.

**Grammar_fragment census:** 19 total (3 from round 5 + 6 from round 6 + 10 from round 7). All `status=proposed`. WF20 promotion ceremony remains the outstanding gate for any of these to become live S1 grammar.

### What's left in the backlog after round 7

- **WF20 promotion algorithm** — how evidence aggregates, how admin signs acceptance, how canonical types materialise. Doctrine declared in v3.9 audit §F; kernel validator not yet exercising WF20.
- **Per-WF CR-safety contracts** — v3.9 adds `audit_note` per WF flagging CR-safety; explicit contract declarations deferred.
- **Kernel validator retirement of `session.role`** — `seat_role` added, legacy `role` marked deprecated; validator still accepts both. Removal scheduled for v3.10.
- **LINK demos (view_filter→session, agent→session)** — deferred in round 5 (no live WF carrier); still pending a WF or WF-extension landing.
- **Predicate evaluator implementation** — §M14 `fires_at`, `window`, etc. declared; evaluator in the `hook-predicates` sub-program (status=draft).

---

## T=168 round 8 — T=187 delivery clock + successor programs + external_op IRL gates

Directive (sam, T=168): *"we have the t187 as a hook, a possible calendar event a delivery date, a possible node that future nodes will depend on, nodes that are composed by this node. Surprise me."*

**Central idea.** T=187 = **May 7, 2026** (T=0 is 2025-11-01). The `t187-kernel-proper` program is now treated as a real IRL-time delivery node — the kind that gates successors, anchors sub-program sprint checkpoints, and gets its own t_hook cascade. The HG becomes its own **spec-level CI/CD pipeline**: t_hooks fire at target_t values across the T=187→T=220 window, each marking a sub-program checkpoint visible via the t-cone.

Full doctrine: `kb/research/s1/20260418-t168-t187-delivery-clock.md`.

### Calendar map

| T-value | Calendar date | Role |
|---------|--------------|------|
| T=168 | 2026-04-18 | Today — round 8 |
| T=187 | 2026-05-07 | Delivery window opens |
| T=195 | 2026-05-15 | `session-chrono-t` checkpoint |
| T=200 | 2026-05-20 | `system-instruction` checkpoint |
| T=205 | 2026-05-25 | `strata-enforcement` checkpoint |
| T=210 | 2026-05-30 | `fold-endpoint` checkpoint |
| T=215 | 2026-06-04 | `http3-quic` checkpoint |
| T=220 | 2026-06-09 | `twin-deploy-mtdc` checkpoint; delivery window closes; v310-delivery starts |
| T=240 | 2026-06-29 | v3.10 delivery target — 23 grammar_fragments promoted |
| T=250 | 2026-07-09 | wiring-proposer target — HDC-grounded auto-wiring active |

### Batch A — 10 t_hook ADDs (delivery clock)

| URN | owner_urn | predicate | react |
|-----|-----------|-----------|-------|
| `t_hook:sam.t187.delivery-opens` | `program:sam.t187-kernel-proper` | `fires_at t=187` | MUTATE kernel-proper `delivery_phase=in-delivery` |
| `t_hook:sam.t187.delivery-closes` | `program:sam.t187-kernel-proper` | `closes_at t=220` | MUTATE kernel-proper `delivery_phase=closed` |
| `t_hook:sam.t187.checkpoint.session-chrono-t` | `program:sam.t187.session-chrono-t` | `fires_at t=195` | MUTATE status=checkpoint |
| `t_hook:sam.t187.checkpoint.system-instruction` | `program:sam.t187.system-instruction` | `fires_at t=200` | MUTATE status=checkpoint |
| `t_hook:sam.t187.checkpoint.strata-enforcement` | `program:sam.t187.strata-enforcement` | `fires_at t=205` | MUTATE status=checkpoint |
| `t_hook:sam.t187.checkpoint.fold-endpoint` | `program:sam.t187.fold-endpoint` | `fires_at t=210` | MUTATE status=checkpoint |
| `t_hook:sam.t187.checkpoint.http3-quic` | `program:sam.t187.http3-quic` | `fires_at t=215` | MUTATE status=checkpoint |
| `t_hook:sam.t187.checkpoint.twin-deploy-mtdc` | `program:sam.t187.twin-deploy-mtdc` | `fires_at t=220` | MUTATE status=checkpoint |
| `t_hook:sam.v310-delivery.startable` | `program:sam.v310-delivery` | `all_of(fires_at t=220, after_urn kernel-proper.status=completed)` | MUTATE status=startable |
| `t_hook:sam.wiring-proposer.startable` | `program:sam.wiring-proposer` | `all_of(fires_at t=240, after_urn kernel-proper.status=completed, after_urn v310-delivery.status=completed)` | MUTATE status=startable |

`owner_urn` is a `t_hook` property (not a separate LINK) — kernel attaches via property lookup. Predicate evaluator for `all_of` + `after_urn` deferred to `t187.hook-predicates` sub-program (currently only `fires_at` is evaluated).

### Batch B — 2 successor programs + 3 WF18 LINKs

| Program | status | starts_t | target_t | Depends on |
|---------|--------|----------|----------|------------|
| `program:sam.v310-delivery` | draft | 220 | 240 | `t187-kernel-proper` |
| `program:sam.wiring-proposer` | inert (pre-existing node, MUTATEd starts_t/target_t) | 240 | 250 | `t187-kernel-proper`, `v310-delivery` |

WF18 LINKs added (composes/composed-by + depends-on/depended-by):
- `v310-delivery --depends-on--> t187-kernel-proper`
- `wiring-proposer --depends-on--> t187-kernel-proper`
- `wiring-proposer --depends-on--> v310-delivery`

### Batch C — 3 external_op ADDs (IRL-condition gates)

Models §M17 doctrine: IRL manual operations whose completion gates sub-program status. Added `external_op` to `ontology.json` as an S2 type (not a grammar_fragment promotion — the type landed directly since the plan required it). One test node `external_op:sam.test` persists in log with status=cancelled (log-is-truth; cannot be removed).

| URN | deadline_t | automates_via | command_hint |
|-----|-----------|---------------|--------------|
| `external_op:sam.mtdc-kernel-start` | 187 | `program:sam.t187.twin-deploy-mtdc` | `ssh mtdc; cd moos-kernel; ./moos-kernel-new --port 8000` |
| `external_op:sam.cf-tunnel-api-mtdc` | 187 | `program:sam.t187.twin-deploy-mtdc` | `cloudflared tunnel route dns mtdc api.my-tiny-data-collider.nl` |
| `external_op:sam.ontology-bootstrap-mtdc` | 220 | `program:sam.v310-delivery` | `curl -X POST http://api.my-tiny-data-collider.nl/ontology -d @kb/superset/ontology.json` |

### Batch D — 4 more grammar_fragment proposals (23 total now)

All four status=proposed, awaiting WF20 promotion.

| URN suffix | Kind | Crystallises |
|------------|------|--------------|
| `v310-11-ontology-publication` | type | §M16 formalised. New S1 type `ontology_publication` with version / content_hash / signed_by / promoted_fragment_urns / supersedes_urn. Twin-link read-only sync makes v3.10 landing atomic. |
| `v310-12-grammar-fragment-enrichment` | property | Adds `blocked_until: urn` to grammar_fragment (mutable, admin scope). Enables dependency-aware promotion queue. Verified rejection_reason already in v3.9. |
| `v310-13-purpose-arity2` | wf_clause | Purpose as S0 arity-2 op-node. `phi_current` and `phi_target` become slots (WF01 LINKs with new port pairs) not scalar properties. Yield = phi-space direction computed at t-cone read time. |
| `v310-14-startable-status` | property | Dual-kind: `program.status` enum gains `startable` + canonical `all_of(fires_at, after_urn*)` t_hook shape. Independent programs: arity-1; dependent programs: arity-N. Materialised by `v310-delivery.startable` + `wiring-proposer.startable` t_hooks. |

### Round 8 batch summary

| Batch | Rewrites | Net nodes | Net relations |
|-------|----------|-----------|---------------|
| A — delivery clock | 10 ADD + 1 MUTATE (ontology_publication-v3.9 calendar_date props) | +10 t_hook | 0 |
| B — successor programs | 1 ADD (v310-delivery) + 2 MUTATE (wiring-proposer starts_t/target_t) + 3 LINK | +1 program | +3 WF18 |
| C — external_op gates | 4 ADD (3 IRL + 1 test) + 2 MUTATE (test→cancelled) | +4 external_op | 0 |
| D — grammar_fragments | 4 ADD | +4 grammar_fragment | 0 |

Totals: **+19 nodes, +3+ relations, ~88 log entries**.

**Grammar_fragment census:** 23 total (3 round 5 + 6 round 6 + 10 round 7 + 4 round 8). All status=proposed.

### Deferred to future rounds (status at round-8 close)

- Predicate evaluator (`after_urn` + `all_of`) — **shipped in round 9** (`t187.hook-predicates` sub-program). See next section.
- 6 active sub-program startable t_hooks — now evaluable; sweep emits governance_proposals when conditions meet.
- MUTATEs to t187-kernel-proper `delivery_phase / calendar_date_open / calendar_date_close` — fields still not in program type spec; awaiting future ontology bump.
- external_op → sub-program LINK via `automates_via` port (WF extension TBD).
- WF20 grammar_promotion ceremony for the remaining 22 fragments (D19.1 merged in round 9).

---

## T=168→169 round 9 — kernel code (no HG hydration)

Round 9 is the first round where the delta is in Go code, not HG ADDs. The `t187.hook-predicates` sub-program is now shipped end-to-end, plus session-occupancy (§M11+§M12+§M19) and t-cone (§M15).

### PRs merged to master

| # | Scope | Branch |
|---|-------|--------|
| **#15** | T=187 sprint v2 replacement for closed #8 | `agent/z440-claude/hdc-engine` |
| **#17** | pure predicate evaluator (§M14 subset: fires_at, closes_at, after_urn, before_urn, all_of, any_of) | hook-predicates |
| **#18** | `GET /t-hook/evaluate/{urn}?at=T` introspection endpoint | thook-evaluate-endpoint |
| **#19** | `POST /t-hook/evaluate` batch endpoint (max 1 MiB body) | thook-batch |
| **#20** | time-driven sweep + WF13 governance_proposal emission (`--sweep-interval` flag, default 30s) | sweep-loop |
| **#21** | `GET /t-cone?session=...&at=T` projection | t-cone |
| **#22** | 4 extended §M14 kinds: window, expires_at, on_prop_set, when_capability (with EvalContext) | predicates-extended |
| **#23** | review-comment followups (correctness tightening across #12–#16) | round-9-review-followups |
| **#24** | **T=169** perf followups: shared `internal/tday` + NodesByType/Relations{Src,Tgt} indexes | t169-perf-followups |
| **ffs0 #31** | **ontology v3.10.0** — D19.1 merged; WF19 gains has-occupant/is-occupant-of port pair and tgt_types {user, agent} | v3.10-session-occupancy |

### New / extended APIs

```
POST /t-hook/evaluate        { "urns": [...], "at": T }    → [{urn, at_t, fires, ...}]
GET  /t-hook/evaluate/{urn}  ?at=T                         → {urn, at_t, fires, ...}
GET  /t-cone                 ?session=urn&at=T             → occupier's projection
```

### New CLI flag

```
--sweep-interval=30s   (0 disables)
```

### Package additions

- `internal/tday` — single source of truth for the mo:os T-day epoch + `Now()` / `At(t)` helpers. Used by `cmd/moos`, `internal/transport`, `internal/kernel/sweep`.
- `internal/operad/occupancy.go` — `ResolveSessionOccupant(state, sessionURN)` and `CheckAdminCapability(state, actor)` (§M11/§M12).
- `internal/kernel/sweep.go` — `SweepOnce`, `RunTimedSweep`, `SweepTick`, `SetSweepActor`.

### Structural hardening (T=169)

- `graph.GraphState` gains 3 secondary indexes (JSON-omitted, rebuilt on load): `NodesByType`, `RelationsBySrc`, `RelationsByTgt`. Maintained by `fold.apply{ADD,LINK,UNLINK}`. Accessors `NodesOfType` / `RelationsFrom` / `RelationsTo` fall back to a full scan when the index is nil (keeps test fixtures correct without Rebuild).
- Hot paths (sweep, occupancy helpers, t-cone, when_capability) migrated from O(N)/O(R) scans to O(bucket-size).

### Firing semantics (locked for this round)

Sweep **proposes via WF13 governance** — NEVER auto-applies. Each firing hook produces a `governance_proposal` node with `status=pending`, `source_t_hook_urn`, `fires_at_t`, `proposed_envelope` (the decoded react_template). Admin sessions flip status to approved or rejected; a separate approver-reactor (not yet shipped) applies the envelope on approval. Matches §M12 fail-closed stance.

### Deferred to future rounds

- Approver reactor (governance_proposal.status=approved → apply proposed_envelope).
- `firing_state` property on t_hook — ontology v3.11 candidate; would tighten sweep idempotency from "check proposal existence" to "check firing_state != proposed".
- Bounded worker pool for `forwardToEagerTwins` (closed #8 Gemini flagged; structural, separate PR).
- Event-shape JSON round-trip fast-path in reactive engine (closed #8 Gemini flagged; cache parsed shape on t_hook node).

---

## Key URNs

```
urn:moos:user:sam
urn:moos:kernel:hp-laptop.primary
urn:moos:kernel:hp-z440.primary
urn:moos:program:sam.t187-kernel-proper
urn:moos:program:sam.t164-room-tying  (completed)
urn:moos:program:sam.ontology-publication-v3.9  (v3.9 publication carrier)

# Round 4 merged sub-programs (by-monitoring-scope names, no t-ref prefix)
urn:moos:program:sam.session-occupancy
urn:moos:program:sam.session-timeline
urn:moos:program:sam.session-view
urn:moos:program:sam.session-tools
urn:moos:program:sam.hook-predicates
urn:moos:program:sam.ontology-publication-prg
urn:moos:program:sam.external-op

urn:moos:purpose:sam.t164-tie-the-room-together
urn:moos:agent:claude-code.hp-laptop
urn:moos:agent:claude-code.hp-z440

# Round 5 demo nodes (v3.9 types in use)
urn:moos:view_filter:sam.important-programs
urn:moos:view_filter:sam.t168-open-deliverables
urn:moos:agent:sam.claude-code-desktop  (placeholder future occupant, §M19)
urn:moos:grammar_fragment:d19-1-session-has-occupant  (status=proposed)
urn:moos:grammar_fragment:d20-2-agent-invocation-protocol  (status=proposed)
urn:moos:grammar_fragment:d14-1-time-predicates  (status=proposed)

# Round 6 v3.10 grammar_fragment proposals (all status=proposed)
urn:moos:grammar_fragment:v310-1-port-binding
urn:moos:grammar_fragment:v310-2-crosswalk
urn:moos:grammar_fragment:v310-3-fiber-completeness
urn:moos:grammar_fragment:v310-4-branchial-ricci
urn:moos:grammar_fragment:v310-5-cascade-spectral-bound
urn:moos:grammar_fragment:v310-6-sheaf-laplacian-inconsistency

# Round 7 §M18..§M20 backlog proposals (all status=proposed)
urn:moos:grammar_fragment:d19-2-session-view-prefs
urn:moos:grammar_fragment:d19-3-session-pins-urn
urn:moos:grammar_fragment:d19-4-session-filtered-by
urn:moos:grammar_fragment:d20-1-session-mounts-tool
urn:moos:grammar_fragment:d20-3-agent-runs-in-harness
urn:moos:grammar_fragment:d20-4-agent-constructs-agent

# Round 7 v3.10 deferred-type proposals (all status=proposed)
urn:moos:grammar_fragment:v310-7-benchmark
urn:moos:grammar_fragment:v310-8-evaluation
urn:moos:grammar_fragment:v310-9-dataset
urn:moos:grammar_fragment:v310-10-dsl

# Round 8 successor programs (T=187 as delivery anchor)
urn:moos:program:sam.v310-delivery       (starts_t=220, target_t=240, status=draft)
urn:moos:program:sam.wiring-proposer     (starts_t=240, target_t=250, status=inert)

# Round 8 delivery-clock t_hooks (10)
urn:moos:t_hook:sam.t187.delivery-opens          (fires_at=187)
urn:moos:t_hook:sam.t187.delivery-closes         (closes_at=220)
urn:moos:t_hook:sam.t187.checkpoint.session-chrono-t     (fires_at=195)
urn:moos:t_hook:sam.t187.checkpoint.system-instruction   (fires_at=200)
urn:moos:t_hook:sam.t187.checkpoint.strata-enforcement   (fires_at=205)
urn:moos:t_hook:sam.t187.checkpoint.fold-endpoint        (fires_at=210)
urn:moos:t_hook:sam.t187.checkpoint.http3-quic           (fires_at=215)
urn:moos:t_hook:sam.t187.checkpoint.twin-deploy-mtdc     (fires_at=220)
urn:moos:t_hook:sam.v310-delivery.startable      (all_of fires_at=220, after_urn kernel-proper=completed)
urn:moos:t_hook:sam.wiring-proposer.startable    (all_of fires_at=240, after_urn kernel-proper=completed, after_urn v310-delivery=completed)

# Round 8 external_op IRL gates (3 + 1 test)
urn:moos:external_op:sam.mtdc-kernel-start           (deadline_t=187)
urn:moos:external_op:sam.cf-tunnel-api-mtdc          (deadline_t=187)
urn:moos:external_op:sam.ontology-bootstrap-mtdc     (deadline_t=220)
urn:moos:external_op:sam.test                        (status=cancelled — HTTP-API verification artifact)

# Round 8 grammar_fragment proposals (all status=proposed)
urn:moos:grammar_fragment:v310-11-ontology-publication
urn:moos:grammar_fragment:v310-12-grammar-fragment-enrichment
urn:moos:grammar_fragment:v310-13-purpose-arity2
urn:moos:grammar_fragment:v310-14-startable-status

# Live sessions (exactly 2 — one per kernel, no T-day in URN)
urn:moos:session:sam.claude-code-hp-laptop  (WF19-LINKed, seat_role=occupier)
urn:moos:session:sam.claude-code-hp-z440    (WF19-LINKed, seat_role=observer)

# Archived sessions (provenance; no WF19 LINK)
urn:moos:session:sam.claude-code-hp-laptop.t164
urn:moos:session:sam.claude-code-hp-laptop.t167
urn:moos:session:sam.claude-code-hp-z440.t168
```

---

## Architecture

```
hp-laptop:  kernel :8000 | MCP :8080
            CF tunnel: kernel.my-tiny-data-collider.nl (SSE) | api.my-tiny-data-collider.nl (REST)
Z440:       kernel :8000–:8003 | router :9000 (federation, WF16)
```

Agents per workstation: `claude-code` · `vscode-codex` · `antigravity`
Repos: `moos-kernel` (Go, public) · `moos-router` · `ffs0` (this workspace, private)

### moos-router (feat/type-map-routing — merged PR #2)
Type routing via `--type-map type_id=url` checked before URN-prefix shard rules.
Companion: `dev/scripts/generate_type_map.py` emits flags from ontology.json strata.

---

## Codex (archived)

`dev/reference/research-archive/20260408-foundation-t158.md` — foundations, nomenclature,
node types, two-presheaf model, functorial semantics, federation architecture.
Active type system: `kb/superset/ontology.json` supersedes for formal types.
