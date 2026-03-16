# VS Code AI / Claude Copilot Instructions

**For:** VS Code Copilot (OpenAI Codex 5.3)
**Role:** Code execution agent
**Workspace:** Open `FFS0_Factory.code-workspace` (folders: root, .agent, moos)
**Protocol:** `.agent/CLAUDE.md`

---

## Session Start Checklist

1. Read state: `cfg/agents/vscode-ai.json`
2. Pull latest: `cd ../moos && git pull origin main`
3. Read direction: `.agent/channels/handoff.md`
4. Update state: set `status: "active"` in `cfg/agents/vscode-ai.json`
5. Verify boot: `cd ../moos/platform/kernel && go run ./cmd/moos --kb "../../ffs0-factory-super/.agent/kb" --hydrate`

## Task Execution Flow

1. Read assigned task file from `tasks/YYYYMMDD-NNN-name.md`
2. Implement code and tests
3. Verify: `go test ./...` and boot checks
4. Commit: `feat|fix|chore: <description> [task:YYYYMMDD-NNN]`
5. Push: `git push origin main`
6. Post completion to `.agent/channels/handoff.md`

## Rules

- Never write task files; Claude Code + Sam own `tasks/`
- Never modify `.agent/channels/testoff.md`; read-only for VS Code AI
- Do write blockers/questions/completions to `.agent/channels/handoff.md`
- Do update `cfg/agents/vscode-ai.json` at session start/end
- Always run tests before commit
- Never force-push or rewrite history

## Quick Reference

| Need              | Path                        | Action                                 |
| ----------------- | --------------------------- | -------------------------------------- |
| Next task         | `tasks/`                    | Read newest assigned task              |
| Direction channel | `channels/handoff.md`       | Read/post updates                      |
| Kernel boot       | `../moos/platform/kernel`   | `go run ./cmd/moos --kb ... --hydrate` |
| Tests             | `../moos/platform/kernel`   | `go test ./...`                        |
| Agent state       | `cfg/agents/vscode-ai.json` | Update status/timestamps               |

## Troubleshooting

- Kernel boot fails: verify `.agent/kb/superset/ontology.json` exists and port `:8000` is free
- Tests fail: rerun package-specific tests and inspect recent diffs
- Push rejected: pull/rebase then push

## Success Criteria

- Acceptance criteria met
- Tests green
- Kernel boot verified
- Commit pushed with task tag
- Completion posted to handoff channel
- Agent state updated
