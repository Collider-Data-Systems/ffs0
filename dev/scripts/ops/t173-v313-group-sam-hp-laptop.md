# T=173 v3.13 group:sam hp-laptop mirror

**Status:** staged, awaits hp-laptop kernel restart to pick up v3.13 ontology (group type + WF01 widening with `owns/owned-by` port pair).

**Precondition:** `/healthz` on kernel:hp-laptop.primary reports `ontology_version: "3.13.0"` AND `/operad/rewrite-categories` shows:

- `WF01.SrcTypes` includes `group`
- `WF01` `additional_port_pairs` includes `owns` / `owned-by`

Binary at `moos-kernel.exe` is already post-PR-31 (per T=173 ~17:00 CEST Guido lane closeout). No rebuild — ontology-only bump.

## Scope — hp-laptop mirror of Z440 `group:sam`

Symmetric counterpart to [`t173-v313-groups-postrestart.json`](t173-v313-groups-postrestart.json) (Wolfram, Z440). This is Guido's lane per [ffs0#33](https://github.com/Collider-Data-Systems/ffs0/issues/33) closeout.

`group:moos` has no hp-laptop-side scope (diary lives on Z440 `kernel:hp-z440.moos`) — no mirror needed for that group.

## How to submit

```bash
curl -sS -X POST -H 'Content-Type: application/json' \
  --data-binary @dev/scripts/ops/t173-v313-group-sam-hp-laptop.json \
  -w '\nHTTP=%{http_code}\n' \
  http://localhost:8000/programs
```

Or via MCP: `mcp__moos-kernel__apply_program` with the envelope list.

Expected: HTTP 200 + 4 `affected_*_urn` entries. Kernel log_len advances by 4 (595 → 599).

## What lands (4 envelopes)

```
ADD   group:sam   (actor=agent:claude-code.hp-laptop, session_urn=sam.governance)

LINK  WF01 owns/owned-by  group:sam -> kernel:hp-laptop.primary         (actor=kernel)
LINK                                -> session:sam.governance            (actor=kernel)
LINK                                -> session:sam.laptop-cowork-workspace (actor=kernel)
```

After lands: hp-laptop sovereign log has `group:sam` with typed ownership edges to its local kernel + 2 sessions — symmetric with Z440's 6-target scope (1 kernel primary + 2 federation + 2 sessions + 1 purpose).

## Deferred / out of scope

- WF02 `delegates-to` sub-roles (`role:{karpathy,steinberger,moos}-scope` ← `role:superadmin`) — future batch, requires ADDing sub-roles first.
- `owner_urn` property deprecation migration — ontology changelog §3.13.0.
