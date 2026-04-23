# T=169 conversation cleanup + handoff

Sam's direction (T=169 ~13:00 CEST): conversation is bloated, land cleanup.

## Execute

1. Move + rename `~/.claude/plans/t167-next-natural-step-purrfect-crayon.md` → `ffs0/kb/research/t169plan_claude_HPlap.md`. Before move, strip the retracted federation plan and keep only the "sessions is next" brief for the z440 handoff context.
2. Write conversation summary → `ffs0/kb/research/t169_conv_sum_claude_HPlap.md`. Scannable. Covers: round 8 HG hydration recap → Claude tooling (skills, jq, memory) → 9 merged moos-kernel PRs (#9,10,11,12,13,14,15,16,17-22 v2s,23,24,25) + ffs0 #31 v3.10 + #32 v3.11 → Z440 catch-up from T=164 → §M9 misread + Sam's correction → "sessions" as the next direction, flavour TBD.
3. Copy all files from `~/.claude/projects/C--Users-maass-HPlaptop/memory/` → `ffs0/kb/research/` (MEMORY.md, user_sam.md, project_moos.md, project_prg_naming.md). Prefix with `t169_memory_` to avoid collision with running kb content.
4. Update ffs0 top-level instruction files to current state:
   - `CLAUDE.md`: bump ontology line from "v3.8, 42 node types, 19 WFs" → "v3.11.0, 52 types, 20 WFs"; note T=169 hydration entrypoint unchanged.
   - `ANTIGRAVITY.md`: same bump (or point at CLAUDE.md if that's the shared-content pattern).
   - `.github/copilot-instructions.md`: read first, then sync any ontology/version references.
5. Update `moos-kernel/CLAUDE.md`:
   - ontology line → v3.11.0, 52 types, 20 WFs
   - rewrite_category range → WF01–WF20
   - package structure — add `internal/tday` (T=169)
   - testing section — add `sweep_test.go`, `predicate_test.go`, `predicate_extended_test.go`, `occupancy_test.go`, `tcone_test.go`, `thook_test.go`, `state_test.go`, `tday_test.go`
   - CLI flags — add `--sweep-interval`, `--quic-addr`, `--tls-cert`, `--tls-key`
6. Clean stale files at `moos-kernel/` root: remove `moos-kernel.exe~` and any leftover temp JSON (e.g. the `"C\357\200\272..."` encoded filename).
7. Commit + push both repos.
   - ffs0: `T=169: conversation cleanup + research notes + instruction refresh`
   - moos-kernel: `docs(CLAUDE.md): refresh to T=169 / v3.11 / 20 WFs; clean stale artifacts`
8. Open GitHub issue referencing `claude-z440`. Title: `Round-10 sessions work — handoff from hp-laptop`. Body: point at the 3 new research notes in ffs0, summarise what's decided vs open, list the 3 concrete next candidates (doctrine note / session mobility / export-import / access control). Address to claude-z440 so the z440 IDE agent can pick it up.

## Notes

- Plan mode prohibits execution — I must ExitPlanMode after writing this file.
- No new code, no new PRs on kernel. Pure housekeeping + docs + handoff.
- Stale-file cleanup uses `git clean -f` ONLY on untracked files I've personally identified (the exe~ and the temp JSON). No `-d`, no destruction of anything tracked.
- Issue goes on the `ffs0` repo (the shared private workspace) unless sam prefers `moos-kernel` public — will confirm at execution if ambiguous.
