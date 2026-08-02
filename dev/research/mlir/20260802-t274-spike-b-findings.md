# Spike B findings — runtime-versioned operad in an MLIR-shaped dialect (T=274)

> **Status: executed, results below. GATE: prose/tooling only.** Companion to
> `dev/design/manifold-bump-4_0/20260802-t274-engine-language-choice.md` and
> `DECISION-engine-language.md` §4. Runner: `t274_spike_b_xdsl_dialect.py` (this folder).
> Environment: Python 3.11.15 · xDSL 0.69.0 · ontology **4.0.4** loaded at runtime from
> `kb/superset/ontology.json` (56 node types, 21 WFs). Linux container, T=274.

## Question

Can a dialect whose verifier is normally generated at build time (ODS/TableGen) carry an
operad that is **runtime data**, loaded at boot and versioned independently of any binary?

## Result: SURVIVES — in a dynamic host. 6/6 fixture cases correct.

The dialect (`moos.program` / `moos.add_node` / `moos.link`) is generated **at process
start** from the loaded ontology; its verifiers close over the operad tables. Nothing about
4.0.4 is frozen into the source file. Verifications exercised against the loaded operad:
V1 node type exists · V2 WF exists + allows LINK · V3 port pair declared (primary +
`additional_port_pairs`) · V4 pair-level src/tgt type sets.

| Case | Expectation | Outcome |
| --- | --- | --- |
| P0 t244 sketch **verbatim** (WF21 `produces/produced-by`) | reject | rejected — pair not declared in 4.0.4 |
| P1 t244 sketch on 4.0.4 pairs (WF21 `causes/caused-by`) | verify | verified |
| P2 WF19 `has-occupant/is-occupant-of` (§M19 pair) | verify | verified |
| N1 undeclared node type (`widget`) | reject | rejected (V1) |
| N2 undeclared port pair on WF21 | reject | rejected (V3) |
| N3 `claim` as `has-occupant` src on WF19 | reject | rejected (V4) |

## The accidental headline: P0

The t244 dialect sketch, written against the 3.16-era operad, uses WF21
`produces/produced-by`. Ontology 4.0.4 declares WF21 as **`causes/caused-by`**. The
runtime-loaded verifier rejects the t244 sketch as written. **This is the build-time-freeze
danger demonstrated empirically by our own two-round-old fixture:** a dialect frozen at t244
build time would today bless IR against a dead operad. Two ontology bumps were enough.

## Interpretation for the language decision

1. **The spike survives because the host is dynamic.** In xDSL/Python the dialect *is data*
   — classes synthesized after loading ontology.json. The equivalent in MLIR-proper C++ is
   NOT the ODS path (build-time by construction). The C++ options are (a) per-ontology-version
   TableGen codegen + rebuild (P0 shows why this rots), or (b) dynamic/IRDL dialects — but
   IRDL's declarative constraint language does not express V3/V4 (a port-pair list with
   per-pair type sets), so those verifiers become hand-registered C++ callbacks over loaded
   tables, i.e. exactly a table-driven checker that happens to live inside MLIR.
2. **Which is the real conclusion: the operad verifier does not need MLIR.** A table-driven
   checker over loaded JSON is what `operad.Registry` in the Go kernel already is. MLIR adds
   value only where its pass/rewrite machinery is used — lowering `moos IR` to execution
   plans, pattern-rewrites over programs — not for admissibility checking.
3. **Consequence for "C++ throughout" (DECISION §1):** the premise narrows but does not
   void. C++'s MLIR proximity is real for a future *offline* moos-IR tool; it is not needed
   *inside* the engine, whose verifier is table-driven in any language. The engine-language
   choice therefore stands or falls on runtime merits + Spike A economics, not on MLIR reach.
4. **t244 open question #1 gets a concrete artifact:** the printed `moos.program` module in
   the runner's output is a working MLIR-shaped textual form of a rewrite program — a
   candidate committed `moos IR` format, generated and verified against the live operad.

## Caveats

- xDSL 0.69.0 is not MLIR-proper; parity with `mlir-opt` semantics is unverified (native
  MLIR tools still absent on the Windows boxes — t244 tooling note stands).
- V4 here resolves URN→type from sibling `add_node` ops only; the real check needs folded
  state (the kernel's working-state validation already does this — `ValidateLINK`).
- §M11/§M12 (liveness/authority) were not modeled; they are stateful gates, out of scope for
  a dialect verifier by design (t244 note already said `moos.gate.m11` stays a runtime pass).

---
authored-by: agent:claude-code.remote / session:none-ungoverned-remote-s0 / t274-engine-language-choice
