# GitHub org + project-board operations — runbook

> **Operator: Zappa** (`agent:claude-cowork.hp-z440` / `session:sam.z440-cowork-workspace`) — Sam handed over board + org operations at **T=247**. Lane: `purpose:sam.github-project-board-sync` (pinned to the Zappa workspace T=245). Doctrine SOT for the bridge mapping: `dev/claude-skills/moos-github-project-bridge/SKILL.md` — this runbook is operations, not doctrine; don't restate the field-mapping table here.
> Board/field identity constants: **`dev/reference/project-field-ids.json`** (read it at runtime, never hardcode `PVT_*` ids). T=247 full item snapshot: `dev/reference/board-baseline-t247.json` (Projects v2 data has no git history — re-snapshot at milestones).

## Org map (verified by readback T=247)

| Entity | State |
|---|---|
| Org | `Collider-Data-Systems` · GitHub **Free** · created 2026-04-12 · billing → owner account |
| Accounts | `MSD21091969` (Sam, sole **owner**). ~~`MoosT2025`~~ **removed from the org T=248** (Sam; zero commits ever — see least-privilege evidence below). Caveat: any PATs it owned died with it — if `PROJECTS_TOKEN` was its, the sync Action warn+skips until the org secret lands with a fresh Sam-minted fine-grained PAT. |
| Teams | `sam`, `moos` — since T=248 both contain only `MSD21091969` (owner); their admin grants are inert. HG: proto-groups pending v3.13 `group` nodes. |
| Repos | `ffs0` (private) · `moos-kernel` (public) · `moos-router` (public) · `.github` (public, org profile) · `demo-repository` (private, **archived T=248**) |
| Projects | org **#4 "mo:os"** = the board (`channel:github.project.mo-os`). User project `MSD21091969/#1` = legacy duplicate — **closed T=248** (20 items retained). |
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

> **T=248 status:** Q4 legacy project #1 **CLOSED** ✓ · demo-repository **ARCHIVED** ✓ · **org 2FA requirement ENABLED** ✓ (2026-07-07 02:41, Sam via Cowork-Z440-driven browser; no-lockout re-verified live). **Public-repo rulesets APPLIED** ✓ (~03:30, Zappa on Sam's literal "apply the rulesets" — see Q2). **T=248 ~04:15 "knock out all" close (Sam authorized all four via AskUserQuestion → Zappa/Cowork-Z440): owner-item-4 security defaults APPLIED ✓ · Q3 SECURITY.md COMMITTED ✓ · Q5 board field renamed ✓ · Q6 sentinel PR-routed (3 PRs, review-ready, merge owner-gated).** Remaining owner-gated: `PROJECTS_TOKEN` org secret = value only Sam has; any future team-permission change = Sam's hands (classifier + missing `admin:org`); ~~the 3 Q6 PR merges (classifier blocks agent self-merge)~~ **Q6 PRs MERGED by Sam 2026-07-07 ~09:40** — moos-kernel#47+#48 · moos-router#9+#10 · .github#1+#2 (the +1s fix an invalid `administration` permission key + make the ruleset-read PAT optional; the two 02:25/02:30Z failed runs were pre-fix, expected). **Post-fix verified T=248 ~11:25 (Zappa, Sam-approved dispatch ×3): all 3 runs `completed success` in 10-12s, zero alert issues — Q6 closed end-to-end.** **Least-privilege evidence (T248): MoosT2025 has ZERO commits in any repo** (per `GET /repos/<r>/commits?author=MoosT2025` across all 4 active repos, all empty) — dropping both teams' repo permission to Read is zero-disruption (org owners keep admin by ownership).

Owner-action (Sam, org settings UI unless noted):
1. ~~**Enable org 2FA requirement**~~ **DONE T=248 (02:41, Sam via Cowork-Z440-driven browser):** org-wide *Require two-factor authentication for everyone* is ON — verified checked after a fresh reload; no-lockout re-confirmed live (`people?query=two-factor:disabled` returned zero members; org = sole owner). ~~**Follow-up (new finding):** the *Only allow secure two-factor methods* sub-policy is **BLOCKED** — the owner's **personal** 2FA is **SMS**, which GitHub does not count as secure.~~ **DONE T=248 (~10:00):** Sam migrated personal 2FA off SMS and ticked the sub-policy himself (owner-gated, his own click; agent verified only) — persisted on a fresh reload (both boxes checked) + API `two_factor_requirement_enabled:true`, zero members without 2FA. **Org 2FA hardening fully closed.**
2. ~~**Restrict member repo-deletion / visibility-change to owners** — moot while the org has no non-owner members (T=248); set it before inviting any future member or agent account.~~ **DONE T=248 (~10:35, Zappa on Sam's AskUserQuestion-approved 7-item list; trigger = Sam re-invited MoosT2025 as Member ~10:20):** base permission `read`→**`none`** (kills automatic member read on private ffs0) · repo creation OFF (public+private) · repo deletion/transfer OFF · visibility change OFF · team creation OFF · Pages creation OFF · issue deletion already off. 5 via `PATCH /orgs` + 2 (deletion, visibility) via browser (API silently ignores them on Free); all re-read-verified. **Platform-limited residual:** `members_can_invite_outside_collaborators` stays `true` — no UI on Free, API ignores the field; moot in practice (members hold admin on nothing under base `none`, and both teams have zero repo grants). Reversible via same page/API. **Moos-rejoin notes:** team `Moos` = `pull` with NO repos attached → Moos gets public-repo read only until an explicit team/repo grant; org 2FA + secure-methods gate means the invite is unusable until MoosT2025 carries authenticator/passkey/GitHub-Mobile 2FA (no SMS); its pre-removal PATs are dead. **Identity (Sam, T=248):** MoosT2025 = Sam's own alt account (`studio66aanderijn@gmail.com`) = the GitHub presence of **Moos the Dachshund** — HG counterpart `urn:moos:user:moos`, already reified since 2026-04-10 on **his own kernel's graph** (`kernel:hp-z440.moos` :8003, where `user:moos —WF01 owns→ kernel:hp-z440.moos`; "exactly one user per kernel" holds — the primary stays Sam's graph). The team description was written from that fold; no HG reification needed.
3. ~~**Downgrade MoosT2025 to least privilege**~~ **DONE T=248: account removed from the org entirely** (Sam) — verified: no access to any private repo, both teams solo.
4. ~~**Enable security defaults** — secret scanning + push protection on public repos (free); dependabot alerts.~~ **DONE T=248 (~04:15, Zappa on Sam's explicit authorization):** `secret_scanning` + `secret_scanning_push_protection` = enabled and dependabot vulnerability-alerts on for **moos-kernel**, **moos-router**, **`.github`** (`PATCH /repos/<r>` + `PUT /repos/<r>/vulnerability-alerts`; re-read-verified `ss=enabled pp=enabled`). Reversible; free on public repos. (Executed via `gh api` with the owner token — needs repo-admin, which ownership grants; no `admin:org` required.)
5. ~~**demo-repository** — archive or delete~~ **DONE T=248: archived** (reversible; its 2 stock Actions are inert on an archived repo).
6. ~~Decide: plan upgrade if server-side protection on ffs0 matters.~~ **DECIDED T=249 (Sam): accept Free-tier limits** — no plan upgrade. ffs0 stays guarded by local discipline + the T249 worktree-per-branch doctrine; org audit-log alerting (member-change etc.) stays platform-limited (90-day retention, no API on Free) = **accepted risk, documented**. Revisit only if a second human principal gets write access.

Zappa-executable (queued):
- **Q1** replicate project-sync.yml to moos-kernel + moos-router (after the ffs0 repoint merges).
- ~~**Q2** rulesets on public repos (block force-push + deletion on default branch; free)~~ **DONE T=248 (~03:30, Sam's literal "apply the rulesets" → Zappa/Cowork-Z440):** `protect-default-branch` active + read-back-verified on `moos-kernel` (id 18596929) · `moos-router` (18596930) · `.github` (18596932) — each `enforcement:active`, condition `~DEFAULT_BRANCH` (resolves master/master/main), rules `non_fast_forward` + `deletion`. Reversible (deletable). ffs0 excluded (private/Free → rulesets unavailable).
- ~~**Q3** `SECURITY.md` in `.github` (vuln-reporting channel for the public repos).~~ **DONE T=248 (~04:15):** committed to `.github` main (`c037004`, direct via Contents API — doc, not code, so no PR-route). Preferred channel = GitHub private vulnerability reporting; fallback = `sam@my-tiny-data-collider.nl`. Applies org-wide to all public repos.
- ~~**Q4** close legacy project `MSD21091969/#1`~~ **DONE T=248: closed** (20 items retained, reopenable).
- ~~**Q5** board hygiene: delete/rename "New field 8" (3 items carry a 2026-04-21 date — decide keep-as-"Legacy Date" vs drop).~~ **DONE T=248 (~04:15):** verified 3 items DID carry `2026-04-21` (the earlier "no data" JSON note was stale) → chose keep-non-destructive: field **renamed `New field 8` → `Legacy Date`** (`updateProjectV2Field`, same id `PVTF_…6uw`). `project-field-ids.json` updated. Sam can still drop it later if the 3 dates are truly junk.
- **Q6** notification SPOF: add a scheduled Action or org webhook alerting on force-push / member-change / repo-deletion (audit-log retention on Free is 90 days). **PARTIAL T=248 (~04:15): `governance-sentinel.yml` PR-routed to all 3 public repos** — [moos-kernel#47](https://github.com/Collider-Data-Systems/moos-kernel/pull/47) · [moos-router#9](https://github.com/Collider-Data-Systems/moos-router/pull/9) · [.github#1](https://github.com/Collider-Data-Systems/.github/pull/1) (Copilot review requested; on board #4 with bridge fields; **merge is owner-gated** — classifier blocks agent self-merge). The workflow uses each repo's own `GITHUB_TOKEN` (no cross-repo secret) to check weekly that the Q2 default-branch ruleset stays active + open an alert issue if removed; a failed run also emails the owner. **Still NOT covered (Free-plan + no `admin:org`):** org **member-change** + **audit-log** alerting need an org webhook / audit-log API (GitHub Team/Enterprise) or a PAT with `admin:org`. After merging, run each workflow once via `workflow_dispatch` to confirm the token can read rulesets (it fails safe/quiet if not).

## Cross-references

`moos-github-project-bridge/SKILL.md` (doctrine + GraphQL shapes) · `project-field-ids.json` (identity/ids) · `board-baseline-t247.json` (snapshot) · `session-affordance-map.json → github_identity` (sync gate) · `moos-round-close/SKILL.md` step 5 (issue-comment handoff — reuse, don't duplicate) · `Watch-GitHubIssue.ps1` (comment poller) · ops `README.md` (script registry).

authored-by: agent:claude-cowork.hp-z440 / session:sam.z440-cowork-workspace / t247-github-takeover
