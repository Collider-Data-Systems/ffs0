#!/usr/bin/env julia

module CalendarTimeFabricProjection

using Dates
using JSON3
using SHA

const DEFAULT_GRAPH_ARTIFACT = "tmp/projections/session_pipeline/graph_artifacts/session_occasion_engineering.json"
const DEFAULT_OUT = "tmp/projections/session_pipeline/calendar/calendar_time_fabric_plan.json"
const DEFAULT_MARKDOWN_OUT = "tmp/projections/session_pipeline/calendar/calendar_time_fabric_plan.md"
const DEFAULT_CONTRACT_URN = "urn:moos:program:sam.t189.calendar-time-fabric-proof"
const DEFAULT_CHANNEL_URN = "urn:moos:channel:google.calendar.sam"
const DEFAULT_T0_DATE = Date("2025-11-01")

const TYPE_LABELS = Dict(
    "claim" => "blue",
    "derivation" => "purple",
    "grammar_fragment" => "red",
    "knowledge_item" => "green",
    "pattern" => "yellow",
    "program" => "purple",
    "purpose" => "purple",
    "session" => "gray",
    "system_instruction" => "gray",
    "workflow" => "orange",
)

const TYPE_ORDER = Dict(
    "derivation" => 1,
    "knowledge_item" => 2,
    "claim" => 3,
    "grammar_fragment" => 4,
    "pattern" => 5,
    "system_instruction" => 6,
    "workflow" => 7,
    "program" => 8,
    "purpose" => 9,
    "session" => 10,
)

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

function string_value(value, default="")
    if value === nothing
        return default
    end
    text = strip(string(value))
    return isempty(text) ? default : text
end

function optional_t(value)
    text = string_value(value)
    isempty(text) && return nothing
    try
        return parse(Int, text)
    catch
        return nothing
    end
end

t_day_date(t_day::Integer; t0_date::Date=DEFAULT_T0_DATE) = t0_date + Day(t_day)

function projection_id(urn::AbstractString, contract_urn::AbstractString=DEFAULT_CONTRACT_URN)
    digest = bytes2hex(sha1(string(contract_urn, "|", urn)))
    return string("moos-", digest[1:24])
end

function node_title(node)
    title = string_value(object_value(node, :title, ""))
    if !isempty(title)
        return title
    end
    props = object_value(node, :properties, Dict())
    for field in (:title, :name, :summary)
        value = object_value(props, field, nothing)
        if value !== nothing
            value = value isa AbstractDict ? object_value(value, :value, nothing) : value
            text = string_value(value)
            !isempty(text) && return text
        end
    end
    return string_value(object_value(node, :urn, "<unknown>"), "<unknown>")
end

function short_title(text::AbstractString; limit::Integer=86)
    clean = replace(strip(text), r"\s+" => " ")
    ncodeunits(clean) <= limit && return clean
    return string(first(clean, limit - 3), "...")
end

function node_status(node)
    status = string_value(object_value(node, :status, ""))
    if !isempty(status)
        return status
    end
    props = object_value(node, :properties, Dict())
    value = object_value(props, :status, nothing)
    value = value isa AbstractDict ? object_value(value, :value, nothing) : value
    return string_value(value, "<none>")
end

function node_t_value(node, fields::Vector{Symbol})
    props = object_value(node, :properties, Dict())
    for field in fields
        value = object_value(props, field, nothing)
        value = value isa AbstractDict ? object_value(value, :value, nothing) : value
        parsed = optional_t(value)
        parsed !== nothing && return parsed
    end
    return nothing
end

function relation_context(relations, urn::AbstractString)
    incoming = []
    outgoing = []
    for rel in relations
        src = string_value(object_value(rel, :src_urn, ""))
        tgt = string_value(object_value(rel, :tgt_urn, ""))
        if src == urn
            push!(outgoing, rel)
        elseif tgt == urn
            push!(incoming, rel)
        end
    end
    return incoming, outgoing
end

function relation_line(rel)
    src_port = string_value(object_value(rel, :src_port, ""))
    tgt_port = string_value(object_value(rel, :tgt_port, ""))
    other = string_value(object_value(rel, :src_urn, ""))
    return string(src_port, " / ", tgt_port, " :: ", other)
end

function summarize_relations(incoming, outgoing; limit::Integer=4)
    lines = String[]
    if !isempty(incoming)
        push!(lines, "Incoming relations:")
        for rel in incoming[1:min(end, limit)]
            src = string_value(object_value(rel, :src_urn, ""))
            port = string_value(object_value(rel, :tgt_port, ""))
            wf = string_value(object_value(rel, :rewrite_category, ""))
            push!(lines, string("- ", wf, " ", port, " <- ", src))
        end
    end
    if !isempty(outgoing)
        push!(lines, "Outgoing relations:")
        for rel in outgoing[1:min(end, limit)]
            tgt = string_value(object_value(rel, :tgt_urn, ""))
            port = string_value(object_value(rel, :src_port, ""))
            wf = string_value(object_value(rel, :rewrite_category, ""))
            push!(lines, string("- ", wf, " ", port, " -> ", tgt))
        end
    end
    return lines
end

function event_date_for_node(node, index::Integer; anchor_t::Integer, t0_date::Date)
    explicit_t = node_t_value(node, [:t_day, :starts_t, :target_t, :deadline_t, :completed_t, :t_start, :t_target])
    if explicit_t !== nothing
        return t_day_date(explicit_t; t0_date=t0_date), string("explicit T", explicit_t)
    end
    offset = fld(index - 1, 5)
    return t_day_date(anchor_t + offset; t0_date=t0_date), string("lens-order placement from active T", anchor_t)
end

function calendar_payload(node, index::Integer, relations; contract_urn::String, anchor_t::Integer, t0_date::Date)
    urn = string_value(object_value(node, :urn, ""))
    isempty(urn) && return nothing
    type_id = string_value(object_value(node, :type_id, "unknown"), "unknown")
    title = short_title(node_title(node))
    status = node_status(node)
    date, timing_note = event_date_for_node(node, index; anchor_t=anchor_t, t0_date=t0_date)
    incoming, outgoing = relation_context(relations, urn)
    projection = projection_id(urn, contract_urn)
    summary = short_title(string("mo:os ", type_id, " :: ", title); limit=96)
    description = String[
        string("HG URN: ", urn),
        string("Type: ", type_id),
        string("Status: ", status),
        string("Projection contract: ", contract_urn),
        string("Moos T anchor: T", anchor_t),
        string("IRL calendar date: ", date),
        string("Temporal interpretation: ", timing_note),
        string("Relation counts: incoming=", length(incoming), ", outgoing=", length(outgoing)),
    ]
    relation_lines = summarize_relations(incoming, outgoing)
    if !isempty(relation_lines)
        push!(description, "")
        append!(description, relation_lines)
    end
    push!(description, "")
    push!(description, "Generated by mo:os Calendar time-fabric projection. Calendar is a projection surface; HG remains source of truth.")

    return Dict(
        "operation" => "upsert",
        "projection_id" => projection,
        "source_urn" => urn,
        "source_type" => type_id,
        "event_kind" => "recent_time_fabric_node",
        "calendar_label" => get(TYPE_LABELS, type_id, "gray"),
        "google_event" => Dict(
            "summary" => summary,
            "description" => join(description, "\n"),
            "start" => Dict("date" => string(date)),
            "end" => Dict("date" => string(date + Day(1))),
            "extendedProperties" => Dict(
                "private" => Dict(
                    "moos_urn" => urn,
                    "moos_type" => type_id,
                    "moos_contract_urn" => contract_urn,
                    "moos_projection_id" => projection,
                    "moos_event_kind" => "recent_time_fabric_node",
                ),
            ),
        ),
    )
end

function sorted_recent_nodes(nodes)
    pairs = collect(enumerate(nodes))
    sort!(pairs; by = pair -> begin
        node = pair[2]
        type_id = string_value(object_value(node, :type_id, "unknown"), "unknown")
        (get(TYPE_ORDER, type_id, 99), string_value(object_value(node, :urn, "")))
    end)
    return [pair[2] for pair in pairs]
end

function plan_time_fabric_projection(artifact; contract_urn::String=DEFAULT_CONTRACT_URN, channel_urn::String=DEFAULT_CHANNEL_URN, anchor_t::Integer=188, t0_date::Date=DEFAULT_T0_DATE, max_events::Integer=64)
    nodes = sorted_recent_nodes(collect(object_value(artifact, :nodes, [])))
    relations = collect(object_value(artifact, :relations, []))
    if max_events > 0 && length(nodes) > max_events
        nodes = nodes[1:max_events]
    end
    events = Dict{String, Any}[]
    for (index, node) in enumerate(nodes)
        payload = calendar_payload(node, index, relations; contract_urn=contract_urn, anchor_t=anchor_t, t0_date=t0_date)
        payload !== nothing && push!(events, payload)
    end
    sort!(events; by = event -> (event["google_event"]["start"]["date"], event["source_type"], event["source_urn"]))
    return Dict(
        "mode" => "plan",
        "source" => "hg_graph_artifact",
        "projection_kind" => "calendar_time_fabric_recent_nodes",
        "contract_urn" => contract_urn,
        "channel_urn" => channel_urn,
        "anchor_t" => anchor_t,
        "anchor_date" => string(t_day_date(anchor_t; t0_date=t0_date)),
        "t0_date" => string(t0_date),
        "node_count" => length(nodes),
        "relation_count" => length(relations),
        "event_count" => length(events),
        "events" => events,
    )
end

function write_json(path::AbstractString, value)
    mkpath(dirname(path))
    open(path, "w") do io
        JSON3.pretty(io, value)
        println(io)
    end
end

function write_markdown(path::AbstractString, plan)
    mkpath(dirname(path))
    open(path, "w") do io
        println(io, "# Calendar Time-Fabric Projection")
        println(io)
        println(io, "- Projection kind: `", plan["projection_kind"], "`")
        println(io, "- Contract URN: `", plan["contract_urn"], "`")
        println(io, "- Anchor: T", plan["anchor_t"], " / ", plan["anchor_date"])
        println(io, "- Events: ", plan["event_count"])
        println(io)
        println(io, "| Date | Type | Source URN | Summary |")
        println(io, "| --- | --- | --- | --- |")
        for event in plan["events"]
            date = event["google_event"]["start"]["date"]
            println(io, "| ", date, " | `", event["source_type"], "` | `", event["source_urn"], "` | ", replace(event["google_event"]["summary"], "|" => "\\|"), " |")
        end
    end
end

function parse_args(argv)
    options = Dict(
        "graph-artifact" => DEFAULT_GRAPH_ARTIFACT,
        "out" => DEFAULT_OUT,
        "markdown-out" => DEFAULT_MARKDOWN_OUT,
        "contract-urn" => DEFAULT_CONTRACT_URN,
        "channel-urn" => DEFAULT_CHANNEL_URN,
        "anchor-t" => "188",
        "t0-date" => string(DEFAULT_T0_DATE),
        "max-events" => "64",
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

function main(argv=ARGS)
    options = parse_args(argv)
    artifact = JSON3.read(read(options["graph-artifact"], String))
    plan = plan_time_fabric_projection(
        artifact;
        contract_urn=options["contract-urn"],
        channel_urn=options["channel-urn"],
        anchor_t=parse(Int, options["anchor-t"]),
        t0_date=Date(options["t0-date"]),
        max_events=parse(Int, options["max-events"]),
    )
    write_json(options["out"], plan)
    write_markdown(options["markdown-out"], plan)
    println("Wrote Calendar time-fabric plan: ", options["out"])
    println("Wrote Calendar time-fabric report: ", options["markdown-out"])
    println("Events: ", plan["event_count"])
    return 0
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    exit(CalendarTimeFabricProjection.main())
end
