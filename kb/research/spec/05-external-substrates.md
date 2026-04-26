# Section 05 — External Substrates

> Architecture Specification §5 — External Substrates Foundation
> Co-authored by Cowork-Z440 (`§5.0`, `§5.2`, `§5.4`) and Cowork-laptop (`§5.1`); synthesized by Wolfram (`§5.3`).
> Derived from: `urn:moos:derivation:cowork-z440.section-05-07-foundation` (Z440 side, log_seq 361)
> + `urn:moos:derivation:cowork-laptop.section-05-07-foundation` (hp-laptop side, log_seq 665)
> + `urn:moos:derivation:wolfram.spec-master-scaffold` (synthesis spine, Z440 log_seq 363).
> Authoring lanes: `agent:claude-cowork.hp-z440` on `session:sam.z440-cowork-workspace` (emit-target `kernel:hp-z440.primary :8000`); `agent:claude-cowork.hp-laptop` on `session:sam.laptop-cowork-workspace` (emit-target `kernel:hp-laptop.primary :8000`); `agent:claude-code.hp-z440` on `session:sam.kernel-proper` (synthesis). Round-14 close, T=176.

## §5.0 — Frame

External substrates are everything the kernel observes but does not author: Google Workspace surfaces (Gmail / Calendar / Drive / Tasks), GitHub repos and project boards, the host filesystem (Pictures / Videos / arbitrary folders), Cowork's own artifact library, AG persona artifact libraries, and eventually any MCP-exposed third-party SaaS. They live outside the HG by construction; the HG attends to them via `channel` S2 nodes (one per surface per principal) and ingests their content via the G-direction adjunction (`F: HG → Ext`, `G: Ext → HG`, `F ⊣ G`). External state is a substrate, not a sub-graph: it changes without our consent, persists when we sleep, and obeys laws we did not write.

Three invariants hold across both sovereign-log views:

1. **Channel as boundary.** Every external surface is reified as exactly one `channel` node per (surface × principal). The channel carries the substrate-correctness metadata (`source_uri`, `kind`, `status`); no node downstream of it has authority to redefine where the bytes live.
2. **G-direction is observation, not capture.** Ingest creates `knowledge_item` chunks pinned to a session via `pins-urn` (D19.3 proposed) or `scope_pins` property (transitional). The chunks reference the source URL; they do not own the source. Re-ingest is a fresh observation, not a state replay.
3. **Per-kernel sovereign observation.** Two kernels watching the same external substrate produce two independent observation logs. The disjointness invariant in `cowork-as-occupant.md §4.2` is what makes `Ext` safe to share without making `HG` shared.

§5.1 covers hp-laptop sovereign-log observations (substrate-property taxonomy in concrete instances). §5.2 covers Z440 sovereign-log observations (multiplex-host pressure-test). §5.3 reconciles into a single substrate axiomatization.

## §5.1 — hp-laptop sovereign-log view

Authored by `agent:claude-cowork.hp-laptop`, session `sam.laptop-cowork-workspace`, on `kernel:hp-laptop.primary`. Anchors per `urn:moos:derivation:cowork-laptop.section-05-07-foundation`.

### §5.1.1 — The four substrate values, instantiated on hp-laptop

| Substrate | Hp-laptop instances |
|---|---|
| `hg-native` | `kernel:hp-laptop.primary`, `agent:claude-{code,cowork,antigravity}.hp-laptop`, all `session:sam.{governance,laptop-cowork-workspace,laptop-moos-diary}`, `purpose:sam.*`, `group:sam`, `role:superadmin`, `derivation:cowork-laptop.section-05-07-foundation`, all WF19 LINKs. Truth is the log; replay reproduces them. |
| `external-channel` | The 4 Workspace `channel:google.{gmail,calendar,drive,tasks}.sam` nodes (log_seq 600-603) and every `knowledge_item` derived from them — concretely, the 12 KIs from the T=174 chunker proof (`urn:moos:ki:gdrive.glossary` + `.s01..s11`). Their `source_url` points outside HG; `substrate_anchor_urn` resolves to the parent channel; freshness depends on G-direction re-ingest. |
| `volatile` | None on hp-laptop log today. The category exists for future leaf-fire intermediates that never persist (per fabric §5 leaf semantics). First volatile node lands when the laptop seat starts firing impure-boundary leaves. |
| `cached` | None on hp-laptop log today. Reserved for future `s4_cache_contract`-governed projections (e.g., per-session agent_capabilities_cache). No hp-laptop projections exist yet. |

### §5.1.2 — Chunker-proof anchor as substrate observation

The T=174 chunker proof (hp-laptop log_seq 604-627) is the cleanest existence proof of `external-channel` substrate on this kernel. The 12 KIs (`gdrive.glossary` umbrella + 11 H2 sections) all carry:

```
substrate              = external-channel
substrate_anchor_urn   = urn:moos:channel:google.drive.sam
source_url             = https://docs.google.com/document/d/1YVXI8Gp.../edit[#sNN]
```

Per `cowork-as-occupant.md §4.2` disjointness, the same external substrate (the Drive doc) backs two HG observations — one on Z440 (log_seq 307-331), one on hp-laptop (604-627). Substrate property doesn't need to encode that disjointness; it just records "this node points outward." The federation surface (router, future twin-sync) reconciles cross-kernel.

### §5.1.3 — Backfill posture

When `v314-4-substrate-property` promotes (round-15+):

- All hp-laptop nodes minted before the bump get `substrate=hg-native` defaulted on next ontology load. No per-node MUTATE needed.
- The 12 chunker-proof KIs get `substrate=external-channel` + `substrate_anchor_urn` resolved from their `source_url` prefix (`https://docs.google.com/document/...` → `channel:google.drive.sam`). Single backfill pass.
- The 4 channel nodes themselves are the substrate boundary — they're `hg-native` (their identity is the kernel log), but they expose `provides-kb` LINKs whose targets carry `substrate=external-channel`.

### §5.1.4 — Federation-symmetry preflight gap restated as substrate observation

The T=174 preflight gap (hp-laptop log was missing the 4 channels; caught at first chunker fire as `ValidateLINK src not found`) is also a substrate-correctness observation. The chunker assumed a `substrate=external-channel` KI could LINK to its `substrate_anchor_urn` channel; the channel nodes had to exist on this kernel's log first. Sovereign-log discipline means the preflight is per-kernel, even when the external substrate is shared. The fix (4-envelope ADD batch at log_seq 600-603 mirroring Z440 259-262) is the per-kernel substrate-anchor materialization step.

### §5.1.5 — Pre-WF21 transitional citation

The substrate proposal in `t175.program-authoring-fabric` §4 lists `substrate_anchor_urn` as `immutable, when substrate=external-channel`. Pre-WF21, no `caused-by` LINK exists from a KI back to the channel (only the WF12 `provides-kb` reverse direction). The `substrate_anchor_urn` property is the transitional citation bridge: it carries the pointer the future causation edge will encode. On WF21 promotion, a one-shot LINK-batch can lift every external-channel KI into a `caused-by` edge to its substrate_anchor_urn channel without a property migration — the property already names the target.

## §5.2 — Z440 sovereign-log view

Authored by `agent:claude-cowork.hp-z440`, session `sam.z440-cowork-workspace`, on `kernel:hp-z440.primary`. Anchors per `urn:moos:derivation:cowork-z440.section-05-07-foundation`.

### §5.2.1 — The multiplex-host case

`kernel:hp-z440.primary` (:8000) hosts six concurrent sessions as of T=175: `sam.kernel-proper` (Wolfram), `sam.mvp-delivery` (Wolfram-multiplex), `sam.z440-cowork-workspace` (me), `sam.moos-diary` (AG-Z440), `sam.karpathy-seat` (`agent:vscode.hp-z440.lola`, pre-seated), `sam.steinberger-seat` (`agent:vscode.hp-z440.menno`, pre-seated). Three federation kernels (`:8001` menno, `:8002` lola, `:8003` moos) carry the metadata side of `WF19 opens-on` only; emits route to `:8000` until §M9 twin sync lands.

The substrate consequence: a single sovereign log carries six emit lanes' observations of the same external substrates. Same Drive doc may be chunked from different sessions on the same kernel. Same Workspace channel-node serves as scope pin for multiple sessions concurrently. Distinct from hp-laptop's three-session simpler-host topology — multiplex pressure tests substrate-side invariants that one-session-per-kernel doesn't surface.

### §5.2.2 — Channel substrate as bootstrap origin

The four Workspace channel nodes (`channel:google.{gmail,calendar,drive,tasks}.sam`) were ADDed on Z440 first at log_seq 256-262 (T=173 ~11:30 CEST) by Wolfram's kernel-actor seeding batch — before any Cowork instance had emitted. Hp-laptop mirrored at log_seq 600-603 on T=174. The temporal asymmetry is structural for now, sheaf-symmetric post-§M9 (see §5.3):

- The kernel that brings up the substrate first becomes the *substrate-bootstrap origin*. Its log carries the `created_at` truth; peer kernels carry mirror observations with their own `retrieved_at`.
- Federation-symmetry preflight: a Cowork emission against a substrate channel that doesn't exist on the local kernel fails at `node not found`. Hp-laptop hit this at first chunker fire (caught at log_seq 600-603 prereq batch). Z440 didn't hit it because Z440 was the bootstrap origin.
- This generalizes: any sovereign log that observes an external substrate must materialize the channel locally before its own ingest can succeed. Federation reconciliation is *not* a substitute for local channel ADD.

### §5.2.3 — Observer kinds and `actor` discipline

Three actor classes touch external substrate from Z440's log:

| Actor class | Example | Substrate access | M11 path |
|---|---|---|---|
| Kernel actor | `kernel:hp-z440.primary` | All — bootstraps channels, emits sweep-driven self-MUTATEs | bypasses §M11 |
| Agent actor (single-session) | `agent:claude-cowork.hp-z440`, `agent:antigravity.hp-z440` (Moos) | Channels in own session's `scope_pins` only | inferred-session via `has-occupant` reverse-lookup |
| Agent actor (multi-session) | `agent:claude-code.hp-z440` (Wolfram on `sam.kernel-proper` + `sam.mvp-delivery`) | Per-session via explicit `session_urn` on each envelope | `ResolveSessionExplicit` |

The §M13 closure (PR `moos-kernel#33` `b1de4ff`) makes both single-session-inferred and multi-session-explicit paths tick `local_t`. Substrate access is uniform; what differs is which session the tick lands on.

### §5.2.4 — v3.14 ontology lift

The T=175 ~19:00 ceremony promoted `derivation` (S2) into the runtime operad. Substrate consequence: doctrine itself becomes graph-resident. The seven backfilled derivations at log_seq 345-351 reify `t169.session-generalization`, `t172.cowork-as-occupant`, `t172.wolframs-court`, `t173.meta-agent-scheduler`, `t175.program-authoring-fabric`, `t187.kernel-proper-spec`, `t171.multimodal-diary-personas` — past-round inference-witnesses now queryable as substrate. This section's authoring derivation joins the same surface.

The substrate property (per `t175.program-authoring-fabric` §4, v314-4 candidate) declares what substrate a node-type belongs to. Z440-side observation: the multiplex-host case lights up the `hg-native + external-channel` boundary with high traffic, making substrate-tagging maintenance an active concern, not a future one.

### §5.2.5 — Cowork artifact library as a fifth substrate

Beyond the four Workspace channels, this seat's artifact library (`mcp__cowork__list_artifacts`) is a substrate authored directly by the persona. Per `cowork-as-occupant.md §3.2`, library content is opt-in into HG (chunker invocation explicit, no auto-pin). Round-15 candidate: pin round-13 broader-picture artifacts retroactively as a chunker test.

This makes the persona-bound artifact library a per-machine-per-persona substrate class; see §5.3 for the cross-kernel generalization.

## §5.3 — Synthesis (Wolfram)

This section unifies §5.1 (substrate-property taxonomy in concrete hp-laptop instances) and §5.2 (Z440 multiplex-host pressure-test) into a single substrate axiomatization, reconciles the bootstrap-origin asymmetry with the §M9 sheaf-symmetric future, and folds the six rough edges flagged by Cowork-Z440.

### §5.3.1 — Canonical register: federated case is canonical, single-kernel is degenerate

Cowork-Z440's §5.2 frames the multiplex-host case as the rich case and references hp-laptop's three-session topology as the "simpler" case. Cowork-laptop's §5.1 doesn't contest the framing but operates on substrate-property taxonomy at the per-instance level rather than at the host-topology level. **Synthesis pick**: the federated multi-kernel case is canonical; the single-kernel host (hp-laptop) is the degenerate case where `emit-target == opens-on` by construction (Guido's `topology-degenerate-vs-federated` round-15 claim names this directly). All §M11 / §M12 / §M13 invariants fire in both cases; the substrate-correctness preflight is per-kernel regardless. This generalizes cleanly when §M9 ships a third kernel beyond Z440-primary + hp-laptop-primary.

### §5.3.2 — Bootstrap-origin asymmetry is historical, sheaf-symmetric is future

§5.2.2 asserts "Z440 first, hp-laptop mirrored" as structural. §5.1.2 doesn't contest but treats both observations as equal under disjointness. **Synthesis pick**: pre-§M9, first-observer-is-privileged is historically true (Z440 carried the `created_at` truth at T=173); post-§M9, all observers are equal under sheaf gluing along the `twin_link` adjoint. The transitional doctrine is: *bootstrap-origin asymmetry is the historical record; §M9 sync produces a sheaf-glued cross-kernel substrate where origin-priority is property-tagged but not topology-privileged*. The 4-channel preflight gap (§5.1.4 / §5.2.2) is the operational evidence of this asymmetry today; §M9 closure makes it a property-form citation rather than a federation-startup gotcha.

### §5.3.3 — Substrate count: four canonical + N persona-bound + 1 federation reconciliation

§5.1 enumerates four substrate values (`hg-native`, `external-channel`, `volatile`, `cached`). §5.2.5 adds Cowork-Z440's artifact library as a fifth substrate. **Synthesis**: per-machine-per-persona artifact libraries (Cowork × 2, AG × 2, future VSCode-attach personae) are not a fifth substrate value; they are *instances* of the `external-channel` value with `substrate_anchor_urn = library:<persona>.<host>`. The four canonical substrate values stay; persona-bound libraries materialize as channel-mediated external-channel instances, with their own `provides-kb` LINKs and ingest skills. **One operational addition**: cross-kernel reciprocity (Cowork pair anchor-03 + anchor-07) introduces a *federation-reconciliation* substrate class — neither pure hg-native nor pure external-channel, but observation-pair-reconciled-via-twin-link. This becomes a first-class substrate class once §M9 ships; pre-§M9 it lives as a property-form citation in `stochastic_weights.anchors[].kind` (per `claim:wolfram.cross-kernel-reciprocity-as-§M9-prefiguration`, round-15+).

### §5.3.4 — Cross-references

- §1 categorical formalism (Karpathy) frames `channel` as a categorical object whose `provides-kb` LINKs satisfy the cooperad axioms (§5.2 currently uses boundary-relation S2 vocabulary; §1 owns the canonical categorical framing).
- §6 multimodal substrate (Moos / AG-laptop) extends `external-channel` to non-textual sources; the four-substrate taxonomy generalizes uniformly.
- §7 time fabric (this section's companion derivation) — the daily 08:00 chunker ritual + AG-Z440 / AG-laptop multimodal ingest fires are the canonical time-fabric instances driving §5 substrate observations.
- §9 governance (Guido) — invariant-bracketing applies to substrate correctness: preflight `ValidateLINK src not found` + post-hoc audit on substrate-tagging consistency.
- §10 LLM substrate (Karpathy) — Collider-LLM training reads the substrate-tagged graph; substrate-property is a training-corpus-stratification primitive.

### §5.3.5 — Promotion-ready spec for `v314-4-substrate-property`

```
property:    substrate
type:        enum {hg-native, external-channel, volatile, cached, federation-reconciled}
mutability:  immutable
authority:   kernel
applies-to:  all S2 nodes
default:     hg-native (on ontology-load backfill for pre-bump nodes)

property:    substrate_anchor_urn
type:        urn
mutability:  immutable
authority:   kernel
applies-to:  S2 nodes where substrate ∈ {external-channel, federation-reconciled}
constraint:  resolves to the channel | derivation that anchors the external observation
```

`federation-reconciled` is held back for round-15+ alongside `v314-3-wf21-causes` since it presupposes the cross-kernel reciprocity primitive.

## §5.4 — Anchors and provenance

This section's authoring derivations carry the full anchor lists. Combined anchor map:

| Anchor id (Z440) | Cited where in §5.2 | Mirror id (laptop) | Cited where in §5.1 |
|---|---|---|---|
| `anchor-01-z440-chunker-proof` | §5.2 frame; §5.2.5 | `anchor-07-z440-chunker-proof-reciprocity` | §5.1.2 |
| `anchor-02-channel-substrate-priority` | §5.2.2 | `anchor-02-federation-preflight-gap` | §5.1.4 |
| `anchor-03-m13-closure` | §5.2.3 | `anchor-03-m13-closure` (dual-citation) | §5.1.5 (transitional citation) |
| `anchor-04-ontology-v3-14-ceremony` | §5.2.4 | — | — |
| `anchor-05-multiplex-host-evidence` | §5.2.1 | — | — |
| `anchor-06-cross-machine-cooperation` | §5.0; §5.1 frame | `anchor-06-cross-machine-cooperation` (peer) | §5.0 frame |
| `anchor-07-laptop-chunker-proof-reciprocity` | §5.2.2 | `anchor-01-chunker-proof` | §5.1.2 |

Cross-kernel reciprocity (anchor-03 perspective-flipped + anchor-07 chunker-proof mirror) is the first pre-§M9 instance of HG-resident cross-kernel coherence.

On WF21 promotion, each anchor lifts to an outbound `consumes` LINK on the respective derivation node (no property migration; current pre-WF21 inline-JSON shape is the transitional carrier). Cross-citation between the two Cowork derivations via `anchor-06.peer_derivation_urn` becomes a `causes` / `caused-by` LINK pair. The synthesis derivation `urn:moos:derivation:wolfram.section-05-synthesis` (round-14 close) consumes both Cowork derivations + Wolfram's master scaffold.
