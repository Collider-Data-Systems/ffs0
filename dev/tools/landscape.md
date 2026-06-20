---
agent: "moos-tooling-dx"
description: "Use when: surveying the concrete technology landscape (fields, platforms, languages, libraries, repos, communities, science) to improve mo:os IDE surfaces and the ffs0 repo — language servers, editor extensions, MCP, LLVM/MLIR, graph-rewriting, event-sourcing, CRDT/local-first."
---

# mo:os Tooling Landscape

Concrete, named technologies to improve the IDE surfaces and the `ffs0` repo. Each entry is
tagged **(IDE)**, **(ffs0)**, or **(both)** and tied to the actual stack: a Go kernel
(`moos-kernel`), a federation router (`moos-router`), Julia/PowerShell projection scripts under
`dev/scripts/`, the JSON ontology at `kb/superset/ontology.json`, MCP servers, and the Tailscale
mesh. Companion to `AGENTS.md` (SOT) and `kb/superset/running-state.md` (live state).

The organizing idea: write **one** server (LSP / MCP) and project it into every editor — the same
F⊣G "one waist, many targets" shape the ontology already encodes.

## Language Server Protocol — give ffs0 its own editor intelligence
LSP turns `ontology.json` + `running-state.md` into a navigable language across VS Code, Neovim,
Zed, Emacs, JetBrains, Theia. **(both)**

- **Spec:** microsoft.github.io/language-server-protocol
- **Build-it libraries:** Go → `tliron/glsp`, `go.lsp.dev/protocol` (fits the kernel; the kernel
  can serve LSP). Rust → `tower-lsp` / `async-lsp`. Python → `pygls`. TypeScript →
  `vscode-languageserver-node`.
- **What a moos-LSP does:** hover a URN → folded node state from `/state`; go-to-def on a relation
  → its ADD log entry; diagnostics = operad / port-color violations live; completion = valid WF
  rewrites in context; semantic tokens for the do/never vocabulary.
- **tree-sitter** (`tree-sitter/tree-sitter`) — incremental parser; a grammar for the envelope/URN
  syntax gives structural highlighting + nav in every modern editor. **(both)**

> Implemented as a first cut in `dev/tools/moos-lsp/` (this repo).

## Editor / extension surfaces
- **VS Code Extension API (IDE):** Webview (render the Graphviz/Cytoscape `index.html` as an HG
  inspector panel), FileSystemProvider (mount HG as a virtual filesystem = the S4 `P_file_tree`
  projection), TreeView (a seats/workspaces explorer), CodeLens + DiagnosticCollection (operad
  violations inline), CustomEditor, Notebook API.
- **Zed** (`zed-industries/zed`, Rust/GPUI) — open-source, GPU-fast, multiplayer-native via CRDT;
  its collab model *is* "humans+agents co-occupy a workspace." Study even if not adopted.
- **Theia** (`eclipse-theia/theia`) — framework to build a bespoke moos IDE, VS Code-extension
  compatible. **Neovim** (built-in LSP + treesitter, Lua). **JetBrains Fleet** (distributed
  multi-backend IDE — architecturally near moos). **monaco-editor** (editor as a web component).

## MCP ecosystem
- **Spec/servers:** modelcontextprotocol.io · `modelcontextprotocol/servers`
- **SDKs:** TS, Python (`FastMCP`), **Go** (`mark3labs/mcp-go`), Rust (`rmcp`), C#, Kotlin.
- **moos-kernel MCP server (ffs0):** expose ADD/LINK/MUTATE/UNLINK as tools, `/state` nodes as
  resources, the 13 skills as prompts. One server → every IDE's agent talks to the kernel
  identically. Implemented in `dev/tools/moos-mcp/` (this repo).
- **`isaacphi/mcp-language-server`** — bridges an LSP into MCP, so an agent gets real
  go-to-def/diagnostics. The LSP × MCP join. **(both)**

## LLVM / compiler tech — the on-point parts
- **MLIR** (mlir.llvm.org) — IR with **user-defined dialects**: define operations/types/regions
  and write verified lowering passes. **MLIR dialect ≈ operad; PDL rewrite patterns ≈ WF rewrite
  categories; lowering ≈ F.** The framework if the rewrite log becomes a real compiler IR. **(ffs0)**
- **egg + egglog** (`egraphs-good/egg`, `egraphs-good/egglog`) — **e-graphs / equality saturation**;
  egglog = Datalog + e-graphs. "Log of rewrites → derived state under an operad" is the textbook
  e-graph use case. Read before extending the kernel. **(ffs0)**
- **WebAssembly + Component Model** (`wasmtime`, `wasmer`, WAMR; **WIT** interface types) — the
  portable "asm subset across processors": Wasm is the cross-ISA waist; WIT typed interfaces = typed
  ports. Ship distributed agent code as wasm components. **(both)**
- **llvm-mca** (instruction-throughput analyzer), **Cranelift** (simpler codegen to study),
  **LLVM ORC JIT** (lazy/distributed compilation).

## The science: graph rewriting + categorical databases
- **AlgebraicJulia** (`AlgebraicJulia/*`) — closest existing implementation of the ontology, in
  Julia (already used by the projection pipeline). **(ffs0)**
  - **`ACSets.jl`** — attributed C-sets = typed graphs with properties = node + property + relation,
    formalized as a categorical database.
  - **`AlgebraicRewriting.jl`** — **double-pushout (DPO) rewriting** = ADD/LINK/MUTATE/UNLINK as
    category-theoretic rules, with confluence machinery (CI-1 Church–Rosser).
  - **`Catlab.jl`** — computational category theory (functors, colimits = manifold).
- **DPO tools:** **Kappa** (kappalanguage.org), **GROOVE**, **AGG**, **GP2**.
- **Categorical-database theory:** **David Spivak / Topos Institute** — C-sets, **ologs**
  (ontology logs); free book **"Seven Sketches in Compositionality"** (Fong & Spivak). The math
  under the semantic SOT. **(ffs0)**

## Append-only / event-sourced data layer
ffs0 is an event-sourced system with a categorical type layer; the production systems already exist.
**(ffs0)**

- **Datomic** + **XTDB** (bitemporal, open-source) — immutable facts (EAV = node-property), time
  first-class, query the past = `fold(log[0..t])`.
- **TerminusDB** — git-like graph DB with branch/merge = `branch=F(session)` / `merge=G(branch)`.
- **Differential Dataflow** (`TimelyDataflow/differential-dataflow`, Materialize) — incremental view
  maintenance = F-projection updated incrementally as the log grows.
- **Datalog:** **Soufflé**, **Datascript/Datalevin**. **Event-sourcing canon:** EventStoreDB/
  **KurrentDB**, **Marten**; Greg Young (CQRS), Martin Fowler.

## Multiplayer (humans co-occupying a workspace)
- **CRDTs:** **Yjs**, **Automerge**, **Loro**, **diamond-types** — how multiple `has-occupant`
  humans + agents edit one workspace concurrently without a lock. **(both)**
- **Local-first software** — **Ink & Switch** (the research lab for "personal portable private
  workspace"), Martin Kleppmann's "local-first" essay. **(ffs0)**

## Languages, by component
- **Go** — keep the kernel (concurrency, HTTP/federation). **Rust** — fast LSP, e-graph layer,
  CRDTs, wasm host, perf-critical lanes. **Julia** — projections + AlgebraicJulia. **TypeScript** —
  IDE extensions, MCP servers, webviews. **Lean 4** (or Rocq/Coq) — to *prove* CI-1…CI-5.
  **Zig** — from-scratch perf experiments.

## Communities / where the science lives
- **AlgebraicJulia Zulip** + **Topos Institute** (toposinstitute.org) — the literal math.
- **e-graphs community** (egraphs-good.github.io, EGRAPHS workshop).
- **Handmade Network** (handmade.network) — perf-first engine dev.
- **Local-first community** (Ink & Switch, localfirstweb).
- **Conferences:** POPL / ICFP / PLDI, Strange Loop archive, LLVM Discourse, CppCon (DOD).
- **Bevy** (`bevyengine.org`, Rust ECS) — cleanest modern ECS to read as the reference for
  "scene = entities + components + systems = hypergraph."

## Graph viz / scene surfaces
Already: Graphviz + Cytoscape.js (`dev/scripts/graph_artifact_projection.jl`,
`session_pipeline_mvp_gate.jl`). Add: **Sigma.js** / **Cosmograph** (GPU, big graphs), **D3**,
**tldraw** / **Excalidraw** (whiteboard scene surface), **Three.js** / **PixiJS** (real render
target).

## Ranked shortlist (highest leverage first)
1. **moos-kernel MCP server** (Go, `mark3labs/mcp-go`) — rewrites as tools, `/state` as resources.
   One artifact, every IDE's agent gets the kernel. → `dev/tools/moos-mcp/`. **(ffs0 + all IDEs)**
2. **moos-LSP** (Go via `tliron/glsp`) — diagnostics = operad/port-color violations, hover = folded
   state, completion = valid WF rewrites. → `dev/tools/moos-lsp/`. **(all IDEs)**
3. **Read `egglog` + `AlgebraicRewriting.jl`** before extending the kernel — "log→derived-state
   under an operad" with proofs and running code, in languages already in the repo.
4. **VS Code Webview HG inspector** — wrap the existing Cytoscape `index.html` as an editor panel.
5. **Evaluate TerminusDB / Datomic** as the substrate — branch/merge and time-travel currently
   hand-rolled.

---
authored-by: agent:claude-code.hp-z440 / session:sam.z440-cowork-workspace / tooling-landscape
