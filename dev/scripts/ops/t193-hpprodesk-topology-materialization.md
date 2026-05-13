# T193 HP ProDesk Topology Materialization

Status: applied to hp-laptop primary at `2026-05-13T16:13:22Z`.

Payload: `dev/scripts/ops/t193-hpprodesk-topology-materialization.program.json`

Target: `kernel:hp-laptop.primary` via the `guido` persona.

Runtime after apply: `status=ok`, `ontology_version=3.16.1`, `t_day=193`, `log_len=1184`.

## Scope

This batch implements the topology-safe slice from the HP ProDesk social-topology inventory:

- ADD `workstation:hpprodesk`.
- ADD `kernel:hpprodesk.primary`.
- ADD `agent:vscode.hpprodesk.primary`.
- ADD `purpose:sam.hpprodesk-workstation-bootstrap`.
- ADD `session:sam.hpprodesk-setup`.
- ADD `program:sam.t193.hpprodesk-topology-materialization`.
- LINK `group:sam` ownership over the workstation, kernel, agent, purpose, session, and program.
- LINK workstation hosting, purpose-program composition, session opens-on, purpose, occupant, and pins.

## Deliberate Non-Scope

- No `user:geurt`.
- No `group:geurt` or `group:geurt-household`.
- No Gmail/auth/account channel.
- No raw email address, OAuth subject, OAuth client, token, or secret material.

Those remain proposal-only until Sam chooses the identity/account model.

## Apply Command

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File dev\scripts\ops\Test-MoosFederation.ps1 -Mode PostProgram -Persona guido -PayloadPath dev\scripts\ops\t193-hpprodesk-topology-materialization.program.json
```

Do not reapply this payload unless the target node/relation absence is rechecked first.

## Expected Readback

After apply, the following resolve on hp-laptop primary:

- `urn:moos:workstation:hpprodesk`
- `urn:moos:kernel:hpprodesk.primary`
- `urn:moos:agent:vscode.hpprodesk.primary`
- `urn:moos:purpose:sam.hpprodesk-workstation-bootstrap`
- `urn:moos:session:sam.hpprodesk-setup`
- `urn:moos:program:sam.t193.hpprodesk-topology-materialization`

The session has 9 outgoing WF19 relations: `opens-on`, `has-purpose`, `has-occupant`, and 6 `pins-urn` links. `group:sam` has 6 HP ProDesk ownership relations. `workstation:hpprodesk` has one WF03 `hosts` relation to `kernel:hpprodesk.primary`.