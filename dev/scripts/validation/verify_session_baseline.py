from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from dev.scripts.validation.session_baseline import fetch_state, load_json, verify_baseline


def main() -> int:
    parser = argparse.ArgumentParser(description="Verify category-driven session baseline on a kernel.")
    parser.add_argument("--base-url", default="http://localhost:8000", help="Kernel base URL")
    parser.add_argument(
        "--ontology",
        default=str(ROOT / "kb" / "superset" / "ontology.json"),
        help="Path to ontology JSON",
    )
    args = parser.parse_args()

    ontology = load_json(args.ontology)
    nodes, relations = fetch_state(args.base_url)
    report = verify_baseline(nodes, relations, ontology)

    print(json.dumps(report, indent=2))
    return 0 if report.get("ok") else 2


if __name__ == "__main__":
    raise SystemExit(main())
