using Test

include(joinpath(@__DIR__, "..", "session_context_projection.jl"))

const SCP = SessionContextProjection

prop(value) = Dict(:value => value, :mutability => "mutable")

@testset "Session context projection" begin
    session_urn = "urn:moos:session:sam.governance"
    actor_urn = "urn:moos:agent:vscode.hp-laptop.copilot"
    purpose_urn = "urn:moos:purpose:sam.session-context"
    kernel_urn = "urn:moos:kernel:hp-laptop.primary"
    scope_urn = "urn:moos:program:sam.session-context-projection"

    nodes = [
        Dict(:urn => session_urn, :type_id => "session", :properties => Dict(:name => prop("Governance"), :local_t => prop(12))),
        Dict(:urn => actor_urn, :type_id => "agent", :properties => Dict(:name => prop("VS Code Copilot hp-laptop"))),
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
    extensions = [
        Dict("id" => "upstash.context7-mcp", "display_name" => "Context7 MCP Server", "version" => "1.0.1", "description" => "MCP documentation server", "categories" => ["AI", "Chat"], "keywords" => ["mcp"], "contributes_mcp" => true),
        Dict("id" => "github.vscode-pull-request-github", "display_name" => "GitHub Pull Requests", "version" => "0.142.0", "description" => "GitHub PR and issue tooling", "categories" => ["SCM Providers"], "keywords" => ["github"], "contributes_mcp" => false),
    ]
    mcp_servers = [
        Dict("name" => "moos-primary", "type" => "sse", "url" => "http://localhost:8080/sse", "command" => "", "arg_count" => 0, "header_names" => String[], "env_names" => String[], "source_path" => ".vscode/mcp.json.example"),
    ]

    plan = SCP.plan_session_context_projection(
        nodes,
        relations;
        session_urn=session_urn,
        actor_urn=actor_urn,
        focus="VS Code session projection harness",
        skill_catalog=skills,
        skill_limit=2,
        extension_catalog=extensions,
        extension_limit=2,
        mcp_servers=mcp_servers,
        health=Dict("log_len" => 1079),
        generated_at="2026-05-07T15:00:00Z",
    )

    @test plan["projection_kind"] == "session_context_pack"
    @test plan["identity"]["status"] == "pass"
    @test plan["identity"]["actor_is_hg_occupant"]
    @test plan["identity"]["harness_matches_actor"]
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
    @test plan["affordance_pack"]["available_extension_count"] == 2
    recommended_extension_ids = Set(extension["id"] for extension in plan["affordance_pack"]["recommended_extensions"])
    @test "upstash.context7-mcp" in recommended_extension_ids
    @test plan["affordance_pack"]["mcp_servers"][1]["name"] == "moos-primary"
    @test occursin(session_urn, plan["handoff"]["prompt_seed"])
    @test occursin("MCP servers", plan["handoff"]["prompt_seed"])

    mismatch = SCP.plan_session_context_projection(
        nodes,
        relations;
        session_urn=session_urn,
        actor_urn=actor_urn,
        harness_agent_urn="urn:moos:agent:claude-code.hp-laptop",
        focus="VS Code session projection harness",
        generated_at="2026-05-07T15:00:00Z",
    )
    @test mismatch["identity"]["status"] == "warn"
    @test !mismatch["identity"]["harness_matches_actor"]

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

    @testset "extension and MCP catalogs" begin
        mktempdir() do dir
            extension_dir = joinpath(dir, "upstash.context7-mcp-1.0.1")
            mkpath(extension_dir)
            write(joinpath(extension_dir, "package.json"), """
            {
                "name": "context7-mcp",
                "displayName": "Context7 MCP Server",
                "publisher": "Upstash",
                "version": "1.0.1",
                "description": "Real-time docs over MCP",
                "categories": ["AI", "Chat"],
                "keywords": ["mcp", "docs"],
                "contributes": {"mcpServerDefinitionProviders": [{"id": "context7"}]}
            }
            """)
            catalog = SCP.load_extension_catalog(dir)
            @test length(catalog) == 1
            @test catalog[1]["id"] == "upstash.context7-mcp"
            @test catalog[1]["contributes_mcp"]

            mcp_path = joinpath(dir, "mcp.json")
            write(mcp_path, """
            {
                "servers": {
                    "_comment": "ignored",
                    "moos-primary": {"type": "sse", "url": "http://localhost:8080/sse"},
                    "cloud": {"type": "http", "url": "https://example.invalid", "headers": {"Authorization": "secret"}}
                }
            }
            """)
            servers = SCP.load_mcp_catalog([mcp_path])
            @test length(servers) == 2
            cloud = only(filter(server -> server["name"] == "cloud", servers))
            @test cloud["header_names"] == ["Authorization"]
            @test !haskey(cloud, "headers")
        end
    end
end
