# GitHub org + project-board operations — runbook

> **Operator: Zappa** (`agent:claude-cowork.hp-z440` / `session:sam.z440-cowork-workspace`) — Sam handed over board + org operations at **T=247**. Lane: `purpose:sam.github-project-board-sync` (pinned to the Zappa workspace T=245). Doctrine SOT for the bridge mapping: `dev/claude-skills/moos-github-project-bridge/SKILL.md` — this runbook is operations, not doctrine; don't restate the field-mapping table here.
> Board/field identity constants: **`dev/reference/project-field-ids.json`** (read it at runtime, never hardcode `PVT_*` ids). T=247 full item snapshot: `dev/reference/board-baseline-t247.json` (Projects v2 data has no git history — re-snapshot at milestones).

## Org map (verified by readback T=247)

| Entity | State |
|---|---|
| Org | `Collider-Data-Systems` · GitHub **Free** · created 2026-04-12 · billing → owner account |
| Accounts | `MSD21091969` (Sam, sole **owner**) · `MoosT2025` (agent account, member — **effective admin on all repos incl. ffs0** via teams) |
| Teams | `sam`, `moos` — identical membership (both accounts), both grant **admin on all 5 repos**. Zero least-privilege separation today. HG: proto-groups pending v3.13 `group` nodes. |
| Repos | `ffs0` (private) · `moos-kernel` (public) · `moos-router` (public) · `.github` (public, org profile) · `demo-repository` (private, stock demo — archival candidate) |
| Projects | org **#4 "mo:os"** = the board (`channel:github.project.mo-os`). User project `MSD21091969/#1` = legacy duplicate (20 items) — close after the Action repoint merges. |
| Board | private; 84 items at baseline; 6 built-in workflows on; **no auto-add-from-repo** (plan-gated) — auto-add rides `.github/workflows/project-sync.yml` instead |

**Plan constraints (Free):** no branch protection / rulesets on **private** repos (ffs0 is guardrail-less server-side — local discipline is the only gate); rulesets **are free on public repos**; built-in project auto-add workflow unavailable.

## Operating cadences

| When | What | How |
|---|---|---|
| Round-open | Board audit: unattached open items, open orphans (no HG URN), status drift | `pwsh -NoProfile -ExecutionPolicy Bypass -File dev\scripts\ops\Sync-ProjectBoard.ps1` (read-only) |
| New issue/PR lands | **Standing rule (Sam, T=247): always add with details — never bare.** The Action auto-adds Status-only; the creating seat immediately backfills the full field set via `-Mode Attach -Repo <r> -Number <n> -HgUrn <urn> -AgentId <id> -OwnerRole <role> -Category <cat> -Phase <phase>` in the same breath | `HG URN` is the G-direction round-trip key; a Status-only card is an orphan |
| Work starts on a card | Status → In Progress (Action does it on reopen/synchronize; manual via board UI or Attach) | |
| Round-close | F-direction sweep so the board reflects the round | `Sync-ProjectBoard.ps1 -Mode Sweep` (dry-run), then `-Apply` |
| Milestones | Re-snapshot the board into `dev/reference/board-baseline-t<N>.json` | the GraphQL export in the bridge SKILL.md |

**HG gate (unchanged):** `session-affordance-map.json → github_identity.sync_policy` = *inventory + HG URN repair only; no G-sync of board Status into HG* until board-row identity is reliable (31/57 rows had HG URN at last inventory). `Sync-ProjectBoard.ps1` emits **no HG rewrites** by design.

## Automation inventory

- **`.github/workflows/project-sync.yml`** (ffs0) — on issue/PR events: add to board + set Status (Todo/In Progress/Done). Repointed T=247 to org project #4; authenticates with `secrets.PROJECTS_TOKEN` (Actions' `github.token` **cannot write org Projects v2**). Non-blocking by design (warns + skips on failure). Replicate to `moos-kernel`/`moos-router` — queue item Q1.
- **`PROJECTS_TOKEN`** (ffs0 Actions secret, set 2026-03-24) — PAT for board writes. **Unverified since the T244 PAT revocations** — if Action runs log "Project not accessible", mint a fine-grained PAT (org `Collider-Data-Systems`, Projects read/write) and update the secret. Record expiry here when rotated.
- **Board built-ins** (6, all on): item-closed→Done, PR-merged→Done, auto-close-issue, auto-add-sub-issues, PR-linked, item-added→Todo.
- **`Watch-GitHubIssue.ps1`** — issue-comment coordination poller (ffs0#54 default); separate concern, unchanged.
- **Copilot billing is usage-based for this org** (banner observed T=247) — every PR-route Copilot review has a marginal cost; keep the one-review-per-PR cadence, don't re-request on trivial pushes. Sam can set a per-user budget in org settings.

## Token / scope table

| Credential | Where | Scopes | Gaps |
|---|---|---|---|
| `gh` keyring (Z440, MSD21091969) | this workstation | `gist project read:org repo workflow` | **no `admin:org`** → team/org-settings writes fail; bump: `gh auth refresh -s admin:org` (owner call) |
| `PROJECTS_TOKEN` | ffs0 Actions secret | unknown (pre-T244) | verify on next Action run; rotate to fine-grained PAT |
| hp-laptop / ProDesk `gh` | other seats | unaudited | audit at next seat hydration on each box |

## Decision ledger — what Zappa does vs. what stays owner-gated

**Zappa, autonomous:** board field/status writes, attach/sweep, audits + snapshots, issue/PR authoring, PR creation + Copilot review requests, runbook upkeep.
**Owner-gated (Sam):** PR **merges** (harness classifier blocks agent self-merge of agent-authored PRs — deliberate); org settings (2FA requirement, member privileges, default perms); team grants/membership (also blocked by missing `admin:org`); repo archive/delete/visibility; plan upgrade; HG rewrites (per running-state boundaries); closing legacy project #1 (Zappa executes after Sam's go once the Action repoint is merged).

## Hardening queue (from the T=247 five-agent audit)

> **T=248 status:** Q4 legacy project #1 **CLOSED** ✓ · demo-repository **ARCHIVED** ✓ (both executed by Zappa under the T248 catch-up goal). Remaining four are hard owner-gated: 2FA flip + org secret = UI/value only Sam has; rulesets + team-permission changes = classifier requires Sam's explicit per-action words or his own hands. **Least-privilege evidence (T248): MoosT2025 has ZERO commits in any repo** (per `GET /repos/<r>/commits?author=MoosT2025` across all 4 active repos, all empty) — dropping both teams' repo permission to Read is zero-disruption (org owners keep admin by ownership).

Owner-action (Sam, org settings UI unless noted):
1. **Enable org 2FA requirement** — biggest gap. Precondition met: Sam's People-page readback (T=247 screenshot) shows **both accounts already have 2FA enabled** → flipping the requirement carries no lockout risk (still vault MoosT2025 recovery codes in `secrets/`).
2. **Restrict member repo-deletion / visibility-change to owners** — MoosT2025 currently can delete/expose any repo incl. ffs0.
3. **Downgrade MoosT2025 to least privilege** — write/maintain on the repos it actually pushes to, not admin-everywhere (needs `admin:org` or UI).
4. **Enable security defaults** — secret scanning + push protection on public repos (free); dependabot alerts.
5. ~~**demo-repository** — archive or delete~~ **DONE T=248: archived** (reversible; its 2 stock Actions are inert on an archived repo).
6. Decide: plan upgrade if server-side protection on ffs0 matters.

Zappa-executable (queued):
- **Q1** replicate project-sync.yml to moos-kernel + moos-router (after the ffs0 repoint merges).
- **Q2** rulesets on public repos (block force-push + deletion on default branch; free) — **blocked by the harness classifier T=247** (org-governance mutation needs Sam's explicit go or a permission rule). Ready-to-run: `gh api -X POST repos/Collider-Data-Systems/<repo>/rulesets` with `{"name":"protect-default-branch","target":"branch","enforcement":"active","conditions":{"ref_name":{"include":["~DEFAULT_BRANCH"],"exclude":[]}},"rules":[{"type":"non_fast_forward"},{"type":"deletion"}]}` for `moos-kernel` · `moos-router` · `.github`.
- **Q3** `SECURITY.md` in `.github` (vuln-reporting channel for the public repos).
- ~~**Q4** close legacy project `MSD21091969/#1`~~ **DONE T=248: closed** (20 items retained, reopenable).
- **Q5** board hygiene: delete/rename "New field 8" (3 items carry a 2026-04-21 date — decide keep-as-"Legacy Date" vs drop).
- **Q6** notification SPOF: add a scheduled Action or org webhook alerting on force-push / member-change / repo-deletion (audit-log retention on Free is 90 days).

## Cross-references

`moos-github-project-bridge/SKILL.md` (doctrine + GraphQL shapes) · `project-field-ids.json` (identity/ids) · `board-baseline-t247.json` (snapshot) · `session-affordance-map.json → github_identity` (sync gate) · `moos-round-close/SKILL.md` step 5 (issue-comment handoff — reuse, don't duplicate) · `Watch-GitHubIssue.ps1` (comment poller) · ops `README.md` (script registry).

authored-by: agent:claude-cowork.hp-z440 / session:sam.z440-cowork-workspace / t247-github-takeover
