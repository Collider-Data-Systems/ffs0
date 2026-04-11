import unittest

from dev.scripts.validation.session_baseline import (
    relation_exists,
    relation_urn,
    verify_baseline,
    propose_hydration,
)


def _ontology_fixture():
    return {
        "rewrite_categories": [
            {"id": "WF01", "src_port": "owns", "tgt_port": "child"},
            {"id": "WF02", "src_port": "governs", "tgt_port": "governed-by"},
            {"id": "WF03", "src_port": "hosts", "tgt_port": "hosted-on"},
            {"id": "WF16", "src_port": "routes-to", "tgt_port": "routed-from"},
        ],
        "types": {
            "s2_infrastructure": [
                {"id": "user"},
                {"id": "agent"},
                {"id": "workstation"},
                {"id": "kernel"},
                {"id": "router"},
                {"id": "shard_rule"},
            ]
        },
    }


def _nodes_fixture():
    return [
        {"urn": "urn:moos:user:sam", "type_id": "user"},
        {"urn": "urn:moos:workstation:hp-z440", "type_id": "workstation"},
        {"urn": "urn:moos:agent:claude-code.hp-z440", "type_id": "agent"},
        {"urn": "urn:moos:kernel:hp-z440.primary", "type_id": "kernel"},
        {"urn": "urn:moos:router:main", "type_id": "router"},
        {
            "urn": "urn:moos:shard:hp-z440.primary",
            "type_id": "shard_rule",
            "properties": {
                "urn_prefix": {"value": "urn:moos:kernel:hp-z440.primary"}
            },
        },
    ]


class SessionBaselineTests(unittest.TestCase):
    def test_relation_urn_is_deterministic(self):
        r1 = relation_urn("WF03", "a", "hosts", "b", "hosted-on")
        r2 = relation_urn("WF03", "a", "hosts", "b", "hosted-on")
        self.assertEqual(r1, r2)

    def test_verify_detects_missing_wf03_and_wf16(self):
        report = verify_baseline(_nodes_fixture(), [], _ontology_fixture())
        kinds = {(m["wf"], m["src_type"], m["tgt_type"]) for m in report["missing"]}
        self.assertIn(("WF03", "workstation", "kernel"), kinds)
        self.assertIn(("WF16", "shard_rule", "kernel"), kinds)

    def test_propose_hydration_adds_expected_links(self):
        proposals = propose_hydration(_nodes_fixture(), [], _ontology_fixture(), "urn:moos:user:sam")
        self.assertGreaterEqual(len(proposals), 3)

        wf02 = [p for p in proposals if p["rewrite_category"] == "WF02"]
        wf03 = [p for p in proposals if p["rewrite_category"] == "WF03"]
        wf16 = [p for p in proposals if p["rewrite_category"] == "WF16"]

        self.assertEqual(1, len(wf02))
        self.assertEqual("urn:moos:user:sam", wf02[0]["src_urn"])
        self.assertEqual("urn:moos:agent:claude-code.hp-z440", wf02[0]["tgt_urn"])

        self.assertEqual(1, len(wf03))
        self.assertEqual("urn:moos:workstation:hp-z440", wf03[0]["src_urn"])
        self.assertEqual("urn:moos:kernel:hp-z440.primary", wf03[0]["tgt_urn"])

        self.assertGreaterEqual(len(wf16), 1)

    def test_propose_hydration_skips_existing_links(self):
        rels = [
            {
                "rewrite_category": "WF02",
                "src_urn": "urn:moos:user:sam",
                "src_port": "governs",
                "tgt_urn": "urn:moos:agent:claude-code.hp-z440",
                "tgt_port": "governed-by",
            },
            {
                "rewrite_category": "WF03",
                "src_urn": "urn:moos:workstation:hp-z440",
                "src_port": "hosts",
                "tgt_urn": "urn:moos:kernel:hp-z440.primary",
                "tgt_port": "hosted-on",
            },
            {
                "rewrite_category": "WF16",
                "src_urn": "urn:moos:shard:hp-z440.primary",
                "src_port": "routes-to",
                "tgt_urn": "urn:moos:kernel:hp-z440.primary",
                "tgt_port": "routed-from",
            },
        ]

        proposals = propose_hydration(_nodes_fixture(), rels, _ontology_fixture(), "urn:moos:user:sam")
        self.assertEqual([], proposals)

    def test_relation_exists_matches_exact_tuple(self):
        rels = [
            {
                "rewrite_category": "WF03",
                "src_urn": "a",
                "src_port": "hosts",
                "tgt_urn": "b",
                "tgt_port": "hosted-on",
            }
        ]
        self.assertTrue(relation_exists(rels, "WF03", "a", "hosts", "b", "hosted-on"))
        self.assertFalse(relation_exists(rels, "WF03", "a", "hosts", "c", "hosted-on"))

    def test_primary_kernel_falls_back_to_workstation_shard(self):
        nodes = [
            {"urn": "urn:moos:user:sam", "type_id": "user"},
            {"urn": "urn:moos:workstation:hp-z440", "type_id": "workstation"},
            {"urn": "urn:moos:kernel:hp-z440.primary", "type_id": "kernel"},
            {
                "urn": "urn:moos:shard:hp-z440",
                "type_id": "shard_rule",
                "properties": {
                    "urn_prefix": {"value": "urn:moos:ws:hp-z440"}
                },
            },
        ]

        proposals = propose_hydration(nodes, [], _ontology_fixture(), "urn:moos:user:sam")
        wf16 = [p for p in proposals if p["rewrite_category"] == "WF16"]
        self.assertEqual(1, len(wf16))
        self.assertEqual("urn:moos:shard:hp-z440", wf16[0]["src_urn"])
        self.assertEqual("urn:moos:kernel:hp-z440.primary", wf16[0]["tgt_urn"])

    def test_primary_kernel_prefers_root_shard_over_instance(self):
        nodes = [
            {"urn": "urn:moos:user:sam", "type_id": "user"},
            {"urn": "urn:moos:workstation:hp-z440", "type_id": "workstation"},
            {"urn": "urn:moos:kernel:hp-z440.primary", "type_id": "kernel"},
            {
                "urn": "urn:moos:shard:hp-z440.menno",
                "type_id": "shard_rule",
                "properties": {
                    "urn_prefix": {"value": "urn:moos:kernel:hp-z440.menno"}
                },
            },
            {
                "urn": "urn:moos:shard:hp-z440",
                "type_id": "shard_rule",
                "properties": {
                    "urn_prefix": {"value": "urn:moos:ws:hp-z440"}
                },
            },
        ]

        proposals = propose_hydration(nodes, [], _ontology_fixture(), "urn:moos:user:sam")
        wf16 = [p for p in proposals if p["rewrite_category"] == "WF16"]
        self.assertEqual(1, len(wf16))
        self.assertEqual("urn:moos:shard:hp-z440", wf16[0]["src_urn"])

    def test_wf16_proposes_preferred_link_when_nonpreferred_exists(self):
        ontology = _ontology_fixture()

        nodes = [
            {"urn": "urn:moos:user:sam", "type_id": "user"},
            {"urn": "urn:moos:workstation:hp-z440", "type_id": "workstation"},
            {"urn": "urn:moos:kernel:hp-z440.primary", "type_id": "kernel"},
            {
                "urn": "urn:moos:shard:hp-z440.menno",
                "type_id": "shard_rule",
                "properties": {
                    "urn_prefix": {"value": "urn:moos:kernel:hp-z440.menno"}
                },
            },
            {
                "urn": "urn:moos:shard:hp-z440",
                "type_id": "shard_rule",
                "properties": {
                    "urn_prefix": {"value": "urn:moos:ws:hp-z440"}
                },
            },
        ]

        relations = [
            {
                "rewrite_category": "WF16",
                "src_urn": "urn:moos:shard:hp-z440.menno",
                "src_port": "routes-to",
                "tgt_urn": "urn:moos:kernel:hp-z440.primary",
                "tgt_port": "routed-from",
            }
        ]

        proposals = propose_hydration(nodes, relations, ontology, "urn:moos:user:sam")
        preferred = [
            p
            for p in proposals
            if p["rewrite_category"] == "WF16"
            and p["src_urn"] == "urn:moos:shard:hp-z440"
            and p["tgt_urn"] == "urn:moos:kernel:hp-z440.primary"
        ]
        self.assertEqual(1, len(preferred))

    def test_nonprimary_kernel_prefers_direct_shard_urn(self):
        nodes = [
            {"urn": "urn:moos:user:sam", "type_id": "user"},
            {"urn": "urn:moos:workstation:hp-z440", "type_id": "workstation"},
            {"urn": "urn:moos:kernel:hp-z440.lola", "type_id": "kernel"},
            {
                "urn": "urn:moos:shard_rule:migrated-rule-1314864089",
                "type_id": "shard_rule",
                "properties": {
                    "urn_prefix": {"value": "urn:moos:kernel:hp-z440.lola"}
                },
            },
            {
                "urn": "urn:moos:shard:hp-z440.lola",
                "type_id": "shard_rule",
                "properties": {
                    "urn_prefix": {"value": "urn:moos:kernel:hp-z440.lola"}
                },
            },
        ]

        proposals = propose_hydration(nodes, [], _ontology_fixture(), "urn:moos:user:sam")
        wf16 = [
            p
            for p in proposals
            if p["rewrite_category"] == "WF16"
            and p["tgt_urn"] == "urn:moos:kernel:hp-z440.lola"
        ]
        self.assertEqual(1, len(wf16))
        self.assertEqual("urn:moos:shard:hp-z440.lola", wf16[0]["src_urn"])


if __name__ == "__main__":
    unittest.main()
