# mo:os 4.0 vocab delta — `kernel`→`instance` + the workstation projection surface (T=218)

> **Status: APPLIED (alias-first) in `ontology.json` v4.0.0 (T=231)** — D6 `instance` alias on `kernel` + D7 surface kinds landed via `channel.kind`. Hard ~59-site `kernel→instance` URN rewrite + D8 `realizes` reification deferred to 4.0.x.
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
- **Sense of "instance" (governance precision).** Meant **model-theoretically** — an instance is a
  *model / realization of the theory* (the operad), the way a structure realizes a signature — **not**
  the cloud/OOP "instance-of-a-class" sense. The doc adopts this reading so the rename does not silently
  inherit the OOP overload Cowork flagged.
- **Semantics unchanged.**`instance := fold(log)` exposed at an endpoint. §M11 (liveness) and §M12
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
  `harness-pane` — derived/observed surfaces, redaction-safe, never authority. **Both lanes + governance
  concur:** fold these D7 surface kinds and the D5 infra kinds into **one** `channel.kind` migration, not
  two passes.

**Conjecture (flagged; reframed after ffs0#54 review).** Earlier wording said "strict F-image"; that
overclaims. Converged statement to hand the categorical seat (Karpathy): the **surface poset is fibered
over the semantic poset** — each semantic node carries a *fiber* of 0..n realizations — and realization
is a **monotone, colimit-preserving, generally non-injective** map (two tabs → one channel; one
workspace spread across four screens). That is precisely the **F (left-adjoint) side of F⊣G**, not a
strict/injective image.

The payoff (governance): the **non-injectivity is the projection-fidelity metric**, not a defect. In
F⊣G the unit `η: x → G(F(x))` measures round-trip loss; a projection is lossless exactly where `η` is
iso, measured per node. "How faithfully does the surface realize the semantics" = how close the unit is
to an isomorphism — the **same number as HDC encode/decode fidelity**. Karpathy seat to prove
"colimit-preserving functor, F side of an adjunction, with a measurable unit-defect," not "strict
F-image."

## D8 — `realizes` / `realized-by` (surface ↔ semantic) — open, observed-first

A harness-pane *realizes* a channel; a virtual-desktop *realizes* a workspace. Kept distinct from
`presents-as` (D4, agent↔persona) and WF19 occupancy (`session has-occupant agent`). Stage as
derived/observed first; promote to a relation port-pair only if the projection pipeline needs to
*write* it. Open.

## Sequencing (converged on ffs0#54 — lead + Cowork + governance)

Land the **vocabulary/alias in the 4.0 bump alongside D1–D5**: D6's `instance` label + `kernel` URN
read-alias is decided together with D2 (`session→workspace`) — both are alias-first label renames, so
they are decided as one, not split. Ship the **hard ~59-site `kernel→instance` URN rewrite as a gated
4.0.x point release**, once Doctor + `go test ./...` pass on the runtime lanes (`moos-kernel` /
`moos-router` `feat/manifold-instances-vocab`). This keeps the 4.0 doc coherent — the rename is
*decided* — without coupling the bump to runtime churn (build-gate = apply-gate, T218).

## Migration guards (inherit the T216 draft)

- Alias-before-rename for `kernel→instance` (D6), same discipline as `session→workspace` (D2).
- Surface layer (D7) modeled as derived/observed S0 + `channel.kind`; **no new authority node types**.
- No opportunistic runtime bump from this thread; the runtime rename is gated by Doctor + `go test ./...`
  on `feat/manifold-instances-vocab`.
- No secrets, credentials, or sensitive window/tab *contents* as durable facts. (Structural workstation
  labels like `hp-z440` / `hp-laptop` are fine — they are already part of kernel/instance URNs; the guard
  is about secret values and private titles, not the topology labels this doc uses.)

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

## D4 reification debt — persona-label ledger (appended T=247, Zappa; per ffs0#99)

The persona "court" lives ONLY in the F-projection until D4 `presents-as` reifies: labels are
carried in `dev/config/seat-display.json` + `moos-federation.topology.json` personas block +
`.claude/agents/*.md` cards. Every rename grows the set a future D4 apply must fold in:
**Zappa** (T244+, ex `cowork-z440`, legacy_key kept) and **John Lydon** (T247, ex `guido`,
PR #98). When D4 lands, one `presents-as` relation per seat replaces these three authored
surfaces as the source; the configs become display cache.

Operational notes from the renames (ffs0#99):
- The seat-table regenerate (`config_projection.py --mode write`) is coupled to full-fleet
  reachability — the shrink-guard refuses when a kernel is down (by design; renames while
  ProDesk is off must ride `--allow-shrink` deliberately or wait).
- **Finding 6 (design):** agent principal URNs bake the SURFACE into identity
  (`vscode.hp-laptop.copilot` posting from Claude Code). Precedent for repair exists (the T239
  guido re-ratification with a legacy alias), but the pattern is fleet-wide — queue an
  agent-URN re-ratification review for the 4.0.x lane alongside the hard rename.
