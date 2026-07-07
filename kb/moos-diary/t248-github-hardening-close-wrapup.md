# T=248 — GitHub hardening catch-up CLOSED: public-repo rulesets applied (6/6)

> Zappa / Cowork-Z440. Ledger already in `kb/superset/running-state.md` (T=248 ~03:30 entry, `c503772`); this is the narrative + the lessons that don't fit in a `> Updated:` block.
>
> *"Without deviation from the norm, progress is not possible."* — the norm here was a public repo with no server-side guardrails whatsoever. We deviated. Three rulesets' worth.

**T-day:** T=248   **Date:** 2026-07-07 (~03:23–03:35 CEST)
**Engine/workspace:** `kernel:hp-z440.primary` :8000 / `session:sam.z440-cowork-workspace`
**Agent:** `agent:claude-cowork.hp-z440` (Zappa)
**Lane:** GitHub org/repo governance — hardening-queue close-out
**Host of record:** `DESKTOP-42D00RD` (Z440, Tailscale `100.82.243.13`), gh auth `MSD21091969`

---

## Executive status — what changed and why it matters

The T=248 owner hardening queue is **6/6, closed.** The last open item — Q2, branch-protection rulesets on the public repos — landed this round. `moos-kernel`, `moos-router`, and `.github` now each carry a `protect-default-branch` ruleset that blocks **force-push** and **default-branch deletion**, enforcement `active`, read-back-verified. That's the difference between "the log is truth and please everyone be careful" and "GitHub itself refuses to let you rewrite or delete the trunk of a public repo." The public surface finally has a server-side gate; before tonight it had exactly none.

`ffs0` is pointedly *not* in that list — it's private on the Free plan, where rulesets aren't offered. Its only guardrail remains local discipline and the log-is-truth doctrine. That's not a gap we can close with an API call; it's a plan-tier fact, and it stays documented rather than papered over.

## The pickup — "take over from the other guy"

This was a clean baton-pass, not a cold start. The **t247;16.50** Zappa session had walked the queue down to one item and then *deliberately parked*, because applying rulesets is an org/repo-governance mutation and the harness classifier gates those — it wanted Sam's literal words, not an agent's initiative. Sam opened a fresh window (**t248;03.23**) and said: take over from the other Zappa.

So I did the thing a successor should do and **did not trust the predecessor's ledger on faith.** I re-derived it against live GitHub:

- org `two_factor_requirement_enabled` → `true` ✓
- org membership → exactly **1** member (`MSD21091969`) — the "enforcing 2FA locks out nobody" claim, re-confirmed, not assumed
- `demo-repository` → `archived=true` ✓
- MoosT2025 → absent from the member list ✓
- the 3 target repos → **zero** pre-existing rulesets (nothing to clobber), `admin:true` on all three (the token *can* write them)

One item I flat-out **could not** re-verify from this seat: the `PROJECTS_TOKEN` org secret. Listing org secrets needs `admin:org`; my token carries `read:org`, so the call 403s by design. I reported it as trusted-from-t247, not verified-by-me. Honesty about the edge of what you can see is cheaper than a confident wrong claim.

## A brief detour — "why is this a remote session??"

Mid-round Sam noticed the app's **"Remote Control"** badge and asked. Worth recording because it's a fleet-topology fact, not a one-off: the *compute* is local to the Z440 (`hostname = DESKTOP-42D00RD`, Tailscale `100.82.243.13` — the documented Z440 address, exactly). The "Remote Control" label + the `HPZ440` title badge just mean the **viewer** Sam was driving from was a different device/window attached to the Z440's session over account-level session sync. Badge = where the runtime lives; tooltip = where the eyeballs are. The `gh` calls run on the Z440 with the Z440's auth regardless of which screen is watching — remoteness changes nothing about the boundary or the classifier gate.

## The crux of the biscuit — one literal phrase

The crux of this round *was* the apostrophe, so to speak: a single authorized phrase. "Take over" resumed the seat; it did **not** authorize the mutation. Only `apply the rulesets`, said plainly, tripped the gate. When Sam said it, execution was one loop:

```
BODY='{"name":"protect-default-branch","target":"branch","enforcement":"active",
       "conditions":{"ref_name":{"include":["~DEFAULT_BRANCH"],"exclude":[]}},
       "rules":[{"type":"non_fast_forward"},{"type":"deletion"}]}'
for r in moos-kernel moos-router .github; do
  echo "$BODY" | gh api -X POST "repos/Collider-Data-Systems/$r/rulesets" --input -
done
```

`~DEFAULT_BRANCH` is the load-bearing detail: the three repos don't agree on a trunk name (`moos-kernel`/`moos-router` = `master`, `.github` = `main`), and the special token resolves per-repo so the *same* body is correct for all three. No per-repo hardcoding, no drift.

## What landed

**Rulesets (external write, GitHub API — no HG rewrite):**

| Repo | Ruleset id | Enforcement | Target ref | Rules |
|------|-----------:|-------------|------------|-------|
| `moos-kernel` | 18596929 | active | `~DEFAULT_BRANCH` → `master` | `non_fast_forward` + `deletion` |
| `moos-router` | 18596930 | active | `~DEFAULT_BRANCH` → `master` | `non_fast_forward` + `deletion` |
| `.github`     | 18596932 | active | `~DEFAULT_BRANCH` → `main`   | `non_fast_forward` + `deletion` |

All three reversible (a ruleset is deletable). Both rules and the `~DEFAULT_BRANCH` condition re-read via `GET .../rulesets/{id}` after the POST — POST-returned-201 is not proof of persisted config; the GET is.

**ffs0 ledger (git, direct-to-main per the standing running-state allowance):** commit `c503772`, pushed `c16dc96..c503772`. Two files, one commit:
- `kb/superset/running-state.md` — new T=248 ~03:30 close entry (6/6 queue, ruleset ids, boundary note).
- `dev/reference/github-org-operations.md` — Q2 struck DONE with ids; the stale "remaining three are owner-gated" status banner corrected to "remaining owner-gated: `PROJECTS_TOKEN`" (it contradicted the now-done Q2 otherwise).

Bundling the runbook §hardening strike into the running-state direct-to-main commit follows the precedent set by the 02:41 2FA entry, which did the same for hardening item #1 — the §hardening section is effectively part of the same state ledger as running-state for this queue.

## Session + occupancy

Carried entirely by `session:sam.z440-cowork-workspace`, occupant `agent:claude-cowork.hp-z440` (Zappa), emitting to `kernel:hp-z440.primary` :8000 — though nothing was emitted to the kernel this round: **zero HG rewrites.** This was git- and settings-side only, which is correct for a governance-hardening round. The GitHub board (#4) needs no new card; this closes queue items, it doesn't open work.

## Surface reading — GitHub ↔ HG

The public repos map to the runtime engines whose code they hold (`moos-kernel` = the Go engine; `moos-router` = federation WF16; `.github` = the org-config channel). The rulesets are a **D7 surface property** — an observed guardrail on the git surface that realizes those channels — not durable HG truth, and intentionally not reified into the graph. They're settings on the projection, verifiable live via `gh api`, exactly where they belong. The board itself was untouched (0 new items; the queue lives in the runbook, not as cards).

## Deferred items — intentionally undone (all Zappa-executable, none owner-gated)

- **Q3** — `SECURITY.md` in `.github` (vuln-reporting channel for the two public code repos).
- **owner-item-4** — security defaults on the public repos: secret-scanning + push-protection + Dependabot alerts (free for public).
- **Q6** — the notification SPOF: a scheduled Action or org webhook alerting on force-push / member-change / repo-deletion. Free-plan audit-log retention is only 90 days, so the alert *is* the durable record.
- **Q5** — board hygiene: the "New field 8" column (3 items carry a stray 2026-04-21 date — keep-as-"Legacy Date" vs drop).

None block anything; all await a go.

## Validation

- **Apply:** `gh api -X POST .../rulesets` ×3 → returned ids 18596929 / 18596930 / 18596932, each `enforcement:active`, `target:branch`.
- **Read-back:** `gh api .../rulesets` and `.../rulesets/{id}` ×3 → condition `~DEFAULT_BRANCH`, rules `["non_fast_forward","deletion"]` confirmed persisted on all three.
- **Pre-apply guards:** `admin:true` ×3; zero pre-existing rulesets ×3; org 2FA `true`; 1 member; demo archived.
- **Ledger:** `git commit c503772`, `git push` → `c16dc96..c503772` on `ffs0/main`, working tree clean, no force-push (the new rules wouldn't have blocked it anyway — they only guard the *public* trunks, and only against force-push/deletion, not ordinary commits).

## The one-liner for the next seat

Public repos are guarded (force-push + trunk-deletion blocked on `moos-kernel`/`moos-router`/`.github`); `ffs0` is not and can't be on Free; the owner hardening queue is **6/6 done**; four non-blocking Zappa items (Q3, owner-4, Q6, Q5) remain and need only a go. Nothing is waiting on Sam.

---
authored-by: agent:claude-cowork.hp-z440 / session:sam.z440-cowork-workspace / github-hardening-close-t248
