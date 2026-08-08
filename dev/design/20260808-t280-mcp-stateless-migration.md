# MCP 2026-07-28 stateless migration — audit, recommendation, plan (t280)

> Written 2026-08-08 20:41 WEDT (`date`-verified). Closes the two remaining action items of
> ffs0#178 comment [5102630706](https://github.com/Collider-Data-Systems/ffs0/issues/178#issuecomment-5102630706)
> (item 1: kernel MCP session/handshake audit · item 4: adopt-now vs pin), re-homed from lane D to the
> Zappa MCP-migration lane by Sam's t280 dispatch. Items 2 and 3 stay closed as verified in the
> [t274 ledger](https://github.com/Collider-Data-Systems/ffs0/issues/178#issuecomment-5159941735) item 8:
> Roots/Sampling/Logging greps over `moos-kernel/internal/mcp` + `collider-pilot/src/mcp` = 0 files;
> `moos-router/internal/proxy/proxy.go` has no MCP route and no session affinity.
> **This round: written recommendation only — no code, no config edits, no restarts, no HG rewrites.**

## 1 · What the 2026-07-28 spec actually changes (from the official changelog)

Source: [modelcontextprotocol.io/specification/2026-07-28/changelog](https://modelcontextprotocol.io/specification/2026-07-28/changelog).
The migration-relevant deltas, not the press summary:

| # | Change | Consequence for mo:os |
|---|---|---|
| 1 | Protocol-level sessions + `Mcp-Session-Id` removed (SEP-2567); cross-call state = server-minted handles as ordinary tool args | The kernel's legacy `sessionId` machinery is exactly this |
| 2 | `initialize`/`notifications/initialized` removed; every request carries `_meta` keys `io.modelcontextprotocol/protocolVersion` / `clientCapabilities` / `clientInfo`; server stamps `serverInfo` into each result's `_meta`; mismatch → `UnsupportedProtocolVersionError` (-32022) | Kernel must read `_meta` per request instead of answering `initialize` |
| 3 | `server/discover` is a **MUST** for servers (also the stdio back-compat probe) | New method to implement |
| 4 | HTTP GET endpoint + `resources/subscribe` replaced by `subscriptions/listen` (opt-in POST stream) | Kernel has `listChanged:false`, nothing to notify — can omit subscriptions entirely |
| 5 | `ping`, `logging/setLevel`, `notifications/roots/list_changed` removed | Kernel implements `ping` (keep for legacy clients only) |
| 8 | All results carry required `resultType` (`"complete"` / `"input_required"`) | Every kernel response needs the field on the new surface |
| m4 | `Mcp-Method`, `Mcp-Name` headers required on Streamable HTTP POSTs | New endpoint must accept (and can route on) them |
| m5 | `ttlMs` + `cacheScope` required on `tools/list` etc. (`CacheableResult`) | Kernel tool list is static — `ttlMs` can be generous, `cacheScope:"private"` (bearer-gated surface) |
| m12 | Error-code partition: MCP-reserved -32020..-32099 | New codes on the new surface |
| D1 | **Roots, Sampling, Logging deprecated** (≥12-month window per the new feature-lifecycle policy) | mo:os usage = 0 (t274-verified). No clock pressure |
| D2 | **HTTP+SSE transport formally Deprecated** (SEP-2596) | **Every live mo:os MCP client entry rides this transport today** — this is the actual clock |

SDK state at publication: official TypeScript/Python/**Go**/C# SDKs support 2026-07-28
([SDK-beta announcement](https://blog.modelcontextprotocol.io/posts/sdk-betas-2026-07-28/)).
`mark3labs/mcp-go` (the bridge's dependency) had no 2026-07-28 release as of this audit.

## 2 · Audit — `moos-kernel/internal/mcp` (at `master@afe140c`)

Three files: `server.go` (11 KB), `protocol.go`, `auth_test.go`.

**Session/handshake assumptions found:**

1. **`server.go:28`** — `sessions map[string]chan []byte` (sessionId → SSE write channel), guarded by `s.mu`.
   In-memory, instance-pinned, unbounded key space (`fmt.Sprintf("s%d", time.Now().UnixNano())`, `server.go:97`).
   Used only by the legacy HTTP+SSE pair: `GET /sse` (`server.go:90-133`, issues the id in the `endpoint` event)
   + `POST /message?sessionId=` (`server.go:137-171`, mirrors the response into the channel).
   **This is verbatim the machinery SEP-2567/2596 removes.** It cannot round-robin across twins and does not
   survive a restart — congruent with the t274 router finding that stateless MCP would let :9000 shard-route MCP later.
2. **`protocol.go:44`** — `MCPProtocolVersion = "2024-11-05"`, pinned. `handleInitialize` (`server.go:246-257`)
   ignores the client's requested version entirely: no negotiation, no `UnsupportedProtocolVersionError` path.
3. **Everything else is already stateless.** `dispatch` (`server.go:227-244`) holds no per-connection state:
   `initialize` stores nothing, `tools/call` works without any prior handshake, the tool list is
   connection-invariant, and the write gate is a per-request bearer check (`server.go:146,187`).
   `POST /sse` (Streamable HTTP, `server.go:176-198`) never issued an `Mcp-Session-Id` — nothing to remove there.
   The stdio path (`server.go:201-224`) is a stateless line loop.

**Missing for 2026-07-28 conformance (the actual work list for the code round):**
`server/discover` · per-request `_meta` read (protocolVersion/clientCapabilities/clientInfo) + `serverInfo`
echo in result `_meta` · `resultType:"complete"` on results · `ttlMs`+`cacheScope` on `tools/list` ·
`Mcp-Method`/`Mcp-Name` header acceptance · the -32020..-32022 error codes.
Nothing on the deprecation clock: Roots/Sampling/Logging usage is 0 (t274, re-confirmed by this read —
`dispatch` routes only initialize/ping/tools/*).

**Estimate:** one package, stdlib-only, no architectural change — the tool semantics are untouched;
the delta is transport/scaffolding in `internal/mcp` plus tests.

## 3 · Audit — `ffs0/dev/tools/moos-mcp` (bridge, stdio)

- Speaks MCP over **stdio only** (`server.ServeStdio`, `main.go:65`); all protocol/handshake behavior is
  delegated to **`mark3labs/mcp-go` v0.55.0** (`go.mod`), which implements the old initialize handshake.
- No session state of its own; kernel access is plain per-request HTTP with an optional bearer
  (`--auth-token-file`, `main.go:32-45`).
- Under 2026-07-28, stdio clients use `server/discover` as the back-compat probe — old stdio servers keep
  working through the deprecation window on the client's fallback. **No urgency.**
- Migration options, decided at the code round, not now: (a) bump `mcp-go` when it lands 2026-07-28 support;
  (b) swap to the official `modelcontextprotocol/go-sdk`; (c) execute the README's standing follow-up —
  fold the bridge into `moos-kernel` and share the operad types directly. (c) is the DRY answer and
  collapses two MCP implementations into one; recommend (c), with (a) as the low-effort fallback.

## 4 · Client-config inventory (Z440; laptop/ProDesk via #178)

Auth material redacted throughout — structure only, per secret hygiene.

| # | File | Entries | 2026-07-28 exposure | Action at the window |
|---|---|---|---|---|
| 1 | `ffs0/.vscode/mcp.json` (gitignored, **live — untouched this round**) | 9: **7 sse** (`moos-primary` :8080 · `moos-menno` :9001 · `moos-lola` :9002 · `moos-moos` :9003 · `moos-hp-laptop-primary` · `moos-hpprodesk-primary` · `moos-kernel-cloud` tunnel) + 1 stdio (`moos-mcp-karpathy`) + 1 http (`moos-api-cloud`) | all 7 sse entries ride the Deprecated transport | flip sse → streamable-http URL; **A13 cleartext-bearer fix rides the same edit** |
| 2 | `ffs0/.vscode/mcp.json.example` (tracked) | 10: 2 stdio + 7 sse + 1 http | same | update in the Phase-1/2 PR |
| 3 | `ffs0/.mcp.json` (tracked, Claude Code project scope) | 2: `moos-kernel-cloud` sse + `moos-api-cloud` http; CF-Access header **placeholders only — committed blob verified clean (0 literals, last touched T=166 `81f326e`)** | 1 sse entry | flip at window |
| 4 | `~/.gemini/config/mcp_config.json` | 7: **4 `serverUrl` sse literals** (primary/menno/lola/moos) + 3 stdio (sequential-thinking, github, filesystem) | 4 entries | flip at window |
| 5 | `~/.gemini/antigravity/mcp_config.json` | 7: same shape as #4 (the t268 AG parity sync) | 4 entries | flip at window |
| 6 | `~/.gemini/antigravity/mcp/` | per-server runtime dirs | cache, not config | none |
| 7 | `~/.claude.json`, `claude_desktop_config.json` | 0 moos MCP refs / absent | — | none |
| 8 | **collider-pilot** (lane B) | A16 per-surface adapters read twin MCP :9001-:9003 | client of the same surface | lane B confirms at the window (Roots/Sampling/Logging already 0) |
| 9 | **hp-laptop + ProDesk equivalents** | unknown from this seat | — | inventory requested on #178 (CLAIM comment); their seats execute their own boxes |

**Anomaly (flag, not fixed — no config edits this round):** `moos-hp-laptop-primary` and
`moos-hpprodesk-primary` in file #1 both point at `http://localhost:8080/sse` — i.e. at the **Z440 primary**
engine, not the named boxes (expected Tailscale targets `100.106.220.58:8080` / `100.87.28.95:8080`).
Any IDE session selecting those entries silently reads the wrong fold. Correcting the two URLs rides the
same restart-window edit as the sse→http flip. Sam: confirm intended targets before the window.

## 5 · Recommendation — **adopt 2026-07-28 now, additively (dual-stack); cut legacy in a later round**

"Pin" is not actually available as a long-term stance: every live client entry rides a transport the spec
formally deprecated on 2026-07-28, and the IDE clients (VS Code, Claude Code, Gemini CLI, Antigravity)
will flip on vendor timelines we don't control — the kernel must speak **both** revisions through the window
no matter when we start. The only real decision is when to start, and the kernel's position makes early
cheap: the tool surface is already stateless (§2.3), the official Go SDK shipped day-one, and the t269
comment's instinct stands — stdlib-first and small beats carrying a compatibility shim under time pressure
later. The stateless surface also unlocks the t274 router finding (MCP round-robin across twins via :9000)
as a future option instead of a rewrite.

### Phase 1 — code (next kernel round; owner = whichever lane Sam gives the kernel MCP surface; no restart)
- New stateless endpoint on the MCP mux (suggest `POST /mcp`): Streamable HTTP per 2026-07-28 —
  `_meta` read/echo, `server/discover`, `resultType:"complete"`, `ttlMs`+`cacheScope` on `tools/list`,
  `Mcp-Method`/`Mcp-Name` acceptance, -32020..-32022 codes. Shares `dispatch` internals with the legacy paths.
- Legacy `GET /sse` + `POST /message` + `POST /sse` + `initialize` + `ping` untouched — old clients unaffected.
- Bearer write-gate applies to the new endpoint identically (`isWriteCall` is transport-independent).
- Bridge: **pin `mcp-go` v0.55.0** this phase; fold-into-kernel (§3c) or SDK swap decided in the same PR-round.
- Tests extend `auth_test.go` + a new conformance test per surface.

### Phase 2 — THE single restart window (everything rides this one)
The next scheduled fleet engine redeploy after the Phase-1 binary is on `master` — do **not** mint a
dedicated window. One window because every item below drops live IDE connections; batching = one reconnect event:
1. Fleet redeploy of the kernel binary: Z440 primary + twins (lane A owns Z440 restarts), laptop
   (`redeploy_laptop_kernel.ps1`), ProDesk (task-routed `redeploy_hpprodesk_kernel.ps1`, t278 mechanism).
2. Client-config flips, per box, by the seat that owns the box (coordinated on #178):
   files #1-#5 above sse/serverUrl → the new streamable endpoint; **A13** — bearer values out of cleartext
   `.vscode/mcp.json` (VS Code `inputs`/env-file indirection); the two localhost mispoints (§4 anomaly) corrected.
3. Verify per box: IDE reconnect + `tools/list` on the new endpoint + no-token write → 401 (t260 gate intact).

### Phase 3 — legacy removal (a later round, well inside the ≥12-month window)
After all fleet clients are confirmed on the new endpoint: delete the `sessions` map + `GET /sse` +
`POST /message` + `initialize`/`ping` handling from `internal/mcp`; drop `MCPProtocolVersion` pin;
optional follow-up issue: MCP route on `moos-router` :9000 with URN-shard round-robin (now trivially safe).

## 6 · References
- ffs0#178 [5102630706](https://github.com/Collider-Data-Systems/ffs0/issues/178#issuecomment-5102630706) (t269 review, four items) · [t274 ledger item 8](https://github.com/Collider-Data-Systems/ffs0/issues/178#issuecomment-5159941735) · t280 CLAIM [5227536073](https://github.com/Collider-Data-Systems/ffs0/issues/178#issuecomment-5227536073)
- Spec: [2026-07-28 changelog](https://modelcontextprotocol.io/specification/2026-07-28/changelog) · [release post](https://blog.modelcontextprotocol.io/posts/2026-07-28/) · [SDK betas](https://blog.modelcontextprotocol.io/posts/sdk-betas-2026-07-28/) · The New Stack [coverage](https://thenewstack.io/mcp-release-candidate-rewrite/)
- Audited at: moos-kernel `master@afe140c` · ffs0 `main@caa08d5` · moos-router `master@710afa0` (all crisp vs origin at read time)

---
authored-by: agent:claude-cowork.hp-z440 / session:sam.z440-cowork-workspace / t280-mcp-migration
