using Dates
using Test

include(joinpath(@__DIR__, "..", "calendar_time_fabric_projection.jl"))

const CTF = CalendarTimeFabricProjection

@testset "Calendar time-fabric projection" begin
    artifact = Dict(
        :nodes => [
            Dict(:urn => "urn:moos:claim:recent", :type_id => "claim", :title => "Recent claim", :status => "open", :properties => Dict(:confidence => 0.8)),
            Dict(:urn => "urn:moos:derivation:recent", :type_id => "derivation", :title => "Recent derivation", :status => "closed", :properties => Dict(:status => "closed")),
            Dict(:urn => "urn:moos:program:explicit", :type_id => "program", :title => "Explicit T", :status => "active", :properties => Dict(:target_t => Dict(:value => 190))),
        ],
        :relations => [
            Dict(:rewrite_category => "WF21", :src_urn => "urn:moos:derivation:recent", :src_port => "causes", :tgt_urn => "urn:moos:claim:recent", :tgt_port => "caused-by"),
        ],
    )

    plan = CTF.plan_time_fabric_projection(artifact; anchor_t=188, t0_date=Date("2025-11-01"), scope_artifact_path="missing-calendar-scope.json")
    @test plan["event_count"] == 3
    @test plan["anchor_date"] == "2026-05-08"
    @test plan["slice_policy"]["calendar_scope_depth"] == 3
    @test plan["calendar_surface_assessment"]["explicit_temporal_event_count"] == 1
    @test plan["calendar_surface_assessment"]["lens_order_event_count"] == 2
    @test plan["scope_diagnostics"]["exists"] == false

    source_urns = Set(event["source_urn"] for event in plan["events"])
    @test "urn:moos:claim:recent" in source_urns
    @test "urn:moos:derivation:recent" in source_urns
    @test "urn:moos:program:explicit" in source_urns

    claim_event = only(filter(event -> event["source_urn"] == "urn:moos:claim:recent", plan["events"]))
    @test claim_event["event_kind"] == "recent_time_fabric_node"
    @test claim_event["calendar_label"] == "blue"
    @test claim_event["surface_role"] == "evidence-lineage"
    @test claim_event["temporal_basis"]["kind"] == "lens_order_placement"
    @test claim_event["calendar_reliability"]["level"] == "low"
    @test claim_event["relation_context"]["incoming_count"] == 1
    @test claim_event["google_event"]["start"]["date"] == "2026-05-08"
    @test occursin("Relation counts: incoming=1", claim_event["google_event"]["description"])
    @test claim_event["google_event"]["extendedProperties"]["private"]["moos_urn"] == "urn:moos:claim:recent"

    explicit_event = only(filter(event -> event["source_urn"] == "urn:moos:program:explicit", plan["events"]))
    @test explicit_event["google_event"]["start"]["date"] == "2026-05-10"
    @test explicit_event["temporal_basis"]["field"] == "target_t"
    @test explicit_event["calendar_reliability"]["level"] == "medium_high"
    @test occursin("explicit T190", explicit_event["google_event"]["description"])
end
