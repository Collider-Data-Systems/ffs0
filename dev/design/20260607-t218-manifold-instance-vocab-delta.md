# mo:os 4.0 vocab delta — `kernel`→`instance` + the workstation projection surface (T=218)

> **Status: DRAFT for review. NOT applied.** No `ontology.json` / `running-state.md` edit.
> Authored: Z440 VS Code lead (`agent:vscode.hp-z440.primary` / `session:sam.z440-vscode-projection-lead`),
> 2026-06-07 (T=218), on lane `z440-vscode-lead/manifold-instances-vocab`.
> Builds on the T216 4.0 draft (`20260605-t216-ontology-4.0-draft.md`, deltas D1–D5) and the
> T218 branching strategy (`20260607-t218-branching-strategy.md`). Baseline: ontology v3.16.2.

## Motivation — the stack is now physically visible

Sam's live workstation topology makes the whole projection stack observable as substrate:

- 4 screens on Z440, 2 on hp-laptop; multiple W11 virtual desktops per machine.
- W11 virtual desktops named `MTDC WS moos z440 …`, `MTDC WS ARRAY …` — workspaces as desktops.
- Chrome tab-groups named `manifold group`, `mo:os`, `math`, `Collider Data Systems`, with a
  `manifold: my-tiny-d…` tab — channels as tab-groups.
- `moos-kernel` / `moos-router` windows, one per running instance.

The nesting Sam states:

```
manifold → instances → workspaces → purpose → channels → { browser tabs, agent harnesses, IDE panes }
```

Two of these levels are already in the T216 4.0 draft: `manifold` (D1) and `session→workspace` (D2).
This delta adds the two that are missing: the **instance** rename and the **surface** terminus.

## D6 — `kernel` → `instance` (alias-first rename)

- **Rationale.** "kernel" overloads the OS-kernel meaning and reads as a single privileged core. The
  mo:os object is *a running fold of one log conforming to the operad* — one **instance** of the
  manifold's runtime. Plural-first by construction: a manifold has many instances (primary + twins +
  one-or-more per workstation). The current live occasion already shows this: `:8000` primary plus
  `:8001/:8002/:8003` twins are four instances of one operad.
- **Semantics unchanged.** `instance := fold(log)` exposed at an endpoint. §M11 (liveness) and §M12
  (admin capability) authority semantics are identical. This renames a node-type *label*, not topology
  — no relation changes, WF19 `opens-on` / `has-occupant` untouched.
- **Migration: alias-first**, exactly parallel to D2 (`session→workspace`).
  - HG: keep the URN form `urn:moos:kernel:<ws>.<name>` readable; introduce `instance` as the canonical
    label with `kernel` retained as a read alias until a reviewed migration rewrites URNs. No hard rename
    in one jump.
  - Runtime footprint (`moos-kernel`, surveyed): `internal/kernel/` package, `/healthz` + state payload
    field names, README/CLAUDE language, ~59 token sites. The rename is gated by **Doctor + `go test ./...`**
    (T218: build gate = apply gate) and is tracked on the runtime lane `feat/manifold-instances-vocab`,
    not applied here.

## D7 — the workstation projection surface (new bottom of the stack)

The genuinely-new contribution. The semantic chain bottoms out in physical substrate, and Sam's
desktop *is* that substrate:

| Semantic (HG) | Substrate (S0 surface) | Sam's live realization |
|---|---|---|
| `manifold` (D1) | the multi-workstation portfolio | `my-tiny-data-collider` across Z440 + hp-laptop |
| `instance` (D6) | a running fold / a host process | `:8000` primary, `:8001–:8003` twins; per-workstation |
| `workspace` (D2) | a W11 virtual desktop | `MTDC WS moos z440 …`, `MTDC WS ARRAY …` |
| `purpose` | what that desktop is *for* | the desktop's directional theme |
| `channel` (D5) | a window or a Chrome tab-group | `manifold group`, `mo:os`, `math` tab-groups |
| (leaf) endpoint | a tab / IDE window / harness pane | a Chrome tab, a VS Code window, a Copilot/Antigravity pane |

**Doctrine placement** (keeps the surface layer clean):

- The surface layer is **S0 projection substrate** — same status as IDE conversations (T173 pivot). A
  screen / virtual-desktop / window / tab is *where F lands*, not a new authority node type.
- It is **observed, not authored.** G-ingest reifies surface observations as `channel` endpoints (D5
  kinds) plus `knowledge_item` observations; it never grants authority. Existence ≠ apply authority
  (T218 E3), one level lower than branches.
- Sam's hand-naming (`MTDC WS …`, `manifold group`) is a **human-maintained F-projection**: a person
  aligning substrate labels to semantic URNs by hand. That alignment is precisely what the projection
  pipeline automates in the F direction.
- **No new node types** for screens/desktops/tabs. If we want them addressable, extend `channel.kind`
  (on top of D5): `workstation-surface`, `virtual-desktop`, `window`, `tab-group`, `browser-tab`,
  `harness-pane` — derived/observed surfaces, redaction-safe, never authority.

**Conjecture (flagged, not asserted).** The surface stack is a strict F-image of the semantic stack:
each semantic level has 0..n substrate realizations and the realization map preserves the nesting
(a functor from the semantic poset to the substrate poset). Unproven — referred to the categorical seat
(Karpathy) for the functoriality/colimit check.

## D8 — `realizes` / `realized-by` (surface ↔ semantic) — open, observed-first

A harness-pane *realizes* a channel; a virtual-desktop *realizes* a workspace. Kept distinct from
`presents-as` (D4, agent↔persona) and WF19 occupancy (session↔agent). Stage as derived/observed first;
promote to a relation port-pair only if the projection pipeline needs to *write* it. Open.

## Migration guards (inherit the T216 draft)

- Alias-before-rename for `kernel→instance` (D6), same discipline as `session→workspace` (D2).
- Surface layer (D7) modeled as derived/observed S0 + `channel.kind`; **no new authority node types**.
- No opportunistic runtime bump from this thread; the runtime rename is gated by Doctor + `go test ./...`
  on `feat/manifold-instances-vocab`.
- No secrets, machine IDs, or sensitive window/tab titles as durable facts.

## Cross-repo gluing (T218)

Shared purpose-slug **`manifold-instances-vocab`** glues three lanes; the `manifold` is the colimit of
these per-repo branches sharing one purpose (T218 E4):

| Repo | Branch | Carries |
|---|---|---|
| `ffs0` | `z440-vscode-lead/manifold-instances-vocab` | this 4.0 vocab delta (D6/D7) |
| `moos-kernel` | `feat/manifold-instances-vocab` | runtime `kernel→instance` rename lane (gated) |
| `moos-router` | `feat/manifold-instances-vocab` | instance-aware federation labels lane (gated) |

`branch = F(session)`, `merge = G(branch)`; promotion to trunk is an explicit reviewed act with a
provenance trailer (`authored-by: <agent-urn> / <session-urn> / manifold-instances-vocab`).

## Open decisions for Sam

1. Is `instance` the right label, or keep `kernel` and add `instance` only as a derived view (D6 light)?
2. D7 addressability: `channel.kind` additions vs a thin derived `surface` view for screens/desktops/tabs.
3. D8 `realizes/realized-by`: reify now, or stay observed-only?
4. Sequencing: does `kernel→instance` ship in the same 4.0 bump as D1–D5, or a later point release?
