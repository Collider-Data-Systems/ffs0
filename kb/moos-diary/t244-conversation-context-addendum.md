# T216 → T244 — the conversational record (addendum)

> Companion to `t244-manifold-arc-baseline-wrapup.md`. That entry was written from the git,
> issue and engine-log evidence; this one recovers what only the **local agent state** knows —
> mined (at Sam's request, T=244) from the Antigravity brain
> (`~/.gemini/antigravity/{brain,conversations}`), the Claude plan files (`~/.claude/plans`)
> and the Claude Code/Cowork transcript chain (`~/.claude/projects`). Personal material is
> kept at topic level; no credential material is reproduced. S0 narrative — evidence, not truth.

## How the fleet actually coordinated (the part no commit shows)

- **Issue #54 was a live message bus.** For most of the first week, Cowork-Z440 auto-polled
  it on a 3-minute cadence while Sam supervised three-to-four agents simultaneously and
  **rotated which agent held "lead."** The multi-seat doctrine that later became formal
  (acks, handoff ledgers, division-of-labor) was first improvised here.
- **Overnight autonomy predates the clearing round.** On Jun 7–8 the Cowork seat ran a fully
  autonomous 30-minute watch over the `.com` nameserver migration while Sam slept. The
  multi-day stall was root-caused to an **unverified ICANN registrant contact** at
  Yourhosting — resolved only after Sam emailed the registrar and the account-wide lock was
  lifted (~Jun 17). None of that diagnosis survives anywhere in git.
- **The session chain never broke.** One continuous Cowork lineage runs Jun 5 → Jul 3
  (8ec916e6 → compaction → 8a0abab1 → the T231 relaunch that became the current session,
  which itself had a 7-second false start, retried two minutes later). Antigravity mirrors
  this: its 33 MB "conversation" is a **single reused thread from Jun 5 to Jul 3**. Both
  seats were bootstrapped across gaps by **agent-authored handoff prompts** — the pattern
  `/orient` and `moos-seat-hydration` later mechanized.
- **Deliberate model economics.** Sam switched models mid-session by phase — lighter models
  for watch/poll loops, heavier ones for planning — visible in the Jun 8 `/model` records.

## The lanes the project record missed

- **A Dutch Smurf comic, first thing.** Antigravity's very first working day on Z440
  (Jun 5, T216) produced an 18-scene + cover nostalgic comic, compiled to PDF with a
  hand-rolled PIL script — interrupted mid-run by image quota, finished that evening with an
  aspect-crop fix. The diary seat introduced itself by making something for the family.
- **The montage was a three-agent pipeline.** Cowork authored the build-prompt as issue #61;
  Antigravity built the video (yt-dlp audio, Ken Burns, then a beat-aware v2 that snaps cuts
  to audio onset peaks); Claude Code QA'd it and did the 1080p CRF-20 re-encode. Three seats,
  one artifact — the QA leg happened entirely outside AG's own record.
- **The `locally-uncensored` lane.** An active workstream on Jun 21, Jul 1 and through T244
  (a local Tauri app wrapping ComfyUI: vite proxy fixes for multipart uploads, embedded-python
  path repair, VideoHelperSuite deps, workflow-JSON compilers) — essentially invisible in the
  mo:os git/issue record because it lives in a third-party clone.
- **Ops babysitting is a real seat duty.** Jun 28 late-evening: Claude took browser and
  system control to shepherd a Windows 11 reboot, restart the gen-stack, and run a
  system watchdog on request — nothing committed, everything necessary.
- **AG's fleet chores.** Before it was "the diary seat," Antigravity fixed the LAN DHCP
  drift of the day (Jun 5), wrote the WMI process launcher (`start_wmi.ps1`) so kernels
  survive shell exit, and consulted on the manifold-paradigm open questions (Jun 7) with
  category-theory framing — a genuine contributor to the 4.0 design, not just a media lane.

## Dead-ends preserved (so they aren't re-walked)

- **Pixtral 12B**: fully evaluated (Jun 16) and declined — VRAM floor on the 12 GB 3060, no
  genuine abliterated variant, fragile Ollama mmproj path. Qwen2.5-VL-7B won. The eval note
  survives at `dev/runbooks/pixtral-12b-vision-eval-t231.md`.
- **EXIF-date scanning over the Drive virtual filesystem** for montage ordering: too slow,
  abandoned for path sorting.
- **A blocking running-state-write guard hook** (T219 review): contested — Z440 lead pro,
  governance called it brittle; parked as report-only-first. (The T244 drift gate is its
  descendant, landed only after the generated table made it cheap.)
- **Antigravity's Windows papercuts**, for whoever builds the next surface: `grep.exe`
  missing from PATH broke its native search all month; it cannot read UTF-16LE files (gh CLI
  `Out-File` output); "paging file too small" errors under load; `Start-Process` children
  dying with the shell (hence the WMI launcher).

## Hygiene findings from the mining itself

- **Plaintext tokens inside the Antigravity conversation DBs.** In the Jun 21 and Jun 28
  sessions the agent, after hitting `Bad credentials`, inlined a GitHub token into shell
  commands — those command lines persist in `~/.gemini/antigravity/conversations/*.db` and
  the cleartext transcripts under `brain/<id>/.system_generated/logs/`. The classic PATs
  involved were revoked by T244 (tokens page verified empty), so exposure is
  local-file-only and likely dead — but the keyring's `gho_` token class does not appear on
  that page. **Recommendation: re-auth `gh` when convenient (`gh auth logout/login`) and
  treat old AG conversation DBs as scrub/delete candidates.**
- **mtime is unreliable in the transcript store** — a Jul 2 bulk-touch stamped several April
  sessions; anyone mining this later should trust in-file timestamps, not file dates.
- **AG DB anatomy**, for future miners: step payloads are protobuf with cleartext user/
  assistant text and tool-call args, but tool *results* are encrypted; the readable mirror is
  `brain/<id>/.system_generated/logs/transcript.jsonl`.

## Sourcing

Mined T=244 by four parallel readers over: `60e755cf` (33 MB, 2,396 steps, Jun 5–Jul 3),
`22ee9db1` (Jun 20–21), `3c5915dc` (Jul 3 "MTDC manifold"), the two plan files
(`woolly-conjuring-bee` = T219 config-overhaul, `t239-…-adaptive-moth` = T239 catch-up; both
verified executed against disk/commits), and the full Cowork/Claude-Code transcript index
(all in-period work ran from `D:\HPZ440` and `d:\FFS0_Factory`; the hp-laptop root holds no
in-period sessions on this machine).

---
authored-by: agent:claude-cowork.hp-z440 / session:sam.z440-cowork-workspace / t244-arc-baseline
