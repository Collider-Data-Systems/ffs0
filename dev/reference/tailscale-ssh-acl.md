# Tailscale SSH ACL — enable ProDesk → peer remote trigger

Lets the ProDesk box (`desktop-3fc7c3f` / `100.87.28.95`) SSH into the hp-laptop
(`lap-sam` / `100.106.220.58`) and Z440 (`desktop-42d00rd` / `100.82.243.13`)
seats so `dev/scripts/ops/Trigger-PeerWatchers.ps1` can run the watcher remotely.

Tailnet: `maassenhochrath@gmail.com` (single-owner — all three boxes belong to
the same login, so they are all "self").

## Two prerequisites (the ACL alone is not enough)

1. **Advertise SSH on each target.** On hp-laptop and Z440, run once:
   ```powershell
   tailscale up --ssh
   ```
   Without this the node does not run a Tailscale SSH server and the dial falls
   back to TCP `:22` (closed) → `502 Bad Gateway`. (No `tailscale down` needed;
   `--ssh` is additive to the existing `tailscale up` state.)
2. **Paste the SSH rule below** into the tailnet policy at
   admin.tailscale.com → **Access controls** (HuJSON). Merge the `ssh` block into
   the existing policy — do **not** replace the whole file.

## Recommended drop-in (single-owner tailnet)

Minimal, not device-specific (acceptable here — one owner owns every node).
Allows the owner's devices to SSH into the owner's own devices as any non-root
local user.

```jsonc
// merge this top-level key into the tailnet policy
"ssh": [
  {
    "action": "accept",          // unattended (no periodic browser re-auth)
    "src":    ["autogroup:member"],
    "dst":    ["autogroup:self"], // same-owner devices = laptop, Z440, ProDesk
    "users":  ["autogroup:nonroot"]
  }
]
```

- `action: "accept"` runs unattended (the trigger script is non-interactive). For
  interactive human SSH you can use `"check"` instead, which forces a periodic
  browser re-auth (higher security, breaks unattended runs).
- `users: ["autogroup:nonroot"]` permits login as any non-root local account; on
  Windows there is no root, so this means any local Windows user.

## Tighter, device-scoped variant (optional, least-privilege)

Restricts to exactly ProDesk → {laptop, Z440}. Requires tagging the devices,
which changes their ownership to the tag (a tagged device can no longer use
`autogroup:self`, and tags can interact with your other ACL rules — apply only if
you already use tags).

```jsonc
"tagOwners": {
  "tag:trigger-src":  ["maassenhochrath@gmail.com"],
  "tag:watcher-seat": ["maassenhochrath@gmail.com"]
},
"ssh": [
  {
    "action": "accept",
    "src":    ["tag:trigger-src"],   // tag ProDesk with this
    "dst":    ["tag:watcher-seat"],  // tag hp-laptop + Z440 with this
    "users":  ["autogroup:nonroot"]
  }
]
```
Tag the devices in admin.tailscale.com → Machines → (device) → Edit ACL tags.

## SSH login username (important)

`tailscale ssh <host>` logs in as your **current** local username by default —
on ProDesk that is `Geurt`, which likely does **not** exist on the peers. You
must connect as each peer's own Windows account:

```powershell
tailscale ssh <peer-windows-user>@lap-sam -- powershell ...
tailscale ssh <peer-windows-user>@desktop-42d00rd -- powershell ...
```

`Trigger-PeerWatchers.ps1` currently connects with no explicit user (so it uses
`Geurt`). Once you know each peer's Windows username, set it there — a `User`
field per peer / `-RemoteUser` param can be wired in (ask and it will be added).

## Verify after enabling

From ProDesk:
```powershell
tailscale ssh <peer-user>@lap-sam hostname           # should print the peer hostname
.\dev\scripts\ops\Trigger-PeerWatchers.ps1 -Issue 64 -LastSeenId 4719756641 -DryRun
.\dev\scripts\ops\Trigger-PeerWatchers.ps1 -Issue 64 -LastSeenId 4719756641   # live: expect TRIGGERED
```

Refs: PR #67 (`Trigger-PeerWatchers.ps1`) · #64 (coordination) · `dev/config/moos-federation.topology.json` (tailscale machine map).
