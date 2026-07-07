---
name: moos-state-readback
description: Use this skill at the start of any mo:os working session, before claiming state is "crisp", and before any git pull/rebuild/restart. Performs the 15-second readback: per-repo `git -C <path> fetch` on ffs0 + moos-kernel + moos-router, diffs against their respective default branches, reads running-state.md header, checks kernel process + ports, pings `/healthz` (reads `ontology_version` directly — no grep-for-features heuristic), lists open handoff-issue comments. Answers "am I up to date — per repo?", "is the kernel up and on what runtime ontology version?", "has any peer agent pushed anything I should pull?". Trigger whenever a new conversation opens in one of the mo:os workspaces (`ffs0`, `moos-kernel`, `moos-router`, `moos-viz`), or any time you are about to make a claim about "is hp-laptop crisp", or before any bash command that changes repo state (pull / rebuild / commit).
---

# mo:os state readback

The 15-second "where are we" dance. Run it before any round. Without this, two failure modes hit:

- **Local `git status` lies by omission** when tracking branches aren't refreshed (T=170 opener: claimed "crisp" while ffs0 was 7 commits behind).
- **Wrong-repo operations** when `cd`-state drifts between bash calls and you pull/build the wrong thing (T=171: "pulled" moos-kernel but was actually in ffs0 dir; built from stale master without the merge).

Both avoidable with the discipline below.

## Cardinal rule — use `git -C <path>`, never trust `cd`

The Bash tool persists working-directory state across calls unpredictably. Rely on explicit `-C` for every git command, every time. No exceptions.

```bash
git -C /c/Users/maass/HPlaptop/ffs0 status -uno   # RIGHT
cd /c/Users/maass/HPlaptop/ffs0 && git status -uno # WRONG (drifts)
```

Same for `gh` — use `gh <cmd> --repo Collider-Data-Systems/<repo-name>` rather than relying on repo auto-detection from cwd.

On Windows, prefer full paths in live commands:

```powershell
git -C C:\Users\maass\HPlaptop\ffs0 status --short --branch
Set-Location 'C:\Users\maass\HPlaptop\ffs0'
& 'C:\Users\maass\AppData\Local\Programs\Julia-1.12.6\bin\julia.exe' dev\scripts\google_calendar_writer.jl --mode check
```

T189 caught the same class of drift with Julia: launching `dev\scripts\google_calendar_writer.jl` from `C:\Users\maass\HPlaptop` fails because the script path is repo-relative. Either `Set-Location` to `ffs0` first or pass an absolute script path.

## Cardinal rule — always qualify PR/issue numbers with repo

`#29` is ambiguous when three repos have their own PR sequences. Write `moos-kernel#29` or `ffs0#33` — every time, even when the context "obviously" implies one. On multi-machine handoffs (hp-laptop, Z440), the context doesn't always carry.

## Cardinal rule — node-existence claims need the right fold

Twins are sovereign folds. `user:moos` living on `kernel:hp-z440.moos` (:8003) is invisible to a
`/state/nodes` query on the primary (:8000) — and that is correct behavior, not drift. Before
claiming a node is "missing from the HG", check **every kernel whose graph could legitimately hold
it** — explicitly, matching the curl style of the rest of this skill:

```bash
# per-kernel node existence (Z440: primary :8000 + twins :8001-:8003)
for p in 8000 8001 8002 8003; do curl -sS http://localhost:$p/state/nodes/urn:moos:user:moos; echo; done
# or one shot via the router fan-in
curl -sS http://localhost:9000/healthz
```

Motivating incidents (T=248, two false "missing node" deltas in ONE day, same root cause):
1. ~11:00 — "`user:moos` doesn't exist; GitHub team description is ahead of the HG" → he'd been on
   `kernel:hp-z440.moos`'s own graph since 2026-04-10.
2. ~11:41 — the Lola-letter honesty clause: "the lola/menno ceremony hasn't been performed yet" →
   `user:lola`/`user:menno` + WF01 owns had been on their twins' graphs since the same April seed.
Both were primary-only readbacks that survived into authored text before live folds falsified them.

## What to check (in parallel)

Run the following as parallel `Bash` calls in a single tool use. Nothing here modifies state — all read-only.

### 1. Per-repo fetch + divergence (all three repos)

```bash
git -C /c/Users/maass/HPlaptop/ffs0 fetch --all --prune 2>&1 | tail -5
git -C /c/Users/maass/HPlaptop/ffs0 status -uno
git -C /c/Users/maass/HPlaptop/ffs0 log --oneline origin/main -10
```

```bash
git -C /c/Users/maass/HPlaptop/moos-kernel fetch --all --prune 2>&1 | tail -5
git -C /c/Users/maass/HPlaptop/moos-kernel status -uno
git -C /c/Users/maass/HPlaptop/moos-kernel log --oneline origin/master -10
```

```bash
git -C /c/Users/maass/HPlaptop/moos-router fetch --all --prune 2>&1 | tail -5
git -C /c/Users/maass/HPlaptop/moos-router status -uno
git -C /c/Users/maass/HPlaptop/moos-router log --oneline -5
```

Default branches: `ffs0` = `main`, `moos-kernel` = `master`, `moos-router` = `feat/type-map-routing` (current feature branch) or `master`. Check each.

For each repo: clean working-dir + `up to date with origin/<branch>` = crisp on that repo. "Behind by N commits" on any = **not crisp — plan per-repo pull before making claims**.

### 2. Running-state header

```bash
head -10 /c/Users/maass/HPlaptop/ffs0/kb/superset/running-state.md
```

The header line after `> Updated:` tells you the last T-day update and what's in flight. Compare its T-day against today's (from the `currentDate` context in your conversation).

### 3. Kernel process + port audit

```bash
tasklist | grep -Ei 'moos|cloudflared'
netstat -ano | grep -Ei 'LISTENING.*:(8000|8001|8002|8003|8080|8081|8082|8083|9000|4433)' | head -20
```

Expected on hp-laptop: one `moos-kernel.exe` PID bound to both `:8000` (transport) and `:8080` (MCP); one `moos-router.exe` on `:9000`. Extra `moos-kernel.exe` PIDs with no port bindings = leftover dev processes, ignore but note.

On Z440: up to 4 kernel PIDs (primary on `:8000/:8080` plus federation trio on `:8001-:8003` / `:9001-:9003`). Running-state typically names each.

### 4. MCP + runtime ontology version

```bash
curl -sS http://localhost:8000/healthz
```

Post-PR-#26 (moos-kernel master tip c642872+) returns:

```json
{"log_len": N, "ontology_version": "3.X.Y", "status": "ok", "t_day": T}
```

If `ontology_version` is absent: the kernel is running a pre-c642872 binary — note this. Older field set was `{log_len, status, t_day}`.

Compare to on-disk ontology version:

```bash
grep -o '"version": "[0-9.]*"' /c/Users/maass/HPlaptop/ffs0/kb/superset/ontology.json | head -1
```

Runtime < on-disk → kernel needs a rebuild+restart to pick up the bump.

### 5. Peer-agent handoff issue(s)

```bash
gh issue list --repo Collider-Data-Systems/ffs0 --state open --limit 10
gh issue view 33 --repo Collider-Data-Systems/ffs0 --comments 2>&1 | tail -80
```

If the active handoff issue isn't `ffs0#33`, substitute the current one. `--comments` with `tail -80` gets the last round of comments from peers — claude-z440, antigravity, or whoever is handing off.

### 6. Projection/public-surface readback

For T189/T200 projection work, also check the public-facing surfaces that can drift:

```powershell
gh auth status
gh repo view Collider-Data-Systems/.github --json name,isPrivate,url,defaultBranchRef
gh project view 4 --owner Collider-Data-Systems --format json
& 'C:\Users\maass\AppData\Local\Programs\Julia-1.12.6\bin\julia.exe' dev\scripts\google_calendar_writer.jl --mode check --out tmp/projections/session_pipeline/calendar/google_calendar_credential_check.json
```

Report GitHub Project item count, field count, and whether `HG URN` coverage is known. For Calendar, report credential/token presence and whether the writer would be a dry plan, insert, or upsert/patch path. Never print token values.

## Reporting shape

After the parallel batch, synthesize a 7-line summary:

```
ffs0:        <ahead|behind|clean> by N — <latest commit sha + short msg>
moos-kernel: <ahead|behind|clean> — <branch> tip <sha> <short msg>
moos-router: <ahead|behind|clean> — <branch>
running:     header T=<day>, <in-flight note>
kernel 0:    PID <pid> on :8000/:8080 — runtime v<X> (on disk v<Y>) [sweep: on|off]
federation:  [Z440 only] PIDs on :8001-:8003 — <status>
handoff:     ffs0#<N> — <M> new comments from <peer>; action queued: <yes/no>
surfaces:    Project #4 <item-count> items / <field-count> fields; Calendar token <present|missing>; org profile <present|missing>
```

If any row says "behind" or a version mismatch, the round opens with a pull/rebuild/restart plan, NOT with a doctrine claim.

## When to pull — and which repo

- **Each repo independently.** A single `git pull` covers one repo's WD. Others stay untouched.
- **Fast-forward safe + no local WIP on that repo**: `git -C <path> pull --ff-only` is fine.
- **Divergent (local ahead + remote ahead on same branch)**: plan a rebase or merge — don't auto-pull.
- **Clean + up to date**: nothing to do.

After pulling any repo: re-read the relevant running-state section / issue comments / PR state, because upstream edits may change what the next action is.

## What this skill does NOT do

- Doesn't restart the kernel (destructive; owner-approval required).
- Doesn't pull automatically (owner-approval for any state change).
- Doesn't rebuild binaries (owner-approval).
- Doesn't commit or push anything — pure read-only.

## Why it exists

**T=170 opener**: local `git status` showed "up to date" on ffs0 because tracking branches weren't refreshed. ffs0 was actually 7 commits behind origin — z440-claude had shipped Round 10 overnight. Caught by Sam's "please check git" nudge at the cost of one plan-file revision.

**T=171 opener** (same machine, fresh conversation): I said "pulling ffs0, rebuilding my binary" — the bash tool's `cd`-state drifted between calls and the "pull" command ran in the ffs0 directory (which was current) instead of moos-kernel (which wasn't). I then built from stale local master, missed the PR-26/#27 merges, and would have shipped a LINK against the pre-strict validator if `/healthz` hadn't told me `ontology_version` wasn't populated. Caught only by the PR 26 feature I was about to check.

Both failures preventable by: (a) per-repo explicit `git -C <path>`, (b) reading `ontology_version` directly from `/healthz` instead of grepping features, (c) enumerating all three repos in the readback rather than just the two most obvious.

## See also

- `moos-rewrite-envelope` — envelope shapes for applying state changes after readback.
- `moos-round-close` — the end-of-round counterpart.
- `ffs0/kb/superset/running-state.md` — the living state card this skill reads.
- `ffs0/dev/reference/research-archive/20260421-t171-guido-governance-session.md` — persona context for the hp-laptop agent running this skill (archived; original session-materialisation snapshot).
