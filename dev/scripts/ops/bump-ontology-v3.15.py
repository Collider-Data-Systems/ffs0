#!/usr/bin/env python3
"""Bump ontology.json from v3.14.0 → v3.15.0 per round-15 ceremony.

Adds: clock node-type, WF21 causes rewrite_category, channel.kind {video,audio},
      substrate + substrate_anchor_urn properties on channel + knowledge_item.

Run from ffs0 root: python dev/scripts/ops/bump-ontology-v3.15.py
"""
import json
from pathlib import Path

ONTOLOGY = Path("kb/superset/ontology.json")
data = json.loads(ONTOLOGY.read_text(encoding="utf-8"))

assert data["version"] == "3.14.0", f"Expected 3.14.0, got {data['version']}"

# --- 1. clock node-type (S2) — companion to v314-2-clock-type fragment ---
clock_type = {
    "id": "clock",
    "stratum": "S2",
    "urn_pattern": "urn:moos:clock:<owner>.<slug>",
    "ports": {"out": ["ticks-on", "keeps-time-with"], "in": ["keeps-time-with"]},
    "properties": {
        "cardinality":      {"type": "enum", "values": ["point", "interval"], "mutability": "immutable", "authority_scope": ""},
        "embedding":        {"type": "enum", "values": ["linear", "cyclic", "dag", "branching"], "mutability": "immutable", "authority_scope": ""},
        "frame":            {"type": "enum", "values": ["absolute", "relative"], "mutability": "immutable", "authority_scope": ""},
        "frame_anchor_urn": {"type": "urn", "mutability": "immutable", "authority_scope": "", "note": "required when frame=relative"},
        "density":          {"type": "enum", "values": ["sec", "min", "hr", "sweep", "T-day", "round", "program-cycle", "event-driven", "custom"], "mutability": "immutable", "authority_scope": ""},
        "density_n":        {"type": "number", "mutability": "immutable", "authority_scope": ""},
        "cycle_period":     {"type": "object", "mutability": "immutable", "authority_scope": "", "note": "required when embedding=cyclic"},
        "authority":        {"type": "enum", "values": ["kernel", "user", "session-occupant"], "mutability": "immutable", "authority_scope": ""},
        "scope_descriptor": {"type": "string", "mutability": "immutable", "authority_scope": ""},
        "status":           {"type": "enum", "values": ["active", "closed"], "mutability": "mutable", "authority_scope": "kernel"},
        "owner_urn":        {"type": "urn", "mutability": "immutable", "authority_scope": ""},
        "created_at":       {"type": "datetime", "mutability": "immutable", "authority_scope": ""}
    }
}

# Insert clock right after derivation (idx 21) → idx 22
s2 = data["types"]["s2_infrastructure"]
deriv_idx = next(i for i, t in enumerate(s2) if t["id"] == "derivation")
s2.insert(deriv_idx + 1, clock_type)

# --- 2. WF21 causes rewrite_category ---
wf21 = {
    "id": "WF21",
    "name": "causes",
    "allowed_rewrites": ["LINK", "UNLINK"],
    "src_types": ["derivation", "claim", "knowledge_item", "program", "task", "knowledge_artifact"],
    "tgt_types": ["derivation", "claim", "knowledge_item", "program", "task", "knowledge_artifact", "channel", "clock"],
    "src_port": "causes",
    "tgt_port": "caused-by",
    "authority": "owner",
    "mutate_scope": [],
    "sync_mode": "none",
    "validator_extension": "ValidateCausalAcyclic — reject any LINK that would close a cycle in the causes/caused-by DAG",
    "additional_port_pairs": []
}
data["rewrite_categories"].append(wf21)

# --- 3. channel.kind enum: add "video" and "audio" ---
for t in s2:
    if t["id"] == "channel":
        kinds = t["properties"]["kind"]["values"]
        for k in ("video", "audio"):
            if k not in kinds:
                kinds.append(k)
        break

# --- 4. substrate + substrate_anchor_urn on channel + knowledge_item ---
substrate_prop = {
    "type": "enum",
    "values": ["hg-native", "external-channel", "volatile", "cached", "federation-reconciled"],
    "mutability": "immutable",
    "authority_scope": "kernel",
    "note": "default hg-native; auto-defaulted on backfill for nodes minted pre-v3.15"
}
substrate_anchor_prop = {
    "type": "urn",
    "mutability": "immutable",
    "authority_scope": "kernel",
    "note": "required when substrate in {external-channel, federation-reconciled}; resolves to channel|derivation that anchors the external observation"
}
for t in s2:
    if t["id"] in ("channel", "knowledge_item"):
        if "substrate" not in t["properties"]:
            t["properties"]["substrate"] = substrate_prop
        if "substrate_anchor_urn" not in t["properties"]:
            t["properties"]["substrate_anchor_urn"] = substrate_anchor_prop

# --- 5. version bump + changelog ---
data["version"] = "3.15.0"
if "changelog" in data:
    data["changelog"].insert(0, {
        "version": "3.15.0",
        "date": "2026-04-26",
        "round": "round-15 (T=176)",
        "fragments_promoted": ["v314-2-clock-type", "v314-3-wf21-causes", "v314-4-substrate-property", "v314-6-channel-kind-video"],
        "summary": "Round-15 ceremony promotes 4 grammar_fragments into the runtime operad: clock node-type (S2; six canonical kinds covered), WF21 causes/caused-by rewrite-category (acyclic validator ValidateCausalAcyclic), substrate + substrate_anchor_urn properties on channel + knowledge_item, channel.kind enum extended with video + audio. Doctrine anchors: kb/research/spec/05-external-substrates.md §5.3.5; kb/research/spec/07-time-fabric.md §7.3.4-§7.3.5."
    })

ONTOLOGY.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
print(f"Bumped to {data['version']}")
print(f"s2_infrastructure: {len(s2)} types")
print(f"rewrite_categories: {len(data['rewrite_categories'])}")
print(f"channel.kind values: {[t['properties']['kind']['values'] for t in s2 if t['id']=='channel'][0]}")
