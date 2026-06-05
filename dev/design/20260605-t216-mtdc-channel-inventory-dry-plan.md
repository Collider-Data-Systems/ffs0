# DRAFT — my-tiny-data-collider domain/channel inventory (dry HG plan, T=216)

> **Status: DRY candidate plan. NOT applied.** No HG rewrite emitted. For review (Sam + Z440 lead + governance).
> Authored: Cowork-Z440, 2026-06-05 (T=216), from live verified readback (DNS / RDAP / HTTP probes / Cloudflare dashboard).
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
| `channel:cf-tunnel.moos-hp` | cloudflare-tunnel | tunnel `moos-hp`; connector alive on hp-laptop (4 HA conns) — **ingress detail PENDING governance redacted config** |
| `channel:cf-access.moos-api` | access-app | `api.*.nl`, policy `sam-only` |
| `channel:cf-access.moos-kernel` | access-app | `kernel.*.nl`, policy `sam-only` |
| `channel:web.mtdc-nl.apex` | website-endpoint | apex → tunnel → 502 (origin down; **target = redirect-to-.com per Sam**) |
| `channel:web.mtdc-nl.www` | website-endpoint | www → tunnel → 502 (same target) |
| `channel:web.mtdc-nl.api` | website-endpoint | api → Access-gated 302 |
| `channel:web.mtdc-nl.kernel` | website-endpoint | kernel → Access-gated 302 |
| `channel:mail.google-workspace.mtdc` | mail / cloud-storage (Workspace) | MX `smtp.google.com`; **SPF + DMARC now present (added T216), DKIM pending**; verify TXT present; users lola/menno/moos archived, sam active |
| `channel:github.collider-data-systems` | vcs / project-board | already modeled (org + Project #4) |

## Candidate `knowledge_item` evidence (G-ingest)
- `ki:readback.mtdc-dns-snapshot.t216` — `.nl` 8-record set + `.com/.eu/.org` NS state.
- `ki:readback.mtdc-registrar.t216` — RDAP: Realtime Register, registered 2026-01-13, active.
- `ki:readback.mtdc-http-probe.t216` — apex/www 502, api/kernel Access-302.
- `ki:readback.mtdc-email-auth.t216` — SPF + DMARC added/verified; DKIM pending Google generation.

## Candidate relations (exact WF pairs per validator)
- `group:my-tiny-data-collider —WF01 owns→` each channel (where the ontology allows ownership of the surface).
- each `ki:readback.* —WF12 source/provides-kb→` the relevant channel (per the validator's declared port-pair).
- `channel:web.* —(facet-of / routed-by)→ channel:cf-tunnel.moos-hp` / `channel:cf-access.*` (topology facet; exact relation pair TBD).

## Pending before this leaves "dry"
1. hp-laptop redacted `moos-hp` `config.yml` (apex/www ingress + origin targets) — fills the tunnel + web-endpoint rows.
2. 4.0 **D5** `channel.kind` values landed (or fall back to generic kind + `domain_tag`).
3. Sam review of source grain + authority boundary.
4. `group:my-tiny-data-collider` existence check in folded HG.

**No HG apply until 1–4 clear.**
