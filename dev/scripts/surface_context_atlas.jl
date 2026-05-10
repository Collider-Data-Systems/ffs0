#!/usr/bin/env julia

module SurfaceContextAtlas

using Dates
using Downloads
using JSON3

const DEFAULT_BASE_URL = "http://localhost:8000"
const DEFAULT_ONTOLOGY = "kb/superset/ontology.json"
const DEFAULT_TOPOLOGY = "dev/config/moos-federation.topology.json"
const DEFAULT_CALENDAR_PLAN = "tmp/projections/session_pipeline/calendar/calendar_time_fabric_plan.json"
const DEFAULT_CALENDAR_WRITE_RESULT = "tmp/projections/session_pipeline/calendar/calendar_time_fabric_write_result.json"
const DEFAULT_GATE = "tmp/projections/session_pipeline/mvp/session_pipeline_gate.json"
const DEFAULT_RECOMMENDATION_PLAN = "tmp/projections/session_pipeline/recommendations/t189_t200_recommendation_hg_plan.json"
const DEFAULT_RECONCILIATION = "tmp/projections/session_pipeline/recommendations/t189_recommendation_reconciliation.json"
const DEFAULT_GRAPH_PACK = "tmp/projections/session_pipeline/graph_artifacts/session_occasion_engineering.json"
const DEFAULT_T189_GRAPH_PACK = "tmp/projections/session_pipeline/graph_artifacts/t189_recommendation_engineering.json"
const DEFAULT_DASHBOARD = "tmp/projections/session_pipeline/index.html"
const DEFAULT_OUT = "tmp/projections/session_pipeline/atlas/surface_context_atlas.json"
const DEFAULT_MARKDOWN_OUT = "tmp/projections/session_pipeline/atlas/surface_context_atlas.md"
const DEFAULT_JSONL_LOG = "../moos-kernel/moos.jsonl"
const DEFAULT_AFFORDANCE_MAP = "dev/config/session-affordance-map.json"

const THEORY_ANCHORS = [
    Dict("urn" => "urn:moos:derivation:guido.architecture-syntax-interpretation", "role" => "HG syntax, runtime interpretation functors, F/G channel boundaries"),
    Dict("urn" => "urn:moos:grammar_fragment:v316-1-depends-on", "role" => "typed dependency lingo for program surfaces"),
]

const UI_UX_ANCHORS = [
    Dict("urn" => "urn:moos:program:sam.t189.surface-context-atlas", "role" => "surface context atlas projection carrier"),
    Dict("urn" => "urn:moos:program:sam.t189.cytoscape-typed-hg-inspector", "role" => "interactive typed-HG inspector"),
    Dict("urn" => "urn:moos:view_filter:sam.t189-time-fabric-session-lens", "role" => "T189 reusable lens candidate"),
    Dict("urn" => "urn:moos:derivation:guido.t200plus.visual-projection-frame", "role" => "visual projection doctrine carrier"),
    Dict("urn" => "urn:moos:program:sam.t200plus.visual-projection-lens", "role" => "T200+ visual lens program"),
    Dict("urn" => "urn:moos:view_filter:sam.t200plus-visual-projection-lens", "role" => "T200+ visual lens view_filter"),
]

const APPLICATION_ANCHORS = [
    Dict("urn" => "urn:moos:group:my-tiny-data-collider", "role" => "application group identity"),
    Dict("urn" => "urn:moos:purpose:sam.my-tiny-data-collider-application", "role" => "application purpose"),
    Dict("urn" => "urn:moos:program:sam.t192.application-group-model-my-tiny-data-collider", "role" => "application surface-map program"),
]

function object_value(obj, name::Symbol, default=nothing)
    if obj isa AbstractDict
        if haskey(obj, name)
            return obj[name]
        end
        key = string(name)
        return haskey(obj, key) ? obj[key] : default
    end
    try
        if haskey(obj, name)
            return getproperty(obj, name)
        end
    catch
        return default
    end
    return default
end

function object_pairs(obj)
    result = Any[]
    if obj isa AbstractDict
        for (key, value) in pairs(obj)
            push!(result, (key, value))
        end
        return result
    end
    try
        for key in propertynames(obj)
            push!(result, (key, getproperty(obj, key)))
        end
    catch
        return result
    end
    return result
end

function prop_value(node, name::Symbol, default=nothing)
    props = object_value(node, :properties, nothing)
    props === nothing && return default
    record = object_value(props, name, nothing)
    record === nothing && return default
    value = object_value(record, :value, nothing)
    return value === nothing ? default : value
end

function node_title(node)
    for field in (:title, :name, :display_name, :summary, :status)
        value = prop_value(node, field, nothing)
        if value !== nothing && !isempty(strip(string(value)))
            return string(value)
        end
    end
    return string(object_value(node, :urn, "<unknown>"))
end

function read_json(path::AbstractString)
    return JSON3.read(read(path, String))
end

function safe_read_json(path::AbstractString)
    isfile(path) || return Dict{String, Any}()
    try
        return read_json(path)
    catch
        return Dict{String, Any}()
    end
end

function fetch_json(base_url::AbstractString, path::AbstractString)
    url = string(rstrip(base_url, '/'), "/", lstrip(path, '/'))
    temp_path = Downloads.download(url)
    try
        return JSON3.read(read(temp_path, String))
    finally
        rm(temp_path; force=true)
    end
end

function write_json(path::AbstractString, value)
    mkpath(dirname(path))
    open(path, "w") do io
        JSON3.pretty(io, value)
        println(io)
    end
end

format_utc(dt::DateTime) = string(Dates.format(dt, dateformat"yyyy-mm-ddTHH:MM:SS"), "Z")

function nodes_by_urn(nodes)
    result = Dict{String, Any}()
    for node in nodes
        urn = string(object_value(node, :urn, ""))
        !isempty(urn) && (result[urn] = node)
    end
    return result
end

function relation_port_count(relations, port_names::Vector{String})
    ports = Set(port_names)
    return count(rel -> string(object_value(rel, :src_port, "")) in ports || string(object_value(rel, :tgt_port, "")) in ports, relations)
end

function file_summary(path::AbstractString)
    exists = isfile(path)
    size = exists ? filesize(path) : 0
    lines = 0
    if exists
        open(path, "r") do io
            for _ in eachline(io)
                lines += 1
            end
        end
    end
    return Dict("path" => path, "exists" => exists, "bytes" => size, "line_count" => lines)
end

function command_output(cmd::Cmd)
    try
        return strip(read(cmd, String))
    catch err
        return string("<unavailable: ", err, ">")
    end
end

function git_repo_summary(label::AbstractString, path::AbstractString)
    exists = isdir(path)
    return Dict(
        "label" => label,
        "path" => path,
        "exists" => exists,
        "branch" => exists ? command_output(`git -C $path rev-parse --abbrev-ref HEAD`) : "",
        "head" => exists ? command_output(`git -C $path rev-parse --short HEAD`) : "",
        "status_short" => exists ? command_output(`git -C $path status --short --branch`) : ""
    )
end

function as_array(value)
    value === nothing && return Any[]
    value isa AbstractString && return Any[value]
    try
        return collect(value)
    catch
        return Any[]
    end
end

function int_value(obj, name::Symbol, default::Integer=0)
    value = object_value(obj, name, default)
    try
        return Int(value)
    catch
        return default
    end
end

function session_affordance_summary(affordance_map)
    sessions = as_array(object_value(affordance_map, :sessions, Any[]))
    skills = Set{String}()
    prompts = Set{String}()
    mcp_servers = Set{String}()
    hosts = Set{String}()
    harness_count = 0
    rows = Any[]

    for session in sessions
        host = string(object_value(session, :host, ""))
        !isempty(host) && push!(hosts, host)
        session_skills = [string(skill) for skill in as_array(object_value(session, :skills, Any[]))]
        session_prompts = [string(prompt) for prompt in as_array(object_value(session, :prompts, Any[]))]
        harnesses = [string(harness) for harness in as_array(object_value(session, :harnesses, Any[]))]
        for skill in session_skills
            !isempty(skill) && push!(skills, skill)
        end
        for prompt in session_prompts
            !isempty(prompt) && push!(prompts, prompt)
        end
        mcp_server = string(object_value(session, :mcp_server, ""))
        !isempty(mcp_server) && push!(mcp_servers, mcp_server)
        harness_count += length(harnesses)
        push!(rows, Dict(
            "key" => string(object_value(session, :key, "")),
            "host" => host,
            "desktop" => object_value(session, :desktop, nothing),
            "session_urn" => string(object_value(session, :session_urn, "")),
            "actor_urn" => string(object_value(session, :actor_urn, "")),
            "emit_kernel" => string(object_value(session, :emit_kernel, "")),
            "mcp_server" => mcp_server,
            "workspace" => string(object_value(session, :workspace, "")),
            "harnesses" => harnesses,
            "skill_count" => length(session_skills),
            "prompt_count" => length(session_prompts),
            "validation_count" => length(as_array(object_value(session, :validation, Any[])))
        ))
    end

    return Dict(
        "session_count" => length(sessions),
        "host_count" => length(hosts),
        "harness_count" => harness_count,
        "skill_count" => length(skills),
        "prompt_count" => length(prompts),
        "mcp_server_count" => length(mcp_servers),
        "skills" => sort(collect(skills)),
        "prompts" => sort(collect(prompts)),
        "mcp_servers" => sort(collect(mcp_servers)),
        "sessions" => rows
    )
end

function workspace_testbed_summary(affordance_map, index)
    testbed = object_value(affordance_map, :multi_workspace_testbed, Dict())
    workspaces = as_array(object_value(testbed, :workspaces, Any[]))
    services = Set{String}()
    channel_rows = Any[]
    existing_count = 0
    planned_count = 0

    for workspace in workspaces
        channels = as_array(object_value(workspace, :channels, Any[]))
        for channel in channels
            service = string(object_value(channel, :service, ""))
            !isempty(service) && push!(services, service)
            urn = string(object_value(channel, :channel_urn, ""))
            exists = haskey(index, urn)
            existing_count += exists ? 1 : 0
            planned_count += exists ? 0 : 1
            push!(channel_rows, Dict(
                "workspace_slug" => string(object_value(workspace, :slug, "")),
                "service" => service,
                "kind" => string(object_value(channel, :kind, "")),
                "channel_urn" => urn,
                "status" => string(object_value(channel, :status, "planned")),
                "present_in_hg" => exists
            ))
        end
    end

    return Dict(
        "status" => string(object_value(testbed, :status, "planned")),
        "purpose_urn" => string(object_value(testbed, :purpose_urn, "")),
        "program_urn" => string(object_value(testbed, :program_urn, "")),
        "owner_group_urn" => string(object_value(testbed, :owner_group_urn, "")),
        "workspace_count" => length(workspaces),
        "service_count" => length(services),
        "channel_count" => length(channel_rows),
        "existing_channel_count" => existing_count,
        "planned_channel_count" => planned_count,
        "services" => sort(collect(services)),
        "channels" => channel_rows,
        "credential_policy" => string(object_value(testbed, :credential_policy, ""))
    )
end

function github_identity_summary(affordance_map)
    github = object_value(affordance_map, :github_identity, Dict())
    coverage = object_value(github, :hg_urn_coverage, Dict())
    known_populated = int_value(coverage, :known_populated, 0)
    known_total = int_value(coverage, :known_total, 0)
    percent = known_total == 0 ? 0.0 : round(100 * known_populated / known_total; digits=1)
    return Dict(
        "status" => string(object_value(github, :status, "inventory-first")),
        "org" => string(object_value(github, :org, "")),
        "project_number" => object_value(github, :project_number, nothing),
        "project_urn" => string(object_value(github, :project_urn, "")),
        "org_channel_urn" => string(object_value(github, :org_channel_urn, "")),
        "hg_urn_coverage" => Dict(
            "known_populated" => known_populated,
            "known_total" => known_total,
            "percent" => percent,
            "ambiguous_rows" => int_value(coverage, :ambiguous_rows, 0),
            "legacy_non_urn_rows" => int_value(coverage, :legacy_non_urn_rows, 0),
            "source" => string(object_value(coverage, :source, ""))
        ),
        "sync_policy" => string(object_value(github, :sync_policy, ""))
    )
end

function network_identity_summary(affordance_map, topology, index)
    network = object_value(affordance_map, :network_identity, Dict())
    cloudflare = object_value(topology, :cloudflare, Dict())
    topology_hostnames = object_value(cloudflare, :hostnames, Dict())
    root_hostname = string(object_value(topology_hostnames, :root, ""))
    domain = string(object_value(network, :domain, root_hostname))
    access = object_value(network, :access_applications, Dict())

    hostname_rows = Any[]
    for (role, hostname) in sort(object_pairs(topology_hostnames); by=pair -> string(pair[1]))
        push!(hostname_rows, Dict(
            "role" => string(role),
            "hostname" => string(hostname),
            "source" => "topology"
        ))
    end
    if isempty(hostname_rows)
        for row in as_array(object_value(network, :expected_hostnames, Any[]))
            push!(hostname_rows, Dict(
                "role" => string(object_value(row, :role, "")),
                "hostname" => string(object_value(row, :hostname, "")),
                "surface" => string(object_value(row, :surface, "")),
                "source" => "affordance-map"
            ))
        end
    end

    access_rows = Any[]
    policy_assignment_count = 0
    for app in as_array(object_value(access, :applications, Any[]))
        policies_assigned = int_value(app, :policies_assigned, 0)
        policy_assignment_count += policies_assigned
        push!(access_rows, Dict(
            "name" => string(object_value(app, :name, "")),
            "application_url" => string(object_value(app, :application_url, "")),
            "hostname_role" => string(object_value(app, :hostname_role, "")),
            "type" => string(object_value(app, :type, "")),
            "total_domains" => int_value(app, :total_domains, 0),
            "policies_assigned" => policies_assigned
        ))
    end

    planned_surfaces = Any[]
    existing_count = 0
    for surface in as_array(object_value(network, :planned_surfaces, Any[]))
        urn = string(object_value(surface, :surface_urn, object_value(surface, :channel_urn, "")))
        exists = haskey(index, urn)
        existing_count += exists ? 1 : 0
        push!(planned_surfaces, Dict(
            "role" => string(object_value(surface, :role, "")),
            "surface_urn" => urn,
            "status" => string(object_value(surface, :status, "planned")),
            "present_in_hg" => exists
        ))
    end

    return Dict(
        "status" => string(object_value(network, :status, "inventory-first")),
        "provider" => string(object_value(network, :provider, "cloudflare")),
        "domain" => domain,
        "topology_source" => string(object_value(network, :topology_source, DEFAULT_TOPOLOGY)),
        "dashboard_observation" => object_value(network, :dashboard_observation, Dict()),
        "access_applications" => Dict(
            "status" => string(object_value(access, :status, "")),
            "source" => string(object_value(access, :source, "")),
            "application_count" => length(access_rows),
            "policy_assignment_count" => policy_assignment_count,
            "applications" => access_rows,
            "local_only_fields" => [string(field) for field in as_array(object_value(access, :local_only_fields, Any[]))]
        ),
        "dns_policy" => string(object_value(network, :dns_policy, "")),
        "hostname_count" => length(hostname_rows),
        "hostnames" => hostname_rows,
        "planned_surface_count" => length(planned_surfaces),
        "existing_surface_count" => existing_count,
        "planned_surfaces" => planned_surfaces,
        "tunnel_id_present" => !isempty(string(object_value(cloudflare, :tunnel_id, "")))
    )
end

function calendar_summary(calendar_plan, write_result)
    events = collect(object_value(calendar_plan, :events, Any[]))
    results = collect(object_value(write_result, :results, Any[]))
    actions = Dict{String, Int}()
    for row in results
        action = string(object_value(row, :action, "<none>"))
        actions[action] = get(actions, action, 0) + 1
    end
    projection_ids = [string(object_value(event, :projection_id, "")) for event in events]
    return Dict(
        "planned_event_count" => length(events),
        "write_result_count" => length(results),
        "actions" => actions,
        "projection_id_count" => count(!isempty, projection_ids),
        "sample_projection_ids" => projection_ids[1:min(length(projection_ids), 6)]
    )
end

function wf07_status(ontology)
    for spec in object_value(ontology, :rewrite_categories, Any[])
        string(object_value(spec, :id, "")) == "WF07" || continue
        primary = Dict("src_port" => string(object_value(spec, :src_port, "")), "tgt_port" => string(object_value(spec, :tgt_port, "")))
        additional = collect(object_value(spec, :additional_port_pairs, Any[]))
        has_anchor = any(pair -> string(object_value(pair, :src_port, "")) == "anchors" && string(object_value(pair, :tgt_port, "")) == "anchor", additional)
        return Dict(
            "primary_pair" => primary,
            "additional_pair_count" => length(additional),
            "has_anchors_anchor_pair" => has_anchor,
            "status" => has_anchor ? "declared" : "needs-rewrite-category-additional-pair"
        )
    end
    return Dict("status" => "WF07 missing")
end

function anchor_rows(anchor_specs, index)
    rows = Any[]
    for spec in anchor_specs
        urn = string(spec["urn"])
        node = get(index, urn, nothing)
        push!(rows, Dict(
            "urn" => urn,
            "role" => spec["role"],
            "present" => node !== nothing,
            "type_id" => node === nothing ? "" : string(object_value(node, :type_id, "")),
            "title" => node === nothing ? "" : node_title(node)
        ))
    end
    return rows
end

function program_irl_rows(nodes, relations; limit::Integer=40)
    relation_urns = Set{String}()
    for rel in relations
        port_hit = string(object_value(rel, :src_port, "")) in ["depends-on", "anchors", "causes"] || string(object_value(rel, :tgt_port, "")) in ["depended-by", "anchor", "caused-by"]
        if port_hit
            push!(relation_urns, string(object_value(rel, :src_urn, "")))
            push!(relation_urns, string(object_value(rel, :tgt_urn, "")))
        end
    end
    pattern = r"IRL|Calendar|Google|GitHub|Workspace|website|DNS|server|external|surface|projection|dashboard|visual|JSONL|jsonl|repo"i
    rows = Any[]
    for node in nodes
        string(object_value(node, :type_id, "")) == "program" || continue
        urn = string(object_value(node, :urn, ""))
        props_text = sprint(io -> JSON3.write(io, object_value(node, :properties, Dict())))
        title = node_title(node)
        property_hit = occursin(pattern, props_text) || occursin(pattern, urn) || occursin(pattern, title)
        relation_hit = urn in relation_urns
        if property_hit || relation_hit
            push!(rows, Dict(
                "urn" => urn,
                "title" => title,
                "status" => string(prop_value(node, :status, "")),
                "property_hit" => property_hit,
                "dependency_or_anchor_relation_hit" => relation_hit
            ))
        end
        length(rows) >= limit && break
    end
    return rows
end

function surface_rows(; health, nodes, relations, ontology, calendar_plan, write_result, gate, graph_pack, t189_graph_pack, dashboard_path, jsonl_log_path, team_setup=Dict(), workspace_testbed=Dict(), github_identity=Dict(), network_identity=Dict())
    health_status = string(object_value(health, :status, ""))
    jsonl = file_summary(jsonl_log_path)
    calendar = calendar_summary(calendar_plan, write_result)
    gate_status = string(object_value(gate, :overall_status, ""))
    return [
        Dict("id" => "folded-hg-json", "header" => "JSON API", "status" => health_status == "ok" ? "pass" : "warn", "summary" => "Folded HG state from /state/nodes, /state/relations, and /healthz.", "evidence" => Dict("nodes" => length(nodes), "relations" => length(relations), "ontology_version" => object_value(health, :ontology_version, object_value(ontology, :version, "")), "log_len" => object_value(health, :log_len, nothing))),
        Dict("id" => "append-only-jsonl", "header" => "JSONL Log", "status" => jsonl["exists"] ? "pass" : "warn", "summary" => "Append-only kernel log. This is the persisted source folded into HG state.", "evidence" => jsonl),
        Dict("id" => "git-repositories", "header" => "Git Repositories", "status" => "pass", "summary" => "Code and docs move through small commits in ffs0, moos-kernel, and moos-router; generated projection outputs remain local artifacts.", "evidence" => Dict("repository_count" => 3)),
        Dict("id" => "team-ide-harnesses", "header" => "Team IDE / Harnesses", "status" => int_value(team_setup, :session_count, 0) > 0 ? "pass" : "warn", "summary" => "Projected session affordances for VS Code, Claude, Antigravity, Cowork, skills, prompts, and MCP servers.", "evidence" => team_setup),
        Dict("id" => "multi-workspace-testbed", "header" => "Multi-Workspace Testbed", "status" => int_value(workspace_testbed, :channel_count, 0) > 0 && int_value(workspace_testbed, :planned_channel_count, 0) == 0 ? "pass" : "warn", "summary" => "Planned Google Workspace channel bundles for four additional Gmail accounts, kept as external channels instead of user principals.", "evidence" => workspace_testbed),
        Dict("id" => "github-org-project", "header" => "GitHub Org / Project Identity", "status" => "warn", "summary" => "GitHub organization, teams, repos, and Project #4 are external identity surfaces; Project status G-sync waits for reliable HG URN coverage.", "evidence" => github_identity),
        Dict("id" => "cloudflare-domain-dns", "header" => "Cloudflare / Domain / DNS", "status" => string(object_value(network_identity, :status, "")) in ["verified", "ready"] ? "pass" : "warn", "summary" => "Cloudflare, domain names, DNS records, and tunnel hostnames are public network projection surfaces for my-tiny-data-collider.", "evidence" => network_identity),
        Dict("id" => "google-calendar", "header" => "Google Calendar", "status" => calendar["planned_event_count"] > 0 ? "pass" : "warn", "summary" => "Calendar is an IRL projection surface keyed by moos_projection_id; event nodes are G-observations back into HG.", "evidence" => calendar),
        Dict("id" => "dashboard", "header" => "Dashboard", "status" => isfile(dashboard_path) || !isempty(gate_status) ? "pass" : "warn", "summary" => "Human control surface that links generated artifacts, gates, visuals, and interactive inspectors.", "evidence" => Dict("path" => dashboard_path, "exists" => isfile(dashboard_path), "gate_status" => gate_status)),
        Dict("id" => "visual-artifacts", "header" => "Visuals", "status" => Int(object_value(graph_pack, :node_count, 0)) > 0 && Int(object_value(t189_graph_pack, :node_count, 0)) > 0 ? "pass" : "warn", "summary" => "Graphviz DOT/SVG is deterministic review; Cytoscape element JSON is interactive exploration.", "evidence" => Dict("session_nodes" => object_value(graph_pack, :node_count, 0), "session_relations" => object_value(graph_pack, :relation_count, 0), "t189_nodes" => object_value(t189_graph_pack, :node_count, 0), "t189_relations" => object_value(t189_graph_pack, :relation_count, 0))),
        Dict("id" => "types-relations-programs", "header" => "Types / Relations / Programs", "status" => !isempty(nodes) && !isempty(relations) ? "pass" : "warn", "summary" => "A compact operator view of node types, WF relation families, and programs with IRL/external dependencies or properties.", "evidence" => Dict("type_count" => length(Set(string(object_value(node, :type_id, "")) for node in nodes)), "wf_count" => length(Set(string(object_value(rel, :rewrite_category, "")) for rel in relations)), "dependency_like_relations" => relation_port_count(relations, ["depends-on", "depended-by", "anchors", "anchor", "causes", "caused-by"])))
    ]
end

function pending_moves(wf07, reconciliation, affordance_map=Dict())
    summary = object_value(reconciliation, :summary, Dict())
    deferred = Int(object_value(summary, :deferred_relations, 0))
    return [
        Dict("id" => "wf07-anchor-declaration", "status" => string(object_value(wf07, :status, "")) == "declared" ? "ready-for-anchor-apply-review" : "pending-ontology-patch", "header" => "Resolve WF07 top-level declaration", "next" => "Add anchors/anchor as an explicit WF07 additional_port_pair, reload/runtime-validate, then apply the deferred Calendar source anchors.", "evidence" => Dict("wf07" => wf07, "deferred_relations" => deferred)),
        Dict("id" => "project-4-row-identity", "status" => "planned", "header" => "Repair Project #4 row identity", "next" => "Dry-run item inventory, populate HG URN coverage, then allow board rows to become conservative G-direction observations.", "evidence" => Dict("program_urn" => "urn:moos:program:sam.t189.github-project-urn-refresh")),
        Dict("id" => "reusable-lens-contracts", "status" => "planned", "header" => "Promote reusable lens contracts", "next" => "Keep script presets as executable proof, then promote only repeated lens shapes into view_filter carriers.", "evidence" => Dict("t189_view_filter" => "urn:moos:view_filter:sam.t189-time-fabric-session-lens", "t200_view_filter" => "urn:moos:view_filter:sam.t200plus-visual-projection-lens")),
        Dict("id" => "tiny-data-collider-surface-map", "status" => "planned", "header" => "Give my-tiny-data-collider a surface map", "next" => "Model website, DNS, GitHub, Calendar, Workspace, server/runtime, and readback surfaces as application-domain topology, not runtime repo identity.", "evidence" => Dict("group" => "urn:moos:group:my-tiny-data-collider")),
        Dict("id" => "runtime-repos-boring", "status" => "standing-rule", "header" => "Keep runtime repos boring", "next" => "Reserve moos-kernel for log/fold/operad/session/transport correctness and moos-router for routing; put application surfaces in ffs0/HG/application repos.", "evidence" => Dict("repos" => ["moos-kernel", "moos-router", "ffs0"])),
        Dict("id" => "team-ide-affordance-map", "status" => "planned", "header" => "Validate team IDE affordance map", "next" => "Use the session affordance config to verify each open IDE or harness has the right session, actor, prompt, skills, MCP server, and validation command before emissions.", "evidence" => Dict("session_count" => length(as_array(object_value(affordance_map, :sessions, Any[]))))),
        Dict("id" => "multi-workspace-cloud-testbed", "status" => "planned", "header" => "Stage four Google Workspace test bundles", "next" => "Create reviewed channel ADD payloads for the four neutral test workspaces, then run read-only credential checks before any Calendar writes or Workspace ingests.", "evidence" => Dict("program_urn" => string(object_value(object_value(affordance_map, :multi_workspace_testbed, Dict()), :program_urn, "")))),
        Dict("id" => "cloudflare-domain-dns-inventory", "status" => "planned", "header" => "Inventory Cloudflare domain and DNS", "next" => "Read Cloudflare zone, DNS records, tunnel routes, and public hostnames for my-tiny-data-collider before any DNS writes or website projection claims.", "evidence" => Dict("domain" => string(object_value(object_value(affordance_map, :network_identity, Dict()), :domain, "")))),
        Dict("id" => "github-org-team-inventory", "status" => "planned", "header" => "Inventory GitHub org, teams, repos, and Project #4", "next" => "Generate a dry identity inventory first; continue HG URN repair and keep board status G-sync blocked until row identity is reliable.", "evidence" => Dict("project_urn" => string(object_value(object_value(affordance_map, :github_identity, Dict()), :project_urn, ""))))
    ]
end

function step_by_step_hg()
    return [
        Dict("step" => 1, "header" => "Read folded state", "detail" => "Use /healthz, /state/nodes, and /state/relations as the current graph view; keep JSON API output distinct from the JSONL log."),
        Dict("step" => 2, "header" => "Name the surface", "detail" => "Decide whether the target is Git, Calendar, dashboard, visual, website, DNS, Workspace, or another external surface."),
        Dict("step" => 3, "header" => "Find or create HG identity", "detail" => "Reuse existing claim/program/derivation/view_filter/group URNs when present; only create new carriers when the shape is durable."),
        Dict("step" => 4, "header" => "Project with F", "detail" => "Generate a dry planner artifact first. Writers are explicit actuator boundaries, not hidden side effects of planning."),
        Dict("step" => 5, "header" => "Observe with G", "detail" => "Read external results back as typed HG evidence such as calendar_event, claim, derivation, or status mutation."),
        Dict("step" => 6, "header" => "Reconcile", "detail" => "Report applied, pending, and deferred rows separately before any additional APPLY batch."),
        Dict("step" => 7, "header" => "Gate and visualize", "detail" => "Expose the result through the dashboard and visual lenses, with why-visible evidence for agents and operators."),
    ]
end

function assessment()
    return Dict(
        "honest_opinion" => "The projection stack is strong because it preserves source-of-truth boundaries and produces deterministic artifacts, but it still makes the operator assemble too much context from separate files. The atlas is the missing table of contents: one generated map that tells a person and an agent what each surface is, why it exists, and what can be trusted.",
        "math_logic_hook" => "Treat each projection as a typed functor from folded HG state to a surface category, with G-ingest as the observation functor back into HG. Logic-programming style rules should explain lens membership: why a node is visible, which relation path admitted it, and which gate made it actionable.",
        "ui_ux_hook" => "Graphviz should stay the proof artifact. Cytoscape should become the day-to-day exploration UI, with selection, lineage, why-visible evidence, and stable surface identity shown in the inspector. The dashboard should be a cockpit, not a second source of truth."
    )
end

function plan_atlas(nodes, relations; health=Dict(), ontology=Dict(), topology=Dict(), calendar_plan=Dict(), write_result=Dict(), gate=Dict(), recommendation_plan=Dict(), reconciliation=Dict(), graph_pack=Dict(), t189_graph_pack=Dict(), affordance_map=Dict(), repo_root=pwd(), dashboard_path=DEFAULT_DASHBOARD, jsonl_log_path=DEFAULT_JSONL_LOG, generated_at::String=format_utc(now(UTC)), base_url::String=DEFAULT_BASE_URL)
    index = nodes_by_urn(nodes)
    wf07 = wf07_status(ontology)
    repo_parent = normpath(joinpath(repo_root, ".."))
    team_setup = session_affordance_summary(affordance_map)
    workspace_testbed = workspace_testbed_summary(affordance_map, index)
    github_identity = github_identity_summary(affordance_map)
    network_identity = network_identity_summary(affordance_map, topology, index)
    return Dict(
        "mode" => "plan",
        "projection_kind" => "surface_context_atlas",
        "generated_at" => generated_at,
        "base_url" => base_url,
        "how_to_read" => [
            "HG folded state is truth for graph claims.",
            "JSON/JSONL/Git/Calendar/dashboard/visual surfaces are projections or observations with explicit identity keys.",
            "Applied, pending, and deferred rows must stay separate.",
        ],
        "surfaces" => surface_rows(; health=health, nodes=nodes, relations=relations, ontology=ontology, calendar_plan=calendar_plan, write_result=write_result, gate=gate, graph_pack=graph_pack, t189_graph_pack=t189_graph_pack, dashboard_path=dashboard_path, jsonl_log_path=jsonl_log_path, team_setup=team_setup, workspace_testbed=workspace_testbed, github_identity=github_identity, network_identity=network_identity),
        "git_repositories" => [
            git_repo_summary("ffs0", repo_root),
            git_repo_summary("moos-kernel", joinpath(repo_parent, "moos-kernel")),
            git_repo_summary("moos-router", joinpath(repo_parent, "moos-router")),
        ],
        "team_setup" => team_setup,
        "multi_workspace_testbed" => workspace_testbed,
        "github_identity" => github_identity,
        "network_identity" => network_identity,
        "hg_anchors" => Dict(
            "category_functor_logic" => anchor_rows(THEORY_ANCHORS, index),
            "ui_ux_visualization" => anchor_rows(UI_UX_ANCHORS, index),
            "application_surface_map" => anchor_rows(APPLICATION_ANCHORS, index),
        ),
        "programs_with_irl_external_shape" => program_irl_rows(nodes, relations),
        "pending_moves" => pending_moves(wf07, reconciliation, affordance_map),
        "step_by_step_hg" => step_by_step_hg(),
        "recommendation_selection_count" => length(object_value(recommendation_plan, :selected_t189_recommendations, Any[])),
        "assessment" => assessment(),
    )
end

function write_markdown(path::AbstractString, atlas)
    mkpath(dirname(path))
    open(path, "w") do io
        println(io, "# Surface Context Atlas")
        println(io)
        println(io, "Generated: ", atlas["generated_at"])
        println(io, "Base URL: ", atlas["base_url"])
        println(io)
        println(io, "## How To Read This")
        for line in atlas["how_to_read"]
            println(io, "- ", line)
        end
        println(io)
        println(io, "## Surface Map")
        for surface in atlas["surfaces"]
            println(io, "### ", surface["header"])
            println(io, "Status: `", surface["status"], "`")
            println(io)
            println(io, surface["summary"])
            println(io)
        end
        println(io, "## Existing HG Anchors")
        for (group, rows) in atlas["hg_anchors"]
            println(io, "### ", group)
            for row in rows
                mark = row["present"] ? "present" : "missing"
                println(io, "- `", row["urn"], "` [", mark, "] - ", row["role"])
            end
            println(io)
        end
        if haskey(atlas, "team_setup")
            println(io, "## Team IDE / Harness Readiness")
            team = atlas["team_setup"]
            println(io, "Sessions: ", team["session_count"], "; hosts: ", team["host_count"], "; harnesses: ", team["harness_count"], "; skills: ", team["skill_count"], "; prompts: ", team["prompt_count"])
            println(io)
            for row in team["sessions"]
                println(io, "- `", row["session_urn"], "` - ", row["key"], " on ", row["host"], " via ", row["mcp_server"])
            end
            println(io)
        end
        if haskey(atlas, "multi_workspace_testbed")
            println(io, "## Multi-Workspace Testbed")
            workspace = atlas["multi_workspace_testbed"]
            println(io, "Status: `", workspace["status"], "`; workspaces: ", workspace["workspace_count"], "; channels: ", workspace["channel_count"], "; present in HG: ", workspace["existing_channel_count"])
            println(io)
            for row in workspace["channels"]
                mark = row["present_in_hg"] ? "present" : "planned"
                println(io, "- `", row["channel_urn"], "` [", mark, "] - ", row["workspace_slug"], " / ", row["service"])
            end
            println(io)
        end
        if haskey(atlas, "github_identity")
            println(io, "## GitHub Org / Project Identity")
            github = atlas["github_identity"]
            coverage = github["hg_urn_coverage"]
            println(io, "Org: ", github["org"], "; Project: ", github["project_number"], "; HG URN coverage: ", coverage["known_populated"], "/", coverage["known_total"], " (", coverage["percent"], "%)")
            println(io)
            println(io, github["sync_policy"])
            println(io)
        end
        if haskey(atlas, "network_identity")
            println(io, "## Cloudflare / Domain / DNS")
            network = atlas["network_identity"]
            println(io, "Provider: ", network["provider"], "; domain: ", network["domain"], "; hostnames: ", network["hostname_count"], "; planned surfaces: ", network["planned_surface_count"])
            println(io)
            observation = network["dashboard_observation"]
            if !isempty(observation)
                println(io, "Dashboard: `", object_value(observation, :status, ""), "` for account `", object_value(observation, :account_label, ""), "` / zone `", object_value(observation, :zone_label, ""), "`")
                println(io)
            end
            access = network["access_applications"]
            if Int(object_value(access, :application_count, 0)) > 0
                println(io, "Access applications: ", access["application_count"], "; policy assignments: ", access["policy_assignment_count"])
                println(io)
                for app in access["applications"]
                    println(io, "- `", app["name"], "` - ", app["application_url"], " (", app["type"], ", policies: ", app["policies_assigned"], ")")
                end
                println(io)
            end
            for row in network["hostnames"]
                println(io, "- `", row["hostname"], "` - ", row["role"], " (", row["source"], ")")
            end
            println(io)
            println(io, network["dns_policy"])
            println(io)
        end
        println(io, "## Programs With IRL / External Shape")
        if isempty(atlas["programs_with_irl_external_shape"])
            println(io, "- <none>")
        else
            for row in atlas["programs_with_irl_external_shape"]
                println(io, "- `", row["urn"], "` - ", row["title"])
            end
        end
        println(io)
        println(io, "## Pending Moves")
        for move in atlas["pending_moves"]
            println(io, "- `", move["status"], "` ", move["header"], ": ", move["next"])
        end
        println(io)
        println(io, "## Step By Step HG Use")
        for row in atlas["step_by_step_hg"]
            println(io, row["step"], ". **", row["header"], "** - ", row["detail"])
        end
        println(io)
        println(io, "## Opinionated Assessment")
        assessment = atlas["assessment"]
        println(io, assessment["honest_opinion"])
        println(io)
        println(io, assessment["math_logic_hook"])
        println(io)
        println(io, assessment["ui_ux_hook"])
    end
end

function parse_args(argv)
    options = Dict(
        "base-url" => DEFAULT_BASE_URL,
        "ontology" => DEFAULT_ONTOLOGY,
        "topology" => DEFAULT_TOPOLOGY,
        "calendar-plan" => DEFAULT_CALENDAR_PLAN,
        "calendar-write-result" => DEFAULT_CALENDAR_WRITE_RESULT,
        "gate" => DEFAULT_GATE,
        "recommendation-plan" => DEFAULT_RECOMMENDATION_PLAN,
        "reconciliation" => DEFAULT_RECONCILIATION,
        "graph-pack" => DEFAULT_GRAPH_PACK,
        "t189-graph-pack" => DEFAULT_T189_GRAPH_PACK,
        "dashboard" => DEFAULT_DASHBOARD,
        "jsonl-log" => DEFAULT_JSONL_LOG,
        "affordance-map" => DEFAULT_AFFORDANCE_MAP,
        "out" => DEFAULT_OUT,
        "markdown-out" => DEFAULT_MARKDOWN_OUT,
        "nodes-file" => "",
        "relations-file" => "",
        "health-file" => "",
    )
    i = 1
    while i <= length(argv)
        arg = argv[i]
        startswith(arg, "--") || error("unexpected argument: ", arg)
        key = arg[3:end]
        haskey(options, key) || error("unknown option: ", arg)
        i < length(argv) || error("missing value for ", arg)
        options[key] = argv[i + 1]
        i += 2
    end
    return options
end

function main(argv=ARGS)
    options = parse_args(argv)
    nodes = isempty(options["nodes-file"]) ? fetch_json(options["base-url"], "/state/nodes") : read_json(options["nodes-file"])
    relations = isempty(options["relations-file"]) ? fetch_json(options["base-url"], "/state/relations") : read_json(options["relations-file"])
    health = isempty(options["health-file"]) ? fetch_json(options["base-url"], "/healthz") : read_json(options["health-file"])
    atlas = plan_atlas(
        nodes,
        relations;
        health=health,
        ontology=safe_read_json(options["ontology"]),
        topology=safe_read_json(options["topology"]),
        calendar_plan=safe_read_json(options["calendar-plan"]),
        write_result=safe_read_json(options["calendar-write-result"]),
        gate=safe_read_json(options["gate"]),
        recommendation_plan=safe_read_json(options["recommendation-plan"]),
        reconciliation=safe_read_json(options["reconciliation"]),
        graph_pack=safe_read_json(options["graph-pack"]),
        t189_graph_pack=safe_read_json(options["t189-graph-pack"]),
        affordance_map=safe_read_json(options["affordance-map"]),
        repo_root=pwd(),
        dashboard_path=options["dashboard"],
        jsonl_log_path=options["jsonl-log"],
        base_url=options["base-url"],
    )
    write_json(options["out"], atlas)
    write_markdown(options["markdown-out"], atlas)
    println("Wrote surface context atlas: ", options["out"])
    println("Wrote surface context atlas report: ", options["markdown-out"])
    println("Surfaces: ", length(atlas["surfaces"]), " Pending moves: ", length(atlas["pending_moves"]))
    return 0
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    exit(SurfaceContextAtlas.main())
end
