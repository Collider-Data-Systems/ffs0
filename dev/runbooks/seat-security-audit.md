# Seat security audit — the local blast radius of an agent IDE (t306)

> **Trigger:** Google Antigravity installed additional applications on the Z440 and hp-laptop
> seats (t306). An agentic IDE is not one process — it registers MCP servers, may install a
> browser extension and a native messaging host, and may leave a service or Run-key behind.
> Each is a **new local principal** on a box whose kernel read surface is unauthenticated by design.
>
> **Capability:** `dev/scripts/ops/Test-SeatSecurity.ps1` — read-only, mutates nothing.
> Run it per seat; every remediation it prints is a boundary act and is Sam's hands.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File dev\scripts\ops\Test-SeatSecurity.ps1
# machine-readable, for G-ingest:
powershell -NoProfile -ExecutionPolicy Bypass -File dev\scripts\ops\Test-SeatSecurity.ps1 -Json > tmp\seat-security-$env:COMPUTERNAME.json
```

Run it in an **elevated** shell — checks F (firewall) and G (services) return `INFO: not readable`
otherwise. Exit code is `1` when any FAIL is present.

## What the script checks

| | check | why it matters here |
|---|---|---|
| A | Antigravity / Gemini / Codeium install roots + running processes | establishes what is actually on the box, versus what the seat table says |
| B | MCP servers registered **outside** `.vscode/mcp.json`, and their filesystem roots | the direct answer to "it opened up file access" — a `server-filesystem` or shell MCP server is a general read+write grant over every root it is handed |
| C | bind address of every moos port (8000–8003, 8080, 9000–9003) + any listener owned by an agent-vendor binary | `0.0.0.0` means LAN + tailnet, not just this box |
| D | is a bearer token actually configured on the running kernel (`--auth-token-file` / `MOOS_AUTH_TOKEN`) | without it the write path is open to every local process |
| E | live probe: unauthenticated `POST /rewrites` must return **401** | proves D rather than assuming it |
| F | inbound firewall Allow rules for agent binaries and for moos ports | installers add these silently |
| G | Run keys, scheduled tasks, and **services** under agent-vendor paths | a service runs outside the session, often as SYSTEM |
| H | `secrets/` ACL and contents (names only, never values) | |
| I | `cloudflared` process + credentials on disk | a tunnel credential is a standing internet route into the box |
| J | browser extensions and native messaging hosts | the bridge from a web page back to the filesystem |

## Two facts that are true before any audit runs

Both are **verified in `moos-kernel` source**, not inferred, and both predate Antigravity —
what Antigravity changes is the number of local principals that can use them.

1. **Kernel reads are unauthenticated and CORS-open.** `internal/transport/server.go:169` sets
   `Access-Control-Allow-Origin: *` on the read surface; `writeGate` strips it on writes only.
   Consequence: **any web page loaded in any browser on the box can `fetch('http://localhost:8000/state')`
   cross-origin and read the entire fold.** This is the shipped design (reads open for
   observability, `--auth-token-file` gates writes) — not a misconfiguration. It becomes a
   sharper exposure the moment an agentic IDE drives a browser on the same host.
   Upstream fix, if wanted, is an origin allowlist on reads in `moos-kernel` — related:
   [moos-kernel#68](https://github.com/Collider-Data-Systems/moos-kernel/issues/68).

2. **The default bind is every interface.** `cmd/moos/main.go:29-30` defaults to `:8000` /
   `:8080`, i.e. `0.0.0.0`. On a Tailscale mesh seat every peer can read the fold directly.
   Deliberate for `hp-z440.primary` (it is the federation emit target); not obviously deliberate
   for the twins `:8001–:8003` or for a laptop seat. Loopback-bind anything that is not a
   federation peer: `--listen 127.0.0.1:8000 --mcp-addr 127.0.0.1:8080`.

## The control that actually holds

An agent IDE running **as Sam** inherits Sam's rights; no ACL on `secrets/` changes that.
The effective controls are, in order:

1. **Do not grant a filesystem/shell MCP server a root above the repo** (check B). This is the
   one grant that is both explicit and revocable.
2. **Configure the kernel bearer token** so the log cannot be appended to by anything that
   merely reaches the port (checks D + E).
3. **Loopback-bind non-federation kernels** (check C).
4. **Delete dormant tunnel credentials.** t283 recorded tunnel `collider-studio` with 0 connectors
   and its credential still sitting in `C:\Users\hp\.cloudflared\` on Z440 (check I).

## Related

`dev/runbooks/cloudflare-tunnel-access.md` — the edge side (Access policies, service tokens).
This runbook is the host side; they are different perimeters and neither substitutes for the other.

---
authored-by: agent:claude-code.remote / session:none-ungoverned-remote-s0 / t306-seat-security-audit
