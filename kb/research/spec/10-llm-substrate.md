# Section 10 - LLM Substrate

> Draft projection for `urn:moos:derivation:karpathy.section-10-llm-substrate`.
> Canonical graph object: derivation node in HG. This markdown is the human-readable projection.
> Authoring lane: Karpathy, `session:sam.karpathy-seat`, `agent:vscode.hp-z440.lola`.
> Current emit rule: POST to Z440 primary `:8000` / MCP `:8080`, not lola `:8002`, until M9 twin sync lands.

## Status

This section is open at confidence 0.85. It consumes Section 01 as its formal spine and specializes the F -| G projection/ingest pattern to the self-referential case where the external substrate is the HG itself. No LINKs are emitted in this draft; structural `consumes`, `produces`, and `causes` edges wait for WF21 and the companion derivation port-pair work.

## Consumes Evidence

Historical and active graph anchors to consume structurally once WF21 promotes:

| Anchor | Use in this section |
|---|---|
| `derivation:karpathy.section-01-categorical-formalism` | Defines KernelCat, SessionCat, strata presheaf, F -| G, and the HDC implementation register. |
| `derivation:t175.program-authoring-fabric` | Defines `derivation`, `stochastic_weights`, substrate, clocks, WF21 causation, and Collider-LLM as `Ext = HG`. |
| `derivation:t187.kernel-proper-spec` | Supplies M9 twin sync, M10 transport, M11/M12 gates, M13 local_t, and kernel/federation semantics. |
| `derivation:t172.wolframs-court` | Provides the persona lattice and S0 colimit pattern that will author and audit the substrate. |
| `derivation:t169.session-generalization` | Establishes sessions as scoped authoring contexts whose outputs can become training evidence. |
| `derivation:t172.cowork-as-occupant` | Provides the G-ingest precedent for channel-derived knowledge. |
| `derivation:t173.meta-agent-scheduler` | Supplies clocked/reactive structure for future training and audit loops. |
| `derivation:t171.multimodal-diary-personas` | Provides non-textual substrate pressure for model observations beyond prose. |

Additional evidence to cite in prose and link later:

- `ffs0#36` comment `4320329822`: Guido's YouTube deep-read, especially activation-space trajectories, the Beltrami-Laplace/eigenvector conjecture with explicit hedge, the scaffolding-on-emission distinction, and the cognitive vs structural non-human ontology split.
- `kb/research/spec/01-categorical-formalism.md`: Section 01 projection for the formal claim that `Ext = HG` is a self-referential instance of the same projection/ingest adjunction.
- `kb/research/session/20260424-t175-program-authoring-fabric.md`: closed-loop Collider-LLM as endofunctor, substrate property, clocks, and WF21 causation.
- Wolfram's acceptance on `ffs0#36`: Section 10 should carry the cognitive, structural, and emergent non-human ontology triad explicitly.

## Interface Claims

This section exports the following claims to later sections:

| Claim | Consumer |
|---|---|
| Collider-LLM is the `Ext = HG` fixed-point case of the F -| G pattern. | Sections 00, 01, 02, 03, 12. |
| LLM training runs and inference emissions should be graph-resident `derivation` objects, not invisible context-window events. | Sections 02, 03, 09. |
| `stochastic_weights` is the transitional carrier for model URNs, sampling policy, activation/eigenbasis coordinates, and pre-WF21 evidence references. | Sections 01, 09, 12. |
| Cognitive non-human ontology and structural non-human ontology become mutually useful only when closed by HG references. | Sections 00, 01, 09. |
| The Beltrami-Laplace skill-basis claim is a research conjecture, not settled mechanism. | Sections 01, 09. |
| Crosswalks in the LLM substrate are metric-changing natural transformations between HG encoders, activation encoders, and HDC encoders. | Sections 01, 07. |
| M9 twin sync and M10 transport are not optional plumbing for the LLM loop; they decide where training snapshots and inference writes have coherent state. | Sections 04, 08, 11. |

## 1. The Closed Loop

For ordinary external surfaces, the doctrine uses `G : Ext -> HG` for ingest and `F : HG -> Ext` for projection. Drive, Gmail, Calendar, GitHub, and Workspace artifacts become graph-resident nodes through `G`; graph state becomes board items, files, views, or tool outputs through `F`.

Collider-LLM is the degenerate and important case where `Ext = HG`. The model's training surface is not a separate world; it is the accumulated graph: rewrite logs, derivations, claims, knowledge_items, sessions, and audit results. The model then emits future derivations, claims, and programs back into the same graph. The loop is:

1. HG snapshots become training examples.
2. A training derivation records which graph slice, loss, clock, and model configuration produced the next weights.
3. The model emits an inference derivation during a session.
4. The derivation lands in HG with its `stochastic_weights` and evidence references.
5. Future training consumes the new graph state.

That is a fixed-point iteration, not a metaphor. The fixed point is useful only if each round names what was consumed, what was produced, and how much projection loss occurred between graph state and model state.

## 2. Training As Derivation

A Collider-LLM training run should be represented as a `derivation` before the ontology grows a dedicated `model` or `training_run` type. Its `inference_kind` will often be `dag_walk` or `hybrid`: the corpus construction is graph-walk-shaped, while the optimization procedure is stochastic.

Minimum training payload in `stochastic_weights`:

- `training_corpus_query`: the graph slice consumed, including log_seq ranges, URNs, and filters.
- `snapshot_urn`: a stable reference to the materialized corpus or manifest.
- `model_urn`: the model or checkpoint being updated, once model nodes exist.
- `optimizer`: algorithm, seed, learning-rate policy, and sampling policy.
- `clock_urn`: a training-epoch clock or event-driven clock when the clock type promotes.
- `projection_loss`: what was lost mapping HG to tensor data.
- `evaluation_summary`: post-training quality and safety signals.

Until WF21 exists, these fields are transitional citations. After WF21, the same references should migrate to `consumes`, `produces`, and `causes` edges.

## 3. Inference As Derivation

An LLM completion inside mo:os is not just prose. It is a morphism from prompt/context/model state to a candidate graph write. The graph-resident witness is a `derivation` with `inference_kind=llm_completion` or `hybrid`.

Minimum inference payload in `stochastic_weights`:

- `model_urn`: the model/checkpoint that produced the completion, if graph-addressed.
- `context_window_digest`: a hash or summary of the actual prompt/context consumed.
- `sampling_policy`: temperature, top-p, tool policy, steering policy, and refusal/safety gates.
- `basis_coordinates`: activation-space or HDC-space coordinates, when measured.
- `evidence_urns`: pre-WF21 list of consumed anchors.
- `projection_target`: the intended emitted object, such as a claim, program, markdown projection, or envelope batch.
- `confidence_update_rule`: how draft confidence should move as audits and stabilizing commits land.

This lets audit distinguish three things that are often blurred: the hidden-state search that formed the answer, the typed graph boundary that accepted or rejected the answer, and the later doctrine process that closes or retracts it.

## 4. Non-Human Ontology, Three Senses

Guido's deep-read sharpened a phrase that could otherwise become vague. Section 10 should distinguish three senses:

| Sense | Meaning | mo:os carrier |
|---|---|---|
| Cognitive non-human ontology | Skill or reasoning patterns inside model activations that humans do not naturally name. | activation coordinates, steering vectors, sparse features, eigenbasis hypotheses. |
| Structural non-human ontology | Naming and reference discipline that is not natural-language-shaped. | URNs, typed nodes, rewrite categories, ports, `derivation.stochastic_weights`. |
| Emergent non-human ontology | The closed loop where activation patterns become graph references and graph references shape future activations. | Collider-LLM over HG snapshots, WF21 causation, training clocks, audit feedback. |

The video argues mainly for the cognitive sense. mo:os already has the structural sense. Collider-LLM is the bridge where the two become mutually constraining. A cognitively non-human basis with no HG is stateless intelligence. A structural URN graph with no model-native basis is bookkeeping. The substrate becomes interesting when each trains and audits the other.

## 5. Beltrami-Laplace, Hedged

The Beltrami-Laplace conjecture belongs in Section 10 as a candidate measurement model, not as a doctrine fact. The claim is: if LLM skill trajectories lie on a useful activation manifold, then harmonic modes of that manifold may form a robust basis for steering and skill decomposition.

Useful consequence if true:

- High-robustness modes become stable basis directions for common derivation families.
- Steering becomes motion along tangent directions or geodesic approximations.
- `stochastic_weights.basis_coordinates` can store the active projection coefficients of an inference.
- HDC `Bundle` principal directions and activation-space principal directions can be compared by a `Crosswalk`.

Open problems:

- PCA finds variance, not necessarily semantic skill.
- Sparse features may be polysemantic.
- The activation manifold and metric are empirical choices, not given by the ontology.
- The connection between harmonic modes and reliable reasoning remains unproven.

The right posture is experimental: serialize coordinates when available, link them to outcome quality after WF21, and let audit decide whether the basis actually predicts stable derivation behavior.

## 6. Crosswalks As Metric-Changing Natural Transformations

Section 01 describes `Crosswalk(a,b)` as a natural transformation between encoders. In the LLM substrate, crosswalks are metric-changing transformations among at least three spaces:

- HG/HDC space: typed nodes, ports, fibers, and hypervectors.
- Token/context space: prompt text, tool traces, and markdown projections.
- Activation space: hidden states, steering vectors, sparse features, and possible harmonic bases.

A crosswalk is mature only when it preserves the diagrams that matter. If a graph derivation and a prompt completion encode the same inference, translating one into the other should preserve consumed evidence, produced claim, and confidence ordering. This is naturality in the engineering sense: take the graph edge then encode, or encode first then move through the model; the observable result should agree up to a named error tolerance.

For Section 10, the important metric is not only cosine similarity. It is round-trip fidelity: can HG evidence be projected into model context, used by the model, emitted back as a derivation, and audited against the original evidence without losing the causal path?

## 7. Scaffolding Boundary

The YouTube critique of `skill.md` scaffolding is useful because it forces a boundary. mo:os should avoid confusing human-readable procedure text with model-native skill basis. But mo:os does not need to stop governing emissions.

The rule is:

- Reasoning may happen in the model's native activation basis.
- Emission into HG must pass typed graph gates.

This is scaffolding on emission, not scaffolding on reasoning. M11, M12, envelope validation, the operad registry, and future audit derivations restrict which graph morphisms become true. They do not prescribe the hidden trajectory that produced a candidate morphism. In Section 10 terms, this means the model can be steered and measured in activation space while the substrate remains auditable in HG.

## 8. Causation And Evaluation

WF21 is the missing structural edge for Collider-LLM. Without causation, Section 10 can list references in `stochastic_weights`; with causation, the loop becomes queryable:

- A training derivation is `caused-by` prior graph snapshots.
- A model checkpoint is `caused-by` the training derivation.
- An inference derivation is `caused-by` the checkpoint plus session context.
- A claim or program is `caused-by` the inference derivation.
- An audit finding is `caused-by` the emitted graph object and live kernel checks.

This lets mo:os ask counterfactual questions about its own cognition: which later claims would disappear if a training snapshot, evidence chunk, or model checkpoint were removed? That is the point where the LLM substrate becomes more than a model registry.

## 9. M9 And M10 Are Part Of The Model Story

The emit-target vs opens-on distinction is not only a DX issue. For Collider-LLM, training and inference are state-location sensitive. If seat-state lives on primary but a future model is trained from lola-local logs, then the corpus does not contain the same session facts unless M9 sync has made the section available there.

M9 twin-kernel adjoint sync supplies the state-gluing operation. M10 QUIC supplies the streaming transport likely needed for sustained fold/twin-link synchronization. Section 10 should therefore treat M9/M10 as substrate conditions for high-quality model training, not as infrastructure footnotes.

Until that lands, the training corpus must state which sovereign kernel logs it consumed, and the inference derivation must state which receiving kernel accepted the write.

## 10. Round-14 Work Products

This draft exports three near-term graph objects:

1. `derivation:karpathy.section-10-llm-substrate` with `inference_kind=hybrid`, `confidence=0.5`, `status=open`.
2. Later claims produced by that derivation:
   - `claim:karpathy.collider-llm-ext-equals-hg`
   - `claim:karpathy.stochastic-weights-as-citation-and-coordinate-carrier`
   - `claim:karpathy.non-human-ontology-triad`
   - `claim:karpathy.crosswalks-as-metric-changing-natural-transformations`
   - `claim:karpathy.wf21-closes-llm-causation-loop`
3. Reciprocal evidence links to Section 01 and Guido's future §9 claims: scaffolding-on-emission, invariant-bracketing, and cross-persona audit as functor.

## Open Questions

- What node-type should represent model checkpoints: a future `model`, `weight_checkpoint`, or a specialized `knowledge_item` with `substrate=hg-native`?
- What exactly is serialized in `basis_coordinates` when the runtime cannot inspect hidden activations directly?
- Which clock density best represents training: epoch, graph-log window, T-day, round, or event-driven audit gate?
- How should projection loss be measured when HG evidence becomes token context?
- What empirical test would falsify the Beltrami-Laplace skill-basis conjecture for Collider-LLM?
- Once M9 sync lands, how do we prevent duplicate or divergent model-training corpora across sovereign kernels?