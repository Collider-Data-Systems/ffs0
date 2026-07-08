#!/usr/bin/env python3
"""moos-config-projection (F) — implements dev/design/manifold-bump-4_0/
20260620-t231-moos-config-projection-spec.md (#58 Phase-4).

Folds the HG seat/surface topology (one row per WF19 has-occupant edge, spec section 3)
into the generated AGENTS.md seat table (fenced region, spec section 5), and runs the
drift check (spec section 4).

  --mode check   (default)  fold from HG; if fences exist, byte-compare the fenced region
                            against the regenerated table (exit 1 on drift); else run the
                            legacy semantic check against the hand-authored table. If the
                            fold came from --fallback-url (router down) and drops
                            previously-generated seats, that is ERROR exit 2 (partial
                            fan-in — bring the router up), never proposed as row deletions
  --mode render             print the generated seat-table markdown + write evidence sidecar
  --mode write              the explicit boundary act: replace the fenced region in AGENTS.md
                            (first write replaces the hand-authored seat table and installs
                            the fences). Refuses to drop previously-generated seats unless
                            --allow-shrink (protects against a partial fan-in eating rows).

Authority spine = HG /state/* (spec section 2), read via the federation router fan-in
(default http://localhost:9000) so cross-kernel seats fold in one read (spec Q1), falling
back to the local engine :8000. Persona display names + D7 surface labels + emit/MCP come
from dev/config/seat-display.json + moos-federation.topology.json (config-sourced display
enrichment, tagged; excluded from HG-authority adjudication).

Idempotence (spec section 4): stable total sort, single table emitter, no timestamps in the
generated block -> same folded HG => byte-identical region. Stdlib only.
"""
import argparse, json, os, sys, urllib.request, re

FENCE_BEGIN = "<!-- BEGIN GENERATED: moos-config-projection seat-table v1 (source: HG /state has-occupant via router fan-in; persona/surface/mcp = seat-display config; do not hand-edit — regenerate with --mode write) -->"
FENCE_END   = "<!-- END GENERATED: moos-config-projection seat-table -->"
FENCE_BEGIN_STABLE = "<!-- BEGIN GENERATED: moos-config-projection seat-table"   # version-independent locator
REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))

def get_json(url, timeout=20):
    with urllib.request.urlopen(url, timeout=timeout) as r:
        return json.load(r)

def as_list(d, *keys):
    if isinstance(d, list): return d
    for k in keys:
        if isinstance(d, dict) and k in d: return d[k]
    return d if isinstance(d, list) else []

def alias(urn):
    return urn.split(":", 3)[-1] if urn and urn.startswith("urn:moos:") else (urn or "")

def read_state(base_url):
    b = base_url.rstrip("/")
    nodes = as_list(get_json(b + "/state/nodes"), "nodes", "node")
    rels  = as_list(get_json(b + "/state/relations"), "relations", "relation")
    return nodes, rels

def fold_from_hg(base_url, fallback_url, topo, disp):
    """One row per WF19 has-occupant edge (spec section 3). Returns (rows, source_url,
    primary_err) — primary_err is None when the router fan-in served the read, else the
    exception that forced the fallback (a fallback fold sees only the local engine, so
    cross-kernel seats are missing — never adjudicate a shrink from it)."""
    primary_err = None
    try:
        nodes, rels = read_state(base_url); src = base_url
    except Exception as e:
        primary_err = e
        nodes, rels = read_state(fallback_url); src = fallback_url
    by_port = lambda p: [r for r in rels if r.get("src_port") == p]
    opens_on    = {r["src_urn"]: r["tgt_urn"] for r in by_port("opens-on")}
    has_purpose = {r["src_urn"]: r["tgt_urn"] for r in by_port("has-purpose")}
    persona_by_actor = {b["actor_urn"]: dict(b, key=name) for name, b in topo.get("personas", {}).items()}
    kernels = topo.get("kernels", {})
    seats_disp = disp.get("seats", {})
    host_order = {h: i for i, h in enumerate(disp.get("workstation_order", []))}

    def kernel_port(kalias):
        k = kernels.get(kalias, {})
        m = re.search(r":(\d+)$", k.get("http_local", "") or k.get("http_lan", "") or k.get("http_tailscale", ""))
        return (":" + m.group(1)) if m else ""

    rows = []
    for r in by_port("has-occupant"):
        ws, agent = r["src_urn"], r["tgt_urn"]
        pa = persona_by_actor.get(agent, {})
        sd = seats_disp.get(agent, {})
        k_urn = opens_on.get(ws)
        if not k_urn and pa.get("opens_on_kernel"):
            k_urn = "urn:moos:kernel:" + pa["opens_on_kernel"]      # config fallback, tagged
        k_alias = alias(k_urn)
        emit = pa.get("emit_kernel", "")
        mcp = pa.get("mcp_server", "")               # server NAME (box-relative URLs mislead cross-host)
        if pa.get("topology_mcp_server"):
            mcp += " *(opens-on `%s`)*" % pa["topology_mcp_server"]
        host = k_alias.split(".")[0] if k_alias else "zzz"
        rows.append({
            "persona":   sd.get("persona") or pa.get("key", "Φ(purpose)?"),   # config display (D3 pending Q2)
            "agent":     alias(agent),                                          # HG principal
            "workspace": alias(ws),                                             # HG session (D2)
            "engine":    k_alias,                                               # HG opens-on (D6: engine⟵kernel)
            "engine_port": kernel_port(k_alias),                                # config
            "emit":      emit,                                                  # config (§M9 split)
            "surface":   sd.get("surface", "—"),                                # config (D7 pending realizes)
            "mcp":       mcp,                                                   # config
            "purpose":   alias(has_purpose.get(ws, "")),                        # HG
            "_sort": (host_order.get(host, 99), kernel_port(k_alias), alias(ws)),
        })
    rows.sort(key=lambda r: r["_sort"])
    return rows, src, primary_err

def render_region(rows):
    """The fenced generated block. Deterministic; no timestamps (spec section 4)."""
    head = "| Persona (=Φ(purpose), D3·config) | Agent (HG principal) | Workspace ⟵`session` (HG·D2) | Engine ⟵`kernel` (HG opens-on·D6) | Surface / IDE-instance (D7·config) | MCP (config) |"
    sep  = "|---|---|---|---|---|---|"
    out = [FENCE_BEGIN, head, sep]
    for r in rows:
        eng = ("`%s` %s" % (r["engine"], r["engine_port"])).strip() if r["engine"] else "—"
        if r["emit"] and r["emit"] != r["engine"]:
            eng += " *(emits `%s` pre-§M9)*" % r["emit"]
        out.append("| %s | `%s` | `%s` | %s | %s | %s |" % (
            r["persona"], r["agent"], r["workspace"], eng, r["surface"], r["mcp"] or "—"))
    out.append(FENCE_END)
    return "\n".join(out)

def find_region(txt):
    """Return (start, end) spans of the fenced region incl. fences, or None."""
    b = txt.find(FENCE_BEGIN_STABLE)                    # version-independent (survives v2, v3, ...)
    if b < 0: return None
    e = txt.find(FENCE_END, b)
    if e < 0: return None
    return (b, e + len(FENCE_END))

def find_authored_table(txt):
    """First-adoption target: the first consecutive pipe-line block after the '## Seats'
    heading (heading + blockquote note + trailing prose all stay untouched)."""
    h = re.search(r"^## Seats[^\n]*$", txt, re.M)
    if not h: return None
    nxt = re.search(r"^##? ", txt[h.end():], re.M)              # don't run into the next section
    limit = h.end() + (nxt.start() if nxt else len(txt) - h.end())
    seg = txt[h.end():limit]
    m = re.search(r"^(\|[^\n]*\n)+", seg, re.M)
    if not m: return None
    return (h.end() + m.start(), h.end() + m.end())

def region_agents(region_txt):
    ags = set()
    for line in region_txt.splitlines():
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) >= 2 and cells[1].startswith("`") and not cells[0].lower().startswith("persona"):
            ags.add(cells[1].strip("`"))
    return ags

# ---------- legacy semantic check (pre-fence tables) ----------
def parse_authored_seats(txt):
    m = re.search(r"## Seats.*?\n(\|.*?)(?:\n\n|\n##)", txt, re.S)
    if not m: return []
    rows = []
    for line in m.group(1).splitlines():
        if not line.startswith("|") or set(line) <= set("|-: "): continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) < 4 or cells[0].lower().startswith("persona"): continue
        bt = lambda s: s.replace("`", "").strip()
        inst = bt(cells[3])
        rows.append({"agent": bt(cells[1]), "workspace": bt(cells[2]),
                     "instance": (re.split(r"\s", inst)[0] if inst else "")})
    return rows

def semantic_drift(hg_rows, authored):
    hg_by_agent = {}
    for r in hg_rows: hg_by_agent.setdefault(r["agent"], []).append(r)
    auth_agents = {a["agent"] for a in authored}
    drift, info = [], []
    for a in sorted(set(hg_by_agent) - auth_agents):
        drift.append("HG-only seat NOT in authored table: agent `%s` (workspaces: %s)" %
                     (a, ", ".join(r["workspace"] for r in hg_by_agent[a])))
    for a in sorted(auth_agents - set(hg_by_agent)):
        info.append("authored seat not folded from HG (kernel unreachable/planned): `%s`" % a)
    for a in sorted(set(hg_by_agent) & auth_agents):
        au = next(x for x in authored if x["agent"] == a)
        engines = {r["engine"] for r in hg_by_agent[a]}
        if au["instance"] and not any(au["instance"].startswith(i) or (i and i.startswith(au["instance"])) for i in engines):
            drift.append("engine mismatch for `%s`: authored=`%s` HG opens-on=%s" % (a, au["instance"], sorted(engines)))
    return drift, info

def main():
    try: sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except Exception: pass
    ap = argparse.ArgumentParser()
    ap.add_argument("--base-url", default="http://localhost:9000",
                    help="router fan-in preferred (cross-kernel, spec Q1)")
    ap.add_argument("--fallback-url", default="http://localhost:8000")
    ap.add_argument("--agents", default=os.path.join(REPO, "AGENTS.md"))
    ap.add_argument("--topology", default=os.path.join(REPO, "dev", "config", "moos-federation.topology.json"))
    ap.add_argument("--display", default=os.path.join(REPO, "dev", "config", "seat-display.json"))
    ap.add_argument("--mode", choices=["check", "render", "write"], default="check")
    ap.add_argument("--allow-shrink", action="store_true",
                    help="permit --mode write to drop seats present in the previous generated region")
    ap.add_argument("--offline-ok", action="store_true",
                    help="check mode: if no engine/router is reachable, verify fence integrity only (CI)")
    ap.add_argument("--out", default=os.path.join(REPO, "tmp", "projections", "session_pipeline", "config"))
    a = ap.parse_args()

    topo = json.load(open(a.topology, encoding="utf-8"))
    disp = json.load(open(a.display, encoding="utf-8")) if os.path.exists(a.display) else {}
    txt = open(a.agents, encoding="utf-8").read()
    span = find_region(txt)

    try:
        hg_rows, src, primary_err = fold_from_hg(a.base_url, a.fallback_url, topo, disp)
    except Exception as e:
        if a.mode == "check" and a.offline_ok:
            print("# moos-config-projection (check, OFFLINE) — no engine/router reachable (%s)" % e)
            if span:
                print("fence integrity: BEGIN/END present, region %d bytes — PASS (HG comparison skipped offline)"
                      % (span[1] - span[0]))
                return 0
            print("fence integrity: NO fenced region in AGENTS.md — FAIL (run --mode write on a live box)")
            return 1
        raise

    region = render_region(hg_rows)
    os.makedirs(a.out, exist_ok=True)
    open(os.path.join(a.out, "seat-table.generated.md"), "w", encoding="utf-8").write(region + "\n")
    json.dump([{k: v for k, v in r.items() if k != "_sort"} for r in hg_rows],
              open(os.path.join(a.out, "seat-table.folded.json"), "w", encoding="utf-8"), indent=1)

    print("# moos-config-projection (%s) — source %s" % (a.mode, src))
    if primary_err is not None:
        print("!! PARTIAL FAN-IN: primary source %s FAILED (%s: %s)" %
              (a.base_url, type(primary_err).__name__, primary_err))
        print("!! folded from FALLBACK %s — cross-kernel seats are missing from this fold" % src)
    print("folded %d seat rows from HG has-occupant (evidence -> %s)\n" % (len(hg_rows), os.path.relpath(a.out, REPO)))

    if a.mode == "render":
        print(region); return 0

    if a.mode == "write":
        if span:
            old_region = txt[span[0]:span[1]]
            dropped = region_agents(old_region) - {r["agent"] for r in hg_rows}
            if dropped and not a.allow_shrink:
                print("WRITE REFUSED: fold would drop previously-generated seat(s): %s" % ", ".join(sorted(dropped)))
                print("(partial fan-in? bring the kernel up, or pass --allow-shrink deliberately)")
                return 2
            new_txt = txt[:span[0]] + region + txt[span[1]:]
            action = "replaced fenced region"
        else:
            tspan = find_authored_table(txt)
            if not tspan:
                print("WRITE FAILED: no fenced region and no '## Seats' table found"); return 2
            new_txt = txt[:tspan[0]] + region + "\n" + txt[tspan[1]:]
            action = "first-adoption: replaced hand-authored seat table with fenced generated region"
        if new_txt == txt:
            print("WRITE: no change (already byte-identical — idempotent)"); return 0
        open(a.agents, "w", encoding="utf-8", newline="").write(new_txt)
        print("WRITE: %s in %s (%d rows)" % (action, os.path.relpath(a.agents, REPO), len(hg_rows)))
        return 0

    # -------- check --------
    if span:
        committed = txt[span[0]:span[1]]
        if committed == region:
            print("DRIFT CHECK: PASS — fenced region is byte-identical to the HG fold (%d rows)." % len(hg_rows))
            return 0
        if primary_err is not None:
            dropped = region_agents(committed) - {r["agent"] for r in hg_rows}
            if dropped:
                print("DRIFT CHECK: ERROR — partial fan-in: FALLBACK fold (%s) is missing previously-generated seat(s): %s"
                      % (src, ", ".join(sorted(dropped))))
                print("partial fan-in — bring the router up (%s) and re-run; refusing to propose row deletions from a partial source." % a.base_url)
                return 2
        import difflib
        diff = list(difflib.unified_diff(committed.splitlines(), region.splitlines(),
                                         "AGENTS.md (committed)", "HG fold (regenerated)", lineterm=""))
        for line in diff[:60]: print(line)
        print("\nDRIFT CHECK: FAIL — fenced region diverges from HG; resolution is --mode write (never hand-edit).")
        return 1
    authored = parse_authored_seats(txt)
    print("no fenced region yet — legacy semantic check vs hand-authored table (%d rows)\n" % len(authored))
    drift, info = semantic_drift(hg_rows, authored)
    for i in info: print("  ~ WARN", i)
    if info: print()
    if not drift:
        print("DRIFT CHECK: PASS — every folded HG seat is present and consistent."); return 0
    for d in drift: print("  ! DRIFT", d)
    print("\nDRIFT CHECK: FAIL (%d) — resolution is regenerate (--mode write), not hand-edit." % len(drift))
    return 1

if __name__ == "__main__":
    sys.exit(main())
