# mo:os — running state

> Hydration entrypoint. Read this first in any new conversation.
> Updated: T=167 (April 17, 2026)

---

## Active program

| | |
|--|--|
| Program | `urn:moos:program:sam.t187-kernel-proper` |
| Title | T=187: kernel proper — session-as-actor, twin kernels, gates |
| Current T-day | T=167 (April 17, 2026) |
| Status | draft (planning phase) |
| Canonical spec | `kb/research/20260417-t187-kernel-proper.md` |

T=164 `sam.t164-room-tying` closed this session: status → completed, completed_t=167.
Succession recorded: `t164 --WF18 scheduled-after--> t187`.

---

## Kernel — hp-laptop

| | |
|--|--|
| URN | `urn:moos:kernel:hp-laptop.primary` |
| Endpoint | `http://localhost:8000` |
| Log entries | 334 |
| Nodes | 107 |
| Relations | 179 |
| Ontology | v3.7 — 40 types, 19 WFs |

## Z440 (federation partner)

Not present at T=166. Tasks parked. Reconnect when back on-site.

---

## Ontology delta T=164

Added: `channel` (S2, kinds: filesystem / messaging / board / drive / mail), `purpose` (S2), WF19 (session governance, local-only, authority=kernel).
Source of truth: `kb/superset/ontology.json`

T=187 will bump to v3.8 when new types land (see below).

---

## T=187 program tasks (sub-programs, WF18 composes)

All ten are `program` nodes with URN `urn:moos:program:sam.t187.<suffix>`, status=draft, owned by `urn:moos:user:sam`. Dependencies are `depends-on` LINKs between siblings.

| Suffix | Title | Depends on | §M |
|--------|-------|------------|----|
| `session-chrono-t` | Session.local_t as first-class carrier | — | M1 |
| `t-hooks-first-class` | Node.t_hooks as explicit port substructure | session-chrono-t | M6 |
| `gates` | gate type + fail-closed pathway | t-hooks-first-class | M8 |
| `system-instruction` | system_instruction S4 type + session.context_urn | — | M7 |
| `fold-endpoint` | Expose fold as HTTP observable `GET /fold?to=<t>` | — | M3 |
| `twin-kernel` | twin_link + adjoint sync protocol | gates | M9 |
| `strata-enforcement` | Compile-time strata filtration | — | M5 |
| `answer-walk-Q1-Q4` | Answer walk Q1..Q4 | — | — |
| `categorical-contract` | Proof obligations for CI-1..CI-5 + categorical claims | all 7 others | M1..M9 |
| `twin-deploy-mtdc` | Deploy twin at my-tiny-data-collider.nl | twin-kernel | M9 |

Opening envelope batch: `dev/scripts/open-t187.py` (35 envelopes, applied at log_seq 300..334).

---

## Open items — T=187 walk

None yet — work picks up incrementally per sub-program. Start with any of: `fold-endpoint`, `system-instruction`, `strata-enforcement`, `answer-walk-Q1-Q4`, or `session-chrono-t`. These have no predecessors.

---

## Key URNs

```
urn:moos:user:sam
urn:moos:kernel:hp-laptop.primary
urn:moos:program:sam.t187-kernel-proper
urn:moos:program:sam.t164-room-tying  (completed)
urn:moos:purpose:sam.t164-tie-the-room-together
urn:moos:agent:claude-code.hp-laptop
urn:moos:agent:claude-code.hp-z440
urn:moos:session:sam.claude-code-hp-laptop.t164
```

---

## Architecture

```
hp-laptop:  kernel :8000 | MCP :8080
            CF tunnel: kernel.my-tiny-data-collider.nl (SSE) | api.my-tiny-data-collider.nl (REST)
Z440:       kernel :8000–:8003 | router :9000 (federation, WF16)
```

Agents per workstation: `claude-code` · `vscode-codex` · `antigravity`
Repos: `moos-kernel` (Go, public) · `moos-router` · `ffs0` (this workspace, private)

### moos-router (feat/type-map-routing — merged PR #2)
Type routing via `--type-map type_id=url` checked before URN-prefix shard rules.
Companion: `dev/scripts/generate_type_map.py` emits flags from ontology.json strata.

---

## Codex (archived)

`dev/reference/research-archive/20260408-foundation-t158.md` — foundations, nomenclature,
node types, two-presheaf model, functorial semantics, federation architecture.
Active type system: `kb/superset/ontology.json` supersedes for formal types.
