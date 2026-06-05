---
agent: "moos-workstation-operator"
description: "Start the profile-aware watcher for ffs0 issue #54; polls every 3 minutes and can post conservative auto-replies from hp-laptop governance or Z440 VS Code lead."
---

# Watch ffs0 Issue #54

Start the portable issue watcher from the ffs0 repo root. This is a deterministic terminal loop, not durable HG truth.

## Z440 VS Code Lead Command

Use this command in the current Z440 VS Code/Copilot conversation:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File dev\scripts\ops\Watch-GitHubIssue.ps1 `
  -Repo Collider-Data-Systems/ffs0 `
  -Issue 54 `
  -Profile z440-vscode-lead `
  -IntervalSeconds 180 `
  -Watch `
  -AutoReply
```

This runs as `session:sam.z440-vscode-projection-lead` / `agent:vscode.hp-z440.primary` and posts only conservative Z440 watcher acknowledgements for comments that explicitly ask for Z440.

## hp-laptop Governance Command

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File dev\scripts\ops\Watch-GitHubIssue.ps1 `
  -Repo Collider-Data-Systems/ffs0 `
  -Issue 54 `
  -Profile hp-laptop-governance `
  -IntervalSeconds 180 `
  -Watch `
  -AutoReply `
  -CloudflaredReadback
```

## Operator Rules

- Run it in an async/background terminal and report the terminal ID.
- Confirm the first output includes profile, state file, latest comment ID, and `AutoReply: True`.
- The script tracks comment IDs in `tmp/issue-watch/` with profile-specific state files, so restarts do not replay old comments.
- Auto-replies must stay conservative: no HG rewrites, no Keep/Calendar/Project sync, no DNS/Cloudflare/tunnel mutation, no secrets, and no manual `moos.jsonl` copying.
- `-CloudflaredReadback` may include redacted hostnames and local service URLs from `~/.cloudflared/config.yml`, but it must not print `tunnel:`, `credentials-file:`, account IDs, tokens, or credential JSON.
- For broader acknowledgement of every Z440-side comment, add `-ReplyToAllZ440`; otherwise each profile only replies to request/handoff-shaped comments aimed at it.
- Stop the watcher by killing its terminal.

## Quick Checks

```powershell
git -C . status --short --branch
gh issue view 54 --repo Collider-Data-Systems/ffs0 --json comments --jq '.comments | sort_by(.createdAt) | last | {createdAt,url,body:(.body | split("\n") | .[0:3] | join("\n"))}'
```