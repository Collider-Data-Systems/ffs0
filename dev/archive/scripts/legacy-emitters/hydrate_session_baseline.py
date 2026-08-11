from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from dev.scripts.validation.session_baseline import (
    fetch_state,
    load_json,
    post_program,
    propose_hydration,
)


def main() -> int:
    parser = argparse.ArgumentParser(description="Hydrate missing category baseline links.")
    parser.add_argument("--base-url", default="http://localhost:8000", help="Kernel base URL")
    parser.add_argument(
        "--ontology",
        default=str(ROOT / "kb" / "superset" / "ontology.json"),
        help="Path to ontology JSON",
    )
    parser.add_argument("--actor", default="urn:moos:user:sam", help="Actor URN for emitted rewrites")
    parser.add_argument("--apply", action="store_true", help="Apply proposals to kernel via POST /programs")
    args = parser.parse_args()

    ontology = load_json(args.ontology)
    nodes, relations = fetch_state(args.base_url)
    proposals = propose_hydration(nodes, relations, ontology, args.actor)

    print(json.dumps({"proposal_count": len(proposals), "proposals": proposals}, indent=2))

    if args.apply and proposals:
        result = post_program(args.base_url, proposals)
        print(json.dumps({"applied": len(proposals), "result": result}, indent=2))

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
