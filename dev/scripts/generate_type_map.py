#!/usr/bin/env python3
"""
Generate --type-map flags for moos-router from kb/superset/ontology.json.

Groups node types by stratum and outputs ready-to-use --type-map flags
that implement the routing functor F: TypeCat -> KernelCat.

Routingfunctor rules (presheaf by stratum):
  S2 infrastructure -> primary kernel  (kernel_instance, agent, channel, purpose, ...)
  S1 grammar        -> primary kernel  (operad, rewrite_category — read-only, owned by primary)
  S3 semantic       -> secondary kernel when available, else primary
  interaction_nodes -> primary kernel

Usage:
  python generate_type_map.py \n    --ontology ../../ffs0/kb/superset/ontology.json \n    --primary  https://api.my-tiny-data-collider.nl \n    --secondary http://localhost:8001

Output (stdout) — paste into your router startup script:
  --type-map channel=https://api.my-tiny-data-collider.nl
  --type-map purpose=https://api.my-tiny-data-collider.nl
  ...
"""

import argparse
import json
import sys

# Default endpoints
DEFAULT_PRIMARY = "https://api.my-tiny-data-collider.nl"
DEFAULT_SECONDARY = "http://localhost:8001"  # Z440 kernel when online

# S3 semantic/knowledge type_ids (not declared in ontology strata — listed here)
S3_TYPES = {
    "knowledge_item",
    "claim",
    "source_feed",
    "domain_tag",
    "classification_scheme",
    "crosswalk",
    "governance_proposal",
    "calendar_event",
    "keep_note",
    "channel_message",
}


def load_ontology(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def classify_types(ontology, primary, secondary):
    """Return list of (type_id, target_url, stratum_note) tuples."""
    results = []
    types_section = ontology.get("types", {})

    # S2 infrastructure types -> primary
    for nt in types_section.get("s2_infrastructure", []):
        tid = nt["id"]
        url = secondary if tid in S3_TYPES else primary
        results.append((tid, url, "S2"))

    # S1 grammar types -> primary (read-only, type system lives on primary)
    for nt in types_section.get("s1_grammar", []):
        results.append((nt["id"], primary, "S1"))

    # interaction_nodes -> primary
    for nt in types_section.get("interaction_nodes", []):
        results.append((nt["id"], primary, "S2"))

    # Explicitly named S3 types not yet in ontology s2_infrastructure
    seen = {r[0] for r in results}
    for tid in sorted(S3_TYPES - seen):
        results.append((tid, secondary, "S3"))

    return results


def main():
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument(
        "--ontology",
        default="kb/superset/ontology.json",
        help="path to ontology.json (default: kb/superset/ontology.json)",
    )
    parser.add_argument(
        "--primary",
        default=DEFAULT_PRIMARY,
        help=f"primary kernel URL for S1/S2 types (default: {DEFAULT_PRIMARY})",
    )
    parser.add_argument(
        "--secondary",
        default=DEFAULT_SECONDARY,
        help=f"secondary kernel URL for S3 types (default: {DEFAULT_SECONDARY})",
    )
    parser.add_argument(
        "--format",
        choices=["flags", "json", "shell"],
        default="flags",
        help="output format: flags (--type-map args), json dict, or shell export",
    )
    args = parser.parse_args()

    try:
        ontology = load_ontology(args.ontology)
    except FileNotFoundError:
        print(f"ERROR: ontology not found at {args.ontology}", file=sys.stderr)
        sys.exit(1)

    entries = classify_types(ontology, args.primary, args.secondary)

    if args.format == "json":
        print(json.dumps({tid: url for tid, url, _ in entries}, indent=2))
    elif args.format == "shell":
        for tid, url, stratum in entries:
            print(f"# {stratum}")
            print(f'export TYPE_MAP_{tid.upper()}="{url}"')
    else:  # flags
        current_stratum = None
        for tid, url, stratum in entries:
            if stratum != current_stratum:
                print(f"# {stratum} types")
                current_stratum = stratum
            print(f"  --type-map {tid}={url} \\")


if __name__ == "__main__":
    main()
