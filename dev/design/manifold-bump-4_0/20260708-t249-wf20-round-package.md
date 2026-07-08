# The collected WF20 round — package for Sam's review (t249)

> Zappa / Cowork-Z440 · the cargo manifest of everything the t248-t249 identity commission staged.
> **GATE: this document authorizes nothing.** It assembles; Sam's review + go authorize the execution
> shape after approval: ONE reviewed PR (ontology.json additive bump + this round's fragment
> ceremony on `:8000`, per the t231 `v400-*` precedent) followed by the gated HG batches.
> Sources cited per item — specs live in the lane notes, not restated here.

## 0. What this round is

Seven fragments + three HG batch-sets + two decisions that only Sam can make. Everything additive,
alias-first, 4.0.x-class. Nothing here touches the hard URN rewrite (stays gated). The round exists
so ontology.json is edited **once, reviewed once** — the crux of the biscuit remains the paperwork.

## 1. Grammar fragments (all `status: proposed`)

| # | Fragment | Source | What it adds | Risk |
|---|---|---|---|---|
| 1 | `d4-presents-as` | Karpathy note §1 | WF19 additional pair `presents-as/presented-by`, `agent → derivation` — persona as `derivation:persona.<name>` (Φ evidence chain: `purpose —WF21 causes→ derivation`). Presentation, never authority; at-most-one per agent. Counit reading C2 stays conjecture, outside the fragment. | Low (additive pair; no authority surface) |
| 2 | `g2-manifold-spans` | Karpathy note §2 | WF18 additional pair `spans/spanned-by`, `manifold → purpose/program/session/channel/group` — the two-level colimit made linkable. Unblocks ADDing `manifold:my-tiny-data-collider` + the T=216 channel topology. | Low (additive; manifold currently relation-less) |
| 3 | `g6a-mutate-scope-prune` | Lydon note | Removes deprecated `session` fields (`status`,`turn_count`,`role`,`seat_role`) from WF19/WF07 `mutate_scope`. | Low-medium (check no tooling still MUTATEs them — Guido's VerifyPersona doesn't) |
| 4 | `g6b-orphan-property-adoption` | Lydon note | Grants orphaned mutable properties a WF home (`capability.max_rewrites`, `agent.invocation_protocol`, `agent.board_id` → WF02 `mutate_scope`). | Medium (mild authority widening — Lydon: review separately from g6a) |
| 5 | `f1-source-type-values` | t239 F1 + t249 evidence | `knowledge_item.source_type` enum += `{photo, video, diary, keep, task, chat, doc}` — the enum is currently **unenforced** and live nodes already carry `photo`/`video` (t244 precedent, t249 family batch). Fragment trues the registry to reality; enforcement decision rides Decision B. | Low (registry catches up with live state) |
| 6 | `port-color-prose-fix` | kernel#50 rider | ontology.json **prose only**: mark `port_color_compatibility.declared_pairs_by_wf` as authored-intent-NOT-loaded (or delete the phantom WF19 rows `claims-session`/`transfers-to`); correct the false "any pair not listed is rejected" description. Zero grammar change. | None (prose) |
| 7 | `f1-hardening-shape` | Lydon note (finding F1) | §M11 infra-ADD bypass is actor-agnostic — `user`/`workstation` ADDs pass both gates on any fold; the T=208 guardrail is prose-only. Shape = **Decision A** below. Deliberately NOT bundled into P4. | Depends on Decision A |

### Prose-vs-gate parity (Lydon cross-ref, [moos-kernel#50 comment](https://github.com/Collider-Data-Systems/moos-kernel/issues/50#issuecomment-4915533539))

Fragments 5, 6 and 7 are **one defect class reviewed as one item**: *authored doctrine claims
fail-closed, enforcement is permissive.* Three instances: the port-color prose ("any pair not
listed is rejected") vs the silent skip · the T=208 user-ADD prohibition + "exactly one user per
kernel" vs the actor-agnostic §M11 infra-ADD bypass · the `source_type` enum vs zero enforcement.
**Round rule:** every fail-closed claim in ontology.json prose must either name its enforcing gate
or be corrected to advisory. Fix-ordering follows the authority note's E3 principle everywhere —
coverage before flip; guards sit above existing checks, never brick the spine they protect.

## 2. HG batch-sets (apply after the bump, per twin, kernel actor, R1 fold-locality)

| Set | Content | Gate |
|---|---|---|
| **R2 birth workspaces** | Per twin (`:8001/:8002/:8003`): ADD `session:<owner>.home` + WF19 `opens-on` its own kernel + `has-occupant` deferred until a real occupant exists. Sam already ruled YES; timing ruled t249 = **this round**. Exact URN shape + occupancy question → Lydon authority-review before apply. | Sam per-batch go |
| **H1 legacy-URN reconciliation** | Twins' April-seed shapes (direct `owns→kernel`, missing `hosts` spine, legacy rel URNs) reconciled to the T=247 workstation-spine convention — additive LINKs only, no rewriting history. | Sam per-batch go |
| **D4/G2 instantiation** | After fragments land: ADD the 7 `derivation:persona.*` nodes + `presents-as` LINKs (retires the seat table's config-only Persona column, closes Q2-persona-nodes) · ADD `manifold:my-tiny-data-collider` + `spans` topology (the dossier's open-end #1 closes; the worked example finally exists). | Sam per-batch go |

## 3. The two decisions only Sam can make

- **Decision A — F1 hardening shape.** (a) Restrict `user`/`workstation` ADDs to kernel actor +
  `SeedIfAbsent` (hard gate, small code change, matches "identity is seed-or-kernel business"); or
  (b) occupant-guard **soft-hook first** — log-and-allow, per Sam's own P4 soft-hook-first ruling,
  flip to hard later. *Lydon's lean and mine: (b) — consistent with P4, reversible, evidence-gathering.*
- **Decision B — `source_type` enforcement.** Once the enum is trued (fragment 5): enforce at ADD
  (validator change, Wolfram lane) or leave advisory. *Lean: enforce — an unenforced enum is a
  false promise, the exact defect class kernel#50 documents for colors.*

## 4. Sequencing (after Sam's go)

1. Fragments 1-6 → ontology.json additive bump (**4.0.1**) on a reviewed PR + WF20 ceremony on
   `:8000` (ADD fragments → promote → merged; t231 precedent script shape).
2. Kernel restarts to pick up the bump (loader is data-driven; additive = version-skew-benign
   until then — restart Z440 primary + twins in one window; laptop at Lydon's convenience).
3. Decision A implementation (if (b): soft-hook rides moos-kernel with #50's fix; if (a): small
   validator PR) — Wolfram lane, alongside **moos-kernel#50** (port-color data-driven map).
4. Batch-sets: R2 → H1 → D4/G2 instantiation, each Sam-gated, each verified by per-fold readback
   (the cardinal rule earns its keep on its own round).
5. Round-close: `config_projection.py --mode check` + cross-persona audit A.12 + running-state
   validator across all folds.

## 5. What this round deliberately does NOT do

No hard URN rewrite (`session`/`kernel` stay canonical) · no P4 hard gate · no D8 `realizes`
reification (stays observed-first) · no persona node-TYPE (persona stays a derivation — D3 holds) ·
no deletion of anything (g6a prunes *grants*, not history; the log keeps every page, as always).

---
authored-by: agent:claude-cowork.hp-z440 / session:sam.z440-cowork-workspace / cowork-workspace-curation
