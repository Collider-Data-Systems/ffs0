# T=247 evening — GitHub takeover + the #40 two-seat race

> Zappa / Cowork-Z440. Ledger in `kb/superset/running-state.md` (T=247 evening entry, `899045d`); this is the narrative + lessons.

## The arc

Sam handed the Zappa seat full ownership of the GitHub surface — org `Collider-Data-Systems`, teams, and the mo:os project board (#4) — in one line: "completely take over the use of project board and github teams organizations etc. think pls." The seat responded with a five-agent audit workflow (org/teams, repo governance, board baseline, ffs0 ops inventory, completeness critic), then landed the operational layer in four ffs0 PRs (#113–#116) plus a workflow replication pair (moos-kernel#43, moos-router#7).

The audit's sharpest finding was archaeological: `project-sync.yml` had been a **silent no-op for months** — it targeted the legacy user project `MSD21091969/#1` with `github.token`, which cannot write org Projects v2 at all; the `PROJECTS_TOKEN` secret existed since March but the workflow never referenced it. The repoint proved itself within minutes: the Action added its own PR to board #4 on the PR's own events.

Mid-arc, the loop caught Sam's go-ahead on moos-kernel#40 (the Δ17 multi-writer forensics) — and produced the evening's best systems story: **two seats implemented the same fix 21 seconds apart** (John Lydon's moos-kernel#41 from the laptop governance seat, Zappa's moos-kernel#42 from Z440). Each seat then reviewed the *other's* PR and independently conceded the other's strength: #42's lock architecture (held handle on the jsonl itself — Windows deny-write is mandatory sharing, so even lock-unaware old binaries are blocked during the mixed-binary migration window, which is exactly the incident class) versus #41's operational hardening (escape hatch, errno discrimination, atomic `LogStats`, docs). Sam's plan of record: moos-kernel#42 the vehicle, #41's hardening folded in, #41 closed superseded. Squash-merged as `4c99df8` after John caught the last hazard — a `closes #40` keyword in a commit body that would have auto-closed the issue with (d)/(e) still open.

## Lessons

1. **The board is only as good as its round-trip key.** 80/84 items had no `HG URN`; the G-direction was structurally impossible. Standing rule now: every item lands with full bridge fields at creation — the Action adds Status, the creating seat backfills the rest in the same breath (`Sync-ProjectBoard.ps1 -Mode Attach`).
2. **Race resolution by mutual review beats ownership disputes.** Both seats read both diffs; the merge took the union of strengths. The 21-second collision cost nothing but produced cross-verification no single seat would have had.
3. **Evidence over review-opinion, in both directions.** Copilot's `String!`-vs-`ID` finding was refuted by schema introspection; its Append-after-Close finding was real and is now guarded + tested. Verify, don't defer.
4. **Mandatory vs advisory locking is a doctrine-grade asymmetry.** Windows share modes protect the log from processes that never heard of the lock protocol; unix flock only binds the cooperating. The platform tests encode this instead of papering over it.
5. **Closing keywords are load-bearing.** Squash-merge with a curated message is the clean way to land a partial fix without GitHub auto-closing the umbrella issue.

## Open tails (as of this note)

- moos-kernel#40(d) executable half: Guido's `Test-MoosFederation -Mode Doctor` Pass 2b (plan posted; no PR yet).
- moos-kernel#40(e): Sam's ops sequencing — repoint the two hp-laptop stdio sidecars (→ live engine MCP :8080) **before** restarting the laptop kernel onto `4c99df8`; both kernels still run pre-fix binaries.
- ffs0#112: one laptop surface act (stale user-level `moos.serverPath`); optional hardening split to #117 (Karpathy).
- Owner hardening queue in `dev/runbooks/github-org-operations.md`: 2FA flip (no-lockout verified), `PROJECTS_TOKEN` → org secret, Q2 rulesets (classifier-blocked, command ready), Q4 legacy project close, demo-repository archive, MoosT2025 least-privilege.

## Close-out (T=247 night, same session)

Every tail above closed before the day ended:

- **moos-kernel#40(d)** landed both halves — doctrine (ffs0#116) and Guido's Doctor executable (ffs0#121, verified against a real replay of hp-laptop's own log: `drift: 17 duplicate entries` reproduced exactly).
- **moos-kernel#40(e)** executed by Sam on hp-laptop, with a live demonstration of the exact hazard the fix targets: the old Claude Desktop config's sidecar, now running the *new* binary, won the single-writer lock ahead of the booting engine (kernel) and blocked it — zero corruption, wrong process owned the log, resolved by killing the sidecar. Config permanently repointed to `mcp-remote http://localhost:8080/sse` afterward. Z440's four engines (kernels), handled by Zappa, followed order-free with no incident. **`moos-kernel#44`** (the tracking issue born mid-arc for this exact step) closed the whole thing.
- **ffs0#112** closed by Karpathy once the fallback (#117/#120) was verified; a genuine sub-finding fell out of the wrap-up receipt — the moos-lsp extension had never actually been installed in hp-laptop's VS Code, so no fix in this arc had been seen working in a live editor there. Split to **#122**, closed same night: two packaging blockers found and fixed (a corrupt `npx` cache entry, then the manifest fields from this diary's original note), extension built, installed, and editor-verified — live warning rendered, server spawned via workspace discovery. A trailing 2-line manifest fix (#123) followed to make the install path reproducible for future boxes.
- **One new, harmless finding** surfaced during the Z440 restart: all 3 dormant twin engines (kernels) show the Δ40-shaped symptom (`log_len > max_log_seq`) but from an unrelated cause — pre-`log_seq`-field seed lines from April default to zero and get miscounted as duplicates. Filed as **moos-kernel#45**, low priority, does not touch anything load-bearing.
- Owner hardening queue is unchanged and still open — none of it was urgent enough to block the deploy arc.

**Board at close: 99 items, exactly 1 open (moos-kernel#45).** Ledger: `kb/superset/running-state.md` T=247 night-close entry, `8c943cc`.

authored-by: agent:claude-cowork.hp-z440 / session:sam.z440-cowork-workspace / github-takeover-t247
