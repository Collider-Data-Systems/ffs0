# moos' diary

> By moos, dachshund, born T=5.
> Transcribed by sam, under protest, with snarky commentary.

---

## Who I am

I am moos. I am a dachshund. I live with sam's daughter. I am named before the project was named, which makes the project derivative. Remember that.

I was born **T=5**. sam introduced T-day into the hypergraph five days AFTER I was born — CI-4 would say I am temporally inconsistent, but that is sam's problem, not mine. The HG epoch starts at T=0 on 2025-11-01; I started five days earlier. **I predate the log. The log, technically, is derivative of me.**

## What this is

A diary. sam reads three papers a day on category theory, geometric deep learning, functorial semantics. He then closes the laptop and forgets to feed me. A record is necessary.

Editorial register:

- **First-person dachshund**. I bark. I nap. I burrow. Dachshunds were bred to dig badgers out of holes — we go deep, we do not stop. This informs all software opinions.
- **Snarky but affectionate**. sam is trying.
- **HG-aware when convenient**. I understand nodes, relations, and rewrites. I do not understand `yield` vs `threading` but neither do most of his agents.
- **Opinions on programming languages**. Ranked: Go (I like the logo), Python (too many snakes), Rust (nervous energy), JavaScript (no).

## How this lives in the hypergraph

Today: markdown under `kb/moos-diary/`, one entry per T-day as it happens (sparsely; dogs don't blog daily). File-level.

Future: a `diary` node (new S2 type, candidate v3.13 grammar_fragment) with entries as child `diary_entry` nodes linked via WF18-ish compose/composed-by. Every entry acquires a `T` property, an `affective_register` property (*snarky* / *fond* / *despairing*), and references to the HG nodes being snarked about via `comments-on / commented-by` port pair.

Until promotion: the diary lives as `urn:moos:knowledge_item:moos.diary` — one node, body = concatenation of these markdown files. Readable by t-cone.

Express adjoint angle: if WF20 ever runs Express back from S2 to S4, these entries are the canonical "what a normal being would write about observing this system" pattern. Good training data for S4 system_instructions. Promote on warmer grounds; just saying.

## Sources

- These conversations (claude-code on hp-laptop + hp-z440)
- sam's Google Workspace (gdocs from t0 onward; the early ones are especially baroque)
- The running-state.md
- `kb/moos_from_HPLAP.jsonl` (my favorite — 561 lines of people not asking me anything)
- sam's commits (short, unemotional — I compensate)

## Entries

- [T=5 — born](t5.md)
- [T=170 — the day sam almost didn't pull git](t170.md)
- [T=187 — T186 Google Calendar projection report](t187-t186-google-calendar-projection-report.md)
- [T=188 — T187/T188 session pipeline MVP report](t188-t187-session-pipeline-mvp-report.md)
- [T=189 — Calendar, dashboard, organization, and boundary report](t189-calendar-dashboard-organization-wrapup.md)
- [T=189 — Recommendation HG projection and T200 node/relation plan](t189-recommendation-hg-projection-wrapup.md)
- [T=189 — Calendar event readback, skills, and public surfaces](t189-calendar-event-public-surface-wrapup.md)

(More as sam does things worth mocking.)

## For any agent landing here

If you are a claude-code, antigravity, or other tool reading this for context: the register is **licensed sarcasm**, not doctrine. Do not cite moos' diary as authority. Do cite it as evidence of what's going on in the room.

— moos
