using Test

include(joinpath(@__DIR__, "..", "t189_recommendation_reconciliation.jl"))

const Recon = T189RecommendationReconciliation

@testset "T189 recommendation reconciliation" begin
    grouped_node = Dict(:urn => "urn:moos:program:grouped", :type_id => "program", :recommendation_scope => "grouped")
    calendar_node = Dict(:urn => "urn:moos:cal:2026-05-09.demo", :type_id => "calendar_event", :recommendation_scope => "individual-calendar-event")
    grouped_relation = Dict(:rewrite_category => "WF18", :src_urn => "urn:moos:purpose:root", :src_port => "composes", :tgt_urn => "urn:moos:program:grouped", :tgt_port => "composed-by", :status => "declared")
    calendar_pin = Dict(:rewrite_category => "WF19", :src_urn => "urn:moos:session:sam.governance", :src_port => "pins-urn", :tgt_urn => "urn:moos:cal:2026-05-09.demo", :tgt_port => "pinned-by-session", :status => "declared")
    deferred = Dict(:rewrite_category => "WF07", :src_urn => "urn:moos:cal:2026-05-09.demo", :src_port => "anchors", :tgt_urn => "urn:moos:program:source", :tgt_port => "anchor", :status => "requires-operad-review", :note => "check WF07")
    plan = Dict(
        :projection_kind => "t189_t200_recommendation_hg_plan",
        :candidate_nodes => [grouped_node, calendar_node],
        :candidate_relations => [grouped_relation, calendar_pin],
        :deferred_relations => [deferred],
    )
    nodes = [Dict(:urn => "urn:moos:program:grouped", :type_id => "program")]
    relations = [grouped_relation]

    report = Recon.reconcile(plan, nodes, relations; health=Dict(:status => "ok"), generated_at="2026-05-09T14:00:00Z")

    @test report["projection_kind"] == "t189_recommendation_reconciliation"
    @test report["summary"]["grouped_nodes_applied"] == 1
    @test report["summary"]["grouped_nodes_total"] == 1
    @test report["summary"]["grouped_relations_applied"] == 1
    @test report["summary"]["grouped_relations_total"] == 1
    @test report["summary"]["calendar_event_nodes_pending"] == 1
    @test report["summary"]["deferred_relations"] == 1
    @test report["summary"]["grouped_nodes_ok"] == true
    @test report["summary"]["grouped_relations_ok"] == true
    statuses = Dict(row["urn"] => row["status"] for row in report["nodes"])
    @test statuses["urn:moos:program:grouped"] == "applied"
    @test statuses["urn:moos:cal:2026-05-09.demo"] == "pending"
    relation_statuses = Dict(row["bucket"] => row["status"] for row in report["relations"])
    @test relation_statuses["grouped-safe"] == "applied"
    @test relation_statuses["calendar-event"] == "pending"

    mktempdir() do dir
        path = joinpath(dir, "reconciliation.md")
        Recon.write_markdown(path, report)
        text = read(path, String)
        @test occursin("Grouped nodes: 1/1 applied", text)
        @test occursin("Calendar event nodes pending: 1", text)
        @test occursin("Deferred Relations", text)
    end
end
