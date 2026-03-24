# VS Code Handoff After Project Sync (2026-03-24)

## Baseline

- Last Claude HG update observed in runtime log:
  - issued_at: 2026-03-24T07:38:44.944593505Z
  - actor: urn:moos:agent:claude-code
  - envelope: LINK urn:moos:message:20260324-lead-delegate-antigraviti -> urn:moos:prg:038-moos-media

## What changed since then (outside PRG execution)

1. GitHub workflow governance in both repos was expanded:
- Branch name policy now includes: feat, fix, chore, agent, admin, hotfix, release.
- PR templates now carry structured PRG/HG/agent/owner/category metadata.
- Issue form `PRG / Agent Task` added.
- Cloud kickstart workflow added and executed to seed labels + starter issue.

2. Next-step automation implemented in both repos:
- CODEOWNERS added.
- PR Intake workflow added for branch + content-based PR labeling.

3. Project operations completed for `mo:os` ProjectV2:
- Custom fields ensured: PRG, Phase, Agent ID, HG URN, Owner Role, Collider Category, Branch Role.
- New `project-sync.yml` workflow added in both repos.
- Auto-adds Issues/PRs to project and maps fields from PR template/Issue form values.
- Fixed auth by introducing `PROJECTS_TOKEN` secret in both repos.

4. Verified end-to-end mapping with smoke issues:
- `MSD21091969/moos#5`
- `MSD21091969/ffs0-factory-super#8`
- Project fields now populated: PRG, Phase, Agent ID, HG URN, Owner Role, Collider Category.

## Procedural deltas / rules inferred since Karpathy wiring integration

1. Delegation is type-driven, not heuristic:
- `delegation_task` is the canonical execution signal.
- listeners and session start workflows should poll `kind=delegation_task` + status transitions.

2. Harness state-machine discipline is now explicit:
- gate sequencing and phase validation are treated as "nines" progression.
- no work starts without typed PRG phase or delegation_task anchoring.

3. Shipping controls are now mandatory path artifacts:
- branch-policy checks
- PR template evidence
- issue templates and label taxonomy
- project field mapping tied to HG semantics

4. GitHub ProjectV2 implementation caveat:
- SINGLE_SELECT creation via GraphQL requires `description` per option.
- project writes from Actions need PAT-backed secret (`PROJECTS_TOKEN`) for user-owned project access.

## Claude fast-restart context

If Claude resumes now, focus on:
1. Keep PRG execution flow on delegation_task lifecycle.
2. Use project-sync fields as cloud projection of HG state.
3. If project-sync fails in Actions, validate `PROJECTS_TOKEN` scope includes `project`.
4. Treat this update as outside-PRG operational hardening and continue normal PRG lane from latest delegated task queue.
