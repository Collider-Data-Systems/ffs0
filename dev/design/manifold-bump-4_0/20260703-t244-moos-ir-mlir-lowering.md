# T244 moos IR / MLIR lowering lane

> **Status: design draft (S0 -> pending G-ingest). GATE: prose/tooling only.** No ontology edit, no HG rewrite, no runtime branch, no URN change. Authored from the Karpathy seat after the T244 IDE/tooling readback.

## One Sentence

`moos IR` is the explicit rewrite-program representation between the semantic operad and any runtime/code surface; MLIR is a candidate host for verifier and lowering experiments, while the current Go engine remains the reference oracle.

## Boundary

The durable object is:

```text
rewrite log + ontology operad -> fold -> derived HG state
```

Every implementation is a projection surface:

```text
Go runtime, Rust runtime, C++ runtime, MLIR module, LLVM IR, machine code, repo branch, IDE view
```

So the rewrite lane should not say "the Rust engine is mo:os" or "the LLVM IR is truth." The precise wording is: **the engine code is an F-projection of the mo:os operad and fold semantics onto a target runtime surface.** Traces, benchmark results, and debugger observations lift back through G as evidence.

## IR Vocabulary

| mo:os concept | Compiler reading | Notes |
| --- | --- | --- |
| ADD / LINK / MUTATE / UNLINK | instruction/opcode family | The four primitive rewrites. |
| WF01..WF21 | op family / effect category | A rewrite_category governs admissibility, not topology itself. |
| node URN | symbol identity | Stable semantic identity; never replaced by an address. |
| relation URN | topology fact identity | Created by LINK, removed by UNLINK. |
| port pair | operand role pair | `src_port` and `tgt_port` are typed interface roles. |
| property | attribute / single-node state | Use only for internal state, not topology. |
| operad registry | type system + verifier spec | Node types, properties, WF categories, additional port pairs. |
| fold | reference interpreter | Pure state transition over one envelope. |
| ApplyProgram | transaction/check pipeline | Validate against a working state; persist all-or-nothing. |
| HDC live index | derived analysis/cache | Projection, not authority. |

## Proposed MLIR Shape

High-level dialect sketch:

```mlir
moos.program @example attributes {actor = "urn:moos:agent:vscode.hp-z440.lola", session = "urn:moos:session:sam.karpathy-seat"} {
  moos.add_node @"urn:moos:claim:karpathy.example" : !moos.node<"claim"> {
    text = "...",
    owner_urn = "urn:moos:user:sam"
  }
  moos.link @"urn:moos:rel:example" {
    wf = "WF21",
    src = @"urn:moos:derivation:karpathy.example",
    src_port = "produces",
    tgt = @"urn:moos:claim:karpathy.example",
    tgt_port = "produced-by"
  }
}
```

This should verify before lowering:

- actor/session liveness shape is present (`moos.gate.m11` can remain a runtime pass until folded state is available),
- node type exists in the operad,
- required immutable properties are present,
- WF allows the rewrite type,
- port pair is declared,
- src/tgt type constraints are satisfied,
- authority-sensitive fields are marked for M12 validation,
- WF21 stays acyclic when a folded/working state is available.

## Why MLIR Before LLVM IR

MLIR is the better home for the mo:os language because it lets us define dialect operations, attributes, traits, verifiers, rewrite patterns, and conversion passes. LLVM IR is too low-level for the operad: by the time a rewrite has become pointer arithmetic and stores, the semantic facts we need for WF validation are already erased or encoded as metadata.

Use LLVM IR only as a backend target after:

1. `moos IR` is verified,
2. graph layout is chosen,
3. target capability vector is selected,
4. lowering has preserved replay equivalence,
5. runtime side effects are outside the pure fold boundary.

## Rust / C++ Split

Rust is the best first experiment for the reference rewrite core because ownership and sum types fit envelopes and persistent state. C++ is a later performance/embedding candidate if the target needs tight native integration with LLVM/MLIR or custom allocators.

Near-term Rust spike:

- `Envelope` enum for ADD/LINK/MUTATE/UNLINK.
- `GraphState` using persistent or copy-on-write maps.
- `fold_step(state, envelope) -> Result<State>`.
- replay fixture comparing Go output to Rust output over a small JSONL log.

Do not port transport, MCP, sweep, or router first. Those are runtime surfaces around the fold, not the semantic core.

## Target Capability Vector

Borrow the target-triple idea, but keep it graph-native:

```text
target = workstation kind + engine endpoint + rewrite reach + surface reach + accelerator/features
```

Examples:

- Z440 CPU engine: high rewrite reach, high local storage, moderate GPU/HDC support.
- Android/Keep surface: low rewrite reach, high surface reach for notes/widgets.
- MLIR JIT target: high batch-fold experimentation, low authority reach until gated.

This is the `moos-soom` F/G degree in compiler clothing.

## Open Questions

1. Should `moos IR` be a committed textual format, or only an internal verifier representation generated from JSON envelopes?
2. Is the first MLIR artifact a C++ ODS/TableGen dialect, a Python/xDSL prototype, or a pure design fixture?
3. Does `derivation` need a separate `fg_direction` property before lower/lift claims are queryable without axis-mixing `inference_kind`?
4. What is the smallest replay fixture that proves Go/Rust fold equivalence without importing the full runtime?

## Immediate Tooling Gaps Closed / Open

Closed locally in this T244 IDE pass:

- Rust Analyzer, clangd, MLIR, CodeLLDB, CMake Tools, and TOML VS Code extensions installed.
- `moos-lsp` server/client built and installed locally.
- Karpathy-scoped `moos-mcp` stdio server added to local MCP config.
- Julia `1.12.6`, Clang/LLVM `22.1.8`, CMake `4.3.4`, and Ninja `1.13.2` are available on the user PATH.
- `xDSL` is installed in the repo-local `.venv` as the lightweight MLIR-compatible prototyping fallback.

Still open:

- Native MLIR command-line tools (`mlir-opt`, `mlir-translate`) are not present in the Windows LLVM installer; use xDSL for early dialect experiments or install/build MLIR separately when native MLIR pass testing is required.
- Karpathy workspace topology has no durable `has-purpose` relation and no scope roots; the generated MVP gate correctly fails for live-session topology until a reviewed HG apply repairs that.
- `moos-lsp` VSIX should eventually be bundled/excluded more aggressively; current local package is fine for workstation use.
