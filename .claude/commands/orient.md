---
description: Hydrate the current mo:os seat — produce a fresh orientation for a seat (or auto-detect from host/cwd).
argument-hint: [seat]
---

Invoke the `moos-seat-hydration` skill for seat `$ARGUMENTS`. If `$ARGUMENTS` is empty, auto-detect the seat from this host and cwd (match against `.claude/rules/seat-context.md` + `dev/config/session-affordance-map.json`).

Produce the orientation: the seat's agent/workspace/engine/MCP affordances, which skills to mount, the emit-target engine + port, and the prompt-delta for this seat. Read live state first (`kb/superset/running-state.md`, then `/healthz`) — readback wins over any authored table.

Do not re-paste any `tmp/**handoff**.md` — that handoff-file flow is retired; this command replaces it.

Keep the output tight: seat header, affordances, then a one-line "you are oriented" close.
