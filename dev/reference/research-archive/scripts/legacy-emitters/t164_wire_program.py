#!/usr/bin/env python3
"""T=164: Wire the concrete program per research doc §15.

Creates:
  - 2 Cloudflare endpoint nodes (moos-api, moos-kernel tunnels)
  - 4 channel nodes (whatsapp, drive, downloads, board)
  - 1 session node (this Claude Code conversation)
  - 1 program node (T=164 room-tying)

Links:
  - 2 endpoints --WF16 routes-to--> hp-laptop kernel
  - session --WF19 opens-on--> hp-laptop kernel
  - program --WF18 composes--> purpose + session + 4 channels

Purpose node was already ADDed by earlier /rewrites call.
"""
import json
import urllib.request
import sys

KERNEL_URL = "http://localhost:8000"
ACTOR = "urn:moos:user:sam"
T164 = "2026-04-14T07:49:00+02:00"
KERNEL_URN = "urn:moos:kernel:hp-laptop.primary"
PURPOSE_URN = "urn:moos:purpose:sam.t164-tie-the-room-together"


def prop(value, mutability="immutable", authority_scope=None, stratum_origin=2):
    p = {"value": value, "mutability": mutability, "stratum_origin": stratum_origin}
    if authority_scope:
        p["authority_scope"] = authority_scope
    return p


def add(node_urn, type_id, properties):
    return {
        "rewrite_type": "ADD",
        "actor": ACTOR,
        "node_urn": node_urn,
        "type_id": type_id,
        "properties": properties,
    }


def link(relation_urn, wf, src, src_port, tgt, tgt_port):
    return {
        "rewrite_type": "LINK",
        "rewrite_category": wf,
        "actor": ACTOR,
        "relation_urn": relation_urn,
        "src_urn": src,
        "src_port": src_port,
        "tgt_urn": tgt,
        "tgt_port": tgt_port,
    }


EP_API = "urn:moos:endpoint:cf-tunnel.moos-api"
EP_KERN = "urn:moos:endpoint:cf-tunnel.moos-kernel"
CH_WA = "urn:moos:channel:messaging.whatsapp-sam"
CH_DR = "urn:moos:channel:drive.sam-my-drive"
CH_FS = "urn:moos:channel:filesystem.hp-laptop-downloads"
CH_BD = "urn:moos:channel:board.msd21091969-moos"
SESSION = "urn:moos:session:sam.claude-code-hp-laptop.t164"
PROGRAM = "urn:moos:program:sam.t164-room-tying"

envelopes = [
    # Endpoints (Cloudflare Access tunnels)
    add(EP_API, "endpoint", {
        "transport_type": prop("https"),
        "status": prop("active", mutability="mutable", authority_scope="kernel"),
    }),
    add(EP_KERN, "endpoint", {
        "transport_type": prop("https"),
        "status": prop("active", mutability="mutable", authority_scope="kernel"),
    }),
    # Channels
    add(CH_WA, "channel", {
        "kind": prop("messaging"),
        "source_uri": prop("whatsapp://sam"),
        "owner_urn": prop(ACTOR),
        "display_name": prop("WhatsApp — Sam", mutability="mutable", authority_scope="owner"),
        "status": prop("active", mutability="mutable", authority_scope="owner"),
        "created_at": prop(T164),
    }),
    add(CH_DR, "channel", {
        "kind": prop("drive"),
        "source_uri": prop("gdrive://sam/My Drive"),
        "owner_urn": prop(ACTOR),
        "display_name": prop("Google Drive — Sam", mutability="mutable", authority_scope="owner"),
        "status": prop("active", mutability="mutable", authority_scope="owner"),
        "created_at": prop(T164),
    }),
    add(CH_FS, "channel", {
        "kind": prop("filesystem"),
        "source_uri": prop("file:///C:/Users/maass/Downloads"),
        "owner_urn": prop(ACTOR),
        "display_name": prop("Downloads — hp-laptop", mutability="mutable", authority_scope="owner"),
        "status": prop("active", mutability="mutable", authority_scope="owner"),
        "created_at": prop(T164),
    }),
    add(CH_BD, "channel", {
        "kind": prop("board"),
        "source_uri": prop("github://msd21091969/mo:os/projects/1"),
        "owner_urn": prop(ACTOR),
        "display_name": prop("GitHub Project — mo:os", mutability="mutable", authority_scope="owner"),
        "status": prop("active", mutability="mutable", authority_scope="owner"),
        "created_at": prop(T164),
    }),
    # Session (T=164 claude-code conversation on hp-laptop)
    add(SESSION, "session", {
        "status": prop("active", mutability="mutable", authority_scope="kernel"),
        "started_at": prop(T164),
        "turn_count": prop(0, mutability="mutable", authority_scope="kernel"),
    }),
    # Program
    add(PROGRAM, "program", {
        "name": prop("T=164 room-tying"),
        "status": prop("active", mutability="mutable", authority_scope="owner"),
        "starts_t": prop(164, mutability="mutable", authority_scope="owner"),
    }),

    # ---- LINKs ----
    # Endpoints → kernel (WF16 federation, transport↔transport)
    link("urn:moos:rel:ep-api-routes-to-kernel", "WF16",
         EP_API, "routes-to", KERNEL_URN, "routed-from"),
    link("urn:moos:rel:ep-kern-routes-to-kernel", "WF16",
         EP_KERN, "routes-to", KERNEL_URN, "routed-from"),
    # Session opens-on kernel (WF19)
    link("urn:moos:rel:t164-session-opens-on-kernel", "WF19",
         SESSION, "opens-on", KERNEL_URN, "occupied-by"),
    # Program composes purpose (WF18 steers pair)
    link("urn:moos:rel:t164-program-steers-purpose", "WF18",
         PROGRAM, "steers", PURPOSE_URN, "steered-by"),
    # Program composes session (WF18 composes)
    link("urn:moos:rel:t164-program-composes-session", "WF18",
         PROGRAM, "composes", SESSION, "composed-by"),
    # Program composes channels
    link("urn:moos:rel:t164-program-composes-ch-wa", "WF18",
         PROGRAM, "composes", CH_WA, "composed-by"),
    link("urn:moos:rel:t164-program-composes-ch-dr", "WF18",
         PROGRAM, "composes", CH_DR, "composed-by"),
    link("urn:moos:rel:t164-program-composes-ch-fs", "WF18",
         PROGRAM, "composes", CH_FS, "composed-by"),
    link("urn:moos:rel:t164-program-composes-ch-bd", "WF18",
         PROGRAM, "composes", CH_BD, "composed-by"),
]


def post(path, payload):
    req = urllib.request.Request(
        KERNEL_URL + path,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=10) as r:
            return r.status, r.read().decode("utf-8")
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode("utf-8")


if __name__ == "__main__":
    # apply individually so we see per-envelope result
    ok = 0
    fail = 0
    for i, env in enumerate(envelopes):
        label = env.get("node_urn") or env.get("relation_urn")
        status, body = post("/rewrites", env)
        if status == 200:
            ok += 1
            print(f"[{i+1:02d}/{len(envelopes)}] {env['rewrite_type']:6} {label} -> OK")
        else:
            fail += 1
            print(f"[{i+1:02d}/{len(envelopes)}] {env['rewrite_type']:6} {label} -> {status} {body.strip()[:200]}")

    print()
    print(f"applied: {ok} ok, {fail} fail out of {len(envelopes)}")
    sys.exit(0 if fail == 0 else 1)
