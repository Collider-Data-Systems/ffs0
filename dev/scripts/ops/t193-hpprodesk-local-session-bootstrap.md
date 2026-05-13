# T193 HP ProDesk Local Session Bootstrap

Status: applied to HP ProDesk primary at `2026-05-13T16:17:53Z`.

Payload: `dev/scripts/ops/t193-hpprodesk-local-session-bootstrap.program.json`

Target: `kernel:hpprodesk.primary` at `http://172.29.0.32:8000` via the `hpprodesk-vscode` persona with `-Force`.

Runtime after apply: `status=ok`, `ontology_version=3.16.1`, `t_day=193`, `log_len=26`. `VerifyPersona -Persona hpprodesk-vscode` passes after this bootstrap.

## Why Force Is Required

`Test-MoosFederation.ps1 -Mode VerifyPersona -Persona hpprodesk-vscode` fails before this batch because the target session and occupant relation do not exist yet on HP ProDesk local primary. The force-post is therefore the bootstrap step that creates the missing session layer.

## Scope

This batch preserves the existing 5-line local seed graph and adds only the missing local session layer:

- ADD `group:sam`.
- ADD `agent:vscode.hpprodesk.primary`.
- ADD `purpose:sam.hpprodesk-workstation-bootstrap`.
- ADD `session:sam.hpprodesk-setup`.
- ADD `program:sam.t193.hpprodesk-topology-materialization`.
- LINK `group:sam` ownership over the local HP ProDesk operational topology.
- LINK purpose-program composition and session `opens-on`, `has-purpose`, `has-occupant`, and pins.

## Deliberate Non-Scope

- No `user:geurt`.
- No `group:geurt` or `group:geurt-household`.
- No Gmail/auth/account channel.
- No raw email address, OAuth subject, OAuth client, token, or secret material.

## Apply Command

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File dev\scripts\ops\Test-MoosFederation.ps1 -Mode PostProgram -Persona hpprodesk-vscode -PayloadPath dev\scripts\ops\t193-hpprodesk-local-session-bootstrap.program.json -Force
```

Do not reapply this payload unless the target node/relation absence is rechecked first.

## Readback

- Session `sam.hpprodesk-setup` has 9 outgoing relations: `opens-on`, `has-purpose`, `has-occupant`, and 6 `pins-urn` links.
- `group:sam` has 6 HP ProDesk ownership relations.
- The original 5-line local seed graph was preserved.