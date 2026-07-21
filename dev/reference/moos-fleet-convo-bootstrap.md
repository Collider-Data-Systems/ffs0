# mo:os standing fleet convo — bootstrap (one per box)

> Paste this file's **Kickoff prompt** into a fresh Claude Code conversation on the target box.
> Pattern established T=262 (2026-07-21) on the ProDesk after the Z440 standing convo was lost to a
> remote-control outage. Design rule learned from that loss: **all watcher state lives on disk, not in
> the conversation** — a successor convo rebuilds from the state file in one read.

## Per-box parameters

| | HP ProDesk | Z440 | hp-laptop |
|---|---|---|---|
| Hostname | `DESKTOP-3FC7C3F` | `desktop-42d00rd` | `lap-sam` |
| Tailscale | 100.87.28.95 | 100.82.243.13 | 100.106.220.58 |
| Repos root | `C:\Users\Geurt\CDS\` | `D:\HPZ440\` | (laptop checkout root) |
| Launcher (tracked, ffs0) | `dev\scripts\ops\start_federation_hpprodesk.ps1` | `dev\scripts\ops\start_federation_z440.ps1` | `dev\scripts\ops\start_federation_laptop.ps1` |
| Kernels | :8000 | :8000 + twins :8001–:8003 | :8000 |
| Router | :9000 | :9000 | :9000 |
| Watch state file | `<repos-root>\watch-state.json` | same | same |

## Kickoff prompt (paste into the new convo)

```
t<NNN>; <hhmm> — standing fleet convo for this box. Set up:

1. ORIENT: run /orient (moos-seat-hydration, auto-detect seat from host/cwd). Live readback wins
   over authored tables: running-state.md header, local /healthz, peer kernels+routers over Tailscale.
2. CATCH-UP GATE: git fetch ffs0 + moos-kernel + moos-router, report behind/ahead + dirty. Any
   pull / rebuild / relaunch / commit / GitHub post is a boundary act — surface it, run only on my word.
3. WATCHER: read <repos-root>\watch-state.json if present (a predecessor's watermark — adopt it);
   else baseline now. Each tick:
   a. Comment-level sweep vs watermark across Collider-Data-Systems/{ffs0,moos-kernel,moos-router}:
      gh api .../issues/comments + .../pulls/comments, sort=created desc, report created_at > watermark.
      NEVER diff issue/PR updatedAt — own posts overwrite it and mask peer comments.
   b. Diff open PRs/issues vs the snapshot in the state file (new / closed / merged).
   c. Fleet probe: local :8000+:9000, peers' :8000 over Tailscale, fan-in count from routers.
   d. Anything new → report fully + surface actionables. Nothing → one line:
      "watcher: quiet — fleet N/6, <local time>".
   e. Update watch-state.json (watermark = max created_at seen; snapshots; last_tick_utc),
      re-arm ScheduleWakeup (~25 min idle cadence).
4. LANE DISCIPLINE: this convo owns only THIS box's leg (its binaries, launcher, relaunches).
   Cross-box asks go via the board (issues/PR comments) — the other boxes' sweeps are the transport.
   GitHub posts and HG emits stay on my word, per seat emit discipline.
```

## Notes

- The three watchers deliberately overlap on the sweep (read-only) — duplicate *reports* on different
  screens are fine; duplicate *actions* can't happen because actions are word-gated per convo.
- If a convo is lost (box unreachable, session gone): start a fresh one with the same kickoff — it
  adopts the on-disk watermark; nothing is missed as long as the sweep is comment-level.
- Kernel rebuild reminder: after any moos-kernel pull, rebuild before relaunch (exe is local-built,
  untracked). Old exe kept as `moos-kernel.exe.bak-t<NNN>-<reason>`.
