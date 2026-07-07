# T=248 — Identity relations plan: engines · users · delegates · personae

> Zappa / Cowork-Z440 · a plan, with jokes, because the commission said so ("it belongs in music,
> so it should fit in programming too" — the man himself settled that question in 1984; the answer
> was yes, provided the band can actually play).
> **GATE: prose-only. This plan authorizes NO ontology change, NO URN change, NO HG rewrite.**
> Every proposal below matures via `grammar_fragment` (status: `proposed`) + WF20 promotion, per house rule.
> Sources: ontology.json v4.0.0 readback · live folds :8000-:8003 (T=248 evening) · `dev/design/manifold-bump-4_0/*`
> · `dev/config/{seat-display,session-affordance-map}.json` · kb/moos-diary letters + postscripts.
> Companion dossier: `20260707-t248-mtdc-conceptual-continuity.md`.

## 0. The commission

We now have, live and verified: **engines** (four on Z440, each with an owner on its own fold),
**users** (sam, menno, lola, moos — one per engine, per the type doctrine), **delegates** (the
agent principals: `claude-cowork.hp-z440` and friends), and **personae** (the band: Wolfram,
Steinberger, Karpathy, Zappa, John Lydon, Guido, Moos — Φ(purpose), presentation not authority).
What we do not have is a settled account of the **relations** among these four kinds. The nouns
arrived before the verbs. This plan inventories what the folds actually hold, names the gaps, and
dispatches four lanes to close them. The crux of the biscuit, as always, is the paperwork.

## 1. What the folds hold today (readback, not doctrine)

| Relation | WF · ports | Where it is live | Status |
|---|---|---|---|
| `user —owns→ workstation` | WF01 owns/child | :8000 (`user:sam → workstation:hp-z440`) | ✅ live |
| `group —owns→ kernel` | WF01 | :8000 (`group:sam → kernel:hp-z440.primary`) | ✅ live |
| `user —owns→ kernel` | WF01 owns/child | :8001/:8002/:8003 (menno/lola/moos → their twins, seed 2026-04-10) | ✅ live |
| `workstation —hosts→ kernel` | WF03 | :8000 only (all four engines) | ⚠️ primary-fold only |
| `user —governs→ agent` | WF02 governs/governed-by | :8000 (`user:sam → 5 agents + role:superadmin`) | ✅ live, sam only |
| `session —opens-on→ kernel` · `has-occupant` · `has-purpose` · `pins-urn` | WF19 | :8000 (the seat spine) | ✅ live, primary only |
| `agent —presents-as→ persona` | **D4 — undefined** | nowhere | ⛔ deferred 4.0.x |
| `manifold —?→ anything` | **no WF declares manifold** | nowhere (`manifold` has ports `self:[identity]` only) | ⛔ deferred follow-on |
| `surface —realizes→ channel/workspace` | **D8 — observed-first** | config + human desktops only | ⛔ deferred 4.0.x |

## 2. What exists only as projection (config, not HG)

The seat table's own column headers confess it: **Persona** and **Surface** are tagged `config`
while Agent/Workspace/Engine fold from HG. Persona display names live in `seat-display.json`
("DISPLAY-ONLY enrichment HG does not yet carry... pending Q2 persona-nodes"); the Φ(purpose)
join is done by a config key naming convention, not a graph query — and for Wolfram, Steinberger
and Moos the purpose URN isn't even named anywhere, so **Φ is not mechanically computable for
three of the seven band members**. They have names the way a bar band has a logo: real enough on
the poster, absent from the tax filing.

## 3. Gap inventory

- **G1 — persona is a name with no node.** D3 ratified persona = Φ(purpose) as a derivation,
  D4 (`presents-as`) is deferred *because there is nothing to point at*. "Q2 persona-nodes" is
  referenced in config comments but no design doc exists. Decide the target shape: persona as a
  `derivation` instance (`purpose —WF21 causes→ derivation:persona.*`, agent `—presents-as→` it)
  vs. staying config-only forever. *(Owner: Karpathy shape · Lydon authority-review.)*
- **G2 — manifold is relation-less.** The type landed identity-first (urn_example:
  `urn:moos:manifold:my-tiny-data-collider`) with spanning relations explicitly deferred. The mtdc
  manifold node itself has never been ADDed; the T=216 channel topology stays a dry plan. The
  colimit doctrine is two-level (workspace = colimit of branch-episodes; manifold = colimit of
  per-repo branches sharing a purpose) — the spanning WF must respect that. *(Owner: Karpathy.)*
- **G3 — the family owns stages with no bands on them.** menno/lola/moos hold `owns → kernel` and
  **nothing else**: no WF02 `governs`, no workspaces open on their engines, no occupants. Karpathy
  rehearses at the seat *attached to* Lola's engine but emits to :8000 pre-§M9. Is
  family-user-as-pure-owner correct doctrine for now, or do their engines get birth workspaces?
  Note the T=208 guardrail ("no new user nodes for Menno/Lola/Moos without a separate
  identity-design decision") — T=248 IS that decision arriving; the seed-era nodes predated it.
  *(Owner: Lydon.)*
- **G4 — cross-fold identity is asymmetric.** `user:sam` exists on :8000 and :8003 but not
  :8001/:8002; twins never got the T=247 workstation-spine (`hosts`) reconciliation; the twins'
  `owns` targets the kernel directly while the primary's spine goes user→workstation→hosts→kernel.
  Sovereign folds are the design (§M9) — but "the same being appearing on several folds" has no
  written identity doctrine. Same being, four filing cabinets, no cross-reference card.
  *(Owner: Lydon doctrine · Guido tooling.)*
- **G5 — declared vs. loaded.** The WF19 note records that `operad/loader.go` (as of v3.12) does
  not consume `additional_port_pairs` — which now carry has-occupant, has-purpose, pins-urn,
  owned-by, delegates-to: the *entire modern identity spine*. Separately,
  `port_color_compatibility` lists WF19 pairs never declared (claims-session, transfers-to) and
  lacks every pair added v3.10-v3.16 except one. Whether the loader caught up is a **code
  readback**, not a doc question. *(Owner: Guido verification-plan; execution = Wolfram lane when
  the runtime round opens.)*
- **G6 — mutate_scope rot.** session's deprecated properties (status, turn_count, role, seat_role)
  still sit in WF19/WF07 mutate_scope; `capability.max_rewrites` is mutable with no WF granting
  it; `agent.invocation_protocol`/`board_id` likewise orphaned. Cosmetic until someone MUTATEs.
  *(Owner: Lydon, fold into the fragment round.)*
- **G7 — Φ inputs incomplete.** Only Zappa, John Lydon, Guido (+ Karpathy via the T=244 wiring)
  have explicit purpose URNs; not every seat has a durable `has-purpose`. Before persona can fold
  from HG, every seat needs its purpose wired. *(Owner: Guido inventory · Sam gates applies.)*

## 4. The lanes (who → where → what)

> Per standing rule these are dispatch-ready action items; **Sam dispatches the delegates**.
> All four produce prose + `grammar_fragment` drafts (status: `proposed`); zero HG writes without
> Sam's per-batch go. Bus: ffs0#131 (or a successor coordination issue). Board: every deliverable
> onto #4 with full bridge fields.

| Lane | Seat | Deliverable |
|---|---|---|
| **Karpathy** → Z440 VS Code (lola seat) → *the shape* | `vscode.hp-z440.lola` / `sam.karpathy-seat` | Design note: the identity square (user–agent–purpose–persona) done properly — persona-as-derivation target for D4 (is `presents-as` the component of a counit? mark it conjecture); manifold spanning relations respecting the two-level colimit; where owners sit in the colimit (cocone vertex vs. provenance stamp). Fragments drafted, not applied. |
| **John Lydon** → hp-laptop Cowork → *the authority* | `claude-cowork.hp-laptop` / `sam.governance` | Governance note: multi-user §M11/§M12 semantics (four superadmins, four folds — what may cross?); P4 occupant-guard exemption set; G3 ruling (family engines: pure ownership vs. birth workspaces); G4 cross-fold identity doctrine; G6 mutate_scope cleanup fragment. Cross-persona audit extended to the twins. |
| **Guido** → hp-laptop VS Code → *the projection* | `vscode.hp-laptop.copilot` / `sam.laptop-vscode-lead` | Tooling: G7 purpose-wiring inventory (which seats lack durable has-purpose); config-projection readiness for folding persona from HG once G1 lands (retire the seat table's two config columns); per-fold readback in `Test-MoosFederation` (VerifyPersona → twins); G5 loader-gap verification plan handed to Wolfram as a moos-kernel issue. |
| **Moos AG** → Z440 Antigravity → *the record* | `antigravity.hp-z440` / `sam.moos-diary` | The narrator's cut: diary entry on the day the humans caught up with the dog's paperwork; multimodal KIs for the family layer (the beings behind the user nodes — photos already in the lane); the mtdc continuity dossier's narrative companion in the diary register. Ingest batches staged, Sam-gated. |

Zappa (this seat) coordinates: board, bus, this plan, and the merge paperwork. Wolfram is not in
the commission but inherits G5's code half when the runtime lane opens — noted so it doesn't
evaporate. None of these characters own anything; they play, the humans (and one dachshund) keep
the score. That sentence is not colour, it is the authority model.

## 5. Sequencing and gates

1. Lanes run in parallel — they touch disjoint surfaces (design note / governance note / tooling /
   diary). Collisions governed by the ffs0#131 contract (rebase discipline, cross-lane via bus).
2. Fragment drafts collect in `dev/design/manifold-bump-4_0/` and go through one reviewed WF20
   round **together** — not piecewise — so D4/G2/G6 land as a coherent 4.0.x candidate.
3. Hard gates unchanged: URN rewrite stays 4.0.x; P4 authority change "must not ride" anything;
   every HG apply is Sam-gated per batch; the seat table's fenced region stays generated.

## 6. Open questions (for Sam, not blocking dispatch)

- G3 ruling has taste in it: do Lola/Menno/Moos engines stay pure-ownership monuments until §M9
  twin-sync, or do they get birth workspaces now so the family can actually put things in them?
- Does the persona court ever *want* to be in the HG (G1), or is "presentation stays projection"
  the durable answer and Q2-persona-nodes gets formally retired?

---
authored-by: agent:claude-cowork.hp-z440 / session:sam.z440-cowork-workspace / cowork-workspace-curation
