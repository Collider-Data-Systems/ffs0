from __future__ import annotations

import hashlib
import json
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any
from urllib import request


@dataclass
class MissingLink:
    wf: str
    src_type: str
    tgt_type: str
    src_urn: str
    tgt_urn: str
    reason: str


@dataclass
class BaselineReport:
    ok: bool
    node_count: int
    relation_count: int
    missing: list[MissingLink]

    def to_dict(self) -> dict[str, Any]:
        return {
            "ok": self.ok,
            "node_count": self.node_count,
            "relation_count": self.relation_count,
            "missing": [asdict(m) for m in self.missing],
        }


def load_json(path: str | Path) -> dict[str, Any]:
    return json.loads(Path(path).read_text(encoding="utf-8"))


def fetch_state(base_url: str) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    nodes = _http_json("GET", f"{base_url.rstrip('/')}/state/nodes")
    relations = _http_json("GET", f"{base_url.rstrip('/')}/state/relations")
    return nodes, relations


def post_program(base_url: str, envelopes: list[dict[str, Any]]) -> Any:
    return _http_json("POST", f"{base_url.rstrip('/')}/programs", envelopes)


def relation_urn(wf: str, src_urn: str, src_port: str, tgt_urn: str, tgt_port: str) -> str:
    token = f"{wf}|{src_urn}|{src_port}|{tgt_urn}|{tgt_port}".encode("utf-8")
    h = hashlib.sha1(token).hexdigest()[:12]
    return f"urn:moos:rel:autogen.{h}"


def relation_exists(
    relations: list[dict[str, Any]],
    wf: str,
    src_urn: str,
    src_port: str,
    tgt_urn: str,
    tgt_port: str,
) -> bool:
    for rel in relations:
        if (
            rel.get("rewrite_category") == wf
            and rel.get("src_urn") == src_urn
            and rel.get("src_port") == src_port
            and rel.get("tgt_urn") == tgt_urn
            and rel.get("tgt_port") == tgt_port
        ):
            return True
    return False


def verify_baseline(
    nodes: list[dict[str, Any]],
    relations: list[dict[str, Any]],
    ontology: dict[str, Any],
) -> dict[str, Any]:
    wf_map = _wf_map(ontology)
    node_map = {n.get("urn"): n for n in nodes if n.get("urn")}

    users = _nodes_by_type(nodes, "user")
    agents = _nodes_by_type(nodes, "agent")
    workstations = _nodes_by_type(nodes, "workstation")
    kernels = _nodes_by_type(nodes, "kernel")

    missing: list[MissingLink] = []

    if users:
        user_urn = users[0]["urn"]
        wf02 = wf_map.get("WF02")
        if wf02:
            for agent in agents:
                if not relation_exists(
                    relations,
                    "WF02",
                    user_urn,
                    wf02["src_port"],
                    agent["urn"],
                    wf02["tgt_port"],
                ):
                    missing.append(
                        MissingLink(
                            wf="WF02",
                            src_type="user",
                            tgt_type="agent",
                            src_urn=user_urn,
                            tgt_urn=agent["urn"],
                            reason="agent missing governance link",
                        )
                    )

    wf03 = wf_map.get("WF03")
    if wf03:
        for kernel in kernels:
            ws = _infer_workstation_for_kernel(kernel["urn"], workstations)
            if not ws:
                continue
            if not relation_exists(
                relations,
                "WF03",
                ws["urn"],
                wf03["src_port"],
                kernel["urn"],
                wf03["tgt_port"],
            ):
                missing.append(
                    MissingLink(
                        wf="WF03",
                        src_type="workstation",
                        tgt_type="kernel",
                        src_urn=ws["urn"],
                        tgt_urn=kernel["urn"],
                        reason="kernel missing host link",
                    )
                )

    wf16 = wf_map.get("WF16")
    if wf16:
        for kernel in kernels:
            inbound = any(
                rel.get("rewrite_category") == "WF16"
                and rel.get("tgt_urn") == kernel["urn"]
                and rel.get("tgt_port") == wf16["tgt_port"]
                for rel in relations
            )
            if not inbound:
                missing.append(
                    MissingLink(
                        wf="WF16",
                        src_type="shard_rule",
                        tgt_type="kernel",
                        src_urn="",
                        tgt_urn=kernel["urn"],
                        reason="kernel missing routed-from relation",
                    )
                )

    report = BaselineReport(
        ok=(len(missing) == 0),
        node_count=len(node_map),
        relation_count=len(relations),
        missing=missing,
    )
    return report.to_dict()


def propose_hydration(
    nodes: list[dict[str, Any]],
    relations: list[dict[str, Any]],
    ontology: dict[str, Any],
    actor: str,
) -> list[dict[str, Any]]:
    wf_map = _wf_map(ontology)

    users = _nodes_by_type(nodes, "user")
    agents = _nodes_by_type(nodes, "agent")
    workstations = _nodes_by_type(nodes, "workstation")
    kernels = _nodes_by_type(nodes, "kernel")
    shard_rules = _nodes_by_type(nodes, "shard_rule")

    proposals: list[dict[str, Any]] = []

    if users and "WF02" in wf_map:
        user_urn = users[0]["urn"]
        for agent in agents:
            proposals.extend(
                _link_if_missing(
                    relations,
                    wf="WF02",
                    src_urn=user_urn,
                    src_port=wf_map["WF02"]["src_port"],
                    tgt_urn=agent["urn"],
                    tgt_port=wf_map["WF02"]["tgt_port"],
                    actor=actor,
                )
            )

    if "WF03" in wf_map:
        for kernel in kernels:
            ws = _infer_workstation_for_kernel(kernel["urn"], workstations)
            if not ws:
                continue
            proposals.extend(
                _link_if_missing(
                    relations,
                    wf="WF03",
                    src_urn=ws["urn"],
                    src_port=wf_map["WF03"]["src_port"],
                    tgt_urn=kernel["urn"],
                    tgt_port=wf_map["WF03"]["tgt_port"],
                    actor=actor,
                )
            )

    if "WF16" in wf_map:
        for kernel in kernels:
            shard = _infer_shard_rule_for_kernel(kernel["urn"], shard_rules)
            if shard:
                proposals.extend(
                    _link_if_missing(
                        relations,
                        wf="WF16",
                        src_urn=shard["urn"],
                        src_port=wf_map["WF16"]["src_port"],
                        tgt_urn=kernel["urn"],
                        tgt_port=wf_map["WF16"]["tgt_port"],
                        actor=actor,
                    )
                )
                continue

            has_inbound = any(
                rel.get("rewrite_category") == "WF16"
                and rel.get("tgt_urn") == kernel["urn"]
                and rel.get("tgt_port") == wf_map["WF16"]["tgt_port"]
                for rel in relations
            )
            if has_inbound:
                continue

    return proposals


def _wf_map(ontology: dict[str, Any]) -> dict[str, dict[str, str]]:
    out: dict[str, dict[str, str]] = {}
    for wf in ontology.get("rewrite_categories", []):
        wf_id = wf.get("id")
        src_port = wf.get("src_port")
        tgt_port = wf.get("tgt_port")
        if wf_id and src_port and tgt_port:
            out[wf_id] = {"src_port": src_port, "tgt_port": tgt_port}
    return out


def _nodes_by_type(nodes: list[dict[str, Any]], type_id: str) -> list[dict[str, Any]]:
    return [n for n in nodes if n.get("type_id") == type_id and n.get("urn")]


def _infer_workstation_for_kernel(kernel_urn: str, workstations: list[dict[str, Any]]) -> dict[str, Any] | None:
    ws_name = ""
    prefix = "urn:moos:kernel:"
    if kernel_urn.startswith(prefix):
        rest = kernel_urn[len(prefix) :]
        ws_name = rest.split(".", 1)[0]

    if ws_name:
        for ws in workstations:
            if ws.get("urn", "").endswith(f":{ws_name}"):
                return ws

    return workstations[0] if workstations else None


def _infer_shard_rule_for_kernel(kernel_urn: str, shard_rules: list[dict[str, Any]]) -> dict[str, Any] | None:
    token = kernel_urn.split(":")[-1]
    workstation_token = token.split(".", 1)[0]

    # Prefer explicit shard URNs tied to the target kernel.
    direct_shard_urn = f"urn:moos:shard:{token}"
    for sr in shard_rules:
        if sr.get("urn") == direct_shard_urn:
            return sr

    # Primary kernels should prefer the workstation-level shard when available.
    if token.endswith(".primary") and workstation_token:
        root_shard_urn = f"urn:moos:shard:{workstation_token}"
        for sr in shard_rules:
            if sr.get("urn") == root_shard_urn:
                return sr

    for sr in shard_rules:
        urn_prefix = _property_value(sr, "urn_prefix")
        if not urn_prefix:
            continue
        if kernel_urn.startswith(urn_prefix) or urn_prefix.startswith(kernel_urn):
            return sr

    # fallback 1: match by full kernel suffix token
    for sr in shard_rules:
        urn_prefix = _property_value(sr, "urn_prefix")
        if token in sr.get("urn", "") or token in urn_prefix:
            return sr

    # fallback 2: primary kernels use workstation shard rules (e.g. hp-z440.primary -> shard:hp-z440)
    if workstation_token:
        exact_shard_urn = f"urn:moos:shard:{workstation_token}"
        exact_ws_prefix = f"urn:moos:ws:{workstation_token}"

        for sr in shard_rules:
            urn_prefix = _property_value(sr, "urn_prefix")
            if sr.get("urn") == exact_shard_urn or urn_prefix == exact_ws_prefix:
                return sr

        needle = f":{workstation_token}"
        for sr in shard_rules:
            urn_prefix = _property_value(sr, "urn_prefix")
            if needle in sr.get("urn", "") or needle in urn_prefix:
                return sr

    return None


def _property_value(node: dict[str, Any], name: str) -> str:
    props = node.get("properties") or {}
    if name not in props:
        return ""
    value_obj = props.get(name)
    if isinstance(value_obj, dict) and "value" in value_obj:
        return str(value_obj["value"])
    return str(value_obj)


def _link_if_missing(
    relations: list[dict[str, Any]],
    wf: str,
    src_urn: str,
    src_port: str,
    tgt_urn: str,
    tgt_port: str,
    actor: str,
) -> list[dict[str, Any]]:
    if relation_exists(relations, wf, src_urn, src_port, tgt_urn, tgt_port):
        return []

    return [
        {
            "rewrite_type": "LINK",
            "rewrite_category": wf,
            "actor": actor,
            "relation_urn": relation_urn(wf, src_urn, src_port, tgt_urn, tgt_port),
            "src_urn": src_urn,
            "src_port": src_port,
            "tgt_urn": tgt_urn,
            "tgt_port": tgt_port,
        }
    ]


def _http_json(method: str, url: str, body: Any | None = None) -> Any:
    headers = {"Content-Type": "application/json"}
    data = None
    if body is not None:
        data = json.dumps(body).encode("utf-8")

    req = request.Request(url=url, method=method, headers=headers, data=data)
    with request.urlopen(req, timeout=10) as resp:
        return json.loads(resp.read().decode("utf-8"))
