# T216 → T244 — the manifold arc, a fleet that learned to verify itself

> Wrap-up spanning ~28 T-days (2026-06-05 → 2026-07-03), written at T=244 as the **baseline
> narrative before the next arc**: the compiler-lowering lane (moos IR → MLIR / Rust / C++)
> and the continuation of the manifold bump. Previous entry on this shelf: t216 (governance
> session projection). This one is deliberately broader and less code-bound — the period it
> covers changed what the system *is*, not just what it does. Evidence and narrative, not
> truth: the log is truth.

## Where we stood at T216

At T216 the fleet was two machines and a hope. Z440 and hp-laptop ran ontology 3.16.2, the
LAN IPs drifted whenever the router felt like it, ProDesk was a stale box at a friend's
place, and everything the system knew about itself — who sits where, which engine serves
which seat — lived in hand-written markdown that went subtly wrong the moment nobody was
looking. The projection pipeline worked (T216 closed with an all-green session pack on the
governance seat), but orientation was a ritual of re-pasted prompts, and secrets were
scattered `.env` files with a GitHub PAT sitting in plaintext on two machines.

The deeper posture was there — log is truth, state is derived, four rewrites — but the
*surfaces* around the hypergraph were still mostly manual, and the distance between "what
the docs say" and "what the engines say" had to be policed by hand.

## The arc, in four movements

### 1. The vocabulary grew a world-model (T218–T231)

The manifold bump started as prose: eight vocabulary deltas (D1–D8) drafted around a simple
observation — the system had engines and sessions but no word for the *application-domain
groupings* they serve, no discriminator for what kind of host a workstation is, no names
for the panes and tabs through which everything is actually observed. `my-tiny-data-collider`
became the worked example: a domain with DNS, mail, calendar, storage — all of it channels.

T231 turned the prose into research and the research into a release. The Poly ⊣ so:om
foundations reframed the whole architecture as an adjunction: **mo:os is the durable engine
(state = fold(log), the only truth); so:om is the surface matrix it projects into and
ingests from.** Ontology **4.0.0** landed the additive core — the `manifold` type,
`workstation.kind`, fourteen new `channel.kind`s (from browser tabs to Cloudflare tunnels),
`workspace` and `instance` as alias-first readings of `session` and `kernel` — all without
touching a single URN. The hard rename was gated to 4.0.x, deliberately. Alias first, cut
later. That discipline held for the whole arc and paid off twice (see movement 4).

Meanwhile the fleet quietly became a real mesh: Tailscale replaced DHCP-drift as the
transport, ProDesk rejoined as a full three-way peer, and the seat-parity doctrine —
equivalent seats on every machine — got its matrix and its runbooks.

### 2. Sovereignty over the accounts (T239)

The Sunday catch-up was two rounds in one day. The first reconciled the fleet (all six
engines already on 4.0.0 — the "pending restarts" note was stale, a small lesson in
readback-beats-docs) and re-ratified D6: the canonical word for the runtime is **engine**,
`instance` deprecated. Same round: the nomenclature reference, the extended branching
attribution (so a commit can say which user, which workstation, which channel-kind it came
through), and the launch-path modernization — `/orient`, seat-hydration skill, six persona
subagents. The re-pasted orientation prompt died that day, replaced by an operation.

The second round rebuilt the relationship with Google. A leaked PAT and a pile of per-machine
key files became: GitHub in the OS keyring, GCP through ADC, provider keys in Secret Manager,
and — the centerpiece — **keyless domain-wide delegation** for the Workspace account. By
end of day, Keep, Calendar, Gmail, Drive and Tasks could all be read for
`sam@my-tiny-data-collider.nl` with *no key file anywhere*: ADC signs a JWT, IAM mints a
delegated token, the token evaporates. The first `keep-widget` channel landed in the HG that
night, carrying a nine-screenshot Keep note Sam had written *to* the assistant from his
phone — the G-direction working exactly as drawn: a human thought, captured on Android,
lifted into the graph on the desktop.

The same round surfaced four honest gaps between the ontology and reality (source_type has
no `keep`, pins were a property instead of relations, channel anchors forced filler values)
— filed as fragments F1–F4 with decisions recorded, not papered over.

### 3. The system started generating itself (T244, morning)

T244 was declared a clearing day — "goal for this convo is to clear all issues" — and it
became the densest round of the arc. Two things stand out above the bookkeeping.

**The canary.** Antigravity had claimed the SOT read→act path "validated" — and Guido, the
governance seat on the laptop, called it out: asserted, never run. So it was run properly:
a tokened directive planted in `AGENTS.md`, the token withheld from every prompt, and AG
told only to re-read the file. It found the token, wrote the ack file, posted the result.
Hex-verified. That small episode is the arc in miniature: **a claim is nothing; a protocol
with an artifact is everything.** The fleet now catches its own optimism.

**The seat table.** Phase-4 of the config overhaul landed: the table in `AGENTS.md` that
says who occupies what — the document every tool orients from — is no longer written by
anyone. It is **folded from the live hypergraph** through the router fan-in, eleven rows,
one per occupancy relation, byte-exact, drift-gated at round close and in CI. The oldest
piece of hand-maintained truth in the workspace became a projection. The file that had
warned "if this table disagrees with readback, readback wins" now *is* the readback.

Around those two: the type-map router merged and live, the deprecated `instance` anchor PRs
closed with supersession instead of merged (alias-first discipline paying off again — never
land dead vocabulary), all four open issues closed with dispositions rather than force, the
exposed Gemini key deleted rather than rotated (Vertex needs no key at all — the best secret
is the one that stops existing), and a stack of small household truths: the family montage
finally actually delivered to Drive (the "old copy" it was meant to replace had never been
uploaded — audits find things), ComfyUI's models junctioned to the data drive, the DHCP
reservations pinned after catching the laptop mid-drift at `.17`, and the discovery that
Tailscale SSH simply does not exist on Windows — a whole planned workstream quietly
dissolved by one error message.

### 4. The next lane opened itself (T244, evening)

While the clearing ran, the other seats came alive in a way they hadn't before. The
Karpathy seat drafted the compiler-lowering IDE affordances — an LSP fix, a new skill, and
the **moos IR / MLIR design note** whose one sentence sets the next arc's boundary:

> *the engine code is an F-projection of the mo:os operad and fold semantics onto a target
> runtime surface* — Go today, Rust/C++/MLIR/LLVM tomorrow; none of them is mo:os; the
> rewrite log and the operad are.

Guido introduced itself formally (issue #89), repaired its own session from `abandoned` to
`active`, and then did the most governance thing imaginable: drafted the HG apply the
Karpathy seat needs (a durable purpose and first scope root) and explicitly *declined to
apply it* — because the Karpathy lane emits to the Z440 engine, and cross-emitting from the
laptop would violate the boundary. Draft on one machine, review and apply on the machine
that owns the lane. The division-of-labor doctrine, executed by the agents themselves,
unprompted.

And Antigravity, given its long-awaited go, wrote the diary lane's first real perceptual
knowledge: two photographs, captioned by a local vision model, landed as knowledge_items
(log 467–470). Moos' diary — the thing this shelf was named for — finally writes itself
into the graph.

## What the baseline is, concretely

As of T=244 evening (Z440 log 471, hp-laptop log 1490, ProDesk powered down until next
week):

- **Truth:** ontology 4.0.0 everywhere; log-is-truth intact; eleven seats folded live.
- **Backlog: zero.** No open issues on ffs0 or moos-kernel; one deliberate work item
  (moos-router#5, hot-reload + drift-detect, Guido's).
- **Identity: keyless.** Keyring + ADC + DWD + Secret Manager; one deleted key, zero key
  files; five Workspace channels readable, write scopes granted but held.
- **Surfaces: increasingly generated.** Seat table folded from HG; mirrors thinned to
  pointers; drift caught by gates, not vigilance.
- **Coordination: multi-agent and self-correcting.** Five persona seats plus two Cowork
  surfaces plus Copilot review, with real cross-checks (Guido vs AG on the canary; Copilot
  catching nomenclature and scope-creep in PRs; seats declining out-of-boundary applies).
- **Pending, chosen, not forgotten:** the Karpathy purpose apply (staged, one word away);
  the 4.0.x hard rename as a fresh engine-vocab lane; fragments F1–F4 awaiting a bump
  window; the personal→mtdc account migration; ProDesk's power button.

## What the next arc is for

The compiler-lowering lane asks the question this whole arc was preparing for: if every
runtime is just a projection surface, **how cheap can we make new surfaces?** The Go engine
becomes the reference oracle; moos IR names the rewrite programs explicitly; xDSL hosts the
first MLIR-shaped experiments (native MLIR tools aren't in the Windows LLVM build — noted,
not blocking); Rust and C++ engines become F-projections to be *verified against the
oracle*, not rewrites of the truth. The manifold bump continues alongside: spanning
relations for `manifold`, the D8 `realizes` reification, and eventually the URN cut.

The period ends where it began — log is truth, state is derived — but the sentence means
more now. At T216 it was doctrine. At T244 it is machinery: the state that is derived
includes the documents, the tables, the captions, and increasingly the code.

---
*Written by Cowork-Z440 at round close, T=244. Sources: running-state.md entries T216–T244,
ffs0 issues #58/#61/#64/#83/#87/#89 + PRs #79–#90, moos-router #4/#5, engine logs Z440
462→471. S0 narrative — not HG truth until G-ingested.*
authored-by: agent:claude-cowork.hp-z440 / session:sam.z440-cowork-workspace / t244-arc-baseline
