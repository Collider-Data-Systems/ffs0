# T274 engine language choice — C / Dependable C / MLIR examined

> **Status: design draft (S0 -> pending G-ingest). GATE: prose/tooling only.** No ontology edit, no HG rewrite, no runtime port begun. Continues the T244 compiler-lowering lane (`20260703-t244-moos-ir-mlir-lowering.md`, purpose `sam.compiler-lowering`). Companion decision record: `DECISION-engine-language.md`. Authored from a remote Claude Code session (ungoverned S0 seat) at Sam's request.

## One Sentence

For the full-runtime replacement Sam has scoped, C++ is the recorded direction pending the MLIR spike; C / Dependable C loses on three of the four stated drivers for a *runtime* but wins cleanly for one narrower artifact (`libmoosfold`, named below as an alternative); MLIR's role rests on one falsifiable assumption that Spike B settles.

## Inputs

- Scope (Sam, T=274): **full runtime replacement** — fold, operad, transport, MCP, sweep, log store; the Go kernel eventually retired. This supersedes T244's "semantic core only" spike scope, which stays valid as the *ordering* (fold core first).
- Drivers (Sam, T=274, all four): **correctness by construction · performance headroom · zero-dependency portability · longevity/AI-legibility.**
- Direction (Sam, T=274): **C++ accepted throughout** to keep MLIR reachable.
- Prior art: T244 note (Rust first, C++ later, MLIR before LLVM); T263 ceiling report (*"The Rust rewrite is justified on the LMAX 10K-naive-vs-6M-optimized codec/allocation axis (~100x), not language speed; it does not move the Windows datapath ceilings at all"*); standing invariant **"stdlib + quic-go only"** (defended T=260 WebTransport revert, T=263 Gemini proxy).

## What the runtime actually is (measured, this round)

`moos-kernel`: **9,808 src LOC / 9,481 test LOC**, 10 packages, one external dep (`quic-go v0.59.0`). `moos-router`: 1,035 / 744, zero deps. A weeks-scale port; the ~1:1 test corpus is the asset that makes replay-equivalence acceptance (Spike C) cheap.

Surface a non-Go runtime must supply: HTTP/1.1+2 with method+pattern routing over 38 routes; TLS 1.3; optional HTTP/3; SSE at `transport/server.go:300,388` + `mcp/server.go:90`; JSON-RPC 2.0; flock + Windows deny-write share-mode log locking (`kernel/log_lock_unix.go`, `log_lock_windows.go` — load-bearing, moos-kernel#40); JSONL append with a 10 MB line scanner. Shape of the code: **181 `json:"..."` struct tags**, **129 non-test `any` sites** (29 type assertions), ~50 node types, error strings the tests assert on. Concurrency is *simple*: one global `sync.RWMutex` (`kernel/runtime.go:39`), snapshot reads, six long-lived tasks, lossy per-subscriber channels — no CSP topology worth preserving. The one hidden cost is `net/http`'s invisible goroutine-per-connection: every handler assumes a blocking concurrent model the replacement must supply.

Where the compute is: `internal/hdc` only. `Dimension = 10000`, `type HV [Dimension]float32` (`hdc/hdc.go:11,14`) — 40 KB values passed **by value** (Bind moves 120 KB/call), scalar 10k-iteration loops Go will not vectorize, invoked O(N·R) **twice per rewrite under the write lock** via `runtime.go:971,1068`, with a fresh `NewEncoder()` codebook minted each call (`spectral.go:408`). Plus a hand-rolled O(n⁴)-worst-case Jacobi eigensolver (`spectral.go:106-115`). Everything else is branchy string/map logic where language choice buys safety and ergonomics, not throughput.

## C / Dependable C, against the four drivers

Dependable C (dependablec.org, Eskil Steenberg) is explicitly **not a dialect**: *"C trying to be as middle of the road as possible in order to be understood and implemented as widely as possible"* — "Newscaster C," a C89-centred universal subset premised on *"the C programming language is unfixable, [but] it is good enough to not need to be fixed."* Prose guidance; no checker, test suite, or certification (contrast MISRA C, which has tooling).

| Driver | Verdict for a full C runtime |
| --- | --- |
| Longevity / AI-legibility | **Genuine win, one caveat.** Deepest corpus of any candidate, most implementations, longest horizon. Caveat: model parameter density is over *modern idiomatic* C; the argument transfers only partly to a strict C89 subset. |
| Zero-dependency portability | **Inverted at this scope.** Today: stdlib + quic-go. A C runtime needs OpenSSL (or mbedTLS), an HTTP/2 stack (nghttp2/h2o class), ngtcp2+nghttp3 for HTTP/3, a JSON library, and a string-keyed hashmap. Dependency count goes *up*, and the subset's compile-anywhere guarantee does not extend to any of those. |
| Correctness by construction | **Worst of the four candidates.** ~60% of the codebase is JSON-mapped structs, string-keyed maps, and rich error paths. C provides none of it structurally; the T249 fp-fruits observation (invariants held "by convention") gets *worse*, not better. |
| Performance headroom | **Neutral-to-negative.** The measured wins are algorithmic (codebook hoist, clone elimination, batch encode — see Spike A) plus SIMD; C89 has no intrinsics, so the first vector op leaves the subset anyway. |

Cost made concrete: hand-writing ~40 serializer/deserializer pairs for the 181 tagged fields plus a hashmap layer is ~1.5–2 kLOC of tedious, bug-prone code before one line of kernel logic exists — roughly doubling the port before it starts.

## Where C *does* win — `libmoosfold` (named alternative, not the plan)

The one artifact where C serves longevity + portability + AI-legibility and hits none of its weaknesses: **`fold` + `GraphState` + operad validation as a zero-dependency C library with a stable C ABI.** That is precisely the T244 durable object (`rewrite log + ontology operad -> fold -> derived HG state`); it is ~926 src LOC of Go today (`internal/fold` 349 + `internal/graph` 577); it has **no** TLS/HTTP/QUIC/JSON-RPC surface; and a C ABI makes every other language a *host* of the semantic core rather than a competing rewrite. This is Dependable C's actual use case — libraries. Recorded as an alternative because it contradicts the full-replacement scope Sam chose; reversing that is Sam's call.

## MLIR, examined

Three findings, strongest first:

1. **Layering mismatch (the real problem).** An ODS/TableGen dialect is **build-time**; the mo:os operad is **runtime data** — `ontology.json` (187 KB, v3.14 → 4.0.4 live) loaded at boot by `cmd/moos/main.go:86` into `operad.Registry`. A generated dialect freezes the ontology version into the binary; every ontology bump becomes a recompile, contradicting the registry-as-loaded-type-system design. Escape hatches exist (codegen the dialect per ontology version; IRDL/dynamic dialects) and Spike B tests whether one survives contact.
2. **C-API dead end.** MLIR's C API has no stability guarantee, covers core IR + passes only, and external dialects through it are broken (llvm-project#108253). A moos dialect means TableGen/ODS and C++ — this is what makes "C engine + MLIR" incoherent as a single-language story and motivated Sam's C++-throughout call.
3. **The workload is not compiler-shaped (conjecture, but a strong one).** The kernel is a fold over a log, not a program being lowered. The HDC ops are a handful of fixed-shape elementwise/reduction kernels over `[10000]f32` — the win there is a codebook hoist + pass-by-pointer + one afternoon of intrinsics, not a dialect. The only DSL in the repo is the t_hook predicate evaluator (`reactive/predicate.go:110`, ~10 node kinds, tree-walked a few times per sweep tick) — compiling it is a performance no-op. MLIR earns a place only if `moos IR` becomes a committed textual format with real verifier/lowering passes (T244 open question #1), and then plausibly as a **separate offline tool**, not inside the engine.

T244 already provisioned the cheap test bench: xDSL in the repo `.venv` (native `mlir-opt`/`mlir-translate` absent from the Windows LLVM installer).

## Recommendation (recorded)

**C++ throughout is the recorded direction — Sam's call, T=274 — with its MLIR premise explicitly pending Spike B.** For honesty of the record: measured against the four drivers alone, Rust scores highest (serde covers the 181 tags and 129 `any` sites 1:1 incl. `omitempty`; hyper/axum covers routes+SSE+HTTP/2; rustls+quinn cover TLS/QUIC; `im`/`rpds` are the off-the-shelf fix for the `Clone()`-per-rewrite cost the code already flags at `graph/state.go:88` — in C++ the equivalents are `immer`, Boost.Beast/nghttp2, msquic, and glaze/reflect-cpp, a materially rougher assembly). C++'s decisive advantages are native LLVM/MLIR proximity, Eigen for the spectral math, and custom-allocator control — exactly T244's "later performance/embedding candidate" framing. The three spikes are the tiebreaker; nobody re-argues taste.

- **Spike A (perf premise):** benchmarks in `moos-kernel` (test files only) quantifying the codebook regeneration (`runtime.go:971,1068` → `spectral.go:408`), `GraphState.Clone()` per rewrite (`graph/state.go:96`; N+1 clones per N-step program, `fold/program.go:31,38`), HV by-value costs, and `EncodeNode` vs the existing unused batch path `EncodeNodes` (`encode.go:90`). If hygiene fixes in Go recover most of the throughput, the perf driver stops justifying a port and the case narrows back to T244's semantic-core spike.
- **Spike B (MLIR premise):** xDSL fixture — can a dialect generated from `ontology.json` carry a runtime-versioned operad? Either outcome is a result.
- **Spike C (acceptance gate, language-neutral):** committed JSONL log + canonical serialization of the folded state (`Nodes` + `Relations` only; derived indexes are `json:"-"`, rebuilt by `Rebuild()` at `graph/state.go:69`) + stable hash. Per the `moos-compiler-lowering` skill: the Go kernel remains the oracle until a replacement reproduces this hash.

Consequential edit this round: `dev/tools/landscape.md` "Languages, by component" says **"Go — keep the kernel"** — updated to reflect the T=274 full-replacement decision (Go = reference oracle until replay equivalence, not permanent home).

## Spike results (measured this round, same container: linux/amd64, Go 1.24.7, 4 vCPU)

**Spike A — the perf premise is confirmed and sharpened.** `go test -bench=SpikeA -benchmem ./internal/hdc/ ./internal/fold/`:

| Measurement | Result |
| --- | --- |
| Full-state HDC encode via per-node path (300 nodes / 600 rels, `TypeExpressions`) | **~1.2–1.3 s and ~7.3 GB allocated per call** — and the runtime calls it **twice per rewrite under the write lock** |
| Same state via the existing-but-unused batch path (`EncodeNodes`, adjacency built once) | **~0.33 s and 147 MB** — ~4× time, **~50× allocation** win, zero production change required |
| Codebook cold (fresh `NewEncoder()`, 256 URNs) vs warm | 43 ms vs 1.2 ms — real (~37×) but secondary to the encode path |
| `GraphState.Clone()` at 1k nodes / 2k rels · 5k/10k | 2.7 ms / 2.15 MB · 19.6 ms / 10.3 MB — per rewrite; ×(N+1) per N-step program (32-step ≈ 85 ms / 71 MB) |
| `Bind` (10k floats, by value) | 6.8 µs ≈ 1.5 GFLOP/s scalar — SIMD headroom ~8–16× on top |

Verdict: the T=263 re-judgment holds with local numbers — the dominant costs are **algorithmic and already fixable in Go** (adopt the batch path in `spectral.go`, persist the encoder on `Runtime`, CoW state). A language port that keeps the O(N·R)-twice-per-rewrite shape inherits the problem; a Go kernel that fixes it removes most of the perf motive. Open question #1 is now live, not rhetorical.

**Spike B — survives, with the premise narrowed.** xDSL 0.69.0, ontology 4.0.4 loaded at runtime, 6/6 fixture cases correct (`dev/research/mlir/20260802-t274-spike-b-findings.md`). A dialect generated at process start can carry the runtime-versioned operad — *in a dynamic host*. Accidental headline: the t244 sketch verbatim is **rejected** by the 4.0.4 operad (WF21 is `causes/caused-by` now, not `produces/produced-by`) — the build-time-freeze rot demonstrated by our own two-round-old fixture. Sharpest conclusion: **the operad verifier does not need MLIR** — it is a table-driven checker in any language (the Go `operad.Registry` already is one). MLIR's value is pass/lowering machinery over a future committed `moos IR`, plausibly as an offline tool; it is not needed inside the engine. C++'s MLIR-proximity advantage is therefore real but narrower than the T=274 framing assumed.

**Spike C — gate built and pinned.** `moos-kernel/testdata/replay/t274-fixture.jsonl` (12 entries: all four rewrite types, idempotent-skip duplicate ADD, additive MUTATE via PropertySpec, WF15 contract LINK) folds to canonical-state SHA-256 `6bb67afc79b23155cb79a38a0be74ed5c5685a5f519b5e081a128300a81e6d90` (`internal/fold/replay_fixture_test.go`, golden + hash committed). Any candidate engine reproduces this hash from the same JSONL or is not an engine. Full `go test ./...` stays green; `go.mod` untouched.

## Open Questions

1. Does the full-replacement scope survive Spike A's numbers, or does the lane narrow back to the T244 fold-core spike with Go retained as the runtime shell?
2. If Spike B kills the build-time dialect, does MLIR leave the engine decision entirely, or return later as an offline tool over a committed `moos IR` text format (T244 open question #1)?

---
authored-by: agent:claude-code.remote / session:none-ungoverned-remote-s0 / t274-engine-language-choice
