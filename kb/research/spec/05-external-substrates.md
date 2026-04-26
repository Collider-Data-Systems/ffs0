# Section 05 — External Substrates

> Architecture Specification §5 — External Substrates Foundation
> Co-authored by Cowork-Z440 (`§5.0`, `§5.2`, `§5.4`) and Cowork-laptop (`§5.1`).
> Derived from: `urn:moos:derivation:cowork-z440.section-05-07-foundation` (Z440 side)
> + `urn:moos:derivation:cowork-laptop.section-05-07-foundation` (hp-laptop side).
> Authoring lanes: `agent:claude-cowork.hp-z440` on `session:sam.z440-cowork-workspace` (emit-target `kernel:hp-z440.primary :8000`); `agent:claude-cowork.hp-laptop` on `session:sam.laptop-cowork-workspace` (emit-target `kernel:hp-laptop.primary :8000`). Branches: `cowork-z440/r14-section-5-7` + `cowork-laptop/r14-section-5-7`. Wolfram synthesizes `§5.3` at round-close on `main`.

## §5.0 — Frame

External substrates are everything the kernel observes but does not author: Google Workspace surfaces (Gmail / Calendar / Drive / Tasks), GitHub repos and project boards, the host filesystem (Pictures / Videos / arbitrary folders), Cowork's own artifact library, and eventually any MCP-exposed third-party SaaS. They live outside the HG by construction; the HG attends to them via `channel` S2 nodes (one per surface per principal) and ingests their content via the G-direction adjunction (`F: HG → Ext`, `G: Ext → HG`, `F ⊣ G`). External state is a substrate, not a sub-graph: it changes without our consent, persists when we sleep, and obeys laws we did not write.

Three invariants hold across both sovereign-log views:

1. **Channel as boundary.** Every external surface is reified as exactly one `channel` node per (surface × principal). The channel carries the substrate-correctness metadata (`source_uri`, `kind`, `status`); no node downstream of it has authority to redefine where the bytes live.
2. **G-direction is observation, not capture.** Ingest creates `knowledge_item` chunks pinned to a session via `pins-urn` (D19.3 proposed) or `scope_pins` property (transitional). The chunks reference the source URL; they do not own the source. Re-ingest is a fresh observation, not a state replay.
3. **Per-kernel sovereign observation.** Two kernels watching the same external substrate produce two independent observation logs. The disjointness invariant in `cowork-as-occupant.md §4.2` is what makes `Ext` safe to share without making `HG` shared.

§5.1 covers hp-laptop sovereign-log observations. §5.2 covers Z440 sovereign-log observations. §5.3 (Wolfram) reconciles into a single substrate axiomatization.

## §5.1 — hp-laptop sovereign-log view

> Authored by Cowork-laptop on branch `cowork-laptop/r14-section-5-7`.
> Cited anchors per `urn:moos:derivation:cowork-laptop.section-05-07-foundation` (anchors 1–7).
> Content lives on the parallel branch; merged into main at round-close synthesis.

*[Branch-merge stub. Z440 working tree does not have laptop's section content. Wolfram folds at round-close.]*

## §5.2 — Z440 sovereign-log view

### §5.2.1 — The multiplex-host case

`kernel:hp-z440.primary` (:8000) hosts six concurrent sessions as of T=175: `sam.kernel-proper` (Wolfram), `sam.mvp-delivery` (Wolfram-multiplex), `sam.z440-cowork-workspace` (me), `sam.moos-diary` (AG-Z440), `sam.karpathy-seat` (`agent:vscode.hp-z440.lola`, pre-seated), `sam.steinberger-seat` (`agent:vscode.hp-z440.menno`, pre-seated). Five federation kernels (`:8001` lola, `:8002` menno, `:8003` moos) carry the metadata side of `WF19 opens-on` only; emits route to `:8000` until §M9 twin sync lands.

The substrate consequence: a single sovereign log carries six emit lanes' observations of the same external substrates. Same Drive doc may be chunked from different sessions on the same kernel. Same Workspace channel-node serves as scope pin for multiple sessions concurrently. Distinct from hp-laptop's three-session simpler-host topology — multiplex pressure tests substrate-side invariants that one-session-per-kernel doesn't surface.

### §5.2.2 — Channel substrate as bootstrap origin

The four Workspace channel nodes (`channel:google.{gmail,calendar,drive,tasks}.sam`) were ADDed on Z440 first at log_seq 256–262 (T=173 ~11:30 CEST) by Wolfram's kernel-actor seeding batch — before any Cowork instance had emitted. Hp-laptop mirrored at log_seq 600–603 on T=174. The temporal asymmetry is structural, not accidental:

- The kernel that brings up the substrate first becomes the *substrate-bootstrap origin*. Its log carries the `created_at` truth; peer kernels carry mirror observations with their own `retrieved_at`.
- Federation-symmetry preflight: a Cowork emission against a substrate channel that doesn't exist on the local kernel fails at `node not found`. Hp-laptop hit this at first chunker fire (caught at log_seq 600–603 prereq batch). Z440 didn't hit it because Z440 was the bootstrap origin.
- This generalizes: any sovereign log that observes an external substrate must materialize the channel locally before its own ingest can succeed. Federation reconciliation is *not* a substitute for local channel ADD.

### §5.2.3 — Observer kinds and `actor` discipline

Three actor classes touch external substrate from Z440's log:

| Actor class | Example | Substrate access | M11 path |
|---|---|---|---|
| Kernel actor | `kernel:hp-z440.primary` | All — bootstraps channels, emits sweep-driven self-MUTATEs | bypasses §M11 |
| Agent actor (single-session) | `agent:claude-cowork.hp-z440` (me), `agent:antigravity.hp-z440` (Moos) | Channels in own session's `scope_pins` only | inferred-session via `has-occupant` reverse-lookup |
| Agent actor (multi-session) | `agent:claude-code.hp-z440` (Wolfram on `sam.kernel-proper` + `sam.mvp-delivery`) | Per-session via explicit `session_urn` on each envelope | `ResolveSessionExplicit` |

The §M13 closure (PR #33 b1de4ff) makes both single-session-inferred and multi-session-explicit paths tick `local_t`. Substrate access is uniform; what differs is which session the tick lands on.

### §5.2.4 — v3.14 ontology lift

The T=175 ~19:00 ceremony promoted `derivation` (S2) into the runtime operad. Substrate consequence: doctrine itself becomes graph-resident. The seven backfilled derivations at log_seq 345–351 reify `t169.session-generalization`, `t172.cowork-as-occupant`, `t172.wolframs-court`, `t173.meta-agent-scheduler`, `t175.program-authoring-fabric`, `t187.kernel-proper-spec`, `t171.multimodal-diary-personas` — past-round inference-witnesses now queryable as substrate. This section's authoring derivation (`urn:moos:derivation:cowork-z440.section-05-07-foundation`) joins the same surface.

The substrate property (per `t175.program-authoring-fabric`, v314-4 candidate) declares what substrate a node-type belongs to (`hg-native` for kernel/session/program; `external-channel` for `knowledge_item` chunks observed via channels; `compute` / `storage` for runtime-emergent infrastructure). Z440-side observation: the multiplex-host case lights up the `hg-native + external-channel` boundary with high traffic, making substrate-tagging maintenance an active concern, not a future one.

### §5.2.5 — Cowork artifact library as a fifth substrate

Beyond the four Workspace channels, my own artifact library (`mcp__cowork__list_artifacts`) is a substrate this seat authors directly. Per `cowork-as-occupant.md §3.2`, library content is opt-in into HG (chunker invocation explicit, no auto-pin). T=175 substrate count: 0 artifacts persisted to HG yet (this session is HITL-driven, no scheduled chunker sweep fired). Round-15 candidate: pin the round-13 broader-picture artifacts retroactively as a chunker test.

## §5.3 — Synthesis

> Wolfram authoring lane. Stub at round-close.

*[Pending Wolfram synthesis. Both Cowork branches feed here; expected scope: unify §5.1 + §5.2 into a single substrate axiomatization that covers the hp-laptop simpler-host case + the Z440 multiplex-host case under one schema; reconcile substrate-property tagging with the v314-4 grammar fragment; cross-cite the F-direction (`programs → calendar / tasks`) skill that pairs with `moos-workspace-ingest`.]*

## §5.4 — Anchors and provenance

This section's authoring `derivation` carries the full anchor list. Z440 side anchor map:

| Anchor id | Cited where in §5.2 |
|---|---|
| `anchor-01-z440-chunker-proof` | §5.2 frame; §5.2.5 |
| `anchor-02-channel-substrate-priority` | §5.2.2 |
| `anchor-03-m13-closure` | §5.2.3 |
| `anchor-04-ontology-v3-14-ceremony` | §5.2.4 |
| `anchor-05-multiplex-host-evidence` | §5.2.1 |
| `anchor-06-cross-machine-cooperation` | §5.0; §5.1 stub |
| `anchor-07-laptop-chunker-proof-reciprocity` | §5.2.2 (federation-symmetry preflight) |

On WF21 promotion, each anchor lifts to an outbound `consumes` LINK on the derivation node (no property migration; current pre-WF21 inline-JSON shape is the transitional carrier). Cross-citation to `urn:moos:derivation:cowork-laptop.section-05-07-foundation` via `anchor-06.peer_derivation_urn` becomes a `causes` / `caused-by` LINK.
