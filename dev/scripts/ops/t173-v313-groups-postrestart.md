# T=173 v3.13 post-restart group materialization

**Status:** staged, awaits kernel restart of kernel 0 (and ideally all 4 Z440 kernels) to pick up widened WF01/WF02 top-level `src_types`/`tgt_types` after the v3.13 ontology bump.

**Precondition:** `/healthz` on kernel 0 reports `ontology_version: "3.13.0"` **AND** `curl /operad/rewrite-categories` shows:

- `WF01.SrcTypes` includes `group` (not just `user`)
- `WF02.SrcTypes` includes `role` and `group`

If kernel hasn't reloaded since the ontology.json widening edit, these will still show the old narrow types. Restart kernel 0 first.

## How to submit

```bash
curl -sS -X POST -H 'Content-Type: application/json' \
  --data-binary @dev/scripts/ops/t173-v313-groups-postrestart.json \
  -w '\nHTTP=%{http_code}\n' \
  http://localhost:8000/programs
```

Expected: HTTP 200 + 11 `affected_*_urn` entries. Kernel log_len advances by 11.

## What lands (11 envelopes in the staged JSON — group ADDs + owns LINKs only; the 4 merge MUTATEs already fired pre-restart at log_seq 289–292)

```
ADD   group:sam     (session_urn: sam.kernel-proper for agent actor disambiguation)
ADD   group:moos    (session_urn: sam.kernel-proper)

LINK  WF01 owns/owned-by  group:sam  -> kernel:hp-z440.primary   (actor=kernel)
LINK                                   -> kernel:hp-z440.lola
LINK                                   -> kernel:hp-z440.menno
LINK                                   -> session:sam.kernel-proper
LINK                                   -> session:sam.mvp-delivery
LINK                                   -> purpose:sam.ship-t187-kernel-proper

LINK  WF01 owns/owned-by  group:moos -> kernel:hp-z440.moos
LINK                                   -> session:sam.moos-diary
LINK                                   -> purpose:sam.multimodal-curation-and-diary
```

After lands: Collider-Data-Systems GitHub teams (`sam`, `moos`) are reified on Z440 kernel 0 as HG nodes with typed ownership edges. Downstream query `what does group:sam own?` via `/state/relations/src/urn:moos:group:sam` returns the full scope list.

## Deferred / not in this batch

- hp-laptop mirror: `group:sam` ADD + `owns` LINKs to hp-laptop.primary + session:sam.governance. Guido's lane via #33.
- WF02 `delegates-to` LINKs: `role:superadmin --delegates-to--> role:{karpathy,steinberger,moos}-scope`. Requires first ADDing the sub-roles. Small follow-up batch; not critical for the initial group topology.
- `owner_urn` property deprecation in favor of `owns/owned-by` edges — deferred per ontology changelog §3.13.0 / migration_actions_in_hg note.
