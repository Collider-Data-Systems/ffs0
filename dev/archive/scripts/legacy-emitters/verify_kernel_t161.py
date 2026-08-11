#!/usr/bin/env python3
"""Verify T161 hydration nodes are present in all reachable kernels."""
import json
import sys
import urllib.request

KERNELS = [
    ("z440-primary", "http://localhost:8000"),
    ("z440-secondary", "http://localhost:8001"),
    ("z440-hdc", "http://localhost:8002"),
    ("z440-ci", "http://localhost:8003"),
]

T161_KEYWORDS = [
    "t158", "t159", "t160", "t161", "t162", "t163",
    "hp-laptop", "session:vscode",
    "watcher:tool", "reactor:tool", "guard:tool",
]


def check_kernel(name, base):
    try:
        health = json.loads(urllib.request.urlopen(f"{base}/healthz", timeout=3).read())
    except Exception as e:
        return {"kernel": name, "status": "unreachable", "error": str(e)}

    nodes = json.loads(urllib.request.urlopen(f"{base}/state/nodes", timeout=5).read())
    rels = json.loads(urllib.request.urlopen(f"{base}/state/relations", timeout=5).read())

    matched = sorted(
        [n for n in nodes if any(k in n["urn"] for k in T161_KEYWORDS)],
        key=lambda n: n["urn"],
    )

    return {
        "kernel": name,
        "status": "ok",
        "t_day": health.get("t_day"),
        "log_len": health.get("log_len"),
        "total_nodes": len(nodes),
        "total_relations": len(rels),
        "t161_nodes": len(matched),
        "t161_node_list": [f"{n['urn']} ({n['type_id']})" for n in matched],
    }


def main():
    results = []
    all_ok = True
    for name, base in KERNELS:
        r = check_kernel(name, base)
        results.append(r)
        if r["status"] != "ok":
            all_ok = False
        elif r["t161_nodes"] == 0:
            all_ok = False

    print(json.dumps(results, indent=2))
    sys.exit(0 if all_ok else 1)


if __name__ == "__main__":
    main()
