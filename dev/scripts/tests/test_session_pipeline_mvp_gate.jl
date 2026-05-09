using Test

include(joinpath(@__DIR__, "..", "session_pipeline_mvp_gate.jl"))

const Gate = SessionPipelineMVPGate

prop(value) = Dict(:value => value, :mutability => "mutable")

@testset "Session pipeline MVP gate" begin
    session_urn = Gate.DEFAULT_SESSION_URN
    actor_urn = Gate.DEFAULT_ACTOR_URN
    keep_channel_urn = Gate.DEFAULT_KEEP_CHANNEL_URN
    keep_ki_urn = Gate.DEFAULT_KEEP_KI_URN
    purpose_urn = "urn:moos:purpose:sam.session-pipeline"
    kernel_urn = "urn:moos:kernel:hp-laptop.primary"
    scope_urn = "urn:moos:program:sam.t200plus.visual-projection-lens"

    nodes = [
        Dict(:urn => keep_channel_urn, :type_id => "channel", :properties => Dict(:name => prop("Keep"))),
        Dict(:urn => keep_ki_urn, :type_id => "knowledge_item", :properties => Dict(:status => prop("extracted"))),
        Dict(:urn => session_urn, :type_id => "session", :properties => Dict(:local_t => prop(27))),
        Dict(:urn => actor_urn, :type_id => "agent", :properties => Dict(:status => prop("active"))),
        Dict(:urn => kernel_urn, :type_id => "kernel", :properties => Dict(:status => prop("active"))),
        Dict(:urn => scope_urn, :type_id => "program", :properties => Dict(:status => prop("draft"))),
        Dict(:urn => purpose_urn, :type_id => "purpose", :properties => Dict(:title => prop("Session pipeline"))),
    ]
    relations = [
        Dict(:urn => "rel:keep", :rewrite_category => "WF12", :src_urn => keep_channel_urn, :src_port => "provides-kb", :tgt_urn => keep_ki_urn, :tgt_port => "kb-source"),
    ]
    session_pack = Dict(
        :projection_kind => "session_context_pack",
        :handoff => Dict(:session_header => Dict(:actor => actor_urn, :session_urn => session_urn, :kernel_base_url => "http://localhost:8000")),
        :purpose_color => "Session pipeline",
        :context => Dict(
            :opens_on => [Dict(:urn => kernel_urn)],
            :occupants => [Dict(:urn => actor_urn)],
            :scope_roots => [Dict(:urn => scope_urn)],
            :purposes => [Dict(:urn => purpose_urn)],
        ),
        :affordance_pack => Dict(
            :recommended_skills => [Dict(:name => string("skill", i)) for i in 1:5],
            :recommended_extensions => [Dict(:id => "upstash.context7-mcp")],
            :mcp_servers => [Dict(:name => "moos-primary")],
        ),
    )
    graph_pack = Dict(
        :projection_kind => "graph_artifact_engineering",
        :node_count => 4,
        :relation_count => 3,
        :nodes => [
            Dict(:urn => "urn:moos:derivation:demo", :type_id => "derivation", :title => "Demo derivation", :status => "closed"),
            Dict(:urn => "urn:moos:claim:demo", :type_id => "claim", :title => "Demo claim", :status => "open"),
        ],
        :relations => [
            Dict(:urn => "urn:moos:rel:demo.causes.claim", :rewrite_category => "WF21", :src_urn => "urn:moos:derivation:demo", :src_port => "causes", :tgt_urn => "urn:moos:claim:demo", :tgt_port => "caused-by"),
        ],
        :root_urns => ["urn:moos:derivation:demo"],
        :filters => Dict(:wfs => ["WF21"], :ports => ["causes"], :types => ["claim"], :match => "session"),
        :analysis => Dict(:root_coverage => [Dict(:urn => "urn:moos:derivation:demo", :connected => true)]),
    )

    mktempdir() do dir
        dot_path = joinpath(dir, "frame.dot")
        svg_path = joinpath(dir, "frame.svg")
        temporal_dot_path = joinpath(dir, "temporal.dot")
        temporal_svg_path = joinpath(dir, "temporal.svg")
        calendar_plan_path = joinpath(dir, "calendar_plan.json")
        calendar_report_path = joinpath(dir, "calendar_plan.md")
        recommendation_plan_path = joinpath(dir, "recommendation_plan.json")
        recommendation_report_path = joinpath(dir, "recommendation_plan.md")
        write(dot_path, "digraph g {}")
        write(svg_path, "<svg></svg>")
        write(temporal_dot_path, "digraph temporal {}")
        write(temporal_svg_path, "<svg></svg>")
        write(calendar_plan_path, "{\"event_count\":2,\"events\":[{},{}]}\n")
        write(calendar_report_path, "# Calendar report\n")
        write(recommendation_plan_path, "{\"candidate_node_count\":8,\"selected_t189_recommendations\":[{},{},{},{},{}]}\n")
        write(recommendation_report_path, "# Recommendation report\n")
        plan = Gate.plan_mvp_gate(
            nodes,
            relations;
            health=Dict(:status => "ok", :ontology_version => "3.16.1", :t_day => 188, :log_len => 1079),
            session_pack=session_pack,
            graph_pack=graph_pack,
            dot_path=dot_path,
            svg_path=svg_path,
            temporal_dot_path=temporal_dot_path,
            temporal_svg_path=temporal_svg_path,
            calendar_plan_path=calendar_plan_path,
            calendar_report_path=calendar_report_path,
            recommendation_plan_path=recommendation_plan_path,
            recommendation_report_path=recommendation_report_path,
            generated_at="2026-05-08T11:30:00Z",
        )

        @test plan["projection_kind"] == "session_pipeline_mvp_gate"
        @test plan["overall_status"] == "pass"
        @test plan["summary"]["fail"] == 0
        @test plan["summary"]["warn"] == 0
        names = Set(gate["name"] for gate in plan["gates"])
        @test "G input channel" in names
        @test "F session handoff header" in names
        @test "visual lens root coverage" in names
        @test "Calendar time-fabric artifacts" in names
        @test "T189/T200 recommendation artifacts" in names
        @test plan["lingo"]["lens"] != ""
        @test plan["lingo"]["Calendar_projection"] != ""
        @test plan["lingo"]["Recommendation_projection"] != ""
        @test plan["renderer_candidates"][2]["name"] == "Cytoscape.js"
        @test plan["interactive_inspector"]["node_count"] == 2
        @test plan["interactive_inspector"]["relation_count"] == 1
        @test length(plan["pipeline_stages"]) == 4
        @test plan["pipeline_stages"][1]["status"] == "pass"
        @test plan["pipeline_stages"][3]["summary"]["pass"] == 6
        @test isempty(plan["priority_actions"])

        html_path = joinpath(dir, "index.html")
        Gate.write_html(html_path, plan)
        @test isfile(html_path)
        html = read(html_path, String)
        @test occursin("Session Pipeline MVP", html)
        @test occursin("G-ingest", html)
        @test occursin("Calendar Time-Fabric", html)
        @test occursin("HG Recommendations", html)
        @test occursin("Interactive HG Inspector", html)
        @test occursin("inspectorData", html)
        @test occursin("Cytoscape.js", html)
    end
end

@testset "Session pipeline MVP gaps" begin
    nodes = [
        Dict(:urn => Gate.DEFAULT_KEEP_CHANNEL_URN, :type_id => "channel", :properties => Dict()),
        Dict(:urn => Gate.DEFAULT_KEEP_KI_URN, :type_id => "knowledge_item", :properties => Dict()),
    ]
    session_pack = Dict(
        :handoff => Dict(:session_header => Dict(:actor => Gate.DEFAULT_ACTOR_URN, :session_urn => Gate.DEFAULT_SESSION_URN)),
        :context => Dict(:opens_on => [], :occupants => [], :scope_roots => [], :purposes => []),
        :affordance_pack => Dict(:recommended_skills => [], :recommended_extensions => [], :mcp_servers => []),
    )
    graph_pack = Dict(
        :projection_kind => "graph_artifact_engineering",
        :node_count => 2,
        :relation_count => 1,
        :root_urns => ["urn:root", "urn:forced"],
        :filters => Dict(:wfs => ["WF21"], :ports => ["causes"], :types => ["claim"]),
        :analysis => Dict(:root_coverage => [
            Dict(:urn => "urn:root", :connected => true),
            Dict(:urn => "urn:forced", :connected => false),
        ]),
    )
    plan = Gate.plan_mvp_gate(
        nodes,
        Any[];
        health=Dict(:status => "ok"),
        session_pack=session_pack,
        graph_pack=graph_pack,
        dot_path="missing.dot",
        svg_path="missing.svg",
        generated_at="2026-05-08T11:30:00Z",
    )

    @test plan["overall_status"] == "fail"
    topics = Dict(gate["name"] => gate["status"] for gate in plan["gates"])
    @test topics["G input evidence topology"] == "fail"
    @test topics["session occasion topology"] == "fail"
    @test topics["visual lens root coverage"] == "warn"
end
