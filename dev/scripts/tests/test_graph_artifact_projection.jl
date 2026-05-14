using Test

include(joinpath(@__DIR__, "..", "graph_artifact_projection.jl"))

const GAP = GraphArtifactProjection

prop(value) = Dict(:value => value, :mutability => "mutable")

@testset "Graph artifact projection" begin
    root_urn = "urn:moos:derivation:demo.frame"
    grammar_urn = "urn:moos:grammar_fragment:v317-1-occasion-type"
    pattern_urn = "urn:moos:pattern:session-affordance-pack"
    workflow_urn = "urn:moos:workflow:z440-session-continuity-reconciliation"
    session_urn = "urn:moos:session:sam.governance"
    agent_urn = "urn:moos:agent:vscode.hp-laptop.copilot"
    group_urn = "urn:moos:group:sam"

    nodes = [
        Dict(:urn => root_urn, :type_id => "derivation", :properties => Dict(:name => prop("Demo frame"), :status => prop("closed"))),
        Dict(:urn => grammar_urn, :type_id => "grammar_fragment", :properties => Dict(:name => prop("occasion type"), :status => prop("proposed"))),
        Dict(:urn => pattern_urn, :type_id => "pattern", :properties => Dict(:name => prop("affordance pack"), :status => prop("draft"))),
        Dict(:urn => workflow_urn, :type_id => "workflow", :properties => Dict(:name => prop("z440 reconciliation"), :status => prop("draft"))),
        Dict(:urn => session_urn, :type_id => "session", :properties => Dict(:name => prop("Governance"))),
        Dict(:urn => agent_urn, :type_id => "agent", :properties => Dict(:name => prop("VS Code Copilot"), :status => prop("active"))),
        Dict(:urn => group_urn, :type_id => "group", :properties => Dict(:name => prop("Sam group"))),
    ]
    relations = [
        Dict(:urn => "rel:g", :rewrite_category => "WF21", :src_urn => root_urn, :src_port => "causes", :tgt_urn => grammar_urn, :tgt_port => "caused-by"),
        Dict(:urn => "rel:p", :rewrite_category => "WF21", :src_urn => root_urn, :src_port => "causes", :tgt_urn => pattern_urn, :tgt_port => "caused-by"),
        Dict(:urn => "rel:w", :rewrite_category => "WF21", :src_urn => root_urn, :src_port => "causes", :tgt_urn => workflow_urn, :tgt_port => "caused-by"),
        Dict(:urn => "rel:s", :rewrite_category => "WF18", :src_urn => root_urn, :src_port => "composes", :tgt_urn => session_urn, :tgt_port => "composed-by"),
        Dict(:urn => "rel:occupant", :rewrite_category => "WF19", :src_urn => session_urn, :src_port => "has-occupant", :tgt_urn => agent_urn, :tgt_port => "is-occupant-of"),
        Dict(:urn => "rel:group-owns-agent", :rewrite_category => "WF01", :src_urn => group_urn, :src_port => "owns", :tgt_urn => agent_urn, :tgt_port => "owned-by"),
        Dict(:urn => "rel:group-owns-session", :rewrite_category => "WF01", :src_urn => group_urn, :src_port => "owns", :tgt_urn => session_urn, :tgt_port => "owned-by"),
    ]

    plan = GAP.plan_graph_artifact_projection(
        nodes,
        relations;
        root_urn=root_urn,
        root_urns=[root_urn],
        radius=1,
        wf_filter=GAP.split_set("WF18,WF21"),
        port_filter=GAP.split_set("causes,caused-by,composes,composed-by"),
        type_filter=GAP.split_set("derivation,grammar_fragment,pattern,workflow,session"),
        match_pattern="",
        health=Dict("log_len" => 1079),
        generated_at="2026-05-07T16:00:00Z",
    )

    @test plan["projection_kind"] == "graph_artifact_engineering"
    @test plan["node_count"] == 7
    @test plan["relation_count"] == 7
    @test plan["analysis"]["type_counts"]["grammar_fragment"] == 1
    @test plan["analysis"]["type_counts"]["agent"] == 1
    @test plan["analysis"]["type_counts"]["group"] == 1
    @test plan["analysis"]["agent_neighborhood"]["agent_urns"] == [agent_urn]
    @test Set(plan["analysis"]["agent_neighborhood"]["relation_urns"]) == Set(["rel:occupant", "rel:group-owns-agent", "rel:group-owns-session"])
    @test group_urn in plan["analysis"]["agent_neighborhood"]["context_urns"]
    @test length(plan["analysis"]["root_coverage"]) == 1
    @test plan["analysis"]["root_coverage"][1]["connected"] == true
    @test plan["analysis"]["root_coverage"][1]["incident_relation_count"] == 4
    topics = Set(finding["topic"] for finding in plan["engineering"]["findings"])
    @test "grammar fragment proposed" in topics
    @test "workflow draft" in topics
    @test "pattern draft" in topics
    @test "session missing has-purpose in projection" in topics
end

@testset "Explicit context agent projection" begin
    root_urn = "urn:moos:derivation:demo.frame"
    claim_urn = "urn:moos:claim:demo"
    session_urn = "urn:moos:session:sam.governance"
    agent_urn = "urn:moos:agent:vscode.hp-laptop.copilot"
    group_urn = "urn:moos:group:sam"
    nodes = [
        Dict(:urn => root_urn, :type_id => "derivation", :properties => Dict(:name => prop("Demo frame"), :status => prop("closed"))),
        Dict(:urn => claim_urn, :type_id => "claim", :properties => Dict(:name => prop("Demo claim"), :status => prop("open"))),
        Dict(:urn => session_urn, :type_id => "session", :properties => Dict(:name => prop("Governance"))),
        Dict(:urn => agent_urn, :type_id => "agent", :properties => Dict(:name => prop("VS Code Copilot"), :status => prop("active"))),
        Dict(:urn => group_urn, :type_id => "group", :properties => Dict(:name => prop("Sam group"))),
    ]
    relations = [
        Dict(:urn => "rel:c", :rewrite_category => "WF21", :src_urn => root_urn, :src_port => "causes", :tgt_urn => claim_urn, :tgt_port => "caused-by"),
        Dict(:urn => "rel:occupant", :rewrite_category => "WF19", :src_urn => session_urn, :src_port => "has-occupant", :tgt_urn => agent_urn, :tgt_port => "is-occupant-of"),
        Dict(:urn => "rel:group-owns-agent", :rewrite_category => "WF01", :src_urn => group_urn, :src_port => "owns", :tgt_urn => agent_urn, :tgt_port => "owned-by"),
    ]

    plan = GAP.plan_graph_artifact_projection(
        nodes,
        relations;
        root_urn=root_urn,
        root_urns=[root_urn],
        radius=1,
        wf_filter=GAP.split_set("WF21"),
        port_filter=GAP.split_set("causes,caused-by"),
        type_filter=GAP.split_set("derivation,claim"),
        match_pattern="",
        context_agent_urns=[agent_urn],
        generated_at="2026-05-07T16:00:00Z",
    )

    @test plan["node_count"] == 5
    @test plan["relation_count"] == 3
    @test plan["filters"]["context_agent_urns"] == [agent_urn]
    @test plan["analysis"]["type_counts"]["agent"] == 1
    @test plan["analysis"]["type_counts"]["session"] == 1
    @test plan["analysis"]["type_counts"]["group"] == 1
    @test Set(plan["analysis"]["agent_neighborhood"]["relation_urns"]) == Set(["rel:occupant", "rel:group-owns-agent"])
end

@testset "Disconnected forced roots" begin
    root_urn = "urn:moos:derivation:demo.frame"
    pattern_urn = "urn:moos:pattern:session-affordance-pack"
    nodes = [
        Dict(:urn => root_urn, :type_id => "derivation", :properties => Dict(:name => prop("Demo frame"), :status => prop("closed"))),
        Dict(:urn => pattern_urn, :type_id => "pattern", :properties => Dict(:name => prop("affordance pack"), :status => prop("draft"))),
    ]

    plan = GAP.plan_graph_artifact_projection(
        nodes,
        Any[];
        root_urn=root_urn,
        root_urns=[root_urn, pattern_urn],
        radius=1,
        wf_filter=GAP.split_set("WF18,WF21"),
        port_filter=GAP.split_set("causes,caused-by,composes,composed-by"),
        type_filter=GAP.split_set("derivation,pattern"),
        match_pattern="",
        generated_at="2026-05-07T16:00:00Z",
    )

    @test plan["node_count"] == 2
    @test plan["relation_count"] == 0
    @test all(entry["connected"] == false for entry in plan["analysis"]["root_coverage"])
    topics = Set(finding["topic"] for finding in plan["engineering"]["findings"])
    @test "pattern draft" in topics
    @test "roots disconnected in projection" in topics
end
