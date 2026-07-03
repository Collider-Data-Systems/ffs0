# T244 — projection-layer snapshot (the F-side of the baseline)

> Third leg of the T244 baseline, next to `t244-manifold-arc-baseline-wrapup.md` (the record)
> and `t244-conversation-context-addendum.md` (the conversations). This one is **what the
> projection pipeline itself says** when run fresh at T=244: the dry F-fold of the hypergraph
> into session pack, lenses, plans and gate. Pipeline re-run 2026-07-03 ~19:11–19:14Z, seated
> as `agent:claude-cowork.hp-z440` / `session:sam.z440-cowork-workspace`, read through the
> router fan-in `:9000`. Durable copies of the key artifacts live in
> [`t244-projection-snapshot/`](t244-projection-snapshot/) (the live originals are in
> gitignored `tmp/projections/session_pipeline/`).

## The numbers

- Folded state through the router: **797 nodes / 793 relations** (Z440 primary log 471,
  hp-laptop log 1490, twins :8001–:8003 up at log 13/11/16, ProDesk down).
- Four visual lenses regenerated ([session_occasion](t244-projection-snapshot/session_occasion_frame.svg) 41n/76e ·
  [temporal_calendar](t244-projection-snapshot/temporal_calendar_frame.svg) 22n/31e ·
  [t189_recommendation](t244-projection-snapshot/t189_recommendation_frame.svg) 124n/213e ·
  [calendar_scope](t244-projection-snapshot/calendar_scope_frame.svg) 154n/266e), plus the
  [interactive dashboard](t244-projection-snapshot/dashboard.html) (Cytoscape, all four lenses embedded).
- MVP gate ([mvp_gate.md](t244-projection-snapshot/mvp_gate.md)): **FAIL — 21 pass / 2 warn / 1 fail.**

## The gate verdict is the baseline's most honest sentence

The single FAIL is precise: `session:sam.z440-cowork-workspace` has `opens_on=1`,
`occupants=1`, **`scope_roots=0`** — the seat that just closed the whole backlog cannot serve
as a live session header because its scope pins live in the unregistered April-era
`scope_pins` *property*, invisible to the projection. The WARN beside it: the session has
**no durable `has-purpose`** — the run's focus string ("T244 baseline snapshot before the
compiler-lowering arc…") is doing duty as a temporary occasion color
([session_pack.md](t244-projection-snapshot/session_pack.md) shows Purposes/Scope Roots/Owners
all `<none>` while identity reconciliation passes cleanly).

And the engineering slices generalize it: **nearly every session in the graph lacks a visible
`has-purpose`** (kernel-proper, moos-diary, both cowork workspaces, karpathy-seat,
hpprodesk-setup, …). PR #90's staged apply fixes exactly one seat — the Karpathy one — but the
gate shows it's a *class*, precisely the F4/D19.3 pins-as-relations decision waiting to be
executed fleet-wide. The baseline's first prescription writes itself: **purpose + pins-urn
applies per active seat**, Karpathy first (staged), Cowork next.

## What the lenses show — and what they can't

The four frames are beautiful and **frozen in an older frontier**: their presets/roots are
still the T187 session-occasion doctrine, the T189 recommendation batch, and the T200+
program lattice. Rendered *at* T244, they contain **nothing from T231–T244** — no `manifold`
node, no engine vocabulary, no compiler-lowering lane, no keyless-channel story. Two months of
the project's most important work is invisible to its own visual layer. Second prescription:
**author new lens presets for the manifold/compiler-lowering frontier** before the next arc
generates state worth looking at.

Other things the projection surfaced that nothing else had:

- **The Calendar F-lane has been quiet since 2026-05-29** — 63 calendar-mirror nodes end
  there; the staged 41-event time-fabric batch is 0/41 applied (nodes, pins, WF07 anchors all
  pending; `write_result_exists: false` — fully dry). Curious detail for the review: all 41
  pending pins target `session:sam.governance`, though the plan was generated from the Cowork
  seat; and its event dates (Jul 3–11) are lens-order synthetic, not real times.
- **A stale label from v3.13**: `channel:google.calendar.sam` still says "placeholder kind
  pending v3.13 calendar-kind MUTATE" at runtime 4.0.0 — feeds the F2 channel-kind fragment.
- **The twins are not dormant** — :8001/:8002/:8003 answer healthz with small live logs; the
  old "kernels 1–3 dormant" note is retired by this snapshot.
- **The atlas stage did not re-run** — `surface_context_atlas` is 5 days stale (Jun 28) inside
  an otherwise-fresh pipeline output; worth a look at the stage wiring.
- The renderer roadmap is preserved in the gate (Graphviz = kept MVP, Cytoscape.js = next,
  ELK/Dagre layouts later; graph-artifact JSON stays the renderer contract; Julia keeps the
  analytics boundary).

## What this means for the next arc

1. **Topology first:** apply the staged #90 (Karpathy purpose+pins), then the same shape for
   the other active seats — it flips the gate class from FAIL to green and makes every seat's
   session pack a *live* header instead of a focus-string apology.
2. **Lenses second:** new presets rooted at the manifold / compiler-lowering purposes, so the
   moos-IR work renders from day one.
3. **Calendar lane decision:** apply-or-archive the 41-event batch (it predates the arc; the
   WF07 anchor review is the single gating item, flagged since the atlas).
4. The pipeline itself is healthy: identity reconciliation, lens generation, drift-gated seat
   table, dashboard — the F-machinery is ready for the new arc's state.

---
authored-by: agent:claude-cowork.hp-z440 / session:sam.z440-cowork-workspace / t244-arc-baseline
