using Test

include(joinpath(@__DIR__, "..", "t194_t200_big_sprint_topology.jl"))

const Big = T194T200BigSprintTopology

function p(value; mutability="immutable", authority="")
    Dict(:value => value, :mutability => mutability, :authority_scope => authority, :stratum_origin => 2)
end

function node(urn, type_id; properties=Dict{Symbol, Any}())
    Dict(:urn => urn, :type_id => type_id, :properties => properties)
end

function rel(wf, src, src_port, tgt, tgt_port)
    Dict(
        :urn => string("urn:moos:rel:test.", replace(src, r"[^A-Za-z0-9]+" => "-"), ".", src_port, ".", replace(tgt, r"[^A-Za-z0-9]+" => "-")),
        :rewrite_category => wf,
        :src_urn => src,
        :src_port => src_port,
        :tgt_urn => tgt,
        :tgt_port => tgt_port,
    )
end

@testset "T194/T200 big sprint topology planner" begin
    nodes = Any[
        node("urn:moos:session:sam.governance", "session"; properties=Dict(:status => p("active"), :local_t => p(12))),
        node("urn:moos:kernel:hp-laptop.primary", "kernel"),
        node("urn:moos:kernel:hp-z440.primary", "kernel"),
        node("urn:moos:group:sam", "group"),
        node("urn:moos:agent:vscode.hp-laptop.copilot", "agent"),
        node("urn:moos:agent:claude-cowork.hp-laptop", "agent"),
        node("urn:moos:agent:vscode.hpprodesk.primary", "agent"),
        node("urn:moos:agent:claude-code.hp-z440", "agent"),
        node("urn:moos:agent:vscode.hp-z440.menno", "agent"),
        node("urn:moos:agent:vscode.hp-z440.lola", "agent"),
        node("urn:moos:agent:antigravity.hp-z440", "agent"),
        node("urn:moos:channel:google.calendar.sam", "channel"),
        node("urn:moos:channel:github.collider-data-systems", "channel"),
        node("urn:moos:channel:github.project.mo-os", "channel"),
        node("urn:moos:program:sam.t189.calendar-event-g-ingest-shape", "program"; properties=Dict(:title => p("Calendar ingest"), :status => p("draft"))),
        node("urn:moos:program:sam.t189.github-project-urn-refresh", "program"; properties=Dict(:title => p("Project refresh"), :status => p("draft"))),
        node("urn:moos:program:sam.t200plus.identity-stable-projection-surface-convergence", "program"; properties=Dict(:title => p("Identity surfaces"), :status => p("draft"))),
        node("urn:moos:program:sam.t192.application-group-model-my-tiny-data-collider", "program"),
        node("urn:moos:derivation:guido.t189-calendar-event-g-ingest-decision", "derivation"; properties=Dict(:name => p("Calendar decision"))),
        node("urn:moos:view_filter:sam.t189-time-fabric-session-lens", "view_filter"),
        node("urn:moos:group:my-tiny-data-collider", "group"),
        node("urn:moos:purpose:sam.my-tiny-data-collider-application", "purpose"),
        node("urn:moos:workflow:z440-session-continuity-reconciliation", "workflow"),
        node("urn:moos:session:sam.kernel-proper", "session"),
        node("urn:moos:session:sam.steinberger-seat", "session"),
        node("urn:moos:session:sam.karpathy-seat", "session"),
        node("urn:moos:session:sam.moos-diary", "session"),
        node("urn:moos:session:sam.z440-cowork-workspace", "session"),
    ]
    relations = Any[
        rel("WF19", "urn:moos:session:sam.governance", "opens-on", "urn:moos:kernel:hp-laptop.primary", "occupied-by"),
        rel("WF19", "urn:moos:session:sam.governance", "has-occupant", "urn:moos:agent:vscode.hp-laptop.copilot", "is-occupant-of"),
    ]
    recommendation_plan = Dict(
        :candidate_nodes => Any[
            Dict(:urn => "urn:moos:cal:2026-05-14.example-one", :type_id => "calendar_event", :properties => Dict(:summary => "One", :date => "2026-05-14", :t_day => 194, :gcal_id => "event-one", :color_label => "blue", :status => "confirmed", :created_at => Big.CREATED_AT)),
            Dict(:urn => "urn:moos:cal:2026-05-15.example-two", :type_id => "calendar_event", :properties => Dict(:summary => "Two", :date => "2026-05-15", :t_day => 195, :gcal_id => "event-two", :color_label => "green", :status => "tentative", :created_at => Big.CREATED_AT)),
        ],
    )
    reconciliation = Dict(:nodes => Any[
        Dict(:urn => "urn:moos:cal:2026-05-14.example-one", :status => "pending"),
        Dict(:urn => "urn:moos:cal:2026-05-15.example-two", :status => "pending"),
    ])
    health = Dict(:status => "ok", :ontology_version => "3.16.1", :t_day => 194, :log_len => 1192)

    plan = Big.plan_topology(health, nodes, relations, recommendation_plan, reconciliation)

    @test plan["projection_kind"] == "t194_t200_big_sprint_topology_audit"
    @test plan["pending_calendar_event_count"] == 2
    @test length(plan["session_lanes"]) == 5
    @test plan["apply_candidate"]["envelope_count"] > 40
    @test haskey(plan["apply_candidate"]["envelope_counts"], "ADD")
    @test haskey(plan["apply_candidate"]["envelope_counts"], "LINK")
    @test any(env -> env["rewrite_type"] == "ADD" && env["node_urn"] == "urn:moos:session:sam.t200plus-calendar-readback", plan["envelopes"])
    @test any(env -> env["rewrite_type"] == "LINK" && env["src_urn"] == "urn:moos:session:sam.t200plus-calendar-readback" && env["tgt_urn"] == "urn:moos:cal:2026-05-14.example-one", plan["envelopes"])
    @test all(env -> !(haskey(env, "rewrite_category") && env["rewrite_category"] == "WF07"), plan["envelopes"])

    md = Big.markdown(plan)
    @test occursin("T194/T200 Big Sprint Topology Audit", md)
    @test occursin("Pending Calendar event observations: 2", md)
end