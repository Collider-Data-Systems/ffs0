---
name: moos-categorical-research
description: Categorical reasoning + HDC/VSA bridge work for Karpathy's seat (`session:sam.karpathy-seat` on `kernel:hp-z440.lola` :8001). Use when emitting categorical/sheaf-theoretic claims, reasoning about presheaves on the strata filtration, working out the F⊣G adjunction details for a specific surface, designing hyperdimensional encoders/decoders, or proposing new categorical structure for the ontology. Trigger phrases: "as a categorical object", "presheaf on", "the adjoint of", "the operadic interface", "VSA encoding of", "sheaf gluing for", "Yoneda", "natural transformation", "fibration", "limit/colimit". Companion to `moos-rewrite-envelope` (envelope authoring) and `moos-domain-expert` (deeper math).
---

# moos-categorical-research

Karpathy's working surface for the HDC/VSA categorical bridge. Translates between three registers: **categorical formalism** (presheaves, adjunctions, operad/cooperad duality), **mo:os HG topology** (nodes, relations, WFs, strata), and **HDC/VSA implementation** (binding, bundling, similarity, fiber operations).

## Triggers

- A claim or thesis about mo:os reaching for categorical lingo ("the kernel is a category KernelCat with morphisms ADD/LINK/MUTATE/UNLINK; what's its limit?")
- A request to formalize an existing pattern as a categorical structure ("can we model channels as a sheaf?")
- HDC encoder/decoder design ("what's the binding scheme for a session's t-cone?")
- An ontology proposal that needs categorical justification ("WF21 causes/caused-by — what's its functorial signature?")
- Cross-walks between formalism and implementation (the moos-kernel `internal/hdc/` package, ontology operad rules, fold semantics)

## What this skill is NOT

- Not for general kernel envelope authoring — use `moos-rewrite-envelope` for that
- Not for round-open readbacks — use `moos-state-readback` / `moos-cowork-readback`
- Not for committing code or running ceremonies — Karpathy emits envelopes; Wolfram/Guido handle code merges

## The three-register translation

When working on a categorical question for mo:os, walk all three registers before settling:

| Register | What it asks | Output shape |
|---|---|---|
| **Formalism** | What categorical structure am I describing? | A signature: objects + morphisms + composition law + coherence diagram |
| **HG topology** | What nodes + relations + WF rewrites realize that structure? | An envelope batch (or doctrine note) showing the realization |
| **HDC implementation** | What hypervector operations reflect the structure? | Bind / bundle / unbind / fiber-product / similarity steps in `internal/hdc/` |

A claim is *finished* when all three registers agree. A draft sits at one register; a settled claim crosses all three.

## Karpathy seat conventions

- **URN root:** `urn:moos:claim:karpathy.<thesis-slug>` for claims, `urn:moos:derivation:karpathy.<slug>` for derivations (post v3.14)
- **Actor:** `urn:moos:agent:vscode.hp-z440.lola`
- **Session:** `urn:moos:session:sam.karpathy-seat` (single-occupancy → inferred path works post-§M13 fix)
- **Kernel:** `kernel:hp-z440.lola` :8001 (HTTP) / :9001 (MCP SSE)
- **Branch role on board items:** `agent`

## Typical envelope: claim ADD

A categorical claim ADD has four immutable properties + one mutable owner-authority confidence:

```json
{
  "rewrite_type": "ADD",
  "actor": "urn:moos:agent:vscode.hp-z440.lola",
  "session_urn": "urn:moos:session:sam.karpathy-seat",
  "node_urn": "urn:moos:claim:karpathy.<thesis-slug>",
  "type_id": "claim",
  "properties": {
    "text":         {"value": "<one-paragraph claim text>", "mutability": "immutable", "authority_scope": "", "stratum_origin": 2},
    "confidence":   {"value": 0.7, "mutability": "mutable", "authority_scope": "owner", "stratum_origin": 2},
    "owner_urn":    {"value": "urn:moos:user:sam", "mutability": "immutable", "authority_scope": "", "stratum_origin": 2},
    "subject_urn":  {"value": "<urn of the categorical object the claim is about>", "mutability": "immutable", "authority_scope": "", "stratum_origin": 2},
    "created_at":   {"value": "<ISO-8601>", "mutability": "immutable", "authority_scope": "", "stratum_origin": 2}
  }
}
```

## Typical envelope: derivation ADD (post v3.14-1 promotion)

Once `derivation` is a runtime node-type, every claim Karpathy makes can sit inside a derivation tracking the inference:

```json
{
  "rewrite_type": "ADD",
  "actor": "urn:moos:agent:vscode.hp-z440.lola",
  "session_urn": "urn:moos:session:sam.karpathy-seat",
  "node_urn": "urn:moos:derivation:karpathy.<slug>",
  "type_id": "derivation",
  "properties": {
    "name":            {"value": "<short label>", "mutability": "immutable", "authority_scope": "", "stratum_origin": 2},
    "inference_kind":  {"value": "deterministic_rule", "mutability": "mutable", "authority_scope": "owner", "stratum_origin": 2},
    "confidence":      {"value": 0.85, "mutability": "mutable", "authority_scope": "owner", "stratum_origin": 2},
    "status":          {"value": "open", "mutability": "mutable", "authority_scope": "kernel", "stratum_origin": 2},
    "owner_urn":       {"value": "urn:moos:user:sam", "mutability": "immutable", "authority_scope": "", "stratum_origin": 2},
    "created_at":      {"value": "<ISO-8601>", "mutability": "immutable", "authority_scope": "", "stratum_origin": 2}
  }
}
```

Then LINK `derivation --produces--> claim` and `derivation --consumes--> <evidence-urns>`.

`inference_kind` enum: {bayesian, llm_completion, deterministic_rule, dag_walk, hand_authored, hybrid}. Karpathy's categorical work is most often `deterministic_rule` (proof-shaped) or `hand_authored` (sketch-and-iterate).

## HDC implementation hooks

When a categorical claim has an HDC realization, the moos-kernel `internal/hdc/` package is the implementation surface:

| Operation | Categorical reading | Code path |
|---|---|---|
| `Bind(a, b)` | Tensor product / pair binding | `hdc/bind.go` |
| `Bundle(xs)` | Coproduct / superposition | `hdc/bundle.go` |
| `Unbind(c, b)` | Left-inverse of Bind (in expectation) | `hdc/bind.go` |
| `Crosswalk(a, b)` | Natural transformation between two encoders | `hdc/crosswalk.go` |
| `Similarity(a, b)` | Cosine — limit of inner products | `hdc/similarity.go` |
| `Fiber(scheme, value)` | Pullback along a classification scheme | `hdc/fiber.go` |
| `LiveIndex` | Recomputed cache; the colimit of recent rewrites' contributions | `hdc/live_index.go` |

When proposing new categorical structure, sketch which HDC operation realizes it; if no existing operation fits, that's a moos-kernel HDC extension — flag it for Wolfram.

## Worked example: F⊣G adjunction for a Workspace channel

**Formalism.** A channel C (e.g. `channel:google.drive.sam`) is a cooperad: one input (the channel URN) emits many outputs (knowledge_items chunked from the source). The chunker skill `moos-workspace-ingest` is the **G** functor (External → HG); future projection skills will be **F** functors (HG → External). The adjunction `F ⊣ G` says emit-then-observe round-trips up to the unit η; observe-then-emit round-trips up to the counit ε.

**HG topology.** Realized today via `WF12 provides-kb / kb-source` between channel and knowledge_item; F-direction not yet wired (Cowork emits artifact briefs back to Drive when the project board gets to it).

**HDC implementation.** `hdc.Crosswalk(channel-encoder, ki-encoder)` should be the natural transformation; the unit η is `Crosswalk · G` ≈ identity on HG, the counit ε is `F · Crosswalk` ≈ identity on Drive. Round-trip fidelity = how close to identity these compositions get.

**Output:** ADD `claim:karpathy.workspace-channel-as-cooperad-with-fg-adjunction` (text the above), ADD `derivation:karpathy.workspace-channel-cooperad-derivation` (inference_kind=hand_authored, consumes the t164 archive note, produces this claim).

## Cross-references

- `moos-rewrite-envelope` — envelope shapes, gates, immutability discipline
- `moos-state-readback` — round-open before any work
- `kb/research/session/20260424-t175-program-authoring-fabric.md` — derivation node-type spec; v314-1 fragment
- `dev/reference/research-archive/20260414-t164-session-channel-purpose.md` — operad/cooperad duality, the original cross-bridge attempt
- `dev/reference/research-archive/20260410-yoneda-hdc-graded-algebra-t160.md` — Yoneda + HDC connection (older but foundational)
- moos-kernel `internal/hdc/` — implementation surface

## Status

**Round-13 deliverable** (T=176). First skill authored to serve the Karpathy seat post-Phase B launch. Iterations expected as Karpathy's actual emit patterns reveal which categorical work is highest-leverage for mo:os.
