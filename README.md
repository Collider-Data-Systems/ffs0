# ffs0-factory-super

Private workspace for the [mo:os](https://github.com/MSD21091969/moos) categorical graph kernel.

## What This Repo Contains

Knowledge base, agent configuration, channels, and operational tooling.
The public kernel code lives at [MSD21091969/moos](https://github.com/MSD21091969/moos).

## Quick Start

```bash
# Clone both repos side by side
git clone https://github.com/MSD21091969/ffs0-factory-super.git
git clone https://github.com/MSD21091969/moos.git

# Boot kernel with KB hydration
cd moos/platform/kernel
go run ./cmd/moos --kb "../../ffs0-factory-super/.agent/kb" --hydrate

# Verify
curl http://localhost:8000/healthz
```

Kernel serves HTTP on `:8000` and MCP (SSE) on `:8080`.

## Layout

```
.agent/
  kb/                  Knowledge base (ontology, instances, design docs)
    superset/          Ontology (28 types) — single source of truth
    instances/         Hydration seeds (18 JSON files)
    design/            Architecture documents
    reference/         Papers, YouTube, external sources
  channels/            Agent communication logs (S4 projections)
  cfg/                 Agent configs, session state, secrets policy
  tasks/               Task files (legacy — PRG now in graph)
  scripts/             PowerShell utilities
  workflows/           Operational workflows
  skills/              Claude Code skills (47 dirs)
  secrets/             API keys (gitignored)
moos/                  -> ../moos (public kernel repo)
.mcp.json              Kernel MCP server config
```

## The Kernel Graph Is Truth

PRG tasks, sessions, calendar events, and Keep notes are graph nodes.
Query `GET /state` for ground truth. Files on disk are seeds (input) or projections (output).
