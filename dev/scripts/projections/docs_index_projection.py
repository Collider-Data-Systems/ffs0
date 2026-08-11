#!/usr/bin/env python3
"""moos-docs-index — project dev/config/doc-index.json into a fenced index in dev/README.md.

Sibling of config_projection.py, deliberately NOT a --scope of it: that script loads seat
topology and can exit 5 on an unrelated Z440 desktop mismatch BEFORE its scope dispatch, so a
docs run would abort on a seat problem. Same conventions, separate blast radius.

  python dev/scripts/projections/docs_index_projection.py --self-test
  python dev/scripts/projections/docs_index_projection.py --mode check    # gate
  python dev/scripts/projections/docs_index_projection.py --mode render   # print, write nothing
  python dev/scripts/projections/docs_index_projection.py --mode write    # regenerate the fence

Exit codes (own namespace; config_projection.py's 1-5 all mean HG/topology conditions):
  0 ok
  1 drift            fenced region diverges from the registry -> --mode write
  6 coverage         a markdown file is on disk but not in the registry, or vice versa
  7 registry invalid malformed entry / unknown status / unknown scope

DETERMINISM IS THE CONTRACT: stable total sort, single emitter, and NO timestamps anywhere in
the output. A generated index carrying a clock drifts daily and the gate becomes noise.

STATUS IS TRANSCRIBED, NEVER ASSIGNED. Where a doc declares its own status line, the registry
mirrors it; this projection only renders. Per mtdc-lab/spec/README.md: "If an index row and a
doc disagree, the doc wins and the row is the bug."
"""
import argparse
import json
import os
import re
import sys

REPO = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
REGISTRY = os.path.join(REPO, "dev", "config", "doc-index.json")
INDEX_FILE = os.path.join(REPO, "dev", "README.md")

FENCE_BEGIN = (
    "<!-- BEGIN GENERATED: moos-docs-index v1 (source: dev/config/doc-index.json; "
    "do not hand-edit — regenerate with "
    "python dev/scripts/projections/docs_index_projection.py --mode write) -->"
)
FENCE_END = "<!-- END GENERATED: moos-docs-index -->"
FENCE_BEGIN_STABLE = "<!-- BEGIN GENERATED: moos-docs-index"

EXIT_OK, EXIT_DRIFT, EXIT_COVERAGE, EXIT_REGISTRY = 0, 1, 6, 7

VALID_STATUS = {"live", "archived"}
VALID_SCOPE = {"substrate", "v1", "process"}
SKIP_DIRS = {"node_modules", ".venv", "dist", "target", ".git", "tmp", "scratch", ".agents"}
ROOT_DOCS = ("AGENTS.md", "CLAUDE.md", "ANTIGRAVITY.md", "README.md")


# ---------- corpus ----------
def walk_corpus():
    """Every markdown file the registry must account for. Deterministic order."""
    found = []
    for base in ("dev", "kb"):
        for root, dirs, files in os.walk(os.path.join(REPO, base)):
            dirs[:] = sorted(d for d in dirs if d not in SKIP_DIRS)
            for f in sorted(files):
                if f.endswith(".md"):
                    found.append(os.path.relpath(os.path.join(root, f), REPO).replace(os.sep, "/"))
    for f in ROOT_DOCS:
        if os.path.exists(os.path.join(REPO, f)):
            found.append(f)
    return sorted(set(found))


def load_registry(path=REGISTRY):
    with open(path, encoding="utf-8-sig") as fh:
        return json.load(fh)


def validate_registry(reg):
    """Structural validation. Returns a list of problem strings."""
    problems = []
    docs = reg.get("docs")
    if not isinstance(docs, list):
        return ["registry has no docs[] array"]
    seen = set()
    for i, d in enumerate(docs):
        p = d.get("path")
        if not p:
            problems.append("entry %d has no path" % i)
            continue
        if p in seen:
            problems.append("%s (duplicate entry)" % p)
        seen.add(p)
        if d.get("status") not in VALID_STATUS:
            problems.append("%s (status %r not in %s)" % (p, d.get("status"), sorted(VALID_STATUS)))
        if d.get("scope") not in VALID_SCOPE:
            problems.append("%s (scope %r not in %s)" % (p, d.get("scope"), sorted(VALID_SCOPE)))
        if not d.get("what"):
            problems.append("%s (no one-line 'what')" % p)
        if d.get("pinned") and d.get("status") != "archived":
            problems.append("%s (pinned is only meaningful on an archived doc)" % p)
    return problems


def coverage(reg, corpus):
    """Two-way: unregistered files on disk, and registry paths that no longer exist.

    This is the whole point of the gate — the same shape as config_projection.py's
    card-directory check, with 'index it or archive it' as the remedy.
    """
    registered = {d["path"] for d in reg["docs"] if d.get("path")}
    on_disk = set(corpus)
    unregistered = sorted(on_disk - registered)
    missing = sorted(registered - on_disk)
    return unregistered, missing


# ---------- render ----------
def _row(d):
    flags = []
    if d.get("pinned"):
        flags.append("pinned")
    if d.get("operad_cited"):
        flags.append("operad-cited")
    status = d["status"] + ((" · " + ", ".join(flags)) if flags else "")
    t = ("t%d" % d["t_day"]) if d.get("t_day") is not None else "—"
    what = (d.get("what") or "").replace("|", "\\|")
    return "| `%s` | %s | %s | %s | %s |" % (d["path"], t, d["scope"], status, what)


def render_block(reg):
    docs = sorted(reg["docs"], key=lambda d: d["path"])
    c = reg.get("counts", {})
    cutoff = reg.get("cutoff", {})
    out = [FENCE_BEGIN, ""]
    out.append("**%d documents** — %d live, %d archived (%d of those pinned by an external citer). "
               "Cutoff **t%s**: docs older than it default to archived, overridden by citation, "
               "open governance, and kind."
               % (c.get("total", len(docs)), c.get("live", 0), c.get("archived", 0),
                  c.get("pinned", 0), cutoff.get("t_day", "?")))
    out.append("")
    out.append("`scope` — **substrate** is manifold-generic and travels to any manifold; "
               "**v1** is `my-tiny-data-collider` instance history; **process** is ops and governance.")
    out.append("")
    groups = {}
    for d in docs:
        top = "/".join(d["path"].split("/")[:2]) if "/" in d["path"] else "(repo root)"
        groups.setdefault(top, []).append(d)
    for top in sorted(groups):
        out.append("### %s" % top)
        out.append("")
        out.append("| doc | t-day | scope | status | what |")
        out.append("|---|---|---|---|---|")
        out.extend(_row(d) for d in groups[top])
        out.append("")
    out.append(FENCE_END)
    return "\n".join(out)


def find_region(txt):
    b = txt.find(FENCE_BEGIN_STABLE)
    if b < 0:
        return None
    e = txt.find(FENCE_END, b)
    if e < 0:
        return None
    return (b, e + len(FENCE_END))


# ---------- self-test ----------
def self_test():
    """Offline, no repo state, no network. Dispatched before any file load."""
    fails = []

    def check(name, got, want):
        if got != want:
            fails.append("%s: got %r want %r" % (name, got, want))

    def doc(path, status="live", scope="substrate", **kw):
        d = {"path": path, "status": status, "scope": scope, "what": "x", "t_day": 300}
        d.update(kw)
        return d

    # 1. unregistered file on disk is a coverage failure (the anti-orphan gate)
    reg = {"docs": [doc("dev/a.md")]}
    unreg, missing = coverage(reg, ["dev/a.md", "dev/b.md"])
    check("unregistered file detected", (unreg, missing), (["dev/b.md"], []))

    # 2. registry path that no longer exists is a coverage failure (the other direction)
    unreg, missing = coverage({"docs": [doc("dev/gone.md")]}, [])
    check("missing registered path detected", (unreg, missing), ([], ["dev/gone.md"]))

    # 3. clean tree passes both ways
    check("clean coverage", coverage({"docs": [doc("dev/a.md")]}, ["dev/a.md"]), ([], []))

    # 4-6. registry validation
    check("bad status rejected", len(validate_registry({"docs": [doc("d.md", status="mu")]})), 1)
    check("bad scope rejected", len(validate_registry({"docs": [doc("d.md", scope="zzz")]})), 1)
    check("duplicate path rejected",
          len(validate_registry({"docs": [doc("d.md"), doc("d.md")]})), 1)

    # 7. pinned only means something on an archived doc
    check("pinned-on-live rejected",
          len(validate_registry({"docs": [doc("d.md", status="live", pinned=True)]})), 1)
    check("pinned-on-archived ok",
          validate_registry({"docs": [doc("d.md", status="archived", pinned=True)]}), [])

    # 8. the fence round-trips, and find_region spans both markers inclusively
    block = render_block({"docs": [doc("dev/a.md")], "counts": {}, "cutoff": {}})
    txt = "before\n" + block + "\nafter"
    span = find_region(txt)
    check("region found", span is not None, True)
    check("region is exactly the block", txt[span[0]:span[1]], block)

    # 9. version bump in the BEGIN fence must not orphan a committed region
    old = txt.replace("moos-docs-index v1", "moos-docs-index v0")
    check("stable prefix survives a version bump", find_region(old) is not None, True)

    # 10. determinism — no clock, and identical input gives identical bytes
    check("render is deterministic", render_block({"docs": [doc("dev/a.md")], "counts": {}, "cutoff": {}}), block)
    check("no timestamp leaked into output", bool(re.search(r"20\d\d-\d\d-\d\d", block)), False)

    # 11. a pipe in a title cannot break the table
    check("pipe escaped in what",
          "\\|" in _row(doc("d.md", **{"what": "a | b"})), True)

    if fails:
        print("SELF-TEST: FAIL (%d)" % len(fails))
        for f in fails:
            print("  !", f)
        return 1
    print("SELF-TEST: PASS — 11 cases (coverage both directions, clean tree, status/scope/duplicate/"
          "pinned validation, fence round-trip, version-bump survival, determinism, pipe escaping)")
    return EXIT_OK


def main():
    ap = argparse.ArgumentParser(description="Project the doc registry into dev/README.md.")
    ap.add_argument("--mode", choices=["check", "render", "write"], default="check")
    ap.add_argument("--registry", default=REGISTRY)
    ap.add_argument("--index", default=INDEX_FILE)
    ap.add_argument("--self-test", action="store_true")
    a = ap.parse_args()

    if a.self_test:
        return self_test()

    reg = load_registry(a.registry)

    problems = validate_registry(reg)
    if problems:
        for p in problems:
            print("  ! REGISTRY", p)
        print("\nREGISTRY INVALID (%d) — fix dev/config/doc-index.json." % len(problems))
        return EXIT_REGISTRY

    corpus = walk_corpus()
    # Bootstrap: --mode write creates the index target, so a registered-but-absent index file
    # is expected on a fresh tree (or a fresh clone regenerating from scratch), not a coverage
    # failure. Every other path is still checked both ways.
    index_rel = os.path.relpath(a.index, REPO).replace(os.sep, "/")
    if a.mode == "write" and index_rel not in corpus:
        corpus = sorted(corpus + [index_rel])

    unregistered, missing = coverage(reg, corpus)
    if unregistered or missing:
        for u in unregistered:
            print("  ! UNREGISTERED %s (on disk but not in doc-index.json — index it or archive it)" % u)
        for m in missing:
            print("  ! MISSING %s (in doc-index.json but not on disk — remove the row or restore the file)" % m)
        print("\nCOVERAGE: FAIL (%d) — every markdown file is either indexed live or archived."
              % (len(unregistered) + len(missing)))
        return EXIT_COVERAGE

    block = render_block(reg)

    if a.mode == "render":
        print(block)
        return EXIT_OK

    txt = ""
    if os.path.exists(a.index):
        with open(a.index, encoding="utf-8") as fh:
            txt = fh.read()
    span = find_region(txt)

    if a.mode == "write":
        if span:
            new = txt[:span[0]] + block + txt[span[1]:]
        else:
            header = txt if txt else (
                "# dev/ — the index\n\n"
                "> Generated below from `dev/config/doc-index.json`. Never hand-edit the fenced region.\n"
                "> A doc declares its own status; this index transcribes it. **If an index row and a doc\n"
                "> disagree, the doc wins and the row is the bug.** A new doc is registered in the same\n"
                "> PR that creates it.\n\n")
            new = header.rstrip("\n") + "\n\n" + block + "\n"
        if new != txt:
            with open(a.index, "w", encoding="utf-8", newline="\n") as fh:
                fh.write(new)
            print("WROTE %s (%d docs)" % (os.path.relpath(a.index, REPO).replace(os.sep, "/"),
                                          len(reg["docs"])))
        else:
            print("UNCHANGED %s" % os.path.relpath(a.index, REPO).replace(os.sep, "/"))
        return EXIT_OK

    # check
    if not span:
        print("  ! no fenced region in %s — run --mode write"
              % os.path.relpath(a.index, REPO).replace(os.sep, "/"))
        print("\nDOC INDEX: FAIL — resolution is --mode write (never hand-edit the fenced block).")
        return EXIT_DRIFT
    if txt[span[0]:span[1]] != block:
        import difflib
        diff = list(difflib.unified_diff(
            txt[span[0]:span[1]].splitlines(), block.splitlines(),
            "dev/README.md (committed)", "doc-index.json (regenerated)", lineterm="", n=1))
        for line in diff[:60]:
            print(line)
        if len(diff) > 60:
            print("... (%d more diff lines)" % (len(diff) - 60))
        print("\nDOC INDEX: FAIL — fenced region diverges from the registry; "
              "resolution is --mode write (never hand-edit).")
        return EXIT_DRIFT

    c = reg.get("counts", {})
    print("DOC INDEX: PASS — %d docs registered and rendered byte-identical "
          "(%d live, %d archived, %d pinned); coverage clean both ways."
          % (c.get("total", 0), c.get("live", 0), c.get("archived", 0), c.get("pinned", 0)))
    return EXIT_OK


if __name__ == "__main__":
    sys.exit(main())
