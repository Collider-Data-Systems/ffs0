# T194 T187 Path And Hp-Laptop Readback

**T-day:** T=194
**Date:** 2026-05-14
**Kernel/session:** `urn:moos:kernel:hp-laptop.primary` / `urn:moos:session:sam.governance`
**Actor:** `urn:moos:agent:claude-code.hp-laptop`
**Runtime readback:** hp-laptop `localhost:8000` ok, `ontology_version=3.16.1`, `t_day=194`, `log_len=1184`; router `localhost:9000` ok with Z440 remote down
**Lane:** session readback, T187 path synthesis, running-state closeout

## Executive status

This pass reconciles the T193 HP ProDesk direction change with the older hp-laptop VS Code tail. The current path is topology/readback/projection, not an ontology edit and not a revival of the unused T190 branch.

The T187 story now has two layers. The old delivery/program layer is historical: `program:sam.t187-kernel-proper` and `program:sam.t187-distributed-hg-mvp` are archived, `program:sam.t187.categorical-contract` is completed, and `session:sam.t187-mvp` is abandoned. The live continuation is the T187/T188/T189 projection family: Keep G-ingest, session-occasion context projection, graph artifacts, Calendar/time-fabric projection, recommendation reconciliation, surface atlas, and the dashboard/MVP gate.

## What landed

No HG rewrites, topology payloads, Calendar writes, GitHub Project G-sync, code changes, or ontology changes landed in this pass.

The durable repo edits are documentation only:

- [kb/superset/running-state.md](../superset/running-state.md) now has a T194 hp-laptop readback and current operating-context update.
- This report records the slower reasoning that should not bloat the hot running-state card.

The pre-existing local edit to [ffs0.code-workspace](../../ffs0.code-workspace) was preserved. Its diff only changes the Downloads folder path style from `${userHome}/Downloads` to `../../Downloads`; it is not part of this closeout.

## T187 path reading

The missing file is now an explicit readback fact: `kb/research/kernel/20260417-t187-kernel-proper.md` is referenced by older instructions, ontology notes, project rows, and ops docs, but it is not present in this checkout. Searches for `20260417`, `kernel-proper`, and matching archive names did not recover it locally. Treat those references as stale historical pointers unless another workstation or remote archive recovers the file.

For current work, use the surviving evidence:

- [kb/moos-diary/t187-t186-google-calendar-projection-report.md](t187-t186-google-calendar-projection-report.md) closes the first real Calendar projection and says the old T187 programs pivot to T200+ continuation.
- [kb/moos-diary/t188-t187-session-pipeline-mvp-report.md](t188-t187-session-pipeline-mvp-report.md) closes the dry Keep/session/visual MVP path with known warnings.
- [kb/moos-diary/t189-surface-context-atlas-wrapup.md](t189-surface-context-atlas-wrapup.md) is the latest pre-T193 projection-lane report.
- [kb/moos-diary/t193-hpprodesk-social-topology-inventory.md](t193-hpprodesk-social-topology-inventory.md) records the HP ProDesk topology and shared-graph projection readback.

The practical continuation is T194 room rejoin: read current hp-laptop, HP ProDesk, and Z440 runtime state before applying anything new. The HP ProDesk local 26-line graph being minimal is correct; projection can read the shared hp-laptop graph when it needs historical T187/T189 roots.

## Session and occupancy reading

This report is authored from the hp-laptop governance lane. The live hp-laptop kernel reports `ontology_version=3.16.1`, `t_day=194`, and `log_len=1184`. The router is healthy on `localhost:9000`, sees the local kernel up, and still reports the Z440 peer down.

The HP ProDesk T193 setup remains a separate local session: `session:sam.hpprodesk-setup` / `agent:vscode.hpprodesk.primary` on `kernel:hpprodesk.primary`, last copied back at `t_day=193`, `log_len=26`, with persona verification passing. Do not reapply either T193 program JSON; both were marked applied and do-not-reapply.

Traceability rule for later readers: this T194 readback is a doc-only projection from `urn:moos:session:sam.governance`; HP ProDesk outputs remain tied to `urn:moos:session:sam.hpprodesk-setup`; and both sessions should be read through WF19 `opens-on`, `has-occupant`, `has-purpose`, and `pins-urn` relations rather than through stale scalar status values.

## Surface and identity reading

GitHub readback during this pass found no open `ffs0` issues. Project #4 `mo:os` is active with 107 items and 19 fields, but no board-status-to-HG sync was performed.

The identity boundary from T193 still holds. Geurt, Gmail accounts, Google accounts, Cloudflare, DNS, and other external accounts are channel/surface/evidence topics unless Sam explicitly approves a stronger authority model. There is still no default `user:geurt`, `group:geurt`, Gmail authority node, account identity node, or secret node to add from this readback.

## Deferred items

- Decide whether the missing `20260417-t187-kernel-proper.md` should be recovered from another workstation/archive or retired by updating stale references.
- Rejoin live room state across hp-laptop, HP ProDesk, and Z440 before any new topology apply.
- Keep the HP ProDesk 26-line local graph minimal unless there is a real local-only projection need.
- Continue T189/T200 projection cleanup: WF07 anchors, forced visual-root relation decisions, Project #4 `HG URN` coverage, and `my-tiny-data-collider` surface mapping.
- The stale deleted HP ProDesk prompt reference in `dev/config/session-affordance-map.json` was superseded by the later T194 VS Code Agents pass, which points HP ProDesk and VS Code sessions at the reusable workstation opener.

## Validation

Readback and validation performed in this pass:

- `ffs0`: on `main`, only `ffs0.code-workspace` dirty.
- `moos-kernel`: on `master`, clean.
- `moos-router`: on `feat/type-map-routing`, clean.
- `localhost:8000/healthz`: ok, `ontology_version=3.16.1`, `t_day=194`, `log_len=1184`.
- `localhost:9000/healthz`: ok, local kernel up, Z440 remote down.
- `kb/superset/ontology.json`: parsed successfully as JSON, version `3.16.1`.
- `gh issue list --repo Collider-Data-Systems/ffs0 --state open`: no open issues.
- `gh project view 4 --owner Collider-Data-Systems`: Project #4 active, 107 items, 19 fields.
