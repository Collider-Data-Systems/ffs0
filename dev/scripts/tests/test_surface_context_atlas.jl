using Test

include(joinpath(@__DIR__, "..", "surface_context_atlas.jl"))

const Atlas = SurfaceContextAtlas

prop(value) = Dict(:value => value, :mutability => "mutable")

@testset "Surface context atlas" begin
    nodes = [
        Dict(:urn => "urn:moos:derivation:guido.architecture-syntax-interpretation", :type_id => "derivation", :properties => Dict(:name => prop("Architecture syntax interpretation"))),
        Dict(:urn => "urn:moos:grammar_fragment:v316-1-depends-on", :type_id => "grammar_fragment", :properties => Dict(:name => prop("depends-on"))),
        Dict(:urn => "urn:moos:program:sam.t189.surface-context-atlas", :type_id => "program", :properties => Dict(:title => prop("Surface context atlas"), :status => prop("active"))),
        Dict(:urn => "urn:moos:program:sam.t189.cytoscape-typed-hg-inspector", :type_id => "program", :properties => Dict(:title => prop("Cytoscape typed HG inspector"), :status => prop("open"))),
        Dict(:urn => "urn:moos:view_filter:sam.t189-time-fabric-session-lens", :type_id => "view_filter", :properties => Dict(:title => prop("T189 time fabric session lens"))),
        Dict(:urn => "urn:moos:derivation:guido.t200plus.visual-projection-frame", :type_id => "derivation", :properties => Dict(:name => prop("Visual projection frame"))),
        Dict(:urn => "urn:moos:program:sam.t200plus.visual-projection-lens", :type_id => "program", :properties => Dict(:title => prop("T200+ visual projection lens"))),
        Dict(:urn => "urn:moos:view_filter:sam.t200plus-visual-projection-lens", :type_id => "view_filter", :properties => Dict(:title => prop("T200+ visual projection lens"))),
        Dict(:urn => "urn:moos:group:my-tiny-data-collider", :type_id => "group", :properties => Dict(:name => prop("my-tiny-data-collider"))),
        Dict(:urn => "urn:moos:purpose:sam.my-tiny-data-collider-application", :type_id => "purpose", :properties => Dict(:title => prop("Tiny Data Collider application"))),
        Dict(:urn => "urn:moos:program:sam.t192.application-group-model-my-tiny-data-collider", :type_id => "program", :properties => Dict(:title => prop("Application website DNS GitHub Calendar surface map"), :status => prop("planned"))),
        Dict(:urn => "urn:moos:program:sam.t200plus.google-calendar-projection-contract", :type_id => "program", :properties => Dict(:title => prop("Google Calendar projection contract"), :status => prop("active"))),
    ]
    relations = [
        Dict(:urn => "urn:moos:rel:visual.causes.program", :rewrite_category => "WF21", :src_urn => "urn:moos:derivation:guido.t200plus.visual-projection-frame", :src_port => "causes", :tgt_urn => "urn:moos:program:sam.t200plus.visual-projection-lens", :tgt_port => "caused-by"),
        Dict(:urn => "urn:moos:rel:program.anchors.calendar", :rewrite_category => "WF07", :src_urn => "urn:moos:program:sam.t200plus.google-calendar-projection-contract", :src_port => "anchors", :tgt_urn => "urn:moos:program:sam.t192.application-group-model-my-tiny-data-collider", :tgt_port => "anchor"),
    ]
    ontology = Dict(:rewrite_categories => [
        Dict(:id => "WF07", :src_port => "participates", :tgt_port => "participated-by", :additional_port_pairs => [Dict(:src_port => "anchors", :tgt_port => "anchor")]),
    ])
    calendar_plan = Dict(:events => [Dict(:projection_id => "moos:one"), Dict(:projection_id => "moos:two")])
    write_result = Dict(:results => [Dict(:action => "patch"), Dict(:action => "patch")])
    reconciliation = Dict(:summary => Dict(:deferred_relations => 16))
    graph_pack = Dict(:node_count => 16, :relation_count => 20)
    t189_graph_pack = Dict(:node_count => 46, :relation_count => 58)

    mktempdir() do dir
        jsonl_log_path = joinpath(dir, "moos.jsonl")
        dashboard_path = joinpath(dir, "index.html")
        write(jsonl_log_path, "{}\n{}\n")
        write(dashboard_path, "<html></html>")

        atlas = Atlas.plan_atlas(
            nodes,
            relations;
            health=Dict(:status => "ok", :ontology_version => "3.16.1", :t_day => 189, :log_len => 1154),
            ontology=ontology,
            calendar_plan=calendar_plan,
            write_result=write_result,
            gate=Dict(:overall_status => "warn"),
            recommendation_plan=Dict(:selected_t189_recommendations => [1, 2, 3, 4, 5]),
            reconciliation=reconciliation,
            graph_pack=graph_pack,
            t189_graph_pack=t189_graph_pack,
            repo_root=normpath(joinpath(@__DIR__, "..", "..")),
            dashboard_path=dashboard_path,
            jsonl_log_path=jsonl_log_path,
            generated_at="2026-05-09T17:30:00Z",
        )

        @test atlas["projection_kind"] == "surface_context_atlas"
        @test length(atlas["surfaces"]) == 7
        @test atlas["surfaces"][1]["header"] == "JSON API"
        @test atlas["surfaces"][2]["header"] == "JSONL Log"
        @test atlas["surfaces"][4]["evidence"]["actions"]["patch"] == 2
        @test all(row -> row["present"], atlas["hg_anchors"]["category_functor_logic"])
        @test all(row -> row["present"], atlas["hg_anchors"]["ui_ux_visualization"])
        @test all(row -> row["present"], atlas["hg_anchors"]["application_surface_map"])
        @test length(atlas["programs_with_irl_external_shape"]) >= 2
        @test atlas["pending_moves"][1]["status"] == "ready-for-anchor-apply-review"
        @test length(atlas["step_by_step_hg"]) == 7
        @test occursin("projection stack is strong", atlas["assessment"]["honest_opinion"])

        json_path = joinpath(dir, "atlas.json")
        md_path = joinpath(dir, "atlas.md")
        Atlas.write_json(json_path, atlas)
        Atlas.write_markdown(md_path, atlas)
        @test isfile(json_path)
        markdown = read(md_path, String)
        @test occursin("Surface Context Atlas", markdown)
        @test occursin("JSON API", markdown)
        @test occursin("Step By Step HG Use", markdown)
        @test occursin("Opinionated Assessment", markdown)
    end
end
