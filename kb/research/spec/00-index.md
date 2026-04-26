# mo:os Comprehensive Architecture — Master Scaffold

> Multi-author, multi-round canonical architecture spec for mo:os.
> Round-14 deliverable scaffold (T=176, opened by Wolfram on `session:sam.kernel-proper`).
> Derived from `urn:moos:derivation:wolfram.spec-master-scaffold` (Z440 :8000 sovereign log).
> Lives at `kb/research/spec/`. Each `NN-<slug>.md` is one section; this file is the TOC + cross-reference grid + status board.

---

## Why this exists

mo:os has reached fan-out capacity at T=175. Round-12 closed §M13 (heartbeat now reliable across the federation). Round-13 promoted `derivation` (S2) into the runtime operad — doctrine becomes graph-resident. The 8-seat persona-lattice is operational across two machines. The constraint that prevented delegated work — no reliable heartbeat, no derivation type, no per-seat tooling — is gone.

Round-14 produces the canonical statement of **what mo:os is**, with each persona authoring the slices their seat is shaped for, and the HG itself carrying the data: every section is both an `.md` file (S4 projection) and a `derivation` node (S2 graph object). The `.md` files are read-only doctrine surfaces; the derivations are queryable substrate. Both adjoints firing on the same deliverable.

---

## Section grid

| § | Title | Primary author | Co-author / reviewer | Branch | Derivation URN | Status |
|---|---|---|---|---|---|---|
| §0 | Foundations | Wolfram | Guido (audit) | `wolfram/r14-master-scaffold` | `derivation:wolfram.section-00-foundations` | scaffold-only |
| §1 | Categorical formalism | Karpathy | Wolfram | (uncommitted, working tree) | `derivation:karpathy.section-01-categorical-formalism` (Z440 log_seq 353) | ✅ derivation; md walking confidence 0.5→0.85 |
| §2 | Session as program-authoring layer | Wolfram | Karpathy | `wolfram/r14-master-scaffold` | `derivation:wolfram.section-02-program-authoring-layer` | scaffold-only |
| §3 | Kernel internals | Wolfram | — | `wolfram/r14-master-scaffold` | `derivation:wolfram.section-03-kernel-internals` | scaffold-only |
| §4 | Federation topology | Wolfram | Steinberger | `wolfram/r14-master-scaffold` | `derivation:wolfram.section-04-federation-topology` | scaffold-only |
| §5 | External-world substrates | Cowork-Z440 + Cowork-laptop | Wolfram (synthesis §5.3) | `cowork-z440/r14-section-5-7` + `cowork-laptop/r14-section-5-7` | `derivation:cowork-z440.section-05-07-foundation` (Z440 log_seq 361) + `derivation:cowork-laptop.section-05-07-foundation` (hp-laptop log_seq 657) | ✅ §5.0 + §5.1 + §5.2 + §5.4; §5.3 synthesis pending |
| §6 | Multimodal substrate | Moos (AG-Z440) + AG-laptop | Cowork-laptop | `main` (commit 6edd687) | `derivation:moos.section-06-multimodal-substrate-foundation` + `derivation:ag-laptop.section-06-multimodal-substrate-foundation` (hp-laptop log_seq 635) | ✅ both halves landed |
| §7 | Time fabric + cycles | Cowork-Z440 + Cowork-laptop | Wolfram (synthesis §7.3) | `cowork-z440/r14-section-5-7` + `cowork-laptop/r14-section-5-7` | (shared with §5) | ✅ §7.0 + §7.1 + §7.2 + §7.4; §7.3 synthesis pending |
| §8 | Tooling + DX | Steinberger | Guido | (pending) | `derivation:steinberger.section-08-tooling-dx-foundation` (pending) | code shipped (commits `18e02be` + `86fd46d`); md projection + derivation pending |
| §9 | Governance + audit | Guido | Wolfram | (pending) | `derivation:guido.section-09-governance-and-audit` (pending) | derivations on hp-laptop log (audit + invariant-bracketing); md pending |
| §10 | LLM substrate (Collider-LLM) | Karpathy | Wolfram | (uncommitted, working tree) | `derivation:karpathy.section-10-llm-substrate` (Z440 log_seq 355) | ✅ derivation; md walking confidence 0.5→0.85 |
| §11 | Hardware + network | Steinberger | Wolfram | (pending) | `derivation:steinberger.section-11-hardware-network` (pending) | pending |
| §12 | MVP delivery integration | Wolfram | Guido (delivery audit) | `wolfram/r14-master-scaffold` | `derivation:wolfram.section-12-mvp-delivery-integration` | scaffold-only |

---

## What "scaffold-only" means for §0 / §2 / §3 / §4 / §12

These five sections are Wolfram-authored. Round-14 ships them as **scaffolds** — section header + frame + sub-section list + cross-reference anchors — not full content. Reasons:

1. The synthesis spine (this conversation) is the only seat that authors them; concentrating Wolfram time on filling all five at round-14 would bottleneck the whole spec.
2. Specialist content (§1, §5–§11) needs to land first so Wolfram can cross-reference accurately.
3. Round-15+ pace fills the scaffolds: §0 + §2 in round-15, §3 + §4 in round-16, §12 in round-17 timed against MVP gate prep. Each fill is one Wolfram round of work.

The scaffolds are committed at round-14 close so the TOC is complete and the cross-reference grid is anchored. Specialists can write `→ §3.2 Kernel sweep loop` knowing the anchor will exist when their section lands; Wolfram fills §3.2 itself in round-16.

---

## Cross-reference grid (initial)

What each section's authoring derivation expects to consume from neighbors:

```
§0  →  consumes: §1 nomenclature; §2 session-as-author primitive; §3 kernel internals frame
§1  →  consumes: §2 derivation as first-class; §6 multimodal as functor-target; §10 LLM as F⊣G case
§2  →  consumes: §1 categorical frame; §3 kernel runtime; §7 time fabric; §9 governance
§3  →  consumes: §0 four-rewrites; §2 session model; §4 federation; §13 hardware (deferred)
§4  →  consumes: §3 kernel internals; §11 hardware; §7 federation time
§5  →  consumes: §1 channel as cooperad; §2 substrate property; §6 external multimodal; §7 ingest cadence
§6  →  consumes: §1 encoder-as-functor; §5 external substrate frame; §10 multimodal-LLM
§7  →  consumes: §2 fabric note; §3 sweep loop; §5 cyclic-clock anchored to channels; §9 round cadence
§8  →  consumes: §3 kernel internals; §4 federation; §9 audit harness; §11 hardware
§9  →  consumes: §2 inference-visibility; §8 harness; §11 sovereignty boundaries
§10 →  consumes: §1 categorical formalism; §6 multimodal; §2 derivation-as-training-evidence
§11 →  consumes: §4 federation; §3 transport; §8 DX
§12 →  consumes: all of §0..§11; produces MVP G1..G6 mapping
```

WF21 promotion (round-15+) lifts each `consumes:` arrow to a typed `consumes` LINK; this is the property-form pre-figuration of the topology-form citation graph.

---

## Status board

**Round-14 specialist contributions landed:**

- ✅ **§1 + §10** — Karpathy on Z440 :8000 (log_seq 353/355), md projections in working tree (uncommitted; walking confidence 0.5 → 0.85)
- ✅ **§5 + §7** — Cowork pair, **first cross-kernel sovereign-log reciprocity** (Z440 :8000 log_seq 361 + hp-laptop :8000 log_seq 657, with anchor-03 perspective-flipped + anchor-07 chunker-proof mirror)
- ✅ **§6** — Moos AG-Z440 + AG-laptop (commit `6edd687` on main + hp-laptop log_seq 635)

**Round-14 specialist contributions pending:**

- ⏳ **§8** — Steinberger: harness shipped as code; derivation ADD + md projection pending
- ⏳ **§9** — Guido: hp-laptop derivations on log (audit + invariant-bracketing); md projection pending
- ⏳ **§11** — Steinberger: pending

**Round-14 Wolfram scaffolds (this branch):**

- ⏳ **§0 / §2 / §3 / §4 / §12** — scaffold-only ADDs in this commit; full fills round-15+

---

## Doctrinal milestones round-14 surfaced

Three meta-doctrinal claims emerged across round-14, each worth folding into §9's transitional-citation-surface sub-section once Guido authors it:

1. **Invariant-bracketing.** Every invariant gains a `(preflight_gate, post_hoc_audit)` pair. §M11 + §M12 + §M13 are preflight; the audit-pattern is post-hoc; both registers must reach the same coherence-verdict for canonical operation. (Surfaced by Guido's A.4 first live pass on Karpathy's §1 derivation.)

2. **`stochastic_weights` as transitional citation surface.** Pre-WF21 evidence-references live in property form (inline JSON); post-WF21 they migrate to structural LINKs. The lattice's referential coherence is **property-encoded before topology-encoded** — Karpathy's §1 cites 7 anchors via `stochastic_weights`, demonstrating cross-persona dependency without WF21 needing to ship first.

3. **Cross-kernel referential coherence.** The Cowork pair's reciprocity (anchor-03 perspective-flipped + anchor-07 chunker-proof mirror) is the **first pre-§M9 instance of HG-resident cross-kernel coherence**. Property-form citations across two unsynced sovereign logs prefigure what §M9 twin-link adjoint sync will eventually do structurally. The `citation_format` string both Cowork seats carry is the migration spec; clean lift on WF21 + §M9 promotion, no re-author.

The unified statement: *the lattice's referential coherence is property-form-first, topology-form-eventual; this holds within-kernel (Karpathy citing 7 anchors), across-personae (Guido citing Karpathy citing Wolfram), and now cross-kernel (Cowork-Z440 ↔ Cowork-laptop).*

A future `claim:wolfram.cross-kernel-reciprocity-as-§M9-prefiguration` ADD will name this as round-15 fragment companion to `v314-3-wf21-causes`.

---

## Branch convention going forward (partition A locked in)

Each authoring lane gets its own `<persona>/r<NN>-<topic>` branch. Wolfram synthesizes at round-close by merging branches into main with conflict-resolution by section marker:

- `cowork-z440/r14-section-5-7` ← Cowork-Z440 (§5.2 + §7.2)
- `cowork-laptop/r14-section-5-7` ← Cowork-laptop (§5.1 + §7.1)
- `wolfram/r14-master-scaffold` ← this branch (§0/§2/§3/§4/§12 scaffolds + this index)
- (future) `karpathy/r14-section-1-10` ← when Karpathy's md confidence walks 0.5 → 0.85
- (future) `steinberger/r14-section-8-11` ← when Steinberger fires §8 / §11 derivations
- (future) `guido/r14-section-9` ← when Guido authors §9 md

Round-14 close-out: Wolfram merges all branches → main → tags `v0.14.0-spec-r14`.

---

## Next moves at round-14 round-open

1. **`#37` round-14 vehicle issue opens** with this scaffold + per-persona round-14 ask
2. **Karpathy** — walk §1 + §10 confidence 0.5 → 0.85 as md projections settle; commit on `karpathy/r14-section-1-10` branch when ready
3. **Steinberger** — fire §8 derivation ADD (`derivation:steinberger.section-08-tooling-dx-foundation`); author §11 hardware/network md; both on `steinberger/r14-section-8-11` branch
4. **Guido** — author §9 governance-and-audit md folding in invariant-bracketing pattern + transitional-citation-surface observations + topology-degenerate-vs-federated distinction; on `guido/r14-section-9` branch
5. **Cowork × 2** — board-anchor parity (4 `gh project item-create` commands per the prompt blocks); §5.3 + §7.3 synthesis at round-close (Wolfram's lane, but Cowork can flag rough edges in their own branches)
6. **Moos + AG-laptop** — round-15 ingestion of the multimodal pile (8 videos + 2 jpegs + 2 markdown files + future YouTube); each ingest fire produces a `knowledge_item` chunk batch + walks §6 confidence
7. **Wolfram** — fill §0 / §2 / §3 / §4 / §12 scaffolds across rounds 15-17; round-17 final pass timed against MVP G1-G6 prep at T=190

---

## Hydration entrypoint

For any persona arriving fresh:

- Read `kb/superset/running-state.md` (T-day, kernel state, open items, key URNs)
- Read this file (TOC + status board)
- Read your section's own md (the one you're authoring)
- Read your persona's skill (`~/.claude/skills/moos-<persona-skill>/SKILL.md`)

Cross-references in this file are stable anchors; section content beneath each `NN-<slug>.md` is what changes round-to-round.

---

— Wolfram, `session:sam.kernel-proper`, `kernel:hp-z440.primary`, T=176 ~13:00 CEST. Master scaffold authored; round-14 vehicle ready to open.
