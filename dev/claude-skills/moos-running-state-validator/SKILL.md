---
name: moos-running-state-validator
description: Validate `kb/superset/running-state.md` for consistency against actual HG state across both kernels. Use at round close (after `moos-round-close`) and at round open (after `moos-state-readback`) to catch drift between the doctrine summary and the live kernel logs. Checks: T-day matches `/healthz` t_day on both kernels; ontology version matches both kernels' runtime version; cited log_seq ranges resolve to actual rewrites; log_len vs max_log_seq integrity per kernel (multi-writer duplicate detection, moos-kernel#40); cited URNs resolve via `/state/nodes`; round-entry chronology is monotonic; no orphaned references to retired notes. Trigger on: round open / round close, "did running-state drift?", post-merge after a doctrine commit, or whenever a hydrating reader (new persona, new conversation) hits a citation that doesn't resolve.
---

# moos-running-state-validator

John Lydon's lane skill. The hydration entrypoint `kb/superset/running-state.md` is read by every persona at session-open as the canonical "what's happening now" surface. It's hand-authored across rounds; without validation, drift accumulates — cited log_seqs fall behind actual logs, ontology versions stamp incorrectly, retired URNs linger in citations.

This skill walks the document against the live kernel state on both machines and reports drift before any reader hydrates from a stale picture.

## Triggers

- **Round-open ritual** (after `moos-state-readback`) — confirm the top entry matches today's actual T-day + log state
- **Round-close ritual** (after `moos-round-close`) — confirm the new top entry's citations all resolve before push
- **Post-doctrine-commit** — every time a derivation/claim ADD lands or a `kb/research/planning.md` edit ships, citations may drift
- **New persona seating** — when a new agent reads `running-state.md` for the first time, validate freshness first
- **Anomaly investigation** — "this comment in #35 cites log_seq X but I can't find it" → run the validator

## What this skill is NOT

- Not for editing `running-state.md` — that's `moos-round-close`'s lane
- Not for full kernel readback — that's `moos-state-readback`'s lane
- Not for the doctrine notes themselves — those have their own audit (cross-references in t187-kernel-proper.md §M sub-program tables)

## Validation passes (in order)

### Pass 1 — header consistency

Top of `running-state.md` should match both kernels' runtime:

- Most-recent entry's claimed T-day == `/healthz` `t_day` on both Z440 :8000 and hp-laptop :8000
- Claimed ontology version (e.g. "v3.13.0") == `/healthz` `ontology_version` on both kernels
- If the entries diverge across kernels (one says T=175, the other T=176), flag as **federation lag**

### Pass 2 — log_seq citations resolve

Every entry that cites `log_seq N..M` or `log_seq=N` should:
- Be ≤ that kernel's current **`max_log_seq`** (fall back to `log_len` on pre-4c99df8 kernels that don't expose it)
- Resolve to a real rewrite via `GET /log?from=N` or `GET /log?from=N&to=M`
- Stamp the right kernel (Z440 :8000 vs hp-laptop :8000 — entries usually say which)

Common drift: round-N entry says "log_seq 600–627" but kernel has been restarted with a partial log; or rounds got re-ordered.

**Grandfathering (T≤247, moos-kernel#40 governance countersign):** all pre-#42 running-state entries cite **len-based** numbers — on hp-laptop up to 1575 against `max_log_seq` 1558 — which is honest history, not new drift. Do not flag them mechanically and never retro-edit (verbatim-archive ethos, same as ffs0#109): annotate on next touch only. Seq-based citations are canonical from the first post-#42 round entry forward.

### Pass 2b — log_len vs max_log_seq integrity (moos-kernel#40 (d))

`/healthz` serves both counters as one atomic snapshot since `4c99df8`. Compare per kernel:

- **`log_len == max_log_seq`** — clean single-writer log. ✓
- **`log_len > max_log_seq`** — the replayed file carries **multi-writer duplicate entries**; the delta is the cumulative duplicate count (hp-laptop's historical Δ17). Report the delta and treat **`max_log_seq` as the canonical citation key** — len-based citations overshoot by the delta (e.g. the ffs0#105 trio is seq 1556–1558, not 1573–1575). Not new corruption by itself, but if the delta GREW since the last validated round, a second writer got in — escalate to ops (find the process; see moos-kernel#40 (e)).
- **`log_len < max_log_seq`** — seqs were stamped for rewrites whose persist failed (the counter never rolls back on Append error). Benign gap; note it, don't alarm.
- Field absent → kernel predates the fix; note "pre-#40 binary, integrity unverifiable" instead of skipping silently.

### Pass 3 — URN citations resolve

For each `urn:moos:<type>:<...>` cited in the most-recent N entries (default N=5):
- Resolve via `/state/nodes/<urn>` on the relevant kernel
- Confirm the node-type matches the cited type
- Flag if the URN doesn't exist (anywhere) or exists with different type

Common drift: a session URN gets renamed via doctrine but the running-state still cites the old URN.

### Pass 4 — chronology monotonicity

Walk all top-level `> Updated:` entries in order:
- T-day should be monotonic non-decreasing top→bottom (newest first)
- CEST timestamps within the same T-day should also monotonic non-decreasing top→bottom
- Flag inversions

### Pass 5 — orphan-citation check

`kb/research/` now contains only `planning.md` (T=178 cleanup); past doctrine notes are reified as `derivation:*` URNs on log. Walk md-path citations in entries:
- Confirm each cited `kb/research/...` path resolves to a live file (almost always `planning.md`) OR is correctly redirected to `dev/reference/research-archive/`
- Flag a citation pointing at `kb/research/<deleted-doctrine>.md` — replace with the corresponding `derivation:*` URN cited via Pass 3

### Pass 6 — ontology-version cross-check

Citations like "v3.13.0", "v3.14.0", "v3.13 candidates" — confirm:
- ontology.json on disk matches the most-recent claimed version
- All grammar_fragment URNs cited (e.g. `v313-7-group-type`) actually exist as nodes
- Their `status` matches what the entry claims (`proposed` / `promoted` / `merged`)

## Output shape

Compact 5-section report:

```
running-state.md validation (T=<N>, run at <ISO>)
  pass 1 header:        OK | DRIFT (kernel says T=N+1, top entry says T=N)
  pass 2 log_seqs:      X cited, Y resolve, Z drift
  pass 3 URNs:          X cited, Y resolve, Z drift
  pass 4 chronology:    OK | inversion at line Q (T=N before T=N+1)
  pass 5 orphan-paths:  X cited, Y exist, Z point at moved files
  pass 6 ontology:      OK | DRIFT (cited v3.13 promoted but ontology.json still v3.12)
verdict: GREEN | YELLOW (cosmetic drift only) | RED (citations fail to resolve)
```

GREEN = no action needed. YELLOW = drift exists but doesn't break hydration. RED = a hydrating reader will hit a broken citation; fix before push.

## Implementation note

This skill is **read-only** — it never mutates running-state or HG state. If drift is found, it surfaces a list of fixes for the round-close author (`moos-round-close`) to apply. The validator doesn't auto-correct because corrections often require human judgment (which entry to retain, how to rephrase).

## Worked example

**Trigger.** Round-13 just landed with 4 new skill SKILL.md files committed. Running-state has a new top entry citing them.

**Pass 1.** Z440 `/healthz` t_day=175, hp-laptop `/healthz` t_day=175. Top entry claims T=175. ✓
**Pass 2.** Top entry cites log_seq 339 (Z440), 638 (hp-laptop). Both resolve. ✓
**Pass 3.** Top entry cites `agent:claude-code.hp-z440`, `session:sam.kernel-proper`, `kernel:hp-z440.primary` — all resolve. ✓
**Pass 4.** Top entries: T=175 ~17:45, T=175 ~16:30, T=175 ~16:15, T=175 ~14:00. Monotonic. ✓
**Pass 5.** Cites `derivation:t175.program-authoring-fabric` (post-T=178 cleanup; was `kb/research/session/20260424-t175-program-authoring-fabric.md`) — resolves on log. ✓
**Pass 6.** ontology.json says 3.13.0; top entry doesn't claim a higher version. ✓

verdict: GREEN.

## Cross-references

- `moos-state-readback` — fleet-wide readback this validator complements
- `moos-round-close` — the author of new entries; this validator is its post-write check
- `kb/superset/running-state.md` — the document under validation
- `kb/superset/ontology.json` — the version source-of-truth

## Status

**Round-13 deliverable** (T=176). John Lydon lane skill — John Lydon authors and primarily uses; Wolfram + Cowork can invoke for sanity. Forward iteration: as the lattice grows, additional passes for board-item / project-#4 consistency, federation-router config consistency, and per-machine sovereignty audit (per §M9).
