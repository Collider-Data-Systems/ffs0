# T206 Keep API MVP And WF07 Wrapup

**T-day:** T=206
**Closeout date:** 2026-05-27
**Kernel/session:** `urn:moos:kernel:hp-laptop.primary` / `urn:moos:session:sam.governance`
**Actor:** `urn:moos:agent:vscode.hp-laptop.copilot`
**Runtime readback:** hp-laptop `localhost:8000` ok, `ontology_version=3.16.2`, `t_day=206`, `log_len=1467`; router `localhost:9000` ok with local hp-laptop up and Z440 down over LAN
**Lane:** Keep/API boundary, harness-neutral staging, Calendar source-anchor repair, projection dashboard closeout

## Executive Status

This sprint delivered the Keep/API ingest surface without crossing the raw-note boundary, then closed the long-running WF07 Calendar source-anchor deferral. The useful result is not that raw T195-T206 Keep notes are now in HG; they are not. The useful result is that any harness can now run the same checked Keep ingest path, the current OAuth blocker is explicit, the MVP carrier is on the log, and Calendar readback is fully reconciled through WF07 source anchors.

The live hp-laptop runtime now reports `ontology_version=3.16.2`, `t_day=206`, `log_len=1467`. The session pipeline gate remains a usable `warn`: 23 pass, 1 warn, 0 fail. The only remaining warning is visual lens root coverage.

## What Landed

| Surface | Result |
| --- | --- |
| Keep API fetcher | `dev/scripts/google_keep_fetch.jl` implements the official Google Keep API/OAuth fetch/export boundary. Discovery exposes `keep.readonly`, but the current Google OAuth project/account still rejects that scope externally. |
| Keep dry stager | `dev/scripts/keep_t195_t206_ingest_stage.jl` can stage exported Keep/loose-thought source material into review artifacts while keeping `apply_ready=false`. |
| Harness-neutral runner | `dev/scripts/ops/Invoke-KeepIngestHarness.ps1` gives any harness the same `Check`, `Stage`, `ClipboardStage`, `ApiAuthListen`, `ApiFetch`, and `Pipeline` modes. |
| Harness prompt | `.github/prompts/keep-ingest-any-harness.prompt.md` records the actor/session/relation guardrails for future agents. |
| MVP carrier | `dev/scripts/t206_keep_mvp_delivery.jl` generated `dev/scripts/ops/t206-keep-api-mvp-delivery.program.json`, which landed the reviewed boundary and status carriers without raw note assertions. |
| WF07 ontology repair | `kb/superset/ontology.json` is now v3.16.2 and declares WF07 `anchors/anchor` as an `additional_port_pair` for `calendar_event` source anchors. |
| WF07 catch-up apply | `dev/scripts/ops/t206-wf07-calendar-anchor-catchup.program.json` applied 22 Calendar event nodes, 22 governance pins, and 22 WF07 source-anchor links. |
| Projection reconciliation | Recommendation reconciliation now reports grouped nodes 10/10, grouped safe relations 16/16, Calendar event nodes 22/22, Calendar session pins 22/22, WF07 source anchors 22/22, deferred relations 0. |

## Rewrite And Runtime Delta

| Batch | Runtime delta | Rewrite shape |
| --- | --- | --- |
| T206 Keep API MVP delivery | `log_len 1360 -> 1400` | 39 affected items from the reviewed Keep/API status carrier program. |
| T206 WF07 Calendar anchor catch-up | `log_len 1400 -> 1467` | 66 reviewed envelopes: 22 `ADD` calendar_event nodes and 44 `LINK` relations, split across WF19 pins and WF07 anchors. |

The log length delta includes kernel-side lifecycle effects around the applied program path. The apply records are marked `applied=true` and `do_not_reapply=true`.

## Boundary Decisions

Raw T195-T206 Keep note content remains intentionally out of HG. The stager and fetcher are ready, but source material still needs Sam-approved structure before it becomes `knowledge_item` evidence or causes claims, derivations, purposes, or programs.

The Google Keep OAuth error is not a mo:os runtime bug. Google discovery lists the scope, but the active OAuth client/project/account returns `invalid_scope` for `https://www.googleapis.com/auth/keep.readonly`. The next move is Google Cloud Console / OAuth consent configuration, not a kernel change.

Calendar source anchors are no longer deferred. The ontology now declares the WF07 pair, the runtime loaded it, endpoint preflight passed, the catch-up applied, and the atlas now marks the WF07 move as `applied` when reconciliation has zero pending anchor rows.

## Validation

- Keep stager tests: 19/19 pass.
- Keep fetcher tests: 25/25 pass.
- T206 MVP delivery tests: 13/13 pass.
- T189/T200 recommendation projection tests: 20/20 pass.
- T189 recommendation reconciliation tests: 29/29 pass.
- Session pipeline MVP gate tests: 98/98 pass.
- Surface context atlas tests: 46/46 pass after the `applied` WF07 status branch.
- Operad integration: `MOOS_INTEGRATION=1 go test ./internal/operad` pass.
- Full session pipeline regeneration: `warn`, 23 pass / 1 warn / 0 fail.
- Keep harness `Check`: runtime `ontology_version=3.16.2`, `log_len=1467`, graph anchors resolved.
- Router readback: `localhost:9000` ok, local hp-laptop up, Z440 down over LAN.

## Next Sprint

The next sprint should stay narrow:

1. Keep raw T195-T206 note ingest postponed until Sam approves structured source notes.
2. Resolve the Google Keep OAuth scope approval externally in Google Cloud Console / OAuth consent configuration.
3. Fix or intentionally preserve the final pipeline warning: visual lens root coverage on the session-occasion lens.
4. Keep the five T200+ lanes scoped-idle until reviewed payloads seat occupants.
5. Continue Project #4 `HG URN` coverage and `my-tiny-data-collider` surface mapping after the above gates are stable.

## Current Reading

The projection family is now in a much cleaner state. Keep/API ingest is harness-neutral and review-gated, Calendar G-readback is fully reconciled, WF07 no longer blocks source anchors, and the dashboard's remaining warning is a real topology/lens design issue rather than a hidden apply backlog.