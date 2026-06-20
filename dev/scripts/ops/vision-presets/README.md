# Local vision-model presets (Qwen2.5-VL abliterated, Ollama)

Vision presets for the Z440 RTX 3060 (12 GB). All wrap the same base model
(`hf.co/mradermacher/Qwen2.5-VL-7B-Abliterated-Caption-it-GGUF:Q4_K_M`, ~6 GB) — `ollama create`
layers a system-prompt/params on top, so each preset costs ~0 extra disk.

```
ollama create moos-vision      -f moos-vision.Modelfile
ollama create moos-ocr         -f moos-ocr.Modelfile
ollama create moos-vision-json -f moos-vision-json.Modelfile
ollama create moos-vision-code -f moos-vision-code.Modelfile
# moos-diary-vision lives one dir up (../moos-diary-vision.Modelfile)
```

| Preset | Use | temp | num_ctx |
|---|---|---|---|
| `moos-vision` | general uncensored vision Q&A / description | 0.5 | 8192 |
| `moos-ocr` | verbatim text/doc transcription (tables→markdown) | 0 | 16384 |
| `moos-vision-json` | image → structured JSON (pair with request `"format":"json"`) | 0 | 8192 |
| `moos-vision-code` | screenshot/diagram/error → code or explanation | 0.3 | 8192 |
| `moos-diary-vision` | family/diary caption (people/setting/occasion/mood/OCR) | 0.2 | — |

## What the model is
**VLM: image(s)-in → text-out.** Does: VQA, OCR (OCRBench 864), document/table/form parsing,
multi-image compare, bbox grounding + pointing (JSON), chart/diagram reading, GUI/agentic grounding.
**Does NOT generate** images/video/audio, and takes no audio input. (Generation = ComfyUI; see below.)

## Use it from
- **Ollama CLI:** `ollama run moos-vision` then drop image path(s) in the prompt.
- **The `locally-uncensored` app** (best for daily use): chat + image attach + model picker + a
  Create tab for *generation* (ComfyUI).
- **API:** `POST http://localhost:11434/api/chat` with `"images": ["<base64>", ...]` (multi-image
  supported; strip any `data:image/...;base64,` prefix). `/v1` is OpenAI-compatible.

## Settings that matter (override per request via `options`)
- `num_ctx` — **Ollama defaults to 4096; always raise it.** 8192 (1 image) → ~16–24k (multi-image).
  Each image is hundreds–thousands of tokens. `OLLAMA_KV_CACHE_TYPE=q8_0` ~doubles usable context.
- `temperature` — 0 for OCR/grounding/JSON, 0.3–0.5 general, 0.6–0.7 dense captions.
- `top_k` 20 (extraction) / 40 (general); `repeat_penalty` ~1.0 for OCR (don't corrupt repeated digits/cells).
- Request `"format":"json"` (or a JSON schema) forces valid JSON — use for grounding/extraction, not prose.

## Caption variant vs Instruct abliterated
These presets sit on the **caption-tuned** variant (already pulled). For the best *general-purpose*
daily driver — multi-turn, grounding, agentic, crisp JSON — the **Instruct abliterated** variant
[`huihui-ai/Qwen2.5-VL-7B-Instruct-abliterated`](https://hf.co/huihui-ai/Qwen2.5-VL-7B-Instruct-abliterated)
is better (caption variant over-describes + is weak at structured/agentic output). Swap the `FROM`
line to rebuild any preset on it. Abliteration removes refusals; expect mild extra hallucination — verify factual OCR.

## Generating pictures / video (separate stack)
The VLM can't. Use **ComfyUI** (the `locally-uncensored` app already integrates it — Create tab +
installer + HF/Civitai downloaders). **⚠ Install ComfyUI + models on `D:` — C: has ~16 GB free and the
stack is ~27 GB.** 12 GB starter pack: image = an **Illustrious/NoobAI SDXL** NSFW merge (3–6 s/img) or
**Flux.1-dev GGUF Q4_K_S** (quality, slower); video = **Wan2.2 TI2V-5B GGUF Q5_K_M** (best 12 GB pick) or
**LTX-Video distilled** (fastest). Full detail: ask Cowork or see the T231 gen-stack notes.
