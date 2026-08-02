# DECISION — engine rewrite language (T=274)

Full-runtime replacement lane (Sam's scope call, T=274; supersedes the T244 semantic-core-only
scope as *target*, keeps it as *ordering*). Rationale + measurements: `20260802-t274-engine-language-choice.md`.
The Go `moos-kernel` remains the **reference oracle** until a replacement proves replay
equivalence (Spike C gate below); this document licenses no port ahead of that gate.

## 1. Language decision

**Engine language: C++ (C++20), chosen for LLVM/MLIR proximity, Eigen, and allocator control —
Sam's direction, T=274.** The MLIR premise is explicitly **pending Spike B** (xDSL: can a
dialect generated from `ontology.json` carry a runtime-versioned operad?). If Spike B fails,
this decision's premise clause is void and the language question reopens on runtime merits,
where the T274 note records Rust as the measured leader.

**C / Dependable C: rejected for the runtime.** Three of four drivers score against it
(dependency count *increases* — OpenSSL + HTTP/2 stack + ngtcp2/nghttp3 + JSON + hashmap;
~40 hand-written serializer pairs for 181 tagged fields; no structural invariants). Reserved
as the candidate for **`libmoosfold`** — fold + GraphState + operad validation as a
zero-dependency C-ABI library (~926 Go src LOC today) — a named alternative requiring a scope
reversal by Sam, not licensed here.

**Zig, Mojo: out.** Zig has one line of prior art in the repo (`dev/tools/landscape.md`,
"from-scratch perf experiments") and no stable HTTP/2/TLS story; Mojo has zero prior art here.

## 2. Anti-goals (what this decision does NOT license)

- **No LLVM/MLIR in the engine's build graph.** MLIR work stays in xDSL/offline-tool space
  until Spike B rules and `moos IR` has a committed textual format (T244 open question #1).
- **No port of transport, MCP, sweep, or router ahead of the fold core** (T244 ordering, kept).
- **No new dependencies in `moos-kernel`** while it is the oracle — "stdlib + quic-go only"
  stands (defended T=260, T=263). Spike A is test-files-only.
- **No ontology edit, no HG rewrite, no `moos-kernel` production-source change** in this lane
  until the replay gate exists and a reviewed apply says otherwise.
- **No C++ dependency sprawl at port time.** The port's dependency list is a future DECISION
  edit here, with pins, before the first `CMakeLists.txt` lands — not an accretion.

## 3. Acceptance gate (language-neutral, Spike C)

A committed JSONL log fixture + canonical serialization of the folded state (`Nodes` +
`Relations` only; derived indexes are `json:"-"`, rebuilt by `Rebuild()`,
`graph/state.go:69`) + a stable SHA-256. Any candidate engine reproduces the hash or is not an
engine. Reference path: `fold.Replay` (`fold/replay.go:29`).

## 4. Re-open triggers — status after the same-round spike runs

1. Spike A shows Go hygiene fixes (persistent encoder, CoW state, batch encode) recover most
   of the throughput → the perf driver lapses; scope narrows back to the T244 fold-core spike.
   **Status: TRIGGERED-IN-PART.** Measured: the unused batch path alone is ~4× time / ~50×
   allocation on the dominant cost (full-state HDC encode, run twice per rewrite under the
   write lock — ~7.3 GB/call at 300 nodes on the per-node path). The perf driver for a
   *language* change is substantially deflated; Sam rules on scope.
2. Spike B fails → MLIR leaves the engine decision; language reopens on runtime merits.
   **Status: not triggered, but premise NARROWED.** The runtime-generated dialect survives
   6/6 in xDSL (dynamic host); the C++ ODS path remains build-time and the t244 sketch
   verbatim is already rejected by operad 4.0.4 (WF21 pair renamed). Conclusion of record:
   the operad verifier needs a table-driven checker, not MLIR; MLIR's value is offline
   pass/lowering tooling over a committed `moos IR`. C++'s §1 premise is thereby weakened
   but not void — Sam rules on whether it still carries the decision.
3. The "stdlib + quic-go only" ethos is extended to the replacement → revisit §1, since C++'s
   HTTP/2 + JSON story depends on third-party libraries as much as Rust's does.
   **Status: open — this is a values call only Sam can make.**

Gate artifact (§3) exists as of this round: fixture SHA-256
`6bb67afc79b23155cb79a38a0be74ed5c5685a5f519b5e081a128300a81e6d90`
(`moos-kernel/testdata/replay/`, `internal/fold/replay_fixture_test.go`).

---
authored-by: agent:claude-code.remote / session:none-ungoverned-remote-s0 / t274-engine-language-choice
