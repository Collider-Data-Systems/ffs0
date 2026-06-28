# mo:os nomenclature — the crisp reference

> One page. Replaces the user/agent/ide/keep-note/"channel"/engine/workspace fog.
> **4.0 alias-first.** First mention dual-names (`engine (kernel)`, `workspace (session)`); thereafter the 4.0 term. Runtime **type-id/URN stay `kernel`/`session`** until the gated 4.0.x rewrite — the 4.0 names are doc-intent aliases, not URN changes.
> Truth check: HG folded state + live `/healthz` outrank this doc. Authoritative vocab = `kb/superset/ontology.json` `nomenclature_rules`. Seat table = `AGENTS.md`.

## The spine (read this first)
```
user / group  —delegates→  agent  —occupies→  WORKSPACE (session)  —opens-on→  ENGINE (kernel)  —hosted-on→  workstation
```
A **user** (or **group**) *delegates* an **agent**; the agent *occupies* a **workspace**; the workspace *opens-on* an **engine**; the engine is *hosted-on* a **workstation**. A workspace also *has-purpose* a **purpose** (its why). **persona** is `Φ(purpose)` — a derived overlay an agent may *present-as*, never an authority principal. **channel** is the ingress side: a node (of some `kind`) that *provides-kb* into the engine. IDE panes / windows / tabs / widgets are **surfaces** (D7) — observed S0 substrate where projections land, never truth.

## Concepts → canonical term · runtime type-id/URN · your word · def

| Canonical (4.0) | Runtime type-id / URN | Sam's word | One-line def |
|---|---|---|---|
| **user** | `user` · `urn:moos:user:<name>` | me / Sam | The human principal. Exactly one per engine; superadmin of their own graph. |
| **group** | `group` · `urn:moos:group:<slug>` | the team / org | Collective principal (mirrors a GitHub org-team). Owns + delegates; members are `member-of`. |
| **agent** | `agent` · `urn:moos:agent:<user>.<name>` | the bot / the AI / Claude | An AI **delegate** — defined by capabilities, *not* by its IDE surface. Owned by one user; `delegate_type ∈ {ide, process, api, service}`. |
| **workspace** | `session` · `urn:moos:session:<owner>.<purpose-slug>` | the workspace / the seat / the lane | Persistent, always-on, engine-bound lane (tmux/Chrome-tab analogue). Tuple `(scope, purpose) × (host, owner, occupant)`. **NOT an IDE conversation** — conversations are ephemeral S0. |
| **engine** | `kernel` · `urn:moos:kernel:<workstation>.<name>` | the kernel / the running mo:os | A running mo:os process. `instance := fold(log)`. Sovereign — bound to one workstation, owned by one user. (`instance` = now-deprecated prior 4.0 alias; `engine` is the re-ratified term.) |
| **workstation** | `workstation` · `urn:moos:workstation:<name>` | the machine / Z440 / laptop | A physical/virtual machine that *hosts* engines. `kind ∈ {server, desktop, laptop, mobile, vm, edge}` — every kind runs an engine at some F/G capability degree (this retired the phantom `device` type). |
| **channel** | `channel` · `urn:moos:channel:<kind>.<slug>` | the inbox / the feed / "where stuff comes from" | A named ingress stream of artifacts. **One type, many `kind`s** (see below). Cooperadic: one channel emits many `knowledge_item`s. Source of ingested structure, not metadata. |
| **persona** | (none — a `derivation`) | the soul / the mascot / the character | `persona = Φ(purpose)` — a derived presentational identity carried as a `derivation`. **Never a node-type, never authority.** Wolfram/Karpathy/Moos are personas. |
| **manifold** | `manifold` · `urn:moos:manifold:<slug>` | the app / the whole project | Top-category node (D1): an application/domain topology; the colimit of branch-episodes sharing one purpose-slug. Worked example: `manifold:my-tiny-data-collider`. |
| **surface** | `channel` w/ surface `kind` (D7) | the screen / window / pane / tab | The **so:om** projection layer — where F lands. Addressed via surface `channel.kind`s. **Observed-not-authored**; never durable truth until G-ingested. |

## The teaching point — channel is ONE type, the `kind` varies
A **Google Keep note**, an **IDE pane**, a **git repo**, and a **mailbox** are all `channel` nodes — they differ only by `kind`. `kind` is **immutable** (set at ADD; change = UNLINK + re-ADD). The full enum:

- **Source / ingress:** `filesystem` · `messaging` · `board` · `drive` · `mail` (mailbox) · `calendar` · `task-list` · `cloud-storage` · `vcs` (git repo) · `project-board` · `video` · `audio`
- **Infra (D5 — structural handles only, never tokens):** `domain` · `dns-zone` · `cloudflare-zone` · `cloudflare-tunnel` · `access-app` · `registrar` · `website-endpoint`
- **Surface (D7 — S0 observed-not-authored, never store private window/tab contents):** `workstation-surface` · `virtual-desktop` · `window` · `tab-group` · `browser-tab` · `harness-pane` (IDE/Claude pane) · `keep-widget` (the Keep note)

> So: "the Keep note" = `channel{kind: keep-widget}`. "this Claude pane" = `channel{kind: harness-pane}`. "the ffs0 repo" = `channel{kind: vcs}`. "Gmail" = `channel{kind: mail}`. Same node-type; the `kind` is the whole distinction.

## Relations spine — src → tgt · WF · one line

| Relation | WF | src → tgt | Meaning |
|---|---|---|---|
| **delegates-to** | WF02 | user/group → agent | Authority/delegation. Principal hands scoped capability to a delegate (`P(delegate) ≤ P(principal)`). |
| **owns** / owned-by | WF01 | group/user → engine·workspace·purpose·program·channel·agent | Typed topology-level ownership (lifts the sticky `owner_urn` provenance stamp into a relation). |
| **has-occupant** | WF19 | workspace → user/agent/group | Liveness/occupancy. **At-most-one**, rotatable via MUTATE of target. Zero = alive-but-idle; one = driven. |
| **opens-on** | WF19 | workspace → engine | Topology intent — which engine the workspace runs on. |
| **has-purpose** | WF19 | workspace → purpose | The workspace's *why*. At-most-one active; repurpose = MUTATE target. |
| **provides-kb** / kb-source | WF12 | channel → knowledge_item/engine/… | Ingestion (G). The channel feeds typed nodes into the engine. |
| **presents-as** | D4 (DEFERRED → 4.0.x) | agent → persona | Presentation only, **not** authority. No persona node yet (persona is a derivation); WF/target undefined. |
| **realizes** / realized-by | D8 (DEFERRED → 4.0.x) | surface → channel/workspace | Surface↔semantic join, observed-first. Reify only if the pipeline must write it. |

> WF01..WF21 are **rewrite_categories** (op-families), not relations. Relations are topology (the LINK result). Don't conflate.

## Your words → canonical (cheat-sheet)

| You say | Means | Caveat |
|---|---|---|
| "the kernel" | **engine** (`kernel`) | URN/type-id still `kernel`. |
| "instance" | **engine** | `instance` is the *deprecated* prior alias — use `engine`. |
| "the workspace" / "the seat" / "the lane" | **workspace** (`session`) | URN/type-id still `session`. A *seat* = workspace × occupant × engine × surface (the `AGENTS.md` table row). |
| "the bot" / "Claude" / "the AI" | **agent** | The principal. Defined by capabilities, not by its pane. |
| "the IDE" / "this pane" / "the window" | **surface** = `channel{kind: harness-pane / window / browser-tab}` | S0, observed-only. Never an authority node, never durable truth. |
| "the Keep note" | `channel{kind: keep-widget}` | A surface channel — ingest (G) before it's HG truth. |
| "the repo" / "git" | `channel{kind: vcs}` | A so:om tentacle; repo/branch/`main` are projection surfaces, not the engine. |
| "the inbox" / "Gmail" | `channel{kind: mail}` | |
| "the soul" / "the mascot" / "Wolfram/Moos" | **persona** = Φ(purpose) | Derived overlay; never authority, never a node-type. |
| "the app" / "the whole MTDC thing" | **manifold** | `manifold:my-tiny-data-collider`. |
| "the machine" / "Z440" / "laptop" | **workstation** | Hosts engines; `kind ∈ {server, desktop, laptop, mobile, …}`. |
| "channel" (vague) | a `channel` node — **always ask `kind`** | The `kind` is the whole meaning; the bare word is ambiguous. |

---
*Reference doc — not HG truth until G-ingested. Authoritative vocab = `kb/superset/ontology.json`; seat map = `AGENTS.md`. No ontology/URN change authorized here.*
authored-by: agent:claude-cowork.hp-z440 / session:sam.z440-cowork-workspace / t239-catchup
