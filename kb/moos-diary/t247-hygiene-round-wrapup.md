# T244+ → T247 — the hygiene round: closing the practice era, naming the seat

> Round wrap-up, written T=247 (2026-07-06) for Sam's eval. Covers everything since the T244
> baseline trio landed (evening of 2026-07-03): the Karpathy apply, the topology-hygiene round,
> and a persona getting its name. Predecessors on this shelf: `t244-manifold-arc-baseline-wrapup`
> (+ conversation addendum + projection snapshot). Evidence and narrative, not truth.

## What this round was for

The T244 baseline had ended on a diagnosis: the projection gate failed honestly because the
practice era (T187–T221) had left the hypergraph with unpurposed seats, orphaned purposes, a
governance workspace drowning in May-era calendar mirrors, and tooling still wired to retired
frontiers. Sam's brief was direct — *"a lot is stale or poorly wired. No shame, these surfaces
were used to practice. Inventory, then: what needs mutate, what needs add and link or unlink."*
This round did exactly that, and applied it.

## What happened, in order

**The Karpathy apply (T244+, the arc's first HG act).** The purpose wiring Guido had drafted
(#90) went onto the Z440 engine: three envelopes, atomic, log 471→475. The proof was immediate —
the same pipeline that had FAILED for the seat went to WARN, with both seat-specific checks
flipping to pass. Guido's Keep-note recheck (read over the keyless keep channel — a Keep note as
a genuine cross-seat coordination surface) closed its ledger and contributed the round's pivotal
reframe: Z440 already held **twelve** purpose nodes. The disease wasn't missing purposes — it was
**missing relations**. That one observation shrank the whole repair from "author new meaning"
to "wire what exists."

**The census (plan mode, three explorers + a live two-kernel re-census).** 26 sessions, 29
purposes (8 orphaned), 103 calendar mirrors (94% on the laptop's sovereign log), a 34-node
t195–t206 keep graveyard with a five-week-stuck `pending` OAuth op, 21 programs past their
target_t, and `sam.governance` carrying 98 pins of which 62 were practice-era calendar mirrors.
Two things the census got *wrong* were as valuable as what it got right: it read the 69%
cross-kernel asymmetry as a sync failure (it's §M9 sovereignty by design) and the same-URN
channels as duplicates (they're per-kernel observations). Doctrine had to correct the
instruments — and did, in writing, before any envelope was drafted.

**Sam's four calls.** Archive the 41-event calendar batch, never apply it. Put governance on a
cal-pin diet. Abandon all seven practice sessions. Wire the four seat-matching orphan purposes
and pin the rest. All four recommendations accepted as offered — the human gate spent its
attention on policy, not mechanics.

**The package (PR #95).** One reviewed unit: the inventory record, four apply batches (102
envelopes), the pipeline fixes, and the persona. Copilot's review earned its keep for the third
time this arc — it caught that **every UNLINK in the pin-diet batch carried a null
relation_urn** (wrong field name off the relations endpoint). The batch was regenerated from the
live list with a zero-null assertion. A practice-era cleanup nearly shipped its own practice-era
bug; the review lane caught it.

**The applies (Z440, log 475→504).** Wolfram, Steinberger, Zappa and the AG diary seat each got
their durable purpose and first scope root — the #90 shape, four more times. Orphan purposes went
8→0. The MVP-delivery session was finally marked what it has been since T219 — abandoned — and
the MVP program marked what it earned at T190: completed. Twelve Z-side programs triaged.
Every apply verified by fold readback; the seat-table drift gate stayed byte-identical
throughout, exactly as designed (purposes aren't columns; occupancy didn't move).

**The handoff (B2 → Guido, #89).** The laptop's share — the 62-pin governance diet and the
t200plus/t206 lifecycle closures — is drafted, reviewed, and waiting on the governance seat,
with a confirm-before-apply gate on the program-triage table. Still pending at T=247 (laptop
log unchanged at 1491). The reverse-#90 division of labor, now running in both directions.

**Two real bugs fixed in the tooling itself.** The chronically stale surface atlas turned out
to be a control-flow bug — the pre-atlas MVP gate *threw* on fail, silently skipping the atlas
stage; it's warn-only now, with fail semantics moved to the final gate. And the pipeline gained
a **compiler-lowering frontier lens**, so the new arc renders from its first day instead of
repeating the T187/T189 pattern of lenses frozen in a previous era.

**And the seat got a name.** Sam named this workspace's persona **Zappa** — Φ(`purpose:sam.
cowork-workspace-curation`), the very purpose this round wired. It landed the way the doctrine
says presentation should: a display-config change flowing through the generated seat table
(`--mode write`, no hand edits), a persona key with a backward-compatible alias, an `@zappa`
agent file. Identity URNs untouched; the log needed no rewrite for the seat to have a soul.

## The scoreboard at T=247

| Dimension | Before (T244 eve) | After (T247) |
|---|---|---|
| Seats with durable purpose (Z440 working seats) | 1 of 6 (Karpathy staged) | **6 of 6** |
| Orphan purposes | 8 | **0** |
| Governance pins | 98 (62 cal noise) | 98 → **36 pending Guido's B2** |
| Practice sessions still "active" | 7 | **2 Z-side closed; 5 laptop-side pending B2** |
| Overdue programs | 21 untriaged | 12 triaged+applied (Z) · 5 drafted (L) · 4 already archived |
| Pipeline gate (repaired seats) | FAIL | **WARN** (only the archived-calendar residual) |
| Persona court | 5 named + "Cowork-Z440" | **6 named — Zappa** 🎸 |

**Open tail:** Guido's B2 apply (#89) · #94 moos-lsp `--stdio` verify (Karpathy lane) ·
moos-router#5 · ProDesk power-on · the deferred channel-label fragments (joins F1–F4).

## What the round proved

Three sessions ago the canary episode established *"a claim is nothing; a protocol with an
artifact is everything."* This round extended it: **an inventory is nothing; a reviewed batch
with a fold readback is everything.** Every number in the scoreboard above is a `/state` query
away from verification, every change rode a PR with an adversarial reviewer that caught a real
bug, and the one repair that couldn't be governed (channel labels with no mutate_scope) was
deferred out loud instead of hacked around. The practice era isn't erased — the log keeps all
of it — it's *closed*: statused, triaged, unpinned from the working views, and no longer
steering the tooling. The graph now says what the fleet is actually doing. That's the baseline
the compiler-lowering arc builds on.

---
authored-by: agent:claude-cowork.hp-z440 / session:sam.z440-cowork-workspace / t247-hygiene-wrapup
