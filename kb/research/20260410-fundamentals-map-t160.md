# Fundamentals Map — T=160

Status: Session map for Z440 operations and fundamentals research.
Canonical source remains: `20260408-foundation-t158.md`.

---

## 1. Minimal axioms

1. Nothing happens except rewrites.
2. Operational primitives are ADD, LINK, MUTATE, UNLINK.
3. State is derived: `state(t) = fold(log[0..t])`.
4. The log is truth; projections are not authority.
5. Relations are truth; properties do not duplicate topology.

---

## 2. Vocabulary lock

Use only:

- node
- relation
- rewrite
- rewrite category (WF01-WF18)
- property
- operad
- interaction node
- `_urn` / `_urns`

Do not use legacy terms for these concepts.

---

## 3. Three-layer model

- L1 runtime: Wolfram-style hypergraph rewriting.
- L2 type system: operad registry, ports, color compatibility.
- L3 representation: HDC hypervectors for similarity and compute.

Identity view at T=160:

- Yoneda view: a node is determined by incident relations.
- HDC view: `phi(node)` bundles encoded incident relations.

---

## 4. Two-presheaf split

Over kernel category `K`:

- `P1: K^op -> Set` for structure and authority.
- `P2: K^op -> Set` for knowledge domain content.

Validation order:

1. P1 authority check.
2. P2 existence/domain check.
3. operad validation.

Delegation invariant:

- `P(delegate) <= P(principal)` (CI-5).

---

## 5. Causal invariants in practice

- CI-1: independent rewrites commute.
- CI-2: only declared structure-preserving projections are natural.
- CI-3: identity stability under rewrites.
- CI-4: deterministic replay from log.
- CI-5: rewrite category stability except governance updates.

---

## 6. Temporal model (T=159+)

`program` nodes carry mutable forward-looking temporal properties:

- `target_t`
- `starts_t`
- `deadline_t`
- `completed_t`

Dependency modes:

- known-node dependency via LINK.
- property-pattern dependency via watcher/guard/reactor flow.

WF18 is the program composition surface.

---

## 7. Multi-agent provenance (T=160)

- Every rewrite carries an actor URN.
- Provenance is reconstructed from log entries affecting a node.
- User remains principal; delegates are governed slices of authority.
- Conflict resolution is log serialization; use CAS/version checks for stricter mutation semantics.

---

## 8. Z440 runtime map

Workstation: `hp-z440`

Kernel instances:

- primary kernel: HTTP 8000, MCP 8080
- menno kernel: HTTP 8001, MCP 9001
- lola kernel: HTTP 8002, MCP 9002
- moos kernel: HTTP 8003, MCP 9003

Router:

- federation router: HTTP 9000

All kernel instances reference the shared ontology path in `ffs0/kb/superset/ontology.json`.

---

## 9. Research posture for this session

- Keep codex terms strict.
- Treat web sources as source_feed -> knowledge_item -> claim -> domain_tag flow.
- Use WF12 for semantic content wiring, WF17 for automation pipelines, WF18 for program-level dependencies.
- Preserve append-only reasoning: no direct state edits outside rewrites.
