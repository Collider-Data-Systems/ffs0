# ComfyUI on Z440 (image/video generation) — runbook

Set up T235 for local diffusion generation, paired with the Ollama vision presets (`vision-presets/`).
The VLM reads images; **ComfyUI generates** them. Lives on **D:** (C: is full).

## What's installed
- **ComfyUI portable** (NVIDIA, v0.26.0) at `D:\ComfyUI_windows_portable\` — bundles its own
  Python + `torch 2.12.0+cu130`. Sees the RTX 3060 (12 GB).
- **Checkpoint:** `Illustrious-XL-v1.0.safetensors` (SDXL/Illustrious, uncensored-capable) in
  `…\ComfyUI\models\checkpoints\`. First image verified: 1024² in ~28 s (~1.4 it/s, 28 steps).
- App wiring: `locally-uncensored/.env` → `COMFYUI_PATH=D:\ComfyUI_windows_portable`.

## Start / stop
- **Start:** double-click `D:\ComfyUI_windows_portable\run_nvidia_gpu.bat`
  (or: `D:\ComfyUI_windows_portable\python_embeded\python.exe -s D:\ComfyUI_windows_portable\ComfyUI\main.py --port 8188`).
- **Use:** browser → **http://127.0.0.1:8188** (full node UI; default template = txt2img, type a prompt → Queue).
- Not autostarted on boot — start it when you want to generate. (Ask Cowork to add a logon task if wanted.)

## Add more models
- Drop any single-file SDXL/Pony/Illustrious `.safetensors` into `…\ComfyUI\models\checkpoints\`
  (diffusers-split repos like `John6666/*` do NOT work — need a single-file checkpoint).
- Or use the `locally-uncensored` app's Create tab (Civitai / HF downloader).

## Prompting Illustrious (SDXL)
- Lead with quality tags: `masterpiece, best quality, very aesthetic, …`; danbooru-style tags work best.
- `cfg 4–6`, `steps 24–30`, sampler `euler_ancestral`/`euler`, 1024×1024 (or 832×1216 portrait).

## Next level — Flux (better fidelity) + video (when wanted)
Needs the GGUF loader node:
```
cd D:\ComfyUI_windows_portable\ComfyUI\custom_nodes
git clone https://github.com/city96/ComfyUI-GGUF
D:\ComfyUI_windows_portable\python_embeded\python.exe -m pip install -r ComfyUI-GGUF\requirements.txt
```
- **Flux image (12 GB):** `city96/FLUX.1-dev-gguf` `Q4_K_S` (6.8 GB) → `models\unet\`; + `t5xxl_fp8`, `clip_l` → `models\clip\`; Flux `ae.safetensors` → `models\vae\`. ~40–90 s/image.
- **Video (12 GB):** `QuantStack/Wan2.2-TI2V-5B-GGUF` `Q5_K_M` (3.8 GB) + ComfyUI-WanVideoWrapper + VideoHelperSuite nodes; ~5 s clips at 480–720p. `LTX-Video` distilled = fastest.
- (Ask Cowork to wire either — multi-GB pulls, D: has the room.)

## Disk
Everything on **D:** (`D:\ComfyUI_windows_portable\…`). D: had ~31 GB free after setup.
Models are the space cost: SDXL ~7 GB each, Flux+encoders ~12 GB, Wan video ~5 GB.
