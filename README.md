# ffs0-factory-super — workspace for moos

This repository is the private workspace (`ffs0-factory-super`); the public kernel repository is called `moos`.

## Quick Start

1. Open `FFS0_Factory.code-workspace` in VS Code.
2. Start kernel from `moos/platform/kernel`:

```powershell
go run ./cmd/moos --kb "../../ffs0-factory-super/.agent/kb" --hydrate
```

3. Verify:

```powershell
curl http://localhost:8000/healthz
curl -N http://localhost:8000/log/stream
```

4. Open Explorer: `http://localhost:8000/explorer`

## Current Layout

```text
ffs0-factory-super/
    .agent/
        CLAUDE.md
        channels/
            handoff.md
            testoff.md
        cfg/
            agents/
            copilot-instructions.md
            antigraviti-instructions.md
        tasks/
        kb/
            superset/
            instances/
            design/
            industry/
            reference/
            archive/
    moos/ (sibling folder via workspace)
```

## Operating Model

- Strategic: Claude Code + Sam
- Execution: VS Code AI (GPT-5.3-Codex)
- Testing: Antigraviti
- Channels:
  - `.agent/channels/handoff.md`
  - `.agent/channels/testoff.md`

## Key Paths

- KB root for `--kb`: `.agent/kb`
- Ontology: `.agent/kb/superset/ontology.json`
- Tasks: `.agent/tasks/`
- Agent config: `.agent/cfg/agents/`
- Protocol and rules: `.agent/CLAUDE.md`

## Notes

- Legacy folders `.agent/knowledge_base/` and `.agent/configs/` are retired.
- Use `.agent/kb/`, `.agent/cfg/`, `.agent/tasks/`, and `.agent/channels/` only.
