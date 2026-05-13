---
description: "Use when: bootstrapping VS Code/Copilot on HP ProDesk as the T193 third mo:os workstation."
---

# T193 HP ProDesk VS Code Bootstrap

You are VS Code/Copilot running on the HP ProDesk. Your job is to bring this workstation up to speed as the third mo:os workstation without pretending the offline Z440 is reachable.

Treat this IDE conversation as S0 substrate. The durable object we are trying to establish is a new HP ProDesk session occasion: host, kernel, agent, setup session, purpose, scope, and router peer status.

## Current Picture

- `hp-laptop` is reachable now and is the current control/governance machine.
- `hp-z440` is part of the three-workstation topology but is physically elsewhere and currently offline/unreachable.
- `hpprodesk` is the new reachable machine. It is not yet in HG as a workstation/kernel/session.
- Do not model HP ProDesk as a Z440 replacement. It is a third workstation.

Candidate HP ProDesk identities, pending real hostname/IP readback:

- `urn:moos:workstation:hpprodesk`
- `urn:moos:kernel:hpprodesk.primary`
- `urn:moos:session:sam.hpprodesk-setup`
- `urn:moos:purpose:sam.hpprodesk-workstation-bootstrap`
- `urn:moos:agent:vscode.hpprodesk.primary`

## First Screen

1. Identify this machine and network position:
   ```powershell
   hostname
   whoami
   Get-ComputerInfo | Select-Object CsName,OsName,OsArchitecture,WindowsVersion
   Get-NetIPAddress -AddressFamily IPv4 |
     Where-Object { $_.IPAddress -notlike '169.*' -and $_.IPAddress -ne '127.0.0.1' } |
     Select-Object InterfaceAlias,IPAddress,PrefixLength
   git --version
   go version
   ```
2. If the repos do not exist yet, clone them under a stable local parent such as `$env:USERPROFILE\CDS` unless Sam chooses a different path:
   ```powershell
   New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\CDS"
   git clone https://github.com/Collider-Data-Systems/ffs0.git "$env:USERPROFILE\CDS\ffs0"
   git clone https://github.com/Collider-Data-Systems/moos-kernel.git "$env:USERPROFILE\CDS\moos-kernel"
   git clone https://github.com/Collider-Data-Systems/moos-router.git "$env:USERPROFILE\CDS\moos-router"
   ```
3. Open `ffs0/ffs0.code-workspace` if it exists. If not, open the `ffs0`, `moos-kernel`, and `moos-router` folders in one VS Code workspace.
4. Read these files before making claims:
   - `kb/superset/running-state.md`
   - `dev/scripts/README.md`
   - `.github/prompts/multi-workstation-git-flow.prompt.md`
   - `tmp/projections/t193_workstation_inventory/workstation_inventory.md` if present
5. If `tmp/projections/t193_workstation_inventory/workstation_inventory.md` is missing, regenerate it from the ffs0 root after the repos are present:
   ```powershell
   & 'C:\Users\maass\AppData\Local\Programs\Julia-1.12.6\bin\julia.exe' dev\scripts\t193_workstation_inventory.jl `
     --jsonl-log ..\moos-kernel\moos.jsonl `
     --topology dev\config\moos-federation.topology.json `
   --reachable-hosts hp-laptop,hpprodesk `
     --offline-hosts hp-z440 `
   --planned-hosts hpprodesk `
     --t-day 193
   ```
   If Julia is not installed on HP ProDesk, skip regeneration and continue with manual readback; do not install Julia unless Sam approves.

## Git And Safety

Use explicit repo paths. Do not rely on terminal current directory.

```powershell
git -C "$env:USERPROFILE\CDS\ffs0" status --short --branch
git -C "$env:USERPROFILE\CDS\moos-kernel" status --short --branch
git -C "$env:USERPROFILE\CDS\moos-router" status --short --branch
```

Check status before edits on HP ProDesk:

```powershell
git -C "$env:USERPROFILE\CDS\ffs0" status --short --branch
```

If the repo has local WIP, preserve it. Never reset or force checkout. Never commit secrets, `.vscode/mcp.json`, generated binaries, or ignored `tmp/` outputs.

## Bring-Up Target

The first technical goal is one HP ProDesk primary kernel only. Do not add HP ProDesk menno/lola/moos twin kernels yet.

1. Build `moos-kernel` from the local repo:
   ```powershell
   go version
   git -C "$env:USERPROFILE\CDS\moos-kernel" status --short --branch
   Set-Location "$env:USERPROFILE\CDS\moos-kernel"
   go test ./...
   go build -o moos-kernel.exe ./cmd/moos
   ```
2. Start HP ProDesk primary against the shared ontology and a persistent HP ProDesk log. Use the real paths on this machine:
   ```powershell
   .\moos-kernel.exe `
   --ontology "$env:USERPROFILE\CDS\ffs0\kb\superset\ontology.json" `
   --log "$env:USERPROFILE\CDS\moos-kernel\moos.jsonl" `
     --listen :8000 `
     --mcp-addr :8080 `
       --seed `
       --seed-user sam `
       --seed-ws hpprodesk
   ```
3. Verify local health:
   ```powershell
   Invoke-RestMethod http://localhost:8000/healthz | ConvertTo-Json -Depth 8
   ```
   Expected target: `status=ok`, `ontology_version=3.16.1`, current `t_day`, and stable `log_len` after restart.
4. Do not apply HG rewrites yet. First report the readback to Sam: hostname, IPv4, repo paths, kernel health, and whether tests/build passed.

## Connecting To hp-laptop

After HP ProDesk local `/healthz` is green, check whether the hp-laptop is reachable on the same LAN. Current T193 readback saw HP ProDesk at `172.29.0.32` and hp-laptop at `172.29.0.38`, but rediscover before making write claims.

```powershell
Test-NetConnection <hp-laptop-ip> -Port 8000
Test-NetConnection <hp-laptop-ip> -Port 9000
Invoke-RestMethod http://<hp-laptop-ip>:8000/healthz | ConvertTo-Json -Depth 8
Invoke-RestMethod http://<hp-laptop-ip>:9000/healthz | ConvertTo-Json -Depth 8
```

Only after both machines are reachable should you propose edits to `dev/config/moos-federation.topology.json` for HP ProDesk router peering.

## State And Projection Routine

Run the same readback discipline used on hp-laptop before claiming the workstation is wired:

```powershell
git -C "$env:USERPROFILE\CDS\ffs0" fetch origin --prune
git -C "$env:USERPROFILE\CDS\ffs0" status --short --branch
git -C "$env:USERPROFILE\CDS\moos-kernel" fetch origin --prune
git -C "$env:USERPROFILE\CDS\moos-kernel" status --short --branch
git -C "$env:USERPROFILE\CDS\moos-router" fetch origin --prune
git -C "$env:USERPROFILE\CDS\moos-router" status --short --branch
Invoke-RestMethod http://localhost:8000/healthz | ConvertTo-Json -Depth 8
Get-NetTCPConnection -State Listen -LocalPort 8000,8080,9000 -ErrorAction SilentlyContinue |
   Select-Object LocalAddress,LocalPort,OwningProcess
```

The projection pipeline is the machine-wiring view. Run it only after the local kernel is healthy. If Julia is not installed, report that projection regeneration is skipped.

Before the reviewed HG setup batch is applied, `session:sam.hpprodesk-setup` may not exist yet; in that case do not invent a session pack. Report that the projection routine is blocked on the reviewed HG batch.

After `session:sam.hpprodesk-setup` exists, regenerate the local projection pack from the ffs0 root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
   -File dev\scripts\projections\run-session-pipeline.ps1 `
   -BaseUrl http://localhost:8000 `
   -SessionUrn urn:moos:session:sam.hpprodesk-setup `
   -ActorUrn urn:moos:agent:vscode.hpprodesk.primary `
   -Focus "HP ProDesk workstation bootstrap, session wiring readback, projection pipeline, and router peer readiness"
```

Inspect and report:

- `tmp/projections/session_pipeline/session_context/current_session.md`
- `tmp/projections/session_pipeline/mvp/session_pipeline_gate.md`
- `tmp/projections/session_pipeline/index.html`

## HG Batch Shape For Later Review

Do not apply this automatically. Once hostname/IP and local health are known, prepare a reviewed batch with these intended facts:

- ADD workstation `urn:moos:workstation:hpprodesk` with hostname/OS/arch.
- ADD kernel `urn:moos:kernel:hpprodesk.primary`.
- LINK workstation hosts kernel via WF03.
- ADD purpose `urn:moos:purpose:sam.hpprodesk-workstation-bootstrap`.
- ADD session `urn:moos:session:sam.hpprodesk-setup`.
- ADD or confirm agent `urn:moos:agent:vscode.hpprodesk.primary`.
- LINK session opens-on kernel via WF19.
- LINK session has-purpose purpose via WF19.
- LINK session has-occupant agent via WF19.
- LINK `group:sam` owns the workstation, kernel, purpose, and setup session via WF01 where the operad permits it.

Use the `moos-rewrite-envelope` skill before authoring the final payload. Kernel-authority actors are required for ontology-governed or kernel-authority operations.

## What To Report Back

Report back in this shape:

```text
HP ProDesk hostname: <name>
HP ProDesk IPv4: <ip>
Repos: <paths and branch status>
Kernel build/test: <pass/fail>
Local /healthz: <status, ontology_version, t_day, log_len>
hp-laptop reachability: <8000/9000 result>
Projection routine: <ran/skipped/blocked, gate status if ran>
Z440: intentionally offline/unreachable for this step
Recommended next apply/config step: <one sentence>
```

Keep this session narrow: bootstrap HP ProDesk, prove one primary kernel, then ask Sam before topology edits or HG applies.