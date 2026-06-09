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
        Dict(:urn => "urn:moos:channel:google.gmail.test-a", :type_id => "channel", :properties => Dict(:display_name => prop("Test Gmail A"))),
        Dict(:urn => "urn:moos:channel:cloudflare.zone.my-tiny-data-collider-nl", :type_id => "channel", :properties => Dict(:display_name => prop("Cloudflare zone"))),
    ]
    relations = [
        Dict(:urn => "urn:moos:rel:visual.causes.program", :rewrite_category => "WF21", :src_urn => "urn:moos:derivation:guido.t200plus.visual-projection-frame", :src_port => "causes", :tgt_urn => "urn:moos:program:sam.t200plus.visual-projection-lens", :tgt_port => "caused-by"),
        Dict(:urn => "urn:moos:rel:program.anchors.calendar", :rewrite_category => "WF07", :src_urn => "urn:moos:program:sam.t200plus.google-calendar-projection-contract", :src_port => "anchors", :tgt_urn => "urn:moos:program:sam.t192.application-group-model-my-tiny-data-collider", :tgt_port => "anchor"),
    ]
    ontology = Dict(:rewrite_categories => [
        Dict(:id => "WF07", :src_port => "participates", :tgt_port => "participated-by", :additional_port_pairs => [Dict(:src_port => "anchors", :tgt_port => "anchor")]),
    ])
    topology = Dict(:cloudflare => Dict(
        :tunnel_id => "test-tunnel",
        :hostnames => Dict(
            :api => "api.my-tiny-data-collider.nl",
            :kernel => "kernel.my-tiny-data-collider.nl",
            :root => "my-tiny-data-collider.nl",
            :www => "www.my-tiny-data-collider.nl",
        ),
    ))
    calendar_plan = Dict(:events => [Dict(:projection_id => "moos:one"), Dict(:projection_id => "moos:two")])
    write_result = Dict(:results => [Dict(:action => "patch"), Dict(:action => "patch")])
    reconciliation = Dict(:summary => Dict(:deferred_relations => 16))
    graph_pack = Dict(:node_count => 16, :relation_count => 20)
    t189_graph_pack = Dict(:node_count => 46, :relation_count => 58)
    affordance_map = Dict(
        :sessions => [
            Dict(
                :key => "z440-vscode-lead",
                :host => "hp-z440",
                :desktop => 1,
                :session_urn => "urn:moos:session:sam.z440-vscode-projection-lead",
                :actor_urn => "urn:moos:agent:vscode.hp-z440.primary",
                :emit_kernel => "urn:moos:kernel:hp-z440.primary",
                :mcp_server => "moos-primary",
                :workspace => "ffs0.code-workspace",
                :harnesses => ["VS Code", "Copilot"],
                :skills => ["moos-session-context-projection", "moos-tooling-dx"],
                :prompts => [],
                :validation => ["Test-MoosFederation.ps1 -Mode VerifyPersona -Persona z440-vscode-lead"],
            )
        ],
        :multi_workspace_testbed => Dict(
            :status => "planned",
            :purpose_urn => "urn:moos:purpose:sam.multi-workspace-cloud-testbed",
            :program_urn => "urn:moos:program:sam.t190.multi-workspace-cloud-testbed",
            :owner_group_urn => "urn:moos:group:sam",
            :credential_policy => "Keep credentials outside git.",
            :workspaces => [
                Dict(
                    :slug => "test-a",
                    :channels => [
                        Dict(:service => "gmail", :kind => "mail", :channel_urn => "urn:moos:channel:google.gmail.test-a", :status => "planned"),
                        Dict(:service => "calendar", :kind => "calendar", :channel_urn => "urn:moos:channel:google.calendar.test-a", :status => "planned"),
                    ],
                )
            ],
        ),
        :github_identity => Dict(
            :status => "inventory-first",
            :org => "Collider-Data-Systems",
            :project_number => 4,
            :project_urn => "urn:moos:channel:github.project.mo-os",
            :org_channel_urn => "urn:moos:channel:github.collider-data-systems",
            :sync_policy => "No status G-sync until HG URN coverage is reliable.",
            :hg_urn_coverage => Dict(:known_populated => 31, :known_total => 57, :ambiguous_rows => 4, :legacy_non_urn_rows => 2, :source => "test"),
        ),
        :network_identity => Dict(
            :status => "inventory-first",
            :provider => "cloudflare",
            :domain => "my-tiny-data-collider.nl",
            :topology_source => "dev/config/moos-federation.topology.json",
            :dashboard_observation => Dict(
                :status => "seen-in-browser",
                :account_label => "my-tiny-data-collider",
                :zone_label => "my-tiny-data-collider.nl",
                :local_only_fields => ["cloudflare_account_id", "dashboard_url", "login_email"],
            ),
            :access_applications => Dict(
                :status => "seen-in-browser",
                :source => "Cloudflare One / Access controls / Applications",
                :applications => [
                    Dict(:name => "moos-api", :application_url => "api.my-tiny-data-collider.nl", :hostname_role => "api", :type => "self-hosted", :total_domains => 1, :policies_assigned => 1),
                    Dict(:name => "moos-kernel", :application_url => "kernel.my-tiny-data-collider.nl", :hostname_role => "kernel", :type => "self-hosted", :total_domains => 1, :policies_assigned => 1),
                ],
                :local_only_fields => ["cloudflare_account_id", "dashboard_url", "login_email", "application_ids", "policy_ids"],
            ),
            :dns_policy => "Read before write.",
            :planned_surfaces => [
                Dict(:role => "cloudflare-zone", :surface_urn => "urn:moos:channel:cloudflare.zone.my-tiny-data-collider-nl", :status => "planned"),
                Dict(:role => "dns-zone", :surface_urn => "urn:moos:channel:dns.zone.my-tiny-data-collider-nl", :status => "planned"),
            ],
        ),
    )

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
            topology=topology,
            calendar_plan=calendar_plan,
            write_result=write_result,
            gate=Dict(:overall_status => "warn"),
            recommendation_plan=Dict(:selected_t189_recommendations => [1, 2, 3, 4, 5]),
            reconciliation=reconciliation,
            graph_pack=graph_pack,
            t189_graph_pack=t189_graph_pack,
            affordance_map=affordance_map,
            repo_root=normpath(joinpath(@__DIR__, "..", "..")),
            dashboard_path=dashboard_path,
            jsonl_log_path=jsonl_log_path,
            generated_at="2026-05-09T17:30:00Z",
        )

        @test atlas["projection_kind"] == "surface_context_atlas"
        @test length(atlas["surfaces"]) == 11
        surfaces_by_id = Dict(row["id"] => row for row in atlas["surfaces"])
        @test surfaces_by_id["folded-hg-json"]["header"] == "JSON API"
        @test surfaces_by_id["append-only-jsonl"]["header"] == "JSONL Log"
        @test surfaces_by_id["google-calendar"]["evidence"]["actions"]["patch"] == 2
        @test surfaces_by_id["team-ide-harnesses"]["status"] == "pass"
        @test surfaces_by_id["multi-workspace-testbed"]["status"] == "warn"
        @test surfaces_by_id["github-org-project"]["status"] == "warn"
        @test surfaces_by_id["cloudflare-domain-dns"]["status"] == "warn"
        @test atlas["team_setup"]["session_count"] == 1
        @test atlas["team_setup"]["skill_count"] == 2
        @test atlas["multi_workspace_testbed"]["channel_count"] == 2
        @test atlas["multi_workspace_testbed"]["existing_channel_count"] == 1
        @test atlas["github_identity"]["hg_urn_coverage"]["known_populated"] == 31
        @test atlas["network_identity"]["domain"] == "my-tiny-data-collider.nl"
        @test atlas["network_identity"]["hostname_count"] == 4
        @test atlas["network_identity"]["planned_surface_count"] == 2
        @test atlas["network_identity"]["existing_surface_count"] == 1
        @test Atlas.object_value(atlas["network_identity"]["dashboard_observation"], :status) == "seen-in-browser"
        @test atlas["network_identity"]["access_applications"]["application_count"] == 2
        @test atlas["network_identity"]["access_applications"]["policy_assignment_count"] == 2
        @test all(row -> row["present"], atlas["hg_anchors"]["category_functor_logic"])
        @test all(row -> row["present"], atlas["hg_anchors"]["ui_ux_visualization"])
        @test all(row -> row["present"], atlas["hg_anchors"]["application_surface_map"])
        @test length(atlas["programs_with_irl_external_shape"]) >= 2
        @test atlas["pending_moves"][1]["status"] == "ready-for-anchor-apply-review"
        closed_moves = Atlas.pending_moves(Dict(:status => "declared"), Dict(:summary => Dict(:deferred_relations => 0, :calendar_anchor_relations_pending => 0)))
        @test closed_moves[1]["status"] == "applied"
        @test occursin("No pending Calendar source anchors remain", closed_moves[1]["next"])
        @test "team-ide-affordance-map" in Set(move["id"] for move in atlas["pending_moves"])
        @test "multi-workspace-cloud-testbed" in Set(move["id"] for move in atlas["pending_moves"])
        @test "cloudflare-domain-dns-inventory" in Set(move["id"] for move in atlas["pending_moves"])
        @test "github-org-team-inventory" in Set(move["id"] for move in atlas["pending_moves"])
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
        @test occursin("Team IDE / Harness Readiness", markdown)
        @test occursin("Multi-Workspace Testbed", markdown)
        @test occursin("GitHub Org / Project Identity", markdown)
        @test occursin("Cloudflare / Domain / DNS", markdown)
        @test occursin("seen-in-browser", markdown)
        @test occursin("moos-api", markdown)
        @test occursin("moos-kernel", markdown)
        @test occursin("Step By Step HG Use", markdown)
        @test occursin("Opinionated Assessment", markdown)
    end
end
