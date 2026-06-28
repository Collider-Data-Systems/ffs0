---
agent: "moos-categorical-research"
description: "Use when: closing the channel/knowledge_item vocab gaps surfaced T239 while wiring the keyless-DWD Workspace channels (Keep/Calendar/Gmail/Drive/Tasks). Four grammar_fragment sketches at status: proposed — F1 source_type enum, F2 channel.kind enum, F3 channels-as-external-channel + ingress derivation anchor, F4 D19.3 pins-urn LINK. F3/F4 DECIDED reading (ii)/(b) T239. Conjecture-marked PROSE; authorizes no ontology/URN change, applies no kernel rewrite."
---

# Grammar-fragment proposals — channel vocab gaps (T=239)

> **Status: design draft (S0 → pending G-ingest). All four PROSE at `status: proposed` — NONE applied.
> GATE: prose only — NO `ontology.json` edit, NO kernel rewrite, NO URN rename. Ontology stays v4.0.0.**
> Surfaced T239 while wiring the keyless-DWD Workspace channels end-to-end (ADC → IAM signJwt →
> delegated token for `sam@my-tiny-data-collider.nl`) and ingesting the `ki:keep.t239-to-claude-code`
> umbrella through the first `keep-widget` channel. Each is a live-observed defect, not a conjecture.
> Mechanism + WF20 promotion path: see `20260620-t231-grammar-fragment-proposals.md` §0 (identical).

---

## F1 — `knowledge_item.source_type += {keep, task, chat, doc}`

- **fragment_kind:** `property` (enum value extension) · **gate:** 4.0 additive bump
- **Defect (live T239):** `channel.kind` gained `keep-widget` / `task-list` in D5, but the *paired*
  provenance enum `knowledge_item.source_type` was never extended. Current values:
  `[youtube, arxiv, website, rss, email, gdrive]`. Ingesting the Keep note had to stamp
  `source_type: gdrive` as a stand-in — semantically wrong (it is a Keep note, not a Drive file).
- **specification (the patch a future ADD would carry):**
  `knowledge_item.source_type.values += ["keep", "task", "chat", "doc"]` (immutable enum; additive).
- **Rationale:** `source_type` is the G-direction provenance discriminator; it must cover every
  `channel.kind` that ingests into `knowledge_item`. Keep/Tasks/Chat are now (or imminently) live
  channels. After promotion, re-stamp `ki:keep.t239-to-claude-code.source_type` `gdrive → keep`
  (immutable ⇒ UNLINK+re-ADD or a narrow migration window).

## F2 — `channel.kind += {contacts, forms}`

- **fragment_kind:** `property` (enum value extension) · **gate:** 4.0 additive bump
- **Defect (T239 app survey):** the `channel.kind` enum is rich (mail/calendar/drive/task-list/
  messaging/video/keep-widget/…) and already covers Chat (`messaging`), Meet (`video`), Groups
  (`messaging`). Missing the two People/Forms surfaces enabled on `my-tiny-data-collider`:
  Contacts (People API) and Forms.
- **specification:** `channel.kind.values += ["contacts", "forms"]` (immutable enum; additive).
- **Rationale:** both are G-ingest surfaces (contacts → `knowledge_item`/principal hints; form
  responses → `knowledge_item`). Additive, no topology change.

## F3 — channels are `external-channel`; anchor → an ingress `derivation`  (DECIDED: reading ii, T239)

- **fragment_kind:** `property` (substrate remodel) + 2 seed `derivation` nodes · **gate:** 4.0 additive (NO kernel change)
- **Defect (live T239):** `substrate_anchor_urn` (immutable) is required on every channel ADD by the
  generic `ValidateADD` (iterates all immutables, `internal/operad/validate.go`). For the keep
  channel (modeled `hg-native`) the anchor was meaningless, forcing a filler (`kernel:hp-z440.primary`).
- **Decision (Sam, T239):** a `channel` **IS** an external observation surface, so its substrate is
  `external-channel`, not `hg-native`. `substrate_anchor_urn` then resolves to a `derivation` naming
  the **ingress mechanism** — the anchor self-documents *how* the surface is observed:
  - `derivation:keyless-dwd-ingress` — ADC → IAM signJwt → delegated `@mtdc` token (Keep/Calendar/Gmail/Drive/Tasks DWD lane)
  - `derivation:workspace-mcp-ingress` — the registered Gmail/Calendar/Drive MCP servers (personal lane)
- **specification:** ADD the two ingress `derivation` nodes; new channels carry `substrate:
  external-channel` + `substrate_anchor_urn: <ingress-derivation-urn>`. Backfill the existing
  gmail/calendar/drive/tasks/keep channels likewise (substrate_anchor is immutable ⇒ a re-ADD
  migration window, or apply only to channels minted from now on).
- **Rejected (i):** conditional `ValidateADD` (kernel build-gate change) — makes the anchor optional
  dead weight instead of signal. (ii) keeps the field always-meaningful with zero kernel churn.

## F4 — pins are relations: promote D19.3 `pins-urn`  (DECIDED: reading b, T239)

- **fragment_kind:** `port` (pins-urn / pinned-by-session pair on WF19) · **gate:** 4.0 additive (ontology + loader)
- **Defect (live T239):** `session.scope_pins` carries values on existing session nodes but is **not
  in the registered `session` type spec** and **no WF lists it in `mutate_scope`** ⇒ it cannot be
  MUTATEd (additive path needs the field declared mutable in the spec; standard path needs a governing
  WF) ⇒ the keep KI could not be pinned to `session:sam.z440-cowork-workspace`. Confirms the **D19.3
  gap** the `moos-workspace-ingest` skill flags; the skill's "append via MUTATE" path does not validate.
- **Decision (Sam, T239):** a pin is **topology, not payload**. Promote the D19.3 `pins-urn` /
  `pinned-by-session` port pair as a WF19 AdditionalPortPair: `session —pins-urn→ ki|channel|…`.
  Pinning becomes a LINK; readback counts pins via the relation.
- **specification:** add the `pins-urn`/`pinned-by-session` port pair to WF19 + the `session` (Out) /
  pinnable-type (In) port declarations; the loader already validates `AdditionalPortPairs` (post-PR1).
  One-time migration: convert each existing `scope_pins` array entry → a `pins-urn` LINK, then drop
  the property.
- **Rejected (a):** registering `scope_pins` as a mutable property + WF — entrenches pins-as-payload,
  the exact "no payload / pins are relations" violation. Fast, but wrong-shape.

---
authored-by: agent:claude-cowork.hp-z440 / session:sam.z440-cowork-workspace / t239-channel-vocab
