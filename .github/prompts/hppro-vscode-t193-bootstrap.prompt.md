---
mode: agent
description: "Use when: bootstrapping VS Code/Copilot on HP Pro as the T193 third mo:os workstation."
---

# T193 HP Pro VS Code Bootstrap

You are VS Code/Copilot running on the HP Pro. Your job is to bring this workstation up to speed as the third mo:os workstation without pretending the offline Z440 is reachable.

Treat this IDE conversation as S0 substrate. The durable object we are trying to establish is a new HP Pro session occasion: host, kernel, agent, setup session, purpose, scope, and router peer status.

## Current Picture

- `hp-laptop` is reachable now and is the current control/governance machine.
- `hp-z440` is part of the three-workstation topology but is physically elsewhere and currently offline/unreachable.
- `hppro` is the new reachable machine. It is not yet in HG as a workstation/kernel/session.
- Do not model HP Pro as a Z440 replacement. It is a third workstation.

Candidate HP Pro identities, pending real hostname/IP readback:

- `urn:moos:workstation:hppro`
- `urn:moos:kernel:hppro.primary`
- `urn:moos:session:sam.hppro-setup`
- `urn:moos:purpose:sam.hppro-workstation-bootstrap`
- `urn:moos:agent:vscode.hppro.primary`

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
2. If the repos do not exist yet, clone them under a stable local parent such as `$env:USERPROFILE\HPlaptop` unless Sam chooses a different path:
   ```powershell
   New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\HPlaptop"
   git clone https://github.com/Collider-Data-Systems/ffs0.git "$env:USERPROFILE\HPlaptop\ffs0"
   git clone https://github.com/Collider-Data-Systems/moos-kernel.git "$env:USERPROFILE\HPlaptop\moos-kernel"
   git clone https://github.com/Collider-Data-Systems/moos-router.git "$env:USERPROFILE\HPlaptop\moos-router"
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
     --reachable-hosts hp-laptop,hppro `
     --offline-hosts hp-z440 `
     --planned-hosts hppro `
     --t-day 193
   ```
   If Julia is not installed on HP Pro, skip regeneration and continue with manual readback; do not install Julia unless Sam approves.

## Git And Safety

Use explicit repo paths. Do not rely on terminal current directory.

```powershell
git -C "$env:USERPROFILE\HPlaptop\ffs0" status --short --branch
git -C "$env:USERPROFILE\HPlaptop\moos-kernel" status --short --branch
git -C "$env:USERPROFILE\HPlaptop\moos-router" status --short --branch
```

Branch before edits on HP Pro:

```powershell
git -C "$env:USERPROFILE\HPlaptop\ffs0" switch -c hppro/t193-bootstrap
```

If the branch already exists or the repo has local WIP, preserve it. Never reset or force checkout. Never commit secrets, `.vscode/mcp.json`, generated binaries, or ignored `tmp/` outputs.

## Bring-Up Target

The first technical goal is one HP Pro primary kernel only. Do not add HP Pro menno/lola/moos twin kernels yet.

1. Build `moos-kernel` from the local repo:
   ```powershell
   go version
   git -C "$env:USERPROFILE\HPlaptop\moos-kernel" status --short --branch
   Set-Location "$env:USERPROFILE\HPlaptop\moos-kernel"
   go test ./...
   go build -o moos-kernel.exe ./cmd/moos
   ```
2. Start HP Pro primary against the shared ontology and a persistent HP Pro log. Use the real paths on this machine:
   ```powershell
   .\moos-kernel.exe `
     --ontology "$env:USERPROFILE\HPlaptop\ffs0\kb\superset\ontology.json" `
     --log "$env:USERPROFILE\HPlaptop\moos-kernel\moos.jsonl" `
     --listen :8000 `
     --mcp-addr :8080 `
     --seed
   ```
3. Verify local health:
   ```powershell
   Invoke-RestMethod http://localhost:8000/healthz | ConvertTo-Json -Depth 8
   ```
   Expected target: `status=ok`, `ontology_version=3.16.1`, current `t_day`, and stable `log_len` after restart.
4. Do not apply HG rewrites yet. First report the readback to Sam: hostname, IPv4, repo paths, kernel health, and whether tests/build passed.

## Connecting To hp-laptop

After HP Pro local `/healthz` is green, check whether the hp-laptop is reachable on the same LAN. Do not assume the old home IP from topology; discover or ask Sam for the current hp-laptop IPv4.

```powershell
Test-NetConnection <hp-laptop-ip> -Port 8000
Test-NetConnection <hp-laptop-ip> -Port 9000
Invoke-RestMethod http://<hp-laptop-ip>:8000/healthz | ConvertTo-Json -Depth 8
Invoke-RestMethod http://<hp-laptop-ip>:9000/healthz | ConvertTo-Json -Depth 8
```

Only after both machines are reachable should you propose edits to `dev/config/moos-federation.topology.json` for HP Pro router peering.

## HG Batch Shape For Later Review

Do not apply this automatically. Once hostname/IP and local health are known, prepare a reviewed batch with these intended facts:

- ADD workstation `urn:moos:workstation:hppro` with hostname/OS/arch.
- ADD kernel `urn:moos:kernel:hppro.primary`.
- LINK workstation hosts kernel via WF03.
- ADD purpose `urn:moos:purpose:sam.hppro-workstation-bootstrap`.
- ADD session `urn:moos:session:sam.hppro-setup`.
- ADD or confirm agent `urn:moos:agent:vscode.hppro.primary`.
- LINK session opens-on kernel via WF19.
- LINK session has-purpose purpose via WF19.
- LINK session has-occupant agent via WF19.
- LINK `group:sam` owns the workstation, kernel, purpose, and setup session via WF01 where the operad permits it.

Use the `moos-rewrite-envelope` skill before authoring the final payload. Kernel-authority actors are required for ontology-governed or kernel-authority operations.

## What To Report Back

Report back in this shape:

```text
HP Pro hostname: <name>
HP Pro IPv4: <ip>
Repos: <paths and branch status>
Kernel build/test: <pass/fail>
Local /healthz: <status, ontology_version, t_day, log_len>
hp-laptop reachability: <8000/9000 result>
Z440: intentionally offline/unreachable for this step
Recommended next apply/config step: <one sentence>
```

Keep this session narrow: bootstrap HP Pro, prove one primary kernel, then ask Sam before topology edits or HG applies.