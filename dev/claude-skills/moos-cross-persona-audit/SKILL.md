---
name: moos-cross-persona-audit
description: Multi-persona / multi-kernel / contribution-log audit for round-close ritual. Walks the N-invariant checklist (§9 governance) across both kernels via federation router, verifies emit-target adherence, port↔URN consistency, single-occupant invariant, derivation-citation coherence, schema-bump backfill completeness, enum-value canonicalisation. Distinct from `moos-running-state-validator` (single-doc-vs-state consistency) and `moos-state-readback` (fleet snapshot one-shot). Trigger phrases: "round close", "cross-persona audit", "audit dry run", "did the round drift", "verify emit-target on N", "WF21 acyclicity check", "post-bump backfill audit", "kind enum drift".
---

# moos-cross-persona-audit

Round-close discipline for the Guido / governance lane. Walks the §9 invariant checklist across both kernels in 30-60 seconds and reports drift in a single comment on the round-vehicle issue.

## When to run

**Firm trigger** — round-close, after each persona has posted their closeout comment. Guido runs this skill, posts AUDIT GREEN or AUDIT FINDINGS list to the round-vehicle issue.

**On-demand triggers** — drift suspected (e.g. Wolfram pushes a doctrine commit and you want to verify referential integrity); host-runner-fired specialist derivation arrives (verify A.4 emit-target adherence); ontology bump promoted (verify A.9/A.10/A.11 backfill completeness); user asks "did the round drift?".

**Skip** — initial round-open (use `moos-state-readback` for fleet snapshot); single-doc consistency check (`moos-running-state-validator` is the right tool); single Cowork-session readback (`moos-cowork-readback`).

## What this skill is NOT

- NOT a write skill. All checks are read-only against `/state` + `/log` + `/healthz` + federation router. No envelope emissions.
- NOT a fleet-startup snapshot — `moos-state-readback` covers that.
- NOT a single-document validator — `moos-running-state-validator` covers running-state.md ↔ HG state consistency.
- NOT a single-session readback — `moos-cowork-readback` covers per-Cowork-session t-cone.
- NOT auto-firing. Manual trigger; reactor-as-autonomy lift is round-16+ candidate (§9.8.2).

## Persona seat conventions

```
agent:    urn:moos:agent:claude-code.hp-laptop  (Guido)
session:  urn:moos:session:sam.governance
kernel:   kernel:hp-laptop.primary  (port 8000 HTTP, 8080 MCP)
branch:   guido/r<NN>-<topic>  (per-round per-topic; round-close commits ride main via PR)
```

The skill is invokable from any persona seat (read-only, no actor required for queries), but interpretation + posting the comment is Guido-lane-specific.

## The N-invariant checklist (round-15+)

Per §9.4.1 of `kb/research/spec/09-governance-and-audit.md`. Run each check; report PASS/FAIL/N/A per invariant. The checklist grows monotonically per substrate-evolution cycle.

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

## Sequence — typical run

```bash
# 1. Fleet snapshot (hp-laptop + Z440 federation)
curl -sS http://192.168.1.13:9000/healthz | jq '.kernels'  # router cascade
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
## [Guido] Round-N audit — AUDIT <GREEN|FINDINGS>

| # | Invariant | Result |
|---|---|---|
| A.1 | §M11 session-liveness | PASS |
| A.2 | §M12 admin-capability | N/A |
| ... |

[FINDINGS list if any, with remediation pointers]

— Guido, session:sam.governance, kernel:hp-laptop.primary, T=NNN
```

## Cross-references

- §9.4.1 of `kb/research/spec/09-governance-and-audit.md` — the canonical N-invariant table.
- `dev/claude-skills/moos-running-state-validator/SKILL.md` — single-doc consistency companion.
- `dev/claude-skills/moos-state-readback/SKILL.md` — fleet-snapshot starter; run before this skill at round-open.
- `dev/scripts/ops/Test-MoosFederation.ps1` — Steinberger's harness; provides the preflight register for A.1+A.4.
- §9.8.1 (round-14/15 claim ADDs landed) + §9.8.2 (round-16+ deferred including audit-as-reactor autonomy lift).

## Status

Authored round-15 expansion (T=177) by Guido on `session:sam.governance`. Pairs with the §9 chapter md projection. Ships in `guido/r15-section-9-expansion` branch alongside the chapter expansion + 3 round-15 claim ADDs + 3 WF21 LINKs.
