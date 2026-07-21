---
name: moos-compiler-lowering
description: mo:os compiler/lowering lane: moos IR, MLIR dialects, LLVM/JIT, Rust/C++ engine rewrite planning, lowering F/G projections to runtime surfaces. Use for compiler-target or IR design work.
---

## When to use (routing detail)

"Use when: designing or implementing the mo:os compiler/rewrite-lowering lane — moos IR, Rust/C++ engine rewrite planning, MLIR dialects, LLVM IR/JIT, target capability vectors, memory-address projections, persistent graph state, operad validators as compiler passes, or lowering F/G projections to runtime/code surfaces. Trigger phrases: moos IR, MLIR dialect, LLVM IR, ORC JIT, Rust rewrite, C++ rewrite, compiler target, lowering pass, persistent graph, copy-on-write GraphState, target triple, memory address, backend target."

# moos-compiler-lowering

Karpathy/Steinberger bridge skill for the compiler lane: turn the mo:os operad and rewrite log into explicit intermediate representations without confusing compiled surfaces for truth.

## Core Frame

- **Truth:** append-only rewrite log + `ontology.json` operad; folded HG state is derived.
- **Reference engine:** the current Go `moos-kernel` remains the oracle until a replacement proves replay equivalence.
- **Compiled runtime:** a surface realization, not truth. Rust/C++/LLVM/MLIR code is an F-projection of the operad onto a target runtime.
- **Memory address:** a target-specific surface coordinate. It may cache or realize a URN, but it never replaces graph identity.
- **Lowering:** F-direction projection from HG/rewrite intent to a code, memory, repo, IDE, or binary surface.
- **Lifting:** G-direction observation from traces, profiles, test results, debug sessions, or compiled artifacts back into HG evidence.

## Use This Skill For

- Drafting a `moos IR` or MLIR dialect.
- Planning a Rust or C++ port of the fold/operad/runtime layers.
- Deciding whether a concern belongs in Go, Rust, C++, MLIR, LLVM IR, or a projection script.
- Translating categorical language into compiler language: operad as instruction set, WF as op family, relation as topology, property as attribute, fold as interpreter.
- Designing target capability vectors: rewrite reach x surface reach.
- Reviewing performance proposals around persistent graph state, copy-on-write indexes, HDC recomputation, or batch validation.

## The Layer Test

Before proposing code, name the layer:

| Layer | Question | Good artifact |
|---|---|---|
| Operad | What rewrites are admissible? | ontology fragment, verifier rule |
| Rewrite IR | What program is being applied? | envelope batch, `moos.program` IR |
| Fold | How does one op transform state? | reference interpreter step |
| Runtime | How are log, locks, store, subscriptions, and transport handled? | engine implementation |
| Lowering | What surface does this project onto? | MLIR pass, Rust/C++ backend, repo commit, dashboard |
| Lifting | What observation returns to HG? | benchmark KI, trace derivation, claim |

If a proposal cannot name its layer, stop and classify it before editing.

## Recommended Naming

- `moos.rewrite` — high-level dialect carrying ADD/LINK/MUTATE/UNLINK.
- `moos.wf` — WF01..WF21 category attribute or op family.
- `moos.urn` — symbol-like identity for nodes and relations.
- `moos.port` — source/target port role.
- `moos.operad.verify` — type/port/property validation pass.
- `moos.gate.m11` / `moos.gate.m12` — liveness and admin capability passes.
- `moos.fold.step` — reference transition from state to state.
- `moos.lower.target` — target capability descriptor, similar in spirit to a target triple plus features.

## Practical Sequence

1. Keep the Go runtime as reference oracle.
2. Specify `moos IR` independent of implementation language.
3. Prototype persistent `GraphState` and batch validation in Rust before porting transport.
4. Draft an MLIR dialect only for verifier/lowering experiments; do not make LLVM IR the source language.
5. Lower to LLVM dialect/IR only after layout, identity, and target capability choices are explicit.
6. Lift benchmark/profile/replay findings back into HG as claims or derivations before changing the doctrine.

## Red Flags

- Treating memory addresses as graph identity.
- Calling a repo, branch, or binary the source of truth.
- Moving time reads into fold/replay.
- Baking WF rules into backend code instead of generating or validating from the operad.
- Collapsing render ticks and rewrite commits into one stream.
- Optimizing `GraphState.Clone()` before replay-equivalence tests exist.

## Validation Surface

For compiler-lane changes, minimum checks are:

- `go test ./...` in `moos-kernel` for the reference runtime.
- Replay equivalence against a known JSONL log.
- `Test-MoosFederation.ps1 -Mode VerifyPersona -Persona karpathy` when emitting from this seat.
- If MLIR is involved: `mlir-opt` parse/verify on sample `.mlir` files once the LLVM toolchain exists.
- If Rust is involved: `cargo test` plus a small replay fixture matching Go fold output.

## Cross-References

- `dev/design/manifold-bump-4_0/20260703-t244-moos-ir-mlir-lowering.md`
- `dev/design/manifold-bump-4_0/20260620-t231-poly-foundations.md`
- `dev/design/manifold-bump-4_0/20260620-t231-moos-soom.md`
- `dev/tools/landscape.md`
- `moos-kernel/internal/fold`, `moos-kernel/internal/operad`, `moos-kernel/internal/kernel`, `moos-kernel/internal/hdc`
