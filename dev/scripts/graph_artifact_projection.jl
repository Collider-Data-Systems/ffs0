#!/usr/bin/env julia

module GraphArtifactProjection

using Dates
using Downloads
using JSON3

const DEFAULT_BASE_URL = "http://localhost:8000"
const DEFAULT_ROOT_URN = "urn:moos:derivation:guido.t187-session-occasion-implementation-frame"
const DEFAULT_ROOT_URNS = join([
    DEFAULT_ROOT_URN,
    "urn:moos:system_instruction:framework.session-occasion-lingo",
    "urn:moos:grammar_fragment:v317-1-occasion-type",
    "urn:moos:pattern:session-affordance-pack",
    "urn:moos:workflow:z440-session-continuity-reconciliation",
], ";")
const DEFAULT_OUT_BASE = "tmp/projections/graph_artifacts/session_occasion_engineering"
const DEFAULT_RADIUS = 2
const DEFAULT_WFS = "WF12,WF18,WF20,WF21"
const DEFAULT_PORTS = "causes,caused-by,composes,composed-by,consumes,consumed-by,produces,produced-by,provides-kb,provided-by,grammar-promotes,grammar-promoted-by"
const DEFAULT_TYPES = "claim,derivation,grammar_fragment,knowledge_item,pattern,program,purpose,session,system_instruction,workflow"
const DEFAULT_MATCH = "session|occasion|affordance|keep|purpose|program|workflow|grammar|z440"

function object_value(obj, name::Symbol, default=nothing)
    if obj isa AbstractDict
        if haskey(obj, name)
            return obj[name]
        end
        string_name = string(name)
        return haskey(obj, string_name) ? obj[string_name] : default
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

function prop_value(node, name::Symbol, default=nothing)
    props = object_value(node, :properties, nothing)
    props === nothing && return default
    record = object_value(props, name, nothing)
    record === nothing && return default
    value = object_value(record, :value, nothing)
    return value === nothing ? default : value
end

function node_title(node)
    for field in (:title, :name, :display_name, :summary, :text)
        value = prop_value(node, field, nothing)
        if value !== nothing && !isempty(strip(string(value)))
            text = string(value)
            return length(text) > 96 ? string(text[1:96], "...") : text
        end
    end
    return string(object_value(node, :urn, "<unknown>"))
end

function split_set(raw::AbstractString)
    items = Set{String}()
    for part in split(raw, ',')
        item = strip(part)
        !isempty(item) && push!(items, String(item))
    end
    return items
end

function split_roots(raw::AbstractString)
    roots = String[]
    for part in split(raw, ';')
        item = strip(part)
        !isempty(item) && push!(roots, String(item))
    end
    return roots
end

function nodes_by_urn(nodes)
    result = Dict{String, Any}()
    for node in nodes
        urn = string(object_value(node, :urn, ""))
        !isempty(urn) && (result[urn] = node)
    end
    return result
end

function relation_allowed(rel, wf_filter::Set{String}, port_filter::Set{String})
    category = string(object_value(rel, :rewrite_category, ""))
    wf_ok = isempty(wf_filter) || category in wf_filter || "*" in wf_filter
    port_ok = isempty(port_filter) || string(object_value(rel, :src_port, "")) in port_filter || string(object_value(rel, :tgt_port, "")) in port_filter || "*" in port_filter
    return wf_ok && port_ok
end

function node_matches(node, urn::AbstractString, type_filter::Set{String}, match_regex)
    type_id = string(object_value(node, :type_id, ""))
    type_ok = isempty(type_filter) || type_id in type_filter || "*" in type_filter
    if !type_ok
        return false
    end
    match_regex === nothing && return true
    return occursin(match_regex, urn) || occursin(match_regex, node_title(node)) || occursin(match_regex, type_id)
end

function expand_neighborhood(relations, roots::Vector{String}; radius::Integer=DEFAULT_RADIUS, wf_filter=split_set(DEFAULT_WFS), port_filter=split_set(DEFAULT_PORTS))
    selected = Set{String}(roots)
    frontier = Set{String}(roots)
    for _ in 1:radius
        next_frontier = Set{String}()
        for rel in relations
            relation_allowed(rel, wf_filter, port_filter) || continue
            src = string(object_value(rel, :src_urn, ""))
            tgt = string(object_value(rel, :tgt_urn, ""))
            if src in frontier && !(tgt in selected) && !isempty(tgt)
                push!(selected, tgt)
                push!(next_frontier, tgt)
            end
            if tgt in frontier && !(src in selected) && !isempty(src)
                push!(selected, src)
                push!(next_frontier, src)
            end
        end
        isempty(next_frontier) && break
        frontier = next_frontier
    end
    return selected
end

function selected_subgraph(nodes, relations; root_urns::Vector{String}=split_roots(DEFAULT_ROOT_URNS), radius::Integer=DEFAULT_RADIUS, wf_filter=split_set(DEFAULT_WFS), port_filter=split_set(DEFAULT_PORTS), type_filter=split_set(DEFAULT_TYPES), match_pattern::String=DEFAULT_MATCH)
    index = nodes_by_urn(nodes)
    isempty(root_urns) && error("at least one root URN is required")
    missing_roots = [urn for urn in root_urns if !haskey(index, urn)]
    isempty(missing_roots) || error("root node not found: ", join(missing_roots, ", "))
    match_regex = isempty(strip(match_pattern)) ? nothing : Regex(match_pattern, "i")
    raw_selected = expand_neighborhood(relations, root_urns; radius=radius, wf_filter=wf_filter, port_filter=port_filter)
    selected = Set{String}()
    for urn in raw_selected
        haskey(index, urn) || continue
        if urn in root_urns || node_matches(index[urn], urn, type_filter, match_regex)
            push!(selected, urn)
        end
    end
    selected_relations = Any[]
    for rel in relations
        relation_allowed(rel, wf_filter, port_filter) || continue
        src = string(object_value(rel, :src_urn, ""))
        tgt = string(object_value(rel, :tgt_urn, ""))
        if src in selected && tgt in selected
            push!(selected_relations, rel)
        end
    end
    return index, selected, selected_relations
end

function compact_properties(node)
    fields = Dict{String, Any}()
    for field in (:status, :fragment_kind, :pattern_kind, :inference_kind, :confidence, :version, :owner_urn, :subject_urn)
        value = prop_value(node, field, nothing)
        if value !== nothing && !isempty(strip(string(value)))
            fields[string(field)] = value
        end
    end
    return fields
end

function node_summary(node)
    return Dict(
        "urn" => string(object_value(node, :urn, "")),
        "type_id" => string(object_value(node, :type_id, "")),
        "title" => node_title(node),
        "status" => string(prop_value(node, :status, "")),
        "properties" => compact_properties(node),
    )
end

function relation_summary(rel)
    return Dict(
        "urn" => string(object_value(rel, :urn, "")),
        "rewrite_category" => string(object_value(rel, :rewrite_category, "")),
        "src_urn" => string(object_value(rel, :src_urn, "")),
        "src_port" => string(object_value(rel, :src_port, "")),
        "tgt_urn" => string(object_value(rel, :tgt_urn, "")),
        "tgt_port" => string(object_value(rel, :tgt_port, "")),
    )
end

function increment!(dict::Dict{String, Int}, key::AbstractString)
    dict[String(key)] = get(dict, String(key), 0) + 1
end

function count_by(nodes, relations)
    type_counts = Dict{String, Int}()
    status_counts = Dict{String, Int}()
    relation_counts = Dict{String, Int}()
    for node in nodes
        increment!(type_counts, string(object_value(node, :type_id, "")))
        status = string(prop_value(node, :status, "<none>"))
        increment!(status_counts, isempty(status) ? "<none>" : status)
    end
    for rel in relations
        increment!(relation_counts, string(object_value(rel, :rewrite_category, "")))
    end
    return Dict{String, Any}(
        "type_counts" => type_counts,
        "status_counts" => status_counts,
        "relation_counts" => relation_counts,
    )
end

function root_coverage(root_urns::Vector{String}, index, selected_relations)
    coverage = Any[]
    for urn in root_urns
        haskey(index, urn) || continue
        inbound_count = 0
        outbound_count = 0
        categories = Set{String}()
        ports = Set{String}()
        for rel in selected_relations
            src = string(object_value(rel, :src_urn, ""))
            tgt = string(object_value(rel, :tgt_urn, ""))
            if src == urn || tgt == urn
                push!(categories, string(object_value(rel, :rewrite_category, "")))
                if src == urn
                    outbound_count += 1
                    push!(ports, string(object_value(rel, :src_port, "")))
                end
                if tgt == urn
                    inbound_count += 1
                    push!(ports, string(object_value(rel, :tgt_port, "")))
                end
            end
        end
        node = index[urn]
        incident_count = inbound_count + outbound_count
        push!(coverage, Dict(
            "urn" => urn,
            "type_id" => string(object_value(node, :type_id, "")),
            "title" => node_title(node),
            "connected" => incident_count > 0,
            "incident_relation_count" => incident_count,
            "inbound_relation_count" => inbound_count,
            "outbound_relation_count" => outbound_count,
            "rewrite_categories" => sort(collect(categories)),
            "ports" => sort(collect(ports)),
        ))
    end
    return coverage
end

function outgoing_ports(relations, urn::AbstractString)
    return Set([string(object_value(rel, :src_port, "")) for rel in relations if string(object_value(rel, :src_urn, "")) == urn])
end

function engineering_findings(selected_nodes, selected_relations; root_coverage=Any[])
    findings = Any[]
    for node in selected_nodes
        urn = string(object_value(node, :urn, ""))
        type_id = string(object_value(node, :type_id, ""))
        status = string(prop_value(node, :status, ""))
        if type_id == "grammar_fragment" && status == "proposed"
            push!(findings, Dict(
                "severity" => "next",
                "topic" => "grammar fragment proposed",
                "urn" => urn,
                "detail" => "A proposed grammar fragment is present in the projection.",
                "next_action" => "Review the fragment specification, decide whether to keep it proposed, promote it, or fold lessons into a later ontology bump.",
            ))
        elseif type_id == "workflow" && status == "draft"
            push!(findings, Dict(
                "severity" => "next",
                "topic" => "workflow draft",
                "urn" => urn,
                "detail" => "A draft workflow is available as executable process structure.",
                "next_action" => "Run a dry readback against its input schema, then emit only the needed compensating rewrite program.",
            ))
        elseif type_id == "pattern" && status == "draft"
            push!(findings, Dict(
                "severity" => "next",
                "topic" => "pattern draft",
                "urn" => urn,
                "detail" => "A draft pattern can be instantiated against a live session/purpose/root program.",
                "next_action" => "Instantiate it through the session context projection and compare expected affordances with actual skills/extensions/MCP servers.",
            ))
        elseif type_id == "system_instruction" && status == "active"
            push!(findings, Dict(
                "severity" => "info",
                "topic" => "active instruction",
                "urn" => urn,
                "detail" => "An active instruction is part of this projection frame.",
                "next_action" => "Project it into session context packs instead of copying it manually into every IDE surface.",
            ))
        elseif type_id == "session"
            ports = outgoing_ports(selected_relations, urn)
            if !("has-purpose" in ports)
                push!(findings, Dict(
                    "severity" => "gap",
                    "topic" => "session missing has-purpose in projection",
                    "urn" => urn,
                    "detail" => "The selected session has no visible WF19 has-purpose relation in this projected subgraph.",
                    "next_action" => "Either link a purpose when the durable purpose is known or keep the focus string as temporary occasion color.",
                ))
            end
        end
    end
    disconnected_roots = [entry for entry in root_coverage if !Bool(entry["connected"])]
    if !isempty(disconnected_roots)
        push!(findings, Dict(
            "severity" => "gap",
            "topic" => "roots disconnected in projection",
            "urn" => "<multi-root>",
            "root_urns" => [entry["urn"] for entry in disconnected_roots],
            "detail" => "One or more explicit roots are present only because they were requested directly; no selected relation connects them inside this projected frame.",
            "next_action" => "Widen the lens if the relations already exist, or emit/link the missing topology when the intended relation is durable.",
        ))
    end
    return findings
end

function plan_graph_artifact_projection(nodes, relations; root_urn::String=DEFAULT_ROOT_URN, root_urns::Vector{String}=String[], radius::Integer=DEFAULT_RADIUS, wf_filter=split_set(DEFAULT_WFS), port_filter=split_set(DEFAULT_PORTS), type_filter=split_set(DEFAULT_TYPES), match_pattern::String=DEFAULT_MATCH, health=nothing, generated_at::String=format_utc(now(UTC)), base_url::String=DEFAULT_BASE_URL)
    roots = isempty(root_urns) ? [root_urn] : root_urns
    index, selected, selected_relations = selected_subgraph(nodes, relations; root_urns=roots, radius=radius, wf_filter=wf_filter, port_filter=port_filter, type_filter=type_filter, match_pattern=match_pattern)
    selected_nodes = [index[urn] for urn in sort(collect(selected))]
    summaries = [node_summary(node) for node in selected_nodes]
    rel_summaries = [relation_summary(rel) for rel in selected_relations]
    counts = count_by(selected_nodes, selected_relations)
    coverage = root_coverage(roots, index, selected_relations)
    counts["root_coverage"] = coverage
    findings = engineering_findings(selected_nodes, selected_relations; root_coverage=coverage)
    return Dict(
        "mode" => "plan",
        "projection_kind" => "graph_artifact_engineering",
        "source" => "hg_folded_state",
        "generated_at" => generated_at,
        "base_url" => base_url,
        "health" => health === nothing ? Dict() : health,
        "root_urn" => first(roots),
        "root_urns" => roots,
        "radius" => radius,
        "filters" => Dict(
            "wfs" => sort(collect(wf_filter)),
            "ports" => sort(collect(port_filter)),
            "types" => sort(collect(type_filter)),
            "match" => match_pattern,
        ),
        "node_count" => length(summaries),
        "relation_count" => length(rel_summaries),
        "nodes" => summaries,
        "relations" => rel_summaries,
        "analysis" => counts,
        "engineering" => Dict(
            "finding_count" => length(findings),
            "findings" => findings,
        ),
    )
end

function format_utc(dt::DateTime)
    return string(Dates.format(dt, dateformat"yyyy-mm-ddTHH:MM:SS"), "Z")
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

read_json(path::AbstractString) = JSON3.read(read(path, String))

function write_json(path::AbstractString, value)
    dir = dirname(path)
    !isempty(dir) && mkpath(dir)
    open(path, "w") do io
        JSON3.pretty(io, value)
        println(io)
    end
end

function sorted_pairs(dict)
    return sort(collect(pairs(dict)); by=pair -> string(pair.first))
end

function write_markdown(path::AbstractString, plan)
    dir = dirname(path)
    !isempty(dir) && mkpath(dir)
    open(path, "w") do io
        println(io, "# mo:os Graph Artifact Projection")
        println(io)
        println(io, "Generated: ", plan["generated_at"])
        println(io, "Base URL: ", plan["base_url"])
        println(io, "Roots: ", join(plan["root_urns"], ", "))
        println(io, "Radius: ", plan["radius"])
        println(io)
        println(io, "This is a dry engineering projection from folded HG state. It does not emit rewrites; it turns a graph frame into reviewable analysis and next actions.")
        println(io)
        println(io, "## Summary")
        println(io, "- Nodes: ", plan["node_count"])
        println(io, "- Relations: ", plan["relation_count"])
        println(io, "- Findings: ", plan["engineering"]["finding_count"])
        println(io)
        println(io, "## Type Counts")
        for (key, value) in sorted_pairs(plan["analysis"]["type_counts"])
            println(io, "- ", key, ": ", value)
        end
        println(io)
        println(io, "## Relation Counts")
        for (key, value) in sorted_pairs(plan["analysis"]["relation_counts"])
            println(io, "- ", key, ": ", value)
        end
        println(io)
        println(io, "## Root Coverage")
        for entry in plan["analysis"]["root_coverage"]
            state = entry["connected"] ? "connected" : "disconnected"
            categories = isempty(entry["rewrite_categories"]) ? "<none>" : join(entry["rewrite_categories"], ", ")
            println(io, "- [", state, "] ", entry["urn"], " (", entry["type_id"], ") incident=", entry["incident_relation_count"], " categories=", categories)
        end
        println(io)
        println(io, "## Engineering Findings")
        findings = plan["engineering"]["findings"]
        if isempty(findings)
            println(io, "- <none>")
        else
            for finding in findings
                println(io, "- [", finding["severity"], "] ", finding["topic"], " — ", finding["urn"])
                println(io, "  ", finding["next_action"])
            end
        end
        println(io)
        println(io, "## Nodes")
        for node in plan["nodes"]
            status = isempty(node["status"]) ? "" : string(" status=", node["status"])
            println(io, "- ", node["urn"], " (", node["type_id"], status, ") - ", node["title"])
        end
    end
end

function parse_args(argv)
    options = Dict(
        "base-url" => DEFAULT_BASE_URL,
        "root-urn" => DEFAULT_ROOT_URN,
        "root-urns" => DEFAULT_ROOT_URNS,
        "radius" => string(DEFAULT_RADIUS),
        "wfs" => DEFAULT_WFS,
        "ports" => DEFAULT_PORTS,
        "types" => DEFAULT_TYPES,
        "match" => DEFAULT_MATCH,
        "out-base" => DEFAULT_OUT_BASE,
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

function load_state(options)
    nodes = isempty(options["nodes-file"]) ? fetch_json(options["base-url"], "/state/nodes") : read_json(options["nodes-file"])
    relations = isempty(options["relations-file"]) ? fetch_json(options["base-url"], "/state/relations") : read_json(options["relations-file"])
    health = isempty(options["health-file"]) ? fetch_json(options["base-url"], "/healthz") : read_json(options["health-file"])
    return nodes, relations, health
end

function main(argv=ARGS)
    options = parse_args(argv)
    nodes, relations, health = load_state(options)
    plan = plan_graph_artifact_projection(
        nodes,
        relations;
        root_urn=options["root-urn"],
        root_urns=split_roots(options["root-urns"]),
        radius=parse(Int, options["radius"]),
        wf_filter=split_set(options["wfs"]),
        port_filter=split_set(options["ports"]),
        type_filter=split_set(options["types"]),
        match_pattern=options["match"],
        health=health,
        base_url=options["base-url"],
    )
    json_path = string(options["out-base"], ".json")
    markdown_path = string(options["out-base"], ".md")
    write_json(json_path, plan)
    write_markdown(markdown_path, plan)
    println("Wrote graph artifact projection JSON: ", json_path)
    println("Wrote graph artifact projection Markdown: ", markdown_path)
    println("Nodes: ", plan["node_count"], " Relations: ", plan["relation_count"], " Findings: ", plan["engineering"]["finding_count"])
    return 0
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    exit(GraphArtifactProjection.main())
end
