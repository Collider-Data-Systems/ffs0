# The Rust corner of the dialect topology, measured (t274 lane E; 2b executed t275)

> **Status: executed; every claim is a passing test in `Collider-Data-Systems/mtdc-lab`
> (private lab repo, lane E of the t274 rev-4 plan).** Gate: `cargo run -p gen-tables &&
> cargo test` — 30 cases (23 runtime + 7 compile_fail doctests) at `mtdc-lab@d4916ca`;
> xDSL target 6/6 on the shared tables (xDSL 0.69.0). Round-1 evidence base: `main@7edce6f`.
> Cross-references, not edits: `dev/design/manifold-bump-4_0/20260802-t274-engine-language-choice.md`,
> `DECISION-engine-language.md` (ffs0#184, adjudication pending), `dev/research/mlir/20260802-t274-spike-b-findings.md`,
> moos-kernel#66. This note ADDS evidence for #184's open ruling 2; it does not touch the record under adjudication.

## The question (t274 re-scope)

The operad is runtime-versioned data (`kb/superset/ontology.json`); every typed-artifact
target is build-time. Where does the line fall per target, and what constraint
expressiveness is lost at each boundary? Corners previously measured: xDSL/Python WORKS
(process-start generation; V1–V4 verify) · MLIR-proper FAILS (IRDL cannot express V3/V4;
ODS is build-time only). This note reports the Rust corner.

## Result 1 — Rust has no IRDL wall: V1–V4 are ALL compile-time expressible

Generated from a pinned ontology.json by a ~200-line emitter (no macros, no proc-macros,
no dependencies beyond serde for parsing):

| check | compile-time encoding | negative case (fails to COMPILE) |
|---|---|---|
| V1 node-type-exists | one ZST per declared type | `nodes::Widget` → E0433 |
| V2 WF-allows-rewrite | `AllowsAdd/Link/Mutate/Unlink` marker traits per `allowed_rewrites` | `mutate::<WF01>` → E0277 |
| V3 port-pair-declared | one ZST per declared (WF, src_port, tgt_port) — the pair namespace IS the declaration table | `pairs::WF21__frobnicates__frobnicated_by` → E0433 |
| V4 pair-level src/tgt types | `SrcOf<Pair>`/`TgtOf<Pair>` impls per pair's type sets, bounds on the link constructor | `claim` as `has-occupant` src → E0277 |

The constraint language that IRDL lacks (a port-pair list with per-pair type sets) is
ordinary trait implementation in Rust. **For the operad-verifier role, Rust is strictly
more expressive at build time than MLIR-proper's runtime option.**

## Result 2 — the line falls between AUTHORED and DATA-BORNE, not between V1 and V4

Compile-time V1–V4 holds only for rewrite programs **authored as Rust source** against the
generated API. Every **data-borne** envelope (JSON over HTTP/MCP — all production traffic)
falls back to a table-driven runtime verifier exactly equivalent to the Go kernel's
`operad.Registry` checks. V4's runtime residue is one call: `TypedUrn::<N>::new(urn_string)`
— the single trust boundary where a URN string is bound to its type at runtime; the binding
is static from that point on.

**Pre-registered falsification clause, engaged honestly:** on the data-borne path the
generated types check nothing the loaded registry doesn't — #184's table-driven-checker
conclusion extends from MLIR to Rust unchanged. It does not fire overall:

1. **The authored path is real in the engine.** `SeedIfAbsent`, the sweep's WF13 proposal
   emitter, and `RotateSessionOccupant` are code-emitted envelope programs; in a
   generated-Rust engine their grammar errors would be build failures. The Go kernel's own
   hand-written `RewriteCategory` enum (graph/relation.go: WF01–WF19, stale names) is the
   standing demonstration of transcription rot that generation removes.
2. **Generation forces whole-operad consistency the runtime never checks.** WF21's type
   lists name `task` and `knowledge_artifact` — neither declared. The generator cannot emit
   an impl for a type that does not exist; it must drop and surface them. The Go registry
   validates envelopes against the lists but never validates the lists.
3. **The generated tier enforces URN shape; the runtime provably does not.**
   `operad.Registry` stores `URNPattern`; `validate.go` never reads it. From `urn_pattern`,
   the generated tier rejects 4 of the 5 g6 no-fold URNs *before any fold is consulted*
   (`repo:ffs0`, `repo:moos-config`, `agent:claude-code` — qualifier shape; `ws:hp-laptop` —
   unclaimed nid); only `kernel:mtdc.primary` is type-perfect and needs the dynamic tier.

## Result 3 — the finding had teeth upstream, twice, same night

- moos-kernel#66's replay fixture carried dead grammar (3 of 12 envelopes V3-rejected
  prospectively vs 4.0.4); confirmed and repaired upstream in `1b11ff8` — where the repair
  surfaced a **fourth** defect the pair typo had masked (seq 8's tgt was also a WF12
  `tgt_types` V4 violation). Golden hash re-baked; the replay-equivalence gate's golden now
  encodes only declared grammar.
- The WF21 `task`/`knowledge_artifact` defect was absorbed into lane A's bump scope (A15/A3).

## 2b — executed against the real 4.0.5 diff (t275, same night)

4.0.5 (kinship bump, pinned from `origin/main@5427730`) regenerated cleanly: the real-diff
flip behaves exactly like the 2a synthetic rehearsal — a WF01 `parent-of/child-of` LINK
verifies under the 4.0.5 artifacts and V3-rejects under 4.0.4; the kinship pair ZSTs exist
only in the `v4_0_5` module (compile_fail against `v4_0_4`). Measured en route:

- The full structural diff is the three kinship pairs + four `port_color_map` entries —
  §12.2 doctrine honoured (every new port shipped a JSON colour).
- **WF21's undeclared `task`/`knowledge_artifact` refs carried forward into 4.0.5** (the
  kinship-only bump did not include the A15/A3 item). Pinned loudly in the lab
  (`wf21_defect_carried_into_405`); flagged for the next bump window — no fix proposed here
  (lane A territory).

## Implication for #184 ruling 2 (the narrowed MLIR premise)

Spike B narrowed the MLIR premise to "table-driven checker, MLIR only for lowering." This
note narrows it further: **for admissibility checking, MLIR adds nothing over either a
table (data-borne path) or the host language's own type system (authored path) — and Rust's
type system covers the full V1–V4 range that IRDL cannot.** The remaining MLIR case is
lowering/pass machinery over committed moos IR, per Spike B finding #2, unchanged. Whether
that carries C++ (or reopens toward "the T274 note records Rust as the measured leader") is
Sam's ruling; this note is evidence, not a recommendation.

## Boundary of validity

Measured on rustc 1.96.0 against pinned ontologies 4.0.4/4.0.5; the WF20 dynamic tier
(types minted at runtime) is representable only as a runtime overlay past V1 — the
generated tier prices grammar promotion at regenerate+rebuild where the table tier pays a
reload. The §12.2 colour gate is not yet mirrored (its truth is split: 90 port colours
hardcoded in `operad/port_colors.go`, 6 now in ontology JSON — round-2 measurement in
progress). WF15's declared pair is the literal string `{semantic}`, which the oracle
string-matches (`linkPairDeclared`) — recorded in lane A's A15 ledger.

---
authored-by: agent:claude-cowork.hp-z440 · session:urn:moos:session:sam.z440-cowork-workspace · convo "mtdc-lab lane (t274+)" · harness 5206ec29 · lane E · sources: mtdc-lab@d4916ca (private), moos-kernel@f0a3995 (#66), ffs0@5427730
