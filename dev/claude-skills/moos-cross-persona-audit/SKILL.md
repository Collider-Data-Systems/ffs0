---
name: moos-cross-persona-audit
description: Governance audit: cross-persona/cross-engine round-close checks (N-invariant checklist, emit-target adherence, schema-bump completeness) plus running-state.md validation against live HG state (absorbed moos-running-state-validator). Use at round open/close or on suspected drift.
---

## When to use (routing detail)

Multi-persona / multi-kernel / contribution-log audit at round close. Walks the N-invariant checklist (§9 governance) across both kernels via federation router; verifies emit-target adherence, port↔URN consistency, single-occupant invariant, derivation-citation coherence, schema-bump completeness, enum-value drift detection. Includes running-state.md ↔ HG single-doc validation as its own mode (absorbed T=262, section below); distinct from `moos-state-readback` (fleet snapshot one-shot). Trigger phrases: "round close", "cross-persona audit", "audit dry run", "did the round drift", "verify emit-target on N", "WF21 acyclicity check", "post-bump completeness check", "kind enum drift".

# moos-cross-persona-audit

Round-close discipline for the John Lydon / governance lane. Walks the §9 invariant checklist across both kernels in 30-60 seconds and reports drift in a single comment on the round-vehicle issue.

## When to run

**Firm trigger** — round-close, after each persona has posted their closeout comment. John Lydon runs this skill, posts AUDIT GREEN or AUDIT FINDINGS list to the round-vehicle issue.

**On-demand triggers** — drift suspected (e.g. Wolfram pushes a doctrine commit and you want to verify referential integrity); host-runner-fired specialist derivation arrives (verify A.4 emit-target adherence); ontology bump promoted (verify A.9/A.10/A.11 backfill completeness); user asks "did the round drift?".

**Skip** — initial round-open (use `moos-state-readback` for fleet snapshot); single Cowork-session readback (`moos-seat-hydration` covers it). Single-doc running-state validation is NOT a skip — since T=262 it is this skill's absorbed mode (section below).

## What this skill is NOT

- NOT a write skill. All checks are read-only against `/state` + `/log` + `/healthz` + federation router. No envelope emissions.
- NOT a fleet-startup snapshot — `moos-state-readback` covers that.
- Running-state.md ↔ HG single-doc validation IS in scope since T=262 (absorbed mode, section below).
- NOT a single-session readback — `moos-seat-hydration` covers the per-Cowork-session t-cone.
- NOT auto-firing. Manual trigger; reactor-as-autonomy lift is round-16+ candidate (§9.8.2).

## Persona seat conventions

```
agent:    urn:moos:agent:claude-cowork.hp-laptop  (John Lydon / hp-laptop Claude Desktop/Cowork)
session:  urn:moos:session:sam.governance
kernel:   kernel:hp-laptop.primary  (port 8000 HTTP, 8080 MCP)
branch:   john-lydon/r<NN>-<topic>  (per-round per-topic; round-close commits ride main via PR)
```

T247 seat split: `urn:moos:agent:vscode.hp-laptop.copilot` is the separate **Guido**
laptop-VS-Code-lead seat (`session:sam.laptop-vscode-lead`), not an alias of this one;
governance occupancy belongs to `claude-cowork.hp-laptop` (the Claude Desktop/Cowork app —
#99 finding-6 correction; `claude-code.hp-laptop` is a retired legacy principal). The skill is invokable from any
persona seat (read-only, no actor required for queries), but interpretation + posting the
comment is John-Lydon-lane-specific.

## The N-invariant checklist (round-15+)

Per `ki:spec.section-09-governance-and-audit` (on log; round-14/15 §9 chapter umbrella) + `derivation:guido.section-09-governance-and-audit`. Run each check; report PASS/FAIL/N/A per invariant. The checklist grows monotonically per substrate-evolution cycle.

### A.1 §M11 session-liveness

For each derivation/claim ADDed in the round, verify the actor URN resolves to a session via `has-occupant` LINK on the receiving kernel.

```bash
# For each new derivation D in round R:
curl -sS http://<receiving-kernel>/state/relations/src/<actor-URN> | jq '[.[] | select(.src_port == "is-occupant-of")]'
# Expect: exactly 1 has-occupant edge to a session
```

PASS if has-occupant resolves to a session whose `opens-on` matches the receiving kernel (or matches the seat-bearing kernel for federated topology — see A.4).

### A.2 §M12 admin-capability

For each ADD/MUTATE on ontology-governed types or kernel-authority properties: verify actor → user via WF02 reverse-lookup, user → role:superadmin via WF02 forward.

```bash
curl -sS http://<kernel>/state/relations/tgt/<actor-URN> | jq '[.[] | select(.rewrite_category == "WF02")]'
```

Most round-N ADDs are not admin-scope; A.2 is N/A for typical claim/derivation ADDs.

### A.3 §M13 local_t tick

For each batch fired in the round, verify kernel-emitted MUTATE on the resolved session's `local_t` immediately follows the user envelope(s).

```bash
# Tail the log around the batch's last seq:
curl -sS "http://<kernel>/log?from=<last-batch-seq-1>&to=<last-batch-seq+2>"
# Expect: kernel-actor MUTATE on session.local_t immediately after the user envelopes
```

PASS if every batch ends with a kernel-emitted local_t MUTATE.

### A.4 emit-target adherence

For each derivation D, verify D.actor.has-occupant points to a session whose opens-on declares the kernel that received the POST.

```bash
# Determine receiving kernel from log location (sovereign log per kernel)
# Verify: actor → has-occupant → session → opens-on → kernel matches receiving kernel
```

For **topology-degenerate** hosts (hp-laptop single-kernel): emit-target == opens-on by construction; PASS trivially.

For **federated** hosts (Z440 4-kernel): emit-target may differ from opens-on (sessions live on primary, opens-on points elsewhere until §M9 sync). PASS if emit-target == seat-bearing kernel (where session was ADDed).

### A.5 §M19 single-occupant

For each session in the lattice, verify exactly 1 outbound `has-occupant` LINK.

```bash
for s in <all-sessions> ; do
  count=$(curl -sS http://<kernel>/state/relations/src/$s | jq '[.[] | select(.src_port == "has-occupant")] | length')
  echo "$s: $count"  # expect: 1
done
```

PASS if all sessions have count == 1.

### A.6 port↔URN consistency

For each kernel listed in `running-state.md` port-map block, verify `/healthz` returns the expected URN + port pairing.

```bash
# Cross-check running-state's port-map against /healthz on each kernel
# Z440: 8000=primary, 8001=menno, 8002=lola, 8003=moos
# hp-laptop: 8000=primary
```

PASS if every port maps to its declared URN.

### A.7 invariant-bracketing-meta (preflight ≡ audit)

For invariants that have BOTH preflight gate (kernel-rejected at Apply time) AND post-hoc audit (this skill): verify they reach the same coherence-verdict on the round's emissions.

PASS if every preflight-rejected emission is also flagged by the audit, AND every audit-flagged emission would also have been preflight-rejected (or surfaces a preflight gap to add).

### A.8 wf21-causal-acyclicity

For all WF21 LINKs added in the round (or all of them, depending on scope), verify the causation DAG remains acyclic.

```bash
# Walk all WF21 LINKs from a node; check no cycle reaches back
# (kernel's ValidateCausalAcyclic enforces at LINK-add time; audit verifies post-hoc)
```

PASS if walk returns no cycle. (Active since v3.15 per moos-kernel `7303aa8`.)

### A.9 property-presence-by-immutability

For each new ADD in the round, verify all immutable properties of the type spec are present on the envelope.

```bash
# For each ADD, fetch its node + the type spec; compare immutable properties
# Flag any missing
```

PASS if all ADDs carry their full immutable-property set.

### A.10 schema-bump-backfill-completeness

After an ontology bump, scan all nodes-of-affected-types for missing newly-introduced immutable properties.

```bash
# After bump: for each affected type T, query all nodes-of-T
# Flag any missing the new immutable property
# Remediation: explicit backfill MUTATE batch (kernel-actor)
```

Currently FINDINGS expected on hp-laptop: `channel:local.moos-footage` (T=171 era) lacks `substrate` + `substrate_anchor_urn` (v3.15 introduced). Remediation queued (round-16+).

### A.11 enum-value-renaming-non-migrating

For each enum-property on each affected type, scan all nodes for values not in the current ontology enum. Flag for migration.

```bash
# For each enum property P on type T, query all nodes-of-T's P-value
# Flag any value not in current enum
```

Currently FINDINGS expected on hp-laptop: `channel:local.moos-footage.kind="fs"` (legacy pre-v3.13 value); v3.15 has `filesystem`. Remediation: UNLINK + re-ADD (since `kind` is immutable) OR canonicalisation function on queries.

### A.12 per-fold identity (twins) — added T=249 per doctrine D

Extend the audit sweep to ALL folds a workstation hosts (Z440: `:8001`/`:8002`/`:8003` alongside `:8000`), per the G4 cross-fold identity doctrine (`dev/design/manifold-bump-4_0/20260708-t249-governance-authority-note.md` §5):

- **Absence-flags are SUPPRESSED**: a being's node missing from a fold is legal (asymmetric presence — presence is demand-driven). Never report "missing from fold N" as a finding. This is the audit-side form of the readback skill's per-fold cardinal rule (post-ffs0#134).
- **Wrong-URN-form flags are KEPT**: the same being under a *different URN form* (e.g. `workstation:hp-z440` vs legacy `ws:hp-z440`) violates URN-equality (clause 1) and IS a finding. Known open instance: H1 in the t249 governance note.
- **Frozen-fold sanity**: on folds with zero sessions, any non-kernel-actor rewrite in the log other than infra-type ADDs is a §M11 violation → hard finding. Infra-type ADDs by non-kernel actors are legal-but-guardrail-relevant (Finding F1) → soft finding, cite T=208.

```bash
# Per twin: users + user-outbound relations + any non-kernel actors in the log tail
for p in 8001 8002 8003 ; do
  curl -sS http://100.82.243.13:$p/state/nodes | jq '[.[] | select(.type_id=="user") | .urn]'
done
```

PASS if no wrong-URN-form duplicates and no §M11-violating log entries; absence of any node is never a finding.

## Sequence — typical run

```bash
# 1. Fleet snapshot (hp-laptop + Z440 federation)
curl -sS http://<router-host>:9000/healthz | jq '.kernels'  # router cascade (Z440 LAN: 192.168.1.11)
curl -sS http://localhost:8000/healthz                       # hp-laptop primary

# 2. For each kernel, walk the N invariants. Record PASS/FAIL/N/A.

# 3. Compose findings (single comment shape):
#    AUDIT GREEN  — all invariants PASS
#    AUDIT FINDINGS — list FAIL/FINDINGS items with remediation pointers

# 4. Post on round-vehicle issue.
```

## Worked example — round-13 close audit

Source: [#36 issuecomment-4320199704](https://github.com/Collider-Data-Systems/ffs0/issues/36#issuecomment-4320199704).

Findings:
- A.1–A.6: PASS across all round-13 emissions.
- A.6 SURFACED a real drift: prompt-template port-map (Karpathy=:8001, Steinberger=:8002) inverted vs federation reality (menno=:8001, lola=:8002). Fix landed in [`0c7cab7`](https://github.com/Collider-Data-Systems/ffs0/commit/0c7cab7) — running-state.md port-map block now canonical.
- Operational gap: Karpathy + Steinberger derivation envelopes authored in #36 comments but NOT on log (sandbox boundary; resolved by Steinberger's host-runner harness round-14 opener `Test-MoosFederation.ps1`).

Outcome: round-13 substrate close path (3) selected; Phase 2 (derivation firings) deferred to round-14 opener post-host-runner.

## Worked example — T=176 cross-persona audit

Source: [#36 issuecomment-4321778462](https://github.com/Collider-Data-Systems/ffs0/issues/36#issuecomment-4321778462).

Findings:
- A.4 first live pass: Karpathy's §1 derivation at Z440 :8000 log_seq 353. Both registers (Steinberger preflight + Guido audit) PASS.
- A.4 audit-pattern observation: invariant-bracketing-discipline pattern (§9.4.1 doctrine seed).

## Worked example — T=177 round-15 expansion audit

Source: [#42 (round-15 vehicle)](https://github.com/Collider-Data-Systems/ffs0/issues/42).

Findings:
- A.1–A.8: PASS.
- A.9: PASS for round-15 ADDs; FINDINGS for pre-v3.15 nodes (channel:local.moos-footage missing substrate properties).
- A.10: FINDINGS — pre-v3.15 channels lack substrate properties; explicit backfill needed.
- A.11: FINDINGS — channel:local.moos-footage.kind="fs" (legacy); UNLINK+re-ADD or canonicalisation function needed.

Outcome: A.9/A.10/A.11 reified as `claim:guido.*` ADDs at hp-laptop log_seq 757-759 + WF21 LINKs at 760-762. Doctrine matures via §9.4.5–§9.4.7 sub-sections.

## Output shape

Single round-vehicle comment:

```
## [John Lydon] Round-N audit — AUDIT <GREEN|FINDINGS>

| # | Invariant | Result |
|---|---|---|
| A.1 | §M11 session-liveness | PASS |
| A.2 | §M12 admin-capability | N/A |
| ... |

[FINDINGS list if any, with remediation pointers]

— John Lydon, session:sam.governance, kernel:hp-laptop.primary, T=NNN
```

## Cross-references

- `ki:spec.section-09-governance-and-audit` + `derivation:guido.section-09-governance-and-audit` (both on log) — the canonical N-invariant table source.
- Running-state validation mode: the absorbed section below (T=262; formerly `moos-running-state-validator`).
- `dev/claude-skills/moos-state-readback/SKILL.md` — fleet-snapshot starter; run before this skill at round-open.
- `dev/scripts/ops/Test-MoosFederation.ps1` — Steinberger's harness; provides the preflight register for A.1+A.4.
- §9.8.1 (round-14/15 claim ADDs landed) + §9.8.2 (round-16+ deferred including audit-as-reactor autonomy lift).

## Status

Authored round-15 expansion (T=177) by Guido on `session:sam.governance`. Pairs with the §9 chapter md projection. Ships in `guido/r15-section-9-expansion` branch alongside the chapter expansion + 3 round-15 claim ADDs + 3 WF21 LINKs.


---

# Absorbed (T=262): moos-running-state-validator

> Former standalone skill; body preserved verbatim — skill names referenced inside are historical (this content IS the running-state mode of `moos-cross-persona-audit`). Former description: Validate `kb/superset/running-state.md` for consistency against actual HG state across both kernels. Use at round close (after `moos-round-close`) and at round open (after `moos-state-readback`) to catch drift between the doctrine summary and the live kernel logs. Checks: T-day matches `/healthz` t_day on both kernels; ontology version matches both kernels' runtime version; cited log_seq ranges resolve to actual rewrites; log_len vs max_log_seq integrity per kernel (multi-writer duplicate detection, moos-kernel#40); cited URNs resolve via `/state/nodes`; round-entry chronology is monotonic; no orphaned references to retired notes. Trigger on: round open / round close, "did running-state drift?", post-merge after a doctrine commit, or whenever a hydrating reader (new persona, new conversation) hits a citation that doesn't resolve.

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
- **`log_seq_missing` (since the moos-kernel#45 fix):** healthz also counts entries persisted before the `log_seq` field existed (April-era seed lines; deserialize to seq 0 — real seqs start at 1). These are legacy, NOT duplicates: classify drift on **`(log_len − log_seq_missing)` vs `max_log_seq`**. The Z440 twins carry 3 each; with the subtraction they read clean.

### Pass 3 — URN citations resolve

For each `urn:moos:<type>:<...>` cited in the most-recent N entries (default N=5):
- Resolve via `/state/nodes/<urn>` on the relevant kernel
- Confirm the node-type matches the cited type
- Flag if the URN doesn't exist (anywhere) or exists with different type

Common drift: a session URN gets renamed via doctrine but the running-state still cites the old URN.

### Pass 4 — chronology monotonicity

Walk all top-level `> Updated:` entries in order:
- T-day should be monotonic non-INCREASING top→bottom (the file is newest-first; PR #144 Copilot wording fix)
- timestamps within the same T-day should likewise be non-increasing top→bottom
- Flag inversions
- **Chronology SOT is the COMMIT CLOCK, not the prose self-stamp** (t249 chronology-drift finding, `94f4edc`: self-stamps ran +0:58→+3:32 ahead of commit clocks in one day and crossed into immutable authored `created_at`). When adjudicating an inversion, resolve each entry's true time via `git log --format="%h %ad" --date=format:"%H:%M" -- kb/superset/running-state.md` and match entries to commits; the self-stamp is approximate unless it says "wall-clock verified". For T=249 specifically the check degrades to ordinal-only (grandfathered drift).

### Pass 4b — fused / headerless entries (t250-baseline finding 1)

A bad merge or careless edit can destroy a `> Updated:` header, silently fusing one entry's body onto the tail of another (real case: commit `0d0a084` fused the T=248 ~21:15 entry onto the T=249 ~12:45 entry; restored `e69f707`). Detect:
- Count `> Updated:` headers vs running-state-touching commits whose subject starts `T=<n>` over the same window — a deficit means a fused or dropped entry.
- Grep entry bodies for a second `**` bold-header pattern mid-paragraph (`. — <topic>: ` followed by prose that reads like an entry opening, or a stray `).**` closing an unopened bold) — the fusion signature.
- On hit: recover the original header from the commit that introduced the entry (`git log -S "<distinctive phrase>"`), restore it with a dated restoration note, never re-type the body.

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
