---
name: moos-round-close
description: End-of-round cleanup: running-state update, single atomic commit+push on ffs0 (and moos-kernel if touched), optional handoff issue comment. Use when a round is done and about to be declared shipped.
---

## When to use (routing detail)

Use this skill at the end of a mo:os round — after the HG rewrites have landed via MCP and any research/doctrine notes are written — to perform the cleanup+commit+push+issue-comment dance cleanly. Handles running-state update, single atomic commit on ffs0 (and moos-kernel if touched), push, and optionally a handoff issue comment notifying peer agents. Catches the "did I forget to update running-state / post the handoff" issue. Trigger whenever a round's work is done and you're about to declare it shipped.

# mo:os round close

The shape of every round's closing ritual. Runs as a small checklist; each step is skippable if already done.

## Preconditions

- HG rewrites (if any) have landed via `mcp__moos-kernel__apply_program` and you've verified affected URNs via `node_lookup`.
- Research / doctrine notes (if any) are written under the active design lane (e.g. `dev/design/manifold-bump-4_0/`) with dated filename (`YYYYMMDD-t<N>-<slug>.md`) — `kb/research/` is retired (archive: `dev/reference/research-archive/`).
- `git status` on the repo(s) you touched shows the intended changes, nothing accidentally staged.

## Steps

### 0. Seat-table drift gate (BLOCKING — #58 Phase-4)

```bash
python dev/scripts/projections/config_projection.py --mode check
```

Exit 0 required to proceed. On FAIL the resolution is **regenerate, never hand-edit**:
`python dev/scripts/projections/config_projection.py --mode write`, review the `AGENTS.md`
diff, include it in this round's commit. (The generated seat table is the fenced region in
`AGENTS.md`; authority spine = HG `/state` via the router fan-in — spec
`dev/design/manifold-bump-4_0/20260620-t231-moos-config-projection-spec.md` §4.)

### 1. Update `kb/superset/running-state.md`

Minimum required edits:

- **Header `> Updated:` line** — bump T-day + add a 1-sentence summary of what this round shipped.
- **Ontology block** — if the ontology version (v4.x) was bumped, update `runtime` vs `on disk` in the Kernel — hp-laptop section.
- **New "T=N round M — <slug>" section** inserted before `## MVP delivery` (or whatever section is the chronological next-newer marker) with:
  - Date + CEST timestamp
  - 1-paragraph framing of what the round was
  - Table of rewrites landed (envelope type + count + summary)
  - "Explicitly not done / deferred" sub-section with rationale
  - Kernel stats delta
- **Key URNs section** — add any new URNs (sessions, programs, grammar_fragments, etc.) under a dedicated subheader for this round.
- **If a prior section had `(in progress)` in its title — change to `(closed)`.**

Do NOT re-write the whole file. Scoped edits only.

### 2. Verify the diff

```bash
git -C <repo> diff --stat
git -C <repo> diff <path> | head -80
```

Sanity-check: no stray `\r\n`, no accidental deletions, section inserts land where intended.

### 3. Commit (single atomic commit per repo)

Commit message shape:

```
T=<N> round <M.K>: <short-verb> <scope>

<1-2 paragraphs of what + why>

- bullet 1
- bullet 2
- bullet 3

<optional "Explicitly deferred" paragraph>

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
```

HEREDOC format for well-formed multi-line:

```bash
git -C <repo> add <path(s)>
git -C <repo> commit -m "$(cat <<'EOF'
T=... round ...: ...

<body>

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

**Rules**: never commit `ffs0/secrets/`, `.vscode/mcp.json`, or build artifacts (`moos-kernel*.exe`). Prefer `git add <path>` over `git add -A`.

### 4. Push

```bash
git -C <repo> push
```

If push rejected (remote ahead): **stop** and do a `moos-state-readback` first. Don't force-push without explicit owner OK.

### 5. Handoff issue comment (optional — when passing work to a peer agent)

If this round delivered prerequisites for a peer (e.g. hp-laptop → z440-claude or vice versa):

```bash
gh issue comment <N> --body "$(cat <<'EOF'
<Peer-name> side <round-slug> landed — ffs0 commit [`<sha>`](https://github.com/Collider-Data-Systems/ffs0/commit/<sha>).

<what shipped — bullet list of the 3-5 key moves>

<what's deferred / what the peer should pick up next>

— claude-<host>, T=<N> ~<HH:MM> CEST
EOF
)"
```

Keep it actionable: the peer agent should be able to read it and know exactly what to do next.

### 6. Update the session todo list

Mark all gates completed. Clear stale entries. This isn't user-facing but helps the next conversation pick up cleanly.

### 7. Final readback

```bash
git -C <repo> log --oneline -3
```

Confirm your commit is the tip. If you pushed, the remote tracking branch should match.

## When you wouldn't run this

- The round had no HG rewrites and no ffs0 changes (purely conversational). No close needed.
- Mid-round — save the cleanup for the actual close.
- Peer agent is already actively running their close — wait for them to finish (avoids double-commits on running-state).

## Common failure modes

| Symptom | Cause | Fix |
|---|---|---|
| `push rejected (non-fast-forward)` | Peer pushed between your fetch and your push | `git pull --rebase` or re-run `moos-state-readback`, then re-commit |
| `pre-commit hook failed` | Lint or format check rejected | Fix the flagged issue, re-stage, commit as a **NEW** commit (never `--amend` after a hook failure — that modifies the wrong commit) |
| Running-state header wrong T-day after edit | Typo or stale paste | Scoped `Edit` fixing only the header line |
| Commit body too long / formatting lost | Used `git commit -m "..."` with inline newlines | Use the HEREDOC form above |
| `gh issue comment` errors | Not authenticated or wrong repo | `gh auth status`; cd to the right repo first |

## Why it exists

T=170 round 10.5 opener: the previous close-round was done ad-hoc; key URNs section missed the `session:hp-laptop.primary` birth-session URN on first pass until caught on diff review. This skill is the checklist so future rounds don't need the second pass.

## See also

- `moos-rewrite-envelope` — envelope shapes (should already be applied before this skill runs).
- `moos-state-readback` — the open-of-round counterpart.
- `ffs0/kb/superset/running-state.md` — the target artifact this skill updates.
