# Projection Scripts

This folder holds orchestration entrypoints for local projection lanes. The Julia adapters still live one level up for compatibility with existing calls and tests.

## Session Pipeline

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File dev\scripts\projections\run-session-pipeline.ps1
```

The runner regenerates the current Keep-note/session/visual/Calendar/recommendation lane:

1. Session context pack.
2. Graph artifact engineering report.
3. Session-occasion DOT/SVG visual lens.
4. Temporal/calendar DOT/SVG visual lens.
5. Calendar time-fabric JSON/Markdown projection plan.
6. T189/T200 recommendation HG JSON/Markdown projection plan.
7. T189 recommendation reconciliation JSON/Markdown.
8. First MVP gate pass, so the atlas can cite the gate result.
9. Surface context atlas JSON/Markdown.
10. Final MVP gate JSON/Markdown and `tmp/projections/session_pipeline/index.html`, regenerated with atlas links.

It is dry: it reads the folded HG state and writes local artifacts, but does not emit rewrites or call external writers. The Calendar plan is writer-compatible, but real Google Calendar writes remain an explicit actuator step through `google_calendar_writer.jl`. The recommendation plan is also dry: it proposes candidate HG nodes/relations, while reconciliation says what is already applied, pending, or deferred in folded state. The atlas is explanatory glue for the operator and agents: JSON/JSONL/Git/Calendar/dashboard/visual/type surfaces are presented together with their trust boundaries and pending HG moves.
