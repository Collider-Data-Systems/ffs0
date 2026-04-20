---
name: moos-state-readback
description: Use this skill at the start of any mo:os working session before claiming state is "crisp" or planning a round. Performs the 10-second readback: `git fetch` on ffs0 + moos-kernel, diffs against origin, reads running-state.md header, checks hp-laptop kernel process + ports, pings MCP, lists open `ffs0#33` (and any other pinned handoff issue) comments. Answers "am I up to date?", "is the kernel up and on what ontology version?", "has the peer agent pushed anything I should pull?". Trigger whenever a new conversation opens in one of the mo:os workspaces (`C:\Users\maass\HPlaptop\ffs0`, `moos-kernel`, `moos-router`, `moos-viz`), or any time you are about to make a claim about "is hp-laptop crisp".
---

# mo:os state readback

The 10-second "where are we" dance. Run it before any round. Without this, local `git status` lies by omission — see T=170 round 10.5 in running-state where a skipped fetch cost the hp-laptop agent a plan revision.

## What to check (in parallel)

Run these in a single message with parallel `Bash` calls. Nothing here modifies state — all read-only.

### 1. ffs0 fetch + divergence

```bash
cd /c/Users/maass/HPlaptop/ffs0
git fetch --all --prune 2>&1
git status -uno
git log --oneline origin/main -10
# If behind: the number of missing commits and their messages
```

Expected: clean wd, `up to date with origin/main`, recent commits visible. If "behind by N commits", **you are not crisp** — plan a pull first.

### 2. moos-kernel fetch + divergence

```bash
cd /c/Users/maass/HPlaptop/moos-kernel
git fetch --all --prune 2>&1
git status -uno
git log --oneline origin/master -10
```

### 3. Running-state header

```bash
head -10 /c/Users/maass/HPlaptop/ffs0/kb/superset/running-state.md
```

The header line after `> Updated:` tells you the last T-day update and what's in flight. Compare its T-day against today's.

### 4. Kernel process + MCP liveness

```bash
tasklist | grep -Ei 'moos|cloudflared'
netstat -ano | grep -E 'LISTENING.*:(8000|8080|9000|4433)' | head -20
```

Expect PID on `:8000` (transport) + same PID on `:8080` (MCP). Extra `moos-kernel.exe` PIDs with no port bindings = leftover dev processes, ignore.

Then MCP ping:

```bash
curl -sS http://localhost:8000/healthz
```

Returns `{"log_len": N, "status": "ok", "t_day": T}`. If fails: kernel not up; note it and decide whether to restart (destructive — needs owner OK).

### 5. Ontology delta: runtime vs on-disk

```bash
# Quick v3.12 marker — if present in runtime, kernel is on v3.12+
curl -sS http://localhost:8000/operad/node-types 2>&1 | grep -o '"version":"[0-9.]*"' | head -1
grep -o '"version": "[0-9.]*"' /c/Users/maass/HPlaptop/ffs0/kb/superset/ontology.json | head -1
```

Runtime < on-disk → kernel needs a restart to pick up the bump.

### 6. Peer-agent handoff issue(s)

```bash
cd /c/Users/maass/HPlaptop/ffs0
gh issue list --state open --limit 10
# If a specific handoff issue is live:
gh issue view 33 --comments
```

Comments from peers on the current handoff issue reveal what they shipped and what's queued for you.

## Reporting shape

After the parallel batch, synthesize a 5-line summary:

```
ffs0:     <ahead|behind|clean> by N — <summary of latest commit>
kernel:   <ahead|behind|clean> — master tip <sha> <short msg>
running:  header T=<day>, <in-flight note>
kernel 0: PID <pid> on :8000/:8080 — ontology v<runtime> (on disk v<disk>)
handoff:  ffs0#<N> has <M> new comments from <peer>
```

## When to pull

- Fast-forward safe (`Your branch is behind by N commits, can be fast-forwarded`) + you have no local WIP: **`git pull --ff-only` and continue**.
- Divergent (local commits ahead of origin + remote ahead): **plan a merge or rebase; don't auto-pull**.
- Clean + up to date: nothing to do.

## What this skill does NOT do

- Doesn't restart the kernel (destructive; owner-approval required).
- Doesn't pull automatically (owner-approval for any state change).
- Doesn't write anything — read-only by design.

## Why it exists

T=170 opener: local `git status` showed "up to date" because tracking branches weren't refreshed. `ffs0` was actually 7 commits behind origin (z440-claude had shipped Round 10 overnight). Caught by Sam's "please check git" nudge, at the cost of one plan-file revision. This skill is the unprompted version of that nudge.

## See also

- `moos-rewrite-envelope` — envelope shapes for applying state changes after readback.
- `moos-round-close` — the end-of-round counterpart.
- `ffs0/kb/superset/running-state.md` — the living state card this skill reads.
