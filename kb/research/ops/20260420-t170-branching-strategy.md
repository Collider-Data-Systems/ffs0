# T=170 — branching strategy for mo:os repos

> Short operational doctrine note. Answers "should we have a branch per kernel / per workstation / per agent".
> Supersedes whatever sam has in his head that he forgot to write down.

---

## Decision

Keep the current pattern. Add no new branches. Record why.

| Repo | Branches | Purpose |
|---|---|---|
| `ffs0` | `main` only | Doctrine trunk. All machines pull + push here. Serial writes; merge conflicts rare (text, append-only sections, dated files). |
| `moos-kernel` | `master` + `agent/<machine>-<agent>/<slug>` feature branches | Sprint trunk + stacked PRs per agent. Pattern already in use T=164+. |
| `moos-router` | `feat/type-map-routing` (current feature) + `master` | Long-lived feature branches when a sprint merits one. Merge to master on close. |
| `moos-viz` | `main` | Single trunk. UI iterates too fast for branches. |

No per-kernel branches. No per-workstation branches.

---

## Why not per-kernel

Four kernel processes on Z440 (`hp-z440.primary` + federation `lola` / `menno` / `moos`) share:

- the same Go binary
- the same `ontology.json`
- the same CLAUDE.md doctrine

They differ only in:

- `--seed-ws` startup flag
- their local `moos.jsonl` log
- the URN namespace they're authoritative over

**None of those differences are git-able.** The log is gitignored per §M9 (sovereign kernels — local truth). The URN namespace is a runtime fact, not a branch fact. The seed-ws flag belongs in a per-machine launch script, not a branch.

A per-kernel branch would only carry:

- Duplicate copies of doctrine (merging becomes the work)
- Local config (belongs in gitignored files, not branches)
- Nothing else

Git is the wrong tool for replicating per-kernel state. The right tools:

- **Sessions** — the distributed-HG carrier (§M19, D22 series)
- **Router** — cross-kernel message bus via WF16
- **twin_link** — local kernel duplication for code-refresh (clarified T=169 round 10)
- **manual snapshots** — `kb/moos_from_HPLAP.jsonl`-style commits of logs into ffs0 for specific audits

---

## Why not per-workstation

Same logic less sharply. Workstations (hp-laptop, hp-z440) do share:

- ffs0 doctrine (identical)
- moos-kernel code (identical)

They differ in:

- which agents run there (claude-code, antigravity, vscode-codex — per machine)
- local kernel state (per machine, per kernel within machine)
- `.vscode/mcp.json` (already gitignored — `mcp.json.example` is the shared template)

The per-agent-per-workstation branch pattern on `moos-kernel` (e.g. `agent/hp-laptop-claude/round-9-review-followups`) already captures parallel work. No workstation-level branch adds information.

---

## When branches DO help

The existing `agent/<machine>-<agent>/<slug>` pattern is the right abstraction for **parallel feature work**:

- Each agent on each machine gets a namespace
- Stacked PRs target `master` or a parent feature branch
- Copilot/Gemini review cycle is per-branch
- Squash-merges keep `master` linear
- Closed PRs auto-delete their branches (T=169 cleanup pattern)

Practical example from T=169: hp-laptop-claude ran 9 stacked PRs under `agent/hp-laptop-claude/*`; z440-claude ran a parallel sprint under `agent/z440-claude/*`. Zero conflicts. Merge order was per-PR, not per-machine.

Scale to ffs0 if and only if parallel doctrine writing causes real merge conflicts. As of T=170 this has not happened in 170 T-days. Main-trunk serial commits are fine.

---

## The 4-z440-kernels launch problem

Sam asked: "in principe zou iedere kernel op z440 een branch hebben". No — but each kernel needs a launch invocation. This belongs in a launch script, not a branch.

Sketch for `ffs0/dev/scripts/z440-launch-kernels.ps1` (draft — sam drives):

```powershell
# Launch 4 z440 kernels, each on its own port, shared ontology + code binary.
$kernel = "D:\HPZ440\moos-kernel\moos-kernel.exe"
$ont    = "D:\HPZ440\ffs0\kb\superset\ontology.json"
$base   = "D:\HPZ440\moos-kernel"

Start-Process $kernel -ArgumentList `
  "--ontology $ont --log $base\moos-primary.jsonl " +
  "--listen :8000 --mcp-addr :8080 " +
  "--sweep-interval=30s " +
  "--seed --seed-user sam --seed-ws hp-z440"

Start-Process $kernel -ArgumentList `
  "--ontology $ont --log $base\moos-lola.jsonl " +
  "--listen :8001 --mcp-addr :8081 " +
  "--sweep-interval=30s " +
  "--seed --seed-user lola --seed-ws lola"

Start-Process $kernel -ArgumentList `
  "--ontology $ont --log $base\moos-menno.jsonl " +
  "--listen :8002 --mcp-addr :8082 " +
  "--sweep-interval=30s " +
  "--seed --seed-user menno --seed-ws menno"

Start-Process $kernel -ArgumentList `
  "--ontology $ont --log $base\moos-moos.jsonl " +
  "--listen :8003 --mcp-addr :8083 " +
  "--sweep-interval=30s " +
  "--seed --seed-user moos --seed-ws moos"
```

(Names `lola`, `menno`, `moos` are the federation kernels per running-state §Z440. Adjust seed-user and seed-ws if the convention differs.)

**One script, four kernels, no branches.** Each kernel's log lives at its own path; git ignores them; sessions + router handle cross-kernel coordination at runtime.

---

## "The not-complicated complexity solution" — candidate reconstructions

Sam mentioned he had a solution in mind but forgot. Possible candidates, ordered most-to-least-likely:

1. **Per-agent-per-workstation branches on moos-kernel** (the already-current pattern). Sam may have been re-deriving from first principles what was already shipped.
2. **Per-kernel launch scripts** (the section above). Captures the "each kernel has its own X" intuition in the right artifact.
3. **Kernel-specific ontology overlays** — a fork of ontology.json per kernel for experimental feature gating. **Rejected**: v3.X ontology is shared truth; feature gating belongs in capability nodes (WF02), not branches.
4. **Federation via git-merge of logs** — append-only JSONL merged between branches. **Rejected**: JSONL ordering is not mergeable; HLC is the right structure, and it's runtime, not git.

If the forgotten idea was (3) or (4), the present note argues against it. If (1) or (2), we're already there.

If none of the above, sam can annotate this file when the idea resurfaces and the note mutates.

---

## Cross-references

- `ffs0/CLAUDE.md` — multi-workstation git-flow prompt pointer
- `ffs0/.github/prompts/multi-workstation-git-flow.prompt.md` — if it exists, the operational incantation
- `kb/superset/running-state.md` §Architecture — the port/kernel layout
- §M9 in `kb/research/kernel/20260417-t187-kernel-proper.md` — sovereignty doctrine
- Commit pattern `T=<N> round <M.K>: <scope>` — used consistently in git history
