"""CLI: Hydrate T161 — programs, agents, sessions, tool wiring into live HG."""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from dev.scripts.validation.session_baseline import fetch_state, post_program
from dev.scripts.validation.t161_hydration import (
    plan_agent_hydration,
    plan_program_hydration,
    plan_session_hydration,
    plan_tool_wiring,
)


def main() -> int:
    parser = argparse.ArgumentParser(description="Hydrate T161 topology into HG.")
    parser.add_argument("--base-url", default="http://localhost:8000")
    parser.add_argument("--actor", default="urn:moos:user:sam")
    parser.add_argument("--t-day", type=int, default=161)
    parser.add_argument("--apply", action="store_true",
                        help="Apply envelopes to kernel via POST /programs")
    args = parser.parse_args()

    nodes, relations = fetch_state(args.base_url)

    all_envelopes: list[dict] = []

    # Phase 1: Programs
    prog_envs = plan_program_hydration(nodes, relations, args.actor,
                                       t_current=args.t_day)
    all_envelopes.extend(prog_envs)

    # Phase 2a: Agents
    agent_envs = plan_agent_hydration(nodes, args.actor)
    all_envelopes.extend(agent_envs)

    # Phase 2b: Session for this agent on this machine
    # Create session for the VS Code Codex agent (this IDE instance)
    agent_urn = "urn:moos:agent:vscode-codex.hp-z440"
    program_urn = f"urn:moos:program:sam.t{args.t_day}"

    # Merge newly-planned nodes into node list for session planning
    planned_nodes = nodes + [
        {"urn": e["node_urn"], "type_id": e["type_id"]}
        for e in all_envelopes if e.get("rewrite_type") == "ADD"
    ]
    session_envs = plan_session_hydration(
        planned_nodes, relations, args.actor,
        agent_urn=agent_urn,
        program_urn=program_urn,
        t_day=args.t_day,
    )
    all_envelopes.extend(session_envs)

    # Phase 4: Tool wiring — verify_baseline as prototype
    tool_envs = plan_tool_wiring(
        planned_nodes + [
            {"urn": e["node_urn"], "type_id": e["type_id"]}
            for e in session_envs if e.get("rewrite_type") == "ADD"
        ],
        relations, args.actor,
        tool_name="verify_baseline",
        match_type_id="tool_call",
    )
    all_envelopes.extend(tool_envs)

    # Summary
    adds = [e for e in all_envelopes if e["rewrite_type"] == "ADD"]
    links = [e for e in all_envelopes if e["rewrite_type"] == "LINK"]
    print(json.dumps({
        "proposal_count": len(all_envelopes),
        "adds": len(adds),
        "links": len(links),
        "envelopes": all_envelopes,
    }, indent=2))

    if args.apply and all_envelopes:
        # Apply in stages: ADDs first, then LINKs (LINKs reference just-created nodes)
        add_envs = [e for e in all_envelopes if e["rewrite_type"] == "ADD"]
        link_envs = [e for e in all_envelopes if e["rewrite_type"] == "LINK"]
        results = []
        if add_envs:
            r = post_program(args.base_url, add_envs)
            results.extend(r if isinstance(r, list) else [r])
        if link_envs:
            r = post_program(args.base_url, link_envs)
            results.extend(r if isinstance(r, list) else [r])
        print(json.dumps({"applied": len(all_envelopes), "result": results}, indent=2))

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
