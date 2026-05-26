using Test

include(joinpath(@__DIR__, "..", "t206_keep_mvp_delivery.jl"))

const T206 = T206KeepMVPDelivery

function node(urn, type_id)
    Dict(:urn => urn, :type_id => type_id, :properties => Dict())
end

@testset "T206 Keep MVP delivery" begin
    nodes = Any[
        node(T206.DEFAULT_SESSION_URN, "session"),
        node(T206.KEEP_CHANNEL, "channel"),
        node(T206.BIG_PROGRAM, "program"),
        node(T206.S0_STAGING_SESSION, "session"),
        node(T206.CALENDAR_READBACK_SESSION, "session"),
    ]
    envelopes, skipped = T206.build_envelopes(nodes, Any[])

    @test isempty(skipped)
    @test any(env -> env["rewrite_type"] == "ADD" && env["node_urn"] == T206.T206_PROGRAM, envelopes)
    @test any(env -> env["rewrite_type"] == "ADD" && env["node_urn"] == T206.T206_KI, envelopes)
    @test any(env -> env["rewrite_type"] == "ADD" && env["node_urn"] == T206.T206_EXTERNAL_OP, envelopes)
    @test count(env -> env["rewrite_type"] == "ADD" && get(env, "type_id", "") == "claim", envelopes) == length(T206.T206_CLAIMS)
    @test all(env -> get(env, "session_urn", "") == T206.DEFAULT_SESSION_URN, envelopes)
    @test !any(env -> get(env, "rewrite_category", "") == "WF07", envelopes)
    @test any(env -> get(env, "rewrite_category", "") == "WF12" && env["src_urn"] == T206.KEEP_CHANNEL && env["tgt_urn"] == T206.T206_KI, envelopes)
    @test any(env -> get(env, "rewrite_category", "") == "WF21" && env["src_urn"] == T206.T206_KI && env["tgt_urn"] == T206.T206_DERIVATION, envelopes)
    @test any(env -> get(env, "rewrite_category", "") == "WF19" && env["src_urn"] == T206.DEFAULT_SESSION_URN && env["tgt_urn"] == T206.T206_EXTERNAL_OP, envelopes)

    existing_nodes = vcat(nodes, [node(spec["urn"], spec["type_id"]) for spec in T206.node_specs()])
    existing_relation = Dict(:rewrite_category => "WF12", :src_urn => T206.KEEP_CHANNEL, :src_port => "provides-kb", :tgt_urn => T206.T206_KI, :tgt_port => "kb-source")
    second_envelopes, second_skipped = T206.build_envelopes(existing_nodes, Any[existing_relation])
    @test length(second_skipped) == length(T206.node_specs())
    @test !any(env -> env["rewrite_type"] == "ADD", second_envelopes)
    @test !any(env -> get(env, "rewrite_category", "") == "WF07", second_envelopes)
end