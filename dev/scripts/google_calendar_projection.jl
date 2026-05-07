#!/usr/bin/env julia

module GoogleCalendarProjection

using Dates
using Downloads
using JSON3
using SHA

const DEFAULT_BASE_URL = "http://localhost:8000"
const DEFAULT_ROOT_URN = "urn:moos:program:sam.t200plus.temporal-projection-fabric"
const DEFAULT_CONTRACT_URN = "urn:moos:program:sam.t200plus.google-calendar-projection-contract"
const DEFAULT_CHANNEL_URN = "urn:moos:channel:google.calendar.sam"
const DEFAULT_T0_DATE = Date("2025-11-01")

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
    if props === nothing
        return default
    end
    record = object_value(props, name, nothing)
    if record === nothing
        return default
    end
    value = object_value(record, :value, nothing)
    if value !== nothing
        return value === nothing ? default : value
    end
    return record
end

function node_title(node)
    for field in (:title, :name, :summary)
        value = prop_value(node, field, nothing)
        if value !== nothing && !isempty(strip(string(value)))
            return string(value)
        end
    end
    return string(object_value(node, :urn, "<unknown>"))
end

function optional_t(value)
    if value === nothing || string(value) == ""
        return nothing
    end
    try
        return parse(Int, string(value))
    catch
        return nothing
    end
end

t_day_date(t_day::Integer; t0_date::Date=DEFAULT_T0_DATE) = string(t0_date + Day(t_day))

function exclusive_end_date(start_t::Integer, end_t::Integer; t0_date::Date=DEFAULT_T0_DATE)
    bounded_end_t = max(start_t, end_t)
    return t_day_date(bounded_end_t + 1; t0_date=t0_date)
end

function projection_id(urn::AbstractString, contract_urn::AbstractString=DEFAULT_CONTRACT_URN)
    digest = bytes2hex(sha1(string(contract_urn, "|", urn)))
    return string("moos-", digest[1:24])
end

function relation_is_traversable(rel)
    category = string(object_value(rel, :rewrite_category, ""))
    if !(category in ("WF18", "WF21"))
        return false
    end
    return string(object_value(rel, :src_port, "")) in ("composes", "causes")
end

function reachable_urns(relations, roots::Vector{String}; radius::Integer=2)
    selected = Set{String}(roots)
    frontier = Set{String}(roots)

    for _ in 1:radius
        next_frontier = Set{String}()
        for rel in relations
            if !relation_is_traversable(rel)
                continue
            end
            src = string(object_value(rel, :src_urn, ""))
            tgt = string(object_value(rel, :tgt_urn, ""))
            if src in frontier && !(tgt in selected) && !isempty(tgt)
                push!(selected, tgt)
                push!(next_frontier, tgt)
            end
        end
        if isempty(next_frontier)
            break
        end
        frontier = next_frontier
    end

    return selected
end

function calendar_event_payload(node; contract_urn::String=DEFAULT_CONTRACT_URN, t0_date::Date=DEFAULT_T0_DATE)
    urn = string(object_value(node, :urn, ""))
    type_id = string(object_value(node, :type_id, ""))
    title = node_title(node)
    start_date = nothing
    end_date = nothing
    event_kind = nothing

    if type_id == "calendar_event"
        event_date = prop_value(node, :date, nothing)
        if event_date === nothing
            event_t = optional_t(prop_value(node, :t_day, nothing))
            if event_t === nothing
                return nothing
            end
            event_date = t_day_date(event_t; t0_date=t0_date)
        end
        start_date = string(event_date)
        end_date = string(Date(start_date) + Day(1))
        event_kind = "calendar_event_anchor"
    elseif type_id == "program"
        start_t = optional_t(prop_value(node, :starts_t, nothing))
        target_t = optional_t(prop_value(node, :target_t, nothing))
        deadline_t = optional_t(prop_value(node, :deadline_t, nothing))
        end_t = deadline_t === nothing ? target_t : deadline_t
        if start_t === nothing
            start_t = end_t
        end
        if start_t === nothing || end_t === nothing
            return nothing
        end
        start_date = t_day_date(start_t; t0_date=t0_date)
        end_date = exclusive_end_date(start_t, end_t; t0_date=t0_date)
        event_kind = "program_temporal_projection"
    else
        return nothing
    end

    scope = prop_value(node, :scope, nothing)
    if scope === nothing || isempty(strip(string(scope)))
        scope = prop_value(node, :summary, "")
    end
    description_parts = [
        string("HG URN: ", urn),
        string("Projection contract: ", contract_urn),
    ]
    if scope !== nothing && !isempty(strip(string(scope)))
        push!(description_parts, "")
        push!(description_parts, string(scope))
    end

    id = projection_id(urn, contract_urn)
    return Dict(
        "operation" => "upsert",
        "projection_id" => id,
        "source_urn" => urn,
        "source_type" => type_id,
        "event_kind" => event_kind,
        "calendar_label" => "purple",
        "google_event" => Dict(
            "summary" => title,
            "description" => join(description_parts, "\n"),
            "start" => Dict("date" => start_date),
            "end" => Dict("date" => end_date),
            "extendedProperties" => Dict(
                "private" => Dict(
                    "moos_urn" => urn,
                    "moos_contract_urn" => contract_urn,
                    "moos_projection_id" => id,
                ),
            ),
        ),
    )
end

function plan_calendar_projection(nodes, relations; root_urn::String=DEFAULT_ROOT_URN, contract_urn::String=DEFAULT_CONTRACT_URN, channel_urn::String=DEFAULT_CHANNEL_URN, radius::Integer=2, t0_date::Date=DEFAULT_T0_DATE)
    nodes_by_urn = Dict{String, Any}()
    for node in nodes
        nodes_by_urn[string(object_value(node, :urn, ""))] = node
    end

    selected = reachable_urns(relations, [root_urn, contract_urn]; radius=radius)
    events = Vector{Dict{String, Any}}()
    for urn in sort(collect(selected))
        if !haskey(nodes_by_urn, urn)
            continue
        end
        payload = calendar_event_payload(nodes_by_urn[urn]; contract_urn=contract_urn, t0_date=t0_date)
        if payload !== nothing
            push!(events, payload)
        end
    end

    sort!(events; by = event -> (event["google_event"]["start"]["date"], event["source_urn"]))

    return Dict(
        "mode" => "plan",
        "source" => "hg",
        "root_urn" => root_urn,
        "contract_urn" => contract_urn,
        "channel_urn" => channel_urn,
        "t0_date" => string(t0_date),
        "event_count" => length(events),
        "events" => events,
    )
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

function parse_args(argv)
    options = Dict(
        "base-url" => DEFAULT_BASE_URL,
        "root-urn" => DEFAULT_ROOT_URN,
        "contract-urn" => DEFAULT_CONTRACT_URN,
        "channel-urn" => DEFAULT_CHANNEL_URN,
        "radius" => "2",
        "t0-date" => string(DEFAULT_T0_DATE),
        "out" => "tmp/projections/google_calendar_projection_plan.json",
        "nodes-file" => "",
        "relations-file" => "",
    )

    i = 1
    while i <= length(argv)
        arg = argv[i]
        if !startswith(arg, "--")
            error("unexpected argument: ", arg)
        end
        key = arg[3:end]
        if !haskey(options, key)
            error("unknown option: ", arg)
        end
        if i == length(argv)
            error("missing value for ", arg)
        end
        options[key] = argv[i + 1]
        i += 2
    end

    return options
end

function load_state(options)
    nodes = if isempty(options["nodes-file"])
        fetch_json(options["base-url"], "/state/nodes")
    else
        JSON3.read(read(options["nodes-file"], String))
    end
    relations = if isempty(options["relations-file"])
        fetch_json(options["base-url"], "/state/relations")
    else
        JSON3.read(read(options["relations-file"], String))
    end
    return nodes, relations
end

function write_json(path::AbstractString, value)
    mkpath(dirname(path))
    open(path, "w") do io
        JSON3.pretty(io, value)
        println(io)
    end
end

function main(argv=ARGS)
    options = parse_args(argv)
    nodes, relations = load_state(options)
    plan = plan_calendar_projection(
        nodes,
        relations;
        root_urn=options["root-urn"],
        contract_urn=options["contract-urn"],
        channel_urn=options["channel-urn"],
        radius=parse(Int, options["radius"]),
        t0_date=Date(options["t0-date"]),
    )
    write_json(options["out"], plan)
    println("Wrote Google Calendar projection plan: ", options["out"])
    println("Events: ", plan["event_count"])
    return 0
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    exit(GoogleCalendarProjection.main())
end