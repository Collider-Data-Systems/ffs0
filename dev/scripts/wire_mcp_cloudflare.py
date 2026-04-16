#!/usr/bin/env python3
"""
Wire the Cloudflare MCP SSE endpoint into the moos kernel graph.

Adds a dedicated endpoint node for the MCP SSE tunnel and links it to the
hp-laptop kernel via WF16 (federation outbound).

Actual tunnel URLs (Cloudflare Zero Trust, self-hosted):
  REST API : https://api.my-tiny-data-collider.nl
  MCP SSE  : https://kernel.my-tiny-data-collider.nl/sse

Usage:
  python wire_mcp_cloudflare.py [--kernel http://localhost:8000]
"""

import argparse
import json
import sys
import urllib.request

ACTOR = "urn:moos:user:sam"
KERNEL_URN = "urn:moos:kernel:hp-laptop.primary"
MCP_ENDPOINT_URN = "urn:moos:endpoint:hp-laptop.mcp-sse.cloudflare"
T164 = "2026-04-14T07:49:00+02:00"


def prop(value, mutability="immutable", authority_scope=None, stratum_origin=2):
    p = {"value": value, "mutability": mutability, "stratum_origin": stratum_origin}
    if authority_scope:
        p["authority_scope"] = authority_scope
    return p


def post_rewrite(base, envelope):
    data = json.dumps(envelope).encode()
    req = urllib.request.Request(
        f"{base}/rewrites",
        data=data,
        headers={"Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read())
    except Exception as exc:
        print(f"  ERROR: {exc}", file=sys.stderr)
        return None


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--kernel", default="http://localhost:8000", help="kernel REST base URL")
    args = parser.parse_args()
    base = args.kernel.rstrip("/")

    envelopes = [
        # ADD dedicated MCP SSE endpoint node
        {
            "rewrite_type": "ADD",
            "actor": ACTOR,
            "node_urn": MCP_ENDPOINT_URN,
            "type_id": "endpoint",
            "properties": {
                "kind": prop("mcp_sse"),
                "name": prop("moos-kernel-mcp-cloudflare"),
                "protocol": prop("sse"),
                "url": prop(
                    "https://kernel.my-tiny-data-collider.nl/sse",
                    mutability="mutable",
                    authority_scope="kernel",
                ),
                "t_created": prop(T164),
            },
            "t_day": T164,
        },
        # LINK MCP endpoint to kernel via WF16 (federation outbound)
        {
            "rewrite_type": "LINK",
            "actor": ACTOR,
            "relation_urn": f"urn:moos:relation:{MCP_ENDPOINT_URN}.wf16.{KERNEL_URN}",
            "rewrite_category": "WF16",
            "src_urn": MCP_ENDPOINT_URN,
            "tgt_urn": KERNEL_URN,
            "t_day": T164,
        },
    ]

    print(f"Wiring MCP SSE endpoint on kernel at {base}")
    for env in envelopes:
        result = post_rewrite(base, env)
        label = f"{env['rewrite_type']} {env.get('node_urn') or env.get('relation_urn', '')}"
        print(f"  {label} -> {'ok' if result else 'FAIL'}")


if __name__ == "__main__":
    main()
