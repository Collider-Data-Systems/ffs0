# T244 — Karpathy seat purpose wiring (proposed HG apply)

Closes the deferred step 6 of ffs0#87 (#88 merged the IDE-affordance branch; the HG
topology fix was explicitly left as a separate boundary act): `session:sam.karpathy-seat`
has no durable `has-purpose` relation and no scope roots, so
`run-session-pipeline.ps1` fails its MVP gate for this seat.

Drafted by Guido (hp-laptop governance) per the locked division: **Guido drafts,
a Z440 seat reviews and applies** — the Karpathy lane's emit target is
`kernel:hp-z440.primary` (`:8000`) until §M9 twin sync; cross-emit from hp-laptop
is out of bounds.

## What it does (3 envelopes, one atomic program)

1. **ADD** `urn:moos:purpose:sam.compiler-lowering` — durable semantic slug
   (naming convention: no round-numbered slugs on durable nodes). Property shape
   copied from the applied T194 pattern (`started_at`/`subject_urn`/`status`/
   `target_state`); agent actor with explicit `session_urn`, matching precedent.
2. **LINK** WF19 `has-purpose / purpose-of-session` — session → purpose
   (many-to-one with rotation; repurposing later = MUTATE `target_urn`).
   Kernel actor, per the T194 precedent for WF19 LINKs.
3. **LINK** WF19 `pins-urn / pinned-by-session` — session pins its own purpose
   node as first scope root. This is the minimal apply that flips the MVP gate
   (`opens_on > 0 && occupants > 0 && scope_roots > 0`; the first two already
   pass per `VerifyPersona -Persona karpathy`, ffs0#87).

Deliberately NOT included: pins to the design note / skill as knowledge_items —
those KIs don't exist in HG yet. Extend with additional `pins-urn` LINKs after a
`moos-workspace-ingest` pass on `dev/design/manifold-bump-4_0/20260703-t244-moos-ir-mlir-lowering.md`,
if the lane wants them pinned.

## Z440 review checklist (before apply)

- [ ] `node_lookup urn:moos:session:sam.karpathy-seat` — exists, no existing
      `has-purpose` relation (avoid duplicate-relation surprise).
- [ ] `node_lookup urn:moos:purpose:sam.compiler-lowering` — must NOT exist yet.
- [ ] Confirm agent `vscode.hp-z440.lola` occupies exactly one session, or keep
      the explicit `session_urn` (it's set).
- [ ] Apply on Z440 primary: `POST http://localhost:8000/programs` with this
      file's body, or `mcp__moos-kernel__apply_program`.
- [ ] Re-run `run-session-pipeline.ps1` for the Karpathy seat — MVP gate should
      now pass; record log_seq range on the round-close note.

authored-by: agent:vscode.hp-laptop.copilot / session:sam.governance / t244-karpathy-purpose-wiring
