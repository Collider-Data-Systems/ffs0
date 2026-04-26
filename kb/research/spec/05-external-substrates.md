# §5 External-world substrates

> Round-14 comprehensive architecture spec, section 5.
> Multi-author: Cowork-laptop authors hp-laptop-side observations; Cowork-Z440 authors Z440-side; Wolfram synthesizes at round-close.
> Status: **draft, in-flight authoring** — hp-laptop section landed; Z440 + synthesis pending.

---

## 5.0 Section scope

How HG nodes locate their truth — does it live in the kernel log, in an external channel, in session-cache, or in some cached projection. The substrate property (proposed `v314-4-substrate-property` per `kb/research/session/20260424-t175-program-authoring-fabric.md` §4) tags every node so downstream queries can route reads to the right surface and apply the right freshness policy.

This section is the architecture-spec face of fabric §4. It is hp-laptop-side observations of substrate values applied to nodes already on the hp-laptop sovereign log; companion observations from Z440 land below; Wolfram synthesizes the colimit.

---

## 5.1 Hp-laptop authorship — Cowork-laptop view

Authored by `agent:claude-cowork.hp-laptop`, session `sam.laptop-cowork-workspace`, on `kernel:hp-laptop.primary`. Anchors back to derivation `urn:moos:derivation:cowork-laptop.section-05-07-foundation` (T=175 ~22:44 CEST).

### 5.1.1 The four substrate values, instantiated on hp-laptop

| Substrate | Hp-laptop instances |
|---|---|
| `hg-native` | `kernel:hp-laptop.primary`, `agent:claude-{code,cowork,antigravity}.hp-laptop`, all `session:sam.{governance,laptop-cowork-workspace,laptop-moos-diary}`, `purpose:sam.*`, `group:sam`, `role:superadmin`, `derivation:cowork-laptop.section-05-07-foundation`, all WF19 LINKs. Truth is the log; replay reproduces them. |
| `external-channel` | The 4 Workspace `channel:google.{gmail,calendar,drive,tasks}.sam` nodes (log_seq 600-603) and every `knowledge_item` derived from them — concretely, the 12 KIs from the T=174 chunker proof (`urn:moos:ki:gdrive.glossary` + `.s01..s11`). Their `source_url` points outside HG; `substrate_anchor_urn` resolves to the parent channel; freshness depends on G-direction re-ingest. |
| `volatile` | None on hp-laptop log today. The category exists for future leaf-fire intermediates that never persist (per fabric §5 leaf semantics). First volatile node lands when the laptop seat starts firing impure-boundary leaves. |
| `cached` | None on hp-laptop log today. Reserved for future `s4_cache_contract`-governed projections (e.g., per-session agent_capabilities_cache). No hp-laptop projections exist yet. |

### 5.1.2 The chunker-proof anchor — substrate as observed in T=174

The T=174 chunker proof (hp-laptop log_seq 604-627) is the cleanest existence proof of `external-channel` substrate on this kernel. The 12 KIs (`gdrive.glossary` umbrella + 11 H2 sections) all carry:

```
substrate              = external-channel
substrate_anchor_urn   = urn:moos:channel:google.drive.sam
source_url             = https://docs.google.com/document/d/1YVXI8Gp.../edit[#sNN]
```

Per §4.2 disjointness, the same external substrate (the Drive doc) backs two HG observations — one on Z440 (log_seq 307-331), one on hp-laptop (604-627). Substrate property doesn't need to encode that disjointness; it just records "this node points outward." The federation surface (router, future twin-sync) reconciles cross-kernel.

### 5.1.3 Backfill posture for hp-laptop

When `v314-4-substrate-property` promotes:

- All hp-laptop nodes minted before the bump get `substrate=hg-native` defaulted on next ontology load. No per-node MUTATE needed.
- The 12 chunker-proof KIs get `substrate=external-channel` + `substrate_anchor_urn` resolved from their `source_url` prefix (`https://docs.google.com/document/...` → `channel:google.drive.sam`). Single backfill pass.
- The 4 channel nodes themselves are the substrate boundary — they're `hg-native` (their identity is the kernel log), but they expose `provides-kb` LINKs that targets carry `substrate=external-channel`.

### 5.1.4 Federation-symmetry preflight gap, restated as substrate observation

The T=174 preflight gap (hp-laptop log was missing the 4 channels; caught at first chunker fire as `ValidateLINK src not found`) is also a substrate-correctness observation. The chunker assumed a `substrate=external-channel` KI could LINK to its `substrate_anchor_urn` channel; the channel nodes had to exist on this kernel's log first. Sovereign-log discipline means the preflight is per-kernel, even when the external substrate is shared. The fix (4-envelope ADD batch at log_seq 600-603 mirroring Z440 259-262) is the per-kernel substrate-anchor materialization step.

### 5.1.5 Pre-WF21 transitional citation

The substrate proposal in fabric §4 lists `substrate_anchor_urn` as `immutable, when substrate=external-channel`. Pre-WF21, no `caused-by` LINK exists from a KI back to the channel (only the WF12 `provides-kb` reverse direction). The substrate_anchor_urn property is the transitional citation bridge: it carries the pointer the future causation edge will encode. On WF21 promotion, a one-shot LINK-batch can lift every external-channel KI into a `caused-by` edge to its substrate_anchor_urn channel without a property migration — the property already names the target.

---

## 5.2 Z440 authorship — Cowork-Z440 view

> _Stub — to be authored by `agent:claude-cowork.hp-z440`, session `sam.z440-cowork-workspace`, on `kernel:hp-z440.primary`. Expected content: Z440-side substrate observations; the 13-KI chunker proof at log_seq 307-331; the 7-derivation backfill at 345-351 as `hg-native` examples; any GitHub-channel substrate notes from the projection side; Z440-side `volatile`/`cached` observations if applicable._

---

## 5.3 Synthesis — Wolfram

> _Stub — to be authored by `agent:claude-code.hp-z440`, session `sam.kernel-proper`. Expected content: cross-kernel colimit of §5.1 + §5.2; reconciliation of disjoint observations of shared external substrates; final substrate-value taxonomy with hp-laptop + Z440 examples; promotion-ready spec text for `v314-4-substrate-property`._

---

## 5.4 Anchors back to round-14 derivation

Provenance anchors for §5.1 (per `urn:moos:derivation:cowork-laptop.section-05-07-foundation` `stochastic_weights.anchors`):

- `anchor-01-chunker-proof` — log_seq 604-627 — gdrive.glossary umbrella + 11 sections
- `anchor-02-federation-preflight-gap` — log_seq 600-603 — 4-channel mirror
- `anchor-05-doctrine-fabric` — fabric §4 maps to this section
- `anchor-06-cross-machine-cooperation` — authorship partition

YouTube ingest anchor (anchor-04) flows into §5.1 once the round-14 YouTube chunker batch lands on hp-laptop log; its KIs will demonstrate `substrate=external-channel` with `substrate_anchor_urn = channel:google.youtube.sam` (channel node minting pending).
