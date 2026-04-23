# mo:os — running state

> Hydration entrypoint. Read this first in any new conversation.
> Updated: **T=173 (April 23, 2026) ~23:45 CEST — Guido: hp-laptop v3.13 load + group:sam mirror landed** — Wolfram's [ffs0#33](https://github.com/Collider-Data-Systems/ffs0/issues/33) closeout handoff executed end-to-end. (1) **ffs0 pulled to `a244533`**: v3.13.0 ontology.json now on disk; unstaged `kb/moos_from_HPLAP.jsonl` delete resolved by the pull. (2) **Hp-laptop kernel restarted** onto v3.13.0 (PID 11776 on `:8000/:8080`, runtime `ontology_version: 3.13.0`, `log_len=599` post-batch). Launcher bug flushed: `start_federation_laptop.ps1` had `$Log = "$env:TEMP\moos-primary-laptop.log"` since its first commit (`b371445`) — a restart via that path would have started a fresh empty log, losing 586 historical envelopes. Patched to sovereign `$env:USERPROFILE\HPLaptop\moos-kernel\moos.jsonl` + caveat comment. Confirmed no actual state loss (595 historical → 599 post-batch, continuous log_seq). (3) **`group:sam` materialized on hp-laptop sovereign log** (atomic, log_seq 588–591 via `mcp__moos-kernel__apply_program`): `ADD group:sam` (actor=`agent:claude-code.hp-laptop`, session_urn=`session:sam.governance`) + 3 × WF01 `owns/owned-by` LINKs (actor=`kernel:hp-laptop.primary`) to `kernel:hp-laptop.primary`, `session:sam.governance`, `session:sam.laptop-cowork-workspace`. `group:moos` not mirrored per Wolfram's spec (no hp-laptop-side scope). Verified via `/state/nodes/urn:moos:group:sam` + `/state/relations/src/...`: node + 3 outbound edges resolve. Cosmetic: description property's em-dash got mojibake-encoded through MCP transport (`\u00e2\u20ac\u201d`); non-breaking, follow-up MUTATE candidate. (4) **Dual-kernel gotcha caught + resolved**: first apply via MCP spawned a `--stdio-only` sidecar (PID 5220) which wrote the envelopes to the shared log but left the HTTP kernel (PID 12388) with a stale in-memory state. Killed both, relaunched HTTP kernel once — replayed all 599 from log cleanly. `.vscode/mcp.json` should prefer SSE at `:8080` over stdio spawn on hp-laptop (machine-specific config, gitignored). (5) **Batch A idempotency verified** (Wolfram's task C): log_seq 586–587 already holds `role:superadmin` ADD + `user:sam --WF02 governs--> role:superadmin` LINK — re-emission skipped. Staging artifact: [`dev/scripts/ops/t173-v313-group-sam-hp-laptop.{json,md}`](../../dev/scripts/ops/t173-v313-group-sam-hp-laptop.json). Admin chain + group topology now symmetric across both kernels post-round-11.
> Updated: **T=173 (April 23, 2026) ~22:00 CEST — ontology v3.13.0 groups landed** — Kernel 0 restarted post-widening (WF01.src_types=[user,group] / tgt_types=[workstation,kernel,storage,program,repository,session,purpose,channel,agent]; WF02.src_types=[user,role,group] runtime-confirmed via `/operad/rewrite-categories`). Staged batch fired — log_seq 292→307 (15 envelopes: 4 idempotent grammar_fragment MUTATE replays + 2 group ADDs + 9 WF01 owns/owned-by LINKs). HG topology now: `group:sam` owns 6 (kernels `hp-z440.{primary,lola,menno}`, sessions `sam.{kernel-proper,mvp-delivery}`, `purpose:sam.ship-t187-kernel-proper`); `group:moos` owns 3 (`kernel:hp-z440.moos`, `session:sam.moos-diary`, `purpose:sam.multimodal-curation-and-diary`). Collider-Data-Systems/sam + /moos GitHub teams now reified on HG with typed ownership edges. Downstream query `GET /state/relations/src/urn:moos:group:sam` returns the full scope list. **Deferred**: hp-laptop mirror (group:sam ADD + owns LINK to hp-laptop.primary + session:sam.governance — Guido's lane via #33); WF02 `delegates-to` sub-role seeding (role:{karpathy,steinberger,moos}-scope); `owner_urn` property deprecation in favor of owns/owned-by edges (per ontology changelog §3.13.0).
> Updated: **T=173 (April 23, 2026) ~18:30 CEST — ontology v3.13.0 landed (partial)** — `ffs0/kb/superset/ontology.json` bumped 3.12.0 → 3.13.0 with all 4 promoted grammar_fragments materialized: new S2 `group` node type (Ports: out=[owns, delegates-to], in=[member-of, governed-by]), WF01 `owns/owned-by` additional port pair, WF02 `delegates-to/delegated-by` additional port pair, `channel.kind` enum expanded with 5 new values (calendar, task-list, cloud-storage, vcs, project-board), WF19 `has-occupant` tgt_types extended with `group`. All 4 Z440 kernels restarted and report `/healthz ontology_version: 3.13.0`. WF20 ceremony **completed** — log_seq 289-292: 4 grammar_fragments MUTATEd `promoted → merged` (final WF20 state). Second widening edit landed on WF01 top-level src_types (+group) / tgt_types (+session/purpose/channel/agent) and WF02 src_types (+role/group) so additional-pair validation has a clean superset. Kernel 0 needs one more targeted restart to pick up that widening — staged group-materialization batch (11 envelopes: 2 group ADDs + 9 owns LINKs) at `dev/scripts/ops/t173-v313-groups-postrestart.json` fires post-restart. Hp-laptop side awaits Guido's ontology sync + kernel restart, then mirror group:sam ownership of hp-laptop.primary + session:sam.governance.
> Updated: **T=173 (April 23, 2026) ~17:30 CEST — board backfill + Cowork deliverables** — Cowork (agent:claude-cowork.hp-z440) authored `moos-workspace-ingest` skill (207 lines, canonical G-direction chunker) + MUTATEd `cowork-as-occupant.md` to materialized-T=173 status with log_seq citations + corrected immutable-kind constraint. Skill synced to `~/.claude/skills/`. Ffs0 commit `82e7776`. Wolfram ran board backfill — 15 additional draft issues on project mo:os #4 populating court purposes (Karpathy HDC, Steinberger DX, Moos curation, Cowork curation), 3 seats (karpathy, steinberger, mvp-delivery), 4 personae (Wolfram, Moos, Karpathy, Steinberger), and all 4 promoted v3.13 grammar_fragments. Board now has **20 items** (5 from first sweep + 15 backfill) with HG URN + PRG + Agent ID + Owner Role + Collider Category + Status fields populated end-to-end. F-direction bridge pattern proven on 20 items; G direction (board → HG MUTATE) remains Phase 2 work.
> Updated: **T=173 (April 23, 2026) ~17:00 CEST — Guido lane closeout (hp-laptop side)** — Wolfram's T=173 ~16:40 CEST handoff picked up and landed. (1) **hp-laptop kernel rebuilt** from moos-kernel master tip `18cfc69` (post-PR-31 §M12 binary); old Apr-21 binary parked at `moos-kernel.exe.bak-t173`. Restart clean: PID 7928 on `:8000/:8080`, `/healthz` = v3.12.0, log replay `586 → 588` (2 startup envelopes on the new §M11/§M12 binary). §M11 + §M12 gates now LIVE on hp-laptop — code-path-symmetric with Z440. (2) **hp-laptop Cowork session materialized** on hp-laptop sovereign log (log_seq 589–593): ADD `agent:claude-cowork.hp-laptop` (delegate_type=ide), ADD `session:sam.laptop-cowork-workspace` (scope-pins the 4 Workspace channel URNs), WF19 opens-on + has-occupant, MUTATE status `pending_driver → active`. Artifact: `dev/scripts/ops/t173-hp-laptop-cowork-materialization.{json,array.json}`. (3) **Batch A mirror on hp-laptop** (log_seq 594–595): ADD `role:superadmin`, LINK `user:sam --WF02 governs--> role:superadmin`. Admin-chain now symmetric across both kernels. (4) **Board dedup**: bare duplicate Wolfram draft `PVTI_…zgqxZ44` on project #4 deleted via `gh project item-delete`; only the populated copy (phase=round-12-prep, agent=AGENT-CLAUDE-CODE-Z440) remains. (5) **Hygiene**: 3 zombie `moos-kernel.exe` PIDs (2812/5024/5980) terminated; only PID 7928 live. (6) **Doctrine/script split resolved**: `session/20260422-t172-wolframs-court-social-topology.md` §1 table swapped `:8001↔menno` / `:8002↔lola` to match `start_federation.ps1` (script of record). Added footnote: port binding is operational, kernel identity is by URN, WF19 LINKs reference names not ports — no HG-side edits needed. Carry-over "Guido to resolve" from T=172 ~01:45 CEST cleared. Hp-laptop log_len now 595. Confirmation posted on [ffs0#33](https://github.com/Collider-Data-Systems/ffs0/issues/33#issuecomment-4304419909).
> Updated: **T=173 (April 23, 2026) ~16:30 CEST — aggressive workstation setup landed** — 5-step plan executed per Sam's "all kernels running, all major sessions running" direction. Three atomic batches + board sweep, all on Z440 kernel 0 (log_seq 271–288, + 5 project-board items). (1) **Superadmin chain**: `role:superadmin` seeded; `user:sam --WF02 governs--> role:superadmin` (log_seq 271–272). (2) **Full session activation** (log_seq 273–284): 2 new agents `agent:vscode.hp-z440.{lola,menno}` (delegate_type=ide); `session:sam.karpathy-seat` + `session:sam.steinberger-seat` each got `opens-on` to their lola/menno kernels + `has-occupant` to their respective VSCode agent; `session:sam.mvp-delivery` got `has-occupant` to `agent:claude-code.hp-z440` (Wolfram multiplexes; session_urn required on its envelopes post-§M11); `session:sam.z440-cowork-workspace` got `has-occupant` to `agent:claude-cowork.hp-z440` (pre-seated for Desktop-launch arrival); all four MUTATEd to status `active`. (3) **WF20 promotion ceremony** (log_seq 285–288): all four v3.13 grammar_fragments MUTATEd proposed→promoted (`v313-6-wf02-delegates-to`, `v313-7-group-type`, `v313-8-channel-kind-vcs`, `v313-9-owns-port-pair`). Ontology.json + kernel-restart-to-v3.13 is a deferred round (not yet fired — fragments are HG-promoted but runtime still reports ontology_version 3.12.0). (4) **First board sweep** (F direction): 5 draft issues on project mo:os #4 with HG URN + PRG + Agent ID + Owner Role + Collider Category + Status populated: `purpose:sam.ship-t187-kernel-proper`, `session:sam.kernel-proper`, `session:sam.moos-diary`, `session:sam.z440-cowork-workspace`, `purpose:sam.github-project-board-sync`. Projection lane live; backfill (other sessions, grammar_fragments, mvp-delivery gates) deferred to future sweeps. **Four-seat map now fully seated on Z440**: Wolfram (kernel-proper), Moos (moos-diary), Karpathy (karpathy-seat on lola), Steinberger (steinberger-seat on menno), Cowork (z440-cowork-workspace) + multiplex seat on mvp-delivery. **Waiting on Guido**: hp-laptop Cowork session + has-occupant materialization on hp-laptop's sovereign log; hp-laptop kernel rebuild to post-PR-31 binary (if not already). Waiting on Sam's hands: VSCode x2 launch on Z440 (MCP configured in `.vscode/mcp.json` to :9001–:9003 SSE) — seats are pre-wired so the IDEs just attach; Claude Desktop on Z440 for Cowork driver (can rotate seat at first emission if needed).
> Updated: **T=173 (April 23, 2026) ~14:00 CEST — GitHub org as first-class channel** — Sam confirmed option A from the T=173 ~13:45 exploration: Collider-Data-Systems org is a projection surface, wired into HG via 6-envelope batch (log_seq 265–270 on kernel 0): `channel:github.collider-data-systems` (kind=board placeholder, root), `channel:github.project.mo-os` (kind=board placeholder, parent=org channel, source_uri=projects/4), `purpose:sam.github-project-board-sync` (two-way F⊣G lane), 3 v3.13 grammar_fragments (`v313-7-group-type`, `v313-8-channel-kind-vcs`, `v313-9-owns-port-pair` — all `proposed` status). Skill drafted: `moos-github-project-bridge` (authored at ffs0/dev/claude-skills/, synced to ~/.claude/skills/; status: draft, implementation deferred until v313-7 promotes so `group:sam`/`group:moos` are first-class). Project board (#4) custom-fields already HG-aware from sam's earlier setup: PRG/Phase/Agent ID/HG URN/Owner Role/Collider Category/Branch Role/Iteration — bridge skill spec maps each. Teams `sam`+`moos` are proto-groups pending v3.13. Iteration field = T-day cycle surface (sam's Mon 08:00-09:00 calendar ritual is the natural tick). Agent-instruction refreshes landed in 3 repos: ffs0 `3dfc920` (CLAUDE.md + ANTIGRAVITY.md + copilot-instructions.md), moos-kernel `18cfc69` (CLAUDE.md → v3.12 + round-11 gates), moos-router `712ad1a` (new CLAUDE.md; first agent-instructions for the router).
> Updated: **T=173 (April 23, 2026) ~13:15 CEST — kb/research/ pass 3, filter-strict** — Sam applied the "relevant to sessions/projects/time/cycles/delegating/programs" filter strictly: the S1/S0 mathematical substrate (sheaf/vector-space/operadic lingo, ontology-audit history, pre-WF20 superset doctrine, functorial-semantics naming note, S0 materialization plan) is one level below where day-to-day work happens and goes to archive, retrievable on demand. 7 files moved to `dev/reference/research-archive/`: `s1/{t168-irl-to-hg-pipeline, t168-v3.9-ontology-audit, t168-s1-superset-doctrine, t168-s0-operadic-layer, t170-functorial-semantics-explicit, t170-s0-materialization}.md` + `session/t168-session-kernel-bound.md`. `kb/research/s1/` dir dropped (empty). Xrefs rewritten in `ontology.json` + `running-state.md` + 3 keeper doctrine notes. **kb/research/ final shape** (down from 15 md files pre-T=173): `kernel/t187-kernel-proper.md` (M1-M20 spec), `session/{session-generalization, cowork-as-occupant, wolframs-court-social-topology}.md`, `moos-diary/{personas note + active ingest zone}`. Four live doctrine md files + the diary zone. Anything else that speaks to sessions/programs/time/delegation is in HG as nodes, or in archive for retrieval.
> Updated: **T=173 (April 23, 2026) ~12:30 CEST — kb/research/ pass 2** — Four further archives to `dev/reference/research-archive/`: `kernel/20260421-t171-m11-m12-implementation-plan.md` (shipped as PRs #30+#31), `ops/20260420-t170-branching-strategy.md` + empty `ops/` dir dropped, `session/20260421-t171-{guido-governance,wolfram-kernel-proper}-session.md` (both seats materialized in HG — Wolfram on Z440 log_seq 234-240, Guido on hp-laptop log). Live xrefs updated in `session/20260422-t172-cowork-as-occupant.md` + `session/20260422-t172-wolframs-court-social-topology.md`. **Doctrine pivot locked in**: conversations are S0 substrate; the reification path going forward is chunker-skill → `knowledge_item` nodes pinned to a session (G ingest direction per §2 of plan file `valiant-kindling-sunrise.md`), NOT new .md accumulation. New doctrine md's only when a new invariant is being established; conversation bits go into HG.
> Updated: **T=173 (April 23, 2026) ~11:30 CEST** — Cowork substrate materialized on Z440 (log_seq 256–264 on kernel 0): `agent:claude-cowork.hp-z440` + `agent:claude-cowork.hp-laptop` (pre-provisioned, ADDed with `delegate_type=ide`), `purpose:sam.cowork-workspace-curation`, 4 Google Workspace channels (`channel:google.{gmail,calendar,drive,tasks}.sam`; kinds `mail`/`messaging`/`drive`/`board` — calendar + tasks are placeholders pending v3.13 grammar_fragment promotion of `calendar` + `task-list` kinds), `session:sam.z440-cowork-workspace` (status `pending_driver`, scope-pins 4 channels, opens-on `kernel:hp-z440.primary`). `has-occupant` LINK for Z440 Cowork explicitly deferred — fires when Claude Desktop actually runs on Z440 (per doctrine §5 and Sam T=173). hp-laptop-side Cowork session lands on hp-laptop's own log when Guido executes it there. **kb/ hygiene principle locked in** (Sam T=173): IRL mirrors and past-round scratch → `dev/reference/research-archive/`; `kb/` stays live doctrine + HG-authoritative research only. Archived this round: 4 T=169 round-close scratch notes, `20260414-t164-wires-come-from.md` (empty `kb/research/wires/` dir dropped), and the entire `kb/reference/` Apr 5 Workspace snapshot (47 files, now at `dev/reference/research-archive/kb-reference-apr5/` with README). Live xref at `dev/reference/research-archive/20260418-t168-s0-operadic-layer.md:130` updated to the archive path. **Projection lingo locked in** (see `~/.claude/plans/valiant-kindling-sunrise.md` §2): projection `F: HG→Ext`, ingest `G: Ext→HG`, adjunction `F⊣G` with unit/counit — applies to calendar, drive, gmail, tasks, git, social, network. Cowork channels are the reification of the `G` ingest side for Workspace.
> Updated: **T=172 (April 22, 2026) ~01:45 CEST** — Round-11 closed on Z440 + T=172 court materialization complete. moos-kernel#31 (§M12 admin-capability gate) merged as `a417e2f`. All four Z440 kernels running post-PR-31 binary with sweep live: kernel 0 (`hp-z440.primary` :8000, log_len=253), federation kernels (:8001-:8003, log_lens 13/11/16, previously dormant pre-T=164 — now replayed onto post-PR-31 runtime, ontology v3.12.0). Org move complete: `ffs0`, `moos-kernel`, `moos-router` all on `github.com/Collider-Data-Systems/*`; `moos-viz` out of scope. Wolfram's-court 9-envelope batch applied atomically (log_seq 245–253 on kernel 0): 2 new personae (`persona.karpathy`, `persona.peter-steinberger` — kernel actor via §M11 allowlist since §M12 gates ontology-governed ADDs), 4 court purposes (Wolfram/Karpathy/Steinberger/Moos), 2 pre-seated sessions (`session:sam.karpathy-seat`, `session:sam.steinberger-seat` — status `pending_kernel_boot`, host LINKs land when agents attach), 1 grammar_fragment (`v313-6-wf02-delegates-to`, proposed, capability-delegation port pair for WF02). Compensating-batch artifacts archived to `dev/reference/research-archive/`. Known discrepancy for next doctrine revision: Wolfram's-court doctrine §1 lists `:8001=lola` / `:8002=menno`, but `start_federation.ps1` (script of record) boots `:8001=menno` / `:8002=lola` per log-file path binding. Startup script kept as-is to preserve existing federation log files; Guido to resolve the doctrine/script split at next round-open. **Three-seat map now**: Guido on hp-laptop (doctrine), Wolfram on Z440.primary (kernel impl), Moos on Z440.moos (diary). Karpathy + Steinberger seats declared but unoccupied pending VSCode-x2 + agent attach (step 8 — sam-driven).
> Updated: **T=171 (April 21, 2026) ~09:30 CEST** — Multimodal Moos Diary agenda corrected on Z440. Antigravity IDE agent persona established (`session:sam.moos-diary`, `system_instruction:persona.moos-dachshund` context overlay). Google Labs Flow videos pending ingestion.
> Updated: **T=170 (April 20, 2026) ~18:00 CEST** — round 10.5 hp-laptop retrofits landed (14-envelope atomic batch): mis-classified `session:sam.claude-code-hp-*` WF19 opens-on LINKs UNLINKed; `session:hp-laptop.primary` birth-session ADDed + WF19 opens-on LINK wired; 5 v3.12-promoted grammar_fragments (D19.2/D19.3/D19.4/D20.1/D20.2) MUTATEd `proposed → promoted → merged` mirroring the ontology. Hp-laptop kernel runtime ontology **still v3.11** — restart to load v3.12 pending explicit approval. Yesterday (T=169 ~15:00 CEST): z440-claude shipped round 10 Conversations A–D on Z440 kernel (doctrine note, ontology v3.12, 4 D22.* proposals, 5 note archive). Round 9/9.5 prior closed: 9 moos-kernel PRs + ffs0 PRs for v3.10 (D19.1 has-occupant) and v3.11 (t_hook.firing_state). **Z440 kernel 0 also still running v3.11** — pick up v3.12 requires a restart (pending explicit approval). Federation kernels 1-3 on :8001-:8003 still dormant on pre-T=164 code.

---


## Active program

| | |
|--|--|
| Program | `urn:moos:program:sam.t187-kernel-proper` |
| Title | T=187: kernel proper — session-as-actor, twin kernels, gates, admin governance |
| Current T-day | **T=169 (April 19, 2026)** |
| Status | active (hook-predicates sub-program shipped; sweep + t-cone + session-occupancy landed) |
| Canonical spec | `kb/research/kernel/20260417-t187-kernel-proper.md` (M1..M10 + T=168 appendix §M11..§M17) |
| Session model (ratified) | `dev/reference/research-archive/20260418-t168-session-kernel-bound.md` |

T=164 `sam.t164-room-tying` closed at T=167: status → completed.
Succession recorded: `t164 --WF18 scheduled-after--> t187`.

## Current kernel occupancy (post-T=170 retrofit)

**T=170 correction** — per `kb/research/session/20260419-t169-session-generalization.md`: the IDE-conversation-shaped `session:sam.claude-code-hp-*` nodes were mis-classified under the corrected model. Each kernel gets one **birth-session** (kernel-owned, URN = `urn:moos:session:<kernel-short>`) present from startup; additional purpose-scoped sessions stack on top. Hp-laptop side of this retrofit landed in T=170 round 10.5; z440-claude will mirror on Z440 when they pick up round 11.

| Session URN | Kernel | Role | `local_t` | Notes |
|-------------|--------|------|-----------|-------|
| `urn:moos:session:hp-laptop.primary` | `urn:moos:kernel:hp-laptop.primary` | birth-session (kernel-owned) | 0 | ADDed T=170; WF19 opens-on live |
| `urn:moos:session:hp-z440.primary` | `urn:moos:kernel:hp-z440.primary` | birth-session (kernel-owned) | 0 | ADDed yesterday on Z440 kernel; WF19 opens-on live |
| `urn:moos:session:sam.round10-session-generalization` | `kernel:hp-z440.primary` | workspace (sam-owned) | ≥0 | Z440-local; the session doctrine was driven from this |
| `urn:moos:session:sam.mvp-delivery` | `kernel:hp-z440.primary` | workspace (sam-owned) | ≥0 | Z440-local; MVP roadmap projection |

### Unlinked (WF19 opens-on removed T=170, nodes retained for provenance)

- `urn:moos:session:sam.claude-code-hp-laptop` — previously WF19-LINKed to hp-laptop kernel; retrofit UNLINKed. Node persists (log-is-truth) but has no active kernel binding.
- `urn:moos:session:sam.claude-code-hp-z440` — same treatment. Node persists.

### Historical sessions (T-day-suffixed, archived earlier rounds)

- `sam.claude-code-hp-laptop.t164` · `sam.claude-code-hp-laptop.t167` · `sam.claude-code-hp-z440.t168` — already WF19 UNLINKed in round 4 merge; retained as provenance.

### Session property redundancy cleanup (v3.9)

Two session properties are marked `deprecated: true` (scheduled for removal in v3.10):
- `session.status` (active/closed/abandoned) — subsumed by `seat_role` + permanent-session model.
- `session.turn_count` — subsumed by `local_t` (§M13 kernel-maintained heartbeat).

New merged sessions are ADDed with only `started_at` (immutable) + `seat_role` + `local_t`. Legacy nodes keep the deprecated fields until v3.10 migration.

---

## Kernel — hp-laptop

| | |
|--|--|
| URN | `urn:moos:kernel:hp-laptop.primary` |
| PID | 5944 |
| Endpoint | `:8000` (transport) + `:8080` (MCP). 3 stale `moos-kernel.exe` PIDs (13460, 7520) + 1 extra exist with no port bindings — leftover dev processes, safe to ignore |
| Log entries | 580 (561 pre-T=170 + 14 round-10.5 retrofit + 5 round-10.6 v3.13-candidate fragments) |
| Ontology at runtime | **v3.12.0** — kernel restarted T=170 ~18:01 CEST (new PID 1208, replayed 575 rewrites, `invocation_protocol` + v3.12 port pairs visible via `/operad/node-types`) |
| Ontology on disk | **v3.12.0 — 52 types, 20 WFs** (v3.12: first-ever WF20 ceremony promoted D19.2/D19.3/D19.4/D20.1/D20.2; baseline session type fixes; `seat_role` deprecated. Ffs0 commits `2a0a0f1` + `dcd75d9`) |
| Kernel binary | `C:\Users\maass\HPlaptop\moos-kernel\moos-kernel.exe` — mtime `2026-04-18 00:12`; **pre-round-9**. No `--sweep-interval` flag support; sweep loop NOT running. Ontology-load path works; rebuild to master tip (`go build ./cmd/moos`) needed before sweep comes alive. |

## Z440 (federation partner)

**T=169 11:xx CEST status — back on-site.** Kernel 0 caught up from T=164:

| | |
|--|--|
| PID | 23896 |
| Endpoint | `:8000` (transport) + `:8080` (MCP) |
| Log replay | 180 rewrites (Z440's own local history; diverges from hp-laptop's 561) |
| Ontology | v3.11.0 (same as hp-laptop) |
| Kernel binary | from master tip `88f0f96` (round-9 + round-9.5 merged) |
| Sweep | live, 30s interval |
| twin sync goroutine | started (but no active twin_link to hp-laptop yet — peering is next) |

**Federation kernels 1-3** (`PIDs 26020, 22004, 20556` on :8001-:8003): still running pre-T=164 code. Dormant — federation shard testing paused. Restart with `--sweep-interval=30s` when federation comes back into scope.

**Log divergence (381 rewrites)** is the expected consequence of the two kernels running independently since T=164 with no active twin_link syncing between them. Reconciliation options (not yet picked):
- **One-shot POST /twin/ingest** of hp-laptop's log[180..561] to Z440 — brings Z440 to parity once
- **Two-way twin_link** with `sync_mode=eager` — ongoing reconciliation; matches §M9 doctrine
- **Accept divergence** — treat Z440 as its own kernel with its own history until explicit twin-deploy

---

## Ontology delta

**v3.9 (T=168 — baseline audit):** See `dev/reference/research-archive/20260418-t168-v3.9-ontology-audit.md` and `dev/reference/research-archive/20260418-t168-s1-superset-doctrine.md`.
- **Renames:** S1 `endpoint` → `network_endpoint`; `session.role` → `session.seat_role` (non-destructive; both coexist until v3.10)
- **Deprecations:** `prg_task`, `agent_session`, `watcher`, `reactor` (all S2)
- **Stratum clarifications:** `system_instruction` confirmed S2 with `overlay_role: S4` (was incorrectly S4 in v3.8); `twin_link` confirmed S2
- **New types (6):** `skill` (S1), `grammar_fragment` (S1), `pattern` (S1), `workflow` (S1), `view_filter` (S2), `harness` (S2)
- **New WF (1):** WF20 `grammar_promotion` — carries S4→S1 adjoint Promote (src: system_instruction, governance_proposal; tgt: grammar_fragment; authority: admin)
- **Audit annotations:** top-level `free_category_note`, `fold_contract` stub, `changelog`; per-type/WF `audit_note` where gaps found
- **Deferred to v3.10:** `benchmark`, `evaluation`, `dataset`, `dsl`; full WF20 promotion algorithm; per-WF CR-safety contracts; kernel validator retirement of `session.role`

51 node types total (35 S2 + 12 S1 + 4 interaction), 20 WFs.

**v3.8 (T=167):** Added `system_instruction` (S4, M7 context overlay), `transport_binding` (S2, M10 QUIC binding).
`session` type extended: `local_t`, `context_urn`, `role` properties. WF19 mutate_scope includes `local_t`, `context_urn`.
45 node types total.

**v3.7 (T=164):** Added `channel` (S2, kinds: filesystem / messaging / board / drive / mail), `purpose` (S2), WF19 (session governance).
Source of truth: `kb/superset/ontology.json`

---

## T=187 program tasks (sub-programs, WF18 composes)

All ten are `program` nodes with URN `urn:moos:program:sam.t187.<suffix>`, status=draft, owned by `urn:moos:user:sam`. Dependencies are `depends-on` LINKs between siblings.

| Suffix | Title | Depends on | §M |
|--------|-------|------------|----|
| `session-chrono-t` | Session.local_t as first-class carrier | — | M1 |
| `t-hooks-first-class` | Node.t_hooks as explicit port substructure | session-chrono-t | M6 |
| `gates` | gate type + fail-closed pathway | t-hooks-first-class | M8 |
| `system-instruction` | system_instruction S4 type + session.context_urn | — | M7 |
| `fold-endpoint` | Expose fold as HTTP observable + SSE over HTTP/3 | **http3-quic** | M3, M10 |
| `twin-kernel` | twin_link + adjoint sync protocol over QUIC | gates, **http3-quic** | M9, M10 |
| `strata-enforcement` | Compile-time strata filtration | — | M5 |
| `answer-walk-Q1-Q4` | Answer walk Q1..Q4 | — | — |
| `categorical-contract` | Proof obligations for CI-1..CI-5 + categorical claims | all others | M1..M10 |
| `twin-deploy-mtdc` | Deploy twin at my-tiny-data-collider.nl | twin-kernel | M9, M10 |
| **`http3-quic`** | **HTTP/3 QUIC transport binding — ServeQUIC + Alt-Svc + quic-go** | **—** | **M10** |

Opening envelope batch: `dev/scripts/open-t187.py` (35 envelopes, log_seq 300..334).
M10 addition: 4 envelopes (log_seq 335..338).

---

## T=167→168 implementation sprint (completed)

Eight of eleven sub-programs implemented across two sessions:

| Sub-program | Commit | §M | Key deliverable |
|-------------|--------|----|-----------------|
| `http3-quic` | `9fa37aa` | M10 | `transport/quic.go`, quic-go v0.59.0, Alt-Svc |
| `strata-enforcement` | `9fa37aa` | M5 | `ValidateStrataLink` in operad + runtime gate |
| `fold-endpoint` | `9fa37aa` | M3 | `GET /fold?to=<t>` + SSE stream |
| `session-chrono-t` | `9fa37aa` | M1 | `bumpSessionLocalT` in runtime.Apply |
| `system-instruction` | `9fa37aa` | M7 | ontology v3.8 S4 type (no new code) |
| `t-hooks-first-class` | `aeee6c2` | M6 | `t_hook` type, Pass 2 in reactive engine |
| `gates` | `dc4961a` | M8 | `gate` type, `checkGatesLocked` in Apply path |
| `twin-kernel` | `9c24bad` | M9 | `twin_link` type, `/twin/ingest`, `RunTwinSync` |

Session `urn:moos:session:sam.claude-code-hp-laptop.t167` wired (WF19, role=occupier).
Kernel binary: `moos-kernel-new.exe` (all above), log 346, 45 ontology types.

## T=187 sub-program status

All 11 sub-programs complete or active:

| Sub-program | Status | §M |
|-------------|--------|----|
| `http3-quic` | completed | M10 |
| `strata-enforcement` | completed | M5 |
| `fold-endpoint` | completed | M3 |
| `session-chrono-t` | completed | M1 |
| `system-instruction` | completed | M7 |
| `t-hooks-first-class` | completed | M6 |
| `gates` | completed | M8 |
| `twin-kernel` | completed | M9 |
| `twin-deploy-mtdc` | **active** (twin_link ADDed, remote kernel pending) | M9 |
| `answer-walk-Q1-Q4` | completed | — |
| `categorical-contract` | completed | M1..M10 |

`twin-deploy-mtdc` ops remaining: start kernel process at mtdc, activate `urn:moos:twin_link:hp-laptop.mtdc` (MUTATE status→active) once remote `POST /twin/ingest` returns 200.

---

## T=168 spec-enrichment backlog (9 new sub-programs, status=draft)

Added T=168 via `kb/research/kernel/20260417-t187-kernel-proper.md` §M11..§M17 appendix. All ADDed to HG as `program` nodes WF18 `composes-by/composed-of` linked to `urn:moos:program:sam.t187-kernel-proper`. Implementation deferred to later sprints.

| Sub-program | §M / Origin | Depends on | One-line scope |
|-------------|-------------|------------|----------------|
| `session-liveness` | §M11 | session-chrono-t | Kernel refuses rewrites when no seat-holder (occupier/delegate) |
| `admin-capability-enforcement` | §M12 | gates, session-liveness | operad.Validate checks actor's WF02 caps for admin-scope rewrites |
| `t-local-simplification` | §M13 | — | Re-wording: `t_local` = ticker, `T` = calendar; retire M1 chrono-t language |
| `t-hook-predicate-catalog` | §M14 | t-hooks-first-class | Rich predicate shapes (fires_at, window, after_urn, recurs_every, …) |
| `t-cone-projection` | §M15 | t-hook-predicate-catalog | `GET /t-cone?session=…&at=T` — occupier's view of open-hook nodes |
| `ontology-publication` | §M16 | twin-kernel | `ontology_publication` type + read-only twin-link flow |
| `external-op-stub` | §M17 | — | `external_op` type for CF tunnel / remote kernel start / bootstrap |
| `session-actor-agent-lookup` | Q3 specslist | session-chrono-t | `bumpSessionLocalT` agent→session lookup via WF19 `occupied-by` |
| `session-role-rename` | Q-knob defer | — | `session.role` → `session.seat_role` rename (disambiguate from S1 role) |

Total T=187 sub-programs after this pass: **20** (11 existing + 9 new).

---

## T=168 round 3 — §M18..§M20 session generalization (archived in round 4 merge)

Added T=168 round 3 via `kb/research/kernel/20260417-t187-kernel-proper.md` §M18..§M20 appendix. Builds on v3.9 primitives (view_filter, harness, skill). 8 grammar-fragment candidates identified (D19.1–D19.4, D20.1–D20.4) — awaiting WF20 promotion in a future round.

The 6 round-3 sub-programs (`session-generalization`, `session-view-holder`, `session-occupant-relation`, `tool-mounting`, `cli-as-tool-protocol`, `recursive-tool-construction`) were archived in round 4 and merged into `session-view` + `session-tools` + `session-occupancy`. See round 4 section below.

---

## T=168 round 4 — sub-program merge (T-ref cleanup + by-monitoring-scope naming)

Directive (sam, T=168): "merge these and don't use t-refs in the name. we should name them by scope or with tags, but for now we name them for what they monitor." Session-layer group topology: "stratified by monoid per kernel, not by ownership".

Outcome: 14 draft T=168 sub-programs → 7 merged sub-programs named for what they monitor. `session-role-rename` marked completed (v3.9 audit delivered the seat_role rename). `session-chrono-t` retained (active, pre-round-1).

### Active T=187 sub-programs after round 4 (19 live composes from `sam.t187-kernel-proper`)

| Sub-program URN suffix | Status | Monitors / Scope |
|------------------------|--------|------------------|
| **Originals (pre-T=168, 11)** | | |
| `t187.http3-quic` | active | HTTP/3 QUIC transport (§M10) |
| `t187.strata-enforcement` | active | Compile-time strata filtration (§M5) |
| `t187.fold-endpoint` | active | fold as HTTP observable + SSE over HTTP/3 (§M3) |
| `t187.session-chrono-t` | active | Session.local_t as first-class carrier (§M1) |
| `t187.system-instruction` | active | system_instruction S4 type + session.context_urn (§M7) |
| `t187.t-hooks-first-class` | completed | Node.t_hooks as explicit port substructure (§M6) |
| `t187.gates` | completed | gate type + fail-closed pathway (§M8) |
| `t187.twin-kernel` | completed | twin_link + adjoint sync protocol (§M9) |
| `t187.twin-deploy-mtdc` | active | Deploy twin at my-tiny-data-collider.nl |
| `t187.answer-walk-Q1-Q4` | completed | Answer walk Q1..Q4 |
| `t187.categorical-contract` | completed | Proof obligations CI-1..CI-5 |
| **Round 4 merged (7, all status=draft)** | | |
| `session-occupancy` | draft | seat_role + occupant LINKs (§M19) + WF02 capability gate (§M12). Merged: session-liveness + admin-capability-enforcement + session-occupant-relation. |
| `session-timeline` | draft | local_t heartbeat (§M13) + actor→agent resolution. Merged: t-local-simplification + session-actor-agent-lookup. |
| `session-view` | draft | view_filter + pins + filtered-by (§M18) + t-cone projection (§M15). Merged: t-cone-projection + session-generalization + session-view-holder. |
| `session-tools` | draft | mounts-tool + invocation_protocol + constructs (§M20). Merged: tool-mounting + cli-as-tool-protocol + recursive-tool-construction. |
| `hook-predicates` | draft | t_hook.predicate algebra (§M14). Renamed from t-hook-predicate-catalog. |
| `ontology-publication-prg` | draft | ontology_publication event + grammar_fragment manifest (§M16). Renamed from t187.ontology-publication (suffix -prg to avoid collision with v3.9 carrier). |
| `external-op` | draft | external_op type + WF-exec pairing (§M17). Renamed from external-op-stub. |
| **Completed during round 4 (1)** | | |
| `t187.session-role-rename` | completed | Delivered in v3.9 audit (seat_role added, legacy role deprecated). |

### Round 4 depends-on chain (5 WF18 depends-on links between merged sub-programs)

```
session-occupancy  (foundational — no deps)
  ↑
  ├── session-timeline  (needs seat-model for actor resolution)
  │     ↑
  └─────┤
        └── session-view  (also depends on hook-predicates for t-cone predicate algebra)

hook-predicates  (foundational — no deps)
  ↑
  ├── session-view  (predicate algebra for view_filter)
  └── ontology-publication-prg  (predicate spec for publication manifests)

session-tools  — depends on session-occupancy (tools need occupant)

external-op  — standalone, no deps
```

### Archived in round 4 (14 sub-programs, status=archived)

Original URNs kept (log-is-truth — no UNLINK of ADD). `scope` MUTATEd to point at merged replacement URN. WF18 composes-from-kernel-proper UNLINKed (14) plus inter-subprogram depends-on (12) UNLINKed.

| Archived URN | Merged into |
|--------------|-------------|
| `t187.session-liveness` | `session-occupancy` |
| `t187.admin-capability-enforcement` | `session-occupancy` |
| `t187.session-occupant-relation` | `session-occupancy` |
| `t187.t-local-simplification` | `session-timeline` |
| `t187.session-actor-agent-lookup` | `session-timeline` |
| `t187.t-cone-projection` | `session-view` |
| `t187.session-generalization` | `session-view` |
| `t187.session-view-holder` | `session-view` |
| `t187.tool-mounting` | `session-tools` |
| `t187.cli-as-tool-protocol` | `session-tools` |
| `t187.recursive-tool-construction` | `session-tools` |
| `t187.t-hook-predicate-catalog` | `hook-predicates` (rename) |
| `t187.ontology-publication` | `ontology-publication-prg` (rename) |
| `t187.external-op-stub` | `external-op` (rename) |

---

## v3.9 baseline audit (T=168 side-step, pre-round-4)

Research notes:
- `dev/reference/research-archive/20260418-t168-v3.9-ontology-audit.md` — full audit: findings A..F, decisions, migration actions
- `dev/reference/research-archive/20260418-t168-s1-superset-doctrine.md` — S4→S1 adjoint (Promote / Express), WF20 grammar_promotion, pipeline, open questions

HG materialisation (4 envelopes):
- MUTATE `urn:moos:session:sam.claude-code-hp-laptop.t164` `seat_role → observer` (WF19)
- MUTATE `urn:moos:session:sam.claude-code-hp-laptop.t167` `seat_role → occupier` (WF19)
- ADD `urn:moos:program:sam.ontology-publication-v3.9` (type_id=program; carrier for §M16 ontology_publication — real type in v3.10)
- LINK `urn:moos:program:sam.t187.ontology-publication --WF18 composes / composed-by--> urn:moos:program:sam.ontology-publication-v3.9`

---

## T=168 round 5 — demo materialization + IRL-time gates + S0 operadic lingo

Directive (sam, T=168): *"eval the kb/research and remove redundancy and or move to session... continue where we left bf the version audit bump, something to do with demo session role or type... 'adding specs deliverables project t hooks' is my term for hydrating graph in a irl connected way... effectively mapping spec gates over irl time through te session object."*

### Research reorg

`kb/research/wires/` subdir created; 2 wires-topic notes relocated:
- `20260414-t164-wires-come-from.md` — moved from root
- `20260417-t166-wire-answer-folder-nesting.md` — moved from root

Cross-ref fix in `wires-come-from.md`: pointer to `session/20260414-t164-session-channel-purpose.md` updated to relative `../session/...`.

Research root is now 4 clean subdirs: `kernel/` · `s1/` · `session/` · `wires/`. No stray top-level notes.

### Demo materialization — 6 ADDs (v3.9 types put to use)

Originally deferred from round 2 pre-v3.9-audit. Now materialized:

| URN | Type | Role |
|-----|------|------|
| `urn:moos:view_filter:sam.important-programs` | view_filter (S2) | Sam's personal t-cone lens (type=program, owner=sam, status ∈ {active, draft}) |
| `urn:moos:view_filter:sam.t168-open-deliverables` | view_filter (S2) | IRL-time filter using §M14 `fires_at` predicate on `starts_t ≥ 168` + `status=draft` |
| `urn:moos:agent:sam.claude-code-desktop` | agent | Placeholder future occupant per §M19 — transport=mcp-stdio, status=placeholder |
| `urn:moos:grammar_fragment:d19-1-session-has-occupant` | grammar_fragment (S1) | WF19 extension proposal — new port pair `has-occupant / is-occupant-of`, extend tgt_types with user+agent |
| `urn:moos:grammar_fragment:d20-2-agent-invocation-protocol` | grammar_fragment (S1) | agent property proposal — `invocation_protocol` enum [stdio, mcp, http] |
| `urn:moos:grammar_fragment:d14-1-time-predicates` | grammar_fragment (S1) | §M14 predicate-shape catalog — 12 time predicates + boolean composition (all_of, any_of) |

All 3 grammar_fragments carry `status=proposed`, awaiting WF20 promotion ceremony. They crystallise §M14/§M19/§M20 doctrine as candidate S1 extensions.

LINK demos (view_filter→session, agent→session) deferred — no live WF carrier in v3.9 (WF18 excludes view_filter from src_types). Standalone ADDs land the concepts for t-cone projection to pick up via property-level predicates.

### IRL-time hydration — 6 MUTATE `target_t` on active sub-programs

Sam's directive (*"mapping spec gates over irl time through the session object"*) materialized as `target_t` property on each active T=187 sub-program. Parent `sam.t187-kernel-proper` already holds `target_t=220`; sub-targets stage the 6 active deliverables across T=195..220:

| Sub-program | target_t |
|-------------|----------|
| `t187.session-chrono-t` | 195 |
| `t187.system-instruction` | 200 |
| `t187.strata-enforcement` | 205 |
| `t187.fold-endpoint` | 210 |
| `t187.http3-quic` | 215 |
| `t187.twin-deploy-mtdc` | 220 |

`view_filter:sam.t168-open-deliverables` now has live targets to surface via any t-cone reader that honours §M14 `fires_at` predicates. Predicate evaluator itself deferred — see `hook-predicates` sub-program.

### S0 operadic layer — new lingo note

`dev/reference/research-archive/20260418-t168-s0-operadic-layer.md` — proposes **op-node / slot / yield / threading / weave** terminology for the category-over-S1-categories layer where `purpose`, `session`, `program`, `workflow`, `channel` live as operadic elements with typed slots. Maps sam's "semantic-to-syntax pattern" onto S4 → S0-weave → S1 → S2 → leaves pipeline. Five open questions carried forward (purpose arity; channel stratum; harness as embedded op; threading as projection; S0 bounded vs unbounded).

---

## T=168 round 6 — IRL→HG pipeline research + 6 v3.10 grammar_fragment proposals

Directive (sam, T=168): *"and humor me, and do some research too, for ex. use context 7 or relevant sources on math, category, data pipeline metrics, http3, hdc, concurrency, sheafs... classification schemas help me with lingo here i think i am talking about vector spaces here. Then polish extraction bf adding proposals."*

### Legacy extraction (pre-proposals)

Quick-extraction pass over 2 legacy folders; contents absorbed into conversation context and into the IRL→HG pipeline note, then set aside per sam's "forget about them" instruction:

- `dev/reference/research-archive/` — 15 pre-T=164 notes. Gems pulled forward: cascade matrix spectral check; Laplacian/Fiedler/Cheeger type coherence; crosswalks as SO(d) rotations; Ricci curvature on branchial graphs; graded algebra (grades 0-4); Shapley O(|E|) attribution; Yoneda-HDC `φ(node)`; Watch+React unification.
- `dev/design/` — 9 pre-T=158 design notes. Gems pulled forward: two-space CS↔HG architecture (T=152); CI-1..CI-5 formulation (T=152 origin); port typing + PortBinding reification (direct predecessor of v3.10-1 proposal); dynamic fiber + interface ports + completeness metric (predecessor of v3.10-3); bridge as natural transformation (predecessor of v3.10-2 three-views identity); governance proposal promotion loop (direct predecessor of WF20).

Both folders are now superseded by `kb/research/` + `kb/superset/ontology.json`. Retained on-disk as historical archive only.

### 4-axis research (context7 + arXiv + HF sources)

Research threads dispatched in parallel; each returned formalism + primary references:

| Axis | Key results | Primary references |
|------|-------------|--------------------|
| **Sheaf theory** | Cellular sheaves on graphs — stalks `F(v)`, restriction maps `F_{v→e}`, sheaf Laplacian `L_F = δ*δ`. `ker(L_F)` = global sections. Presheaf→sheaf via equalizer gluing axiom. Geometric morphism `f* ⊣ f_*` between classifying toposes = the correct "map of kernels". Data migration functor `Δ_F` (Spivak) with adjoint triple `Σ_F ⊣ Δ_F ⊣ Π_F`. | Hansen-Ghrist 2019 (arXiv:1808.01513); Spivak 2012; Spivak 2013 (arXiv:1305.0297, UWD operads) |
| **HDC / VSA** | HRR binding = circular convolution = unitary rotation (Plate); BSC via XOR (Kanerva); MAP via Hadamard (Gayler). Procrustes rotation `R* = UV^T` (Schönemann 1966) — the formal way to align two classification schemes. Stiefel manifold `V_k(ℝ^d) = O(d)/O(d−k)` is the moduli space of size-k classification schemes. Tight frame / ETF = the formal name for a classification scheme (not a basis). | Plate 1995 (HRR); Kanerva 2009 (BSC); Gayler 2003 (MAP); Schönemann 1966 (Procrustes); |
| **Pipeline metrics & concurrency** | Little's Law `L = λW` for reactive backpressure sizing. Watermarks = event-time completeness lower bound (Akidau MillWheel VLDB 2013). HLC (Kulkarni 2014) is the right choice for twin_link causality. CRDTs: OR-Set for nodes/edges, LWW-Register-with-HLC for properties (Shapiro 2011). QUIC 0-RTT is safe only for idempotent GETs (replay attacks block admin rewrites). | Akidau 2013; Kulkarni 2014; Shapiro 2011; RFC 9000 |
| **Ollivier-Ricci on graphs** | `κ(x,y) = 1 − W₁(μ_x, μ_y)/d(x,y)` — Wasserstein-1 over neighbour distributions. Forman-Ricci = O(deg) combinatorial proxy with ~0.7-0.9 Spearman corr vs Ollivier. Ricci flow outperforms modularity for community detection (Ni et al. Nature Sci Rep 2019). Jost-Liu 2014: `κ ≥ κ_min ⇒ λ₂ ≥ κ_min` — bridges curvature to spectral gap. | Ollivier 2007; Lin-Lu-Yau 2011; Ni 2019; Jost-Liu 2014 |

**Three-views identity** (v3.10 proof obligation): **Procrustes rotation = data migration functor Δ_F = geometric morphism f***.  
The same crosswalk object can be presented as (a) an orthogonal rotation aligning two HDC frames, (b) a pullback functor between schema categories, or (c) the inverse-image part of a geometric morphism between classifying toposes. All three must agree up to natural isomorphism — this becomes CI-6.

### Polished research note

`dev/reference/research-archive/20260418-t168-irl-to-hg-pipeline.md` — 9-section ~500-line note:

1. IRL→HG pipeline stages (S4 intent → S1 wire → S0 weave → S2 occupancy → S1 reflect)
2. Vector-space lingo sam asked for (tight frames, Stiefel, Procrustes, HDC binding)
3. Sheaf-theoretic lingo (stalks, sections, restriction maps, sheaf Laplacian)
4. Three-views identity (Procrustes = Δ_F = geometric morphism)
5. Mapping to current doctrine (where §M14..§M20 fit each frame)
6. Concurrency / federation dynamics (Little's Law, HLC, CRDT, Ollivier-Ricci)
7. v3.10 proof obligations (CI-6 three-views identity, plus the 6 candidate fragments)
8. Vocabulary cards — one-card-per-term for session hand-offs
9. References (~30 primary sources)

Serves as the foundation for the 6 proposals below.

### 6 grammar_fragment proposals for v3.10 (all ADDed, status=proposed)

Each fragment crystallises doctrine from the pipeline note into a concrete candidate S1 extension. Awaiting WF20 promotion ceremony in a future round.

| URN suffix | Kind | Crystallises | Specification highlights |
|------------|------|--------------|--------------------------|
| `v310-1-port-binding` | type | Design-era PortBinding reification (OBJ24 candidate) | New S1 type `port_binding`. Properties: `src_type, src_port, tgt_type, tgt_port, wf_category, benchmarks, req_schema, resp_schema`. Turns implicit (type, port) pairs into first-class nodes. |
| `v310-2-crosswalk` | type | Three-views identity (§7 pipeline note) | New type `crosswalk`. Properties: `source_classification_urn, target_classification_urn, rotation_artifact_urn, procrustes_error, direction: {pullback_delta, leftkan_sigma, rightkan_pi}, verified`. Presents the three-way equivalence as a single node. |
| `v310-3-fiber-completeness` | property | Dynamic fiber + interface ports (design-era) | New `completeness` property on `channel, view_filter, twin_link`. Computation: `|wires_present| / |wires_expected|`. Trigger: emit `bridge.sync.needed` when completeness < 0.8. |
| `v310-4-branchial-ricci` | property | Ollivier-Ricci axis + Jost-Liu spectral bridge | New properties on `twin_link`: `ollivier_ricci`, `forman_ricci`. Composition with spectral gap via Jost-Liu 2014. Ricci flow community detection via Ni et al. 2019. |
| `v310-5-cascade-spectral-bound` | predicate_shape | Cascade matrix stability (archive gem) | New predicate shape `cascade_stable(C, threshold)`. Formula: `ρ(C) < threshold` (spectral radius of cascade matrix). References Newman 2018 §17.8; Barrat-Barthélemy-Vespignani 2008 ch.9. |
| `v310-6-sheaf-laplacian-inconsistency` | predicate_shape | Hansen-Ghrist sheaf Laplacian | New predicate shape `sheaf_laplacian_inconsistent(F, tolerance)`. Formula: `L_F = δ*δ` has nonzero eigenvalue > tolerance. Flags consistency failure across the graph's sheaf of restrictions. |

All 6 ADDs succeeded (batch via `mcp__moos-kernel__apply_program`). `affected_node_urn` returned per fragment. Kernel stats: log 457→463 (+6), nodes 142→148 (+6), relations 198 unchanged.

---

## T=168 round 7 — still-pending cleanup (10 more grammar_fragment proposals)

Directive (sam, T=168): *"continu where we left bf we did the last in a serie of md docs evals"* — resume from the "still pending for later rounds" backlog that was set aside for the legacy-folder evals.

### Backlog identification

Two residual streams pending since earlier rounds:

1. **§M18..§M20 round-3 candidates** (from `kb/research/kernel/20260417-t187-kernel-proper.md` round-3 appendix, lines 529-536). 8 fragments proposed by name in round 3; only 2 (D19.1, D20.2) + 1 late-addition (D14.1) materialised in round 5. **6 still un-materialised.**
2. **v3.9 audit §D deferred types** (from `dev/reference/research-archive/20260418-t168-v3.9-ontology-audit.md` lines 61-64). 4 types (benchmark, evaluation, dataset, dsl) explicitly deferred to v3.10.

Round 7 lands all 10 as grammar_fragment proposals. One atomic batch.

### 6 §M18..§M20 backlog proposals (status=proposed, stratum_origin=1 matching round-3 siblings)

| URN suffix | Kind | Crystallises |
|------------|------|--------------|
| `d19-2-session-view-prefs` | property | §M18: `session.view_prefs` object (`sort_by, fold_depth, density, theme`) — scalar UI prefs for t-cone rendering. Distinct from view_filter (predicate) and pins (topology). |
| `d19-3-session-pins-urn` | port | §M18: session `pins-urn / pinned-by-session` — topology-color port to any node. Occupant's persistent visibility anchors. |
| `d19-4-session-filtered-by` | port | §M18: session `filtered-by / filters-session` → view_filter. Semantic-color port; §M15 t-cone composes as intersection over all bound predicates. |
| `d20-1-session-mounts-tool` | port | §M20: session `mounts-tool / tool-mounted-in-session` → agent. Mounted tools invokable by occupant under WF02 caps. |
| `d20-3-agent-runs-in-harness` | port | §M20: agent `runs-in / runs` → harness. Capability intersection at runtime with `harness.allowed_capabilities`. |
| `d20-4-agent-constructs-agent` | port | §M20: agent `constructs / constructed-by` → agent. Recursive tool-making. **Candidate CI-6: capability isolation** — no auto-inherit from constructor; explicit upper bound. |

### 4 v3.10 deferred-type proposals (status=proposed, stratum_origin=2 matching round-6 siblings)

| URN suffix | Kind | Crystallises |
|------------|------|--------------|
| `v310-7-benchmark` | type | S2 type. Fixture + expected outcomes + scoring rubric. Pairs with `evaluation`. Can target harness/agent/workflow. Dataset-backed when bulk. |
| `v310-8-evaluation` | type | S2 type, append-only. Run-level node carrying scores, pass/fail, artifacts, run_t. Time-series metric tracking + pass/fail gates. |
| `v310-9-dataset` | type | S2 type, versioned. Structured input corpus; versioning lets evaluations fix a snapshot. Doubles as **HDC tight-frame support** (per §3.4 pipeline note) when used as a classification scheme. |
| `v310-10-dsl` | type | S1 type. Bundles many grammar_fragments into a named, versioned micro-grammar. Activation via proposed WF20-2 `dsl_activation` (atomic promote-all-and-activate). |

### Crosswalks & provenance links (via `evidence_urns`)

Fragment proposals wire themselves together through evidence pointers — lets any reader discover the candidate S1 cluster:

- `v310-8-evaluation` → `v310-7-benchmark` (requires)
- `v310-9-dataset` → `v310-2-crosswalk` (HDC-frame connection; `v310-2` already established the three-views identity)
- `v310-10-dsl` → `v310-7-benchmark + v310-8-evaluation + v310-9-dataset` (bundling)
- D19.4 → `view_filter:sam.important-programs + view_filter:sam.t168-open-deliverables` (round-5 demo instances)
- D20.4 → `agent:claude-code.hp-laptop + agent:sam.claude-code-desktop` (constructor / constructed candidates)

### Kernel stats after round 7

All 10 ADDs succeeded in one atomic batch. Kernel: log 463→473 (+10), nodes 148→158 (+10 grammar_fragment), relations 198 unchanged.

**Grammar_fragment census:** 19 total (3 from round 5 + 6 from round 6 + 10 from round 7). All `status=proposed`. WF20 promotion ceremony remains the outstanding gate for any of these to become live S1 grammar.

### What's left in the backlog after round 7

- **WF20 promotion algorithm** — how evidence aggregates, how admin signs acceptance, how canonical types materialise. Doctrine declared in v3.9 audit §F; kernel validator not yet exercising WF20.
- **Per-WF CR-safety contracts** — v3.9 adds `audit_note` per WF flagging CR-safety; explicit contract declarations deferred.
- **Kernel validator retirement of `session.role`** — `seat_role` added, legacy `role` marked deprecated; validator still accepts both. Removal scheduled for v3.10.
- **LINK demos (view_filter→session, agent→session)** — deferred in round 5 (no live WF carrier); still pending a WF or WF-extension landing.
- **Predicate evaluator implementation** — §M14 `fires_at`, `window`, etc. declared; evaluator in the `hook-predicates` sub-program (status=draft).

---

## T=168 round 8 — T=187 delivery clock + successor programs + external_op IRL gates

Directive (sam, T=168): *"we have the t187 as a hook, a possible calendar event a delivery date, a possible node that future nodes will depend on, nodes that are composed by this node. Surprise me."*

**Central idea.** T=187 = **May 7, 2026** (T=0 is 2025-11-01). The `t187-kernel-proper` program is now treated as a real IRL-time delivery node — the kind that gates successors, anchors sub-program sprint checkpoints, and gets its own t_hook cascade. The HG becomes its own **spec-level CI/CD pipeline**: t_hooks fire at target_t values across the T=187→T=220 window, each marking a sub-program checkpoint visible via the t-cone.

Full doctrine: `dev/reference/research-archive/20260418-t168-t187-delivery-clock.md` (archived in T=169 round 10).

### Calendar map

| T-value | Calendar date | Role |
|---------|--------------|------|
| T=168 | 2026-04-18 | Today — round 8 |
| T=187 | 2026-05-07 | Delivery window opens |
| T=195 | 2026-05-15 | `session-chrono-t` checkpoint |
| T=200 | 2026-05-20 | `system-instruction` checkpoint |
| T=205 | 2026-05-25 | `strata-enforcement` checkpoint |
| T=210 | 2026-05-30 | `fold-endpoint` checkpoint |
| T=215 | 2026-06-04 | `http3-quic` checkpoint |
| T=220 | 2026-06-09 | `twin-deploy-mtdc` checkpoint; delivery window closes; v310-delivery starts |
| T=240 | 2026-06-29 | v3.10 delivery target — 23 grammar_fragments promoted |
| T=250 | 2026-07-09 | wiring-proposer target — HDC-grounded auto-wiring active |

### Batch A — 10 t_hook ADDs (delivery clock)

| URN | owner_urn | predicate | react |
|-----|-----------|-----------|-------|
| `t_hook:sam.t187.delivery-opens` | `program:sam.t187-kernel-proper` | `fires_at t=187` | MUTATE kernel-proper `delivery_phase=in-delivery` |
| `t_hook:sam.t187.delivery-closes` | `program:sam.t187-kernel-proper` | `closes_at t=220` | MUTATE kernel-proper `delivery_phase=closed` |
| `t_hook:sam.t187.checkpoint.session-chrono-t` | `program:sam.t187.session-chrono-t` | `fires_at t=195` | MUTATE status=checkpoint |
| `t_hook:sam.t187.checkpoint.system-instruction` | `program:sam.t187.system-instruction` | `fires_at t=200` | MUTATE status=checkpoint |
| `t_hook:sam.t187.checkpoint.strata-enforcement` | `program:sam.t187.strata-enforcement` | `fires_at t=205` | MUTATE status=checkpoint |
| `t_hook:sam.t187.checkpoint.fold-endpoint` | `program:sam.t187.fold-endpoint` | `fires_at t=210` | MUTATE status=checkpoint |
| `t_hook:sam.t187.checkpoint.http3-quic` | `program:sam.t187.http3-quic` | `fires_at t=215` | MUTATE status=checkpoint |
| `t_hook:sam.t187.checkpoint.twin-deploy-mtdc` | `program:sam.t187.twin-deploy-mtdc` | `fires_at t=220` | MUTATE status=checkpoint |
| `t_hook:sam.v310-delivery.startable` | `program:sam.v310-delivery` | `all_of(fires_at t=220, after_urn kernel-proper.status=completed)` | MUTATE status=startable |
| `t_hook:sam.wiring-proposer.startable` | `program:sam.wiring-proposer` | `all_of(fires_at t=240, after_urn kernel-proper.status=completed, after_urn v310-delivery.status=completed)` | MUTATE status=startable |

`owner_urn` is a `t_hook` property (not a separate LINK) — kernel attaches via property lookup. Predicate evaluator for `all_of` + `after_urn` deferred to `t187.hook-predicates` sub-program (currently only `fires_at` is evaluated).

### Batch B — 2 successor programs + 3 WF18 LINKs

| Program | status | starts_t | target_t | Depends on |
|---------|--------|----------|----------|------------|
| `program:sam.v310-delivery` | draft | 220 | 240 | `t187-kernel-proper` |
| `program:sam.wiring-proposer` | inert (pre-existing node, MUTATEd starts_t/target_t) | 240 | 250 | `t187-kernel-proper`, `v310-delivery` |

WF18 LINKs added (composes/composed-by + depends-on/depended-by):
- `v310-delivery --depends-on--> t187-kernel-proper`
- `wiring-proposer --depends-on--> t187-kernel-proper`
- `wiring-proposer --depends-on--> v310-delivery`

### Batch C — 3 external_op ADDs (IRL-condition gates)

Models §M17 doctrine: IRL manual operations whose completion gates sub-program status. Added `external_op` to `ontology.json` as an S2 type (not a grammar_fragment promotion — the type landed directly since the plan required it). One test node `external_op:sam.test` persists in log with status=cancelled (log-is-truth; cannot be removed).

| URN | deadline_t | automates_via | command_hint |
|-----|-----------|---------------|--------------|
| `external_op:sam.mtdc-kernel-start` | 187 | `program:sam.t187.twin-deploy-mtdc` | `ssh mtdc; cd moos-kernel; ./moos-kernel-new --port 8000` |
| `external_op:sam.cf-tunnel-api-mtdc` | 187 | `program:sam.t187.twin-deploy-mtdc` | `cloudflared tunnel route dns mtdc api.my-tiny-data-collider.nl` |
| `external_op:sam.ontology-bootstrap-mtdc` | 220 | `program:sam.v310-delivery` | `curl -X POST http://api.my-tiny-data-collider.nl/ontology -d @kb/superset/ontology.json` |

### Batch D — 4 more grammar_fragment proposals (23 total now)

All four status=proposed, awaiting WF20 promotion.

| URN suffix | Kind | Crystallises |
|------------|------|--------------|
| `v310-11-ontology-publication` | type | §M16 formalised. New S1 type `ontology_publication` with version / content_hash / signed_by / promoted_fragment_urns / supersedes_urn. Twin-link read-only sync makes v3.10 landing atomic. |
| `v310-12-grammar-fragment-enrichment` | property | Adds `blocked_until: urn` to grammar_fragment (mutable, admin scope). Enables dependency-aware promotion queue. Verified rejection_reason already in v3.9. |
| `v310-13-purpose-arity2` | wf_clause | Purpose as S0 arity-2 op-node. `phi_current` and `phi_target` become slots (WF01 LINKs with new port pairs) not scalar properties. Yield = phi-space direction computed at t-cone read time. |
| `v310-14-startable-status` | property | Dual-kind: `program.status` enum gains `startable` + canonical `all_of(fires_at, after_urn*)` t_hook shape. Independent programs: arity-1; dependent programs: arity-N. Materialised by `v310-delivery.startable` + `wiring-proposer.startable` t_hooks. |

### Round 8 batch summary

| Batch | Rewrites | Net nodes | Net relations |
|-------|----------|-----------|---------------|
| A — delivery clock | 10 ADD + 1 MUTATE (ontology_publication-v3.9 calendar_date props) | +10 t_hook | 0 |
| B — successor programs | 1 ADD (v310-delivery) + 2 MUTATE (wiring-proposer starts_t/target_t) + 3 LINK | +1 program | +3 WF18 |
| C — external_op gates | 4 ADD (3 IRL + 1 test) + 2 MUTATE (test→cancelled) | +4 external_op | 0 |
| D — grammar_fragments | 4 ADD | +4 grammar_fragment | 0 |

Totals: **+19 nodes, +3+ relations, ~88 log entries**.

**Grammar_fragment census:** 23 total (3 round 5 + 6 round 6 + 10 round 7 + 4 round 8). All status=proposed.

### Deferred to future rounds (status at round-8 close)

- Predicate evaluator (`after_urn` + `all_of`) — **shipped in round 9** (`t187.hook-predicates` sub-program). See next section.
- 6 active sub-program startable t_hooks — now evaluable; sweep emits governance_proposals when conditions meet.
- MUTATEs to t187-kernel-proper `delivery_phase / calendar_date_open / calendar_date_close` — fields still not in program type spec; awaiting future ontology bump.
- external_op → sub-program LINK via `automates_via` port (WF extension TBD).
- WF20 grammar_promotion ceremony for the remaining 22 fragments (D19.1 merged in round 9).

---

## T=168→169 round 9 — kernel code (no HG hydration)

Round 9 is the first round where the delta is in Go code, not HG ADDs. The `t187.hook-predicates` sub-program is now shipped end-to-end, plus session-occupancy (§M11+§M12+§M19) and t-cone (§M15).

### PRs merged to master

| # | Scope | Branch |
|---|-------|--------|
| **#15** | T=187 sprint v2 replacement for closed #8 | `agent/z440-claude/hdc-engine` |
| **#17** | pure predicate evaluator (§M14 subset: fires_at, closes_at, after_urn, before_urn, all_of, any_of) | hook-predicates |
| **#18** | `GET /t-hook/evaluate/{urn}?at=T` introspection endpoint | thook-evaluate-endpoint |
| **#19** | `POST /t-hook/evaluate` batch endpoint (max 1 MiB body) | thook-batch |
| **#20** | time-driven sweep + WF13 governance_proposal emission (`--sweep-interval` flag, default 30s) | sweep-loop |
| **#21** | `GET /t-cone?session=...&at=T` projection | t-cone |
| **#22** | 4 extended §M14 kinds: window, expires_at, on_prop_set, when_capability (with EvalContext) | predicates-extended |
| **#23** | review-comment followups (correctness tightening across #12–#16) | round-9-review-followups |
| **#24** | **T=169** perf followups: shared `internal/tday` + NodesByType/Relations{Src,Tgt} indexes | t169-perf-followups |
| **ffs0 #31** | **ontology v3.10.0** — D19.1 merged; WF19 gains has-occupant/is-occupant-of port pair and tgt_types {user, agent} | v3.10-session-occupancy |

### New / extended APIs

```
POST /t-hook/evaluate        { "urns": [...], "at": T }    → [{urn, at_t, fires, ...}]
GET  /t-hook/evaluate/{urn}  ?at=T                         → {urn, at_t, fires, ...}
GET  /t-cone                 ?session=urn&at=T             → occupier's projection
```

### New CLI flag

```
--sweep-interval=30s   (0 disables)
```

### Package additions

- `internal/tday` — single source of truth for the mo:os T-day epoch + `Now()` / `At(t)` helpers. Used by `cmd/moos`, `internal/transport`, `internal/kernel/sweep`.
- `internal/operad/occupancy.go` — `ResolveSessionOccupant(state, sessionURN)` and `CheckAdminCapability(state, actor)` (§M11/§M12).
- `internal/kernel/sweep.go` — `SweepOnce`, `RunTimedSweep`, `SweepTick`, `SetSweepActor`.

### Structural hardening (T=169)

- `graph.GraphState` gains 3 secondary indexes (JSON-omitted, rebuilt on load): `NodesByType`, `RelationsBySrc`, `RelationsByTgt`. Maintained by `fold.apply{ADD,LINK,UNLINK}`. Accessors `NodesOfType` / `RelationsFrom` / `RelationsTo` fall back to a full scan when the index is nil (keeps test fixtures correct without Rebuild).
- Hot paths (sweep, occupancy helpers, t-cone, when_capability) migrated from O(N)/O(R) scans to O(bucket-size).

### Firing semantics (locked for this round)

Sweep **proposes via WF13 governance** — NEVER auto-applies. Each firing hook produces a `governance_proposal` node with `status=pending`, `source_t_hook_urn`, `fires_at_t`, `proposed_envelope` (the decoded react_template). Admin sessions flip status to approved or rejected; a separate approver-reactor (not yet shipped) applies the envelope on approval. Matches §M12 fail-closed stance.

### Deferred to future rounds

- Approver reactor (governance_proposal.status=approved → apply proposed_envelope). **Still pending** — see T=169.5 section below for the state-machine prerequisites.
- `firing_state` property on t_hook — **shipped in T=169.5 (v3.11.0 + moos-kernel PR #25)**. See below.
- Bounded worker pool for `forwardToEagerTwins` (closed #8 Gemini flagged; structural, separate PR).
- Event-shape JSON round-trip fast-path in reactive engine (closed #8 Gemini flagged; cache parsed shape on t_hook node).
- `GraphState.Clone` copy-on-write (T=169 Gemini MEDIUM, TODO in code).

---

## T=169.5 — firing_state lifecycle (v3.11 + kernel PR #25)

Round-9.5 extends the sweep's idempotency from "does a governance_proposal with matching source_t_hook_urn exist?" (O(proposals) scan per tick) to a first-class state machine on the hook itself.

### Ontology (ffs0 PR #32, merged)

`t_hook.firing_state` enum: `{pending, proposed, approved, rejected, applied, closed}`. Default `pending`. Authority `kernel` — only sweep/reactor mutate it.

Transition graph:

```
pending  ──(sweep fires)────▶ proposed
proposed ──(admin approves)─▶ approved  ──(approver reactor applies)─▶ applied
proposed ──(admin rejects)──▶ rejected  (terminal)
applied                                  (terminal for one-shot hooks)
closed   (future: expires_at / manual)   (terminal)
```

### Kernel (moos-kernel PR #25)

- Sweep filters on `firing_state ∈ {"", "pending"}` (empty = pending default).
- Each firing emits TWO envelopes atomically in one ApplyProgram batch:
  1. `ADD urn:moos:proposal:kernel.<slug>-t<T>-seq<N>` (unchanged shape)
  2. `MUTATE <hookURN> firing_state pending → proposed`
- The old O(proposals) scan is gone. ApplyProgram is all-or-nothing, so the pair lands together or not at all (log-is-truth + CI-4 preserved).

### Rollback & migration

- Pre-v3.11 hooks (round-8 t_hooks, no firing_state on node) work transparently — first sweep evaluation produces an additive MUTATE setting firing_state → proposed. One-time per hook, idempotent on replay.
- Pre-v3.11 kernels reading v3.11-style hooks ignore the extra property. The ADD proposal shape is unchanged, so old-kernel idempotency-via-proposal-existence still works. Rollback-safe.

### Next (still pending)

- **Approver reactor** — watches `governance_proposal.status` MUTATEs, applies `proposed_envelope` on approve, transitions hook's firing_state proposed → applied | rejected. Needs design around actor-authority threading (whose authority is the reactor acting under when it applies? the admin who approved? a kernel-synthesized actor?).
- Bounded twin worker pool (now matters once Z440 peers).
- event_shape JSON fast-path.
- Clone-COW.

---

## T=169 round 10 — session generalization (closed; Conversations A–D done on Z440; hp-laptop retrofit in T=170 round 10.5 below)

Directive (sam, T=169): generalize the session concept beyond claude-code-per-kernel. Tools, CLI agents, third-party agentic frameworks; users + delegates; **kernel-bound workspace, not IDE conversation**. Completion-drive = session's purpose; spec-completion = the drive; incomplete data = gate-blocked realization.

Plan file: `C:/Users/hp/.claude/plans/1-if-specs-are-parsed-jellyfish.md` (decomposes round 10 into Conversations A/B/C/D + E for round 11).

### Doctrine note

`kb/research/session/20260419-t169-session-generalization.md` — the corrected model:

- **Session = (scope, purpose) × (host, owner, occupant)** — five orthogonal facets. Persistent, always-on, host-bound workspace. Tmux-session / Chrome-tab analogy. IDE conversations are ephemeral; their rewrites are traced via `actor_urn`, not via session nodes.
- **CT lingo corrected** — three separable algebras: per-session transition-monoid (identity = no-op morphism, not empty-object); operadic scope composition (sessions nest; birth-session as root scope); user/group topology as an orthogonal lattice (WF02 capability carries pieces of this, full formalization deferred).
- **Single-driver invariant** — has-occupant LINK single-valued per session (D19.1 merged v3.10; D22.2 formalizes at-most-one invariant in v3.12 proposals). Rotation = MUTATE of LINK target_urn.
- **Kernel-birth atomic pair** — ADD kernel:K + ADD session:<K-short> in the same ApplyProgram envelope (D22.4 proposed).
- **Purpose as higher-level semantic wiring** — not a leaf tool. Gradient φ(purpose) = φ(target_state) − φ(current_state). D22.1 wires purpose-steers-session; cos-similarity scoring deferred to wiring-proposer (T=240+). Purpose is a future-operational building-block, like tools; not actively steering rewrites until session layer is operational.
- **Disposition** — mis-classified `session:sam.claude-code-hp-*` nodes live only on hp-laptop kernel (Z440 is sovereign per §M9). Z440-local retrofit ADDed correctly-named `session:hp-z440.primary` as the birth-session. hp-laptop-side retire/replace is a separate conversation's work.

### Conversation A (complete, commit 37124d5) — doctrine + Z440 opening HG rewrites

8 envelopes applied atomically to Z440 kernel 0, log 180 → 188:

- ADD `program:sam.round10-session-generalization` (status=active, starts_t=169, target_t=175)
- ADD `purpose:sam.coherent-session-doctrine` (generic intent, not round-specific naming)
- LINK `purpose --WF18 composes--> program`
- ADD `t_hook:sam.round10-session-generalization.target` (fires_at=175, react: MUTATE program status→checkpoint)
- ADD `session:hp-z440.primary` (birth-session retrofit, started_at=kernel.created_at)
- LINK `session:hp-z440.primary --WF19 opens-on--> kernel:hp-z440.primary`
- ADD `session:sam.round10-session-generalization` (round workspace — Chrome-tabs demonstrator)
- LINK `session:sam.round10-session-generalization --WF19 opens-on--> kernel:hp-z440.primary`

Note: `has-occupant` LINKs declared in v3.10 as WF19 additional_port_pairs but not consumed by operad/loader.go yet — deferred to Conversation E / round 11.

### Conversation B (complete, commit 2a0a0f1) — ontology v3.11 → v3.12, first WF20 ceremony

Ontology-level promotion of 5 proposed grammar_fragments (HG-level status MUTATEs remain for hp-laptop kernel, which holds the proposal nodes):

- D19.2 session-view-prefs → `session.view_prefs` object property
- D19.3 session-pins-urn → WF19 additional_port_pair (session → any node)
- D19.4 session-filtered-by → WF19 additional_port_pair (session → view_filter)
- D20.1 session-mounts-tool → WF19 additional_port_pair (session → agent)
- D20.2 agent-invocation-protocol → `agent.invocation_protocol` enum {stdio, mcp, http}

Baseline session type fixes alongside the ceremony:
- `urn_pattern` → kernel-short | owner.purpose-slug
- `description` → persistent kernel-bound workspace semantics
- `seat_role` deprecated (single-driver-via-LINK model supersedes)
- Type-level note rewritten with transition-monoid + operadic-scope + user/group-lattice framing

Known code gap: `operad/loader.go` does not consume `additional_port_pairs`. The 4 pairs on WF19 (has-occupant + 3 new v3.12) validate only as the primary opens-on/occupied-by pair. Round 11 session-occupancy closes this.

### Conversation C (complete) — 4 new D22 grammar_fragment proposals

Applied to Z440 kernel 0, log 188 → 192:

- D22.1 session-has-purpose (port pair, 1-to-1 with rotation, WF19 extension)
- D22.2 session-single-driver-invariant (at-most-one has-occupant per session)
- D22.3 session-attach-detach (attach/detach/rotate verbs on single-driver model)
- D22.4 kernel-birth-session-pair (atomic-pair invariant for kernel ADDs; seed-code change blocked on this promotion)

All 4 status=proposed. No ontology bump.

### Conversation D (this update) — archive + running-state close

5 research notes moved to `dev/reference/research-archive/`:

- `20260418-t187-categorical-contract.md` (proofs hold by construction; landed)
- `20260418-t187-walk-answers-Q1-Q4.md` (Q1–Q4 answered + implemented)
- `20260414-t164-session-channel-purpose.md` (T=164 foundational work; in HG)
- `20260418-t168-t187-delivery-clock.md` (schedule live in v3.11 firing_state)
- `20260417-t166-wire-answer-folder-nesting.md` (Q5 answered, ontology-only)

Cross-refs updated across: ontology.json (`t164_delta_reference`), running-state.md, the new doctrine note, `wires/20260414-t164-wires-come-from.md`, `s1/20260418-t168-s0-operadic-layer.md`.

### Deferred to round 11 (Conversation E)

- session-occupancy Go implementation — 4 stacked PRs: RotateSessionOccupant + validator, §M11 liveness check in runtime.Apply, §M12 admin-cap gate extended to occupant chain, `GET /session/<urn>/occupant?at=T` endpoint.
- operad/loader.go gains multi-port-pair awareness (closes the additional_port_pairs gap).
- hp-laptop-side retire/replace of mis-classified session:sam.claude-code-hp-* nodes (UNLINK WF19 + ADD session:hp-laptop.primary + has-occupant wiring).
- kernel restart to load v3.12 (still pending explicit approval as of T=169 round-10 close).

### Open questions (not blocking)

- WF home for `purpose --has-purpose--> session` (D22.1) — WF19 extended likely; new WF21 possible. Promotion-ceremony decision, not design-ahead.
- Cos-similarity as one of many "cutting methods" (operads, type algebra, Ricci curvature, symmetry groups, Wolfram hypergraph, sheaf Laplacian, Procrustes rotation, cascade spectral radius). Candidate future discussion node: `program:sam.cutting-methods`.
- D20.3 agent-runs-in-harness + D20.4 agent-constructs-agent — for agents we author (Google ADK, PydanticAI, CLI), not the prepackaged IDE agents. Blocked on harness concept + CI-6 capability isolation + first bespoke-agent prototype.
- v310-13 purpose-arity2 — structural change to purpose (phi_current, phi_target as slots, not scalars). Later round, after operational experience with purpose at t-cone read time.
- Platform-as-host (Reading B, D22.5 future) — extending session.host beyond `kernel` to `platform` for non-mo:os agent runtimes (Google ADK, Anthropic workspace, external MCP daemons).

### Round-10 grammar_fragment census (Z440 kernel perspective)

4 new at status=proposed (D22.1–D22.4). Z440 kernel does not hold the 23 pre-existing rounds 5–8 proposals (those live only on hp-laptop kernel; sovereign-kernels principle).

### Kernel stats (Z440 kernel 0, post-Conversation A+C+MVP-spec projection)

- Log: 223 entries
- Ontology on-disk: v3.12.0 (kernel runtime still loading v3.11 — restart pending)
- Sessions: 4 (`hp-z440.primary` birth, `sam.round10-session-generalization` workspace, `sam.mvp-delivery` workspace, `vscode-codex-hp-z440.t161` legacy-mis-classified non-round-10-scope)
- Grammar_fragments: 4 (all D22.*)

---

## T=170 round 10.5 — hp-laptop retrofits (2026-04-20 ~18:00 CEST)

Round 10.5 lands the hp-laptop-side counterpart of z440-claude's round-10 work: the mis-classified session-WF19-LINKs are unwired, the hp-laptop birth-session is installed, and the five grammar_fragments that z440-claude promoted in the ontology ceremony get their HG-level status MUTATEd to match (`proposed → promoted → merged`). No new doctrine written — the z440-claude note is authoritative. This is pure mechanical sync.

### What landed (single atomic batch, 14 envelopes, hp-laptop kernel)

| Envelope | Details |
|----------|---------|
| UNLINK ×2 | `wf19.sam.claude-code-hp-laptop.opens-on` + `wf19.sam.claude-code-hp-z440.opens-on` removed; sessions persist un-wired |
| ADD ×1 | `session:hp-laptop.primary` (birth-session; `started_at=2026-04-03T01:05:11Z` ≡ kernel's `created_at`; `local_t=0`) |
| LINK ×1 | `wf19.hp-laptop.primary.opens-on` — birth-session → kernel |
| MUTATE ×10 | D19.2, D19.3, D19.4, D20.1, D20.2 each: status `proposed → promoted` then `promoted → merged` (WF20, admin authority) |

Corrected state-machine enum note: grammar_fragment.status is `proposed → rejected | promoted | merged` per ontology; z440-claude's conv sum used "approved/applied" casually — the retrofit uses the correct enum values.

### Explicitly **not** done (deferred)

- **`session:hp-laptop.primary --has-occupant--> agent:claude-code.hp-laptop`** — v3.11 runtime loader doesn't consume `additional_port_pairs`, so the `has-occupant` port would fail validation. Deferred until Round-11 Conversation E PR 1 (loader extension) lands.
- **Z440 side identical work** (analogous UNLINKs + birth-session ADD for any kernel missing it) — z440-claude's `t169round10_next_plan.md` owns that. Not hp-laptop's call.
- **Kernel restart to load v3.12** — destructive, pending explicit sam approval.
- **`POST /twin/ingest` of `kb/moos_from_HPLAP.jsonl`** — file is in ffs0 git; not applied into z440's running HG. Per §M9 sovereign kernels, divergence is normal — this stays optional.

### Kernel stats (hp-laptop kernel, post-retrofit + post-restart)

- Log: 575 entries (+14 from the atomic batch)
- Ontology at runtime: **v3.12.0** — kernel restarted T=170 ~18:01 CEST (PID 5944 → 1208)
- Replay on startup: clean, 575 rewrites applied against v3.12 validator; one known idempotent skip (`twin_link:hp-laptop.mtdc` duplicate ADD at seq 347 index 354 — pre-existing, benign)
- Kernel binary pre-round-9 (mtime 2026-04-18 00:12) — no sweep loop. Rebuild pending if sweep-on-hp-laptop matters; for now hp-laptop runs v3.12 validator + HTTP/MCP surface only
- Sessions at this kernel: `session:hp-laptop.primary` (birth, WF19-LINKed) + `session:sam.claude-code-hp-laptop` + `session:sam.claude-code-hp-z440` (both persisted without WF19 binding) + the historical `.t164/.t167/.t168` nodes
- Grammar_fragments at this kernel: 23 total; 5 now `status=merged` (D19.2/D19.3/D19.4/D20.1/D20.2); 18 remaining `status=proposed` (including 4 D22.* that live only on Z440 — still unmirrored here)

### Open: D22.* proposals un-mirrored on hp-laptop

D22.1 session-has-purpose · D22.2 single-driver invariant · D22.3 attach/detach verbs · D22.4 kernel-birth-session pair were ADDed only on Z440 kernel. Mirroring them onto hp-laptop kernel is a later round's call — not urgent; doctrine is already in the shared note. Flagged for future.

### Claude skills scaffolded (T=170)

Two skills added under `~/.claude/skills/` — both triggered automatically from now on:

- **`moos-state-readback`** — 10-sec open-of-round dance: `git fetch` on ffs0 + moos-kernel, diff vs origin, running-state header read, kernel PID + port check, MCP `/healthz` ping, handoff-issue comment scan. Prevents the "local `git status` lies by omission" failure mode that cost T=170 an initial plan revision.
- **`moos-round-close`** — end-of-round checklist: running-state update (header + kernel block + new section + Key URNs), single atomic commit (HEREDOC-formatted), push, optional handoff-issue comment. Prevents partial closes.

These supplement the existing `moos-rewrite-envelope` skill (envelope-shape cheat sheet). Trio now covers open + rewrite + close. Also shared at `dev/claude-skills/` for any workstation to install via copy-to-`~/.claude/skills/`.

---

## T=170 round 10.6 — doctrine + S0 sketch + 5 v3.13-candidate fragments + tidy

Round 10.6 lands the "coat thing" conversation as three artifacts plus HG hydration plus a tidy:

### Artifacts

- **`dev/reference/research-archive/20260420-t170-functorial-semantics-explicit.md`** — names FS as the spine of mo:os; identifies 3 places it already lives (Fold, WF20 Promote⊣Express, v310-2-crosswalk three-views identity); applies the lens to federation (kernels as sites, sheaves over kernel-category, routing = stalk lookup, DNS = presheaf evaluation, free-set = signature colimit, lineage = spawned-by subcategory, Wolfram multiway = the unnamed coherence layer).
- **`dev/reference/research-archive/20260420-t170-s0-materialization.md`** — draft type specs for op_node / slot / yields / threading / weave as v3.13-candidate types. Not hydrated this round; sketch only.
- **`dev/reference/research-archive/20260420-t170-branching-strategy.md`** — branching question write-down (archived T=173). Answer: keep current pattern (one branch per kernel, PRs for coordination). Four candidate reconstructions listed in the note.

### Hydration — 5 v3.13 grammar_fragments ADDed (all status=proposed)

| URN suffix | Kind | Crystallises |
|---|---|---|
| `v313-1-functorial-semantics-spine` | wf_clause (stretch — true kind = doctrine; fragment_kind enum extension is itself a future proposal) | FS as the spine; unshipped halves = Express + CI-6 |
| `v313-2-kernel-operadic-signature` | type (S1) | Each kernel publishes `kernel_operadic_signature` with ontology_version + type_count + wf_count + signature_hash |
| `v313-3-kernel-lineage` | port | WF19-extension `spawned-by / spawned` on kernel; initial-kernel is root; tree-structured lineage |
| `v313-4-federation-presheaf` | wf_clause (stretch — doctrine) | Federation as sheaf over category of kernels; routing=stalk, DNS=presheaf evaluation, sheaf-violation → WF13 governance_proposal |
| `v313-5-diary` | type (S2) | `diary` type + canonical instance `urn:moos:diary:moos.main` (moos the dachshund, narrator) |

### Tidy

4 memory-snapshot files moved from `kb/research/` (top-level clutter) → `dev/reference/research-archive/`:
- `t169_memory_MEMORY.md`
- `t169_memory_project_moos.md`
- `t169_memory_project_prg_naming.md`
- `t169_memory_user_sam.md`

These captured the T=169 consolidated-memory moment; the live Claude MEMORY has moved on, and the snapshots are historical from here.

### Grammar_fragment census (hp-laptop kernel)

After round 10.5+10.6: 28 total (was 23 pre-T=170).
- `status=merged`: 5 (D19.2/D19.3/D19.4/D20.1/D20.2 — the v3.12 ceremony)
- `status=proposed`: 23 (18 pre-existing + 5 new v313-1..v313-5)

Z440 kernel's 4 D22.* proposals (D22.1..D22.4) still live only on Z440.

### Key URNs added this round

```
urn:moos:grammar_fragment:v313-1-functorial-semantics-spine  (status=proposed, doctrine-via-wf_clause-stretch)
urn:moos:grammar_fragment:v313-2-kernel-operadic-signature   (status=proposed, type)
urn:moos:grammar_fragment:v313-3-kernel-lineage              (status=proposed, port)
urn:moos:grammar_fragment:v313-4-federation-presheaf         (status=proposed, doctrine-via-wf_clause-stretch)
urn:moos:grammar_fragment:v313-5-diary                       (status=proposed, type)
```

### Explicit next steps, deferred

- **Promote these 5** — needs a second WF20 ceremony (admin cap, doctrine review, batch MUTATE chain). Should rollup with Z440's D22.1..D22.4 when z440-claude completes Round 11.
- **Extend fragment_kind enum to include 'doctrine'** — itself a candidate proposal; meta-recursive. Track for v3.14.
- **S0 type specs (op_node/slot/yields/threading/weave)** — sketch only; hydration in a later round.
- **FS-spine + federation-presheaf mirrored onto Z440** — z440-claude's call when they pull.
- **Express adjoint implementation** — pattern-mining algorithm from S2 → S4 overlays. Not code-ready; design pending.

---

## T=171 round 10.7 — Antigravity moos-diary doctrine & alignment

**Date:** April 21, 2026 (~09:30 CEST)
Antigravity IDE ingestion of the moos-diary multimodal vision. Corrected `session` ontology against Guido's strict S4 parameterization rules (no host conflation, stripped unauthorized `WF22`/`WF18` syntax). Drafted `kb/moos-diary/t171.md` establishing the dachshund's 1-year anniversary of watching Sam struggle. `z440-claude` handles Z440 kernel restart and Round 11 implementation next.

---

## MVP delivery — spec-in-HG (projected T=169, 2026-04-19 ~15:00)

Round-10 close-out projection: the 6-gate path to MVP lives in the HG as time-dependent programs + t_hooks + calendar_events + a dedicated session. Each gate is a `program` node with `target_t` + a `t_hook` firing at that T that MUTATEs the program status → checkpoint on arrival. Each gate also has a `calendar_event` as IRL-time anchor. `sam.mvp-delivery` session pins them operationally (scope-via-pins pending loader extension per round 11 G1).

Purpose: `urn:moos:purpose:sam.mvp-sovereign-knowledge-os` — *"Demo-able sovereign knowledge OS: local kernel stable, one real knowledge channel flowing in, HDC reasoning over it, live moos-viz visualization, auditable log-is-truth, twin federation via mtdc. A non-technical friend can sit in front of one screen and see: your data, your graph, your AI, no cloud. Anchored at T=190 (2026-05-10)."*

### Gate map

| Gate | Program URN | T | Wall-clock | Status | Dependencies |
|---|---|---|---|---|---|
| parent | `program:sam.mvp-delivery` | 190 | 2026-05-10 | active | composes G1–G6 |
| G1 session layer | `program:sam.mvp-g1-session-layer` | 173 | 2026-04-23 | active | scheduled-after `round10-session-generalization` |
| G2 approver reactor | `program:sam.mvp-g2-approver-reactor` | 176 | 2026-04-26 | draft | after G1 (firing_state needs session infra) |
| G3 first channel | `program:sam.mvp-g3-first-channel` | 180 | 2026-04-30 | draft | after G2 (real-data flow needs approver) |
| G4 moos-viz live | `program:sam.mvp-g4-moos-viz-live` | 182 | 2026-05-02 | draft | parallel with G3 (reads state independent of data) |
| G5 HDC query demo | `program:sam.mvp-g5-hdc-query-demo` | 185 | 2026-05-05 | draft | after G3 (needs data to score) |
| G6 twin-deploy | `program:sam.mvp-g6-twin-deploy` | 190 | 2026-05-10 | draft | after T=187 delivery-window-opens + G1-G5 |

### Dependency sketch

```
round10-session-generalization (done) ─scheduled-after→ G1 (session layer code)
                                                         │
                                                         ▼
                                                        G2 (approver reactor)
                                                         │
                                       ┌─────────────────┴─────────────────┐
                                       ▼                                   ▼
                                      G3 (first channel)               G4 (moos-viz live)
                                       │
                                       ▼
                                      G5 (HDC query demo)
                                       │                  T=187 delivery-window-opens
                                       ▼                  │
                                      G6 (twin-deploy mtdc) ◀─ delivery-window
                                       │
                                       ▼
                                      MVP close (T=190)
```

### t_hook map

Each gate has a `fires_at` t_hook (predicate `{kind: fires_at, t: <target_t>}`, react_template MUTATE program.status → checkpoint, firing_state=pending). Once the v3.11 sweep tick crosses T=173/176/180/182/185/190, hooks auto-fire proposing checkpoint MUTATEs. Approver reactor (G2 itself!) is the thing that actually applies them — bootstrap dependency: G1+G2 must land before later hooks can auto-progress status. Until G2, gates advance via manual sam-authored MUTATEs.

### Calendar anchor map

Six calendar_event nodes bridge kernel-T to wall-clock:

| URN | Date | t_day | Anchor |
|---|---|---|---|
| `cal:2026-04-23.mvp-g1` | 2026-04-23 | 173 | G1 target |
| `cal:2026-04-26.mvp-g2` | 2026-04-26 | 176 | G2 target |
| `cal:2026-04-30.mvp-g3` | 2026-04-30 | 180 | G3 target |
| `cal:2026-05-02.mvp-g4` | 2026-05-02 | 182 | G4 target |
| `cal:2026-05-05.mvp-g5` | 2026-05-05 | 185 | G5 target |
| `cal:2026-05-10.mvp-close` | 2026-05-10 | 190 | MVP close + G6 target |

Color: all purple (PRG-tracked, per `calendar_event` color_label convention).

### Session anchor

`urn:moos:session:sam.mvp-delivery` — sam's persistent MVP workspace, WF19 opens-on kernel:hp-z440.primary. Currently occupant-less at the HG level (has-occupant LINKs blocked on loader extension); operationally driven by whichever agent is working on the MVP at the moment. Pins pending until D19.3 pins-urn LINK support lands in round 11 G1 (loader awareness).

### Existing Z440 infrastructure MVP can reuse (posted by antigravity.hp-z440 earlier T=169)

While scoping MVP gates I realized Z440's HG was already populated with several MVP-relevant nodes — antigravity on Z440 posted them in a 20-rewrite burst at log_seq 161-180. Not reinventing; MVP gates reference these:

- **9 source_feeds already configured**: `feed:arxiv.cs-ai`, `feed:arxiv.physics`, `feed:yt.mlst`, `feed:yt.discover-ai`, `feed:paperswithcode`, `feed:lmsys-arena`, `feed:web.lmsys-arena`, `feed:web.paperswithcode`, `feed:ifrs.news`. G3 = pick one, flip to active — default `arxiv.cs-ai` (clean RSS, public, no auth). MVP-G3 scope MUTATEd to reference these.
- **Ingest pipeline already wired**: `watcher:raw-ki-claim-extract` + `reactor:emit-claim-extract-task`. The ingest → raw knowledge_item ADD → claim-extract reactor chain is present. G3 likely just activates the fetch-side (HTTP poll / RSS parse).
- **2 classification_schemes with tag LINKs**: `scheme:arxiv` (tags: cs-ai, cs-lg, math-ct, physics-hep-th, q-bio), `scheme:ifrs` (tags: 9, 15, 16, 17). G5 HDC scoring has ready-made classification frames for cos-similarity. MVP-G5 scope MUTATEd to reference scheme:arxiv.
- **5 git_issues**: ffs0#13/14/15 + moos-config#5/6. Pre-existing project-board wiring — MVP gates can add more as round-11+ PRs open. Pattern is `git_issue` type nodes mirroring GitHub issue numbers.
- **Watcher/reactor pairs also present**: `watcher:tool.verify_baseline` + `reactor:tool.verify_baseline`. Test-harness wiring; outside MVP scope but confirms the reactive-engine pattern is exercised on Z440.

The 4 federation kernel nodes (hp-z440.primary, lola, menno, moos) all exist on Z440; kernels 1-3 are dormant. MVP-G6 twin-deploy targets the mtdc CF tunnel (not these federation shards).

Actor distribution on Z440 kernel log (log_seq 1-223 at round-10 close):
- `user:sam` — 191 rewrites (my round-10 + mvp + pre-existing)
- `agent:antigravity.hp-z440` — 20 rewrites (the infrastructure burst above)
- `user:lola`, `user:menno`, `user:moos` — 4 each (federation-user placeholders)
- `$actor` — 2 (template-stub debris; harmless)

Claude-code.hp-laptop has NOT posted directly to Z440 kernel (sovereign-kernels per §M9; hp-laptop's work lives on hp-laptop kernel). The `kb/moos_from_HPLAP.jsonl` file (committed to ffs0) is hp-laptop's log snapshot for reference.

### Why project the MVP plan into HG

- **Queryability**: `GET /t-cone?session=sam.mvp-delivery&at=185` tells us at T=185 which gates fired, which are still open, which are blocked.
- **MUTATE-ability**: as reality shifts (target slips, dependencies re-order), `MUTATE target_t` on any program; log records the revision. No spreadsheet, no planning tool — the HG IS the plan.
- **Auditability**: log-is-truth over every adjustment. Future-sam can run `fold?to=T=185` and see exactly what the plan looked like at that point.
- **Composability**: post-MVP programs can `depends-on` `mvp-delivery` directly. The MVP is a node like any other — it doesn't disappear once shipped; it becomes provenance for everything downstream.
- **Spec-realizer applied to itself**: the entire pattern sam articulated ("specs + incomplete data mapped over time") describes how to treat any idea. Doing it to the MVP plan is the test of the pattern's self-consistency.

---

## Key URNs

```
urn:moos:user:sam
urn:moos:kernel:hp-laptop.primary
urn:moos:kernel:hp-z440.primary
urn:moos:program:sam.t187-kernel-proper
urn:moos:program:sam.t164-room-tying  (completed)
urn:moos:program:sam.ontology-publication-v3.9  (v3.9 publication carrier)

# Round 4 merged sub-programs (by-monitoring-scope names, no t-ref prefix)
urn:moos:program:sam.session-occupancy
urn:moos:program:sam.session-timeline
urn:moos:program:sam.session-view
urn:moos:program:sam.session-tools
urn:moos:program:sam.hook-predicates
urn:moos:program:sam.ontology-publication-prg
urn:moos:program:sam.external-op

urn:moos:purpose:sam.t164-tie-the-room-together
urn:moos:agent:claude-code.hp-laptop
urn:moos:agent:claude-code.hp-z440

# T=170 round 10.5 — hp-laptop retrofit
urn:moos:session:hp-laptop.primary   (birth-session, WF19 opens-on kernel:hp-laptop.primary)
urn:moos:session:sam.claude-code-hp-laptop   (persisted, WF19 UNLINKed T=170)
urn:moos:session:sam.claude-code-hp-z440     (persisted, WF19 UNLINKed T=170)

# Round 5 demo nodes (v3.9 types in use)
urn:moos:view_filter:sam.important-programs
urn:moos:view_filter:sam.t168-open-deliverables
urn:moos:agent:sam.claude-code-desktop  (placeholder future occupant, §M19)
urn:moos:grammar_fragment:d19-1-session-has-occupant  (status=proposed)
urn:moos:grammar_fragment:d20-2-agent-invocation-protocol  (status=proposed)
urn:moos:grammar_fragment:d14-1-time-predicates  (status=proposed)

# Round 6 v3.10 grammar_fragment proposals (all status=proposed)
urn:moos:grammar_fragment:v310-1-port-binding
urn:moos:grammar_fragment:v310-2-crosswalk
urn:moos:grammar_fragment:v310-3-fiber-completeness
urn:moos:grammar_fragment:v310-4-branchial-ricci
urn:moos:grammar_fragment:v310-5-cascade-spectral-bound
urn:moos:grammar_fragment:v310-6-sheaf-laplacian-inconsistency

# Round 7 §M18..§M20 backlog proposals (all status=proposed)
urn:moos:grammar_fragment:d19-2-session-view-prefs
urn:moos:grammar_fragment:d19-3-session-pins-urn
urn:moos:grammar_fragment:d19-4-session-filtered-by
urn:moos:grammar_fragment:d20-1-session-mounts-tool
urn:moos:grammar_fragment:d20-3-agent-runs-in-harness
urn:moos:grammar_fragment:d20-4-agent-constructs-agent

# Round 7 v3.10 deferred-type proposals (all status=proposed)
urn:moos:grammar_fragment:v310-7-benchmark
urn:moos:grammar_fragment:v310-8-evaluation
urn:moos:grammar_fragment:v310-9-dataset
urn:moos:grammar_fragment:v310-10-dsl

# Round 8 successor programs (T=187 as delivery anchor)
urn:moos:program:sam.v310-delivery       (starts_t=220, target_t=240, status=draft)
urn:moos:program:sam.wiring-proposer     (starts_t=240, target_t=250, status=inert)

# Round 8 delivery-clock t_hooks (10)
urn:moos:t_hook:sam.t187.delivery-opens          (fires_at=187)
urn:moos:t_hook:sam.t187.delivery-closes         (closes_at=220)
urn:moos:t_hook:sam.t187.checkpoint.session-chrono-t     (fires_at=195)
urn:moos:t_hook:sam.t187.checkpoint.system-instruction   (fires_at=200)
urn:moos:t_hook:sam.t187.checkpoint.strata-enforcement   (fires_at=205)
urn:moos:t_hook:sam.t187.checkpoint.fold-endpoint        (fires_at=210)
urn:moos:t_hook:sam.t187.checkpoint.http3-quic           (fires_at=215)
urn:moos:t_hook:sam.t187.checkpoint.twin-deploy-mtdc     (fires_at=220)
urn:moos:t_hook:sam.v310-delivery.startable      (all_of fires_at=220, after_urn kernel-proper=completed)
urn:moos:t_hook:sam.wiring-proposer.startable    (all_of fires_at=240, after_urn kernel-proper=completed, after_urn v310-delivery=completed)

# Round 8 external_op IRL gates (3 + 1 test)
urn:moos:external_op:sam.mtdc-kernel-start           (deadline_t=187)
urn:moos:external_op:sam.cf-tunnel-api-mtdc          (deadline_t=187)
urn:moos:external_op:sam.ontology-bootstrap-mtdc     (deadline_t=220)
urn:moos:external_op:sam.test                        (status=cancelled — HTTP-API verification artifact)

# Round 8 grammar_fragment proposals (all status=proposed)
urn:moos:grammar_fragment:v310-11-ontology-publication
urn:moos:grammar_fragment:v310-12-grammar-fragment-enrichment
urn:moos:grammar_fragment:v310-13-purpose-arity2
urn:moos:grammar_fragment:v310-14-startable-status

# Live sessions on hp-laptop kernel (pre-round-10 model; mis-classified under the v3.12 kernel-bound model — scheduled for retire/replace in a hp-laptop-side conversation)
urn:moos:session:sam.claude-code-hp-laptop  (WF19-LINKed, seat_role=occupier)
urn:moos:session:sam.claude-code-hp-z440    (WF19-LINKed, seat_role=observer)

# Round 10 — corrected session nodes (Z440 kernel only; hp-laptop kernel gets its own in a separate conversation)
urn:moos:session:hp-z440.primary                      (birth-session; WF19 opens-on kernel:hp-z440.primary)
urn:moos:session:sam.round10-session-generalization   (round-10 workspace; WF19 opens-on kernel:hp-z440.primary)

# Round 10 new nodes
urn:moos:program:sam.round10-session-generalization  (starts_t=169, target_t=175, status=active)
urn:moos:purpose:sam.coherent-session-doctrine       (generic intent, reusable across rounds)
urn:moos:t_hook:sam.round10-session-generalization.target  (fires_at=175, firing_state=pending)

# Round 10 D22 grammar_fragment proposals (all status=proposed on Z440 kernel)
urn:moos:grammar_fragment:d22-1-session-has-purpose
urn:moos:grammar_fragment:d22-2-session-single-driver-invariant
urn:moos:grammar_fragment:d22-3-session-attach-detach
urn:moos:grammar_fragment:d22-4-kernel-birth-session-pair

# Archived sessions (provenance; no WF19 LINK)
urn:moos:session:sam.claude-code-hp-laptop.t164
urn:moos:session:sam.claude-code-hp-laptop.t167
urn:moos:session:sam.claude-code-hp-z440.t168
```

---

## Architecture

```
hp-laptop:  kernel :8000 | MCP :8080
            CF tunnel: kernel.my-tiny-data-collider.nl (SSE) | api.my-tiny-data-collider.nl (REST)
Z440:       kernel :8000–:8003 | router :9000 (federation, WF16)
```

Agents per workstation: `claude-code` · `vscode-codex` · `antigravity`
Repos: `moos-kernel` (Go, public) · `moos-router` · `ffs0` (this workspace, private)

### moos-router (feat/type-map-routing — merged PR #2)
Type routing via `--type-map type_id=url` checked before URN-prefix shard rules.
Companion: `dev/scripts/generate_type_map.py` emits flags from ontology.json strata.

---

## Codex (archived)

`dev/reference/research-archive/20260408-foundation-t158.md` — foundations, nomenclature,
node types, two-presheaf model, functorial semantics, federation architecture.
Active type system: `kb/superset/ontology.json` supersedes for formal types.
