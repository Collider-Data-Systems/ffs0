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
        :identity => Dict(
            :status => "pass",
            :actor_urn => actor_urn,
            :actor_node_exists => true,
            :actor_is_hg_occupant => true,
            :hg_occupant_urns => [actor_urn],
            :harness_kind => "VS Code/Copilot",
            :harness_agent_urn => actor_urn,
            :harness_agent_node_exists => true,
            :harness_agent_is_hg_occupant => true,
            :harness_matches_actor => true,
            :reasons => ["actor_urn, HG occupant, and harness candidate agree"],
        ),
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
            Dict(:urn => actor_urn, :type_id => "agent", :title => "VS Code Copilot", :status => "active"),
        ],
        :relations => [
            Dict(:urn => "urn:moos:rel:demo.causes.claim", :rewrite_category => "WF21", :src_urn => "urn:moos:derivation:demo", :src_port => "causes", :tgt_urn => "urn:moos:claim:demo", :tgt_port => "caused-by"),
        ],
        :root_urns => ["urn:moos:derivation:demo"],
        :filters => Dict(:wfs => ["WF21"], :ports => ["causes"], :types => ["claim"], :match => "session"),
        :analysis => Dict(:root_coverage => [Dict(:urn => "urn:moos:derivation:demo", :connected => true)], :type_counts => Dict(:agent => 1)),
    )
    t189_graph_pack = Dict(
        :projection_kind => "graph_artifact_engineering",
        :node_count => 8,
        :relation_count => 8,
        :nodes => [
            Dict(:urn => "urn:moos:purpose:t189", :type_id => "purpose", :title => "T189 convergence", :status => "open"),
            Dict(:urn => "urn:moos:program:t189", :type_id => "program", :title => "T189 program", :status => "draft"),
            Dict(:urn => actor_urn, :type_id => "agent", :title => "VS Code Copilot", :status => "active"),
        ],
        :relations => [
            Dict(:urn => "urn:moos:rel:t189", :rewrite_category => "WF18", :src_urn => "urn:moos:purpose:t189", :src_port => "composes", :tgt_urn => "urn:moos:program:t189", :tgt_port => "composed-by"),
        ],
        :root_urns => ["urn:moos:purpose:t189"],
        :filters => Dict(:wfs => ["WF18", "WF19"], :ports => ["composes", "pins-urn"], :types => ["purpose", "program"], :match => "t189"),
        :analysis => Dict(:root_coverage => [Dict(:urn => "urn:moos:purpose:t189", :connected => true)], :type_counts => Dict(:agent => 1)),
    )
    temporal_graph_pack = Dict(
        :projection_kind => "graph_artifact_engineering",
        :node_count => 6,
        :relation_count => 4,
        :nodes => [
            Dict(:urn => "urn:moos:program:temporal", :type_id => "program", :title => "Temporal fabric", :status => "active"),
            Dict(:urn => "urn:moos:channel:calendar", :type_id => "channel", :title => "Calendar channel", :status => "active"),
            Dict(:urn => actor_urn, :type_id => "agent", :title => "VS Code Copilot", :status => "active"),
        ],
        :relations => [
            Dict(:urn => "urn:moos:rel:temporal", :rewrite_category => "WF18", :src_urn => "urn:moos:program:temporal", :src_port => "composes", :tgt_urn => "urn:moos:channel:calendar", :tgt_port => "composed-by"),
        ],
        :root_urns => ["urn:moos:program:temporal"],
        :filters => Dict(:wfs => ["WF18", "WF19", "WF21"], :ports => ["composes", "pins-urn"], :types => ["program", "channel"], :match => "calendar"),
        :analysis => Dict(:root_coverage => [Dict(:urn => "urn:moos:program:temporal", :connected => true)], :type_counts => Dict(:agent => 1)),
    )
    calendar_scope_graph_pack = Dict(
        :projection_kind => "graph_artifact_engineering",
        :node_count => 12,
        :relation_count => 10,
        :nodes => [
            Dict(:urn => "urn:moos:channel:google.calendar.sam", :type_id => "channel", :title => "Google Calendar", :status => "active"),
            Dict(:urn => "urn:moos:program:sam.t200plus.temporal-projection-fabric", :type_id => "program", :title => "Temporal fabric", :status => "active"),
            Dict(:urn => actor_urn, :type_id => "agent", :title => "VS Code Copilot", :status => "active"),
        ],
        :relations => [
            Dict(:urn => "urn:moos:rel:calendar.scope", :rewrite_category => "WF18", :src_urn => "urn:moos:program:sam.t200plus.temporal-projection-fabric", :src_port => "composes", :tgt_urn => "urn:moos:channel:google.calendar.sam", :tgt_port => "composed-by"),
        ],
        :root_urns => ["urn:moos:program:sam.t200plus.temporal-projection-fabric"],
        :filters => Dict(:wfs => ["WF18", "WF19", "WF21"], :ports => [], :types => ["program", "channel"], :match => "calendar"),
        :analysis => Dict(:root_coverage => [Dict(:urn => "urn:moos:program:sam.t200plus.temporal-projection-fabric", :connected => true)], :component_count => 1, :largest_component_size => 3, :type_counts => Dict(:agent => 1)),
    )

    mktempdir() do dir
        dot_path = joinpath(dir, "frame.dot")
        svg_path = joinpath(dir, "frame.svg")
        temporal_dot_path = joinpath(dir, "temporal.dot")
        temporal_svg_path = joinpath(dir, "temporal.svg")
        t189_dot_path = joinpath(dir, "t189.dot")
        t189_svg_path = joinpath(dir, "t189.svg")
        calendar_scope_dot_path = joinpath(dir, "calendar_scope.dot")
        calendar_scope_svg_path = joinpath(dir, "calendar_scope.svg")
        calendar_plan_path = joinpath(dir, "calendar_plan.json")
        calendar_report_path = joinpath(dir, "calendar_plan.md")
        recommendation_plan_path = joinpath(dir, "recommendation_plan.json")
        recommendation_report_path = joinpath(dir, "recommendation_plan.md")
        reconciliation_path = joinpath(dir, "reconciliation.json")
        reconciliation_report_path = joinpath(dir, "reconciliation.md")
        atlas_path = joinpath(dir, "surface_context_atlas.json")
        atlas_report_path = joinpath(dir, "surface_context_atlas.md")
        one_shot_apply_script_path = joinpath(dir, "apply_t189_grouped.ps1")
        write(dot_path, "digraph g {}")
        write(svg_path, "<svg></svg>")
        write(temporal_dot_path, "digraph temporal {}")
        write(temporal_svg_path, "<svg></svg>")
        write(t189_dot_path, "digraph t189 {}")
        write(t189_svg_path, "<svg></svg>")
        write(calendar_scope_dot_path, "digraph calendar_scope {}")
        write(calendar_scope_svg_path, "<svg></svg>")
        write(calendar_plan_path, "{\"event_count\":2,\"events\":[{},{}]}\n")
        write(calendar_report_path, "# Calendar report\n")
        write(recommendation_plan_path, "{\"candidate_node_count\":8,\"selected_t189_recommendations\":[{},{},{},{},{}]}\n")
        write(recommendation_report_path, "# Recommendation report\n")
        write(reconciliation_path, "{\"summary\":{\"grouped_nodes_applied\":10,\"grouped_nodes_total\":10,\"grouped_relations_applied\":16,\"grouped_relations_total\":16,\"calendar_event_nodes_applied\":16,\"calendar_event_nodes_total\":16,\"calendar_event_nodes_pending\":0,\"calendar_event_relations_applied\":16,\"calendar_event_relations_total\":16,\"calendar_event_relations_pending\":0,\"calendar_anchor_relations_applied\":16,\"calendar_anchor_relations_total\":16,\"calendar_anchor_relations_pending\":0,\"deferred_relations\":0,\"grouped_nodes_ok\":true,\"grouped_relations_ok\":true}}\n")
        write(reconciliation_report_path, "# Reconciliation report\n")
        write(atlas_path, "{\"projection_kind\":\"surface_context_atlas\",\"surfaces\":[{},{},{},{},{},{}],\"pending_moves\":[{},{},{},{},{}]}\n")
        write(atlas_report_path, "# Surface Context Atlas\n")
        plan = Gate.plan_mvp_gate(
            nodes,
            relations;
            health=Dict(:status => "ok", :ontology_version => "3.16.1", :t_day => 188, :log_len => 1079),
            session_pack=session_pack,
            graph_pack=graph_pack,
            temporal_graph_pack=temporal_graph_pack,
            t189_graph_pack=t189_graph_pack,
            calendar_scope_graph_pack=calendar_scope_graph_pack,
            dot_path=dot_path,
            svg_path=svg_path,
            temporal_dot_path=temporal_dot_path,
            temporal_svg_path=temporal_svg_path,
            t189_dot_path=t189_dot_path,
            t189_svg_path=t189_svg_path,
            calendar_scope_dot_path=calendar_scope_dot_path,
            calendar_scope_svg_path=calendar_scope_svg_path,
            calendar_plan_path=calendar_plan_path,
            calendar_report_path=calendar_report_path,
            recommendation_plan_path=recommendation_plan_path,
            recommendation_report_path=recommendation_report_path,
            reconciliation_path=reconciliation_path,
            reconciliation_report_path=reconciliation_report_path,
            atlas_path=atlas_path,
            atlas_report_path=atlas_report_path,
            one_shot_apply_script_path=one_shot_apply_script_path,
            generated_at="2026-05-08T11:30:00Z",
        )

        @test plan["projection_kind"] == "session_pipeline_mvp_gate"
        @test plan["overall_status"] == "pass"
        @test plan["summary"]["fail"] == 0
        @test plan["summary"]["warn"] == 0
        names = Set(gate["name"] for gate in plan["gates"])
        @test "G input channel" in names
        @test "F session handoff header" in names
        @test "session actor/occupant reconciliation" in names
        @test "visual lens root coverage" in names
        @test "Temporal Calendar lens" in names
        @test "Calendar time-fabric artifacts" in names
        @test "T189/T200 recommendation artifacts" in names
        @test "T189 recommendation lens" in names
        @test "Calendar scope lens" in names
        @test "T189 recommendation reconciliation" in names
        @test "deferred apply boundaries" in names
        @test "agent neighborhood visibility" in names
        @test "surface context atlas" in names
        @test "one-shot apply script cleanup" in names
        @test plan["lingo"]["lens"] != ""
        @test plan["lingo"]["reconciliation"] != ""
        @test plan["lingo"]["Calendar_projection"] != ""
        @test plan["lingo"]["Recommendation_projection"] != ""
        @test plan["lingo"]["SVG_zoom_pane"] != ""
        @test plan["lingo"]["HG_inspector"] != ""
        @test plan["lingo"]["HG_occupant"] != ""
        @test plan["lingo"]["IDE_harness_surface"] != ""
        @test plan["lingo"]["actor_occupant_reconciliation"] != ""
        @test plan["lingo"]["agent_neighborhood_lens"] != ""
        @test plan["lingo"]["F_G_role_color"] != ""
        @test plan["lingo"]["relation_family_insight"] != ""
        @test plan["renderer_candidates"][2]["name"] == "Cytoscape.js"
        @test any(candidate["name"] == "svg-pan-zoom" for candidate in plan["renderer_candidates"])
        @test any(candidate["name"] == "GraphMakie + Graphs.jl" for candidate in plan["renderer_candidates"])
        @test any(candidate["name"] == "ELK / Dagre hierarchical layout" for candidate in plan["renderer_candidates"])
        @test length(plan["visual_stack_notes"]) == 4
        @test plan["interactive_inspector"]["node_count"] == 3
        @test plan["interactive_inspector"]["relation_count"] == 1
        @test plan["interactive_inspector"]["type_counts"]["agent"] == 1
        @test plan["interactive_inspector"]["agent_urns"] == [actor_urn]
        @test plan["interactive_inspector"]["fg_counts"]["authority"] == 1
        @test plan["interactive_inspector"]["fg_counts"]["g-evidence"] == 1
        @test plan["interactive_inspector"]["relation_family_counts"]["causal lineage"] == 1
        @test any(node["fg_role"] == "lineage" for node in plan["interactive_inspector"]["top_nodes"])
        @test length(plan["interactive_inspectors"]) == 4
        @test plan["interactive_inspectors"][2]["label"] == "Calendar Time-Fabric"
        @test plan["interactive_inspectors"][3]["label"] == "T189 Recommendations"
        @test plan["interactive_inspectors"][4]["label"] == "Calendar Scope"
        @test length(plan["pipeline_stages"]) == 4
        @test plan["pipeline_stages"][1]["status"] == "pass"
        @test plan["pipeline_stages"][3]["summary"]["pass"] == 12
        @test isempty(plan["priority_actions"])

        html_path = joinpath(dir, "index.html")
        Gate.write_html(html_path, plan)
        @test isfile(html_path)
        html = read(html_path, String)
        @test occursin("Session Pipeline MVP", html)
        @test occursin("G-ingest", html)
        @test occursin("Calendar Time-Fabric", html)
        @test occursin("HG Recommendations", html)
        @test occursin("Visual Lenses", html)
        @test occursin("F/G Relation Insights", html)
        @test occursin("Graphview Stack Notes", html)
        @test occursin("Renderer separation", html)
        @test occursin("causal lineage", html)
        @test occursin("authority", html)
        @test occursin("SVG zoom pane", html)
        @test occursin("Static Graphviz proof frame", html)
        @test occursin("data-svg-panel", html)
        @test occursin("data-svg-action=\"fit\"", html)
        @test occursin("data-svg-action=\"svg-find\"", html)
        @test occursin("data-svg-action=\"center\"", html)
        @test occursin("data-svg-action=\"zoom-in\"", html)
        @test occursin("data-svg-action=\"zoom-out\"", html)
        @test occursin("data-svg-action=\"reset\"", html)
        @test occursin("data-svg-action=\"wide\"", html)
        @test occursin("svgBackdrop", html)
        @test length(collect(eachmatch(r"<div class=\"visualPanel\" data-svg-panel", html))) == 4
        @test occursin("T189 Recommendations", html)
        @test occursin("Calendar Scope", html)
        @test occursin("Review Surfaces", html)
        @test occursin("cySearch", html)
        @test occursin("cyTypeFilters", html)
        @test occursin("cyRelationFilters", html)
        @test occursin("cyWide", html)
        @test occursin("inspectorBackdrop", html)
        @test occursin("cyZoomIn", html)
        @test occursin("cyZoomOut", html)
        @test occursin("cyCircle", html)
        @test occursin("cyBreadth", html)
        @test occursin("cyConcentric", html)
        @test occursin("cyAgents", html)
        @test occursin("cyNeighborhood", html)
        @test occursin("cyExport", html)
        @test occursin("Open Graph Artifact", html)
        @test occursin("Open Reconciliation", html)
        @test occursin("Surface Context Atlas", html)
        @test occursin("Open Atlas Report", html)
        @test occursin("Interactive HG Inspector", html)
        @test occursin("inspectorData", html)
        @test occursin("inspectorsData", html)
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
        atlas_path="missing-atlas.json",
        atlas_report_path="missing-atlas.md",
        generated_at="2026-05-08T11:30:00Z",
    )

    @test plan["overall_status"] == "fail"
    topics = Dict(gate["name"] => gate["status"] for gate in plan["gates"])
    @test topics["G input evidence topology"] == "fail"
    @test topics["session occasion topology"] == "fail"
    @test topics["visual lens root coverage"] == "warn"
end
