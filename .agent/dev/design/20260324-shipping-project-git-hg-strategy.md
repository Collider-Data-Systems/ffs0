# Shipping Strategy: GitHub Projects + Feature Branches + HG Mapping

Date: 2026-03-24  
Status: Active proposal (ready to adopt)  
Depends on: 20260324-triangle-operations-manual.md, 20260321-prg-in-graph.md, 20260319-cloverleaf-kernel-topology.md

---

## 1. Purpose

As the system shifts from experimentation to shipping, we need one operating model that aligns:

1. Local development and git branch flow.
2. GitHub Projects planning and release visibility.
3. Hypergraph (HG) runtime truth for sessions, PRGs, and delegation.

This strategy keeps all three synchronized while preserving the graph-first architecture.

---

## 2. Operating Principles

1. Git is code truth for source files.
2. HG is runtime/process truth for session state, delegation, and PRG lifecycle.
3. GitHub Projects is delivery truth for roadmap, owners, and release status.
4. No work item starts without a typed PRG phase or delegation_task in HG.
5. No work item closes without both git evidence (commit/PR) and HG checkpoint.

---

## 3. Branch Model (Shipping)

## Long-lived branches

1. main

- Protected.
- Always releasable.
- Merge by PR only.

2. release/<version> (optional once cadence is regular)

- Stabilization branch for final QA/hotfix before release.
- Back-merge to main after release.

## Short-lived branches

1. feat/<scope>-<short-name>

- Example: feat/prg039-5-delegation-task-wiring
- Used for net-new functionality.

2. fix/<scope>-<short-name>

- Example: fix/listener-delegation-task-filter
- Used for defects/regressions.

3. chore/<scope>-<short-name>

- Example: chore/workflow-session-start-vscode
- Used for non-feature operational updates.

## Local discipline

1. One branch per task.
2. Rebase/merge main daily.
3. Small commits with clear intent.
4. Push early, open draft PR early.

---

## 4. Commit and PR Conventions

## Commit format

Use conventional prefix with PRG/phase hint:

- feat(prg039.5): add DELEGATES/RECEIVES ontology morphisms
- fix(prg001.6): poll delegation_task instead of channel heuristic
- chore(prg001.7): add vscode session start workflow

## Pull request template requirements

Every PR includes:

1. PRG and phase IDs.
2. HG URNs touched (prg_task/session/message/delegation_task).
3. Validation evidence (tests, endpoint checks).
4. Rollback notes.

Suggested PR title pattern:

[PRG039.5] feat: delegates/receives wire protocol

---

## 5. GitHub Projects: Shipping Schema

Use one project as release control plane.

## Core custom fields

1. Item Type

- epic | feature | hardening | blocker | release-task

2. Repo

- ffs0-factory-super | ffs1-collider-super | ffs2-collider-backend | ffs3-collider-frontend

3. PRG

- Example: PRG039

4. Phase

- Example: 039.5

5. HG URN

- Primary urn:moos:\* node for the item.

6. Target Release

- Example: 0.9.0

7. Owner

- vscode-ai | claude-code | antigraviti | human

8. Delivery Status

- planned | delegated | in_progress | in_review | merged | shipped | blocked

9. Risk

- low | medium | high

10. Rollback Class

- config-only | reversible-data | migration-required

## Required views

1. Shipping this week (Target Release + in_progress/in_review).
2. Blocked critical path (Delivery Status=blocked, Risk=high).
3. By PRG phase (group by PRG, then Phase).
4. Ready to ship (merged + checks green + no blockers).

---

## 6. Direct Mapping: Git <-> GitHub <-> HG

## Entity mapping

1. Feature branch <-> delegation_task (HG)

- Branch name appears in delegation_task payload.branch.

2. Commit <-> channel_message checkpoint (HG)

- Include commit SHA and summary in message payload.

3. Pull request <-> prg_task phase execution window

- PR open = phase in_progress.
- PR merged = phase completed candidate.

4. Release tag <-> keep_note or channel_message release checkpoint

- Tag vX.Y.Z mapped to release note node linked to affected PRGs.

## Event mapping contract

1. Branch created for task

- ADD delegation_task(status=pending, assigned_to, prg_urn, phase_id, branch).

2. Task claimed

- MUTATE delegation_task status=pending -> in_progress.

3. PR opened

- ADD channel_message(type=pr_open, pr_url, branch, sha).
- LINK message -> prg_task.

4. PR merged

- MUTATE prg_task phase status -> completed with validation_result.
- MUTATE delegation_task status -> completed.
- ADD channel_message(type=completion, pr_url, merge_sha).

5. Release cut

- ADD keep_note(type=release_checkpoint, tag, build, migration_notes).
- LINK release note -> relevant PRGs.

---

## 7. Minimal Automation (Now)

## GitHub Actions

1. On pull_request opened/synchronize:

- Run build/tests.
- Comment PR with checklist state.

2. On pull_request closed merged:

- Emit webhook/job to write HG completion checkpoint.

3. On tag push v\*:

- Generate release notes.
- Emit HG release checkpoint.

## Manual fallback (if webhook not available)

1. Use a small script after merge that posts:

- MUTATE for phase completion.
- ADD completion message + LINK to PRG.

This preserves graph truth even without full CI-to-HG bridge.

---

## 8. Phase-Gate Shipping Policy

For gate PRGs (034/035/036/037):

1. No direct completion mutation without linked git evidence.
2. Required evidence per phase:

- test output
- runtime validation (where relevant)
- checkpoint message

For adaptive PRGs (001/038/039/040):

1. Phase ordering can adapt.
2. Still requires same completion evidence package.

---

## 9. Practical Branch Naming Matrix

1. feat/prg001-5-delegation-task-type
2. feat/prg039-5-session-delegates-receives
3. fix/prg001-6-antigraviti-listener-poll
4. chore/prg001-7-session-start-vscode

These names map 1:1 with phase-level HG checkpoints and Project items.

---

## 10. Ready-to-Ship Checklist

Before marking an item shipped:

1. Branch merged to main.
2. Required checks green.
3. PR linked to Project item.
4. PRG phase mutated to completed in HG.
5. delegation_task closed in HG.
6. Completion message linked to PRG in HG.
7. Release view shows no high-risk blockers.

---

## 11. Immediate Adoption Plan (Next 48h)

1. Add the custom fields and views in GitHub Projects.
2. Start enforcing branch naming by PRG/phase.
3. Update PR template with HG URN + checkpoint requirements.
4. Use delegation_task payload.branch for new delegated work.
5. Add one post-merge script (or action) to write HG completion morphisms.

---

## 12. Why This Fits mo:os

This strategy matches the existing architecture:

1. Graph remains the operational state machine.
2. Git remains the artifact history.
3. Project remains the portfolio and release lens.
4. Mapping is explicit, typed, and auditable.

No duplicate tracking systems are required; only synchronized projections.

---

## 13. Bootstrap Commands (Team Setup)

Run once per clone:

```powershell
Set-Location C:\Users\HP\FFS0_HPlaptop\ffs0-factory-super
pwsh -File .agent/dev/install-git-hooks.ps1
git config --get core.hooksPath
```

Verify branch guard behavior locally:

```powershell
git checkout -b feat/prg000-bootstrap-check
git push -u origin feat/prg000-bootstrap-check
```

Expected:

1. Local pre-push hook allows valid branch names.
2. GitHub Branch Name Guard workflow enforces naming on PR.
3. PR template prompts PRG/phase/HG evidence.
