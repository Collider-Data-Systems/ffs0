# T=169 round 10 → round 11 — plan for the fresh conversation

> Written at round-10 close (Conversations A–D done). For whichever claude-code IDE conversation picks this up next.
> Companion: `t169round10_conv_sum_claude_z440.md` (what happened so far).
> Full plan (still authoritative): `C:/Users/hp/.claude/plans/1-if-specs-are-parsed-jellyfish.md`.

---

## Hydration — read in this order before doing anything

1. `kb/superset/running-state.md` — especially the header + §"T=169 round 10 — session generalization" + Key URNs.
2. `kb/research/t169round10_conv_sum_claude_z440.md` — what the previous conversation did + corrections accumulated.
3. This file — what you do next.
4. `kb/research/session/20260419-t169-session-generalization.md` — round-10 doctrine note (canonical session model).
5. `C:/Users/hp/.claude/plans/1-if-specs-are-parsed-jellyfish.md` — full round-10 plan (Conversations A–E). Conversations A/B/C/D are done; E is the round-11 work below.

Optional / reference:
- `moos-kernel/internal/operad/loader.go` — the file that needs extension for `additional_port_pairs` awareness (Conversation E PR 0 or embedded in PR 1).
- `moos-kernel/internal/operad/occupancy.go` + `occupancy_test.go` — where RotateSessionOccupant lives + its tests.
- `moos-kernel/CLAUDE.md` — kernel repo instructions.

## Decision 1 — kernel restart approval (destructive, needs explicit OK)

Z440 kernel 0 (PID 23896) is running the v3.11 ontology. Ontology on disk is v3.12 (pushed). Kernel has no hot-reload path. To pick up v3.12:

```bash
taskkill //PID 23896 //F
cd /d/HPZ440/moos-kernel && ./moos-kernel.exe \
  --ontology /d/HPZ440/ffs0/kb/superset/ontology.json \
  --log /d/HPZ440/moos-kernel/moos.jsonl \
  --listen :8000 \
  --mcp-addr :8080 \
  --sweep-interval=30s \
  --seed --seed-user sam --seed-ws hp-z440 \
  > /d/HPZ440/moos-kernel/startup-T169-v312.log 2>&1 &
```

**Fresh conversation asks sam before running this.** Don't restart silently.

**Expected startup log after restart:**
- `operad: loaded 52 node types, 20 rewrite categories` (type count unchanged — v3.12 adds 3 port pairs + 2 properties, no new types)
- `runtime: replayed 192 rewrites` (Z440's log count at round-10 close)
- `sweep: starting (interval=30s)`
- `transport: listening on :8000`
- `mcp: listening on :8080`
- No schema errors.

**Post-restart verification:**
- `curl http://localhost:8000/healthz` → `{"log_len": 192, "status": "ok", ...}`
- `curl http://localhost:8000/state/nodes/urn:moos:session:hp-z440.primary` → returns the birth-session.
- Spot-check a v3.12 addition: `curl http://localhost:8000/operad/node-types | grep invocation_protocol` → finds the new agent property.
- `curl http://localhost:8000/operad/rewrite-categories | grep -A3 WF19` → WF19 with `additional_port_pairs` listed (but loader probably still only validates the primary pair — that's the known gap).

**If restart succeeds**: commit a brief marker: `T=169 round 10: Z440 kernel on v3.12 ontology`. No ffs0 file changes needed beyond maybe updating the running-state header's "kernel at runtime" line.

**If restart fails** (schema error on v3.12): diagnose. Possible causes: JSON syntax error I missed, ontology loader rejecting `deprecated: true` markers I added, fragment-reference IDs not matching existing fragments. Roll forward by fixing, not by reverting to v3.11.

## Decision 2 — scope of the fresh conversation

Pick one:

**Option A — Minimal (30 min)**: just the restart + verification + marker commit. Clean close of round 10's operational side. Round 11 starts in a later conversation.

**Option B — Opener-for-round-11 (~90 min, recommended if context allows)**: restart + verify, then open Conversation E PR 1 on moos-kernel:

- Branch: `feat/t187-session-occupancy-rotate`
- File changes: `internal/operad/occupancy.go` gains `RotateSessionOccupant(state, sessionURN, newPrincipalURN) (graph.Envelope, error)` helper + its validation logic. `internal/operad/occupancy_test.go` gets rotation tests (happy path; double-occupant rejected if D22.2 invariant code lands; new principal is user/agent).
- Commit message: `feat(t187/session-occupancy): RotateSessionOccupant + rotation validator`
- Open draft PR, link it in running-state via a brief append.

**Option C — Full Conversation E (multi-conversation, several hours)**: all 4 stacked PRs (rotate, liveness, admin-cap, HTTP endpoint). Probably wants its own conversation-per-PR for context hygiene. Don't attempt in one shot.

Default choice: **Option B**. Delivers visible round-11 progress while keeping the scope bounded. If sam says Option A, stop at the restart.

## Work items (ordered checklist)

### Round-10 close (all options)

- [ ] Ask sam for restart approval; show the exact command.
- [ ] Execute restart only after explicit OK.
- [ ] Verify startup log matches expectations.
- [ ] Commit `T=169 round 10: Z440 kernel on v3.12 ontology` on ffs0 main (if any running-state header tweak is needed; otherwise no commit — the log-on-disk IS the change record).
- [ ] Optionally: push a small running-state header update reflecting "Z440 kernel on v3.12.0 — PID <new>".

### Round-11 opener (Option B)

- [ ] Read `moos-kernel/internal/operad/occupancy.go` to understand the existing `ResolveSessionOccupant` shape.
- [ ] Read `moos-kernel/internal/graph/` for Envelope structure (relation_urn, src_port, tgt_port fields used for WF19 LINKs).
- [ ] Read `moos-kernel/internal/operad/loader.go` to see if `additional_port_pairs` needs multi-port-pair awareness right now, OR if `RotateSessionOccupant` can work via the primary WF19 pair for this PR and the loader extension comes as a separate PR.
- [ ] On branch `feat/t187-session-occupancy-rotate` in moos-kernel: write `RotateSessionOccupant` + tests, `go build ./...` clean, `go test ./...` green, push, open draft PR targeting `master`. Wait for CI/Copilot/Gemini reviews before merging.
- [ ] Update ffs0 running-state with a PR link, commit + push.

### Round-11 later (Option C, or follow-up conversations)

- [ ] Conversation E PR 2: §M11 liveness check in runtime.Apply.
- [ ] Conversation E PR 3: §M12 admin-cap gate extended via has-occupant chain.
- [ ] Conversation E PR 4: `GET /session/<urn>/occupant?at=T` endpoint.
- [ ] Post-merge: MUTATE `program:sam.session-occupancy` `status=draft → active` (→ `completed` after all 4 PRs).

## Explicitly deferred (do NOT do in fresh conversation)

- **hp-laptop-side retrofits**: UNLINK mis-classified `session:sam.claude-code-hp-*` + ADD `session:hp-laptop.primary` + HG status MUTATEs on D19.2/3/4, D20.1/2 fragments. Those nodes live only on hp-laptop kernel. A hp-laptop-driven claude-code conversation does that work. Z440 fresh-conversation should not touch them (cross-machine action with no authority on hp-laptop's kernel state).
- **Reading B / D22.5** (host-as-platform generalization — adds `platform` as non-mo:os host type): premature. Only needed when we actually integrate with Google ADK / Anthropic workspace / external MCP daemon. Round 11 doesn't touch this.
- **v310-13 purpose-arity2**: structural change to purpose. Post-round-11 when operational experience with purpose at t-cone read time exists.
- **Federation kernels 1-3 upgrade** (lola, menno, moos on Z440 :8001-:8003): dormant on pre-T=164 code. Not in scope until federation testing resumes.
- **Cos-similarity wiring-proposer** (target_t=250): far future.

## Open questions (do not solve — just be aware)

- Should D22.1 `has-purpose` land in WF19 extended or a new WF21? Promotion-ceremony decision, not design-ahead. Round 11 doesn't promote D22.* so this stays open.
- Should `additional_port_pairs` loader extension be its own PR or folded into Conversation E PR 1? PR 0 standalone is cleaner but delays PR 1; folding keeps the sub-program shape. Pick during PR 1 drafting.
- Should `session.seat_role` actually be removed in a future round (v3.13 per the v3.12 deprecation note) or left as legacy-validating-ignored? Post-Conversation-E, when code clearly no longer reads it.

## Fresh-conversation prompt template

```
Continue round 10 / round 11 work per
D:/HPZ440/ffs0/kb/research/t169round10_next_plan.md. Read it first,
then the files it lists in the hydration order. Then ask me about the
kernel restart before doing anything destructive.
```

That's the handoff trigger. Paste into a fresh claude-code IDE panel on Z440 (or wherever you drive from).
