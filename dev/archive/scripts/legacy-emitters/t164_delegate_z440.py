#!/usr/bin/env python3
"""T=164: Strict delegation to Z440 via HG.

Creates 6 prg_task nodes on hp-laptop kernel, one per open issue.
Each task is wired:
  - agent(claude-code.hp-z440) --WF07 participates--> prg_task
  - program(t164-room-tying) --WF18 composes--> prg_task

Z440 claude-code queries:
  GET /state/relations/src/urn:moos:agent:claude-code.hp-z440
  filter: category=WF07, src_port=participates, target type_id=prg_task
"""
import json
import urllib.request

KERNEL = "http://localhost:8000"
ACTOR = "urn:moos:user:sam"
AGENT_Z440 = "urn:moos:agent:claude-code.hp-z440"
PROGRAM = "urn:moos:program:sam.t164-room-tying"

# (prg_urn_suffix, title, t_target, issue_url)
TASKS = [
    ("z440.hdc-e-crosswalk",
     "HDC-E crosswalk rotations — verify SO(d) composition",
     166, "https://github.com/MSD21091969/ffs0/issues/20"),
    ("z440.cors-verify",
     "CORS — verify moos-viz:5173 fetch end-to-end",
     165, "https://github.com/MSD21091969/ffs0/issues/22"),
    ("z440.seed-schemes",
     "Seed classification schemes + crosswalks on Z440 primary",
     165, "https://github.com/MSD21091969/ffs0/issues/23"),
    ("z440.viz-verify",
     "moos-viz render matches kernel state — node/edge counts",
     166, "https://github.com/MSD21091969/ffs0/issues/24"),
    ("z440.narration-update",
     "Demo narration — walk end-to-end + add T=164 paragraph",
     166, "https://github.com/MSD21091969/ffs0/issues/25"),
    ("z440.ontology-v3.6-pickup",
     "Pick up ontology v3.6 on Z440 — restart + verify 19 WFs + channel/purpose",
     164, "https://github.com/MSD21091969/ffs0/issues/29"),
]

T164 = "2026-04-14T09:51:00+02:00"


def prop(value, mutability="immutable", authority_scope=None):
    p = {"value": value, "mutability": mutability, "stratum_origin": 2}
    if authority_scope:
        p["authority_scope"] = authority_scope
    return p


def post(payload):
    req = urllib.request.Request(
        KERNEL + "/rewrites",
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=10) as r:
            return r.status, r.read().decode("utf-8")
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode("utf-8")


envelopes = []
for suffix, title, t_tgt, url in TASKS:
    prg_urn = f"urn:moos:prg:{suffix}"
    envelopes.append({
        "rewrite_type": "ADD",
        "actor": ACTOR,
        "node_urn": prg_urn,
        "type_id": "prg_task",
        "properties": {
            "title": prop(title),
            "status": prop("active", mutability="mutable", authority_scope="kernel"),
            "harness_pattern": prop("dynamic-plan-adaptive"),
            "t_start": prop(164),
            "t_target": prop(t_tgt),
            "color_label": prop("purple"),
            "created_at": prop(T164),
            "issue_url": prop(url),
        },
    })
    # LINK agent --WF07 participates--> prg_task
    envelopes.append({
        "rewrite_type": "LINK",
        "rewrite_category": "WF07",
        "actor": ACTOR,
        "relation_urn": f"urn:moos:rel:assign-{suffix}",
        "src_urn": AGENT_Z440,
        "src_port": "participates",
        "tgt_urn": prg_urn,
        "tgt_port": "participated-by",
    })
    # LINK program --WF18 composes--> prg_task
    envelopes.append({
        "rewrite_type": "LINK",
        "rewrite_category": "WF18",
        "actor": ACTOR,
        "relation_urn": f"urn:moos:rel:t164-composes-{suffix}",
        "src_urn": PROGRAM,
        "src_port": "composes",
        "tgt_urn": prg_urn,
        "tgt_port": "composed-by",
    })


if __name__ == "__main__":
    ok = 0; fail = 0
    for i, env in enumerate(envelopes):
        label = env.get("node_urn") or env.get("relation_urn")
        code, body = post(env)
        tag = "OK " if code == 200 else f"{code}"
        print(f"[{i+1:02d}/{len(envelopes)}] {env['rewrite_type']:6} {tag} {label}")
        if code == 200: ok += 1
        else: fail += 1; print(f"        {body.strip()[:200]}")
    print()
    print(f"{ok} ok / {fail} fail of {len(envelopes)}")
