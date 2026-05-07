using Dates
using Test

include(joinpath(@__DIR__, "..", "google_calendar_projection.jl"))

const GCP = GoogleCalendarProjection

prop(value) = Dict(:value => value, :mutability => "mutable")

@testset "Google Calendar projection" begin
    @testset "reachable URNs" begin
        relations = [
            Dict(:rewrite_category => "WF18", :src_urn => GCP.DEFAULT_ROOT_URN, :src_port => "composes", :tgt_urn => "urn:moos:program:sam.target", :tgt_port => "composed-by"),
            Dict(:rewrite_category => "WF21", :src_urn => "urn:moos:program:sam.target", :src_port => "causes", :tgt_urn => "urn:moos:program:sam.after", :tgt_port => "caused-by"),
            Dict(:rewrite_category => "WF01", :src_urn => "urn:moos:user:sam", :src_port => "owns", :tgt_urn => GCP.DEFAULT_ROOT_URN, :tgt_port => "child"),
        ]
        selected = GCP.reachable_urns(relations, [GCP.DEFAULT_ROOT_URN]; radius=2)
        @test "urn:moos:program:sam.target" in selected
        @test "urn:moos:program:sam.after" in selected
        @test !("urn:moos:user:sam" in selected)
    end

    @testset "program target T" begin
        node = Dict(
            :urn => "urn:moos:program:sam.t205-demo",
            :type_id => "program",
            :properties => Dict(
                :title => prop("T205 demo"),
                :target_t => prop(205),
                :scope => prop("Show the thing."),
            ),
        )
        payload = GCP.calendar_event_payload(node; t0_date=Date("2025-11-01"))
        @test payload !== nothing
        @test payload["google_event"]["start"]["date"] == "2026-05-25"
        @test payload["google_event"]["end"]["date"] == "2026-05-26"
        @test occursin("HG URN: urn:moos:program:sam.t205-demo", payload["google_event"]["description"])
        @test payload["calendar_label"] == "purple"
    end

    @testset "program window" begin
        node = Dict(
            :urn => "urn:moos:program:sam.window",
            :type_id => "program",
            :properties => Dict(
                :title => prop("Window"),
                :starts_t => prop(200),
                :target_t => prop(205),
            ),
        )
        payload = GCP.calendar_event_payload(node; t0_date=Date("2025-11-01"))
        @test payload["google_event"]["start"]["date"] == "2026-05-20"
        @test payload["google_event"]["end"]["date"] == "2026-05-26"
    end

    @testset "calendar_event anchor" begin
        node = Dict(
            :urn => "urn:moos:cal:2026-05-25.demo",
            :type_id => "calendar_event",
            :properties => Dict(
                :summary => prop("Existing calendar anchor"),
                :date => prop("2026-05-25"),
            ),
        )
        payload = GCP.calendar_event_payload(node; t0_date=Date("2025-11-01"))
        @test payload["event_kind"] == "calendar_event_anchor"
        @test payload["google_event"]["summary"] == "Existing calendar anchor"
    end

    @testset "planning reachable nodes only" begin
        nodes = [
            Dict(:urn => GCP.DEFAULT_ROOT_URN, :type_id => "program", :properties => Dict(:title => prop("Root"), :target_t => prop(205))),
            Dict(:urn => GCP.DEFAULT_CONTRACT_URN, :type_id => "program", :properties => Dict(:title => prop("Contract"), :target_t => prop(205))),
            Dict(:urn => GCP.DEFAULT_CHANNEL_URN, :type_id => "channel", :properties => Dict(:title => prop("Calendar"))),
            Dict(:urn => "urn:moos:program:sam.unreachable", :type_id => "program", :properties => Dict(:title => prop("Nope"), :target_t => prop(205))),
        ]
        relations = [
            Dict(:rewrite_category => "WF18", :src_urn => GCP.DEFAULT_ROOT_URN, :src_port => "composes", :tgt_urn => GCP.DEFAULT_CONTRACT_URN, :tgt_port => "composed-by"),
            Dict(:rewrite_category => "WF18", :src_urn => GCP.DEFAULT_CONTRACT_URN, :src_port => "composes", :tgt_urn => GCP.DEFAULT_CHANNEL_URN, :tgt_port => "composed-by"),
        ]
        plan = GCP.plan_calendar_projection(nodes, relations; t0_date=Date("2025-11-01"))
        source_urns = Set(event["source_urn"] for event in plan["events"])
        @test GCP.DEFAULT_ROOT_URN in source_urns
        @test GCP.DEFAULT_CONTRACT_URN in source_urns
        @test !(GCP.DEFAULT_CHANNEL_URN in source_urns)
        @test !("urn:moos:program:sam.unreachable" in source_urns)
    end

    @testset "stable projection id" begin
        urn = "urn:moos:program:sam.demo"
        @test GCP.projection_id(urn) == GCP.projection_id(urn)
        @test startswith(GCP.projection_id(urn), "moos-")
    end
end