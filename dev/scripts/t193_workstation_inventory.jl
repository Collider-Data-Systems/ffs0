#!/usr/bin/env julia

module T193WorkstationInventory

using Dates
using JSON3

const DEFAULT_JSONL_LOG = "../moos-kernel/moos.jsonl"
const DEFAULT_TOPOLOGY = "dev/config/moos-federation.topology.json"
const DEFAULT_OUT = "tmp/projections/t193_workstation_inventory/workstation_inventory.json"
const DEFAULT_MARKDOWN_OUT = "tmp/projections/t193_workstation_inventory/workstation_inventory.md"

const REQUESTED_TYPES = [
    "user",
    "group",
    "role",
    "workstation",
    "kernel",
    "session",
    "agent",
    "purpose",
    "program",
    "channel",
    "repository",
]

function object_value(obj, name::Symbol, default=nothing)
    if obj isa AbstractDict
        haskey(obj, name) && return obj[name]
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

function object_value(obj, name::AbstractString, default=nothing)
    if obj isa AbstractDict
        haskey(obj, name) && return obj[name]
        symbol_name = Symbol(name)
        return haskey(obj, symbol_name) ? obj[symbol_name] : default
    end
    try
        symbol_name = Symbol(name)
        if haskey(obj, symbol_name)
            return getproperty(obj, symbol_name)
        end
    catch
        return default
    end
    return default
end

function object_pairs(obj)
    rows = Any[]
    if obj isa AbstractDict
        for (key, value) in pairs(obj)
            push!(rows, (string(key), value))
        end
        return rows
    end
    try
        for key in propertynames(obj)
            push!(rows, (string(key), getproperty(obj, key)))
        end
    catch
        return rows
    end
    return rows
end

function shallow_dict(obj)
    result = Dict{String, Any}()
    for (key, value) in object_pairs(obj)
        result[string(key)] = value
    end
    return result
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

function split_csv(value::AbstractString)
    rows = String[]
    for part in split(value, ",")
        clean = strip(part)
        isempty(clean) || push!(rows, clean)
    end
    return rows
end

function format_utc(dt::DateTime)
    return string(Dates.format(dt, dateformat"yyyy-mm-ddTHH:MM:SS"), "Z")
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

function write_json(path::AbstractString, value)
    mkpath(dirname(path))
    open(path, "w") do io
        JSON3.pretty(io, value)
        println(io)
    end
end

function prop_value(node, name::Symbol, default="")
    props = object_value(node, :properties, Dict{String, Any}())
    record = object_value(props, name, nothing)
    record === nothing && return default
    value = object_value(record, :value, nothing)
    if value === nothing
        return record isa AbstractString ? record : default
    end
    return value
end

function node_title(node)
    for field in (:title, :name, :display_name, :summary, :status)
        value = prop_value(node, field, "")
        text = strip(string(value))
        isempty(text) || return text
    end
    return string(object_value(node, :urn, ""))
end

function node_status(node)
    status = prop_value(node, :status, "")
    return strip(string(status))
end

function fold_jsonl_log(path::AbstractString)
    nodes = Dict{String, Any}()
    relations = Dict{String, Any}()
    rewrite_counts = Dict{String, Int}()
    max_log_seq = 0
    line_count = 0

    isfile(path) || error("JSONL log not found: ", path)

    open(path, "r") do io
        for line in eachline(io)
            text = strip(line)
            isempty(text) && continue
            line_count += 1
            record = JSON3.read(text)
            env = object_value(record, :envelope, Dict{String, Any}())
            rewrite_type = string(object_value(env, :rewrite_type, ""))
            rewrite_counts[rewrite_type] = get(rewrite_counts, rewrite_type, 0) + 1
            try
                max_log_seq = max(max_log_seq, Int(object_value(record, :log_seq, max_log_seq)))
            catch
            end

            if rewrite_type == "ADD"
                urn = string(object_value(env, :node_urn, ""))
                isempty(urn) && continue
                nodes[urn] = Dict(
                    "urn" => urn,
                    "type_id" => string(object_value(env, :type_id, "")),
                    "properties" => shallow_dict(object_value(env, :properties, Dict{String, Any}())),
                )
            elseif rewrite_type == "LINK"
                urn = string(object_value(env, :relation_urn, ""))
                isempty(urn) && continue
                relations[urn] = Dict(
                    "urn" => urn,
                    "rewrite_category" => string(object_value(env, :rewrite_category, "")),
                    "src_urn" => string(object_value(env, :src_urn, "")),
                    "src_port" => string(object_value(env, :src_port, "")),
                    "tgt_urn" => string(object_value(env, :tgt_urn, "")),
                    "tgt_port" => string(object_value(env, :tgt_port, "")),
                )
            elseif rewrite_type == "UNLINK"
                urn = string(object_value(env, :relation_urn, ""))
                isempty(urn) || delete!(relations, urn)
            elseif rewrite_type == "MUTATE"
                target = string(object_value(env, :target_urn, ""))
                field = string(object_value(env, :field, ""))
                if haskey(nodes, target) && !isempty(field)
                    props = shallow_dict(object_value(nodes[target], :properties, Dict{String, Any}()))
                    props[field] = Dict("value" => object_value(env, :new_value, nothing), "mutability" => "mutable")
                    nodes[target]["properties"] = props
                end
            end
        end
    end

    node_rows = sort(collect(values(nodes)); by=row -> string(row["urn"]))
    relation_rows = sort(collect(values(relations)); by=row -> string(row["urn"]))
    return Dict(
        "log_path" => path,
        "line_count" => line_count,
        "max_log_seq" => max_log_seq,
        "rewrite_counts" => rewrite_counts,
        "nodes" => node_rows,
        "relations" => relation_rows,
    )
end

function count_by_field(rows, field::AbstractString)
    counts = Dict{String, Int}()
    for row in rows
        key = string(object_value(row, Symbol(field), object_value(row, field, "")))
        isempty(key) && continue
        counts[key] = get(counts, key, 0) + 1
    end
    return [Dict("name" => key, "count" => counts[key]) for key in sort(collect(keys(counts)))]
end

function node_summary(node)
    return Dict(
        "urn" => string(node["urn"]),
        "type_id" => string(node["type_id"]),
        "title" => node_title(node),
        "status" => node_status(node),
    )
end

function requested_type_inventory(nodes)
    rows = Any[]
    for type_id in REQUESTED_TYPES
        matches = [node_summary(node) for node in nodes if string(object_value(node, :type_id, "")) == type_id]
        sort!(matches; by=row -> string(row["urn"]))
        push!(rows, Dict("type_id" => type_id, "count" => length(matches), "nodes" => matches))
    end
    return rows
end

function relation_inventory(relations)
    by_category = Dict{String, Int}()
    by_port = Dict{String, Int}()
    for rel in relations
        category = string(object_value(rel, :rewrite_category, ""))
        isempty(category) || (by_category[category] = get(by_category, category, 0) + 1)
        src_port = string(object_value(rel, :src_port, ""))
        tgt_port = string(object_value(rel, :tgt_port, ""))
        isempty(src_port) || (by_port[src_port] = get(by_port, src_port, 0) + 1)
        isempty(tgt_port) || (by_port[tgt_port] = get(by_port, tgt_port, 0) + 1)
    end
    return Dict(
        "by_category" => [Dict("name" => key, "count" => by_category[key]) for key in sort(collect(keys(by_category)))],
        "by_port" => [Dict("name" => key, "count" => by_port[key]) for key in sort(collect(keys(by_port)))],
    )
end

function workstation_host_key(node)
    hostname = strip(string(prop_value(node, :hostname, "")))
    !isempty(hostname) && return hostname
    urn = string(object_value(node, :urn, ""))
    for prefix in ("urn:moos:workstation:", "urn:moos:ws:")
        startswith(urn, prefix) && return urn[length(prefix)+1:end]
    end
    return urn
end

function configured_kernel_rows(topology)
    rows = Any[]
    kernels = object_value(topology, :kernels, Dict{String, Any}())
    for (name, kernel) in sort(object_pairs(kernels); by=pair -> string(pair[1]))
        seats = [string(seat) for seat in as_array(object_value(kernel, :seats, Any[]))]
        push!(rows, Dict(
            "name" => name,
            "urn" => string(object_value(kernel, :urn, "")),
            "host" => string(object_value(kernel, :host, "")),
            "http_local" => string(object_value(kernel, :http_local, "")),
            "http_lan" => string(object_value(kernel, :http_lan, "")),
            "mcp_server" => string(object_value(kernel, :mcp_server, "")),
            "expected_ontology_version" => string(object_value(kernel, :expected_ontology_version, object_value(topology, :expected_ontology_version, ""))),
            "seat_count" => length(seats),
            "seats" => seats,
        ))
    end
    return rows
end

function configured_persona_rows(topology)
    rows = Any[]
    personas = object_value(topology, :personas, Dict{String, Any}())
    for (name, persona) in sort(object_pairs(personas); by=pair -> string(pair[1]))
        push!(rows, Dict(
            "name" => name,
            "actor_urn" => string(object_value(persona, :actor_urn, "")),
            "session_urn" => string(object_value(persona, :session_urn, "")),
            "opens_on_kernel" => string(object_value(persona, :opens_on_kernel, "")),
            "emit_kernel" => string(object_value(persona, :emit_kernel, "")),
            "mcp_server" => string(object_value(persona, :mcp_server, "")),
        ))
    end
    return rows
end

function host_matrix(nodes, topology, reachable_hosts, offline_hosts, planned_hosts)
    reachable = Set(reachable_hosts)
    offline = Set(offline_hosts)
    planned = Set(planned_hosts)
    workstation_nodes = [node for node in nodes if string(object_value(node, :type_id, "")) == "workstation"]
    workstation_by_host = Dict{String, Any}()
    for node in workstation_nodes
        workstation_by_host[workstation_host_key(node)] = node
    end

    kernels = configured_kernel_rows(topology)
    hosts = Set{String}()
    for host in keys(workstation_by_host)
        push!(hosts, host)
    end
    for row in kernels
        host = string(row["host"])
        isempty(host) || push!(hosts, host)
    end
    for host in planned_hosts
        push!(hosts, host)
    end

    rows = Any[]
    for host in sort(collect(hosts))
        host_kernels = [row for row in kernels if string(row["host"]) == host]
        seat_count = isempty(host_kernels) ? 0 : sum(Int(row["seat_count"]) for row in host_kernels)
        status = host in reachable ? "reachable-now" : host in offline ? "offline-now" : host in planned ? "planned-now" : "inventory-only"
        workstation = get(workstation_by_host, host, nothing)
        push!(rows, Dict(
            "host" => host,
            "status" => status,
            "present_in_hg" => workstation !== nothing,
            "workstation_urn" => workstation === nothing ? "" : string(workstation["urn"]),
            "configured_kernel_count" => length(host_kernels),
            "configured_session_count" => seat_count,
            "kernels" => host_kernels,
        ))
    end
    return rows
end

function workstation_candidate(host::AbstractString)
    safe_host = lowercase(replace(strip(host), r"[^A-Za-z0-9-]" => "-"))
    return Dict(
        "host" => safe_host,
        "status" => "candidate-confirm-hostname-ip-first",
        "workstation_urn" => string("urn:moos:workstation:", safe_host),
        "kernel_urn" => string("urn:moos:kernel:", safe_host, ".primary"),
        "session_urn" => string("urn:moos:session:sam.", safe_host, "-setup"),
        "purpose_urn" => string("urn:moos:purpose:sam.", safe_host, "-workstation-bootstrap"),
        "agent_urn" => string("urn:moos:agent:vscode.", safe_host, ".primary"),
        "router_peer_status" => "defer until primary health is green",
    )
end

function recommended_sequence()
    return [
        Dict("step" => 1, "header" => "Confirm HP ProDesk identity", "detail" => "On the HP ProDesk, record hostname, LAN IPv4, Windows user path, architecture, and whether Go/PowerShell/Git are ready."),
        Dict("step" => 2, "header" => "Clone or refresh repos", "detail" => "Bring ffs0, moos-kernel, and moos-router to the intended branches without changing hp-laptop or Z440 state."),
        Dict("step" => 3, "header" => "Start one primary kernel", "detail" => "Build moos-kernel and start only the HP ProDesk primary kernel against ontology v3.16.1 and a persistent local JSONL log."),
        Dict("step" => 4, "header" => "Run local health", "detail" => "Require /healthz to report status ok, ontology_version 3.16.1, current t_day, and a stable log_len after restart."),
        Dict("step" => 5, "header" => "Add topology config", "detail" => "After HP ProDesk health is real, add it to moos-federation.topology.json and run Doctor from hp-laptop with Z440 marked offline if needed."),
        Dict("step" => 6, "header" => "Apply reviewed HG batch", "detail" => "Only after the concrete hostname/IP is known, apply workstation, kernel, purpose, session, opens-on, has-purpose, has-occupant, and group ownership rewrites."),
        Dict("step" => 7, "header" => "Reconcile Z440 later", "detail" => "When back at the Z440, wake it, run Doctor, and compare all three workstations before moving persona seats or adding twin kernels."),
    ]
end

function plan_inventory(; log_state, topology=Dict{String, Any}(), reachable_hosts=["hp-laptop", "hpprodesk"], offline_hosts=["hp-z440"], planned_hosts=["hpprodesk"], generated_at=format_utc(now(UTC)), t_day="193")
    nodes = log_state["nodes"]
    relations = log_state["relations"]
    candidates = [workstation_candidate(host) for host in planned_hosts]
    return Dict(
        "mode" => "plan",
        "projection_kind" => "t193_workstation_inventory",
        "generated_at" => generated_at,
        "t_day" => t_day,
        "source" => Dict(
            "jsonl_log" => log_state["log_path"],
            "line_count" => log_state["line_count"],
            "max_log_seq" => log_state["max_log_seq"],
            "topology_config" => DEFAULT_TOPOLOGY,
        ),
        "operating_assumption" => "Consider hp-laptop, HP ProDesk, and HP Z440 together; run only the reachable machines now. Z440 being offline should not block HP ProDesk bootstrap.",
        "how_to_read" => [
            "The host matrix combines folded JSONL workstation nodes with the source-controlled topology config.",
            "Raw node status properties are listed as observed properties; session presence is evaluated from WF19 opens-on, has-purpose, has-occupant, and live kernel health.",
            "HP ProDesk rows are candidate planning rows until hostname, LAN IP, and first /healthz readback are real.",
        ],
        "host_matrix" => host_matrix(nodes, topology, reachable_hosts, offline_hosts, planned_hosts),
        "workstation_candidates" => candidates,
        "node_type_counts" => count_by_field(nodes, "type_id"),
        "rewrite_counts" => log_state["rewrite_counts"],
        "requested_type_inventory" => requested_type_inventory(nodes),
        "relation_inventory" => relation_inventory(relations),
        "configured_kernels" => configured_kernel_rows(topology),
        "configured_personas" => configured_persona_rows(topology),
        "recommended_sequence" => recommended_sequence(),
        "guardrails" => [
            "Do not model HP ProDesk as a Z440 replacement; it is a third workstation.",
            "Do not add HP ProDesk twin kernels until the primary kernel is healthy and restart-stable.",
            "Do not emit HG rewrites from this inventory. Use a reviewed envelope batch after hostname/IP readback.",
            "Keep Z440 in topology consideration even while it is offline.",
        ],
    )
end

function write_markdown(path::AbstractString, inventory)
    mkpath(dirname(path))
    open(path, "w") do io
        println(io, "# T193 Workstation Inventory")
        println(io)
        println(io, "Generated: ", inventory["generated_at"])
        println(io, "T-day: ", inventory["t_day"])
        println(io)
        println(io, inventory["operating_assumption"])
        println(io)

        println(io, "## How To Read This")
        println(io)
        for line in inventory["how_to_read"]
            println(io, "- ", line)
        end
        println(io)

        println(io, "## Host Matrix")
        println(io)
        println(io, "| Host | Status | HG workstation | Kernels | Sessions |")
        println(io, "|---|---|---:|---:|---:|")
        for row in inventory["host_matrix"]
            println(io, "| ", row["host"], " | `", row["status"], "` | ", row["present_in_hg"], " | ", row["configured_kernel_count"], " | ", row["configured_session_count"], " |")
        end
        println(io)

        println(io, "## HP ProDesk Candidate")
        println(io)
        for row in inventory["workstation_candidates"]
            println(io, "- Host: `", row["host"], "`")
            println(io, "- Workstation: `", row["workstation_urn"], "`")
            println(io, "- Kernel: `", row["kernel_urn"], "`")
            println(io, "- Setup session: `", row["session_urn"], "`")
            println(io, "- Agent: `", row["agent_urn"], "`")
            println(io)
        end

        println(io, "## Current Node Counts")
        println(io)
        for row in inventory["node_type_counts"]
            println(io, "- `", row["name"], "`: ", row["count"])
        end
        println(io)

        println(io, "## Requested Type Inventory")
        for group in inventory["requested_type_inventory"]
            println(io)
            println(io, "### ", group["type_id"], " (", group["count"], ")")
            if isempty(group["nodes"])
                println(io, "- <none>")
            else
                for node in group["nodes"]
                    suffix = isempty(node["status"]) ? "" : string(" - status: `", node["status"], "`")
                    println(io, "- `", node["urn"], "` - ", node["title"], suffix)
                end
            end
        end
        println(io)

        println(io, "## Configured Personas")
        println(io)
        for row in inventory["configured_personas"]
            println(io, "- `", row["name"], "`: ", row["actor_urn"], " -> ", row["session_urn"], " (emit ", row["emit_kernel"], ")")
        end
        println(io)

        println(io, "## Recommended Sequence")
        println(io)
        for row in inventory["recommended_sequence"]
            println(io, row["step"], ". **", row["header"], "** - ", row["detail"])
        end
        println(io)

        println(io, "## Guardrails")
        println(io)
        for line in inventory["guardrails"]
            println(io, "- ", line)
        end
    end
end

function parse_args(argv)
    options = Dict(
        "jsonl-log" => DEFAULT_JSONL_LOG,
        "topology" => DEFAULT_TOPOLOGY,
        "out" => DEFAULT_OUT,
        "markdown-out" => DEFAULT_MARKDOWN_OUT,
        "reachable-hosts" => "hp-laptop,hpprodesk",
        "offline-hosts" => "hp-z440",
        "planned-hosts" => "hpprodesk",
        "t-day" => "193",
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
    log_state = fold_jsonl_log(options["jsonl-log"])
    topology = safe_read_json(options["topology"])
    inventory = plan_inventory(
        log_state=log_state,
        topology=topology,
        reachable_hosts=split_csv(options["reachable-hosts"]),
        offline_hosts=split_csv(options["offline-hosts"]),
        planned_hosts=split_csv(options["planned-hosts"]),
        t_day=options["t-day"],
    )
    inventory["source"]["topology_config"] = options["topology"]
    write_json(options["out"], inventory)
    write_markdown(options["markdown-out"], inventory)
    println("Wrote T193 workstation inventory: ", options["out"])
    println("Wrote T193 workstation inventory report: ", options["markdown-out"])
    println("Hosts: ", length(inventory["host_matrix"]), " Requested types: ", length(inventory["requested_type_inventory"]))
    return 0
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    exit(T193WorkstationInventory.main())
end