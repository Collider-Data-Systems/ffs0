# Round-11 PR 1 compensating batch — Z440 side

**Status:** staged. Do **not** submit before:
1. [moos-kernel#27](https://github.com/MSD21091969/moos-kernel/pull/27) (PR 1 — loader extension + strict `ValidateLINK`) is merged.
2. Z440 kernel 0 is rebuilt from the new master binary.
3. Kernel 0 is restarted (targeted — PID on :8000/:8080 only, per `round11/pr0..2` pattern; federation kernels 1-3 stay up).
4. `/healthz` reports `ontology_version: "3.12.0"` (via [#26](https://github.com/MSD21091969/moos-kernel/pull/26) once merged).

Submitting earlier fails closed at Envelope 2 & 3 on the strict-pair validator (which is the whole point of PR 1), leaving the non-canonical `log_seq=233` LINK in place and no replacements seated. The batch is atomic — all-or-nothing — so a failed submission is a no-op, but it wastes log pressure via the validation roundtrip.

## What the batch does

Three envelopes, one atomic program on `kernel:hp-z440.primary`:

| # | Rewrite | URN | Intent |
|---|---|---|---|
| 1 | UNLINK | `urn:moos:relation:has_occupant:session.diary.to.occupant` | Remove the non-canonical `has-occupant`/`occupies` LINK AG landed at `log_seq=233` on v3.11 |
| 2 | LINK | `urn:moos:rel:session.sam.moos-diary.has-occupant.agent.antigravity-hp-z440` | Re-seat AG on the moos-diary session with canonical v3.10 `has-occupant`/`is-occupant-of` port pair |
| 3 | LINK | `urn:moos:rel:session.sam.kernel-proper.has-occupant.agent.claude-code-hp-z440` | Seat claude-z440 on the kernel-proper session (first-time seat; §M19 forcing function) |

Post-batch state:
- `session:sam.moos-diary` — `has-occupant` → `agent:antigravity.hp-z440` (canonical)
- `session:sam.kernel-proper` — `has-occupant` → `agent:claude-code.hp-z440` (canonical, new)
- Historical `log_seq=233` relation is gone from state but the ADD/LINK at that seq still appears in the log — "log is truth" preserved.

## How to submit (from Z440)

```bash
curl -sS -X POST -H 'Content-Type: application/json' \
  --data-binary @dev/scripts/ops/round11-pr1-postmerge-compensating-batch.json \
  -w '\nHTTP=%{http_code}\n' \
  http://localhost:8000/programs
```

Expected response: HTTP 200 + array of three `{"affected_...": "..."}` entries. Kernel `log_len` advances by 3.

## Pre-flight checks

```bash
# Confirm kernel sees post-PR-1 validator
curl -sS http://localhost:8000/healthz
# → ontology_version: "3.12.0", log_len: N

# Confirm session:sam.moos-diary still has the non-canonical LINK (pre-batch)
curl -sS 'http://localhost:8000/state/relations/src/urn:moos:session:sam.moos-diary' \
  | python -c "import sys,json; d=json.load(sys.stdin); print([{'tgt':r['tgt_urn'],'tgt_port':r['tgt_port']} for r in d])"
# → should include has-occupant/occupies entry targeting agent:antigravity.hp-z440
```

## Hp-laptop side (not in this batch)

Per [Guido's #33 cross-kernel atomicity correction](https://github.com/MSD21091969/ffs0/issues/33), the governance-session seat ships in its own 1-envelope batch on `kernel:hp-laptop.primary`:

```json
{
  "rewrite_type": "LINK",
  "actor": "urn:moos:kernel:hp-laptop.primary",
  "relation_urn": "urn:moos:rel:session.sam.governance.has-occupant.agent.claude-code-hp-laptop",
  "src_urn": "urn:moos:session:sam.governance",
  "src_port": "has-occupant",
  "tgt_urn": "urn:moos:agent:claude-code.hp-laptop",
  "tgt_port": "is-occupant-of",
  "rewrite_category": "WF19"
}
```

Hp-laptop-claude owns that envelope. Coordination via ffs0#33.

## See also

- `kb/research/session/20260421-t171-wolfram-kernel-proper-session.md` §5 (PR stack)
- `kb/research/session/20260421-t171-guido-governance-session.md`
- `kb/research/moos-diary/20260421-t171-multimodal-diary-personas.md`
- moos-kernel#27 (prerequisite)
- ffs0#33 (handoff thread)
