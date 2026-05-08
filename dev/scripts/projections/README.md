# Projection Scripts

This folder holds orchestration entrypoints for local projection lanes. The Julia adapters still live one level up for compatibility with existing calls and tests.

## Session Pipeline

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File dev\scripts\projections\run-session-pipeline.ps1
```

The runner regenerates the current Keep-note/session/visual lane:

1. Session context pack.
2. Graph artifact engineering report.
3. Session-occasion DOT/SVG visual lens.
4. MVP gate JSON/Markdown and `tmp/projections/session_pipeline/index.html`.

It is dry: it reads the folded HG state and writes local artifacts, but does not emit rewrites or call external writers.