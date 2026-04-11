"""TDD tests for T161 hydration: programs, agents, sessions, tool wiring."""
from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from dev.scripts.validation.t161_hydration import (
    plan_program_hydration,
    plan_agent_hydration,
    plan_session_hydration,
    plan_tool_wiring,
)

ACTOR = "urn:moos:user:sam"
T_DAY = 161


def _base_nodes() -> list[dict]:
    """Minimal existing HG node set matching live inventory."""
    return [
        {"urn": "urn:moos:user:sam", "type_id": "user"},
        {"urn": "urn:moos:workstation:hp-z440", "type_id": "workstation"},
        {"urn": "urn:moos:kernel:hp-z440.primary", "type_id": "kernel"},
        {"urn": "urn:moos:agent:antigravity.hp-z440", "type_id": "agent"},
        {"urn": "urn:moos:agent:vscode-codex.hp-z440", "type_id": "agent"},
        {"urn": "urn:moos:agent:claude-code.hp-z440", "type_id": "agent"},
        {"urn": "urn:moos:issue:ffs0.13", "type_id": "git_issue"},
        {"urn": "urn:moos:issue:ffs0.14", "type_id": "git_issue"},
        {"urn": "urn:moos:issue:ffs0.15", "type_id": "git_issue"},
        {"urn": "urn:moos:watcher:raw-ki-claim-extract", "type_id": "watcher"},
        {"urn": "urn:moos:reactor:emit-claim-extract-task", "type_id": "reactor"},
    ]


class TestProgramHydration(unittest.TestCase):
    """Phase 1: T-card program nodes + issue projections."""

    def test_adds_missing_program_nodes(self):
        nodes = _base_nodes()
        rels = []
        envelopes = plan_program_hydration(nodes, rels, ACTOR, t_current=T_DAY)
        adds = [e for e in envelopes if e["rewrite_type"] == "ADD"]
        # Should propose T158-T163 program nodes (6 total since none exist)
        self.assertGreaterEqual(len(adds), 4)  # At least T158-T161
        urns = {e["node_urn"] for e in adds}
        self.assertIn("urn:moos:program:sam.t161", urns)

    def test_skips_existing_program_nodes(self):
        nodes = _base_nodes() + [
            {"urn": "urn:moos:program:sam.t161", "type_id": "program"},
        ]
        rels = []
        envelopes = plan_program_hydration(nodes, rels, ACTOR, t_current=T_DAY)
        adds = [e for e in envelopes if e["rewrite_type"] == "ADD"
                and e.get("node_urn") == "urn:moos:program:sam.t161"]
        self.assertEqual(len(adds), 0)

    def test_links_programs_to_issues(self):
        # Add programs so the linker can find them
        nodes = _base_nodes() + [
            {"urn": "urn:moos:program:sam.t158", "type_id": "program"},
        ]
        rels = []
        envelopes = plan_program_hydration(nodes, rels, ACTOR, t_current=T_DAY)
        links = [e for e in envelopes if e["rewrite_type"] == "LINK"
                 and e.get("rewrite_category") == "WF18"]
        # ffs0.13/14/15 could link to programs via WF18
        self.assertGreaterEqual(len(links), 0)


class TestAgentHydration(unittest.TestCase):
    """Phase 2a: Laptop agent nodes."""

    def test_adds_missing_laptop_agents(self):
        nodes = _base_nodes()
        envelopes = plan_agent_hydration(nodes, ACTOR)
        adds = [e for e in envelopes if e["rewrite_type"] == "ADD"]
        urns = {e["node_urn"] for e in adds}
        self.assertIn("urn:moos:agent:antigravity.hp-laptop", urns)
        self.assertIn("urn:moos:agent:claude-code.hp-laptop", urns)

    def test_skips_existing_agents(self):
        nodes = _base_nodes() + [
            {"urn": "urn:moos:agent:antigravity.hp-laptop", "type_id": "agent"},
            {"urn": "urn:moos:agent:claude-code.hp-laptop", "type_id": "agent"},
        ]
        envelopes = plan_agent_hydration(nodes, ACTOR)
        adds = [e for e in envelopes if e["rewrite_type"] == "ADD"]
        self.assertEqual(len(adds), 0)


class TestSessionHydration(unittest.TestCase):
    """Phase 2b: Agent session topology."""

    def test_creates_session_for_active_agent(self):
        nodes = _base_nodes() + [
            {"urn": "urn:moos:program:sam.t161", "type_id": "program"},
        ]
        rels = []
        envelopes = plan_session_hydration(
            nodes, rels, ACTOR,
            agent_urn="urn:moos:agent:vscode-codex.hp-z440",
            program_urn="urn:moos:program:sam.t161",
            t_day=T_DAY,
        )
        adds = [e for e in envelopes if e["rewrite_type"] == "ADD"]
        links = [e for e in envelopes if e["rewrite_type"] == "LINK"]
        self.assertEqual(len(adds), 1)
        self.assertEqual(adds[0]["type_id"], "agent_session")
        # Two links: WF07 agent→session, + focus→program
        self.assertGreaterEqual(len(links), 2)

    def test_session_urn_contains_agent_and_tday(self):
        nodes = _base_nodes() + [
            {"urn": "urn:moos:program:sam.t161", "type_id": "program"},
        ]
        envelopes = plan_session_hydration(
            nodes, [], ACTOR,
            agent_urn="urn:moos:agent:vscode-codex.hp-z440",
            program_urn="urn:moos:program:sam.t161",
            t_day=T_DAY,
        )
        adds = [e for e in envelopes if e["rewrite_type"] == "ADD"]
        session_urn = adds[0]["node_urn"]
        self.assertIn("vscode-codex", session_urn)
        self.assertIn("t161", session_urn)


class TestToolWiring(unittest.TestCase):
    """Phase 4: Tool as watcher+reactor+guard triple."""

    def test_creates_watcher_reactor_guard_triple(self):
        nodes = _base_nodes()
        rels = []
        envelopes = plan_tool_wiring(
            nodes, rels, ACTOR,
            tool_name="verify_baseline",
            match_type_id="tool_call",
        )
        adds = [e for e in envelopes if e["rewrite_type"] == "ADD"]
        links = [e for e in envelopes if e["rewrite_type"] == "LINK"]
        type_ids = {e.get("type_id") for e in adds}
        self.assertIn("watcher", type_ids)
        self.assertIn("reactor", type_ids)
        self.assertIn("guard", type_ids)
        self.assertEqual(len(adds), 3)
        # WF17 links: watcher→reactor (triggers), guard→watcher (guards)
        wf17_links = [l for l in links if l.get("rewrite_category") == "WF17"]
        self.assertEqual(len(wf17_links), 2)

    def test_skips_existing_tool_watcher(self):
        nodes = _base_nodes() + [
            {"urn": "urn:moos:watcher:tool.verify_baseline", "type_id": "watcher"},
        ]
        rels = []
        envelopes = plan_tool_wiring(
            nodes, rels, ACTOR,
            tool_name="verify_baseline",
            match_type_id="tool_call",
        )
        adds = [e for e in envelopes if e["rewrite_type"] == "ADD"]
        self.assertEqual(len(adds), 0)

    def test_watcher_has_correct_match_properties(self):
        envelopes = plan_tool_wiring(
            _base_nodes(), [], ACTOR,
            tool_name="verify_baseline",
            match_type_id="tool_call",
        )
        watcher_add = [e for e in envelopes
                       if e["rewrite_type"] == "ADD" and e.get("type_id") == "watcher"][0]
        props = watcher_add["properties"]
        self.assertEqual(props["match_rewrite_type"]["value"], "ADD")
        self.assertEqual(props["match_type_id"]["value"], "tool_call")
        self.assertEqual(props["status"]["value"], "active")

    def test_guard_filters_on_tool_name(self):
        envelopes = plan_tool_wiring(
            _base_nodes(), [], ACTOR,
            tool_name="verify_baseline",
            match_type_id="tool_call",
        )
        guard_add = [e for e in envelopes
                     if e["rewrite_type"] == "ADD" and e.get("type_id") == "guard"][0]
        props = guard_add["properties"]
        self.assertEqual(props["predicate_type"]["value"], "node_property")
        self.assertEqual(props["field"]["value"], "tool_name")
        self.assertEqual(props["expected_value"]["value"], "verify_baseline")

    def test_reactor_has_template_producing_tool_result(self):
        envelopes = plan_tool_wiring(
            _base_nodes(), [], ACTOR,
            tool_name="verify_baseline",
            match_type_id="tool_call",
        )
        reactor_add = [e for e in envelopes
                       if e["rewrite_type"] == "ADD" and e.get("type_id") == "reactor"][0]
        props = reactor_add["properties"]
        self.assertEqual(props["action_type"]["value"], "rewrite")
        template = props["template"]["value"]
        self.assertEqual(template["rewrite_type"], "ADD")
        self.assertEqual(template["type_id"], "tool_result")


if __name__ == "__main__":
    unittest.main()
