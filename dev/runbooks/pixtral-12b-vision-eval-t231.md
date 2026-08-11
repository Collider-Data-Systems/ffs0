# Pixtral 12B (+ uncensored fine-tunes) as multimodal-ingest vision backbone — survey

> **T=231 (2026-06-20)** · read-only evaluation · `apply_ready=false`
> Lane: `moos-multimodal-ingest` / `session:sam.moos-diary` / `kernel:hp-z440.primary` · GitHub `ffs0#72`
> Target box (Z440): NVIDIA RTX 3060 **12 GB VRAM**, driver 595.97; Ollama 0.30.10 installed (`bakllava` present); Node/WebView2 present; rustup + MSVC build tools NOT installed.
> **No serving change is authorized by this survey.** This is prose/design only — survey + recommendation. No installs, no download, no kernel rewrite.

---

## TL;DR recommendation

**Pixtral-12B is NOT the right primary pick at 12 GB.** It fits only with aggressive quantization and a fragile Ollama-patched vision path, and — critically — **there is no real "abliterated" or "Dolphin" Pixtral fine-tune in existence** (the #72 premise is mistaken on that point; see §2). The de-censoring path for Pixtral is a *captioner* fine-tune, not an abliteration.

- **Primary (recommend):** **`huihui-ai/Qwen2.5-VL-7B-Instruct-abliterated`** served via **Ollama** (native `qwen2.5vl` engine, no mmproj hack) at **Q4_K_M / Q5_K_M GGUF**. Genuinely abliterated, first-class Ollama vision support, multi-image, 125–128k context, best OCR in class, fits 12 GB with comfortable KV headroom. For pure caption/OCR-of-diary-photos, the task-specialized **`prithivMLmods/Qwen2.5-VL-7B-Abliterated-Caption-it`** (GGUF via `mradermacher`/`fairy322`) is the sharper tool.
- **Fallback / if Pixtral is mandated:** **`Ertugrul/Pixtral-12B-Captioner-Relaxed`** (de-censored captioner, the canonical one — 4K downloads) served as GGUF via the **`EnlistedGhost/Pixtral-12B-Ollama-GGUF`** bundle (mmproj baked in) at **Q4_K_M (7.48 GB weights + 0.87 GB mmproj)**. Works, but tighter on VRAM and a community-patched path.
- **Use:** caption/OCR of diary photos → `knowledge_item` nodes per `moos-multimodal-ingest`. Nothing here is `apply_ready`; no diary-lane ADD/LINK until a reviewed payload is approved by Sam.

---

## 1. Pixtral 12B — verifying the #72 claims

Official: **`mistralai/Pixtral-12B-2409`** ([HF](https://huggingface.co/mistralai/Pixtral-12B-2409)) · base **`mistralai/Pixtral-12B-Base-2409`** ([HF](https://huggingface.co/mistralai/Pixtral-12B-Base-2409)) · transformers/LLaVA-arch port **`mistral-community/pixtral-12b`** ([HF](https://huggingface.co/mistral-community/pixtral-12b), 1.8M downloads, now under `mistral-experimental/`). Paper: [arXiv:2410.07073](https://arxiv.org/pdf/2410.07073).

| #72 claim | Verdict | Detail |
|---|---|---|
| Multi-image input at raw resolution | **TRUE** | Vision encoder uses relative **RoPE** in self-attention → variable image sizes; ingests images at native resolution/aspect ratio; multiple images per request. ([Mistral news](https://mistral.ai/news/pixtral-12b/), paper §arch) |
| 128k context window | **TRUE** | 128K tokens; ~50–100 images depending on resolution; each image ≈ 500–2000 tokens. ([Vercel specs](https://vercel.com/ai-gateway/models/pixtral-12b)) |
| Architecture: vision encoder + Mistral-Nemo 12B | **TRUE** | ~**400M** vision encoder + **12B** multimodal transformer decoder (Mistral-Nemo lineage). Total ≈ 12.68B params. ([HF repo details]) |
| License | **Apache-2.0** | Permissive — fine for the sovereign-KB lane. (Note: *Pixtral-Large* is `license:other`, non-commercial — irrelevant here.) |
| "Less aggressive hardcoding" / low refusal | **PARTLY TRUE** | Mistral's own card: *"the Pixtral model does not have any moderation mechanisms."* So the **base instruct model is already lightly-aligned** — a major reason a separate abliteration barely exists (nobody needed one). |
| MMMU reasoning | 52.5% — surpasses several larger models. ([UC Strategies](https://ucstrategies.com/news/pixtral-12b-specs-benchmarks-how-to-deploy-mistrals-vision-model-2026/)) |

---

## 2. "Uncensored / abliterated" Pixtral fine-tunes — what actually exists

**Finding: there is NO genuine abliterated (refusal-orthogonalized) or "Dolphin" Pixtral 12B on HF.** Searches for `Pixtral abliterated` / `Pixtral uncensored` / `Pixtral amoral` return **zero** matching repos. The #72 expectation ("seek out an abliterated or Dolphin-style Pixtral") **cannot be satisfied** — that artifact does not exist as of T=231. What exists instead:

| Repo | Type | What it does | Downloads / quant |
|---|---|---|---|
| [`Ertugrul/Pixtral-12B-Captioner-Relaxed`](https://huggingface.co/Ertugrul/Pixtral-12B-Captioner-Relaxed) | instruction fine-tune | **Canonical "relaxed" captioner** — detailed, less-restricted natural-language captions; the de-facto de-censored Pixtral for captioning | 4.0K dl, 30 likes; safetensors (fp16) |
| [`unalignment/Pixtral-12B-Captioner-Relaxed`](https://huggingface.co/unalignment/Pixtral-12B-Captioner-Relaxed) | mirror/variant | Same relaxed captioner under the `unalignment` org | 495 dl |
| [`Hyphonical/...-Captioner-Relaxed-Q4_K_M-GGUF`](https://huggingface.co/Hyphonical/Pixtral-12B-Captioner-Relaxed-Q4_K_M-GGUF) · [`noctrex/...-Captioner-Relaxed-GGUF`](https://huggingface.co/noctrex/Pixtral-12B-Captioner-Relaxed-GGUF) | quant | **GGUF** of the relaxed captioner (Q4_K_M etc.) | runnable in llama.cpp |
| [`mrcuddle/Lumimaid-v0.2-12B-Pixtral`](https://huggingface.co/mrcuddle/Lumimaid-v0.2-12B-Pixtral) | NSFW RP merge | Pixtral vision head on NeverSleep **Lumimaid** (uncensored RP LM); GGUF via [`Koitenshin/...-GGUF`](https://huggingface.co/Koitenshin/Lumimaid_VISION-v0.2-12B-Pixtral-GGUF) | small audience; RP-tuned, not ingest-tuned |

**Conjecture:** the relaxed captioner ≈ "uncensored-enough" for benign personal/diary imagery (its whole point is dropping refusal/hedging on image description). It is *not* a true abliteration and its behavior on edge content is uncharacterized. Treat the "uninhibited visual agent" framing in #72 as **not literally available for Pixtral** — the nearest substitute is the relaxed captioner, and a genuinely abliterated VLM only exists in the **Qwen2.5-VL / Llama-3.2-Vision** families (§4).

**Plain Pixtral GGUF / quant availability** (for completeness): `bartowski/mistral-community_pixtral-12b-GGUF`, `ggml-org/pixtral-12b-GGUF`, `mradermacher/pixtral-12b(-i1)-GGUF`, `lmstudio-community/pixtral-12b-GGUF`; 4-bit `SeanScripts/pixtral-12b-nf4`, `unsloth/Pixtral-12B-2409-(unsloth-)bnb-4bit`; FP8 `RedHatAI/pixtral-12b-FP8-dynamic`; INT4 `RedHatAI/pixtral-12b-quantized.w4a16` (vLLM); 8-bit/4-bit MLX. **Ollama-ready (mmproj bundled):** [`EnlistedGhost/Pixtral-12B-Ollama-GGUF`](https://huggingface.co/EnlistedGhost/Pixtral-12B-Ollama-GGUF).

---

## 3. Runtime fit on 12 GB VRAM

### Quant / size table (Pixtral 12B GGUF, from `EnlistedGhost` card)
| Quant | Weights | + mmproj (vision) | Effective load |
|---|---|---|---|
| Q4_K_S | 7.12 GB | +0.87 GB (F16) / +0.47 GB (Q8) | ~7.6–8.0 GB |
| **Q4_K_M** | **7.48 GB** | **+0.87 GB** | **~8.3 GB** ← practical floor |
| Q5_K_M | 8.73 GB | +0.87 GB | ~9.6 GB |
| Q8_0 | 13.7 GB | — | **does not fit 12 GB** |
| F16 | 24.5 GB | — | no |

mmproj options: Q8_0 465 MB · F16 870 MB · F32 1.74 GB.

### Per-runtime verdict (12 GB RTX 3060)
- **Ollama (installed, 0.30.10):** No first-class Pixtral entry in the Ollama library. **Vanilla Ollama does not accept a separate mmproj file**, so plain Pixtral GGUFs won't do vision. The **community `EnlistedGhost` "Ollama-patched" build bundles the projector** and reportedly runs both text+vision with no config. Works, but unofficial. **Conjecture:** at Q4_K_M (~8.3 GB) you have ~3.5 GB for KV+overhead → fine for **short** multi-image ingest, **not** 128k.
- **llama.cpp / llama-server:** First-class Pixtral vision via `--mmproj` (see [llama.cpp multimodal docs](https://github.com/ggml-org/llama.cpp/blob/master/docs/multimodal.md)). Most flexible local path; Q4_K_M + F16 mmproj fits with room for moderate context.
- **vLLM:** **Does NOT fit 12 GB in any comfortable config.** vLLM wants **~24–25 GB** for Pixtral in bf16; FP8 (`RedHatAI/...-FP8-dynamic`) ~halves that to ~12–13 GB **before** KV/graph → still over budget on a 3060. INT4 `w4a16` is closer but vLLM's Pixtral quant path is rough ([vLLM #8566](https://github.com/vllm-project/vllm/issues/8566)). Best on a cloud/24 GB card, not Z440.
- **transformers (bnb 4-bit):** `SeanScripts/pixtral-12b-nf4` / `unsloth ...-bnb-4bit` load ~7–8 GB; usable for batch captioning, but needs Python/torch+CUDA stack (heavier than Ollama/llama.cpp). No rustup/MSVC needed; this path is Python, not Rust.

### Is 128k actually feasible on 12 GB? — **No.**
The 128k window is a *model* capability, not a 12 GB *runtime* capability. After ~8.3 GB weights+projector, the remaining ~3 GB of VRAM caps the KV cache to roughly **8k–16k tokens** at Q4 (order-of-magnitude; ~a handful of raw-res images, not 50–100). Diary ingest is bursty small batches (a few photos at a time), so this is acceptable — **but the "128k visual context in one pass" selling point is not realizable on the Z440 GPU.** ([RTX 3060 LLM guidance](https://knightli.com/en/2026/05/08/rtx-3060-local-llm-models/))

---

## 4. Alternatives that fit 12 GB better for uncensored vision ingest

| Model | Params | Best 12 GB quant | Multi-image | Context | OCR / caption | Uncensored availability | Ollama native |
|---|---|---|---|---|---|---|---|
| **Qwen2.5-VL-7B** ⭐ | 7B | Q4_K_M ≈ 6 GB | **Yes** | **125–128k** | **Best-in-class OCR**, multi-lang/orientation | **Genuine abliteration** + uncensored captioner (below) | **Yes** (`qwen2.5vl`) |
| Qwen2-VL-7B | 7B | Q4 ≈ 6 GB | Yes | 32k (ext.) | Strong | huihui abliterated exists | Yes (older engine) |
| Llama-3.2-11B-Vision | 11B | bnb-4bit ≈ 7–8 GB | **No (single image, mllama)** | 128k text | Good captions, weaker dense OCR | **Genuine abliteration** (huihui) | Yes |
| MiniCPM-V 2.6 | 8B | Q4_K_M ≈ 8.6 GB | Yes (+video) | ~32k | **SOTA OCRBench** (>GPT-4V/4o claim) | Weak (no strong abliteration) | Yes (`minicpm-v`) |
| InternVL2-8B | 8B | 4-bit ≈ 8–10 GB | Yes | ~16–32k | Strong | Weak | partial |
| **Pixtral-12B** | 12B+0.4B | Q4_K_M ≈ 8.3 GB | **Yes (raw-res)** | 128k (model) | Strong docs+natural | **No true abliteration** — relaxed captioner only | No (patched only) |
| bakllava (present) | 7B | already installed | No | 4k | Weak/legacy | n/a | Yes |

Sources: [Roboflow local VLMs](https://blog.roboflow.com/local-vision-language-models/), [Presenc 2026 VLM survey](https://presenc.ai/research/best-open-weight-vision-language-models-2026), [Qwen2.5-VL report arXiv:2502.13923](https://arxiv.org/abs/2502.13923), [Ollama multimodal engine](https://ollama.com/blog/multimodal-models), [`ollama.com/library/qwen2.5vl`](https://ollama.com/library/qwen2.5vl).

### The genuinely-uncensored vision options (real abliterations, with GGUF)
- **[`huihui-ai/Qwen2.5-VL-7B-Instruct-abliterated`](https://huggingface.co/huihui-ai/Qwen2.5-VL-7B-Instruct-abliterated)** — 130K dl, the canonical abliterated VLM. GGUF: [`mradermacher/...-GGUF`](https://huggingface.co/mradermacher/Qwen2.5-VL-7B-Instruct-abliterated-GGUF) + [`...-i1-GGUF`](https://huggingface.co/mradermacher/Qwen2.5-VL-7B-Instruct-abliterated-i1-GGUF), Q4_K_M [`decerto/...`](https://huggingface.co/decerto/Qwen2.5-VL-7B-Instruct-abliterated-Q4_K_M-GGUF), Q8 [`dthryjdrk/...`](https://huggingface.co/dthryjdrk/Qwen2.5-VL-7B-Instruct-abliterated-Q8_0-GGUF); EXL2 + NVFP4 also exist.
- **[`prithivMLmods/Qwen2.5-VL-7B-Abliterated-Caption-it`](https://huggingface.co/prithivMLmods/Qwen2.5-VL-7B-Abliterated-Caption-it)** — purpose-built **uncensored captioner** (the on-lane tool). GGUF: [`mradermacher/...-Caption-it-GGUF`](https://huggingface.co/mradermacher/Qwen2.5-VL-7B-Abliterated-Caption-it-GGUF) (7.5K dl), [`fairy322/...-i1-GGUF`](https://huggingface.co/fairy322/Qwen2.5-VL-7B-Abliterated-Caption-it-i1-GGUF).
- **[`shutkit/Qwen2.5-VL-7B-NSFW-Caption-V3-abliterated`](https://huggingface.co/shutkit/Qwen2.5-VL-7B-NSFW-Caption-V3-abliterated)** — strongest de-inhibition if benign-personal refusal is still an issue; `not-for-all-audiences`. GGUF via mradermacher.
- **[`huihui-ai/Llama-3.2-11B-Vision-Instruct-abliterated`](https://huggingface.co/huihui-ai/Llama-3.2-11B-Vision-Instruct-abliterated)** — real abliteration, GGUF ([`case01/...-gguf`](https://huggingface.co/case01/Llama-3.2-11B-Vision-Instruct-abliterated-gguf)) — but **single-image only** (mllama), which conflicts with the lane's multi-image-per-pass goal. Demote.

---

## 5. Recommendation for the moos-diary ingest lane

**Primary: `huihui-ai/Qwen2.5-VL-7B-Instruct-abliterated`, Q4_K_M (or Q5_K_M) GGUF, served via Ollama.**
Rationale, scored against the lane's actual needs (caption/OCR of diary photos → `knowledge_item`):
1. **Genuinely uncensored** (real abliteration) — directly satisfies the "won't over-refuse on benign personal/diary imagery" requirement that Pixtral can only *approximate* via a relaxed captioner.
2. **First-class Ollama vision** (`qwen2.5vl`, Ollama's flagship multimodal-engine model) — the box already runs Ollama 0.30.10 (≥0.7.0 floor satisfied), so **no mmproj patching, no new Rust/MSVC toolchain, no vLLM**. Lowest-friction wiring into the existing pipeline.
3. **Fits 12 GB with real headroom** (~6 GB weights at Q4_K_M → meaningful KV budget for multi-image batches), unlike Pixtral's ~8.3 GB floor.
4. **Multi-image + 125–128k context + best-in-class OCR** — matches every capability #72 wanted from Pixtral, on hardware that can actually serve it.
5. For pure captioning, swap to **`prithivMLmods/Qwen2.5-VL-7B-Abliterated-Caption-it`** (GGUF) — same base, tuned for dense uncensored captions.

**Fallback (if Pixtral specifically is mandated):** `Ertugrul/Pixtral-12B-Captioner-Relaxed` → run its GGUF via llama.cpp (`--mmproj`) or via the `EnlistedGhost` Ollama-patched bundle at Q4_K_M (~8.3 GB). Accept the tighter VRAM, the unofficial Ollama path, and that this is a *relaxed captioner*, not an abliteration.

**Explicit answer to #72:** Pixtral-12B is a fine model but **not the right pick at 12 GB**, and the specific artifact #72 asks for — an *abliterated / Dolphin Pixtral* — **does not exist**. The uncensored-vision-ingest goal is better served by the **Qwen2.5-VL-7B abliterated** family, which *does* exist as a true abliteration, fits the GPU with headroom, and is natively served by the already-installed Ollama.

### Ingest framing / boundaries
- Use: per `moos-multimodal-ingest`, the chosen VLM produces caption + OCR text for each diary photo, which becomes the semantic payload of a `knowledge_item` node (umbrella + per-artifact chunks, `composes`/`composed-by` LINKs, WF18) — **only when a reviewed payload is approved.**
- **`apply_ready=false`.** This survey authorizes **no** model download, **no** serving change, and **no** kernel rewrite. No diary-lane ADD/LINK, no MUTATE, no UNLINK until Sam approves a payload. No secrets/tokens touched.
- Next step (not done here): Sam's go to pull one GGUF and smoke-test caption/OCR quality on real diary photos before any HG wiring.

---
authored-by: agent:claude-cowork.hp-z440 / session:sam.z440-cowork-workspace / urn:moos:purpose:sam.mvp-sovereign-knowledge-os
