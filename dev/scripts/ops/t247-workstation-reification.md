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

Drafted with the kernel actor (infrastructure backfill). Two envelope-shape lessons surfaced on
apply and are now baked into these files:

1. **Additive MUTATE drops `rewrite_category`.** `kind` was absent, so this is the additive-MUTATE
   path (`moos-rewrite-envelope`): `{rewrite_type, actor, target_urn, field, new_value}` only — the
   runtime auto-injects the PropertySpec from the ontology. The initial draft wrongly carried a
   placeholder `rewrite_category` (that is the *standard*-MUTATE path, for a field already on the
   node). Removed.
2. **A workstation ADD needs all three required immutables.** The type spec requires immutable
   `hostname`, `os`, `arch` (+ mutable `kind`); the first ADD attempt omitted `os`/`arch` and set
   `hostname` mutable → `operad: required immutable property "os" missing`. The phone ADD now
   carries `hostname=sam-android`, `os=android`, `arch=arm64` (immutable), `kind=mobile` (mutable),
   matching the existing-node format (`os=windows`, `arch=amd64`).

## Apply — DONE (T=247)

Applied via `Test-MoosFederation.ps1 -Mode PostProgram` (kernel actor; §M11/§M12 bypassed for
infrastructure). Verified in the fold:
- `workstation:hp-z440 kind=desktop` (on hp-z440.primary)
- `workstation:hp-laptop kind=laptop` (on hp-laptop.primary)
- `workstation:sam-android` resolves — `kind=mobile os=android arch=arm64 hostname=sam-android`
- `user:sam —owns→ workstation:sam-android` (`urn:moos:rel:sam.owns.sam-android`)

The phone is now a first-class `workstation: <urn>` value for every Keep-ingest provenance trailer
(git and HG agree, per T239).

## NOT in scope

- No `hosts` relation for the phone (surface-only; no local engine — correct by doctrine).
- No phone→`google.keep.sam` relation (D8 `realizes` is deferred; surfaces are observed-only).
- No persona / `presents-as` work (D4 deferred; separate 4.0.x lane).

authored-by: agent:claude-cowork.hp-z440 / session:sam.z440-cowork-workspace / t247-spine-reification
