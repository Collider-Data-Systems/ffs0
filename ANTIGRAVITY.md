# ANTIGRAVITY.md

Primary directive for Antigravity IDE (Google Gemini) in the `ffs0` workspace.
Owner: `urn:moos:user:sam` — pulled on every workstation.

On Z440, AG currently drives `session:sam.moos-diary` on `kernel:hp-z440.moos` (:8003) as `agent:antigravity.hp-z440`, with `persona.moos-dachshund` as the S4 context overlay. Lane: multimodal-curation + Labs Flow ingestion + diary-entry authoring.

---

## Running state

**Read `kb/superset/running-state.md` first.** Current T-day, active program, kernel state, open items, key URNs.

---

## The rule

Four rewrites only: `ADD` · `LINK` · `MUTATE` · `UNLINK`
Log is truth. State is derived. Nodes don't call things. Relations don't carry messages.

Nomenclature, ontology rules, agent-actor discipline, workspace structure: see `CLAUDE.md` — identical constraints apply.

---

## Lane — what AG owns on Z440

- `session:sam.moos-diary` on `hp-z440.moos` kernel
- `purpose:sam.multimodal-curation-and-diary`
- Labs Flow videos → `knowledge_item` chunks pinned to the session
- Diary entries under `kb/moos-diary/` (md + media)

AG does NOT own: kernel Go code (Wolfram's lane), doctrine review (Guido's lane), the three other court personae (Karpathy HDC / Steinberger DX / Wolfram implementation).

---

## Actor discipline (post-§M11, T=171 PR #30/#31)

When emitting envelopes:
- `actor = urn:moos:agent:antigravity.hp-z440` for ordinary ADDs / MUTATEs / LINKs (inferred-session path via moos-diary occupancy).
- `actor = urn:moos:kernel:hp-z440.moos` for ontology-governed ADDs (`system_instruction`, `gate`, `twin_link`, `transport_binding`, `kernel`) and kernel-authority-scope MUTATEs — §M11 allowlist bypass.
- Never `urn:moos:user:sam` (fails §M11; sam is owner, not occupant).

Envelope authoring reference: `moos-rewrite-envelope` skill.

---

## T=173 pivot — conversations-as-S0

IDE conversations are S0 substrate. Reification path: chunker-skill → `knowledge_item` chunks → pinned to session (G ingest) → downstream programs/tasks. New doctrine `.md` only when establishing a new invariant; past-round scratch and instantiation snapshots live under `dev/reference/research-archive/`.

For AG specifically: diary entries are their own shape (per the moos-diary chunking rule in `kb/research/session/20260422-t172-cowork-as-occupant.md` §3.1 — per-artifact-section with umbrella `knowledge_item`).

---

## Domain knowledge

Invoke the `moos-domain-expert` skill for categorical/mathematical reasoning.
Nomenclature, ontology, workspace structure: see `CLAUDE.md`.

---

## Safety

- Never commit `secrets/` values or API keys.
- Never commit `.vscode/mcp.json` (machine-specific).
- Keep destructive actions explicit and intentional.
- Raw media in `kb/moos-diary/` is fine; chunk before writing doctrine.
