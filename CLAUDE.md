# CLAUDE.md

Personal portable private workspace for mo:os research and operations.
Owner: `urn:moos:user:sam` — pulled on every workstation.
Machine-specific IDE config (MCP ports) is **gitignored** — copy `.vscode/mcp.json.example` → `.vscode/mcp.json` on first checkout.

---

## Running state

**Read `kb/superset/running-state.md` first.** Current T-day, active program, kernel state, open items, key URNs.

At T=178 both kernels are live (Z440 4-kernel federation + hp-laptop primary), v3.15.0 ontology, 9 sessions occupied. `kb/research/planning.md` carries the live state summary; doctrine lives as derivations on log.

---

## The rule

Four rewrites only: `ADD` · `LINK` · `MUTATE` · `UNLINK`
Log is truth. State is derived. Nodes don't call things. Relations don't carry messages.

---

## Nomenclature

| Use | Never use |
|-----|-----------|
| node | object, element, vertex |
| relation | binding, edge, wire, association |
| rewrite | morphism, update, mutation |
| rewrite category WF01–WF20 | named relation, UML association |
| property | field, payload, attribute |
| operad | schema, grammar |
| interaction node | transition, event, message |
| `_urn` / `_urns` | `_ref` / `_refs` |

Relations are truth. Properties never duplicate topology.

---

## Ontology

`kb/superset/ontology.json` — **v3.12.0**, 52 node types, 20 WFs (WF01–WF20).
Do not edit without reading running-state.md first.

Notable recent bumps:
- v3.10.0 (T=168 round 9) — WF19 extended with `has-occupant`/`is-occupant-of` port pair for §M19 session-occupancy; D19.1 grammar_fragment merged.
- v3.11.0 (T=169 round 9.5) — `t_hook.firing_state` enum `{pending, proposed, approved, rejected, applied, closed}`.
- v3.12.0 (T=169 round 10) — first WF20 ceremony: D19.3 `pins-urn` / D19.4 `filtered-by` / D20.1 `mounts-tool` port pairs + D20.2 `agent.invocation_protocol` enum + D19.2 `session.view_prefs` merged.

v3.13 candidates (proposed, not yet promoted):
- `channel.kind` additions: `calendar`, `task-list`, `cloud-storage`
- `v313-6-wf02-delegates-to` — capability-delegation port pair for Wolfram's court
- `running_host` supertype with subtypes `kernel` and `platform` (post-D22.5) — for Cowork platform-host doctrine

---

## Post-§M11 actor discipline (T=171 PR #30, T=171 PR #31)

Every envelope has `actor`. The kernel gate-checks it against §M11 (session liveness) + §M12 (admin capability).

- **Agent actor** (`urn:moos:agent:<short>`) — default. Works via reverse-lookup when the agent occupies exactly one session (inferred path). Sets `env.session_urn` explicitly when the agent drives multiple sessions.
- **Kernel actor** (`urn:moos:kernel:<ws>.<name>`) — bypasses §M11 allowlist AND §M12 admin-scope. Required for: ontology-governed type ADDs (`system_instruction`, `gate`, `twin_link`, `transport_binding`, `kernel`), kernel-authority-scope MUTATEs on non-kernel nodes, WF19 `opens-on` LINKs, sweep WF13 emissions.
- **User actor** (`urn:moos:user:sam`) — fails §M11 (sam is owner, not occupant). Only valid inside `SeedIfAbsent` path (liveness bypassed structurally).

`env.actor` = who emits (ephemeral, per envelope). `owner_urn` property = who owns (sticky provenance). Don't conflate.

Full envelope shape + gotchas: `moos-rewrite-envelope` skill.

---

## Current sessions + personae (T=173)

| Persona | Agent | Session | Host kernel | Notes |
|---|---|---|---|---|
| Guido van Rossum | `claude-code.hp-laptop` | `sam.governance` | `hp-laptop.primary` | doctrine + audit |
| Stephen Wolfram | `claude-code.hp-z440` | `sam.kernel-proper` | `hp-z440.primary` | kernel implementation (currently driving this conversation) |
| Moos the Dachshund | `antigravity.hp-z440` | `sam.moos-diary` | `hp-z440.primary` | multimodal diary curation |
| Andrej Karpathy | (pending VSCode attach) | `sam.karpathy-seat` | `hp-z440.lola` | HDC/VSA categorical bridge |
| Peter Steinberger | (pending VSCode attach) | `sam.steinberger-seat` | `hp-z440.menno` | tooling + DX ergonomics |
| (Cowork substrate) | `claude-cowork.hp-{z440,hp-laptop}` | `sam.{z440,laptop}-cowork-workspace` | kernel double-duty | Google Workspace channels pinned; has-occupant fires when Desktop runs |

Full topology: `derivation:t172.wolframs-court` + `derivation:t172.cowork-as-occupant` (both on log; `kb/research/planning.md` has the live state summary).

---

## Conversations are S0 (T=173 pivot)

IDE conversations are **S0 substrate** — the raw rewriting layer that emits work. They are NOT data, code, or doctrine. The reification path forward:

```
S0 conversation
  → chunker-skill (moos-workspace-ingest, queued)
  → knowledge_item chunks
  → pinned to a session (G ingest direction, adjunction F⊣G)
  → programs / tasks delegate to tools / sub-agents / other personae
  → F projects back out to calendar / git / social / network surfaces
```

New doctrine `.md` files only when establishing a new invariant. Past-round scratch, shipped implementation plans, instantiation snapshots, and substrate-lingo notes live in `dev/reference/research-archive/` — retrievable by path, provenance intact.

Current adjunctions inventory (channel nodes live, skill queued):
- Google Gmail / Calendar / Drive / Tasks — `channel:google.*.sam`
- Git (Collider-Data-Systems) / Social / Network — queued

---

## Domain knowledge

Invoke the `moos-domain-expert` skill for categorical/mathematical reasoning.
Invoke `moos-rewrite-envelope` for HG envelope authoring, `moos-state-readback` for session/round opens, `moos-round-close` for end-of-round cleanup.

Archive material (`dev/reference/research-archive/`) is retrievable on demand: sheaves, operadic-layer lingo, pre-WF20 superset doctrine, T=168 ontology audit, session-kernel-bound FAQ, session-seating snapshots, past-round conversation summaries.

---

## Workspace

```
kb/
  superset/          ontology.json (S1) + running-state.md (hydration entrypoint)
  research/
    kernel/          t187-kernel-proper.md (M1-M20 spec)
    session/         3 live doctrine notes (generalization, cowork-as-occupant, wolframs-court)
    moos-diary/      active multimodal ingest zone
dev/
  scripts/           ops + utility scripts
  reference/
    research-archive/  retrievable: past-round scratch, shipped plans, substrate lingo, Apr 5 Workspace snapshot, seating snapshots
secrets/             GITIGNORED (local-first)
.github/
  instructions/      IDE-specific auto-injected context
  prompts/           stored prompts (all IDEs)
```

---

## Runtime repos (siblings)

- `moos-kernel/` — Go kernel (ontology-aware; §M11 + §M12 gates live)
- `moos-router/` — federation router (WF16)
- `moos-config/` — **LEGACY**, do not use

All three at `github.com/Collider-Data-Systems/*` since T=172.

---

## Safety

- Never commit `secrets/` values or API keys.
- Never commit `.vscode/mcp.json` (machine-specific).
- Keep destructive actions explicit and intentional.

---

## Instruction routing

- Broad defaults: this file
- Design work: `.github/instructions/design-research.instructions.md`
- Current plan (if any): `~/.claude/plans/<slug>.md` — this Claude-Code IDE's plan-mode outputs
