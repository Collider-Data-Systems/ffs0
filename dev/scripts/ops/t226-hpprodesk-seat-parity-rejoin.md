# T=226 — HP ProDesk seat-parity rejoin

> **Goal (Sam, T=226):** equivalent "seats" on all three machines — hp-laptop, Z440, HP ProDesk — so IDEs, notes, and Google Calendar work *equally* on each. hp-laptop and Z440 are already at parity. This runbook brings the **stale ProDesk seat** (last live ≈ T=198, ontology `3.16.1`, dropped from the Tailscale mesh) back to parity. Same shape as the Z440 rejoin (ffs0#54).
>
> Authored from hp-laptop, `agent:claude-code.hp-laptop` / `session:sam.governance`. Branch `hplaptop/prodesk-seat-parity`, tracked on ffs0#58.

## What "equivalent seat" means (the parity matrix)

A seat is `persona (=Φ(purpose)) × agent × workspace (session) × instance (kernel) × surface (IDE-instance, D7) × emit-MCP` — see `AGENTS.md` → **Seats**. For two seats to be *equivalent* (Sam's ask), nine machine-agnostic ingredients must match. hp-laptop and Z440 satisfy all nine today; the right-hand column is ProDesk's gap.

| # | Ingredient | Source of truth | hp-laptop / Z440 | HP ProDesk gap @ T=226 |
|---|---|---|---|---|
| 1 | Repos: `ffs0` + `moos-kernel` + `moos-router` cloned & current | `github.com/Collider-Data-Systems/*` | current | **pull to current** (`ffs0` was ≈T=198) |
| 2 | Config SOT: `AGENTS.md` + `CLAUDE.md`×2 + `.github/copilot-instructions.md` + `ANTIGRAVITY.md` | `ffs0/AGENTS.md` (PR #59/#60, T=220) | present | **absent** — lands on pull #1 |
| 3 | Skills: 13 skills synced to `~/.claude/skills/` | `dev/scripts/sync-claude-skills.ps1` | synced | **re-run sync** after pull |
| 4 | IDE surface: tracked `ffs0.code-workspace` baseline + gitignored `*.local.code-workspace` delta | `ffs0` root | present | regenerate local delta |
| 5 | Kernel: local `moos-kernel` built at ontology **3.16.2** + local `moos-router` | `moos-kernel`@`master` tip | 3.16.2 | **3.16.1 → rebuild to 3.16.2** |
| 6 | Network: Tailscale membership w/ permanent `100.x` IP | tailnet `maassenhochrath@gmail.com` | on mesh | **not visible from `lap-sam` — confirm join + IP** |
| 7 | Google Calendar: `google_calendar_writer.jl` + OAuth client/token | `dev/scripts/` + `secrets/` (gitignored) | working | drop `secrets/` creds locally (never committed) |
| 8 | Notes lanes: diary + Keep ingest + workspace-ingest skill | `kb/moos-diary/`, Keep tokens in `secrets/` | working | creds + skill present after #1–#3 |
| 9 | HG seat registered: `vscode.hpprodesk.primary` + `sam.hpprodesk-setup` + WF19 `opens-on hpprodesk.primary` | ProDesk `:8000` HG (per emit discipline) | n/a | re-verify against rebuilt 3.16.2 kernel (T=193 bootstrap programs exist) |

Ingredients 7–8 are **identical files on every machine** (calendar writer, OAuth client, Keep tokens, ingest skills) — parity here is just "the same `secrets/` present locally + repo current." The differentiators are #5 (own 3.16.2 kernel), #6 (Tailscale mesh IP), and #9 (seat registered on *its own* kernel per emit discipline).

## Decisions (Sam, T=226)
- **Kernel model: own local kernel rejoin** (full parity, like laptop/Z440) — *not* thin-client-over-Tailscale.
- **Network: Tailscale** — ProDesk is at a different physical location, so the old LAN IP `172.29.0.32` is dead. Permanent `100.x` mesh IP required.
- **Open blocker:** ProDesk is **not visible** on `tailscale status` from `lap-sam` at T=226. Confirm the tailnet join and capture the IP (step 0) before mesh activation (step 7).

## Runbook (run at the HP ProDesk)

> Paths assume the same layout as laptop/Z440: repos under `C:\Users\<user>\...\ffs0` (and sibling `moos-kernel`, `moos-router`). Adjust the drive/user prefix to ProDesk's actual checkout.

**0. Confirm Tailscale + capture IP** — `tailscale status` then `tailscale ip -4`. If not joined: `tailscale up` and authenticate to tailnet `maassenhochrath@gmail.com`. Report the `100.x.y.z` back so the topology sentinel `TS-IP-PENDING-HPPRODESK` can be replaced.

**1. Pull repos to current** (resolves the T=198 staleness + lands the config SOT):
```powershell
git -C <ffs0>        fetch --all --prune; git -C <ffs0>        checkout main;   git -C <ffs0>        pull --ff-only
git -C <moos-kernel> fetch --all --prune; git -C <moos-kernel> checkout master; git -C <moos-kernel> pull --ff-only
git -C <moos-router> fetch --all --prune; git -C <moos-router> pull --ff-only
```

**2. Sync skills** to `~/.claude/skills/`:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <ffs0>\dev\scripts\sync-claude-skills.ps1
```

**3. Drop local secrets** (never committed — copy from a parity machine or your password store): `secrets/google_calendar_oauth_client.json`, `secrets/google_calendar_token.json`, `secrets/api_keys.env`, and the Keep tokens. Templates (`*.example`) are tracked; the real files are gitignored.

**4. Rebuild the kernel to 3.16.2** (from `moos-kernel`), then run kernel `:8000` (+ MCP `:8080`) and `moos-router` `:9000`. Verify:
```powershell
curl http://localhost:8000/healthz   # expect {"status":"ok","ontology_version":"3.16.2",...}
```
Do not proceed past 3.16.1 — the seat must answer 3.16.2 to be equivalent.

**5. IDE surface** — open `ffs0.code-workspace` in VS Code; generate the local `.vscode/mcp.json` from `.vscode/mcp.json.example` (gitignored, never committed). Per-instance layout lives in a gitignored `ffs0.local.code-workspace`.

**6. Claude Desktop (Sam handles this himself at ProDesk)** — point the ProDesk Claude Desktop MCP at the local kernel `moos-hpprodesk-primary` → `http://localhost:8080/sse`, matching the `mcp_servers` block in `dev/config/moos-federation.topology.json`. The cloud `.mcp.json` (Cloudflare-Access SSE) is already repo-tracked and identical on every machine.

**7. Mesh activation (back on a parity machine, once step 0 yields the IP)** — replace the `TS-IP-PENDING-HPPRODESK` sentinel in `dev/config/moos-federation.topology.json` with the real `100.x` IP (kernel `http_tailscale`/`mcp_sse_tailscale`, the `tailscale.machines.hpprodesk` entry, and re-add the ProDesk router peer to the `hp-z440`/`hp-laptop` peer lists — currently *withheld* to avoid a dead-peer timeout regression). Restart the routers. `Test-MoosFederation.ps1 -Mode Doctor` should then resolve all three hosts.

**8. Seat registration (#9)** — re-verify `vscode.hpprodesk.primary` / `sam.hpprodesk-setup` / WF19 `opens-on hpprodesk.primary` against the rebuilt 3.16.2 kernel. The T=193 bootstrap programs are reusable:
`dev/scripts/ops/t193-hpprodesk-local-session-bootstrap.program.json` and `…-topology-materialization.program.json`. Emit to ProDesk `:8000` per emit discipline — **not** to laptop/Z440 (do not cross-emit the seat).

## What was done on the hp-laptop side this round (this branch)
- `dev/config/moos-federation.topology.json`: ProDesk kernel bumped `3.16.1 → 3.16.2`; added `http_tailscale`/`mcp_sse_tailscale` with the `TS-IP-PENDING-HPPRODESK` sentinel; `source_of_truth` note records the rejoin. **Router peer re-add deliberately withheld** until the real IP exists (re-adding the dead `172.29.0.32` peer would re-introduce the federation timeout).
- `AGENTS.md`: ProDesk seat-table row updated from "offline/non-blocking" to "seat-parity rejoin in progress T=226."
- `kb/superset/running-state.md`: T=226 rejoin entry.

## Boundaries honored
No HG rewrite, no Calendar/Keep write, no secret read/commit, no router restart, no kernel rebuild performed from hp-laptop. Steps 0, 4, 6, 8 execute at the ProDesk; step 7 is a one-line fill once the IP lands.

authored-by: agent:claude-code.hp-laptop / session:sam.governance / prodesk-seat-parity
