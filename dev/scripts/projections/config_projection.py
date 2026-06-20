#!/usr/bin/env python3
"""moos-config-projection (F) — prototype implementing dev/design/manifold-bump-4_0/
20260620-t231-moos-config-projection-spec.md (#58 Phase-4).

Folds the HG seat/surface topology (one row per WF19 has-occupant edge, spec §3) into the
generated AGENTS.md seat table, and runs the drift check (spec §4) against the hand-authored
table. Read-only: no kernel rewrite, no AGENTS.md write in --mode check.

  --mode check   (default)  fold from HG, semantic-diff vs the committed table, exit 1 on real drift
  --mode render             print the generated seat-table markdown + write evidence sidecar

Stdlib only. Authority spine = HG /state/* (spec §2); persona display name / emit / mcp come
from dev/config/moos-federation.topology.json (config-sourced display enrichment, tagged).
"""
import argparse, json, os, sys, urllib.request, re

def get_json(url):
    with urllib.request.urlopen(url, timeout=8) as r:
        return json.load(r)

def as_list(d, *keys):
    if isinstance(d, list): return d
    for k in keys:
        if isinstance(d, dict) and k in d: return d[k]
    return d if isinstance(d, list) else []

def alias(urn):
    # urn:moos:<type>:<rest> -> <rest>
    return urn.split(":", 3)[-1] if urn and urn.startswith("urn:moos:") else urn

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))

def fold_from_hg(base_url, topo):
    nodes = as_list(get_json(base_url.rstrip("/") + "/state/nodes"), "nodes", "node")
    rels  = as_list(get_json(base_url.rstrip("/") + "/state/relations"), "relations", "relation")
    by_port = lambda p: [r for r in rels if r.get("src_port") == p]
    opens_on   = {r["src_urn"]: r["tgt_urn"] for r in by_port("opens-on")}
    has_purpose= {r["src_urn"]: r["tgt_urn"] for r in by_port("has-purpose")}
    persona_by_actor = {b["actor_urn"]: dict(b, name=name) for name, b in topo.get("personas", {}).items()}
    kernels = topo.get("kernels", {})
    def kernel_port(kalias):
        k = kernels.get(kalias, {})
        # http_local like http://localhost:8000 -> :8000
        m = re.search(r":(\d+)$", k.get("http_local", "") or k.get("http_lan", ""))
        return (":" + m.group(1)) if m else ""
    rows = []
    for r in by_port("has-occupant"):
        ws, agent = r["src_urn"], r["tgt_urn"]
        pa = persona_by_actor.get(agent, {})
        k_urn = opens_on.get(ws) or ("urn:moos:kernel:" + pa.get("opens_on_kernel", "")) if pa.get("opens_on_kernel") else opens_on.get(ws)
        k_alias = alias(k_urn) if k_urn else ""
        emit_alias = pa.get("emit_kernel", "")
        mcp = topo.get("mcp_servers", {}).get(pa.get("mcp_server", ""), "")
        rows.append({
            "persona": pa.get("name", "Φ(purpose)?"),       # config-sourced display (tagged)
            "agent": alias(agent),                            # HG
            "workspace": alias(ws),                           # HG (session, D2)
            "instance": k_alias,                              # HG opens-on (D6)
            "instance_port": kernel_port(k_alias),            # config
            "emit_kernel": emit_alias,                        # config (§M9 split)
            "mcp": mcp,                                       # config
            "purpose": alias(has_purpose.get(ws, "")),        # HG
            "_host": k_alias.split(".")[0] if k_alias else "zzz",
        })
    rows.sort(key=lambda r: (r["_host"], r["instance_port"], r["workspace"]))
    return rows

def render_table(rows):
    head = "| Persona (config·D3) | Agent (HG principal) | Workspace ⟵session (HG·D2) | Instance ⟵kernel (HG opens-on·D6) | emit (§M9) | MCP |"
    sep  = "|---|---|---|---|---|---|"
    out = [
        "<!-- BEGIN GENERATED: moos-config-projection seat-table v0-prototype (source: HG /state/has-occupant; persona/emit/mcp = topology config; do not hand-edit) -->",
        head, sep,
    ]
    for r in rows:
        inst = (("`%s`" % r["instance"]) + (" " + r["instance_port"] if r["instance_port"] else "")) if r["instance"] else "—"
        emit = ("`%s`" % r["emit_kernel"]) if r["emit_kernel"] else "—"
        out.append("| %s | `%s` | `%s` | %s | %s | %s |" % (
            r["persona"], r["agent"], r["workspace"], inst, emit, r["mcp"] or "—"))
    out.append("<!-- END GENERATED: moos-config-projection seat-table -->")
    return "\n".join(out)

def parse_authored_seats(agents_md):
    """Extract the hand-authored ## Seats table rows -> list of dicts keyed by agent alias."""
    txt = open(agents_md, encoding="utf-8").read()
    m = re.search(r"## Seats.*?\n(\|.*?)(?:\n\n|\n##)", txt, re.S)
    if not m: return []
    rows = []
    for line in m.group(1).splitlines():
        if not line.startswith("|") or set(line) <= set("|-: "): continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) < 4 or cells[0].lower().startswith("persona"): continue
        def bt(s): return s.replace("`", "").strip()
        agent = bt(cells[1])
        inst = bt(cells[3])
        rows.append({"persona": cells[0], "agent": agent,
                     "workspace": bt(cells[2]),
                     "instance_raw": inst,
                     "instance": (re.split(r"\s", inst)[0] if inst else "")})
    return rows

def drift_check(hg_rows, authored):
    hg_by_agent = {}
    for r in hg_rows:  # an agent (e.g. vscode.hp-z440.primary) may occupy 2 workspaces
        hg_by_agent.setdefault(r["agent"], []).append(r)
    auth_agents = {a["agent"] for a in authored}
    hg_agents = set(hg_by_agent)
    drift = []   # real drift -> exit 1
    info  = []   # authored-ahead / cross-kernel -> warn only
    # HG seats missing from the authored table = real drift (table omits a live seat)
    for a in sorted(hg_agents - auth_agents):
        drift.append("HG-only seat NOT in authored table: agent `%s` (workspaces: %s)" %
                     (a, ", ".join(r["workspace"] for r in hg_by_agent[a])))
    # authored seats not in this kernel's HG = info (other kernel / planned)
    for a in sorted(auth_agents - hg_agents):
        info.append("authored seat not on this kernel's HG (other-kernel/planned): `%s`" % a)
    # field mismatch on shared agents (HG opens-on instance vs authored instance)
    for a in sorted(hg_agents & auth_agents):
        au = next(x for x in authored if x["agent"] == a)
        hg_insts = {r["instance"] for r in hg_by_agent[a]}
        if au["instance"] and not any(au["instance"].startswith(i) or i.startswith(au["instance"]) for i in hg_insts if i):
            drift.append("instance mismatch for `%s`: authored=`%s` HG opens-on=%s" %
                         (a, au["instance"], sorted(hg_insts)))
    return drift, info

def main():
    try: sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except Exception: pass
    ap = argparse.ArgumentParser()
    ap.add_argument("--base-url", default="http://localhost:8000")
    ap.add_argument("--agents", default=os.path.join(REPO, "AGENTS.md"))
    ap.add_argument("--topology", default=os.path.join(REPO, "dev", "config", "moos-federation.topology.json"))
    ap.add_argument("--mode", choices=["check", "render"], default="check")
    ap.add_argument("--out", default=os.path.join(REPO, "tmp", "projections", "session_pipeline", "config"))
    a = ap.parse_args()
    topo = json.load(open(a.topology, encoding="utf-8"))
    hg_rows = fold_from_hg(a.base_url, topo)
    table = render_table(hg_rows)
    os.makedirs(a.out, exist_ok=True)
    open(os.path.join(a.out, "seat-table.generated.md"), "w", encoding="utf-8").write(table + "\n")
    json.dump(hg_rows, open(os.path.join(a.out, "seat-table.folded.json"), "w", encoding="utf-8"), indent=1)

    print("# moos-config-projection (%s) — base %s" % (a.mode, a.base_url))
    print("folded %d seat rows from HG has-occupant (evidence -> %s)\n" % (len(hg_rows), os.path.relpath(a.out, REPO)))
    if a.mode == "render":
        print(table)
        return 0
    authored = parse_authored_seats(a.agents)
    print("authored AGENTS.md seat rows: %d\n" % len(authored))
    drift, info = drift_check(hg_rows, authored)
    for i in info:  print("  ~ WARN", i)
    if info: print()
    if not drift:
        print("DRIFT CHECK: PASS — every live HG seat is present in the authored table with a consistent instance.")
        return 0
    for d in drift: print("  ! DRIFT", d)
    print("\nDRIFT CHECK: FAIL (%d) — resolution is regenerate-from-HG (--mode write), not hand-edit (spec §4)." % len(drift))
    return 1

if __name__ == "__main__":
    sys.exit(main())
