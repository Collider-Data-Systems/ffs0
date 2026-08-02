# DECISION — engine rewrite language (T=274, amended same round)

> **Amendment history:** rev 1 recorded "C++ (C++20) throughout" as the direction. Sam's
> mid-round ruling (t274) superseded it before merge; rev 2 (this text) records the actual
> decision. Rationale + measurements: `20260802-t274-engine-language-choice.md` (incl. its
> t274 addendum). Nothing in rev 1's evidence was overturned — only its ruling.

## 1. Ruling

**The engine-language question is DEFERRED, and dissolved into a better-posed one.** No
language is chosen for a runtime port this round. The Go `moos-kernel` stays where it is —
**reference oracle behind the replay-equivalence gate** (§3, now merged) and the running
engine, with no retirement plan attached. The object of study for the rewrite lane is the
**dialect topology**: workspaces connect to purpose; a purpose slices the HG's wiring to its
operations; per-concern dialects (compute, transport, maths, …) lower to code catered per
target. Languages are **targets, plural**, selected per lowering by the conversion pipeline —
not an identity the engine commits to. Design work continues in the t274 note's addendum and
its successor notes under `purpose:sam.compiler-lowering`.

Rulings that stand from rev 1 (evidence unaffected by the reframe):

- **C / Dependable C: rejected for a full runtime.** The zero-dep driver inverts (OpenSSL +
  HTTP/2 stack + ngtcp2/nghttp3 + JSON + hashmap vs today's stdlib+quic-go); ~40 hand-written
  serializer pairs for 181 tagged fields; no structural invariants. Reserved candidate for
  **`libmoosfold`** — fold + GraphState + operad validation as a zero-dependency C-ABI
  library (~926 Go src LOC today) — requiring an explicit scope call by Sam, not licensed here.
- **Zig, Mojo: out** (one line and zero lines of prior art respectively; no stable
  HTTP/2/TLS story for Zig).
- **MLIR is not an engine dependency.** Spike B's conclusion of record: the operad verifier is
  a table-driven checker in any language (the Go `operad.Registry` already is one); MLIR's
  value is pass/lowering machinery over a committed `moos IR`, as offline tooling. Confirmed
  independently from the MLIR side: IRDL's declarative constraints cannot express the
  port-pair matrix, and its `irdl.c_pred` escape hatch forfeits runtime loading — so
  per-purpose dialects generated from the HG stay in xDSL/dynamic-host territory.

## 2. Anti-goals (unchanged in substance; what this decision does NOT license)

- **No LLVM/MLIR in the engine's build graph.** MLIR work stays in xDSL/offline-tool space
  until `moos IR` has a committed textual format (T244 open question #1).
- **No port of transport, MCP, sweep, or router ahead of the fold core** (T244 ordering, kept
  for whenever a port lane opens).
- **No new dependencies in `moos-kernel`** while it is the oracle — "stdlib + quic-go only"
  stands (defended T=260, T=263).
- **No ontology edit, no HG rewrite** in this lane without a reviewed apply. The dialect-
  topology grammar work (purpose → operations-slice + scope-slice join) is future fragments,
  Sam-gated.
- **Go hygiene fixes are licensed on their own merits** (batch `EncodeNodes` in
  `spectral.go`, persistent encoder on `Runtime`, CoW state per the existing
  `TODO(perf)`) — they are oracle maintenance, not a port.

## 3. Acceptance gate — MERGED (moos-kernel#66)

Committed JSONL log fixture + canonical serialization of the folded state (`Nodes` +
`Relations` only; derived indexes are `json:"-"`, rebuilt by `Rebuild()`,
`graph/state.go:69`) + stable SHA-256. Any candidate engine, in any language, reproduces the
hash from the same JSONL or is not an engine. Reference path: `fold.Replay`
(`fold/replay.go:29`).

Current gate hash (rev 2 — fixture envelopes on declared 4.0.4 port pairs after the lane-A
dead-grammar finding; reproduced cross-OS/cross-Go by lane A):

```
d8283f2777648bb38eeaecbcb7023b10dfee90784529aeb70d1788bd65098dc1
```

The rev-1 hash `6bb67afc…` is void — its fixture encoded undeclared grammar (WF19
`occupies`, WF12 `kb-provided-by` + out-of-`tgt_types` target, WF15 non-literal pair).
`testdata/replay/* -text` in `.gitattributes` protects the golden bytes on autocrlf clones.

## 4. Re-open triggers → resolution

Rev 1's triggers are resolved by the ruling itself:

1. *Spike A deflates the perf motive* — **CONFIRMED and absorbed**: the dominant costs are
   algorithmic and Go-fixable (~4× time / ~50× allocation on the write path's dominant term
   via the existing batch path alone). This is now §2's licensed hygiene work.
2. *Spike B narrows the MLIR premise* — **CONFIRMED and absorbed**: table-driven checker in
   the engine; MLIR as offline tooling; dialects generated from the live HG, never frozen at
   build time (the t244 sketch verbatim is already rejected by operad 4.0.4).
3. *The stdlib-only values call* — **MOOT for now**: no replacement runtime is being built,
   so no replacement dependency list needs ruling. Reopens with any future port lane.

This DECISION reopens only on an explicit scope call by Sam (e.g. `libmoosfold`, or a
concrete lowering target that needs a non-Go engine surface).

---
authored-by: agent:claude-code.remote / session:none-ungoverned-remote-s0 / t274-engine-language-choice
