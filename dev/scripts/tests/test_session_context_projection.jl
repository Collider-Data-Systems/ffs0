using Test

include(joinpath(@__DIR__, "..", "session_context_projection.jl"))

const SCP = SessionContextProjection

prop(value) = Dict(:value => value, :mutability => "mutable")

@testset "Session context projection" begin
    session_urn = "urn:moos:session:sam.governance"
    actor_urn = "urn:moos:agent:claude-code.hp-laptop"
    purpose_urn = "urn:moos:purpose:sam.session-context"
    kernel_urn = "urn:moos:kernel:hp-laptop.primary"
    scope_urn = "urn:moos:program:sam.session-context-projection"

    nodes = [
        Dict(:urn => session_urn, :type_id => "session", :properties => Dict(:name => prop("Governance"), :local_t => prop(12))),
        Dict(:urn => actor_urn, :type_id => "agent", :properties => Dict(:name => prop("Claude Code hp-laptop"))),
        Dict(:urn => purpose_urn, :type_id => "purpose", :properties => Dict(:title => prop("Session context projection"))),
        Dict(:urn => kernel_urn, :type_id => "kernel", :properties => Dict(:name => prop("hp-laptop primary"))),
        Dict(:urn => scope_urn, :type_id => "program", :properties => Dict(:title => prop("Projection program"))),
        Dict(:urn => "urn:moos:group:sam", :type_id => "group", :properties => Dict(:name => prop("sam"))),
    ]
    relations = [
        Dict(:urn => "rel:opens", :rewrite_category => "WF19", :src_urn => session_urn, :src_port => "opens-on", :tgt_urn => kernel_urn, :tgt_port => "opened-by"),
        Dict(:urn => "rel:occupant", :rewrite_category => "WF19", :src_urn => session_urn, :src_port => "has-occupant", :tgt_urn => actor_urn, :tgt_port => "is-occupant-of"),
        Dict(:urn => "rel:purpose", :rewrite_category => "WF19", :src_urn => session_urn, :src_port => "has-purpose", :tgt_urn => purpose_urn, :tgt_port => "purpose-of-session"),
        Dict(:urn => "rel:scope", :rewrite_category => "WF19", :src_urn => session_urn, :src_port => "pins-urn", :tgt_urn => scope_urn, :tgt_port => "pinned-by"),
        Dict(:urn => "rel:owner", :rewrite_category => "WF01", :src_urn => "urn:moos:group:sam", :src_port => "owns", :tgt_urn => session_urn, :tgt_port => "owned-by"),
    ]
    skills = [
        Dict("name" => "moos-state-readback", "description" => "Use at the start of any mo:os working session."),
        Dict("name" => "moos-tooling-dx", "description" => "Use for IDE attach, harness patterns, and projection tooling."),
        Dict("name" => "moos-workspace-ingest", "description" => "Use for G-direction Workspace ingest."),
    ]

    plan = SCP.plan_session_context_projection(
        nodes,
        relations;
        session_urn=session_urn,
        actor_urn=actor_urn,
        focus="VS Code session projection harness",
        skill_catalog=skills,
        skill_limit=2,
        health=Dict("log_len" => 1079),
        generated_at="2026-05-07T15:00:00Z",
    )

    @test plan["projection_kind"] == "session_context_pack"
    @test plan["context"]["opens_on"][1]["urn"] == kernel_urn
    @test plan["context"]["occupants"][1]["urn"] == actor_urn
    @test plan["context"]["purposes"][1]["urn"] == purpose_urn
    @test plan["context"]["scope_roots"][1]["urn"] == scope_urn
    @test plan["context"]["owners"][1]["urn"] == "urn:moos:group:sam"
    @test plan["purpose_color"] == "Session context projection"
    @test length(plan["affordance_pack"]["recommended_skills"]) == 2
    recommended_names = Set(skill["name"] for skill in plan["affordance_pack"]["recommended_skills"])
    @test "moos-state-readback" in recommended_names
    @test "moos-tooling-dx" in recommended_names
    @test occursin(session_urn, plan["handoff"]["prompt_seed"])

    @testset "skill frontmatter catalog" begin
        mktempdir() do dir
            skill_dir = joinpath(dir, "moos-demo")
            mkpath(skill_dir)
            write(joinpath(skill_dir, "SKILL.md"), "---\nname: moos-demo\ndescription: \"Use when: testing session projection.\"\n---\n\n# moos-demo\n")
            catalog = SCP.load_skill_catalog(dir)
            @test length(catalog) == 1
            @test catalog[1]["name"] == "moos-demo"
            @test occursin("testing session projection", catalog[1]["description"])
        end
    end
end
