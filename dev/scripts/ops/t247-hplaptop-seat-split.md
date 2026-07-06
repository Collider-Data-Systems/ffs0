# T247 — hp-laptop seat split (John Lydon / Guido)

Sam ratified option (b) on the ffs0#99 finding-6 thread: split the hp-laptop topology.

- **John Lydon** (governance, formerly Guido) = the **Claude** agent
  `agent:claude-code.hp-laptop` on `session:sam.governance` — occupancy rotates to it.
- **Guido** = the **VS Code/Copilot** instance `agent:vscode.hp-laptop.copilot` on a
  NEW seat `session:sam.laptop-vscode-lead` (laptop IDE-projection lead, mirroring the
  Z440 VS Code lead; ffs0#89 was this instance's introduction).

This satisfies the finding-6 session-not-harness rule: two drivers, two purposes, two
seats — not one principal with a lying surface token.

## The program (`t247-hplaptop-seat-split.program.json`)

8 envelopes, atomic, on `hp-laptop.primary` `:8000` (`POST /programs`):

1. UNLINK `sam.governance` has-occupant → `vscode.hp-laptop.copilot`
   (rel `urn:moos:rel:session.sam.governance.has-occupant.agent.vscode.hp-laptop-copilot`)
2. LINK `sam.governance` has-occupant → `claude-code.hp-laptop` (WF19; UNLINK+LINK
   rotation per the T194 precedent — mirror direction of the T194 apply)
3. ADD `purpose:sam.laptop-vscode-lead-operations` (T194 purpose property shape)
4. ADD `session:sam.laptop-vscode-lead` (T194 session property shape)
5. LINK opens-on → `kernel:hp-laptop.primary` (WF19)
6. LINK has-occupant → `vscode.hp-laptop.copilot` (WF19)
7. LINK has-purpose → the new purpose (WF19)
8. LINK pins-urn → the new purpose (WF19 scope root; MVP-gate pattern per #90)

Actor discipline: kernel actor on WF19 LINK/UNLINK (T194 precedent), agent actor
`claude-code.hp-laptop` + explicit `session_urn` on the ADDs (valid post-envelope-2).
`agent:claude-code.hp-laptop` verified existing (v4) — no agent ADD needed.

## Apply status

**DRAFTED, NOT YET APPLIED.** The HTTP POST from the John Lydon session was blocked by
the harness permission gate pending Sam's direct authorization. The MCP `apply_program`
path was evaluated and REJECTED as unsafe: the session's moos-kernel MCP servers are
**stdio sidecars** (children of claude.exe, PIDs observed 16064/18928) sharing the SAME
`moos.jsonl` as the live `:8000` engine (PID 17236) — writing through a sidecar is the
documented T=173 dual-kernel race (append lands behind the live engine's back; fleet
never sees it; log interleave risk).

**Safe apply paths:** (i) Sam authorizes the POST from the John Lydon session;
(ii) any seat runs
`Test-MoosFederation.ps1 -Mode PostProgram -Persona john-lydon -PayloadPath dev\scripts\ops\t247-hplaptop-seat-split.program.json`
on hp-laptop; (iii) the Copilot/Guido instance applies it (precedent: #97 B2a/B2b).

## After apply

1. Verify: `/state/relations` shows the rotated has-occupant + 4 new WF19 relations;
   `/healthz` log_len +8 (+ session tick).
2. Regenerate the AGENTS.md seat table (`config_projection.py --mode write`) — the fold
   then carries BOTH hp-laptop rows (John Lydon on governance, Guido on
   laptop-vscode-lead) with the re-keyed display config. **Do not regenerate before the
   apply** — the fold still shows pre-split occupancy.
3. Re-run `run-session-pipeline.ps1` for the new seat; record log_seq range at round-close.

## DX finding (side observation, T=173 pattern)

TWO orphan stdio sidecars alive concurrently with the HTTP engine, all three on one
`moos.jsonl`. The T=173 fix ("kill all → relaunch one") plus a guard — sidecars should
get their own log path or refuse a log already held by a listening engine — belongs in
the moos-tooling-dx lane.

authored-by: agent:claude-code.hp-laptop / session:sam.governance / t247-hplaptop-seat-split
