# T193 HP ProDesk Social Topology Inventory

**T-day:** T=193
**Date:** 2026-05-13
**Workstation:** HP ProDesk at Geurt's place, Windows host `DESKTOP-3FC7C3F`
**Scope:** social/topology inventory and proposal only
**Apply status:** inventory was read-only; follow-up topology-safe implementation applied on hp-laptop primary at `2026-05-13T16:13:22Z`

## Status

This report records the read-only HP ProDesk inventory and revises the identity proposal after noticing an important modeling issue: this VS Code conversation is running on a new physical workstation, under a local Windows login, and the workstation may have its own Google/Gmail account identity in settings.

That fact matters, but it should not automatically create an authority-bearing `user` node. Under the current ontology, `user` is a human principal with kernel authority semantics, not a general identity/account record. External account identity should enter first as a channel/account surface or as a knowledge item until Sam approves a stronger identity model.

This file is a projection/readback document. The source of truth remains the JSONL logs and live HTTP state.

## Implementation Follow-Up

After this inventory, Sam requested implementation. Hp-laptop primary applied `dev/scripts/ops/t193-hpprodesk-topology-materialization.program.json` through the `guido` persona.

The apply was deliberately limited to topology-safe HP ProDesk materialization:

- New shared-HG nodes: `workstation:hpprodesk`, `kernel:hpprodesk.primary`, `agent:vscode.hpprodesk.primary`, `purpose:sam.hpprodesk-workstation-bootstrap`, `session:sam.hpprodesk-setup`, and `program:sam.t193.hpprodesk-topology-materialization`.
- New wiring: `group:sam` ownership, WF03 workstation hosting, WF18 purpose-program composition, and WF19 session `opens-on`, `has-purpose`, `has-occupant`, and `pins-urn` relations.
- Runtime readback after apply: `status=ok`, `ontology_version=3.16.1`, `t_day=193`, `log_len=1184`.

The identity decision remains unchanged: no `user:geurt`, no `group:geurt`, no Gmail/auth/account channel, and no secret or raw account identifier was added.

The HP ProDesk local kernel then received its own session-layer bootstrap through `dev/scripts/ops/t193-hpprodesk-local-session-bootstrap.program.json`. That batch preserved the existing 5-line seed graph, added local `group:sam`, `agent:vscode.hpprodesk.primary`, `purpose:sam.hpprodesk-workstation-bootstrap`, `session:sam.hpprodesk-setup`, and `program:sam.t193.hpprodesk-topology-materialization`, then wired ownership and WF19 session relations. Local HP ProDesk readback after apply: `status=ok`, `ontology_version=3.16.1`, `t_day=193`, `log_len=26`; `VerifyPersona -Persona hpprodesk-vscode` passes.

## Readback

Repository state on HP ProDesk:

- `ffs0`: `main...origin/main`, `9a54dfe tools: add HP ProDesk projection routine`.
- `moos-kernel`: `master...origin/master`, `b5935e0 Document T189 calendar event projection status`.
- `moos-router`: `master...origin/master`, `18212eb Merge pull request #1 from Collider-Data-Systems/docs/round-12-readme`.

Runtime health:

- HP ProDesk local kernel `http://localhost:8000/healthz`: `status=ok`, `ontology_version=3.16.1`, `t_day=193`, `log_len=5`.
- hp-laptop kernel `http://172.29.0.38:8000/healthz`: `status=ok`, `ontology_version=3.16.1`, `t_day=193`, `log_len=1160`.
- hp-laptop router `http://172.29.0.38:9000/healthz`: `status=ok`; it sees hp-laptop local kernel as OK and Z440 `192.168.1.11` as down.

Z440 remains part of topology, but it is not required to be online for this HP ProDesk inventory.

## Local HP ProDesk HG State

The local HP ProDesk log is a 5-entry seed graph:

- `urn:moos:user:sam`
- `urn:moos:workstation:hpprodesk`
- `urn:moos:kernel:hpprodesk.primary`
- WF01 `user:sam --owns/child--> workstation:hpprodesk`
- WF03 `workstation:hpprodesk --hosts/hosted-on--> kernel:hpprodesk.primary`

That is locally real. It is not yet the shared governance HG shape.

## hp-laptop Shared HG Inventory

hp-laptop is currently the richer shared governance read surface:

- Total nodes: 427.
- Key counts: `user=1`, `group=2`, `role=1`, `workstation=2`, `kernel=2`, `agent=8`, `session=10`, `purpose=9`, `program=70`, `channel=14`, `repository=5`.
- Key users/groups/roles: `user:sam`, `group:sam`, `group:my-tiny-data-collider`, `role:superadmin`.
- Workstations/kernels present: `workstation:hp-laptop`, `ws:hp-z440`, `kernel:hp-laptop.primary`, `kernel:hp-z440.primary`.
- HP ProDesk targets are missing from shared HG: `workstation:hpprodesk`, `kernel:hpprodesk.primary`, `agent:vscode.hpprodesk.primary`, `session:sam.hpprodesk-setup`, and `purpose:sam.hpprodesk-workstation-bootstrap`.

Relation counts on hp-laptop for the requested WFs:

- WF01: 37 ownership edges, including `user:sam --owns/child--> workstation:hp-laptop`, `user:sam --owns/child--> ws:hp-z440`, and `group:sam --owns/owned-by--> kernel:hp-laptop.primary`.
- WF02: 7 governance edges, all from `user:sam` to agents or `role:superadmin`.
- WF18: 123 composition/dependency-style edges.
- WF19: 61 session governance edges: 5 `opens-on`, 4 `has-occupant`, 4 `has-purpose`, 46 `pins-urn`, and 2 `filtered-by`.
- WF21: 40 causal edges.

No shared-HG nodes were found for `group:geurt`, `group:geurt-household`, or `user:geurt`.

## Identity Model Correction

The first safe distinction is:

- `user:sam` is the current authority-bearing human principal in mo:os.
- `desktop-3fc7c3f\geurt` is an OS login observed on the physical workstation.
- A Gmail/Google identity in Windows or VS Code settings is an external account/auth surface.
- The HP ProDesk itself is a workstation substrate.
- This VS Code/Copilot conversation is S0 substrate attached to the planned `session:sam.hpprodesk-setup` occasion.

These should not collapse into one `user` node.

The current ontology defines `user` as `urn:moos:user:<name>` with only `name` and `created_at` properties. It also says a user is the human principal and superadmin of their own graph. So `user:geurt` would be a serious authority statement. It should only be minted if Sam explicitly wants Geurt to become a kernel principal.

The topology/property boundary also matters: properties should not duplicate relations. A Gmail account is not a scalar property of `user:sam` or `workstation:hpprodesk`; it is an external identity/account surface that can be owned, pinned, observed, or used as evidence.

## Revised Geurt Proposal

Options, now in better order:

1. Report-only context: keep Geurt as prose in this T193 diary report. This is still the safest default.
2. Knowledge item: add a future `knowledge_item` saying HP ProDesk is physically at Geurt's place and was observed under local OS login `desktop-3fc7c3f\geurt`. This preserves evidence without identity authority.
3. Account/channel surface: if the local Gmail/Google identity must identify the workstation/session, model it as a channel or account surface first, not as `user:geurt`.
4. `group:geurt` or `group:geurt-household`: only if Sam wants a recurring social/place container for the physical context.
5. `user:geurt`: only after explicit approval that Geurt is an authority-bearing kernel principal. This remains non-default.

Recommendation: for the next reviewed batch, keep Geurt out of authority topology. If identity evidence is needed, use a knowledge item and an auth/Gmail channel proposal.

## Gmail/Auth Surface Proposal

The workstation having its own Gmail/Google identity in settings is useful for identification, but the report should not store raw email addresses, OAuth IDs, tokens, client files, or secrets.

Two safe modeling levels:

### Level 1: current ontology, no grammar change

Use a future knowledge item and possibly an existing `channel` if the account is a mailbox/channel to be ingested:

- `urn:moos:ki:t193.hpprodesk.local-login-readback`
- `urn:moos:ki:t193.hpprodesk.google-auth-readback`
- Optional only if mail/Workspace ingestion is intended: `urn:moos:channel:google.gmail.<approved-slug>` with `kind=mail`, redacted `source_uri`, `display_name` without raw email unless Sam approves, `owner_urn=urn:moos:group:sam` or another chosen owner.

Then link only after review:

- WF01 `group:sam --owns/owned-by--> channel:google.gmail.<approved-slug>` if the account is part of Sam's operational mo:os scope.
- WF19 `session:sam.hpprodesk-setup --pins-urn-->` the auth readback knowledge item and any approved channel.
- WF12 from channel to knowledge items when actual ingestion happens.

### Level 2: proposed ontology improvement, not for immediate apply

If the system needs account identity distinct from mailbox ingestion, propose a future grammar fragment such as `grammar_fragment:t193-auth-account-channel-surface`:

- Add `channel.kind = auth-account` or add a small `account_surface` node type.
- Allow non-secret properties such as `provider`, `account_slug`, `display_name`, `status`, `created_at`, and maybe `subject_hint_kind`.
- Do not store raw Gmail addresses, OAuth subject IDs, refresh tokens, or client secrets in HG or git.
- Do not add `primary_gmail` or similar to `user`; that would hide a relation as a property.

If `user` needs a future property extension, keep it modest: `display_name` or `status` might be safe owner-scoped properties. Auth identity should still live as a channel/account node linked or pinned through topology.

## Revised HP ProDesk Batch Shape

Do not apply automatically. Prepare as a reviewed `moos-rewrite-envelope` batch after Sam chooses the identity/account shape.

Core HP ProDesk topology:

- ADD `urn:moos:workstation:hpprodesk`.
- ADD `urn:moos:kernel:hpprodesk.primary`.
- ADD `urn:moos:agent:vscode.hpprodesk.primary`.
- ADD `urn:moos:session:sam.hpprodesk-setup`.
- ADD `urn:moos:purpose:sam.hpprodesk-workstation-bootstrap`.
- Optional ADD `urn:moos:program:sam.t193.hpprodesk-topology-materialization` as the reviewed apply carrier.
- LINK WF03 `workstation:hpprodesk --hosts/hosted-on--> kernel:hpprodesk.primary`.
- LINK WF19 `session:sam.hpprodesk-setup --opens-on/occupied-by--> kernel:hpprodesk.primary`.
- LINK WF19 `session:sam.hpprodesk-setup --has-purpose/purpose-of-session--> purpose:sam.hpprodesk-workstation-bootstrap`.
- LINK WF19 `session:sam.hpprodesk-setup --has-occupant/is-occupant-of--> agent:vscode.hpprodesk.primary`.
- LINK WF19 `session:sam.hpprodesk-setup --pins-urn--> group:sam`, the workstation, the kernel, the purpose, and selected readback evidence.
- LINK WF01 `group:sam --owns/owned-by-->` the kernel, session, purpose, agent, and any approved account/channel surfaces that are part of Sam's operational mo:os scope.

Identity evidence additions, proposal-only:

- ADD `ki:t193.hpprodesk.local-login-readback` for the observed Windows login and physical location context.
- ADD `ki:t193.hpprodesk.google-auth-readback` for the observed Gmail/Google settings identity, with no secret values and no raw email unless Sam explicitly approves.
- Optional ADD `channel:google.gmail.<approved-slug>` only if this is a real mailbox/Workspace channel to be ingested.
- Optional future ADD `channel:auth-account.google.<approved-slug>` only after the auth-account grammar/model decision exists.

Geurt additions, proposal-only:

- No `user:geurt` by default.
- Consider `group:geurt-household` only if Sam wants the physical-place/social container to become graph topology.
- Prefer knowledge-item evidence first.

## Next Gate

Before applying anything, Sam should choose:

1. Is the HP ProDesk account identity just readback evidence, or should it become a durable channel/account surface?
2. Is the Gmail/Google setting a mailbox/workspace channel (`channel:google.gmail.<slug>`) or an auth-account surface that needs a small grammar/model extension?
3. Should Geurt remain report-only/knowledge-item context, or become a group/place container?
4. Which receiving kernel should get the reviewed HP ProDesk topology batch?

Until those choices are made, the safe state is: HP ProDesk is locally seeded and healthy; shared HG should treat HP ProDesk and Geurt/Gmail identity as proposal-only.