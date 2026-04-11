"""T161 hydration: programs, agents, sessions, tool wiring.

Pure functions that produce rewrite envelopes (dicts).
No IO — callers handle HTTP and file access.
"""
from __future__ import annotations

import hashlib
import json
from datetime import datetime, timezone
from typing import Any


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _urn_set(nodes: list[dict]) -> set[str]:
    return {n.get("urn", "") for n in nodes}


def _nodes_of_type(nodes: list[dict], type_id: str) -> list[dict]:
    return [n for n in nodes if n.get("type_id") == type_id]


def _relation_urn(wf: str, src: str, sp: str, tgt: str, tp: str) -> str:
    token = f"{wf}|{src}|{sp}|{tgt}|{tp}".encode()
    return f"urn:moos:rel:autogen.{hashlib.sha1(token).hexdigest()[:12]}"


def _prop(value: Any, *, mutability: str = "immutable",
          authority: str = "", typ: str = "string") -> dict:
    p: dict[str, Any] = {"value": value, "mutability": mutability, "type": typ}
    if authority:
        p["authority_scope"] = authority
    return p


def _add(urn: str, type_id: str, props: dict, actor: str) -> dict:
    return {
        "rewrite_type": "ADD",
        "actor": actor,
        "node_urn": urn,
        "type_id": type_id,
        "properties": props,
    }


def _link(wf: str, src: str, sp: str, tgt: str, tp: str,
          actor: str, **extra: Any) -> dict:
    env: dict[str, Any] = {
        "rewrite_type": "LINK",
        "rewrite_category": wf,
        "actor": actor,
        "relation_urn": _relation_urn(wf, src, sp, tgt, tp),
        "src_urn": src,
        "src_port": sp,
        "tgt_urn": tgt,
        "tgt_port": tp,
    }
    env.update(extra)
    return env


# ---------------------------------------------------------------------------
# Phase 1 — Program nodes (T-cards) + issue projection links
# ---------------------------------------------------------------------------

# T-card definitions: (slug, title, target_t, status)
_T_CARDS = [
    ("t158", "Foundation codex & ontology v3.5", 158, "completed"),
    ("t159", "Federation routing & presheaf projection", 159, "completed"),
    ("t160", "Gate-close: kernel authority & reactive engine", 160, "completed"),
    ("t161", "HG authority, provenance, agent sessions & tool wiring", 161, "active"),
    ("t162", "Distributed presheaf hydration & multi-agent flow", 162, "draft"),
    ("t163", "Claude agents: ignition on both workstations", 163, "draft"),
]


def plan_program_hydration(
    nodes: list[dict],
    relations: list[dict],
    actor: str,
    *,
    t_current: int = 161,
) -> list[dict]:
    """Return envelopes to ADD missing program nodes and LINK to issues."""
    existing = _urn_set(nodes)
    now = datetime.now(timezone.utc).isoformat()
    envelopes: list[dict] = []

    for slug, title, target_t, status in _T_CARDS:
        urn = f"urn:moos:program:sam.{slug}"
        if urn in existing:
            continue
        envelopes.append(_add(urn, "program", {
            "title": _prop(title),
            "owner_urn": _prop(actor, typ="urn"),
            "status": _prop(status, mutability="mutable", authority="owner",
                            typ="enum"),
            "target_t": _prop(target_t, mutability="mutable", authority="owner",
                              typ="integer"),
            "created_at": _prop(now, typ="datetime"),
        }, actor))

    # Link programs → git_issues via WF18 (program composition: produces/produced-by)
    programs = _nodes_of_type(nodes, "program") + [
        e for e in envelopes if e.get("type_id") == "program"
    ]
    issues = _nodes_of_type(nodes, "git_issue")

    # Simple heuristic: link issues mentioning a T-number to its program
    for issue in issues:
        issue_urn = issue.get("urn", "")
        for prog in programs:
            prog_urn = prog.get("urn") or prog.get("node_urn", "")
            slug = prog_urn.split(".")[-1] if prog_urn else ""
            if not slug:
                continue
            rel_urn = _relation_urn("WF18", prog_urn, "produces", issue_urn, "produced-by")
            already = any(
                r.get("src_urn") == prog_urn
                and r.get("tgt_urn") == issue_urn
                and r.get("rewrite_category") == "WF18"
                for r in relations
            )
            if already:
                continue
            # Only link if issue number plausibly maps to this program's timeframe
            # (conservative: link ffs0 issues to t161 since they're current work)
            if slug == f"t{t_current}" and "ffs0" in issue_urn:
                envelopes.append(_link(
                    "WF18", prog_urn, "produces",
                    issue_urn, "produced-by", actor,
                ))

    return envelopes


# ---------------------------------------------------------------------------
# Phase 2a — Agent nodes (laptop agents)
# ---------------------------------------------------------------------------

_EXPECTED_AGENTS = [
    ("urn:moos:agent:antigravity.hp-z440", "antigravity.hp-z440", "ide", "hp-z440"),
    ("urn:moos:agent:vscode-codex.hp-z440", "vscode-codex.hp-z440", "ide", "hp-z440"),
    ("urn:moos:agent:claude-code.hp-z440", "claude-code.hp-z440", "ide", "hp-z440"),
    ("urn:moos:agent:antigravity.hp-laptop", "antigravity.hp-laptop", "ide", "hp-laptop"),
    ("urn:moos:agent:claude-code.hp-laptop", "claude-code.hp-laptop", "ide", "hp-laptop"),
]


def plan_agent_hydration(nodes: list[dict], actor: str) -> list[dict]:
    """Return ADD envelopes for missing agent nodes."""
    existing = _urn_set(nodes)
    now = datetime.now(timezone.utc).isoformat()
    envelopes: list[dict] = []

    for urn, name, delegate_type, workstation in _EXPECTED_AGENTS:
        if urn in existing:
            continue
        envelopes.append(_add(urn, "agent", {
            "name": _prop(name),
            "delegate_type": _prop(delegate_type),
            "owner_urn": _prop(actor, typ="urn"),
            "status": _prop("idle", mutability="mutable"),
            "created_at": _prop(now, typ="datetime"),
        }, actor))

    return envelopes


# ---------------------------------------------------------------------------
# Phase 2b — Agent session topology
# ---------------------------------------------------------------------------

def plan_session_hydration(
    nodes: list[dict],
    relations: list[dict],
    actor: str,
    *,
    agent_urn: str,
    program_urn: str,
    t_day: int,
) -> list[dict]:
    """Return envelopes to ADD an agent_session and LINK it to agent + program."""
    existing = _urn_set(nodes)
    now = datetime.now(timezone.utc).isoformat()

    # Derive slug from agent URN: e.g. vscode-codex.hp-z440 → vscode-codex-hp-z440
    agent_slug = agent_urn.split(":")[-1].replace(".", "-")
    session_urn = f"urn:moos:session:{agent_slug}.t{t_day}"

    if session_urn in existing:
        return []

    envelopes: list[dict] = []

    # ADD agent_session node
    envelopes.append(_add(session_urn, "agent_session", {
        "name": _prop(f"{agent_slug}.t{t_day}"),
        "agent_urn": _prop(agent_urn, typ="urn"),
        "role": _prop("active", mutability="mutable", authority="owner", typ="enum"),
        "status": _prop("open", mutability="mutable", authority="kernel", typ="enum"),
        "t_day": _prop(t_day, typ="integer"),
        "created_at": _prop(now, typ="datetime"),
    }, actor))

    # LINK agent → session via WF07 (participates / participated-by)
    envelopes.append(_link(
        "WF07", agent_urn, "participates",
        session_urn, "participated-by", actor,
    ))

    # LINK session → program via focus port (WF07)
    envelopes.append(_link(
        "WF07", session_urn, "focus",
        program_urn, "anchor", actor,
    ))

    return envelopes


# ---------------------------------------------------------------------------
# Phase 4 — Tool wiring: watcher + reactor + guard
# ---------------------------------------------------------------------------

def plan_tool_wiring(
    nodes: list[dict],
    relations: list[dict],
    actor: str,
    *,
    tool_name: str,
    match_type_id: str = "tool_call",
) -> list[dict]:
    """Return envelopes to wire a tool as a watcher+reactor+guard triple."""
    existing = _urn_set(nodes)
    now = datetime.now(timezone.utc).isoformat()

    watcher_urn = f"urn:moos:watcher:tool.{tool_name}"
    reactor_urn = f"urn:moos:reactor:tool.{tool_name}"
    guard_urn = f"urn:moos:guard:tool.{tool_name}"

    # If watcher already exists, tool is already wired
    if watcher_urn in existing:
        return []

    envelopes: list[dict] = []

    # ADD watcher — pattern matcher for tool_call ADDs
    envelopes.append(_add(watcher_urn, "watcher", {
        "name": _prop(f"tool.{tool_name}"),
        "match_rewrite_type": _prop("ADD"),
        "match_type_id": _prop(match_type_id),
        "status": _prop("active", mutability="mutable"),
        "owner_urn": _prop(actor, typ="urn"),
        "created_at": _prop(now, typ="datetime"),
    }, actor))

    # ADD reactor — template that produces a tool_result node
    template = {
        "rewrite_type": "ADD",
        "actor": "$actor",
        "node_urn": f"urn:moos:tool_result:$matched_urn.result",
        "type_id": "tool_result",
        "properties": {
            "status": {"value": "completed", "mutability": "immutable", "type": "string"},
            "output": {"value": {"tool": tool_name, "source": "$matched_urn"},
                       "mutability": "immutable", "type": "object"},
            "for_call_urn": {"value": "$matched_urn", "mutability": "immutable", "type": "urn"},
        },
    }
    envelopes.append(_add(reactor_urn, "reactor", {
        "name": _prop(f"tool.{tool_name}"),
        "action_type": _prop("rewrite"),
        "template": _prop(template, typ="object"),
        "status": _prop("active", mutability="mutable"),
        "owner_urn": _prop(actor, typ="urn"),
        "created_at": _prop(now, typ="datetime"),
    }, actor))

    # ADD guard — predicate filtering on tool_name property
    envelopes.append(_add(guard_urn, "guard", {
        "name": _prop(f"tool.{tool_name}.guard"),
        "predicate_type": _prop("node_property"),
        "field": _prop("tool_name"),
        "expected_value": _prop(tool_name),
        "target_urn": _prop("$matched_urn", typ="urn"),
        "negate": _prop(False, typ="string"),
        "owner_urn": _prop(actor, typ="urn"),
        "created_at": _prop(now, typ="datetime"),
    }, actor))

    # LINK watcher → reactor (WF17 triggers/triggered-by)
    envelopes.append(_link(
        "WF17", watcher_urn, "triggers",
        reactor_urn, "triggered-by", actor,
    ))

    # LINK guard → watcher (WF17 guards/guarded-by)
    envelopes.append(_link(
        "WF17", guard_urn, "guards",
        watcher_urn, "guarded-by", actor,
    ))

    return envelopes
