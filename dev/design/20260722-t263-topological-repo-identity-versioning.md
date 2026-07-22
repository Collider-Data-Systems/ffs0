# T=263 — Workspace access and the topological repo (v2.1)

**Answer, in four lines.**
1. The organizing structure is one function — `slice: State × Agent → Context` — under three obligations: security law, bandwidth filter, consistency check (§2). Ratify the stamp discipline: every decision/readback/proposal carries `(engine, log_seq, ontology, law-version)`.
2. The m-ary topology symmetry is real but graded: two-level colimit and branch-coordinates are doctrine; axes/symmetries/fibration are graph-witnessed conjecture; groups have **no declared internal structure** today, and the manifold node exists but is spans-sparse (§4).
3. The engine is a *staged, twice-gated* projection product of the workspaces — a cycle, not a paradox (§4.6).
4. Git is a channel (`channel.kind: vcs`), not a home. The durable home stays the blessed log; the repo shape arrives as a lens over it (§5-B), not a migration.

> **Status: v2.1, committed with ffs0#172 (T263 evening) for Sam's review. Prose-only — this note itself authorizes no ontology change, no HG rewrite, no migration; the companion 4.0.4 bump + staged batch ride the same PR as a separate ruling (see `manifold-bump-4_0/20260722-t263-user-topology-glue.md`).**
> Zappa / Cowork-Z440. v1 = storage framing; v2 = Sam's access reframe + screen readback + a 10-agent research round; v2.1 = fixes from a 4-lens adversarial verify (two blockers among them). Sources: running-state T=263 · `access.js`/`live-smoke.mjs` · t259/t260 staging programs · t216/t218/t231/t239/t248 docs · t263 ceiling report · moos-kernel + moos.jsonl readback · cited literature (§3–§4). Per-agent digests in session scratchpad.

## 0. The question, reframed

Who may open which workspace, through which channel, serviced by which engine — and how is
that answer versioned together with everything it governs? The storage question (git-projected
vs HG-native vs other substrate) is the storage face of this one.

Readback, not doctrine: **channels** are where workspaces open (IDE conversations, Keep, the
SM-A14R's Android apps, the pilot side-panel/PiP/tab, the GitHub web UI, terminals) and they
outnumber engines. **Engines** service workspaces without colocating with channels (the pilot
panel in Z440 Chrome reads `hp-z440.primary`; Wolfram's laptop seat emits cross-box). **Not
all users have engines; not all channels run on an engine box** (T263 hub ruling: users arrive
as thin channel apps; engines are hosted on the seed). **Surfaces** form a large, mostly
dormant site (4 screens × ~14 virtual desktops on Z440, one live; 2 laptop screens; the
phone); occupancy is the sparse thing worth versioning — and per the applied t259 access-law
conjecture, access binds at workspace/engine, never at surface (S1 surface-gauge).

## 1. Readback: what exists today

**Storage.** The identity spine (user/group/agent/workspace/engine + WF01 owns · WF02 governs ·
WF19 has-occupant/opens-on) lives in the HG, persisted as one append-only JSONL log **per
engine** (`moos.jsonl`, single-writer lock, replay at boot; Z440 611 · laptop 1603 · ProDesk
29 at T=263 — three sovereign histories, a fact §2 must respect). Entries carry a monotone
`log_seq`; **no content-addressing, no hash-chain** (the SHA-1 in `runtime.go` is a URN
display hash). Git holds code, doctrine, config, and generated F-images of HG state, per T218:
`branch = F(workspace)`, `merge = G(branch)`, refs derived, E2/E5 provenance trailers.

**The access law** ([access.js](https://github.com/Collider-Data-Systems/collider-pilot/blob/main/src/mcp/access.js), pure, shared verbatim
between panel and Node, self-declared Go-port anti-drift anchor):
`permitted = governs-closure(WF02, incl. delegates-to) ∪ reverse WF19 has-occupant ∪
owned-sessions (owner_urn) ∪ public (visibility/anon_visible)`, then a workstation intersection
that is tri-state (`applied | skipped-widened | failed-closed`) because the ontology has no D7
`realizes` relation yet — the client tier skips and widens, a server-authoritative tier must
fail closed. Identity is fail-closed (`effectiveMode` collapses to anon without trusted-storage
backing; the MV3 worker strips forged identity structurally). The keep-set applies a ∀-owner
rule — a node stays visible only if **every** owning workspace is permitted — with one
documented exception: unattributable (zero-owner) nodes fail closed for anon and at the server
tier but are *shown* at the identified client-presentation tier (explicitly not a security
boundary); the fail-closed behavior is what ports into `access.go`. The kernel port is a
committed gate before any second real user (T263 ruling) but does not exist yet. The panel
already stamps every readback with `ENGINE · LOG_SEQ · T-day · ontology · FOLDED_AT ·
VIEW_FILTER` plus the decision path (`wf19-has-occupant`, `skipped-widened`).

**Graph-truth conjectures** (applied T=260, log 562→604, `status=open` +
`epistemic_status=conjecture`, confidence 0.55–0.65; cited below as T260-C*): the manifold's
5-axis coordinate structure (A1 identity-poset user < group < manifold-group · A2 placement ·
A3 runtime · A4 semantics · A5 time-lineage), 5 symmetries (S1 surface-gauge … S5
identity-fibration), an access-law derivation (`access(workspace) = f(user, device,
workstation) × owns(user, engine(workspace))`; surfaces deliberately absent), and the
categorical-branching spine — **T260-C1**: branch = cartesian lift over base B = A1×A2,
worktree = the lift's filesystem realization; **T260-C4**: push = gated log-segment transport
(select → materialize → gated ingest; what moves is never a node-set, always a log segment),
*plus* a formal reading — push = Lan_f, a pointwise colimit along a base morphism — that sits
`status=open` in the graph and is exactly the machinery T262 deleted (ledgered as C11). The
t250-testing program that would falsify these **never executed** — REVIVE/KILL is an open
Sam-gate; until then this layer is asserted-not-checked (the ACSet oracle's fold→C-set
faithfulness is the only proven identification).

**T262 architecture** (adopted T262; propose-only-offline accepted *conditionally* — crisp
ratification is an open Sam-gate, see C5): one blessed sequencer totally orders the log;
offline = propose-only; canonical state = pure function of the set of envelopes; frames
(atomically committed envelope groups) commit as units; cognition on the speculative tail,
actuation gates on finality; colimit-merge machinery deleted.

## 2. The central claim: one function, three obligations

`slice : State × Agent → Context` — the access law — is one function under three obligations:

| Obligation | Statement | Source |
|---|---|---|
| **Security** | permitted sub-fold per principal; fail-closed; kernel-enforced before a second user | pilot A3 + T263 ruling |
| **Bandwidth** | slice subscription = interest management; "broadcasting a total order costs rate x size x N and is the first thing that breaks" — a GbE NIC feeds ~2 full-rate subscribers at 500 B × 100 K env/s, ~1 through Tailscale-on-Windows. Load-bearing day-one at swarm tempo | t263 ceiling report |
| **Consistency** | an access decision must never be evaluated at a fold older than the content it gates | Zanzibar transfer, below |

**The consistency obligation.** Zanzibar (Pang et al., USENIX ATC 2019) names the failure the
*New Enemy problem*: applying old access state to new content, or neglecting the order between
access updates coordinated out of band. Its remedy is the *zookie* — an opaque token tying a
content version to a minimum check timestamp; the TrueTime apparatus exists only because
Google's access store and content stores are separate systems with independent clocks.

**Transfer (theorem sketch, marked, and scoped).** *Within one engine's log*, access relations
and content share one total order, and within any fold of a contiguous committed prefix the
problem vanishes by construction: content at position m is visible only in folds ≥ m, which
already contain all access envelopes < m. The zookie degenerates to the log position — for
log-resident content. Two scope limits, stated plainly:

- **Per-sequencer-domain only.** The fleet runs *three* sovereign logs today; positions from
  different logs are incomparable, and a laptop fold gating content whose access envelopes
  live in the Z440 log is exactly Zanzibar's separate-systems case. Fleet-wide same-log is an
  MTDC-era assumption (seed-hosted engines, T263 hub ruling); until then every stamp is the
  **pair `(engine_urn, log_seq)`** — which the panel already displays — and cross-engine
  position comparison is undefined.
- **Log-resident content only.** Substantial content lives outside the log: git blobs, Keep
  note bodies, Drive artifacts, the GitHub org/board state, binaries behind multimodal KIs. A
  log position versions the HG node, not the external bytes — a Keep edit or a force-push
  changes what a channel serves with no envelope sequenced. For reference-carrying nodes the
  stamp must stay a pair *(position, content-hash)*: pin a content hash at ADD/LINK time so
  the position transitively fixes the bytes (folds into §5-B item 4). Channels serving
  unpinned external content are seam-3 caches by definition.

**It reappears at four seams:**

1. **Speculative tail.** A fold including proposed-but-unsequenced envelopes may pair new
   content with access state the final order contradicts. Rule: speculative folds may render
   an engine's *own* drafts; they never authorize serving content to a third party.
2. **Cross-view mixing (same log).** Two derived views advancing independently (kernel fold,
   pilot cache, any index) recreate the problem if an evaluator reads content at n₂ but checks
   access at n₁ < n₂. The invariant is a property of **evaluation**, not storage: enforce
   max-position + re-fold, or refuse.
3. **Channel-cache staleness.** Lagging channels and cached renders (Keep, the phone, the
   side-panel, and — the largest instance — **git-committed F-projections**: the seat table,
   mirrors, seat-context serve identity data as files cloned everywhere, read at hydration as
   operative instructions, currently carrying no fold stamp). Mitigations: re-check-on-access
   + TTL for renders; every generated identity-bearing artifact carries `(engine, log_seq,
   folded_at)` in its fence header; clones/checkouts are long-lived caches and access-relevant
   consumption re-checks live — "readback wins" becomes a stated consequence, not folklore.
   (Git history of F-images is also a PII replication channel the §3 erasure decision must
   cover.)
4. **Cross-engine fan-in.** The router :9000 fan-in, twin reads, and any future seat portal
   compose folds from different logs; there is no max-position there and re-fold does not
   help. A composed view carries a position *vector* (engine → log_seq); access for a node is
   evaluated against its home engine's component. Until the law can do that, **fan-in views
   are non-authoritative for access decisions** — display-only, in the spirit of the panel's
   `ACCESS: PRESENTATION` badge.

**The revocation window — the residual honesty.** The prefix invariant orders only *sequenced*
envelopes. Two windows remain and must be owned, not implied away:

- **Pending revocation.** A revocation decided but sitting in the propose/Sam-gate lane while
  content commits is New Enemy case 2, not closed by anything above — and routing access
  rewrites through the gate makes them structurally the *slowest* envelope class. Options:
  a fail-closed pre-admission tombstone (the slice respects a proposed revocation for the
  affected principal pending admission), or per-revocation gate bypass (running-state
  direct-to-main is the precedent). Minimum: doctrine states the window = sequencing +
  approval latency.
- **Unbounded staleness.** Zanzibar's stale-serving is safe *under a bounded-staleness
  regime*; mo:os channels lag unboundedly (ProDesk at log 29, mostly off). A stale prefix
  fold is confidentiality-safe *for the frontier at n* — but after a revocation at r, a
  channel folded at n < r serves the revoked principal indefinitely. **Revocation propagation
  is a separate obligation**: either a max serve-staleness for non-owner principals, or
  push-invalidation through the per-subscriber watermarks §5-B already requires (an admitted
  access envelope forces affected subscribers forward or suspends serving). If no bound is
  set pre-MTDC, that is Sam's explicit accepted risk, stated as such.

Auxiliary disciplines: **pin one ontology version per fold** (Zanzibar pins one
type-declaration snapshot per request; the panel already shows 4.0.3 beside log_seq); **stamp
the law version too** (access.js/access.go commit hash) — the law changed at T260, so
check-at-position is *normative* by default ("what would today's law have permitted at p") and
*historical* only when replayed under the law version recorded at p; and note the ∀-owner rule
is **non-monotone** — adding a WF12 provides-kb relation can shrink visibility — so
incremental slice maintenance cannot be pure additive closure (C10).

**Unification with the repo lens (§5-B):** the per-subscriber machinery the ceiling report
requires anyway (ack frontier/watermark, delta-vs-last-acked, late-joiner catch-up) *is* the
repo surface: a subscriber's watermark is a "ref," catch-up is "clone/fetch," and the zookie
stamp is the same `(engine, log_seq)`. Repo lens, netcode layer, and access-consistency
protocol are one mechanism carrying three vocabularies.

## 3. Prior art, second pass (corrections and additions to v1)

v1's VCS survey (git's Merkle DAG; Pijul/patch pushouts as the road T262 closed; jj's
operation log; Fossil's derived-tables shape; Dolt/Datomic/Irmin/TerminusDB) stands, with one
correction and several sharpenings:

- **Fossil correction.** Fossil users/capabilities live in an *unversioned local table* beside
  the versioned artifacts — ordinary HTTP clone does not transfer them (only a
  Setup-privileged config pull can); config-sync is a separate manual, privilege-gated
  command. The most-cited "identity in the repo" example is the opposite on inspection. Its
  rationale — per-clone autonomy, every clone its own authority domain — is exactly the
  requirement T262 removed. Fossil's argument against versioned identity does not apply.
- **Gerrit NoteDb is the shipped-at-scale blueprint.** Accounts are per-user branches in a
  meta repo (`refs/users/…`; docs verbatim: the history "serves as an audit log"); groups
  versioned since 2.16; per-project access rules live on a config branch whose changes are
  **themselves reviewed changes** only owners can land. Identity, membership, and access
  policy versioned inside the substrate they govern, with the review loop applied to the
  authorization layer itself. mo:os analog: identity/access rewrites through the
  staged-program + Sam-gate lane (t_hook proposed→approved→applied) — same move, and the
  source of the pending-revocation window §2 names.
- **gitolite**: authorization fully versioned, compiled **synchronously in the push hook** —
  no reconcile window. Fold-at-apply is the same end of the enforcement-timing spectrum;
  never introduce an async access projection that can lag the log.
- **GitOps / policy-as-code — the honest counterpoint.** The industry's dominant pattern for
  versioned users/groups/access *is* git-projected (Terraform IAM, Kubernetes RBAC, OPA
  bundles), and it genuinely wins **when the enforced substrate is external** — you cannot
  fold your way into AWS IAM, the GitHub org, or OS accounts (the Collider-Data-Systems org
  rules are live unversioned external state of exactly this class). Its three structural
  failure modes: (1) **drift** (declared ≠ applied) — absent by construction when state is a
  pure fold; (2) **ordering** between a permission change and the content needing it — GitOps
  patches with hand-maintained sync-wave annotations; the sequencer's total order solves it
  structurally *within a domain* (§2); (3) **the trust root** — every such system has an
  unversioned key and first admin outside the loop. That one survives translation: **the
  sequencer's identity and the genesis superadmin envelope (`SeedIfAbsent`, the only place
  `actor: user` is legal) are the mo:os trust root — outside the log, authorizing the log.
  Name it in doctrine.** Worth copying regardless: the pre-apply diff — a **fold preview**
  (the state delta a staged program would cause) is the `terraform plan` of the propose lane.
- **Capability attenuation** (Macaroons NDSS 2014; Biscuit spec; UCAN). Delegation = appending
  a restriction to an immutable chain; narrowing only; verification walks the chain to the
  authority root (UCAN's recursive witness check is the algorithm shape for validating a
  `delegates-to` chain at fold time). Biscuit adds origin-scoping (a delegatee's assertions
  are never read as grants), sealing (no-further-delegation), and revocation-by-chain-element
  (= UNLINK one `delegates-to` relation kills the subtree). **Narrowed negative result: none
  of the surveyed token systems maintains a versioned, authoritative store of delegation
  chains** — verification always walks the presented credential (UCAN services may persist
  delegations, but that store is neither ordered nor load-bearing for verification). Landing
  delegation chains as LINK envelopes in a totally-ordered log is ahead of the capability art
  on auditability. (Matches the moos-soom ownership-by-key conjecture — kept open there, kept
  open here.)
- **Directory services are the anti-model**: built to converge replicas, not to remember (AD
  keeps only winning values and purges tombstones; SCIM has ETags; Keycloak audit rows are
  optional and expire). None can answer "who had access at t." **Even Zanzibar GCs its tuple
  history** (SpiceDB's point-in-time checks die at a ~24 h window; OpenFGA and Ory Keto
  shipped the data model without consistency tokens — the protocol is the hard, skipped
  part). An append-only log with the GC/provenance lane governing retention gives **unbounded
  point-in-time access audit** — `could agent A read workspace W at (engine, p)` = the law
  over the prefix fold ≤ p, under the law version stamped there (§2) — a headline capability
  no surveyed production system has. Worth a first-class **check-at-position** readback.
- **The erasure tension, named now.** Append-only truth vs right-to-erasure becomes real with
  a second user. Established pattern: crypto-shredding (per-subject encryption of PII-bearing
  property values; destroy the key to erase), legal status unsettled. The operad-level
  *decision* — which property classes are shreddable, plus a **deterministic redacted-value
  fold semantics** (never error on undecryptable) — is cheap prose and must precede
  multi-user data (§6 Now-5); the implementation is 4.0.x. Scope includes git history of
  F-images (§2 seam 3) as a PII replication channel.

## 4. The topology claim, taken seriously — and critically

Sam's framing: manifold, users, groups, workspaces, worktrees, branches, the git repo — one
m-ary shape with topology, recurring across levels; engine code itself a projection product of
workspaces. Graded against readback:

**Grounded.** The two-level colimit shape (workspace = colimit of its branch-episodes;
manifold = colimit of per-repo branches sharing a purpose — T218 E4, with the T260 errata:
the *merge* is G(branch), not itself a colimit; `moos-soom.md` §5 still carries the
uncorrected phrasing — rot to fix). Branch names as flattened WF19 tuples. Occupancy as
liveness (E3). And the structure Sam intuits is **computed operationally at every access
check** — the governs-closure BFS *is* the identity topology, declaratively absent but
operationally present. The manifold node itself **exists**: `urn:moos:manifold:
my-tiny-data-collider` was ADDed at log_seq 542 with one WF18 spans relation (to
`channel:google.keep.sam`, 543, ~T=249) — grounded but spans-sparse.

**Conjecture with a graph witness** (applied T=260, marked, unfalsified — t250-testing never
ran). The 5 axes and 5 symmetries; A1 identity-poset; S5 as applied: *workspaces fibered over
the identity poset; access = pullback along user into group; sharing/push = extension along
user into group*; T260-C1: *branch = cartesian lift over base B = A1×A2*.

**Absent.** Groups have **no declared internal structure in any doctrine doc** — flat
substrate under a Stage-1 manifold view. The fibration base B has no graph witness. The full
G2 spanning set and any derived manifold view do not exist. So the symmetry claim is real as a
shape, thin as a readback: one level grounded, one witnessed-conjectural, the group level
still aspiration.

**What the literature actually supports** (each mapping marked):

1. **Access and branching are one structure — the strongest candidate formal home.** S5
   conjectures access = pullback in the same fibration whose cartesian lifts T260-C1 calls
   branches. Independently: Johnson–Rosebrugh–Wood, *Lenses, fibrations and universal
   translations*, MSCS 22(1):25–42, 2012, doi:10.1017/S0960129511000442 — "a c-lens is
   nothing other than an opfibration" (split, in the standard reading) — and delta lenses
   (Diskin–Xiong–Czarnecki, JOT 10(6), 2011), views that propagate *deltas*, matching a log
   of ADD/LINK/MUTATE/UNLINK envelopes natively. The workspace-access story ("slice as
   updatable view") and the branching story ("scope as base change") are candidates for the
   same mathematics. **Conjecture (C7)** — but with both a graph witness and published
   scaffolding.
2. **The precise novel object.** Secure lenses exist (Foster–Pierce–Zdancewic, CSF 2009:
   confidentiality = hidden source regions never affect the view; integrity = *untrusted*
   view edits never touch trusted source regions — a non-interference law on put). Delta
   lenses exist. **Never combined: a secure delta lens over an append-only rewrite log
   appears in no publication found.** That is the MTDC-shaped contribution — new work,
   scoped, stated honestly.
3. **The testable law** (fit for property-based checking against the ACSet oracle, no new
   proof machinery): per-audience visibility as an idempotent comonad (Kavvos, POPL 2019
   lineage); target property **`fold(envelopes visible to A) = project_A(fold(all))`** —
   noninterference of the slice, a finite checkable property of the pure fold. First thing
   t250-testing should check if REVIVEd; a failure localizes which envelope kinds leak.
4. **Poly, honestly**: channel = polynomial (positions = postures, directions = admitted
   readbacks/commands; propose-only = a position whose directions are propose-envelopes
   only). Consistent with t231; zero published Poly access-control work; parked as C9.
5. **Sheaf language, honestly**: the real sheaf-security results (Sterling–Harper FSCD 2022;
   Kavvos 2019) are lattice-leveled information flow, not org-shaped access — and over a
   totally-ordered log the gluing condition is nearly trivial; sheaf vocabulary must not
   smuggle merge semantics back in.
6. **The repo question dissolves into the channel vocabulary.** moos-soom already says it:
   the VCS is a so:om surface (`channel.kind: vcs`), "one polynomial among many." Git is a
   *channel* through which code-workspaces open — same standing as Keep or the pilot — not a
   candidate home for truth. The bootstrap loop (workspaces author code → F-projection to
   repos → build gate → engine binary → engines service workspaces) is a real cycle, not a
   paradox: it passes two explicit gates per turn (merge = G review; build gate = the
   apply-gate analog, T260-C4's transport half), so the engine is a *staged* projection
   product of the workspaces.

## 5. Candidate architectures (updated)

### A — Git as the durable home
Gerrit proves identity-in-git *works* — but via a purpose-built lens over bare refs with its
own review protocol: git as storage substrate under a domain lens, not files-in-a-worktree
with PRs. Reproducing that means building the lens anyway, on a foreign store, while
inverting log-is-truth and re-importing line-merge semantics at the crux. GitOps wins only
where the enforced substrate is external (§3) — the GitHub org, not the HG. **Verdict:
reject as home. Git remains an F-projection surface — one channel among many
(`channel.kind: vcs`).** Adopt from this lane anyway: the fold preview and the named trust
root.

### B — Repo-shaped lens over the blessed log — recommended
The v1 mapping stands (fold = checkout · log range = diff, typed at authoring time · frame =
commit · staged program + Sam-gate = branch/PR · admission validation = merge · stale
proposal = conflict, surfaced not auto-resolved · t_day = tag · replication = clone/fetch ·
GC lane = packing). What the lens *is*: **the slice function under its three obligations
(§2)**. Concretely:

1. **Refs = per-subscriber watermarks** — required by the bandwidth obligation anyway; also
   the carrier for revocation push-invalidation (§2).
2. **Stamp discipline** — every readback/decision/proposal carries
   `(engine_urn, log_seq, ontology, law-version)`; external references pinned by content
   hash; admission-time authorization at the sequencer. The pilot panel is the prototype.
3. **Check-at-position** — point-in-time access audit as a first-class readback; normative
   by default, historical under the recorded law version; ahead of every surveyed system.
4. **Content-address envelopes/frames + snapshot folds at watermarks** — integrity for
   replication, bounded replay for late joiners; extended to pin external-reference bytes.
5. **Delegation chains in the log** — `delegates-to` with Biscuit-grade semantics (monotone
   narrowing, origin-scoping, sealing, UNLINK-revocation).
6. **Fold preview** for staged programs; **named trust root** (sequencer identity + genesis
   superadmin envelope); **non-monotone keep-set** handled by stratification or
   owner-change recompute (C10); **PII property classes** decided before a second user (§6).

### C — External versioned substrate
Verdict unchanged (second SOT, foreign merge semantics at the crux, scale argument absent);
the directory-service survey adds: external identity stores are built to converge, not to
remember. Steal query surfaces (`FOR SYSTEM_TIME AS OF` ≙ prefix fold), not stores.

## 6. Recommendation

**Now (T263+, Go-oracle era — cheap moves only; all are ratifications, decisions, or
one-paragraph fixes except where marked):**
1. Ratify the §2 doctrine sentence, engine-qualified: *access decisions, readbacks, and
   proposals carry `(engine_urn, log_seq, ontology, law-version)`; cross-engine position
   comparison is undefined; fan-in views are non-authoritative for access; authorization is
   part of admission validation.* Caveat stated with it: position stamps are authenticated
   only once §5-B item 4 lands — until then they are trustworthy exactly as far as the
   single-writer local log and the box it lives on. The `access.go` port (already the
   pre-second-user gate) carries the stamp from day one.
2. Rule the revocation window (§2): accept it explicitly (window = sequencing + approval
   latency; no staleness bound pre-MTDC), or adopt the fail-closed pre-admission tombstone
   for revocation-intent proposals.
3. Backup discipline for `moos.jsonl` per engine — the binaries have `.bak` copies, the
   truth does not. Still the cheapest real risk reduction.
4. Name the staged-program + Sam-gate lane as the proto-branch of the lens (doctrine
   sentence; the fold preview itself moves to 4.0.x as tooling).
5. Decide the PII/shredding property classes + redacted-value fold semantics *on paper* —
   same trigger and deadline as the access.go gate: before any second real user's data
   enters the log. (Implementation stays 4.0.x.)
6. Rule t250-testing REVIVE/KILL — §4's conjectures (S5/T260-C1, the noninterference law C8)
   stay asserted-not-checked until that lane exists; the ACSet oracle is the ready bench.
7. Fix the moos-soom §5 errata rot (doc-only). Do not build the lens on the Go oracle.

**4.0.x / MTDC:**
1. Build B as stated: slice/lens as one mechanism under three obligations; refs-as-watermarks
   with revocation push-invalidation; the full stamp discipline; check-at-position;
   content-addressed frames + snapshot folds + external-reference pinning; delegation
   chains; trust root named in the genesis story; fold preview.
2. Land the ref/proposal/snapshot vocabulary through one WF20 round **together with the URN
   rewrite** (identity stability makes refs and diffs readable; renames as MUTATEs, never
   identity changes — C2). This resolves C4 refs-as-nodes by plan.
3. Implement crypto-shredding per the Now-5 decision.
4. Target formal object: the **secure delta lens over the rewrite log** (§4.2), first law =
   the noninterference equation (§4.3) — novel, scoped, falsifiable.
5. Merge stays deleted. The dependency structure of rewrite applications is a poset
   (AlgebraicRewriting `find_deps`); a total order is one linearization — no derivation
   information lost, concurrency forgone. Mimram–Di Giusto (MFPS 2013) documents the price
   of the alternative: conflicts live only in a free cocompletion, a strictly larger
   category; refusing merges means never leaving the category. If the break-the-total-order
   experiment ever runs, that literature is the re-entry point.

## 7. Conjecture ledger (this note's namespace C1–C11; applied T260 graph conjectures cited as T260-C1/T260-C4)

- **C1** — Prolly-tree/Merkle structural sharing of fold snapshots: unnecessary at current
  scale; revisit if snapshots outgrow memory-trivial size.
- **C2** — URN identity transposes from merge-critical (T261) to rename-critical under total
  order; renames = MUTATEs, never identity changes.
- **C3** — TerminusDB merge capability: low-confidence; verify before further use.
- **C4** — Refs-as-nodes vs refs-as-config: resolved-by-plan at MTDC (refs land as ontology
  vocabulary per §6 4.0.x-2 — subscribers are principals, frontiers are state); open only
  for the Go-oracle era, where config-only refs are acceptable.
- **C5** — "No new merge machinery" holds exactly as long as propose-only-offline holds —
  which Sam accepted only conditionally. §2's construction also assumes it (seam 1).
- **C6** — The New-Enemy-vanishes claim is a theorem sketch, **scoped per sequencer domain**,
  resting on the prefix-fold invariant; no literature co-locates access tuples and content
  in one totally-ordered log. State and check it formally (property-based check against the
  ACSet oracle).
- **C7** — Access = base change in the same fibration whose cartesian lifts are branches
  (S5 + T260-C1 + JRW MSCS 22(1):25–42 c-lens/opfibration bridge + delta lenses). Graph-
  witnessed conjecture, confidence 0.55–0.65 as applied.
- **C8** — The slice noninterference law `fold(visible_A) = project_A(fold(all))`: stated,
  checkable, unchecked. First target if t250-testing is REVIVEd.
- **C9** — Poly channel mapping (positions = postures, directions = admitted acts):
  structurally apt, zero literature; parked until an admission theorem exists.
- **C10** — The ∀-owner keep-set non-monotonicity is compatible with incremental slice
  maintenance via stratification or owner-change recompute — asserted, not designed.
- **C11** — T260-C4's *transport* reading (push = gated log-segment transport) survives T262;
  its *formal* reading (push = Lan_f, pointwise colimit) is superseded by the T262 deletion
  of merge machinery and sits `status=open` in the graph — candidate for epistemic
  supersession via the GC/provenance lane, same class as the moos-soom §5 rot.

---
authored-by: agent:claude-cowork.hp-z440 / session:sam.z440-cowork-workspace / t263-topological-repo-identity-versioning
