#!/usr/bin/env python3
"""T=167: Close T=164 and open T=187 as hypergraph-native program.

Builds one atomic envelope batch and POSTs it to the kernel:

  - 1 MUTATE: sam.t164-room-tying status -> completed
  - 1 ADD:    sam.t187-kernel-proper program (status=draft)
  - 1 LINK:   t164 --WF18 scheduled-after--> t187 (succession)
  - 10 ADDs:  sub-programs t187.<suffix> (status=draft)
  - 10 LINKs: parent --WF18 composes--> sub-program
  - 5 LINKs:  sub-program --WF18 depends-on--> predecessor

Total: 1 MUTATE + 11 ADDs + 16 LINKs = 28 envelopes.

Rationale: places the T=187 roadmap IN the HG, not in a flat document.
Canonical reference: kb/research/kernel/20260417-t187-kernel-proper.md §M1-M9.
"""
import json
import sys
import urllib.request
import urllib.error

KERNEL_URL = "http://localhost:8000"
ACTOR = "urn:moos:agent:claude-code.hp-laptop"
OWNER = "urn:moos:user:sam"
T167 = "2026-04-17T00:00:00Z"

T164 = "urn:moos:program:sam.t164-room-tying"
T187 = "urn:moos:program:sam.t187-kernel-proper"


def prop(value, mutability="immutable", authority_scope=None, stratum_origin=2):
    p = {"value": value, "mutability": mutability, "stratum_origin": stratum_origin}
    if authority_scope:
        p["authority_scope"] = authority_scope
    return p


def add(node_urn, type_id, properties):
    return {
        "rewrite_type": "ADD",
        "actor": ACTOR,
        "node_urn": node_urn,
        "type_id": type_id,
        "properties": properties,
    }


def link(relation_urn, wf, src, src_port, tgt, tgt_port):
    return {
        "rewrite_type": "LINK",
        "rewrite_category": wf,
        "actor": ACTOR,
        "relation_urn": relation_urn,
        "src_urn": src,
        "src_port": src_port,
        "tgt_urn": tgt,
        "tgt_port": tgt_port,
    }


def mutate(target_urn, field, new_value, wf="WF18"):
    return {
        "rewrite_type": "MUTATE",
        "actor": ACTOR,
        "rewrite_category": wf,
        "target_urn": target_urn,
        "field": field,
        "new_value": new_value,
    }


# ---- sub-program decomposition -----------------------------------------------
# (suffix, title, [depends_on_suffixes])
SUBS = [
    ("session-chrono-t",     "Session.local_t as first-class carrier (M1)",                    []),
    ("t-hooks-first-class",  "Node.t_hooks as explicit port substructure (M6)",                ["session-chrono-t"]),
    ("gates",                "gate type + fail-closed pathway (M8)",                           ["t-hooks-first-class"]),
    ("system-instruction",   "system_instruction S4 type + session.context_urn (M7)",          []),
    ("fold-endpoint",        "Expose fold as HTTP observable (M3)",                            []),
    ("twin-kernel",          "twin_link + adjoint sync protocol (M9)",                         ["gates"]),
    ("strata-enforcement",   "Compile-time strata filtration (M5)",                            []),
    ("answer-walk-Q1-Q4",    "Answer walk Q1..Q4 (first kernel, purpose vector, 2-cell, agent-as-tool)", []),
    ("categorical-contract", "Proof obligations for CI-1..CI-5 + monoid/functor/catamorphism", ["session-chrono-t", "t-hooks-first-class", "gates", "system-instruction", "fold-endpoint", "twin-kernel", "strata-enforcement"]),
    ("twin-deploy-mtdc",     "Deploy twin at my-tiny-data-collider.nl via CF tunnel (M9)",     ["twin-kernel"]),
]


def sub_urn(suffix):
    return f"urn:moos:program:sam.t187.{suffix}"


envelopes = []

# 1. Close T=164
envelopes.append(mutate(T164, "status", "completed"))
envelopes.append(mutate(T164, "completed_t", 167))

# 2. Open T=187 parent program
envelopes.append(add(T187, "program", {
    "title":      prop("T=187: kernel proper — session-as-actor, twin kernels, gates"),
    "owner_urn":  prop(OWNER),
    "status":     prop("draft", mutability="mutable", authority_scope="owner"),
    "scope":      prop(
        "Distributed, decoupled, categorically independent kernel at my-tiny-data-collider.nl. "
        "Session-as-actor doctrine. See kb/research/kernel/20260417-t187-kernel-proper.md for the full spec.",
        mutability="mutable", authority_scope="owner",
    ),
    "starts_t":   prop(187, mutability="mutable", authority_scope="owner"),
    "target_t":   prop(220, mutability="mutable", authority_scope="owner"),
    "created_at": prop(T167),
}))

# 3. Succession: t164 --scheduled-after--> t187
envelopes.append(link(
    "urn:moos:rel:t164.scheduled-after.t187",
    "WF18", T164, "scheduled-after", T187, "scheduled-before",
))

# 4. Sub-programs (10 ADDs)
for suffix, title, _ in SUBS:
    envelopes.append(add(sub_urn(suffix), "program", {
        "title":      prop(title),
        "owner_urn":  prop(OWNER),
        "status":     prop("draft", mutability="mutable", authority_scope="owner"),
        "scope":      prop(
            f"Sub-program of T=187 — see kb/research/kernel/20260417-t187-kernel-proper.md",
            mutability="mutable", authority_scope="owner",
        ),
        "starts_t":   prop(187, mutability="mutable", authority_scope="owner"),
        "created_at": prop(T167),
    }))

# 5. Composition: T=187 --composes--> each sub (10 LINKs)
for suffix, _, _ in SUBS:
    envelopes.append(link(
        f"urn:moos:rel:t187.composes.{suffix}",
        "WF18", T187, "composes", sub_urn(suffix), "composed-by",
    ))

# 6. Dependencies between subs (WF18 depends-on)
for suffix, _, deps in SUBS:
    for dep in deps:
        envelopes.append(link(
            f"urn:moos:rel:t187.{suffix}.depends-on.{dep}",
            "WF18", sub_urn(suffix), "depends-on", sub_urn(dep), "depended-by",
        ))


def main():
    url = f"{KERNEL_URL}/programs"
    body = json.dumps(envelopes).encode("utf-8")
    print(f"POST {url}  ({len(envelopes)} envelopes)", file=sys.stderr)
    req = urllib.request.Request(
        url, data=body, headers={"Content-Type": "application/json"}, method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            print(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        print(f"HTTP {e.code}: {e.read().decode('utf-8', errors='replace')}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    if "--dry-run" in sys.argv:
        print(json.dumps({"envelopes": envelopes}, indent=2))
    else:
        main()
