# Section 01 - Categorical Formalism

> Draft projection for `urn:moos:derivation:karpathy.section-01-categorical-formalism`.
> Canonical graph object: derivation node in HG. This markdown is the human-readable projection.
> Authoring lane: Karpathy, `session:sam.karpathy-seat`, `agent:vscode.hp-z440.lola`.
> Current emit rule: POST to Z440 primary `:8000` / MCP `:8080`, not lola `:8002`, until M9 twin sync lands.

## Status

This section is open in HG at confidence 0.85. The corresponding derivation ADD landed on Z440 primary at log_seq 353 as `urn:moos:derivation:karpathy.section-01-categorical-formalism`; the kernel-emitted M13 tick advanced `session:sam.karpathy-seat.local_t` at log_seq 354. No LINKs are emitted in this draft; structural `consumes` and `produces` edges wait for WF21 and the companion derivation port-pair work.

## Consumes Evidence

Historical anchor derivations to consume structurally once WF21 promotes:

| Anchor | Use in this section |
|---|---|
| `derivation:t169.session-generalization` | Session as scoped authoring context and local time carrier. |
| `derivation:t172.wolframs-court` | Persona lattice, local sections, and S0 synthesis spine. |
| `derivation:t172.cowork-as-occupant` | External workspace ingest as an instance of the G direction. |
| `derivation:t173.meta-agent-scheduler` | Scheduler and reactive structure as event-indexed morphisms. |
| `derivation:t175.program-authoring-fabric` | `derivation` as first-class inference witness. |
| `derivation:t187.kernel-proper-spec` | KernelCat, SessionCat, fold, strata, M9 twin adjunction, and M10 transport. |
| `derivation:t171.multimodal-diary-personas` | Multimodal lane as non-textual section evidence. |

Additional evidence to cite in prose and link later:

- `dev/reference/research-archive/20260414-t164-session-channel-purpose.md`: sessions as monoids; tools as operads; watcher/reactor fan-out as cooperads; channel and purpose foundations.
- `ffs0#36` comment `4320329822`: Guido's YouTube deep-read, especially the Beltrami-Laplace/eigenvector framing, the explicit hedge around that conjecture, and the distinction between scaffolding on emission and scaffolding on reasoning.
- Wolfram's `emit-target != opens-on` correction on `ffs0#36`: the current primary-as-receiving-kernel rule is evidence about where state lives before M9 sheaf gluing exists.

## Interface Claims

This section exports the following finite claims to later sections:

| Claim | Consumer |
|---|---|
| `KernelCat` is the category whose objects are kernel graph states and whose morphisms are validated rewrite programs. | Sections 02, 03, 04, 09. |
| `SessionCat` is the category of occupied authoring contexts; the session-to-kernel map is functorial when M11/M13 hold. | Sections 02, 08, 09. |
| The strata filtration is a presheaf of visible structure over cutoff strata. | Sections 03, 04, 09. |
| Federation coherence is sheaf gluing over sovereign kernel logs; current emit-target behavior is a pre-gluing boundary case. | Sections 04, 08, 11. |
| Channels are cooperadic ingest surfaces; tools and leaves are operadic computation surfaces. | Sections 05, 06, 07. |
| The F -| G projection/ingest pattern is the adjoint design signature for external systems and for the `Ext = HG` LLM loop. | Sections 05, 08, 10, 12. |
| HDC/VSA operations implement approximate categorical structure through binding, bundling, unbinding, crosswalks, fibers, and similarity. | Sections 07, 10. |

## 1. KernelCat

Fix a kernel log. Let a state be the fold image of a finite log prefix. Define `KernelCat_K` as follows:

- Objects are well-typed graph states reachable from the empty or seed state by replaying a finite prefix of kernel `K`'s append-only log.
- Morphisms are validated rewrite programs, i.e. finite sequences of `ADD`, `LINK`, `MUTATE`, and `UNLINK` envelopes whose source state satisfies all runtime gates and whose fold image is the target state.
- Composition is program concatenation when the target state of the first program is the source state of the second.
- The identity on a state is the empty program.

Associativity follows from associativity of list concatenation plus replay determinism. Identity follows from the no-op program. The category is not a category of files, prompts, or processes; those are external projections. The semantic ground is the typed rewrite fold.

The subtle point is that validation is part of the morphism definition. A syntactically shaped envelope that fails M11, M12, strata validation, immutability, or port compatibility is not a morphism in `KernelCat_K`; it is a rejected candidate. This keeps the category aligned with actual kernel behavior rather than with a looser prose model.

## 2. SessionCat

`SessionCat` has session snapshots as objects: scope, purpose, host kernel, owner, occupant, local time, and context. Its morphisms are acknowledged session transitions: acquiring or rotating occupancy, authoring a program, advancing local time, changing scoped context through a valid rewrite, or closing/retracting a derivation.

There is a functorial map from session work to kernel work when M11 and M13 hold:

- A session-authored transition maps to the kernel rewrite program that records it.
- The session local time increment maps to the kernel-emitted local_t MUTATE acknowledged after the user rewrite.
- Occupancy naturality is enforced by WF19 and M11: a program emitted by an agent must factor through the session currently bearing the relevant `has-occupant` relation on the receiving kernel.

This is why the current Karpathy emit target is primary. `session:sam.karpathy-seat --opens-on--> kernel:hp-z440.lola` is topology intent, but the receiving-kernel state carrying the actual session and `has-occupant` relation is Z440 primary. Until M9 twin sync copies or reconstructs that section on lola, a direct POST to lola is not a morphism in the relevant `KernelCat_lola`; M11 rejects it. The doctor and harness are therefore checking a categorical precondition, not merely a port preference.

## 3. Strata As Presheaf

Let `Strata` be the ordered cutoff category generated by `S0 <= S1 <= S2 <= S3 <= S4`. Define a presheaf `P : Strata^op -> Set` where `P(Si)` is the set of graph structures visible at or below stratum `Si`: rewrite log, grammar, infrastructure, interaction, and projection overlays. For `Si <= Sj`, the restriction map `P(Sj) -> P(Si)` forgets higher-layer structure while preserving lower-layer invariants.

A doctrine section is coherent when its projections agree under these restrictions:

- S4 prose should restrict to S1 vocabulary without inventing undeclared types.
- S2 derivation nodes should restrict to S1 type rules without violating immutable properties or port declarations.
- S0 log evidence should fold to the S2 facts cited by the section.

This gives Guido's audit lane a formal job: check that section projections commute across markdown, HG state, issue comments, and runtime queries. Audit is not an external review process; it is a functor from the persona-lattice diagram to a coherence verdict.

## 4. Federation As Sheaf Gluing

Each kernel log is a local site. A persona-local statement is a local section over one site; a fleet-level doctrine claim is a glued section over the covering family of kernels. Gluing is valid only when overlaps agree under restriction.

The `emit-target != opens-on` catch is the worked example. Karpathy's semantic section belongs to lola, but the current seat-state lives on primary. The overlap between the lola-intended section and primary-held state does not yet commute by automatic replication. Therefore the valid emit surface is primary, while lola remains an opens-on metadata target. M9 twin sync is precisely the missing gluing operation: it should supply functors between kernel sites plus unit/counit acknowledgement conditions that make the local section available where its topology says it belongs.

In the strict category-theory register, M9 should not merely say "sync data." It should state which functors move rewrite evidence between kernels, what the unit and counit components are for each synchronized object, and which triangle identities hold up to replay equivalence. Until that is implemented, the primary surface is the only state-bearing section for the VSCode seats.

## 5. Operads, Cooperads, And Interfaces

The t164 archive note supplies the interface law:

- Tools and leaves are operadic: many typed arguments compose into one result.
- Channels and watchers are cooperadic: one source fans out into many emitted nodes, relations, or reactions.

This is not decorative language. A broken external interface is usually a missing composition law. The mo:os repair is to force every boundary to declare the shape of its inputs, outputs, and color-compatible ports. `LINK` is the activation rewrite: wiring existing nodes is how the graph does work.

For Section 1, the important consequence is that every interface must expose its categorical signature before it becomes trusted substrate. A Drive chunker, a GitHub issue bridge, a VSCode host-runner, and a future LLM steering interface are different surfaces, but each must tell the kernel whether it is composing many inputs into one output, decomposing one input into many outputs, or doing both as an adjoint pair.

## 6. Projection/Ingest: The F -| G Design Signature

Use `G : Ext -> HG` for ingest: an external artifact becomes graph-resident nodes and relations. Use `F : HG -> Ext` for projection: graph-resident state becomes an issue, markdown file, board item, UI view, model training corpus, or emitted tool artifact.

This is an adjunction design signature, not yet a fully proven hom-set bijection for every external surface. To make it strict, each surface must define:

- the external category and its morphisms,
- the HG subcategory it maps into,
- the unit component saying how an external object is recovered after ingest and projection,
- the counit component saying how an HG object is recovered after projection and ingest,
- the conditions under which the triangle identities hold, probably up to lossy projection equivalence.

This precision matters for Section 10. When `Ext = HG`, the loop becomes self-referential: HG snapshots train Collider-LLM; the model emits derivations; derivations enter HG; future training sees those derivations. The adjunction becomes an iterative fixed-point process, and the fixed point is only meaningful if unit/counit loss is named rather than hand-waved.

## 7. HDC/VSA Implementation Register

Let `phi` be an encoder from typed HG nodes and local sections into high-dimensional vectors. The categorical structures above have approximate HDC realizations:

| HDC operation | Formal reading | mo:os use |
|---|---|---|
| `Bind(a,b)` | typed pairing / tensor-like role binding | bind session, purpose, kernel, transport, and evidence roles. |
| `Bundle(xs)` | coproduct-like superposition | accumulate a local section or t-cone. |
| `Unbind(c,b)` | approximate projection from a bound composite | recover role-conditioned evidence. |
| `Crosswalk(a,b)` | natural transformation between encoders | move between channel, KI, claim, and derivation encodings. |
| `Fiber(scheme,value)` | pullback along a classification scheme | restrict evidence to a typed sub-surface. |
| `Similarity(a,b)` | observable inner product | measure overlap between sections, terms, or dependencies. |

The operator cockpit and host-runner are also HDC hygiene. Before a derivation can mean anything, the system must bind the correct persona, session, kernel, and transport. A wrong binding contaminates every downstream vector and every downstream graph fact. That is why VerifyPersona belongs before PostProgram.

## 8. Beltrami-Laplace Conjecture, Hedged

Guido's YouTube deep-read gives a useful external anchor: model skills may correspond to eigenfunctions of a Beltrami-Laplace operator on the activation manifold, with steering as motion along tangent directions. This is the right mathematical frame to cite, but it is a conjecture, not settled doctrine.

What is defensible now:

- Activation-space vs weight-space is a real distinction.
- Harmonic bases on manifolds are mathematically natural.
- Steering vectors and sparse feature discovery make activation-space skill structure plausible.
- `derivation.stochastic_weights` is the right HG carrier for projections onto discovered basis components.

What remains open:

- PCA finds variance, not necessarily semantic skill.
- Sparse autoencoder features can be polysemantic.
- The mechanism connecting skill semantics to a specific Beltrami-Laplace operator is not proven.
- "Non-human ontology" must be split into cognitive non-human structure and structural non-human naming.

Section 1 should therefore phrase this as a research conjecture: if LLM skill trajectories admit a useful manifold model, then the principal harmonic directions are candidate HDC basis vectors for derivation weights. Section 10 can use the same claim operationally: Collider-LLM should try to serialize the active coordinates of an inference into `stochastic_weights` when it emits a derivation.

## 9. Scaffolding On Emission, Not Reasoning

The video's critique of skill scaffolding applies to command-sequence templates that try to force the model's internal reasoning into a human-written script. mo:os should not defend that weaker pattern.

The stronger distinction is this: mo:os scaffolding is on emission, not on reasoning. M11, M12, the operad registry, and the rewrite envelope schema restrict what can be written to HG. They do not prescribe the hidden-state trajectory that produces the candidate write. This is type-system discipline at the graph boundary, not a claim that human-readable skills are the model's native skill basis.

That distinction belongs mainly to Section 9, but Section 1 needs it because it explains why categorical structure and eigenvector-style model-native reasoning are compatible. The graph constrains morphisms at the boundary. The model can still search its internal space in whatever basis is most natural.

## 10. Round-14 Work Products

This draft exports four near-term graph objects:

1. `derivation:karpathy.section-01-categorical-formalism` with `inference_kind=hybrid`, `confidence=0.5`, `status=open`.
2. Later claims produced by that derivation:
   - `claim:karpathy.kernelcat-rewrite-category`
   - `claim:karpathy.strata-presheaf`
   - `claim:karpathy.federation-as-sheaf-gluing`
   - `claim:karpathy.fg-projection-ingest-signature`
   - `claim:karpathy.hdc-bundle-principal-directions`
3. Section 10 follow-up: `derivation:karpathy.section-10-llm-substrate`, consuming this Section 1 derivation plus Guido's cognitive/structural non-human ontology distinction.
4. Audit cross-link: Guido's future `claim:guido.scaffolding-on-emission-not-reasoning` should be reciprocal evidence for this section, while this section should be evidence for Guido's audit-as-functor subsection.

## Open Questions

- What exact external categories make `F -| G` strict for GitHub, Drive, and Collider-LLM rather than only a design signature?
- What equivalence relation should measure round-trip fidelity when projection is lossy?
- Which HDC encoder is canonical for derivation nodes: type-first binding, port-first binding, or evidence-first bundling?
- Does the Beltrami-Laplace conjecture survive empirical contact with actual Collider-LLM hidden states, or is it only a useful metaphor?
- When M9 twin sync lands, which triangle identities must hold for lola and primary to collapse Karpathy's emit-target into opens-on?