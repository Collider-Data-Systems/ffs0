# DRAFT — my-tiny-data-collider domain/channel inventory (dry HG plan, T=216)

> **Status: DRY candidate plan. NOT applied.** No HG rewrite emitted. For review (Sam + Z440 lead + governance).
> Authored: Cowork-Z440, 2026-06-05 (T=216), from live verified readback (DNS / RDAP / HTTP probes / Cloudflare dashboard).
> Updated 2026-06-05 ~19:38: folded in the `moos-hp` tunnel config evidence (ffs0#54 governance `4634511485` + lead `4634844188`).
> **Redaction boundary:** no secrets, tokens, raw account IDs, or credential paths as durable facts.
> Depends on 4.0 draft **D5** for `channel.kind` values (else use a generic kind + `domain_tag`).

## Owning anchor
- `group:my-tiny-data-collider` — ADD if absent (existence check pending folded-HG readback). The application manifold's group anchor.

## Candidate `channel` nodes (kinds per 4.0 D5)
| Proposed URN | kind | Observed state (evidence) |
|---|---|---|
| `channel:registrar.realtime-register.mtdc` | registrar | Realtime Register via Yourhosting reseller; `.com/.eu/.nl/.org` registered, "Actief" |
| `channel:dns.cloudflare.mtdc-nl` | dns-zone / cloudflare-zone | `.nl` authoritative on Cloudflare (elliott/meera.ns); 8 records |
| `channel:dns.yourhosting.mtdc-eu` | dns-zone | `.eu` on Yourhosting NS, empty |
| `channel:dns.parking.mtdc-com` | dns-zone | `.com` on `suspension*.mydomainprovider` NS — parked/suspended |
| `channel:dns.parking.mtdc-org` | dns-zone | `.org` — same as `.com` |
| `channel:cf-tunnel.moos-hp` | cloudflare-tunnel | tunnel `moos-hp` (id `3b748eb8-9032-4e9f-a20c-a06d494e9b58`); connector alive on hp-laptop (PID 11960, 4 HA conns). Ingress (redacted): `api`→`localhost:9000` (router), `kernel`→`localhost:8080` (MCP), apex+`www`→`localhost:9000/` (router root), catch-all→404 |
| `channel:cf-access.moos-api` | access-app | `api.*.nl`, policy `sam-only` |
| `channel:cf-access.moos-kernel` | access-app | `kernel.*.nl`, policy `sam-only` |
| `channel:web.mtdc-nl.apex` | website-endpoint | apex → tunnel → router root `:9000/` → **502** (local `:9000/`=502, `:9000/healthz`=200 ⇒ origin-shape debt, not connector). Target: off-tunnel → CF-edge `301→.com` |
| `channel:web.mtdc-nl.www` | website-endpoint | www → same as apex (router root `:9000/` → 502). Same target |
| `channel:web.mtdc-nl.api` | website-endpoint | api → tunnel → router `:9000`; Access-gated 302 (**stays tunnel**) |
| `channel:web.mtdc-nl.kernel` | website-endpoint | kernel → tunnel → MCP `:8080`; Access-gated 302 (**stays tunnel**) |
| `channel:mail.google-workspace.mtdc` | mail / cloud-storage (Workspace) | MX `smtp.google.com`; **SPF + DMARC now present (added T216), DKIM pending**; verify TXT present; users lola/menno/moos archived, sam active |
| `channel:github.collider-data-systems` | vcs / project-board | already modeled (org + Project #4) |

## Candidate `knowledge_item` evidence (G-ingest)
- `ki:readback.mtdc-dns-snapshot.t216` — `.nl` 8-record set + `.com/.eu/.org` NS state.
- `ki:readback.mtdc-registrar.t216` — RDAP: Realtime Register, registered 2026-01-13, active.
- `ki:readback.mtdc-http-probe.t216` — apex/www 502, api/kernel Access-302.
- `ki:readback.mtdc-email-auth.t216` — SPF + DMARC added/verified; DKIM pending Google generation.
- `ki:readback.mtdc-tunnel-config.t216` — redacted `moos-hp` ingress + local origin tests (apex/www→`:9000/`=502, `:9000/healthz`=200); connector alive (4 HA conns). Source: ffs0#54 `4634511485` (governance) + `4634844188` (lead).

## Candidate `claim` / `derivation`
- `claim:mtdc.apex-www-502-is-origin-shape` — apex/www `502` is **ingress/origin-shape debt** (router root is not a website origin), **not** connector-liveness debt. Cross-seat consensus (governance + lead).

## Candidate relations (exact WF pairs per validator)
- `group:my-tiny-data-collider —WF01 owns→` each channel (where the ontology allows ownership of the surface).
- each `ki:readback.* —WF12 source/provides-kb→` the relevant channel (per the validator's declared port-pair).
- `channel:web.* —(facet-of / routed-by)→ channel:cf-tunnel.moos-hp` / `channel:cf-access.*` (topology facet; exact relation pair TBD).
- `ki:readback.mtdc-tunnel-config.t216 —(evidence-for)→ claim:mtdc.apex-www-502-is-origin-shape`.

## Consensus apex/www fix sequencing (ratified ffs0#54, NOT yet applied)
Per Sam's decision + lead's caution — stage the edge replacement **before** removing tunnel ingress:
1. create/verify CF-edge placeholder or redirect for apex/www;
2. confirm certs + redirect targets;
3. remove/bypass apex/www tunnel ingress (hp-laptop `config.yml`);
4. re-probe apex/www externally;
5. leave `api`/`kernel` tunnel paths untouched.
Implementation waits on a fresh Sam go (multi-surface: hp-laptop + Cloudflare).

## Pending before this leaves "dry"
1. ~~hp-laptop redacted `moos-hp` `config.yml`~~ — **DONE** (ffs0#54 `4634511485`); tunnel + web-endpoint rows filled.
2. 4.0 **D5** `channel.kind` values landed (or fall back to generic kind + `domain_tag`).
3. Sam review of source grain + authority boundary.
4. `group:my-tiny-data-collider` existence check in folded HG.

**No HG apply until 2–4 clear.**
