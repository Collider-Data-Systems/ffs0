# Cloudflare tunnel + Access — verified state and the last mile (t283)

> **STATUS: WORKING end-to-end since t283** — both hostnames return **200** to a request carrying the
> service token, and **302 → login** without one. Runbook for `kernel.my-tiny-data-collider.nl` (SSE)
> and `api.my-tiny-data-collider.nl` (REST).
> Everything in §1 is **MEASURED** from Z440 at t283. §3 is the remaining work and it is
> owner-gated (dashboard + credential creation = Sam's hands, never an agent's).

## 1 · What is true today (measured, t283)

| fact | evidence |
|---|---|
| Tunnel **`moos-hp`** (`3b748eb8-9032-4e9f-a20c-a06d494e9b58`) is **UP** | `cloudflared tunnel info moos-hp` → 1 connector, 4 edge connections (`1xams13/18/20/21`), `windows_amd64`, cloudflared **2026.3.0** |
| The connector runs on **hp-laptop**, not Z440 | connector ORIGIN IP `84.83.220.183` = this network's public egress (same NAT); Z440 has no `cloudflared` process or service, and its installed binary is 2025.8.1 ≠ the connector's 2026.3.0 |
| Both hostnames resolve **through Cloudflare** | `nslookup` → `104.21.23.193` / `172.67.212.247` (kernel), `188.114.96.0/97.0` (api) |
| Both endpoints answer **302 → Access login** | `GET /healthz` on each → `302`, `Www-Authenticate: Cloudflare-Access`, `Location: …cloudflareaccess.com/cdn-cgi/access/login/…`, JWT meta `service_token_status: false` |
| **Anonymous internet reads are gated at the edge** | the 302 above — the request never reaches the origin. *This retires the earlier "the tunnel exposes the fold publicly" concern recorded at t280; it does not retire [moos-kernel#68](https://github.com/Collider-Data-Systems/moos-kernel/issues/68), which is about per-user filtering once someone IS authenticated.* |
| The origins behind it are **healthy** | laptop kernel `:8000/healthz` → 200, laptop MCP `:8080/sse` → 200 (over Tailscale) |
| Second tunnel **`collider-studio`** (`773839eb…`) exists with **0 connectors** | `cloudflared tunnel list`; its credential sits in `C:\Users\hp\.cloudflared\` on Z440. Dormant — not serving anything |

**Conclusion: the tunnel works.** It is not broken, not misconfigured, and not open. What is missing is a
**machine identity** for it — see §3.

## 2 · The client side — already fixed (t280/t283)

`.vscode/mcp.json` (gitignored, Z440) declares two cloud servers, `moos-kernel-cloud` (sse) and
`moos-api-cloud` (http). They carried **bare `${CF_ACCESS_CLIENT_ID}` / `${CF_ACCESS_CLIENT_SECRET}`**,
which **VS Code does not resolve** — only `${input:…}` and `${env:…}` are substituted, so the Access
headers were being sent as literal text and could never authenticate. Fixed: both now read
`${input:cf-access-client-id}` / `${input:cf-access-client-secret}`, with matching `promptString`
inputs (`password: true`), so the values live in VS Code secret storage and never in the file.
The portable shape is in the tracked `.vscode/mcp.json.example`.

## 3 · The last mile — DONE (t283). Recorded here as the procedure and its gotchas

The common failure here is doing only the first step. A service token by itself changes nothing:
an Access application ignores service-token headers unless a **policy** admits them.

**[MEASURED, with a caveat]** Sending `CF-Access-Client-Id` / `CF-Access-Client-Secret` headers with
dummy values returns **302 → login**, not `401`/`403`. A configured Service-Auth policy would evaluate
the headers and reject them explicitly. *Caveat, stated as such: an unrecognised token id can also fall
through to the login redirect, so this is strong evidence rather than proof that no Service-Auth policy
exists — it is a **CONJECTURE** that the policy is absent. Either way step 2 below is required and is
the step people skip.*

1. **Create the service token.** Zero Trust dashboard → **Access → Service Auth → Service Tokens →
   Create Service Token**. Name it for the consumer (e.g. `z440-vscode-mcp`). Copy **Client ID**
   (ends `.access`) and **Client Secret** — *the secret is shown exactly once*.
2. **Admit it in the application policy.** Zero Trust → **Access → Applications** → the app covering
   `kernel.my-tiny-data-collider.nl` (and the one for `api.…`) → **Policies** → add a policy with
   **Action: Service Auth** and **Include → Service Token →** the token from step 1. Without this the
   token authenticates nothing.
3. **Hand it to VS Code.** Restart an MCP server (Command Palette → *MCP: List Servers* → a `moos-…`
   server → *Restart*); VS Code prompts once for each input and stores them in secret storage.

**Verify (any shell, no secrets in argv — put them in env first):**

```bash
curl -s -o /dev/null -w "%{http_code}\n" \
  -H "CF-Access-Client-Id: $CF_ACCESS_CLIENT_ID" \
  -H "CF-Access-Client-Secret: $CF_ACCESS_CLIENT_SECRET" \
  https://kernel.my-tiny-data-collider.nl/healthz
```

`200` = done: the edge authenticated the machine and the origin answered. `302` = step 2 is missing
(policy does not admit the token). `403` = the policy exists but does not include *this* token.

## 3b · What was actually done (t283) — and three gotchas that cost real time

**Configured:** service token **`z440-vscode-mcp`**; a reusable Access policy **`service-token-mcp`**
(`c1a22969-03f2-4463-80e8-592d3462f45a`, action **Service Auth**, include = that specific token, not
"Any Access Service Token"); attached to **both** apps — `moos-kernel` and `moos-api` — which already
shared the single `sam-only` policy. Verified live: `200` with the token on both hostnames, `302`
without. Anonymous reads remain gated at the edge.

**Gotcha 1 — a token alone does nothing.** Confirmed by inspection, not inference: before this, both
apps carried exactly one policy (`sam-only`) and the account had **zero** service tokens. An Access
app ignores service-token headers unless a policy with action **Service Auth** admits them. That is
why the pre-t283 probe returned 302 rather than 401.

**Gotcha 2 — the dashboard moved.** Zero Trust paths are now
`dash.cloudflare.com/<account>/one/access-controls/{apps,policies,service-credentials}`. The older
`/access/apps` and `/one/access/apps` URLs 404. Service tokens live under **Service credentials**,
not "Service Auth".

**Gotcha 3 — paste the VALUE, not the header.** Cloudflare shows the credential as a ready-made
header line (`CF-Access-Client-Id: <value>`). Pasting that whole line into `secrets/api_keys.env`
puts the header name *inside* the variable, and the space makes `set -a; . api_keys.env` try to
execute the value as a command. The file wants bare `KEY=value` — no header prefix, no spaces around
`=`, and the template's lines start commented, so uncomment them.

**Client config:** `.vscode/mcp.json`'s two cloud servers read `${input:cf-access-client-id}` /
`${input:cf-access-client-secret}` (VS Code secret storage). Restart an MCP server to be prompted.

## 4 · Notes worth keeping

- **Access ≠ the kernel's bearer.** Two independent gates: Cloudflare Access controls *who reaches the
  origin at all*; the kernel's `--auth-token-file` bearer controls *who may write* once there. Reads are
  open at the kernel and closed at the edge. A service token grants edge passage only — it confers no
  write authority, and must never be reused as the kernel bearer.
- **cloudflared on Z440 is 2025.8.1** and warns on every invocation that 2026.7.3 exists. Z440 runs no
  connector, so this is cosmetic; upgrade only if Z440 ever hosts a tunnel.
- **`collider-studio` is dormant** (0 connectors). Decide at leisure: delete it, or keep it as the
  reserved name for a Z440-hosted tunnel. Nothing depends on it.
- **The exposure question is the kernel's, not the tunnel's.** Once a principal is past Access, the
  kernel serves reads to anyone — that is moos-kernel#68 (server-side per-user filtering), still open
  and unscheduled. Adding a *second* human to the Access policy is the event that makes #68 blocking.

---
authored-by: agent:claude-cowork.hp-z440 / session:sam.z440-cowork-workspace / t283-tunnel-access-closeout
