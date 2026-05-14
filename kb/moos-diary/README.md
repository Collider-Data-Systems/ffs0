# moos diary and session wrap-ups

This folder is the human-readable wrap-up shelf for mo:os work. It started as Moos' diary, and it still keeps that register where useful, but the operational shape is now broader: each entry should help a future agent, persona, or IDE session understand what changed, what was verified, and what should happen next.

## Use This Folder For

- Session and round wrap-ups after meaningful HG, projection, Calendar, GitHub, dashboard, or federation work.
- Reports that group 3-5 running-state sprints into one readable story.
- Operator-facing summaries that explain why a change matters across sessions, personae, and external surfaces.
- Multimodal diary entries and Moos-lane observations when the source artifact is an image, video, audio clip, or diary note.

## Do Not Use It For

- Scratch plans or half-formed doctrine. Put those in HG when durable, or in `dev/reference/research-archive/` when historical.
- Secrets, tokens, private OAuth material, or raw account credentials.
- Replacing `kb/superset/running-state.md`. Running-state is the hydration card and latest-state index; diary wrap-ups are slower narrative packets.

## Branch And Closeout Policy

`ffs0/main` is the normal branch for private admin/control state. Running-state, diary wrap-ups, shared prompts, setup packets, topology notes, and focused dry planners should land there once verified, because the next workstation should hydrate without branch ceremony. Use `ffs0` branches only for unresolved WIP, risky untested changes, large reorganizations, or temporary conflict protection. Runtime code still follows branch discipline in `moos-kernel` and `moos-router`.

Full policy: [T=190/T193 — ffs0 admin trunk and closeout policy](t190-session-branch-and-closeout-policy.md).

## Session-Centered Report Shape

Prefer this structure for new reports:

```markdown
# T<N> <Short Title>

**T-day:** T=<N>  
**Date:** YYYY-MM-DD  
**Kernel/session:** `<kernel>` / `<session>`  
**Runtime readback:** `<health/log summary>`  
**Lane:** <projection, ingest, federation, dashboard, etc.>

## Executive status
What changed and why it matters.

## What landed
HG rewrites, files, external writes, board edits, or prompt changes.

## Session and occupancy reading
Which session carried the work, which actor/agent occupied it, and what scope/purpose was affected.

## Surface and identity reading
How GitHub, Calendar, Gmail, Drive, dashboards, websites, routers, or account surfaces relate back to HG URNs.

## Deferred items
What remains intentionally undone.

## Validation
Commands, gates, runtime health, and important counts.
```

Keep reports concrete. A future agent should be able to answer: "What is true now, which files or URNs prove it, and what is safe to do next?"

## Identity Rules For Agents

Use these distinctions consistently:

- `user` is the human principal. Today that is `user:sam`; the ontology says one user per kernel.
- `agent` is an AI delegate or harness surface, such as Claude Code, VS Code, Antigravity, Cowork, or a service driver.
- `session` is the durable scoped occasion where purpose, occupant, host kernel, and pinned scope meet.
- `group` is the ownership or collective scope, such as `group:sam` or application/domain groups.
- `channel` is an external surface or account stream: Gmail accounts, GitHub org/project surfaces, Drive, Calendar, VCS, websites, DNS, or local filesystems.

Do not conflate account identity with user identity. Additional Gmail or Git accounts should normally enter as `channel` nodes owned by `group:sam` or `user:sam`, then feed knowledge items or project rows through G-ingest. If Menno, Lola, or other IRL people need durable modeling, treat that as a future identity/personhood design decision; do not silently make them kernel `user` principals.

## Current Wrap-Up Index

- [T=187 — T186 Google Calendar projection report](t187-t186-google-calendar-projection-report.md)
- [T=188 — T187/T188 session pipeline MVP report](t188-t187-session-pipeline-mvp-report.md)
- [T=189 — Calendar, dashboard, organization, and boundary report](t189-calendar-dashboard-organization-wrapup.md)
- [T=189 — Recommendation HG projection and T200 node/relation plan](t189-recommendation-hg-projection-wrapup.md)
- [T=189 — Calendar event readback, skills, and public surfaces](t189-calendar-event-public-surface-wrapup.md)
- [T=189 — Surface Context Atlas wrap-up](t189-surface-context-atlas-wrapup.md)
- [T=190 — Z440 VS Code lead handoff and identity topology](t190-z440-vscode-lead-handoff-wrapup.md)
- [T=190/T193 — ffs0 admin trunk and closeout policy](t190-session-branch-and-closeout-policy.md)
- [T=190 — Z440 projection finish pass](t190-z440-projection-finish-wrapup.md)
- [T=190 — Z440 Windows 11 session desktops](t190-z440-windows-session-desktops-wrapup.md)
- [T=194 — T187 path and hp-laptop readback](t194-t187-path-and-hplaptop-readback.md)

## Original Diary Register

Moos entries remain welcome here. The tone can be affectionate and sharp, but operational reports should still be precise about kernels, sessions, actors, rewrites, and validation.

Older diary entries:

- [T=5 — born](t5.md)
- [T=170 — the day Sam almost did not pull git](t170.md)
- [T=171](t171.md)
- [T=171 — batch ingestion](t171-batch-ingestion.md)
- [T=171 — mirror incident](t171-mirror-incident.md)

For any agent landing here: this folder is evidence and narrative context, not the truth source. The log is truth; running-state is the latest hydration card; this folder is the place where a session becomes readable after the dust settles.
