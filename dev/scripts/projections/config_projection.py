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

  --self-test               offline gate for the fan-in collapse + §M19 detector; no engine

Exit codes: 0 ok · 1 drift · 2 partial fan-in · 3 §M19 duplicate occupancy. 3 is distinct
from 1 on purpose — drift is resolved by regenerating, a §M19 violation is not (regenerating
renders the duplicate faithfully; the fix is an UNLINK on the owning engine).

Fan-in duplicates (T=264, ffs0#174): the router concatenates /state/relations across
kernels, so one relation can arrive over more than one path. Those are collapsed on the
relation URN before rows are built — one relation seen twice is not two seats. Two
has-occupant relations with DISTINCT URNs on one (workspace, agent) pair are the opposite
case and are never collapsed: that is a §M19 violation, and smoothing it here would erase
the only evidence of it. The duplicate ProDesk row audited at T=264 came from the missing
collapse; the audit found the fold itself clean.

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

EXIT_M19 = 3   # §M19 duplicate occupancy — distinct from drift (1) and partial fan-in (2),
               # because "regenerate with --mode write" is the wrong resolution for it

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

def collapse_fanin(rels):
    """The router fan-in concatenates /state/relations across kernels, so ONE relation can
    arrive over more than one path and be counted twice. Collapse on the relation URN —
    that is one relation seen twice, not two relations, and rendering it twice produced the
    duplicate seat row audited at T=264 (ffs0#174).

    Deliberately NOT keyed on (src, tgt): two relations with distinct URNs asserting the
    same occupancy is a §M19 violation, and collapsing it here would erase the only signal
    of it. That case is detected separately by duplicate_occupancy() and never collapsed.

    Older folds may carry relations without a URN; those fall back to the full identity
    tuple, which makes the same "one relation" claim structurally.

    Returns (unique_rels, collapsed_count) — order-stable (first arrival wins)."""
    seen, out, collapsed = set(), [], 0
    for r in rels:
        key = r.get("urn") or (r.get("rewrite_category"), r.get("src_urn"), r.get("src_port"), r.get("tgt_urn"), r.get("tgt_port"))
        if key in seen:
            collapsed += 1
            continue
        seen.add(key)
        out.append(r)
    return out, collapsed

def duplicate_occupancy(rels):
    """§M19: a workspace has at most one occupant. AFTER the fan-in collapse, MORE THAN ONE
    surviving has-occupant relation out of a workspace is a violation of the fold, not a
    read artifact.

    Grouped by workspace alone — deliberately NOT by (workspace, agent). Keying on the pair
    only catches one occupancy asserted twice and is blind to the canonical violation, a
    workspace held by two DIFFERENT agents: that yields two pair-keys of length one each and
    reads clean. Grouping by src_urn is strictly wider and keeps both cases (caught by
    @Zappa reviewing ffs0#175 — the pair key contradicted this function's own first line).
    Matches the invariant as stated in the Cowork readback procedure: one has-occupant out
    of the workspace, "if >1 → §M19 violation", whatever the target.

    Surfacing this is the point of keeping it out of collapse_fanin(): a projection script
    must not smooth over a graph-level violation, and the kernel — not this script — is
    where the invariant belongs.

    Returns [(workspace_urn, [(agent_urn, relation_urn), ...]), ...]."""
    by_ws = {}
    for r in rels:
        if r.get("src_port") != "has-occupant":
            continue
        by_ws.setdefault(r.get("src_urn"), []).append((r.get("tgt_urn"), r.get("urn") or "<no-urn>"))
    return sorted((ws, sorted(occ)) for ws, occ in by_ws.items() if len(occ) > 1)

def self_test():
    """Offline gate for the fan-in collapse and the §M19 detector (T=264, ffs0#174). No
    engine required, stdlib only — runnable on a cloud runner alongside the fence check.
    The distinction it guards is the whole point of the change: same relation URN twice =
    read artifact (collapse); same (src, tgt) with different URNs = §M19 (never collapse)."""
    ho = "has-occupant"
    def rel(urn, src, tgt, port=ho):
        return {"urn": urn, "src_urn": src, "src_port": port, "tgt_port": "is-occupant-of", "tgt_urn": tgt}
    ws, ag = "urn:moos:session:w", "urn:moos:agent:a"
    fails = []
    def check(name, got, want):
        if got != want:
            fails.append("%s: got %r want %r" % (name, got, want))

    # 1. the ffs0#174 case — one relation reached over two fan-in paths collapses to one row
    dup_path = [rel("urn:moos:rel:r1", ws, ag), rel("urn:moos:rel:r1", ws, ag)]
    kept, collapsed = collapse_fanin(dup_path)
    check("fan-in collapse count", collapsed, 1)
    check("fan-in collapse kept", len(kept), 1)
    check("fan-in collapse is not §M19", duplicate_occupancy(kept), [])

    # 2. the case that must SURVIVE — two distinct relations asserting one occupancy
    m19 = [rel("urn:moos:rel:r1", ws, ag), rel("urn:moos:rel:r2", ws, ag)]
    kept, collapsed = collapse_fanin(m19)
    check("§M19 not collapsed", collapsed, 0)
    check("§M19 both kept", len(kept), 2)
    check("§M19 detected", duplicate_occupancy(kept),
          [(ws, [(ag, "urn:moos:rel:r1"), (ag, "urn:moos:rel:r2")])])

    # 3. distinct seats are never conflated, and a clean fold reports clean
    clean = [rel("urn:moos:rel:r1", ws, ag), rel("urn:moos:rel:r2", "urn:moos:session:w2", "urn:moos:agent:b")]
    kept, collapsed = collapse_fanin(clean)
    check("clean fold collapse", collapsed, 0)
    check("clean fold kept", len(kept), 2)
    check("clean fold no §M19", duplicate_occupancy(kept), [])

    # 4. non-occupancy ports collapse too, but never register as §M19
    pins = [rel("urn:moos:rel:p1", ws, "urn:moos:group:sam", "pins-urn")] * 2
    kept, collapsed = collapse_fanin(pins)
    check("non-occupancy collapse", (collapsed, len(kept)), (1, 1))
    check("non-occupancy not §M19", duplicate_occupancy(kept), [])

    # 5. URN-less relations (older folds) fall back to the identity tuple
    legacy = [{"src_urn": ws, "src_port": ho, "tgt_port": "is-occupant-of", "tgt_urn": ag}] * 2
    kept, collapsed = collapse_fanin(legacy)
    check("urn-less collapse", (collapsed, len(kept)), (1, 1))

    # 6. order stability — first arrival wins, so the render stays deterministic
    ordered = [rel("urn:moos:rel:r%d" % i, "urn:moos:session:w%d" % i, ag) for i in (1, 2, 3)]
    kept, _ = collapse_fanin(ordered + ordered)
    check("order stable", [r["urn"] for r in kept], ["urn:moos:rel:r1", "urn:moos:rel:r2", "urn:moos:rel:r3"])

    # 7. the CANONICAL §M19 — one workspace, two DIFFERENT occupants. This is the case a
    #    (workspace, agent) key cannot see: two pair-keys of length one each, reported
    #    clean. It fails against a pair-keyed detector, which is why it is here.
    two_agents = [rel("urn:moos:rel:r1", ws, ag), rel("urn:moos:rel:r2", ws, "urn:moos:agent:b")]
    kept, collapsed = collapse_fanin(two_agents)
    check("two occupants not collapsed", collapsed, 0)
    check("two occupants detected", len(duplicate_occupancy(kept)), 1)
    check("two occupants named", duplicate_occupancy(kept),
          [(ws, [("urn:moos:agent:a", "urn:moos:rel:r1"), ("urn:moos:agent:b", "urn:moos:rel:r2")])])

    # 8. agent-card identity matcher (ffs0#165) — the block must extend to the terminating
    #    blank line so an INDENTED continuation line stays inside it. Matching `^-` only
    #    stopped at john-lydon's `  *(T247 ...)*` note and left the tail as a duplicate.
    card_txt = ("# Seat: X\n\nintro prose.\n\n"
                "- **Agent (principal):** `a`\n"
                "  *(indented continuation note that does not start with a dash)*\n"
                "- **Workspace (session):** `w`\n\n"
                "trailing prose stays.\n")
    reg = find_card_authored_identity(card_txt)
    captured = card_txt[reg[0]:reg[1]] if reg else ""
    check("card matcher captures indented continuation", "indented continuation note" in captured, True)
    check("card matcher stops at the blank line", "trailing prose" in captured, False)
    check("card matcher spans both bullets", captured.count("- **"), 2)

    if fails:
        print("SELF-TEST: FAIL (%d)" % len(fails))
        for f in fails: print("  !", f)
        return 1
    print("SELF-TEST: PASS — 8 cases (fan-in collapse, §M19 same-pair survival + detection, "
          "clean fold, non-occupancy ports, urn-less fallback, order stability, "
          "canonical §M19 two-occupant detection, agent-card identity matcher)")
    return 0

def fold_from_hg(base_url, fallback_url, topo, disp):
    """One row per WF19 has-occupant edge (spec section 3). Returns (rows, source_url,
    primary_err, fold_notes) — primary_err is None when the router fan-in served the read,
    else the exception that forced the fallback (a fallback fold sees only the local engine,
    so cross-kernel seats are missing — never adjudicate a shrink from it). fold_notes
    carries the fan-in collapse count and any §M19 duplicate-occupancy findings."""
    primary_err = None
    try:
        nodes, rels = read_state(base_url); src = base_url
    except Exception as e:
        primary_err = e
        nodes, rels = read_state(fallback_url); src = fallback_url
    rels, collapsed = collapse_fanin(rels)
    fold_notes = {"fanin_collapsed": collapsed, "duplicate_occupancy": duplicate_occupancy(rels)}
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
    return rows, src, primary_err, fold_notes

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

def region_seat_ids(region_txt):
    """Return a set of (agent, workspace) identity tuples from a fenced region.
    An agent can legitimately occupy multiple rows (multiple workspaces), so
    comparing only agent names misses dropped rows for multi-seat agents."""
    ids = set()
    for line in region_txt.splitlines():
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) >= 3 and cells[1].startswith("`") and not cells[0].lower().startswith("persona"):
            ids.add((cells[1].strip("`"), cells[2].strip("`")))
    return ids

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

# ---------- agent-card projection (ffs0#165, harness-diet leg 6) ----------
# The seven .claude/agents/*.md cards hand-duplicate seat facts (identity URNs, engine,
# emit, skills, surface) that already live in config + the fold — a third hand-maintained
# copy of seat truth (the first two: AGENTS.md seat table, seat-context.md). This fences
# the DRIFTING identity block in each card and regenerates it from source; the persona
# voice (Start here / GATE / the rule) stays hand-authored OUTSIDE the fence.
#
# Source of the fenced facts is CONFIG (affordance skills + topology engine/emit/mcp +
# seat-display persona/surface), not the fold — so the card check runs OFFLINE (all inputs
# are in-repo) and does not break when a peer kernel (e.g. hp-laptop) is down. When a kernel
# IS reachable the fold is used only as a cross-check: warn if a carded seat has no
# has-occupant relation. HG stays authority; this is an F-projection of it plus config.
CARD_FENCE_BEGIN = "<!-- BEGIN GENERATED: moos-config-projection agent-card v1 (source: session-affordance-map skills + moos-federation.topology engine/emit/mcp + seat-display persona/surface; HG has-occupant cross-checked when a kernel is reachable; do not hand-edit — regenerate with --scope cards --mode write) -->"
CARD_FENCE_END   = "<!-- END GENERATED: moos-config-projection agent-card -->"
CARD_FENCE_BEGIN_STABLE = "<!-- BEGIN GENERATED: moos-config-projection agent-card"

def skills_for(affordance, actor_urn, session_urn):
    """Skills for the (actor, session) seat from the affordance map. Match on the pair —
    an actor can occupy multiple sessions with different skill mounts (John Lydon)."""
    for s in affordance.get("sessions", []):
        if s.get("actor_urn") == actor_urn and s.get("session_urn") == session_urn:
            return list(s.get("skills", []))
    return None   # None = no affordance entry (distinct from an empty skills list)

def card_facts(card, topo, disp, affordance):
    """Facts for one card, purely from config. `card` = {file, actor_urn, session_urn,
    persona_key?}. persona_key disambiguates the topology lookup: one actor can back two
    persona blocks (claude-cowork.hp-laptop is both `john-lydon` and `cowork-laptop`), and an
    actor-only key would silently take whichever is last in file order — the wrong seat's
    engine/emit/mcp. With persona_key set we read the exact block; without it we fall back to
    the FIRST actor match (deterministic, but register persona_key when an actor is shared)."""
    actor, session = card["actor_urn"], card["session_urn"]
    personas = topo.get("personas", {})
    pk = card.get("persona_key")
    if pk:
        pa = dict(personas.get(pk, {}), key=pk)
    else:
        pa = next((dict(b, key=name) for name, b in personas.items()
                   if b.get("actor_urn") == actor), {})
    kernels = topo.get("kernels", {})
    sd = disp.get("seats", {}).get(actor, {})

    def kport(kalias):
        k = kernels.get(kalias, {})
        m = re.search(r":(\d+)$", k.get("http_local", "") or k.get("http_lan", "") or k.get("http_tailscale", ""))
        return (":" + m.group(1)) if m else ""

    engine = pa.get("opens_on_kernel", "")           # topology intent (D6)
    emit   = pa.get("emit_kernel", "")               # actual receiving kernel (§M9 split)
    mcp = pa.get("mcp_server", "")
    if pa.get("topology_mcp_server"):
        mcp += " *(opens-on `%s`)*" % pa["topology_mcp_server"]
    return {
        "file":      card["file"],
        "agent":     actor,
        "workspace": session,
        "persona":   sd.get("persona") or pa.get("key", ""),
        "surface":   sd.get("surface", "—"),
        "engine":    engine,
        "engine_port": kport(engine),
        "emit":      emit,
        "emit_port": kport(emit),
        "mcp":       mcp or "—",
        "skills":    skills_for(affordance, actor, session),
    }

def render_card_block(f):
    """The fenced identity block. Deterministic; no timestamps (matches the seat-table rule)."""
    eng = ("`%s` — HTTP %s" % (f["engine"], f["engine_port"])) if f["engine"] else "—"
    if f["emit"] and f["emit"] != f["engine"]:
        emit_line = "- **Emit target:** `%s` %s — this seat opens-on `%s` but emits here until §M9 twin-sync" % (
            f["emit"], f["emit_port"], f["engine"])
    else:
        emit_line = "- **Emit target:** `%s` %s (until §M9 twin-sync)" % (f["emit"] or f["engine"], f["emit_port"] or f["engine_port"])
    if f["skills"] is None:
        skills_line = "- **Skills:** _(no affordance-map entry for this seat)_"
    elif not f["skills"]:
        skills_line = "- **Skills:** _(none mounted)_"
    else:
        skills_line = "- **Skills:** " + " · ".join("`%s`" % s for s in f["skills"])
    lines = [
        CARD_FENCE_BEGIN,
        "- **Agent (principal):** `%s`" % f["agent"],
        "- **Workspace (session):** `%s`" % f["workspace"],
        "- **Engine (kernel):** %s" % eng,
        emit_line,
        "- **Surface:** %s" % f["surface"],
        "- **Persona:** %s" % (f["persona"] or "—"),
        skills_line,
        "- **MCP:** %s" % f["mcp"],
        CARD_FENCE_END,
    ]
    return "\n".join(lines)

def find_card_region(txt):
    b = txt.find(CARD_FENCE_BEGIN_STABLE)
    if b < 0: return None
    e = txt.find(CARD_FENCE_END, b)
    if e < 0: return None
    return (b, e + len(CARD_FENCE_END))

def find_card_authored_identity(txt):
    """First-adoption target: the hand-authored identity list after the first `# Seat:`
    header — from the first `- **` bullet to the blank line that terminates the block.
    Extending to the blank line (rather than matching only `^-` lines) keeps INDENTED
    continuation lines inside the block, e.g. john-lydon's `  *(T247 seat split ...)*`
    note; matching `^-` only would stop at that line and leave the rest as a duplicate.
    Header + surrounding prose stay untouched."""
    h = re.search(r"^# Seat:[^\n]*$", txt, re.M)
    if not h: return None
    seg = txt[h.end():]
    m = re.search(r"^- \*\*", seg, re.M)                 # first identity bullet
    if not m: return None
    start = m.start()
    bm = re.search(r"\n[ \t]*\n", seg[start:])           # first blank line ends the block
    end = start + (bm.start() + 1 if bm else len(seg[start:]))   # include last content newline
    return (h.end() + start, h.end() + end)

def run_cards(a, topo, disp):
    """check / render / write the fenced identity block across the configured cards."""
    affordance = json.load(open(a.affordance, encoding="utf-8")) if os.path.exists(a.affordance) else {"sessions": []}
    cards = disp.get("cards", [])
    if not cards:
        print("CARDS: no `cards` list in seat-display.json — nothing to project."); return 0

    # Optional HG cross-check: warn if a carded seat has no has-occupant relation.
    # --offline-ok skips the attempt entirely (Copilot on #176): without it, an offline
    # runner pays up to 2 x 20s of connect timeouts just to learn what the flag states.
    seated = None
    if a.offline_ok:
        print("CARDS: --offline-ok — config-only projection, HG cross-check skipped")
    else:
        try:
            rows, src, _perr = fold_from_hg(a.base_url, a.fallback_url, topo, disp)[:3]
            seated = {(r["agent"], r["workspace"]) for r in rows}
            print("CARDS: HG cross-check via %s (%d seated rows)" % (src, len(rows)))
        except Exception as e:
            print("CARDS: HG unreachable (%s) — config-only projection, cross-check skipped" % type(e).__name__)

    cards_dir = os.path.join(REPO, ".claude", "agents")
    drift, wrote, missing_seat = [], [], []
    for c in cards:
        facts = card_facts(c, topo, disp, affordance)
        if seated is not None and (alias(facts["agent"]), alias(facts["workspace"])) not in seated:
            missing_seat.append("%s (%s / %s)" % (c["file"], alias(facts["agent"]), alias(facts["workspace"])))
        block = render_card_block(facts)
        path = os.path.join(cards_dir, c["file"])
        if not os.path.exists(path):
            print("  ! CARD MISSING: %s" % c["file"]); drift.append(c["file"] + " (file absent)"); continue
        txt = open(path, encoding="utf-8").read()
        region = find_card_region(txt)

        if a.mode == "render":
            print("\n# %s\n%s" % (c["file"], block)); continue
        if a.mode == "write":
            if region:
                new = txt[:region[0]] + block + txt[region[1]:]
            else:
                ident = find_card_authored_identity(txt)
                if not ident:
                    print("  ! %s: no fenced region and no identity bullet block after '# Seat:' — skipped" % c["file"])
                    drift.append(c["file"] + " (no insertion point)"); continue
                new = txt[:ident[0]] + block + "\n" + txt[ident[1]:]
            if new != txt:
                open(path, "w", encoding="utf-8", newline="").write(new); wrote.append(c["file"])
        else:  # check
            if not region:
                drift.append(c["file"] + " (no fenced region — run --scope cards --mode write)")
            elif txt[region[0]:region[1]] != block:
                drift.append(c["file"] + " (fenced block diverges from source)")

    # Coverage: .claude/agents/ is seat-card-only, so every *.md there must be a configured
    # card. An unregistered file would carry an unfenced, hand-authored identity block that
    # the gate never checks — the exact single-source hole this projection exists to close.
    if os.path.isdir(cards_dir):
        configured = {c["file"] for c in cards}
        unregistered = sorted(f for f in os.listdir(cards_dir) if f.endswith(".md") and f not in configured)
        for u in unregistered:
            drift.append(u + " (on disk but not in seat-display cards[] — register it or remove it)")

    for m in missing_seat:
        print("  ~ WARN carded seat has no has-occupant in the fold: %s" % m)
    if a.mode == "write":
        print("CARDS: wrote %d card(s): %s" % (len(wrote), ", ".join(wrote) or "none (already current)"))
        return 0
    if a.mode == "render":
        return 0
    if drift:
        for d in drift: print("  ! CARD DRIFT", d)
        print("\nCARD CHECK: FAIL (%d) — resolution is --scope cards --mode write (never hand-edit the fenced block)." % len(drift))
        return 1
    print("CARD CHECK: PASS — every card's fenced identity block is byte-identical to source (%d cards)." % len(cards))
    return 0

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
    ap.add_argument("--scope", choices=["seats", "cards"], default="seats",
                    help="seats = AGENTS.md seat table (default, unchanged); cards = .claude/agents/*.md identity blocks (ffs0#165). CI runs both as separate steps.")
    ap.add_argument("--affordance", default=os.path.join(REPO, "dev", "config", "session-affordance-map.json"),
                    help="skills source for --scope cards")
    ap.add_argument("--allow-shrink", action="store_true",
                    help="permit --mode write to drop seats present in the previous generated region")
    ap.add_argument("--offline-ok", action="store_true",
                    help="check mode: if no engine/router is reachable, verify fence integrity only (CI)")
    ap.add_argument("--out", default=os.path.join(REPO, "tmp", "projections", "session_pipeline", "config"))
    ap.add_argument("--self-test", action="store_true",
                    help="run the offline fan-in/§M19 gate and exit (no engine required)")
    a = ap.parse_args()

    if a.self_test:
        return self_test()

    topo = json.load(open(a.topology, encoding="utf-8"))
    disp = json.load(open(a.display, encoding="utf-8")) if os.path.exists(a.display) else {}

    if a.scope == "cards":
        return run_cards(a, topo, disp)

    txt = open(a.agents, encoding="utf-8").read()
    span = find_region(txt)

    try:
        hg_rows, src, primary_err, fold_notes = fold_from_hg(a.base_url, a.fallback_url, topo, disp)
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

    json.dump(fold_notes, open(os.path.join(a.out, "seat-table.fold-notes.json"), "w", encoding="utf-8"), indent=1)
    if fold_notes["fanin_collapsed"]:
        print("fan-in: collapsed %d duplicate relation(s) reached over more than one path "
              "(same relation URN — one relation, not two)." % fold_notes["fanin_collapsed"])
    dup_occ = fold_notes["duplicate_occupancy"]
    if dup_occ:
        print("!! §M19 DUPLICATE OCCUPANCY — %d workspace(s) carry more than one has-occupant "
              "relation. These are NOT collapsed: distinct relation URNs mean distinct "
              "relations, and the fold — not this projection — is where that is wrong." % len(dup_occ))
        for ws_urn, occ in dup_occ:
            agents = sorted(set(ag_urn for ag_urn, _ in occ))       # NB: never bind `a` here — it is the argparse namespace
            print("   %s — %d occupant relation(s)%s" % (
                alias(ws_urn), len(occ),
                (", %d DISTINCT agents" % len(agents)) if len(agents) > 1 else " (same agent, asserted twice)"))
            for ag_urn, rel_urn in occ:
                print("     %-46s %s" % (alias(ag_urn), rel_urn))
        print("   resolution is an UNLINK of the redundant relation on the owning engine, "
              "NOT --mode write (regenerating renders the duplicate faithfully).")
        if a.mode == "check":
            print("\nDRIFT CHECK: NOT RUN — §M19 violation takes precedence over table drift.")
            return EXIT_M19

    if a.mode == "render":
        print(region); return 0

    if a.mode == "write":
        if span:
            old_region = txt[span[0]:span[1]]
            dropped = region_seat_ids(old_region) - {(r["agent"], r["workspace"]) for r in hg_rows}
            if dropped and not a.allow_shrink:
                print("WRITE REFUSED: fold would drop previously-generated seat(s): %s" % ", ".join(sorted("%s/%s" % t for t in dropped)))
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
            dropped = region_seat_ids(committed) - {(r["agent"], r["workspace"]) for r in hg_rows}
            if dropped:
                print("DRIFT CHECK: ERROR — partial fan-in: FALLBACK fold (%s) is missing previously-generated seat(s): %s"
                      % (src, ", ".join(sorted("%s/%s" % t for t in dropped))))
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
