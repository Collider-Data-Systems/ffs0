using Dates
using Test

include(joinpath(@__DIR__, "..", "t189_t200_recommendation_projection.jl"))

const Rec = T189T200RecommendationProjection

@testset "T189/T200 recommendation projection" begin
    ontology = Dict(
        :version => "3.16.1",
        :types => Dict(:s2 => [Dict(:id => type) for type in Rec.REQUIRED_TYPES]),
        :rewrite_categories => [Dict(:id => wf) for wf in Rec.REQUIRED_WFS],
    )
    calendar_plan = Dict(
        :events => [
            Dict(
                :projection_id => "moos-one",
                :source_urn => "urn:moos:program:source-one",
                :calendar_label => "purple",
                :google_event => Dict(:summary => "mo:os program :: One", :start => Dict(:date => "2026-05-09")),
            ),
            Dict(
                :projection_id => "moos-two",
                :source_urn => "urn:moos:claim:source-two",
                :calendar_label => "blue",
                :google_event => Dict(:summary => "mo:os claim :: Two", :start => Dict(:date => "2026-05-10")),
            ),
        ],
    )
    write_result = Dict(:results => [Dict(:projection_id => "moos-one", :source_urn => "urn:moos:program:source-one", :action => "insert", :google_event_id => "event-one")])

    plan = Rec.plan_projection(ontology, calendar_plan, write_result; t0_date=Date("2025-11-01"))

    @test plan["projection_kind"] == "t189_t200_recommendation_hg_plan"
    @test length(plan["selected_t189_recommendations"]) == 5
    @test plan["calendar_event_node_count"] == 2
    @test plan["calendar_ingest_decision"]["chosen_shape"] == "hybrid"
    @test isempty(plan["ontology_check"]["unknown_required_types"])
    @test isempty(plan["ontology_check"]["unknown_required_wfs"])
    @test plan["deferred_relation_count"] == 2

    event_one = only(filter(node -> node["urn"] == "urn:moos:cal:2026-05-09.moos-one", plan["candidate_nodes"]))
    @test event_one["type_id"] == "calendar_event"
    @test event_one["properties"]["t_day"] == 189
    @test event_one["properties"]["gcal_id"] == "event-one"
    @test event_one["properties"]["status"] == "confirmed"

    event_two = only(filter(node -> node["urn"] == "urn:moos:cal:2026-05-10.moos-two", plan["candidate_nodes"]))
    @test event_two["properties"]["status"] == "tentative"
    @test any(node -> node["urn"] == "urn:moos:group:my-tiny-data-collider", plan["candidate_nodes"])
    @test any(rel -> rel["rewrite_category"] == "WF19" && rel["src_port"] == "filtered-by", plan["candidate_relations"])
    @test any(rec -> rec["urn"] == "urn:moos:program:sam.t200plus.identity-stable-projection-surface-convergence", plan["t200_recommendations"])
end
