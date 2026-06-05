---
agent: "moos-workstation-operator"
description: "Start the hp-laptop governance watcher for ffs0 issue #54; polls every 3 minutes and can post conservative auto-replies for Z440-side requests."
---

# Watch ffs0 Issue #54

Start the portable issue watcher from the ffs0 repo root. This is a deterministic terminal loop, not durable HG truth.

## Default Command

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File dev\scripts\ops\Watch-GitHubIssue.ps1 `
  -Repo Collider-Data-Systems/ffs0 `
  -Issue 54 `
  -IntervalSeconds 180 `
  -Watch `
  -AutoReply `
  -CloudflaredReadback
```

## Operator Rules

- Run it in an async/background terminal and report the terminal ID.
- Confirm the first output includes the state file, latest comment ID, and `AutoReply: True`.
- The script tracks comment IDs in `tmp/issue-watch/` so restarts do not replay old comments.
- Auto-replies must stay conservative: no HG rewrites, no Keep/Calendar/Project sync, no DNS/Cloudflare/tunnel mutation, no secrets, and no manual `moos.jsonl` copying.
- `-CloudflaredReadback` may include redacted hostnames and local service URLs from `~/.cloudflared/config.yml`, but it must not print `tunnel:`, `credentials-file:`, account IDs, tokens, or credential JSON.
- For broader acknowledgement of every Z440-side comment, add `-ReplyToAllZ440`; otherwise the script only replies to request/handoff-shaped comments.
- Stop the watcher by killing its terminal.

## Quick Checks

```powershell
git -C . status --short --branch
gh issue view 54 --repo Collider-Data-Systems/ffs0 --json comments --jq '.comments | sort_by(.createdAt) | last | {createdAt,url,body:(.body | split("\n") | .[0:3] | join("\n"))}'
```