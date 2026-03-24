# Summary

Describe what changed and why.

## PRG Mapping

- PRG: <!-- e.g., PRG039 -->
- Phase: <!-- e.g., 039.5 -->
- HG URN(s): <!-- e.g., urn:moos:prg:039-session-identity -->
- Agent ID: <!-- e.g., AGENT-KERNEL-01 -->
- User/Admin/Group: <!-- e.g., user:alice, admin:ops, group:kernel-maintainers -->
- Collider Category: <!-- e.g., delegation_task, channel_message, agent_session -->

## Branch

- Branch name: <!-- should match feat/*, fix/*, chore/*, or release/* -->
- Branch role: <!-- feature | hotfix | agent | admin | release -->

## Validation Evidence

- [ ] Tests run locally (paste command + result)
- [ ] Runtime validation performed where applicable
- [ ] No unrelated files included

Commands/results:

```text
# Example
# go test ./... => ok
```

## HG Checkpoint Contract

- [ ] Completion channel_message will be posted to HG after merge
- [ ] Message links to target PRG node
- [ ] Phase mutation includes validation_result

Optional merge metadata:

- PR URL: <!-- paste URL -->
- Merge SHA: <!-- fill after merge -->

## Rollback

How to revert safely if needed.

## Risks

- Risk level: low | medium | high
- Notes:

## Kickstart Signals

- [ ] Auto-label ready (PRG/agent/category labels can be derived from this PR)
- [ ] Backlog issue linkage included if this PR closes/advances an issue
