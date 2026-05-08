# CLAUDE.md

Personal portable private workspace for mo:os research and operations.
Owner: `urn:moos:user:sam` — pulled on every workstation.
Machine-specific IDE config (MCP ports) is **gitignored** — copy `.vscode/mcp.json.example` → `.vscode/mcp.json` on first checkout.

---

## Running state

**Read `kb/superset/running-state.md` first.** Current T-day, active program, kernel state, open items, key URNs.

At T=188 hp-laptop kernel is live on v3.16.1 (log_len 1080, t_day 188). Z440 4-kernel federation last confirmed at v3.15.0 (T=177). `session:sam.governance` now has durable WF19 purpose `purpose:sam.doctrine-governance-and-delegation`; the active working lane is the dry Keep/session/visual projection pipeline, not a single running HG program. Current operator report: `kb/moos-diary/t188-t187-session-pipeline-mvp-report.md`. Doctrine lives as derivations on log plus carefully chosen reports; conversations should still reify through HG chunks when they need persistence.

---

## The rule

Four rewrites only: `ADD` · `LINK` · `MUTATE` · `UNLINK`
Log is truth. State is derived. Nodes don't call things. Relations don't carry messages.

---

## Session model

A session is present when purpose × occupant × scope evaluate present from graph data.

- **Purpose** — directional intent, represented by WF19 `has-purpose` from session to purpose.
- **Occupant** — evaluated from ownership, capability, and in-scope rewrite categories; empty result means idle/no live occupant.
- **Scope** — the session's WF19 `pins-urn` outbound sub-DAG, reachable through composition and causal chains.

Kernel-bound sessions use the same machinery: purpose = host the substrate, occupant = evaluated from ownership/capability data, scope = admin/governance wiring. The kernel remains a stream fold; choices are predicate satisfaction over data, with side effects only at actuator leaves via channels.

Node role shorthand:
- **Anchor** — identity/where/why/who nodes: purpose, session, program, agent, user, group, role, capability, kernel, workstation, harness, compute, storage, transport_binding, endpoint, protocol, router, repository, channel, system_instruction.
- **Gate** — predicate-and-reaction nodes: t_hook, gate, guard, watcher, reactor, view_filter.
- **Actuator** — boundary action nodes: prg_task, external_op, twin_link.
- **Carrier** — typed data flowing as arguments: knowledge_item, claim, derivation, calendar_event, git_issue, source_feed, shard_rule, domain_tag, classification_scheme, crosswalk, grammar_fragment.

---

## Nomenclature

| Use | Never use |
|-----|-----------|
| node | object, element, vertex |
| relation | binding, edge, wire, association |
| rewrite | morphism, update, mutation |
| rewrite category WF01–WF21 | named relation, UML association |
| property | field, payload, attribute |
| operad | schema, grammar |
| interaction node | transition, event, message |
| `_urn` / `_urns` | `_ref` / `_refs` |

Relations are truth. Properties never duplicate topology.

---

## Ontology

`kb/superset/ontology.json` — **v3.16.1**, 53 node types, 21 WFs (WF01–WF21).
Do not edit without reading running-state.md first.

Notable bumps since v3.9 baseline (T=168):
- v3.10.0 (T=168) — WF19 `has-occupant`/`is-occupant-of` for §M19 session-occupancy.
- v3.11.0 (T=169) — `t_hook.firing_state` lifecycle enum.
- v3.12.0 (T=169) — first WF20 merge: D19.2/D19.3/D19.4/D20.1/D20.2 (session view_prefs, pins-urn, filtered-by, mounts-tool, agent.invocation_protocol).
- v3.13.0 (T=173) — WF02 delegates-to, `group` node type, channel.kind expansion (+calendar, +task-list, +cloud-storage, +vcs, +project-board), WF01 owns/owned-by.
- v3.14.0 (T=175) — `derivation` S2 node type for reifying session-internal inference.
- v3.15.0 (T=176) — `clock` node type, WF21 causes/caused-by (acyclic), substrate properties on channel/knowledge_item, channel.kind +video/+audio.
- v3.16.0 (T=185) — D22.1 `has-purpose`/`purpose-of-session` WF19 port-pair. Session repurposing via MUTATE.
- v3.16.1 (T=187) — authority-scope patch for kernel-authored lifecycle closeout and current projection-lane validation.

---

## Post-§M11 actor discipline (T=171 PR #30, T=171 PR #31)

Every envelope has `actor`. The kernel gate-checks it against §M11 (session liveness) + §M12 (admin capability).

- **Agent actor** (`urn:moos:agent:<short>`) — default. Works via reverse-lookup when the agent occupies exactly one session (inferred path). Sets `env.session_urn` explicitly when the agent drives multiple sessions.
- **Kernel actor** (`urn:moos:kernel:<ws>.<name>`) — bypasses §M11 allowlist AND §M12 admin-scope. Required for: ontology-governed type ADDs (`system_instruction`, `gate`, `twin_link`, `transport_binding`, `kernel`), kernel-authority-scope MUTATEs on non-kernel nodes, WF19 `opens-on` LINKs, sweep WF13 emissions.
- **User actor** (`urn:moos:user:sam`) — fails §M11 (sam is owner, not occupant). Only valid inside `SeedIfAbsent` path (liveness bypassed structurally).

`env.actor` = who emits (ephemeral, per envelope). `owner_urn` property = who owns (sticky provenance). Don't conflate.

Full envelope shape + gotchas: `moos-rewrite-envelope` skill.

---

## Current sessions + personae (T=188)

Active on hp-laptop now: `sam.governance`, `sam.laptop-cowork-workspace`, `sam.laptop-moos-diary`, `hp-laptop.primary`. `sam.governance` is the current Guido lane for doctrine, projection gating, and round closeout. Z440 rows below are topology memory until that federation is live again.

| Persona | Agent | Session | Host kernel | Notes |
|---|---|---|---|---|
| Guido van Rossum | `claude-code.hp-laptop` | `sam.governance` | `hp-laptop.primary` | doctrine + audit |
| Stephen Wolfram | `claude-code.hp-z440` | `sam.kernel-proper` | `hp-z440.primary` | kernel implementation |
| Moos the Dachshund | `antigravity.hp-z440` | `sam.moos-diary` | `hp-z440.primary` | multimodal diary curation |
| Andrej Karpathy | `vscode.hp-z440.lola` | `sam.karpathy-seat` | `hp-z440.lola` | HDC/VSA categorical bridge |
| Peter Steinberger | `vscode.hp-z440.menno` | `sam.steinberger-seat` | `hp-z440.menno` | tooling + DX ergonomics |
| (Cowork substrate) | `claude-cowork.hp-{z440,hp-laptop}` | `sam.{z440,laptop}-cowork-workspace` | kernel double-duty | Google Workspace channels pinned; has-occupant fires when Desktop runs |

Full topology: `derivation:t172.wolframs-court` + `derivation:t172.cowork-as-occupant` (both on log).

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
- Google Keep — `channel:google.keep.sam` + `ki:gdrive.t187-keep-session-occasion-lingo` (T187/T188 session-pipeline G-ingest)
- Git (Collider-Data-Systems) / Social / Network — queued

---

## Current projection lane (T188)

The local dry pipeline is the first screen for T189 projection work:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File dev\scripts\projections\run-session-pipeline.ps1
```

Outputs land under `tmp/projections/session_pipeline/`:

- `session_context/current_session.{json,md}` — IDE/agent/harness session context pack.
- `graph_artifacts/session_occasion_engineering.{json,md}` — selected HG frame with root coverage and engineering findings.
- `visual/session_occasion_frame.{dot,svg}` — static Graphviz review artifact.
- `mvp/session_pipeline_gate.{json,md}` — pass/warn/fail gate report.
- `index.html` — local human-facing control surface.

Latest gate after WF19 purpose anchor: `warn`, 11 pass, 2 warn, 0 fail. Remaining T189 warnings: disconnected forced visual roots and no interactive Cytoscape.js-style typed-HG inspector. Keep Graphviz for deterministic review; prototype Cytoscape.js for interactive lensing.

---

## Domain knowledge

Invoke `moos-rewrite-envelope` for HG envelope authoring, `moos-state-readback` for session/round opens, `moos-round-close` for end-of-round cleanup.
Invoke `moos-categorical-research` (Karpathy seat) for categorical/HDC bridge work, `moos-cross-persona-audit` (Guido) for round-close governance.

Archive material (`dev/reference/research-archive/`) is retrievable on demand: sheaves, operadic-layer lingo, pre-WF20 superset doctrine, T=168 ontology audit, session-kernel-bound FAQ, session-seating snapshots, past-round conversation summaries.

---

## Workspace

```
kb/
  superset/              ontology.json (S1) + running-state.md (hydration entrypoint)
  research/              live doctrine (kernel spec, session notes, moos-diary)
dev/
  scripts/               ops + utility scripts
  claude-skills/         12 skill directories (synced to ~/.claude/skills/)
  reference/
    research-archive/    past-round scratch, shipped plans, substrate lingo, seating snapshots
secrets/                 GITIGNORED (local-first)
.github/
  instructions/          IDE-specific auto-injected context
  prompts/               stored prompts (all IDEs)
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
