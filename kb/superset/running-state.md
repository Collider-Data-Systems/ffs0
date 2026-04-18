# mo:os — running state

> Hydration entrypoint. Read this first in any new conversation.
> Updated: T=168 (April 18, 2026) — round 5: demo materialization + IRL-time gates (`target_t` on 6 active sub-programs) + S0 operadic lingo + research reorg (`wires/` subdir)

---

## Active program

| | |
|--|--|
| Program | `urn:moos:program:sam.t187-kernel-proper` |
| Title | T=187: kernel proper — session-as-actor, twin kernels, gates, admin governance |
| Current T-day | T=168 (April 18, 2026) |
| Status | active (spec-enrichment + implementation phases) |
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
| Log entries | 457 (round 5: +6 ADDs demos, +6 MUTATEs target_t) |
| Nodes | 142 (136 + 6 round-5 demo ADDs: 2 view_filter, 1 agent, 3 grammar_fragment) |
| Relations | 198 (unchanged in round 5 — ADDs + MUTATEs only, no LINK/UNLINK) |
| Ontology | **v3.9 — 51 types, 20 WFs** (session.status + turn_count marked deprecated: true) |

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
