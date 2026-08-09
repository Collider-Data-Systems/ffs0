# Memory, allocation, and whether processes travel (T=281)

> **Status: design draft (S0 → pending G-ingest). GATE: prose + measurement only.** No ontology edit, no HG rewrite, no runtime change, no URN change. Continues `purpose:sam.compiler-lowering` (t244 → t274). Authored from a remote Claude Code session (ungoverned S0 seat) at Sam's request (`t281;1636`).
>
> **Rule of this note (inherited from t265):** no general definition appears without the number it produces on real data. Every figure below is either **MEASURED** in this container this round, **DERIVED** analytically from source constants, or **PROJECTED** from a measured constant onto the last measured fold shape — each is tagged. Conjectures are tagged.
>
> **This note answers a question the record left open.** The t274 addendum recorded: *"Marked conjecture: whether 'memory-allocation projections' means bufferization is open — the correspondence is real only if workspace projections decide materialization sharing vs copy (one-shot bufferize's alias-set problem); otherwise the honest analog is plain lowering plus DLTI layout attributes. **Sam to disambiguate when the fragment lands.**"* §6 rules on it.

---

## §0 Headline, before the argument

Three findings, strongest first. Each is a number, not a position.

1. **The operad already contains the entire hardware-travel grammar, and it has never been instantiated.** Four rewrite categories are devoted to the substrate axis — **WF04** (workstation `contains` compute|storage), **WF08** (compute|storage `bound-to` workstation), **WF09** *"Kernel routes operations to compute substrates"* (kernel `computes-on` compute), **WF10** (kernel's log `persisted-in` storage). The `compute` type carries `compute_type ∈ {cpu, gpu, cloud, docker}` and `execution_model ∈ {sequential, concurrent, distributed}`. **MEASURED:** the production seeder (`cmd/moos/main.go:273-398`) mints `user`, `workstation`, `kernel` and exactly two relations — WF01 and WF03. It mints **no `compute` node, no `storage` node, no WF04/WF08/WF09/WF10 relation, ever.** The only artifact that does is `kb/superset/instances/seed.json`, consumed by **one** script (`dev/scripts/ops/Start-ScratchKernel.ps1`) and by nothing in the runtime. This is the same shape t265 measured for the deployment axis (0 instantiated nodes) — *declared and empty* — and it is the direct answer to the travel question (§7).

2. **Essentially 100% of the engine's memory traffic is one capacity expression.** `encode.go:68` sizes a per-node scratch slice by **the total relation count of the whole graph**, in units of 40 KB:
   ```go
   vectors := make([]HV, 0, typeWeight+1+len(state.Relations))   // typeWeight = 6
   ```
   **DERIVED:** at 300 nodes / 600 relations that is `300 × (6+1+600) × 40,000 B = 7,284,000,000 B`. **MEASURED** the same run: `7,286,361,656 B/op`. The prediction is off by **0.032%** — the capacity hint *is* the memory bill. What the node actually needs is `6+1+(incident relations)`; at that shape the mean is 4, so the slice is over-provisioned **55×**.

3. **The memory pressure is not a performance bug — it is a stratum violation.** The workload doing the allocating is the HDC live index. `ontology.json.ci2_projection_registry` classifies it under **lossy**: *"`P_search_rank` — S3 HDC/VSA evaluation artifact; non-invertible"*, and the registry's own rule is *"Projections not listed [as CI-2 compliant] are lossy — valid for S4 display only, not for authority."* **MEASURED:** it is nevertheless recomputed **synchronously, totally, inside `Runtime.Apply`/`ApplyProgram`, while holding the global write lock** (`runtime.go:321, 469 → 1036`). A non-authoritative S3/S4 projection executes in the S2 authority path. Everything in §3 follows from that one placement error; fixing it is architectural and is already licensed by the ontology's own register.

---

## §1 What "memory" and "allocation" even mean here

Start from the doctrine, because it determines what can and cannot be a memory concept.

```
state(t) = fold(log[0..t])          log is truth · state is derived
```

`fold` is a catamorphism over the free monoid of rewrites. Initial-algebra semantics of that kind is **deliberately resource-blind**: an F-algebra says what a rewrite *means*, never what it *costs* or where it *lives*. So the first ruling is definitional and it is load-bearing for everything after:

> **Ruling R1. Memory is not a semantic concept in mo:os. It is a property of the F-projection — the engine — and it belongs in the target descriptor, never in the operad.**
>
> This is not a gap. It is why `ontology.json` has no allocation vocabulary and should not acquire one. The correct home for bytes is the `compute`/`storage`/`harness` substrate nodes (which already exist, §0) and the moos-soom capability vector (t244's "target capability vector"), not the rewrite grammar.

With that fixed, there are exactly **two** memories in the system, and they behave completely differently.

| | **The log** | **The fold** |
|---|---|---|
| role | truth | derived cache of truth |
| discipline | append-only, single-writer (flock / Windows deny-write, `kernel/log_lock_*.go`) | mutable in-process image, replaced never mutated in place |
| allocator | **ADD** and **LINK** — the only two rewrites that create | `Clone()` on every apply |
| deallocator | **UNLINK** — and nothing else | — |
| lifetime | forever (no compaction path exists) | process lifetime; rebuilt by `fold.Replay` at boot |
| unit cost | **MEASURED:** 3,694 B / 12 entries = **~308 B per rewrite** (`testdata/replay/t274-fixture.jsonl`) | see §3 |

### The allocation asymmetry — the sharpest structural fact about memory in mo:os

**MEASURED:** across the entire non-test kernel there is exactly **one** deletion site:

```
internal/fold/evaluate.go:160 →  delete(state.Relations, env.RelationURN)
```

`delete(state.Nodes, …)` **does not occur anywhere in the non-test tree.** There is no fifth rewrite, no tombstone, no retention policy, no log compaction, no snapshot-and-truncate.

Consequences, stated plainly:

- **Nodes are cartesian; relations are affine.** A node, once ADDed, can be referenced freely and can never be consumed. A relation is created once by LINK and may be consumed once by UNLINK. In substructural terms the rewrite calculus admits contraction and weakening on nodes but treats relations as use-once resources. *(Reading, not theorem — tagged in §8.)*
- **`|Nodes|` is monotone non-decreasing in `t`, by construction.** The graph has a `malloc` and no `free`. This is correct for an event-sourced system and it is also the reason a memory budget cannot be derived from the ontology: growth is bounded only by how much Sam writes.
- **The only reclamation primitive available is "don't replay it"** — i.e. snapshot + truncate, which does not exist and would have to be reconciled with CI-4 (`fold(log[0..t])` deterministic) and with `log/integrity`'s per-entry effect report. This is a real future decision, not a defect today; recorded in §9.

### Lifecycle of structures — the honest table

| structure | born | changes | dies | versioned |
|---|---|---|---|---|
| node | ADD (`Version: 1`, `CreatedAt`) | MUTATE (one typed property, one node) | **never** | yes (`Version`) |
| relation | LINK | — (topology is not mutable except the §M19 occupancy rotation) | UNLINK | no |
| property | ADD (with node) or MUTATE | MUTATE | with its node, i.e. never | via node version |
| derived index (`NodesByType`, `RelationsBySrc/Tgt`) | maintained incrementally by `fold` | per rewrite | with the process | `json:"-"` — never serialized, `Rebuild()`s |
| HDC live index | **recomputed from scratch, totally, per rewrite** | — | with the process | not registered as a cache at all (§9 D3) |

The last two rows are the whole story. **`fold` is incremental. Its derived projections are not.** One is `O(Δ)`; the other is `O(N·R)` and runs on the same lock.

---

## §2 The memory hierarchy mo:os actually has

Sam asked about CPU/GPU memory types. Here is the real hierarchy, and — separately — the mo:os tiers, because **they are not the same axis and conflating them is the mistake to avoid.**

### 2a. The hardware hierarchy, with this workload's position marked

| tier | typical size | typical bandwidth | latency | where mo:os lands |
|---|---|---|---|---|
| CPU registers / SIMD | ~2 KB | — | ~0 | `HV` never fits; Go emits scalar loops (**no SIMD in tree — MEASURED: zero `avx`/`simd` mentions**) |
| L1d | 32–48 KB / core | ~1 TB/s | ~1 ns | **`HV` = 40,000 B, and `Bind` touches three of them = 120 KB.** No L1d in production holds one `Bind`'s working set; on the Z440's Xeon-E5 class (32 KB) it does not hold even a single `HV` |
| L2 | 0.5–2 MB / core | ~200–400 GB/s | ~4 ns | a *packed* HV (§4d) would live here comfortably |
| L3 (shared) | 8–35 MB | ~100–200 GB/s | ~15 ns | one node's bundle working set = **24.3 MB** — at or past L3, shared with 3 other vCPUs |
| DRAM | 8–128 GB | 15–50 GB/s | ~80 ns | **where the write path actually runs.** MEASURED effective 17.65 GB/s (below) |
| NVMe / page cache | TB | 2–7 GB/s | ~100 µs | the JSONL log; the OS page cache is the real read tier |
| tailnet (Tailscale mesh) | — | ~100 Mb–1 Gb/s | ~1–20 ms | twin sync, router fan-out — the federation "memory" |
| **GPU** registers / shared | 256 KB / 100 KB per SM | ~10 TB/s | ~0 | — |
| **GPU** HBM / VRAM | 8–80 GB | **0.5–3 TB/s** | ~300 ns | **the tier `compute.compute_type=gpu` was minted for, with 0 instances** |
| PCIe host↔device | — | 16–64 GB/s | ~5 µs | the tax any GPU lane pays; ~1× DRAM bandwidth, so it only pays off if data *stays* resident |

**The diagnosis, from one measured number.** `Bind` is 10,000 elementwise `float32` multiplies over three 40 KB vectors (two read, one written):

- **MEASURED:** 6.797 µs/op, **0 B allocated** (stack-resident, so this is pure traffic).
- **DERIVED:** 120,000 B / 6.797 µs = **17.65 GB/s effective** — squarely single-core DRAM bandwidth.
- **DERIVED:** 10,000 flops / 6.797 µs = **1.47 GFLOP/s**, i.e. **0.083 flop per byte**. Machine balance is ~10 flop/byte.

> **HV algebra is not compute-bound. It is memory-bandwidth-bound by two orders of magnitude.** That single fact determines everything about whether a GPU helps (§7c) and about which fix is worth doing first (§4d). A language port that keeps `[10000]float32` inherits the bandwidth wall exactly; this is the t263 "the Rust rewrite is justified on the codec/allocation axis, not language speed" judgment, reproduced independently on the HDC path.

### 2b. The mo:os tiers, and what they are *not*

**S0–S4 is not a memory hierarchy.** It is a provenance filtration — how *validated* a fact is, not how far it is from the ALU. Reading it as a cache hierarchy is a category error (S4 is not "slower S2"; it is *non-authoritative* S2). What mo:os *does* have that is genuinely cache-shaped is narrower and better than the filtration:

**`ontology.json.s4_cache_contract` is a write-invalidate cache-coherence protocol, written down.** Four named caches, each with a declared backing projection and an **invalidation trigger keyed on a WF category**:

| cache | backing projection | invalidated by |
|---|---|---|
| `agent_capabilities_cache` | `P_capabilities` | any WF02 LINK/UNLINK on that agent |
| `session_participants_cache` | `P_session_participants` | any WF07 LINK/UNLINK on that session |
| `kernel_endpoints_cache` | `P_kernel_endpoints` | any WF05 LINK/UNLINK on that kernel |
| `agent_properties_cache` | `P_agent` | any WF02 MUTATE on that agent |

plus five forbidden patterns that are, precisely, *"topology stored as property"* — the denormalization every cache designer eventually regrets. This is a better-specified coherence story than most systems have. **The HDC live index is not in it** (§9 D3), which is exactly why it is the one that hurts.

---

## §3 Where the memory actually goes — measured

`go test -bench=SpikeA -benchmem -benchtime=1x ./internal/fold/ ./internal/hdc/` · linux/amd64 · Go 1.24.7 · Intel Xeon @ 2.80 GHz · 4 vCPU. Reproduces the t274 Spike A shape on the current tree.

| benchmark | ns/op | **B/op** | allocs/op |
|---|---:|---:|---:|
| `Clone` 100 nodes / 200 rels | 187,974 | 197,880 | 822 |
| `Clone` 1k / 2k | 3,805,447 | 2,150,320 | 8,037 |
| `Clone` 5k / 10k | 29,126,240 | 10,279,408 | 40,108 |
| `EvaluateADD` 1k | 3,792,019 | 2,151,888 | 8,041 |
| `Program` 1k nodes, 8 steps | 2,581,593 | 2,166,416 | 8,079 |
| `Program` 1k nodes, **32 steps** | 3,865,875 | **2,215,616** | 8,201 |
| `Codebook` cold (fresh encoder, 256 URNs) | 38,023,788 | 11,888,872 | 525 |
| `Codebook` warm | 1,860,025 | **0** | **0** |
| `TypeExpressions` 300 nodes, warm enc | 1,162,471,063 | 7,339,741,672 | 21,080 |
| **`EncodeNode` per-node, 300 nodes** | 1,407,419,557 | **7,286,361,656** | 19,510 |
| **`EncodeNodes` batch, 300 nodes** | 294,115,276 | **147,459,112** | 20,718 |
| `Bind` (10k float32, by value) | 6,797 | 0 | 0 |
| `Bundle` ×12 | 112,156 | 0 | 0 |
| `Cosine` | 14,630 | 0 | 0 |

### 3a. Two of t274's three licensed hygiene fixes have already landed

Comparing against the t274 record (commit `856cfcd`, *"perf(t274): reuse HDC encoder and program state clone"*):

- **Persistent encoder — DONE.** `Runtime` now holds `hdcEncoder` (`runtime.go:131`) and passes it at both call sites. Cold-vs-warm is still **20.4×** (38.0 ms → 1.86 ms, 11.9 MB → **0 B**) but the runtime no longer pays it.
- **N+1 clones per N-step program — DONE.** `EvaluateProgramAt` clones once and then runs `evaluateInPlace` per envelope. **Confirmed by measurement, not by reading:** 32 steps allocates 2,215,616 B against a single clone's 2,150,320 B — a **3% delta**, where N+1 would have been ~71 MB.
- **Batch `EncodeNodes` on the write path — NOT DONE, and it is the big one.** `spectral.go:406 embeddingsFromState` still calls `enc.EncodeNode(state, urn)` per node. The batch path exists (`encode.go:90`), is correct, and is used by `fiber.go` and `crosswalk.go` — just not by the path that runs on every rewrite. **MEASURED: 4.79× time, 49.4× allocation, for adopting code already in the tree.**

### 3b. The one line

```go
// internal/hdc/encode.go:68  (EncodeNode — the per-node path)
vectors := make([]HV, 0, typeWeight+1+len(state.Relations))   //  ← len(ALL relations)
...
for _, rel := range state.Relations {
    if rel.SrcURN != urn && rel.TgtURN != urn { continue }     //  ← but only INCIDENT ones are appended
```

The scan is `O(R)` per node (annoying); the **capacity** is `O(R)` per node *in 40 KB units* (fatal). The batch path at `encode.go:113` gets it right — `make([]HV, 0, typeWeight+1+len(rels))` against a pre-built adjacency list.

**DERIVED vs MEASURED at the benchmark shape (300 nodes / 600 relations):**

```
predicted  300 × (6 + 1 + 600) × 40,000 B  =  7,284,000,000 B
measured                                       7,286,361,656 B      Δ = 0.032 %
```

**PROJECTED onto the last measured live fold** (t266 Z440: **313 nodes · 229 relations · log 669/669**; §11 of the t265 note):

| quantity | value | basis |
|---|---:|---|
| slice capacity per node | `6+1+229 = 236` HV = 9.44 MB | DERIVED |
| allocation per `Recompute` | **2.955 GB** | DERIVED (313 × 9.44 MB) |
| mean incident relations per node | `2×229/313 = 1.46` | DERIVED |
| capacity actually needed | ~8.5 HV = 338 KB/node → **106 MB** | DERIVED |
| **over-provision factor** | **27.9×** | DERIVED |
| wall time per `Recompute` | **~0.57 s** | PROJECTED at the measured 5.18 GB/s alloc-and-fill rate |

### 3c. How often it runs, precisely

The t274 note recorded *"twice per rewrite under the write lock."* The current tree is more precise, and the difference matters for the fix:

- `runHDCIndexAndDriftLocked` is called **once per `Apply`** (`runtime.go:321`) and **once per `ApplyProgram`** — for the whole batch, with the final envelope as trigger (`runtime.go:469`), **not** once per envelope. Batching already amortizes it.
- Inside, `Recompute` runs at `:1036` **always**, and a second time at `:1133` **only when `Drifted()` is non-empty**.

> **So the floor is one full `O(N·R)` recompute per apply-call, and two when any type-drift row crosses threshold.** On the live fold that is **~3 GB and ~0.6 s of DRAM traffic inside the global write lock, per rewrite, to maintain an index the ontology itself classifies as non-authoritative.**

---

## §4 The functional-programming reading

Sam asked how this relates to the FP shape of the codebase. Four connections, in decreasing order of how much they actually buy.

### 4a. Value semantics is the allocator, and the code already says so

`GraphState` is a value: `Clone()` on entry, replaced never mutated (`state.go:84-96`, and the `TODO(perf)` there names the problem exactly). This is textbook persistent-data-structure discipline and it is *why* the rollback guarantee is free — a failed program returns the original state because the original was never touched.

The cost is measured and it is honest: **2.15 MB / 8,037 allocs at 1k nodes; 10.3 MB / 40,108 allocs at 5k.** Note the alloc *count*: it is `≈ 4 × nodes`, because `Clone` deep-copies every node's `Properties` map plus three index maps. The bytes are fine; the **allocation count** is the GC pressure.

The standard fix is structural sharing — a HAMT/CHAMP persistent map, where `Clone` is `O(1)` and each mutation copies only the path to the changed key (`O(log₃₂ N)`, i.e. ≤ 5 nodes at this scale). The t274 note already named the off-the-shelf options (`im`/`rpds` in Rust, `immer` in C++); in Go it is a hand-rolled HAMT or nothing. **At 313 nodes this is not urgent** — 2 MB and 800 allocs — and it will matter at 10k. Recorded, not recommended.

### 4b. Fold is incremental; its projections are not — and CI-1 is the licence to fix that

The catamorphism is already per-step: `Apply` folds *one* envelope into the existing state. Nothing recomputes the graph from the log on the hot path. That is the good half.

The bad half is that everything *derived* from state is recomputed **totally**. And the ontology already contains the exact concept needed to make it incremental:

```
CI1  Church-Rosser: M_a;M_b = M_b;M_a  when  affected(M_a) ∩ affected(M_b) = ∅
```

`affected(M)` is the dependency cone. A rewrite affects one node (ADD/MUTATE) or two (LINK/UNLINK). **An index over nodes therefore needs to invalidate at most 1–2 entries per rewrite, plus their incident neighbours** — which is precisely the `RelationsBySrc`/`RelationsByTgt` walk that already exists and is already `O(1)`. The right shape is not `Recompute(state)` but `Update(index, Δ)` — change propagation (Adapton / differential-dataflow shaped), with `affected()` as the change set and the s4 cache contract's per-WF invalidation triggers as the precedent for how to write it down.

> **DERIVED:** with per-affected-node invalidation, a single ADD re-encodes **1 node** instead of 313 — `9.44 MB → ~30 KB`, a **~10⁵×** reduction on the dominant term, *before* any of §4d's constant-factor work. This is the largest single number in the note and it costs no ontology change and no language change.

### 4c. What the F ⊣ G framing does and does not say about memory

The adjunction is about *meaning transport* (S0 conversation → G-ingest → HG → F-projection → surface), not about storage. Two things it does buy here:

- **CI-2 naturality, `Project(Apply(M,S)) = Apply(M', Project(S))`, is the lowering-correctness square** (t274's corrected spine). Applied to *caches* rather than surfaces, it is exactly the incremental-view-maintenance law: updating the cache from the delta must equal recomputing the cache from the new state. That law is what an `Update(index, Δ)` implementation is *proving*, and it already has a home in the register.
- **The register already rules on HDC.** `P_search_rank` is listed **lossy** → S4 display only → **not authority**. So moving it off the write path is not a design liberty; it is compliance.

What the adjunction does **not** buy is any statement about bytes. See §6.

### 4d. The representation is 32× larger than the information it carries

**MEASURED, from source:** `Codebook.Encode` produces values in `{−1, +1}` only (`hdc.go:36-40`). `Bind` is elementwise multiplication — **closed on `{−1,+1}`**. `Bundle` sums and L2-normalizes, so it leaves the set; `Cosine` needs floats. Therefore:

| representation | bytes per HV | `Bind` | fits in |
|---|---:|---|---|
| today: `[10000]float32` | 40,000 | 10k float mults | L2/L3 |
| bipolar bitpacked: `[157]uint64` | **1,250** | 10k-bit **XOR** = 157 word-ops | **L1d** |

**PROJECTED (not measured — no packed implementation exists):** a bitpacked codebook and `Bind` path is **32×** smaller, moves the entire hot working set inside L1, and turns a bandwidth-bound float loop into a popcount/XOR loop. Only the *bundled* result and `Cosine` need to leave the packed domain (int16 accumulators, 20 KB per bundle). This is the classic VSA representation choice — `float32` bipolar is emulating binary/bipolar HDC at 32× the cost.

### The ladder, at the live fold shape

| step | per-`Recompute` allocation | factor | status |
|---|---:|---:|---|
| today (per-node path) | 2.955 GB | — | MEASURED formula, PROJECTED shape |
| \+ adopt batch `EncodeNodes` in `spectral.go` | ~106 MB | 27.9× | code already in tree, unused here |
| \+ bipolar bitpacking | ~3.3 MB | 32× | PROJECTED |
| \+ `affected()`-scoped incremental update | ~10–30 KB | ~10²–10³× | PROJECTED |

> **Ruling R2. The workload that looks like it needs a GPU currently needs a `make()` fixed.** Do the arithmetic before the hardware. Any accelerator lane opened against the *current* shape would be buying a ~1000× algorithmic win and reporting it as a hardware win — the exact error the t263 ceiling report caught on the Rust axis.

---

## §5 Evaluation

Three evaluation strategies are in play and only one of them is chosen deliberately.

| what | strategy | chosen? |
|---|---|---|
| `fold` over the log | **strict, incremental, per-envelope** | yes — the design |
| `ApplyProgram` | **strict, transactional, all-or-nothing**, working-state clone + `evaluateInPlace` | yes — the design |
| derived structural indexes | **incremental**, maintained by `fold` on ADD/LINK/UNLINK | yes |
| HDC live index | **eager, total, synchronous, on the write lock** | **no — inherited** |
| `logIntegrity` | **replay-time snapshot, frozen** | yes, and the field comment argues it well |
| replay | **strict, prospective-only** (`fold.Replay` skips the liveness gates) | yes |

The odd row out is the one costing 3 GB. The three alternatives, ordered by cost:

1. **Lazy / on-read.** Compute on `GET /hdc` instead of on write. Cheapest possible change; makes reads slow and unpredictable; correct if nobody reads it often. Loses the drift-claim emission, which is a *write* (see 3 below).
2. **Async, off-lock.** Recompute on a goroutine from a state snapshot, publish when done. Preserves drift claims; introduces a staleness window — which is *already the semantics*, since the index is S4-non-authoritative by register. **This is the smallest correct change.**
3. **Incremental (`affected()`-scoped).** §4b. Strictly best, needs the invalidation walk written and a CI-2-shaped test that "update from delta == recompute from state."

One subtlety worth recording because it is the reason this was never just moved: `runHDCIndexAndDriftLocked` does not only *compute* — it **emits** WF-tagged drift claims back into the graph via `applyReactiveLocked`. So it is a read-projection that writes. That is a genuine reactive loop (watcher → proposed rewrite), and it belongs on the sweep/reactive path (`reactive.Engine` is explicitly read-only and returns *proposed* envelopes for the normal `ApplyProgram` route) — not inline in `Apply`. **The architecture for doing this correctly already exists in the tree and this one caller bypasses it.**

---

## §6 Ruling on the t274 bufferization conjecture

> *"whether 'memory-allocation projections' means bufferization is open — the correspondence is real only if workspace projections decide materialization sharing vs copy; otherwise the honest analog is plain lowering plus DLTI layout attributes."*

**Ruling R3: the conjecture is refuted as stated, and the thing it was reaching for is real, better-shaped, and already half-built. Bufferization is the wrong analog; liveness analysis is the right one.**

**Why the stated form fails, measured.** Bufferization converts value-semantics ops into memory-semantics ops, deciding alias-vs-copy inside one compilation. The predicate was *"workspace projections decide materialization sharing vs copy."* They do not, and cannot:

- **MEASURED:** no `session`/`workspace`, `purpose`, or `manifold` type carries any layout, sharing, residency, or materialization property. The only substrate-shaped properties in the whole ontology are `compute.capacity` (`type: object`, `authority_scope: substrate`) and `harness.resource_bounds` (`type: object`, noted verbatim *"CPU/RAM/GPU/timeout bounds. Optional. **Enforcement out of scope for v3.9**"*). Both are free-form objects with no consumer.
- **MEASURED:** neither type is instantiated by the runtime (§0.1).
- A workspace projects *meaning to a surface*. Nothing in the F-lane touches the fold's storage layout. There is no arrow from workspace to allocator to be natural over.

**And a real bufferization decision does exist — but it is inside the engine, not in a projection.** `EvaluateAt` = clone-then-mutate; `EvaluateProgramAt` = **one** clone at the transaction boundary then `evaluateInPlace` throughout. That is, exactly, a one-shot bufferize with a conservative copy at the function boundary and in-place ops within — and the `json:"-"` indexes rebuilt by `Rebuild()` are "materialize on demand." The engine already bufferizes; it just isn't spelled that way. Per **R1**, that is an F-projection concern, and the honest external form is the other half of the t274 sentence: **DLTI-shaped layout attributes on the target descriptor** (the moos-soom capability vector on `workstation`/`kernel`/`compute`), not a workspace decision.

**What survives, and it is the productive part.** The t274 addendum's convergence finding — *the operations slice (`capability.scope`, a legality set) and the wiring slice (`pins-urn` + `view_filter`) must join at the `purpose` node* — is a memory construct in disguise:

> **A purpose slice is a live-set. In a compiler, liveness is what an allocator consumes. So the correct reading of "memory-allocation projection" is: the purpose slice determines *which sub-HG a lowering must materialize*.**

That is scope-directed materialization — slicing + dead-code elimination feeding an arena — not bufferization. It is a better fit for what Sam described, it needs no new vocabulary, and it is **checkable today**: the fraction of the fold a purpose's slice actually reaches is a number anyone can measure against `/fold`, and it is the same number that would size an arena. The t274 spine already seats the engine as *"context (uniquing arena owning loaded dialects)"* — an arena reading of the engine, with the purpose slice as its live-set, is coherent end to end.

**Net:** replace the marked conjecture with `purpose slice = liveness analysis; materialization = arena sizing over the slice`. Bufferization stays where it belongs — inside one engine's lowering, invisible to the HG.

---

## §7 Do concurrent processes travel? And can they travel into hardware?

### 7a. What travels today — enumerated, with what each one actually moves

| mechanism | what crosses the wire | is it process migration? |
|---|---|---|
| `twin_link` + `POST /twin/ingest` (§M9) | **envelopes** — re-applied via `ApplyProgram` at the receiver | **No.** Log replication. `sync_mode ∈ {eager, lazy, read-only}` with loop prevention by convention |
| `moos-router` (WF16) | read fan-out + write proxy; *"does NOT log rewrites, does NOT validate operads, does NOT enforce §M11/§M12"* | **No.** A switch, not a scheduler |
| `shard_rule` | URN prefix → kernel URL | **Placement, yes — but static and syntactic.** It places *names*, not running work |
| SSE `/fold` stream, subscriber channels | notifications | No |
| sweep goroutine | proposes WF13 governance envelopes on t_hook transitions | Concurrency *within* a kernel; nothing leaves |
| `L_p` (t265/t266) | rooms → nodes | Presentation placement (A3), explicitly not deployment (A2) |

> **Verdict: nothing that could be called a process travels. Rewrites travel. A rewrite is not a continuation, and replaying a log at a peer is replication, not migration.** The t265 axis ruling is the precise statement of why this keeps getting conflated: **A2 = deployment** (where an engine runs) and **A3 = presentation** (where a human sees it) were wearing one word, and it was A3 that got instantiated (14 rooms, t266) while A2 still has **0 instantiated nodes**.

### 7b. The grammar for travel exists, in full, unused

This is the finding that answers Sam's question, and it is the same shape as t265's:

| what would be needed | does the grammar have it? | instances |
|---|---|---:|
| name a compute substrate, typed cpu/gpu/cloud/docker | **yes** — `compute`, with `execution_model ∈ {sequential, concurrent, distributed}` | **0 minted by the runtime** |
| name durable storage | **yes** — `storage` (`git_repo`/`local_fs`/`rewrite_log`) | **0** |
| bind substrate to a machine | **yes** — WF04 `contains`, WF08 `bound-to` | **0** |
| **route a kernel's operations to a substrate** | **yes** — **WF09** *"Kernel routes operations to compute substrates"*, `computes-on`/`computed-by` | **0** |
| put the log on a named storage | **yes** — WF10 `persisted-in`/`persists` | **0** |
| name a running execution environment with resource bounds | **yes** — `harness` (`resource_bounds`: CPU/RAM/GPU/timeout) | ~1 referenced in docs |
| name a process as a first-class object | **yes** — `workflow`: *"Executable process template — DAG-shaped composition of rewrite steps... a first-class reified process that a session can instantiate"* | — |
| **wire that process to anything** | **NO** | — |

That last row is a hard structural stop and it is **MEASURED**: **all 12 `s1_grammar` types carry properties and no `ports` block at all** — `workflow`, `runtime`, `shard_rule`, `router`, `pattern`, `language`, `protocol`, `package`, `network_endpoint`, `skill`, `grammar_fragment`, `stratum`. By contrast **39/39 `s2_infrastructure` types have ports.** A node with no ports cannot be the endpoint of a LINK. So the one type that reifies a process **cannot participate in topology** — it can be ADDed and MUTATEd and never wired to a harness, a compute, or a kernel.

Separately **MEASURED:** `harness`'s declared out-port **`hosts-agent` appears in zero WF port-pair declarations** — it is declared on the type and admitted by no rewrite category, so it is un-LINKable too (§9 D5).

> **So: "is there an evolution by which concurrent processes travel?" — Grammatically, four fifths of it is already written and ratified. Empirically, none of it has ever been instantiated, and the one missing fifth (ports on `workflow`) is what would let a process be *placed* rather than merely *named*.** That is not a research question. It is a minting question plus one small grammar fragment.

### 7c. "…perhaps even into hardware?" — the honest ladder, and where it actually starts

The t244 lowering ladder is the right frame: `HG → moos IR → per-concern dialect → target → machine code`, with the t274 ruling that **languages are targets, plural, chosen per lowering**. Under that frame "travelling into hardware" means: a lowering selects a target descriptor, and the sub-HG the purpose slice marks live gets materialized there. §6 says the descriptor is DLTI-shaped and lives on `workstation`/`kernel`/`compute` — where `arch`, `kind`, and `capacity` already sit.

Two things make this concrete rather than aspirational, and they converge:

1. **The ontology already assigns the GPU a job.** `compute`'s own description: *"**CPU: sequential kernel spine. GPU: concurrent subgraph partitions as hypervector operations.**"* And `Stratum` S3 is defined as *"Evaluated — concurrent subgraph eval, hypervector encoding."* The GPU's role was specified years of rounds ago, and it is *exactly* HDC.
2. **The only workload in the entire repo with accelerator-shaped arithmetic is the same one burning the memory.** `internal/hdc` is the sole compute kernel — fixed-shape elementwise ops and reductions over `[10000]f32`. **MEASURED: zero `gpu`/`cuda`/`simd`/`avx` occurrences anywhere in the non-test tree.**

> **The punchline: memory pressure and hardware travel converge on one object.** The thing that would travel first is HDC encode; the thing eating all the memory is HDC encode; the stratum that says "this is the concurrent/GPU tier" is the stratum HDC lives in. There is exactly one place to start and the measurement and the doctrine agree on it.

**But R2 applies with force.** §4d's ladder says the current shape is ~10²–10³× off its own algorithmic optimum, and §2a says the workload is bandwidth-bound at 0.083 flop/byte. A bandwidth-bound kernel does port well to HBM (~3 TB/s vs ~18 GB/s measured ≈ 170× on paper) — but only if the data *stays resident*, because PCIe (16–64 GB/s) is about one DRAM's worth of bandwidth, and this index is recomputed per rewrite from a state that lives on the CPU. **PROJECTED:** at the live fold shape, per-rewrite transfer of ~106 MB (post-batch-fix) over PCIe at 32 GB/s is ~3 ms — which is fine, and is also *slower than just doing the incremental update on the CPU* (§4b, ~30 KB). **A GPU lane is justified when the fold is large enough that even the incremental slice is wide — not at 313 nodes.**

The first honest step is therefore not a GPU. It is **minting the substrate objects so the question becomes measurable at all** — precisely t265's lesson: nothing could be said about placement until the 14 room objects existed. Today `compute:hp-z440.gpu` does not exist, so "does work run on the GPU" is not a false statement in the fold; it is an unaskable one.

---

## §8 Conjecture ledger

**Checkable today** — reproducible from this tree plus `go test -bench=SpikeA -benchmem`: capacity formula `300×(6+1+600)×40,000 = 7,284,000,000` vs measured `7,286,361,656` (Δ 0.032%) · per-node vs batch **4.79× time / 49.4× allocation** · 32-step program allocates 1.03× a single clone (N+1 clone closed) · codebook cold/warm 20.4×, warm 0 B/0 allocs · `Bind` 6,797 ns, 0 B → **17.65 GB/s, 1.47 GFLOP/s, 0.083 flop/byte** · `HV` = 40,000 B, `Bind` working set 120 KB > any L1d · **1** node-deletion site in the non-test tree (`delete(state.Relations, …)`), **0** for `Nodes` · log ≈ 308 B/rewrite · seeder mints 3 node types + WF01 + WF03, **0** compute/storage/WF04/WF08/WF09/WF10 · **0/12** `s1_grammar` types have ports, **39/39** `s2_infrastructure` do · `hosts-agent` in **0** WF pair declarations · **0** `gpu`/`cuda`/`simd`/`avx` occurrences · HDC recompute **1× per apply-call**, 2× when drift fires · `P_search_rank` registered **lossy** in `ci2_projection_registry`.

**Projected from measured constants onto the t266 fold (313 nodes · 229 relations)** — falsifiable by re-running against `:8000`: 2.955 GB and ~0.57 s per `Recompute` · 27.9× over-provision · ~106 MB post-batch-fix · ~3.3 MB post-bitpacking · ~10–30 KB post-incremental.

| claim | status |
|---|---|
| "memory-allocation projections" = bufferization (t274 marked conjecture) | **REFUTED AS STATED** — no workspace/purpose/manifold type carries any materialization property, and none is instantiated; the real bufferize decision is inside the engine (clone-then-`evaluateInPlace`). §6 |
| The productive replacement: **purpose slice = liveness analysis; materialization = arena sizing over the slice** | **NEW CONJECTURE, and checkable** — the slice's reach against `/fold` is a number, and it is the same number that sizes an arena |
| Nodes are cartesian, relations affine, in the rewrite calculus | **READING, not theorem** — grounded in the measured single deletion site; a substructural formalization is not attempted here |
| S0–S4 is a memory hierarchy | **REJECTED** — it is a provenance filtration. The genuine cache-coherence artifact is `s4_cache_contract` (4 caches, per-WF invalidation triggers) |
| HDC live index belongs on the write path | **REFUTED BY THE PROJECT'S OWN REGISTER** — `P_search_rank` is lossy → S4 display only → not authority (§0.3) |
| Concurrent processes travel in the distributed HG today | **NO** — replication and static name-sharding only; `workflow` has no ports, so a process cannot be placed (§7b) |
| The grammar for hardware travel is missing | **REFUTED** — WF04/WF08/WF09/WF10 + `compute`/`storage`/`harness` are ratified; instances are 0 |
| A GPU lane is justified at the current fold shape | **NO (PROJECTED)** — bandwidth-bound and ~10²–10³× off its algorithmic optimum; PCIe round-trip exceeds the incremental CPU update. Reopens when the incremental slice itself is wide |
| Bitpacked bipolar HV is 32× smaller with `Bind` = XOR | **PROJECTED** — derived from `Encode` producing ±1 and `Bind` being elementwise multiply (closed on {−1,+1}); no packed implementation exists to measure |

---

## §9 Defects recorded (none fixed this round)

| # | defect | measured impact |
|---|---|---|
| **D1** | `encode.go:68` sizes the per-node scratch slice by `len(state.Relations)` instead of incident count | **99.97% of all engine allocation**; 27.9× over-provision at live shape; 49.4× measured at bench shape |
| **D2** | The write path uses `EncodeNode` while the correct batch path `EncodeNodes` sits in the tree, used only by `fiber.go`/`crosswalk.go` | 4.79× time, 49.4× allocation, **zero new code** |
| **D3** | The HDC live index is a cache that is **not in `s4_cache_contract`** and has no invalidation trigger — it is recomputed totally instead | the whole of §3 |
| **D4** | A projection registered **lossy / non-authoritative** (`P_search_rank`) executes synchronously in the S2 authority path, on the global write lock, and **emits rewrites** from there (`applyReactiveLocked`), bypassing the read-only `reactive.Engine` route that exists for exactly this | stratum violation; ~0.57 s/rewrite lock hold (PROJECTED) |
| **D5** | `harness.hosts-agent` is declared on the type and appears in **0** WF port-pair declarations — un-LINKable | §M20 `mounts-tool` grounding is blocked |
| **D6** | **All 12 `s1_grammar` types have no `ports` block**, including `workflow` — the only reified process template. A process can be named and never placed | blocks every placement/travel claim in §7 |
| **D7** | `compute`/`storage` and WF04/WF08/WF09/WF10 are ratified with **0** runtime instances; the only artifact minting them (`kb/superset/instances/seed.json`) is read by one scratch script and never by the kernel | the A2 deployment axis remains unmeasurable |
| **D8** | No log compaction / snapshot path exists, and `|Nodes|` is monotone by construction — the graph has `malloc` and no `free` | not urgent at log 669; a real decision before it is 10⁶ |
| **D9** | `harness.resource_bounds` and `compute.capacity` are free-form `type: object` with *"enforcement out of scope"* and no consumer — the only two places bytes could be declared | R1's designated home is a hole |

*(Recording, not fixing — t265 house rule. Nothing above has been applied. D1/D2/D4 are already licensed as "Go hygiene fixes on their own merits" by `DECISION-engine-language.md` §2; they are still Sam's call to schedule.)*

---

## §10 Smallest acts that move a number

Ordered by benefit/cost. **Recommendations only — none applied.** Nothing enters this list without the number it moves.

| # | act | moves | licensed by |
|---|---|---|---|
| 1 | In `spectral.go:406 embeddingsFromState`, call `enc.EncodeNodes(state, urns)` instead of per-node `EncodeNode` | **49.4× allocation, 4.79× time** (MEASURED); 2.955 GB → ~106 MB at live shape | `DECISION` §2 hygiene, explicitly named |
| 2 | Fix `encode.go:68` capacity to the incident count (makes the per-node path safe for its remaining callers too) | removes D1 at the source | same |
| 3 | Move `runHDCIndexAndDriftLocked` off the write lock: snapshot + async recompute, drift claims proposed through the normal `reactive` → `ApplyProgram` route | ~0.57 s → ~0 lock hold (PROJECTED); closes **D4**, the stratum violation | `ci2_projection_registry` (its own register) |
| 4 | Register the HDC index in `s4_cache_contract` with an explicit invalidation trigger | closes **D3**; makes step 5 a spec-conformance task instead of an optimization | ontology edit, Sam-gated |
| 5 | Incremental update scoped by `affected()` (CI-1's set), with a CI-2-shaped test: *update-from-delta == recompute-from-state* | ~10²–10³× on top of #1 (PROJECTED) | CI-1 + CI-2 already in the ontology |
| 6 | Mint `compute:hp-z440.{cpu,gpu}` + `storage:hp-z440.rewrite-log` + WF04/WF08/WF09/WF10 LINKs on one box | A2 deployment axis: **0 → first instances**; makes every §7 claim measurable instead of arguable | grammar already ratified — **no ontology bump** |
| 7 | Bitpack the codebook + `Bind` to `[157]uint64` (XOR), int16 accumulators in `Bundle` | 32× (PROJECTED); moves the hot set into L1 | pure engine change, no grammar |
| 8 | Grammar fragment (t231 style): give `workflow` a `ports` block so a process can be LINKed to `harness`/`compute`; fix `harness.hosts-agent`'s missing WF pair | closes **D6**/**D5** — the precondition for any migration claim | fragment, Sam-gated |
| 9 | **Only then** ask the GPU question, with #1–#7 done and a fold large enough that the incremental slice is still wide | — | R2 |

Explicitly **not** on this list: any GPU/CUDA lane now; any language port (the `DECISION` stands — Go is oracle and running engine); log compaction; reifying D8-placement; adding memory vocabulary to the operad (**R1** forbids it).

---

## §11 One-paragraph answer to the question as asked

Memory is not a semantic object in mo:os and should never become one — the four-rewrite calculus is resource-blind by construction, so bytes belong to the F-projection and its target descriptor (**R1**). What the system *does* have is two memories: an append-only log that only ADD/LINK allocate into and that nothing ever frees, and a derived in-process fold that is cloned per apply and rebuilt from the log at boot. Nodes are cartesian and never die; relations are affine and die exactly once, at the single `delete` site in the tree. The FP shape — value semantics, catamorphism, structural sharing — is what makes rollback free and what makes `Clone()` the visible cost, but the visible cost is not the real one: **the real one is that `fold` is incremental while everything derived from it is recomputed totally**, and the biggest such projection recomputes ~3 GB per rewrite on the global write lock to maintain an index the ontology itself classifies as non-authoritative. The bufferization framing for "memory-allocation projections" does not survive contact with the data — no workspace or purpose carries a materialization property and none is instantiated — but the idea underneath it does, in a better form: **a purpose slice is a live-set, and a live-set is exactly what an allocator consumes**, so the honest construct is scope-directed materialization (slice + arena), with DLTI-shaped layout attributes on `workstation`/`kernel`/`compute`. And on travel: nothing that could be called a process travels today — rewrites replicate and names shard — but **the grammar for travelling into hardware is already ratified and completely empty** (WF04/WF08/WF09/WF10, `compute` typed cpu/gpu/cloud/docker, `harness` with resource bounds), and the one gap is that `workflow`, the sole reified process, has no ports and therefore cannot be placed. The evolution Sam is asking about has exactly one starting point, and the measurement and the doctrine agree on it: HDC encode is simultaneously the only accelerator-shaped workload in the repo, the source of essentially all its memory traffic, and the workload the S3 stratum was *defined* to describe. Fix the `make()` first; mint the substrate objects second; ask the GPU third.

---

## Reproduce every number

```bash
# in moos-kernel/
go test -bench=SpikeA -benchmem -benchtime=1x ./internal/fold/ ./internal/hdc/
```
Static facts (deletion sites, port coverage, seeder contents, WF pair declarations, gpu/simd occurrences) are greps over `moos-kernel@f12cb1b` and `ffs0/kb/superset/ontology.json` **v4.0.6 · t_day 280**. Fold-shape projections use the last measured live shape of record — **Z440, ontology 4.0.4 · t_day 266 · log 669/669 · 313 nodes · 229 relations** (t265 note §11) — and will move on a grown fold; the ratios are the claim, not the absolute counts.

---
authored-by: agent:claude-code.remote / session:none-ungoverned-remote-s0 / t281-memory-allocation-and-travel
