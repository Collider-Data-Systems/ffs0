#!/usr/bin/env julia
# ============================================================================
# mo:os × AlgebraicJulia spike  (T=260, Zappa/Cowork-Z440)
# ============================================================================
# SEMANTIC-ORACLE REFERENCE — **NOT a kernel replacement.**
# The Go kernel stays the sovereign runtime (§M11/§M12, transport, MCP, the
# append-only log). This file is a categorical mirror used to answer one
# empirical question: is the mo:os HG *actually* an attributed C-set (ACSet),
# and are ADD/LINK/MUTATE/UNLINK *actually* rewriting rules (DPO spans L←K→R)?
#
#   ACSets.jl (via Catlab)   ↔  node · relation · property   (attributed C-set)
#   AlgebraicRewriting.jl    ↔  ADD·LINK·MUTATE·UNLINK        (DPO rules L←K→R)
#   Catlab data-migration    ↔  view_filter = Δ_F · push = Σ_F = Lan_F
#
# Run:  julia --project=. moos_hg_spike.jl
#   Reads a live snapshot from http://localhost:8000/fold; falls back to an
#   inline fixture if the kernel is down, so the spike always runs.
#
# EVERY categorical claim below is tagged  [PROVEN-BY-API]  or  [CONJECTURE].
# Verified against the installed depot: Catlab 0.17.6 / ACSets 0.2.29 /
# AlgebraicRewriting 0.5.0 / GATlab 0.2.4. Static-source-verified; a 30s REPL
# smoke-test of the `using` line is the final gate before trusting runtime scope.
# ============================================================================

# --- THE DEPENDENCY DECISION -------------------------------------------------
# [PROVEN-BY-API] `using Catlab` transitively @reexports the ENTIRE ACSets public
#   API (@present/@acset_type/@acset/AttrVar/part-ops) AND the Δ/Σ functorial
#   data-migration API — so a separate `using ACSets` is redundant.
# [PROVEN-BY-API] Catlab ALONE is INSUFFICIENT: Rule/rewrite/rewrite_match live
#   only in AlgebraicRewriting, which does NOT re-export Catlab. Hence BOTH.
# DataMigrations.jl and GATlab are NOT spike deps (see DECISION.md).
using Catlab                 # @present, @acset_type, @acset, AttrVar, homomorphism,
                             # ACSetCategory, DeltaMigration, SigmaMigrationFunctor, migrate
using AlgebraicRewriting     # REQUIRED, not in Catlab: Rule, rewrite, rewrite_match, create, id[cat]
using JSON3                  # load ffs0/kb/superset/ontology.json-shaped /fold snapshot
using Downloads              # stdlib — fetch the live /fold snapshot

# ---------------------------------------------------------------------------
# 1. The mo:os HG as an ACSet schema  (the FOLD SHAPE, not the operad).
#
#    [PROVEN-BY-API] Objects Node/Relation/Property; src,tgt: Relation→Node is
#      literally Catlab's SchGraph (a directed multigraph). mo:os relations are
#      BINARY src→tgt in the fold (one src_port/tgt_port pair per WF01..WF21),
#      so binary is faithful — no n-ary incidence object is needed.
#    [PROVEN-BY-API] node_type / ports / prop key+val are ATTRIBUTES on single
#      sorts. This mirrors the kernel: a single-sorted typed-node store plus a
#      SEPARATE validating operad (CI-5: "enforced at rewrite validation time").
#    DISCIPLINE: this C-set is the fold SHAPE. The operad — 56 type-ids, per-type
#      port sets, the 8-colour port-compatibility MATRIX, per-WF src/tgt types —
#      is an admissibility PREDICATE over instances, NOT the schema. A plain
#      C-set cannot encode the colour matrix; do not try to "make the schema be
#      the operad".  (property = typed/governed, never a free-form payload —
#      hence Property-as-part EAV, never Catlab's SchPropertyGraph dict-bag.)
# ---------------------------------------------------------------------------
@present SchMoosHG(FreeSchema) begin
    (Node, Relation, Property)::Ob
    src::Hom(Relation, Node)          # binary — faithful to the fold shape
    tgt::Hom(Relation, Node)
    owner::Hom(Property, Node)        # each property owned by exactly one node

    (Urn, TypeId, WF, Port, PKey, PVal)::AttrType
    node_urn::Attr(Node, Urn)
    node_type::Attr(Node, TypeId)     # single-sorted + operad-validated (mirrors kernel)
    rel_urn::Attr(Relation, Urn)
    rel_cat::Attr(Relation, WF)       # rewrite_category WF01..WF21
    rel_src_port::Attr(Relation, Port)   # port NAME; colour/legality lives in the operad
    rel_tgt_port::Attr(Relation, Port)
    prop_key::Attr(Property, PKey)
    prop_val::Attr(Property, PVal)
end

# [PROVEN-BY-API] BUGFIX vs the strawman: `@acset_type MoosHG(...) <: ACSet` is a
#   hard arity error — `abstract type ACSet{PT}` takes ONE param but @acset_type's
#   codegen applies the parent with THREE (schema, attrtypes, parts-type). Fix:
#   subtype a 3-param @abstract_acset_type (exactly how Catlab declares Graph).
#   unique_index=[:node_urn] makes incident(hg, urn, :node_urn) O(1).
@abstract_acset_type AbstractMoosHG
@acset_type MoosHG(SchMoosHG, index=[:src, :tgt, :owner],
                   unique_index=[:node_urn]) <: AbstractMoosHG

# Attrtypes bind in DECLARATION order: {Urn, TypeId, WF, Port, PKey, PVal}.
# Folded state mixes property value types, so PVal=Any there. The MUTATE demo
# below uses a PVal=Bool instance for clean AttrVar matching (see §3d caveat).
newhg() = MoosHG{String,String,String,String,String,Any}()

# ---------------------------------------------------------------------------
# 2. Ingest: fold(log) → MoosHG ACSet.  "state = fold(log)" made concrete: the
#    folded state IS a C-set instance.  GET /fold returns
#    {t, log_len, nodes:{urn=>{type_id,properties}},
#     relations:{urn=>{rewrite_category,src_urn,src_port,tgt_urn,tgt_port}}}.
# ---------------------------------------------------------------------------
function fetch_fold(url="http://localhost:8000/fold")
    try
        return JSON3.read(String(take!(Downloads.download(url, IOBuffer()))))
    catch e
        @warn "kernel /fold unreachable ($e) — using inline fixture"
        return JSON3.read("""
        {"t":260,"log_len":3,
         "nodes":[
           {"urn":"urn:moos:session:sam.z440-cowork-workspace","type_id":"session","properties":{"single_occupant":{"value":true}}},
           {"urn":"urn:moos:ki:keep.t259","type_id":"knowledge_item","properties":{"source_type":{"value":"keep"}}}],
         "relations":[
           {"urn":"urn:moos:rel:demo.1","rewrite_category":"WF19","src_urn":"urn:moos:session:sam.z440-cowork-workspace","src_port":"pins-urn","tgt_urn":"urn:moos:ki:keep.t259","tgt_port":"pinned-by-session"}]}""")
    end
end

prop_scalar(v) = v isa AbstractDict && haskey(v, :value) ? v[:value] : v

# [PROVEN-BY-API] unique_index ⇒ O(1) urn→part via `incident` (a Catlab export).
#   Defensive: incident may return a scalar part (unique_index) OR a 0/1-vector
#   depending on version — normalise to a part id or `nothing`.
function node_of(hg, urn)
    p = incident(hg, String(urn), :node_urn)
    if p isa AbstractVector
        isempty(p) ? nothing : first(p)
    else
        p == 0 ? nothing : p
    end
end

function build_acset(fold)::MoosHG
    hg = newhg()
    # GET /fold returns nodes/relations as LISTS of records; each carries its own urn.
    for n in fold.nodes
        v = add_part!(hg, :Node; node_urn=String(n.urn), node_type=String(n.type_id))
        if haskey(n, :properties)
            for (k, pv) in pairs(n.properties)
                add_part!(hg, :Property; owner=v, prop_key=String(k), prop_val=prop_scalar(pv))
            end
        end
    end
    for r in fold.relations
        s = node_of(hg, r.src_urn)
        t = node_of(hg, r.tgt_urn)
        (s === nothing || t === nothing) && continue   # drop dangling — a relation needs both endpoints
        add_part!(hg, :Relation; src=s, tgt=t, rel_urn=String(r.urn),
                  rel_cat=String(r.rewrite_category),
                  rel_src_port=String(get(r, :src_port, "")),
                  rel_tgt_port=String(get(r, :tgt_port, "")))
    end
    hg
end

# ---------------------------------------------------------------------------
# 3. The four rewrites as rewriting rules.
#
#    [PROVEN-BY-API] A Rule is a SPAN  L ⟵l— K —r⟶ R  passed as `Rule(l, r)`:
#      BOTH legs point OUT of the interface K, l: K→L and r: K→R (NOT L→R).
#      Default semantics is DPO. DPO's gluing/dangling condition IS the kernel's
#      referential-integrity guard, so illegal UNLINKs are rejected the same way.
#    [PROVEN-BY-API] The installed 0.17.x / 0.5.0 stack is MODEL-DISPATCHED via
#      GATlab: build a category object once and thread `cat=` through every
#      Rule/homomorphism/rewrite call. `id[cat](X)` / `create[cat](X)` are the
#      indexed-operation forms. VarACSetCat handles BOTH topology-only rules
#      (ADD/LINK/UNLINK) and attribute rebinds (MUTATE), so use it throughout.
# ---------------------------------------------------------------------------
const 𝒱 = ACSetCategory(VarACSetCat(newhg()))   # one category for all four rewrites

# (3a) ADD — ∅ ⟵ ∅ ⟶ {node}.  l = id on the empty interface; r = create(R).
# [PROVEN-BY-API] shape = AlgebraicRewriting DPO.jl "add a part" test.
function rule_add_node(urn::String, typ::String)
    I = newhg()                                   # empty interface = empty pattern L
    R = newhg(); add_part!(R, :Node; node_urn=urn, node_type=typ)
    Rule(id[𝒱](I), create[𝒱](R); cat=𝒱)          # +1 Node per pushout = +1 ADD log append
end

# (3b) LINK — {n1,n2} ⟵ {n1,n2} ⟶ {n1,n2,rel}.  Interface = the two endpoints
# (matched by concrete URN); l = id keeps them; r adds the Relation + WF + ports.
# [PROVEN-BY-API] shape = DPO "add an edge" test.
function rule_link(u1, t1, u2, t2, relurn, wf, sp, tp)
    I = newhg()
    a = add_part!(I, :Node; node_urn=u1, node_type=t1)
    b = add_part!(I, :Node; node_urn=u2, node_type=t2)
    R = copy(I)
    add_part!(R, :Relation; src=a, tgt=b, rel_urn=relurn, rel_cat=wf,
              rel_src_port=sp, rel_tgt_port=tp)
    Rule(id[𝒱](I), homomorphism(I, R; cat=𝒱); cat=𝒱)   # l=id(nodes), r: I↪R adds the relation
end

# (3c) UNLINK — {n1,n2,rel} ⟵ {n1,n2} ⟶ {n1,n2}.  l: K↪L includes the Relation
# to delete; r = id keeps the endpoints. DPO dangling condition auto-guards
# against orphaning — the kernel's referential-integrity invariant, for free.
# [PROVEN-BY-API] shape = DPO "delete an edge" test.
function rule_unlink(u1, t1, u2, t2, relurn, wf, sp, tp)
    K = newhg()
    a = add_part!(K, :Node; node_urn=u1, node_type=t1)
    b = add_part!(K, :Node; node_urn=u2, node_type=t2)
    L = copy(K)
    add_part!(L, :Relation; src=a, tgt=b, rel_urn=relurn, rel_cat=wf,
              rel_src_port=sp, rel_tgt_port=tp)
    Rule(homomorphism(K, L; cat=𝒱), id[𝒱](K); cat=𝒱)   # l: K↪L (has rel), r=id(nodes)
end

# (3d) MUTATE — THE CRUX.  Plain concrete-attribute DPO CANNOT rebind a value in
# place (a morphism must map value v only to v). The installed fix is VARIABLE
# ATTRIBUTES: put AttrVar(1) in prop_val of L (matches ANY current value); re-add
# the Property in R with a new value bound by `expr`. Runs as DPO over VarACSetCat.
# [PROVEN-BY-API] shape = AlgebraicRewriting weighted-graph "merge/rebind" test
#   (test/rewrite/DPO.jl) + full_demo.jl §7 "Attribute variables" + the `expr`
#   constructor discipline ("Must set AttrVar value for newly introduced attribute").
# CAVEAT: this deletes+re-adds the Property row (owner+key identity is stable, so
#   it is observationally the kernel's single MUTATE log entry). Preserving the
#   Property PART itself while rebinding its value under the pure (non-bang)
#   `rewrite_match` is the classically-awkward DPO case → [CONJECTURE] (see below);
#   the proven in-place alternative is `rewrite!` + a concrete value in R (SetAttr).
# We use a PVal=Bool instance so AttrVar attribute-matching stays clean (Any-typed
# attributes can confuse hom-search value comparison).
function mutate_demo()
    T = MoosHG{String,String,String,String,String,Bool}
    G = T()
    n = add_part!(G, :Node; node_urn="urn:moos:session:sam.z440-cowork-workspace", node_type="session")
    add_part!(G, :Property; owner=n, prop_key="single_occupant", prop_val=true)
    𝒲 = ACSetCategory(VarACSetCat(T()))

    L = T()
    nL = add_part!(L, :Node; node_urn="urn:moos:session:sam.z440-cowork-workspace", node_type="session")
    add_part!(L, :PVal)                                   # one attribute variable slot
    add_part!(L, :Property; owner=nL, prop_key="single_occupant", prop_val=AttrVar(1))  # OLD = any value

    K = T()                                              # keep the NODE; the Property row changes
    add_part!(K, :Node; node_urn="urn:moos:session:sam.z440-cowork-workspace", node_type="session")

    R = T()
    nR = add_part!(R, :Node; node_urn="urn:moos:session:sam.z440-cowork-workspace", node_type="session")
    add_part!(R, :PVal)
    add_part!(R, :Property; owner=nR, prop_key="single_occupant", prop_val=AttrVar(1))  # NEW, bound below

    l = homomorphism(K, L; cat=𝒲)
    r = homomorphism(K, R; cat=𝒲)
    # expr binds the fresh AttrVar in R from the matched old value(s): here, toggle.
    rule = Rule(l, r; cat=𝒲, expr=Dict(:PVal => [ old -> !old[1] ]))
    G2 = rewrite(rule, G; cat=𝒲)
    (G, G2, 𝒲)
end

# ---------------------------------------------------------------------------
# 4. Migration verdict scaffolding  (see DECISION.md for the honest ledger).
#   [PROVEN-BY-API] view_filter = Δ_F   : migrate(TgtType, X, DeltaMigration(F))
#   [PROVEN-BY-API] push = Lan_F = Σ_F  : SigmaMigrationFunctor(F, dom, codom)(X)
#                     (Σ_F is the left adjoint to Δ_F; return_unit=true gives η)
#   [CONJECTURE]   branch = cartesian lift of a fibration : NO Catlab
#                   fibration/cartesian_lift API — hand-roll from `elements`
#                   (category of elements / Grothendieck) + `pullback`.
#   NOT on this stack: predicate/join view_filter (conjunctive @migration DSL)
#                   needs DataMigrations.jl, which pins Catlab 0.16 → will not
#                   co-install with 0.17.6. Δ view_filter = projection/reindex only.
# We do not execute a migration here (needs a second schema); the API is real and
# reachable from `using Catlab` — see DECISION.md and the migration dimension.
# ---------------------------------------------------------------------------

function main()
    fold = fetch_fold()
    hg = build_acset(fold)
    n_nodes = nparts(hg, :Node); n_rels = nparts(hg, :Relation); n_props = nparts(hg, :Property)

    println("=== mo:os HG as ACSet  (fold → C-set) ===")
    println("kernel /fold : t=$(fold.t) log_len=$(fold.log_len) " *
            "nodes=$(length(fold.nodes)) relations=$(length(fold.relations))")
    println("ACSet parts  : Node=$n_nodes Relation=$n_rels Property=$n_props")
    println("faithful node count: " *
            (n_nodes == length(fold.nodes) ? "YES — the folded state IS a C-set instance" : "MISMATCH"))

    # ADD as a rewrite: +1 Node.
    println("\n=== ADD as a rewriting rule  (∅ ⟵ ∅ ⟶ {node}) ===")
    add_rule = rule_add_node("urn:moos:derivation:zappa.t260-acset-witness", "derivation")
    hgA = rewrite(add_rule, hg; cat=𝒱)
    dA = nparts(hgA, :Node) - n_nodes
    println("after ADD    : Node=$(nparts(hgA,:Node))  (Δ=$dA)")
    @assert dA == 1 "ADD must append exactly one node"
    println(dA == 1 ? "PASS — one pushout = one ADD = one log append." : "unexpected Δ")

    # LINK as a rewrite: +1 Relation, against two existing endpoints in the fold.
    println("\n=== LINK as a rewriting rule  ({n1,n2} ⟵ {n1,n2} ⟶ {n1,n2,rel}) ===")
    urns = [String(n.urn) for n in fold.nodes]
    if length(urns) >= 2
        u1, u2 = urns[1], urns[2]
        t1 = subpart(hg, node_of(hg, u1), :node_type)
        t2 = subpart(hg, node_of(hg, u2), :node_type)
        link_rule = rule_link(u1, t1, u2, t2, "urn:moos:rel:zappa.t260-witness",
                              "WF12", "provides-kb", "kb-source")
        hgL = rewrite(link_rule, hg; cat=𝒱)
        dL = nparts(hgL, :Relation) - n_rels
        println("after LINK   : Relation=$(nparts(hgL,:Relation))  (Δ=$dL)")
        @assert dL == 1 "LINK must append exactly one relation"
        println(dL == 1 ? "PASS — one pushout = one LINK = one log append." : "unexpected Δ")

        # UNLINK as a rewrite: −1 Relation, removing exactly the relation LINK added.
        # LINK and UNLINK are inverse pushouts — the pushout complement drops the part.
        println("\n=== UNLINK as a rewriting rule  ({n1,n2,rel} ⟵ {n1,n2} ⟶ {n1,n2}) ===")
        unlink_rule = rule_unlink(u1, t1, u2, t2, "urn:moos:rel:zappa.t260-witness",
                                  "WF12", "provides-kb", "kb-source")
        hgU = rewrite(unlink_rule, hgL; cat=𝒱)
        dU = nparts(hgU, :Relation) - nparts(hgL, :Relation)
        println("after UNLINK : Relation=$(nparts(hgU,:Relation))  (Δ=$dU)")
        @assert dU == -1 "UNLINK must remove exactly one relation"
        println(dU == -1 ? "PASS — one pushout-complement = one UNLINK = one log append." : "unexpected Δ")
    else
        println("(skipped — need ≥2 nodes in the fold)")
    end

    # MUTATE as a rewrite: property count unchanged, value flipped true→false.
    println("\n=== MUTATE as a rewriting rule  (attribute rebind via AttrVar+expr) ===")
    Gm, Gm2, _ = mutate_demo()
    v_before = subpart(Gm,  1, :prop_val)
    v_after  = subpart(Gm2, 1, :prop_val)
    dP = nparts(Gm2, :Property) - nparts(Gm, :Property)
    println("single_occupant: $v_before → $v_after   (ΔProperty=$dP)")
    @assert dP == 0 "MUTATE must not change the property count"
    @assert v_after == !v_before "MUTATE must rebind the value"
    println((dP == 0 && v_after == !v_before) ?
        "PASS — value rebound, part-count stable = one MUTATE log entry (one property rebind)." :
        "unexpected MUTATE result")

    println("\nConclusion: ADD/LINK/UNLINK are topology-only DPO rules and MUTATE is a")
    println("variable-attribute DPO rewrite on the mo:os C-set; AlgebraicRewriting")
    println("reproduces the kernel's append semantics (part-count Δ == log Δ).")
    println("This ACSet model is the SEMANTIC ORACLE — the Go kernel stays the runtime.")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
