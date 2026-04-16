# mo:os — running state

> Hydration entrypoint. Read this first in any new conversation.
> Updated: T=166 (April 16, 2026)

---

## Active program

| | |
|--|--|
| Program | `urn:moos:program:sam.t164-room-tying` |
| Title | T=164 room-tying |
| Current T-day | T=166 (April 16, 2026) |
| Status | active |

---

## Kernel — hp-laptop

| | |
|--|--|
| URN | `urn:moos:kernel:hp-laptop.primary` |
| Endpoint | `http://localhost:8000` |
| Log entries | 298 |
| Nodes | 95 |
| Relations | 157 |
| Ontology | v3.6 — 40 types, 19 WFs |

## Z440 (federation partner)

Not present at T=166. Tasks parked. Reconnect when back on-site.

---

## Ontology delta T=164

Added: `channel` (S2, kinds: filesystem / messaging / board / drive / mail), `purpose` (S2), WF19 (session governance, local-only, authority=kernel).
Source of truth: `kb/superset/ontology.json`

---

## prg_task queue (T=164)

| Suffix | Title | Status |
|--------|-------|--------|
| `z440.cors-verify` | CORS — verify moos-viz:5173 fetch end-to-end | completed |
| `z440.seed-schemes` | Seed classification schemes + crosswalks on Z440 | completed |
| `z440.viz-verify` | moos-viz render matches kernel state | completed |
| `z440.narration-update` | Demo narration — add T=164 paragraph | completed |
| `z440.ontology-v3.6-pickup` | Pick up ontology v3.6 on Z440 | completed |
| `z440.hdc-e-crosswalk` | HDC-E crosswalk rotations — SO(d) composition | blocked |

---

## Open items — T=164 walk

**A.** ADD `program: wiring-proposer` to hp-laptop kernel (inert until watcher attached)
**B.** Write research note answering one of Q1–Q6 (`kb/research/20260414-t164-wires-come-from.md` §7)
**C.** Extend `channel` with `parent_channel_urn` optional property (folder nesting)
**D.** Add `tool_call.agent_urn` port to ontology (agents-as-tools clean wiring)

---

## Key URNs

```
urn:moos:user:sam
urn:moos:kernel:hp-laptop.primary
urn:moos:program:sam.t164-room-tying
urn:moos:purpose:sam.t164-tie-the-room-together
urn:moos:agent:claude-code.hp-laptop
urn:moos:agent:claude-code.hp-z440
urn:moos:session:sam.claude-code-hp-laptop.t164
```

---

## Architecture

```
hp-laptop:  kernel :8000 | MCP :8080
Z440:       kernel :8000–:8003 | router :9000 (federation, WF16)
```

Agents per workstation: `claude-code` · `vscode-codex` · `antigravity`
Repos: `moos-kernel` (Go, public) · `moos-router` · `ffs0` (this workspace, private)

---

## Codex (archived)

`dev/reference/research-archive/20260408-foundation-t158.md` — foundations, nomenclature,
node types, two-presheaf model, functorial semantics, federation architecture.
Active type system: `kb/superset/ontology.json` supersedes for formal types.
