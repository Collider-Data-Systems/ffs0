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

T=164 `sam.t164-room-tying` closed at T=167: status → completed.
Succession recorded: `t164 --WF18 scheduled-after--> t187`.
T=167 session wired into HG: `urn:moos:session:sam.claude-code-hp-laptop.t167` (WF19, role=occupier).

---

## Kernel — hp-laptop

| | |
|--|--|
| URN | `urn:moos:kernel:hp-laptop.primary` |
| Endpoint | `http://localhost:8000` |
| Log entries | 346 |
| Nodes | 109 |
| Relations | 184 |
| Ontology | v3.8 — 42 types, 19 WFs |

## Z440 (federation partner)

Not present at T=166. Tasks parked. Reconnect when back on-site.

---

## Ontology delta

**v3.8 (T=167):** Added `system_instruction` (S4, M7 context overlay), `transport_binding` (S2, M10 QUIC binding).
`session` type extended: `local_t`, `context_urn`, `role` properties. WF19 mutate_scope includes `local_t`, `context_urn`.
42 node types total.

**v3.7 (T=164):** Added `channel` (S2, kinds: filesystem / messaging / board / drive / mail), `purpose` (S2), WF19 (session governance).
Source of truth: `kb/superset/ontology.json`

---

## T=187 program tasks (sub-programs, WF18 composes)

All ten are `program` nodes with URN `urn:moos:program:sam.t187.<suffix>`, status=draft, owned by `urn:moos:user:sam`. Dependencies are `depends-on` LINKs between siblings.

| Suffix | Title | Depends on | §M |
|--------|-------|------------|----|
| `session-chrono-t` | Session.local_t as first-class carrier | — | M1 |
| `t-hooks-first-class` | Node.t_hooks as explicit port substructure | session-chrono-t | M6 |
| `gates` | gate type + fail-closed pathway | t-hooks-first-class | M8 |
| `system-instruction` | system_instruction S4 type + session.context_urn | — | M7 |
| `fold-endpoint` | Expose fold as HTTP observable + SSE over HTTP/3 | **http3-quic** | M3, M10 |
| `twin-kernel` | twin_link + adjoint sync protocol over QUIC | gates, **http3-quic** | M9, M10 |
| `strata-enforcement` | Compile-time strata filtration | — | M5 |
| `answer-walk-Q1-Q4` | Answer walk Q1..Q4 | — | — |
| `categorical-contract` | Proof obligations for CI-1..CI-5 + categorical claims | all others | M1..M10 |
| `twin-deploy-mtdc` | Deploy twin at my-tiny-data-collider.nl | twin-kernel | M9, M10 |
| **`http3-quic`** | **HTTP/3 QUIC transport binding — ServeQUIC + Alt-Svc + quic-go** | **—** | **M10** |

Opening envelope batch: `dev/scripts/open-t187.py` (35 envelopes, log_seq 300..334).
M10 addition: 4 envelopes (log_seq 335..338).

---

## T=167 implementation sprint (completed this session)

Five sub-programs implemented and committed (`9fa37aa` on `agent/z440-claude/hdc-engine`):

| Sub-program | Status | Key files |
|-------------|--------|-----------|
| `http3-quic` | **done** | `transport/quic.go`, `go.mod` (quic-go v0.59.0), `cmd/moos/main.go` |
| `strata-enforcement` | **done** | `operad/validate.go` ValidateStrataLink, `kernel/runtime.go` LINK gate |
| `fold-endpoint` | **done** | `transport/server.go` GET /fold + GET /fold/stream SSE |
| `session-chrono-t` | **done** | `kernel/runtime.go` bumpSessionLocalT, WF19 internal MUTATE |
| `system-instruction` | **done** | ontology v3.8 (S4 type, no new code) |

Session `urn:moos:session:sam.claude-code-hp-laptop.t167` wired into HG (WF19 occupier).
`local_t` auto-incrementing from this session forward.

## Open items — T=187 walk

Remaining sub-programs (in dependency order):

| Sub-program | Depends on | §M |
|-------------|------------|----|
| `t-hooks-first-class` | session-chrono-t ✅ | M6 |
| `gates` | t-hooks-first-class | M8 |
| `twin-kernel` | gates + http3-quic ✅ | M9 |
| `twin-deploy-mtdc` | twin-kernel | M9 |
| `answer-walk-Q1-Q4` | — | — |
| `categorical-contract` | all others | M1..M10 |

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
urn:moos:session:sam.claude-code-hp-laptop.t167  (active, role=occupier)
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
