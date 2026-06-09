# ANTIGRAVITY.md

Primary directive for Antigravity IDE (Google Gemini) in the `ffs0` workspace.
Owner: `urn:moos:user:sam` — pulled on every workstation.

> **Mirror of `ffs0/AGENTS.md`** (the project SOT) · manual · don't edit except emergency de-rot. Canonical cross-tool orientation — seat map, 3-tier SOT hierarchy (HG→`AGENTS.md`→mirrors), S0→HG pipeline, 4.0 vocab, branching, safety — lives in `AGENTS.md` (Antigravity reads it natively). This file = AG-surface deltas (the `moos-diary` / multimodal-curation lane).

On Z440, AG drives `session:sam.moos-diary` as `agent:antigravity.hp-z440`, emitting to `kernel:hp-z440.primary` (:8000 / MCP :8080); `hp-z440.moos` (:8003) is overflow-lane metadata (see the AGENTS.md seat table). `persona.moos-dachshund` (= Φ(purpose), D3) is the S4 context overlay. Lane: multimodal-curation + Labs Flow ingestion + diary-entry authoring.

---

## Running state

**Read `kb/superset/running-state.md` first.** Current T-day, active program, kernel state, open items, key URNs.

---

## The rule

Four rewrites only: `ADD` · `LINK` · `MUTATE` · `UNLINK`
Log is truth. State is derived. Nodes don't call things. Relations don't carry messages.

Nomenclature, ontology rules, agent-actor discipline, workspace structure: see `AGENTS.md` (project SOT) — identical constraints apply.

---

## Lane — what AG owns on Z440

- `session:sam.moos-diary`, emit `hp-z440.primary` :8000 (opens-on `.primary`; `.moos` :8003 is overflow-lane metadata only)
- `purpose:sam.multimodal-curation-and-diary`
- Labs Flow videos → `knowledge_item` chunks pinned to the session
- Diary entries under `kb/moos-diary/` (md + media)

AG does NOT own: kernel Go code (Wolfram's lane), doctrine review (Guido's lane), the three other court personae (Karpathy HDC / Steinberger DX / Wolfram implementation).

T189 note: the current governance/projection lane added Calendar time-fabric projection, a local dashboard with temporal/calendar visuals, and a broad report at `kb/moos-diary/t189-calendar-dashboard-organization-wrapup.md`. AG diary work can cite this report as recent room context, but kernel/application architecture remains governed by `CLAUDE.md` and running-state.

---

## Actor discipline (post-§M11, T=171 PR #30/#31)

When emitting envelopes:
- `actor = urn:moos:agent:antigravity.hp-z440` for ordinary ADDs / MUTATEs / LINKs (inferred-session path via moos-diary occupancy).
- `actor = urn:moos:kernel:hp-z440.primary` (the emit-target kernel) for ontology-governed ADDs (`system_instruction`, `gate`, `twin_link`, `transport_binding`, `kernel`) and kernel-authority-scope MUTATEs — §M11 allowlist bypass.
- Never `urn:moos:user:sam` (fails §M11; sam is owner, not occupant).

Envelope authoring reference: `moos-rewrite-envelope` skill.

---

## T=173 pivot — conversations-as-S0

IDE conversations are S0 substrate. Reification path: chunker-skill → `knowledge_item` chunks → pinned to session (G ingest) → downstream programs/tasks. New doctrine `.md` only when establishing a new invariant; past-round scratch and instantiation snapshots live under `dev/reference/research-archive/`.

For AG specifically: diary entries are their own shape (per the moos-diary chunking rule reified as `derivation:t172.cowork-as-occupant` on log — per-artifact-section with umbrella `knowledge_item`).

Application boundary: `my-tiny-data-collider` is an HG application group/domain, not the `moos-kernel` codebase. Treat websites, DNS, Calendar, GitHub, and Workspace as projection/ingest surfaces owned by application groups unless a kernel/runtime task explicitly says otherwise.

---

## Domain knowledge

Invoke `moos-categorical-research` for categorical/HDC/mathematical reasoning; `moos-multimodal-ingest` for diary chunking.
Nomenclature, ontology, workspace structure, full doctrine: see `AGENTS.md` (project SOT).

---

## Safety

- Never commit `secrets/` values or API keys.
- Never commit `.vscode/mcp.json` (machine-specific).
- Keep destructive actions explicit and intentional.
- Raw media in `kb/moos-diary/` is fine; chunk before writing doctrine.
