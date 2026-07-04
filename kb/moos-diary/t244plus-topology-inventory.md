# T244+ — workspace topology inventory (what we have · what we use · what changes)

> The Phase-A record of the topology-hygiene round. Census run 2026-07-03 (t_day 245 at capture,
> Z440 log 475 / hp-laptop log 1491), three read-only explorers + a live two-kernel re-census
> (all repair lists were regenerated from `/state/relations` at draft time — never from summary
> tables). Repair batches: `dev/scripts/ops/t244plus-hygiene/`. Doctrine guardrails honored:
> per-kernel sovereignty (69% node asymmetry is §M9 design, NOT a sync bug); same-URN nodes on
> both kernels are sovereign observations, not duplicates.

## Sessions (26 via router fan-in)

| Session | Res. | Status | opens-on | occupant | purpose | pins | disposition |
|---|---|---|---|---|---|---|---|
| sam.governance | L | active | ✓ | ✓ | ✓ | **98→36** | KEEP · pin-diet B2a (−62 cal) |
| sam.kernel-proper (Wolfram) | Z | active | ✓ | ✓ | —→**✓** | 0→1 | wire B1a |
| sam.steinberger-seat | Z | active | ✓ | ✓ | —→**✓** | 0→1 | wire B1a |
| sam.karpathy-seat | Z | active | ✓ | ✓ | ✓ (T244+) | 1→2 | +hdc-vsa pin B1a |
| sam.z440-cowork-workspace (Zappa) | Z | active | ✓ | ✓ | —→**✓** | 0→4 | wire B1a (+3 historic-purpose pins) |
| sam.moos-diary (AG) | Z | (none)→active | ✓ | ✓ | —→**✓** | 0→2 | wire B1a + status B1b |
| sam.z440-vscode-projection-lead | Z | active | ✓ | ✓ | ✓ | 9 | KEEP |
| sam.z440-primary-vscode-setup | Z | active | ✓ | ✓ | ✓ | 1 | KEEP (live 2nd lead workspace) |
| sam.laptop-cowork-workspace | L | active | ✓ | ✓ | ✓ | 0 | KEEP (pins later) |
| sam.laptop-moos-diary | L | active | ✓ | ✓ | ✓ | 0 | KEEP |
| sam.hpprodesk-setup | L* | active | ✓ | ✓ | ✓ | 6 | KEEP (*ProDesk-origin, served via fan-in) |
| sam.mvp-delivery | Z | active→**abandoned** | ✓ | — | — | 0 | B1b (dormant since T219; MVP shipped T190) |
| sam.round10-session-generalization | Z | (none)→**abandoned** | ✓ | — | — | 0 | B1b |
| 5× sam.t200plus-* | L | active→**abandoned** | ✓ | — | ✓ | 45Σ | B2b (scoped-idle practice; pins/filters/tools stay as history) |
| 6× sam.claude-code-* + sam.t187-mvp | Z/L | abandoned | ± | — | — | 0–13 | already closed — no action |
| hp-z440.primary / hp-laptop.primary | Z/L | (none)/active | ✓ | — | ±purpose | 0 | KEEP (birth sessions, infrastructure) |

## Purposes (29 · 8 orphans → 0 after batches)

Wired by B1a: `kernel-implementation-z440`→Wolfram · `tooling-ergonomics-and-dx`→Steinberger ·
`cowork-workspace-curation`→Zappa · `multimodal-curation-and-diary`→AG. Pinned by B1a:
`hdc-vsa-categorical-bridge`←karpathy · `mvp-sovereign-knowledge-os`/`github-project-board-sync`/
`coherent-session-doctrine`←z440-cowork · `build-moos-diary`←moos-diary (+status→open).
Already-wired: compiler-lowering (T244+), lead-operations, laptop pair, hpprodesk-bootstrap,
t200plus quartet, tiny-data-collider, t194-t300-solidification. Abandoned (leave):
doctrine-governance-and-delegation, distributed-hg-network. Achieved: t164-tie-the-room-together.

## Calendar (103 mirror nodes, dates 2026-03-23→09-21)
94% laptop-resident; the F-lane has written nothing since 2026-05-29. **Policy (Sam):** the
staged 41-event T189 batch is **archived, never applied**; existing mirrors stay in the fold as
history but lose their governance-t-cone dominance via B2a. Fresh calendar projection restarts
with real timestamps when the next arc needs it.

## Keep era (t187/t195/t206): 34 orphaned nodes
Claims (22), programs (3), KIs (3), derivations (3), external_ops (2), proposal (1) — all
zero-relation practice artifacts. **Left in the fold** (log is truth; they harm nothing once the
t206 external_op is cancelled in B2b). Harness de-rot (Phase C) stops the *tooling* pointing at
them; `ki:keep.t239-to-claude-code` + `channel:google.keep.sam` are the live keep lane.

## Channels (23; same-URN sovereign pairs on 4)
Divergences documented, not "fixed" (kind immutable): `google.keep.sam` Z=keep-widget /
L=cloud-storage · `local.moos-footage` kind drift (A.11) · calendar/tasks placeholder labels
live in *different mutable fields per kernel* but **no WF governs text/display_name MUTATEs** →
deferred to the next grammar-fragment round (joins F1–F4 from T239).

## External ops (7): t206-keep-oauth → cancelled (B2b); ontology-bootstrap-mtdc,
cf-tunnel-api-mtdc, mtdc-kernel-start stay `pending` (live cloud-endpoint intents); rest OK.

## Programs: 21 overdue triaged (see companion md tables — 8 completed, 9 archived, ProDesk
materialization + cytoscape inspector completed; Guido confirms the L column before applying).

## What we USE (unchanged, verified live)
The 11-row generated seat table (drift-gated) · the 10 VerifyPersona personas · the session
pipeline + 4 lenses + dashboard · keyless-DWD channels (keep/calendar/gmail/drive/tasks) ·
GitHub issues/PRs as the cross-seat channel · moos-router#5 as the only open work item.

---
authored-by: agent:claude-cowork.hp-z440 / session:sam.z440-cowork-workspace / t244plus-topology-hygiene
