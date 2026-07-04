# T244+ topology hygiene — reviewed apply batches

> Companion to the four `*.program.json` batches in this directory. Drafted by Zappa/Cowork-Z440
> from the live two-kernel census (2026-07-03, t_day 245, Z log 475 / L log 1491); Sam approved
> the four policy calls (archive cal-batch · governance pin-diet · abandon practice sessions ·
> wire orphans + pin the rest). Inventory record: `kb/moos-diary/t244plus-topology-inventory.md`.
> Apply discipline: **B1\* on `hp-z440.primary` (Zappa applies) · B2\* on `hp-laptop.primary`
> (Guido reviews + applies — handoff via ffs0#89).** Atomic per batch; readback after each.

## B1a — Z440 purpose LINKs (13 envelopes, kernel actor, WF19)
The #90/Karpathy shape, ×4 seats + orphan pins:
| Session | has-purpose → | + pins-urn |
|---|---|---|
| `sam.kernel-proper` (Wolfram) | `purpose:sam.kernel-implementation-z440` | ✓ |
| `sam.steinberger-seat` | `purpose:sam.tooling-ergonomics-and-dx` | ✓ |
| `sam.z440-cowork-workspace` (Zappa) | `purpose:sam.cowork-workspace-curation` | ✓ |
| `sam.moos-diary` (AG) | `purpose:sam.multimodal-curation-and-diary` | ✓ |

Orphan-purpose pins (pins only — `has-purpose` stays at-most-one):
`karpathy-seat` pins `hdc-vsa-categorical-bridge` · `z440-cowork-workspace` pins
`mvp-sovereign-knowledge-os`, `github-project-board-sync`, `coherent-session-doctrine`
(Z-resident purposes; the curation workspace holds historic purposes exactly as governance
does on the laptop) · `moos-diary` pins `build-moos-diary`.

## B1b — Z440 lifecycle MUTATEs (16)
- Sessions → `abandoned`: `mvp-delivery` (dormant since T219; MVP shipped T190),
  `round10-session-generalization` (additive — node had no status).
- `moos-diary` session status → `active` (additive; live occupied seat, was statusless).
- `purpose:sam.build-moos-diary` status → `open` (additive; was statusless).
- **Program triage (Z, target_t < 200 at t_day 245):**
  | → completed | → archived |
  |---|---|
  | t161 · t162-presentation · t190.z440-vscode-projection-lead-transition · round10-session-generalization · mvp-g1-session-layer · mvp-delivery | t163 · mvp-g2-approver-reactor · mvp-g4-moos-viz-live · mvp-g5-hdc-query-demo · mvp-g3-first-channel · t162 |

  Rationale: completed = verifiably shipped per running-state history; archived = drafts
  superseded by later work (G3 note: the *first channel* eventually landed as `keep-widget`
  T239 by a different route — the draft program itself never executed).

## B2a — hp-laptop governance pin-diet (62 UNLINKs) — GUIDO APPLIES
UNLINK every `sam.governance —pins-urn→ urn:moos:cal:*` relation. The 62 relation URNs were
generated from the LIVE laptop relation list (not the census). Governance keeps its 36 non-cal
pins (14 program, 5 session, 5 claim, 4 derivation, 2 view_filter, 2 purpose, ki/channel/agent/
external_op ×1). Nodes are untouched — the 103 calendar mirrors stay in the log/fold as history;
they just stop dominating the governance t-cone.

## B2b — hp-laptop lifecycle (11) — GUIDO APPLIES
- 5× `t200plus-*` sessions → `abandoned` (scoped-idle practice lanes; affordance-map entries
  remain as historical reference).
- `external_op:sam.t206-google-keep-oauth-scope-approval` → `cancelled` (superseded by the
  keyless-DWD path, T239). The 3 mtdc external_ops stay `pending` — live future intents.
- **Program triage (L):** completed: `t193.hpprodesk-topology-materialization` (rejoin done
  T226/T239), `t189.cytoscape-typed-hg-inspector` (the interactive inspector ships in the
  pipeline dashboard) · archived: `t192.application-group-model-my-tiny-data-collider`,
  `t189.github-project-urn-refresh`, `t189.calendar-event-g-ingest-shape`.
- **Guido: confirm the triage columns before applying** — flip any row you disagree with and
  note it on #89.

## Explicitly DEFERRED (no valid governance path today)
- **Channel label MUTATEs** (`text` on Z / `display_name` on L still carry 'placeholder kind
  pending v3.13'): NO rewrite_category lists `text`/`display_name` in its mutate_scope →
  standard MUTATE has no governing WF; additive path unavailable (fields exist). Needs an
  ontology mutate_scope extension — queued for the next grammar-fragment round (joins F1–F4).
- **Channel `kind` divergences** (same URN, different kind per kernel): `kind` is immutable —
  documented in the inventory; converge on future ADDs only.
- **41-event T189 calendar batch: ARCHIVED, never apply** (Sam's call). The plan artifacts stay
  under gitignored tmp/ as evidence.

## Apply + verify (per batch)
```bash
node -e "const p=require('./dev/scripts/ops/t244plus-hygiene/<batch>.program.json');require('fs').writeFileSync('tmp/_b.json',JSON.stringify(p.envelopes))"
curl -s -X POST http://<kernel>:8000/programs -H "Content-Type: application/json" --data @tmp/_b.json
# then: /healthz log growth · spot node_lookup · config_projection.py --mode check (byte-identical)
```

authored-by: agent:claude-cowork.hp-z440 / session:sam.z440-cowork-workspace / t244plus-topology-hygiene
