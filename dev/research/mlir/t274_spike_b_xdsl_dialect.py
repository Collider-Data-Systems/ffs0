#!/usr/bin/env python3
"""Spike B (T=274 engine-language lane): can an MLIR-shaped dialect carry a
RUNTIME-versioned operad?

The mo:os operad is runtime data — kb/superset/ontology.json, loaded at kernel
boot, versioned independently of any binary (4.0.4 live at T=274). An MLIR
ODS/TableGen dialect is build-time. This spike tests the escape hatch: generate
the dialect (ops + verifiers) AT PROCESS START from the loaded ontology, in
xDSL (the MLIR-compatible Python framework T=244 provisioned because native
mlir-opt is absent from the Windows LLVM installer).

Fixture = the t244 dialect sketch: moos.program carrying moos.add_node +
moos.link (dev/design/manifold-bump-4_0/20260703-t244-moos-ir-mlir-lowering.md).

Verifications exercised against the LOADED operad (not hardcoded):
  V1  node type exists in the ontology            (moos.add_node)
  V2  WF exists and allows the rewrite type       (moos.link)
  V3  port pair is declared for the WF            (primary or additional_port_pairs)
  V4  pair-level src/tgt type constraints hold    (moos.link, needs node-type context)

Negative cases must FAIL verification: an undeclared node type, an undeclared
port pair on a declared WF, and a type-constraint violation.

Result interpretation (either outcome is a result — see findings doc):
  PASS => a runtime-generated dialect is feasible where the dialect machinery
          is itself dynamic (xDSL/Python). The C++ ODS path stays build-time;
          MLIR-proper's runtime option is IRDL/dynamic dialects, whose
          constraint language does not express V3/V4 (checked in findings).
  FAIL => record the exact wall.

Run: python3 t274_spike_b_xdsl_dialect.py [path/to/ontology.json]
"""

import json
import sys
from pathlib import Path

from xdsl.dialects.builtin import ModuleOp, StringAttr
from xdsl.ir import Block, Dialect, Region
from xdsl.irdl import (
    IRDLOperation,
    irdl_op_definition,
    opt_prop_def,
    prop_def,
    region_def,
    traits_def,
)
from xdsl.traits import NoTerminator
from xdsl.utils.exceptions import VerifyException

DEFAULT_ONTOLOGY = Path(__file__).resolve().parents[3] / "kb" / "superset" / "ontology.json"


# --- 1. Load the operad at RUNTIME (this is the point) -----------------------

def load_operad(path: Path) -> dict:
    raw = json.loads(path.read_text(encoding="utf-8"))
    node_types: set[str] = set()
    for section in raw["types"].values():
        for t in section:
            node_types.add(t["id"])
    wfs: dict[str, dict] = {}
    for wf in raw["rewrite_categories"]:
        pairs = []
        if wf.get("src_port") and wf.get("tgt_port"):
            pairs.append({
                "src_port": wf["src_port"],
                "tgt_port": wf["tgt_port"],
                "src_types": set(wf.get("src_types") or []),
                "tgt_types": set(wf.get("tgt_types") or []),
            })
        for p in wf.get("additional_port_pairs") or []:
            pairs.append({
                "src_port": p["src_port"],
                "tgt_port": p["tgt_port"],
                "src_types": set(p.get("src_types") or wf.get("src_types") or []),
                "tgt_types": set(p.get("tgt_types") or wf.get("tgt_types") or []),
            })
        wfs[wf["id"]] = {
            "allowed_rewrites": set(wf.get("allowed_rewrites") or []),
            "pairs": pairs,
        }
    return {"version": raw["version"], "node_types": node_types, "wfs": wfs}


# --- 2. Generate the dialect from the loaded operad --------------------------

def build_dialect(operad: dict):
    """The dialect's verifiers close over the operad tables loaded above.
    Nothing about ontology 4.0.4 is frozen into this file."""

    @irdl_op_definition
    class AddNodeOp(IRDLOperation):
        name = "moos.add_node"
        node_urn = prop_def(StringAttr)
        type_id = prop_def(StringAttr)

        def verify_(self) -> None:
            tid = self.type_id.data
            if tid not in operad["node_types"]:  # V1
                raise VerifyException(
                    f"node type {tid!r} not in operad v{operad['version']}"
                )

    @irdl_op_definition
    class LinkOp(IRDLOperation):
        name = "moos.link"
        relation_urn = prop_def(StringAttr)
        wf = prop_def(StringAttr)
        src = prop_def(StringAttr)
        src_port = prop_def(StringAttr)
        tgt = prop_def(StringAttr)
        tgt_port = prop_def(StringAttr)

        def verify_(self) -> None:
            wf = operad["wfs"].get(self.wf.data)
            if wf is None:  # V2a
                raise VerifyException(f"unknown rewrite_category {self.wf.data!r}")
            if "LINK" not in wf["allowed_rewrites"]:  # V2b
                raise VerifyException(f"{self.wf.data} does not allow LINK")
            sp, tp = self.src_port.data, self.tgt_port.data
            pair = next(
                (p for p in wf["pairs"] if p["src_port"] == sp and p["tgt_port"] == tp),
                None,
            )
            if pair is None:  # V3
                raise VerifyException(
                    f"port pair ({sp!r}, {tp!r}) not declared for {self.wf.data}"
                )
            # V4 needs node-type context: resolve URN -> type via sibling
            # add_node ops in the enclosing program (folded-state lookup in
            # the real kernel; the program region stands in for it here).
            prog = self.parent_op()
            if isinstance(prog, ProgramOp):
                types = {
                    op.node_urn.data: op.type_id.data
                    for op in prog.body.ops
                    if isinstance(op, AddNodeOp)
                }
                for urn, allowed, side in (
                    (self.src.data, pair["src_types"], "src"),
                    (self.tgt.data, pair["tgt_types"], "tgt"),
                ):
                    tid = types.get(urn)
                    if tid is not None and allowed and tid not in allowed:
                        raise VerifyException(
                            f"{side} type {tid!r} not allowed for "
                            f"({sp!r}, {tp!r}) on {self.wf.data}"
                        )

    @irdl_op_definition
    class ProgramOp(IRDLOperation):
        name = "moos.program"
        actor = prop_def(StringAttr)
        session = opt_prop_def(StringAttr)
        body = region_def()
        # A rewrite program is a plain envelope batch — no control flow, so no
        # terminator (MLIR's single-block-region rule requires declaring this).
        traits = traits_def(NoTerminator())

    dialect = Dialect("moos", [ProgramOp, AddNodeOp, LinkOp])
    return dialect, ProgramOp, AddNodeOp, LinkOp


# --- 3. The t244 fixture + negative cases ------------------------------------

def main() -> int:
    path = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_ONTOLOGY
    operad = load_operad(path)
    print(f"operad loaded at runtime: v{operad['version']}, "
          f"{len(operad['node_types'])} node types, {len(operad['wfs'])} WFs")

    _, ProgramOp, AddNodeOp, LinkOp = build_dialect(operad)

    def program(ops):
        return ProgramOp(
            properties={
                "actor": StringAttr("urn:moos:agent:vscode.hp-z440.lola"),
                "session": StringAttr("urn:moos:session:sam.karpathy-seat"),
            },
            regions=[Region([Block(ops)])],
        )

    results: list[tuple[str, bool, str]] = []

    def check(label: str, ops, want_pass: bool):
        prog = program(ops)
        module = ModuleOp([prog])
        try:
            module.verify()
            ok, detail = want_pass, "verified"
        except VerifyException as e:
            ok, detail = (not want_pass), str(e)
        results.append((label, ok, detail))

    # The t244 sketch VERBATIM: WF21 produces/produced-by. Written against the
    # 3.16-era operad; ontology 4.0.4 declares WF21 as causes/caused-by, so the
    # runtime-loaded verifier must now REJECT it. This is the spike's thesis
    # demonstrated by the fixture itself: a dialect frozen at t244 build time
    # would still bless this against a dead operad.
    check("P0 t244 sketch verbatim = stale vs 4.0.4 (expected reject)", [
        AddNodeOp(properties={
            "node_urn": StringAttr("urn:moos:derivation:karpathy.example"),
            "type_id": StringAttr("derivation")}),
        AddNodeOp(properties={
            "node_urn": StringAttr("urn:moos:claim:karpathy.example"),
            "type_id": StringAttr("claim")}),
        LinkOp(properties={
            "relation_urn": StringAttr("urn:moos:rel:example"),
            "wf": StringAttr("WF21"),
            "src": StringAttr("urn:moos:derivation:karpathy.example"),
            "src_port": StringAttr("produces"),
            "tgt": StringAttr("urn:moos:claim:karpathy.example"),
            "tgt_port": StringAttr("produced-by")}),
    ], want_pass=False)

    # The t244 sketch corrected to the 4.0.4 operad: WF21 causes/caused-by.
    check("P1 t244 sketch on 4.0.4 pairs (WF21 causes/caused-by)", [
        AddNodeOp(properties={
            "node_urn": StringAttr("urn:moos:derivation:karpathy.example"),
            "type_id": StringAttr("derivation")}),
        AddNodeOp(properties={
            "node_urn": StringAttr("urn:moos:claim:karpathy.example"),
            "type_id": StringAttr("claim")}),
        LinkOp(properties={
            "relation_urn": StringAttr("urn:moos:rel:example"),
            "wf": StringAttr("WF21"),
            "src": StringAttr("urn:moos:derivation:karpathy.example"),
            "src_port": StringAttr("causes"),
            "tgt": StringAttr("urn:moos:claim:karpathy.example"),
            "tgt_port": StringAttr("caused-by")}),
    ], want_pass=True)

    # positive: WF19 has-occupant (session -> agent), the §M19 pair
    check("P2 WF19 has-occupant pair", [
        AddNodeOp(properties={
            "node_urn": StringAttr("urn:moos:session:fixture.lane"),
            "type_id": StringAttr("session")}),
        AddNodeOp(properties={
            "node_urn": StringAttr("urn:moos:agent:fixture.engine"),
            "type_id": StringAttr("agent")}),
        LinkOp(properties={
            "relation_urn": StringAttr("urn:moos:rel:fixture.occ"),
            "wf": StringAttr("WF19"),
            "src": StringAttr("urn:moos:session:fixture.lane"),
            "src_port": StringAttr("has-occupant"),
            "tgt": StringAttr("urn:moos:agent:fixture.engine"),
            "tgt_port": StringAttr("is-occupant-of")}),
    ], want_pass=True)

    # negative V1: undeclared node type
    check("N1 undeclared node type", [
        AddNodeOp(properties={
            "node_urn": StringAttr("urn:moos:widget:nope"),
            "type_id": StringAttr("widget")}),
    ], want_pass=False)

    # negative V3: undeclared port pair on a real WF
    check("N2 undeclared port pair on WF21", [
        AddNodeOp(properties={
            "node_urn": StringAttr("urn:moos:claim:a"),
            "type_id": StringAttr("claim")}),
        AddNodeOp(properties={
            "node_urn": StringAttr("urn:moos:claim:b"),
            "type_id": StringAttr("claim")}),
        LinkOp(properties={
            "relation_urn": StringAttr("urn:moos:rel:bad"),
            "wf": StringAttr("WF21"),
            "src": StringAttr("urn:moos:claim:a"),
            "src_port": StringAttr("frobnicates"),
            "tgt": StringAttr("urn:moos:claim:b"),
            "tgt_port": StringAttr("frobnicated-by")}),
    ], want_pass=False)

    # negative V4: declared pair, disallowed src type (has-occupant src must be session)
    check("N3 type constraint: claim cannot has-occupant", [
        AddNodeOp(properties={
            "node_urn": StringAttr("urn:moos:claim:a"),
            "type_id": StringAttr("claim")}),
        AddNodeOp(properties={
            "node_urn": StringAttr("urn:moos:agent:x"),
            "type_id": StringAttr("agent")}),
        LinkOp(properties={
            "relation_urn": StringAttr("urn:moos:rel:bad2"),
            "wf": StringAttr("WF19"),
            "src": StringAttr("urn:moos:claim:a"),
            "src_port": StringAttr("has-occupant"),
            "tgt": StringAttr("urn:moos:agent:x"),
            "tgt_port": StringAttr("is-occupant-of")}),
    ], want_pass=False)

    all_ok = True
    for label, ok, detail in results:
        flag = "PASS" if ok else "FAIL"
        all_ok &= ok
        print(f"  [{flag}] {label} — {detail}")

    # Round-trip: the IR prints as MLIR-shaped text (the moos IR surface form).
    demo = program([
        AddNodeOp(properties={
            "node_urn": StringAttr("urn:moos:claim:karpathy.example"),
            "type_id": StringAttr("claim")}),
    ])
    print("\n--- printed moos IR (t244 open question #1: committed textual format?) ---")
    print(ModuleOp([demo]))

    print("\nSPIKE B:", "SURVIVES — runtime-generated dialect verifies the loaded operad"
          if all_ok else "FAILS — see cases above")
    return 0 if all_ok else 1


if __name__ == "__main__":
    sys.exit(main())
