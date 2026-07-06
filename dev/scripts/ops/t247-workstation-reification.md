# T247 — spine reification: workstation.kind backfill + the phone

Follows the "workstation → user → agent → workspace → purpose → surface → engine" spine
design-think. A live read-only probe (T=247) settled what is already reified vs genuinely
missing. **Correction to an earlier claim: `workstation —hosts→ engine` is NOT missing — it
is live and sovereign per §M9.**

## What the live fold already carries (no work needed)

| Link | State in the fold |
|------|-------------------|
| `workstation —hosts→ engine` | ✅ live. `hp-z440 —hosts→ {hp-z440.primary, menno, lola, moos}` on the Z440 engine; `hp-laptop —hosts→ hp-laptop.primary` on the laptop engine. Reverse `hosted-on` shows in the engine's incoming-port histogram. Sovereign per §M9 (each box's hosts-relations live in its own log). |
| `user —owns→ workstation` | ✅ live. `urn:moos:rel:sam.owns.hp-z440` (WF01, ports `owns`/`child`). |
| `user —governs→ agent` | ✅ live. `user:sam —governs→` the agent principals + `role:superadmin`. |
| `workspace —WF19 has-occupant / opens-on / has-purpose / pins-urn→ …` | ✅ live (the seat table). `opens-on` records where the workspace's fold landed — it is not a routing choice; the engine is ambient (Sam, T247: "it's just there; workspaces just open in some engine"). |

## The only genuinely-missing reification (this batch)

1. **`workstation.kind` never backfilled.** The P1 enum `{server, desktop, laptop, mobile, vm, edge}`
   landed in the operad v4.0.0, but the existing workstation nodes carry only `arch/hostname/os`
   — no `kind`. Backfill: `hp-z440 → desktop`, `hp-laptop → laptop`.
2. **The phone is not in the graph.** Sam's `.device_samsandroid.noagent.user_sam` matrix
   coordinate has no node behind it. Reify it as a **surface-only** workstation (`kind: mobile`),
   `owned-by user:sam`. It hosts **no engine** — its Keep notes reach a fold through the existing
   `google.keep.sam` channel + G-ingest + the T239 trailer (`channel-kind: keep-widget`,
   `workstation: urn:moos:workstation:sam-android`). This makes the "no-agent / user-direct" path
   real without faking an agent into it.

## Residency (§M9 — why two files)

Each workstation node's log is sovereign on the box it describes:
- `t247-workstation-kind.z440.program.json` → **POST hp-z440.primary :8000** (hp-z440 kind).
- `t247-workstation-kind.laptop.program.json` → **POST hp-laptop.primary :8000** (hp-laptop kind
  + android ADD + owns LINK — the phone belongs to the mobile/laptop side of the fleet).
- **hpprodesk kind:** deferred — its node resolved with no props and its residency was not
  confirmed this pass (box mostly off). Add `kind: desktop` in a ProDesk-resident batch when it
  is next reachable.

## Review before apply (two envelope-shape confirmations)

Drafted with the kernel actor (infrastructure backfill) mirroring the b1b lifecycle-MUTATE and the
`sam.owns.hp-z440` relation shape. A reviewer / the `moos-rewrite-envelope` skill must confirm:

1. **Additive-MUTATE for a previously-absent optional property.** `kind` was never set, so this may
   need the full additive-MUTATE PropertySpec path rather than the plain `field`/`new_value` form
   (which targets a property already in `mutate_scope`). If additive, the envelope carries the spec
   (mutability/authority_scope/stratum_origin), not just the value.
2. **`rewrite_category` for a workstation property set / node ADD.** WF01 is used as a placeholder
   (the base topology family, matching the owns relation). Confirm the correct WF for a workstation
   S2 property MUTATE and a workstation ADD.

## Apply (boundary act — awaiting Sam's go)

```powershell
# batch Z440
dev\scripts\ops\...  POST -> http://localhost:8000/programs   (envelopes bare array)
# batch laptop
dev\scripts\ops\...  POST -> http://100.106.220.58:8000/programs
```
After apply: re-probe `kind` on all three nodes; confirm `workstation:sam-android` resolves and
`sam.owns.sam-android` links; then the phone is a first-class `workstation: <urn>` value in every
Keep-ingest provenance trailer (git and HG agree, per T239).

## NOT in scope

- No `hosts` relation for the phone (surface-only; no local engine — correct by doctrine).
- No phone→`google.keep.sam` relation (D8 `realizes` is deferred; surfaces are observed-only).
- No persona / `presents-as` work (D4 deferred; separate 4.0.x lane).

authored-by: agent:claude-cowork.hp-z440 / session:sam.z440-cowork-workspace / t247-spine-reification
