---
name: moos-github-project-bridge
description: Two-way sync between the HG and the Collider-Data-Systems "mo:os" GitHub Projects v2 board (#4). Use when creating/updating/closing HG nodes (program, session, agent, purpose, grammar_fragment, knowledge_item) and you want the board reflected, OR when a board item status changes and the referenced HG node needs a MUTATE. Covers the F ⊣ G adjunction between HG and GitHub Projects with round-trip fidelity as the invariant.
---

# moos-github-project-bridge

HG ↔ GitHub Projects v2 sync. The mo:os board (Collider-Data-Systems/projects/4) is the external surface; this skill carries envelopes through the adjunction.

## Boundaries

- **`F: HG → board`** — emit project-item writes when HG nodes land or transition.
- **`G: board → HG`** — emit HG MUTATEs when board items move state.
- **Round-trip fidelity** — a node that has emitted F then observed G should round-trip back to an equivalent HG state (the unit η).

What this skill does NOT do:

- Create GitHub issues or PRs. Those are authored by humans / coding agents (me, Guido, AG, future Cowork). The bridge ATTACHES existing issues/PRs to the board and sets custom fields.
- Sync repo contents, branches, CI status. Out of scope.
- Decide merge readiness. That's review-cycle, not board state.

## The mo:os project board

- Org: `Collider-Data-Systems`
- Project number: `4`
- Project node id: `PVT_kwDOEGql9M4BVUTp`
- Source URI: `https://github.com/orgs/Collider-Data-Systems/projects/4`
- HG reification: `channel:github.project.mo-os` (parent: `channel:github.collider-data-systems`)

### Fields (19 total; 7 custom are HG-aware)

| Field | Type | HG mapping | Required on create |
|---|---|---|---|
| Title | TITLE | `<node>.text` short form OR issue/PR title | yes |
| Assignees | ASSIGNEES | derived from `<node>.has-occupant` principal | no |
| Status | SINGLE_SELECT (Todo \| In Progress \| Done) | `<node>.status` enum mapping per §5 | yes |
| Labels | LABELS | derived per category | no |
| Linked pull requests | LINKED_PULL_REQUESTS | when node refers to moos-kernel PR | no |
| Milestone | MILESTONE | derived from `target_t` band | no |
| Repository | REPOSITORY | `ffs0` \| `moos-kernel` \| `moos-router` | no |
| Reviewers | REVIEWERS | only if item is a PR | no |
| Parent issue | PARENT_ISSUE | parent node URN (via `composes-by` or similar) | no |
| Sub-issues progress | SUB_ISSUES_PROGRESS | auto | no |
| **PRG** | TEXT | program slug (e.g. `sam.t187-kernel-proper`) | yes if related to a program |
| **Phase** | TEXT | phase slug (free text; convention: lowercase-kebab-case) | no |
| **Agent ID** | TEXT | `agent.board_id` property (e.g. `AGENT-CODE-Z440`, `AGENT-COWORK-Z440`) | yes if driven by an agent |
| **HG URN** | TEXT | full URN of the referenced HG node | **yes — this is the round-trip key** |
| **Owner Role** | SINGLE_SELECT (user \| admin \| group \| agent) | principal type of the `owner_urn` or (post-v3.13) `owns` edge | yes |
| **Collider Category** | SINGLE_SELECT (delegation_task \| channel_message \| agent_session \| ptp_family \| other) | derived from node type §6 | yes |
| **Branch Role** | SINGLE_SELECT (feature \| hotfix \| agent \| admin \| release) | for PRs only | no |
| **Iteration** | ITERATION | T-day band mapped to project iteration | no |

Always populate **HG URN** — it's the key the G direction uses to find the right HG node to MUTATE.

## F direction: HG node → board item

### When to emit

Trigger on any of:

- `ADD` of types: `program`, `session`, `purpose`, `grammar_fragment`, `knowledge_item` (top-level, not chunks)
- `MUTATE` of `status` on any of the above
- `MUTATE` of `target_t` (schedule change → iteration change)
- `LINK` of `has-occupant` on a session (assignees change)
- New issue or PR in Collider-Data-Systems/{ffs0,moos-kernel,moos-router} that declares an HG URN in its body (`HG URN: urn:moos:<type>:<slug>`)

### How to emit

Use `gh api graphql` against the Projects v2 mutation API. Do NOT use REST for Projects v2 — it doesn't exist.

**Create item** (for an HG node that has no existing issue/PR):

```
mutation {
  addProjectV2DraftIssue(input: {
    projectId: "PVT_kwDOEGql9M4BVUTp",
    title: "<node.text short form>",
    body: "HG URN: <full urn>\n\n<node.text long form>"
  }) {
    projectItem { id }
  }
}
```

Then set custom fields one-by-one via `updateProjectV2ItemFieldValue`. Field IDs are project-scoped; fetch once via:

```bash
gh api graphql -f query='{ node(id: "PVT_kwDOEGql9M4BVUTp") { ... on ProjectV2 { fields(first: 30) { nodes { ... on ProjectV2Field { id name } ... on ProjectV2SingleSelectField { id name options { id name } } } } } }'
```

Cache the field IDs (they're stable) in the kernel's HG as `channel.project.field-id-map` or pass them through the skill invocation.

**Attach existing issue/PR** (when the bridge discovers an HG URN in an issue body):

```
mutation {
  addProjectV2ItemById(input: {
    projectId: "PVT_kwDOEGql9M4BVUTp",
    contentId: "<issue or PR node id>"
  }) { item { id } }
}
```

Then populate custom fields as above.

### HG URN body convention

Every board-linked issue/PR SHOULD have in its body:

```
HG URN: urn:moos:<type>:<slug>
```

on its own line, near the top. The G direction greps for this when figuring out which HG node a status change refers to. If the URN is missing, the G direction can't round-trip and the item falls into "orphan" — flag via `moos-cowork-readback` at round-open.

## G direction: board status change → HG MUTATE

### When to emit

Trigger on project webhook events (once a webhook receiver exists; today: polled):

- `projects_v2_item.edited` where `field_name == "Status"` → status transition
- `projects_v2_item.edited` where `field_name == "Iteration"` → schedule shift
- `projects_v2_item.edited` where `field_name == "Assignees"` → has-occupant rotation
- `projects_v2_item.archived` → status=archived or node MUTATE

### How to resolve

1. Read the item's `HG URN` field. No URN → log + skip (orphan item; human triage).
2. Look up the HG node via `GET /state/nodes/<urn>` against the kernel that owns it (usually `kernel:hp-z440.primary`).
3. Translate the board field change to an HG property MUTATE per the mapping table in §1.
4. Emit the MUTATE via `POST /programs` with the appropriate actor:
   - Agent actor for status/scope/text mutations (inferred-session path)
   - Kernel actor for kernel-authority-scope properties

### Status enum mapping (F and G)

| Board Status | HG `status` equivalents |
|---|---|
| Todo | `proposed` (grammar_fragment), `pending` (t_hook), `pending_driver` (session), `active` (for not-yet-started programs with target_t in the future) |
| In Progress | `active` (for in-motion programs), `driving` (session with an occupant and recent rewrites) |
| Done | `merged` (grammar_fragment), `completed` (program), `closed` (t_hook, session), `checkpoint` (program that hit a target_t milestone) |

Ambiguity rule: if the translation is lossy, prefer preserving HG state. Emit a `channel_message` note in the `Collider Category` field describing the lossy translation rather than flattening.

## Collider Category derivation

| HG type | Category |
|---|---|
| `program`, `purpose` (scope >1 agent) | `delegation_task` |
| `knowledge_item`, `diary_entry` (v3.13) | `channel_message` |
| `session`, `agent_session` | `agent_session` |
| `grammar_fragment`, `system_instruction` | `other` |
| ptp_* (point-to-point personal family nodes; Sam's IRL family) | `ptp_family` |

`ptp_family` is the Moos-Dachshund / Menno / Lola lane — IRL-personal scope where HG reifies family/pet relationships (currently implicit via seat assignment; explicit via v3.13 `group` nodes).

## Group handling — deferred until v3.13

Currently principalTypes = `{user, agent}`. Board's `Owner Role` enum includes `group`. Until `grammar_fragment:v313-7-group-type` promotes via WF20, the bridge:

- Maps `Owner Role = group` items to their `HG URN` if present (the owning group is indicated in the item body, not as an HG node).
- For F direction: when ADDing a program/session owned by a collective, set `Owner Role = group` on the board item and write the group slug into `Phase` or the body. After v3.13 promotion the bridge re-syncs these to proper `group:<slug>` nodes.

`sam` and `moos` teams on the GitHub org are known proto-groups. Post-v3.13 they become:

- `group:sam` with `owns → kernel:hp-z440.primary, session:sam.kernel-proper, session:sam.governance, ...` (many edges)
- `group:moos` with `owns → kernel:hp-z440.moos, session:sam.moos-diary, purpose:sam.multimodal-curation-and-diary`

## Iteration / cycles mapping

GitHub Iterations are time-boxed (weekly/bi-weekly by default). T-day bands are the HG analog:

- Iteration name format: `T=<start>–<end>` (e.g. `T=170–176` for a week-ish band) OR sam-meaningful labels (`Round 11`, `Court setup`)
- F direction: derive from node's `target_t` or `completed_t` property.
- G direction: iteration change → MUTATE `target_t` if schedule slipped.

Sam's weekly ritual (Monday 08:00-09:00 purple/red calendar sync) is the natural iteration tick. Bridge skill's scheduled run lives at that time (via Cowork scheduled-tasks).

## Actor discipline (post-§M11)

All bridge-emitted envelopes use one of:

- `agent:claude-cowork.hp-z440` — when bridge runs inside Claude Desktop on Z440 (scheduled task)
- `agent:claude-code.hp-z440` — when bridge runs inside Claude Code on Z440 (ad-hoc)
- `agent:antigravity.hp-z440` — if AG picks up the bridge task
- `kernel:hp-z440.primary` — for ontology-governed MUTATEs (rare for this skill)

Never user:sam. Always verify the driving session has has-occupant in HG state before emitting.

## Failure modes + recovery

| Failure | Recovery |
|---|---|
| Orphan item (no HG URN in body/field) | Log; surface in `moos-cowork-readback` at round-open; human triage |
| HG node missing when G tries to MUTATE | Log; the node may have been UNLINKed from an umbrella or archived; don't force-create |
| GitHub API rate limit | Back off; bridge is idempotent (re-running emits no-op on already-synced items) |
| Field ID map stale (GitHub added fields) | Re-fetch field IDs on `unknown field` error; cache refresh |
| Projects v2 permission error | Bridge needs `project` scope on the GitHub token; verify `gh auth status` includes it |

## Integration with running-state

At round-open (`moos-state-readback`): report orphan items + items with `Status=In Progress` but no recent HG activity on the referenced node (stalled work).

At round-close (`moos-round-close`): emit a single F-direction sweep so the board reflects the round's landed HG changes. Optional; round can close without touching the board if nothing changed that's projection-relevant.

## Implementation queue

**Phase 1 (MVP, ~200 LoC)**:

- CLI wrapper `moos-github-bridge.ps1` (Windows primary) or `.sh` (Linux later)
- F direction: walk state snapshot for {program, session, agent, purpose} with `status ∈ {active, pending, in-progress}`, upsert board items, populate HG URN + PRG + Agent ID + Owner Role + Status fields
- Hydrate field-ID map once, cache in `ffs0/dev/reference/project-field-ids.json`
- Idempotent on re-run

**Phase 2 (G direction)**:

- Polling loop reading board deltas via `projects_v2_item` timestamps
- Status/Iteration/Assignees → HG MUTATE translations
- Orphan report

**Phase 3 (post-v3.13)**:

- Group node support
- `owns` port-pair traversal replaces property-based owner_urn lookups
- `channel.kind = project-board` (dedicated enum) once v313-8 promotes

## Cross-references

- `channel:github.collider-data-systems` — org root channel
- `channel:github.project.mo-os` — project board channel
- `purpose:sam.github-project-board-sync` — this skill's lane
- `grammar_fragment:v313-7-group-type` (proposed) — group type for Owner Role=group
- `grammar_fragment:v313-8-channel-kind-vcs` (proposed) — dedicated VCS + project-board kinds
- `grammar_fragment:v313-9-owns-port-pair` (proposed) — WF01 owns/owned-by for group → downstream
- `kb/research/session/20260422-t172-cowork-as-occupant.md` §3 — chunking discipline (applies to issues + comments too)
- `~/.claude/plans/valiant-kindling-sunrise.md` §2 — adjunction F ⊣ G framing

## Skill status

**Draft — not yet implemented.** T=173 introduction. Substrate (channel nodes + purpose + grammar_fragments) landed at log_seq 265-270. Implementation deferred: Wolfram's lane, queued after v3.13 grammar_fragment promotion makes the group-type work first-class.
