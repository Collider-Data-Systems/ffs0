# T263 — user-topology glue: member-of, poset realization, same-function ratification (ontology 4.0.4)

> Companion to the ontology 4.0.4 bump (this PR). Parent analysis: `dev/design/20260722-t263-topological-repo-identity-versioning.md` (T263 note, v2.1). Sam's ruling (t263 evening, Cowork-Z440 ops session): full-chain membership · full lane · revocation window accepted explicitly.
> Design-doc discipline applies: relation-first, rewrite-first; conjectures marked as conjectures.

## 1. Ratifications (T263 note §6, gate 1) — now doctrine

1. **Engine-qualified stamp.** Every access decision, readback, and proposal carries `(engine_urn, log_seq, ontology, law-version)`. Cross-engine position comparison is undefined pre-MTDC; fan-in views (router :9000, twins, seat portal) are non-authoritative for access decisions; authorization is part of admission validation. Caveat: stamps are authenticated only once the §5-B lens lands (4.0.x); `access.go` carries the stamp from day one.
2. **The same function.** The organizing structure across **user → group → manifold → workspace → branch → channel** is one function — `slice : State × Agent → Context` under three obligations (security law · bandwidth filter · consistency check) — with the F⊣G lens shape recurring at every stratum (project = F/lower, ingest = G/lift; branch = F(workspace), merge = G(branch)). **Grading stays honest**: the two-level colimit (workspace = colimit of branch-episodes; manifold = colimit of per-repo branches sharing a purpose) and branch-as-F-projection are doctrine (t218 E4 + t260 errata); the fibration base B = A1×A2, axes A2–A5, symmetry S5, and laws C7/C8 remain graph-witnessed conjecture. What this round changes: the **A1 identity-poset (user < group < manifold-group) moves from "absent" to graph-witnessed** when the membership batch lands.

## 2. Revocation window — ACCEPTED (T263 note §6, gate 2 ruled)

The prefix invariant orders only sequenced envelopes. Doctrine sentence, ratified: **the revocation window equals sequencing latency plus approval latency; there is no staleness bound for lagging channels pre-MTDC; this is a stated, accepted risk.** The fail-closed pre-admission tombstone (a proposed revocation immediately narrows the slice for the affected principal pending admission) is queued as 4.0.x implementation, not adopted now. Revocation is `UNLINK member-of` (or `UNLINK governs`) — the slowest envelope class by construction, because access rewrites route through the Sam-gate.

## 3. The member-of fragment (v404-1-wf02-member-of)

WF02 `additional_port_pairs` += `member-of` / `has-member`, src `{user, agent, group}` → tgt `{group}`. LINK/UNLINK; many-to-many (no at-most-one; the pair schema carries no cardinality field — spans precedent). Port colors: **first use of `port_color_compatibility.port_color_map`**, mapping both ports → `auth` — required because the kernel color gate is fail-closed for declared-but-uncolored ports (kernel#50 landed; the stale permissive-skip note in the ontology was trued up in this bump).

Semantics:
- **Membership is identity topology** — distinct from `governs` (authority) and `has-occupant` (liveness). A member inherits the group's *grant-closure*: whatever the group owns (WF01), governs (WF02), or occupies (WF19) becomes reachable in the member's permitted sub-fold.
- The access BFS follows member-of in the **member → group direction only** (monotone widening; sharing/push = extension along user into group, per S5-as-applied).
- **group → group inclusion is legal** — this is the poset's middle rung. Acyclicity is doctrine, not validator (a cycle would be a governance error, caught by audit, not the operad).

## 4. Poset realization (this batch's graph witness)

```
user:sam —member-of→ group:sam —member-of→ group:moos ←spans— manifold:my-tiny-data-collider
agents (8 fold-present seat agents) —member-of→ group:moos
manifold —spans→ {group:moos · 4 vcs channels · purpose:sam.mvp-sovereign-knowledge-os · session:public-demo · session:sam.z440-cowork-workspace}
```
After apply: A1 = user < group < manifold-group is graph-witnessed on the Z440 primary fold. Laptop/ProDesk replication queued next round (G4: URN-equality is identity; asymmetric presence is legal). Still conjecture: B = A1×A2 as fibration base, S5, C7 (access-and-branching-one-structure as *law*), C8 (noninterference `fold(visible_A) = project_A(fold(all))` — untested until the t250-testing lane rules).

## 5. Branch stays projection; git is a channel

Per the T263 note (§5 verdict A→B) and t218: **git is `channel.kind: vcs` — a channel, never the home.** Branch = F(workspace); the branch name is the flattened WF19 tuple; merge = G(branch) under review. No branch or worktree nodes are reified. This batch ADDs the four repo **channels** (`github.ffs0`, `github.moos-kernel`, `github.moos-router`, `github.collider-pilot`) — reifying the surface the F-projection lands on, nothing more. The repo-shaped lens over the blessed log stays 4.0.x/MTDC.

## 6. Batch inventory and gates

| File (dev/scripts/ops/) | Envelopes | Actor | Gate |
|---|---|---|---|
| `t263-4_0_4-bump-wf20-ceremony.program.json` | ADD fragment → MUTATE promoted → MUTATE merged | kernel | 4.0.4 live on /healthz |
| `t263-membership-topology.staged.json` | 10 × WF02 member-of LINK | kernel | 4.0.4 live + Sam flips apply_ready |
| `t263-vcs-channels-and-spans.staged.json` | 4 × ADD channel · 4 × WF01 owns · 8 × WF18 spans | Zappa (ADDs) / kernel (LINKs) | Sam flips apply_ready |

Sam gates: (1) merge this PR; (2) announced Z440 federation restart onto 4.0.4 (moos.jsonl backed up first; throwaway boot validates the port_color_map before the fleet touches it); (3) flip `apply_ready`; (4) optional: add `vscode-codex.hp-z440` to group:moos.

Excluded from membership, stated: `claude-code.*` (retired principals) · `vscode-codex.hp-z440` (fold-present, not an active seat) · `vscode.hp-laptop.copilot`, `vscode.hpprodesk.primary` (absent from the Z440 fold — ride the replication round).

## 7. Consequences for the access law

`permitted_workspaces = f(group_topology × user × workstation)` — `group_topology` extends from `governs ∪ delegates-to` to `governs ∪ delegates-to ∪ member-of`. Widening today is exactly `{group:sam, group:moos}` for sam (the groups own/govern/occupy nothing yet); real widening arrives only through future group-granted relations — which is the point of the glue. Anon path structurally unchanged (fail-closed short-circuit precedes the closure). Pilot `src/mcp/access.js` is the reference implementation and Go-port anchor; its PR follows the batch apply and must keep the anon asserts green.

## 8. Open questions (unchanged by this round)

- Group-internal *roles* (member vs admin of a group) — not modeled; `delegates-to` (role→role) remains the only capability-narrowing relation.
- The orphaned `governed-by` in-port on `group` (WF02 does not target group) — noted, deferred.
- One-user-per-fold enforcement (T249 F1: infra-ADD bypass is actor-agnostic) — P4-adjacent hardening, stays 4.0.x-class.

---
authored-by: agent:claude-cowork.hp-z440 / session:sam.z440-cowork-workspace / t263-user-topology-glue
