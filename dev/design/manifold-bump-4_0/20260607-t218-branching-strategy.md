# Branching strategy — git as topology, not hierarchy (T=218)

> **Status: PROPOSAL for review.** No workflow is enforced by this doc; it records the
> doctrine-aligned convention so lanes can adopt it. Authored by Z440 VS Code lead
> (`agent:vscode.hp-z440.primary` / `session:sam.z440-vscode-projection-lead`), 2026-06-07.
> Posted to `ffs0#54`.

## Why a strategy at all

Multiple sessions (soon: named workspaces) on multiple workstations now author into the
same repos. Without a convention, merge-to-trunk silently conflates **who authored** with
**who committed** — the VCS analog of emitting an envelope with the wrong `actor` URN.
This strategy maps git onto our existing rules instead of inventing a parallel hierarchy.

Invariants borrowed from the kernel doctrine:

- **Log is truth, refs are derived.** The commit DAG is the log; `main`/branch refs are
  derived pointers, exactly as kernel state is `fold(log)`.
- **Topology over hierarchy.** A branch is a *coordinate*, not a tree node. No branch is
  "under" another.
- **Data over imperative.** A branch carries data (docs, dry plans, scripts, artifacts).
  A branch's existence never emits an HG rewrite, writes DNS/Cloudflare/Calendar/Workspace,
  or triggers a deploy.
- **Actor/occupancy discipline.** You commit what your session authored. Cross-lane
  authorship is made explicit at the merge (reconciliation) point.

## The mapping

| mo:os concept | git surface | Reading |
|---|---|---|
| folded state / shared baseline | trunk (`main` / `master`) | the derived "current truth" read first |
| commit DAG | the log | append-only; provenance preserved |
| session / workspace (authoring locus) | a branch | unit of intent = purpose × occupant × scope |
| occupant (`agent:…`) | commit author / lane | commit only what your session authored |
| merge to trunk | **G-ingest** (reconciliation) | lane work folded into shared graph |
| build/deploy from trunk | **F-projection** | trunk projected onto a kernel/website |
| manifold (`my-tiny-data-collider`) | gluing object across repos | colimit over per-repo branches sharing one purpose |

Formally: `branch = F(session)` projected onto the VCS surface; `merge = G(branch)`
ingested back into trunk. Promotion to trunk is always an explicit reviewed act, never a
side effect of a branch existing (mirrors §M11/§M12: existence ≠ apply authority).

## Branch coordinate scheme

```
<workstation-or-lane>/<purpose-slug>
```

The `/` is cosmetic grouping, not nesting. The name **is** the flattened WF19 tuple:
which lane/occupant, for which purpose. Already in use:

- `cowork-z440/t216-mtdc-channel-inventory`
- `cowork-z440/r14-section-5-7`

Extend per workstation/session:

- `z440-vscode-lead/<purpose-slug>` (this lead session)
- `hplaptop-governance/<purpose-slug>`
- `z440-kernel-proper/<purpose-slug>` (Wolfram's kernel session)

## Per-repo policy (kernel / workstation / group separation)

- **ffs0** (control/research): trunk-first on `main`. Small, single-lane, non-colliding
  edits go straight to `main` once verified (established T208 rule). **Collision-prone or
  multi-lane work** (multiple sessions touching the same file) goes to a per-lane branch
  and merges with provenance.
- **moos-kernel / moos-router** (runtime function programs): **always** feature-branch
  (`feat/<purpose-slug>`), keyed to a feature session (kernel work = Wolfram's
  `sam.kernel-proper`). Merge only when Doctor + `go test ./...` pass — the build gate is
  the analog of the apply gate. Deployment-safety lanes are distinct from authoring sessions.
- **application groups / manifolds** (`my-tiny-data-collider`): HG groups, **not** the
  kernel repos. Their projection repos/surfaces branch per application-feature, reusing the
  **same purpose-slug** as any coupled ffs0 branch so the manifold can glue them.

## Merge, not rebase, on shared lanes

Log-is-truth favours preserving provenance over rewriting it.

- Feature/lane branches reconcile into trunk via merge/PR — the merge commit records the
  G-ingest and the cross-lane authorship.
- Trunk stays linear/ff-only from **reviewed** branches.
- Rebase is allowed only for in-lane tidy-up before first review — never on a branch
  another lane has pulled, just as we never rewrite a kernel log others have folded.

## Worked example: the Cowork-authored design doc

`dev/design/20260605-t216-mtdc-channel-inventory-dry-plan.md` was authored by the Cowork
lane (`agent:claude-cowork.hp-z440` / `session:sam.z440-cowork-workspace`), edited while the
Z440 lead (`agent:vscode.hp-z440.primary`) was active. Doctrine-correct handling, in order:

1. **Best:** the Cowork occupant commits it on `cowork-z440/t216-mtdc-channel-inventory`,
   then opens it for review/merge. Authorship and occupancy stay aligned.
2. **Fallback:** the lead moves it onto that cowork-named branch with an explicit provenance
   note ("authored by Cowork-Z440, committed by Z440 lead on its behalf") and pushes the
   **branch**, not `main`.
3. **Avoid:** committing it to `main` as Z440-lead work — that erases the authoring lane.

Merge-to-trunk remains the single reconciliation point where cross-lane authorship is made
explicit, analogous to how `moos-round-close` reconciles a round before it becomes shared
truth.

## Errata + refinements (T=218, post-convergence)

> Forward-only correction. The thread converged after this doc's first commit (`94dc1a0`);
> per log-is-truth we amend forward rather than rewrite history. Source: `ffs0#54`
> Z440-lead proposal, Cowork-Z440 endorsement, and hp-laptop governance read.

**E1 — Factual correction to the worked example.** The first version implied the two T216
dry drafts (including `20260605-t216-mtdc-channel-inventory-dry-plan.md`) were being
*held off* `main`. They were in fact already committed to `main` in `226bf2d` before this
strategy existed; only later Cowork-lane edits remained branch/worktree work. Per
forward-only discipline we do **not** revert dry docs off trunk to "fix" provenance — that
would itself rewrite shared history. `226bf2d` + the `#54` thread is the provenance record.
Branch-per-lane applies to **future** collision-prone work.

**E2 — Provenance-anchored merge (adopted, Cowork refinement).** A merge/PR is a real
G-ingest only if it carries the source lane's occupant + purpose. Convention: every
lane-merge commit message includes a trailer:

```text
authored-by: <agent-urn> / <session-urn> / <purpose-slug>
```

This is the git analogue of a WF07/WF12 source anchor; without it the merge loses the
occupant and the `merge = G` story leaks.

**E3 — Occupancy is the liveness predicate (adopted).** A branch with no occupant is
dormant S0 substrate, not a live workspace — exactly as a session with no `has-occupant` is
idle in the kernel. No running without an occupant, echoed in version control.

**E4 — Two-level cardinality (adopted; final vocabulary remains owned by the 4.0 draft).**

- a **workspace** (renamed `session`) is the colimit of its branch-episodes;
- a **manifold** is the colimit of per-repo branches sharing a purpose.

Same shape, two levels. This keeps the branching doctrine and the 4.0 vocabulary from
drifting apart. Final naming is owned by `20260605-t216-ontology-4.0-draft.md`.
